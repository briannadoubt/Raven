import Foundation

/// A normalized point in a view's coordinate space.
///
/// A unit point represents a position in a view where (0, 0) is the top-leading
/// corner and (1, 1) is the bottom-trailing corner. Values between 0 and 1
/// represent positions within the view, while values outside this range
/// represent positions beyond the view's bounds.
///
/// ## Example Usage
///
/// ```swift
/// // Scale from the center
/// Circle()
///     .scaleEffect(2.0, anchor: .center)
///
/// // Rotate around the top-leading corner
/// Rectangle()
///     .rotationEffect(.degrees(45), anchor: .topLeading)
///
/// // Scale transition from bottom-trailing
/// DetailView()
///     .transition(.scale(scale: 0.5, anchor: .bottomTrailing))
/// ```
///
/// ## Common Unit Points
///
/// Use the static properties for common anchor points:
/// - `.center` - The center of the view
/// - `.topLeading` - The top-leading corner
/// - `.bottomTrailing` - The bottom-trailing corner
///
/// Or create custom points:
/// ```swift
/// let customPoint = UnitPoint(x: 0.75, y: 0.25)  // 75% right, 25% down
/// ```
///
/// ## Topics
///
/// ### Creating Unit Points
/// - ``init(x:y:)``
///
/// ### Getting Point Values
/// - ``x``
/// - ``y``
///
/// ### Common Points
/// - ``zero``
/// - ``center``
/// - ``top``
/// - ``bottom``
/// - ``leading``
/// - ``trailing``
/// - ``topLeading``
/// - ``topTrailing``
/// - ``bottomLeading``
/// - ``bottomTrailing``
///
/// - Note: Unit points are coordinate-space independent and automatically
///   adapt to different view sizes and layout directions.
public struct UnitPoint: Sendable, Hashable {
    /// The normalized x-coordinate.
    ///
    /// A value of 0 represents the leading edge, and a value of 1 represents
    /// the trailing edge.
    public var x: Double

    /// The normalized y-coordinate.
    ///
    /// A value of 0 represents the top edge, and a value of 1 represents
    /// the bottom edge.
    public var y: Double

    /// Creates a unit point with the specified coordinates.
    ///
    /// - Parameters:
    ///   - x: The normalized x-coordinate (0.0 to 1.0, where 0 is leading and 1 is trailing).
    ///   - y: The normalized y-coordinate (0.0 to 1.0, where 0 is top and 1 is bottom).
    ///
    /// ## Example
    ///
    /// ```swift
    /// let topQuarter = UnitPoint(x: 0.5, y: 0.25)  // Centered horizontally, 25% from top
    /// let customAnchor = UnitPoint(x: 0.3, y: 0.7)  // 30% from leading, 70% from top
    /// ```
    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }

    // MARK: - Common Points

    /// The origin point (0, 0) at the top-leading corner.
    ///
    /// Equivalent to `.topLeading`.
    public static let zero = UnitPoint(x: 0, y: 0)

    /// The center point (0.5, 0.5).
    ///
    /// This is the most commonly used anchor point for transformations.
    ///
    /// ## Example
    ///
    /// ```swift
    /// Text("Hello")
    ///     .scaleEffect(1.5, anchor: .center)
    /// ```
    public static let center = UnitPoint(x: 0.5, y: 0.5)

    /// The top-center point (0.5, 0).
    ///
    /// Useful for vertical transformations that should pivot from the top.
    public static let top = UnitPoint(x: 0.5, y: 0)

    /// The bottom-center point (0.5, 1).
    ///
    /// Useful for vertical transformations that should pivot from the bottom.
    public static let bottom = UnitPoint(x: 0.5, y: 1)

    /// The leading-center point (0, 0.5).
    ///
    /// Useful for horizontal transformations that should pivot from the leading edge.
    public static let leading = UnitPoint(x: 0, y: 0.5)

    /// The trailing-center point (1, 0.5).
    ///
    /// Useful for horizontal transformations that should pivot from the trailing edge.
    public static let trailing = UnitPoint(x: 1, y: 0.5)

    /// The top-leading corner point (0, 0).
    ///
    /// This is the origin point in the view's coordinate space.
    ///
    /// ## Example
    ///
    /// ```swift
    /// Rectangle()
    ///     .rotationEffect(.degrees(45), anchor: .topLeading)
    /// ```
    public static let topLeading = UnitPoint(x: 0, y: 0)

    /// The top-trailing corner point (1, 0).
    ///
    /// Useful for transformations that should pivot from the top-trailing corner.
    public static let topTrailing = UnitPoint(x: 1, y: 0)

    /// The bottom-leading corner point (0, 1).
    ///
    /// Useful for transformations that should pivot from the bottom-leading corner.
    public static let bottomLeading = UnitPoint(x: 0, y: 1)

    /// The bottom-trailing corner point (1, 1).
    ///
    /// Useful for transformations that should pivot from the bottom-trailing corner.
    ///
    /// ## Example
    ///
    /// ```swift
    /// Image("photo")
    ///     .scaleEffect(2.0, anchor: .bottomTrailing)
    /// ```
    public static let bottomTrailing = UnitPoint(x: 1, y: 1)
}

// MARK: - CSS Translation

extension UnitPoint {
    /// Returns the CSS transform-origin value for this unit point.
    ///
    /// This is used internally by the rendering system to set the CSS
    /// `transform-origin` property for animations and transformations.
    ///
    /// - Returns: A CSS transform-origin value (e.g., "50% 50%").
    internal var cssTransformOrigin: String {
        "\(x * 100)% \(y * 100)%"
    }
}

// MARK: - CustomStringConvertible

extension UnitPoint: CustomStringConvertible {
    public var description: String {
        "UnitPoint(x: \(x), y: \(y))"
    }
}
