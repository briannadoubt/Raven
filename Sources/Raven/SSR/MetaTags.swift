import Foundation

/// Represents an HTML meta tag for SEO and social sharing
public struct MetaTag: Sendable, Hashable {
    /// Meta tag type
    public enum TagType: Sendable, Hashable {
        /// Standard meta tag with name and content
        case name(String, String)
        /// Property-based meta tag (OpenGraph, etc.)
        case property(String, String)
        /// HTTP-equiv meta tag
        case httpEquiv(String, String)
        /// Charset declaration
        case charset(String)
        /// Viewport configuration
        case viewport(String)
    }

    /// The meta tag type
    public let type: TagType

    /// Create a new meta tag
    public init(type: TagType) {
        self.type = type
    }

    /// Render the meta tag to HTML
    public func toHTML() -> String {
        switch type {
        case .name(let name, let content):
            return "<meta name=\"\(escapeHTML(name))\" content=\"\(escapeHTML(content))\">"
        case .property(let property, let content):
            return "<meta property=\"\(escapeHTML(property))\" content=\"\(escapeHTML(content))\">"
        case .httpEquiv(let equiv, let content):
            return "<meta http-equiv=\"\(escapeHTML(equiv))\" content=\"\(escapeHTML(content))\">"
        case .charset(let charset):
            return "<meta charset=\"\(escapeHTML(charset))\">"
        case .viewport(let content):
            return "<meta name=\"viewport\" content=\"\(escapeHTML(content))\">"
        }
    }
}

// MARK: - Meta Tag Builder

/// Builder for constructing comprehensive meta tag sets for SEO
public struct MetaTagBuilder: Sendable {
    private var tags: [MetaTag] = []

    /// Create a new meta tag builder
    public init() {}

    // MARK: - Basic Meta Tags

    /// Set the page title (for <title> tag, stored as name="title")
    public func title(_ title: String) -> MetaTagBuilder {
        var builder = self
        builder.tags.append(MetaTag(type: .name("title", title)))
        return builder
    }

    /// Set the page description
    public func description(_ description: String) -> MetaTagBuilder {
        var builder = self
        builder.tags.append(MetaTag(type: .name("description", description)))
        return builder
    }

    /// Set keywords
    public func keywords(_ keywords: [String]) -> MetaTagBuilder {
        var builder = self
        let keywordString = keywords.joined(separator: ", ")
        builder.tags.append(MetaTag(type: .name("keywords", keywordString)))
        return builder
    }

    /// Set the author
    public func author(_ author: String) -> MetaTagBuilder {
        var builder = self
        builder.tags.append(MetaTag(type: .name("author", author)))
        return builder
    }

    /// Set the canonical URL
    public func canonical(_ url: String) -> MetaTagBuilder {
        var builder = self
        builder.tags.append(MetaTag(type: .name("canonical", url)))
        return builder
    }

    /// Set robots directives
    public func robots(index: Bool = true, follow: Bool = true) -> MetaTagBuilder {
        var builder = self
        var directives: [String] = []
        directives.append(index ? "index" : "noindex")
        directives.append(follow ? "follow" : "nofollow")
        builder.tags.append(MetaTag(type: .name("robots", directives.joined(separator: ", "))))
        return builder
    }

    /// Set viewport configuration
    public func viewport(
        width: String = "device-width",
        initialScale: Double = 1.0,
        minimumScale: Double? = nil,
        maximumScale: Double? = nil,
        userScalable: Bool = true
    ) -> MetaTagBuilder {
        var builder = self
        var parts = ["width=\(width)", "initial-scale=\(initialScale)"]
        if let minimumScale = minimumScale {
            parts.append("minimum-scale=\(minimumScale)")
        }
        if let maximumScale = maximumScale {
            parts.append("maximum-scale=\(maximumScale)")
        }
        if !userScalable {
            parts.append("user-scalable=no")
        }
        builder.tags.append(MetaTag(type: .viewport(parts.joined(separator: ", "))))
        return builder
    }

    /// Set charset
    public func charset(_ charset: String = "UTF-8") -> MetaTagBuilder {
        var builder = self
        builder.tags.append(MetaTag(type: .charset(charset)))
        return builder
    }

    // MARK: - OpenGraph Tags

    /// Set OpenGraph title
    public func ogTitle(_ title: String) -> MetaTagBuilder {
        var builder = self
        builder.tags.append(MetaTag(type: .property("og:title", title)))
        return builder
    }

