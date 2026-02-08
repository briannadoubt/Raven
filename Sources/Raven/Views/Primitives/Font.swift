import Foundation

/// A font value that can be applied to text.
///
/// `Font` provides a way to specify text fonts using system fonts, custom fonts,
/// and semantic text styles. It supports weight and design variations.
///
/// Example:
/// ```swift
/// Text("Hello")
///     .font(.headline)
///
/// Text("Custom")
///     .font(.custom("Helvetica", size: 18))
///
/// Text("Weighted")
///     .font(.system(size: 16, weight: .bold))
/// ```
public struct Font: Sendable, Hashable {
    /// The internal representation of the font
    internal let descriptor: FontDescriptor

    internal enum FontDescriptor: Sendable, Hashable {
        case system(size: Double, weight: Weight, design: Design)
        case custom(name: String, size: Double)
        case customFixed(name: String, fixedSize: Double)
        case largeTitle
        case title
        case title2
        case title3
        case headline
        case subheadline
        case body
        case callout
        case footnote
        case caption
        case caption2
    }

    /// Font weight values
    public enum Weight: String, Sendable, Hashable {
        case ultraLight
        case thin
        case light
        case regular
        case medium
        case semibold
        case bold
        case heavy
        case black

        /// CSS font-weight value
        internal var cssValue: String {
            switch self {
            case .ultraLight: return "100"
            case .thin: return "200"
            case .light: return "300"
            case .regular: return "400"
            case .medium: return "500"
            case .semibold: return "600"
            case .bold: return "700"
            case .heavy: return "800"
            case .black: return "900"
            }
        }
    }

    /// Font design values
    public enum Design: String, Sendable, Hashable {
        case `default`
        case serif
        case rounded
        case monospaced

        /// CSS font-family suffix or value
        internal var cssFontFamily: String {
            switch self {
            case .default: return "system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif"
            case .serif: return "Georgia, 'Times New Roman', serif"
            case .rounded: return "ui-rounded, 'SF Pro Rounded', system-ui, sans-serif"
            case .monospaced: return "ui-monospace, 'SF Mono', Monaco, 'Cascadia Code', 'Courier New', monospace"
            }
        }
    }

    // MARK: - Text Styles

    /// Large title text style
    public static let largeTitle = Font(descriptor: .largeTitle)

    /// Title text style
    public static let title = Font(descriptor: .title)

    /// Second-level title text style
    public static let title2 = Font(descriptor: .title2)

    /// Third-level title text style
    public static let title3 = Font(descriptor: .title3)

    /// Headline text style
    public static let headline = Font(descriptor: .headline)

    /// Subheadline text style
    public static let subheadline = Font(descriptor: .subheadline)

    /// Body text style (default)
    public static let body = Font(descriptor: .body)

    /// Callout text style
    public static let callout = Font(descriptor: .callout)

    /// Footnote text style
    public static let footnote = Font(descriptor: .footnote)

    /// Caption text style
    public static let caption = Font(descriptor: .caption)

    /// Second-level caption text style
    public static let caption2 = Font(descriptor: .caption2)

    // MARK: - Initializers

    /// Creates a system font with the specified size.
    ///
    /// - Parameters:
    ///   - size: The font size in points.
    ///   - weight: The font weight. Defaults to `.regular`.
    ///   - design: The font design. Defaults to `.default`.
    /// - Returns: A system font with the specified properties.
    public static func system(size: Double, weight: Weight = .regular, design: Design = .default) -> Font {
        Font(descriptor: .system(size: size, weight: weight, design: design))
    }

    /// Creates a custom font with the specified name and size.
    ///
    /// The font scales with Dynamic Type size changes.
    ///
    /// - Parameters:
    ///   - name: The name of the custom font family.
    ///   - size: The font size in points.
    /// - Returns: A custom font with the specified properties.
    public static func custom(_ name: String, size: Double) -> Font {
        Font(descriptor: .custom(name: name, size: size))
    }

    /// Creates a custom font with a fixed size that doesn't scale.
    ///
    /// Use this when you need precise control over font size without Dynamic Type scaling.
    ///
    /// - Parameters:
    ///   - name: The name of the custom font family.
    ///   - fixedSize: The fixed font size in points.
    /// - Returns: A custom font with the specified properties.
    public static func custom(_ name: String, fixedSize: Double) -> Font {
        Font(descriptor: .customFixed(name: name, fixedSize: fixedSize))
    }

    // MARK: - Modifiers

    /// Returns a font with the specified weight.
    ///
    /// - Parameter weight: The desired font weight.
    /// - Returns: A new font with the specified weight.
    public func weight(_ weight: Weight) -> Font {
        switch descriptor {
        case .system(let size, _, let design):
            return Font(descriptor: .system(size: size, weight: weight, design: design))
        case .custom(_, let size):
            // For custom fonts, we'll store weight but application depends on font having that weight
            return Font(descriptor: .system(size: size, weight: weight, design: .default))
        case .customFixed(_, let fixedSize):
            return Font(descriptor: .system(size: fixedSize, weight: weight, design: .default))
        default:
            // For text styles, convert to system font at standard size with weight
            let size = textStyleSize(for: descriptor)
            return Font(descriptor: .system(size: size, weight: weight, design: .default))
        }
    }

