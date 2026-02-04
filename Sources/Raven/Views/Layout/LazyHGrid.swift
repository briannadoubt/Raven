import Foundation

/// A container view that arranges its child views in a grid that grows horizontally,
/// creating items only as needed.
///
/// `LazyHGrid` is a lazy grid container that creates its child views on demand,
/// arranging them in a horizontal scrolling grid with a specified number of rows.
/// It's ideal for displaying large collections of items in a multi-row layout that
/// scrolls horizontally.
///
/// The grid creates columns automatically as needed to accommodate all items, with
/// each column containing the number of rows specified by the `rows` parameter.
///
/// Example:
/// ```swift
/// LazyHGrid(
///     rows: [
///         GridItem(.fixed(100)),
///         GridItem(.flexible()),
///         GridItem(.fixed(100))
///     ],
///     spacing: 16
/// ) {
///     ForEach(photos) { photo in
///         PhotoView(photo: photo)
///     }
/// }
///
/// // For large datasets, use virtualization
/// LazyHGrid(rows: rows) {
///     ForEach(0..<10000) { index in
///         CellView(index: index)
///     }
/// }
/// .virtualized(estimatedItemHeight: 100)
/// ```
///
/// The grid renders as a CSS Grid layout with `auto-flow: column`, meaning items
/// flow into columns automatically.
///
/// ## Performance Optimization
///
/// For grids with thousands of items, use the `.virtualized()` modifier to enable
/// virtual scrolling and significantly improve rendering performance.
///
/// - Parameters:
///   - rows: An array of `GridItem` that describe the rows of the grid.
///   - alignment: The alignment of items within their grid cells. Defaults to `.center`.
///   - spacing: The spacing between rows and columns. Defaults to `nil` (no explicit spacing).
///   - pinnedViews: The kinds of child views to pin. Currently unused but included for API compatibility.
///   - content: A view builder that creates the child views.
public struct LazyHGrid<Content: View>: View, PrimitiveView, Sendable {
    public typealias Body = Never

    /// The row definitions for this grid
    let rows: [GridItem]

    /// The alignment of items within their grid cells
    let alignment: Alignment

    /// The spacing between rows and columns
    let spacing: Double?

    /// The child views
    let content: Content

    // MARK: - Initializers

    /// Creates a lazy horizontal grid with the specified rows, alignment, and spacing.
    ///
    /// - Parameters:
    ///   - rows: An array of `GridItem` that describe the rows of the grid.
    ///   - alignment: The alignment of items within their grid cells. Defaults to `.center`.
    ///   - spacing: The spacing between rows and columns in pixels. Defaults to `nil`.
    ///   - pinnedViews: The kinds of child views to pin. Currently unused but included for API compatibility.
    ///   - content: A view builder that creates the child views.
    @MainActor public init(
        rows: [GridItem],
        alignment: Alignment = .center,
        spacing: Double? = nil,
        pinnedViews: PinnedScrollableViews = .init(),
        @ViewBuilder content: () -> Content
    ) {
        self.rows = rows
        self.alignment = alignment
        self.spacing = spacing
        self.content = content()
    }

    // MARK: - VNode Conversion

    /// Converts this LazyHGrid to a virtual DOM node.
    ///
    /// The LazyHGrid is rendered as a `div` element with CSS Grid styling:
    /// - `display: grid`
    /// - `grid-auto-flow: column` (items flow into columns)
    /// - `grid-template-rows: <row specs>` (based on the rows parameter)
    /// - `gap: <spacing>px` (if spacing is provided)
    /// - `justify-items` and `align-items` (based on alignment)
    ///
    /// The grid handles three types of row sizing:
    /// - `.fixed`: Creates a fixed-size row (e.g., `100px`)
    /// - `.flexible`: Creates a flexible row with min/max constraints (e.g., `minmax(50px, 1fr)`)
    /// - `.adaptive`: Creates auto-fitting rows (e.g., `repeat(auto-fit, minmax(80px, 1fr))`)
    ///
    /// Note: The children are not converted here. The RenderCoordinator
    /// will handle rendering the content by accessing the `content` property.
    ///
    /// - Returns: A VNode configured as a CSS Grid container with horizontal flow.
    @MainActor public func toVNode() -> VNode {
        var props: [String: VProperty] = [
            "display": .style(name: "display", value: "grid"),
            "grid-auto-flow": .style(name: "grid-auto-flow", value: "column")
        ]

        // Generate grid-template-rows from GridItem specs
        let templateRows = generateGridTemplateRows()
        props["grid-template-rows"] = .style(
            name: "grid-template-rows",
            value: templateRows
        )

        // Add gap spacing if provided
        if let spacing = spacing {
            props["gap"] = .style(name: "gap", value: "\(spacing)px")
        }

        // Add alignment using place-items (combines align-items and justify-items)
        props["place-items"] = .style(name: "place-items", value: alignment.cssValue)

        // Return element with empty children - the RenderCoordinator will populate them
        return VNode.element(
            "div",
            props: props,
            children: []
        )
    }

    // MARK: - Private Helpers

    /// Generate the CSS grid-template-rows value from the rows array.
    ///
    /// This method handles the conversion of GridItem definitions into a valid
    /// CSS grid template string, including special handling for adaptive rows.
    ///
    /// - Returns: A CSS grid-template-rows value.
    private func generateGridTemplateRows() -> String {
        var templates: [String] = []

        for row in rows {
            if row.isAdaptive {
                // Adaptive rows use repeat(auto-fit, ...)
                templates.append("repeat(auto-fit, \(row.toCSSTemplate()))")
            } else {
                templates.append(row.toCSSTemplate())
            }
        }

        return templates.joined(separator: " ")
    }
}
