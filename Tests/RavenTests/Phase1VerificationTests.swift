import Testing
@testable import Raven

/// Comprehensive Phase 1 verification tests that validate the entire pipeline
/// from View to VNode.
///
/// These tests verify that:
/// 1. Views can be converted to VNodes correctly
/// 2. VNode creation works as expected
/// 3. VTree operations function properly
/// 4. ViewBuilder constructs work correctly
@MainActor
@Suite struct Phase1VerificationTests {

    // MARK: - Test 1: Basic Text Rendering

    @Test func basicTextRendering() async throws {
        // Create a Text view
        let text = Text("Hello, Raven!")

        // Convert it to VNode
        let vnode = text.toVNode()

        // Verify the VNode structure is correct
        #expect(vnode.isElement(tag: "span"))
        #expect(vnode.textContent == "Hello, Raven!")

        // Verify node ID is generated
        #expect(vnode.id != nil)

        // Verify a single text child
        #expect(vnode.children.count == 1)
        #expect(vnode.children[0].isText)
        #expect(vnode.children[0].textContent == "Hello, Raven!")

        // Verify no properties
        #expect(vnode.props.isEmpty)
    }

    @Test func textWithInterpolation() async throws {
        let name = "Raven"
        let version = 1
        let text = Text("Welcome to \(name) v\(version)")

        let vnode = text.toVNode()

        #expect(vnode.textContent == "Welcome to Raven v1")
    }

    @Test func textFromStringLiteral() async throws {
        let text: Text = "Literal String"
        let vnode = text.toVNode()

        #expect(vnode.textContent == "Literal String")
    }

    // MARK: - Test 2: VNode Creation

    @Test func vNodeTextFactory() async throws {
        let vnode = VNode.text("Test content")

        #expect(vnode.isText)
        #expect(vnode.textContent == "Test content")
        #expect(vnode.children.isEmpty)
        #expect(vnode.props.isEmpty)
        #expect(vnode.key == nil)
    }

    @Test func vNodeTextFactoryWithKey() async throws {
        let vnode = VNode.text("Keyed content", key: "unique-key")

        #expect(vnode.textContent == "Keyed content")
        #expect(vnode.key == "unique-key")
    }

    @Test func vNodeElementFactory() async throws {
        let vnode = VNode.element("div")

        #expect(vnode.isElement(tag: "div"))
        #expect(vnode.elementTag == "div")
        #expect(vnode.children.isEmpty)
        #expect(vnode.props.isEmpty)
    }

    @Test func vNodeElementFactoryWithChildren() async throws {
        let child1 = VNode.text("Child 1")
        let child2 = VNode.text("Child 2")
        let parent = VNode.element("div", children: [child1, child2])

        #expect(parent.children.count == 2)
        #expect(parent.children[0].textContent == "Child 1")
        #expect(parent.children[1].textContent == "Child 2")
    }

    @Test func vNodeElementFactoryWithProperties() async throws {
        let props: [String: VProperty] = [
            "class": .attribute(name: "class", value: "container"),
            "id": .attribute(name: "id", value: "main")
        ]
        let vnode = VNode.element("div", props: props)

        #expect(vnode.props.count == 2)
        #expect(vnode.props["class"] == .attribute(name: "class", value: "container"))
        #expect(vnode.props["id"] == .attribute(name: "id", value: "main"))
    }

    @Test func vNodeComponentFactory() async throws {
        let vnode = VNode.component()

        if case .component = vnode.type {
            // Success
        } else {
            Issue.record("Should be a component node")
        }
    }

    @Test func vNodeFragmentFactory() async throws {
        let child1 = VNode.text("Fragment child 1")
        let child2 = VNode.text("Fragment child 2")
        let fragment = VNode.fragment(children: [child1, child2])

        if case .fragment = fragment.type {
            // Success
        } else {
            Issue.record("Should be a fragment node")
        }

        #expect(fragment.children.count == 2)
    }

    // MARK: - Test 3: VTree Operations