    /// Returns a font with the specified design.
    ///
    /// - Parameter design: The desired font design.
    /// - Returns: A new font with the specified design.
    public func design(_ design: Design) -> Font {
        switch descriptor {
        case .system(let size, let weight, _):
            return Font(descriptor: .system(size: size, weight: weight, design: design))
        case .custom, .customFixed:
            // Custom fonts keep their name, design doesn't apply
            return self
        default:
            // For text styles, convert to system font at standard size with design
            let size = textStyleSize(for: descriptor)
            return Font(descriptor: .system(size: size, weight: .regular, design: design))
        }
    }

    // MARK: - CSS Conversion

    /// Converts this font to CSS font properties.
    ///
    /// - Parameter scale: The scale factor to apply to font sizes. Defaults to 1.0.
    /// - Returns: A tuple of CSS font-family and font-size values.
    internal func cssProperties(scale: Double = 1.0) -> (family: String, size: String, weight: String) {
        let baseProperties: (family: String, size: Double, weight: String)

        switch descriptor {
        case .system(let size, let weight, let design):
            baseProperties = (family: design.cssFontFamily, size: size, weight: weight.cssValue)
        case .custom(let name, let size):
            baseProperties = (family: "'\(name)', sans-serif", size: size, weight: "400")
        case .customFixed(let name, let fixedSize):
            // Fixed size fonts don't scale
            return (family: "'\(name)', sans-serif", size: "\(fixedSize)px", weight: "400")
        case .largeTitle:
            baseProperties = (family: Design.default.cssFontFamily, size: 34, weight: "700")
        case .title:
            baseProperties = (family: Design.default.cssFontFamily, size: 28, weight: "700")
        case .title2:
            baseProperties = (family: Design.default.cssFontFamily, size: 22, weight: "700")
        case .title3:
            baseProperties = (family: Design.default.cssFontFamily, size: 20, weight: "600")
        case .headline:
            baseProperties = (family: Design.default.cssFontFamily, size: 17, weight: "600")
        case .subheadline:
            baseProperties = (family: Design.default.cssFontFamily, size: 15, weight: "400")
        case .body:
            baseProperties = (family: Design.default.cssFontFamily, size: 17, weight: "400")
        case .callout:
            baseProperties = (family: Design.default.cssFontFamily, size: 16, weight: "400")
        case .footnote:
            baseProperties = (family: Design.default.cssFontFamily, size: 13, weight: "400")
        case .caption:
            baseProperties = (family: Design.default.cssFontFamily, size: 12, weight: "400")
        case .caption2:
            baseProperties = (family: Design.default.cssFontFamily, size: 11, weight: "400")
        }

        // Apply scale factor to the size
        let scaledSize = baseProperties.size * scale
        return (family: baseProperties.family, size: "\(scaledSize)px", weight: baseProperties.weight)
    }

    // MARK: - Private Helpers

    private func textStyleSize(for descriptor: FontDescriptor) -> Double {
        switch descriptor {
        case .largeTitle: return 34
        case .title: return 28
        case .title2: return 22
        case .title3: return 20
        case .headline: return 17
        case .subheadline: return 15
        case .body: return 17
        case .callout: return 16
        case .footnote: return 13
        case .caption: return 12
        case .caption2: return 11
        default: return 17 // fallback to body size
        }
    }
}

// MARK: - Dynamic Type (Placeholder)

/// Content size categories for Dynamic Type support.
///
/// These categories represent different text size preferences for accessibility.
/// Dynamic Type scaling is fully implemented and applied via the environment.
/// Use `.environment(\.sizeCategory, .extraLarge)` to test different sizes.
public enum ContentSizeCategory: String, Sendable, CaseIterable {
    case extraSmall
    case small
    case medium
    case large
    case extraLarge
    case extraExtraLarge
    case extraExtraExtraLarge
    case accessibilityMedium
    case accessibilityLarge
    case accessibilityExtraLarge
    case accessibilityExtraExtraLarge
    case accessibilityExtraExtraExtraLarge

    /// Default content size category
    public static let `default`: ContentSizeCategory = .large

    /// Scaling factor relative to the default size (placeholder for future implementation)
    internal var scaleFactor: Double {
        switch self {
        case .extraSmall: return 0.82
        case .small: return 0.88
        case .medium: return 0.94
        case .large: return 1.0
        case .extraLarge: return 1.12
        case .extraExtraLarge: return 1.24
        case .extraExtraExtraLarge: return 1.35
        case .accessibilityMedium: return 1.60
        case .accessibilityLarge: return 1.90
        case .accessibilityExtraLarge: return 2.35
        case .accessibilityExtraExtraLarge: return 2.76
        case .accessibilityExtraExtraExtraLarge: return 3.12
        }
    }
}
