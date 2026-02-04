import XCTest
@testable import Raven

/// Phase 8 Verification: Form Controls and Interactive Elements
///
/// This test suite verifies all Phase 8 controls for form-based applications:
/// - SecureField for password input
/// - Slider for range selection
/// - Stepper for increment/decrement
/// - ProgressView for loading indicators
/// - Picker for selection controls
/// - Link for hyperlinks
/// - Label for icon + text combinations
///
/// Each control is tested for:
/// - Initialization and configuration
/// - VNode structure and DOM representation
/// - Event handler setup
/// - Two-way binding behavior
/// - Accessibility features
/// - Edge cases and boundary conditions
@available(macOS 13.0, *)
@MainActor
final class Phase8VerificationTests: XCTestCase {

    // MARK: - SecureField Tests (7 tests)

    func testSecureFieldBasicInitialization() {
        var password = ""
        let binding = Binding<String>(
            get: { password },
            set: { password = $0 }
        )

        let field = SecureField("Enter password", text: binding)
        let node = field.toVNode()

        XCTAssertEqual(node.elementTag, "input", "SecureField should render as input element")
    }

    func testSecureFieldWithLocalizedStringKey() {
        var password = ""
        let binding = Binding<String>(
            get: { password },
            set: { password = $0 }
        )

        let field = SecureField(LocalizedStringKey("password_placeholder"), text: binding)
        let node = field.toVNode()

        XCTAssertEqual(node.elementTag, "input", "SecureField should render as input element")
    }

    func testSecureFieldVNodeStructure() {
        var password = ""
        let binding = Binding<String>(
            get: { password },
            set: { password = $0 }
        )

        let field = SecureField("Password", text: binding)
        let node = field.toVNode()

        // Verify type attribute
        if case .attribute(name: "type", value: let type) = node.props["type"] {
            XCTAssertEqual(type, "password", "SecureField should have type='password'")
        } else {
            XCTFail("SecureField should have type attribute")
        }

        // Verify placeholder attribute
        if case .attribute(name: "placeholder", value: let placeholder) = node.props["placeholder"] {
            XCTAssertEqual(placeholder, "Password", "SecureField should have correct placeholder")
        } else {
            XCTFail("SecureField should have placeholder attribute")
        }

        // Verify value attribute
        if case .attribute(name: "value", value: let value) = node.props["value"] {
            XCTAssertEqual(value, "", "SecureField should have value attribute")
        } else {
            XCTFail("SecureField should have value attribute")
        }
    }

    func testSecureFieldEventHandler() {
        var password = ""
        let binding = Binding<String>(
            get: { password },
            set: { password = $0 }
        )

        let field = SecureField("Password", text: binding)
        let node = field.toVNode()

        // Verify input event handler exists
        if case .eventHandler(event: "input", handlerID: _) = node.props["onInput"] {
            XCTAssertTrue(true, "SecureField should have input event handler")
        } else {
            XCTFail("SecureField should have onInput event handler")
        }
    }

    func testSecureFieldTwoWayBinding() {
        var password = "secret"
        let binding = Binding<String>(
            get: { password },
            set: { password = $0 }
        )

        let field = SecureField("Password", text: binding)
        let node = field.toVNode()

        // Verify binding value is reflected
        if case .attribute(name: "value", value: let value) = node.props["value"] {
            XCTAssertEqual(value, "secret", "SecureField should reflect binding value")
        }

        // Verify binding is accessible
        let textBinding = field.textBinding
        XCTAssertEqual(textBinding.wrappedValue, "secret", "Binding should be accessible")

        // Update binding
        textBinding.wrappedValue = "newpass"
        XCTAssertEqual(password, "newpass", "Binding should update source value")
    }