    @Test func vTreeCreation() async throws {
        let root = VNode.text("Root")
        let tree = VTree(root: root)

        #expect(tree.root.id == root.id)
        #expect(tree.metadata.version == 0)
    }

    @Test func vTreeNodeCount() async throws {
        let child1 = VNode.text("Child 1")
        let child2 = VNode.text("Child 2")
        let root = VNode.element("div", children: [child1, child2])
        let tree = VTree(root: root)

        let count = tree.nodeCount()
        #expect(count == 3)
    }

    @Test func vTreeNodeCountNested() async throws {
        let grandchild = VNode.text("Grandchild")
        let child = VNode.element("span", children: [grandchild])
        let root = VNode.element("div", children: [child])
        let tree = VTree(root: root)

        let count = tree.nodeCount()
        #expect(count == 3)
    }

    @Test func vTreeMaxDepth() async throws {
        let root = VNode.text("Root")
        let tree = VTree(root: root)

        let depth = tree.maxDepth()
        #expect(depth == 1)
    }

    @Test func vTreeMaxDepthNested() async throws {
        let grandchild = VNode.text("Grandchild")
        let child = VNode.element("span", children: [grandchild])
        let root = VNode.element("div", children: [child])
        let tree = VTree(root: root)

        let depth = tree.maxDepth()
        #expect(depth == 3)
    }

    @Test func vTreeMaxDepthWithMultipleChildren() async throws {
        let deepGrandchild = VNode.text("Deep")
        let deepChild = VNode.element("span", children: [deepGrandchild])
        let shallowChild = VNode.text("Shallow")
        let root = VNode.element("div", children: [deepChild, shallowChild])
        let tree = VTree(root: root)

        let depth = tree.maxDepth()
        #expect(depth == 3)
    }

    @Test func vTreeFindNode() async throws {
        let child1 = VNode.text("Child 1")
        let child2 = VNode.text("Child 2")
        let root = VNode.element("div", children: [child1, child2])
        let tree = VTree(root: root)

        // Find root
        let foundRoot = tree.findNode(id: root.id)
        #expect(foundRoot != nil)
        #expect(foundRoot?.id == root.id)

        // Find child1
        let foundChild1 = tree.findNode(id: child1.id)
        #expect(foundChild1 != nil)
        #expect(foundChild1?.id == child1.id)

        // Find child2
        let foundChild2 = tree.findNode(id: child2.id)
        #expect(foundChild2 != nil)
        #expect(foundChild2?.id == child2.id)

        // Try to find non-existent node
        let notFound = tree.findNode(id: NodeID())
        #expect(notFound == nil)
    }

    @Test func vTreeAllNodeIDs() async throws {
        let child1 = VNode.text("Child 1")
        let child2 = VNode.text("Child 2")
        let root = VNode.element("div", children: [child1, child2])
        let tree = VTree(root: root)

        let allIDs = tree.allNodeIDs()
        #expect(allIDs.count == 3)
        #expect(allIDs.contains(root.id))
        #expect(allIDs.contains(child1.id))
        #expect(allIDs.contains(child2.id))
    }

    @Test func vTreeWithRoot() async throws {
        let oldRoot = VNode.text("Old")
        let tree = VTree(root: oldRoot)

        let newRoot = VNode.text("New")
        let newTree = tree.withRoot(newRoot)

        #expect(newTree.root.id == newRoot.id)
        #expect(newTree.metadata.version == 1)
        #expect(tree.metadata.version == 0)
    }

    @Test func vTreeValidation() async throws {
        let child = VNode.text("Valid child")
        let root = VNode.element("div", children: [child])
        let tree = VTree(root: root)

        let errors = tree.validate()
        #expect(errors.isEmpty)
    }

    @Test func vTreeValidationEmptyTag() async throws {
        // Create an element with empty tag using the initializer
        let invalidNode = VNode(type: .element(tag: ""), props: [:], children: [])
        let tree = VTree(root: invalidNode)

        let errors = tree.validate()
        #expect(errors.count == 1)

        if case .emptyElementTag = errors[0] {
            // Success
        } else {
            Issue.record("Should detect empty element tag")
        }
    }

