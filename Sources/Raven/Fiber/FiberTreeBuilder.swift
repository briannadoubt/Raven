import Foundation

/// Builds and reconciles fiber trees from VNode hierarchies.
///
/// On first render, builds a full fiber tree from the VNode tree.
/// On subsequent renders, reconciles existing fiber children against
/// new VNode children using key-based matching first, then positional fallback.
@MainActor
public final class FiberTreeBuilder {

    public init() {}

    // MARK: - Tree Building

    /// Builds a complete fiber tree from a VNode hierarchy.
    ///
    /// - Parameters:
    ///   - vnode: The root VNode to build from.
    ///   - parentFiber: Optional parent fiber.
    ///   - basePath: Base path for generating FiberIDs (default `"root"`).
    /// - Returns: The root fiber of the built tree.
    public func buildTree(
        from vnode: VNode,
        parentFiber: Fiber? = nil,
        basePath: String = "root"
    ) -> Fiber {
        let fiber = createFiber(from: vnode, parent: parentFiber, path: basePath)

        // Build children recursively
        buildChildren(for: fiber, from: vnode.children, pathPrefix: basePath)

        return fiber
    }

    /// Recursively build child fibers from VNode children.
    private func buildChildren(for parentFiber: Fiber, from children: [VNode], pathPrefix: String) {
        var previousSibling: Fiber?

        for (i, childVNode) in children.enumerated() {
            let childKey = childVNode.key ?? String(i)
            let childPath = "\(pathPrefix).\(childKey)"

            let childFiber = createFiber(from: childVNode, parent: parentFiber, path: childPath)

            // Link into tree
            childFiber.parent = parentFiber
            if let prev = previousSibling {
                prev.sibling = childFiber
            } else {
                parentFiber.child = childFiber
            }
            previousSibling = childFiber

            // Recurse into grandchildren
            if !childVNode.children.isEmpty {
                buildChildren(for: childFiber, from: childVNode.children, pathPrefix: childPath)
            }
        }
    }

    // MARK: - Child Reconciliation

    /// Reconciles existing fiber children against new VNode children.
    ///
    /// Uses key-based matching first, then falls back to positional matching.
    /// Creates, updates, or deletes child fibers accordingly.
    ///
    /// - Parameters:
    ///   - parentFiber: The parent fiber whose children to reconcile.
    ///   - newChildren: The new VNode children to reconcile against.
    ///   - pathPrefix: Path prefix for generating child FiberIDs.
    public func reconcileChildren(
        of parentFiber: Fiber,
        newChildren: [VNode],
        pathPrefix: String
    ) {
        let existingChildren = parentFiber.children

        // Build key maps for efficient lookup
        var existingByKey: [String: Fiber] = [:]
        var existingUnkeyed: [Fiber] = []

        for existing in existingChildren {
            if let key = existing.key {
                existingByKey[key] = existing
            } else {
                existingUnkeyed.append(existing)
            }
        }

        // Clear existing children — we'll rebuild the sibling chain
        parentFiber.removeAllChildren()

        var unkeyedIndex = 0
        var previousFiber: Fiber?

        for (i, newChild) in newChildren.enumerated() {
            let childKey = newChild.key ?? String(i)
            let childPath = "\(pathPrefix).\(childKey)"
            let reconciledFiber: Fiber

            // Try key-based matching first
            if let key = newChild.key, let existing = existingByKey[key] {
                reconciledFiber = reconcileFiber(
                    existing: existing, with: newChild, path: childPath
                )
                existingByKey.removeValue(forKey: key)
            } else if newChild.key == nil, unkeyedIndex < existingUnkeyed.count {
                // Positional matching for unkeyed children
                let existing = existingUnkeyed[unkeyedIndex]
                reconciledFiber = reconcileFiber(
                    existing: existing, with: newChild, path: childPath
                )
                unkeyedIndex += 1
            } else {
                // No match — create new fiber
                reconciledFiber = createFiber(from: newChild, parent: parentFiber, path: childPath)
                // Build sub-children for new fiber
                if !newChild.children.isEmpty {
                    buildChildren(for: reconciledFiber, from: newChild.children, pathPrefix: childPath)
                }
            }

            // Link into sibling chain
            reconciledFiber.parent = parentFiber
            if let prev = previousFiber {
                prev.sibling = reconciledFiber
            } else {
                parentFiber.child = reconciledFiber
            }
            previousFiber = reconciledFiber

            // Propagate dirty flags upward so ReconcilePass doesn't skip
            // the parent subtree.  We must propagate for ALL dirty fibers
            // (not just new ones) because removeAllChildren() nils parent
            // pointers before reconcileFiber runs, so any propagation
            // inside reconcileFiber is lost.  Now that the parent is
            // re-linked (line above), propagate from here.
            if reconciledFiber.isDirty || reconciledFiber.hasDirtyDescendant {
                reconciledFiber.propagateDirtyToAncestors()
            }
        }

        // Collect NodeIDs of unmatched old fibers for removal.
        // Keyed children not consumed above, plus unkeyed children beyond
        // unkeyedIndex, are no longer in the tree and need DOM removal.
        var removals: [NodeID] = []
        for (_, fiber) in existingByKey {
            if let nodeID = fiber.stableNodeID {
                removals.append(nodeID)
            }
        }
        for i in unkeyedIndex..<existingUnkeyed.count {
            if let nodeID = existingUnkeyed[i].stableNodeID {
                removals.append(nodeID)
            }
        }
        if !removals.isEmpty {
            parentFiber.pendingRemovals = removals
            parentFiber.isDirty = true
            parentFiber.propagateDirtyToAncestors()
        }
    }

