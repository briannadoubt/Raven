import Foundation

/// Main entry point for server-side rendering of SwiftUI views to static HTML
public struct StaticRenderer: Sendable {
    // MARK: - Configuration

    /// Rendering configuration
    public struct Configuration: Sendable {
        /// HTML serialization configuration
        public let serializerConfig: HTMLSerializer.Configuration

        /// Cache policy for the rendered output
        public let cachePolicy: CachePolicy

        /// SSR cache configuration
        public let cacheConfig: SSRCacheConfiguration

        /// Default language for HTML documents
        public let defaultLanguage: String

        /// Whether to include hydration markers
        public let enableHydration: Bool

        /// Whether to include performance metrics
        public let includeMetrics: Bool

        /// Create a new rendering configuration
        public init(
            serializerConfig: HTMLSerializer.Configuration = .default,
            cachePolicy: CachePolicy = .ssrDefault,
            cacheConfig: SSRCacheConfiguration = .production,
            defaultLanguage: String = "en",
            enableHydration: Bool = true,
            includeMetrics: Bool = false
        ) {
            self.serializerConfig = serializerConfig
            self.cachePolicy = cachePolicy
            self.cacheConfig = cacheConfig
            self.defaultLanguage = defaultLanguage
            self.enableHydration = enableHydration
            self.includeMetrics = includeMetrics
        }

        /// Production configuration
        public static let production = Configuration(
            serializerConfig: .production,
            cachePolicy: .ssrDefault,
            cacheConfig: .production,
            enableHydration: true,
            includeMetrics: false
        )

        /// Development configuration
        public static let development = Configuration(
            serializerConfig: .development,
            cachePolicy: .noCache,
            cacheConfig: .development,
            enableHydration: true,
            includeMetrics: true
        )
    }

    // MARK: - Properties

    private let configuration: Configuration
    private let serializer: HTMLSerializer

    /// Create a new static renderer
    public init(configuration: Configuration = .production) {
        self.configuration = configuration
        self.serializer = HTMLSerializer(configuration: configuration.serializerConfig)
    }

    // MARK: - Rendering

    /// Render a VNode tree to an HTML string
    /// - Parameters:
    ///   - vnode: The virtual DOM node to render
    ///   - context: Rendering context with metadata and configuration
    /// - Returns: Rendered HTML string
    public func renderToString(
        _ vnode: VNode,
        context: RenderContext = RenderContext()
    ) -> String {
        serializer.serialize(vnode)
    }

    /// Render a complete HTML document
    /// - Parameters:
    ///   - vnode: The virtual DOM node for the body content
    ///   - context: Rendering context with metadata and configuration
    ///   - title: Document title
    ///   - additionalMetaTags: Additional meta tags beyond what's in the context
    ///   - additionalPreloadHints: Additional preload hints beyond what's in the context
    /// - Returns: Complete HTML document string
    public func renderDocument(
        _ vnode: VNode,
        context: RenderContext = RenderContext(),
        title: String? = nil,
        additionalMetaTags: [MetaTag] = [],
        additionalPreloadHints: [PreloadHint] = []
    ) -> RenderedDocument {
        let startTime = Date()

        // Combine meta tags
        var allMetaTags = context.metaTags + additionalMetaTags

        // Add default viewport if not present
        if !allMetaTags.contains(where: { tag in
            if case .viewport = tag.type { return true }
            return false
        }) {
            allMetaTags.insert(
                MetaTag(type: .viewport("width=device-width, initial-scale=1.0")),
                at: 0
            )
        }

        // Add charset if not present
        if !allMetaTags.contains(where: { tag in
            if case .charset = tag.type { return true }
            return false
        }) {
            allMetaTags.insert(
                MetaTag(type: .charset("UTF-8")),
                at: 0
            )
        }

        // Combine preload hints
        let allPreloadHints = context.preloadHints + additionalPreloadHints

        // Create document configuration
        let docConfig = HTMLDocumentSerializer.DocumentConfiguration(
            language: configuration.defaultLanguage,
            title: title,
            metaTags: allMetaTags,
            preloadHints: allPreloadHints,
            scripts: context.scripts,
            stylesheets: context.stylesheets
        )

        // Serialize the document
        let docSerializer = HTMLDocumentSerializer(
            configuration: configuration.serializerConfig,
            documentConfiguration: docConfig
        )

        let html = docSerializer.serializeDocument(body: vnode)
        let renderDuration = Date().timeIntervalSince(startTime)

        // Get cache policy for the path
        let path = context.url?.path ?? "/"
        let cachePolicy = configuration.cacheConfig.policy(for: path)
        var headers = configuration.cacheConfig.headers(for: path, content: html)

        // Add standard headers
        headers["Content-Type"] = "text/html; charset=utf-8"
        headers["X-Powered-By"] = "Raven"

        // Add performance metrics if enabled
        if configuration.includeMetrics {
            headers["Server-Timing"] = "render;dur=\(Int(renderDuration * 1000))"
        }

        return RenderedDocument(
            html: html,
            headers: headers,
            cachePolicy: cachePolicy,
            renderDuration: renderDuration,
            context: context
        )
    }

