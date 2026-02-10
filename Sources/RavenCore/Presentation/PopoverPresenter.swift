import Foundation

/// A View-based implementation of popover presentation.
///
/// Important: Presentation modifiers need stable state (the presentation UUID)
/// tied to the view tree position, not to a transient `ViewModifier` value.
/// We implement popovers as primitive views using `persistentState` so they can
/// register/dismiss reliably across renders.
@MainActor
struct _PopoverPresenter<Source: View, PopoverContent: View>: View, PrimitiveView, Sendable {
    typealias Body = Never

    private final class State: @unchecked Sendable {
        var isVisible: Bool = false
        var presentationId: UUID?
    }

    let source: Source
    @Binding var isPresented: Bool
    let attachmentAnchor: PopoverAttachmentAnchor
    let arrowEdge: Edge
    let onDismiss: (@MainActor @Sendable () -> Void)?
    let popoverContent: @MainActor @Sendable () -> PopoverContent

    @Environment(\.presentationCoordinator) private var coordinator

    init(
        source: Source,
        isPresented: Binding<Bool>,
        attachmentAnchor: PopoverAttachmentAnchor,
        arrowEdge: Edge,
        onDismiss: (@MainActor @Sendable () -> Void)?,
        @ViewBuilder content: @escaping @MainActor @Sendable () -> PopoverContent
    ) {
        self.source = source
        self._isPresented = isPresented
        self.attachmentAnchor = attachmentAnchor
        self.arrowEdge = arrowEdge
        self.onDismiss = onDismiss
        self.popoverContent = content
    }

    @MainActor func toVNode() -> VNode {
        VNode.fragment(children: [])
    }
}

extension _PopoverPresenter: _CoordinatorRenderable {
    @MainActor func _render(with context: any _RenderContext) -> VNode {
        let state: State = context.persistentState { State() }

        func presentIfNeeded() {
            guard state.presentationId == nil else { return }
            let handleDismiss: @MainActor @Sendable () -> Void = { [onDismiss, _isPresented] in
                _isPresented.wrappedValue = false
                onDismiss?()
            }
            state.presentationId = coordinator.present(
                type: .popover(anchor: attachmentAnchor, edge: arrowEdge),
                content: AnyView(popoverContent()),
                onDismiss: handleDismiss
            )
        }

        func dismissIfNeeded() {
            if let id = state.presentationId {
                coordinator.dismiss(id)
                state.presentationId = nil
            }
        }

        // Schedule coordinator mutations after this render pass.
        // This avoids re-entrant mutations while building VNodes and doesn't rely on lifecycle events.
        if isPresented, state.presentationId == nil {
            context.enqueuePostRender {
                presentIfNeeded()
            }
        } else if !isPresented, state.presentationId != nil {
            context.enqueuePostRender {
                dismissIfNeeded()
            }
        }

        return context.renderChild(source)
    }
}

@MainActor
struct _PopoverItemPresenter<Source: View, Item: Identifiable & Sendable, PopoverContent: View>: View, PrimitiveView, Sendable where Item.ID: Sendable {
    typealias Body = Never

    private final class State: @unchecked Sendable {
        var isVisible: Bool = false
        var presentationId: UUID?
        var currentItemId: Item.ID?
    }

    let source: Source
    @Binding var item: Item?
    let attachmentAnchor: PopoverAttachmentAnchor
    let arrowEdge: Edge
    let onDismiss: (@MainActor @Sendable () -> Void)?
    let popoverContent: @MainActor @Sendable (Item) -> PopoverContent

    @Environment(\.presentationCoordinator) private var coordinator

    init(
        source: Source,
        item: Binding<Item?>,
        attachmentAnchor: PopoverAttachmentAnchor,
        arrowEdge: Edge,
        onDismiss: (@MainActor @Sendable () -> Void)?,
        @ViewBuilder content: @escaping @MainActor @Sendable (Item) -> PopoverContent
    ) {
        self.source = source
        self._item = item
        self.attachmentAnchor = attachmentAnchor
        self.arrowEdge = arrowEdge
        self.onDismiss = onDismiss
        self.popoverContent = content
    }

    @MainActor func toVNode() -> VNode { VNode.fragment(children: []) }
}

extension _PopoverItemPresenter: _CoordinatorRenderable {
    @MainActor func _render(with context: any _RenderContext) -> VNode {
        let state: State = context.persistentState { State() }

        func dismissIfNeeded() {
            if let id = state.presentationId {
                coordinator.dismiss(id)
                state.presentationId = nil
                state.currentItemId = nil
            }
        }

        func present(item: Item) {
            let handleDismiss: @MainActor @Sendable () -> Void = { [onDismiss, _item] in
                _item.wrappedValue = nil
                onDismiss?()
            }
            state.presentationId = coordinator.present(
                type: .popover(anchor: attachmentAnchor, edge: arrowEdge),
                content: AnyView(popoverContent(item)),
                onDismiss: handleDismiss
            )
            state.currentItemId = item.id
        }

        // Keep in sync with changes to `item` while this view is rendered.
        if let item {
            if state.presentationId == nil {
                context.enqueuePostRender { present(item: item) }
            } else if state.currentItemId != item.id {
                context.enqueuePostRender {
                    dismissIfNeeded()
                    present(item: item)
                }
            }
        } else if state.presentationId != nil {
            context.enqueuePostRender { dismissIfNeeded() }
        }

        return context.renderChild(source)
    }
}
