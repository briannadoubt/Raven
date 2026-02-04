import Foundation

/// A circular shape.
///
/// A circle is a shape that is equidistant from its center at all points.
/// In Raven, circles are inscribed within the rectangle provided to the
/// `path(in:)` method. If the rectangle is not square, the circle will
/// be inscribed in the smallest dimension, creating a perfect circle
/// rather than an ellipse.
///
/// ## Creating a Circle
///
/// Create a circle and fill it with a color:
///
/// ```swift
/// Circle()
///     .fill(Color.blue)
///     .frame(width: 100, height: 100)
/// ```
///
/// ## Stroking a Circle
///
/// Draw just the outline of a circle:
///
/// ```swift
/// Circle()
///     .stroke(Color.red, lineWidth: 3)
///     .frame(width: 50, height: 50)
/// ```
///
/// ## Usage as a Button Background
///
/// Circles make excellent button backgrounds:
///
/// ```swift
/// ZStack {
///     Circle()
///         .fill(Color.blue)
///     Text("Tap")
///         .foregroundColor(.white)
/// }
/// .frame(width: 60, height: 60)
/// ```
///
/// ## SVG Rendering
///
/// In Raven, circles are rendered as SVG `<ellipse>` elements using the
/// path-based approach for consistency with other shapes. This provides
/// resolution-independent graphics that scale perfectly at any size.
///
/// ## Topics
///
/// ### Creating a Circle
/// - ``init()``
///
/// ### Shape Protocol
/// - ``path(in:)``
///
/// - Note: For an ellipse that fills non-square rectangles, use ``Ellipse``
///   instead. Circle always produces a perfect circle inscribed in the
///   provided rectangle.
public struct Circle: Shape, Sendable {
    /// Creates a new circle shape.
    ///
    /// The circle will be inscribed within the rectangle provided to the
    /// `path(in:)` method. If the rectangle is not square, the circle will
    /// fit within the smallest dimension.
    public init() {}

    /// Describes the circle's path within the specified rectangle.
    ///
    /// The circle is centered in the rectangle and inscribed with a diameter
    /// equal to the minimum of the rectangle's width and height. This ensures
    /// the circle is always perfectly round, even in non-square rectangles.
    ///
    /// - Parameter rect: The rectangle in which to inscribe the circle.
    /// - Returns: A path representing the circle.
    @MainActor public func path(in rect: CGRect) -> Path {
        // Use the smaller dimension to ensure a perfect circle
        let diameter = min(rect.width, rect.height)
        let radius = diameter / 2

        // Center the circle in the rect
        let centerX = rect.midX
        let centerY = rect.midY

        // Create a square rect centered in the original rect
        let circleRect = CGRect(
            x: centerX - radius,
            y: centerY - radius,
            width: diameter,
            height: diameter
        )

        return Path(ellipseIn: circleRect)
    }
}
