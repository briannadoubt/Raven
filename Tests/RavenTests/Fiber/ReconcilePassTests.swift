import Testing
import Raven

@MainActor
@Suite("ReconcilePass Tests")
struct ReconcilePassTests {

    // MARK: - Helpers

    /// Create a fiber with the given parameters and a stable node ID.
    private func makeFiber(
        path: String,
        tag: FiberTag = .host,
        viewTypeName: String = "div",
        key: String? = nil,
        elementDesc: VNode? = nil,
        isDirty: Bool = true
    ) -> Fiber {
        let fiber = Fiber(
            id: FiberID(path: path),
            tag: tag,
            viewTypeName: viewTypeName,
            key: key,
            elementDesc: elementDesc
        )
        fiber.stableNodeID = NodeID(stablePath: path)
        fiber.isDirty = isDirty
        return fiber
    }

    // MARK: - Skip Clean Subtrees

    @Test("Skip clean subtrees - only dirty leaf produces mutations")
    func skipCleanSubtrees() {
        // Build tree: root -> child -> dirtyLeaf
        let root = makeFiber(path: "root", isDirty: false)
        root.hasDirtyDescendant = true

        let child = makeFiber(path: "root.0", isDirty: false)
        child.hasDirtyDescendant = true
        root.appendChild(child)

        let dirtyLeaf = makeFiber(
            path: "root.0.0",
            elementDesc: VNode.element("span"),
            isDirty: true
        )
        child.appendChild(dirtyLeaf)

        // dirtyLeaf has no alternate → insert mutation
        let reconciler = ReconcilePass()
        let result = reconciler.run(root: root)

        guard case .complete(let mutations) = result else {
            Issue.record("Expected complete result")
            return
        }

        // Only the dirty leaf should produce a mutation (insert, since no alternate)
        #expect(mutations.count == 1)
        if case .insert(_, _, _) = mutations[0] {
            // expected
        } else {
            Issue.record("Expected insert mutation, got \(mutations[0])")
        }
    }

    // MARK: - All-Dirty Tree

    @Test("All-dirty tree produces mutations for all fibers")
    func allDirtyTree() {
        let root = makeFiber(
            path: "root",
            elementDesc: VNode.element("div"),
            isDirty: true
        )
        let child1 = makeFiber(
            path: "root.0",
            viewTypeName: "span",
            elementDesc: VNode.element("span"),
            isDirty: true
        )
        let child2 = makeFiber(
            path: "root.1",
            viewTypeName: "p",
            elementDesc: VNode.element("p"),
            isDirty: true
        )
        root.appendChild(child1)
        root.appendChild(child2)

        let reconciler = ReconcilePass()
        let result = reconciler.run(root: root)

        guard case .complete(let mutations) = result else {
            Issue.record("Expected complete result")
            return
        }

        // All 3 fibers dirty, all produce mutations
        #expect(mutations.count >= 2) // root has no parent so no insert, children do
    }

    // MARK: - New Insertion

    @Test("New insertion without alternate produces insert mutation")
    func newInsertion() {
        let parent = makeFiber(path: "root", isDirty: false)
        parent.hasDirtyDescendant = true

        let newChild = makeFiber(
            path: "root.0",
            viewTypeName: "button",
            elementDesc: VNode.element("button", props: ["class": .attribute(name: "class", value: "btn")]),
            isDirty: true
        )
        newChild.alternate = nil
        parent.appendChild(newChild)

        let reconciler = ReconcilePass()
        let result = reconciler.run(root: parent)

        guard case .complete(let mutations) = result else {
            Issue.record("Expected complete result")
            return
        }

        #expect(mutations.count == 1)
        if case .insert(let parentID, _, let index) = mutations[0] {
            #expect(parentID == NodeID(stablePath: "root"))
            #expect(index == 0)
        } else {
            Issue.record("Expected insert mutation")
        }
    }

    // MARK: - Property Change

