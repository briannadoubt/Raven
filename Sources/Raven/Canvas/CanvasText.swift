import Foundation
import JavaScriptKit

/// Text rendering capabilities for canvas drawing.
///
/// Canvas text provides low-level text drawing with full control over fonts,
/// alignment, baseline, and styling. Unlike SwiftUI's Text view which creates
/// DOM elements, canvas text is rasterized directly into the canvas bitmap.
///
/// ## Overview
///
/// Canvas text is ideal for dynamic text that needs to be part of animated or
/// interactive graphics. It supports all CSS font specifications and provides
/// precise control over text positioning and appearance.
///
/// ## Drawing Text
///
/// ```swift
/// Canvas { context, size in
///     context.drawText(
///         "Hello, Canvas!",
///         at: CGPoint(x: size.width / 2, y: size.height / 2),
///         font: .system(size: 24, weight: .bold),
///         color: .blue,
///         alignment: .center
///     )
/// }
/// ```
///
/// ## Measuring Text
///
/// ```swift
/// Canvas { context, size in
///     let text = "Sample Text"
///     let metrics = context.measureText(text, font: .system(size: 16))
///
///     // Center text based on measurements
///     let x = (size.width - metrics.width) / 2
///     context.drawText(text, at: CGPoint(x: x, y: 50))
/// }
/// ```

extension GraphicsContext {
    /// Draws text at the specified point.
    ///
    /// - Parameters:
    ///   - text: The text to draw.
    ///   - point: The point at which to draw the text.
    ///   - font: The font to use for the text.
    ///   - color: The text color.
    ///   - alignment: The horizontal text alignment.
    ///   - baseline: The text baseline alignment.
    public func drawText(
        _ text: String,
        at point: CGPoint,
        font: CanvasFont = .system(size: 12),
        color: Color = .black,
        alignment: TextAlignment = .leading,
        baseline: TextBaseline = .alphabetic
    ) {
        // Set font
        jsContext.font = .string(font.cssValue)

        // Set text alignment
        jsContext.textAlign = .string(alignment.cssValue)

        // Set text baseline
        jsContext.textBaseline = .string(baseline.cssValue)

        // Set fill color
        jsContext.fillStyle = .string(color.cssValue)

        // Draw text
        jsContext.fillText!(text, point.x, point.y)
    }

    /// Draws stroked (outlined) text at the specified point.
    ///
    /// - Parameters:
    ///   - text: The text to draw.
    ///   - point: The point at which to draw the text.
    ///   - font: The font to use for the text.
    ///   - color: The stroke color.
    ///   - lineWidth: The width of the stroke.
    ///   - alignment: The horizontal text alignment.
    ///   - baseline: The text baseline alignment.
    public func strokeText(
        _ text: String,
        at point: CGPoint,
        font: CanvasFont = .system(size: 12),
        color: Color = .black,
        lineWidth: Double = 1,
        alignment: TextAlignment = .leading,
        baseline: TextBaseline = .alphabetic
    ) {
        // Set font
        jsContext.font = .string(font.cssValue)

        // Set text alignment
        jsContext.textAlign = .string(alignment.cssValue)

        // Set text baseline
        jsContext.textBaseline = .string(baseline.cssValue)

        // Set stroke style
        jsContext.strokeStyle = .string(color.cssValue)
        jsContext.lineWidth = .number(lineWidth)

        // Draw text
        jsContext.strokeText!(text, point.x, point.y)
    }

    /// Measures the width of text with the specified font.
    ///
    /// - Parameters:
    ///   - text: The text to measure.
    ///   - font: The font to use for measurement.
    /// - Returns: Text metrics including width.
    public func measureText(_ text: String, font: CanvasFont = .system(size: 12)) -> TextMetrics {
        // Set font
        jsContext.font = .string(font.cssValue)

        // Measure text
        let metrics = jsContext.measureText!(text).object!

        return TextMetrics(
            width: metrics.width.number ?? 0,
            actualBoundingBoxLeft: metrics.actualBoundingBoxLeft.number ?? 0,
            actualBoundingBoxRight: metrics.actualBoundingBoxRight.number ?? 0,
            actualBoundingBoxAscent: metrics.actualBoundingBoxAscent.number ?? 0,
            actualBoundingBoxDescent: metrics.actualBoundingBoxDescent.number ?? 0
        )
    }

