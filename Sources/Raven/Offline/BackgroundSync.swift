import Foundation
import JavaScriptKit

/// Wrapper for the Background Sync API for deferred operations.
///
/// `OfflineBackgroundSync` provides a Swift interface to the Background Sync API,
/// allowing operations to be deferred until the user has stable network connectivity.
@MainActor
public final class OfflineBackgroundSync: @unchecked Sendable {
    /// Singleton instance for global background sync management
    public static let shared = OfflineBackgroundSync()

    // MARK: - Properties

    /// Whether Background Sync API is supported
    public let isSupported: Bool

    /// Service worker registration for sync
    private var registration: JSObject?

    /// Callbacks for sync events by tag
    private var syncCallbacks: [String: @Sendable @MainActor () async -> Void] = [:]

    /// Pending sync tags
    private var pendingSyncTags: Set<String> = []

    // MARK: - Initialization

    private init() {
        // Check if Background Sync is supported
        let navigator = JSObject.global.navigator
        self.isSupported = !navigator.serviceWorker.isUndefined

        if isSupported {
            setupServiceWorker()
        }
    }

    // MARK: - Sync Registration

    /// Register a background sync
    /// - Parameters:
    ///   - tag: Unique identifier for this sync
    ///   - handler: Closure to execute when sync fires
    /// - Returns: True if registration was successful
    @discardableResult
    public func register(
        tag: String,
        handler: @escaping @Sendable @MainActor () async -> Void
    ) async -> Bool {
        guard isSupported else {
            return false
        }

        // Store handler for this tag
        syncCallbacks[tag] = handler

        // Get service worker registration
        guard let registration = await getServiceWorkerRegistration() else {
            return false
        }

        // Check if sync manager is available
        guard !registration.sync.isUndefined else {
            return false
        }

        do {
            // Check if sync manager is available
            guard let syncManager = registration.sync.object else {
                return false
            }

            // Register the sync
            guard let registerFunc = syncManager.register.function else {
                return false
            }
            let promise = registerFunc(tag)
            _ = try await JSPromise(promise.object!)!.getValue()

            pendingSyncTags.insert(tag)
            return true
        } catch {
            return false
        }
    }

    /// Get all registered sync tags
    /// - Returns: Array of registered tag names
    public func getTags() async -> [String] {
        guard isSupported else {
            return []
        }

        guard let registration = await getServiceWorkerRegistration() else {
            return []
        }

        guard !registration.sync.isUndefined else {
            return []
        }

        do {
            guard let syncManager = registration.sync.object else {
                return []
            }
            guard let getTagsFunc = syncManager.getTags.function else {
                return []
            }
            let promise = getTagsFunc()
            let tags = try await JSPromise(promise.object!)!.getValue()

            guard let tagsArray = tags.object else {
                return []
            }

            let length = tagsArray.length.number ?? 0
            var result: [String] = []

            for i in 0..<Int(length) {
                if let tag = tagsArray[i].string {
                    result.append(tag)
                }
            }

            return result
        } catch {
            return []
        }
    }

    /// Check if a specific sync is registered
    /// - Parameter tag: Tag to check
    /// - Returns: True if the sync is registered
    public func isRegistered(tag: String) async -> Bool {
        let tags = await getTags()
        return tags.contains(tag)
    }

    /// Unregister a sync callback
    /// - Parameter tag: Tag to unregister
    public func unregister(tag: String) {
        syncCallbacks.removeValue(forKey: tag)
        pendingSyncTags.remove(tag)
    }

    // MARK: - Sync Execution

    /// Handle a sync event (called by service worker message)
    /// - Parameter tag: Tag of the sync to execute
    internal func handleSync(tag: String) async {
        guard let handler = syncCallbacks[tag] else {
            return
        }

        await handler()
        pendingSyncTags.remove(tag)
    }

    // MARK: - Periodic Background Sync

    /// Register a periodic background sync (if supported)
    /// - Parameters:
    ///   - tag: Unique identifier for this sync
    ///   - minInterval: Minimum interval between syncs in milliseconds
    ///   - handler: Closure to execute when sync fires
    /// - Returns: True if registration was successful
    @discardableResult
    public func registerPeriodicSync(
        tag: String,
        minInterval: Int,
        handler: @escaping @Sendable @MainActor () async -> Void
    ) async -> Bool {
        guard isSupported else {
            return false
        }

        // Store handler for this tag
        syncCallbacks[tag] = handler

        // Get service worker registration
        guard let registration = await getServiceWorkerRegistration() else {
            return false
        }

        // Check if periodic sync is available
        guard !registration.periodicSync.isUndefined else {
            return false
        }

        do {
            // Register the periodic sync
            guard let periodicSync = registration.periodicSync.object else {
                return false
            }
            let options = JSObject.global.Object.function!.new()
            options.minInterval = .number(Double(minInterval))
            guard let registerFunc = periodicSync.register.function else {
                return false
            }
            let promise = registerFunc(tag, options)
            _ = try await JSPromise(promise.object!)!.getValue()

            return true
        } catch {
            return false
        }
    }

    /// Unregister a periodic background sync
    /// - Parameter tag: Tag to unregister
    /// - Returns: True if unregistration was successful
    @discardableResult
    public func unregisterPeriodicSync(tag: String) async -> Bool {
        guard isSupported else {
            return false
        }

        guard let registration = await getServiceWorkerRegistration() else {
            return false
        }

        guard !registration.periodicSync.isUndefined else {
            return false
        }

        do {
            guard let periodicSync = registration.periodicSync.object else {
                return false
            }
            guard let unregisterFunc = periodicSync.unregister.function else {
                return false
            }
            let promise = unregisterFunc(tag)
            _ = try await JSPromise(promise.object!)!.getValue()

            syncCallbacks.removeValue(forKey: tag)
            return true
        } catch {
            return false
        }
    }

