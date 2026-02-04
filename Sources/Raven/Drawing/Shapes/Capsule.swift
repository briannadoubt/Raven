import Foundation

/// A capsule shape with fully rounded ends.
///
/// A capsule is a rounded rectangle where the corner radius is automatically
/// set to half the minimum dimension, creating a pill shape with completely
/// rounded ends. This is commonly used for toggle switches, tags, and modern
/// button designs.
///
/// ## Creating a Capsule
///
/// Create a capsule and fill it with a color:
///
/// ```swift
/// Capsule()
///     .fill(Color.blue)
///     .frame(width: 100, height: 40)
/// ```
///
/// ## Stroking with Border
///
/// Since `Capsule` conforms to `InsettableShape`, you can use `strokeBorder`
/// to keep the stroke inside the bounds:
///
/// ```swift
/// Capsule()
///     .strokeBorder(Color.blue, lineWidth: 3)
///     .frame(width: 80, height: 30)
/// ```
///
/// ## Toggle Switch Style
///
/// Capsules are perfect for creating toggle switches:
///
/// ```swift
/// ZStack(alignment: .leading) {
///     Capsule()
///         .fill(isOn ? Color.green : Color.gray)
///     Circle()
///         .fill(Color.white)
///         .padding(2)
///         .offset(x: isOn ? 20 : 0)
/// }
/// .frame(width: 50, height: 30)
/// ```
///
/// ## Tag or Badge Design
///
/// Create tag-like elements with capsules:
///
/// ```swift
/// Text("New")
///     .padding(.horizontal, 12)
///     .padding(.vertical, 6)
///     .background(
///         Capsule()
///             .fill(Color.red)
///     )
///     .foregroundColor(.white)
/// ```
///
/// ## Pill-Shaped Buttons
///
/// Capsules make excellent pill-shaped button backgrounds:
///
/// ```swift
/// Text("Subscribe")
///     .padding()
///     .background(
///         Capsule()
///             .fill(Color.blue)
///     )
///     .foregroundColor(.white)
/// ```
///
/// ## Adaptive Rounding
///
/// Unlike `RoundedRectangle`, a capsule automatically adjusts its corner
/// radius based on its dimensions. If the shape is 100 points wide and
/// 40 points tall, the corners will have a 20-point radius (half of 40),
/// creating perfect semi-circles at each end.
///
/// ## SVG Rendering
///
/// In Raven, capsules are rendered using SVG path commands with quadratic
/// curves for the fully rounded ends. The corner radius is automatically
/// calculated to be half the minimum dimension.
///
/// ## Topics
///
/// ### Creating a Capsule
/// - ``init()``
///
/// ### Shape Protocol
/// - ``path(in:)``
///
/// ### Insettable Shape
/// - ``inset(by:)``
///
/// - Note: For custom corner radii, use ``RoundedRectangle`` instead.
///   Capsule always uses the maximum possible corner radius for its dimensions.
public struct Capsule: InsettableShape, Sendable {
    /// The amount this shape has been inset.
    public var insetAmount: CGFloat = 0

    /// Creates a new capsule shape.
    ///
    /// The capsule will have fully rounded ends, with a corner radius equal
    /// to half the minimum dimension of the rectangle provided to `path(in:)`.
    public init() {}

    /// Describes the capsule's path within the specified rectangle.
    ///
    /// The path creates a rounded rectangle with the corner radius set to
    /// half the minimum dimension, creating a pill shape with completely
    /// rounded ends.
    ///
    /// - Parameter rect: The rectangle bounds to fill.
    /// - Returns: A path representing the capsule.
    @MainActor public func path(in rect: CGRect) -> Path {
        // Apply inset
        let insetRect = rect.insetBy(dx: insetAmount, dy: insetAmount)

        // Use half the minimum dimension for the corner radius to create
        // a true capsule/pill shape with fully rounded ends
        let cornerRadius = min(insetRect.width, insetRect.height) / 2

        return Path(roundedRect: insetRect, cornerRadius: cornerRadius)
    }

    /// Returns a new capsule that is inset by the specified amount.
    ///
    /// Insetting moves all edges toward the center by the specified amount,
    /// making the shape smaller. This is used by the `strokeBorder` modifier
    /// to keep strokes inside the shape's bounds.
    ///
    /// - Parameter amount: The amount to inset the shape.
    /// - Returns: A new inset capsule.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let capsule = Capsule()
    /// let insetCapsule = capsule.inset(by: 5)  // 5 points smaller on all sides
    /// ```
    @MainActor public func inset(by amount: CGFloat) -> Capsule {
        var shape = self
        shape.insetAmount += amount
        return shape
    }
}