    /// Render with automatic meta tag generation
    /// - Parameters:
    ///   - vnode: The virtual DOM node for the body content
    ///   - context: Rendering context
    ///   - seo: SEO configuration
    /// - Returns: Complete HTML document string
    public func renderWithSEO(
        _ vnode: VNode,
        context: RenderContext = RenderContext(),
        seo: SEOConfiguration
    ) -> RenderedDocument {
        let metaTags = generateSEOMetaTags(from: seo, url: context.url)
        let preloadHints = generatePreloadHints(from: seo)

        return renderDocument(
            vnode,
            context: context,
            title: seo.title,
            additionalMetaTags: metaTags,
            additionalPreloadHints: preloadHints
        )
    }

    // MARK: - SEO Helpers

    private func generateSEOMetaTags(from seo: SEOConfiguration, url: URL?) -> [MetaTag] {
        var builder = MetaTagBuilder()
            .description(seo.description)

        if let keywords = seo.keywords {
            builder = builder.keywords(keywords)
        }

        if let author = seo.author {
            builder = builder.author(author)
        }

        if let canonicalURL = seo.canonicalURL ?? url?.absoluteString {
            builder = builder.canonical(canonicalURL)
        }

        // OpenGraph
        builder = builder
            .ogTitle(seo.ogTitle ?? seo.title)
            .ogDescription(seo.ogDescription ?? seo.description)
            .ogType(seo.ogType ?? "website")

        if let ogURL = seo.ogURL ?? url?.absoluteString {
            builder = builder.ogURL(ogURL)
        }

        if let ogImage = seo.ogImage {
            builder = builder.ogImage(
                url: ogImage.url,
                width: ogImage.width,
                height: ogImage.height,
                alt: ogImage.alt
            )
        }

        if let siteName = seo.siteName {
            builder = builder.ogSiteName(siteName)
        }

        // Twitter
        if let twitterCard = seo.twitterCard {
            builder = builder.twitterCard(twitterCard)
        }

        if let twitterSite = seo.twitterSite {
            builder = builder.twitterSite(twitterSite)
        }

        if let twitterCreator = seo.twitterCreator {
            builder = builder.twitterCreator(twitterCreator)
        }

        // Robots
        builder = builder.robots(index: seo.indexable, follow: seo.followable)

        return builder.build()
    }

    private func generatePreloadHints(from seo: SEOConfiguration) -> [PreloadHint] {
        var hints: [PreloadHint] = []

        // Preload critical images
        if let ogImage = seo.ogImage {
            hints.append(PreloadHint(
                strategy: .preload,
                url: ogImage.url,
                resourceType: .image,
                fetchPriority: .high
            ))
        }

        return hints
    }
}

// MARK: - Rendered Document

/// Represents a fully rendered HTML document with metadata
public struct RenderedDocument: Sendable {
    /// The rendered HTML content
    public let html: String

    /// HTTP headers to send with the response
    public let headers: [String: String]

    /// Cache policy for this document
    public let cachePolicy: CachePolicy

    /// Time taken to render the document
    public let renderDuration: TimeInterval

    /// The rendering context used
    public let context: RenderContext

