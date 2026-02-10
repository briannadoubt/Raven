import Foundation

/// A rectangular shape.
///
/// A rectangle is a four-sided shape with right angles at each corner.
/// In Raven, rectangles fill the entire bounds provided to the `path(in:)`
/// method, making them useful for backgrounds, containers, and layout.
///
/// ## Creating a Rectangle
///
/// Create a rectangle and fill it with a color:
///
/// ```swift
/// Rectangle()
///     .fill(Color.blue)
///     .frame(width: 200, height: 100)
/// ```
///
/// ## Stroking a Rectangle
///
/// Draw just the outline of a rectangle:
///
/// ```swift
/// Rectangle()
///     .stroke(Color.black, lineWidth: 2)
///     .frame(width: 150, height: 75)
/// ```
///
/// ## Usage as a Divider
///
/// Rectangles make excellent dividers:
///
/// ```swift
/// Rectangle()
///     .fill(Color.gray)
///     .frame(height: 1)
/// ```
///
/// ## Overlays and Backgrounds
///
/// Use rectangles to add backgrounds to other views:
///
/// ```swift
/// Text("Hello")
///     .padding()
///     .background(
///         Rectangle()
///             .fill(Color.blue.opacity(0.2))
///     )
/// ```
///
/// ## SVG Rendering
///
/// In Raven, rectangles are rendered as SVG `<rect>` elements using the
/// path-based approach. This provides clean, efficient vector graphics
/// that scale perfectly.
///
/// ## Topics
///
/// ### Creating a Rectangle
/// - ``init()``
///
/// ### Shape Protocol
/// - ``path(in:)``
///
/// - Note: For rectangles with rounded corners, use ``RoundedRectangle``
///   instead. For pill-shaped rectangles, use ``Capsule``.
public struct Rectangle: Shape, Sendable {
    /// Creates a new rectangle shape.
    ///
    /// The rectangle will fill the entire bounds provided to the
    /// `path(in:)` method.
    public init() {}

    /// Describes the rectangle's path within the specified rectangle.
    ///
    /// The path fills the entire provided rectangle with straight edges
    /// and right angles at each corner.
    ///
    /// - Parameter rect: The rectangle bounds to fill.
    /// - Returns: A path representing the rectangle.
    @MainActor public func path(in rect: CGRect) -> Path {
        return Path(rect)
    }
}
