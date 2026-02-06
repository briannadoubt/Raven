import XCTest
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
final class Phase1VerificationTests: XCTestCase {

    // MARK: - Test 1: Basic Text Rendering

    func testBasicTextRendering() async throws {
        // Create a Text view
        let text = Text("Hello, Raven!")

        // Convert it to VNode
        let vnode = text.toVNode()

        // Verify the VNode structure is correct
        XCTAssertTrue(vnode.isText, "VNode should be a text node")
        XCTAssertEqual(vnode.textContent, "Hello, Raven!", "Text content should match")

        // Verify node ID is generated
        XCTAssertNotNil(vnode.id, "Node ID should be generated")

        // Verify no children
        XCTAssertTrue(vnode.children.isEmpty, "Text node should have no children")

        // Verify no properties
        XCTAssertTrue(vnode.props.isEmpty, "Text node should have no properties")
    }

    func testTextWithInterpolation() async throws {
        let name = "Raven"
        let version = 1
        let text = Text("Welcome to \(name) v\(version)")

        let vnode = text.toVNode()

        XCTAssertEqual(vnode.textContent, "Welcome to Raven v1", "String interpolation should work")
    }

    func testTextFromStringLiteral() async throws {
        let text: Text = "Literal String"
        let vnode = text.toVNode()

        XCTAssertEqual(vnode.textContent, "Literal String", "String literal should work")
    }

    // MARK: - Test 2: VNode Creation

    func testVNodeTextFactory() async throws {
        let vnode = VNode.text("Test content")

        XCTAssertTrue(vnode.isText, "Should be a text node")
        XCTAssertEqual(vnode.textContent, "Test content", "Content should match")
        XCTAssertTrue(vnode.children.isEmpty, "Text node should have no children")
        XCTAssertTrue(vnode.props.isEmpty, "Text node should have no properties")
        XCTAssertNil(vnode.key, "Key should be nil if not provided")
    }

    func testVNodeTextFactoryWithKey() async throws {
        let vnode = VNode.text("Keyed content", key: "unique-key")

        XCTAssertEqual(vnode.textContent, "Keyed content")
        XCTAssertEqual(vnode.key, "unique-key", "Key should be set")
    }

    func testVNodeElementFactory() async throws {
        let vnode = VNode.element("div")

        XCTAssertTrue(vnode.isElement(tag: "div"), "Should be a div element")
        XCTAssertEqual(vnode.elementTag, "div", "Element tag should be 'div'")
        XCTAssertTrue(vnode.children.isEmpty, "Should have no children by default")
        XCTAssertTrue(vnode.props.isEmpty, "Should have no properties by default")
    }

    func testVNodeElementFactoryWithChildren() async throws {
        let child1 = VNode.text("Child 1")
        let child2 = VNode.text("Child 2")
        let parent = VNode.element("div", children: [child1, child2])

        XCTAssertEqual(parent.children.count, 2, "Should have 2 children")
        XCTAssertEqual(parent.children[0].textContent, "Child 1")
        XCTAssertEqual(parent.children[1].textContent, "Child 2")
    }

    func testVNodeElementFactoryWithProperties() async throws {
        let props: [String: VProperty] = [
            "class": .attribute(name: "class", value: "container"),
            "id": .attribute(name: "id", value: "main")
        ]
        let vnode = VNode.element("div", props: props)

        XCTAssertEqual(vnode.props.count, 2, "Should have 2 properties")
        XCTAssertEqual(vnode.props["class"], .attribute(name: "class", value: "container"))
        XCTAssertEqual(vnode.props["id"], .attribute(name: "id", value: "main"))
    }

    func testVNodeComponentFactory() async throws {
        let vnode = VNode.component()

        if case .component = vnode.type {
            // Success
        } else {
            XCTFail("Should be a component node")
        }
    }

    func testVNodeFragmentFactory() async throws {
        let child1 = VNode.text("Fragment child 1")
        let child2 = VNode.text("Fragment child 2")
        let fragment = VNode.fragment(children: [child1, child2])

        if case .fragment = fragment.type {
            // Success
        } else {
            XCTFail("Should be a fragment node")
        }

        XCTAssertEqual(fragment.children.count, 2)
    }

    // MARK: - Test 3: VTree Operations

    func testVTreeCreation() async throws {
        let root = VNode.text("Root")
        let tree = VTree(root: root)

        XCTAssertEqual(tree.root.id, root.id, "Root should be set correctly")
        XCTAssertEqual(tree.metadata.version, 0, "Initial version should be 0")
    }

