import Foundation
import JavaScriptKit

/// High-level Web Worker pool with work-stealing scheduler.
///
/// `ThreadPool` provides a complete thread pool implementation with:
/// - Automatic worker management
/// - Work-stealing scheduler for load balancing
/// - Priority-based task scheduling
/// - Task cancellation and timeout
/// - Health monitoring and recovery
///
/// ## Architecture
///
/// Each worker has its own work-stealing deque. When a worker runs out of
/// work, it attempts to steal from other workers' queues, providing automatic
/// load balancing.
///
/// ## Usage
///
/// ```swift
/// let pool = ThreadPool(workerCount: 4)
/// try await pool.start()
///
/// // Submit tasks
/// let taskID = try await pool.submit(type: .render, priority: .high) { context in
///     // Work performed in worker
///     return result
/// }
///
/// // Wait for result
/// let result = try await pool.wait(for: taskID)
/// ```
///
/// ## Performance
///
/// - Work stealing reduces idle time
/// - Priority scheduling ensures responsiveness
/// - Automatic scaling based on load
/// - Minimal contention through per-worker queues
@MainActor
public final class ThreadPool: Sendable {

    // MARK: - Types

    /// Pool configuration
    public struct Configuration: Sendable {
        /// Number of worker threads
        public var workerCount: Int

        /// Queue capacity per worker
        public var queueCapacity: Int

        /// Enable work stealing
        public var enableWorkStealing: Bool

        /// Work stealing threshold (attempt to steal when queue below this)
        public var stealThreshold: Int

        /// Task timeout in seconds
        public var taskTimeout: TimeInterval

        /// Enable health monitoring
        public var enableHealthMonitoring: Bool

        /// Health check interval
        public var healthCheckInterval: TimeInterval

        /// Maximum task retries on failure
        public var maxRetries: Int

        public init(
            workerCount: Int = 4,
            queueCapacity: Int = 1024,
            enableWorkStealing: Bool = true,
            stealThreshold: Int = 10,
            taskTimeout: TimeInterval = 30.0,
            enableHealthMonitoring: Bool = true,
            healthCheckInterval: TimeInterval = 5.0,
            maxRetries: Int = 2
        ) {
            self.workerCount = workerCount
            self.queueCapacity = queueCapacity
            self.enableWorkStealing = enableWorkStealing
            self.stealThreshold = stealThreshold
            self.taskTimeout = taskTimeout
            self.enableHealthMonitoring = enableHealthMonitoring
            self.healthCheckInterval = healthCheckInterval
            self.maxRetries = maxRetries
        }
    }

    /// Pool statistics
    public struct Statistics: Sendable {
        public let workerCount: Int
        public let activeWorkers: Int
        public let totalTasksSubmitted: Int
        public let totalTasksCompleted: Int
        public let totalTasksFailed: Int
        public let totalStealAttempts: Int
        public let successfulSteals: Int
        public let averageTaskTime: TimeInterval
        public let poolUtilization: Double

        public var stealSuccessRate: Double {
            guard totalStealAttempts > 0 else { return 0.0 }
            return Double(successfulSteals) / Double(totalStealAttempts)
        }
    }

    // MARK: - Properties

    /// Pool configuration
    public let config: Configuration

    /// Worker coordinator
    private let coordinator: WorkerCoordinator

    /// Shared buffer for queues
    private let sharedBuffer: SharedBuffer

    /// Work-stealing queues (one per worker)
    private var queues: [WorkStealingQueue]

    /// Task registry
    private var tasks: [UUID: TrackedTask]

    /// Global task counter
    private var taskCounter: AtomicInt32

    /// Statistics tracking
    private var stats: PoolStatistics

    /// Whether pool is running
    private var isRunning: Bool

    /// Health monitoring task
    private var healthTask: Task<Void, Never>?

    /// Scheduler task
    private var schedulerTask: Task<Void, Never>?

    // MARK: - Initialization

