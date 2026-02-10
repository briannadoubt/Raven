import Foundation

/// A container view that arranges its child views in a 2D grid layout.
///
/// `Grid` is a non-lazy grid container that arranges views in a 2D grid, similar
/// to SwiftUI's Grid view. Unlike `LazyVGrid`, Grid is not lazy—it creates all views
/// immediately. Grid rows are defined using `GridRow` containers, and individual cells
/// can be configured with modifiers like `gridCellColumns(_:)`, `gridCellAnchor(_:)`,
/// and `gridColumnAlignment(_:)`.
///
/// The grid renders as a CSS Grid layout with automatic column width calculation based
/// on content. Each `GridRow` contributes to the grid's structure, and cells can span
/// multiple columns or be aligned within their cells.
///
/// ## Overview
///
/// Use `Grid` to create structured 2D layouts with explicit rows and columns. It's
/// ideal for forms, data tables, and complex layouts where content needs to be
/// organized in a grid format.
///
/// ## Basic Usage
///
/// Create a simple 2-column grid with rows:
///
/// ```swift
/// Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 12) {
///     GridRow {
///         Text("Name:")
///         TextField("Enter name", text: $name)
///     }
///     GridRow {
///         Text("Email:")
///         TextField("Enter email", text: $email)
///     }
///     GridRow {
///         Text("Phone:")
///         TextField("Enter phone", text: $phone)
///     }
/// }
/// ```
///
/// ## Alignment
///
/// Control alignment both horizontally and vertically:
///
/// ```swift
/// Grid(alignment: .topLeading) {
///     GridRow {
///         Text("Header 1")
///         Text("Header 2")
///     }
///     GridRow {
///         VStack(alignment: .leading) {
///             Text("Row 1, Item 1")
///             Text("Subtitle")
///         }
///         Text("Row 1, Item 2")
///     }
/// }
/// ```
///
/// ## Spacing
///
/// Control spacing between rows and columns:
///
/// ```swift
/// Grid(
///     alignment: .center,
///     horizontalSpacing: 16,
///     verticalSpacing: 8
/// ) {
///     GridRow {
///         Text("A")
///         Text("B")
///     }
///     GridRow {
///         Text("C")
///         Text("D")
///     }
/// }
/// ```
///
/// ## Multi-Column Cells
///
/// Make cells span multiple columns:
///
/// ```swift
/// Grid {
///     GridRow {
///         Text("Header")
///             .gridCellColumns(2)
///     }
///     GridRow {
///         Text("Left")
///         Text("Right")
///     }
/// }
/// ```
///
/// ## Column Alignment
///
/// Control alignment within individual columns:
///
/// ```swift
/// Grid {
///     GridRow {
///         Text("Numbers")
///             .gridColumnAlignment(.trailing)
///         Text("Labels")
///             .gridColumnAlignment(.leading)
///     }
///     GridRow {
///         Text("123")
///             .gridColumnAlignment(.trailing)
///         Text("Example")
///             .gridColumnAlignment(.leading)
///     }
/// }
/// ```
///
/// ## See Also
///
/// - ``GridRow``
/// - ``LazyVGrid``
/// - ``LazyHGrid``
///
/// - Parameters:
///   - alignment: The alignment of items within their grid cells. Defaults to `.center`.
///   - horizontalSpacing: The horizontal spacing between grid columns in pixels. Defaults to `nil`.
///   - verticalSpacing: The vertical spacing between grid rows in pixels. Defaults to `nil`.
///   - content: A view builder that creates the grid rows.
public struct Grid<Content: View>: View, PrimitiveView, Sendable {
    public typealias Body = Never

    /// The alignment of items within their grid cells
    let alignment: Alignment

    /// The horizontal spacing between grid columns
    let horizontalSpacing: CGFloat?

    /// The vertical spacing between grid rows
    let verticalSpacing: CGFloat?

    /// The child views (grid rows)
    let content: Content

    // MARK: - Initializers

    /// Creates a grid with optional alignment and spacing.
    ///
    /// - Parameters:
    ///   - alignment: The alignment of items within their grid cells. Defaults to `.center`.
    ///   - horizontalSpacing: The horizontal spacing between grid columns in pixels. Defaults to `nil`.
    ///   - verticalSpacing: The vertical spacing between grid rows in pixels. Defaults to `nil`.
    ///   - content: A view builder that creates the grid rows.
    @MainActor public init(
        alignment: Alignment = .center,
        horizontalSpacing: CGFloat? = nil,
        verticalSpacing: CGFloat? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.alignment = alignment
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
        self.content = content()
    }

