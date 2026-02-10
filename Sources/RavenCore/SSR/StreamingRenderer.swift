import Foundation

/// Streaming renderer for generating HTML progressively
///
/// StreamingRenderer enables progressive rendering where HTML is sent to the client
/// in chunks as it's generated, reducing time-to-first-byte and improving perceived
/// performance. Supports Suspense boundaries for async content loading.
public actor StreamingRenderer {
    // MARK: - Configuration

    /// Streaming configuration
    public struct Configuration: Sendable {
        /// HTML serializer configuration
        public let serializerConfig: HTMLSerializer.Configuration

        /// Chunk size in bytes before flushing
        public let chunkSize: Int

        /// Whether to enable suspense boundaries
        public let enableSuspense: Bool

        /// Placeholder content for suspended components
        public let suspensePlaceholder: String

        /// Maximum time to wait for suspended content (milliseconds)
        public let suspenseTimeout: Int

        /// Create a new streaming configuration
        public init(
            serializerConfig: HTMLSerializer.Configuration = .production,
            chunkSize: Int = 8192,
            enableSuspense: Bool = true,
            suspensePlaceholder: String = "<div class=\"loading\">Loading...</div>",
            suspenseTimeout: Int = 5000
        ) {
            self.serializerConfig = serializerConfig
            self.chunkSize = chunkSize
            self.enableSuspense = enableSuspense
            self.suspensePlaceholder = suspensePlaceholder
            self.suspenseTimeout = suspenseTimeout
        }

        /// Default streaming configuration
        public static let `default` = Configuration()

        /// Production configuration
        public static let production = Configuration(
            serializerConfig: .production,
            enableSuspense: true
        )
    }

    // MARK: - Properties

    private let configuration: Configuration
    private let serializer: HTMLSerializer

    /// Create a new streaming renderer
    public init(configuration: Configuration = .default) {
        self.configuration = configuration
        self.serializer = HTMLSerializer(configuration: configuration.serializerConfig)
    }

    // MARK: - Streaming

    /// Stream render a VNode tree
    /// - Parameters:
    ///   - vnode: The VNode tree to render
    ///   - context: Render context
    ///   - onChunk: Callback for each HTML chunk
    public func streamRender(
        _ vnode: VNode,
        context: RenderContext = RenderContext(),
        onChunk: @Sendable @escaping (String) async -> Void
    ) async throws {
        var buffer = StreamBuffer(maxSize: configuration.chunkSize)

        // Start with doctype and opening tags
        await buffer.append("<!DOCTYPE html>\n", flushTo: onChunk)
        await buffer.append("<html lang=\"en\">\n", flushTo: onChunk)
        await buffer.append("<head>\n", flushTo: onChunk)

        // Render head content
        await renderHead(context: context, buffer: &buffer, onChunk: onChunk)

        await buffer.append("</head>\n", flushTo: onChunk)
        await buffer.append("<body>\n", flushTo: onChunk)

        // Render body content
        await renderNode(vnode, buffer: &buffer, onChunk: onChunk, depth: 1)

        await buffer.append("\n</body>\n", flushTo: onChunk)
        await buffer.append("</html>", flushTo: onChunk)

        // Flush remaining content
        await buffer.flush(to: onChunk)
    }

    /// Stream render a complete document
    /// - Parameters:
    ///   - vnode: The VNode tree for body content
    ///   - context: Render context
    ///   - seo: SEO configuration
    ///   - onChunk: Callback for each HTML chunk
    public func streamRenderDocument(
        _ vnode: VNode,
        context: RenderContext = RenderContext(),
        seo: SEOConfiguration? = nil,
        onChunk: @Sendable @escaping (String) async -> Void
    ) async throws {
        var buffer = StreamBuffer(maxSize: configuration.chunkSize)

        // Document start
        await buffer.append("<!DOCTYPE html>\n", flushTo: onChunk)
        await buffer.append("<html lang=\"en\">\n", flushTo: onChunk)
        await buffer.append("<head>\n", flushTo: onChunk)

        // Render head with SEO
        var headContext = context
        if let seo = seo {
            let metaTags = generateSEOMetaTags(from: seo, url: context.url)
            headContext.addMetaTags(metaTags)
        }

        await renderHead(context: headContext, buffer: &buffer, onChunk: onChunk)

        await buffer.append("</head>\n", flushTo: onChunk)
        await buffer.append("<body>\n", flushTo: onChunk)

        // Force flush to send initial HTML quickly
        await buffer.flush(to: onChunk)

        // Render body progressively
        await renderNode(vnode, buffer: &buffer, onChunk: onChunk, depth: 1)

        await buffer.append("\n</body>\n", flushTo: onChunk)
        await buffer.append("</html>", flushTo: onChunk)

        await buffer.flush(to: onChunk)
    }

    // MARK: - Head Rendering

    private func renderHead(
        context: RenderContext,
        buffer: inout StreamBuffer,
        onChunk: @Sendable @escaping (String) async -> Void
    ) async {
        // Meta tags
        await buffer.append("  <meta charset=\"UTF-8\">\n", flushTo: onChunk)
        await buffer.append("  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n", flushTo: onChunk)

        for metaTag in context.metaTags {
            await buffer.append("  \(metaTag.toHTML())\n", flushTo: onChunk)
        }

        // Preload hints
        for hint in context.preloadHints {
            await buffer.append("  \(hint.toHTML())\n", flushTo: onChunk)
        }

        // Stylesheets
        for stylesheet in context.stylesheets {
            await buffer.append("  \(renderStylesheet(stylesheet))\n", flushTo: onChunk)
        }
    }

    // MARK: - Node Rendering

    private func renderNode(
        _ vnode: VNode,
        buffer: inout StreamBuffer,
        onChunk: @Sendable @escaping (String) async -> Void,
        depth: Int
    ) async {
        switch vnode.type {
        case .element(let tag):
            await renderElement(vnode, tag: tag, buffer: &buffer, onChunk: onChunk, depth: depth)

        case .text(let content):
            await buffer.append(indent(depth) + escapeHTML(content), flushTo: onChunk)

        case .component:
            await renderComponent(vnode, buffer: &buffer, onChunk: onChunk, depth: depth)

        case .fragment:
            await renderFragment(vnode, buffer: &buffer, onChunk: onChunk, depth: depth)
        }
    }

    private func renderElement(
        _ vnode: VNode,
        tag: String,
        buffer: inout StreamBuffer,
        onChunk: @Sendable @escaping (String) async -> Void,
        depth: Int
    ) async {
        // Opening tag
        let html = serializer.serialize(vnode, depth: depth)
        await buffer.append(html, flushTo: onChunk)

        // Check if we should flush after this element
        if shouldFlushAfter(tag) {
            await buffer.flush(to: onChunk)
        }
    }

    private func renderComponent(
        _ vnode: VNode,
        buffer: inout StreamBuffer,
        onChunk: @Sendable @escaping (String) async -> Void,
        depth: Int
    ) async {
        // Render component children
        for child in vnode.children {
            await renderNode(child, buffer: &buffer, onChunk: onChunk, depth: depth)
        }
    }

    private func renderFragment(
        _ vnode: VNode,
        buffer: inout StreamBuffer,
        onChunk: @Sendable @escaping (String) async -> Void,
        depth: Int
    ) async {
        if configuration.serializerConfig.includeHydrationMarkers {
            await buffer.append("<template data-raven-fragment=\"\(vnode.id.uuidString)\">", flushTo: onChunk)
        }

        for child in vnode.children {
            await renderNode(child, buffer: &buffer, onChunk: onChunk, depth: depth)
        }

        if configuration.serializerConfig.includeHydrationMarkers {
            await buffer.append("</template>", flushTo: onChunk)
        }
    }

    // MARK: - Suspense Rendering

    /// Render with suspense boundaries
    /// - Parameters:
    ///   - vnode: The VNode tree to render
    ///   - suspenseNodes: Set of node IDs that should be suspended
    ///   - context: Render context
    ///   - onChunk: Callback for each HTML chunk
    public func streamRenderWithSuspense(
        _ vnode: VNode,
        suspenseNodes: Set<String>,
        context: RenderContext = RenderContext(),
        onChunk: @Sendable @escaping (String) async -> Void
    ) async throws {
        var buffer = StreamBuffer(maxSize: configuration.chunkSize)

        await buffer.append("<!DOCTYPE html>\n", flushTo: onChunk)
        await buffer.append("<html lang=\"en\">\n", flushTo: onChunk)
        await buffer.append("<head>\n", flushTo: onChunk)

        await renderHead(context: context, buffer: &buffer, onChunk: onChunk)

        await buffer.append("</head>\n", flushTo: onChunk)
        await buffer.append("<body>\n", flushTo: onChunk)

        // Flush head immediately
        await buffer.flush(to: onChunk)

        // Render body with suspense
        await renderNodeWithSuspense(
            vnode,
            suspenseNodes: suspenseNodes,
            buffer: &buffer,
            onChunk: onChunk,
            depth: 1
        )

        await buffer.append("\n</body>\n", flushTo: onChunk)
        await buffer.append("</html>", flushTo: onChunk)

        await buffer.flush(to: onChunk)
    }

    private func renderNodeWithSuspense(
        _ vnode: VNode,
        suspenseNodes: Set<String>,
        buffer: inout StreamBuffer,
        onChunk: @Sendable @escaping (String) async -> Void,
        depth: Int
    ) async {
        let nodeID = vnode.id.uuidString

        // Check if this node should be suspended
        if suspenseNodes.contains(nodeID) {
            // Render placeholder
            await buffer.append(
                "<div id=\"suspense-\(nodeID)\">\(configuration.suspensePlaceholder)</div>",
                flushTo: onChunk
            )

            // Render script to replace placeholder when content arrives
            await buffer.append(
                "<script>window.__suspense = window.__suspense || {}; window.__suspense['\(nodeID)'] = true;</script>",
                flushTo: onChunk
            )

            await buffer.flush(to: onChunk)
            return
        }

        // Normal rendering
        await renderNode(vnode, buffer: &buffer, onChunk: onChunk, depth: depth)
    }

    // MARK: - Helpers

    private func shouldFlushAfter(_ tag: String) -> Bool {
        // Flush after certain tags to improve perceived performance
        ["head", "header", "nav", "main"].contains(tag.lowercased())
    }

    private func renderStylesheet(_ stylesheet: Stylesheet) -> String {
        switch stylesheet.source {
        case .external(let url):
            return "<link rel=\"stylesheet\" href=\"\(escapeAttribute(url))\">"
        case .inline(let content):
            return "<style>\(content)</style>"
        }
    }

    private func generateSEOMetaTags(from seo: SEOConfiguration, url: URL?) -> [MetaTag] {
        var builder = MetaTagBuilder()
            .description(seo.description)

        if let keywords = seo.keywords {
            builder = builder.keywords(keywords)
        }

        builder = builder
            .ogTitle(seo.ogTitle ?? seo.title)
            .ogDescription(seo.ogDescription ?? seo.description)

        return builder.build()
    }

    private func indent(_ depth: Int) -> String {
        configuration.serializerConfig.minify ? "" : String(repeating: "  ", count: depth)
    }
}

