import Testing
import Raven

@MainActor
@Suite("Fiber Tree Tests")
struct FiberTreeTests {

    // MARK: - Fiber Tree Construction

    @Test("Fiber construction with basic properties")
    func fiberConstruction() {
        let id = FiberID(path: "root/test")
        let fiber = Fiber(
            id: id,
            tag: .composite,
            viewTypeName: "TestView",
            key: "testKey"
        )

        #expect(fiber.id == id)
        #expect(fiber.tag == .composite)
        #expect(fiber.viewTypeName == "TestView")
        #expect(fiber.key == "testKey")
        #expect(fiber.parent == nil)
        #expect(fiber.child == nil)
        #expect(fiber.sibling == nil)
        #expect(fiber.alternate == nil)
        #expect(fiber.isDirty == true)
        #expect(fiber.hasDirtyDescendant == false)
    }

    @Test("Fiber with different tags")
    func fiberWithDifferentTags() {
        let hostFiber = Fiber(id: FiberID(path: "host"), tag: .host, viewTypeName: "div")
        #expect(hostFiber.tag == .host)

        let textFiber = Fiber(id: FiberID(path: "text"), tag: .text, viewTypeName: "Text")
        #expect(textFiber.tag == .text)

        let fragmentFiber = Fiber(id: FiberID(path: "fragment"), tag: .fragment, viewTypeName: "Fragment")
        #expect(fragmentFiber.tag == .fragment)

        let rootFiber = Fiber(id: FiberID(path: "root"), tag: .root, viewTypeName: "Root")
        #expect(rootFiber.tag == .root)
    }

    // MARK: - Parent/Child/Sibling Navigation

    @Test("appendChild establishes parent-child relationship")
    func appendChildRelationship() {
        let parent = Fiber(id: FiberID(path: "parent"), tag: .composite, viewTypeName: "Parent")
        let child1 = Fiber(id: FiberID(path: "parent/child1"), tag: .composite, viewTypeName: "Child1")
        let child2 = Fiber(id: FiberID(path: "parent/child2"), tag: .composite, viewTypeName: "Child2")

        parent.appendChild(child1)

        #expect(parent.child === child1)
        #expect(child1.parent === parent)
        #expect(child1.sibling == nil)

        parent.appendChild(child2)

        #expect(parent.child === child1)
        #expect(child1.sibling === child2)
        #expect(child2.parent === parent)
        #expect(child2.sibling == nil)
    }

    @Test("children array returns all children")
    func childrenArray() {
        let parent = Fiber(id: FiberID(path: "parent"), tag: .composite, viewTypeName: "Parent")
        let child1 = Fiber(id: FiberID(path: "parent/child1"), tag: .composite, viewTypeName: "Child1")
        let child2 = Fiber(id: FiberID(path: "parent/child2"), tag: .composite, viewTypeName: "Child2")
        let child3 = Fiber(id: FiberID(path: "parent/child3"), tag: .composite, viewTypeName: "Child3")

        parent.appendChild(child1)
        parent.appendChild(child2)
        parent.appendChild(child3)

        let children = parent.children

        #expect(children.count == 3)
        #expect(children[0] === child1)
        #expect(children[1] === child2)
        #expect(children[2] === child3)
    }

    @Test("removeAllChildren clears child list")
    func removeAllChildren() {
        let parent = Fiber(id: FiberID(path: "parent"), tag: .composite, viewTypeName: "Parent")
        let child1 = Fiber(id: FiberID(path: "parent/child1"), tag: .composite, viewTypeName: "Child1")
        let child2 = Fiber(id: FiberID(path: "parent/child2"), tag: .composite, viewTypeName: "Child2")

        parent.appendChild(child1)
        parent.appendChild(child2)

        #expect(parent.children.count == 2)

        parent.removeAllChildren()

        #expect(parent.child == nil)
        #expect(parent.children.isEmpty)
    }

    @Test("sibling chain navigation")
    func siblingChainNavigation() {
        let parent = Fiber(id: FiberID(path: "parent"), tag: .composite, viewTypeName: "Parent")
        let child1 = Fiber(id: FiberID(path: "parent/child1"), tag: .composite, viewTypeName: "Child1")
        let child2 = Fiber(id: FiberID(path: "parent/child2"), tag: .composite, viewTypeName: "Child2")
        let child3 = Fiber(id: FiberID(path: "parent/child3"), tag: .composite, viewTypeName: "Child3")

        parent.appendChild(child1)
        parent.appendChild(child2)
        parent.appendChild(child3)

        #expect(child1.sibling === child2)
        #expect(child2.sibling === child3)
        #expect(child3.sibling == nil)
    }