    // MARK: - Fiber Creation and Reconciliation

    /// Creates a new fiber from a VNode.
    private func createFiber(from vnode: VNode, parent: Fiber?, path: String) -> Fiber {
        let tag = fiberTag(for: vnode.type)
        let typeName = viewTypeName(for: vnode.type)
        let fiberID = FiberID(path: path)

        let fiber = Fiber(
            id: fiberID,
            tag: tag,
            viewTypeName: typeName,
            key: vnode.key,
            elementDesc: vnode
        )
        fiber.stableNodeID = vnode.id
        fiber.isDirty = true
        return fiber
    }

    /// Reconciles an existing fiber with a new VNode.
    ///
    /// If the type and key match, reuses the fiber and updates its element description.
    /// Otherwise creates a new fiber and links the old one as an alternate.
    private func reconcileFiber(existing: Fiber, with vnode: VNode, path: String) -> Fiber {
        let newTag = fiberTag(for: vnode.type)
        let canReuse = existing.tag == newTag && existing.key == vnode.key

        if canReuse {
            let oldDesc = existing.elementDesc

            // Snapshot old state into alternate so ReconcilePass can diff
            // old vs new and generate .updateProps instead of .insert
            let snapshot = Fiber(
                id: existing.id,
                tag: existing.tag,
                viewTypeName: existing.viewTypeName,
                key: existing.key,
                elementDesc: oldDesc
            )
            snapshot.stableNodeID = existing.stableNodeID
            existing.alternate = snapshot

            existing.elementDesc = vnode
            existing.stableNodeID = vnode.id

            // Mark dirty only if element description actually changed
            if oldDesc != vnode {
                existing.isDirty = true
                existing.propagateDirtyToAncestors()
            }

            // Reconcile children
            if !vnode.children.isEmpty || existing.child != nil {
                reconcileChildren(of: existing, newChildren: vnode.children, pathPrefix: path)
            }

            return existing
        } else {
            // Type/key mismatch — create replacement, link old as alternate
            let newFiber = createFiber(from: vnode, parent: existing.parent, path: path)
            newFiber.alternate = existing

            if !vnode.children.isEmpty {
                buildChildren(for: newFiber, from: vnode.children, pathPrefix: path)
            }

            return newFiber
        }
    }

    // MARK: - Helpers

    private func fiberTag(for nodeType: NodeType) -> FiberTag {
        switch nodeType {
        case .element: return .host
        case .text: return .text
        case .component: return .composite
        case .fragment: return .fragment
        }
    }

    private func viewTypeName(for nodeType: NodeType) -> String {
        switch nodeType {
        case .element(let tag): return tag
        case .text(let content): return "Text(\"\(content.prefix(20))\")"
        case .component: return "Component"
        case .fragment: return "Fragment"
        }
    }
}