// MARK: - Stream Buffer

/// Buffer for accumulating HTML chunks before flushing
private struct StreamBuffer: Sendable {
    private var content: String = ""
    private let maxSize: Int

    init(maxSize: Int) {
        self.maxSize = maxSize
    }

    mutating func append(
        _ string: String,
        flushTo onChunk: @Sendable @escaping (String) async -> Void
    ) async {
        content.append(string)

        if content.utf8.count >= maxSize {
            await flush(to: onChunk)
        }
    }

    mutating func flush(to onChunk: @Sendable @escaping (String) async -> Void) async {
        guard !content.isEmpty else { return }

        await onChunk(content)
        content.removeAll(keepingCapacity: true)
    }
}

// MARK: - Async Stream Extension

extension StreamingRenderer {
    /// Create an async stream of HTML chunks
    /// - Parameters:
    ///   - vnode: The VNode tree to render
    ///   - context: Render context
    /// - Returns: AsyncStream of HTML chunks
    public func streamAsyncSequence(
        _ vnode: VNode,
        context: RenderContext = RenderContext()
    ) -> AsyncStream<String> {
        AsyncStream { continuation in
            Task {
                do {
                    try await streamRender(vnode, context: context) { chunk in
                        continuation.yield(chunk)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish()
                }
            }
        }
    }
}

// MARK: - Suspense Boundary

/// Represents a suspense boundary for async content
public struct SuspenseBoundary: Sendable {
    /// Unique identifier for this boundary
    public let id: String

    /// Placeholder content while loading
    public let placeholder: String

    /// Timeout in milliseconds
    public let timeout: Int

    /// Fallback content if timeout is reached
    public let fallback: String?

    public init(
        id: String = UUID().uuidString,
        placeholder: String = "<div class=\"loading\">Loading...</div>",
        timeout: Int = 5000,
        fallback: String? = nil
    ) {
        self.id = id
        self.placeholder = placeholder
        self.timeout = timeout
        self.fallback = fallback
    }
}

// MARK: - HTML Escaping

private func escapeHTML(_ string: String) -> String {
    string
        .replacingOccurrences(of: "&", with: "&amp;")
        .replacingOccurrences(of: "<", with: "&lt;")
        .replacingOccurrences(of: ">", with: "&gt;")
        .replacingOccurrences(of: "\"", with: "&quot;")
        .replacingOccurrences(of: "'", with: "&#39;")
}

private func escapeAttribute(_ string: String) -> String {
    string
        .replacingOccurrences(of: "&", with: "&amp;")
        .replacingOccurrences(of: "\"", with: "&quot;")
        .replacingOccurrences(of: "<", with: "&lt;")
        .replacingOccurrences(of: ">", with: "&gt;")
}
