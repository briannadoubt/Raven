import Foundation

/// Reconciliation pass that walks the WIP fiber tree depth-first,
/// skipping clean subtrees and collecting mutations.
///
/// This is the key performance optimization: entire subtrees where
/// `isDirty == false && hasDirtyDescendant == false` are skipped entirely.
@MainActor
public struct ReconcilePass {

    /// Result of a reconciliation pass.
    public enum Result {
        /// Reconciliation completed — all fibers processed.
        case complete(mutations: [FiberMutation])
        /// Reconciliation paused due to work budget exhaustion.
        case paused(resumeFrom: Fiber, mutations: [FiberMutation])
    }

    public init() {}

    /// Run reconciliation starting from root.
    ///
    /// - Parameters:
    ///   - root: Root fiber to reconcile.
    ///   - workBudget: Maximum number of fibers to process (default: unlimited).
    /// - Returns: Result indicating completion or pause state.
    public func run(root: Fiber, workBudget: Int = .max) -> Result {
        return processLoop(from: root, root: root, remainingBudget: workBudget, mutations: [])
    }

    /// Resume reconciliation from a paused state.
    ///
    /// - Parameters:
    ///   - fiber: Fiber to resume from.
    ///   - root: Root fiber (for traversal boundaries).
    ///   - remainingBudget: Remaining work budget.
    ///   - mutations: Previously collected mutations.
    /// - Returns: Result indicating completion or pause state.
    public func resume(
        from fiber: Fiber,
        root: Fiber,
        remainingBudget: Int,
        mutations: [FiberMutation]
    ) -> Result {
        return processLoop(from: fiber, root: root, remainingBudget: remainingBudget, mutations: mutations)
    }

    // MARK: - Core Loop

    private func processLoop(
        from startFiber: Fiber,
        root: Fiber,
        remainingBudget: Int,
        mutations: [FiberMutation]
    ) -> Result {
        var current: Fiber? = startFiber
        var budget = remainingBudget
        var collected = mutations

        while let fiber = current {
            // Check work budget
            if budget <= 0 {
                return .paused(resumeFrom: fiber, mutations: collected)
            }
            budget -= 1

            // KEY PERF WIN: skip entire clean subtrees
            if !fiber.isDirty && !fiber.hasDirtyDescendant {
                current = nextFiberSkippingSubtree(fiber, root: root)
                continue
            }

            // Process dirty fiber
            var createdFullSubtree = false
            if fiber.isDirty {
                let fiberMutations = reconcileFiber(fiber)
                collected.append(contentsOf: fiberMutations)

                // .insert and .replace both create the entire DOM subtree
                // via createDOMNode, so we must skip children to avoid
                // generating duplicate mutations.
                createdFullSubtree = fiberMutations.contains { m in
                    switch m {
                    case .insert, .replace: return true
                    default: return false
                    }
                }
            }

            if createdFullSubtree {
                current = nextFiberSkippingSubtree(fiber, root: root)
            } else {
                // Continue depth-first traversal (into children)
                current = fiber.nextFiber(root: root)
            }
        }

        return .complete(mutations: collected)
    }

    // MARK: - Single Fiber Reconciliation

    /// Reconcile a single dirty fiber by comparing old (alternate) vs new elementDesc.
    private func reconcileFiber(_ fiber: Fiber) -> [FiberMutation] {
        var mutations: [FiberMutation] = []

        guard let newElement = fiber.elementDesc else {
            // No element description — the fiber was removed
            if let nodeID = fiber.stableNodeID {
                mutations.append(.remove(nodeID: nodeID))
            }
            return mutations
        }

        // Check if we have an alternate (previous version of this fiber)
        guard let alternate = fiber.alternate,
              let oldElement = alternate.elementDesc else {
            // No alternate = new insertion
            if let parentID = fiber.parent?.stableNodeID {
                let index = indexInParent(fiber)
                mutations.append(.insert(parentID: parentID, node: newElement, index: index))
            }
            return mutations
        }

        // Both old and new exist — diff them
        if !areNodeTypesCompatible(old: oldElement, new: newElement) {
            // Type changed — full replacement
            if let nodeID = fiber.stableNodeID {
                mutations.append(.replace(oldID: nodeID, newNode: newElement))
            }
        } else {
            // Same type — diff properties
            let propPatches = diffProps(old: oldElement.props, new: newElement.props)
            if !propPatches.isEmpty, let nodeID = fiber.stableNodeID {
                mutations.append(.updateProps(nodeID: nodeID, patches: propPatches))
            }
        }

        // Check for child reordering
        if let reorderMutation = checkChildReordering(fiber) {
            mutations.append(reorderMutation)
        }

        // Drain pending removals — old children that were not matched
        // during FiberTreeBuilder.reconcileChildren.
        if !fiber.pendingRemovals.isEmpty {
            for nodeID in fiber.pendingRemovals {
                mutations.append(.remove(nodeID: nodeID))
            }
            fiber.pendingRemovals.removeAll()
        }

        return mutations
    }

    // MARK: - Diffing Helpers

    /// Check if two VNode types are compatible (same tag).
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

    /// Diff properties between old and new VNodes.
    private func diffProps(
        old: [String: VProperty],
        new: [String: VProperty]
    ) -> [PropPatch] {
        var patches: [PropPatch] = []

        // Find removed and updated properties
        for (key, oldValue) in old {
            if let newValue = new[key] {
                if oldValue != newValue {
                    patches.append(.update(key: key, value: newValue))
                }
            } else {
                patches.append(.remove(key: key))
            }
        }

        // Find added properties
        for (key, newValue) in new where old[key] == nil {
            patches.append(.add(key: key, value: newValue))
        }

        return patches
    }

    /// Detect child reordering by comparing keys between alternate and current fiber.
    private func checkChildReordering(_ fiber: Fiber) -> FiberMutation? {
        guard let parentNodeID = fiber.stableNodeID else { return nil }

        let oldChildren = fiber.alternate?.children ?? []
        let newChildren = fiber.children

        guard oldChildren.count > 1 || newChildren.count > 1 else { return nil }

        // Build key-to-index maps
        var oldKeyMap: [String: Int] = [:]
        for (i, child) in oldChildren.enumerated() {
            if let key = child.key {
                oldKeyMap[key] = i
            }
        }

        guard !oldKeyMap.isEmpty else { return nil }

        var moves: [Move] = []
        for (newIndex, child) in newChildren.enumerated() {
            if let key = child.key, let oldIndex = oldKeyMap[key], oldIndex != newIndex {
                moves.append(Move(from: oldIndex, to: newIndex))
            }
        }

        if !moves.isEmpty {
            return .reorder(parentID: parentNodeID, moves: moves)
        }

        return nil
    }

    // MARK: - Tree Navigation Helpers

    /// Calculate the index of a fiber among its parent's children.
    private func indexInParent(_ fiber: Fiber) -> Int {
        guard let parent = fiber.parent else { return 0 }
        var index = 0
        var current = parent.child
        while let c = current {
            if c === fiber { return index }
            index += 1
            current = c.sibling
        }
        return index
    }

    /// Get next fiber while skipping the subtree of the current fiber.
    /// Goes to sibling, or walks up to find an ancestor's sibling.
    private func nextFiberSkippingSubtree(_ fiber: Fiber, root: Fiber) -> Fiber? {
        if let sibling = fiber.sibling {
            return sibling
        }
        var current = fiber.parent
        while let parent = current {
            if parent === root { return nil }
            if let sibling = parent.sibling { return sibling }
            current = parent.parent
        }
        return nil
    }
}
