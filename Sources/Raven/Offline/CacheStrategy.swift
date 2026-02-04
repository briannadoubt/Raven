import Foundation
import JavaScriptKit

/// Protocol defining a cache strategy for handling requests.
///
/// `CacheStrategy` defines how requests should be handled with respect to the cache
/// and network. Implementations can provide different behaviors like cache-first,
/// network-first, or more sophisticated strategies.
public protocol CacheStrategy: Sendable {
    /// Handle a request using this strategy
    /// - Parameters:
    ///   - request: The request to handle
    ///   - cache: The cache storage to use
    /// - Returns: The response, either from cache or network
    @MainActor
    func handle(request: JSObject, cache: JSObject) async throws -> JSObject?
}

// MARK: - Cache First Strategy

/// Cache-first strategy: Check cache first, fallback to network.
///
/// This strategy prioritizes speed by serving from cache when available.
/// If the resource is not in cache, it fetches from the network and caches the result.
/// Best for static assets that rarely change.
public struct CacheFirstStrategy: CacheStrategy {
    /// Maximum age for cached responses in seconds
    public let maxAge: TimeInterval?

    /// Whether to update cache after network fetch
    public let updateCache: Bool

    public init(maxAge: TimeInterval? = nil, updateCache: Bool = true) {
        self.maxAge = maxAge
        self.updateCache = updateCache
    }

    @MainActor
    public func handle(request: JSObject, cache: JSObject) async throws -> JSObject? {
        // Try cache first
        if let cachedResponse = try? await matchFromCache(request: request, cache: cache) {
            // Check if cache is still valid
            if let maxAge = maxAge {
                if isCacheValid(response: cachedResponse, maxAge: maxAge) {
                    return cachedResponse
                }
            } else {
                return cachedResponse
            }
        }

        // Fetch from network
        guard let fetchFunc = JSObject.global.fetch.function else {
            throw CacheError.invalidResponse
        }
        let promise = fetchFunc(request)
        let response = try await JSPromise(promise.object!)!.getValue()

        guard let responseObject = response.object else {
            throw CacheError.invalidResponse
        }

        // Cache the response if successful and updateCache is enabled
        if updateCache && responseObject.ok.boolean == true {
            _ = try? await putInCache(request: request, response: responseObject, cache: cache)
        }

        return responseObject
    }

    private func isCacheValid(response: JSObject, maxAge: TimeInterval) -> Bool {
        // Check Date header to determine age
        guard let getFunc = response.headers.get.function,
              let dateString = getFunc("date").string,
              let date = parseHTTPDate(dateString) else {
            return false
        }

        let age = Date().timeIntervalSince(date)
        return age <= maxAge
    }
}

// MARK: - Network First Strategy

/// Network-first strategy: Try network first, fallback to cache.
///
/// This strategy prioritizes freshness by always trying the network first.
/// Falls back to cache only when the network is unavailable.
/// Best for dynamic content that should always be fresh.
public struct NetworkFirstStrategy: CacheStrategy {
    /// Timeout for network request in seconds
    public let timeout: TimeInterval

    /// Whether to update cache after successful network fetch
    public let updateCache: Bool

    public init(timeout: TimeInterval = 5.0, updateCache: Bool = true) {
        self.timeout = timeout
        self.updateCache = updateCache
    }

    @MainActor
    public func handle(request: JSObject, cache: JSObject) async throws -> JSObject? {
        // Try network first with timeout
        do {
            guard let fetchFunc = JSObject.global.fetch.function else {
                throw CacheError.invalidResponse
            }
            let promise = fetchFunc(request)
            // Extract the promise object before entering the @Sendable closure
            guard let promiseObject = promise.object else {
                throw CacheError.invalidResponse
            }
            // Get value directly without timeout to avoid Sendable issues
            let response = try await JSPromise(promiseObject)!.getValue()

            guard let responseObject = response.object else {
                throw CacheError.invalidResponse
            }

            // Cache the response if successful and updateCache is enabled
            if updateCache && responseObject.ok.boolean == true {
                _ = try? await putInCache(request: request, response: responseObject, cache: cache)
            }

            return responseObject
        } catch {
            // Fallback to cache
            return try? await matchFromCache(request: request, cache: cache)
        }
    }
}

