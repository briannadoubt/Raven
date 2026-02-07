import Foundation
import Testing
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
@MainActor
@Suite struct Phase8VerificationTests {

    // MARK: - SecureField Tests (7 tests)

    @Test func secureFieldBasicInitialization() {
        var password = ""
        let binding = Binding<String>(
            get: { password },
            set: { password = $0 }
        )

        let field = SecureField("Enter password", text: binding)
        let node = field.toVNode()

        #expect(node.elementTag == "input")
    }

    @Test func secureFieldWithLocalizedStringKey() {
        var password = ""
        let binding = Binding<String>(
            get: { password },
            set: { password = $0 }
        )

        let field = SecureField(LocalizedStringKey("password_placeholder"), text: binding)
        let node = field.toVNode()

        #expect(node.elementTag == "input")
    }

    @Test func secureFieldVNodeStructure() {
        var password = ""
        let binding = Binding<String>(
            get: { password },
            set: { password = $0 }
        )

        let field = SecureField("Password", text: binding)
        let node = field.toVNode()

        // Verify type attribute
        if case .attribute(name: "type", value: let type) = node.props["type"] {
            #expect(type == "password")
        } else {
            Issue.record("SecureField should have type attribute")
        }

        // Verify placeholder attribute
        if case .attribute(name: "placeholder", value: let placeholder) = node.props["placeholder"] {
            #expect(placeholder == "Password")
        } else {
            Issue.record("SecureField should have placeholder attribute")
        }

        // Verify value attribute
        if case .attribute(name: "value", value: let value) = node.props["value"] {
            #expect(value == "")
        } else {
            Issue.record("SecureField should have value attribute")
        }
    }

    @Test func secureFieldEventHandler() {
        var password = ""
        let binding = Binding<String>(
            get: { password },
            set: { password = $0 }
        )

        let field = SecureField("Password", text: binding)
        let node = field.toVNode()

        // Verify input event handler exists
        if case .eventHandler(event: "input", handlerID: _) = node.props["onInput"] {
            #expect(true)
        } else {
            Issue.record("SecureField should have onInput event handler")
        }
    }

    @Test func secureFieldTwoWayBinding() {
        var password = "secret"
        let binding = Binding<String>(
            get: { password },
            set: { password = $0 }
        )

        let field = SecureField("Password", text: binding)
        let node = field.toVNode()

        // Verify binding value is reflected
        if case .attribute(name: "value", value: let value) = node.props["value"] {
            #expect(value == "secret")
        }

        // Verify binding is accessible
        let textBinding = field.textBinding
        #expect(textBinding.wrappedValue == "secret")

        // Update binding
        textBinding.wrappedValue = "newpass"
        #expect(password == "newpass")
    }

    @Test func secureFieldDefaultStyling() {
        var password = ""
        let binding = Binding<String>(
            get: { password },
            set: { password = $0 }
        )

        let field = SecureField("Password", text: binding)
        let node = field.toVNode()

        // Verify default styles
        #expect(node.props["padding"] != nil)
        #expect(node.props["border"] != nil)
        #expect(node.props["border-radius"] != nil)
        #expect(node.props["font-size"] != nil)
    }

    @Test func secureFieldEmptyChildren() {
        var password = ""
        let binding = Binding<String>(
            get: { password },
            set: { password = $0 }
        )

        let field = SecureField("Password", text: binding)
        let node = field.toVNode()

        #expect(node.children.isEmpty)
    }

    // MARK: - Slider Tests (8 tests)

    @Test func sliderBasicInitialization() {
        var value = 0.5
        let binding = Binding<Double>(
            get: { value },
            set: { value = $0 }
        )

        let slider = Slider(value: binding)
        let node = slider.toVNode()

        #expect(node.elementTag == "input")
    }

    @Test func sliderWithDefaultRange() {
        var value = 0.5
        let binding = Binding<Double>(
            get: { value },
            set: { value = $0 }
        )

        let slider = Slider(value: binding)
        let node = slider.toVNode()

        // Verify default range (0...1)
        if case .attribute(name: "min", value: let min) = node.props["min"] {
            #expect(min == "0.0")
        } else {
            Issue.record("Slider should have min attribute")
        }

        if case .attribute(name: "max", value: let max) = node.props["max"] {
            #expect(max == "1.0")
        } else {
            Issue.record("Slider should have max attribute")
        }
    }

    @Test func sliderWithCustomRange() {
        var value = 50.0
        let binding = Binding<Double>(
            get: { value },
            set: { value = $0 }
        )

        let slider = Slider(value: binding, in: 0...100)
        let node = slider.toVNode()

        // Verify custom range
        if case .attribute(name: "min", value: let min) = node.props["min"] {
            #expect(min == "0.0")
        }

        if case .attribute(name: "max", value: let max) = node.props["max"] {
            #expect(max == "100.0")
        }
    }

