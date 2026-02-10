import Foundation

/// Cache control policy for server-side rendered content
public struct CachePolicy: Sendable, Hashable {
    /// Cache strategy type
    public enum Strategy: Sendable, Hashable {
        /// No caching - always fetch fresh content
        case noCache
        /// Cache with immediate revalidation
        case revalidate
        /// Cache for a specific duration
        case maxAge(seconds: Int)
        /// Cache indefinitely (for static content)
        case immutable(maxAge: Int)
        /// Cache with stale-while-revalidate pattern
        case staleWhileRevalidate(maxAge: Int, staleWhileRevalidate: Int)
        /// Custom cache control directives
        case custom(directives: [String])
    }

    /// The caching strategy to use
    public let strategy: Strategy

    /// Whether the response can be cached by public caches (CDNs)
    public let `public`: Bool

    /// Whether the response is private to a single user
    public let `private`: Bool

    /// Whether to require validation before serving stale content
    public let mustRevalidate: Bool

    /// Whether proxies can transform the content
    public let noTransform: Bool

    /// Vary header values for cache key differentiation
    public let vary: [String]

    /// ETag for content validation
    public let etag: String?

    /// Last-Modified timestamp
    public let lastModified: Date?

    /// Create a new cache policy
    public init(
        strategy: Strategy,
        public: Bool = false,
        private: Bool = false,
        mustRevalidate: Bool = false,
        noTransform: Bool = false,
        vary: [String] = [],
        etag: String? = nil,
        lastModified: Date? = nil
    ) {
        self.strategy = strategy
        self.`public` = `public`
        self.`private` = `private`
        self.mustRevalidate = mustRevalidate
        self.noTransform = noTransform
        self.vary = vary
        self.etag = etag
        self.lastModified = lastModified
    }

    /// Generate Cache-Control header value
    public var cacheControlHeader: String {
        var directives: [String] = []

        // Add public/private
        if self.`public` {
            directives.append("public")
        } else if self.`private` {
            directives.append("private")
        }

        // Add strategy-specific directives
        switch strategy {
        case .noCache:
            directives.append("no-cache")
            directives.append("no-store")

        case .revalidate:
            directives.append("no-cache")

        case .maxAge(let seconds):
            directives.append("max-age=\(seconds)")

        case .immutable(let maxAge):
            directives.append("max-age=\(maxAge)")
            directives.append("immutable")

        case .staleWhileRevalidate(let maxAge, let swr):
            directives.append("max-age=\(maxAge)")
            directives.append("stale-while-revalidate=\(swr)")

        case .custom(let customDirectives):
            directives.append(contentsOf: customDirectives)
        }

        // Add must-revalidate
        if mustRevalidate {
            directives.append("must-revalidate")
        }

        // Add no-transform
        if noTransform {
            directives.append("no-transform")
        }

        return directives.joined(separator: ", ")
    }

    /// Generate Vary header value
    public var varyHeader: String? {
        vary.isEmpty ? nil : vary.joined(separator: ", ")
    }

    /// Generate ETag header value
    public var etagHeader: String? {
        etag.map { "\"\($0)\"" }
    }

    /// Generate Last-Modified header value
    public var lastModifiedHeader: String? {
        lastModified.map { httpDateFormatter.string(from: $0) }
    }

    /// Generate all cache-related headers
    public var headers: [String: String] {
        var headers: [String: String] = [:]

        headers["Cache-Control"] = cacheControlHeader

        if let vary = varyHeader {
            headers["Vary"] = vary
        }

        if let etag = etagHeader {
            headers["ETag"] = etag
        }

        if let lastModified = lastModifiedHeader {
            headers["Last-Modified"] = lastModified
        }

        return headers
    }
}

// MARK: - Common Policies

extension CachePolicy {
    /// No caching policy - always fetch fresh content
    public static var noCache: CachePolicy {
        CachePolicy(strategy: .noCache)
    }

    /// Static content policy - cache indefinitely with CDN support
    public static func `static`(maxAge: Int = 31536000) -> CachePolicy {
        CachePolicy(
            strategy: .immutable(maxAge: maxAge),
            public: true,
            noTransform: true
        )
    }

    /// Dynamic content policy - short-lived cache with revalidation
    public static func dynamic(maxAge: Int = 60, staleWhileRevalidate: Int = 300) -> CachePolicy {
        CachePolicy(
            strategy: .staleWhileRevalidate(
                maxAge: maxAge,
                staleWhileRevalidate: staleWhileRevalidate
            ),
            public: true
        )
    }

    /// Private content policy - user-specific, not cacheable by CDN
    public static func `private`(maxAge: Int = 300) -> CachePolicy {
        CachePolicy(
            strategy: .maxAge(seconds: maxAge),
            private: true,
            mustRevalidate: true
        )
    }

    /// SSR default policy - balanced caching for server-rendered pages
    public static var ssrDefault: CachePolicy {
        CachePolicy(
            strategy: .staleWhileRevalidate(maxAge: 60, staleWhileRevalidate: 3600),
            public: true,
            vary: ["Accept-Encoding"]
        )
    }

