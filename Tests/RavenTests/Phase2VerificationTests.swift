import XCTest
@testable import Raven

/// Comprehensive Phase 2 verification tests that validate interactive apps work.
///
/// These tests verify that:
/// 1. Counter app structure with @State is created correctly
/// 2. Button click actions can be extracted and simulated
/// 3. Layout views (VStack, HStack, ZStack) convert to VNode correctly
/// 4. View modifiers (.padding(), .frame(), .foregroundColor()) work correctly
/// 5. Complete Counter app integration with state and interactions
@MainActor
final class Phase2VerificationTests: XCTestCase {

    // MARK: - Test 1: Counter App Structure

    func testCounterAppStructure() async throws {
        // Define a Counter view that uses @State
        @MainActor
        struct CounterView: View {
            @State var count = 0

            var body: some View {
                VStack {
                    Text("Count: \(count)")
                    Button("Increment") {
                        count += 1
                    }
                }
            }

            init() {}
        }

        // Create the counter view
        let counter = CounterView()

        // Verify it has a body
        let body = counter.body

        // The body should be a VStack
        XCTAssertTrue(type(of: body) is VStack<TupleView<(Text, Button<Text>)>>.Type,
                      "Counter body should be a VStack with Text and Button")
    }

    func testCounterStateInitialization() async throws {
        @MainActor
        struct CounterView: View {
            @State var count = 0

            var body: some View {
                Text("Count: \(count)")
            }

            init() {}
        }

        let counter = CounterView()

        // Access the body to verify state is initialized
        let body = counter.body

        // The body should contain a Text view
        XCTAssertTrue(type(of: body) is Text.Type)
    }

    func testCounterViewWithMultipleStates() async throws {
        @MainActor
        struct MultiStateView: View {
            @State var count = 0
            @State var name = "Counter"
            @State var isActive = true

            var body: some View {
                VStack {
                    Text("\(name): \(count)")
                    Button("Increment") {
                        count += 1
                    }
                }
            }

            init() {}
        }

        let view = MultiStateView()
        let body = view.body

        // Verify the view structure is created
        XCTAssertTrue(type(of: body) is VStack<TupleView<(Text, Button<Text>)>>.Type)
    }

    // MARK: - Test 2: Button Click Simulation

    func testButtonClickSimulation() async throws {
        // Create a button with action
        var clicked = false
        let button = Button("Click Me") {
            clicked = true
        }

        // Extract the action closure
        let action = button.actionClosure

        // Simulate clicking by calling the action
        action()

        // Verify state changes are triggered
        XCTAssertTrue(clicked, "Button action should have been called")
    }

    func testButtonClickWithStateUpdate() async throws {
        var counter = 0
        let button = Button("Increment") {
            counter += 1
        }

        // Initial value
        XCTAssertEqual(counter, 0)

        // Simulate clicking
        button.actionClosure()
        XCTAssertEqual(counter, 1)

        // Simulate multiple clicks
        button.actionClosure()
        XCTAssertEqual(counter, 2)

        button.actionClosure()
        XCTAssertEqual(counter, 3)
    }

    func testButtonActionExtraction() async throws {
        var actionLog: [String] = []

        let button1 = Button("Action 1") {
            actionLog.append("action1")
        }

        let button2 = Button("Action 2") {
            actionLog.append("action2")
        }

        // Execute actions
        button1.actionClosure()
        button2.actionClosure()
        button1.actionClosure()

        XCTAssertEqual(actionLog, ["action1", "action2", "action1"])
    }

    // MARK: - Test 3: Layout View Tests

    func testVStackConvertsToVNode() async throws {
        let vstack = VStack {
            Text("First")
            Text("Second")
        }

        let vnode = vstack.toVNode()

        // Verify it creates a div element
        XCTAssertTrue(vnode.isElement(tag: "div"), "VStack should create a div element")

        // Verify CSS properties
        XCTAssertEqual(vnode.props["display"], .style(name: "display", value: "flex"))
        XCTAssertEqual(vnode.props["flex-direction"], .style(name: "flex-direction", value: "column"))
        XCTAssertEqual(vnode.props["align-items"], .style(name: "align-items", value: "center"))
    }

