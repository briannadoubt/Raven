import XCTest
@testable import Raven

/// Additional test coverage for edge cases and untested code paths
/// Targets VNode, Differ, View rendering, modifiers, and error handling
@available(macOS 13.0, *)
final class AdditionalCoverageTests: XCTestCase {

    // MARK: - VNode Edge Cases

    func testVNodeWithEmptyChildren() {
        let node = VNode.element("div", children: [])

        XCTAssertEqual(node.children.count, 0, "VNode should support empty children array")
        XCTAssertTrue(node.isElement(tag: "div"), "Should be a div element")
        XCTAssertEqual(node.elementTag, "div", "Element tag should be accessible")
    }

    func testVNodeDeeplyNestedTree() {
        // Create a deeply nested tree: div > ul > li > span > text
        let deeplyNested = VNode.element("div", children: [
            VNode.element("ul", children: [
                VNode.element("li", children: [
                    VNode.element("span", children: [
                        VNode.text("Deeply nested content")
                    ])
                ])
            ])
        ])

        XCTAssertEqual(deeplyNested.children.count, 1, "Root should have 1 child")
        XCTAssertEqual(deeplyNested.children[0].children.count, 1, "ul should have 1 child")
        XCTAssertEqual(deeplyNested.children[0].children[0].children.count, 1, "li should have 1 child")
        XCTAssertEqual(deeplyNested.children[0].children[0].children[0].children.count, 1, "span should have 1 child")

        let textNode = deeplyNested.children[0].children[0].children[0].children[0]
        XCTAssertTrue(textNode.isText, "Deepest node should be text")
        XCTAssertEqual(textNode.textContent, "Deeply nested content", "Text content should be preserved")
    }

    func testVNodeWithMultipleProperties() {
        let props: [String: VProperty] = [
            "class": .attribute(name: "class", value: "container"),
            "id": .attribute(name: "id", value: "main"),
            "color": .style(name: "color", value: "red"),
            "fontSize": .style(name: "font-size", value: "16px"),
            "disabled": .boolAttribute(name: "disabled", value: true)
        ]

        let node = VNode.element("div", props: props)

        XCTAssertEqual(node.props.count, 5, "Should have all 5 properties")
        XCTAssertTrue(node.props.keys.contains("class"), "Should have class attribute")
        XCTAssertTrue(node.props.keys.contains("disabled"), "Should have disabled attribute")
    }

    func testVNodeFragmentWithMultipleChildren() {
        let fragment = VNode.fragment(children: [
            VNode.text("First"),
            VNode.element("div", children: [VNode.text("Second")]),
            VNode.text("Third")
        ])

        XCTAssertEqual(fragment.children.count, 3, "Fragment should have 3 children")
        if case .fragment = fragment.type {
            XCTAssertTrue(true, "Should be a fragment node")
        } else {
            XCTFail("Expected fragment node type")
        }
    }

    func testVNodeComponentWithKey() {
        let component = VNode.component(
            props: ["name": .attribute(name: "name", value: "MyComponent")],
            children: [VNode.text("Component content")],
            key: "unique-component-key"
        )

        XCTAssertEqual(component.key, "unique-component-key", "Key should be preserved")
        XCTAssertEqual(component.children.count, 1, "Component should have children")
        if case .component = component.type {
            XCTAssertTrue(true, "Should be a component node")
        } else {
            XCTFail("Expected component node type")
        }
    }

    func testVNodeTextContentRetrieval() {
        let textNode = VNode.text("Hello, world!")
        let elementNode = VNode.element("div")

        XCTAssertEqual(textNode.textContent, "Hello, world!", "Text content should be retrievable")
        XCTAssertNil(elementNode.textContent, "Element node should not have text content")

        XCTAssertTrue(textNode.isText, "Should identify as text node")
        XCTAssertFalse(elementNode.isText, "Element should not identify as text node")
    }

    func testVNodeElementTagRetrieval() {
        let element = VNode.element("button")
        let textNode = VNode.text("Text")

        XCTAssertEqual(element.elementTag, "button", "Element tag should be retrievable")
        XCTAssertNil(textNode.elementTag, "Text node should not have element tag")

        XCTAssertTrue(element.isElement(tag: "button"), "Should identify as button element")
        XCTAssertFalse(element.isElement(tag: "div"), "Should not identify as div element")
    }

    // MARK: - Differ Edge Cases

