import Foundation
import JavaScriptKit

/// Manages Web Worker lifecycle, communication, and coordination.
///
/// `WorkerCoordinator` handles:
/// - Worker creation and termination
/// - Message passing and event handling
/// - Worker health monitoring
/// - Resource cleanup
///
/// ## Worker Communication
///
/// Uses structured message protocol:
/// - Commands: Requests from main thread to workers
/// - Results: Responses from workers to main thread
/// - Events: Asynchronous notifications
///
/// ## Usage
///
/// ```swift
/// let coordinator = WorkerCoordinator(workerCount: 4, scriptURL: "/worker.js")
/// try await coordinator.start()
///
/// // Send task to worker
/// coordinator.postMessage(to: 0, task: task)
///
/// // Handle results
/// coordinator.onResult { result in
///     processResult(result)
/// }
/// ```
@MainActor
public final class WorkerCoordinator: Sendable {

    // MARK: - Types

    /// Information about a managed worker
    public struct WorkerInfo: Sendable {
        /// Worker ID
        public let id: Int

        /// JavaScript Worker object (not Sendable, but safe in this context)
        nonisolated(unsafe) public let worker: JSObject

        /// Worker creation time
        public let createdAt: TimeInterval

        /// Is worker ready to receive tasks
        public private(set) var isReady: Bool

        /// Current task count
        public private(set) var activeTaskCount: Int

        /// Total tasks completed
        public private(set) var completedTaskCount: Int

        /// Total tasks failed
        public private(set) var failedTaskCount: Int

        /// Last heartbeat time
        public private(set) var lastHeartbeat: TimeInterval

        init(id: Int, worker: JSObject) {
            self.id = id
            self.worker = worker
            self.createdAt = Date().timeIntervalSince1970
            self.isReady = false
            self.activeTaskCount = 0
            self.completedTaskCount = 0
            self.failedTaskCount = 0
            self.lastHeartbeat = Date().timeIntervalSince1970
        }

        mutating func markReady() {
            self.isReady = true
            self.lastHeartbeat = Date().timeIntervalSince1970
        }

        mutating func incrementActiveTasks() {
            self.activeTaskCount += 1
        }

        mutating func incrementActiveTasks(by count: Int) {
            self.activeTaskCount += count
        }

        mutating func decrementActiveTasks() {
            self.activeTaskCount = max(0, activeTaskCount - 1)
        }

        mutating func recordSuccess() {
            self.completedTaskCount += 1
            decrementActiveTasks()
        }

        mutating func recordFailure() {
            self.failedTaskCount += 1
            decrementActiveTasks()
        }

        mutating func updateHeartbeat() {
            self.lastHeartbeat = Date().timeIntervalSince1970
        }

        public var isHealthy: Bool {
            let now = Date().timeIntervalSince1970
            return now - lastHeartbeat < 30.0  // 30 second timeout
        }
    }

    /// Message types for worker communication
    public enum MessageType: String, Sendable {
        case initialize = "initialize"
        case task = "task"
        case result = "result"
        case error = "error"
        case heartbeat = "heartbeat"
        case terminate = "terminate"
        case ready = "ready"
    }

    /// Callback for task results
    public typealias ResultHandler = @MainActor @Sendable (TaskResult, Int) -> Void

    /// Callback for worker errors
    public typealias ErrorHandler = @MainActor @Sendable (Error, Int) -> Void

    // MARK: - Properties

    /// Number of workers to manage
    public let workerCount: Int

    /// URL to worker script
    public let scriptURL: String

    /// Managed workers
    private var workers: [WorkerInfo]

    /// Message handler closures (kept alive)
    private var messageClosures: [JSClosure]

    /// Error handler closures (kept alive)
    private var errorClosures: [JSClosure]

    /// Result callback
    private var resultHandler: ResultHandler?

    /// Error callback
    private var errorHandler: ErrorHandler?

    /// Whether coordinator is started
    private var isStarted: Bool

    /// Shared buffers for worker communication
    private var sharedBuffers: [SharedBuffer]