    func testVTreeNodeCount() async throws {
        let child1 = VNode.text("Child 1")
        let child2 = VNode.text("Child 2")
        let root = VNode.element("div", children: [child1, child2])
        let tree = VTree(root: root)

        let count = tree.nodeCount()
        XCTAssertEqual(count, 3, "Should count root + 2 children = 3 nodes")
    }

    func testVTreeNodeCountNested() async throws {
        let grandchild = VNode.text("Grandchild")
        let child = VNode.element("span", children: [grandchild])
        let root = VNode.element("div", children: [child])
        let tree = VTree(root: root)

        let count = tree.nodeCount()
        XCTAssertEqual(count, 3, "Should count root + child + grandchild = 3 nodes")
    }

    func testVTreeMaxDepth() async throws {
        let root = VNode.text("Root")
        let tree = VTree(root: root)

        let depth = tree.maxDepth()
        XCTAssertEqual(depth, 1, "Single node should have depth 1")
    }

    func testVTreeMaxDepthNested() async throws {
        let grandchild = VNode.text("Grandchild")
        let child = VNode.element("span", children: [grandchild])
        let root = VNode.element("div", children: [child])
        let tree = VTree(root: root)

        let depth = tree.maxDepth()
        XCTAssertEqual(depth, 3, "Three levels should have depth 3")
    }

    func testVTreeMaxDepthWithMultipleChildren() async throws {
        let deepGrandchild = VNode.text("Deep")
        let deepChild = VNode.element("span", children: [deepGrandchild])
        let shallowChild = VNode.text("Shallow")
        let root = VNode.element("div", children: [deepChild, shallowChild])
        let tree = VTree(root: root)

        let depth = tree.maxDepth()
        XCTAssertEqual(depth, 3, "Should return maximum depth among all branches")
    }

    func testVTreeFindNode() async throws {
        let child1 = VNode.text("Child 1")
        let child2 = VNode.text("Child 2")
        let root = VNode.element("div", children: [child1, child2])
        let tree = VTree(root: root)

        // Find root
        let foundRoot = tree.findNode(id: root.id)
        XCTAssertNotNil(foundRoot, "Should find root node")
        XCTAssertEqual(foundRoot?.id, root.id)

        // Find child1
        let foundChild1 = tree.findNode(id: child1.id)
        XCTAssertNotNil(foundChild1, "Should find child1")
        XCTAssertEqual(foundChild1?.id, child1.id)

        // Find child2
        let foundChild2 = tree.findNode(id: child2.id)
        XCTAssertNotNil(foundChild2, "Should find child2")
        XCTAssertEqual(foundChild2?.id, child2.id)

        // Try to find non-existent node
        let notFound = tree.findNode(id: NodeID())
        XCTAssertNil(notFound, "Should not find non-existent node")
    }

    func testVTreeAllNodeIDs() async throws {
        let child1 = VNode.text("Child 1")
        let child2 = VNode.text("Child 2")
        let root = VNode.element("div", children: [child1, child2])
        let tree = VTree(root: root)

        let allIDs = tree.allNodeIDs()
        XCTAssertEqual(allIDs.count, 3, "Should have 3 unique node IDs")
        XCTAssertTrue(allIDs.contains(root.id))
        XCTAssertTrue(allIDs.contains(child1.id))
        XCTAssertTrue(allIDs.contains(child2.id))
    }

    func testVTreeWithRoot() async throws {
        let oldRoot = VNode.text("Old")
        let tree = VTree(root: oldRoot)

        let newRoot = VNode.text("New")
        let newTree = tree.withRoot(newRoot)

        XCTAssertEqual(newTree.root.id, newRoot.id, "Root should be updated")
        XCTAssertEqual(newTree.metadata.version, 1, "Version should be incremented")
        XCTAssertEqual(tree.metadata.version, 0, "Original tree should be unchanged")
    }

    func testVTreeValidation() async throws {
        let child = VNode.text("Valid child")
        let root = VNode.element("div", children: [child])
        let tree = VTree(root: root)

        let errors = tree.validate()
        XCTAssertTrue(errors.isEmpty, "Valid tree should have no errors")
    }

    func testVTreeValidationEmptyTag() async throws {
        // Create an element with empty tag using the initializer
        let invalidNode = VNode(type: .element(tag: ""), props: [:], children: [])
        let tree = VTree(root: invalidNode)

        let errors = tree.validate()
        XCTAssertEqual(errors.count, 1, "Should have one validation error")

        if case .emptyElementTag = errors[0] {
            // Success
        } else {
            XCTFail("Should detect empty element tag")
        }
    }