    /// Set OpenGraph description
    public func ogDescription(_ description: String) -> MetaTagBuilder {
        var builder = self
        builder.tags.append(MetaTag(type: .property("og:description", description)))
        return builder
    }

    /// Set OpenGraph type
    public func ogType(_ type: String) -> MetaTagBuilder {
        var builder = self
        builder.tags.append(MetaTag(type: .property("og:type", type)))
        return builder
    }

    /// Set OpenGraph URL
    public func ogURL(_ url: String) -> MetaTagBuilder {
        var builder = self
        builder.tags.append(MetaTag(type: .property("og:url", url)))
        return builder
    }

    /// Set OpenGraph image
    public func ogImage(
        url: String,
        width: Int? = nil,
        height: Int? = nil,
        alt: String? = nil
    ) -> MetaTagBuilder {
        var builder = self
        builder.tags.append(MetaTag(type: .property("og:image", url)))
        if let width = width {
            builder.tags.append(MetaTag(type: .property("og:image:width", String(width))))
        }
        if let height = height {
            builder.tags.append(MetaTag(type: .property("og:image:height", String(height))))
        }
        if let alt = alt {
            builder.tags.append(MetaTag(type: .property("og:image:alt", alt)))
        }
        return builder
    }

    /// Set OpenGraph site name
    public func ogSiteName(_ siteName: String) -> MetaTagBuilder {
        var builder = self
        builder.tags.append(MetaTag(type: .property("og:site_name", siteName)))
        return builder
    }

    /// Set OpenGraph locale
    public func ogLocale(_ locale: String) -> MetaTagBuilder {
        var builder = self
        builder.tags.append(MetaTag(type: .property("og:locale", locale)))
        return builder
    }

    // MARK: - Twitter Card Tags

    /// Set Twitter card type
    public func twitterCard(_ card: String = "summary_large_image") -> MetaTagBuilder {
        var builder = self
        builder.tags.append(MetaTag(type: .name("twitter:card", card)))
        return builder
    }

    /// Set Twitter site handle
    public func twitterSite(_ site: String) -> MetaTagBuilder {
        var builder = self
        builder.tags.append(MetaTag(type: .name("twitter:site", site)))
        return builder
    }

    /// Set Twitter creator handle
    public func twitterCreator(_ creator: String) -> MetaTagBuilder {
        var builder = self
        builder.tags.append(MetaTag(type: .name("twitter:creator", creator)))
        return builder
    }

    /// Set Twitter title
    public func twitterTitle(_ title: String) -> MetaTagBuilder {
        var builder = self
        builder.tags.append(MetaTag(type: .name("twitter:title", title)))
        return builder
    }

    /// Set Twitter description
    public func twitterDescription(_ description: String) -> MetaTagBuilder {
        var builder = self
        builder.tags.append(MetaTag(type: .name("twitter:description", description)))
        return builder
    }

    /// Set Twitter image
    public func twitterImage(url: String, alt: String? = nil) -> MetaTagBuilder {
        var builder = self
        builder.tags.append(MetaTag(type: .name("twitter:image", url)))
        if let alt = alt {
            builder.tags.append(MetaTag(type: .name("twitter:image:alt", alt)))
        }
        return builder
    }

    // MARK: - Additional SEO Tags

    /// Set theme color for mobile browsers
    public func themeColor(_ color: String) -> MetaTagBuilder {
        var builder = self
        builder.tags.append(MetaTag(type: .name("theme-color", color)))
        return builder
    }

    /// Set application name
    public func applicationName(_ name: String) -> MetaTagBuilder {
        var builder = self
        builder.tags.append(MetaTag(type: .name("application-name", name)))
        return builder
    }

    /// Set referrer policy
    public func referrerPolicy(_ policy: String) -> MetaTagBuilder {
        var builder = self
        builder.tags.append(MetaTag(type: .name("referrer", policy)))
        return builder
    }

    /// Set format detection for mobile
    public func formatDetection(telephone: Bool = true, email: Bool = true, address: Bool = true) -> MetaTagBuilder {
        var builder = self
        var parts: [String] = []
        if !telephone { parts.append("telephone=no") }
        if !email { parts.append("email=no") }
        if !address { parts.append("address=no") }
        if !parts.isEmpty {
            builder.tags.append(MetaTag(type: .name("format-detection", parts.joined(separator: ", "))))
        }
        return builder
    }

    // MARK: - Custom Tags

