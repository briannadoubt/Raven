import Foundation

/// Root-level host that renders active presentations (sheets, alerts, action sheets, etc.).
///
/// Raven's presentation modifiers register entries with `PresentationCoordinator`.
/// This host is responsible for turning those entries into actual DOM nodes
/// (HTML `<dialog>` elements via `DialogRenderer`).
///
/// The runtime wraps the app root in `PresentationHost` automatically so apps
/// don't have to opt in.
@MainActor
public struct PresentationHost<Content: View>: View, Sendable {
    @Environment(\.presentationCoordinator) private var coordinator
    private let content: Content

    @MainActor public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    @MainActor public var body: some View {
        _PresentationHostObserved(coordinator: coordinator, content: content)
    }
}

@MainActor
private struct _PresentationHostObserved<Content: View>: View, PrimitiveView, _CoordinatorRenderable, Sendable {
    typealias Body = Never

    @ObservedObject var coordinator: PresentationCoordinator
    let content: Content

    @MainActor func toVNode() -> VNode {
        // `_render(with:)` is used for actual rendering; this is only required
        // to satisfy `PrimitiveView` conformance.
        VNode.fragment(children: [])
    }

    @MainActor func _render(with context: any _RenderContext) -> VNode {
        let contentNode = context.renderChild(content)
        let dialogs = coordinator.presentations.map { entry in
            let presentedContent = context.renderChild(entry.content)
            return DialogRenderer.render(entry: entry, coordinator: coordinator, content: presentedContent)
        }
        return VNode.fragment(children: [contentNode] + dialogs)
    }
}