    func testVTreeValidationTextWithChildren() async throws {
        let child = VNode.text("Invalid child")
        // Create a text node with children (invalid)
        let invalidNode = VNode(type: .text("Text"), props: [:], children: [child])
        let tree = VTree(root: invalidNode)

        let errors = tree.validate()
        XCTAssertEqual(errors.count, 1, "Should have one validation error")

        if case .textNodeWithChildren = errors[0] {
            // Success
        } else {
            XCTFail("Should detect text node with children")
        }
    }

    // MARK: - Test 5: ViewBuilder

    func testEmptyView() async throws {
        let empty = EmptyView()

        // EmptyView should have Never as Body type
        XCTAssertTrue(type(of: empty.self) == EmptyView.self)
    }

    func testTupleViewTwoElements() async throws {
        let text1 = Text("First")
        let text2 = Text("Second")
        let tuple = TupleView(text1, text2)

        // Verify the tuple view can extract children
        let children = tuple._extractChildren()
        XCTAssertEqual(children.count, 2)
    }

    func testTupleViewThreeElements() async throws {
        let text1 = Text("First")
        let text2 = Text("Second")
        let text3 = Text("Third")
        let tuple = TupleView(text1, text2, text3)

        // Verify the tuple view can extract children
        let children = tuple._extractChildren()
        XCTAssertEqual(children.count, 3)
    }

    func testViewBuilderSingleElement() async throws {
        @ViewBuilder
        func makeView() -> some View {
            Text("Single")
        }

        let view = makeView()
        XCTAssertTrue(type(of: view) == Text.self)
    }

    func testViewBuilderEmpty() async throws {
        @ViewBuilder
        func makeView() -> some View {
            // Empty
        }

        let view = makeView()
        XCTAssertTrue(type(of: view) == EmptyView.self)
    }

    func testViewBuilderTwoElements() async throws {
        @ViewBuilder
        func makeView() -> some View {
            Text("First")
            Text("Second")
        }

        let view = makeView()
        // Should return a TupleView (parameter pack generic, check via string)
        let typeName = String(describing: type(of: view))
        XCTAssertTrue(typeName.contains("TupleView"), "Expected TupleView, got \(typeName)")
    }

    func testViewBuilderThreeElements() async throws {
        @ViewBuilder
        func makeView() -> some View {
            Text("First")
            Text("Second")
            Text("Third")
        }

        let view = makeView()
        let typeName = String(describing: type(of: view))
        XCTAssertTrue(typeName.contains("TupleView"), "Expected TupleView, got \(typeName)")
    }

    func testConditionalContent() async throws {
        let trueContent = ConditionalContent<Text, Text>(trueContent: Text("True"))

        if case .trueContent(let content) = trueContent.storage {
            let vnode = content.toVNode()
            XCTAssertEqual(vnode.textContent, "True")
        } else {
            XCTFail("Should have true content")
        }

        let falseContent = ConditionalContent<Text, Text>(falseContent: Text("False"))

        if case .falseContent(let content) = falseContent.storage {
            let vnode = content.toVNode()
            XCTAssertEqual(vnode.textContent, "False")
        } else {
            XCTFail("Should have false content")
        }
    }

    func testOptionalContent() async throws {
        let withContent = OptionalContent(content: Text("Present"))
        XCTAssertNotNil(withContent.content)

        let vnode = withContent.content?.toVNode()
        XCTAssertEqual(vnode?.textContent, "Present")

        let withoutContent = OptionalContent<Text>(content: nil)
        XCTAssertNil(withoutContent.content)
    }

    func testForEachView() async throws {
        let views = [Text("First"), Text("Second"), Text("Third")]
        let forEach = ForEachView(views: views)

        XCTAssertEqual(forEach.views.count, 3)

        let vnodes = forEach.views.map { $0.toVNode() }
        XCTAssertEqual(vnodes[0].textContent, "First")
        XCTAssertEqual(vnodes[1].textContent, "Second")
        XCTAssertEqual(vnodes[2].textContent, "Third")
    }

    // MARK: - Integration Tests

    func testCompleteElementTreePipeline() async throws {
        // Create a simple tree structure
        let child1 = VNode.text("Child 1")
        let child2 = VNode.text("Child 2")
        let root = VNode.element("div", children: [child1, child2])

        // Create VTree
        let tree = VTree(root: root)

        // Validate tree structure
        XCTAssertEqual(tree.nodeCount(), 3)
        XCTAssertEqual(tree.maxDepth(), 2)

        // Verify we can find all nodes
        XCTAssertNotNil(tree.findNode(id: root.id))
        XCTAssertNotNil(tree.findNode(id: child1.id))
        XCTAssertNotNil(tree.findNode(id: child2.id))

        // Validate tree
        let errors = tree.validate()
        XCTAssertTrue(errors.isEmpty, "Tree should be valid")
    }