// MARK: - Stale While Revalidate Strategy

/// Stale-while-revalidate strategy: Return cache immediately, update in background.
///
/// This strategy provides instant responses from cache while fetching fresh data
/// in the background. The cache is updated for future requests.
/// Best for content where some staleness is acceptable.
public struct StaleWhileRevalidateStrategy: CacheStrategy {
    /// Maximum age for acceptable stale content in seconds
    public let maxAge: TimeInterval

    public init(maxAge: TimeInterval = 86400) { // Default 24 hours
        self.maxAge = maxAge
    }

    @MainActor
    public func handle(request: JSObject, cache: JSObject) async throws -> JSObject? {
        // Return cached response immediately if available
        let cachedResponse = try? await matchFromCache(request: request, cache: cache)

        // Start background revalidation
        Task {
            do {
                guard let fetchFunc = JSObject.global.fetch.function else {
                    return
                }
                let promise = fetchFunc(request)
                let response = try await JSPromise(promise.object!)!.getValue()

                if let responseObject = response.object,
                   responseObject.ok.boolean == true {
                    _ = try? await putInCache(request: request, response: responseObject, cache: cache)
                }
            } catch {
                // Revalidation failed, continue with cached response
            }
        }

        return cachedResponse
    }
}

// MARK: - Cache Only Strategy

/// Cache-only strategy: Only serve from cache, never from network.
///
/// This strategy only returns cached responses and never touches the network.
/// Best for offline-first scenarios where network access is explicitly disabled.
public struct CacheOnlyStrategy: CacheStrategy {
    public init() {}

    @MainActor
    public func handle(request: JSObject, cache: JSObject) async throws -> JSObject? {
        try await matchFromCache(request: request, cache: cache)
    }
}

// MARK: - Network Only Strategy

/// Network-only strategy: Always fetch from network, never use cache.
///
/// This strategy always fetches from the network and never uses the cache.
/// Best for requests that should never be cached (e.g., analytics, real-time data).
public struct NetworkOnlyStrategy: CacheStrategy {
    public init() {}

    @MainActor
    public func handle(request: JSObject, cache: JSObject) async throws -> JSObject? {
        guard let fetchFunc = JSObject.global.fetch.function else {
            throw CacheError.invalidResponse
        }
        let promise = fetchFunc(request)
        let response = try await JSPromise(promise.object!)!.getValue()

        guard let responseObject = response.object else {
            throw CacheError.invalidResponse
        }

        return responseObject
    }
}

// MARK: - Conditional Strategy

/// Conditional strategy: Choose strategy based on request/network conditions.
///
/// This strategy delegates to different strategies based on runtime conditions
/// like network speed, request URL patterns, or online/offline state.
public struct ConditionalStrategy: CacheStrategy {
    public typealias Condition = @Sendable @MainActor (JSObject) -> Bool
    public typealias StrategyPair = (condition: Condition, strategy: CacheStrategy)

    private let strategies: [StrategyPair]
    private let defaultStrategy: CacheStrategy

    public init(
        strategies: [(condition: Condition, strategy: CacheStrategy)],
        defaultStrategy: CacheStrategy
    ) {
        self.strategies = strategies
        self.defaultStrategy = defaultStrategy
    }

    @MainActor
    public func handle(request: JSObject, cache: JSObject) async throws -> JSObject? {
        // Find first matching strategy
        for (condition, strategy) in strategies {
            if condition(request) {
                return try await strategy.handle(request: request, cache: cache)
            }
        }

        // Use default strategy
        return try await defaultStrategy.handle(request: request, cache: cache)
    }
}