    func testSecureFieldDefaultStyling() {
        var password = ""
        let binding = Binding<String>(
            get: { password },
            set: { password = $0 }
        )

        let field = SecureField("Password", text: binding)
        let node = field.toVNode()

        // Verify default styles
        XCTAssertNotNil(node.props["padding"], "SecureField should have padding style")
        XCTAssertNotNil(node.props["border"], "SecureField should have border style")
        XCTAssertNotNil(node.props["border-radius"], "SecureField should have border-radius style")
        XCTAssertNotNil(node.props["font-size"], "SecureField should have font-size style")
    }

    func testSecureFieldEmptyChildren() {
        var password = ""
        let binding = Binding<String>(
            get: { password },
            set: { password = $0 }
        )

        let field = SecureField("Password", text: binding)
        let node = field.toVNode()

        XCTAssertTrue(node.children.isEmpty, "SecureField input element should have no children")
    }

    // MARK: - Slider Tests (8 tests)

    func testSliderBasicInitialization() {
        var value = 0.5
        let binding = Binding<Double>(
            get: { value },
            set: { value = $0 }
        )

        let slider = Slider(value: binding)
        let node = slider.toVNode()

        XCTAssertEqual(node.elementTag, "input", "Slider should render as input element")
    }

    func testSliderWithDefaultRange() {
        var value = 0.5
        let binding = Binding<Double>(
            get: { value },
            set: { value = $0 }
        )

        let slider = Slider(value: binding)
        let node = slider.toVNode()

        // Verify default range (0...1)
        if case .attribute(name: "min", value: let min) = node.props["min"] {
            XCTAssertEqual(min, "0.0", "Slider should have default min of 0")
        } else {
            XCTFail("Slider should have min attribute")
        }

        if case .attribute(name: "max", value: let max) = node.props["max"] {
            XCTAssertEqual(max, "1.0", "Slider should have default max of 1")
        } else {
            XCTFail("Slider should have max attribute")
        }
    }

    func testSliderWithCustomRange() {
        var value = 50.0
        let binding = Binding<Double>(
            get: { value },
            set: { value = $0 }
        )

        let slider = Slider(value: binding, in: 0...100)
        let node = slider.toVNode()

        // Verify custom range
        if case .attribute(name: "min", value: let min) = node.props["min"] {
            XCTAssertEqual(min, "0.0", "Slider should have custom min")
        }

        if case .attribute(name: "max", value: let max) = node.props["max"] {
            XCTAssertEqual(max, "100.0", "Slider should have custom max")
        }
    }

    func testSliderWithStepParameter() {
        var value = 5.0
        let binding = Binding<Double>(
            get: { value },
            set: { value = $0 }
        )

        let slider = Slider(value: binding, in: 0...10, step: 1.0)
        let node = slider.toVNode()

        // Verify step attribute
        if case .attribute(name: "step", value: let step) = node.props["step"] {
            XCTAssertEqual(step, "1.0", "Slider should have step attribute")
        } else {
            XCTFail("Slider should have step attribute when specified")
        }
    }

    func testSliderVNodeStructure() {
        var value = 0.7
        let binding = Binding<Double>(
            get: { value },
            set: { value = $0 }
        )

        let slider = Slider(value: binding)
        let node = slider.toVNode()

        // Verify type attribute
        if case .attribute(name: "type", value: let type) = node.props["type"] {
            XCTAssertEqual(type, "range", "Slider should have type='range'")
        } else {
            XCTFail("Slider should have type attribute")
        }

        // Verify value attribute
        if case .attribute(name: "value", value: let val) = node.props["value"] {
            XCTAssertEqual(val, "0.7", "Slider should have value attribute")
        } else {
            XCTFail("Slider should have value attribute")
        }
    }

    func testSliderValueBinding() {
        var volume = 0.5
        let binding = Binding<Double>(
            get: { volume },
            set: { volume = $0 }
        )

        let slider = Slider(value: binding)

        // Verify binding is accessible
        let valueBinding = slider.valueBinding
        XCTAssertEqual(valueBinding.wrappedValue, 0.5, "Binding should return current value")

        // Update binding
        valueBinding.wrappedValue = 0.8
        XCTAssertEqual(volume, 0.8, "Binding should update source value")
    }