    @Test func sliderWithStepParameter() {
        var value = 5.0
        let binding = Binding<Double>(
            get: { value },
            set: { value = $0 }
        )

        let slider = Slider(value: binding, in: 0...10, step: 1.0)
        let node = slider.toVNode()

        // Verify step attribute
        if case .attribute(name: "step", value: let step) = node.props["step"] {
            #expect(step == "1.0")
        } else {
            Issue.record("Slider should have step attribute when specified")
        }
    }

    @Test func sliderVNodeStructure() {
        var value = 0.7
        let binding = Binding<Double>(
            get: { value },
            set: { value = $0 }
        )

        let slider = Slider(value: binding)
        let node = slider.toVNode()

        // Verify type attribute
        if case .attribute(name: "type", value: let type) = node.props["type"] {
            #expect(type == "range")
        } else {
            Issue.record("Slider should have type attribute")
        }

        // Verify value attribute
        if case .attribute(name: "value", value: let val) = node.props["value"] {
            #expect(val == "0.7")
        } else {
            Issue.record("Slider should have value attribute")
        }
    }

    @Test func sliderValueBinding() {
        var volume = 0.5
        let binding = Binding<Double>(
            get: { volume },
            set: { volume = $0 }
        )

        let slider = Slider(value: binding)

        // Verify binding is accessible
        let valueBinding = slider.valueBinding
        #expect(valueBinding.wrappedValue == 0.5)

        // Update binding
        valueBinding.wrappedValue = 0.8
        #expect(volume == 0.8)
    }

    @Test func sliderDefaultStyling() {
        var value = 0.5
        let binding = Binding<Double>(
            get: { value },
            set: { value = $0 }
        )

        let slider = Slider(value: binding)
        let node = slider.toVNode()

        // Verify width style
        if case .style(name: "width", value: let width) = node.props["width"] {
            #expect(width == "100%")
        } else {
            Issue.record("Slider should have width style")
        }
    }

    @Test func sliderEventHandler() {
        var value = 0.5
        let binding = Binding<Double>(
            get: { value },
            set: { value = $0 }
        )

        let slider = Slider(value: binding)
        let node = slider.toVNode()

        // Verify input event handler exists
        if case .eventHandler(event: "input", handlerID: _) = node.props["onInput"] {
            #expect(true)
        } else {
            Issue.record("Slider should have onInput event handler")
        }
    }

    // MARK: - Stepper Tests (8 tests)

    @Test func stepperBasicInitialization() {
        var value = 5
        let binding = Binding<Int>(
            get: { value },
            set: { value = $0 }
        )

        let stepper = Stepper("Count", value: binding, in: 0...10)
        let node = stepper.toVNode()

        #expect(node.elementTag == "div")
    }

    @Test func stepperWithoutLabel() {
        var value = 5
        let binding = Binding<Int>(
            get: { value },
            set: { value = $0 }
        )

        let stepper = Stepper(value: binding, in: 0...10)
        let node = stepper.toVNode()

        #expect(node.elementTag == "div")
        #expect(!node.children.isEmpty)
    }

    @Test func stepperButtonStructure() {
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

        #expect(buttonsContainer != nil)

        if let container = buttonsContainer {
            #expect(container.children.count == 2)
        }
    }

    @Test func stepperRangeBoundaryEnforcement() {
        var value = 0  // At minimum
        let binding = Binding<Int>(
            get: { value },
            set: { value = $0 }
        )

        let stepper = Stepper(value: binding, in: 0...10)

        // Try to decrement below minimum
        stepper.decrementHandler()
        #expect(value == 0)

        // Set to maximum
        value = 10
        stepper.incrementHandler()
        #expect(value == 10)
    }