    @Test func vTreeValidationTextWithChildren() async throws {
        let child = VNode.text("Invalid child")
        // Create a text node with children (invalid)
        let invalidNode = VNode(type: .text("Text"), props: [:], children: [child])
        let tree = VTree(root: invalidNode)

        let errors = tree.validate()
        #expect(errors.count == 1)

        if case .textNodeWithChildren = errors[0] {
            // Success
        } else {
            Issue.record("Should detect text node with children")
        }
    }

    // MARK: - Test 5: ViewBuilder

    @Test func emptyView() async throws {
        let empty = EmptyView()

        // EmptyView should have Never as Body type
        #expect(type(of: empty.self) == EmptyView.self)
    }

    @Test func tupleViewTwoElements() async throws {
        let text1 = Text("First")
        let text2 = Text("Second")
        let tuple = TupleView(text1, text2)

        // Verify the tuple view can extract children
        let children = tuple._extractChildren()
        #expect(children.count == 2)
    }

    @Test func tupleViewThreeElements() async throws {
        let text1 = Text("First")
        let text2 = Text("Second")
        let text3 = Text("Third")
        let tuple = TupleView(text1, text2, text3)

        // Verify the tuple view can extract children
        let children = tuple._extractChildren()
        #expect(children.count == 3)
    }

    @Test func viewBuilderSingleElement() async throws {
        @ViewBuilder
        func makeView() -> some View {
            Text("Single")
        }

        let view = makeView()
        #expect(type(of: view) == Text.self)
    }

    @Test func viewBuilderEmpty() async throws {
        @ViewBuilder
        func makeView() -> some View {
            // Empty
        }

        let view = makeView()
        #expect(type(of: view) == EmptyView.self)
    }

    @Test func viewBuilderTwoElements() async throws {
        @ViewBuilder
        func makeView() -> some View {
            Text("First")
            Text("Second")
        }

        let view = makeView()
        // Should return a TupleView (parameter pack generic, check via string)
        let typeName = String(describing: type(of: view))
        #expect(typeName.contains("TupleView"))
    }

    @Test func viewBuilderThreeElements() async throws {
        @ViewBuilder
        func makeView() -> some View {
            Text("First")
            Text("Second")
            Text("Third")
        }

        let view = makeView()
        let typeName = String(describing: type(of: view))
        #expect(typeName.contains("TupleView"))
    }

    @Test func conditionalContent() async throws {
        let trueContent = ConditionalContent<Text, Text>(trueContent: Text("True"))

        if case .trueContent(let content) = trueContent.storage {
            let vnode = content.toVNode()
            #expect(vnode.textContent == "True")
        } else {
            Issue.record("Should have true content")
        }

        let falseContent = ConditionalContent<Text, Text>(falseContent: Text("False"))

        if case .falseContent(let content) = falseContent.storage {
            let vnode = content.toVNode()
            #expect(vnode.textContent == "False")
        } else {
            Issue.record("Should have false content")
        }
    }

    @Test func optionalContent() async throws {
        let withContent = OptionalContent(content: Text("Present"))
        #expect(withContent.content != nil)

        let vnode = withContent.content?.toVNode()
        #expect(vnode?.textContent == "Present")

        let withoutContent = OptionalContent<Text>(content: nil)
        #expect(withoutContent.content == nil)
    }

    @Test func forEachView() async throws {
        let views = [Text("First"), Text("Second"), Text("Third")]
        let forEach = ForEachView(views: views)

        #expect(forEach.views.count == 3)

        let vnodes = forEach.views.map { $0.toVNode() }
        #expect(vnodes[0].textContent == "First")
        #expect(vnodes[1].textContent == "Second")
        #expect(vnodes[2].textContent == "Third")
    }

    // MARK: - Integration Tests