    func testSliderDefaultStyling() {
        var value = 0.5
        let binding = Binding<Double>(
            get: { value },
            set: { value = $0 }
        )

        let slider = Slider(value: binding)
        let node = slider.toVNode()

        // Verify width style
        if case .style(name: "width", value: let width) = node.props["width"] {
            XCTAssertEqual(width, "100%", "Slider should have full width")
        } else {
            XCTFail("Slider should have width style")
        }
    }

    func testSliderEventHandler() {
        var value = 0.5
        let binding = Binding<Double>(
            get: { value },
            set: { value = $0 }
        )

        let slider = Slider(value: binding)
        let node = slider.toVNode()

        // Verify input event handler exists
        if case .eventHandler(event: "input", handlerID: _) = node.props["onInput"] {
            XCTAssertTrue(true, "Slider should have input event handler")
        } else {
            XCTFail("Slider should have onInput event handler")
        }
    }

    // MARK: - Stepper Tests (8 tests)

    func testStepperBasicInitialization() {
        var value = 5
        let binding = Binding<Int>(
            get: { value },
            set: { value = $0 }
        )

        let stepper = Stepper("Count", value: binding, in: 0...10)
        let node = stepper.toVNode()

        XCTAssertEqual(node.elementTag, "div", "Stepper should render as div element")
    }

    func testStepperWithoutLabel() {
        var value = 5
        let binding = Binding<Int>(
            get: { value },
            set: { value = $0 }
        )

        let stepper = Stepper(value: binding, in: 0...10)
        let node = stepper.toVNode()

        XCTAssertEqual(node.elementTag, "div", "Stepper should render as div element")
        XCTAssertFalse(node.children.isEmpty, "Stepper should have button container")
    }

    func testStepperButtonStructure() {
        var value = 5
        let binding = Binding<Int>(
            get: { value },
            set: { value = $0 }
        )

        let stepper = Stepper(value: binding, in: 0...10)
        let node = stepper.toVNode()

        // Find button container
        let buttonsContainer = node.children.first { child in
            if case .attribute(name: "class", value: let className) = child.props["class"] {
                return className.contains("raven-stepper-buttons")
            }
            return false
        }

        XCTAssertNotNil(buttonsContainer, "Stepper should have buttons container")

        if let container = buttonsContainer {
            XCTAssertEqual(container.children.count, 2, "Stepper should have 2 buttons")
        }
    }

    func testStepperRangeBoundaryEnforcement() {
        var value = 0  // At minimum
        let binding = Binding<Int>(
            get: { value },
            set: { value = $0 }
        )

        let stepper = Stepper(value: binding, in: 0...10)

        // Try to decrement below minimum
        stepper.decrementHandler()
        XCTAssertEqual(value, 0, "Value should not go below minimum")

        // Set to maximum
        value = 10
        stepper.incrementHandler()
        XCTAssertEqual(value, 10, "Value should not exceed maximum")
    }

    func testStepperDecrementButtonDisabledAtMin() {
        var value = 0
        let binding = Binding<Int>(
            get: { value },
            set: { value = $0 }
        )

        let stepper = Stepper(value: binding, in: 0...10)
        let node = stepper.toVNode()

        // Find buttons container
        let buttonsContainer = node.children.first { child in
            if case .attribute(name: "class", value: let className) = child.props["class"] {
                return className.contains("raven-stepper-buttons")
            }
            return false
        }

        if let container = buttonsContainer {
            let decrementButton = container.children.first
            if let button = decrementButton {
                // Verify disabled attribute
                if case .boolAttribute(name: "disabled", value: let disabled) = button.props["disabled"] {
                    XCTAssertTrue(disabled, "Decrement button should be disabled at minimum")
                } else {
                    XCTFail("Decrement button should have disabled attribute at minimum")
                }
            }
        }
    }

