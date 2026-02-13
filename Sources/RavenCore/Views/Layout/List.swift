import Foundation

/// A container that presents rows of data arranged in a single column.
///
/// `List` is a scrollable container view that presents a collection of views in a
/// vertical list. It's a primitive view that renders directly to an HTML element
/// with appropriate list semantics and ARIA attributes for accessibility.
///
/// Example:
/// ```swift
/// List {
///     Text("Item 1")
///     Text("Item 2")
///     Text("Item 3")
/// }
///
/// // With ForEach for dynamic content
/// List {
///     ForEach(items) { item in
///         Text(item.name)
///     }
/// }
///
/// // For large datasets, use virtualization for better performance
/// List(0..<10000) { index in
///     Text("Item \(index)")
/// }
/// .virtualized(estimatedItemHeight: 44)
/// ```
///
/// The List view integrates seamlessly with ForEach for rendering dynamic collections
/// and provides proper accessibility attributes for screen readers and assistive technologies.
///
/// ## Performance Optimization
///
/// For lists with thousands of items, use the `.virtualized()` modifier to enable
/// virtual scrolling. This renders only visible items, dramatically improving performance:
///
/// ```swift
/// List(largeDataset) { item in
///     ItemView(item: item)
/// }
/// .virtualized()
/// ```
public struct List<Content: View>: View, PrimitiveView, Sendable {
    public typealias Body = Never

    /// The child views to display in the list
    let content: Content

    @Environment(\.listStyle) private var listStyle

    // MARK: - Initializers

    /// Creates a list with the given content.
    ///
    /// - Parameter content: A view builder that creates the list items.
    ///
    /// Example:
    /// ```swift
    /// List {
    ///     Text("First item")
    ///     Text("Second item")
    ///     Text("Third item")
    /// }
    /// ```
    @MainActor public init(
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
    }

    // MARK: - VNode Conversion

    /// Converts this List to a virtual DOM node.
    ///
    /// The List is rendered as a `div` element with:
    /// - `role="list"` attribute for accessibility
    /// - `overflow-y: auto` for vertical scrolling
    /// - `display: flex` and `flex-direction: column` for layout
    ///
    /// ARIA attributes ensure proper accessibility for screen readers and
    /// assistive technologies. The list container uses semantic HTML roles
    /// to communicate its purpose to accessibility tools.
    ///
    /// Note: The children are not converted here. The RenderCoordinator
    /// will handle rendering the content by accessing the `content` property.
    ///
    /// - Returns: A VNode configured as a list container with ARIA attributes.
    @MainActor public func toVNode() -> VNode {
        let styleVariant = _resolvedStyleVariant()
        let props: [String: VProperty] = [
            // ARIA role for accessibility (WCAG 2.1 requirement)
            "role": .attribute(name: "role", value: "list"),
            "class": .attribute(name: "class", value: "raven-list"),
            "data-list-style": .attribute(name: "data-list-style", value: styleVariant.rawValue),

            // Layout styles
            "display": .style(name: "display", value: "flex"),
            "flex-direction": .style(name: "flex-direction", value: "column"),
            "gap": .style(name: "gap", value: styleVariant.itemGap),

            // Scrolling behavior
            "overflow-y": .style(name: "overflow-y", value: "auto"),

            // Default styling
            "width": .style(name: "width", value: "100%"),
            "list-style": .style(name: "list-style", value: "none"),
            "padding": .style(name: "padding", value: styleVariant.padding),
            "margin": .style(name: "margin", value: styleVariant.margin),
            "background": .style(name: "background", value: styleVariant.background),
            "border": .style(name: "border", value: styleVariant.border),
            "border-radius": .style(name: "border-radius", value: styleVariant.cornerRadius)
        ]

        // Additional ARIA attributes can be set via accessibility modifiers:
        // - aria-label: Descriptive label for the list
        // - aria-describedby: Reference to element describing the list
        // List items should have role="listitem" and optionally:
        // - aria-posinset: Position in the set (1-based index)
        // - aria-setsize: Total number of items in the set

        // Return element with empty children - the RenderCoordinator will populate them
        return VNode.element(
            "div",
            props: props,
            children: []
        )
    }
}

// MARK: - Coordinator Renderable

extension List: _CoordinatorRenderable {
    @MainActor public func _render(with context: any _RenderContext) -> VNode {
        let wrapperNode = toVNode()
        let contentNode = context.renderChild(content)

        let children: [VNode]
        if case .fragment = contentNode.type {
            children = contentNode.children
        } else {
            children = [contentNode]
        }

        return VNode(
            id: wrapperNode.id,
            type: wrapperNode.type,
            props: wrapperNode.props,
            children: children,
            key: wrapperNode.key
        )
    }
}

// MARK: - Style Resolution

private extension List {
    enum _ListStyleVariant: String {
        case automatic
        case `default`
        case plain
        case grouped
        case inset
        case insetGrouped
        case sidebar

        var itemGap: String {
            switch self {
            case .grouped, .insetGrouped:
                return "10px"
            case .sidebar:
                return "4px"
            case .automatic, .default, .plain, .inset:
                return "6px"
            }
        }

        var padding: String {
            switch self {
            case .plain:
                return "0"
            case .inset:
                return "0 12px"
            case .insetGrouped:
                return "8px 12px"
            case .sidebar:
                return "6px 8px"
            case .automatic, .default, .grouped:
                return "8px"
            }
        }