    /// API response policy - short cache with stale-while-revalidate
    public static func api(maxAge: Int = 30, staleWhileRevalidate: Int = 300) -> CachePolicy {
        CachePolicy(
            strategy: .staleWhileRevalidate(
                maxAge: maxAge,
                staleWhileRevalidate: staleWhileRevalidate
            ),
            public: true,
            vary: ["Accept", "Accept-Encoding"]
        )
    }
}

// MARK: - ETag Generation

extension CachePolicy {
    /// Generate an ETag from content
    public static func generateETag(content: String, weak: Bool = true) -> String {
        let hash = content.hash
        return weak ? "W/\"\(abs(hash))\"" : "\"\(abs(hash))\""
    }

    /// Generate an ETag from data
    public static func generateETag(data: Data, weak: Bool = true) -> String {
        let hash = data.hashValue
        return weak ? "W/\"\(abs(hash))\"" : "\"\(abs(hash))\""
    }
}

// MARK: - Cache Invalidation

/// Represents a cache invalidation strategy
public struct CacheInvalidation: Sendable {
    /// Invalidation trigger type
    public enum Trigger: Sendable {
        /// Invalidate after a time duration
        case afterDuration(TimeInterval)
        /// Invalidate at a specific time
        case atTime(Date)
        /// Invalidate when a condition is met
        case onCondition(String)
        /// Manual invalidation
        case manual
    }

    /// The invalidation trigger
    public let trigger: Trigger

    /// Paths or patterns to invalidate
    public let patterns: [String]

    /// Whether to invalidate related resources
    public let cascading: Bool

    /// Create a new cache invalidation strategy
    public init(
        trigger: Trigger,
        patterns: [String],
        cascading: Bool = false
    ) {
        self.trigger = trigger
        self.patterns = patterns
        self.cascading = cascading
    }
}

// MARK: - Cache Configuration

/// Configuration for SSR caching behavior
public struct SSRCacheConfiguration: Sendable {
    /// Default cache policy for pages
    public let defaultPolicy: CachePolicy

    /// Path-specific cache policies
    public let pathPolicies: [String: CachePolicy]

    /// Whether to enable edge caching (CDN)
    public let enableEdgeCaching: Bool

    /// Whether to enable service worker caching
    public let enableServiceWorkerCache: Bool

    /// Surrogate control header for CDN
    public let surrogateControl: String?

    /// Create a new SSR cache configuration
    public init(
        defaultPolicy: CachePolicy = .ssrDefault,
        pathPolicies: [String: CachePolicy] = [:],
        enableEdgeCaching: Bool = true,
        enableServiceWorkerCache: Bool = false,
        surrogateControl: String? = nil
    ) {
        self.defaultPolicy = defaultPolicy
        self.pathPolicies = pathPolicies
        self.enableEdgeCaching = enableEdgeCaching
        self.enableServiceWorkerCache = enableServiceWorkerCache
        self.surrogateControl = surrogateControl
    }

    /// Get the cache policy for a specific path
    public func policy(for path: String) -> CachePolicy {
        // Check for exact match
        if let policy = pathPolicies[path] {
            return policy
        }

        // Check for pattern matches (simple prefix matching)
        for (pattern, policy) in pathPolicies {
            if pattern.hasSuffix("*") {
                let prefix = String(pattern.dropLast())
                if path.hasPrefix(prefix) {
                    return policy
                }
            }
        }

        return defaultPolicy
    }

    /// Generate headers for a specific path
    public func headers(for path: String, content: String? = nil) -> [String: String] {
        var headers = policy(for: path).headers

        // Add Surrogate-Control for CDN
        if enableEdgeCaching, let surrogateControl = surrogateControl {
            headers["Surrogate-Control"] = surrogateControl
        }

        // Add ETag if content is provided
        if let content = content, headers["ETag"] == nil {
            headers["ETag"] = CachePolicy.generateETag(content: content)
        }

        return headers
    }
}

// MARK: - Common Configurations

extension SSRCacheConfiguration {
    /// Production configuration - aggressive caching
    public static var production: SSRCacheConfiguration {
        SSRCacheConfiguration(
            defaultPolicy: .ssrDefault,
            pathPolicies: [
                "/static/*": .static(),
                "/api/*": .api(),
                "/assets/*": .static(maxAge: 31536000)
            ],
            enableEdgeCaching: true,
            enableServiceWorkerCache: true,
            surrogateControl: "max-age=3600"
        )
    }

    /// Development configuration - minimal caching
    public static var development: SSRCacheConfiguration {
        SSRCacheConfiguration(
            defaultPolicy: .noCache,
            pathPolicies: [:],
            enableEdgeCaching: false,
            enableServiceWorkerCache: false
        )
    }

    /// Preview configuration - short-lived caching
    public static var preview: SSRCacheConfiguration {
        SSRCacheConfiguration(
            defaultPolicy: .dynamic(maxAge: 10, staleWhileRevalidate: 60),
            pathPolicies: [
                "/static/*": .static(maxAge: 3600)
            ],
            enableEdgeCaching: true,
            enableServiceWorkerCache: false
        )
    }
}

// MARK: - HTTP Date Formatter

private let httpDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss z"
    formatter.timeZone = TimeZone(identifier: "GMT")
    formatter.locale = Locale(identifier: "en_US_POSIX")
    return formatter
}()