    // MARK: - Alternate Linking

    @Test("alternate pointer linking")
    func alternatePointerLinking() {
        let fiber1 = Fiber(id: FiberID(path: "test"), tag: .composite, viewTypeName: "TestView")
        let fiber2 = Fiber(id: FiberID(path: "test"), tag: .composite, viewTypeName: "TestView")

        #expect(fiber1.alternate == nil)
        #expect(fiber2.alternate == nil)

        fiber1.alternate = fiber2
        fiber2.alternate = fiber1

        #expect(fiber1.alternate === fiber2)
        #expect(fiber2.alternate === fiber1)
    }

    // MARK: - Dirty Flag Propagation

    @Test("markDirty sets isDirty flag")
    func markDirtySetsFlag() {
        let fiber = Fiber(id: FiberID(path: "test"), tag: .composite, viewTypeName: "TestView")
        fiber.isDirty = false

        fiber.markDirty()

        #expect(fiber.isDirty == true)
    }

    @Test("markDirty propagates hasDirtyDescendant to parent")
    func markDirtyPropagatesUpward() {
        let root = Fiber(id: FiberID(path: "root"), tag: .root, viewTypeName: "Root")
        let parent = Fiber(id: FiberID(path: "root/parent"), tag: .composite, viewTypeName: "Parent")
        let child = Fiber(id: FiberID(path: "root/parent/child"), tag: .composite, viewTypeName: "Child")

        root.appendChild(parent)
        parent.appendChild(child)

        root.isDirty = false
        root.hasDirtyDescendant = false
        parent.isDirty = false
        parent.hasDirtyDescendant = false

        child.markDirty()

        #expect(child.isDirty == true)
        #expect(parent.hasDirtyDescendant == true)
        #expect(root.hasDirtyDescendant == true)
    }

    @Test("markDirty propagates through multiple levels")
    func markDirtyMultipleLevels() {
        let root = Fiber(id: FiberID(path: "root"), tag: .root, viewTypeName: "Root")
        let level1 = Fiber(id: FiberID(path: "root/level1"), tag: .composite, viewTypeName: "Level1")
        let level2 = Fiber(id: FiberID(path: "root/level1/level2"), tag: .composite, viewTypeName: "Level2")
        let level3 = Fiber(id: FiberID(path: "root/level1/level2/level3"), tag: .composite, viewTypeName: "Level3")

        root.appendChild(level1)
        level1.appendChild(level2)
        level2.appendChild(level3)

        root.hasDirtyDescendant = false
        level1.hasDirtyDescendant = false
        level2.hasDirtyDescendant = false

        level3.markDirty()

        #expect(level3.isDirty == true)
        #expect(level2.hasDirtyDescendant == true)
        #expect(level1.hasDirtyDescendant == true)
        #expect(root.hasDirtyDescendant == true)
    }

    @Test("clearDirtyFlags clears local flags")
    func clearDirtyFlagsLocal() {
        let fiber = Fiber(id: FiberID(path: "test"), tag: .composite, viewTypeName: "TestView")
        fiber.isDirty = true
        fiber.hasDirtyDescendant = true

        fiber.clearDirtyFlags()

        #expect(fiber.isDirty == false)
        #expect(fiber.hasDirtyDescendant == false)
    }

    // MARK: - Clear Dirty Flags Recursive

    @Test("clearDirtyFlagsRecursive clears entire subtree")
    func clearDirtyFlagsRecursive() {
        let root = Fiber(id: FiberID(path: "root"), tag: .root, viewTypeName: "Root")
        let child1 = Fiber(id: FiberID(path: "root/child1"), tag: .composite, viewTypeName: "Child1")
        let child2 = Fiber(id: FiberID(path: "root/child2"), tag: .composite, viewTypeName: "Child2")
        let grandchild = Fiber(id: FiberID(path: "root/child1/grandchild"), tag: .composite, viewTypeName: "Grandchild")

        root.appendChild(child1)
        root.appendChild(child2)
        child1.appendChild(grandchild)

        root.isDirty = true
        root.hasDirtyDescendant = true
        child1.isDirty = true
        child1.hasDirtyDescendant = true
        child2.isDirty = true
        grandchild.isDirty = true

        root.clearDirtyFlagsRecursive()

        #expect(root.isDirty == false)
        #expect(root.hasDirtyDescendant == false)
        #expect(child1.isDirty == false)
        #expect(child1.hasDirtyDescendant == false)
        #expect(child2.isDirty == false)
        #expect(grandchild.isDirty == false)
    }

