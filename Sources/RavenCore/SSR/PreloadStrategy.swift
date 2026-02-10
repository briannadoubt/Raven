import Foundation

/// Represents a resource preload hint for optimizing page load performance
public struct PreloadHint: Sendable, Hashable {
    /// Resource type to preload
    public enum ResourceType: String, Sendable, Hashable {
        case script
        case style
        case font
        case image
        case fetch
        case document
        case audio
        case video
        case track
        case worker
        case embed
        case `object`
    }

    /// Fetch priority for the resource
    public enum FetchPriority: String, Sendable, Hashable {
        case high
        case low
        case auto
    }

    /// Preload strategy type
    public enum Strategy: Sendable, Hashable {
        /// Preload - high priority, critical resource
        case preload
        /// Prefetch - low priority, likely needed later
        case prefetch
        /// Preconnect - establish connection to domain
        case preconnect
        /// DNS-prefetch - resolve DNS early
        case dnsPrefetch
        /// Modulepreload - preload ES module
        case modulepreload
    }

    /// The preload strategy to use
    public let strategy: Strategy

    /// URL of the resource
    public let url: String

    /// Type of resource being preloaded
    public let resourceType: ResourceType?

    /// MIME type of the resource
    public let mimeType: String?

    /// Cross-origin attribute
    public let crossOrigin: String?

    /// Fetch priority
    public let fetchPriority: FetchPriority?

    /// Integrity hash for SRI
    public let integrity: String?

    /// Media query for conditional loading
    public let media: String?

    /// Referrer policy
    public let referrerPolicy: String?

    /// Create a new preload hint
    public init(
        strategy: Strategy,
        url: String,
        resourceType: ResourceType? = nil,
        mimeType: String? = nil,
        crossOrigin: String? = nil,
        fetchPriority: FetchPriority? = nil,
        integrity: String? = nil,
        media: String? = nil,
        referrerPolicy: String? = nil
    ) {
        self.strategy = strategy
        self.url = url
        self.resourceType = resourceType
        self.mimeType = mimeType
        self.crossOrigin = crossOrigin
        self.fetchPriority = fetchPriority
        self.integrity = integrity
        self.media = media
        self.referrerPolicy = referrerPolicy
    }

    /// Convert to HTML link tag
    public func toHTML() -> String {
        var attributes: [String] = []

        // Determine rel attribute
        let rel: String
        switch strategy {
        case .preload:
            rel = "preload"
        case .prefetch:
            rel = "prefetch"
        case .preconnect:
            rel = "preconnect"
        case .dnsPrefetch:
            rel = "dns-prefetch"
        case .modulepreload:
            rel = "modulepreload"
        }
        attributes.append("rel=\"\(rel)\"")

        // Add href
        attributes.append("href=\"\(escapeHTML(url))\"")

        // Add as attribute for preload/modulepreload
        if (strategy == .preload || strategy == .modulepreload), let resourceType = resourceType {
            attributes.append("as=\"\(resourceType.rawValue)\"")
        }

        // Add type if provided
        if let mimeType = mimeType {
            attributes.append("type=\"\(escapeHTML(mimeType))\"")
        }

        // Add crossorigin if provided
        if let crossOrigin = crossOrigin {
            attributes.append("crossorigin=\"\(escapeHTML(crossOrigin))\"")
        }

        // Add fetchpriority if provided
        if let fetchPriority = fetchPriority {
            attributes.append("fetchpriority=\"\(fetchPriority.rawValue)\"")
        }

        // Add integrity if provided
        if let integrity = integrity {
            attributes.append("integrity=\"\(escapeHTML(integrity))\"")
        }

        // Add media if provided
        if let media = media {
            attributes.append("media=\"\(escapeHTML(media))\"")
        }

        // Add referrerpolicy if provided
        if let referrerPolicy = referrerPolicy {
            attributes.append("referrerpolicy=\"\(escapeHTML(referrerPolicy))\"")
        }

        return "<link \(attributes.joined(separator: " "))>"
    }
}

// MARK: - Preload Strategy Builder

