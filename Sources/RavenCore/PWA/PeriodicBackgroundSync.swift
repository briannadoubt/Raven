import Foundation
import JavaScriptKit

/// Manages periodic background sync for PWAs
///
/// PeriodicBackgroundSync enables PWAs to synchronize data in the background
/// at regular intervals, even when the app is not running, providing a
/// native-like experience for keeping content fresh.
///
/// Example usage:
/// ```swift
/// let sync = PeriodicBackgroundSync()
///
/// // Check if supported
/// if sync.isSupported {
///     // Register periodic sync
///     try await sync.register(
///         tag: "content-sync",
///         minInterval: 24 * 60 * 60 * 1000 // 24 hours in milliseconds
///     )
///
///     // Check registration
///     let tags = try await sync.getTags()
///     print("Registered syncs: \(tags)")
///
///     // Unregister when no longer needed
///     try await sync.unregister(tag: "content-sync")
/// }
/// ```
///
/// Note: Actual sync execution happens in the service worker via the
/// `periodicsync` event. This manager handles registration only.
@MainActor
public final class PeriodicBackgroundSync: Sendable {

    // MARK: - Properties

    /// Service worker registration
    private var registration: JSObject?

    /// Whether periodic background sync is supported
    public var isSupported: Bool {
        get async {
            await ensureRegistration()
            return registration?.periodicSync != nil && !registration!.periodicSync.isUndefined
        }
    }

    /// Active sync registrations (cached)
    private var cachedTags: Set<String> = []

    // MARK: - Initialization

    public init() {
        Task {
            await ensureRegistration()
            await loadCachedTags()
        }
    }

    // MARK: - Registration

    /// Register a periodic background sync
    /// - Parameters:
    ///   - tag: Unique identifier for this sync
    ///   - minInterval: Minimum interval between syncs in milliseconds
    /// - Throws: SyncError if registration fails
    public func register(tag: String, minInterval: Int) async throws {
        guard let registration = registration else {
            throw SyncError.serviceWorkerNotAvailable
        }

        guard let periodicSync = registration.periodicSync.object else {
            throw SyncError.notSupported
        }

        // Create options object
        let options = JSObject.global.Object.function!.new()
        options.minInterval = .number(Double(minInterval))

        do {
            let registerPromise = periodicSync.register.function!(tag, options)
            _ = try await JSPromise(from: registerPromise)!.getValue()

            cachedTags.insert(tag)
        } catch {
            throw SyncError.registrationFailed(error.localizedDescription)
        }
    }

    /// Unregister a periodic background sync
    /// - Parameter tag: Tag of the sync to unregister
    /// - Throws: SyncError if unregistration fails
    public func unregister(tag: String) async throws {
        guard let registration = registration else {
            throw SyncError.serviceWorkerNotAvailable
        }

        guard let periodicSync = registration.periodicSync.object else {
            throw SyncError.notSupported
        }

        do {
            let unregisterPromise = periodicSync.unregister.function!(tag)
            _ = try await JSPromise(from: unregisterPromise)!.getValue()

            cachedTags.remove(tag)
        } catch {
            throw SyncError.unregistrationFailed(error.localizedDescription)
        }
    }

    /// Get all registered sync tags
    /// - Returns: Array of registered tags
    /// - Throws: SyncError if fetching fails
    public func getTags() async throws -> [String] {
        guard let registration = registration else {
            throw SyncError.serviceWorkerNotAvailable
        }

        guard let periodicSync = registration.periodicSync.object else {
            throw SyncError.notSupported
        }

        do {
            let getTagsPromise = periodicSync.getTags.function!()
            let result = try await JSPromise(from: getTagsPromise)!.getValue()

            if let tagsArray = result.object {
                let length = Int(tagsArray.length.number ?? 0)
                var tags: [String] = []

                for i in 0..<length {
                    if let tag = tagsArray[i].string {
                        tags.append(tag)
                    }
                }

                // Update cache
                cachedTags = Set(tags)
                return tags
            }

            return []
        } catch {
            throw SyncError.fetchFailed(error.localizedDescription)
        }
    }

    /// Check if a specific tag is registered
    /// - Parameter tag: Tag to check
    /// - Returns: True if tag is registered
    public func isRegistered(tag: String) async throws -> Bool {
        let tags = try await getTags()
        return tags.contains(tag)
    }

    /// Get cached tags (synchronous, may be stale)
    /// - Returns: Set of cached tags
    public func getCachedTags() -> Set<String> {
        cachedTags
    }

    // MARK: - Private Methods

    /// Ensure service worker registration is available
    private func ensureRegistration() async {
        guard registration == nil else { return }

        let navigator = JSObject.global.navigator

        guard let serviceWorker = navigator.serviceWorker.object else {
            print("⚠️ PeriodicBackgroundSync: Service Worker not supported")
            return
        }

        do {
            let readyPromise = serviceWorker.ready
            let reg = try await JSPromise(from: readyPromise)!.getValue()
            registration = reg.object
        } catch {
            print("⚠️ PeriodicBackgroundSync: Failed to get service worker registration")
        }
    }

