import Foundation

/// Serializes VNodes to HTML strings with proper escaping and hydration markers
public struct HTMLSerializer: Sendable {
    // MARK: - Configuration

    /// Serialization configuration
    public struct Configuration: Sendable {
        /// Whether to include hydration markers
        public let includeHydrationMarkers: Bool

        /// Whether to minify the output HTML
        public let minify: Bool

        /// Whether to include debug comments
        public let includeDebugComments: Bool

        /// Whether to self-close void elements
        public let selfCloseVoidElements: Bool

        /// Indentation string (used when not minified)
        public let indentation: String

        /// Create a new configuration
        public init(
            includeHydrationMarkers: Bool = true,
            minify: Bool = false,
            includeDebugComments: Bool = false,
            selfCloseVoidElements: Bool = true,
            indentation: String = "  "
        ) {
            self.includeHydrationMarkers = includeHydrationMarkers
            self.minify = minify
            self.includeDebugComments = includeDebugComments
            self.selfCloseVoidElements = selfCloseVoidElements
            self.indentation = indentation
        }

        /// Default configuration
        public static let `default` = Configuration()

        /// Production configuration with minification
        public static let production = Configuration(
            includeHydrationMarkers: true,
            minify: true,
            includeDebugComments: false
        )

        /// Development configuration with debug info
        public static let development = Configuration(
            includeHydrationMarkers: true,
            minify: false,
            includeDebugComments: true
        )
    }

    // MARK: - Properties

    private let configuration: Configuration

    /// Create a new HTML serializer
    public init(configuration: Configuration = .default) {
        self.configuration = configuration
    }

    // MARK: - Serialization

    /// Serialize a VNode tree to an HTML string
    public func serialize(_ node: VNode, depth: Int = 0) -> String {
        switch node.type {
        case .element(let tag):
            return serializeElement(node, tag: tag, depth: depth)
        case .text(let content):
            return serializeText(content, depth: depth)
        case .component:
            return serializeComponent(node, depth: depth)
        case .fragment:
            return serializeFragment(node, depth: depth)
        }
    }

    /// Serialize multiple VNodes
    public func serialize(_ nodes: [VNode], depth: Int = 0) -> String {
        nodes.map { serialize($0, depth: depth) }.joined(separator: newline)
    }

    // MARK: - Element Serialization

    private func serializeElement(_ node: VNode, tag: String, depth: Int) -> String {
        var html = ""

        // Add debug comment
        if configuration.includeDebugComments {
            html += indent(depth) + "<!-- \(tag) node: \(node.id.uuidString) -->\n"
        }

        // Opening tag
        html += indent(depth) + "<\(tag)"

        // Add attributes and styles
        html += serializeProperties(node.props)

        // Add hydration marker
        if configuration.includeHydrationMarkers {
            html += " data-raven-id=\"\(node.id.uuidString)\""
            if let key = node.key {
                html += " data-raven-key=\"\(escapeAttribute(key))\""
            }
        }

        // Handle void elements
        if isVoidElement(tag) {
            if configuration.selfCloseVoidElements {
                html += " />"
            } else {
                html += ">"
            }
            return html
        }

        html += ">"

        // Children
        if !node.children.isEmpty {
            let childrenHTML = node.children.map { child in
                serialize(child, depth: depth + 1)
            }.joined(separator: newline)

            if !configuration.minify && !node.children.allSatisfy({ $0.isText }) {
                html += newline + childrenHTML + newline + indent(depth)
            } else {
                html += childrenHTML
            }
        }

        // Closing tag
        html += "</\(tag)>"

        return html
    }

    // MARK: - Text Serialization

    private func serializeText(_ content: String, depth: Int) -> String {
        let escaped = escapeHTML(content)
        return configuration.minify ? escaped : indent(depth) + escaped
    }

    // MARK: - Component Serialization

    private func serializeComponent(_ node: VNode, depth: Int) -> String {
        // Components are rendered as their children
        if configuration.includeDebugComments {
            var html = indent(depth) + "<!-- Component: \(node.id.uuidString) -->\n"
            html += serialize(node.children, depth: depth)
            html += "\n" + indent(depth) + "<!-- /Component -->"
            return html
        }
        return serialize(node.children, depth: depth)
    }

    // MARK: - Fragment Serialization

