import Foundation

/// An elliptical shape.
///
/// An ellipse is a closed curve where the sum of distances from any point on
/// the curve to two fixed points (foci) is constant. Unlike a circle, an
/// ellipse can have different horizontal and vertical radii, allowing it to
/// be stretched in one direction.
///
/// In Raven, ellipses fill the entire rectangle provided to the `path(in:)`
/// method, creating a perfect oval that touches all four sides.
///
/// ## Creating an Ellipse
///
/// Create an ellipse and fill it with a color:
///
/// ```swift
/// Ellipse()
///     .fill(Color.blue)
///     .frame(width: 200, height: 100)
/// ```
///
/// ## Difference from Circle
///
/// While `Circle` always produces a perfect circle (even in non-square rectangles),
/// `Ellipse` stretches to fill the entire rectangle:
///
/// ```swift
/// // Circle - creates a perfect circle in the center
/// Circle()
///     .fill(Color.red)
///     .frame(width: 200, height: 100)
///
/// // Ellipse - creates an oval that fills the entire frame
/// Ellipse()
///     .fill(Color.blue)
///     .frame(width: 200, height: 100)
/// ```
///
/// ## Stroking an Ellipse
///
/// Draw just the outline of an ellipse:
///
/// ```swift
/// Ellipse()
///     .stroke(Color.black, lineWidth: 2)
///     .frame(width: 150, height: 80)
/// ```
///
/// ## Usage for Avatars
///
/// Ellipses can create oval avatar frames:
///
/// ```swift
/// Image("profile")
///     .resizable()
///     .frame(width: 120, height: 150)
///     .clipShape(Ellipse())
/// ```
///
/// ## Loading Indicators
///
/// Create animated loading indicators with ellipses:
///
/// ```swift
/// Ellipse()
///     .trim(from: 0, to: 0.7)
///     .stroke(Color.blue, lineWidth: 4)
///     .frame(width: 40, height: 40)
///     .rotationEffect(.degrees(rotation))
/// ```
///
/// ## SVG Rendering
///
/// In Raven, ellipses are rendered as SVG path elements using Bezier curve
/// approximations. This provides smooth, resolution-independent ovals that
/// scale perfectly at any size.
///
/// ## Topics
///
/// ### Creating an Ellipse
/// - ``init()``
///
/// ### Shape Protocol
/// - ``path(in:)``
///
/// - Note: For a perfect circle that doesn't stretch, use ``Circle`` instead.
///   Ellipse always fills the entire provided rectangle, creating an oval
///   if the rectangle is not square.
public struct Ellipse: Shape, Sendable {
    /// Creates a new ellipse shape.
    ///
    /// The ellipse will fill the entire bounds provided to the `path(in:)`
    /// method, creating an oval that touches all four sides of the rectangle.
    public init() {}

    /// Describes the ellipse's path within the specified rectangle.
    ///
    /// The path creates an ellipse that fills the entire provided rectangle.
    /// The ellipse touches the midpoint of each side of the rectangle.
    ///
    /// - Parameter rect: The rectangle to fill with the ellipse.
    /// - Returns: A path representing the ellipse.
    @MainActor public func path(in rect: CGRect) -> Path {
        return Path(ellipseIn: rect)
    }
}