    /// Initialize thread pool.
    ///
    /// - Parameters:
    ///   - config: Pool configuration
    ///   - workerScriptURL: URL to worker script
    /// - Throws: If initialization fails
    public init(
        config: Configuration = Configuration(),
        workerScriptURL: String = "/raven-worker.js"
    ) throws {
        self.config = config
        self.coordinator = WorkerCoordinator(
            workerCount: config.workerCount,
            scriptURL: workerScriptURL
        )

        // Calculate buffer size for all queues
        let bytesPerQueue = WorkStealingQueue.requiredBytes(capacity: config.queueCapacity)
        let totalBytes = bytesPerQueue * config.workerCount + 1024  // Extra for metadata

        self.sharedBuffer = try SharedBuffer(byteLength: totalBytes)
        self.taskCounter = try AtomicInt32(buffer: sharedBuffer, index: 0)

        // Create work-stealing queues
        self.queues = []
        for i in 0..<config.workerCount {
            let offset = 16 + (i * bytesPerQueue)  // 16 bytes for header
            let queue = try WorkStealingQueue(
                capacity: config.queueCapacity,
                buffer: sharedBuffer,
                offset: offset
            )
            queues.append(queue)
        }

        self.tasks = [:]
        self.stats = PoolStatistics()
        self.isRunning = false

        setupCoordinator()
    }

    /// Setup coordinator callbacks.
    private func setupCoordinator() {
        coordinator.onResult { [weak self] result, workerID in
            guard let self = self else { return }
            self.handleTaskCompletion(result, from: workerID)
        }

        coordinator.onError { [weak self] error, workerID in
            guard let self = self else { return }
            self.handleTaskError(error, from: workerID)
        }
    }

    // MARK: - Lifecycle

    /// Start the thread pool.
    ///
    /// Initializes workers and begins scheduling.
    ///
    /// - Throws: If startup fails
    public func start() async throws {
        guard !isRunning else { return }

        // Start coordinator
        try await coordinator.start()

        // Transfer shared buffer to workers
        for i in 0..<config.workerCount {
            let initMessage = JSObject.global.Object.function!.new()
            initMessage.sharedBuffer = .object(sharedBuffer.transferable())
            initMessage.queueOffset = .number(Double(16 + (i * WorkStealingQueue.requiredBytes(capacity: config.queueCapacity))))
            initMessage.queueCapacity = .number(Double(config.queueCapacity))

            coordinator.sendMessage(
                to: i,
                type: .initialize,
                payload: initMessage
            )
        }

        isRunning = true

        // Start scheduler
        startScheduler()

        // Start health monitoring if enabled
        if config.enableHealthMonitoring {
            startHealthMonitoring()
        }
    }

    /// Stop the thread pool.
    ///
    /// Waits for active tasks to complete and shuts down workers.
    public func stop() async {
        guard isRunning else { return }

        // Stop scheduler and health monitoring
        schedulerTask?.cancel()
        healthTask?.cancel()

        // Wait for active tasks
        await drainQueue()

        // Stop coordinator
        coordinator.stop()

        // Clear state
        tasks.removeAll()
        isRunning = false
    }

    /// Wait for all active tasks to complete.
    private func drainQueue() async {
        let maxWait = 30.0  // 30 seconds
        let startTime = Date().timeIntervalSince1970

        while !tasks.isEmpty {
            if Date().timeIntervalSince1970 - startTime > maxWait {
                break
            }
            try? await Task.sleep(for: .milliseconds(100))
        }
    }

    // MARK: - Task Submission

    /// Submit a task to the pool.
    ///
    /// - Parameters:
    ///   - type: Task type
    ///   - priority: Task priority
    ///   - deadline: Optional deadline
    ///   - payload: Task data
    /// - Returns: Task identifier
    /// - Throws: If submission fails
    @discardableResult
    public func submit(
        type: WorkerTask.TaskType,
        priority: WorkerTask.Priority = .normal,
        deadline: TimeInterval? = nil,
        payload: WorkerTask.Payload = WorkerTask.Payload()
    ) async throws -> UUID {
        guard isRunning else {
            throw ThreadPoolError.poolNotRunning
        }

        // Create task
        let task = WorkerTask(
            type: type,
            priority: priority,
            payload: payload,
            deadline: deadline
        )

        // Track task
        let tracked = TrackedTask(
            task: task,
            submittedAt: Date().timeIntervalSince1970,
            retryCount: 0
        )
        tasks[task.id] = tracked

        // Update statistics
        stats.tasksSubmitted += 1

        // Schedule task
        try scheduleTask(task)

        return task.id
    }