/// Builder for creating optimized resource preload strategies
public struct PreloadStrategyBuilder: Sendable {
    private var hints: [PreloadHint] = []

    /// Create a new preload strategy builder
    public init() {}

    // MARK: - Critical Resources (Preload)

    /// Preload a critical script
    public func preloadScript(
        url: String,
        integrity: String? = nil,
        crossOrigin: String? = "anonymous",
        fetchPriority: PreloadHint.FetchPriority? = .high
    ) -> PreloadStrategyBuilder {
        var builder = self
        builder.hints.append(PreloadHint(
            strategy: .preload,
            url: url,
            resourceType: .script,
            crossOrigin: crossOrigin,
            fetchPriority: fetchPriority,
            integrity: integrity
        ))
        return builder
    }

    /// Preload a critical stylesheet
    public func preloadStylesheet(
        url: String,
        integrity: String? = nil,
        crossOrigin: String? = "anonymous",
        media: String? = nil,
        fetchPriority: PreloadHint.FetchPriority? = .high
    ) -> PreloadStrategyBuilder {
        var builder = self
        builder.hints.append(PreloadHint(
            strategy: .preload,
            url: url,
            resourceType: .style,
            crossOrigin: crossOrigin,
            fetchPriority: fetchPriority,
            integrity: integrity,
            media: media
        ))
        return builder
    }

    /// Preload a critical font
    public func preloadFont(
        url: String,
        mimeType: String? = nil,
        crossOrigin: String? = "anonymous",
        fetchPriority: PreloadHint.FetchPriority? = .high
    ) -> PreloadStrategyBuilder {
        var builder = self
        builder.hints.append(PreloadHint(
            strategy: .preload,
            url: url,
            resourceType: .font,
            mimeType: mimeType,
            crossOrigin: crossOrigin,
            fetchPriority: fetchPriority
        ))
        return builder
    }

    /// Preload a critical image
    public func preloadImage(
        url: String,
        mimeType: String? = nil,
        fetchPriority: PreloadHint.FetchPriority? = .high,
        media: String? = nil
    ) -> PreloadStrategyBuilder {
        var builder = self
        builder.hints.append(PreloadHint(
            strategy: .preload,
            url: url,
            resourceType: .image,
            mimeType: mimeType,
            fetchPriority: fetchPriority,
            media: media
        ))
        return builder
    }

    /// Preload data via fetch
    public func preloadFetch(
        url: String,
        crossOrigin: String? = "anonymous",
        fetchPriority: PreloadHint.FetchPriority? = nil
    ) -> PreloadStrategyBuilder {
        var builder = self
        builder.hints.append(PreloadHint(
            strategy: .preload,
            url: url,
            resourceType: .fetch,
            crossOrigin: crossOrigin,
            fetchPriority: fetchPriority
        ))
        return builder
    }

    /// Preload an ES module
    public func preloadModule(
        url: String,
        integrity: String? = nil,
        crossOrigin: String? = "anonymous",
        fetchPriority: PreloadHint.FetchPriority? = .high
    ) -> PreloadStrategyBuilder {
        var builder = self
        builder.hints.append(PreloadHint(
            strategy: .modulepreload,
            url: url,
            resourceType: .script,
            crossOrigin: crossOrigin,
            fetchPriority: fetchPriority,
            integrity: integrity
        ))
        return builder
    }

    // MARK: - Future Resources (Prefetch)

    /// Prefetch a script for future navigation
    public func prefetchScript(url: String) -> PreloadStrategyBuilder {
        var builder = self
        builder.hints.append(PreloadHint(
            strategy: .prefetch,
            url: url,
            resourceType: .script
        ))
        return builder
    }

    /// Prefetch a stylesheet for future navigation
    public func prefetchStylesheet(url: String) -> PreloadStrategyBuilder {
        var builder = self
        builder.hints.append(PreloadHint(
            strategy: .prefetch,
            url: url,
            resourceType: .style
        ))
        return builder
    }

    /// Prefetch an image for future use
    public func prefetchImage(url: String) -> PreloadStrategyBuilder {
        var builder = self
        builder.hints.append(PreloadHint(
            strategy: .prefetch,
            url: url,
            resourceType: .image
        ))
        return builder
    }

