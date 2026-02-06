import Foundation

// MARK: - Patch Operations

/// Represents a single patch operation to transform one virtual DOM tree into another
public enum Patch: Hashable, Sendable {
    /// Insert a new node as a child of the parent at the specified index
    case insert(parent: NodeID, node: VNode, index: Int)

    /// Remove a node from the tree
    case remove(nodeID: NodeID)

    /// Replace an old node with a new node
    case replace(oldID: NodeID, newNode: VNode)

    /// Update properties of an existing node
    case updateProps(nodeID: NodeID, patches: [PropPatch])

    /// Reorder children of a parent node
    case reorder(parent: NodeID, moves: [Move])
}

// MARK: - Property Patch Operations

/// Represents a single property patch operation
public enum PropPatch: Hashable, Sendable {
    /// Add a new property
    case add(key: String, value: VProperty)

    /// Remove an existing property
    case remove(key: String)

    /// Update an existing property value
    case update(key: String, value: VProperty)
}

// MARK: - Move Operation

/// Represents a move operation for reordering children
public struct Move: Hashable, Sendable {
    /// Source index
    public let from: Int

    /// Destination index
    public let to: Int

    public init(from: Int, to: Int) {
        self.from = from
        self.to = to
    }
}