    // MARK: - Text Alignment

    /// Horizontal text alignment.
    public enum TextAlignment: Sendable {
        case leading
        case center
        case trailing

        var cssValue: String {
            switch self {
            case .leading: return "left"
            case .center: return "center"
            case .trailing: return "right"
            }
        }
    }

    // MARK: - Text Baseline

    /// Vertical text baseline alignment.
    public enum TextBaseline: Sendable {
        /// Align to the top of the em square.
        case top

        /// Align to the hanging baseline (used in Tibetan and other Indic scripts).
        case hanging

        /// Align to the middle of the em square.
        case middle

        /// Align to the alphabetic baseline (default).
        case alphabetic

        /// Align to the ideographic baseline (used in Chinese, Japanese, Korean).
        case ideographic

        /// Align to the bottom of the bounding box.
        case bottom

        var cssValue: String {
            switch self {
            case .top: return "top"
            case .hanging: return "hanging"
            case .middle: return "middle"
            case .alphabetic: return "alphabetic"
            case .ideographic: return "ideographic"
            case .bottom: return "bottom"
            }
        }
    }
}

// MARK: - Canvas Font

/// A font specification for canvas text rendering.
public struct CanvasFont: Sendable, Hashable {
    let cssValue: String

    /// Creates a font from a CSS font string.
    ///
    /// - Parameter cssValue: A CSS font specification string.
    public init(cssValue: String) {
        self.cssValue = cssValue
    }

    /// Creates a system font.
    ///
    /// - Parameters:
    ///   - size: The font size in points.
    ///   - weight: The font weight.
    ///   - design: The font design (ignored for canvas fonts).
    /// - Returns: A system font.
    public static func system(
        size: Double,
        weight: FontWeight = .regular,
        design: FontDesign = .default
    ) -> CanvasFont {
        let weightValue = weight.cssValue
        return CanvasFont(cssValue: "\(weightValue) \(size)px system-ui, -apple-system, sans-serif")
    }

    /// Creates a custom font.
    ///
    /// - Parameters:
    ///   - name: The font family name.
    ///   - size: The font size in points.
    ///   - weight: The font weight.
    /// - Returns: A custom font.
    public static func custom(
        _ name: String,
        size: Double,
        weight: FontWeight = .regular
    ) -> CanvasFont {
        let weightValue = weight.cssValue
        return CanvasFont(cssValue: "\(weightValue) \(size)px '\(name)', sans-serif")
    }

    /// Creates a monospaced font.
    ///
    /// - Parameters:
    ///   - size: The font size in points.
    ///   - weight: The font weight.
    /// - Returns: A monospaced font.
    public static func monospaced(
        size: Double,
        weight: FontWeight = .regular
    ) -> CanvasFont {
        let weightValue = weight.cssValue
        return CanvasFont(cssValue: "\(weightValue) \(size)px 'SF Mono', Monaco, 'Courier New', monospace")
    }

    // MARK: - Font Weight

    public enum FontWeight: Sendable, Hashable {
        case ultraLight
        case thin
        case light
        case regular
        case medium
        case semibold
        case bold
        case heavy
        case black

        var cssValue: String {
            switch self {
            case .ultraLight: return "200"
            case .thin: return "300"
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

    // MARK: - Font Design

    public enum FontDesign: Sendable, Hashable {
        case `default`
        case serif
        case rounded
        case monospaced
    }
}

// MARK: - Text Metrics

/// Measurements of text rendered with a specific font.
public struct TextMetrics: Sendable {
    /// The width of the text in pixels.
    public let width: Double

    /// The distance from the alignment point to the left side of the bounding box.
    public let actualBoundingBoxLeft: Double

    /// The distance from the alignment point to the right side of the bounding box.
    public let actualBoundingBoxRight: Double

    /// The distance from the baseline to the top of the bounding box.
    public let actualBoundingBoxAscent: Double

    /// The distance from the baseline to the bottom of the bounding box.
    public let actualBoundingBoxDescent: Double

    /// The total height of the text.
    public var height: Double {
        actualBoundingBoxAscent + actualBoundingBoxDescent
    }

    /// The actual width of the bounding box.
    public var actualWidth: Double {
        actualBoundingBoxLeft + actualBoundingBoxRight
    }
}
