import Testing
@testable import Raven

/// Tests for Stepper primitive view
@MainActor
@Suite struct StepperTests {

    // MARK: - Basic Initialization Tests

    @Test func stepperWithTextLabel() throws {
        var value = 5
        let binding = Binding<Int>(
            get: { value },
            set: { value = $0 }
        )

        let stepper = Stepper("Quantity", value: binding, in: 0...10)
        let node = stepper.toVNode()

        #expect(node.elementTag == "div")
        #expect(!node.children.isEmpty)

        // Verify role attribute
        if case .attribute(name: "role", value: let role) = node.props["role"] {
            #expect(role == "group")
        } else {
            Issue.record("Stepper should have role attribute")
        }

        // Verify flexbox styling
        if case .style(name: "display", value: let display) = node.props["display"] {
            #expect(display == "flex")
        } else {
            Issue.record("Stepper should have display style")
        }
    }

    @Test func stepperWithoutLabel() throws {
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

    @Test func stepperWithLocalizedStringKey() throws {
        var value = 5
        let binding = Binding<Int>(
            get: { value },
            set: { value = $0 }
        )

        let stepper = Stepper(LocalizedStringKey("volume_label"), value: binding, in: 0...100)
        let node = stepper.toVNode()

        #expect(node.elementTag == "div")
    }

    // MARK: - Button Tests

    @Test func stepperHasDecrementButton() throws {
        var value = 5
        let binding = Binding<Int>(
            get: { value },
            set: { value = $0 }
        )

        let stepper = Stepper(value: binding, in: 0...10)
        let node = stepper.toVNode()

        // Find the button container
        let buttonsContainer = node.children.first { child in
            if case .attribute(name: "class", value: let className) = child.props["class"] {
                return className.contains("raven-stepper-buttons")
            }
            return false
        }

        #expect(buttonsContainer != nil)

        // Find decrement button
        if let container = buttonsContainer {
            let decrementButton = container.children.first { child in
                if case .attribute(name: "class", value: let className) = child.props["class"] {
                    return className.contains("raven-stepper-decrement")
                }
                return false
            }

            #expect(decrementButton != nil)

            if let button = decrementButton {
                // Verify button type
                if case .attribute(name: "type", value: let type) = button.props["type"] {
                    #expect(type == "button")
                } else {
                    Issue.record("Decrement button should have type attribute")
                }

                // Verify aria-label
                if case .attribute(name: "aria-label", value: let ariaLabel) = button.props["aria-label"] {
                    #expect(ariaLabel == "Decrement")
                } else {
                    Issue.record("Decrement button should have aria-label")
                }

                // Verify button text
                let textNode = button.children.first
                if case .text(let text) = textNode?.type {
                    #expect(text == "-")
                } else {
                    Issue.record("Decrement button should have text content")
                }
            }
        }
    }

    @Test func stepperHasIncrementButton() throws {
        var value = 5
        let binding = Binding<Int>(
            get: { value },
            set: { value = $0 }
        )

        let stepper = Stepper(value: binding, in: 0...10)
        let node = stepper.toVNode()

        // Find the button container
        let buttonsContainer = node.children.first { child in
            if case .attribute(name: "class", value: let className) = child.props["class"] {
                return className.contains("raven-stepper-buttons")
            }
            return false
        }

        #expect(buttonsContainer != nil)

        // Find increment button
        if let container = buttonsContainer {
            let incrementButton = container.children.last { child in
                if case .attribute(name: "class", value: let className) = child.props["class"] {
                    return className.contains("raven-stepper-increment")
                }
                return false
            }

            #expect(incrementButton != nil)

            if let button = incrementButton {
                // Verify button type
                if case .attribute(name: "type", value: let type) = button.props["type"] {
                    #expect(type == "button")
                } else {
                    Issue.record("Increment button should have type attribute")
                }

                // Verify aria-label
                if case .attribute(name: "aria-label", value: let ariaLabel) = button.props["aria-label"] {
                    #expect(ariaLabel == "Increment")
                } else {
                    Issue.record("Increment button should have aria-label")
                }

                // Verify button text
                let textNode = button.children.first
                if case .text(let text) = textNode?.type {
                    #expect(text == "+")
                } else {
                    Issue.record("Increment button should have text content")
                }
            }
        }
    }

    // MARK: - Range Boundary Tests

    @Test func stepperDisablesDecrementAtMinimum() throws {
        var value = 0  // At minimum
        let binding = Binding<Int>(
            get: { value },
            set: { value = $0 }
        )

        let stepper = Stepper(value: binding, in: 0...10)
        let node = stepper.toVNode()

        // Find the button container
        let buttonsContainer = node.children.first { child in
            if case .attribute(name: "class", value: let className) = child.props["class"] {
                return className.contains("raven-stepper-buttons")
            }
            return false
        }

        // Find decrement button
        if let container = buttonsContainer {
            let decrementButton = container.children.first { child in
                if case .attribute(name: "class", value: let className) = child.props["class"] {
                    return className.contains("raven-stepper-decrement")
                }
                return false
            }

            if let button = decrementButton {
                // Verify button is disabled
                if case .boolAttribute(name: "disabled", value: let disabled) = button.props["disabled"] {
                    #expect(disabled)
                } else {
                    Issue.record("Decrement button should have disabled attribute at minimum")
                }

                // Verify aria-disabled
                if case .attribute(name: "aria-disabled", value: let ariaDisabled) = button.props["aria-disabled"] {
                    #expect(ariaDisabled == "true")
                } else {
                    Issue.record("Decrement button should have aria-disabled attribute")
                }

                // Verify no onClick handler when disabled
                #expect(button.props["onClick"] == nil)
            } else {
                Issue.record("Decrement button not found")
            }
        }
    }

    @Test func stepperDisablesIncrementAtMaximum() throws {
        var value = 10  // At maximum
        let binding = Binding<Int>(
            get: { value },
            set: { value = $0 }
        )

        let stepper = Stepper(value: binding, in: 0...10)
        let node = stepper.toVNode()

        // Find the button container
        let buttonsContainer = node.children.first { child in
            if case .attribute(name: "class", value: let className) = child.props["class"] {
                return className.contains("raven-stepper-buttons")
            }
            return false
        }

        // Find increment button
        if let container = buttonsContainer {
            let incrementButton = container.children.last { child in
                if case .attribute(name: "class", value: let className) = child.props["class"] {
                    return className.contains("raven-stepper-increment")
                }
                return false
            }

            if let button = incrementButton {
                // Verify button is disabled
                if case .boolAttribute(name: "disabled", value: let disabled) = button.props["disabled"] {
                    #expect(disabled)
                } else {
                    Issue.record("Increment button should have disabled attribute at maximum")
                }

                // Verify aria-disabled
                if case .attribute(name: "aria-disabled", value: let ariaDisabled) = button.props["aria-disabled"] {
                    #expect(ariaDisabled == "true")
                } else {
                    Issue.record("Increment button should have aria-disabled attribute")
                }

                // Verify no onClick handler when disabled
                #expect(button.props["onClick"] == nil)
            } else {
                Issue.record("Increment button not found")
            }
        }
    }

    @Test func stepperEnablesButtonsInMiddleOfRange() throws {
        var value = 5  // In middle of range
        let binding = Binding<Int>(
            get: { value },
            set: { value = $0 }
        )

        let stepper = Stepper(value: binding, in: 0...10)
        let node = stepper.toVNode()

        // Find the button container
        let buttonsContainer = node.children.first { child in
            if case .attribute(name: "class", value: let className) = child.props["class"] {
                return className.contains("raven-stepper-buttons")
            }
            return false
        }

        if let container = buttonsContainer {
            // Check decrement button is enabled
            let decrementButton = container.children.first { child in
                if case .attribute(name: "class", value: let className) = child.props["class"] {
                    return className.contains("raven-stepper-decrement")
                }
                return false
            }

            if let button = decrementButton {
                #expect(button.props["disabled"] == nil)
                #expect(button.props["onClick"] != nil)
            }

            // Check increment button is enabled
            let incrementButton = container.children.last { child in
                if case .attribute(name: "class", value: let className) = child.props["class"] {
                    return className.contains("raven-stepper-increment")
                }
                return false
            }

            if let button = incrementButton {
                #expect(button.props["disabled"] == nil)
                #expect(button.props["onClick"] != nil)
            }
        }
    }

    // MARK: - Event Handler Tests

    @Test func incrementHandler() throws {
        var value = 5
        let binding = Binding<Int>(
            get: { value },
            set: { value = $0 }
        )

        let stepper = Stepper(value: binding, in: 0...10)

        // Execute increment handler
        #expect(value == 5)
        stepper.incrementHandler()
        #expect(value == 6)
        stepper.incrementHandler()
        #expect(value == 7)
    }

    @Test func decrementHandler() throws {
        var value = 5
        let binding = Binding<Int>(
            get: { value },
            set: { value = $0 }
        )

        let stepper = Stepper(value: binding, in: 0...10)

        // Execute decrement handler
        #expect(value == 5)
        stepper.decrementHandler()
        #expect(value == 4)
        stepper.decrementHandler()
        #expect(value == 3)
    }

    @Test func incrementHandlerRespectsBounds() throws {
        var value = 10  // At maximum
        let binding = Binding<Int>(
            get: { value },
            set: { value = $0 }
        )

        let stepper = Stepper(value: binding, in: 0...10)

        // Try to increment beyond maximum
        stepper.incrementHandler()
        #expect(value == 10)
    }

    @Test func decrementHandlerRespectsBounds() throws {
        var value = 0  // At minimum
        let binding = Binding<Int>(
            get: { value },
            set: { value = $0 }
        )

        let stepper = Stepper(value: binding, in: 0...10)

        // Try to decrement below minimum
        stepper.decrementHandler()
        #expect(value == 0)
    }

    @Test func stepperValueBinding() throws {
        var value = 5
        let binding = Binding<Int>(
            get: { value },
            set: { value = $0 }
        )

        let stepper = Stepper(value: binding, in: 0...10)

        // Verify binding is accessible
        let stepperBinding = stepper.valueBinding
        #expect(stepperBinding.wrappedValue == 5)

        // Modify through binding
        stepperBinding.wrappedValue = 8
        #expect(value == 8)
    }

    // MARK: - Integration Tests

    @Test func stepperWithCompleteInteraction() throws {
        var quantity = 1
        let binding = Binding<Int>(
            get: { quantity },
            set: { quantity = $0 }
        )

        let stepper = Stepper("Quantity", value: binding, in: 1...5)

        // Initial state
        #expect(quantity == 1)

        // Increment several times
        stepper.incrementHandler()
        #expect(quantity == 2)
        stepper.incrementHandler()
        #expect(quantity == 3)

        // Decrement
        stepper.decrementHandler()
        #expect(quantity == 2)

        // Increment to maximum
        stepper.incrementHandler()  // 3
        stepper.incrementHandler()  // 4
        stepper.incrementHandler()  // 5
        #expect(quantity == 5)

        // Try to exceed maximum
        stepper.incrementHandler()
        #expect(quantity == 5)

        // Decrement to minimum
        stepper.decrementHandler()  // 4
        stepper.decrementHandler()  // 3
        stepper.decrementHandler()  // 2
        stepper.decrementHandler()  // 1
        #expect(quantity == 1)

        // Try to go below minimum
        stepper.decrementHandler()
        #expect(quantity == 1)
    }
}
