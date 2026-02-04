import XCTest
@testable import Raven

/// Tests for Stepper primitive view
@MainActor
final class StepperTests: XCTestCase {

    // MARK: - Basic Initialization Tests

    func testStepperWithTextLabel() throws {
        var value = 5
        let binding = Binding<Int>(
            get: { value },
            set: { value = $0 }
        )

        let stepper = Stepper("Quantity", value: binding, in: 0...10)
        let node = stepper.toVNode()

        XCTAssertEqual(node.elementTag, "div", "Stepper should render as div element")
        XCTAssertFalse(node.children.isEmpty, "Stepper should have children")

        // Verify role attribute
        if case .attribute(name: "role", value: let role) = node.props["role"] {
            XCTAssertEqual(role, "group", "Stepper should have group role")
        } else {
            XCTFail("Stepper should have role attribute")
        }

        // Verify flexbox styling
        if case .style(name: "display", value: let display) = node.props["display"] {
            XCTAssertEqual(display, "flex", "Stepper should use flexbox")
        } else {
            XCTFail("Stepper should have display style")
        }
    }

    func testStepperWithoutLabel() throws {
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

    func testStepperWithLocalizedStringKey() throws {
        var value = 5
        let binding = Binding<Int>(
            get: { value },
            set: { value = $0 }
        )

        let stepper = Stepper(LocalizedStringKey("volume_label"), value: binding, in: 0...100)
        let node = stepper.toVNode()

        XCTAssertEqual(node.elementTag, "div", "Stepper should render as div element")
    }

    // MARK: - Button Tests

    func testStepperHasDecrementButton() throws {
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

        XCTAssertNotNil(buttonsContainer, "Stepper should have buttons container")

        // Find decrement button
        if let container = buttonsContainer {
            let decrementButton = container.children.first { child in
                if case .attribute(name: "class", value: let className) = child.props["class"] {
                    return className.contains("raven-stepper-decrement")
                }
                return false
            }

            XCTAssertNotNil(decrementButton, "Stepper should have decrement button")

            if let button = decrementButton {
                // Verify button type
                if case .attribute(name: "type", value: let type) = button.props["type"] {
                    XCTAssertEqual(type, "button", "Decrement should be button type")
                } else {
                    XCTFail("Decrement button should have type attribute")
                }

                // Verify aria-label
                if case .attribute(name: "aria-label", value: let ariaLabel) = button.props["aria-label"] {
                    XCTAssertEqual(ariaLabel, "Decrement", "Decrement button should have aria-label")
                } else {
                    XCTFail("Decrement button should have aria-label")
                }

                // Verify button text
                let textNode = button.children.first
                if case .text(let text) = textNode?.type {
                    XCTAssertEqual(text, "-", "Decrement button should show minus sign")
                } else {
                    XCTFail("Decrement button should have text content")
                }
            }
        }
    }

    func testStepperHasIncrementButton() throws {
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

        XCTAssertNotNil(buttonsContainer, "Stepper should have buttons container")

        // Find increment button
        if let container = buttonsContainer {
            let incrementButton = container.children.last { child in
                if case .attribute(name: "class", value: let className) = child.props["class"] {
                    return className.contains("raven-stepper-increment")
                }
                return false
            }

            XCTAssertNotNil(incrementButton, "Stepper should have increment button")

            if let button = incrementButton {
                // Verify button type
                if case .attribute(name: "type", value: let type) = button.props["type"] {
                    XCTAssertEqual(type, "button", "Increment should be button type")
                } else {
                    XCTFail("Increment button should have type attribute")
                }

                // Verify aria-label
                if case .attribute(name: "aria-label", value: let ariaLabel) = button.props["aria-label"] {
                    XCTAssertEqual(ariaLabel, "Increment", "Increment button should have aria-label")
                } else {
                    XCTFail("Increment button should have aria-label")
                }

                // Verify button text
                let textNode = button.children.first
                if case .text(let text) = textNode?.type {
                    XCTAssertEqual(text, "+", "Increment button should show plus sign")
                } else {
                    XCTFail("Increment button should have text content")
                }
            }
        }
    }

    // MARK: - Range Boundary Tests

    func testStepperDisablesDecrementAtMinimum() throws {
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
                    XCTAssertTrue(disabled, "Decrement button should be disabled at minimum")
                } else {
                    XCTFail("Decrement button should have disabled attribute at minimum")
                }

                // Verify aria-disabled
                if case .attribute(name: "aria-disabled", value: let ariaDisabled) = button.props["aria-disabled"] {
                    XCTAssertEqual(ariaDisabled, "true", "Decrement button should have aria-disabled")
                } else {
                    XCTFail("Decrement button should have aria-disabled attribute")
                }

                // Verify no onClick handler when disabled
                XCTAssertNil(button.props["onClick"], "Decrement button should not have onClick when disabled")
            } else {
                XCTFail("Decrement button not found")
            }
        }
    }

    func testStepperDisablesIncrementAtMaximum() throws {
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
                    XCTAssertTrue(disabled, "Increment button should be disabled at maximum")
                } else {
                    XCTFail("Increment button should have disabled attribute at maximum")
                }

                // Verify aria-disabled
                if case .attribute(name: "aria-disabled", value: let ariaDisabled) = button.props["aria-disabled"] {
                    XCTAssertEqual(ariaDisabled, "true", "Increment button should have aria-disabled")
                } else {
                    XCTFail("Increment button should have aria-disabled attribute")
                }

                // Verify no onClick handler when disabled
                XCTAssertNil(button.props["onClick"], "Increment button should not have onClick when disabled")
            } else {
                XCTFail("Increment button not found")
            }
        }
    }

    func testStepperEnablesButtonsInMiddleOfRange() throws {
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
                XCTAssertNil(button.props["disabled"], "Decrement button should be enabled in middle of range")
                XCTAssertNotNil(button.props["onClick"], "Decrement button should have onClick handler")
            }

            // Check increment button is enabled
            let incrementButton = container.children.last { child in
                if case .attribute(name: "class", value: let className) = child.props["class"] {
                    return className.contains("raven-stepper-increment")
                }
                return false
            }

            if let button = incrementButton {
                XCTAssertNil(button.props["disabled"], "Increment button should be enabled in middle of range")
                XCTAssertNotNil(button.props["onClick"], "Increment button should have onClick handler")
            }
        }
    }

    // MARK: - Event Handler Tests

    func testIncrementHandler() throws {
        var value = 5
        let binding = Binding<Int>(
            get: { value },
            set: { value = $0 }
        )

        let stepper = Stepper(value: binding, in: 0...10)

        // Execute increment handler
        XCTAssertEqual(value, 5, "Initial value should be 5")
        stepper.incrementHandler()
        XCTAssertEqual(value, 6, "Value should increment to 6")
        stepper.incrementHandler()
        XCTAssertEqual(value, 7, "Value should increment to 7")
    }

    func testDecrementHandler() throws {
        var value = 5
        let binding = Binding<Int>(
            get: { value },
            set: { value = $0 }
        )

        let stepper = Stepper(value: binding, in: 0...10)

        // Execute decrement handler
        XCTAssertEqual(value, 5, "Initial value should be 5")
        stepper.decrementHandler()
        XCTAssertEqual(value, 4, "Value should decrement to 4")
        stepper.decrementHandler()
        XCTAssertEqual(value, 3, "Value should decrement to 3")
    }

    func testIncrementHandlerRespectsBounds() throws {
        var value = 10  // At maximum
        let binding = Binding<Int>(
            get: { value },
            set: { value = $0 }
        )

        let stepper = Stepper(value: binding, in: 0...10)

        // Try to increment beyond maximum
        stepper.incrementHandler()
        XCTAssertEqual(value, 10, "Value should not exceed maximum")
    }

    func testDecrementHandlerRespectsBounds() throws {
        var value = 0  // At minimum
        let binding = Binding<Int>(
            get: { value },
            set: { value = $0 }
        )

        let stepper = Stepper(value: binding, in: 0...10)

        // Try to decrement below minimum
        stepper.decrementHandler()
        XCTAssertEqual(value, 0, "Value should not go below minimum")
    }

    func testStepperValueBinding() throws {
        var value = 5
        let binding = Binding<Int>(
            get: { value },
            set: { value = $0 }
        )

        let stepper = Stepper(value: binding, in: 0...10)

        // Verify binding is accessible
        let stepperBinding = stepper.valueBinding
        XCTAssertEqual(stepperBinding.wrappedValue, 5, "Binding should return current value")

        // Modify through binding
        stepperBinding.wrappedValue = 8
        XCTAssertEqual(value, 8, "Binding should update value")
    }

    // MARK: - Integration Tests

    func testStepperWithCompleteInteraction() throws {
        var quantity = 1
        let binding = Binding<Int>(
            get: { quantity },
            set: { quantity = $0 }
        )

        let stepper = Stepper("Quantity", value: binding, in: 1...5)

        // Initial state
        XCTAssertEqual(quantity, 1, "Initial quantity should be 1")

        // Increment several times
        stepper.incrementHandler()
        XCTAssertEqual(quantity, 2)
        stepper.incrementHandler()
        XCTAssertEqual(quantity, 3)

        // Decrement
        stepper.decrementHandler()
        XCTAssertEqual(quantity, 2)

        // Increment to maximum
        stepper.incrementHandler()  // 3
        stepper.incrementHandler()  // 4
        stepper.incrementHandler()  // 5
        XCTAssertEqual(quantity, 5)

        // Try to exceed maximum
        stepper.incrementHandler()
        XCTAssertEqual(quantity, 5, "Should stay at maximum")

        // Decrement to minimum
        stepper.decrementHandler()  // 4
        stepper.decrementHandler()  // 3
        stepper.decrementHandler()  // 2
        stepper.decrementHandler()  // 1
        XCTAssertEqual(quantity, 1)

        // Try to go below minimum
        stepper.decrementHandler()
        XCTAssertEqual(quantity, 1, "Should stay at minimum")
    }
}
