import Foundation

/// A color gradient for canvas drawing.
///
/// Gradients can be used to fill or stroke paths with smooth color transitions.
/// Raven supports both linear and radial gradients via the GraphicsContext.
///
/// ## Overview
///
/// While SwiftUI provides `LinearGradient` and `RadialGradient` for declarative views,
/// Canvas uses `GraphicsContext.Gradient` for imperative drawing. This type provides
/// a lightweight gradient representation optimized for canvas rendering.
///
/// ## Creating Linear Gradients
///
/// ```swift
/// Canvas { context, size in
///     let gradient = GraphicsContext.Gradient(
///         colors: [.red, .orange, .yellow],
///         startPoint: CGPoint(x: 0, y: 0),
///         endPoint: CGPoint(x: size.width, y: 0)
///     )
///     context.fill(
///         Path(CGRect(origin: CGPoint.zero, size: size)),
///         with: .gradient(gradient)
///     )
/// }
/// ```
///
/// ## Creating Radial Gradients
///
/// ```swift
/// Canvas { context, size in
///     let gradient = GraphicsContext.Gradient(
///         colors: [.white, .blue, .black],
///         center: CGPoint(x: size.width / 2, y: size.height / 2),
///         startRadius: 0,
///         endRadius: min(size.width, size.height) / 2
///     )
///     context.fill(
///         Path(ellipseIn: CGRect(origin: CGPoint.zero, size: size)),
///         with: .gradient(gradient)
///     )
/// }
/// ```
///
/// ## Color Stops
///
/// Canvas gradients automatically distribute colors evenly across the gradient range.
/// For custom color stop positions, you would need to create multiple gradients or
/// use intermediate colors.
///
/// - Note: Canvas gradients are created on-demand during rendering and don't require
///   SVG gradient definitions like declarative Shape gradients do.

// Gradient is defined in GraphicsContext.swift as GraphicsContext.Gradient
// This file provides additional gradient utilities and documentation

extension GraphicsContext.Gradient {
    /// Creates a horizontal linear gradient.
    ///
    /// - Parameters:
    ///   - colors: The gradient colors from left to right.
    ///   - width: The width of the gradient.
    /// - Returns: A linear gradient.
    public static func horizontal(colors: [Color], width: Double) -> GraphicsContext.Gradient {
        GraphicsContext.Gradient(
            colors: colors,
            startPoint: CGPoint(x: 0, y: 0),
            endPoint: CGPoint(x: width, y: 0)
        )
    }

    /// Creates a vertical linear gradient.
    ///
    /// - Parameters:
    ///   - colors: The gradient colors from top to bottom.
    ///   - height: The height of the gradient.
    /// - Returns: A linear gradient.
    public static func vertical(colors: [Color], height: Double) -> GraphicsContext.Gradient {
        GraphicsContext.Gradient(
            colors: colors,
            startPoint: CGPoint(x: 0, y: 0),
            endPoint: CGPoint(x: 0, y: height)
        )
    }

    /// Creates a diagonal linear gradient.
    ///
    /// - Parameters:
    ///   - colors: The gradient colors from top-left to bottom-right.
    ///   - size: The size of the gradient area.
    /// - Returns: A linear gradient.
    public static func diagonal(colors: [Color], size: CGSize) -> GraphicsContext.Gradient {
        GraphicsContext.Gradient(
            colors: colors,
            startPoint: CGPoint.zero,
            endPoint: CGPoint(x: size.width, y: size.height)
        )
    }

    /// Creates an angular (conic) linear gradient approximation.
    ///
    /// Note: True conic gradients are not supported by HTML5 Canvas 2D context.
    /// This creates a linear gradient at the specified angle.
    ///
    /// - Parameters:
    ///   - colors: The gradient colors.
    ///   - center: The center point.
    ///   - angle: The gradient angle.
    ///   - length: The length of the gradient.
    /// - Returns: A linear gradient.
    public static func angular(
        colors: [Color],
        center: CGPoint,
        angle: Angle,
        length: Double
    ) -> GraphicsContext.Gradient {
        let radians = angle.radians
        let endX = center.x + length * cos(radians)
        let endY = center.y + length * sin(radians)
        let startX = center.x - length * cos(radians)
        let startY = center.y - length * sin(radians)

        return GraphicsContext.Gradient(
            colors: colors,
            startPoint: CGPoint(x: startX, y: startY),
            endPoint: CGPoint(x: endX, y: endY)
        )
    }

    /// Creates a radial gradient centered at a point.
    ///
    /// - Parameters:
    ///   - colors: The gradient colors from center outward.
    ///   - center: The center point.
    ///   - radius: The radius of the gradient.
    /// - Returns: A radial gradient.
    public static func radial(
        colors: [Color],
        center: CGPoint,
        radius: Double
    ) -> GraphicsContext.Gradient {
        GraphicsContext.Gradient(
            colors: colors,
            center: center,
            startRadius: 0,
            endRadius: radius
        )
    }

    /// Creates a radial gradient that fills a rectangular area.
    ///
    /// - Parameters:
    ///   - colors: The gradient colors from center outward.
    ///   - rect: The rectangular area to fill.
    /// - Returns: A radial gradient.
    public static func radial(colors: [Color], in rect: CGRect) -> GraphicsContext.Gradient {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = sqrt(pow(rect.width / 2, 2) + pow(rect.height / 2, 2))

        return GraphicsContext.Gradient(
            colors: colors,
            center: center,
            startRadius: 0,
            endRadius: radius
        )
    }
}

// MARK: - Common Gradient Presets

extension GraphicsContext.Gradient {
    /// A rainbow gradient with smooth color transitions.
    public static func rainbow(size: CGSize) -> GraphicsContext.Gradient {
        horizontal(
            colors: [.red, .orange, .yellow, .green, .blue, .purple],
            width: size.width
        )
    }

    /// A sunset gradient from orange to purple.
    public static func sunset(size: CGSize) -> GraphicsContext.Gradient {
        vertical(
            colors: [
                Color(red: 1.0, green: 0.6, blue: 0.2),
                Color(red: 1.0, green: 0.4, blue: 0.3),
                Color(red: 0.8, green: 0.3, blue: 0.5),
                Color(red: 0.4, green: 0.2, blue: 0.6)
            ],
            height: size.height
        )
    }

    /// A ocean gradient from light to deep blue.
    public static func ocean(size: CGSize) -> GraphicsContext.Gradient {
        vertical(
            colors: [
                Color(red: 0.4, green: 0.7, blue: 0.9),
                Color(red: 0.2, green: 0.5, blue: 0.8),
                Color(red: 0.1, green: 0.3, blue: 0.6)
            ],
            height: size.height
        )
    }

    /// A metallic silver gradient.
    public static func metal(size: CGSize) -> GraphicsContext.Gradient {
        horizontal(
            colors: [
                Color(white: 0.7),
                Color(white: 0.9),
                Color(white: 0.7),
                Color(white: 0.5)
            ],
            width: size.width
        )
    }
}
