import Foundation
import JavaScriptKit

// MARK: - State Change Receiver Protocol

/// Protocol for receiving state change notifications and scheduling renders.
///
/// `RenderCoordinator` conforms to this protocol to enable batched rendering:
/// multiple state changes coalesce into a single render pass.
@MainActor public protocol _StateChangeReceiver: AnyObject {
    /// Schedule a render pass. Multiple calls before the microtask fires
    /// are coalesced into a single render.
    func scheduleRender()

    /// Mark a component path as dirty (state changed), triggering selective
    /// re-rendering of only the affected subtree.
    func markDirty(path: String)
}

// MARK: - Render Context Protocol

/// Abstracts the render coordinator so views in the Raven module can render
/// children and register event handlers without importing RavenRuntime.
///
/// `RenderCoordinator` conforms to this protocol in RavenRuntime.
@MainActor public protocol _RenderContext: AnyObject {
    /// Recursively convert a child view into its VNode representation.
    func renderChild(_ view: any View) -> VNode

    /// Register a click/action handler and return its unique ID.
    /// The ID is stable across renders based on position in the view tree.
    func registerClickHandler(_ action: @escaping @Sendable @MainActor () -> Void) -> UUID

    /// Register an input handler that receives the raw DOM event and return its unique ID.
    /// The ID is stable across renders based on position in the view tree.
    func registerInputHandler(_ handler: @escaping @Sendable @MainActor (JSValue) -> Void) -> UUID

    /// Retrieve or create a persistent state object keyed by position in the view tree.
    /// The object survives across re-renders, enabling stateful controllers (e.g. NavigationStackController).
    func persistentState<T: AnyObject>(create: () -> T) -> T
}

// MARK: - Coordinator Renderable Protocol

/// Views that can render themselves given a render context.
///
/// This replaces Mirror-based reflection in RenderLoop. Each conforming view
/// produces its own VNode tree using the context to render children and
/// register event handlers.
@MainActor public protocol _CoordinatorRenderable {
    func _render(with context: any _RenderContext) -> VNode
}

// MARK: - Modifier Renderable Protocol

/// Convenience protocol for modifier views that wrap a single `content` child
/// and add CSS styles via `toVNode()`.
///
/// The default `_render` implementation:
/// 1. Calls `toVNode()` to get the wrapper element (with CSS props, empty children)
/// 2. Calls `context.renderChild(content)` to render the wrapped content
/// 3. Merges the rendered children into the wrapper
@MainActor public protocol _ModifierRenderable: _CoordinatorRenderable, PrimitiveView {
    associatedtype ModifiedContent: View
    var _modifiedContent: ModifiedContent { get }
}

extension _ModifierRenderable {
    @MainActor public func _render(with context: any _RenderContext) -> VNode {
        let wrapperNode = toVNode()
        let contentNode = context.renderChild(_modifiedContent)

        switch wrapperNode.type {
        case .element(let tag):
            let children: [VNode]
            if case .fragment = contentNode.type {
                children = contentNode.children
            } else {
                children = [contentNode]
            }
            return VNode(
                id: wrapperNode.id,
                type: .element(tag: tag),
                props: wrapperNode.props,
                children: children,
                key: wrapperNode.key
            )
        default:
            // Fallback: just return the content
            return contentNode
        }
    }
}
