import Foundation
import JavaScriptKit

/// Manages cache invalidation, versioning, and expiration policies.
///
/// `CacheControl` provides sophisticated cache management including versioning,
/// size limits, expiration policies, and selective invalidation.
@MainActor
public final class CacheControl: @unchecked Sendable {
    // MARK: - Types

    /// Cache versioning information
    public struct CacheVersion: Sendable, Codable {
        public let version: String
        public let timestamp: Date
        public let cacheNames: [String]

        public init(version: String, timestamp: Date = Date(), cacheNames: [String]) {
            self.version = version
            self.timestamp = timestamp
            self.cacheNames = cacheNames
        }
    }

    /// Cache entry metadata
    public struct CacheMetadata: Sendable, Codable {
        public let url: String
        public let timestamp: Date
        public let expiresAt: Date?
        public let size: Int?
        public let version: String?
        public let tags: [String]

        public init(
            url: String,
            timestamp: Date = Date(),
            expiresAt: Date? = nil,
            size: Int? = nil,
            version: String? = nil,
            tags: [String] = []
        ) {
            self.url = url
            self.timestamp = timestamp
            self.expiresAt = expiresAt
            self.size = size
            self.version = version
            self.tags = tags
        }
    }

    /// Cache cleanup policy
    public struct CleanupPolicy: Sendable {
        public let maxCacheSize: Int64 // in bytes
        public let maxAge: TimeInterval // in seconds
        public let maxEntries: Int

        public static let `default` = CleanupPolicy(
            maxCacheSize: 50 * 1024 * 1024, // 50 MB
            maxAge: 7 * 24 * 60 * 60, // 7 days
            maxEntries: 1000
        )

        public init(maxCacheSize: Int64, maxAge: TimeInterval, maxEntries: Int) {
            self.maxCacheSize = maxCacheSize
            self.maxAge = maxAge
            self.maxEntries = maxEntries
        }
    }

    // MARK: - Properties

    /// Current cache version
    private(set) var currentVersion: CacheVersion

    /// Cleanup policy
    public let cleanupPolicy: CleanupPolicy

    /// IndexedDB for metadata storage
    private let metadataDB: IndexedDB

    /// Cache metadata by URL
    private var metadata: [String: CacheMetadata] = [:]

    // MARK: - Initialization

    public init(
        version: String,
        cleanupPolicy: CleanupPolicy = .default
    ) {
        self.currentVersion = CacheVersion(version: version, timestamp: Date(), cacheNames: [])
        self.cleanupPolicy = cleanupPolicy

        // Set up metadata storage
        let storeConfig = IndexedDB.StoreConfig(
            name: "cacheMetadata",
            keyPath: "url",
            autoIncrement: false,
            indexes: [
                IndexedDB.IndexConfig(name: "timestamp", keyPath: "timestamp"),
                IndexedDB.IndexConfig(name: "version", keyPath: "version")
            ]
        )

        self.metadataDB = IndexedDB(name: "RavenCacheControl", version: 1, stores: [storeConfig])

        Task {
            await loadMetadata()
        }
    }

    // MARK: - Version Management

    /// Update to a new cache version
    /// - Parameter version: New version string
    public func updateVersion(_ version: String) async {
        _ = currentVersion

        // Create new version
        currentVersion = CacheVersion(version: version, timestamp: Date(), cacheNames: [])

        // Clean up old caches
        await cleanupOldVersions(keepingCurrent: true)

        // Clear metadata for old version
        metadata.removeAll()
        await loadMetadata()
    }

    /// Get the current cache version
    public func getVersion() -> String {
        currentVersion.version
    }

