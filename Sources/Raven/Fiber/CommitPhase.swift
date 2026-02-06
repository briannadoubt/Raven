import Foundation

/// The commit phase applies collected mutations to the platform renderer
/// and swaps the work-in-progress tree to become the current tree.
@MainActor
public enum CommitPhase {
    /// Commits the work-in-progress tree by applying mutations and swapping trees.
    ///
    /// - Parameters:
    ///   - mutations: The mutations collected during reconciliation
    ///   - wipRoot: The work-in-progress root fiber
    ///   - currentRoot: The current root fiber (if any)
    ///   - renderer: The platform renderer to apply changes to
    /// - Returns: The new current root (the former WIP root)
    public static func commit(
        mutations: [FiberMutation],
        wipRoot: Fiber,
        currentRoot: Fiber?,
        renderer: PlatformRenderer
    ) -> Fiber {
        // Apply mutations to the platform renderer
        if !mutations.isEmpty {
            let patches = mutations.map { $0.toPatch() }
            renderer.applyPatches(patches)
        }

        // Clear dirty flags on the WIP tree
        wipRoot.clearDirtyFlagsRecursive()

        // Link alternates between the new tree (wipRoot) and old tree (currentRoot)
        if let currentRoot {
            linkAlternates(newRoot: wipRoot, oldRoot: currentRoot)
        } else {
            // First render: WIP has no alternate yet
            clearAlternates(fiber: wipRoot)
        }

        // The WIP tree becomes the new current tree
        return wipRoot
    }

    /// Links alternate pointers between corresponding fibers in the new and old trees.
    ///
    /// This sets up the dual-tree structure for the next reconciliation cycle:
    /// - Each fiber in the new tree gets its alternate set to the corresponding old fiber
    /// - Each fiber in the old tree gets its alternate set to the corresponding new fiber
    private static func linkAlternates(newRoot: Fiber, oldRoot: Fiber) {
        // Link the roots
        newRoot.alternate = oldRoot
        oldRoot.alternate = newRoot

        // Recursively link children
        linkAlternatesRecursive(newFiber: newRoot, oldFiber: oldRoot)
    }

    /// Recursively links alternates between corresponding child fibers.
    private static func linkAlternatesRecursive(newFiber: Fiber, oldFiber: Fiber) {
        let newChildren = newFiber.children
        let oldChildren = oldFiber.children

        // Link corresponding children by index
        // Note: The reconciliation phase should have already matched up corresponding nodes
        let count = min(newChildren.count, oldChildren.count)
        for i in 0..<count {
            let newChild = newChildren[i]
            let oldChild = oldChildren[i]

            newChild.alternate = oldChild
            oldChild.alternate = newChild

            // Recurse into children
            linkAlternatesRecursive(newFiber: newChild, oldFiber: oldChild)
        }

        // New children beyond the old count have no alternates
        for i in count..<newChildren.count {
            clearAlternates(fiber: newChildren[i])
        }
    }

    /// Clears alternate pointers for a fiber and its descendants (used for new fibers).
    private static func clearAlternates(fiber: Fiber) {
        fiber.alternate = nil
        for child in fiber.children {
            clearAlternates(fiber: child)
        }
    }
}
