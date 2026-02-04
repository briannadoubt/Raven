import XCTest
@testable import Raven

/// Tests for Image and Toggle primitive views
@MainActor
final class ImageToggleTests: XCTestCase {

    // MARK: - Image Tests

    func testImageNamedInitializer() throws {
        let image = Image("test-photo")
        let node = image.toVNode()

        XCTAssertEqual(node.elementTag, "img", "Image should render as img element")
        XCTAssertTrue(node.children.isEmpty, "Image should have no children")

        // Verify src attribute
        if case .attribute(name: "src", value: let src) = node.props["src"] {
            XCTAssertTrue(src.contains("test-photo"), "Should contain image name")
        } else {
            XCTFail("Image should have src attribute")
        }

        // Verify alt attribute exists
        XCTAssertNotNil(node.props["alt"], "Image should have alt attribute")
    }

    func testImageSystemNameInitializer() throws {
        let image = Image(systemName: "star.fill")
        let node = image.toVNode()

        XCTAssertEqual(node.elementTag, "img", "System image should render as img element")

        // Verify src attribute for system icon
        if case .attribute(name: "src", value: let src) = node.props["src"] {
            XCTAssertTrue(src.contains("data:image/svg+xml"), "System icon should use SVG data URL")
            XCTAssertTrue(src.contains("star.fill"), "Should contain system name")
        } else {
            XCTFail("System image should have src attribute")
        }
    }

    func testImageDecorativeInitializer() throws {
        let image = Image(decorative: "background")
        let node = image.toVNode()

        // Verify decorative image has empty alt and presentation role
        if case .attribute(name: "alt", value: let alt) = node.props["alt"] {
            XCTAssertEqual(alt, "", "Decorative image should have empty alt text")
        } else {
            XCTFail("Decorative image should have alt attribute")
        }

        if case .attribute(name: "role", value: let role) = node.props["role"] {
            XCTAssertEqual(role, "presentation", "Decorative image should have presentation role")
        } else {
            XCTFail("Decorative image should have role attribute")
        }
    }

    func testImageWithCustomAltText() throws {
        let image = Image("chart", alt: "Sales chart showing upward trend")
        let node = image.toVNode()

        // Verify custom alt text
        if case .attribute(name: "alt", value: let alt) = node.props["alt"] {
            XCTAssertEqual(alt, "Sales chart showing upward trend", "Should use custom alt text")
        } else {
            XCTFail("Image should have alt attribute")
        }
    }

    func testImageLazyLoading() throws {
        let image = Image("photo")
        let node = image.toVNode()

        // Verify lazy loading attribute
        if case .attribute(name: "loading", value: let loading) = node.props["loading"] {
            XCTAssertEqual(loading, "lazy", "Image should have lazy loading")
        } else {
            XCTFail("Image should have loading attribute")
        }
    }

    func testImageAccessibilityModifier() throws {
        let image = Image("icon")
            .accessibilityLabel("Custom label")
        let node = image.toVNode()

        // Verify accessibility label
        if case .attribute(name: "alt", value: let alt) = node.props["alt"] {
            XCTAssertEqual(alt, "Custom label", "Should use accessibility label")
        } else {
            XCTFail("Image should have alt attribute")
        }
    }

    // MARK: - Toggle Tests

    func testToggleWithTextLabel() throws {
        var isOn = false
        let binding = Binding<Bool>(
            get: { isOn },
            set: { isOn = $0 }
        )

        let toggle = Toggle("Test Toggle", isOn: binding)
        let node = toggle.toVNode()

        XCTAssertEqual(node.elementTag, "label", "Toggle should render as label element")
        XCTAssertFalse(node.children.isEmpty, "Toggle should have children")

        // Find the input element
        let inputNode = node.children.first { child in
            child.elementTag == "input"
        }

        XCTAssertNotNil(inputNode, "Toggle should contain input element")

        // Verify input properties
        if let input = inputNode {
            // Verify type
            if case .attribute(name: "type", value: let type) = input.props["type"] {
                XCTAssertEqual(type, "checkbox", "Input should be checkbox type")
            } else {
                XCTFail("Input should have type attribute")
            }

            // Verify checked state
            if case .boolAttribute(name: "checked", value: let checked) = input.props["checked"] {
                XCTAssertFalse(checked, "Initial state should be false")
            } else {
                XCTFail("Input should have checked attribute")
            }

            // Verify role
            if case .attribute(name: "role", value: let role) = input.props["role"] {
                XCTAssertEqual(role, "switch", "Input should have switch role")
            } else {
                XCTFail("Input should have role attribute")
            }

            // Verify onChange event handler
            XCTAssertNotNil(input.props["onChange"], "Input should have onChange handler")
        }
    }

