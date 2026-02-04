import Foundation

/// A protocol that describes the appearance of a shape or view.
///
/// `ShapeStyle` represents different ways to fill or stroke shapes, including
/// solid colors, gradients, and other visual styles. Types conforming to this
/// protocol can be used with shape modifiers like `.fill()` and `.stroke()`.
///
/// Raven provides built-in conformances for common style types:
/// - `Color` for solid color fills
/// - `LinearGradient` for linear gradient fills
/// - `RadialGradient` for radial gradient fills
///
/// ## Rendering to SVG
///
/// In Raven, shapes are rendered as SVG elements in the DOM. Shape styles are
/// converted to SVG fill and stroke attributes, enabling hardware-accelerated
/// vector graphics in the browser.
///
/// ## Example Usage
///
/// ```swift
/// Circle()
///     .fill(Color.blue)
///
/// Rectangle()
///     .fill(LinearGradient(
///         colors: [.red, .orange],
///         angle: .degrees(45)
///     ))
///
/// RoundedRectangle(cornerRadius: 10)
///     .stroke(Color.black, lineWidth: 2)
/// ```
///
/// ## Topics
///
/// ### Built-in Styles
/// - ``Color``
/// - ``LinearGradient``
/// - ``RadialGradient``
///
/// ### Shape Modifiers
/// - ``Shape/fill(_:)``
/// - ``Shape/stroke(_:lineWidth:)``
///
/// - Note: Shape styles in Raven are rendered using SVG's fill and stroke
///   attributes, providing resolution-independent graphics that scale smoothly
///   at any size.
public protocol ShapeStyle: Sendable {
    /// Converts this style to an SVG fill attribute value.
    ///
    /// This method is used internally by the rendering system to generate
    /// SVG markup. For solid colors, this returns a color string. For gradients,
    /// this returns a reference to an SVG gradient definition.
    ///
    /// - Returns: An SVG-compatible fill value string.
    func svgFillValue() -> String

    /// Converts this style to an SVG stroke attribute value.
    ///
    /// This method is used internally by the rendering system to generate
    /// SVG markup for stroke operations.
    ///
    /// - Returns: An SVG-compatible stroke value string.
    func svgStrokeValue() -> String

    /// Generates SVG gradient definitions if needed.
    ///
    /// For gradient styles, this returns the SVG `<defs>` content needed to
    /// define the gradient. For solid colors, this returns an empty string.
    ///
    /// - Parameter id: A unique identifier for the gradient definition.
    /// - Returns: SVG gradient definition markup, or an empty string.
    func svgDefinitions(id: String) -> String
}

// MARK: - Color Conformance

extension Color: ShapeStyle {
    /// Converts this color to an SVG fill attribute value.
    ///
    /// Solid colors are rendered directly as their CSS color value.
    ///
    /// - Returns: The CSS color value suitable for SVG fill attributes.
    public func svgFillValue() -> String {
        cssValue
    }

    /// Converts this color to an SVG stroke attribute value.
    ///
    /// Solid colors are rendered directly as their CSS color value.
    ///
    /// - Returns: The CSS color value suitable for SVG stroke attributes.
    public func svgStrokeValue() -> String {
        cssValue
    }

    /// Colors don't require gradient definitions.
    ///
    /// - Parameter id: Unused for solid colors.
    /// - Returns: An empty string.
    public func svgDefinitions(id: String) -> String {
        ""
    }
}

// MARK: - LinearGradient Conformance

extension LinearGradient: ShapeStyle {
    /// Converts this gradient to an SVG fill attribute value.
    ///
    /// Linear gradients are rendered as references to SVG gradient definitions.
    ///
    /// - Returns: A URL reference to the gradient definition.
    public func svgFillValue() -> String {
        "url(#linearGradient-\(objectIdentifier))"
    }