    /// Get all registered periodic sync tags
    /// - Returns: Array of registered periodic tag names
    public func getPeriodicTags() async -> [String] {
        guard isSupported else {
            return []
        }

        guard let registration = await getServiceWorkerRegistration() else {
            return []
        }

        guard !registration.periodicSync.isUndefined else {
            return []
        }

        do {
            guard let periodicSync = registration.periodicSync.object else {
                return []
            }
            guard let getTagsFunc = periodicSync.getTags.function else {
                return []
            }
            let promise = getTagsFunc()
            let tags = try await JSPromise(promise.object!)!.getValue()

            guard let tagsArray = tags.object else {
                return []
            }

            let length = tagsArray.length.number ?? 0
            var result: [String] = []

            for i in 0..<Int(length) {
                if let tag = tagsArray[i].string {
                    result.append(tag)
                }
            }

            return result
        } catch {
            return []
        }
    }

    // MARK: - Common Sync Operations

    /// Register a one-time sync for a network operation
    /// - Parameters:
    ///   - operationId: Unique identifier for the operation
    ///   - operation: The operation to perform
    /// - Returns: True if registration was successful
    @discardableResult
    public func syncOperation(
        operationId: String,
        operation: @escaping @Sendable @MainActor () async throws -> Void
    ) async -> Bool {
        await register(tag: "operation-\(operationId)") {
            do {
                try await operation()
            } catch {
                // Operation failed, it will be retried on next sync
            }
        }
    }

    /// Register a periodic data sync
    /// - Parameters:
    ///   - dataType: Type of data to sync
    ///   - intervalMinutes: Interval in minutes
    ///   - syncHandler: Handler to perform the sync
    /// - Returns: True if registration was successful
    @discardableResult
    public func periodicDataSync(
        dataType: String,
        intervalMinutes: Int,
        syncHandler: @escaping @Sendable @MainActor () async throws -> Void
    ) async -> Bool {
        let minInterval = intervalMinutes * 60 * 1000 // Convert to milliseconds

        return await registerPeriodicSync(
            tag: "data-sync-\(dataType)",
            minInterval: minInterval
        ) {
            do {
                try await syncHandler()
            } catch {
                // Sync failed, will retry on next interval
            }
        }
    }

    // MARK: - Private Methods

    private func setupServiceWorker() {
        Task {
            // Wait for service worker to be ready
            guard let registration = await getServiceWorkerRegistration() else {
                return
            }

            self.registration = registration

            // Set up message listener for sync events from service worker
            let navigator = JSObject.global.navigator
            guard let serviceWorker = navigator.serviceWorker.object else { return }

            let messageHandler = JSClosure { [weak self] args in
                Task { @MainActor in
                    guard let self = self,
                          let event = args.first?.object,
                          let data = event.data.object,
                          let type = data.type.string,
                          type == "BACKGROUND_SYNC",
                          let tag = data.tag.string else {
                        return
                    }

                    await self.handleSync(tag: tag)
                }
                return .undefined
            }

            guard let addEventListenerFunc = serviceWorker.addEventListener.function else { return }
            _ = addEventListenerFunc("message", messageHandler)
        }
    }

    private func getServiceWorkerRegistration() async -> JSObject? {
        if let registration = registration {
            return registration
        }

        let navigator = JSObject.global.navigator
        guard let serviceWorker = navigator.serviceWorker.object else { return nil }

        do {
            let promise = serviceWorker.ready
            let reg = try await JSPromise(promise.object!)!.getValue()

            if let regObject = reg.object {
                self.registration = regObject
                return regObject
            }

            return nil
        } catch {
            return nil
        }
    }
}

// MARK: - Convenience Extensions

extension OfflineBackgroundSync {
    /// Register a sync for uploading data
    /// - Parameters:
    ///   - uploadId: Unique identifier for the upload
    ///   - uploadHandler: Handler to perform the upload
    /// - Returns: True if registration was successful
    @discardableResult
    public func syncUpload(
        uploadId: String,
        uploadHandler: @escaping @Sendable @MainActor () async throws -> Void
    ) async -> Bool {
        await syncOperation(operationId: "upload-\(uploadId)", operation: uploadHandler)
    }

    /// Register a sync for downloading data
    /// - Parameters:
    ///   - downloadId: Unique identifier for the download
    ///   - downloadHandler: Handler to perform the download
    /// - Returns: True if registration was successful
    @discardableResult
    public func syncDownload(
        downloadId: String,
        downloadHandler: @escaping @Sendable @MainActor () async throws -> Void
    ) async -> Bool {
        await syncOperation(operationId: "download-\(downloadId)", operation: downloadHandler)
    }

    /// Register a sync for analytics
    /// - Parameter analyticsHandler: Handler to send analytics
    /// - Returns: True if registration was successful
    @discardableResult
    public func syncAnalytics(
        analyticsHandler: @escaping @Sendable @MainActor () async throws -> Void
    ) async -> Bool {
        await syncOperation(operationId: "analytics", operation: analyticsHandler)
    }
}

// MARK: - Errors

/// Errors that can occur during background sync operations
public enum BackgroundSyncError: Error, Sendable {
    case notSupported
    case registrationFailed
    case serviceWorkerNotReady
    case syncFailed
}