    /// Delete all caches from previous versions
    public func cleanupOldVersions(keepingCurrent: Bool = true) async {
        do {
            let caches = JSObject.global.caches

            // Get all cache names
            guard let keysFunc = caches.keys.function else { return }
            let promise = keysFunc()
            let keys = try await JSPromise(promise.object!)!.getValue()

            guard let keysArray = keys.object else { return }

            let length = keysArray.length.number ?? 0

            for i in 0..<Int(length) {
                guard let cacheName = keysArray[i].string else { continue }

                // Skip current version caches if requested
                if keepingCurrent && currentVersion.cacheNames.contains(cacheName) {
                    continue
                }

                // Delete old cache
                guard let deleteFunc = caches.delete.function else { continue }
                let deletePromise = deleteFunc(cacheName)
                _ = try? await JSPromise(deletePromise.object!)!.getValue()
            }
        } catch {
            // Failed to cleanup old versions
        }
    }

    // MARK: - Metadata Management

    /// Store metadata for a cache entry
    /// - Parameter metadata: Metadata to store
    public func setMetadata(_ metadata: CacheMetadata) async {
        self.metadata[metadata.url] = metadata

        do {
            try await metadataDB.open()
            try await metadataDB.put(to: "cacheMetadata", value: encodeMetadata(metadata), key: metadata.url)
        } catch {
            // Failed to persist metadata
        }
    }

    /// Get metadata for a cache entry
    /// - Parameter url: URL of the cache entry
    /// - Returns: Metadata if found
    public func getMetadata(for url: String) -> CacheMetadata? {
        metadata[url]
    }

    /// Remove metadata for a cache entry
    /// - Parameter url: URL of the cache entry
    public func removeMetadata(for url: String) async {
        metadata.removeValue(forKey: url)

        do {
            try await metadataDB.open()
            try await metadataDB.delete(from: "cacheMetadata", key: url)
        } catch {
            // Failed to remove metadata
        }
    }

    /// Get all stored metadata
    /// - Returns: Array of all cache metadata
    public func getAllMetadata() -> [CacheMetadata] {
        Array(metadata.values)
    }

    // MARK: - Expiration Management

    /// Check if a cache entry has expired
    /// - Parameter url: URL of the cache entry
    /// - Returns: True if expired
    public func isExpired(url: String) -> Bool {
        guard let meta = metadata[url] else { return true }

        if let expiresAt = meta.expiresAt {
            return Date() > expiresAt
        }

        // Check against max age
        let age = Date().timeIntervalSince(meta.timestamp)
        return age > cleanupPolicy.maxAge
    }

    /// Remove expired entries from cache
    /// - Parameter cacheName: Name of the cache to clean
    public func removeExpiredEntries(from cacheName: String) async {
        do {
            let caches = JSObject.global.caches
            let cachePromise = caches.open(cacheName)
            let cache = try await JSPromise(cachePromise.object!)!.getValue()

            guard let cacheObject = cache.object else { return }

            // Get all requests from cache
            guard let keysFn = cacheObject[dynamicMember: "keys"].function else { return }
            let keysPromise = keysFn()
            let keys = try await JSPromise(keysPromise.object!)!.getValue()

            guard let keysArray = keys.object else { return }
            let length = keysArray.length.number ?? 0

            for i in 0..<Int(length) {
                guard let request = keysArray[i].object,
                      let url = request.url.string else { continue }

                if isExpired(url: url) {
                    guard let deleteFn = cacheObject[dynamicMember: "delete"].function else { continue }
                    let deletePromise = deleteFn(request)
                    _ = try? await JSPromise(deletePromise.object!)!.getValue()

                    await removeMetadata(for: url)
                }
            }
        } catch {
            // Failed to remove expired entries
        }
    }

    // MARK: - Size Management

    /// Estimate total cache size
    /// - Returns: Estimated size in bytes
    public func estimateCacheSize() async -> Int64 {
        guard let storage = JSObject.global.navigator.storage.object else {
            return 0
        }

        do {
            guard let estimateFn = storage[dynamicMember: "estimate"].function else {
                return 0
            }
            let promise = estimateFn()
            let estimate = try await JSPromise(promise.object!)!.getValue()

            guard let estimateObject = estimate.object,
                  let usage = estimateObject.usage.number else {
                return 0
            }

            return Int64(usage)
        } catch {
            return 0
        }
    }

