import Foundation

/// A mutable node in the fiber tree.
///
/// Each `Fiber` wraps a VNode (the element description) and adds:
/// - Parent/child/sibling pointers for tree traversal
/// - An `alternate` pointer for dual-tree reconciliation
/// - Dirty flags for skip-clean-subtree optimization
/// - Identity (FiberID) for registry lookups
///
/// Fibers are always accessed on `@MainActor`. They form a persistent
/// mutable tree that is reused across renders — only dirty fibers are
/// re-evaluated.
@MainActor
public final class Fiber: Sendable {

    // MARK: - Identity

    /// Stable identity derived from position in the view tree.
    public let id: FiberID

    /// What kind of fiber this is (host, composite, text, fragment, root).
    public let tag: FiberTag

    /// Human-readable name of the view type (e.g. `"VStack"`, `"Button"`).
    public let viewTypeName: String

    /// Optional key for keyed reconciliation of siblings.
    public var key: String?

    // MARK: - Tree Pointers

    /// Parent fiber (nil for the root).
    public weak var parent: Fiber?

    /// First child fiber.
    public var child: Fiber?

    /// Next sibling fiber.
    public var sibling: Fiber?

    // MARK: - Dual-Tree (Alternate)

    /// Pointer to this fiber's counterpart in the other tree.
    ///
    /// During reconciliation the "work-in-progress" (WIP) tree is built by
    /// cloning fibers from the "current" tree via their alternates. After
    /// commit, the WIP root becomes the new current root and the alternates
    /// are swapped.
    public var alternate: Fiber?

    // MARK: - Element Description

    /// The VNode produced by this fiber's view (set after evaluation).
    public var elementDesc: VNode?

    /// Snapshot of the view for equality-based bailout.
    public var viewSnapshot: AnyViewSnapshot?

    // MARK: - Dirty Tracking

    /// Whether this fiber's own state has changed and needs re-evaluation.
    public var isDirty: Bool = true

    /// Whether any descendant of this fiber is dirty.
    /// Used to skip entire clean subtrees during reconciliation.
    public var hasDirtyDescendant: Bool = false

    // MARK: - Pending Removals

    /// NodeIDs of child fibers that were present last render but not matched
    /// during reconciliation.  `ReconcilePass` drains this list to emit
    /// `.remove` mutations.
    public var pendingRemovals: [NodeID] = []

    // MARK: - Stable Node ID

    /// The `NodeID` assigned to this fiber's DOM element (matches the VNode's
    /// stable ID). Used for patch/mutation targeting.
    public var stableNodeID: NodeID?

    // MARK: - Initialization

    /// Create a new fiber.
    ///
    /// - Parameters:
    ///   - id: Stable identity from view-tree path.
    ///   - tag: The fiber classification.
    ///   - viewTypeName: Human-readable view type name.
    ///   - key: Optional reconciliation key.
    ///   - elementDesc: The initial VNode (nil for unbuilt fibers).
    public init(
        id: FiberID,
        tag: FiberTag,
        viewTypeName: String,
        key: String? = nil,
        elementDesc: VNode? = nil
    ) {
        self.id = id
        self.tag = tag
        self.viewTypeName = viewTypeName
        self.key = key
        self.elementDesc = elementDesc
    }

    // MARK: - Tree Navigation

    /// All direct children as an array (walks child → sibling chain).
    public var children: [Fiber] {
        var result: [Fiber] = []
        var current = child
        while let c = current {
            result.append(c)
            current = c.sibling
        }
        return result
    }

    /// Append a child fiber.
    ///
    /// Sets parent pointer and inserts at the end of the sibling chain.
    public func appendChild(_ newChild: Fiber) {
        newChild.parent = self
        if child == nil {
            child = newChild
        } else {
            var last = child!
            while let next = last.sibling {
                last = next
            }
            last.sibling = newChild
        }
    }

    /// Remove all children (for rebuilding during reconciliation).
    public func removeAllChildren() {
        var current = child
        while let c = current {
            c.parent = nil
            let next = c.sibling
            c.sibling = nil
            current = next
        }
        child = nil
    }

    // MARK: - Dirty Propagation

    /// Mark this fiber as dirty and propagate `hasDirtyDescendant` up to root.
    public func markDirty() {
        isDirty = true
        propagateDirtyToAncestors()
    }

    /// Walk up to root, setting `hasDirtyDescendant` on each ancestor.
    public func propagateDirtyToAncestors() {
        var ancestor = parent
        while let a = ancestor {
            if a.hasDirtyDescendant { break } // already propagated
            a.hasDirtyDescendant = true
            ancestor = a.parent
        }
    }

    /// Clear dirty flags after a successful commit.
    public func clearDirtyFlags() {
        isDirty = false
        hasDirtyDescendant = false
    }

    /// Recursively clear dirty flags on this fiber and all descendants.
    public func clearDirtyFlagsRecursive() {
        clearDirtyFlags()
        for child in children {
            child.clearDirtyFlagsRecursive()
        }
    }

    // MARK: - Depth-First Traversal

    /// Returns the next fiber in depth-first order, scoped to `root`.
    ///
    /// Visits: child → sibling → uncle (parent's sibling), stopping when
    /// we've walked back up to `root`.
    public func nextFiber(root: Fiber) -> Fiber? {
        // Try child first
        if let c = child {
            return c
        }

        // Walk up looking for a sibling
        var current: Fiber? = self
        while let c = current {
            if c === root { return nil }
            if let s = c.sibling { return s }
            current = c.parent
        }
        return nil
    }
}