    // MARK: - Next Fiber Traversal

    @Test("nextFiber traverses depth-first")
    func nextFiberDepthFirst() {
        let root = Fiber(id: FiberID(path: "root"), tag: .root, viewTypeName: "Root")
        let child1 = Fiber(id: FiberID(path: "root/child1"), tag: .composite, viewTypeName: "Child1")
        let child2 = Fiber(id: FiberID(path: "root/child2"), tag: .composite, viewTypeName: "Child2")
        let grandchild = Fiber(id: FiberID(path: "root/child1/grandchild"), tag: .composite, viewTypeName: "Grandchild")

        root.appendChild(child1)
        root.appendChild(child2)
        child1.appendChild(grandchild)

        // Depth-first order: root -> child1 -> grandchild -> child2
        let next1 = root.nextFiber(root: root)
        #expect(next1 === child1)

        let next2 = next1?.nextFiber(root: root)
        #expect(next2 === grandchild)

        let next3 = next2?.nextFiber(root: root)
        #expect(next3 === child2)

        let next4 = next3?.nextFiber(root: root)
        #expect(next4 == nil)
    }

    @Test("nextFiber returns nil at end of tree")
    func nextFiberAtEnd() {
        let root = Fiber(id: FiberID(path: "root"), tag: .root, viewTypeName: "Root")
        let child = Fiber(id: FiberID(path: "root/child"), tag: .composite, viewTypeName: "Child")

        root.appendChild(child)

        let next = child.nextFiber(root: root)
        #expect(next == nil)
    }

    @Test("nextFiber handles complex tree structure")
    func nextFiberComplexTree() {
        //       root
        //      /    \
        //    A       B
        //   / \       \
        //  C   D       E
        let root = Fiber(id: FiberID(path: "root"), tag: .root, viewTypeName: "Root")
        let a = Fiber(id: FiberID(path: "root/a"), tag: .composite, viewTypeName: "A")
        let b = Fiber(id: FiberID(path: "root/b"), tag: .composite, viewTypeName: "B")
        let c = Fiber(id: FiberID(path: "root/a/c"), tag: .composite, viewTypeName: "C")
        let d = Fiber(id: FiberID(path: "root/a/d"), tag: .composite, viewTypeName: "D")
        let e = Fiber(id: FiberID(path: "root/b/e"), tag: .composite, viewTypeName: "E")

        root.appendChild(a)
        root.appendChild(b)
        a.appendChild(c)
        a.appendChild(d)
        b.appendChild(e)

        // Expected order: root -> A -> C -> D -> B -> E
        var current: Fiber? = root
        let expectedOrder = [root, a, c, d, b, e]

        for expected in expectedOrder {
            #expect(current === expected)
            current = current?.nextFiber(root: root)
        }

        #expect(current == nil)
    }

    // MARK: - FiberTreeBuilder buildTree

    @Test("buildTree creates fiber from simple VNode")
    func buildTreeSimpleVNode() {
        let builder = FiberTreeBuilder()
        let vnode = VNode.element("div", props: [:], children: [], key: "testKey")

        let fiber = builder.buildTree(from: vnode, parentFiber: nil, basePath: "root")

        #expect(fiber.tag == .host)
        #expect(fiber.viewTypeName == "div")
        #expect(fiber.key == "testKey")
        #expect(fiber.elementDesc == vnode)
        #expect(fiber.id.path == "root")
    }

    @Test("buildTree creates text fiber from text VNode")
    func buildTreeTextVNode() {
        let builder = FiberTreeBuilder()
        let vnode = VNode.text("Hello World")

        let fiber = builder.buildTree(from: vnode, parentFiber: nil, basePath: "root")

        #expect(fiber.tag == .text)
        #expect(fiber.viewTypeName.hasPrefix("Text("))
        #expect(fiber.elementDesc == vnode)
    }

