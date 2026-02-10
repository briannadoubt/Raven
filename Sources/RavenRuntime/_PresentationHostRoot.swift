import Foundation
import RavenCore

/// Runtime-level root wrapper that mounts Raven presentations into the DOM.
///
/// Presentations are registered into `PresentationCoordinator`, but they won't
/// display unless something renders `coordinator.presentations` into the VDOM.
/// The runtime wraps the app root in this view automatically.
@MainActor
internal struct _PresentationHostRoot<Content: View>: View, Sendable {
    @Environment(\.presentationCoordinator) private var coordinator
    private let content: Content

    @MainActor internal init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    @MainActor internal var body: some View {
        // Ensure changes to `coordinator.presentations` invalidate the view tree by
        // observing the coordinator explicitly. Without this, `.actionSheet` and
        // friends can register presentations that never make it into the DOM.
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
