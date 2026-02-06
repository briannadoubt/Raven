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

// MARK: - Differ

/// Main diffing engine using a modified Myers algorithm for virtual DOM trees
@MainActor
public struct Differ: Sendable {

    public init() {}

    /// Compute the minimal set of patches to transform old tree into new tree
    /// - Parameters:
    ///   - old: Optional old virtual node
    ///   - new: Optional new virtual node
    /// - Returns: Array of patches to apply
    public func diff(old: VNode?, new: VNode?) -> [Patch] {
        // Handle nil cases
        guard let old = old else {
            // No old node, insert new if it exists
            if let new = new {
                // We need a parent ID to insert, which we don't have at root level
                // In practice, this would be handled by the caller
                return []
            }
            return []
        }

        guard let new = new else {
            // Old node exists but new doesn't, remove it
            return [.remove(nodeID: old.id)]
        }

        // Both nodes exist, diff them
        return diffNodes(old: old, new: new)
    }

    /// Diff two non-nil nodes
    private func diffNodes(old: VNode, new: VNode) -> [Patch] {
        var patches: [Patch] = []

        // Fast path: if types differ, replace whole subtree
        if !areNodeTypesCompatible(old: old, new: new) {
            patches.append(.replace(oldID: old.id, newNode: new))
            return patches
        }

        // Types are compatible, diff properties
        let propPatches = diffProps(old: old.props, new: new.props)
        if !propPatches.isEmpty {
            patches.append(.updateProps(nodeID: old.id, patches: propPatches))
        }

        // Diff children
        let childPatches = diffChildren(
            parentID: old.id,
            oldChildren: old.children,
            newChildren: new.children
        )
        patches.append(contentsOf: childPatches)

        return patches
    }

    /// Check if two node types are compatible for diffing
    private func areNodeTypesCompatible(old: VNode, new: VNode) -> Bool {
        switch (old.type, new.type) {
        case (.element(let oldTag), .element(let newTag)):
            return oldTag == newTag
        case (.text(let oldText), .text(let newText)):
            return oldText == newText
        case (.component, .component):
            return true
        case (.fragment, .fragment):
            return true
        default:
            return false
        }
    }

    /// Diff properties between old and new nodes
    private func diffProps(
        old: [String: VProperty],
        new: [String: VProperty]
    ) -> [PropPatch] {
        var patches: [PropPatch] = []

        // Find removed and updated properties
        for (key, oldValue) in old {
            if let newValue = new[key] {
                // Property exists in both, check if it changed
                if oldValue != newValue {
                    patches.append(.update(key: key, value: newValue))
                }
            } else {
                // Property was removed
                patches.append(.remove(key: key))
            }
        }

        // Find added properties
        for (key, newValue) in new {
            if old[key] == nil {
                patches.append(.add(key: key, value: newValue))
            }
        }

        return patches
    }

    /// Diff children arrays using modified Myers algorithm
    private func diffChildren(
        parentID: NodeID,
        oldChildren: [VNode],
        newChildren: [VNode]
    ) -> [Patch] {
        // Check if children have keys
        let oldHasKeys = oldChildren.contains { $0.key != nil }
        let newHasKeys = newChildren.contains { $0.key != nil }

        if oldHasKeys || newHasKeys {
            // Use keyed diffing algorithm
            return diffKeyedChildren(
                parentID: parentID,
                oldChildren: oldChildren,
                newChildren: newChildren
            )
        } else {
            // Use simple positional diffing
            return diffPositionalChildren(
                parentID: parentID,
                oldChildren: oldChildren,
                newChildren: newChildren
            )
        }
    }

    /// Diff children without keys using simple positional algorithm
    private func diffPositionalChildren(
        parentID: NodeID,
        oldChildren: [VNode],
        newChildren: [VNode]
    ) -> [Patch] {
        var patches: [Patch] = []
        let maxLen = max(oldChildren.count, newChildren.count)

        for i in 0..<maxLen {
            if i < oldChildren.count && i < newChildren.count {
                // Both exist, recursively diff
                let childPatches = diffNodes(old: oldChildren[i], new: newChildren[i])
                patches.append(contentsOf: childPatches)
            } else if i < oldChildren.count {
                // Old child exists but new doesn't, remove it
                patches.append(.remove(nodeID: oldChildren[i].id))
            } else {
                // New child exists but old doesn't, insert it
                patches.append(.insert(parent: parentID, node: newChildren[i], index: i))
            }
        }

        return patches
    }