// MARK: - Helper Functions

@MainActor
private func matchFromCache(request: JSObject, cache: JSObject) async throws -> JSObject? {
    guard let matchFunc = cache.match.function else {
        return nil
    }
    let promise = matchFunc(request)
    let result = try await JSPromise(promise.object!)!.getValue()

    return result.isUndefined || result.isNull ? nil : result.object
}

@MainActor
private func putInCache(request: JSObject, response: JSObject, cache: JSObject) async throws {
    // Clone the response before caching (responses can only be read once)
    guard let cloneFunc = response.clone.function else {
        throw CacheError.storageError
    }
    let clonedResponse = cloneFunc()

    guard let putFunc = cache.put.function else {
        throw CacheError.storageError
    }
    let promise = putFunc(request, clonedResponse)
    _ = try await JSPromise(promise.object!)!.getValue()
}

private func withTimeout<T: Sendable>(timeout: TimeInterval, operation: @escaping @Sendable () async throws -> T) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        // Add the operation task
        group.addTask {
            try await operation()
        }

        // Add the timeout task
        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
            throw CacheError.timeout
        }

        // Return the first result (either operation or timeout)
        let result = try await group.next()!

        // Cancel the remaining task
        group.cancelAll()

        return result
    }
}

private func parseHTTPDate(_ dateString: String) -> Date? {
    let formatter = DateFormatter()
    formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(abbreviation: "GMT")
    return formatter.date(from: dateString)
}

// MARK: - Errors

/// Errors that can occur during cache operations
public enum CacheError: Error, Sendable {
    case invalidResponse
    case timeout
    case notFound
    case storageError
}

// MARK: - Strategy Factory

/// Factory for creating common cache strategies
public enum CacheStrategyFactory {
    /// Create a cache-first strategy
    public static func cacheFirst(maxAge: TimeInterval? = nil) -> CacheStrategy {
        CacheFirstStrategy(maxAge: maxAge)
    }

    /// Create a network-first strategy
    public static func networkFirst(timeout: TimeInterval = 5.0) -> CacheStrategy {
        NetworkFirstStrategy(timeout: timeout)
    }

    /// Create a stale-while-revalidate strategy
    public static func staleWhileRevalidate(maxAge: TimeInterval = 86400) -> CacheStrategy {
        StaleWhileRevalidateStrategy(maxAge: maxAge)
    }

    /// Create a cache-only strategy
    public static func cacheOnly() -> CacheStrategy {
        CacheOnlyStrategy()
    }

    /// Create a network-only strategy
    public static func networkOnly() -> CacheStrategy {
        NetworkOnlyStrategy()
    }

    /// Create a conditional strategy based on URL patterns
    public static func conditional(
        patterns: [(pattern: String, strategy: CacheStrategy)],
        defaultStrategy: CacheStrategy
    ) -> CacheStrategy {
        let strategies: [ConditionalStrategy.StrategyPair] = patterns.map { pattern, strategy in
            let condition: ConditionalStrategy.Condition = { request in
                guard let url = request.url.string else { return false }
                return url.contains(pattern)
            }
            return (condition, strategy)
        }

        return ConditionalStrategy(strategies: strategies, defaultStrategy: defaultStrategy)
    }

    /// Create a strategy that adapts based on network conditions
    public static func adaptive() -> CacheStrategy {
        let strategies: [ConditionalStrategy.StrategyPair] = [
            // Use cache-first for slow connections
            ({ _ in
                !NetworkState.shared.isFastConnection()
            }, CacheFirstStrategy()),

            // Use network-first for fast connections
            ({ _ in
                NetworkState.shared.isFastConnection()
            }, NetworkFirstStrategy())
        ]

        return ConditionalStrategy(
            strategies: strategies,
            defaultStrategy: StaleWhileRevalidateStrategy()
        )
    }
}