    /// Converts this gradient to an SVG stroke attribute value.
    ///
    /// Linear gradients can be used for strokes as well as fills.
    ///
    /// - Returns: A URL reference to the gradient definition.
    public func svgStrokeValue() -> String {
        "url(#linearGradient-\(objectIdentifier))"
    }

    /// Generates the SVG linear gradient definition.
    ///
    /// Creates an SVG `<linearGradient>` element with color stops for each
    /// color in the gradient.
    ///
    /// - Parameter id: A unique identifier for the gradient definition.
    /// - Returns: SVG `<linearGradient>` markup.
    public func svgDefinitions(id: String) -> String {
        let gradientId = "linearGradient-\(objectIdentifier)"

        // Convert angle to x1, y1, x2, y2 coordinates
        // 0° = right, 90° = down, 180° = left, 270° = up
        let radians = angle.radians
        let x1 = 50 + 50 * cos(radians + .pi)
        let y1 = 50 + 50 * sin(radians + .pi)
        let x2 = 50 + 50 * cos(radians)
        let y2 = 50 + 50 * sin(radians)

        var svg = "<linearGradient id=\"\(gradientId)\" "
        svg += "x1=\"\(x1)%\" y1=\"\(y1)%\" x2=\"\(x2)%\" y2=\"\(y2)%\">\n"

        // Generate color stops
        let step = colors.count > 1 ? 100.0 / Double(colors.count - 1) : 0.0
        for (index, color) in colors.enumerated() {
            let offset = colors.count > 1 ? Double(index) * step : 0.0
            svg += "  <stop offset=\"\(offset)%\" stop-color=\"\(color.cssValue)\" />\n"
        }

        svg += "</linearGradient>"
        return svg
    }

    /// A unique identifier for this gradient instance.
    private var objectIdentifier: String {
        // Create a stable identifier based on gradient properties
        let colorHash = colors.map { $0.cssValue }.joined(separator: "-")
        let angleHash = String(format: "%.2f", angle.degrees)
        return "\(colorHash)-\(angleHash)".replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "#", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
            .replacingOccurrences(of: ",", with: "")
    }
}

// MARK: - RadialGradient Conformance

extension RadialGradient: ShapeStyle {
    /// Converts this gradient to an SVG fill attribute value.
    ///
    /// Radial gradients are rendered as references to SVG gradient definitions.
    ///
    /// - Returns: A URL reference to the gradient definition.
    public func svgFillValue() -> String {
        "url(#radialGradient-\(objectIdentifier))"
    }

    /// Converts this gradient to an SVG stroke attribute value.
    ///
    /// Radial gradients can be used for strokes as well as fills.
    ///
    /// - Returns: A URL reference to the gradient definition.
    public func svgStrokeValue() -> String {
        "url(#radialGradient-\(objectIdentifier))"
    }

    /// Generates the SVG radial gradient definition.
    ///
    /// Creates an SVG `<radialGradient>` element with color stops for each
    /// color in the gradient.
    ///
    /// - Parameter id: A unique identifier for the gradient definition.
    /// - Returns: SVG `<radialGradient>` markup.
    public func svgDefinitions(id: String) -> String {
        let gradientId = "radialGradient-\(objectIdentifier)"

        var svg = "<radialGradient id=\"\(gradientId)\" "
        svg += "cx=\"50%\" cy=\"50%\" r=\"50%\">\n"

        // Generate color stops
        let step = colors.count > 1 ? 100.0 / Double(colors.count - 1) : 0.0
        for (index, color) in colors.enumerated() {
            let offset = colors.count > 1 ? Double(index) * step : 0.0
            svg += "  <stop offset=\"\(offset)%\" stop-color=\"\(color.cssValue)\" />\n"
        }

        svg += "</radialGradient>"
        return svg
    }

    /// A unique identifier for this gradient instance.
    private var objectIdentifier: String {
        // Create a stable identifier based on gradient properties
        let colorHash = colors.map { $0.cssValue }.joined(separator: "-")
        return colorHash.replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "#", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
            .replacingOccurrences(of: ",", with: "")
    }
}
