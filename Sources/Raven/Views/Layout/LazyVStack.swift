import Foundation

/// A view that arranges its children in a vertical line, creating items only as needed.
///
/// `LazyVStack` is a lazy vertical stack that creates its child views on demand,
/// similar to `VStack` but with lazy loading semantics. It's ideal for displaying
/// large collections of items in a vertical layout where you want to defer view
/// creation until the views are needed.
///
/// ## Overview
///
/// Use `LazyVStack` when you have a large number of child views that you want to
/// arrange vertically, but don't want to create all the views up front. This is
/// particularly useful inside a `ScrollView` with many items.
///
/// ## Basic Usage
///
/// Create a simple lazy vertical stack:
///
/// ```swift
/// ScrollView {
///     LazyVStack {
///         ForEach(0..<1000) { index in
///             Text("Item \(index)")
///         }
///     }
/// }
/// ```
///
/// ## Alignment
///
/// Control horizontal alignment of children:
///
/// ```swift
/// LazyVStack(alignment: .leading) {
///     ForEach(items) { item in
///         Text(item.title)
///     }
/// }
/// ```
///
/// ## Spacing
///
/// Add consistent spacing between views:
///
/// ```swift
/// LazyVStack(spacing: 16) {
///     ForEach(items) { item in
///         ItemView(item: item)
///     }
/// }
/// ```
///
/// ## Pinned Views
///
/// Pin section headers and footers to the top/bottom of the scroll area:
///
/// ```swift
/// LazyVStack(pinnedViews: .sectionHeaders) {
///     Section(header: Text("Section 1")) {
///         ForEach(items) { item in
///             Text(item.name)
///         }
///     }
/// }
/// ```
///
/// ## Performance Optimization
///
/// For very large datasets, consider using the `.virtualized()` modifier for
/// viewport-based rendering optimization:
///
/// ```swift
/// ScrollView {
///     LazyVStack {
///         ForEach(0..<10000) { index in
///             ItemView(index: index)
///         }
///     }
///     .virtualized(estimatedItemHeight: 44)
/// }
/// ```
///
/// ## Differences from VStack
///
/// - **Lazy Loading**: Views are created on demand, not all at once
/// - **Large Collections**: Better for long lists with hundreds or thousands of items
/// - **Layout Effects**: Some layout features may behave differently due to lazy loading
///
/// ## See Also
///
/// - ``VStack``
/// - ``LazyHStack``
/// - ``LazyVGrid``
/// - ``List``
/// - ``ScrollView``
///
/// - Parameters:
///   - alignment: The horizontal alignment of child views. Defaults to `.center`.
///   - spacing: The vertical spacing between child views in pixels. Defaults to `nil` (no explicit spacing).
///   - pinnedViews: The kinds of child views to pin to the scroll area bounds. Defaults to empty.
///   - content: A view builder that creates the child views.
public struct LazyVStack<Content: View>: View, PrimitiveView, Sendable {
    public typealias Body = Never

    /// The horizontal alignment of child views
    let alignment: HorizontalAlignment

    /// The spacing between child views in pixels
    let spacing: Double?

    /// The kinds of child views to pin
    let pinnedViews: PinnedScrollableViews

    /// The child views
    let content: Content

    // MARK: - Initializers

    /// Creates a lazy vertical stack with optional alignment, spacing, and pinned views.
    ///
    /// - Parameters:
    ///   - alignment: The horizontal alignment of child views. Defaults to `.center`.
    ///   - spacing: The vertical spacing between child views in pixels. Defaults to `nil`.
    ///   - pinnedViews: The kinds of child views to pin to the scroll area bounds. Defaults to empty.
    ///   - content: A view builder that creates the child views.
    @MainActor public init(
        alignment: HorizontalAlignment = .center,
        spacing: Double? = nil,
        pinnedViews: PinnedScrollableViews = .init(),
        @ViewBuilder content: () -> Content
    ) {
        self.alignment = alignment
        self.spacing = spacing
        self.pinnedViews = pinnedViews
        self.content = content()
    }

    // MARK: - VNode Conversion

    /// Converts this LazyVStack to a virtual DOM node.
    ///
    /// The LazyVStack is rendered as a `div` element with flexbox styling:
    /// - `display: flex`
    /// - `flex-direction: column`
    /// - `align-items: <alignment>` (based on the alignment parameter)
    /// - `gap: <spacing>px` (if spacing is provided)
    /// - `class: raven-lazy-vstack` (for styling and identification)
    ///
    /// The rendering is similar to `VStack`, but with lazy semantics applied by
    /// the view hierarchy. The actual lazy loading behavior is handled by the
    /// `ForEach` view or virtualization modifiers that work with the layout.
    ///
    /// Note: The children are not converted here. The RenderCoordinator
    /// will handle rendering the content by accessing the `content` property,
    /// applying lazy loading as appropriate.
    ///
    /// - Returns: A VNode configured as a vertical flexbox container with lazy semantics.
    @MainActor public func toVNode() -> VNode {
        var props: [String: VProperty] = [
            "display": .style(name: "display", value: "flex"),
            "flex-direction": .style(name: "flex-direction", value: "column"),
            "align-items": .style(name: "align-items", value: alignment.cssValue),
            "class": .attribute(name: "class", value: "raven-lazy-vstack")
        ]

        // Add gap spacing if provided
        if let spacing = spacing {
            props["gap"] = .style(name: "gap", value: "\(spacing)px")
        }

        // Add data attribute for pinned views if set
        if !pinnedViews.isEmpty {
            var pinnedTypes: [String] = []
            if pinnedViews.contains(.sectionHeaders) {
                pinnedTypes.append("headers")
            }
            if pinnedViews.contains(.sectionFooters) {
                pinnedTypes.append("footers")
            }
            props["data-pinned-views"] = .attribute(
                name: "data-pinned-views",
                value: pinnedTypes.joined(separator: ",")
            )
        }

        // Return element with empty children - the RenderCoordinator will populate them
        return VNode.element(
            "div",
            props: props,
            children: []
        )
    }
}

// MARK: - Coordinator Renderable

extension LazyVStack: _CoordinatorRenderable {
    @MainActor public func _render(with context: any _RenderContext) -> VNode {
        var props: [String: VProperty] = [
            "display": .style(name: "display", value: "flex"),
            "flex-direction": .style(name: "flex-direction", value: "column"),
            "align-items": .style(name: "align-items", value: alignment.cssValue),
            "class": .attribute(name: "class", value: "raven-lazy-vstack")
        ]
        if let spacing = spacing {
            props["gap"] = .style(name: "gap", value: "\(spacing)px")
        }
        if !pinnedViews.isEmpty {
            var pinnedTypes: [String] = []
            if pinnedViews.contains(.sectionHeaders) {
                pinnedTypes.append("headers")
            }
            if pinnedViews.contains(.sectionFooters) {
                pinnedTypes.append("footers")
            }
            props["data-pinned-views"] = .attribute(
                name: "data-pinned-views",
                value: pinnedTypes.joined(separator: ",")
            )
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