    func testVStackWithAlignment() async throws {
        let vstackLeading = VStack(alignment: .leading) {
            Text("Leading")
        }

        let vnodeLeading = vstackLeading.toVNode()
        XCTAssertEqual(vnodeLeading.props["align-items"],
                       .style(name: "align-items", value: "flex-start"))

        let vstackTrailing = VStack(alignment: .trailing) {
            Text("Trailing")
        }

        let vnodeTrailing = vstackTrailing.toVNode()
        XCTAssertEqual(vnodeTrailing.props["align-items"],
                       .style(name: "align-items", value: "flex-end"))

        let vstackCenter = VStack(alignment: .center) {
            Text("Center")
        }

        let vnodeCenter = vstackCenter.toVNode()
        XCTAssertEqual(vnodeCenter.props["align-items"],
                       .style(name: "align-items", value: "center"))
    }

    func testVStackWithSpacing() async throws {
        let vstack = VStack(spacing: 16) {
            Text("First")
            Text("Second")
        }

        let vnode = vstack.toVNode()

        // Verify spacing is set as gap
        XCTAssertEqual(vnode.props["gap"], .style(name: "gap", value: "16.0px"))
    }

    func testHStackConvertsToVNode() async throws {
        let hstack = HStack {
            Text("Left")
            Text("Right")
        }

        let vnode = hstack.toVNode()

        // Verify it creates a div element
        XCTAssertTrue(vnode.isElement(tag: "div"), "HStack should create a div element")

        // Verify CSS properties
        XCTAssertEqual(vnode.props["display"], .style(name: "display", value: "flex"))
        XCTAssertEqual(vnode.props["flex-direction"], .style(name: "flex-direction", value: "row"))
        XCTAssertEqual(vnode.props["align-items"], .style(name: "align-items", value: "center"))
    }

    func testHStackWithAlignment() async throws {
        let hstackTop = HStack(alignment: .top) {
            Text("Top")
        }

        let vnodeTop = hstackTop.toVNode()
        XCTAssertEqual(vnodeTop.props["align-items"],
                       .style(name: "align-items", value: "flex-start"))

        let hstackBottom = HStack(alignment: .bottom) {
            Text("Bottom")
        }

        let vnodeBottom = hstackBottom.toVNode()
        XCTAssertEqual(vnodeBottom.props["align-items"],
                       .style(name: "align-items", value: "flex-end"))
    }

    func testHStackWithSpacing() async throws {
        let hstack = HStack(spacing: 8) {
            Text("A")
            Text("B")
            Text("C")
        }

        let vnode = hstack.toVNode()

        // Verify spacing is set as gap
        XCTAssertEqual(vnode.props["gap"], .style(name: "gap", value: "8.0px"))
    }

    func testZStackConvertsToVNode() async throws {
        let zstack = ZStack {
            Text("Background")
            Text("Foreground")
        }

        let vnode = zstack.toVNode()

        // Verify it creates a div element
        XCTAssertTrue(vnode.isElement(tag: "div"), "ZStack should create a div element")

        // Verify CSS properties (ZStack uses CSS Grid)
        XCTAssertEqual(vnode.props["display"], .style(name: "display", value: "grid"))
        XCTAssertEqual(vnode.props["grid-template-columns"],
                       .style(name: "grid-template-columns", value: "1fr"))
        XCTAssertEqual(vnode.props["grid-template-rows"],
                       .style(name: "grid-template-rows", value: "1fr"))
        XCTAssertEqual(vnode.props["place-items"],
                       .style(name: "place-items", value: "center center"))
    }