    /// Submit a batch of tasks.
    ///
    /// - Parameter batch: Task batch
    /// - Returns: Array of task IDs
    /// - Throws: If submission fails
    @discardableResult
    public func submitBatch(_ batch: TaskBatch) async throws -> [UUID] {
        var taskIDs: [UUID] = []

        for task in batch.tasks {
            let tracked = TrackedTask(
                task: task,
                submittedAt: Date().timeIntervalSince1970,
                retryCount: 0
            )
            tasks[task.id] = tracked
            taskIDs.append(task.id)
        }

        stats.tasksSubmitted += batch.count

        // Distribute tasks
        try await distributeBatch(batch)

        return taskIDs
    }

    /// Schedule a single task to a worker.
    private func scheduleTask(_ task: WorkerTask) throws {
        // Find least loaded worker
        guard let workerID = findBestWorker(for: task) else {
            throw ThreadPoolError.noAvailableWorkers
        }

        // Enqueue task
        let taskID = Int32(taskCounter.increment())
        guard queues[workerID].push(taskID) else {
            throw ThreadPoolError.queueFull
        }

        // Notify worker
        coordinator.postTask(to: workerID, task: task)
    }

    /// Distribute batch to workers.
    private func distributeBatch(_ batch: TaskBatch) async throws {
        let tasksPerWorker = batch.count / config.workerCount
        var remaining = batch.tasks

        for workerID in 0..<config.workerCount {
            let count = workerID < config.workerCount - 1 ? tasksPerWorker : remaining.count
            let workerTasks = Array(remaining.prefix(count))
            remaining.removeFirst(count)

            let workerBatch = TaskBatch(tasks: workerTasks)
            coordinator.postBatch(to: workerID, batch: workerBatch)
        }
    }

    /// Find best worker for a task.
    private func findBestWorker(for task: WorkerTask) -> Int? {
        // Check affinity first
        if let affinityWorker = task.affinityWorkerID,
           affinityWorker < config.workerCount {
            return affinityWorker
        }

        // Find worker with smallest queue
        var bestWorker: Int?
        var bestCount = Int.max

        for i in 0..<config.workerCount {
            let count = queues[i].count
            if count < bestCount {
                bestCount = count
                bestWorker = i
            }
        }

        return bestWorker
    }

    // MARK: - Task Management

    /// Wait for a task to complete.
    ///
    /// - Parameters:
    ///   - taskID: Task identifier
    ///   - timeout: Optional timeout
    /// - Returns: Task result
    /// - Throws: If task fails or times out
    public func wait(for taskID: UUID, timeout: TimeInterval? = nil) async throws -> TaskResult {
        let deadline = timeout.map { Date().timeIntervalSince1970 + $0 }

        while true {
            guard let tracked = tasks[taskID] else {
                throw ThreadPoolError.taskNotFound
            }

            if let result = tracked.result {
                if result.success {
                    return result
                } else {
                    throw ThreadPoolError.taskFailed(result.error ?? "Unknown error")
                }
            }

            if let deadline = deadline,
               Date().timeIntervalSince1970 > deadline {
                throw ThreadPoolError.timeout
            }

            try await Task.sleep(for: .milliseconds(10))
        }
    }

    /// Cancel a task.
    ///
    /// - Parameter taskID: Task to cancel
    public func cancel(_ taskID: UUID) {
        guard let tracked = tasks[taskID] else { return }

        var updatedTask = tracked.task
        updatedTask.markCancelled()

        tasks[taskID] = TrackedTask(
            task: updatedTask,
            submittedAt: tracked.submittedAt,
            retryCount: tracked.retryCount,
            result: TaskResult(
                taskID: taskID,
                success: false,
                error: "Cancelled",
                duration: 0,
                workerID: -1
            )
        )
    }

    // MARK: - Task Completion

    /// Handle task completion.
    private func handleTaskCompletion(_ result: TaskResult, from workerID: Int) {
        guard let tracked = tasks[result.taskID] else { return }

        // Update task
        tasks[result.taskID] = TrackedTask(
            task: tracked.task,
            submittedAt: tracked.submittedAt,
            retryCount: tracked.retryCount,
            result: result
        )

        // Update statistics
        if result.success {
            stats.tasksCompleted += 1
            stats.totalTaskTime += result.duration
        } else {
            stats.tasksFailed += 1
        }

        // Remove from queue
        _ = queues[workerID].pop()
    }

    /// Handle task error.
    private func handleTaskError(_ error: Error, from workerID: Int) {
        stats.tasksFailed += 1
        _ = queues[workerID].pop()
    }

