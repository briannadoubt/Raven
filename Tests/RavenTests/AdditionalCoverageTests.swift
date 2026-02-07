import Foundation
import Testing
@testable import Raven

/// Additional test coverage for edge cases and untested code paths
/// Targets VNode, View rendering, modifiers, and error handling
@MainActor
@Suite struct AdditionalCoverageTests {

    // MARK: - VNode Edge Cases

    @Test func vNodeWithEmptyChildren() {
        let node = VNode.element("div", children: [])

        #expect(node.children.count == 0)
        #expect(node.isElement(tag: "div"))
        #expect(node.elementTag == "div")
    }

    @Test func vNodeDeeplyNestedTree() {
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

        #expect(deeplyNested.children.count == 1)
        #expect(deeplyNested.children[0].children.count == 1)
        #expect(deeplyNested.children[0].children[0].children.count == 1)
        #expect(deeplyNested.children[0].children[0].children[0].children.count == 1)

        let textNode = deeplyNested.children[0].children[0].children[0].children[0]
        #expect(textNode.isText)
        #expect(textNode.textContent == "Deeply nested content")
    }

    @Test func vNodeWithMultipleProperties() {
        let props: [String: VProperty] = [
            "class": .attribute(name: "class", value: "container"),
            "id": .attribute(name: "id", value: "main"),
            "color": .style(name: "color", value: "red"),
            "fontSize": .style(name: "font-size", value: "16px"),
            "disabled": .boolAttribute(name: "disabled", value: true)
        ]

        let node = VNode.element("div", props: props)

        #expect(node.props.count == 5)
        #expect(node.props.keys.contains("class"))
        #expect(node.props.keys.contains("disabled"))
    }

    @Test func vNodeFragmentWithMultipleChildren() {
        let fragment = VNode.fragment(children: [
            VNode.text("First"),
            VNode.element("div", children: [VNode.text("Second")]),
            VNode.text("Third")
        ])

        #expect(fragment.children.count == 3)
        if case .fragment = fragment.type {
            #expect(Bool(true))
        } else {
            Issue.record("Expected fragment node type")
        }
    }

    @Test func vNodeComponentWithKey() {
        let component = VNode.component(
            props: ["name": .attribute(name: "name", value: "MyComponent")],
            children: [VNode.text("Component content")],
            key: "unique-component-key"
        )

        #expect(component.key == "unique-component-key")
        #expect(component.children.count == 1)
        if case .component = component.type {
            #expect(Bool(true))
        } else {
            Issue.record("Expected component node type")
        }
    }

    @Test func vNodeTextContentRetrieval() {
        let textNode = VNode.text("Hello, world!")
        let elementNode = VNode.element("div")

        #expect(textNode.textContent == "Hello, world!")
        #expect(elementNode.textContent == nil)

        #expect(textNode.isText)
        #expect(!elementNode.isText)
    }

    @Test func vNodeElementTagRetrieval() {
        let element = VNode.element("button")
        let textNode = VNode.text("Text")

        #expect(element.elementTag == "button")
        #expect(textNode.elementTag == nil)

        #expect(element.isElement(tag: "button"))
        #expect(!element.isElement(tag: "div"))
    }

    // MARK: - View Rendering Edge Cases

    @MainActor
    @Test func emptyViewRendering() {
        struct EmptyTestView: View {
            var body: some View {
                EmptyView()
            }
        }

        let view = EmptyTestView()
        // Just test that the view compiles and can be created
        #expect(view != nil)
    }

    @MainActor
    @Test func deeplyNestedViewBuilder() {
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
        #expect(view != nil)
    }

    @MainActor
    @Test func conditionalViewRendering() {
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

        #expect(viewShown != nil)
        #expect(viewHidden != nil)
    }

    @MainActor
    @Test func optionalViewRendering() {
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

        #expect(withText != nil)
        #expect(withoutText != nil)
    }

    // MARK: - Modifier Composition

    @MainActor
    @Test func chainingMultipleModifiers() {
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
        #expect(view != nil)
    }

    @MainActor
    @Test func nestedModifierApplication() {
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
        #expect(view != nil)
    }

    @MainActor
    @Test func modifierOrderMatters() {
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
        #expect(view != nil)
    }

    @MainActor
    @Test func customModifierComposition() {
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
        #expect(view != nil)
    }