    func testToggleCheckedState() throws {
        var isOn = true
        let binding = Binding<Bool>(
            get: { isOn },
            set: { isOn = $0 }
        )

        let toggle = Toggle("Enabled", isOn: binding)
        let node = toggle.toVNode()

        // Find the input element
        let inputNode = node.children.first { child in
            child.elementTag == "input"
        }

        if let input = inputNode {
            // Verify checked state is true
            if case .boolAttribute(name: "checked", value: let checked) = input.props["checked"] {
                XCTAssertTrue(checked, "State should be true")
            } else {
                XCTFail("Input should have checked attribute")
            }
        } else {
            XCTFail("Toggle should contain input element")
        }
    }

    func testToggleChangeHandler() throws {
        var isOn = false
        let binding = Binding<Bool>(
            get: { isOn },
            set: { isOn = $0 }
        )

        let toggle = Toggle("Test", isOn: binding)

        // Execute change handler
        XCTAssertFalse(isOn, "Initial state should be false")
        toggle.changeHandler()
        XCTAssertTrue(isOn, "State should toggle to true")
        toggle.changeHandler()
        XCTAssertFalse(isOn, "State should toggle back to false")
    }

    func testToggleWithCustomLabel() throws {
        var isOn = false
        let binding = Binding<Bool>(
            get: { isOn },
            set: { isOn = $0 }
        )

        let toggle = Toggle(isOn: binding) {
            HStack {
                Image(systemName: "bell")
                Text("Notifications")
            }
        }
        let node = toggle.toVNode()

        XCTAssertEqual(node.elementTag, "label", "Toggle should render as label element")
        XCTAssertFalse(node.children.isEmpty, "Toggle should have children")

        // Verify input element exists
        let hasInput = node.children.contains { child in
            child.elementTag == "input"
        }
        XCTAssertTrue(hasInput, "Toggle should contain input element")
    }

    func testToggleAriaAttributes() throws {
        var isOn = true
        let binding = Binding<Bool>(
            get: { isOn },
            set: { isOn = $0 }
        )

        let toggle = Toggle("Accessible Toggle", isOn: binding)
        let node = toggle.toVNode()

        // Find the input element
        let inputNode = node.children.first { child in
            child.elementTag == "input"
        }

        if let input = inputNode {
            // Verify aria-checked attribute
            if case .attribute(name: "aria-checked", value: let ariaChecked) = input.props["aria-checked"] {
                XCTAssertEqual(ariaChecked, "true", "aria-checked should match state")
            } else {
                XCTFail("Input should have aria-checked attribute")
            }
        } else {
            XCTFail("Toggle should contain input element")
        }
    }

    func testToggleWithLocalizedStringKey() throws {
        var isOn = false
        let binding = Binding<Bool>(
            get: { isOn },
            set: { isOn = $0 }
        )

        let toggle = Toggle(LocalizedStringKey("toggle_key"), isOn: binding)
        let node = toggle.toVNode()

        XCTAssertEqual(node.elementTag, "label", "Toggle should render as label element")
    }

    func testToggleIDModifier() throws {
        var isOn = false
        let binding = Binding<Bool>(
            get: { isOn },
            set: { isOn = $0 }
        )

        let toggle = Toggle("Test", isOn: binding)
            .toggleID("custom-toggle-id")
        let node = toggle.toVNode()

        // Find the input element
        let inputNode = node.children.first { child in
            child.elementTag == "input"
        }

        if let input = inputNode {
            // Verify custom ID
            if case .attribute(name: "id", value: let id) = input.props["id"] {
                XCTAssertEqual(id, "custom-toggle-id", "Should use custom ID")
            } else {
                XCTFail("Input should have id attribute")
            }
        } else {
            XCTFail("Toggle should contain input element")
        }
    }

    // MARK: - Integration Tests

    func testImageAndToggleTogether() throws {
        var showImage = true
        let binding = Binding<Bool>(
            get: { showImage },
            set: { showImage = $0 }
        )

        // Create a simple view with both Image and Toggle
        let toggle = Toggle("Show Image", isOn: binding)
        let image = Image("test")

        let toggleNode = toggle.toVNode()
        let imageNode = image.toVNode()

        XCTAssertEqual(toggleNode.elementTag, "label", "Toggle should be label")
        XCTAssertEqual(imageNode.elementTag, "img", "Image should be img")
        XCTAssertTrue(showImage, "Initial state should be true")

        // Test interaction
        toggle.changeHandler()
        XCTAssertFalse(showImage, "State should toggle")
    }
}
