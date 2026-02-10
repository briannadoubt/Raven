import Foundation

/// A mutation produced by the reconciliation pass.
///
/// `FiberMutation` mirrors `Patch` but is decoupled from the VNode-based
/// diffing pipeline. The commit phase translates these into platform
/// operations (or falls back to `Patch` via the default `applyMutations`
/// implementation on `PlatformRenderer`).
public enum FiberMutation: Sendable {
    /// Insert a new element as a child of `parentID` at `index`.
    case insert(parentID: NodeID, node: VNode, index: Int)

    /// Remove the element identified by `nodeID`.
    case remove(nodeID: NodeID)

    /// Replace the element at `oldID` with a new `VNode`.
    case replace(oldID: NodeID, newNode: VNode)

    /// Update properties on the element at `nodeID`.
    case updateProps(nodeID: NodeID, patches: [PropPatch])

    /// Reorder children of the element at `parentID`.
    case reorder(parentID: NodeID, moves: [Move])
}

// MARK: - Conversion to Patch

extension FiberMutation {
    /// Convert this mutation to the equivalent legacy `Patch`.
    ///
    /// Used by the default `PlatformRenderer.applyMutations` implementation
    /// so renderers that only implement `applyPatches` still work.
    public func toPatch() -> Patch {
        switch self {
        case .insert(let parentID, let node, let index):
            return .insert(parent: parentID, node: node, index: index)
        case .remove(let nodeID):
            return .remove(nodeID: nodeID)
        case .replace(let oldID, let newNode):
            return .replace(oldID: oldID, newNode: newNode)
        case .updateProps(let nodeID, let patches):
            return .updateProps(nodeID: nodeID, patches: patches)
        case .reorder(let parentID, let moves):
            return .reorder(parent: parentID, moves: moves)
        }
    }
}
