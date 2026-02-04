import Foundation

/// A rectangular shape with rounded corners.
///
/// A rounded rectangle is like a rectangle but with smoothly curved corners
/// instead of sharp right angles. The corner radius determines how much the
/// corners are rounded. This shape is commonly used for buttons, cards, and
/// modern UI elements.
///
/// ## Creating a Rounded Rectangle
///
/// Create a rounded rectangle with a corner radius:
///
/// ```swift
/// RoundedRectangle(cornerRadius: 12)
///     .fill(Color.blue)
///     .frame(width: 200, height: 100)
/// ```
///
/// ## Using Corner Size
///
/// For different horizontal and vertical corner radii:
///
/// ```swift
/// RoundedRectangle(cornerSize: CGSize(width: 20, height: 10))
///     .fill(Color.green)
///     .frame(width: 150, height: 80)
/// ```
///
/// ## Stroking with Border
///
/// Since `RoundedRectangle` conforms to `InsettableShape`, you can use
/// `strokeBorder` to keep the stroke inside the bounds:
///
/// ```swift
/// RoundedRectangle(cornerRadius: 8)
///     .strokeBorder(Color.blue, lineWidth: 4)
///     .frame(width: 100, height: 60)
/// ```
///
/// ## Button Styling
///
/// Rounded rectangles are perfect for button backgrounds:
///
/// ```swift
/// Text("Tap Me")
///     .padding()
///     .background(
///         RoundedRectangle(cornerRadius: 10)
///             .fill(Color.blue)
///     )
/// ```
///
/// ## Card Design
///
/// Create card-like containers with rounded corners:
///
/// ```swift
/// VStack {
///     Text("Title")
///         .font(.headline)
///     Text("Content")
/// }
/// .padding()
/// .background(
///     RoundedRectangle(cornerRadius: 16)
///         .fill(Color.white)
///         .shadow(radius: 4)
/// )
/// ```
///
/// ## SVG Rendering
///
/// In Raven, rounded rectangles are rendered using SVG path commands with
/// quadratic curves for the corners. This provides smooth, resolution-independent
/// corners that scale perfectly at any size.
///
/// ## Topics
///
/// ### Creating a Rounded Rectangle
/// - ``init(cornerRadius:)``
/// - ``init(cornerSize:)``
///
/// ### Shape Protocol
/// - ``path(in:)``
///
/// ### Insettable Shape
/// - ``inset(by:)``
///
/// - Note: For fully rounded ends (pill shape), use ``Capsule`` instead.
///   For sharp corners, use ``Rectangle``.
public struct RoundedRectangle: InsettableShape, Sendable {
    /// The size of the rounded corners.
    public var cornerSize: CGSize

    /// The amount this shape has been inset.
    public var insetAmount: CGFloat = 0

    /// Creates a rounded rectangle with the specified corner radius.
    ///
    /// The corner radius is applied equally to all four corners in both
    /// horizontal and vertical directions.
    ///
    /// - Parameter cornerRadius: The radius of the rounded corners.
    ///
    /// ## Example
    ///
    /// ```swift
    /// RoundedRectangle(cornerRadius: 12)
    ///     .fill(Color.blue)
    /// ```
    public init(cornerRadius: CGFloat) {
        self.cornerSize = CGSize(width: cornerRadius, height: cornerRadius)
    }

    /// Creates a rounded rectangle with the specified corner size.
    ///
    /// This allows different horizontal and vertical corner radii, creating
    /// elliptical corners instead of circular ones.
    ///
    /// - Parameter cornerSize: The size of the rounded corners.
    ///
    /// ## Example
    ///
    /// ```swift
    /// RoundedRectangle(cornerSize: CGSize(width: 20, height: 10))
    ///     .fill(Color.green)
    /// ```
    public init(cornerSize: CGSize) {
        self.cornerSize = cornerSize
    }

    /// Describes the rounded rectangle's path within the specified rectangle.
    ///
    /// The path creates a rectangle with smoothly rounded corners. The corner
    /// size is clamped to ensure it doesn't exceed half the rectangle's width
    /// or height.
    ///
    /// - Parameter rect: The rectangle bounds to fill.
    /// - Returns: A path representing the rounded rectangle.
    @MainActor public func path(in rect: CGRect) -> Path {
        // Apply inset
        let insetRect = rect.insetBy(dx: insetAmount, dy: insetAmount)

        // Clamp corner size to valid range
        let effectiveCornerSize = CGSize(
            width: min(cornerSize.width, insetRect.width / 2),
            height: min(cornerSize.height, insetRect.height / 2)
        )

        return Path(roundedRect: insetRect, cornerSize: effectiveCornerSize)
    }

    /// Returns a new rounded rectangle that is inset by the specified amount.
    ///
    /// Insetting moves all edges toward the center by the specified amount,
    /// making the shape smaller. This is used by the `strokeBorder` modifier
    /// to keep strokes inside the shape's bounds.
    ///
    /// - Parameter amount: The amount to inset the shape.
    /// - Returns: A new inset rounded rectangle.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let rect = RoundedRectangle(cornerRadius: 12)
    /// let insetRect = rect.inset(by: 5)  // 5 points smaller on all sides
    /// ```
    @MainActor public func inset(by amount: CGFloat) -> RoundedRectangle {
        var shape = self
        shape.insetAmount += amount
        return shape
    }
}
