import Foundation

/// Virtual tree wrapper for managing the root of the virtual DOM
public struct VTree: Sendable {
    /// Root node of the virtual tree
    public let root: VNode

    /// Metadata about the tree
    public let metadata: TreeMetadata

    /// Initialize a virtual tree
    /// - Parameters:
    ///   - root: Root node
    ///   - metadata: Tree metadata
    public init(root: VNode, metadata: TreeMetadata = TreeMetadata()) {
        self.root = root
        self.metadata = metadata
    }
}

/// Metadata for tracking tree state and performance
public struct TreeMetadata: Sendable {
    /// Timestamp when the tree was created
    public let createdAt: Date

    /// Version number for the tree (increments on updates)
    public let version: Int

    /// Optional identifier for debugging
    public let debugLabel: String?

    /// Initialize tree metadata
    /// - Parameters:
    ///   - createdAt: Creation timestamp
    ///   - version: Version number
    ///   - debugLabel: Optional debug label
    public init(
        createdAt: Date = Date(),
        version: Int = 0,
        debugLabel: String? = nil
    ) {
        self.createdAt = createdAt
        self.version = version
        self.debugLabel = debugLabel
    }

    /// Create a new metadata with incremented version
    /// - Returns: New metadata with version incremented by 1
    public func incrementVersion() -> TreeMetadata {
        TreeMetadata(
            createdAt: createdAt,
            version: version + 1,
            debugLabel: debugLabel
        )
    }
}

// MARK: - Tree Operations

extension VTree {
    /// Create a new tree with updated root
    /// - Parameter root: New root node
    /// - Returns: New VTree with updated root and incremented version
    public func withRoot(_ root: VNode) -> VTree {
        VTree(
            root: root,
            metadata: metadata.incrementVersion()
        )
    }

    /// Count total nodes in the tree
    /// - Returns: Total number of nodes including root and all descendants
    public func nodeCount() -> Int {
        countNodes(root)
    }

    private func countNodes(_ node: VNode) -> Int {
        1 + node.children.reduce(0) { $0 + countNodes($1) }
    }

    /// Calculate maximum depth of the tree
    /// - Returns: Maximum depth from root to deepest leaf
    public func maxDepth() -> Int {
        calculateDepth(root)
    }

    private func calculateDepth(_ node: VNode) -> Int {
        guard !node.children.isEmpty else { return 1 }
        return 1 + (node.children.map { calculateDepth($0) }.max() ?? 0)
    }

    /// Collect all node IDs in the tree
    /// - Returns: Set of all NodeIDs in the tree
    public func allNodeIDs() -> Set<NodeID> {
        var ids = Set<NodeID>()
        collectNodeIDs(root, into: &ids)
        return ids
    }

    private func collectNodeIDs(_ node: VNode, into set: inout Set<NodeID>) {
        set.insert(node.id)
        for child in node.children {
            collectNodeIDs(child, into: &set)
        }
    }

    /// Find node by ID
    /// - Parameter id: NodeID to search for
    /// - Returns: VNode if found, nil otherwise
    public func findNode(id: NodeID) -> VNode? {
        findNodeRecursive(id: id, in: root)
    }

    private func findNodeRecursive(id: NodeID, in node: VNode) -> VNode? {
        if node.id == id {
            return node
        }
        for child in node.children {
            if let found = findNodeRecursive(id: id, in: child) {
                return found
            }
        }
        return nil
    }
}

// MARK: - Tree Validation

extension VTree {
    /// Validate tree structure
    /// - Returns: Array of validation errors (empty if valid)
    public func validate() -> [TreeValidationError] {
        var errors: [TreeValidationError] = []
        var seenIDs = Set<NodeID>()
        validateNode(root, seenIDs: &seenIDs, errors: &errors, path: "root")
        return errors
    }

    private func validateNode(
        _ node: VNode,
        seenIDs: inout Set<NodeID>,
        errors: inout [TreeValidationError],
        path: String
    ) {
        // Check for duplicate IDs
        if seenIDs.contains(node.id) {
            errors.append(.duplicateID(nodeID: node.id, path: path))
        } else {
            seenIDs.insert(node.id)
        }

        // Validate node type specific rules
        switch node.type {
        case .text:
            if !node.children.isEmpty {
                errors.append(.textNodeWithChildren(nodeID: node.id, path: path))
            }
        case .element(let tag):
            if tag.isEmpty {
                errors.append(.emptyElementTag(nodeID: node.id, path: path))
            }
        case .component, .fragment:
            break
        }

        // Recursively validate children
        for (index, child) in node.children.enumerated() {
            validateNode(
                child,
                seenIDs: &seenIDs,
                errors: &errors,
                path: "\(path)/[\(index)]"
            )
        }
    }
}

/// Errors that can occur during tree validation
public enum TreeValidationError: Hashable, Sendable, CustomStringConvertible {
    case duplicateID(nodeID: NodeID, path: String)
    case textNodeWithChildren(nodeID: NodeID, path: String)
    case emptyElementTag(nodeID: NodeID, path: String)

    public var description: String {
        switch self {
        case .duplicateID(let nodeID, let path):
            return "Duplicate node ID \(nodeID) at \(path)"
        case .textNodeWithChildren(let nodeID, let path):
            return "Text node \(nodeID) at \(path) has children"
        case .emptyElementTag(let nodeID, let path):
            return "Element node \(nodeID) at \(path) has empty tag"
        }
    }
}
