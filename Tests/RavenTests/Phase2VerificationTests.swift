import Testing
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
@Suite struct Phase2VerificationTests {

    // MARK: - Test 1: Counter App Structure

    @Test func counterAppStructure() async throws {
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
        }

        // Create the counter view
        let counter = CounterView()

        // Verify it has a body
        let body = counter.body

        // The body should be a VStack
        #expect(String(describing: type(of: body)).contains("VStack"))
    }

    @Test func counterStateInitialization() async throws {
        @MainActor
        struct CounterView: View {
            @State var count = 0

            var body: some View {
                Text("Count: \(count)")
            }
        }

        let counter = CounterView()

        // Access the body to verify state is initialized
        let body = counter.body

        // The body should contain a Text view
        #expect(type(of: body) is Text.Type)
    }

    @Test func counterViewWithMultipleStates() async throws {
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
        }

        let view = MultiStateView()
        let body = view.body

        // Verify the view structure is created
        #expect(String(describing: type(of: body)).contains("VStack"))
    }

    // MARK: - Test 2: Button Click Simulation

    @Test func buttonClickSimulation() async throws {
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
        #expect(clicked)
    }

    @Test func buttonClickWithStateUpdate() async throws {
        var counter = 0
        let button = Button("Increment") {
            counter += 1
        }

        // Initial value
        #expect(counter == 0)

        // Simulate clicking
        button.actionClosure()
        #expect(counter == 1)

        // Simulate multiple clicks
        button.actionClosure()
        #expect(counter == 2)

        button.actionClosure()
        #expect(counter == 3)
    }

    @Test func buttonActionExtraction() async throws {
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

        #expect(actionLog == ["action1", "action2", "action1"])
    }

    // MARK: - Test 3: Layout View Tests

    @Test func vStackConvertsToVNode() async throws {
        let vstack = VStack {
            Text("First")
            Text("Second")
        }

        let vnode = vstack.toVNode()

        // Verify it creates a div element
        #expect(vnode.isElement(tag: "div"))

        // Verify CSS properties
        #expect(vnode.props["display"] == .style(name: "display", value: "flex"))
        #expect(vnode.props["flex-direction"] == .style(name: "flex-direction", value: "column"))
        #expect(vnode.props["align-items"] == .style(name: "align-items", value: "center"))
    }

    @Test func vStackWithAlignment() async throws {
        let vstackLeading = VStack(alignment: .leading) {
            Text("Leading")
        }

        let vnodeLeading = vstackLeading.toVNode()
        #expect(vnodeLeading.props["align-items"] ==
                       .style(name: "align-items", value: "flex-start"))

        let vstackTrailing = VStack(alignment: .trailing) {
            Text("Trailing")
        }

        let vnodeTrailing = vstackTrailing.toVNode()
        #expect(vnodeTrailing.props["align-items"] ==
                       .style(name: "align-items", value: "flex-end"))

        let vstackCenter = VStack(alignment: .center) {
            Text("Center")
        }

        let vnodeCenter = vstackCenter.toVNode()
        #expect(vnodeCenter.props["align-items"] ==
                       .style(name: "align-items", value: "center"))
    }

    @Test func vStackWithSpacing() async throws {
        let vstack = VStack(spacing: 16) {
            Text("First")
            Text("Second")
        }

        let vnode = vstack.toVNode()

        // Verify spacing is set as gap
        #expect(vnode.props["gap"] == .style(name: "gap", value: "16.0px"))
    }

    @Test func hStackConvertsToVNode() async throws {
        let hstack = HStack {
            Text("Left")
            Text("Right")
        }

        let vnode = hstack.toVNode()

        // Verify it creates a div element
        #expect(vnode.isElement(tag: "div"))

        // Verify CSS properties
        #expect(vnode.props["display"] == .style(name: "display", value: "flex"))
        #expect(vnode.props["flex-direction"] == .style(name: "flex-direction", value: "row"))
        #expect(vnode.props["align-items"] == .style(name: "align-items", value: "center"))
    }

    @Test func hStackWithAlignment() async throws {
        let hstackTop = HStack(alignment: .top) {
            Text("Top")
        }

        let vnodeTop = hstackTop.toVNode()
        #expect(vnodeTop.props["align-items"] ==
                       .style(name: "align-items", value: "flex-start"))

        let hstackBottom = HStack(alignment: .bottom) {
            Text("Bottom")
        }

        let vnodeBottom = hstackBottom.toVNode()
        #expect(vnodeBottom.props["align-items"] ==
                       .style(name: "align-items", value: "flex-end"))
    }

    @Test func hStackWithSpacing() async throws {
        let hstack = HStack(spacing: 8) {
            Text("A")
            Text("B")
            Text("C")
        }

        let vnode = hstack.toVNode()

        // Verify spacing is set as gap
        #expect(vnode.props["gap"] == .style(name: "gap", value: "8.0px"))
    }

    @Test func zStackConvertsToVNode() async throws {
        let zstack = ZStack {
            Text("Background")
            Text("Foreground")
        }

        let vnode = zstack.toVNode()

        // Verify it creates a div element
        #expect(vnode.isElement(tag: "div"))

        // Verify CSS properties (ZStack uses CSS Grid)
        #expect(vnode.props["display"] == .style(name: "display", value: "grid"))
        #expect(vnode.props["grid-template-columns"] ==
                       .style(name: "grid-template-columns", value: "1fr"))
        #expect(vnode.props["grid-template-rows"] ==
                       .style(name: "grid-template-rows", value: "1fr"))
        #expect(vnode.props["place-items"] ==
                       .style(name: "place-items", value: "center center"))
    }

    @Test func zStackWithAlignment() async throws {
        let zstackTopLeading = ZStack(alignment: .topLeading) {
            Text("Content")
        }

        let vnodeTopLeading = zstackTopLeading.toVNode()
        #expect(vnodeTopLeading.props["place-items"] ==
                       .style(name: "place-items", value: "flex-start flex-start"))

        let zstackBottomTrailing = ZStack(alignment: .bottomTrailing) {
            Text("Content")
        }

        let vnodeBottomTrailing = zstackBottomTrailing.toVNode()
        #expect(vnodeBottomTrailing.props["place-items"] ==
                       .style(name: "place-items", value: "flex-end flex-end"))
    }

    // MARK: - Test 4: Modifier Tests

    @Test func paddingModifier() async throws {
        let view = Text("Hello").padding()

        let vnode = view.toVNode()

        // Verify it creates a wrapper div
        #expect(vnode.isElement(tag: "div"))

        // Verify padding style is set (default is 8px)
        #expect(vnode.props["padding"] == .style(name: "padding", value: "8.0px"))
    }

    @Test func paddingModifierWithCustomValue() async throws {
        let view = Text("Hello").padding(16)

        let vnode = view.toVNode()

        // Verify custom padding value
        #expect(vnode.props["padding"] == .style(name: "padding", value: "16.0px"))
    }

    @Test func paddingModifierWithEdgeInsets() async throws {
        let view = Text("Hello").padding(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20))

        let vnode = view.toVNode()

        // Verify individual edge padding
        #expect(vnode.props["padding-top"] == .style(name: "padding-top", value: "10.0px"))
        #expect(vnode.props["padding-left"] == .style(name: "padding-left", value: "20.0px"))
        #expect(vnode.props["padding-bottom"] == .style(name: "padding-bottom", value: "10.0px"))
        #expect(vnode.props["padding-right"] == .style(name: "padding-right", value: "20.0px"))
    }

    @Test func frameModifier() async throws {
        let view = Text("Hello").frame(width: 100, height: 50)

        let vnode = view.toVNode()

        // Verify it creates a wrapper div
        #expect(vnode.isElement(tag: "div"))

        // Verify size styles
        #expect(vnode.props["width"] == .style(name: "width", value: "100.0px"))
        #expect(vnode.props["height"] == .style(name: "height", value: "50.0px"))
    }

    @Test func frameModifierWidthOnly() async throws {
        let view = Text("Hello").frame(width: 200)

        let vnode = view.toVNode()

        // Verify only width is set
        #expect(vnode.props["width"] == .style(name: "width", value: "200.0px"))
        #expect(vnode.props["height"] == nil)
    }

    @Test func frameModifierHeightOnly() async throws {
        let view = Text("Hello").frame(height: 75)

        let vnode = view.toVNode()

        // Verify only height is set
        #expect(vnode.props["width"] == nil)
        #expect(vnode.props["height"] == .style(name: "height", value: "75.0px"))
    }

    @Test func foregroundColorModifier() async throws {
        let view = Text("Hello").foregroundColor(.blue)

        let vnode = view.toVNode()

        // Verify it creates a wrapper div
        #expect(vnode.isElement(tag: "div"))

        // Verify color style
        #expect(vnode.props["color"] == .style(name: "color", value: "blue"))
    }

    @Test func foregroundColorModifierWithCustomColor() async throws {
        let view = Text("Hello").foregroundColor(.red)

        let vnode = view.toVNode()

        #expect(vnode.props["color"] == .style(name: "color", value: "red"))
    }

    @Test func foregroundColorModifierWithRGBColor() async throws {
        let customColor = Color(red: 1.0, green: 0.5, blue: 0.0)
        let view = Text("Hello").foregroundColor(customColor)

        let vnode = view.toVNode()

        // Verify RGB color is converted to CSS
        #expect(vnode.props["color"] == .style(name: "color", value: "rgb(255, 127, 0)"))
    }

    @Test func modifierChaining() async throws {
        let view = Text("Hello")
            .padding(10)
            .frame(width: 150, height: 50)
            .foregroundColor(.blue)

        // Verify the view structure is created
        // The outermost modifier should be foregroundColor
        let outerVNode = view.toVNode()
        #expect(outerVNode.isElement(tag: "div"))
        #expect(outerVNode.props["color"] == .style(name: "color", value: "blue"))
    }

    // MARK: - Test 5: Integration Test - Complete Counter App

    @Test func completeCounterAppIntegration() async throws {
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
        }

        // Create the app
        let app = CounterApp()

        // Verify initial state
        let body = app.body

        // The body should be a VStack
        #expect(String(describing: type(of: body)).contains("VStack"))
    }

    @Test func counterButtonInteraction() async throws {
        // Test that button actions can be extracted and executed
        var counter = 0

        let button = Button("Increment") {
            counter += 1
        }

        // Create VNode to verify structure
        let vnode = button.toVNode()
        #expect(vnode.isElement(tag: "button"))
        #expect(vnode.props["onClick"] != nil)

        // Simulate interaction
        #expect(counter == 0)
        button.actionClosure()
        #expect(counter == 1)
        button.actionClosure()
        #expect(counter == 2)
    }

    @Test func counterWithStateCallback() async throws {
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
        #expect(state.wrappedValue == 0)
        #expect(updateCount == 0)

        // Simulate button clicks
        incrementAction()
        #expect(state.wrappedValue == 1)
        #expect(updateCount == 1)

        incrementAction()
        #expect(state.wrappedValue == 2)
        #expect(updateCount == 2)

        incrementAction()
        #expect(state.wrappedValue == 3)
        #expect(updateCount == 3)
    }

    @Test func completeLayoutPipeline() async throws {
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
        #expect(vnode.isElement(tag: "div"))
        #expect(vnode.props["width"] == .style(name: "width", value: "300.0px"))
    }

    @Test func multipleButtonsWithDifferentActions() async throws {
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
        #expect(vnode1.isElement(tag: "button"))
        #expect(vnode2.isElement(tag: "button"))
        #expect(vnode3.isElement(tag: "button"))

        // Execute actions
        #expect(!action1Called)
        #expect(!action2Called)
        #expect(!action3Called)

        button1.actionClosure()
        #expect(action1Called)
        #expect(!action2Called)
        #expect(!action3Called)

        button2.actionClosure()
        #expect(action1Called)
        #expect(action2Called)
        #expect(!action3Called)

        button3.actionClosure()
        #expect(action1Called)
        #expect(action2Called)
        #expect(action3Called)
    }

    @Test func zStackWithOverlayedContent() async throws {
        let view = ZStack {
            Color.blue
                .frame(width: 100, height: 100)
            Text("Overlay")
                .foregroundColor(.white)
        }

        let vnode = view.toVNode()

        // Verify ZStack creates a grid container
        #expect(vnode.isElement(tag: "div"))
        #expect(vnode.props["display"] == .style(name: "display", value: "grid"))
    }

    @Test func colorView() async throws {
        let color = Color.red
        let vnode = color.toVNode()

        // Color renders as a div with background color
        #expect(vnode.isElement(tag: "div"))
        #expect(vnode.props["background-color"] ==
                       .style(name: "background-color", value: "red"))
        #expect(vnode.props["width"] ==
                       .style(name: "width", value: "100%"))
        #expect(vnode.props["height"] ==
                       .style(name: "height", value: "100%"))
    }

    @Test func nestedLayoutViews() async throws {
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
        #expect(vnode.isElement(tag: "div"))
        #expect(vnode.props["flex-direction"] ==
                       .style(name: "flex-direction", value: "column"))
    }

    @Test func edgeInsetsUniformValue() {
        let insets = EdgeInsets(8)

        #expect(insets.top == 8)
        #expect(insets.leading == 8)
        #expect(insets.bottom == 8)
        #expect(insets.trailing == 8)
    }

    @Test func edgeInsetsIndividualValues() {
        let insets = EdgeInsets(top: 10, leading: 20, bottom: 30, trailing: 40)

        #expect(insets.top == 10)
        #expect(insets.leading == 20)
        #expect(insets.bottom == 30)
        #expect(insets.trailing == 40)
    }

    @Test func alignmentValues() {
        // Test all alignment values
        #expect(Alignment.center.horizontal == .center)
        #expect(Alignment.center.vertical == .center)

        #expect(Alignment.topLeading.horizontal == .leading)
        #expect(Alignment.topLeading.vertical == .top)

        #expect(Alignment.bottomTrailing.horizontal == .trailing)
        #expect(Alignment.bottomTrailing.vertical == .bottom)
    }

    @Test func alignmentCSSValues() {
        // Test CSS value conversion
        #expect(HorizontalAlignment.leading.cssValue == "flex-start")
        #expect(HorizontalAlignment.center.cssValue == "center")
        #expect(HorizontalAlignment.trailing.cssValue == "flex-end")

        #expect(VerticalAlignment.top.cssValue == "flex-start")
        #expect(VerticalAlignment.center.cssValue == "center")
        #expect(VerticalAlignment.bottom.cssValue == "flex-end")
    }
}