    /// Diff children with keys using LCS-based algorithm
    private func diffKeyedChildren(
        parentID: NodeID,
        oldChildren: [VNode],
        newChildren: [VNode]
    ) -> [Patch] {
        var patches: [Patch] = []

        // Build key-to-node and key-to-index maps
        var oldKeyToNode: [String: VNode] = [:]
        var oldKeyToIndex: [String: Int] = [:]
        var newKeyToIndex: [String: Int] = [:]

        for (index, child) in oldChildren.enumerated() {
            if let key = child.key {
                oldKeyToNode[key] = child
                oldKeyToIndex[key] = index
            }
        }

        for (index, child) in newChildren.enumerated() {
            if let key = child.key {
                newKeyToIndex[key] = index
            }
        }

        // Find nodes to remove (in old but not in new)
        var nodesToRemove = Set<NodeID>()
        for child in oldChildren {
            if let key = child.key {
                if newKeyToIndex[key] == nil {
                    nodesToRemove.insert(child.id)
                }
            } else {
                // Unkeyed child in keyed list, remove it
                nodesToRemove.insert(child.id)
            }
        }

        // Process new children
        var moves: [Move] = []
        var seenKeys = Set<String>()

        for (newIndex, newChild) in newChildren.enumerated() {
            if let key = newChild.key {
                seenKeys.insert(key)

                if let oldNode = oldKeyToNode[key], let oldIndex = oldKeyToIndex[key] {
                    // Node exists in both trees
                    // Check if it moved
                    if oldIndex != newIndex {
                        moves.append(Move(from: oldIndex, to: newIndex))
                    }

                    // Diff the node's properties and children
                    let nodePatches = diffNodes(old: oldNode, new: newChild)
                    patches.append(contentsOf: nodePatches)
                } else {
                    // New node, insert it
                    patches.append(.insert(parent: parentID, node: newChild, index: newIndex))
                }
            } else {
                // Unkeyed child in keyed list, treat as new
                patches.append(.insert(parent: parentID, node: newChild, index: newIndex))
            }
        }

        // Add remove patches
        for nodeID in nodesToRemove {
            patches.append(.remove(nodeID: nodeID))
        }

        // Add reorder patch if there are moves
        if !moves.isEmpty {
            patches.append(.reorder(parent: parentID, moves: moves))
        }

        return patches
    }
}

// MARK: - LCS Helper (for future optimization)

extension Differ {
    /// Longest Common Subsequence using Myers algorithm
    /// This can be used for more sophisticated diffing
    private func longestCommonSubsequence<T: Equatable>(
        _ a: [T],
        _ b: [T]
    ) -> [(aIndex: Int, bIndex: Int)] {
        guard !a.isEmpty && !b.isEmpty else { return [] }

        let n = a.count
        let m = b.count
        let max = n + m

        var v: [Int: Int] = [1: 0]
        var trace: [[Int: Int]] = []

        for d in 0...max {
            trace.append(v)

            for k in stride(from: -d, through: d, by: 2) {
                var x: Int

                if k == -d || (k != d && (v[k - 1] ?? 0) < (v[k + 1] ?? 0)) {
                    x = v[k + 1] ?? 0
                } else {
                    x = (v[k - 1] ?? 0) + 1
                }

                var y = x - k

                while x < n && y < m && a[x] == b[y] {
                    x += 1
                    y += 1
                }

                v[k] = x

                if x >= n && y >= m {
                    return backtrack(trace: trace, a: a, b: b, n: n, m: m)
                }
            }
        }

        return []
    }

    /// Backtrack through the trace to find the LCS
    private func backtrack<T: Equatable>(
        trace: [[Int: Int]],
        a: [T],
        b: [T],
        n: Int,
        m: Int
    ) -> [(aIndex: Int, bIndex: Int)] {
        var x = n
        var y = m
        var lcs: [(aIndex: Int, bIndex: Int)] = []

        for d in stride(from: trace.count - 1, through: 0, by: -1) {
            let v = trace[d]
            let k = x - y

            let prev_k: Int
            if k == -d || (k != d && (v[k - 1] ?? 0) < (v[k + 1] ?? 0)) {
                prev_k = k + 1
            } else {
                prev_k = k - 1
            }

            let prev_x = v[prev_k] ?? 0
            let prev_y = prev_x - prev_k

            while x > prev_x && y > prev_y {
                x -= 1
                y -= 1
                if x >= 0 && y >= 0 && x < a.count && y < b.count && a[x] == b[y] {
                    lcs.insert((aIndex: x, bIndex: y), at: 0)
                }
            }

            if d > 0 {
                x = prev_x
                y = prev_y
            }
        }

        return lcs
    }
}