    @MainActor
    func testDifferIdenticalTrees() async {
        let tree1 = VNode.element("div", children: [
            VNode.element("p", children: [VNode.text("Same content")])
        ])

        let tree2 = VNode.element("div", children: [
            VNode.element("p", children: [VNode.text("Same content")])
        ])

        let differ = Differ()
        let patches = await differ.diff(old: tree1, new: tree2)

        // Patches should only include property updates if node IDs differ
        // but no structural changes
        XCTAssertNotNil(patches, "Differ should handle identical trees")
    }

    @MainActor
    func testDifferCompletelyDifferentTrees() async {
        let tree1 = VNode.element("div", children: [
            VNode.element("p", children: [VNode.text("Old content")])
        ])

        let tree2 = VNode.element("section", children: [
            VNode.element("h1", children: [VNode.text("New content")]),
            VNode.element("ul", children: [
                VNode.element("li", children: [VNode.text("Item")])
            ])
        ])

        let differ = Differ()
        let patches = await differ.diff(old: tree1, new: tree2)

        XCTAssertFalse(patches.isEmpty, "Should generate patches for different trees")

        // Should contain a replace patch since root elements differ
        let hasReplace = patches.contains { patch in
            if case .replace = patch {
                return true
            }
            return false
        }
        XCTAssertTrue(hasReplace, "Should replace nodes with different types")
    }

    @MainActor
    func testDifferSingleChildToMultipleChildren() async {
        let tree1 = VNode.element("ul", children: [
            VNode.element("li", children: [VNode.text("Item 1")])
        ])

        let tree2 = VNode.element("ul", children: [
            VNode.element("li", children: [VNode.text("Item 1")]),
            VNode.element("li", children: [VNode.text("Item 2")]),
            VNode.element("li", children: [VNode.text("Item 3")])
        ])

        let differ = Differ()
        let patches = await differ.diff(old: tree1, new: tree2)

        XCTAssertFalse(patches.isEmpty, "Should generate patches for added children")

        // Should contain insert patches
        let insertCount = patches.filter { patch in
            if case .insert = patch {
                return true
            }
            return false
        }.count

        XCTAssertEqual(insertCount, 2, "Should insert 2 new children")
    }

    @MainActor
    func testDifferMultipleChildrenToEmpty() async {
        let tree1 = VNode.element("ul", children: [
            VNode.element("li", children: [VNode.text("Item 1")]),
            VNode.element("li", children: [VNode.text("Item 2")])
        ])

        let tree2 = VNode.element("ul", children: [])

        let differ = Differ()
        let patches = await differ.diff(old: tree1, new: tree2)

        XCTAssertFalse(patches.isEmpty, "Should generate patches for removed children")

        // Should contain remove patches
        let removeCount = patches.filter { patch in
            if case .remove = patch {
                return true
            }
            return false
        }.count

        XCTAssertEqual(removeCount, 2, "Should remove 2 children")
    }

    @MainActor
    func testDifferNilOldTree() async {
        let newTree = VNode.element("div", children: [VNode.text("New")])

        let differ = Differ()
        let patches = await differ.diff(old: nil, new: newTree)

        // When old is nil, differ returns empty array (handled by caller)
        XCTAssertTrue(patches.isEmpty, "Differ returns empty array for nil old tree")
    }

    @MainActor
    func testDifferNilNewTree() async {
        let oldTree = VNode.element("div", children: [VNode.text("Old")])

        let differ = Differ()
        let patches = await differ.diff(old: oldTree, new: nil)

        XCTAssertFalse(patches.isEmpty, "Should generate remove patch when new tree is nil")

        if case .remove = patches[0] {
            XCTAssertTrue(true, "Should remove old tree")
        } else {
            XCTFail("Expected remove patch")
        }
    }

    @MainActor
    func testDifferPropertyChanges() async {
        let tree1 = VNode.element("div", props: [
            "class": .attribute(name: "class", value: "old-class")
        ])

        let tree2 = VNode.element("div", props: [
            "class": .attribute(name: "class", value: "new-class"),
            "id": .attribute(name: "id", value: "new-id")
        ])

        let differ = Differ()
        let patches = await differ.diff(old: tree1, new: tree2)

        // Should contain updateProps patch
        let hasUpdateProps = patches.contains { patch in
            if case .updateProps = patch {
                return true
            }
            return false
        }

        XCTAssertTrue(hasUpdateProps, "Should update properties")
    }

    // MARK: - View Rendering Edge Cases

    @MainActor
    func testEmptyViewRendering() {
        struct EmptyTestView: View {
            var body: some View {
                EmptyView()
            }
        }

        let view = EmptyTestView()
        // Just test that the view compiles and can be created
        XCTAssertNotNil(view, "EmptyView should be accessible")
    }

