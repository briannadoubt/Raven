import Foundation
import JavaScriptKit

/// Represents a unit of work that can be distributed to Web Workers.
///
/// `WorkerTask` encapsulates a rendering or computation task with all necessary
/// context and priority information. Tasks are serialized for transfer between
/// the main thread and workers.
///
/// ## Task Types
///
/// - Render: VNode tree rendering
/// - Diff: Virtual DOM diffing
/// - Layout: Layout computation
/// - Paint: Style and paint operations
///
/// ## Priority Levels
///
/// - High: User-interactive work (animations, input)
/// - Normal: Regular rendering updates
/// - Low: Background work (prefetch, cleanup)
/// - Idle: Can be deferred indefinitely
///
/// ## Usage
///
/// ```swift
/// let task = WorkerTask(
///     id: UUID(),
///     type: .render,
///     priority: .high,
///     payload: renderPayload
/// )
///
/// // Serialize for worker transfer
/// let serialized = task.serialize()
/// worker.postMessage(serialized)
/// ```
public struct WorkerTask: Sendable, Identifiable {

    // MARK: - Types

    /// Type of work to perform
    public enum TaskType: Int32, Sendable, Codable {
        case render = 0
        case diff = 1
        case layout = 2
        case paint = 3
        case compute = 4
        case custom = 99
    }

    /// Priority level for task scheduling
    public enum Priority: Int32, Sendable, Codable, Comparable {
        case idle = 0
        case low = 1
        case normal = 2
        case high = 3

        public static func < (lhs: Priority, rhs: Priority) -> Bool {
            return lhs.rawValue < rhs.rawValue
        }
    }

    /// Task execution status
    public enum Status: Int32, Sendable, Codable {
        case pending = 0
        case running = 1
        case completed = 2
        case failed = 3
        case cancelled = 4
    }

    /// Task payload containing work data
    public struct Payload: Sendable, Codable {
        /// JSON-encoded data
        public let data: String

        /// Shared buffer references (indices)
        public let bufferRefs: [Int]

        /// Additional metadata
        public let metadata: [String: String]

        public init(data: String = "", bufferRefs: [Int] = [], metadata: [String: String] = [:]) {
            self.data = data
            self.bufferRefs = bufferRefs
            self.metadata = metadata
        }
    }

    // MARK: - Properties

    /// Unique identifier for this task
    public let id: UUID

    /// Type of work to perform
    public let type: TaskType

    /// Priority level
    public let priority: Priority

    /// Task payload
    public let payload: Payload

    /// Parent task ID (for hierarchical tasks)
    public let parentID: UUID?

    /// Worker ID that should execute this task (nil = any worker)
    public let affinityWorkerID: Int?

    /// Task creation timestamp
    public let createdAt: TimeInterval

    /// Deadline for task completion (nil = no deadline)
    public let deadline: TimeInterval?

    /// Current status
    public private(set) var status: Status

    /// Worker ID currently executing this task
    public private(set) var assignedWorkerID: Int?

    /// Task start timestamp
    public private(set) var startedAt: TimeInterval?

    /// Task completion timestamp
    public private(set) var completedAt: TimeInterval?

    /// Error message if failed
    public private(set) var error: String?

    // MARK: - Initialization

    /// Initialize a new worker task.
    ///
    /// - Parameters:
    ///   - id: Unique identifier (auto-generated if nil)
    ///   - type: Type of work to perform
    ///   - priority: Priority level
    ///   - payload: Task data
    ///   - parentID: Parent task identifier
    ///   - affinityWorkerID: Preferred worker ID
    ///   - deadline: Optional deadline timestamp
    public init(
        id: UUID = UUID(),
        type: TaskType,
        priority: Priority = .normal,
        payload: Payload = Payload(),
        parentID: UUID? = nil,
        affinityWorkerID: Int? = nil,
        deadline: TimeInterval? = nil
    ) {
        self.id = id
        self.type = type
        self.priority = priority
        self.payload = payload
        self.parentID = parentID
        self.affinityWorkerID = affinityWorkerID
        self.createdAt = Date().timeIntervalSince1970
        self.deadline = deadline
        self.status = .pending
        self.assignedWorkerID = nil
        self.startedAt = nil
        self.completedAt = nil
        self.error = nil
    }

    // MARK: - Status Management

    /// Mark task as started by a worker.
    ///
    /// - Parameter workerID: ID of the worker executing the task
    public mutating func markStarted(by workerID: Int) {
        self.status = .running
        self.assignedWorkerID = workerID
        self.startedAt = Date().timeIntervalSince1970
    }

    /// Mark task as completed successfully.
    public mutating func markCompleted() {
        self.status = .completed
        self.completedAt = Date().timeIntervalSince1970
    }

    /// Mark task as failed with an error.
    ///
    /// - Parameter error: Error message
    public mutating func markFailed(error: String) {
        self.status = .failed
        self.completedAt = Date().timeIntervalSince1970
        self.error = error
    }