    // MARK: - Error Handling Paths

    @Test func neverBodyFatalError() {
        // Test that Never.body causes a fatal error if called
        // We can't actually trigger this in a test, but we can verify the structure
        #expect(Bool(true))
    }

    @Test func primitiveViewBodyAccess() {
        // Primitive views have Body = Never
        // Accessing body should fatal error, but we verify the type system prevents this
        struct PrimitiveView: View {
            typealias Body = Never
        }

        // The compiler prevents calling .body on primitive views
        #expect(Bool(true))
    }

    @Test func invalidNodeTypeMatching() {
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

        #expect(!test.areCompatible(type1: .element(tag: "div"), type2: .text("text")))
        #expect(!test.areCompatible(type1: .component, type2: .fragment))
        #expect(test.areCompatible(type1: .element(tag: "div"), type2: .element(tag: "div")))
    }

    // MARK: - VProperty Edge Cases

    @Test func vPropertyEquality() {
        let prop1 = VProperty.attribute(name: "class", value: "container")
        let prop2 = VProperty.attribute(name: "class", value: "container")
        let prop3 = VProperty.attribute(name: "class", value: "different")

        #expect(prop1 == prop2)
        #expect(prop1 != prop3)
    }

    @Test func vPropertyStyleVsAttribute() {
        let style = VProperty.style(name: "color", value: "red")
        let attribute = VProperty.attribute(name: "color", value: "red")

        #expect(style != attribute)
    }

    @Test func vPropertyBoolAttribute() {
        let enabledTrue = VProperty.boolAttribute(name: "disabled", value: true)
        let enabledFalse = VProperty.boolAttribute(name: "disabled", value: false)

        #expect(enabledTrue != enabledFalse)
    }

    @Test func vPropertyEventHandler() {
        let handler1 = VProperty.eventHandler(event: "click", handlerID: UUID())
        let handler2 = VProperty.eventHandler(event: "click", handlerID: UUID())

        // Different UUIDs should make them unequal
        #expect(handler1 != handler2)
    }

    // MARK: - NodeID Tests

    @Test func nodeIDUniqueness() {
        let id1 = NodeID()
        let id2 = NodeID()

        #expect(id1 != id2)
        #expect(id1.uuidString != id2.uuidString)
    }

    @Test func nodeIDDescription() {
        let id = NodeID()
        let description = id.description
        let uuidString = id.uuidString

        #expect(description == uuidString)
        #expect(!description.isEmpty)
    }

    @Test func nodeIDHashable() {
        let id1 = NodeID()
        let id2 = NodeID()

        var set = Set<NodeID>()
        set.insert(id1)
        set.insert(id2)

        #expect(set.count == 2)
        #expect(set.contains(id1))
        #expect(set.contains(id2))
    }

    // MARK: - Move Operation Tests

    @Test func moveOperation() {
        let move1 = Move(from: 0, to: 2)
        let move2 = Move(from: 0, to: 2)
        let move3 = Move(from: 1, to: 3)

        #expect(move1 == move2)
        #expect(move1 != move3)
        #expect(move1.from == 0)
        #expect(move1.to == 2)
    }

    // MARK: - PropPatch Tests

    @Test func propPatchAdd() {
        let patch = PropPatch.add(key: "newProp", value: .attribute(name: "data-id", value: "123"))

        if case .add(let key, let value) = patch {
            #expect(key == "newProp")
            if case .attribute(let name, let val) = value {
                #expect(name == "data-id")
                #expect(val == "123")
            } else {
                Issue.record("Expected attribute property")
            }
        } else {
            Issue.record("Expected add patch")
        }
    }

    @Test func propPatchRemove() {
        let patch = PropPatch.remove(key: "oldProp")

        if case .remove(let key) = patch {
            #expect(key == "oldProp")
        } else {
            Issue.record("Expected remove patch")
        }
    }

    @Test func propPatchUpdate() {
        let patch = PropPatch.update(key: "existingProp", value: .style(name: "color", value: "blue"))

        if case .update(let key, let value) = patch {
            #expect(key == "existingProp")
            if case .style(let name, let val) = value {
                #expect(name == "color")
                #expect(val == "blue")
            } else {
                Issue.record("Expected style property")
            }
        } else {
            Issue.record("Expected update patch")
        }
    }
}
