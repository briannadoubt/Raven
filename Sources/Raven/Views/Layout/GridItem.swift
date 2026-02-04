import Foundation

/// A description of a row or column in a lazy grid.
///
/// Use `GridItem` to describe the behavior of columns in a `LazyVGrid` or rows
/// in a `LazyHGrid`. Each grid item defines how its corresponding track should
/// size and align its content.
///
/// Example:
/// ```swift
/// LazyVGrid(columns: [
///     GridItem(.fixed(100)),           // Fixed 100px column
///     GridItem(.flexible(minimum: 50)), // Flexible column with 50px minimum
///     GridItem(.adaptive(minimum: 80))  // Adaptive columns, each at least 80px
/// ]) {
///     ForEach(0..<20) { index in
///         Text("Item \(index)")
///     }
/// }
/// ```
public struct GridItem: Sendable, Hashable {
    /// The size of a grid item.
    ///
    /// Use size values to configure how a grid item should be sized:
    /// - `.fixed`: A column or row with a fixed size in points
    /// - `.flexible`: A column or row that grows to fill available space
    /// - `.adaptive`: Multiple columns or rows that adapt to available space
    public enum Size: Sendable, Hashable {
        /// A single item with a fixed size.
        ///
        /// The item will always be the specified size in points.
        ///
        /// - Parameter value: The size of the item in points.
        case fixed(Double)

        /// A single item that can grow and shrink.
        ///
        /// The item will grow to fill available space, respecting the
        /// minimum and maximum constraints.
        ///
        /// - Parameters:
        ///   - minimum: The minimum size of the item. Defaults to 10.
        ///   - maximum: The maximum size of the item. Defaults to infinity.
        case flexible(minimum: Double = 10, maximum: Double = .infinity)

        /// Multiple items in the space of a single flexible item.
        ///
        /// The grid will create as many items as fit in the available space,
        /// with each item being at least the minimum size.
        ///
        /// - Parameters:
        ///   - minimum: The minimum size of each item. Defaults to 10.
        ///   - maximum: The maximum size of each item. Defaults to infinity.
        case adaptive(minimum: Double = 10, maximum: Double = .infinity)
    }

    /// The size of this grid item.
    public let size: Size

    /// The spacing to the next item.
    ///
    /// If `nil`, the grid uses the spacing parameter passed to its initializer.
    public let spacing: Double?

    /// The spacing to the next item.
    ///
    /// If `nil`, the grid uses the spacing parameter passed to its initializer.
    /// Note: Per-item alignment is not currently supported in CSS Grid layout.

    /// Creates a grid item with the specified size and spacing.
    ///
    /// - Parameters:
    ///   - size: The size of the grid item. Defaults to `.flexible()`.
    ///   - spacing: The spacing to the next item, or `nil` to use the grid's spacing.
    public init(
        _ size: Size = .flexible(),
        spacing: Double? = nil
    ) {
        self.size = size
        self.spacing = spacing
    }

    /// Convert this grid item to a CSS grid template value.
    ///
    /// This generates the appropriate CSS value for `grid-template-columns` or
    /// `grid-template-rows` based on the size configuration.
    ///
    /// - Returns: A CSS grid track sizing value.
    internal func toCSSTemplate() -> String {
        switch size {
        case .fixed(let value):
            return "\(value)px"

        case .flexible(let minimum, let maximum):
            let minValue = "\(minimum)px"
            let maxValue = maximum.isInfinite ? "1fr" : "\(maximum)px"
            return "minmax(\(minValue), \(maxValue))"

        case .adaptive(let minimum, let maximum):
            let minValue = "\(minimum)px"
            let maxValue = maximum.isInfinite ? "1fr" : "\(maximum)px"
            // For adaptive, we use auto-fit with minmax
            // This will be wrapped in repeat(auto-fit, ...) by the grid view
            return "minmax(\(minValue), \(maxValue))"
        }
    }

    /// Check if this grid item is adaptive.
    ///
    /// Adaptive items need special handling in CSS with `repeat(auto-fit, ...)`.
    internal var isAdaptive: Bool {
        if case .adaptive = size {
            return true
        }
        return false
    }
}