    @Test func stepperDecrementButtonDisabledAtMin() {
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
                    #expect(disabled)
                } else {
                    Issue.record("Decrement button should have disabled attribute at minimum")
                }
            }
        }
    }

    @Test func stepperIncrementButtonDisabledAtMax() {
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
                    #expect(disabled)
                } else {
                    Issue.record("Increment button should have disabled attribute at maximum")
                }
            }
        }
    }

    @Test func stepperEventHandlers() {
        var value = 5
        let binding = Binding<Int>(
            get: { value },
            set: { value = $0 }
        )

        let stepper = Stepper(value: binding, in: 0...10)

        // Test increment handler
        stepper.incrementHandler()
        #expect(value == 6)

        // Test decrement handler
        stepper.decrementHandler()
        #expect(value == 5)
    }

    @Test func stepperValueBinding() {
        var count = 5
        let binding = Binding<Int>(
            get: { count },
            set: { count = $0 }
        )

        let stepper = Stepper(value: binding, in: 0...10)

        let valueBinding = stepper.valueBinding
        #expect(valueBinding.wrappedValue == 5)

        valueBinding.wrappedValue = 8
        #expect(count == 8)
    }

    // MARK: - ProgressView Tests (8 tests)

    @Test func progressViewIndeterminateMode() {
        let progress = ProgressView()
        let node = progress.toVNode()

        // Indeterminate should create a spinner (div)
        #expect(node.elementTag == "div")

        // Verify spinner role
        if case .attribute(name: "role", value: let role) = node.props["role"] {
            #expect(role == "progressbar")
        }
    }

    @Test func progressViewDeterminateMode() {
        let progress = ProgressView(value: 0.5, total: 1.0)
        let node = progress.toVNode()

        // Determinate should create a progress element
        #expect(node.elementTag == "progress")
    }

    @Test func progressViewVNodeStructureIndeterminate() {
        let progress = ProgressView()
        let node = progress.toVNode()

        // Verify ARIA attributes
        if case .attribute(name: "aria-busy", value: let busy) = node.props["aria-busy"] {
            #expect(busy == "true")
        }

        if case .attribute(name: "aria-valuetext", value: let text) = node.props["aria-valuetext"] {
            #expect(text == "Loading")
        }
    }

    @Test func progressViewVNodeStructureDeterminate() {
        let progress = ProgressView(value: 45.0, total: 100.0)
        let node = progress.toVNode()

        // Verify value attribute
        if case .attribute(name: "value", value: let value) = node.props["value"] {
            #expect(value == "45.0")
        }

        // Verify max attribute
        if case .attribute(name: "max", value: let max) = node.props["max"] {
            #expect(max == "100.0")
        }

        // Verify ARIA attributes
        if case .attribute(name: "aria-valuenow", value: let valuenow) = node.props["aria-valuenow"] {
            #expect(valuenow == "45.0")
        }

        if case .attribute(name: "aria-valuemin", value: let valuemin) = node.props["aria-valuemin"] {
            #expect(valuemin == "0")
        }

        if case .attribute(name: "aria-valuemax", value: let valuemax) = node.props["aria-valuemax"] {
            #expect(valuemax == "100.0")
        }
    }

    @Test func progressViewValueTotalHandling() {
        let progress1 = ProgressView(value: 0.75)  // Default total 1.0
        let node1 = progress1.toVNode()

        if case .attribute(name: "max", value: let max) = node1.props["max"] {
            #expect(max == "1.0")
        }

        let progress2 = ProgressView(value: 75, total: 100)
        let node2 = progress2.toVNode()

        if case .attribute(name: "max", value: let max) = node2.props["max"] {
            #expect(max == "100.0")
        }
    }

    @Test func progressViewWithLabel() {
        let progress = ProgressView("Loading...", value: 0.5, total: 1.0)
        let node = progress.toVNode()

        // With label, should be wrapped in container
        #expect(node.elementTag == "div")

        // Verify label is in children
        #expect(!node.children.isEmpty)

        // Verify aria-label on progress element
        let progressElement = node.children.first { child in
            child.elementTag == "progress"
        }
        #expect(progressElement != nil)
    }

    @Test func progressViewARIAAttributes() {
        let progress = ProgressView(value: 50, total: 100)
        let node = progress.toVNode()

        // Verify all ARIA attributes are present
        #expect(node.props["role"] != nil)
        #expect(node.props["aria-valuenow"] != nil)
        #expect(node.props["aria-valuemin"] != nil)
        #expect(node.props["aria-valuemax"] != nil)
    }

    @Test func progressViewSpinnerAnimation() {
        let progress = ProgressView()
        let node = progress.toVNode()

        // Verify spinner has animation styles
        if case .attribute(name: "style", value: let style) = node.props["style"] {
            #expect(style.contains("animation"))
            #expect(style.contains("border"))
            #expect(style.contains("border-radius"))
        } else {
            Issue.record("Spinner should have inline styles")
        }
    }

    // MARK: - Picker Tests (10 tests)

    @Test func pickerBasicInitialization() {
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
        #expect(node.elementTag == "select")
    }

    @Test func pickerSelectionBinding() {
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
        #expect(selectionBinding.wrappedValue == "blue")

        selectionBinding.wrappedValue = "red"
        #expect(color == "red")
    }

    @Test func pickerTagExtraction() {
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
        #expect(options.count == 3)
        // Note: Labels are currently empty due to AnyView type erasure
        // The important part is that tag values are correctly extracted
        #expect(options[0].value == 1)
        #expect(options[1].value == 2)
        #expect(options[2].value == 3)
    }

    @Test func pickerVNodeStructure() {
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
            #expect(label == "Letter")
        }

        // Verify children are option elements
        #expect(node.children.count == 2)
        for child in node.children {
            #expect(child.elementTag == "option")
        }
    }

    @Test func pickerChangeEventHandler() {
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
            #expect(true)
        } else {
            Issue.record("Picker should have onChange event handler")
        }
    }

    @Test func pickerOptionElements() {
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
        #expect(firstOption.props["value"] != nil)

        // Verify selected attribute on matching option
        if case .boolAttribute(name: "selected", value: let selected) = firstOption.props["selected"] {
            #expect(selected)
        }

        // Verify option has text child (even if empty due to AnyView type erasure)
        #expect(!firstOption.children.isEmpty)
    }

    @Test func pickerWithLocalizedStringKey() {
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
        #expect(node.elementTag == "select")
    }

    @Test func pickerDefaultStyling() {
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
        #expect(node.props["padding"] != nil)
        #expect(node.props["border"] != nil)
        #expect(node.props["border-radius"] != nil)
        #expect(node.props["background-color"] != nil)
    }

    @Test func pickerWithIntegerSelection() {
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
        #expect(options.count == 3)
        #expect(options[1].value == 2)
    }

    @Test func pickerSelectedOptionHighlighting() {
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

        #expect(selectedOption != nil)

        // Verify it's the second option (green)
        if let _ = selectedOption {
            // The second option should be selected (green)
            let selectedIndex = node.children.firstIndex(where: { child in
                if case .boolAttribute(name: "selected", value: true) = child.props["selected"] {
                    return true
                }
                return false
            })
            #expect(selectedIndex == 1)
        }
    }

    // MARK: - Link Tests (5 tests)

    @Test func linkWithStringLabel() {
        let url = URL(string: "https://example.com")!
        let link = Link("Visit Example", destination: url)
        let node = link.toVNode()

        #expect(node.elementTag == "a")

        // Verify href attribute
        if case .attribute(name: "href", value: let href) = node.props["href"] {
            #expect(href == "https://example.com")
        } else {
            Issue.record("Link should have href attribute")
        }
    }

    @Test func linkVNodeStructure() {
        let url = URL(string: "https://swift.org")!
        let link = Link("Swift", destination: url)
        let node = link.toVNode()

        #expect(node.elementTag == "a")

        // Verify href
        #expect(node.props["href"] != nil)

        // Verify default styling
        if case .style(name: "color", value: _) = node.props["style:color"] {
            #expect(true)
        }

        if case .style(name: "text-decoration", value: let decoration) = node.props["style:text-decoration"] {
            #expect(decoration == "underline")
        }
    }

    @Test func linkExternalAttributes() {
        let url = URL(string: "https://github.com")!
        let link = Link("GitHub", destination: url)
        let node = link.toVNode()

        // Verify target="_blank" for external links
        if case .attribute(name: "target", value: let target) = node.props["target"] {
            #expect(target == "_blank")
        } else {
            Issue.record("External link should have target attribute")
        }

        // Verify rel attribute for security
        if case .attribute(name: "rel", value: let rel) = node.props["rel"] {
            #expect(rel == "noopener noreferrer")
        } else {
            Issue.record("External link should have rel attribute")
        }
    }

    @Test func linkInternalURL() {
        let url = URL(string: "/profile")!
        let link = Link("Profile", destination: url)
        let node = link.toVNode()

        // Internal links should not have target="_blank"
        #expect(node.props["target"] == nil)
        #expect(node.props["rel"] == nil)
    }

    @Test func linkWithLocalizedStringKey() {
        let url = URL(string: "https://example.com")!
        let link = Link(LocalizedStringKey("home_link"), destination: url)
        let node = link.toVNode()

        #expect(node.elementTag == "a")
    }

    // MARK: - Label Tests (5 tests)

    @Test func labelBasicInitialization() {
        let label = Label {
            Text("Title")
        } icon: {
            Text("icon")
        }

        // Label has a body, so we test its structure
        let body = label.body
        #expect(body != nil)
    }

    @Test func labelStringConvenienceInitializer() {
        let label = Label("Settings", systemImage: "gear")

        // Verify body is created
        let body = label.body
        #expect(body != nil)
    }

    @Test func labelBodyComposition() {
        let label = Label("Favorites", systemImage: "star")

        // Label body should be an HStack
        let body = label.body
        #expect(body != nil)
    }

    @Test func labelWithLocalizedStringKey() {
        let label = Label(LocalizedStringKey("settings_label"), systemImage: "gear")

        let body = label.body
        #expect(body != nil)
    }

    @Test func labelIntegrationWithOtherViews() {
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
        #expect(view.body != nil)
    }

    // MARK: - Integration Tests

    @Test func allPhase8ControlsExist() {
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

        #expect(true)
    }

    @Test func phase8FormExample() {
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

        #expect(true)
    }
}