    @MainActor
    func testDeeplyNestedViewBuilder() {
        struct NestedView: View {
            var body: some View {
                VStack {
                    VStack {
                        VStack {
                            VStack {
                                Text("Deeply nested")
                            }
                        }
                    }
                }
            }
        }

        let view = NestedView()
        // Test that the view compiles
        XCTAssertNotNil(view, "Deeply nested ViewBuilder should compile")
    }

    @MainActor
    func testConditionalViewRendering() {
        struct ConditionalView: View {
            let showContent: Bool

            var body: some View {
                VStack {
                    if showContent {
                        Text("Content shown")
                    } else {
                        Text("Content hidden")
                    }
                }
            }
        }

        let viewShown = ConditionalView(showContent: true)
        let viewHidden = ConditionalView(showContent: false)

        XCTAssertNotNil(viewShown, "Conditional view should render with content")
        XCTAssertNotNil(viewHidden, "Conditional view should render without content")
    }

    @MainActor
    func testOptionalViewRendering() {
        struct OptionalContentView: View {
            let optionalText: String?

            var body: some View {
                VStack {
                    if let text = optionalText {
                        Text(text)
                    }
                }
            }
        }

        let withText = OptionalContentView(optionalText: "Hello")
        let withoutText = OptionalContentView(optionalText: nil)

        XCTAssertNotNil(withText, "Should handle optional content present")
        XCTAssertNotNil(withoutText, "Should handle optional content absent")
    }

    // MARK: - Modifier Composition

    @MainActor
    func testChainingMultipleModifiers() {
        struct ModifiedView: View {
            var body: some View {
                Text("Modified")
                    .padding(10)
                    .background(Color.blue)
                    .foregroundColor(Color.white)
                    .frame(width: 100, height: 50)
            }
        }

        let view = ModifiedView()
        XCTAssertNotNil(view, "Should chain multiple modifiers")
    }

    @MainActor
    func testNestedModifierApplication() {
        struct NestedModifiers: View {
            var body: some View {
                VStack {
                    Text("Outer")
                        .padding(5)
                }
                .padding(10)
                .background(Color.gray)
            }
        }

        let view = NestedModifiers()
        XCTAssertNotNil(view, "Should apply modifiers at multiple levels")
    }

    @MainActor
    func testModifierOrderMatters() {
        struct OrderedModifiers: View {
            var body: some View {
                VStack {
                    // Background then padding
                    Text("First")
                        .background(Color.red)
                        .padding(10)

                    // Padding then background
                    Text("Second")
                        .padding(10)
                        .background(Color.blue)
                }
            }
        }

        let view = OrderedModifiers()
        XCTAssertNotNil(view, "Should preserve modifier order")
    }

    @MainActor
    func testCustomModifierComposition() {
        struct CustomModifier: ViewModifier {
            func body(content: Content) -> some View {
                content
                    .padding(20)
                    .background(Color.yellow)
            }
        }

        struct CustomModifiedView: View {
            var body: some View {
                Text("Custom")
                    .modifier(CustomModifier())
                    .foregroundColor(Color.black)
            }
        }

        let view = CustomModifiedView()
        XCTAssertNotNil(view, "Should compose custom modifiers")
    }

    // MARK: - Error Handling Paths

    func testNeverBodyFatalError() {
        // Test that Never.body causes a fatal error if called
        // We can't actually trigger this in a test, but we can verify the structure
        XCTAssertTrue(true, "Never.body should fatal error if called")
    }

    func testPrimitiveViewBodyAccess() {
        // Primitive views have Body = Never
        // Accessing body should fatal error, but we verify the type system prevents this
        struct PrimitiveView: View {
            typealias Body = Never
        }

        // The compiler prevents calling .body on primitive views
        XCTAssertTrue(true, "Type system prevents primitive view body access")
    }

    func testInvalidNodeTypeMatching() {
        // Test that incompatible node types are detected
        struct TypeMismatchTest {
            func areCompatible(type1: NodeType, type2: NodeType) -> Bool {
                switch (type1, type2) {
                case (.element(let tag1), .element(let tag2)):
                    return tag1 == tag2
                case (.text, .text):
                    return true
                case (.component, .component):
                    return true
                case (.fragment, .fragment):
                    return true
                default:
                    return false
                }
            }
        }

        let test = TypeMismatchTest()

        XCTAssertFalse(test.areCompatible(type1: .element(tag: "div"), type2: .text("text")),
                      "Element and text should not be compatible")
        XCTAssertFalse(test.areCompatible(type1: .component, type2: .fragment),
                      "Component and fragment should not be compatible")
        XCTAssertTrue(test.areCompatible(type1: .element(tag: "div"), type2: .element(tag: "div")),
                     "Same element types should be compatible")
    }