    /// Mark task as cancelled.
    public mutating func markCancelled() {
        self.status = .cancelled
        self.completedAt = Date().timeIntervalSince1970
    }

    // MARK: - Timing

    /// Duration the task has been running (if started).
    public var duration: TimeInterval? {
        guard let startedAt = startedAt else { return nil }

        if let completedAt = completedAt {
            return completedAt - startedAt
        } else {
            return Date().timeIntervalSince1970 - startedAt
        }
    }

    /// Time since task was created.
    public var age: TimeInterval {
        return Date().timeIntervalSince1970 - createdAt
    }

    /// Check if task has exceeded its deadline.
    public var isOverdue: Bool {
        guard let deadline = deadline else { return false }
        return Date().timeIntervalSince1970 > deadline
    }

    /// Time remaining until deadline (nil if no deadline or already passed).
    public var timeRemaining: TimeInterval? {
        guard let deadline = deadline else { return nil }
        let remaining = deadline - Date().timeIntervalSince1970
        return remaining > 0 ? remaining : nil
    }

    // MARK: - Serialization

    /// Serialize task for transfer to a Web Worker.
    ///
    /// Creates a JavaScript object suitable for postMessage.
    ///
    /// - Returns: JavaScript object representation
    public func serialize() -> JSObject {
        let obj = JSObject.global.Object.function!.new()

        obj.id = .string(id.uuidString)
        obj.type = .number(Double(type.rawValue))
        obj.priority = .number(Double(priority.rawValue))
        obj.status = .number(Double(status.rawValue))
        obj.createdAt = .number(createdAt)

        // Payload
        let payloadObj = JSObject.global.Object.function!.new()
        payloadObj.data = .string(payload.data)

        let bufferRefsArray = JSObject.global.Array.function!.new()
        for (index, ref) in payload.bufferRefs.enumerated() {
            bufferRefsArray[index] = .number(Double(ref))
        }
        payloadObj.bufferRefs = .object(bufferRefsArray)

        let metadataObj = JSObject.global.Object.function!.new()
        for (key, value) in payload.metadata {
            metadataObj[key] = .string(value)
        }
        payloadObj.metadata = .object(metadataObj)

        obj.payload = .object(payloadObj)

        // Optional fields
        if let parentID = parentID {
            obj.parentID = .string(parentID.uuidString)
        }
        if let affinityWorkerID = affinityWorkerID {
            obj.affinityWorkerID = .number(Double(affinityWorkerID))
        }
        if let deadline = deadline {
            obj.deadline = .number(deadline)
        }
        if let assignedWorkerID = assignedWorkerID {
            obj.assignedWorkerID = .number(Double(assignedWorkerID))
        }
        if let startedAt = startedAt {
            obj.startedAt = .number(startedAt)
        }
        if let completedAt = completedAt {
            obj.completedAt = .number(completedAt)
        }
        if let error = error {
            obj.error = .string(error)
        }

        return obj
    }

    /// Deserialize task from a JavaScript object.
    ///
    /// - Parameter jsObject: JavaScript object from postMessage
    /// - Returns: Reconstructed WorkerTask
    /// - Throws: If deserialization fails
    public static func deserialize(_ jsObject: JSObject) throws -> WorkerTask {
        guard let idString = jsObject.id.string,
              let id = UUID(uuidString: idString) else {
            throw TaskError.invalidTaskID
        }

        guard let typeRaw = jsObject.type.number,
              let type = TaskType(rawValue: Int32(typeRaw)) else {
            throw TaskError.invalidTaskType
        }

        guard let priorityRaw = jsObject.priority.number,
              let priority = Priority(rawValue: Int32(priorityRaw)) else {
            throw TaskError.invalidPriority
        }

        guard let statusRaw = jsObject.status.number,
              let status = Status(rawValue: Int32(statusRaw)) else {
            throw TaskError.invalidStatus
        }

        guard jsObject.createdAt.number != nil else {
            throw TaskError.missingCreatedAt
        }

        // Deserialize payload
        guard let payloadObj = jsObject.payload.object else {
            throw TaskError.missingPayload
        }

        let payloadData = payloadObj.data.string ?? ""

        var bufferRefs: [Int] = []
        if let bufferRefsArray = payloadObj.bufferRefs.object {
            let length = Int(bufferRefsArray.length.number ?? 0)
            for i in 0..<length {
                if let ref = bufferRefsArray[i].number {
                    bufferRefs.append(Int(ref))
                }
            }
        }

        var metadata: [String: String] = [:]
        if let metadataObj = payloadObj.metadata.object {
            let keys = JSObject.global.Object.keys(metadataObj)
            let length = Int(keys.length.number ?? 0)
            for i in 0..<length {
                if let key = keys[i].string,
                   let value = metadataObj[key].string {
                    metadata[key] = value
                }
            }
        }

        let payload = Payload(data: payloadData, bufferRefs: bufferRefs, metadata: metadata)

        // Optional fields
        let parentID = jsObject.parentID.string.flatMap { UUID(uuidString: $0) }
        let affinityWorkerID = jsObject.affinityWorkerID.number.map { Int($0) }
        let deadline = jsObject.deadline.number

        var task = WorkerTask(
            id: id,
            type: type,
            priority: priority,
            payload: payload,
            parentID: parentID,
            affinityWorkerID: affinityWorkerID,
            deadline: deadline
        )

        // Restore status fields
        task.status = status
        task.assignedWorkerID = jsObject.assignedWorkerID.number.map { Int($0) }
        task.startedAt = jsObject.startedAt.number
        task.completedAt = jsObject.completedAt.number
        task.error = jsObject.error.string

        return task
    }
}