        var margin: String {
            switch self {
            case .plain:
                return "0"
            case .sidebar:
                return "4px 0"
            case .automatic, .default, .grouped, .inset, .insetGrouped:
                return "0"
            }
        }

        var background: String {
            switch self {
            case .plain:
                return "transparent"
            case .grouped:
                return "var(--raven-list-grouped-bg, #f5f5f7)"
            case .insetGrouped:
                return "var(--raven-list-inset-grouped-bg, #f2f2f7)"
            case .sidebar:
                return "var(--raven-list-sidebar-bg, #f7f7fa)"
            case .automatic, .default, .inset:
                return "transparent"
            }
        }

        var border: String {
            switch self {
            case .grouped:
                return "1px solid rgba(0, 0, 0, 0.08)"
            case .insetGrouped:
                return "1px solid rgba(0, 0, 0, 0.08)"
            case .sidebar:
                return "1px solid rgba(0, 0, 0, 0.06)"
            case .automatic, .default, .plain, .inset:
                return "none"
            }
        }

        var cornerRadius: String {
            switch self {
            case .grouped, .insetGrouped:
                return "12px"
            case .sidebar:
                return "10px"
            case .automatic, .default, .plain, .inset:
                return "0"
            }
        }
    }

    @MainActor func _resolvedStyleVariant() -> _ListStyleVariant {
        if listStyle is InsetGroupedListStyle { return .insetGrouped }
        if listStyle is GroupedListStyle { return .grouped }
        if listStyle is InsetListStyle { return .inset }
        if listStyle is PlainListStyle { return .plain }
        if listStyle is SidebarListStyle { return .sidebar }
        if listStyle is DefaultListStyle { return .default }
        return .automatic
    }
}

// MARK: - Convenience Initializers

extension List {
    /// Creates a list that computes its rows on demand from an underlying collection.
    ///
    /// This convenience initializer creates a List containing a ForEach, which is
    /// a common pattern for displaying dynamic collections.
    ///
    /// - Parameters:
    ///   - data: The collection of data to iterate over.
    ///   - id: Key path to the property that identifies each element.
    ///   - content: A view builder that creates the view for each element.
    ///
    /// Example:
    /// ```swift
    /// struct Item: Sendable {
    ///     let id: Int
    ///     let name: String
    /// }
    ///
    /// List(items, id: \.id) { item in
    ///     Text(item.name)
    /// }
    /// ```
    @MainActor public init<Data, ID, RowContent>(
        _ data: Data,
        id: KeyPath<Data.Element, ID>,
        @ViewBuilder content: @escaping @Sendable @MainActor (Data.Element) -> RowContent
    ) where Content == ForEach<Data, ID, RowContent>,
            Data: RandomAccessCollection,
            Data: Sendable,
            Data.Element: Sendable,
            ID: Hashable,
            ID: Sendable,
            RowContent: View {
        self.content = ForEach(data, id: id, content: content)
    }

    /// Creates a list that identifies its rows based on the `id` property of the underlying data.
    ///
    /// This initializer is used when your data elements conform to `Identifiable`.
    ///
    /// - Parameters:
    ///   - data: The collection of identifiable data.
    ///   - content: A view builder that creates the view for each element.
    ///
    /// Example:
    /// ```swift
    /// struct Item: Identifiable, Sendable {
    ///     let id: UUID
    ///     let name: String
    /// }
    ///
    /// List(items) { item in
    ///     Text(item.name)
    /// }
    /// ```
    @MainActor public init<Data, RowContent>(
        _ data: Data,
        @ViewBuilder content: @escaping @Sendable @MainActor (Data.Element) -> RowContent
    ) where Content == ForEach<Data, Data.Element.ID, RowContent>,
            Data: RandomAccessCollection,
            Data.Element: Identifiable & Sendable,
            Data: Sendable,
            RowContent: View {
        self.content = ForEach(data, content: content)
    }

    /// Creates a list that computes views on demand over a range of integers.
    ///
    /// - Parameters:
    ///   - data: A range of integers.
    ///   - content: A view builder that creates the view for each integer.
    ///
    /// Example:
    /// ```swift
    /// List(0..<10) { index in
    ///     Text("Row \(index)")
    /// }
    /// ```
    @MainActor public init<RowContent>(
        _ data: Range<Int>,
        @ViewBuilder content: @escaping @Sendable @MainActor (Int) -> RowContent
    ) where Content == ForEach<Range<Int>, Int, RowContent>,
            RowContent: View {
        self.content = ForEach(data, content: content)
    }

    /// Creates a list that computes views on demand over a closed range of integers.
    ///
    /// - Parameters:
    ///   - data: A closed range of integers.
    ///   - content: A view builder that creates the view for each integer.
    ///
    /// Example:
    /// ```swift
    /// List(1...3) { index in
    ///     Text("Row \(index)")
    /// }
    /// ```
    @MainActor public init<RowContent>(
        _ data: ClosedRange<Int>,
        @ViewBuilder content: @escaping @Sendable @MainActor (Int) -> RowContent
    ) where Content == ForEach<ClosedRange<Int>, Int, RowContent>,
            RowContent: View {
        self.content = ForEach(data, content: content)
    }
}
