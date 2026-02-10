import Foundation
import JavaScriptKit

/// Queue for managing offline operations with automatic sync when online.
///
/// `SyncQueue` maintains a persistent queue of operations that failed or occurred
/// while offline, and automatically retries them when the network becomes available.
@MainActor
public final class SyncQueue: @unchecked Sendable {
    // MARK: - Types

    /// Represents a queued operation
    public struct QueuedOperation: Sendable, Codable {
        public let id: String
        public let type: String
        public let url: String
        public let method: String
        public let headers: [String: String]
        public let body: String?
        public let timestamp: Date
        public let priority: Int
        public var retryCount: Int
        public var lastRetry: Date?

        public init(
            id: String = UUID().uuidString,
            type: String,
            url: String,
            method: String,
            headers: [String: String] = [:],
            body: String? = nil,
            priority: Int = 0,
            retryCount: Int = 0
        ) {
            self.id = id
            self.type = type
            self.url = url
            self.method = method
            self.headers = headers
            self.body = body
            self.timestamp = Date()
            self.priority = priority
            self.retryCount = retryCount
            self.lastRetry = nil
        }
    }

    /// Retry strategy configuration
    public struct RetryConfig: Sendable {
        public let maxRetries: Int
        public let initialDelay: TimeInterval
        public let maxDelay: TimeInterval
        public let backoffMultiplier: Double

        public static let `default` = RetryConfig(
            maxRetries: 5,
            initialDelay: 1.0,
            maxDelay: 300.0,
            backoffMultiplier: 2.0
        )

        public init(
            maxRetries: Int,
            initialDelay: TimeInterval,
            maxDelay: TimeInterval,
            backoffMultiplier: Double
        ) {
            self.maxRetries = maxRetries
            self.initialDelay = initialDelay
            self.maxDelay = maxDelay
            self.backoffMultiplier = backoffMultiplier
        }
    }

    // MARK: - Properties

    /// IndexedDB storage for queue persistence
    private let storage: IndexedDB

    /// Store name for queued operations
    private let storeName = "syncQueue"

    /// Retry configuration
    public let retryConfig: RetryConfig

    /// In-memory cache of queued operations
    private var queue: [QueuedOperation] = []

    /// Whether a sync is currently in progress
    private var isSyncing = false

    /// Network state observer token
    private var networkToken: UUID?

    /// Callbacks for operation completion
    private var completionCallbacks: [String: @Sendable @MainActor (Result<Void, Error>) -> Void] = [:]

    /// Callbacks for sync progress
    private var progressCallbacks: [UUID: @Sendable @MainActor (Int, Int) -> Void] = [:]

    // MARK: - Initialization

    public init(
        databaseName: String = "RavenSyncQueue",
        retryConfig: RetryConfig = .default
    ) {
        self.retryConfig = retryConfig

        // Configure IndexedDB storage
        let storeConfig = IndexedDB.StoreConfig(
            name: storeName,
            keyPath: "id",
            autoIncrement: false,
            indexes: [
                IndexedDB.IndexConfig(name: "timestamp", keyPath: "timestamp"),
                IndexedDB.IndexConfig(name: "priority", keyPath: "priority"),
                IndexedDB.IndexConfig(name: "type", keyPath: "type")
            ]
        )

        self.storage = IndexedDB(name: databaseName, version: 1, stores: [storeConfig])

        // Set up network observer
        setupNetworkObserver()

        // Load queue from storage
        Task {
            await loadQueue()
        }
    }

    // MARK: - Queue Operations

    /// Add an operation to the queue
    /// - Parameters:
    ///   - operation: Operation to queue
    ///   - completion: Optional callback for operation completion
    public func enqueue(
        _ operation: QueuedOperation,
        completion: (@Sendable @MainActor (Result<Void, Error>) -> Void)? = nil
    ) async {
        // Store completion callback if provided
        if let completion = completion {
            completionCallbacks[operation.id] = completion
        }

        // Add to in-memory queue
        queue.append(operation)
        sortQueue()

        // Persist to storage
        do {
            try await storage.open()
            try await storage.put(to: storeName, value: encodeOperation(operation), key: operation.id)
        } catch {
            // Failed to persist, but keep in memory
        }

        // Try to sync if online
        if NetworkState.shared.isOnline {
            await startSync()
        }
    }

