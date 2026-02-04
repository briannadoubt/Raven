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
public struct Image: View, Sendable {
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
        var props: [String: VProperty] = [:]

        // Set the image source
        let srcValue: String
        switch source {
        case .named(let name):
            // Named images could be resolved to a path
            // For now, treat as a relative path to an assets folder
            srcValue = "/assets/\(name)"
        case .system(let systemName):
            // System icons could map to an icon font or SVG sprite
            // For now, use a placeholder approach with data attributes
            // In a real implementation, this might render as an SVG or icon font
            srcValue = "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24'%3E%3Ctext x='50%25' y='50%25' dominant-baseline='middle' text-anchor='middle'%3E\(systemName)%3C/text%3E%3C/svg%3E"
        case .url(let urlString):
            srcValue = urlString
        }

        props["src"] = .attribute(name: "src", value: srcValue)

        // Set accessibility attributes
        if isDecorative {
            // Decorative images should have empty alt text and role="presentation"
            props["alt"] = .attribute(name: "alt", value: "")
            props["role"] = .attribute(name: "role", value: "presentation")
        } else {
            // Non-decorative images should have meaningful alt text
            let altText = alternativeText ?? extractAltTextFromSource()
            props["alt"] = .attribute(name: "alt", value: altText)
        }

        // Add loading attribute for lazy loading
        props["loading"] = .attribute(name: "loading", value: "lazy")

        return VNode.element(
            "img",
            props: props,
            children: []
        )
    }

    // MARK: - Helper Methods

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
