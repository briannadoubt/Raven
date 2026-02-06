import Foundation

// MARK: - Test Renderer

/// A headless renderer that records all operations for testing.
///
/// Use `TestRenderer` to verify rendering behavior without a browser:
/// ```swift
/// let renderer = TestRenderer()
/// let coordinator = RenderCoordinator(renderer: renderer)
/// coordinator.render(view: MyView())
/// #expect(renderer.renderCount == 1)
/// ```
///
/// No JavaScriptKit dependency — lives in the `Raven` module so
/// `RavenTests` can use it without importing `RavenRuntime`.
@MainActor
public final class TestRenderer: PlatformRenderer, Sendable {

    // MARK: - Recorded State

    /// The last VNode tree passed to `mountTree`.
    public private(set) var mountedTree: VNode?

    /// Patches applied on each render cycle (one entry per `applyPatches` call).
    public private(set) var appliedPatches: [[Patch]] = []

    /// Total number of mount + applyPatches calls.
    public private(set) var renderCount: Int = 0

    /// Registered nodes by ID.
    public private(set) var nodeRegistry: [NodeID: Any] = [:]

    /// Recorded event handler attachments: (nodeID, event, handlerID).
    public private(set) var attachedHandlers: [(nodeID: NodeID, event: String, handlerID: UUID)] = []

    /// Current event handler closures, keyed by UUID.
    public private(set) var eventHandlers: [UUID: @Sendable @MainActor () -> Void] = [:]

    /// Current input event handler closures, keyed by UUID.
    public private(set) var inputEventHandlers: [UUID: @Sendable @MainActor (Any) -> Void] = [:]

    /// IDs of handlers that have been cleaned up.
    public private(set) var cleanedUpHandlerIDs: [UUID] = []

    /// The root container set via `setRootContainer`.
    public private(set) var rootContainer: Any?

    // MARK: - Init

    public init() {}

    // MARK: - PlatformRenderer Conformance

    public func setRootContainer(_ container: Any) {
        rootContainer = container
    }

    public func mountTree(_ root: VNode) {
        mountedTree = root
        renderCount += 1
    }

    public func applyPatches(_ patches: [Patch]) {
        appliedPatches.append(patches)
        renderCount += 1
    }

    public func registerNode(id: NodeID, element: Any) {
        nodeRegistry[id] = element
    }

    public func unregisterNode(id: NodeID) {
        nodeRegistry.removeValue(forKey: id)
    }

    public func getNode(id: NodeID) -> Any? {
        nodeRegistry[id]
    }

    public func attachEventHandler(nodeID: NodeID, event: String, handlerID: UUID) {
        attachedHandlers.append((nodeID: nodeID, event: event, handlerID: handlerID))
    }

    public func updateEventHandler(id: UUID, handler: @escaping @Sendable @MainActor () -> Void) {
        eventHandlers[id] = handler
    }

    public func updateInputEventHandler(id: UUID, handler: @escaping @Sendable @MainActor (Any) -> Void) {
        inputEventHandlers[id] = handler
    }

    public func cleanupHandler(id: UUID) {
        cleanedUpHandlerIDs.append(id)
        eventHandlers.removeValue(forKey: id)
        inputEventHandlers.removeValue(forKey: id)
    }

    // MARK: - Test Helpers

    /// Reset all recorded state.
    public func reset() {
        mountedTree = nil
        appliedPatches.removeAll()
        renderCount = 0
        nodeRegistry.removeAll()
        attachedHandlers.removeAll()
        eventHandlers.removeAll()
        inputEventHandlers.removeAll()
        cleanedUpHandlerIDs.removeAll()
        rootContainer = nil
    }
}
