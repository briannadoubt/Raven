import XCTest
@testable import Raven

/// Tests for interaction modifiers: .disabled, .onTapGesture, .onAppear, .onDisappear, .onChange
final class InteractionModifierTests: XCTestCase {

    // MARK: - Disabled Modifier Tests

    @MainActor
    func testDisabledModifier() {
        // Create a view with disabled modifier
        let view = Text("Button")
            .disabled(true)

        // Verify the type is correct
        XCTAssertTrue(view is _DisabledView<Text>)
    }

    @MainActor
    func testDisabledModifierVNode() {
        // Create a disabled view
        let view = Text("Content")
            .disabled(true)

        // Convert to VNode
        let vnode = view.toVNode()

        // Verify it's a div element (wrapper)
        XCTAssertEqual(vnode.elementTag, "div")

        // Verify the props contain disabled styling
        XCTAssertTrue(vnode.props.contains { key, value in
            if case .style(let name, let val) = value {
                return name == "pointer-events" && val == "none"
            }
            return false
        })

        XCTAssertTrue(vnode.props.contains { key, value in
            if case .style(let name, let val) = value {
                return name == "opacity" && val == "0.5"
            }
            return false
        })

        XCTAssertTrue(vnode.props.contains { key, value in
            if case .style(let name, let val) = value {
                return name == "cursor" && val == "not-allowed"
            }
            return false
        })
    }

    @MainActor
    func testDisabledModifierWhenFalse() {
        // Create a non-disabled view
        let view = Text("Content")
            .disabled(false)

        // Convert to VNode
        let vnode = view.toVNode()

        // When disabled is false, it should still create a wrapper but without the disabled styles
        XCTAssertEqual(vnode.elementTag, "div")
    }

    @MainActor
    func testDisabledWithButton() {
        // Create a button with disabled modifier
        let view = Button("Submit") { }
            .disabled(true)

        // Verify it compiles and type-checks
        let _ = view
    }

    // MARK: - OnTapGesture Modifier Tests

    @MainActor
    func testOnTapGestureModifier() {
        var tapped = false

        // Create a view with tap gesture
        let view = Text("Tap me")
            .onTapGesture {
                tapped = true
            }

        // Verify the type is correct
        XCTAssertTrue(view is _OnTapGestureView<Text>)
    }

    @MainActor
    func testOnTapGestureVNode() {
        // Create a view with tap gesture
        let view = Text("Tap me")
            .onTapGesture {
                print("Tapped")
            }

        // Convert to VNode
        let vnode = view.toVNode()

        // Verify it's a div element (wrapper with event handler)
        XCTAssertEqual(vnode.elementTag, "div")

        // Verify it has an event handler property
        let hasClickHandler = vnode.props.contains { key, value in
            if case .eventHandler(let event, _) = value {
                return event == "click"
            }
            return false
        }
        XCTAssertTrue(hasClickHandler)
    }

    @MainActor
    func testOnTapGestureWithCount() {
        // Create a view with double-tap gesture
        let view = Text("Double tap me")
            .onTapGesture(count: 2) {
                print("Double tapped")
            }

        // Verify it compiles
        let _ = view
    }

    @MainActor
    func testOnTapGestureWithImage() {
        // Test tap gesture on non-text view
        let view = Image(systemName: "star")
            .onTapGesture {
                print("Image tapped")
            }

        // Verify it compiles
        let _ = view
    }

    // MARK: - OnAppear Modifier Tests

    @MainActor
    func testOnAppearModifier() {
        var appeared = false

        // Create a view with onAppear
        let view = Text("Content")
            .onAppear {
                appeared = true
            }

        // Verify the type is correct
        XCTAssertTrue(view is _OnAppearView<Text>)
    }

    @MainActor
    func testOnAppearVNode() {
        // Create a view with onAppear
        let view = Text("Content")
            .onAppear {
                print("View appeared")
            }

        // Convert to VNode
        let vnode = view.toVNode()

        // Verify it's a div element with lifecycle handler
        XCTAssertEqual(vnode.elementTag, "div")

        // Verify it has an appear event handler
        let hasAppearHandler = vnode.props.contains { key, value in
            if case .eventHandler(let event, _) = value {
                return event == "appear"
            }
            return false
        }
        XCTAssertTrue(hasAppearHandler)
    }

    // MARK: - OnDisappear Modifier Tests

    @MainActor
    func testOnDisappearModifier() {
        var disappeared = false

        // Create a view with onDisappear
        let view = Text("Content")
            .onDisappear {
                disappeared = true
            }

        // Verify the type is correct
        XCTAssertTrue(view is _OnDisappearView<Text>)
    }

