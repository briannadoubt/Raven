import Foundation

/// Server-side rendering context that tracks state and metadata during HTML generation
///
/// RenderContext provides the execution environment for server-side rendering,
/// managing request information, render state, and collected metadata like
/// meta tags and resource hints.
public struct RenderContext: Sendable {
    // MARK: - Request Information

    /// The request URL being rendered
    public let url: URL?

    /// User agent string from the request
    public let userAgent: String?

    /// Request headers
    public let headers: [String: String]

    /// Query parameters from the request URL
    public let queryParameters: [String: String]

    // MARK: - Render State

    /// Unique identifier for this render session
    public let renderID: UUID

    /// Timestamp when rendering started
    public let startTime: Date

    /// Whether to include hydration markers in the output
    public let includeHydrationMarkers: Bool

    /// Whether to minify the HTML output
    public let minifyHTML: Bool

    /// Whether to include debug information in the output
    public let includeDebugInfo: Bool

    // MARK: - Collected Metadata

    /// Meta tags collected during rendering
    public private(set) var metaTags: [MetaTag]

    /// Resource preload hints collected during rendering
    public private(set) var preloadHints: [PreloadHint]

    /// Scripts to include in the HTML output
    public private(set) var scripts: [Script]

    /// Stylesheets to include in the HTML output
    public private(set) var stylesheets: [Stylesheet]

    /// Custom data attached to the context
    public private(set) var customData: [String: String]

    // MARK: - Performance Tracking

    /// Performance metrics collected during rendering
    public private(set) var metrics: RenderMetrics

    // MARK: - Initialization

    /// Create a new render context
    /// - Parameters:
    ///   - url: Request URL being rendered
    ///   - userAgent: User agent string from the request
    ///   - headers: Request headers
    ///   - queryParameters: Query parameters from the URL
    ///   - includeHydrationMarkers: Whether to include hydration markers
    ///   - minifyHTML: Whether to minify HTML output
    ///   - includeDebugInfo: Whether to include debug information
    public init(
        url: URL? = nil,
        userAgent: String? = nil,
        headers: [String: String] = [:],
        queryParameters: [String: String] = [:],
        includeHydrationMarkers: Bool = true,
        minifyHTML: Bool = false,
        includeDebugInfo: Bool = false
    ) {
        self.url = url
        self.userAgent = userAgent
        self.headers = headers
        self.queryParameters = queryParameters
        self.renderID = UUID()
        self.startTime = Date()
        self.includeHydrationMarkers = includeHydrationMarkers
        self.minifyHTML = minifyHTML
        self.includeDebugInfo = includeDebugInfo
        self.metaTags = []
        self.preloadHints = []
        self.scripts = []
        self.stylesheets = []
        self.customData = [:]
        self.metrics = RenderMetrics()
    }

    // MARK: - Metadata Collection

    /// Add a meta tag to the context
    public mutating func addMetaTag(_ tag: MetaTag) {
        metaTags.append(tag)
    }

    /// Add multiple meta tags to the context
    public mutating func addMetaTags(_ tags: [MetaTag]) {
        metaTags.append(contentsOf: tags)
    }

    /// Add a preload hint to the context
    public mutating func addPreloadHint(_ hint: PreloadHint) {
        preloadHints.append(hint)
    }

    /// Add multiple preload hints to the context
    public mutating func addPreloadHints(_ hints: [PreloadHint]) {
        preloadHints.append(contentsOf: hints)
    }

    /// Add a script to the context
    public mutating func addScript(_ script: Script) {
        scripts.append(script)
    }

    /// Add a stylesheet to the context
    public mutating func addStylesheet(_ stylesheet: Stylesheet) {
        stylesheets.append(stylesheet)
    }

    /// Set custom data in the context
    public mutating func setCustomData(key: String, value: String) {
        customData[key] = value
    }

    /// Get custom data from the context
    public func getCustomData(key: String) -> String? {
        customData[key]
    }

    // MARK: - Performance Tracking

    /// Record a performance metric
    public mutating func recordMetric(name: String, duration: TimeInterval) {
        metrics.timings[name] = duration
    }

    /// Increment a counter metric
    public mutating func incrementCounter(name: String, by amount: Int = 1) {
        metrics.counters[name, default: 0] += amount
    }

    /// Get total render duration
    public var totalDuration: TimeInterval {
        Date().timeIntervalSince(startTime)
    }
}

// MARK: - Script

/// Represents a script to include in the HTML output
public struct Script: Sendable, Hashable {
    /// Script source type
    public enum Source: Sendable, Hashable {
        /// External script with URL
        case external(url: String)
        /// Inline script with content
        case inline(content: String)
    }

    /// Script source
    public let source: Source

    /// Whether the script is async
    public let async: Bool