    @Test("Property change produces updateProps mutation")
    func propertyChange() {
        let oldVNode = VNode.element("div", props: ["class": .attribute(name: "class", value: "old")])
        let newVNode = VNode.element("div", props: ["class": .attribute(name: "class", value: "new")])

        let alternate = makeFiber(path: "root", elementDesc: oldVNode, isDirty: false)

        let fiber = makeFiber(path: "root", elementDesc: newVNode, isDirty: true)
        fiber.alternate = alternate

        let reconciler = ReconcilePass()
        let result = reconciler.run(root: fiber)

        guard case .complete(let mutations) = result else {
            Issue.record("Expected complete result")
            return
        }

        #expect(mutations.count == 1)
        if case .updateProps(let nodeID, let patches) = mutations[0] {
            #expect(nodeID == NodeID(stablePath: "root"))
            #expect(!patches.isEmpty)
        } else {
            Issue.record("Expected updateProps mutation, got \(mutations[0])")
        }
    }

    // MARK: - Type Change

    @Test("Type change produces replace mutation")
    func typeChange() {
        let oldVNode = VNode.element("div")
        let newVNode = VNode.element("span")

        let alternate = makeFiber(path: "root", elementDesc: oldVNode, isDirty: false)

        let fiber = makeFiber(path: "root", elementDesc: newVNode, isDirty: true)
        fiber.alternate = alternate

        let reconciler = ReconcilePass()
        let result = reconciler.run(root: fiber)

        guard case .complete(let mutations) = result else {
            Issue.record("Expected complete result")
            return
        }

        #expect(mutations.count == 1)
        if case .replace(let oldID, _) = mutations[0] {
            #expect(oldID == NodeID(stablePath: "root"))
        } else {
            Issue.record("Expected replace mutation, got \(mutations[0])")
        }
    }

    // MARK: - Removal

    @Test("Removal with nil elementDesc produces remove mutation")
    func removal() {
        let fiber = makeFiber(path: "root", elementDesc: nil, isDirty: true)

        let reconciler = ReconcilePass()
        let result = reconciler.run(root: fiber)

        guard case .complete(let mutations) = result else {
            Issue.record("Expected complete result")
            return
        }

        #expect(mutations.count == 1)
        if case .remove(let nodeID) = mutations[0] {
            #expect(nodeID == NodeID(stablePath: "root"))
        } else {
            Issue.record("Expected remove mutation, got \(mutations[0])")
        }
    }

    // MARK: - Work Budget / Pause

    @Test("Small work budget produces paused result")
    func workBudgetPause() {
        let root = makeFiber(
            path: "root",
            elementDesc: VNode.element("div"),
            isDirty: true
        )
        let child1 = makeFiber(
            path: "root.0",
            elementDesc: VNode.element("span"),
            isDirty: true
        )
        let child2 = makeFiber(
            path: "root.1",
            elementDesc: VNode.element("p"),
            isDirty: true
        )
        let child3 = makeFiber(
            path: "root.2",
            elementDesc: VNode.element("a"),
            isDirty: true
        )
        root.appendChild(child1)
        root.appendChild(child2)
        root.appendChild(child3)

        let reconciler = ReconcilePass()
        let result = reconciler.run(root: root, workBudget: 2)

        guard case .paused(_, let mutations) = result else {
            Issue.record("Expected paused result with small budget")
            return
        }

        #expect(!mutations.isEmpty)
        #expect(mutations.count < 4)
    }

    // MARK: - Resume from Paused

    @Test("Resume from paused completes remaining work")
    func resumeFromPaused() {
        let root = makeFiber(
            path: "root",
            elementDesc: VNode.element("div"),
            isDirty: true
        )
        let child1 = makeFiber(
            path: "root.0",
            elementDesc: VNode.element("span"),
            isDirty: true
        )
        let child2 = makeFiber(
            path: "root.1",
            elementDesc: VNode.element("p"),
            isDirty: true
        )
        let child3 = makeFiber(
            path: "root.2",
            elementDesc: VNode.element("a"),
            isDirty: true
        )
        root.appendChild(child1)
        root.appendChild(child2)
        root.appendChild(child3)

        let reconciler = ReconcilePass()

        // First pass with small budget
        let pausedResult = reconciler.run(root: root, workBudget: 2)

        guard case .paused(let resumeFrom, let initialMutations) = pausedResult else {
            Issue.record("Expected paused result")
            return
        }

        let initialCount = initialMutations.count

        // Resume with unlimited budget
        let finalResult = reconciler.resume(
            from: resumeFrom,
            root: root,
            remainingBudget: .max,
            mutations: initialMutations
        )

        guard case .complete(let allMutations) = finalResult else {
            Issue.record("Expected complete result after resume")
            return
        }

        #expect(allMutations.count > initialCount)
    }
}
