import Foundation
import JavaScriptKit

/// Central coordinator for offline functionality.
///
/// `OfflineManager` integrates all offline components (Service Worker, Cache, IndexedDB, Sync)
/// to provide a unified offline-first experience. It manages the lifecycle of offline features
/// and coordinates between different subsystems.
@MainActor
public final class OfflineManager: @unchecked Sendable {
    /// Singleton instance for global offline management
    public static let shared = OfflineManager()

    // MARK: - Configuration

    /// Configuration for offline functionality
    public struct Configuration: Sendable {
        public let enableServiceWorker: Bool
        public let enableIndexedDB: Bool
        public let enableBackgroundSync: Bool
        public let cacheVersion: String
        public let defaultCacheStrategy: CacheStrategy
        public let cleanupPolicy: CacheControl.CleanupPolicy
        public let syncRetryConfig: SyncQueue.RetryConfig

        public static let `default` = Configuration(
            enableServiceWorker: true,
            enableIndexedDB: true,
            enableBackgroundSync: true,
            cacheVersion: "v1",
            defaultCacheStrategy: CacheStrategyFactory.staleWhileRevalidate(),
            cleanupPolicy: .default,
            syncRetryConfig: .default
        )

        public init(
            enableServiceWorker: Bool,
            enableIndexedDB: Bool,
            enableBackgroundSync: Bool,
            cacheVersion: String,
            defaultCacheStrategy: CacheStrategy,
            cleanupPolicy: CacheControl.CleanupPolicy,
            syncRetryConfig: SyncQueue.RetryConfig
        ) {
            self.enableServiceWorker = enableServiceWorker
            self.enableIndexedDB = enableIndexedDB
            self.enableBackgroundSync = enableBackgroundSync
            self.cacheVersion = cacheVersion
            self.defaultCacheStrategy = defaultCacheStrategy
            self.cleanupPolicy = cleanupPolicy
            self.syncRetryConfig = syncRetryConfig
        }
    }

    /// Offline status
    public enum Status: Sendable {
        case online
        case offline
        case syncing
    }

    // MARK: - Properties

    /// Current configuration
    private(set) var configuration: Configuration

    /// Service worker manager
    public let serviceWorker: ServiceWorkerManager

    /// Network state monitor
    public let networkState: NetworkState

    /// Cache control
    public let cacheControl: CacheControl

    /// Sync queue
    public let syncQueue: SyncQueue

    /// Background sync
    public let backgroundSync: OfflineBackgroundSync

    /// Current offline status
    private(set) var status: Status

    /// Whether offline manager is initialized
    private(set) var isInitialized: Bool = false

    /// Status change callbacks
    private var statusCallbacks: [UUID: @Sendable @MainActor (Status) -> Void] = [:]

    /// Network observer token
    private var networkToken: UUID?

    // MARK: - Initialization

    private init() {
        self.configuration = .default
        self.serviceWorker = ServiceWorkerManager.shared
        self.networkState = NetworkState.shared
        self.cacheControl = CacheControl(version: Configuration.default.cacheVersion, cleanupPolicy: Configuration.default.cleanupPolicy)
        self.syncQueue = SyncQueue(retryConfig: Configuration.default.syncRetryConfig)
        self.backgroundSync = OfflineBackgroundSync.shared
        self.status = networkState.isOnline ? .online : .offline
    }

    // MARK: - Lifecycle

    /// Initialize offline functionality with custom configuration
    /// - Parameter configuration: Configuration to use
    public func initialize(with configuration: Configuration = .default) async {
        guard !isInitialized else { return }

        self.configuration = configuration

        // Initialize service worker if enabled
        if configuration.enableServiceWorker && serviceWorker.isSupported {
            await initializeServiceWorker()
        }

        // Set up network monitoring
        setupNetworkMonitoring()

        // Schedule periodic cleanup
        schedulePeriodicCleanup()

        isInitialized = true
    }

    /// Shutdown offline functionality
    public func shutdown() {
        // Remove network observer
        if let token = networkToken {
            networkState.removeCallback(token)
            networkToken = nil
        }

        // Clear callbacks
        statusCallbacks.removeAll()

        isInitialized = false
    }

    // MARK: - Service Worker

    private func initializeServiceWorker() async {
        // Register service worker with the script path
        // In production, this should point to your actual service worker file
        _ = await serviceWorker.register(scriptURL: "/sw.js", scope: "/")

        // Set up service worker update handling
        _ = serviceWorker.onUpdate { updateStatus in

            switch updateStatus {
            case .updateAvailable:
                // Notify app about update
                break
            case .updateReady:
                // New service worker is ready
                break
            case .noUpdate:
                break
            }
        }
    }

    // MARK: - Network Monitoring