    /// Remove oldest entries to free up space
    /// - Parameter cacheName: Name of the cache to clean
    /// - Parameter targetSize: Target size in bytes
    public func trimToSize(cacheName: String, targetSize: Int64) async {
        let currentSize = await estimateCacheSize()

        guard currentSize > targetSize else { return }

        // Sort metadata by timestamp (oldest first)
        let sortedMetadata = metadata.values.sorted { $0.timestamp < $1.timestamp }

        do {
            let caches = JSObject.global.caches
            let cachePromise = caches.open(cacheName)
            let cache = try await JSPromise(cachePromise.object!)!.getValue()

            guard let cacheObject = cache.object else { return }

            var removedSize: Int64 = 0
            let targetRemoval = currentSize - targetSize

            for meta in sortedMetadata {
                guard removedSize < targetRemoval else { break }

                // Delete entry
                guard let deleteFn = cacheObject[dynamicMember: "delete"].function else { continue }
                let deletePromise = deleteFn(meta.url)
                if (try? await JSPromise(deletePromise.object!)!.getValue().boolean) == true {
                    removedSize += Int64(meta.size ?? 0)
                    await removeMetadata(for: meta.url)
                }
            }
        } catch {
            // Failed to trim cache
        }
    }

    /// Enforce cache size limits
    /// - Parameter cacheName: Name of the cache to enforce limits on
    public func enforceSizeLimits(for cacheName: String) async {
        let currentSize = await estimateCacheSize()

        if currentSize > cleanupPolicy.maxCacheSize {
            await trimToSize(cacheName: cacheName, targetSize: cleanupPolicy.maxCacheSize)
        }

        // Also check entry count
        if metadata.count > cleanupPolicy.maxEntries {
            await trimToEntryCount(cacheName: cacheName, targetCount: cleanupPolicy.maxEntries)
        }
    }

    // MARK: - Tag-Based Invalidation

    /// Invalidate all cache entries with a specific tag
    /// - Parameters:
    ///   - tag: Tag to invalidate
    ///   - cacheName: Name of the cache
    public func invalidateByTag(_ tag: String, in cacheName: String) async {
        let matchingMetadata = metadata.values.filter { $0.tags.contains(tag) }

        do {
            let caches = JSObject.global.caches
            let cachePromise = caches.open(cacheName)
            let cache = try await JSPromise(cachePromise.object!)!.getValue()

            guard let cacheObject = cache.object else { return }

            for meta in matchingMetadata {
                let deletePromise = cacheObject.delete!(meta.url)
                _ = try? await JSPromise(deletePromise.object!)!.getValue()

                await removeMetadata(for: meta.url)
            }
        } catch {
            // Failed to invalidate by tag
        }
    }

    /// Invalidate all cache entries matching a URL pattern
    /// - Parameters:
    ///   - pattern: URL pattern (supports wildcards)
    ///   - cacheName: Name of the cache
    public func invalidateByPattern(_ pattern: String, in cacheName: String) async {
        let regex: NSRegularExpression?
        do {
            let regexPattern = pattern
                .replacingOccurrences(of: "*", with: ".*")
                .replacingOccurrences(of: "?", with: ".")
            regex = try NSRegularExpression(pattern: regexPattern)
        } catch {
            regex = nil
        }

        guard let regex = regex else { return }

        let matchingMetadata = metadata.values.filter { meta in
            let range = NSRange(location: 0, length: meta.url.utf16.count)
            return regex.firstMatch(in: meta.url, range: range) != nil
        }

        do {
            let caches = JSObject.global.caches
            let cachePromise = caches.open(cacheName)
            let cache = try await JSPromise(cachePromise.object!)!.getValue()

            guard let cacheObject = cache.object else { return }

            for meta in matchingMetadata {
                let deletePromise = cacheObject.delete!(meta.url)
                _ = try? await JSPromise(deletePromise.object!)!.getValue()

                await removeMetadata(for: meta.url)
            }
        } catch {
            // Failed to invalidate by pattern
        }
    }

