import Foundation

// MARK: - Platform Renderer Protocol

/// Abstraction over the platform rendering backend.
///
/// `DOMRenderer` (in RavenRuntime) implements this for browser DOM rendering.
/// `TestRenderer` (in Raven/Testing) implements this for headless testing.
///
/// The renderer translates VNodes and Patches into platform-specific operations.
/// Event handlers are stored in `RenderCoordinator`; the renderer attaches
/// platform listeners that call back into the coordinator via invoker closures.
@MainActor public protocol PlatformRenderer: AnyObject {
    /// Set the root container for rendering.
    func setRootContainer(_ container: Any)

    /// Mount a full VNode tree to the platform (initial render).
    func mountTree(_ root: VNode)

    /// Apply an array of patches to the existing platform tree.
    func applyPatches(_ patches: [Patch])

    /// Register a platform node by its NodeID for later lookup.
    func registerNode(id: NodeID, element: Any)

    /// Unregister a platform node.
    func unregisterNode(id: NodeID)

    /// Look up a previously registered platform node.
    func getNode(id: NodeID) -> Any?

    /// Attach an event handler to a platform node.
    func attachEventHandler(nodeID: NodeID, event: String, handlerID: UUID)

    /// Update the closure for a click/action event handler.
    func updateEventHandler(id: UUID, handler: @escaping @Sendable @MainActor () -> Void)

    /// Update the closure for an input event handler that receives event data.
    func updateInputEventHandler(id: UUID, handler: @escaping @Sendable @MainActor (Any) -> Void)

    /// Clean up a handler that is no longer active.
    func cleanupHandler(id: UUID)

    /// Apply fiber mutations in batch.
    ///
    /// The default implementation translates each `FiberMutation` to a `Patch`
    /// and delegates to `applyPatches`. Renderers may override for better perf.
    func applyMutations(_ mutations: [FiberMutation])
}

// MARK: - Default applyMutations

extension PlatformRenderer {
    public func applyMutations(_ mutations: [FiberMutation]) {
        let patches = mutations.map { $0.toPatch() }
        applyPatches(patches)
    }
}