    func testZStackWithAlignment() async throws {
        let zstackTopLeading = ZStack(alignment: .topLeading) {
            Text("Content")
        }

        let vnodeTopLeading = zstackTopLeading.toVNode()
        XCTAssertEqual(vnodeTopLeading.props["place-items"],
                       .style(name: "place-items", value: "flex-start flex-start"))

        let zstackBottomTrailing = ZStack(alignment: .bottomTrailing) {
            Text("Content")
        }

        let vnodeBottomTrailing = zstackBottomTrailing.toVNode()
        XCTAssertEqual(vnodeBottomTrailing.props["place-items"],
                       .style(name: "place-items", value: "flex-end flex-end"))
    }

    // MARK: - Test 4: Modifier Tests

    func testPaddingModifier() async throws {
        let view = Text("Hello").padding()

        let vnode = view.toVNode()

        // Verify it creates a wrapper div
        XCTAssertTrue(vnode.isElement(tag: "div"), "Padding should wrap in a div")

        // Verify padding style is set (default is 8px)
        XCTAssertEqual(vnode.props["padding"], .style(name: "padding", value: "8.0px"))
    }

    func testPaddingModifierWithCustomValue() async throws {
        let view = Text("Hello").padding(16)

        let vnode = view.toVNode()

        // Verify custom padding value
        XCTAssertEqual(vnode.props["padding"], .style(name: "padding", value: "16.0px"))
    }

    func testPaddingModifierWithEdgeInsets() async throws {
        let view = Text("Hello").padding(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20))

        let vnode = view.toVNode()