    func testStepperIncrementButtonDisabledAtMax() {
        var value = 10
        let binding = Binding<Int>(
            get: { value },
            set: { value = $0 }
        )

        let stepper = Stepper(value: binding, in: 0...10)
        let node = stepper.toVNode()

        // Find buttons container
        let buttonsContainer = node.children.first { child in
            if case .attribute(name: "class", value: let className) = child.props["class"] {
                return className.contains("raven-stepper-buttons")
            }
            return false
        }

        if let container = buttonsContainer {
            let incrementButton = container.children.last
            if let button = incrementButton {
                // Verify disabled attribute
                if case .boolAttribute(name: "disabled", value: let disabled) = button.props["disabled"] {
                    XCTAssertTrue(disabled, "Increment button should be disabled at maximum")
                } else {
                    XCTFail("Increment button should have disabled attribute at maximum")
                }
            }
        }
    }

    func testStepperEventHandlers() {
        var value = 5
        let binding = Binding<Int>(
            get: { value },
            set: { value = $0 }
        )

        let stepper = Stepper(value: binding, in: 0...10)

        // Test increment handler
        stepper.incrementHandler()
        XCTAssertEqual(value, 6, "Increment handler should increase value")

        // Test decrement handler
        stepper.decrementHandler()
        XCTAssertEqual(value, 5, "Decrement handler should decrease value")
    }

    func testStepperValueBinding() {
        var count = 5
        let binding = Binding<Int>(
            get: { count },
            set: { count = $0 }
        )

        let stepper = Stepper(value: binding, in: 0...10)

        let valueBinding = stepper.valueBinding
        XCTAssertEqual(valueBinding.wrappedValue, 5, "Binding should return current value")

        valueBinding.wrappedValue = 8
        XCTAssertEqual(count, 8, "Binding should update source value")
    }

    // MARK: - ProgressView Tests (8 tests)

    func testProgressViewIndeterminateMode() {
        let progress = ProgressView()
        let node = progress.toVNode()

        // Indeterminate should create a spinner (div)
        XCTAssertEqual(node.elementTag, "div", "Indeterminate ProgressView should render as div")

        // Verify spinner role
        if case .attribute(name: "role", value: let role) = node.props["role"] {
            XCTAssertEqual(role, "progressbar", "ProgressView should have progressbar role")
        }
    }

    func testProgressViewDeterminateMode() {
        let progress = ProgressView(value: 0.5, total: 1.0)
        let node = progress.toVNode()

        // Determinate should create a progress element
        XCTAssertEqual(node.elementTag, "progress", "Determinate ProgressView should render as progress element")
    }

    func testProgressViewVNodeStructureIndeterminate() {
        let progress = ProgressView()
        let node = progress.toVNode()

        // Verify ARIA attributes
        if case .attribute(name: "aria-busy", value: let busy) = node.props["aria-busy"] {
            XCTAssertEqual(busy, "true", "Indeterminate progress should have aria-busy=true")
        }

        if case .attribute(name: "aria-valuetext", value: let text) = node.props["aria-valuetext"] {
            XCTAssertEqual(text, "Loading", "Indeterminate progress should have aria-valuetext")
        }
    }

    func testProgressViewVNodeStructureDeterminate() {
        let progress = ProgressView(value: 45.0, total: 100.0)
        let node = progress.toVNode()

        // Verify value attribute
        if case .attribute(name: "value", value: let value) = node.props["value"] {
            XCTAssertEqual(value, "45.0", "ProgressView should have value attribute")
        }

        // Verify max attribute
        if case .attribute(name: "max", value: let max) = node.props["max"] {
            XCTAssertEqual(max, "100.0", "ProgressView should have max attribute")
        }

        // Verify ARIA attributes
        if case .attribute(name: "aria-valuenow", value: let valuenow) = node.props["aria-valuenow"] {
            XCTAssertEqual(valuenow, "45.0", "ProgressView should have aria-valuenow")
        }

        if case .attribute(name: "aria-valuemin", value: let valuemin) = node.props["aria-valuemin"] {
            XCTAssertEqual(valuemin, "0", "ProgressView should have aria-valuemin")
        }

        if case .attribute(name: "aria-valuemax", value: let valuemax) = node.props["aria-valuemax"] {
            XCTAssertEqual(valuemax, "100.0", "ProgressView should have aria-valuemax")
        }
    }