    private func serializeFragment(_ node: VNode, depth: Int) -> String {
        // Fragments render their children without a wrapper
        if configuration.includeHydrationMarkers {
            var html = ""
            if configuration.includeDebugComments {
                html += indent(depth) + "<!-- Fragment: \(node.id.uuidString) -->\n"
            }
            html += "<template data-raven-fragment=\"\(node.id.uuidString)\">"
            html += serialize(node.children, depth: depth)
            html += "</template>"
            return html
        }
        return serialize(node.children, depth: depth)
    }

    // MARK: - Property Serialization

    private func serializeProperties(_ props: [String: VProperty]) -> String {
        var attributes: [String] = []

        for (_, value) in props.sorted(by: { $0.key < $1.key }) {
            switch value {
            case .attribute(let name, let attrValue):
                attributes.append("\(name)=\"\(escapeAttribute(attrValue))\"")

            case .boolAttribute(let name, let boolValue):
                if boolValue {
                    attributes.append(name)
                }

            case .style:
                // Styles will be collected and added as a style attribute
                continue

            case .eventHandler:
                // Event handlers are not serialized in SSR
                // They will be attached during hydration
                continue
            }
        }

        // Collect all styles into a single style attribute
        let styles = props.values.compactMap { prop -> (String, String)? in
            if case .style(let name, let value) = prop {
                return (name, value)
            }
            return nil
        }

        if !styles.isEmpty {
            let styleString = styles
                .sorted { $0.0 < $1.0 }
                .map { "\($0.0): \(escapeAttribute($0.1))" }
                .joined(separator: "; ")
            attributes.append("style=\"\(styleString)\"")
        }

        return attributes.isEmpty ? "" : " " + attributes.joined(separator: " ")
    }

    // MARK: - Helpers

    private var newline: String {
        configuration.minify ? "" : "\n"
    }

    private func indent(_ depth: Int) -> String {
        configuration.minify ? "" : String(repeating: configuration.indentation, count: depth)
    }

    private func isVoidElement(_ tag: String) -> Bool {
        voidElements.contains(tag.lowercased())
    }
}

// MARK: - Void Elements

/// HTML void elements that don't have closing tags
private let voidElements: Set<String> = [
    "area", "base", "br", "col", "embed", "hr", "img", "input",
    "link", "meta", "param", "source", "track", "wbr"
]

// MARK: - HTML Escaping

/// Escape HTML special characters
private func escapeHTML(_ string: String) -> String {
    string
        .replacingOccurrences(of: "&", with: "&amp;")
        .replacingOccurrences(of: "<", with: "&lt;")
        .replacingOccurrences(of: ">", with: "&gt;")
        .replacingOccurrences(of: "\"", with: "&quot;")
        .replacingOccurrences(of: "'", with: "&#39;")
}

/// Escape HTML attribute values
private func escapeAttribute(_ string: String) -> String {
    string
        .replacingOccurrences(of: "&", with: "&amp;")
        .replacingOccurrences(of: "\"", with: "&quot;")
        .replacingOccurrences(of: "<", with: "&lt;")
        .replacingOccurrences(of: ">", with: "&gt;")
}

// MARK: - Document Serializer

/// Serializes complete HTML documents with DOCTYPE and metadata
public struct HTMLDocumentSerializer: Sendable {
    /// Document configuration
    public struct DocumentConfiguration: Sendable {
        /// HTML language attribute
        public let language: String

        /// Document title
        public let title: String?

        /// Meta tags to include
        public let metaTags: [MetaTag]

        /// Preload hints to include
        public let preloadHints: [PreloadHint]

        /// Scripts to include
        public let scripts: [Script]

        /// Stylesheets to include
        public let stylesheets: [Stylesheet]

        /// Inline styles
        public let inlineStyles: String?

        /// Body attributes
        public let bodyAttributes: [String: String]

        /// Additional head content
        public let additionalHeadContent: String?