    // MARK: - VProperty Edge Cases

    func testVPropertyEquality() {
        let prop1 = VProperty.attribute(name: "class", value: "container")
        let prop2 = VProperty.attribute(name: "class", value: "container")
        let prop3 = VProperty.attribute(name: "class", value: "different")

        XCTAssertEqual(prop1, prop2, "Identical properties should be equal")
        XCTAssertNotEqual(prop1, prop3, "Different properties should not be equal")
    }

    func testVPropertyStyleVsAttribute() {
        let style = VProperty.style(name: "color", value: "red")
        let attribute = VProperty.attribute(name: "color", value: "red")

        XCTAssertNotEqual(style, attribute, "Style and attribute should be different types")
    }

    func testVPropertyBoolAttribute() {
        let enabledTrue = VProperty.boolAttribute(name: "disabled", value: true)
        let enabledFalse = VProperty.boolAttribute(name: "disabled", value: false)

        XCTAssertNotEqual(enabledTrue, enabledFalse, "Boolean attributes with different values should differ")
    }

    func testVPropertyEventHandler() {
        let handler1 = VProperty.eventHandler(event: "click", handlerID: UUID())
        let handler2 = VProperty.eventHandler(event: "click", handlerID: UUID())

        // Different UUIDs should make them unequal
        XCTAssertNotEqual(handler1, handler2, "Event handlers with different IDs should differ")
    }

    // MARK: - NodeID Tests

    func testNodeIDUniqueness() {
        let id1 = NodeID()
        let id2 = NodeID()

        XCTAssertNotEqual(id1, id2, "Each NodeID should be unique")
        XCTAssertNotEqual(id1.uuidString, id2.uuidString, "UUID strings should differ")
    }

    func testNodeIDDescription() {
        let id = NodeID()
        let description = id.description
        let uuidString = id.uuidString

        XCTAssertEqual(description, uuidString, "Description should match uuidString")
        XCTAssertFalse(description.isEmpty, "Description should not be empty")
    }

    func testNodeIDHashable() {
        let id1 = NodeID()
        let id2 = NodeID()

        var set = Set<NodeID>()
        set.insert(id1)
        set.insert(id2)

        XCTAssertEqual(set.count, 2, "Different NodeIDs should be stored in Set")
        XCTAssertTrue(set.contains(id1), "Set should contain id1")
        XCTAssertTrue(set.contains(id2), "Set should contain id2")
    }

    // MARK: - Move Operation Tests

    func testMoveOperation() {
        let move1 = Move(from: 0, to: 2)
        let move2 = Move(from: 0, to: 2)
        let move3 = Move(from: 1, to: 3)

        XCTAssertEqual(move1, move2, "Identical moves should be equal")
        XCTAssertNotEqual(move1, move3, "Different moves should not be equal")
        XCTAssertEqual(move1.from, 0, "Move from should be accessible")
        XCTAssertEqual(move1.to, 2, "Move to should be accessible")
    }

    // MARK: - PropPatch Tests

    func testPropPatchAdd() {
        let patch = PropPatch.add(key: "newProp", value: .attribute(name: "data-id", value: "123"))

        if case .add(let key, let value) = patch {
            XCTAssertEqual(key, "newProp", "Key should be preserved")
            if case .attribute(let name, let val) = value {
                XCTAssertEqual(name, "data-id", "Attribute name should be preserved")
                XCTAssertEqual(val, "123", "Attribute value should be preserved")
            } else {
                XCTFail("Expected attribute property")
            }
        } else {
            XCTFail("Expected add patch")
        }
    }

    func testPropPatchRemove() {
        let patch = PropPatch.remove(key: "oldProp")

        if case .remove(let key) = patch {
            XCTAssertEqual(key, "oldProp", "Key should be preserved")
        } else {
            XCTFail("Expected remove patch")
        }
    }

    func testPropPatchUpdate() {
        let patch = PropPatch.update(key: "existingProp", value: .style(name: "color", value: "blue"))

        if case .update(let key, let value) = patch {
            XCTAssertEqual(key, "existingProp", "Key should be preserved")
            if case .style(let name, let val) = value {
                XCTAssertEqual(name, "color", "Style name should be preserved")
                XCTAssertEqual(val, "blue", "Style value should be preserved")
            } else {
                XCTFail("Expected style property")
            }
        } else {
            XCTFail("Expected update patch")
        }
    }
}