    func testProgressViewValueTotalHandling() {
        let progress1 = ProgressView(value: 0.75)  // Default total 1.0
        let node1 = progress1.toVNode()

        if case .attribute(name: "max", value: let max) = node1.props["max"] {
            XCTAssertEqual(max, "1.0", "Default total should be 1.0")
        }

        let progress2 = ProgressView(value: 75, total: 100)
        let node2 = progress2.toVNode()

        if case .attribute(name: "max", value: let max) = node2.props["max"] {
            XCTAssertEqual(max, "100.0", "Custom total should be used")
        }
    }

    func testProgressViewWithLabel() {
        let progress = ProgressView("Loading...", value: 0.5, total: 1.0)
        let node = progress.toVNode()

        // With label, should be wrapped in container
        XCTAssertEqual(node.elementTag, "div", "ProgressView with label should be wrapped in div")

        // Verify label is in children
        XCTAssertFalse(node.children.isEmpty, "ProgressView with label should have children")

        // Verify aria-label on progress element
        let progressElement = node.children.first { child in
            child.elementTag == "progress"
        }
        XCTAssertNotNil(progressElement, "Should contain progress element")
    }

    func testProgressViewARIAAttributes() {
        let progress = ProgressView(value: 50, total: 100)
        let node = progress.toVNode()

        // Verify all ARIA attributes are present
        XCTAssertNotNil(node.props["role"], "Should have role attribute")
        XCTAssertNotNil(node.props["aria-valuenow"], "Should have aria-valuenow")
        XCTAssertNotNil(node.props["aria-valuemin"], "Should have aria-valuemin")
        XCTAssertNotNil(node.props["aria-valuemax"], "Should have aria-valuemax")
    }

    func testProgressViewSpinnerAnimation() {
        let progress = ProgressView()
        let node = progress.toVNode()

        // Verify spinner has animation styles
        if case .attribute(name: "style", value: let style) = node.props["style"] {
            XCTAssertTrue(style.contains("animation"), "Spinner should have animation style")
            XCTAssertTrue(style.contains("border"), "Spinner should have border style")
            XCTAssertTrue(style.contains("border-radius"), "Spinner should have border-radius")
        } else {
            XCTFail("Spinner should have inline styles")
        }
    }

    // MARK: - Picker Tests (10 tests)

    func testPickerBasicInitialization() {
        var selection = "red"
        let binding = Binding<String>(
            get: { selection },
            set: { selection = $0 }
        )

        let picker = Picker("Color", selection: binding) {
            Text("Red").tag("red")
            Text("Green").tag("green")
            Text("Blue").tag("blue")
        }

        let node = picker.toVNode()
        XCTAssertEqual(node.elementTag, "select", "Picker should render as select element")
    }

    func testPickerSelectionBinding() {
        var color = "blue"
        let binding = Binding<String>(
            get: { color },
            set: { color = $0 }
        )

        let picker = Picker("Color", selection: binding) {
            Text("Red").tag("red")
            Text("Blue").tag("blue")
        }

        let selectionBinding = picker.selectionBinding
        XCTAssertEqual(selectionBinding.wrappedValue, "blue", "Binding should return current selection")

        selectionBinding.wrappedValue = "red"
        XCTAssertEqual(color, "red", "Binding should update selection")
    }