    /// Whether the script is defer
    public let `defer`: Bool

    /// Script type attribute
    public let type: String?

    /// Script integrity hash for SRI
    public let integrity: String?

    /// Cross-origin attribute
    public let crossOrigin: String?

    /// Create a new script
    public init(
        source: Source,
        async: Bool = false,
        defer: Bool = false,
        type: String? = nil,
        integrity: String? = nil,
        crossOrigin: String? = nil
    ) {
        self.source = source
        self.async = async
        self.defer = `defer`
        self.type = type
        self.integrity = integrity
        self.crossOrigin = crossOrigin
    }
}

// MARK: - Stylesheet

/// Represents a stylesheet to include in the HTML output
public struct Stylesheet: Sendable, Hashable {
    /// Stylesheet source type
    public enum Source: Sendable, Hashable {
        /// External stylesheet with URL
        case external(url: String)
        /// Inline stylesheet with content
        case inline(content: String)
    }

    /// Stylesheet source
    public let source: Source

    /// Media query for the stylesheet
    public let media: String?

    /// Stylesheet integrity hash for SRI
    public let integrity: String?

    /// Cross-origin attribute
    public let crossOrigin: String?

    /// Create a new stylesheet
    public init(
        source: Source,
        media: String? = nil,
        integrity: String? = nil,
        crossOrigin: String? = nil
    ) {
        self.source = source
        self.media = media
        self.integrity = integrity
        self.crossOrigin = crossOrigin
    }
}

// MARK: - RenderMetrics

/// Performance metrics collected during rendering
public struct RenderMetrics: Sendable {
    /// Named timing measurements
    public var timings: [String: TimeInterval]

    /// Named counter values
    public var counters: [String: Int]

    /// Create new render metrics
    public init() {
        self.timings = [:]
        self.counters = [:]
    }
}

// MARK: - Context Builder

extension RenderContext {
    /// Builder for constructing render contexts
    public struct Builder {
        private var context: RenderContext

        /// Create a new builder
        public init() {
            self.context = RenderContext()
        }

        /// Set the request URL
        public func url(_ url: URL) -> Builder {
            var builder = self
            builder.context = RenderContext(
                url: url,
                userAgent: context.userAgent,
                headers: context.headers,
                queryParameters: context.queryParameters,
                includeHydrationMarkers: context.includeHydrationMarkers,
                minifyHTML: context.minifyHTML,
                includeDebugInfo: context.includeDebugInfo
            )
            return builder
        }

        /// Set the user agent
        public func userAgent(_ userAgent: String) -> Builder {
            var builder = self
            builder.context = RenderContext(
                url: context.url,
                userAgent: userAgent,
                headers: context.headers,
                queryParameters: context.queryParameters,
                includeHydrationMarkers: context.includeHydrationMarkers,
                minifyHTML: context.minifyHTML,
                includeDebugInfo: context.includeDebugInfo
            )
            return builder
        }

        /// Set request headers
        public func headers(_ headers: [String: String]) -> Builder {
            var builder = self
            builder.context = RenderContext(
                url: context.url,
                userAgent: context.userAgent,
                headers: headers,
                queryParameters: context.queryParameters,
                includeHydrationMarkers: context.includeHydrationMarkers,
                minifyHTML: context.minifyHTML,
                includeDebugInfo: context.includeDebugInfo
            )
            return builder
        }

        /// Enable hydration markers
        public func withHydrationMarkers(_ enabled: Bool = true) -> Builder {
            var builder = self
            builder.context = RenderContext(
                url: context.url,
                userAgent: context.userAgent,
                headers: context.headers,
                queryParameters: context.queryParameters,
                includeHydrationMarkers: enabled,
                minifyHTML: context.minifyHTML,
                includeDebugInfo: context.includeDebugInfo
            )
            return builder
        }

        /// Enable HTML minification
        public func withMinification(_ enabled: Bool = true) -> Builder {
            var builder = self
            builder.context = RenderContext(
                url: context.url,
                userAgent: context.userAgent,
                headers: context.headers,
                queryParameters: context.queryParameters,
                includeHydrationMarkers: context.includeHydrationMarkers,
                minifyHTML: enabled,
                includeDebugInfo: context.includeDebugInfo
            )
            return builder
        }

        /// Enable debug information
        public func withDebugInfo(_ enabled: Bool = true) -> Builder {
            var builder = self
            builder.context = RenderContext(
                url: context.url,
                userAgent: context.userAgent,
                headers: context.headers,
                queryParameters: context.queryParameters,
                includeHydrationMarkers: context.includeHydrationMarkers,
                minifyHTML: context.minifyHTML,
                includeDebugInfo: enabled
            )
            return builder
        }

        /// Build the render context
        public func build() -> RenderContext {
            context
        }
    }
}