    private func setupNetworkMonitoring() {
        networkToken = networkState.onOnlineStatusChange { [weak self] isOnline in
            guard let self = self else { return }

            let newStatus: Status = isOnline ? .online : .offline
            self.updateStatus(newStatus)

            // Start sync when coming online
            if isOnline {
                Task {
                    await self.syncQueue.startSync()
                }
            }
        }

        // Also monitor sync queue progress
        _ = syncQueue.onSyncProgress { [weak self] processed, total in
            guard let self = self else { return }

            if processed > 0 && processed < total {
                self.updateStatus(.syncing)
            } else if processed == total && self.networkState.isOnline {
                self.updateStatus(.online)
            }
        }
    }

    private func updateStatus(_ newStatus: Status) {
        let oldStatus = status
        status = newStatus

        if oldStatus != newStatus {
            for callback in statusCallbacks.values {
                callback(newStatus)
            }
        }
    }

    // MARK: - Cache Management

    /// Get cache storage with the configured default strategy
    /// - Parameter cacheName: Name of the cache
    /// - Returns: Cache object
    public func getCache(named cacheName: String) async throws -> JSObject {
        let caches = JSObject.global.caches
        let promiseValue = caches.open(cacheName)

        guard let promiseObject = promiseValue.object else {
            throw OfflineError.cacheNotAvailable
        }

        let cache = try await JSPromise(promiseObject)!.getValue()

        guard let cacheObject = cache.object else {
            throw OfflineError.cacheNotAvailable
        }

        return cacheObject
    }

    /// Fetch a resource using the configured cache strategy
    /// - Parameters:
    ///   - url: URL to fetch
    ///   - cacheName: Cache to use
    ///   - strategy: Optional custom strategy (uses default if not provided)
    /// - Returns: Response object
    public func fetch(
        url: String,
        cacheName: String = "raven-cache",
        strategy: CacheStrategy? = nil
    ) async throws -> JSObject? {
        let cache = try await getCache(named: cacheName)
        let request = JSObject.global.Request.function!.new(url)

        let usedStrategy = strategy ?? configuration.defaultCacheStrategy
        return try await usedStrategy.handle(request: request, cache: cache)
    }

    /// Precache a list of URLs
    /// - Parameters:
    ///   - urls: URLs to precache
    ///   - cacheName: Cache to store in
    public func precache(urls: [String], cacheName: String = "raven-cache") async {
        guard let cache = try? await getCache(named: cacheName) else {
            return
        }

        for url in urls {
            do {
                // Fetch the resource
                guard let fetchFunc = JSObject.global.fetch.function else { continue }
                let promise = fetchFunc(url)
                let response = try await JSPromise(promise.object!)!.getValue()

                guard let responseObject = response.object else { continue }

                // Cache it
                guard let putFunc = cache.put.function else { continue }
                let putPromise = putFunc(url, responseObject)
                _ = try await JSPromise(putPromise.object!)!.getValue()

                // Store metadata
                let metadata = CacheControl.CacheMetadata(
                    url: url,
                    timestamp: Date(),
                    version: configuration.cacheVersion
                )
                await cacheControl.setMetadata(metadata)
            } catch {
                // Failed to precache this URL, continue with others
                continue
            }
        }
    }

    /// Clear cache and metadata
    /// - Parameter cacheName: Optional specific cache to clear
    public func clearCache(named cacheName: String? = nil) async {
        if let cacheName = cacheName {
            do {
                let caches = JSObject.global.caches
                let deletePromiseValue = caches.delete(cacheName)
                if let deletePromise = deletePromiseValue.object {
                    _ = try await JSPromise(deletePromise)!.getValue()
                }
            } catch {
                // Failed to clear cache
            }
        } else {
            await cacheControl.clearAll()
        }
    }

    // MARK: - Data Storage

    /// Store data in IndexedDB
    /// - Parameters:
    ///   - key: Storage key
    ///   - value: Value to store
    ///   - database: Optional custom database name
    public func storeData(key: String, value: [String: Any], database: String? = nil) async throws {
        guard configuration.enableIndexedDB else {
            throw OfflineError.indexedDBNotEnabled
        }

        let dbName = database ?? "RavenOfflineData"
        let storeConfig = IndexedDB.StoreConfig(name: "data", keyPath: "key")
        let db = IndexedDB(name: dbName, version: 1, stores: [storeConfig])

        try await db.open()
        var dataWithKey = value
        dataWithKey["key"] = key
        try await db.put(to: "data", value: dataWithKey, key: key)
        db.close()
    }