    @Test("buildTree creates fragment fiber from fragment VNode")
    func buildTreeFragmentVNode() {
        let builder = FiberTreeBuilder()
        let vnode = VNode.fragment(children: [])

        let fiber = builder.buildTree(from: vnode, parentFiber: nil, basePath: "root")

        #expect(fiber.tag == .fragment)
        #expect(fiber.viewTypeName == "Fragment")
    }

    @Test("buildTree creates nested fiber tree")
    func buildTreeNestedStructure() {
        let builder = FiberTreeBuilder()

        let child1 = VNode.element("span", children: [], key: "span1")
        let child2 = VNode.text("Hello")
        let vnode = VNode.element("div", children: [child1, child2], key: "parent")

        let fiber = builder.buildTree(from: vnode, parentFiber: nil, basePath: "root")

        #expect(fiber.viewTypeName == "div")
        #expect(fiber.key == "parent")

        let children = fiber.children
        #expect(children.count == 2)
        #expect(children[0].viewTypeName == "span")
        #expect(children[0].key == "span1")
        #expect(children[1].viewTypeName.hasPrefix("Text("))
    }

    @Test("buildTree maintains parent pointers")
    func buildTreeParentPointers() {
        let builder = FiberTreeBuilder()

        let child = VNode.element("span")
        let vnode = VNode.element("div", children: [child])

        let fiber = builder.buildTree(from: vnode, parentFiber: nil, basePath: "root")

        let childFiber = fiber.children.first
        #expect(childFiber?.parent === fiber)
    }

    @Test("buildTree creates deep hierarchy")
    func buildTreeDeepHierarchy() {
        let builder = FiberTreeBuilder()

        let level3 = VNode.text("Deep text")
        let level2 = VNode.element("p", children: [level3])
        let level1 = VNode.element("div", children: [level2])
        let root = VNode.element("section", children: [level1])

        let fiber = builder.buildTree(from: root, parentFiber: nil, basePath: "root")

        #expect(fiber.viewTypeName == "section")

        let level1Fiber = fiber.children.first
        #expect(level1Fiber?.viewTypeName == "div")

        let level2Fiber = level1Fiber?.children.first
        #expect(level2Fiber?.viewTypeName == "p")

        let level3Fiber = level2Fiber?.children.first
        #expect(level3Fiber?.viewTypeName.hasPrefix("Text(") == true)
    }

    // MARK: - FiberTreeBuilder reconcileChildren

    @Test("reconcileChildren creates new children from VNodes")
    func reconcileChildrenCreatesNew() {
        let builder = FiberTreeBuilder()
        let parent = Fiber(id: FiberID(path: "root"), tag: .composite, viewTypeName: "Parent")

        let child1 = VNode.element("div", key: "child1")
        let child2 = VNode.element("span", key: "child2")

        builder.reconcileChildren(of: parent, newChildren: [child1, child2], pathPrefix: "root")

        let children = parent.children
        #expect(children.count == 2)
        #expect(children[0].viewTypeName == "div")
        #expect(children[0].key == "child1")
        #expect(children[1].viewTypeName == "span")
        #expect(children[1].key == "child2")
    }

    @Test("reconcileChildren matches by key")
    func reconcileChildrenKeyedMatching() {
        let builder = FiberTreeBuilder()
        let parent = Fiber(id: FiberID(path: "root"), tag: .composite, viewTypeName: "Parent")

        // Initial children
        let initialChild1 = VNode.element("div", key: "a")
        let initialChild2 = VNode.element("span", key: "b")
        builder.reconcileChildren(of: parent, newChildren: [initialChild1, initialChild2], pathPrefix: "root")

        let oldChildren = parent.children
        #expect(oldChildren.count == 2)

        // Reorder children by key
        let newChild1 = VNode.element("span", key: "b")
        let newChild2 = VNode.element("div", key: "a")
        builder.reconcileChildren(of: parent, newChildren: [newChild1, newChild2], pathPrefix: "root")

        let newChildren = parent.children
        #expect(newChildren.count == 2)
        #expect(newChildren[0].key == "b")
        #expect(newChildren[1].key == "a")
    }