    /// Heartbeat check interval (seconds)
    private let heartbeatInterval: TimeInterval = 5.0

    /// Heartbeat task
    private var heartbeatTask: Task<Void, Never>?

    // MARK: - Initialization

    /// Initialize worker coordinator.
    ///
    /// - Parameters:
    ///   - workerCount: Number of workers to create
    ///   - scriptURL: URL to worker JavaScript file
    public init(workerCount: Int, scriptURL: String) {
        self.workerCount = workerCount
        self.scriptURL = scriptURL
        self.workers = []
        self.messageClosures = []
        self.errorClosures = []
        self.isStarted = false
        self.sharedBuffers = []
    }

    // MARK: - Lifecycle

    /// Start all workers.
    ///
    /// Creates and initializes worker threads.
    ///
    /// - Throws: If worker creation fails
    public func start() async throws {
        guard !isStarted else { return }

        guard let workerConstructor = JSObject.global.Worker.function else {
            throw CoordinatorError.workerNotSupported
        }

        // Create workers
        for id in 0..<workerCount {
            let workerObj = workerConstructor.new(scriptURL)

            let info = WorkerInfo(id: id, worker: workerObj)
            workers.append(info)

            // Setup message handler
            let messageClosure = JSClosure { [weak self] args -> JSValue in
                guard let self = self, args.count > 0 else {
                    return .undefined
                }

                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    self.handleMessage(args[0], from: id)
                }

                return .undefined
            }
            messageClosures.append(messageClosure)
            guard let addEventListenerFunc = workerObj.addEventListener.function else {
                throw CoordinatorError.workerCreationFailed(id: id)
            }
            _ = addEventListenerFunc("message", messageClosure)

            // Setup error handler
            let errorClosure = JSClosure { [weak self] args -> JSValue in
                guard let self = self, args.count > 0 else {
                    return .undefined
                }

                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    self.handleError(args[0], from: id)
                }

                return .undefined
            }
            errorClosures.append(errorClosure)
            guard let addEventListenerFunc2 = workerObj.addEventListener.function else {
                throw CoordinatorError.workerCreationFailed(id: id)
            }
            _ = addEventListenerFunc2("error", errorClosure)