    /// The size of the HTML in bytes
    public var byteSize: Int {
        html.utf8.count
    }

    /// Create a new rendered document
    public init(
        html: String,
        headers: [String: String],
        cachePolicy: CachePolicy,
        renderDuration: TimeInterval,
        context: RenderContext
    ) {
        self.html = html
        self.headers = headers
        self.cachePolicy = cachePolicy
        self.renderDuration = renderDuration
        self.context = context
    }
}

// MARK: - SEO Configuration

/// Configuration for SEO metadata
public struct SEOConfiguration: Sendable {
    // MARK: - Basic SEO

    /// Page title
    public let title: String

    /// Page description
    public let description: String

    /// Keywords
    public let keywords: [String]?

    /// Author
    public let author: String?

    /// Canonical URL
    public let canonicalURL: String?

    /// Whether the page should be indexed
    public let indexable: Bool

    /// Whether links should be followed
    public let followable: Bool

    // MARK: - OpenGraph

    /// OpenGraph title
    public let ogTitle: String?

    /// OpenGraph description
    public let ogDescription: String?

    /// OpenGraph type
    public let ogType: String?

    /// OpenGraph URL
    public let ogURL: String?

    /// OpenGraph image
    public let ogImage: OGImage?

    /// Site name
    public let siteName: String?

    // MARK: - Twitter

    /// Twitter card type
    public let twitterCard: String?

    /// Twitter site handle
    public let twitterSite: String?

    /// Twitter creator handle
    public let twitterCreator: String?

    /// OpenGraph image configuration
    public struct OGImage: Sendable {
        public let url: String
        public let width: Int?
        public let height: Int?
        public let alt: String?

        public init(url: String, width: Int? = nil, height: Int? = nil, alt: String? = nil) {
            self.url = url
            self.width = width
            self.height = height
            self.alt = alt
        }
    }

    /// Create a new SEO configuration
    public init(
        title: String,
        description: String,
        keywords: [String]? = nil,
        author: String? = nil,
        canonicalURL: String? = nil,
        indexable: Bool = true,
        followable: Bool = true,
        ogTitle: String? = nil,
        ogDescription: String? = nil,
        ogType: String? = nil,
        ogURL: String? = nil,
        ogImage: OGImage? = nil,
        siteName: String? = nil,
        twitterCard: String? = nil,
        twitterSite: String? = nil,
        twitterCreator: String? = nil
    ) {
        self.title = title
        self.description = description
        self.keywords = keywords
        self.author = author
        self.canonicalURL = canonicalURL
        self.indexable = indexable
        self.followable = followable
        self.ogTitle = ogTitle
        self.ogDescription = ogDescription
        self.ogType = ogType
        self.ogURL = ogURL
        self.ogImage = ogImage
        self.siteName = siteName
        self.twitterCard = twitterCard
        self.twitterSite = twitterSite
        self.twitterCreator = twitterCreator
    }

    /// Create a basic SEO configuration
    public static func basic(title: String, description: String) -> SEOConfiguration {
        SEOConfiguration(title: title, description: description)
    }
}

// MARK: - Batch Rendering

extension StaticRenderer {
    /// Render multiple pages in parallel
    /// - Parameter pages: Dictionary of path to VNode
    /// - Returns: Dictionary of path to rendered document
    public func renderPages(
        _ pages: [String: VNode],
        baseContext: RenderContext = RenderContext()
    ) async -> [String: RenderedDocument] {
        await withTaskGroup(of: (String, RenderedDocument).self) { group in
            for (path, vnode) in pages {
                group.addTask {
                    var context = baseContext
                    if let url = URL(string: path) {
                        context = RenderContext(
                            url: url,
                            userAgent: baseContext.userAgent,
                            headers: baseContext.headers,
                            includeHydrationMarkers: baseContext.includeHydrationMarkers,
                            minifyHTML: baseContext.minifyHTML,
                            includeDebugInfo: baseContext.includeDebugInfo
                        )
                    }
                    let document = self.renderDocument(vnode, context: context)
                    return (path, document)
                }
            }

            var results: [String: RenderedDocument] = [:]
            for await (path, document) in group {
                results[path] = document
            }
            return results
        }
    }
}
