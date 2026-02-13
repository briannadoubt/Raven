import Foundation

/// Placement options for `NavigationBarItem`.
public enum NavigationBarItemPlacement: Sendable, Hashable {
    case leading
    case trailing
}

/// A type representing an item in the navigation bar.
///
/// This mirrors SwiftUI's `NavigationBarItem` concept and maps to Raven's
/// navigation toolbar placement model.
public struct NavigationBarItem<Content: View>: Sendable {
    public let placement: NavigationBarItemPlacement
    public let content: Content

    @MainActor
    public init(
        placement: NavigationBarItemPlacement,
        @ViewBuilder content: () -> Content
    ) {
        self.placement = placement
        self.content = content()
    }
}

@MainActor
private struct _NavigationBarItemsModifier<Content: View>: View, PrimitiveView, _CoordinatorRenderable, Sendable {
    typealias Body = Never

    let content: Content
    let leading: AnyView?
    let trailing: AnyView?

    @MainActor
    func toVNode() -> VNode {
        VNode.text("")
    }

    @MainActor
    func _render(with context: any _RenderContext) -> VNode {
        if let controller = NavigationStackController._current {
            if let leading {
                let renderedLeading = context.renderChild(leading)
                controller.toolbarItems.append(
                    ToolbarItemInfo(
                        placement: .navigationBarLeading,
                        node: renderedLeading
                    )
                )
            }

            if let trailing {
                let renderedTrailing = context.renderChild(trailing)
                controller.toolbarItems.append(
                    ToolbarItemInfo(
                        placement: .navigationBarTrailing,
                        node: renderedTrailing
                    )
                )
            }
        }

        return context.renderChild(content)
    }
}

extension View {
    @MainActor
    public func navigationBarItems<Leading: View>(
        leading: Leading
    ) -> some View {
        _NavigationBarItemsModifier(
            content: self,
            leading: AnyView(leading),
            trailing: nil
        )
    }

    @MainActor
    public func navigationBarItems<Trailing: View>(
        trailing: Trailing
    ) -> some View {
        _NavigationBarItemsModifier(
            content: self,
            leading: nil,
            trailing: AnyView(trailing)
        )
    }

    @MainActor
    public func navigationBarItems<Leading: View, Trailing: View>(
        leading: Leading,
        trailing: Trailing
    ) -> some View {
        _NavigationBarItemsModifier(
            content: self,
            leading: AnyView(leading),
            trailing: AnyView(trailing)
        )
    }

    @MainActor
    public func navigationBarItems<ItemContent: View>(
        _ item: NavigationBarItem<ItemContent>
    ) -> some View {
        switch item.placement {
        case .leading:
            return AnyView(
                _NavigationBarItemsModifier(
                    content: self,
                    leading: AnyView(item.content),
                    trailing: nil
                )
            )
        case .trailing:
            return AnyView(
                _NavigationBarItemsModifier(
                    content: self,
                    leading: nil,
                    trailing: AnyView(item.content)
                )
            )
        }
    }
}