    @Test func completeElementTreePipeline() async throws {
        // Create a simple tree structure
        let child1 = VNode.text("Child 1")
        let child2 = VNode.text("Child 2")
        let root = VNode.element("div", children: [child1, child2])

        // Create VTree
        let tree = VTree(root: root)

        // Validate tree structure
        #expect(tree.nodeCount() == 3)
        #expect(tree.maxDepth() == 2)

        // Verify we can find all nodes
        #expect(tree.findNode(id: root.id) != nil)
        #expect(tree.findNode(id: child1.id) != nil)
        #expect(tree.findNode(id: child2.id) != nil)

        // Validate tree
        let errors = tree.validate()
        #expect(errors.isEmpty)
    }

    @Test func nodeIDUniqueness() async throws {
        let id1 = NodeID()
        let id2 = NodeID()

        // NodeIDs should be unique
        #expect(id1 != id2)
        #expect(id1.uuidString != id2.uuidString)
    }

    @Test func nodeIDHashable() async throws {
        let id = NodeID()
        var set = Set<NodeID>()

        set.insert(id)
        #expect(set.contains(id))
        #expect(set.count == 1)

        // Insert same ID again
        set.insert(id)
        #expect(set.count == 1)
    }

    @Test func vPropertyEquality() async throws {
        let prop1 = VProperty.attribute(name: "class", value: "container")
        let prop2 = VProperty.attribute(name: "class", value: "container")
        let prop3 = VProperty.attribute(name: "class", value: "different")

        #expect(prop1 == prop2)
        #expect(prop1 != prop3)
    }

    @Test func vNodeEquality() async throws {
        // VNodes with same structure but different IDs are not equal
        let vnode1 = VNode.text("Same")
        let vnode2 = VNode.text("Same")

        #expect(vnode1 != vnode2)
    }

    // MARK: - Test 9: Button View

    @Test func basicButtonWithTextLabel() async throws {
        // Create a button with a simple text label
        let button = Button("Click Me") {
            // action
        }

        // Convert to VNode
        let vnode = button.toVNode()

        // Verify it creates a button element
        #expect(vnode.isElement(tag: "button"))
        #expect(vnode.elementTag == "button")

        // Verify it has an event handler
        #expect(!vnode.props.isEmpty)
        #expect(vnode.props["onClick"] != nil)

        // Verify the event handler property
        if case .eventHandler(let event, let handlerID) = vnode.props["onClick"] {
            #expect(event == "click")
            #expect(handlerID != nil)
        } else {
            Issue.record("onClick property should be an event handler")
        }

        // Verify it has a text child
        #expect(vnode.children.count == 1)
        #expect(vnode.children[0].isText)
        #expect(vnode.children[0].textContent == "Click Me")
    }

    @Test func buttonWithLocalizedStringKey() async throws {
        // Create a button with a localized string key
        let button = Button(LocalizedStringKey("button.submit")) {
            print("Submitted")
        }

        let vnode = button.toVNode()

        // Verify button element
        #expect(vnode.isElement(tag: "button"))

        // Verify text content
        #expect(vnode.children.count == 1)
        #expect(vnode.children[0].textContent == "button.submit")
    }

    @Test func buttonWithCustomLabel() async throws {
        // Create a button with custom label using ViewBuilder
        let button = Button(action: { print("Tapped") }) {
            Text("Custom Label")
        }

        let vnode = button.toVNode()

        // Verify button element
        #expect(vnode.isElement(tag: "button"))
        #expect(vnode.props["onClick"] != nil)

        // Verify it has a text child (since label is Text)
        #expect(vnode.children.count == 1)
        #expect(vnode.children[0].textContent == "Custom Label")
    }

    @Test func buttonEventHandlerUniqueIDs() async throws {
        // Create two buttons and verify they get unique event handler IDs
        let button1 = Button("Button 1") { print("1") }
        let button2 = Button("Button 2") { print("2") }

        let vnode1 = button1.toVNode()
        let vnode2 = button2.toVNode()

        // Extract handler IDs
        guard case .eventHandler(_, let id1) = vnode1.props["onClick"],
              case .eventHandler(_, let id2) = vnode2.props["onClick"] else {
            Issue.record("Both buttons should have event handlers")
            return
        }

        // Verify unique IDs
        #expect(id1 != id2)
    }
}