    /// Remove an operation from the queue
    /// - Parameter operationId: ID of the operation to remove
    public func dequeue(_ operationId: String) async {
        queue.removeAll { $0.id == operationId }

        do {
            try await storage.open()
            try await storage.delete(from: storeName, key: operationId)
        } catch {
            // Failed to delete from storage
        }

        completionCallbacks.removeValue(forKey: operationId)
    }

    /// Get all queued operations
    /// - Returns: Array of queued operations
    public func getAllOperations() -> [QueuedOperation] {
        queue
    }

    /// Get operations by type
    /// - Parameter type: Operation type to filter by
    /// - Returns: Array of matching operations
    public func getOperations(ofType type: String) -> [QueuedOperation] {
        queue.filter { $0.type == type }
    }

    /// Clear all operations from the queue
    public func clearQueue() async {
        queue.removeAll()
        completionCallbacks.removeAll()

        do {
            try await storage.open()
            try await storage.clear(storeName: storeName)
        } catch {
            // Failed to clear storage
        }
    }

    /// Get the number of queued operations
    public var count: Int {
        queue.count
    }

    // MARK: - Sync Operations

    /// Manually trigger sync of queued operations
    public func startSync() async {
        guard !isSyncing else { return }
        guard NetworkState.shared.isOnline else { return }
        guard !queue.isEmpty else { return }

        isSyncing = true

        let total = queue.count
        var processed = 0

        // Process operations in priority order
        let sortedQueue = queue.sorted { lhs, rhs in
            if lhs.priority != rhs.priority {
                return lhs.priority > rhs.priority
            }
            return lhs.timestamp < rhs.timestamp
        }

        for operation in sortedQueue {
            guard NetworkState.shared.isOnline else {
                break
            }

            let result = await processOperation(operation)

            processed += 1
            notifyProgress(processed: processed, total: total)

            switch result {
            case .success:
                // Remove from queue
                await dequeue(operation.id)

                // Notify completion callback
                if let callback = completionCallbacks[operation.id] {
                    callback(.success(()))
                    completionCallbacks.removeValue(forKey: operation.id)
                }

            case .failure(let error):
                // Update retry count
                var updatedOperation = operation
                updatedOperation.retryCount += 1
                updatedOperation.lastRetry = Date()

                // Check if max retries reached
                if updatedOperation.retryCount >= retryConfig.maxRetries {
                    // Remove from queue
                    await dequeue(operation.id)

                    // Notify completion callback with error
                    if let callback = completionCallbacks[operation.id] {
                        callback(.failure(error))
                        completionCallbacks.removeValue(forKey: operation.id)
                    }
                } else {
                    // Update operation in queue
                    if let index = queue.firstIndex(where: { $0.id == operation.id }) {
                        queue[index] = updatedOperation
                    }

                    // Persist updated operation
                    do {
                        try await storage.open()
                        try await storage.put(to: storeName, value: encodeOperation(updatedOperation), key: updatedOperation.id)
                    } catch {
                        // Failed to persist
                    }

                    // Wait before next retry
                    let delay = calculateRetryDelay(retryCount: updatedOperation.retryCount)
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }

        isSyncing = false
    }

    /// Register callback for sync progress
    /// - Parameter callback: Closure called with (processed, total)
    /// - Returns: Token for unregistering the callback
    public func onSyncProgress(
        _ callback: @escaping @Sendable @MainActor (Int, Int) -> Void
    ) -> UUID {
        let id = UUID()
        progressCallbacks[id] = callback
        return id
    }

    /// Unregister a progress callback
    /// - Parameter token: Token returned from registration
    public func removeProgressCallback(_ token: UUID) {
        progressCallbacks.removeValue(forKey: token)
    }

    // MARK: - Private Methods

    private func loadQueue() async {
        do {
            try await storage.open()
            let operations = try await storage.getAll(from: storeName)

            queue = operations.compactMap { decodeOperation($0) }
            sortQueue()

            // Auto-sync if online
            if NetworkState.shared.isOnline {
                await startSync()
            }
        } catch {
            // Failed to load queue
        }
    }

    private func sortQueue() {
        queue.sort { lhs, rhs in
            if lhs.priority != rhs.priority {
                return lhs.priority > rhs.priority
            }
            return lhs.timestamp < rhs.timestamp
        }
    }

    private func setupNetworkObserver() {
        networkToken = NetworkState.shared.onOnlineStatusChange { [weak self] isOnline in
            guard let self = self, isOnline else { return }

            Task {
                await self.startSync()
            }
        }
    }

    private func processOperation(_ operation: QueuedOperation) async -> Result<Void, Error> {
        do {
            // Build request options
            let requestOptions = JSObject.global.Object.function!.new()
            requestOptions.method = .string(operation.method)

            // Add headers
            if !operation.headers.isEmpty {
                let jsHeaders = JSObject.global.Object.function!.new()
                for (key, value) in operation.headers {
                    jsHeaders[dynamicMember: key] = .string(value)
                }
                requestOptions.headers = .object(jsHeaders)
            }

            // Add body
            if let body = operation.body {
                requestOptions.body = .string(body)
            }

            // Make request
            guard let fetchFunc = JSObject.global.fetch.function else {
                throw SyncQueueError.invalidResponse
            }
            let promiseValue = fetchFunc(operation.url, requestOptions)
            guard let promiseObject = promiseValue.object else {
                throw SyncQueueError.invalidResponse
            }

            let response = try await JSPromise(promiseObject)!.getValue()

            guard let responseObject = response.object else {
                throw SyncQueueError.invalidResponse
            }

            // Check response status
            guard responseObject.ok.boolean == true else {
                let status = responseObject.status.number ?? 0
                throw SyncQueueError.httpError(Int(status))
            }

            return .success(())
        } catch {
            return .failure(error)
        }
    }

    private func calculateRetryDelay(retryCount: Int) -> TimeInterval {
        let delay = retryConfig.initialDelay * pow(retryConfig.backoffMultiplier, Double(retryCount))
        return min(delay, retryConfig.maxDelay)
    }

    private func notifyProgress(processed: Int, total: Int) {
        for callback in progressCallbacks.values {
            callback(processed, total)
        }
    }

    private func encodeOperation(_ operation: QueuedOperation) -> [String: Any] {
        var dict: [String: Any] = [
            "id": operation.id,
            "type": operation.type,
            "url": operation.url,
            "method": operation.method,
            "headers": operation.headers,
            "timestamp": operation.timestamp.timeIntervalSince1970,
            "priority": operation.priority,
            "retryCount": operation.retryCount
        ]

        if let body = operation.body {
            dict["body"] = body
        }

        if let lastRetry = operation.lastRetry {
            dict["lastRetry"] = lastRetry.timeIntervalSince1970
        }

        return dict
    }

    private func decodeOperation(_ dict: [String: Any]) -> QueuedOperation? {
        guard let id = dict["id"] as? String,
              let type = dict["type"] as? String,
              let url = dict["url"] as? String,
              let method = dict["method"] as? String,
              let headers = dict["headers"] as? [String: String],
              let _ = dict["timestamp"] as? Double,
              let priority = dict["priority"] as? Int,
              let retryCount = dict["retryCount"] as? Int else {
            return nil
        }

        let body = dict["body"] as? String

        var operation = QueuedOperation(
            id: id,
            type: type,
            url: url,
            method: method,
            headers: headers,
            body: body,
            priority: priority,
            retryCount: retryCount
        )

        if let lastRetryValue = dict["lastRetry"] as? Double {
            operation.lastRetry = Date(timeIntervalSince1970: lastRetryValue)
        }

        return operation
    }

    // MARK: - Cleanup

    deinit {
        // Note: Cleanup of network callbacks and storage happens automatically
        // when the object is deallocated. Direct cleanup calls from deinit
        // would require complex actor isolation handling.
        if let token = networkToken {
            Task { @MainActor in
                NetworkState.shared.removeCallback(token)
            }
        }
        storage.close()
    }
}

// MARK: - Errors

/// Errors that can occur during sync queue operations
public enum SyncQueueError: Error, Sendable {
    case invalidResponse
    case httpError(Int)
    case networkUnavailable
    case maxRetriesExceeded
}