// MARK: - Task Errors

/// Errors that can occur with worker tasks
public enum TaskError: Error, Sendable {
    case invalidTaskID
    case invalidTaskType
    case invalidPriority
    case invalidStatus
    case missingCreatedAt
    case missingPayload
    case serializationFailed
    case deserializationFailed
    case taskNotFound
    case taskAlreadyStarted
    case taskAlreadyCompleted
}

// MARK: - Task Result

/// Result of task execution
public struct TaskResult: Sendable, Codable {
    /// Task ID
    public let taskID: UUID

    /// Whether execution succeeded
    public let success: Bool

    /// Result data (if successful)
    public let data: String?

    /// Error message (if failed)
    public let error: String?

    /// Execution duration in seconds
    public let duration: TimeInterval

    /// Worker ID that executed the task
    public let workerID: Int

    public init(
        taskID: UUID,
        success: Bool,
        data: String? = nil,
        error: String? = nil,
        duration: TimeInterval,
        workerID: Int
    ) {
        self.taskID = taskID
        self.success = success
        self.data = data
        self.error = error
        self.duration = duration
        self.workerID = workerID
    }

    /// Serialize result for transfer back to main thread.
    public func serialize() -> JSObject {
        let obj = JSObject.global.Object.function!.new()
        obj.taskID = .string(taskID.uuidString)
        obj.success = .boolean(success)
        obj.duration = .number(duration)
        obj.workerID = .number(Double(workerID))

        if let data = data {
            obj.data = .string(data)
        }
        if let error = error {
            obj.error = .string(error)
        }

        return obj
    }

    /// Deserialize result from JavaScript object.
    public static func deserialize(_ jsObject: JSObject) throws -> TaskResult {
        guard let taskIDString = jsObject.taskID.string,
              let taskID = UUID(uuidString: taskIDString) else {
            throw TaskError.invalidTaskID
        }

        guard let success = jsObject.success.boolean else {
            throw TaskError.deserializationFailed
        }

        guard let duration = jsObject.duration.number else {
            throw TaskError.deserializationFailed
        }

        guard let workerID = jsObject.workerID.number else {
            throw TaskError.deserializationFailed
        }

        let data = jsObject.data.string
        let error = jsObject.error.string

        return TaskResult(
            taskID: taskID,
            success: success,
            data: data,
            error: error,
            duration: duration,
            workerID: Int(workerID)
        )
    }
}

// MARK: - Task Batch

/// A collection of related tasks that should be processed together.
///
/// Batching reduces overhead for many small tasks.
public struct TaskBatch: Sendable {
    /// Tasks in this batch
    public let tasks: [WorkerTask]

    /// Batch priority (highest priority of contained tasks)
    public var priority: WorkerTask.Priority {
        return tasks.map(\.priority).max() ?? .normal
    }

    /// Total task count
    public var count: Int {
        return tasks.count
    }

    public init(tasks: [WorkerTask]) {
        self.tasks = tasks
    }

    /// Serialize batch for worker transfer.
    public func serialize() -> JSObject {
        let obj = JSObject.global.Object.function!.new()

        let tasksArray = JSObject.global.Array.function!.new()
        for (index, task) in tasks.enumerated() {
            tasksArray[index] = .object(task.serialize())
        }

        obj.tasks = .object(tasksArray)
        obj.count = .number(Double(count))
        obj.priority = .number(Double(priority.rawValue))

        return obj
    }

    /// Deserialize batch from JavaScript object.
    public static func deserialize(_ jsObject: JSObject) throws -> TaskBatch {
        guard let tasksArray = jsObject.tasks.object else {
            throw TaskError.deserializationFailed
        }

        let length = Int(tasksArray.length.number ?? 0)
        var tasks: [WorkerTask] = []

        for i in 0..<length {
            if let taskObj = tasksArray[i].object {
                let task = try WorkerTask.deserialize(taskObj)
                tasks.append(task)
            }
        }

        return TaskBatch(tasks: tasks)
    }
}