    func testNodeIDUniqueness() async throws {
        let id1 = NodeID()
        let id2 = NodeID()

        // NodeIDs should be unique
        XCTAssertNotEqual(id1, id2, "Generated NodeIDs should be unique")
        XCTAssertNotEqual(id1.uuidString, id2.uuidString)
    }

    func testNodeIDHashable() async throws {
        let id = NodeID()
        var set = Set<NodeID>()

        set.insert(id)
        XCTAssertTrue(set.contains(id), "NodeID should be hashable")
        XCTAssertEqual(set.count, 1)

        // Insert same ID again
        set.insert(id)
        XCTAssertEqual(set.count, 1, "Set should not grow with duplicate ID")
    }

    func testVPropertyEquality() async throws {
        let prop1 = VProperty.attribute(name: "class", value: "container")
        let prop2 = VProperty.attribute(name: "class", value: "container")
        let prop3 = VProperty.attribute(name: "class", value: "different")

        XCTAssertEqual(prop1, prop2, "Identical properties should be equal")
        XCTAssertNotEqual(prop1, prop3, "Different properties should not be equal")
    }

    func testVNodeEquality() async throws {
        // VNodes with same structure but different IDs are not equal
        let vnode1 = VNode.text("Same")
        let vnode2 = VNode.text("Same")

        XCTAssertNotEqual(vnode1, vnode2, "VNodes with different IDs should not be equal")
    }

    // MARK: - Test 9: Button View

    func testBasicButtonWithTextLabel() async throws {
        // Create a button with a simple text label
        let button = Button("Click Me") {
            // action
        }

        // Convert to VNode
        let vnode = button.toVNode()

        // Verify it creates a button element
        XCTAssertTrue(vnode.isElement(tag: "button"), "Button should create a button element")
        XCTAssertEqual(vnode.elementTag, "button")

        // Verify it has an event handler
        XCTAssertFalse(vnode.props.isEmpty, "Button should have event handler property")
        XCTAssertNotNil(vnode.props["onClick"], "Button should have onClick handler")

        // Verify the event handler property
        if case .eventHandler(let event, let handlerID) = vnode.props["onClick"] {
            XCTAssertEqual(event, "click", "Event should be 'click'")
            XCTAssertNotNil(handlerID, "Handler ID should be generated")
        } else {
            XCTFail("onClick property should be an event handler")
        }

        // Verify it has a text child
        XCTAssertEqual(vnode.children.count, 1, "Button should have one child for the label")
        XCTAssertTrue(vnode.children[0].isText, "Button child should be a text node")
        XCTAssertEqual(vnode.children[0].textContent, "Click Me", "Button text should match label")
    }

    func testButtonWithLocalizedStringKey() async throws {
        // Create a button with a localized string key
        let button = Button(LocalizedStringKey("button.submit")) {
            print("Submitted")
        }

        let vnode = button.toVNode()

        // Verify button element
        XCTAssertTrue(vnode.isElement(tag: "button"))

        // Verify text content
        XCTAssertEqual(vnode.children.count, 1)
        XCTAssertEqual(vnode.children[0].textContent, "button.submit")
    }

    func testButtonWithCustomLabel() async throws {
        // Create a button with custom label using ViewBuilder
        let button = Button(action: { print("Tapped") }) {
            Text("Custom Label")
        }

        let vnode = button.toVNode()

        // Verify button element
        XCTAssertTrue(vnode.isElement(tag: "button"))
        XCTAssertNotNil(vnode.props["onClick"])

        // Verify it has a text child (since label is Text)
        XCTAssertEqual(vnode.children.count, 1)
        XCTAssertEqual(vnode.children[0].textContent, "Custom Label")
    }

    func testButtonEventHandlerUniqueIDs() async throws {
        // Create two buttons and verify they get unique event handler IDs
        let button1 = Button("Button 1") { print("1") }
        let button2 = Button("Button 2") { print("2") }

        let vnode1 = button1.toVNode()
        let vnode2 = button2.toVNode()

        // Extract handler IDs
        guard case .eventHandler(_, let id1) = vnode1.props["onClick"],
              case .eventHandler(_, let id2) = vnode2.props["onClick"] else {
            XCTFail("Both buttons should have event handlers")
            return
        }

        // Verify unique IDs
        XCTAssertNotEqual(id1, id2, "Each button should have a unique event handler ID")
    }
}