    // MARK: - VNode Conversion

    /// Converts this Grid to a virtual DOM node.
    ///
    /// The Grid is rendered as a `div` element with CSS Grid styling:
    /// - `display: grid`
    /// - `grid-auto-columns: max-content` (auto-fit column widths to content)
    /// - `gap: <horizontalSpacing>px <verticalSpacing>px` (if spacing is provided)
    /// - `place-items: <alignment>` (based on the alignment parameter)
    ///
    /// Note: The children are not converted here. The RenderCoordinator
    /// will handle rendering the content by accessing the `content` property.
    ///
    /// - Returns: A VNode configured as a CSS Grid container.
    @MainActor public func toVNode() -> VNode {
        var props: [String: VProperty] = [
            "display": .style(name: "display", value: "grid"),
            "grid-auto-flow": .style(name: "grid-auto-flow", value: "row"),
            "grid-auto-columns": .style(name: "grid-auto-columns", value: "max-content")
        ]

        // Add gap spacing if provided
        if let horizontalSpacing = horizontalSpacing, let verticalSpacing = verticalSpacing {
            props["gap"] = .style(name: "gap", value: "\(verticalSpacing)px \(horizontalSpacing)px")
        } else if let horizontalSpacing = horizontalSpacing {
            props["column-gap"] = .style(name: "column-gap", value: "\(horizontalSpacing)px")
        } else if let verticalSpacing = verticalSpacing {
            props["row-gap"] = .style(name: "row-gap", value: "\(verticalSpacing)px")
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
}

/// A row within a `Grid` that organizes views horizontally.
///
/// `GridRow` is used as a direct child of `Grid` to define a row of items in the grid.
/// Each cell within a `GridRow` occupies one column in the grid, and `GridRow` contributes
/// to the structure by defining how many cells are in each row.
///
/// Cells within a row can be configured with modifiers to:
/// - Span multiple columns with `gridCellColumns(_:)`
/// - Set a custom anchor point with `gridCellAnchor(_:)`
/// - Control horizontal alignment with `gridColumnAlignment(_:)`
///
/// ## Overview
///
/// Use `GridRow` as the direct child of `Grid` to define each row's content.
/// Each view in the `GridRow` becomes a cell aligned within its column.
///
/// ## Basic Usage
///
/// Create rows with different numbers of cells:
///
/// ```swift
/// Grid {
///     GridRow {
///         Text("Name:")
///         TextField("John", text: $name)
///     }
///     GridRow {
///         Text("Email:")
///         TextField("john@example.com", text: $email)
///     }
/// }
/// ```
///
/// ## Row Alignment
///
/// Control vertical alignment within a specific row:
///
/// ```swift
/// Grid {
///     GridRow(alignment: .top) {
///         VStack {
///             Text("Large")
///             Text("Content")
///         }
///         Text("Short")
///     }
///     GridRow(alignment: .center) {
///         Text("Centered")
///         Image("icon")
///     }
/// }
/// ```
///
/// ## Multi-Column Cells
///
/// Make a cell span multiple columns:
///
/// ```swift
/// Grid {
///     GridRow {
///         Text("Header")
///             .gridCellColumns(2)
///     }
///     GridRow {
///         Text("Col 1")
///         Text("Col 2")
///     }
/// }
/// ```
///
/// ## See Also
///
/// - ``Grid``
/// - ``View/gridCellColumns(_:)``
/// - ``View/gridCellAnchor(_:)``
/// - ``View/gridColumnAlignment(_:)``
///
/// - Parameters:
///   - alignment: The vertical alignment of items within this row. Defaults to `nil` (inherits from Grid).
///   - content: A view builder that creates the cells in this row.
public struct GridRow<Content: View>: View, PrimitiveView, Sendable {
    public typealias Body = Never

    /// The vertical alignment of items within this row
    let alignment: VerticalAlignment?

    /// The child views (cells)
    let content: Content

    // MARK: - Initializers

    /// Creates a grid row with optional vertical alignment.
    ///
    /// - Parameters:
    ///   - alignment: The vertical alignment of items within this row. Defaults to `nil`.
    ///   - content: A view builder that creates the cells in this row.
    @MainActor public init(
        alignment: VerticalAlignment? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.alignment = alignment
        self.content = content()
    }

    // MARK: - VNode Conversion

    /// Converts this GridRow to a virtual DOM node.
    ///
    /// The GridRow is rendered as a `div` element that serves as a row container.
    /// It uses `display: contents` to participate in the parent Grid's layout without
    /// adding extra hierarchy, allowing its children to become direct grid items.
    ///
    /// If a vertical alignment is specified, it's applied to the row's children.
    ///
    /// Note: The children are not converted here. The RenderCoordinator
    /// will handle rendering the content by accessing the `content` property.
    ///
    /// - Returns: A VNode configured as a grid row container.
    @MainActor public func toVNode() -> VNode {
        var props: [String: VProperty] = [
            "display": .style(name: "display", value: "contents")
        ]

        // Add alignment if specified
        if let alignment = alignment {
            props["align-items"] = .style(name: "align-items", value: alignment.cssValue)
        }

        // Return element with empty children - the RenderCoordinator will populate them
        return VNode.element(
            "div",
            props: props,
            children: []
        )
    }
}

// MARK: - Grid Cell Modifiers

extension View {
    /// Makes a cell span multiple columns in a grid.
    ///
    /// Use this modifier to make a cell in a `GridRow` occupy multiple columns.
    /// This is useful for headers, dividers, or other content that should span
    /// the width of multiple columns.
    ///
    /// - Parameter count: The number of columns this cell should span. Must be at least 1.
    /// - Returns: A view that spans the specified number of columns.
    ///
    /// Example:
    /// ```swift
    /// Grid {
    ///     GridRow {
    ///         Text("Header")
    ///             .gridCellColumns(2)
    ///     }
    ///     GridRow {
    ///         Text("Column 1")
    ///         Text("Column 2")
    ///     }
    /// }
    /// ```
    @MainActor public func gridCellColumns(_ count: Int) -> some View {
        _GridCellColumnsView(columnCount: count, content: self)
    }

    /// Sets the anchor point for a cell in a grid.
    ///
    /// Use this modifier to specify how content within a grid cell should be
    /// positioned relative to the cell's bounds. The anchor point is expressed
    /// as a unit point from (0, 0) at the top-left to (1, 1) at the bottom-right.
    ///
    /// - Parameter anchor: The anchor point for the cell. Defaults to `.center`.
    /// - Returns: A view with the specified anchor point.
    ///
    /// Example:
    /// ```swift
    /// Grid {
    ///     GridRow {
    ///         Text("Top-left")
    ///             .gridCellAnchor(.topLeading)
    ///         Text("Bottom-right")
    ///             .gridCellAnchor(.bottomTrailing)
    ///     }
    /// }
    /// ```
    @MainActor public func gridCellAnchor(_ anchor: UnitPoint) -> some View {
        _GridCellAnchorView(anchor: anchor, content: self)
    }

    /// Sets the horizontal alignment for a specific column in a grid.
    ///
    /// Use this modifier to control how content within a specific grid column
    /// is aligned horizontally. This alignment applies to all cells in that column.
    ///
    /// - Parameter alignment: The horizontal alignment for the column.
    /// - Returns: A view with the specified column alignment.
    ///
    /// Example:
    /// ```swift
    /// Grid {
    ///     GridRow {
    ///         Text("100")
    ///             .gridColumnAlignment(.trailing)
    ///         Text("Label")
    ///             .gridColumnAlignment(.leading)
    ///     }
    ///     GridRow {
    ///         Text("200")
    ///             .gridColumnAlignment(.trailing)
    ///         Text("Another")
    ///             .gridColumnAlignment(.leading)
    ///     }
    /// }
    /// ```
    @MainActor public func gridColumnAlignment(_ alignment: HorizontalAlignment) -> some View {
        _GridColumnAlignmentView(alignment: alignment, content: self)
    }
}

// MARK: - Wrapper Views for Grid Cell Modifiers

/// Wrapper view that applies grid cell column spanning
struct _GridCellColumnsView<Content: View>: View, PrimitiveView {
    let columnCount: Int
    let content: Content

    public typealias Body = Never

    @MainActor public func toVNode() -> VNode {
        let props: [String: VProperty] = [
            "grid-column": .style(name: "grid-column", value: "span \(columnCount)")
        ]

        return VNode.element(
            "div",
            props: props,
            children: []
        )
    }
}

/// Wrapper view that applies grid cell anchor positioning
struct _GridCellAnchorView<Content: View>: View, PrimitiveView {
    let anchor: UnitPoint
    let content: Content

    public typealias Body = Never

    @MainActor public func toVNode() -> VNode {
        // Convert UnitPoint to CSS alignment
        // UnitPoint (0, 0) is top-left, (1, 1) is bottom-right
        let horizontalAlignment: String
        if anchor.x < 0.33 {
            horizontalAlignment = "start"
        } else if anchor.x > 0.66 {
            horizontalAlignment = "end"
        } else {
            horizontalAlignment = "center"
        }

        let verticalAlignment: String
        if anchor.y < 0.33 {
            verticalAlignment = "start"
        } else if anchor.y > 0.66 {
            verticalAlignment = "end"
        } else {
            verticalAlignment = "center"
        }

        let props: [String: VProperty] = [
            "justify-self": .style(name: "justify-self", value: horizontalAlignment),
            "align-self": .style(name: "align-self", value: verticalAlignment)
        ]

        return VNode.element(
            "div",
            props: props,
            children: []
        )
    }
}

/// Wrapper view that applies grid column alignment
struct _GridColumnAlignmentView<Content: View>: View, PrimitiveView {
    let alignment: HorizontalAlignment
    let content: Content

    public typealias Body = Never

    @MainActor public func toVNode() -> VNode {
        let cssValue: String
        switch alignment {
        case .leading:
            cssValue = "start"
        case .center:
            cssValue = "center"
        case .trailing:
            cssValue = "end"
        }

        let props: [String: VProperty] = [
            "justify-self": .style(name: "justify-self", value: cssValue)
        ]

        return VNode.element(
            "div",
            props: props,
            children: []
        )
    }
}

// MARK: - Coordinator Renderable Conformances

extension Grid: _CoordinatorRenderable {
    @MainActor public func _render(with context: any _RenderContext) -> VNode {
        var props: [String: VProperty] = [
            "display": .style(name: "display", value: "grid"),
            "grid-auto-flow": .style(name: "grid-auto-flow", value: "row"),
            "grid-auto-columns": .style(name: "grid-auto-columns", value: "max-content")
        ]
        if let horizontalSpacing = horizontalSpacing, let verticalSpacing = verticalSpacing {
            props["gap"] = .style(name: "gap", value: "\(verticalSpacing)px \(horizontalSpacing)px")
        } else if let horizontalSpacing = horizontalSpacing {
            props["column-gap"] = .style(name: "column-gap", value: "\(horizontalSpacing)px")
        } else if let verticalSpacing = verticalSpacing {
            props["row-gap"] = .style(name: "row-gap", value: "\(verticalSpacing)px")
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

extension GridRow: _CoordinatorRenderable {
    @MainActor public func _render(with context: any _RenderContext) -> VNode {
        var props: [String: VProperty] = [
            "display": .style(name: "display", value: "contents")
        ]
        if let alignment = alignment {
            props["align-items"] = .style(name: "align-items", value: alignment.cssValue)
        }

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

extension _GridCellColumnsView: _CoordinatorRenderable {
    @MainActor public func _render(with context: any _RenderContext) -> VNode {
        let props: [String: VProperty] = [
            "grid-column": .style(name: "grid-column", value: "span \(columnCount)")
        ]
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

extension _GridCellAnchorView: _CoordinatorRenderable {
    @MainActor public func _render(with context: any _RenderContext) -> VNode {
        let horizontalAlignment: String
        if anchor.x < 0.33 {
            horizontalAlignment = "start"
        } else if anchor.x > 0.66 {
            horizontalAlignment = "end"
        } else {
            horizontalAlignment = "center"
        }
        let verticalAlignment: String
        if anchor.y < 0.33 {
            verticalAlignment = "start"
        } else if anchor.y > 0.66 {
            verticalAlignment = "end"
        } else {
            verticalAlignment = "center"
        }
        let props: [String: VProperty] = [
            "justify-self": .style(name: "justify-self", value: horizontalAlignment),
            "align-self": .style(name: "align-self", value: verticalAlignment)
        ]
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

extension _GridColumnAlignmentView: _CoordinatorRenderable {
    @MainActor public func _render(with context: any _RenderContext) -> VNode {
        let cssValue: String
        switch alignment {
        case .leading:
            cssValue = "start"
        case .center:
            cssValue = "center"
        case .trailing:
            cssValue = "end"
        }
        let props: [String: VProperty] = [
            "justify-self": .style(name: "justify-self", value: cssValue)
        ]
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