    /// Add a custom meta tag by name
    public func custom(name: String, content: String) -> MetaTagBuilder {
        var builder = self
        builder.tags.append(MetaTag(type: .name(name, content)))
        return builder
    }

    /// Add a custom meta tag by property
    public func customProperty(property: String, content: String) -> MetaTagBuilder {
        var builder = self
        builder.tags.append(MetaTag(type: .property(property, content)))
        return builder
    }

    /// Add a custom HTTP-equiv tag
    public func httpEquiv(equiv: String, content: String) -> MetaTagBuilder {
        var builder = self
        builder.tags.append(MetaTag(type: .httpEquiv(equiv, content)))
        return builder
    }

    // MARK: - Build

    /// Build the collection of meta tags
    public func build() -> [MetaTag] {
        tags
    }
}

// MARK: - Structured Data

/// Represents JSON-LD structured data for rich search results
public struct StructuredData: Sendable {
    /// Schema.org type
    public let type: String

    /// Properties as key-value pairs
    public let properties: [String: StructuredDataValue]

    /// Create new structured data
    public init(type: String, properties: [String: StructuredDataValue]) {
        self.type = type
        self.properties = properties
    }

    /// Convert to JSON-LD string
    public func toJSONLD() -> String {
        var json: [String: Any] = ["@context": "https://schema.org", "@type": type]

        for (key, value) in properties {
            json[key] = value.rawValue
        }

        if let data = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted]),
           let string = String(data: data, encoding: .utf8) {
            return string
        }

        return "{}"
    }

    /// Convert to script tag with JSON-LD
    public func toScriptTag() -> String {
        "<script type=\"application/ld+json\">\n\(toJSONLD())\n</script>"
    }
}

/// Value type for structured data properties
public enum StructuredDataValue: Sendable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case array([StructuredDataValue])
    case object([String: StructuredDataValue])

    var rawValue: Any {
        switch self {
        case .string(let value): return value
        case .number(let value): return value
        case .bool(let value): return value
        case .array(let values): return values.map { $0.rawValue }
        case .object(let dict): return dict.mapValues { $0.rawValue }
        }
    }
}

// MARK: - Common Structured Data Types

extension StructuredData {
    /// Create Article structured data
    public static func article(
        headline: String,
        author: String,
        datePublished: Date,
        dateModified: Date? = nil,
        image: String? = nil,
        publisher: String? = nil
    ) -> StructuredData {
        var properties: [String: StructuredDataValue] = [
            "headline": .string(headline),
            "author": .object(["@type": .string("Person"), "name": .string(author)]),
            "datePublished": .string(ISO8601DateFormatter().string(from: datePublished))
        ]

        if let dateModified = dateModified {
            properties["dateModified"] = .string(ISO8601DateFormatter().string(from: dateModified))
        }
        if let image = image {
            properties["image"] = .string(image)
        }
        if let publisher = publisher {
            properties["publisher"] = .object(["@type": .string("Organization"), "name": .string(publisher)])
        }

        return StructuredData(type: "Article", properties: properties)
    }

    /// Create Organization structured data
    public static func organization(
        name: String,
        url: String,
        logo: String? = nil,
        description: String? = nil,
        sameAs: [String] = []
    ) -> StructuredData {
        var properties: [String: StructuredDataValue] = [
            "name": .string(name),
            "url": .string(url)
        ]

        if let logo = logo {
            properties["logo"] = .string(logo)
        }
        if let description = description {
            properties["description"] = .string(description)
        }
        if !sameAs.isEmpty {
            properties["sameAs"] = .array(sameAs.map { .string($0) })
        }

        return StructuredData(type: "Organization", properties: properties)
    }

    /// Create WebSite structured data
    public static func website(
        name: String,
        url: String,
        description: String? = nil
    ) -> StructuredData {
        var properties: [String: StructuredDataValue] = [
            "name": .string(name),
            "url": .string(url)
        ]

        if let description = description {
            properties["description"] = .string(description)
        }

        return StructuredData(type: "WebSite", properties: properties)
    }

    /// Create BreadcrumbList structured data
    public static func breadcrumb(items: [(name: String, url: String)]) -> StructuredData {
        let listItems = items.enumerated().map { index, item in
            StructuredDataValue.object([
                "@type": .string("ListItem"),
                "position": .number(Double(index + 1)),
                "name": .string(item.name),
                "item": .string(item.url)
            ])
        }

        return StructuredData(type: "BreadcrumbList", properties: [
            "itemListElement": .array(listItems)
        ])
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