    /// Load cached tags from service worker
    private func loadCachedTags() async {
        do {
            let tags = try await getTags()
            cachedTags = Set(tags)
        } catch {
            print("⚠️ PeriodicBackgroundSync: Failed to load cached tags")
        }
    }
}

// MARK: - Supporting Types

/// Periodic sync configuration
public struct SyncConfiguration: Sendable {
    /// Unique tag for the sync
    public let tag: String

    /// Minimum interval between syncs in milliseconds
    public let minInterval: Int

    /// Human-readable description
    public let description: String?

    public init(tag: String, minInterval: Int, description: String? = nil) {
        self.tag = tag
        self.minInterval = minInterval
        self.description = description
    }
}

/// Common sync intervals
public enum SyncInterval: Sendable {
    /// Every hour (3600000 ms)
    case hourly

    /// Every 6 hours
    case sixHours

    /// Every 12 hours
    case twelveHours

    /// Daily (86400000 ms)
    case daily

    /// Every 2 days
    case twoDays

    /// Weekly (604800000 ms)
    case weekly

    /// Custom interval in milliseconds
    case custom(Int)

    public var milliseconds: Int {
        switch self {
        case .hourly:
            return 3600000
        case .sixHours:
            return 21600000
        case .twelveHours:
            return 43200000
        case .daily:
            return 86400000
        case .twoDays:
            return 172800000
        case .weekly:
            return 604800000
        case .custom(let ms):
            return ms
        }
    }
}

/// Sync errors
public enum SyncError: Error, Sendable {
    case notSupported
    case serviceWorkerNotAvailable
    case registrationFailed(String)
    case unregistrationFailed(String)
    case fetchFailed(String)
}

// MARK: - One-Time Background Sync

/// Manages one-time background sync (different from periodic sync)
///
/// BackgroundSync provides one-time sync capabilities that retry until successful,
/// useful for ensuring critical operations complete even when offline.
///
/// Example usage:
/// ```swift
/// let bgSync = BackgroundSync()
///
/// // Register one-time sync
/// try await bgSync.register(tag: "upload-data")
///
/// // The service worker will handle the actual sync via 'sync' event
/// ```
@MainActor
public final class BackgroundSync: Sendable {

    // MARK: - Properties

    /// Service worker registration
    private var registration: JSObject?

    /// Whether background sync is supported
    public var isSupported: Bool {
        get async {
            await ensureRegistration()
            return registration?.sync != nil && !registration!.sync.isUndefined
        }
    }

    // MARK: - Initialization

    public init() {
        Task {
            await ensureRegistration()
        }
    }

    // MARK: - Registration

    /// Register a one-time background sync
    /// - Parameter tag: Unique identifier for this sync
    /// - Throws: SyncError if registration fails
    public func register(tag: String) async throws {
        guard let registration = registration else {
            throw SyncError.serviceWorkerNotAvailable
        }

        guard let sync = registration.sync.object else {
            throw SyncError.notSupported
        }

        do {
            let registerPromise = sync.register.function!(tag)
            _ = try await JSPromise(from: registerPromise)!.getValue()
        } catch {
            throw SyncError.registrationFailed(error.localizedDescription)
        }
    }

    /// Get all registered sync tags
    /// - Returns: Array of registered tags
    /// - Throws: SyncError if fetching fails
    public func getTags() async throws -> [String] {
        guard let registration = registration else {
            throw SyncError.serviceWorkerNotAvailable
        }

        guard let sync = registration.sync.object else {
            throw SyncError.notSupported
        }

        do {
            let getTagsPromise = sync.getTags.function!()
            let result = try await JSPromise(from: getTagsPromise)!.getValue()

            if let tagsArray = result.object {
                let length = Int(tagsArray.length.number ?? 0)
                var tags: [String] = []

                for i in 0..<length {
                    if let tag = tagsArray[i].string {
                        tags.append(tag)
                    }
                }

                return tags
            }

            return []
        } catch {
            throw SyncError.fetchFailed(error.localizedDescription)
        }
    }

    // MARK: - Private Methods

    /// Ensure service worker registration is available
    private func ensureRegistration() async {
        guard registration == nil else { return }

        let navigator = JSObject.global.navigator

        guard let serviceWorker = navigator.serviceWorker.object else {
            print("⚠️ BackgroundSync: Service Worker not supported")
            return
        }

        do {
            let readyPromise = serviceWorker.ready
            let reg = try await JSPromise(from: readyPromise)!.getValue()
            registration = reg.object
        } catch {
            print("⚠️ BackgroundSync: Failed to get service worker registration")
        }
    }
}