            // Initialize worker
            try await initializeWorker(id: id)
        }

        isStarted = true

        // Start heartbeat monitoring
        startHeartbeatMonitoring()
    }

    /// Stop all workers.
    ///
    /// Terminates worker threads and cleans up resources.
    public func stop() {
        guard isStarted else { return }

        // Cancel heartbeat monitoring
        heartbeatTask?.cancel()
        heartbeatTask = nil

        // Terminate workers
        for worker in workers {
            sendMessage(to: worker.id, type: .terminate, payload: nil)
            _ = worker.worker.terminate!()
        }

        // Clear references
        workers.removeAll()
        messageClosures.removeAll()
        errorClosures.removeAll()
        sharedBuffers.removeAll()

        isStarted = false
    }

    /// Initialize a specific worker.
    private func initializeWorker(id: Int) async throws {
        let initData = JSObject.global.Object.function!.new()
        initData.workerID = .number(Double(id))
        initData.workerCount = .number(Double(workerCount))

        // Create shared buffer for this worker
        let buffer = try SharedBuffer(byteLength: 65536)  // 64KB per worker
        sharedBuffers.append(buffer)

        initData.sharedBuffer = .object(buffer.transferable())

        sendMessage(to: id, type: .initialize, payload: initData)

        // Wait for ready signal (with timeout)
        try await waitForReady(workerID: id, timeout: 5.0)
    }

    /// Wait for worker to signal ready.
    private func waitForReady(workerID: Int, timeout: TimeInterval) async throws {
        let deadline = Date().timeIntervalSince1970 + timeout

        while !workers[workerID].isReady {
            if Date().timeIntervalSince1970 > deadline {
                throw CoordinatorError.workerInitTimeout(id: workerID)
            }

            try? await Task.sleep(for: .milliseconds(100))
        }
    }

    // MARK: - Message Handling

    /// Handle message from a worker.
    private func handleMessage(_ event: JSValue, from workerID: Int) {
        guard let eventObj = event.object,
              let data = eventObj.data.object else {
            return
        }

        guard let typeString = data.type.string,
              let messageType = MessageType(rawValue: typeString) else {
            return
        }

        switch messageType {
        case .ready:
            handleReadyMessage(workerID: workerID)

        case .result:
            handleResultMessage(data: data, workerID: workerID)

        case .error:
            handleErrorMessage(data: data, workerID: workerID)

        case .heartbeat:
            handleHeartbeatMessage(workerID: workerID)

        default:
            break
        }
    }

    /// Handle ready message from worker.
    private func handleReadyMessage(workerID: Int) {
        guard workerID < workers.count else { return }
        workers[workerID].markReady()
    }

    /// Handle task result from worker.
    private func handleResultMessage(data: JSObject, workerID: Int) {
        guard let resultObj = data.result.object else { return }

        do {
            let result = try TaskResult.deserialize(resultObj)
            workers[workerID].recordSuccess()

            resultHandler?(result, workerID)
        } catch {
            workers[workerID].recordFailure()
            errorHandler?(error, workerID)
        }
    }

    /// Handle error message from worker.
    private func handleErrorMessage(data: JSObject, workerID: Int) {
        let errorMessage = data.error.string ?? "Unknown worker error"
        let error = CoordinatorError.workerError(id: workerID, message: errorMessage)

        workers[workerID].recordFailure()
        errorHandler?(error, workerID)
    }

    /// Handle heartbeat from worker.
    private func handleHeartbeatMessage(workerID: Int) {
        guard workerID < workers.count else { return }
        workers[workerID].updateHeartbeat()
    }

    /// Handle JavaScript error event.
    private func handleError(_ event: JSValue, from workerID: Int) {
        guard let eventObj = event.object else { return }

        let message = eventObj.message.string ?? "Unknown error"
        let error = CoordinatorError.workerError(id: workerID, message: message)

        workers[workerID].recordFailure()
        errorHandler?(error, workerID)
    }

    // MARK: - Sending Messages

    /// Send a message to a specific worker.
    ///
    /// - Parameters:
    ///   - workerID: ID of target worker
    ///   - type: Message type
    ///   - payload: Optional message payload
    public func sendMessage(to workerID: Int, type: MessageType, payload: JSObject?) {
        guard workerID < workers.count else { return }

        let message = JSObject.global.Object.function!.new()
        message.type = .string(type.rawValue)

        if let payload = payload {
            message.payload = .object(payload)
        }

        let worker = workers[workerID].worker
        _ = worker.postMessage!(message)
    }

    /// Post a task to a specific worker.
    ///
    /// - Parameters:
    ///   - workerID: ID of target worker
    ///   - task: Task to execute
    public func postTask(to workerID: Int, task: WorkerTask) {
        guard workerID < workers.count else { return }

        let taskObj = task.serialize()
        workers[workerID].incrementActiveTasks()

        sendMessage(to: workerID, type: .task, payload: taskObj)
    }

    /// Post a task batch to a worker.
    public func postBatch(to workerID: Int, batch: TaskBatch) {
        guard workerID < workers.count else { return }

        let batchObj = batch.serialize()
        workers[workerID].incrementActiveTasks(by: batch.count)

        sendMessage(to: workerID, type: .task, payload: batchObj)
    }

    /// Broadcast a message to all workers.
    ///
    /// - Parameters:
    ///   - type: Message type
    ///   - payload: Optional payload
    public func broadcast(type: MessageType, payload: JSObject? = nil) {
        for id in 0..<workers.count {
            sendMessage(to: id, type: type, payload: payload)
        }
    }

    // MARK: - Callbacks

    /// Set callback for task results.
    ///
    /// - Parameter handler: Callback receiving results and worker ID
    public func onResult(_ handler: @escaping ResultHandler) {
        self.resultHandler = handler
    }

    /// Set callback for errors.
    ///
    /// - Parameter handler: Callback receiving errors and worker ID
    public func onError(_ handler: @escaping ErrorHandler) {
        self.errorHandler = handler
    }

    // MARK: - Worker Management

    /// Get information about a specific worker.
    ///
    /// - Parameter workerID: Worker ID
    /// - Returns: Worker information if valid ID
    public func workerInfo(for workerID: Int) -> WorkerInfo? {
        guard workerID < workers.count else { return nil }
        return workers[workerID]
    }

    /// Get all worker information.
    public func allWorkerInfo() -> [WorkerInfo] {
        return workers
    }

    /// Find least busy worker.
    ///
    /// - Returns: Worker ID of least busy worker
    public func leastBusyWorker() -> Int? {
        guard !workers.isEmpty else { return nil }

        return workers.enumerated()
            .filter { $0.element.isReady && $0.element.isHealthy }
            .min { $0.element.activeTaskCount < $1.element.activeTaskCount }?
            .offset
    }

    /// Check if any workers are available.
    public var hasAvailableWorkers: Bool {
        return workers.contains { $0.isReady && $0.isHealthy }
    }

    // MARK: - Health Monitoring

    /// Start heartbeat monitoring.
    private func startHeartbeatMonitoring() {
        heartbeatTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self = self else { break }
                try? await Task.sleep(for: .seconds(self.heartbeatInterval))

                await MainActor.run {
                    self.checkWorkerHealth()
                }
            }
        }
    }

    /// Check health of all workers.
    private func checkWorkerHealth() {
        for (index, worker) in workers.enumerated() {
            if !worker.isHealthy {
                // Worker is unresponsive
                let error = CoordinatorError.workerUnresponsive(id: worker.id)
                errorHandler?(error, worker.id)

                // Optionally restart worker
                Task {
                    try? await restartWorker(id: index)
                }
            }
        }
    }

    /// Restart a worker.
    private func restartWorker(id: Int) async throws {
        guard id < workers.count else { return }

        // Terminate old worker
        let oldWorker = workers[id].worker
        _ = oldWorker.terminate!()

        // Create new worker
        guard let workerConstructor = JSObject.global.Worker.function else {
            throw CoordinatorError.workerNotSupported
        }

        let newWorkerObj = workerConstructor.new(scriptURL)

        // Update info
        workers[id] = WorkerInfo(id: id, worker: newWorkerObj)

        // Re-setup handlers (reuse existing closures)
        guard let addEventListenerFunc = newWorkerObj.addEventListener.function else {
            throw CoordinatorError.workerCreationFailed(id: id)
        }
        _ = addEventListenerFunc("message", messageClosures[id])
        _ = addEventListenerFunc("error", errorClosures[id])

        // Reinitialize
        try await initializeWorker(id: id)
    }

    // MARK: - Statistics

    /// Get coordinator statistics.
    ///
    /// - Returns: Dictionary with statistics
    public func statistics() -> [String: Any] {
        let totalActive = workers.reduce(0) { $0 + $1.activeTaskCount }
        let totalCompleted = workers.reduce(0) { $0 + $1.completedTaskCount }
        let totalFailed = workers.reduce(0) { $0 + $1.failedTaskCount }
        let readyCount = workers.filter(\.isReady).count
        let healthyCount = workers.filter(\.isHealthy).count

        return [
            "workerCount": workerCount,
            "activeWorkers": readyCount,
            "healthyWorkers": healthyCount,
            "activeTasks": totalActive,
            "completedTasks": totalCompleted,
            "failedTasks": totalFailed,
            "isStarted": isStarted
        ]
    }
}

// MARK: - Task Extension


// MARK: - Coordinator Errors

/// Errors that can occur with worker coordination
public enum CoordinatorError: Error, Sendable {
    case workerNotSupported
    case workerCreationFailed(id: Int)
    case workerInitTimeout(id: Int)
    case workerUnresponsive(id: Int)
    case workerError(id: Int, message: String)
    case invalidWorkerID
    case coordinatorNotStarted
}
