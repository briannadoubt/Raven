import Foundation

/// A view that displays an image.
///
/// `Image` is a primitive view that renders directly to an img element in the virtual DOM.
/// It supports loading images from URLs, system icons, and named resources.
///
/// Example:
/// ```swift
/// Image("photo")
/// Image(systemName: "star.fill")
/// ```
///
/// Because `Image` is a primitive view with `Body == Never`, it converts directly
/// to a VNode without further composition.
public struct Image: View, PrimitiveView, Sendable {
    public typealias Body = Never

    /// The source of the image
    private let source: ImageSource

    /// Whether this image is decorative (for accessibility)
    private let isDecorative: Bool

    /// Alternative text for accessibility
    private let alternativeText: String?

    // MARK: - Image Source

    /// Represents the source of an image
    private enum ImageSource: Sendable {
        /// Named image or resource
        case named(String)
        /// System icon (e.g., SF Symbols style)
        case system(String)
        /// URL string
        case url(String)
    }

    // MARK: - Initializers

    /// Creates an image from a named resource.
    ///
    /// - Parameter name: The name of the image resource.
    public init(_ name: String) {
        self.source = .named(name)
        self.isDecorative = false
        self.alternativeText = nil
    }

    /// Creates an image from a system icon name.
    ///
    /// This initializer is intended for system-provided icons, similar to SF Symbols.
    /// In the web context, this could map to icon fonts or SVG icons.
    ///
    /// - Parameter systemName: The name of the system icon.
    public init(systemName: String) {
        self.source = .system(systemName)
        self.isDecorative = false
        self.alternativeText = nil
    }

    /// Creates a decorative image that should be ignored by accessibility tools.
    ///
    /// Use this initializer for images that are purely decorative and don't convey
    /// meaningful information to the user.
    ///
    /// - Parameter name: The name of the image resource.
    /// - Returns: An image view marked as decorative.
    public init(decorative name: String) {
        self.source = .named(name)
        self.isDecorative = true
        self.alternativeText = nil
    }

    /// Creates an image with custom alternative text for accessibility.
    ///
    /// - Parameters:
    ///   - name: The name of the image resource.
    ///   - alt: The alternative text describing the image.
    public init(_ name: String, alt: String) {
        self.source = .named(name)
        self.isDecorative = false
        self.alternativeText = alt
    }

    // MARK: - VNode Conversion

    /// Converts this Image view to a virtual DOM node.
    ///
    /// This method is used internally by the rendering system to convert
    /// the Image primitive into its VNode representation.
    ///
    /// - Returns: An img element VNode with appropriate attributes.
    @MainActor public func toVNode() -> VNode {
        switch source {
        case .system(let systemName):
            return systemSymbolVNode(systemName: systemName)
        case .named, .url:
            return rasterImageVNode()
        }
    }

    // MARK: - Helper Methods
    @MainActor
    private func rasterImageVNode() -> VNode {
        var props: [String: VProperty] = [:]

        let srcValue: String
        switch source {
        case .named(let name):
            // Named images could be resolved to a path.
            // For now, treat as a relative path to an assets folder.
            srcValue = "/assets/\(name)"
        case .url(let urlString):
            srcValue = urlString
        case .system:
            // Unreachable by design.
            srcValue = ""
        }

        props["src"] = .attribute(name: "src", value: srcValue)

        // Set accessibility attributes
        if isDecorative {
            props["alt"] = .attribute(name: "alt", value: "")
            props["role"] = .attribute(name: "role", value: "presentation")
        } else {
            let altText = alternativeText ?? extractAltTextFromSource()
            props["alt"] = .attribute(name: "alt", value: altText)
        }

        props["loading"] = .attribute(name: "loading", value: "lazy")

        return VNode.element("img", props: props, children: [])
    }