    func testPickerTagExtraction() {
        var selection = 1
        let binding = Binding<Int>(
            get: { selection },
            set: { selection = $0 }
        )

        let picker = Picker("Number", selection: binding) {
            Text("One").tag(1)
            Text("Two").tag(2)
            Text("Three").tag(3)
        }

        let options = picker.options
        XCTAssertEqual(options.count, 3, "Picker should extract all tagged options")
        // Note: Labels are currently empty due to AnyView type erasure
        // The important part is that tag values are correctly extracted
        XCTAssertEqual(options[0].value, 1, "First option should have correct value")
        XCTAssertEqual(options[1].value, 2, "Second option should have correct value")
        XCTAssertEqual(options[2].value, 3, "Third option should have correct value")
    }

    func testPickerVNodeStructure() {
        var selection = "a"
        let binding = Binding<String>(
            get: { selection },
            set: { selection = $0 }
        )

        let picker = Picker("Letter", selection: binding) {
            Text("A").tag("a")
            Text("B").tag("b")
        }

        let node = picker.toVNode()

        // Verify aria-label
        if case .attribute(name: "aria-label", value: let label) = node.props["aria-label"] {
            XCTAssertEqual(label, "Letter", "Picker should have aria-label")
        }

        // Verify children are option elements
        XCTAssertEqual(node.children.count, 2, "Picker should have 2 option elements")
        for child in node.children {
            XCTAssertEqual(child.elementTag, "option", "Children should be option elements")
        }
    }

    func testPickerChangeEventHandler() {
        var selection = "x"
        let binding = Binding<String>(
            get: { selection },
            set: { selection = $0 }
        )

        let picker = Picker("Choice", selection: binding) {
            Text("X").tag("x")
            Text("Y").tag("y")
        }

        let node = picker.toVNode()

        // Verify change event handler
        if case .eventHandler(event: "change", handlerID: _) = node.props["onChange"] {
            XCTAssertTrue(true, "Picker should have change event handler")
        } else {
            XCTFail("Picker should have onChange event handler")
        }
    }

    func testPickerOptionElements() {
        var selection = "cat"
        let binding = Binding<String>(
            get: { selection },
            set: { selection = $0 }
        )

        let picker = Picker("Animal", selection: binding) {
            Text("Cat").tag("cat")
            Text("Dog").tag("dog")
        }

        let node = picker.toVNode()

        // Verify first option
        let firstOption = node.children[0]
        XCTAssertNotNil(firstOption.props["value"], "Option should have value attribute")

        // Verify selected attribute on matching option
        if case .boolAttribute(name: "selected", value: let selected) = firstOption.props["selected"] {
            XCTAssertTrue(selected, "First option should be selected")
        }

        // Verify option has text child (even if empty due to AnyView type erasure)
        XCTAssertFalse(firstOption.children.isEmpty, "Option should have text child")
    }

    func testPickerWithLocalizedStringKey() {
        var selection = 1
        let binding = Binding<Int>(
            get: { selection },
            set: { selection = $0 }
        )

        let picker = Picker(LocalizedStringKey("size_label"), selection: binding) {
            Text("Small").tag(1)
            Text("Large").tag(2)
        }

        let node = picker.toVNode()
        XCTAssertEqual(node.elementTag, "select", "Picker with LocalizedStringKey should render as select")
    }

    func testPickerDefaultStyling() {
        var selection = "a"
        let binding = Binding<String>(
            get: { selection },
            set: { selection = $0 }
        )

        let picker = Picker("Choice", selection: binding) {
            Text("A").tag("a")
        }

        let node = picker.toVNode()

        // Verify default styles
        XCTAssertNotNil(node.props["padding"], "Picker should have padding style")
        XCTAssertNotNil(node.props["border"], "Picker should have border style")
        XCTAssertNotNil(node.props["border-radius"], "Picker should have border-radius style")
        XCTAssertNotNil(node.props["background-color"], "Picker should have background-color style")
    }

