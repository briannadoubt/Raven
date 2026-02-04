import Foundation

/// Vertical alignment for views within a horizontal container.
///
/// Used by `HStack` to control how child views are aligned vertically
/// when their heights differ.
public enum VerticalAlignment: Sendable, Hashable {
    /// Align views to their top edges.
    case top

    /// Align views to their vertical centers.
    case center

    /// Align views to their bottom edges.
    case bottom

    /// Convert to CSS align-items value for flexbox.
    public var cssValue: String {
        switch self {
        case .top:
            return "flex-start"
        case .center:
            return "center"
        case .bottom:
            return "flex-end"
        }
    }
}

/// Horizontal alignment for views within a vertical container.
///
/// Used by `VStack` to control how child views are aligned horizontally
/// when their widths differ.
public enum HorizontalAlignment: Sendable, Hashable {
    /// Align views to their leading edges (left in LTR, right in RTL).
    case leading

    /// Align views to their horizontal centers.
    case center

    /// Align views to their trailing edges (right in LTR, left in RTL).
    case trailing

    /// Convert to CSS align-items value for flexbox.
    public var cssValue: String {
        switch self {
        case .leading:
            return "flex-start"
        case .center:
            return "center"
        case .trailing:
            return "flex-end"
        }
    }
}

// MARK: - Combined Alignment

/// Combined alignment for both horizontal and vertical axes.
///
/// Used by `ZStack` and grid layouts to control how child views are aligned
/// when they differ in size. This type combines both horizontal and vertical
/// alignment into a single value.
public struct Alignment: Sendable, Hashable {
    /// The horizontal alignment component
    public let horizontal: HorizontalAlignment

    /// The vertical alignment component
    public let vertical: VerticalAlignment

    /// Creates an alignment with the specified horizontal and vertical components.
    ///
    /// - Parameters:
    ///   - horizontal: The horizontal alignment component.
    ///   - vertical: The vertical alignment component.
    public init(horizontal: HorizontalAlignment, vertical: VerticalAlignment) {
        self.horizontal = horizontal
        self.vertical = vertical
    }

    /// Convert to CSS place-items value for grid layout.
    ///
    /// This combines vertical and horizontal alignment into a single CSS property value.
    /// CSS place-items takes: <align-items> <justify-items>
    /// - align-items controls vertical alignment (block axis)
    /// - justify-items controls horizontal alignment (inline axis)
    public var cssValue: String {
        return "\(vertical.cssValue) \(horizontal.cssValue)"
    }

    // MARK: - Common Alignments

    /// Center alignment on both axes
    public static let center = Alignment(horizontal: .center, vertical: .center)

    /// Leading top alignment
    public static let topLeading = Alignment(horizontal: .leading, vertical: .top)

    /// Center top alignment
    public static let top = Alignment(horizontal: .center, vertical: .top)

    /// Trailing top alignment
    public static let topTrailing = Alignment(horizontal: .trailing, vertical: .top)

    /// Leading center alignment
    public static let leading = Alignment(horizontal: .leading, vertical: .center)

    /// Trailing center alignment
    public static let trailing = Alignment(horizontal: .trailing, vertical: .center)

    /// Leading bottom alignment
    public static let bottomLeading = Alignment(horizontal: .leading, vertical: .bottom)

    /// Center bottom alignment
    public static let bottom = Alignment(horizontal: .center, vertical: .bottom)

    /// Trailing bottom alignment
    public static let bottomTrailing = Alignment(horizontal: .trailing, vertical: .bottom)
}