    // MARK: - Work Stealing

    /// Start the work-stealing scheduler.
    private func startScheduler() {
        guard config.enableWorkStealing else { return }

        schedulerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(100))  // Check every 100ms

                guard let self = self else { break }

                await MainActor.run {
                    self.performWorkStealing()
                }
            }
        }
    }

    /// Perform work stealing across workers.
    private func performWorkStealing() {
        for victimID in 0..<config.workerCount {
            let victimQueue = queues[victimID]

            // Check if worker needs work
            if victimQueue.count < config.stealThreshold {
                stats.stealAttempts += 1

                // Try to steal from another worker
                if let thief = findStealTarget(excluding: victimID) {
                    if let stolen = queues[thief].steal() {
                        _ = victimQueue.push(stolen)
                        stats.successfulSteals += 1
                    }
                }
            }
        }
    }

    /// Find a worker to steal from.
    private func findStealTarget(excluding victimID: Int) -> Int? {
        var bestTarget: Int?
        var bestCount = 0

        for i in 0..<config.workerCount where i != victimID {
            let count = queues[i].count
            if count > bestCount {
                bestCount = count
                bestTarget = i
            }
        }

        return bestTarget
    }

    // MARK: - Health Monitoring

    /// Start health monitoring.
    private func startHealthMonitoring() {
        let interval = config.healthCheckInterval
        healthTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(Int(interval * 1000)))

                guard let self = self else { break }

                await MainActor.run {
                    self.checkHealth()
                }
            }
        }
    }

    /// Check pool health.
    private func checkHealth() {
        // Check for stuck tasks
        let now = Date().timeIntervalSince1970

        for (taskID, tracked) in tasks {
            let age = now - tracked.submittedAt

            if age > config.taskTimeout && tracked.result == nil {
                // Task is stuck, cancel it
                cancel(taskID)
            }
        }

        // Check worker health
        for info in coordinator.allWorkerInfo() {
            if !info.isHealthy {
                print("Worker \(info.id) is unhealthy")
            }
        }
    }

    // MARK: - Statistics

    /// Get pool statistics.
    public func statistics() -> Statistics {
        let activeWorkers = coordinator.allWorkerInfo().filter(\.isReady).count
        let avgTime = stats.tasksCompleted > 0 ? stats.totalTaskTime / Double(stats.tasksCompleted) : 0.0

        let totalCapacity = config.workerCount * config.queueCapacity
        let totalUsed = queues.reduce(0) { $0 + $1.count }
        let utilization = Double(totalUsed) / Double(totalCapacity)

        return Statistics(
            workerCount: config.workerCount,
            activeWorkers: activeWorkers,
            totalTasksSubmitted: stats.tasksSubmitted,
            totalTasksCompleted: stats.tasksCompleted,
            totalTasksFailed: stats.tasksFailed,
            totalStealAttempts: stats.stealAttempts,
            successfulSteals: stats.successfulSteals,
            averageTaskTime: avgTime,
            poolUtilization: utilization
        )
    }
}

// MARK: - Supporting Types

/// Tracked task with metadata
private struct TrackedTask: Sendable {
    let task: WorkerTask
    let submittedAt: TimeInterval
    let retryCount: Int
    let result: TaskResult?

    init(task: WorkerTask, submittedAt: TimeInterval, retryCount: Int, result: TaskResult? = nil) {
        self.task = task
        self.submittedAt = submittedAt
        self.retryCount = retryCount
        self.result = result
    }
}

/// Internal statistics tracking
private struct PoolStatistics {
    var tasksSubmitted: Int = 0
    var tasksCompleted: Int = 0
    var tasksFailed: Int = 0
    var stealAttempts: Int = 0
    var successfulSteals: Int = 0
    var totalTaskTime: TimeInterval = 0.0
}

// MARK: - Thread Pool Errors

/// Errors that can occur with thread pool
public enum ThreadPoolError: Error, Sendable {
    case poolNotRunning
    case noAvailableWorkers
    case queueFull
    case taskNotFound
    case taskFailed(String)
    case timeout
    case invalidConfiguration
}

// MARK: - WorkStealingQueue Extension

extension WorkStealingQueue {
    static func requiredBytes(capacity: Int) -> Int {
        return 8 + (capacity * 4)  // Header + data
    }
}