    /// Retrieve data from IndexedDB
    /// - Parameters:
    ///   - key: Storage key
    ///   - database: Optional custom database name
    /// - Returns: Stored value if found
    ///
    /// TEMPORARILY COMMENTED OUT: Depends on IndexedDB.get() which has JSClosure issues
    /*
    public func retrieveData(key: String, database: String? = nil) async throws -> [String: Any]? {
        guard configuration.enableIndexedDB else {
            throw OfflineError.indexedDBNotEnabled
        }

        let dbName = database ?? "RavenOfflineData"
        let storeConfig = IndexedDB.StoreConfig(name: "data", keyPath: "key")
        let db = IndexedDB(name: dbName, version: 1, stores: [storeConfig])

        try await db.open()
        let data = try await db.get(from: "data", key: key)
        db.close()

        return data
    }
    */

    /// Delete data from IndexedDB
    /// - Parameters:
    ///   - key: Storage key
    ///   - database: Optional custom database name
    public func deleteData(key: String, database: String? = nil) async throws {
        guard configuration.enableIndexedDB else {
            throw OfflineError.indexedDBNotEnabled
        }

        let dbName = database ?? "RavenOfflineData"
        let storeConfig = IndexedDB.StoreConfig(name: "data", keyPath: "key")
        let db = IndexedDB(name: dbName, version: 1, stores: [storeConfig])

        try await db.open()
        try await db.delete(from: "data", key: key)
        db.close()
    }

    // MARK: - Sync Operations

    /// Queue an operation for sync
    /// - Parameters:
    ///   - operation: Operation to queue
    ///   - completion: Optional completion handler
    public func queueOperation(
        _ operation: SyncQueue.QueuedOperation,
        completion: (@Sendable @MainActor (Result<Void, Error>) -> Void)? = nil
    ) async {
        await syncQueue.enqueue(operation, completion: completion)
    }

    /// Manually trigger sync
    public func sync() async {
        updateStatus(.syncing)
        await syncQueue.startSync()

        if networkState.isOnline {
            updateStatus(.online)
        }
    }

    // MARK: - Periodic Cleanup

    private func schedulePeriodicCleanup() {
        // Schedule cleanup every hour
        Task {
            while isInitialized {
                try? await Task.sleep(nanoseconds: 3600_000_000_000) // 1 hour

                if isInitialized {
                    await performCleanup()
                }
            }
        }
    }

    private func performCleanup() async {
        // Clean up all known caches
        await cacheControl.performCleanup(for: "raven-cache")

        // Clean up old versions
        await cacheControl.cleanupOldVersions()
    }

    // MARK: - Status Callbacks

    /// Register callback for status changes
    /// - Parameter callback: Closure called with new status
    /// - Returns: Token for unregistering the callback
    public func onStatusChange(
        _ callback: @escaping @Sendable @MainActor (Status) -> Void
    ) -> UUID {
        let id = UUID()
        statusCallbacks[id] = callback
        return id
    }

    /// Unregister a status callback
    /// - Parameter token: Token returned from registration
    public func removeStatusCallback(_ token: UUID) {
        statusCallbacks.removeValue(forKey: token)
    }

    // MARK: - Utility Methods

    /// Check if offline mode is available
    public var isOfflineModeAvailable: Bool {
        (configuration.enableServiceWorker && serviceWorker.isSupported) ||
        configuration.enableIndexedDB
    }

    /// Get current network information
    public var networkInfo: NetworkState.ConnectionInfo {
        networkState.currentInfo
    }

    /// Get sync queue statistics
    public var syncQueueStats: (pending: Int, total: Int) {
        (pending: syncQueue.count, total: syncQueue.count)
    }
}

// MARK: - Errors

/// Errors that can occur during offline operations
public enum OfflineError: Error, Sendable {
    case notInitialized
    case serviceWorkerNotAvailable
    case cacheNotAvailable
    case indexedDBNotEnabled
    case networkUnavailable
    case operationFailed
}

// MARK: - Convenience Extensions

extension OfflineManager {
    /// Enable offline mode for the app
    public func enableOfflineMode() async {
        await initialize(with: configuration)
    }

    /// Check if currently offline
    public var isOffline: Bool {
        !networkState.isOnline
    }

    /// Check if currently online
    public var isOnline: Bool {
        networkState.isOnline
    }

    /// Force update cache version (triggers cleanup of old caches)
    public func updateCacheVersion(_ version: String) async {
        var newConfig = configuration
        newConfig = Configuration(
            enableServiceWorker: newConfig.enableServiceWorker,
            enableIndexedDB: newConfig.enableIndexedDB,
            enableBackgroundSync: newConfig.enableBackgroundSync,
            cacheVersion: version,
            defaultCacheStrategy: newConfig.defaultCacheStrategy,
            cleanupPolicy: newConfig.cleanupPolicy,
            syncRetryConfig: newConfig.syncRetryConfig
        )
        configuration = newConfig

        await cacheControl.updateVersion(version)
    }
}