        // Verify individual edge padding
        XCTAssertEqual(vnode.props["padding-top"], .style(name: "padding-top", value: "10.0px"))
        XCTAssertEqual(vnode.props["padding-left"], .style(name: "padding-left", value: "20.0px"))
        XCTAssertEqual(vnode.props["padding-bottom"], .style(name: "padding-bottom", value: "10.0px"))
        XCTAssertEqual(vnode.props["padding-right"], .style(name: "padding-right", value: "20.0px"))
    }

    func testFrameModifier() async throws {
        let view = Text("Hello").frame(width: 100, height: 50)

        let vnode = view.toVNode()

        // Verify it creates a wrapper div
        XCTAssertTrue(vnode.isElement(tag: "div"), "Frame should wrap in a div")

        // Verify size styles
        XCTAssertEqual(vnode.props["width"], .style(name: "width", value: "100.0px"))
        XCTAssertEqual(vnode.props["height"], .style(name: "height", value: "50.0px"))
    }

    func testFrameModifierWidthOnly() async throws {
        let view = Text("Hello").frame(width: 200)

        let vnode = view.toVNode()

        // Verify only width is set
        XCTAssertEqual(vnode.props["width"], .style(name: "width", value: "200.0px"))
        XCTAssertNil(vnode.props["height"])
    }

    func testFrameModifierHeightOnly() async throws {
        let view = Text("Hello").frame(height: 75)

        let vnode = view.toVNode()

        // Verify only height is set
        XCTAssertNil(vnode.props["width"])
        XCTAssertEqual(vnode.props["height"], .style(name: "height", value: "75.0px"))
    }

    func testForegroundColorModifier() async throws {
        let view = Text("Hello").foregroundColor(.blue)

        let vnode = view.toVNode()

        // Verify it creates a wrapper div
        XCTAssertTrue(vnode.isElement(tag: "div"), "ForegroundColor should wrap in a div")

        // Verify color style
        XCTAssertEqual(vnode.props["color"], .style(name: "color", value: "blue"))
    }

    func testForegroundColorModifierWithCustomColor() async throws {
        let view = Text("Hello").foregroundColor(.red)

        let vnode = view.toVNode()

        XCTAssertEqual(vnode.props["color"], .style(name: "color", value: "red"))
    }

    func testForegroundColorModifierWithRGBColor() async throws {
        let customColor = Color(red: 1.0, green: 0.5, blue: 0.0)
        let view = Text("Hello").foregroundColor(customColor)

        let vnode = view.toVNode()

        // Verify RGB color is converted to CSS
        XCTAssertEqual(vnode.props["color"], .style(name: "color", value: "rgb(255, 127, 0)"))
    }

    func testModifierChaining() async throws {
        let view = Text("Hello")
            .padding(10)
            .frame(width: 150, height: 50)
            .foregroundColor(.blue)

        // Verify the view structure is created
        // The outermost modifier should be foregroundColor
        let outerVNode = view.toVNode()
        XCTAssertTrue(outerVNode.isElement(tag: "div"))
        XCTAssertEqual(outerVNode.props["color"], .style(name: "color", value: "blue"))
    }

    // MARK: - Test 5: Integration Test - Complete Counter App

    func testCompleteCounterAppIntegration() async throws {
        // Define a complete Counter view
        @MainActor
        struct CounterApp: View {
            @State var count = 0

            var body: some View {
                VStack(spacing: 12) {
                    Text("Count: \(count)")
                        .foregroundColor(.blue)
                    Button("Increment") {
                        count += 1
                    }
                    .padding()
                }
            }

            init() {}
        }

        // Create the app
        let app = CounterApp()

        // Verify initial state
        let body = app.body

        // The body should be a VStack
        XCTAssertTrue(String(describing: type(of: body)).contains("VStack"),
                      "App body should be a VStack")
    }

    func testCounterButtonInteraction() async throws {
        // Test that button actions can be extracted and executed
        var counter = 0

        let button = Button("Increment") {
            counter += 1
        }

        // Create VNode to verify structure
        let vnode = button.toVNode()
        XCTAssertTrue(vnode.isElement(tag: "button"))
        XCTAssertNotNil(vnode.props["onClick"])

        // Simulate interaction
        XCTAssertEqual(counter, 0)
        button.actionClosure()
        XCTAssertEqual(counter, 1)
        button.actionClosure()
        XCTAssertEqual(counter, 2)
    }

    func testCounterWithStateCallback() async throws {
        let state = State(wrappedValue: 0)
        var updateCount = 0

        // Set update callback
        state.setUpdateCallback {
            updateCount += 1
        }

        // Simulate button actions that modify state
        let incrementAction: @Sendable @MainActor () -> Void = {
            state.wrappedValue += 1
        }

        // Initial state
        XCTAssertEqual(state.wrappedValue, 0)
        XCTAssertEqual(updateCount, 0)

        // Simulate button clicks
        incrementAction()
        XCTAssertEqual(state.wrappedValue, 1)
        XCTAssertEqual(updateCount, 1)

        incrementAction()
        XCTAssertEqual(state.wrappedValue, 2)
        XCTAssertEqual(updateCount, 2)

        incrementAction()
        XCTAssertEqual(state.wrappedValue, 3)
        XCTAssertEqual(updateCount, 3)
    }

    func testCompleteLayoutPipeline() async throws {
        // Test a complete view hierarchy with layouts and modifiers
        let view = VStack(spacing: 16) {
            Text("Title")
                .foregroundColor(.blue)
                .padding(8)

            HStack(spacing: 8) {
                Button("Cancel") {
                    print("Cancelled")
                }
                Button("OK") {
                    print("OK")
                }
            }
            .padding(12)
        }
        .frame(width: 300)

        // Convert to VNode and verify structure
        let vnode = view.toVNode()

        // Outermost should be frame modifier (div)
        XCTAssertTrue(vnode.isElement(tag: "div"))
        XCTAssertEqual(vnode.props["width"], .style(name: "width", value: "300.0px"))
    }

    func testMultipleButtonsWithDifferentActions() async throws {
        var action1Called = false
        var action2Called = false
        var action3Called = false

        let button1 = Button("Action 1") { action1Called = true }
        let button2 = Button("Action 2") { action2Called = true }
        let button3 = Button("Action 3") { action3Called = true }

        // Convert to VNodes
        let vnode1 = button1.toVNode()
        let vnode2 = button2.toVNode()
        let vnode3 = button3.toVNode()

        // Verify all are button elements
        XCTAssertTrue(vnode1.isElement(tag: "button"))
        XCTAssertTrue(vnode2.isElement(tag: "button"))
        XCTAssertTrue(vnode3.isElement(tag: "button"))

        // Execute actions
        XCTAssertFalse(action1Called)
        XCTAssertFalse(action2Called)
        XCTAssertFalse(action3Called)

        button1.actionClosure()
        XCTAssertTrue(action1Called)
        XCTAssertFalse(action2Called)
        XCTAssertFalse(action3Called)

        button2.actionClosure()
        XCTAssertTrue(action1Called)
        XCTAssertTrue(action2Called)
        XCTAssertFalse(action3Called)

        button3.actionClosure()
        XCTAssertTrue(action1Called)
        XCTAssertTrue(action2Called)
        XCTAssertTrue(action3Called)
    }

    func testZStackWithOverlayedContent() async throws {
        let view = ZStack {
            Color.blue
                .frame(width: 100, height: 100)
            Text("Overlay")
                .foregroundColor(.white)
        }

        let vnode = view.toVNode()

        // Verify ZStack creates a grid container
        XCTAssertTrue(vnode.isElement(tag: "div"))
        XCTAssertEqual(vnode.props["display"], .style(name: "display", value: "grid"))
    }

    func testColorView() async throws {
        let color = Color.red
        let vnode = color.toVNode()

        // Color renders as a div with background color
        XCTAssertTrue(vnode.isElement(tag: "div"))
        XCTAssertEqual(vnode.props["background-color"],
                       .style(name: "background-color", value: "red"))
        XCTAssertEqual(vnode.props["width"],
                       .style(name: "width", value: "100%"))
        XCTAssertEqual(vnode.props["height"],
                       .style(name: "height", value: "100%"))
    }

    func testNestedLayoutViews() async throws {
        let view = VStack {
            HStack {
                Text("A")
                Text("B")
            }
            HStack {
                Text("C")
                Text("D")
            }
        }

        let vnode = view.toVNode()

        // Verify outer VStack
        XCTAssertTrue(vnode.isElement(tag: "div"))
        XCTAssertEqual(vnode.props["flex-direction"],
                       .style(name: "flex-direction", value: "column"))
    }

    func testEdgeInsetsUniformValue() {
        let insets = EdgeInsets(8)

        XCTAssertEqual(insets.top, 8)
        XCTAssertEqual(insets.leading, 8)
        XCTAssertEqual(insets.bottom, 8)
        XCTAssertEqual(insets.trailing, 8)
    }

    func testEdgeInsetsIndividualValues() {
        let insets = EdgeInsets(top: 10, leading: 20, bottom: 30, trailing: 40)

        XCTAssertEqual(insets.top, 10)
        XCTAssertEqual(insets.leading, 20)
        XCTAssertEqual(insets.bottom, 30)
        XCTAssertEqual(insets.trailing, 40)
    }

    func testAlignmentValues() {
        // Test all alignment values
        XCTAssertEqual(Alignment.center.horizontal, .center)
        XCTAssertEqual(Alignment.center.vertical, .center)

        XCTAssertEqual(Alignment.topLeading.horizontal, .leading)
        XCTAssertEqual(Alignment.topLeading.vertical, .top)

        XCTAssertEqual(Alignment.bottomTrailing.horizontal, .trailing)
        XCTAssertEqual(Alignment.bottomTrailing.vertical, .bottom)
    }

    func testAlignmentCSSValues() {
        // Test CSS value conversion
        XCTAssertEqual(HorizontalAlignment.leading.cssValue, "flex-start")
        XCTAssertEqual(HorizontalAlignment.center.cssValue, "center")
        XCTAssertEqual(HorizontalAlignment.trailing.cssValue, "flex-end")

        XCTAssertEqual(VerticalAlignment.top.cssValue, "flex-start")
        XCTAssertEqual(VerticalAlignment.center.cssValue, "center")
        XCTAssertEqual(VerticalAlignment.bottom.cssValue, "flex-end")
    }
}