    /// Prefetch a document for future navigation
    public func prefetchDocument(url: String) -> PreloadStrategyBuilder {
        var builder = self
        builder.hints.append(PreloadHint(
            strategy: .prefetch,
            url: url,
            resourceType: .document
        ))
        return builder
    }

    // MARK: - Connection Optimization

    /// Preconnect to a domain
    public func preconnect(
        url: String,
        crossOrigin: Bool = false
    ) -> PreloadStrategyBuilder {
        var builder = self
        builder.hints.append(PreloadHint(
            strategy: .preconnect,
            url: url,
            crossOrigin: crossOrigin ? "anonymous" : nil
        ))
        return builder
    }

    /// DNS-prefetch a domain
    public func dnsPrefetch(url: String) -> PreloadStrategyBuilder {
        var builder = self
        builder.hints.append(PreloadHint(
            strategy: .dnsPrefetch,
            url: url
        ))
        return builder
    }

    // MARK: - Custom Hint

    /// Add a custom preload hint
    public func custom(hint: PreloadHint) -> PreloadStrategyBuilder {
        var builder = self
        builder.hints.append(hint)
        return builder
    }

    // MARK: - Build

    /// Build the collection of preload hints
    public func build() -> [PreloadHint] {
        hints
    }
}

// MARK: - Common Strategies

extension PreloadStrategyBuilder {
    /// Create a strategy for a typical SPA (Single Page Application)
    public static func spa(
        appJS: String,
        appCSS: String,
        fonts: [String] = [],
        apiEndpoint: String? = nil
    ) -> PreloadStrategyBuilder {
        var builder = PreloadStrategyBuilder()
            .preloadScript(url: appJS)
            .preloadStylesheet(url: appCSS)

        for font in fonts {
            builder = builder.preloadFont(url: font)
        }

        if let apiEndpoint = apiEndpoint {
            builder = builder.preconnect(url: apiEndpoint, crossOrigin: true)
        }

        return builder
    }

    /// Create a strategy for content-heavy pages
    public static func contentHeavy(
        heroImage: String? = nil,
        criticalFonts: [String] = [],
        cdnDomains: [String] = []
    ) -> PreloadStrategyBuilder {
        var builder = PreloadStrategyBuilder()

        if let heroImage = heroImage {
            builder = builder.preloadImage(url: heroImage, fetchPriority: .high)
        }

        for font in criticalFonts {
            builder = builder.preloadFont(url: font)
        }

        for domain in cdnDomains {
            builder = builder.preconnect(url: domain)
        }

        return builder
    }

    /// Create a strategy for progressive web apps
    public static func pwa(
        appJS: String,
        appCSS: String,
        manifestURL: String,
        serviceWorkerURL: String,
        icons: [String] = []
    ) -> PreloadStrategyBuilder {
        var builder = PreloadStrategyBuilder()
            .preloadScript(url: appJS, fetchPriority: .high)
            .preloadStylesheet(url: appCSS, fetchPriority: .high)
            .preloadFetch(url: manifestURL)
            .prefetchScript(url: serviceWorkerURL)

        for icon in icons {
            builder = builder.preloadImage(url: icon)
        }

        return builder
    }

    /// Create a strategy for multi-page applications
    public static func mpa(
        commonCSS: String,
        commonJS: String,
        nextPages: [String] = []
    ) -> PreloadStrategyBuilder {
        var builder = PreloadStrategyBuilder()
            .preloadStylesheet(url: commonCSS)
            .preloadScript(url: commonJS)

        for page in nextPages {
            builder = builder.prefetchDocument(url: page)
        }

        return builder
    }
}

// MARK: - HTML Escaping Helper

private func escapeHTML(_ string: String) -> String {
    string
        .replacingOccurrences(of: "&", with: "&amp;")
        .replacingOccurrences(of: "<", with: "&lt;")
        .replacingOccurrences(of: ">", with: "&gt;")
        .replacingOccurrences(of: "\"", with: "&quot;")
        .replacingOccurrences(of: "'", with: "&#39;")
}