        /// Create a new document configuration
        public init(
            language: String = "en",
            title: String? = nil,
            metaTags: [MetaTag] = [],
            preloadHints: [PreloadHint] = [],
            scripts: [Script] = [],
            stylesheets: [Stylesheet] = [],
            inlineStyles: String? = nil,
            bodyAttributes: [String: String] = [:],
            additionalHeadContent: String? = nil
        ) {
            self.language = language
            self.title = title
            self.metaTags = metaTags
            self.preloadHints = preloadHints
            self.scripts = scripts
            self.stylesheets = stylesheets
            self.inlineStyles = inlineStyles
            self.bodyAttributes = bodyAttributes
            self.additionalHeadContent = additionalHeadContent
        }
    }

    private let serializer: HTMLSerializer
    private let docConfig: DocumentConfiguration

    /// Create a new document serializer
    public init(
        configuration: HTMLSerializer.Configuration = .default,
        documentConfiguration: DocumentConfiguration
    ) {
        self.serializer = HTMLSerializer(configuration: configuration)
        self.docConfig = documentConfiguration
    }

    /// Serialize a complete HTML document
    public func serializeDocument(body: VNode) -> String {
        var html = "<!DOCTYPE html>\n"
        html += "<html lang=\"\(escapeAttribute(docConfig.language))\">\n"
        html += "<head>\n"

        // Meta tags
        html += "  <meta charset=\"UTF-8\">\n"
        html += "  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n"

        // Title
        if let title = docConfig.title {
            html += "  <title>\(escapeHTML(title))</title>\n"
        }

        // Additional meta tags
        for metaTag in docConfig.metaTags {
            html += "  \(metaTag.toHTML())\n"
        }

        // Preload hints
        for hint in docConfig.preloadHints {
            html += "  \(hint.toHTML())\n"
        }

        // Stylesheets
        for stylesheet in docConfig.stylesheets {
            html += "  \(serializeStylesheet(stylesheet))\n"
        }

        // Inline styles
        if let inlineStyles = docConfig.inlineStyles {
            html += "  <style>\(inlineStyles)</style>\n"
        }

        // Additional head content
        if let additionalHead = docConfig.additionalHeadContent {
            html += "  \(additionalHead)\n"
        }

        html += "</head>\n"

        // Body
        let bodyAttrs = docConfig.bodyAttributes
            .sorted { $0.key < $1.key }
            .map { "\($0.key)=\"\(escapeAttribute($0.value))\"" }
            .joined(separator: " ")

        if bodyAttrs.isEmpty {
            html += "<body>\n"
        } else {
            html += "<body \(bodyAttrs)>\n"
        }

        // Body content
        html += serializer.serialize(body, depth: 1)
        html += "\n"

        // Scripts
        for script in docConfig.scripts {
            html += "  \(serializeScript(script))\n"
        }

        html += "</body>\n"
        html += "</html>"

        return html
    }

    private func serializeStylesheet(_ stylesheet: Stylesheet) -> String {
        switch stylesheet.source {
        case .external(let url):
            var attrs = ["rel=\"stylesheet\"", "href=\"\(escapeAttribute(url))\""]
            if let media = stylesheet.media {
                attrs.append("media=\"\(escapeAttribute(media))\"")
            }
            if let integrity = stylesheet.integrity {
                attrs.append("integrity=\"\(escapeAttribute(integrity))\"")
            }
            if let crossOrigin = stylesheet.crossOrigin {
                attrs.append("crossorigin=\"\(escapeAttribute(crossOrigin))\"")
            }
            return "<link \(attrs.joined(separator: " "))>"

        case .inline(let content):
            return "<style>\(content)</style>"
        }
    }

    private func serializeScript(_ script: Script) -> String {
        var attrs: [String] = []

        if let type = script.type {
            attrs.append("type=\"\(escapeAttribute(type))\"")
        }

        if script.async {
            attrs.append("async")
        }

        if script.defer {
            attrs.append("defer")
        }

        if let integrity = script.integrity {
            attrs.append("integrity=\"\(escapeAttribute(integrity))\"")
        }

        if let crossOrigin = script.crossOrigin {
            attrs.append("crossorigin=\"\(escapeAttribute(crossOrigin))\"")
        }

        switch script.source {
        case .external(let url):
            attrs.insert("src=\"\(escapeAttribute(url))\"", at: 0)
            return "<script \(attrs.joined(separator: " "))></script>"

        case .inline(let content):
            let attrsString = attrs.isEmpty ? "" : " " + attrs.joined(separator: " ")
            return "<script\(attrsString)>\(content)</script>"
        }
    }
}
