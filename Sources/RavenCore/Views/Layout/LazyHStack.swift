import Foundation

/// A view that arranges its children in a horizontal line, creating items only as needed.
///
/// `LazyHStack` is a lazy horizontal stack that creates its child views on demand,
/// similar to `HStack` but with lazy loading semantics.
///
/// - Parameters:
///   - alignment: The vertical alignment of child views. Defaults to `.center`.
///   - spacing: The horizontal spacing between child views in pixels. Defaults to `nil`.
///   - pinnedViews: The kinds of child views to pin to scroll bounds. Defaults to empty.
///   - content: A view builder that creates the child views.
public struct LazyHStack<Content: View>: View, PrimitiveView, Sendable {
    public typealias Body = Never

    /// The vertical alignment of child views.
    let alignment: VerticalAlignment

    /// The spacing between child views in pixels.
    let spacing: Double?

    /// The kinds of child views to pin.
    let pinnedViews: PinnedScrollableViews

    /// The child views.
    let content: Content

    /// Creates a lazy horizontal stack with optional alignment, spacing, and pinned views.
    @MainActor public init(
        alignment: VerticalAlignment = .center,
        spacing: Double? = nil,
        pinnedViews: PinnedScrollableViews = .init(),
        @ViewBuilder content: () -> Content
    ) {
        self.alignment = alignment
        self.spacing = spacing
        self.pinnedViews = pinnedViews
        self.content = content()
    }

    @MainActor public func toVNode() -> VNode {
        var props: [String: VProperty] = [
            "display": .style(name: "display", value: "flex"),
            "flex-direction": .style(name: "flex-direction", value: "row"),
            "align-items": .style(name: "align-items", value: alignment.cssValue),
            "class": .attribute(name: "class", value: "raven-lazy-hstack")
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

        return VNode.element("div", props: props, children: [])
    }
}

// MARK: - Coordinator Renderable

extension LazyHStack: _CoordinatorRenderable {
    @MainActor public func _render(with context: any _RenderContext) -> VNode {
        var props: [String: VProperty] = [
            "display": .style(name: "display", value: "flex"),
            "flex-direction": .style(name: "flex-direction", value: "row"),
            "align-items": .style(name: "align-items", value: alignment.cssValue),
            "class": .attribute(name: "class", value: "raven-lazy-hstack")
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