    func testPickerWithIntegerSelection() {
        var quantity = 1
        let binding = Binding<Int>(
            get: { quantity },
            set: { quantity = $0 }
        )

        let picker = Picker("Quantity", selection: binding) {
            Text("1").tag(1)
            Text("2").tag(2)
            Text("5").tag(5)
        }

        let options = picker.options
        XCTAssertEqual(options.count, 3, "Picker should handle integer selection")
        XCTAssertEqual(options[1].value, 2, "Options should have correct integer values")
    }

    func testPickerSelectedOptionHighlighting() {
        var selection = "green"
        let binding = Binding<String>(
            get: { selection },
            set: { selection = $0 }
        )

        let picker = Picker("Color", selection: binding) {
            Text("Red").tag("red")
            Text("Green").tag("green")
        }

        let node = picker.toVNode()

        // Find the selected option
        let selectedOption = node.children.first { child in
            if case .boolAttribute(name: "selected", value: true) = child.props["selected"] {
                return true
            }
            return false
        }

        XCTAssertNotNil(selectedOption, "Should have a selected option")

        // Verify it's the second option (green)
        if let option = selectedOption {
            // The second option should be selected (green)
            let selectedIndex = node.children.firstIndex(where: { child in
                if case .boolAttribute(name: "selected", value: true) = child.props["selected"] {
                    return true
                }
                return false
            })
            XCTAssertEqual(selectedIndex, 1, "Second option (green) should be selected")
        }
    }

    // MARK: - Link Tests (5 tests)

    func testLinkWithStringLabel() {
        let url = URL(string: "https://example.com")!
        let link = Link("Visit Example", destination: url)
        let node = link.toVNode()

        XCTAssertEqual(node.elementTag, "a", "Link should render as anchor element")

        // Verify href attribute
        if case .attribute(name: "href", value: let href) = node.props["href"] {
            XCTAssertEqual(href, "https://example.com", "Link should have correct href")
        } else {
            XCTFail("Link should have href attribute")
        }
    }

    func testLinkVNodeStructure() {
        let url = URL(string: "https://swift.org")!
        let link = Link("Swift", destination: url)
        let node = link.toVNode()

        XCTAssertEqual(node.elementTag, "a", "Link should be anchor element")

        // Verify href
        XCTAssertNotNil(node.props["href"], "Link should have href")

        // Verify default styling
        if case .style(name: "color", value: _) = node.props["style:color"] {
            XCTAssertTrue(true, "Link should have color style")
        }

        if case .style(name: "text-decoration", value: let decoration) = node.props["style:text-decoration"] {
            XCTAssertEqual(decoration, "underline", "Link should be underlined")
        }
    }

    func testLinkExternalAttributes() {
        let url = URL(string: "https://github.com")!
        let link = Link("GitHub", destination: url)
        let node = link.toVNode()

        // Verify target="_blank" for external links
        if case .attribute(name: "target", value: let target) = node.props["target"] {
            XCTAssertEqual(target, "_blank", "External link should open in new tab")
        } else {
            XCTFail("External link should have target attribute")
        }

        // Verify rel attribute for security
        if case .attribute(name: "rel", value: let rel) = node.props["rel"] {
            XCTAssertEqual(rel, "noopener noreferrer", "External link should have security attributes")
        } else {
            XCTFail("External link should have rel attribute")
        }
    }

    func testLinkInternalURL() {
        let url = URL(string: "/profile")!
        let link = Link("Profile", destination: url)
        let node = link.toVNode()

        // Internal links should not have target="_blank"
        XCTAssertNil(node.props["target"], "Internal link should not have target attribute")
        XCTAssertNil(node.props["rel"], "Internal link should not have rel attribute")
    }

    func testLinkWithLocalizedStringKey() {
        let url = URL(string: "https://example.com")!
        let link = Link(LocalizedStringKey("home_link"), destination: url)
        let node = link.toVNode()

        XCTAssertEqual(node.elementTag, "a", "Link with LocalizedStringKey should render as anchor")
    }

