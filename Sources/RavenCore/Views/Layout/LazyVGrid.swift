import Foundation

/// A container view that arranges its child views in a grid that grows vertically,
/// creating items only as needed.
///
/// `LazyVGrid` is a lazy grid container that creates its child views on demand,
/// arranging them in a vertical scrolling grid with a specified number of columns.
/// It's ideal for displaying large collections of items in a multi-column layout.
///
/// The grid creates rows automatically as needed to accommodate all items, with
/// each row containing the number of columns specified by the `columns` parameter.
///
/// Example:
/// ```swift
/// LazyVGrid(
///     columns: [
///         GridItem(.flexible()),
///         GridItem(.flexible()),
///         GridItem(.flexible())
///     ],
///     spacing: 16
/// ) {
///     ForEach(photos) { photo in
///         PhotoView(photo: photo)
///     }
/// }
///
/// // For large datasets, use virtualization
/// LazyVGrid(columns: columns) {
///     ForEach(0..<10000) { index in
///         CellView(index: index)
///     }
/// }
/// .virtualized(estimatedItemHeight: 100)
/// ```
///
/// The grid renders as a CSS Grid layout with `auto-flow: row`, meaning items
/// flow into rows automatically.
///
/// ## Performance Optimization
///
/// For grids with thousands of items, use the `.virtualized()` modifier to enable
/// virtual scrolling and significantly improve rendering performance.
///
/// - Parameters:
///   - columns: An array of `GridItem` that describe the columns of the grid.
///   - alignment: The alignment of items within their grid cells. Defaults to `.center`.
///   - spacing: The spacing between rows and columns. Defaults to `nil` (no explicit spacing).
///   - pinnedViews: The kinds of child views to pin. Currently unused but included for API compatibility.
///   - content: A view builder that creates the child views.
public struct LazyVGrid<Content: View>: View, PrimitiveView, Sendable {
    public typealias Body = Never

    /// The column definitions for this grid
    let columns: [GridItem]

    /// The alignment of items within their grid cells
    let alignment: Alignment

    /// The spacing between rows and columns
    let spacing: Double?

    /// The child views
    let content: Content

    // MARK: - Initializers

    /// Creates a lazy vertical grid with the specified columns, alignment, and spacing.
    ///
    /// - Parameters:
    ///   - columns: An array of `GridItem` that describe the columns of the grid.
    ///   - alignment: The alignment of items within their grid cells. Defaults to `.center`.
    ///   - spacing: The spacing between rows and columns in pixels. Defaults to `nil`.
    ///   - pinnedViews: The kinds of child views to pin. Currently unused but included for API compatibility.
    ///   - content: A view builder that creates the child views.
    @MainActor public init(
        columns: [GridItem],
        alignment: Alignment = .center,
        spacing: Double? = nil,
        pinnedViews: PinnedScrollableViews = .init(),
        @ViewBuilder content: () -> Content
    ) {
        self.columns = columns
        self.alignment = alignment
        self.spacing = spacing
        self.content = content()
    }

    // MARK: - VNode Conversion

    /// Converts this LazyVGrid to a virtual DOM node.
    ///
    /// The LazyVGrid is rendered as a `div` element with CSS Grid styling:
    /// - `display: grid`
    /// - `grid-auto-flow: row` (items flow into rows)
    /// - `grid-template-columns: <column specs>` (based on the columns parameter)
    /// - `gap: <spacing>px` (if spacing is provided)
    /// - `justify-items` and `align-items` (based on alignment)
    ///
    /// The grid handles three types of column sizing:
    /// - `.fixed`: Creates a fixed-size column (e.g., `100px`)
    /// - `.flexible`: Creates a flexible column with min/max constraints (e.g., `minmax(50px, 1fr)`)
    /// - `.adaptive`: Creates auto-fitting columns (e.g., `repeat(auto-fit, minmax(80px, 1fr))`)
    ///
    /// Note: The children are not converted here. The RenderCoordinator
    /// will handle rendering the content by accessing the `content` property.
    ///
    /// - Returns: A VNode configured as a CSS Grid container with vertical flow.
    @MainActor public func toVNode() -> VNode {
        var props: [String: VProperty] = [
            "display": .style(name: "display", value: "grid"),
            "grid-auto-flow": .style(name: "grid-auto-flow", value: "row")
        ]

        // Generate grid-template-columns from GridItem specs
        let templateColumns = generateGridTemplateColumns()
        props["grid-template-columns"] = .style(
            name: "grid-template-columns",
            value: templateColumns
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

    /// Generate the CSS grid-template-columns value from the columns array.
    ///
    /// This method handles the conversion of GridItem definitions into a valid
    /// CSS grid template string, including special handling for adaptive columns.
    ///
    /// - Returns: A CSS grid-template-columns value.
    private func generateGridTemplateColumns() -> String {
        var templates: [String] = []

        for column in columns {
            if column.isAdaptive {
                // Adaptive columns use repeat(auto-fit, ...)
                templates.append("repeat(auto-fit, \(column.toCSSTemplate()))")
            } else {
                templates.append(column.toCSSTemplate())
            }
        }

        return templates.joined(separator: " ")
    }
}

/// Specifies which views to pin in a scrollable view.
///
/// This type is included for SwiftUI API compatibility but is currently unused
/// in Raven's implementation.
public struct PinnedScrollableViews: OptionSet, Sendable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    /// Pin section headers to the top of the scrollable area.
    public static let sectionHeaders = PinnedScrollableViews(rawValue: 1 << 0)

    /// Pin section footers to the bottom of the scrollable area.
    public static let sectionFooters = PinnedScrollableViews(rawValue: 1 << 1)
}

// MARK: - Coordinator Renderable

extension LazyVGrid: _CoordinatorRenderable {
    @MainActor public func _render(with context: any _RenderContext) -> VNode {
        var props: [String: VProperty] = [
            "display": .style(name: "display", value: "grid"),
            "grid-auto-flow": .style(name: "grid-auto-flow", value: "row")
        ]
        let templateColumns = generateGridTemplateColumns()
        props["grid-template-columns"] = .style(
            name: "grid-template-columns",
            value: templateColumns
        )
        if let spacing = spacing {
            props["gap"] = .style(name: "gap", value: "\(spacing)px")
        }
        props["place-items"] = .style(name: "place-items", value: alignment.cssValue)

        let contentNode = context.renderChild(content)
        let children: [VNode]
        if case .fragment = contentNode.type {
            children = contentNode.children
        } else {
            children = [contentNode]
        }
        return VNode.element("div", props: props, children: children)
    }
}
