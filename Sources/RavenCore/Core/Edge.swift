import Foundation

/// An edge of a rectangle.
///
/// Use edges to specify which side of a view to apply effects to, such as
/// padding, transitions, or safe area insets.
///
/// ## Example Usage
///
/// ```swift
/// // Slide in from the leading edge
/// DetailView()
///     .transition(.move(edge: .leading))
///
/// // Add padding on specific edges
/// Text("Hello")
///     .padding([.top, .bottom], 20)
/// ```
///
/// ## Topics
///
/// ### Edge Cases
/// - ``top``
/// - ``bottom``
/// - ``leading``
/// - ``trailing``
///
/// ### Edge Sets
/// - ``Set``
///
/// - Note: Leading and trailing edges adapt to the current layout direction,
///   with leading being left in LTR layouts and right in RTL layouts.
public enum Edge: String, Sendable, Hashable, CaseIterable {
    /// The top edge of a rectangle.
    case top

    /// The bottom edge of a rectangle.
    case bottom

    /// The leading edge of a rectangle.
    ///
    /// This is the left edge in left-to-right layouts and the right edge
    /// in right-to-left layouts.
    case leading

    /// The trailing edge of a rectangle.
    ///
    /// This is the right edge in left-to-right layouts and the left edge
    /// in right-to-left layouts.
    case trailing

    /// A set of edges.
    ///
    /// Use edge sets to specify multiple edges at once:
    ///
    /// ```swift
    /// Text("Hello")
    ///     .padding([.horizontal])  // Leading and trailing
    ///     .padding([.top, .bottom], 10)  // Top and bottom
    /// ```
    public struct Set: OptionSet, Sendable, Hashable {
        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        /// The top edge.
        public static let top = Set(rawValue: 1 << 0)

        /// The bottom edge.
        public static let bottom = Set(rawValue: 1 << 1)

        /// The leading edge.
        public static let leading = Set(rawValue: 1 << 2)

        /// The trailing edge.
        public static let trailing = Set(rawValue: 1 << 3)

        /// All edges.
        public static let all: Set = [.top, .bottom, .leading, .trailing]

        /// The horizontal edges (leading and trailing).
        public static let horizontal: Set = [.leading, .trailing]

        /// The vertical edges (top and bottom).
        public static let vertical: Set = [.top, .bottom]
    }
}

// MARK: - CSS Translation

extension Edge {
    /// Returns the CSS property name for this edge in transform operations.
    ///
    /// This is used internally by the transition system to generate
    /// appropriate CSS transforms.
    internal var cssTransformAxis: String {
        switch self {
        case .top:
            return "translateY(-100%)"
        case .bottom:
            return "translateY(100%)"
        case .leading:
            return "translateX(-100%)"
        case .trailing:
            return "translateX(100%)"
        }
    }

    /// Returns the opposite edge.
    ///
    /// - Returns: The edge opposite to this one.
    internal var opposite: Edge {
        switch self {
        case .top:
            return .bottom
        case .bottom:
            return .top
        case .leading:
            return .trailing
        case .trailing:
            return .leading
        }
    }
}