    @MainActor
    func testOnDisappearVNode() {
        // Create a view with onDisappear
        let view = Text("Content")
            .onDisappear {
                print("View disappeared")
            }

        // Convert to VNode
        let vnode = view.toVNode()

        // Verify it's a div element with lifecycle handler
        XCTAssertEqual(vnode.elementTag, "div")

        // Verify it has a disappear event handler
        let hasDisappearHandler = vnode.props.contains { key, value in
            if case .eventHandler(let event, _) = value {
                return event == "disappear"
            }
            return false
        }
        XCTAssertTrue(hasDisappearHandler)
    }

    @MainActor
    func testOnAppearAndOnDisappearTogether() {
        // Test using both lifecycle modifiers
        let view = Text("Content")
            .onAppear {
                print("Appeared")
            }
            .onDisappear {
                print("Disappeared")
            }

        // Verify it compiles
        let _ = view
    }

    // MARK: - OnChange Modifier Tests

    @MainActor
    func testOnChangeModifier() {
        let value = "test"
        var changedValue: String?

        // Create a view with onChange
        let view = Text("Content")
            .onChange(of: value) { newValue in
                changedValue = newValue
            }

        // Verify the type is correct
        XCTAssertTrue(view is _OnChangeView<Text, String>)
    }

    @MainActor
    func testOnChangeVNode() {
        let value = 42

        // Create a view with onChange
        let view = Text("Content")
            .onChange(of: value) { newValue in
                print("Value changed to \(newValue)")
            }

        // Convert to VNode
        let vnode = view.toVNode()

        // Verify it's a div element
        XCTAssertEqual(vnode.elementTag, "div")

        // Verify it has change tracking attributes
        let hasChangeHandler = vnode.props.contains { key, value in
            if case .eventHandler(let event, _) = value {
                return event == "change"
            }
            return false
        }
        XCTAssertTrue(hasChangeHandler)
    }

    @MainActor
    func testOnChangeWithDifferentTypes() {
        // Test onChange with Int
        let intView = Text("Int")
            .onChange(of: 10) { newValue in
                print("Int: \(newValue)")
            }
        let _ = intView

        // Test onChange with String
        let stringView = Text("String")
            .onChange(of: "test") { newValue in
                print("String: \(newValue)")
            }
        let _ = stringView

        // Test onChange with Bool
        let boolView = Text("Bool")
            .onChange(of: true) { newValue in
                print("Bool: \(newValue)")
            }
        let _ = boolView
    }

    // MARK: - Modifier Composition Tests

    @MainActor
    func testModifierComposition() {
        // Test chaining multiple interaction modifiers
        let view = Text("Content")
            .onAppear {
                print("Appeared")
            }
            .onTapGesture {
                print("Tapped")
            }
            .disabled(false)

        // Verify it compiles
        let _ = view
    }

    @MainActor
    func testInteractionModifiersWithLayoutModifiers() {
        // Mix interaction modifiers with layout modifiers
        let view = Text("Content")
            .padding(10)
            .onTapGesture {
                print("Tapped")
            }
            .background(.blue)
            .disabled(false)
            .cornerRadius(5)

        // Verify it compiles
        let _ = view
    }

    @MainActor
    func testComplexModifierChain() {
        // Create a complex chain of modifiers
        let view = Button("Action") { }
            .padding()
            .background(.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            .disabled(false)
            .onTapGesture {
                print("Button tapped")
            }
            .onAppear {
                print("Button appeared")
            }
            .shadow(color: .gray, radius: 3, x: 0, y: 2)

        // Verify it compiles
        let _ = view
    }

    // MARK: - Sendable Conformance Tests

    @MainActor
    func testInteractionModifiersAreSendable() {
        // Verify that interaction views conform to Sendable
        let disabledView: any View & Sendable = Text("Test").disabled(true)
        let tapView: any View & Sendable = Text("Test").onTapGesture { }
        let appearView: any View & Sendable = Text("Test").onAppear { }
        let disappearView: any View & Sendable = Text("Test").onDisappear { }
        let changeView: any View & Sendable = Text("Test").onChange(of: 1) { _ in }

        // These should all compile without issues
        let _ = disabledView
        let _ = tapView
        let _ = appearView
        let _ = disappearView
        let _ = changeView
    }

    // MARK: - Edge Cases

    @MainActor
    func testDisabledWithComplexView() {
        // Test disabled on a complex view hierarchy
        let view = VStack {
            Text("Title")
            Button("Action") { }
            HStack {
                Text("Left")
                Text("Right")
            }
        }
        .disabled(true)

        // Verify it compiles
        let _ = view
    }

    @MainActor
    func testOnChangeWithOptionalValue() {
        // Test onChange with optional values
        let value: Int? = 42

        let view = Text("Content")
            .onChange(of: value) { newValue in
                print("Value changed to \(String(describing: newValue))")
            }

        // Verify it compiles
        let _ = view
    }
}