    @Test("reconcileChildren positional matching when no keys")
    func reconcileChildrenPositionalMatching() {
        let builder = FiberTreeBuilder()
        let parent = Fiber(id: FiberID(path: "root"), tag: .composite, viewTypeName: "Parent")

        // Children without keys
        let child1 = VNode.element("div")
        let child2 = VNode.element("span")

        builder.reconcileChildren(of: parent, newChildren: [child1, child2], pathPrefix: "root")

        let children = parent.children
        #expect(children.count == 2)
        #expect(children[0].viewTypeName == "div")
        #expect(children[1].viewTypeName == "span")
    }

    @Test("reconcileChildren removes excess children")
    func reconcileChildrenRemovesExcess() {
        let builder = FiberTreeBuilder()
        let parent = Fiber(id: FiberID(path: "root"), tag: .composite, viewTypeName: "Parent")

        // Start with 3 children
        let initial = [
            VNode.element("div", key: "a"),
            VNode.element("span", key: "b"),
            VNode.element("p", key: "c")
        ]
        builder.reconcileChildren(of: parent, newChildren: initial, pathPrefix: "root")
        #expect(parent.children.count == 3)

        // Reconcile with only 1 child
        let updated = [VNode.element("div", key: "a")]
        builder.reconcileChildren(of: parent, newChildren: updated, pathPrefix: "root")

        #expect(parent.children.count == 1)
        #expect(parent.children[0].key == "a")
    }

    @Test("reconcileChildren adds new children")
    func reconcileChildrenAddsNew() {
        let builder = FiberTreeBuilder()
        let parent = Fiber(id: FiberID(path: "root"), tag: .composite, viewTypeName: "Parent")

        // Start with 1 child
        let initial = [VNode.element("div", key: "a")]
        builder.reconcileChildren(of: parent, newChildren: initial, pathPrefix: "root")
        #expect(parent.children.count == 1)

        // Add 2 more children
        let updated = [
            VNode.element("div", key: "a"),
            VNode.element("span", key: "b"),
            VNode.element("p", key: "c")
        ]
        builder.reconcileChildren(of: parent, newChildren: updated, pathPrefix: "root")

        #expect(parent.children.count == 3)
        #expect(parent.children[0].key == "a")
        #expect(parent.children[1].key == "b")
        #expect(parent.children[2].key == "c")
    }

    @Test("reconcileChildren handles empty children list")
    func reconcileChildrenEmptyList() {
        let builder = FiberTreeBuilder()
        let parent = Fiber(id: FiberID(path: "root"), tag: .composite, viewTypeName: "Parent")

        // Start with children
        let initial = [VNode.element("div"), VNode.element("span")]
        builder.reconcileChildren(of: parent, newChildren: initial, pathPrefix: "root")
        #expect(parent.children.count == 2)

        // Reconcile with empty list
        builder.reconcileChildren(of: parent, newChildren: [], pathPrefix: "root")

        #expect(parent.children.isEmpty)
    }

    @Test("reconcileChildren mixed keyed and unkeyed children")
    func reconcileChildrenMixedKeys() {
        let builder = FiberTreeBuilder()
        let parent = Fiber(id: FiberID(path: "root"), tag: .composite, viewTypeName: "Parent")

        let children = [
            VNode.element("div", key: "a"),
            VNode.element("span"),
            VNode.element("p", key: "c")
        ]

        builder.reconcileChildren(of: parent, newChildren: children, pathPrefix: "root")

        let result = parent.children
        #expect(result.count == 3)
        #expect(result[0].key == "a")
        #expect(result[1].key == nil)
        #expect(result[2].key == "c")
    }

    // MARK: - FiberID Tests

    @Test("FiberID child creates new ID with appended path")
    func fiberIDChild() {
        let parentID = FiberID(path: "root.parent")
        let childID = parentID.child("child")

        #expect(childID.path == "root.parent.child")
    }

    @Test("FiberID equality based on path")
    func fiberIDEquality() {
        let id1 = FiberID(path: "root/test")
        let id2 = FiberID(path: "root/test")
        let id3 = FiberID(path: "root/other")

        #expect(id1 == id2)
        #expect(id1 != id3)
    }

    @Test("FiberID hashing")
    func fiberIDHashing() {
        let id1 = FiberID(path: "root/test")
        let id2 = FiberID(path: "root/test")

        var set = Set<FiberID>()
        set.insert(id1)
        set.insert(id2)

        #expect(set.count == 1)
    }
}