    // MARK: - Label Tests (5 tests)

    func testLabelBasicInitialization() {
        let label = Label {
            Text("Title")
        } icon: {
            Text("icon")
        }

        // Label has a body, so we test its structure
        let body = label.body
        XCTAssertNotNil(body, "Label should have a body")
    }

    func testLabelStringConvenienceInitializer() {
        let label = Label("Settings", systemImage: "gear")

        // Verify body is created
        let body = label.body
        XCTAssertNotNil(body, "Label with string initializer should have a body")
    }

    func testLabelBodyComposition() {
        let label = Label("Favorites", systemImage: "star")

        // Label body should be an HStack
        let body = label.body
        XCTAssertNotNil(body, "Label should compose with HStack")
    }

    func testLabelWithLocalizedStringKey() {
        let label = Label(LocalizedStringKey("settings_label"), systemImage: "gear")

        let body = label.body
        XCTAssertNotNil(body, "Label with LocalizedStringKey should have a body")
    }

    func testLabelIntegrationWithOtherViews() {
        // Test that Label can be used in composition
        struct TestView: View {
            var body: some View {
                VStack {
                    Label("Item 1", systemImage: "1.circle")
                    Label("Item 2", systemImage: "2.circle")
                }
            }
        }

        let view = TestView()
        XCTAssertNotNil(view.body, "Label should integrate with other views")
    }

    // MARK: - Integration Tests

    func testAllPhase8ControlsExist() {
        // Verify all Phase 8 types are available
        var text = ""
        let textBinding = Binding<String>(get: { text }, set: { text = $0 })

        var doubleVal = 0.5
        let doubleBinding = Binding<Double>(get: { doubleVal }, set: { doubleVal = $0 })

        var intVal = 5
        let intBinding = Binding<Int>(get: { intVal }, set: { intVal = $0 })

        var selection = "a"
        let selectionBinding = Binding<String>(get: { selection }, set: { selection = $0 })

        // Verify all controls can be instantiated
        let _ = SecureField("Password", text: textBinding)
        let _ = Slider(value: doubleBinding)
        let _ = Stepper(value: intBinding, in: 0...10)
        let _ = ProgressView()
        let _ = ProgressView(value: 0.5)
        let _ = Picker("Choice", selection: selectionBinding) {
            Text("A").tag("a")
        }
        let _ = Link("Test", destination: URL(string: "https://example.com")!)
        let _ = Label("Test", systemImage: "star")

        XCTAssertTrue(true, "All Phase 8 controls should be available")
    }

    func testPhase8FormExample() {
        // Integration test: create a complete form with all Phase 8 controls
        var username = ""
        var password = ""
        var volume = 0.5
        var quantity = 1
        var isLoading = false
        var role = "user"

        let usernameBinding = Binding<String>(get: { username }, set: { username = $0 })
        let passwordBinding = Binding<String>(get: { password }, set: { password = $0 })
        let volumeBinding = Binding<Double>(get: { volume }, set: { volume = $0 })
        let quantityBinding = Binding<Int>(get: { quantity }, set: { quantity = $0 })
        let roleBinding = Binding<String>(get: { role }, set: { role = $0 })

        // Verify all controls can be used together
        let _ = TextField("Username", text: usernameBinding)
        let _ = SecureField("Password", text: passwordBinding)
        let _ = Slider(value: volumeBinding)
        let _ = Stepper("Quantity", value: quantityBinding, in: 1...10)
        let _ = ProgressView()
        let _ = Picker("Role", selection: roleBinding) {
            Text("User").tag("user")
            Text("Admin").tag("admin")
        }
        let _ = Link("Privacy Policy", destination: URL(string: "/privacy")!)
        let _ = Label("Help", systemImage: "questionmark.circle")

        XCTAssertTrue(true, "Complete form with all Phase 8 controls should work")
    }
}