    /// Render a subset of SF-Symbol-like system images as inline SVG.
    ///
    /// This has two big benefits over rendering via `<img src="data:...">`:
    /// - `.foregroundColor(...)` can tint the icon via `currentColor`.
    /// - Icons are DOM-native and can be styled/laid out like SwiftUI symbols.
    @MainActor
    private func systemSymbolVNode(systemName: String) -> VNode {
        let altText = isDecorative ? "" : (alternativeText ?? extractAltTextFromSource())

        var svgProps: [String: VProperty] = [
            "viewBox": .attribute(name: "viewBox", value: "0 0 1 1"),
            "width": .attribute(name: "width", value: "24"),
            "height": .attribute(name: "height", value: "24"),
            "display": .style(name: "display", value: "inline-block"),
            "vertical-align": .style(name: "vertical-align", value: "middle"),
        ]

        if isDecorative {
            svgProps["role"] = .attribute(name: "role", value: "presentation")
            svgProps["aria-hidden"] = .attribute(name: "aria-hidden", value: "true")
        } else {
            svgProps["role"] = .attribute(name: "role", value: "img")
            svgProps["aria-label"] = .attribute(name: "aria-label", value: altText)
        }

        guard let symbol = Symbol.systemName(systemName) else {
            // Fallback: show the name as a text glyph, still tintable via currentColor.
            let textProps: [String: VProperty] = [
                "x": .attribute(name: "x", value: "0.5"),
                "y": .attribute(name: "y", value: "0.56"),
                "text-anchor": .attribute(name: "text-anchor", value: "middle"),
                "dominant-baseline": .attribute(name: "dominant-baseline", value: "middle"),
                "font-size": .attribute(name: "font-size", value: "0.22"),
                "fill": .attribute(name: "fill", value: "currentColor"),
            ]

            return VNode.element(
                "svg",
                props: svgProps,
                children: [
                    VNode.element("text", props: textProps, children: [.text(systemName)]),
                ]
            )
        }

        // Some symbols include open segments (lines) and closed shapes in one pathData.
        // Using both `fill` and `stroke` keeps icons legible across that mix.
        let isFilledSymbol = systemName.contains(".fill")
        let fillValue = isFilledSymbol ? "currentColor" : "none"
        let strokeValue = "currentColor"

        let pathProps: [String: VProperty] = [
            "d": .attribute(name: "d", value: symbol.pathData),
            "fill": .attribute(name: "fill", value: fillValue),
            "stroke": .attribute(name: "stroke", value: strokeValue),
            // Unit-square viewBox: 0.08 is roughly a 2px stroke at 24px icon size.
            "stroke-width": .attribute(name: "stroke-width", value: "0.08"),
            "stroke-linecap": .attribute(name: "stroke-linecap", value: "round"),
            "stroke-linejoin": .attribute(name: "stroke-linejoin", value: "round"),
        ]

        return VNode.element(
            "svg",
            props: svgProps,
            children: [
                VNode.element("path", props: pathProps, children: []),
            ]
        )
    }

    /// Extracts a reasonable alt text from the image source when none is provided.
    ///
    /// - Returns: A string suitable for use as alt text.
    private func extractAltTextFromSource() -> String {
        switch source {
        case .named(let name):
            // Convert "my-photo" to "My Photo"
            return name
                .replacingOccurrences(of: "-", with: " ")
                .replacingOccurrences(of: "_", with: " ")
                .capitalized
        case .system(let systemName):
            // Convert "star.fill" to "Star Fill"
            return systemName
                .replacingOccurrences(of: ".", with: " ")
                .replacingOccurrences(of: "-", with: " ")
                .replacingOccurrences(of: "_", with: " ")
                .capitalized
        case .url(let urlString):
            // Extract filename from URL
            if let lastComponent = urlString.split(separator: "/").last {
                return String(lastComponent)
                    .replacingOccurrences(of: "-", with: " ")
                    .replacingOccurrences(of: "_", with: " ")
                    .capitalized
            }
            return "Image"
        }
    }
}

// MARK: - URL Support

extension Image {
    /// Creates an image from a URL string.
    ///
    /// - Parameter url: The URL string of the image.
    /// - Returns: An image view that loads from the URL.
    public static func url(_ url: String) -> Image {
        var image = Image("")
        image = Image.urlInternal(url)
        return image
    }

    /// Internal initializer for URL-based images.
    private static func urlInternal(_ url: String) -> Image {
        Image(source: .url(url), isDecorative: false, alternativeText: nil)
    }

    /// Private initializer for internal use.
    private init(source: ImageSource, isDecorative: Bool, alternativeText: String?) {
        self.source = source
        self.isDecorative = isDecorative
        self.alternativeText = alternativeText
    }
}

// MARK: - View Modifiers

extension Image {
    /// Marks this image as decorative for accessibility purposes.
    ///
    /// Decorative images are hidden from assistive technologies and should
    /// only be used for purely decorative content that doesn't convey meaning.
    ///
    /// - Returns: A modified image view marked as decorative.
    public func accessibility(decorative: Bool) -> Image {
        Image(
            source: self.source,
            isDecorative: decorative,
            alternativeText: self.alternativeText
        )
    }

    /// Sets custom alternative text for accessibility.
    ///
    /// - Parameter text: The alternative text describing the image.
    /// - Returns: A modified image view with custom alt text.
    public func accessibilityLabel(_ text: String) -> Image {
        Image(
            source: self.source,
            isDecorative: self.isDecorative,
            alternativeText: text
        )
    }
}