    // MARK: - Cleanup Operations

    /// Perform full cache cleanup based on policy
    /// - Parameter cacheName: Name of the cache to clean
    public func performCleanup(for cacheName: String) async {
        // Remove expired entries
        await removeExpiredEntries(from: cacheName)

        // Enforce size limits
        await enforceSizeLimits(for: cacheName)
    }

    /// Clear all caches
    public func clearAll() async {
        do {
            let caches = JSObject.global.caches

            // Get all cache names
            guard let keysFunc = caches.keys.function else { return }
            let promise = keysFunc()
            let keys = try await JSPromise(promise.object!)!.getValue()

            guard let keysArray = keys.object else { return }
            let length = keysArray.length.number ?? 0

            for i in 0..<Int(length) {
                guard let cacheName = keysArray[i].string else { continue }

                let deletePromise = caches.delete(cacheName)
                _ = try? await JSPromise(deletePromise.object!)!.getValue()
            }

            // Clear metadata
            metadata.removeAll()
            try await metadataDB.open()
            try await metadataDB.clear(storeName: "cacheMetadata")
        } catch {
            // Failed to clear all caches
        }
    }

    // MARK: - Private Methods

    private func loadMetadata() async {
        do {
            try await metadataDB.open()
            let entries = try await metadataDB.getAll(from: "cacheMetadata")

            for entry in entries {
                if let meta = decodeMetadata(entry) {
                    metadata[meta.url] = meta
                }
            }
        } catch {
            // Failed to load metadata
        }
    }

    private func trimToEntryCount(cacheName: String, targetCount: Int) async {
        guard metadata.count > targetCount else { return }

        let sortedMetadata = metadata.values.sorted { $0.timestamp < $1.timestamp }
        let toRemove = sortedMetadata.prefix(metadata.count - targetCount)

        do {
            let caches = JSObject.global.caches
            let cachePromise = caches.open(cacheName)
            let cache = try await JSPromise(cachePromise.object!)!.getValue()

            guard let cacheObject = cache.object else { return }

            for meta in toRemove {
                let deletePromise = cacheObject.delete!(meta.url)
                _ = try? await JSPromise(deletePromise.object!)!.getValue()

                await removeMetadata(for: meta.url)
            }
        } catch {
            // Failed to trim to entry count
        }
    }

    private func encodeMetadata(_ metadata: CacheMetadata) -> [String: Any] {
        var dict: [String: Any] = [
            "url": metadata.url,
            "timestamp": metadata.timestamp.timeIntervalSince1970,
            "tags": metadata.tags
        ]

        if let expiresAt = metadata.expiresAt {
            dict["expiresAt"] = expiresAt.timeIntervalSince1970
        }

        if let size = metadata.size {
            dict["size"] = size
        }

        if let version = metadata.version {
            dict["version"] = version
        }

        return dict
    }

    private func decodeMetadata(_ dict: [String: Any]) -> CacheMetadata? {
        guard let url = dict["url"] as? String,
              let timestampValue = dict["timestamp"] as? Double else {
            return nil
        }

        let timestamp = Date(timeIntervalSince1970: timestampValue)
        let expiresAt: Date? = {
            if let value = dict["expiresAt"] as? Double {
                return Date(timeIntervalSince1970: value)
            }
            return nil
        }()
        let size = dict["size"] as? Int
        let version = dict["version"] as? String
        let tags = dict["tags"] as? [String] ?? []

        return CacheMetadata(
            url: url,
            timestamp: timestamp,
            expiresAt: expiresAt,
            size: size,
            version: version,
            tags: tags
        )
    }
}
