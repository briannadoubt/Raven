import Testing
@testable import Raven

/// Tests for Image and Toggle primitive views
@MainActor
@Suite struct ImageToggleTests {

    // MARK: - Image Tests

    @Test func imageNamedInitializer() throws {
        let image = Image("test-photo")
        let node = image.toVNode()

        #expect(node.elementTag == "img")
        #expect(node.children.isEmpty)

        // Verify src attribute
        if case .attribute(name: "src", value: let src) = node.props["src"] {
            #expect(src.contains("test-photo"))
        } else {
            Issue.record("Image should have src attribute")
        }

        // Verify alt attribute exists
        #expect(node.props["alt"] != nil)
    }

    @Test func imageSystemNameInitializer() throws {
        let image = Image(systemName: "star.fill")
        let node = image.toVNode()

        #expect(node.elementTag == "img")

        // Verify src attribute for system icon
        if case .attribute(name: "src", value: let src) = node.props["src"] {
            #expect(src.contains("data:image/svg+xml"))
            #expect(src.contains("star.fill"))
        } else {
            Issue.record("System image should have src attribute")
        }
    }

    @Test func imageDecorativeInitializer() throws {
        let image = Image(decorative: "background")
        let node = image.toVNode()

        // Verify decorative image has empty alt and presentation role
        if case .attribute(name: "alt", value: let alt) = node.props["alt"] {
            #expect(alt == "")
        } else {
            Issue.record("Decorative image should have alt attribute")
        }

        if case .attribute(name: "role", value: let role) = node.props["role"] {
            #expect(role == "presentation")
        } else {
            Issue.record("Decorative image should have role attribute")
        }
    }

    @Test func imageWithCustomAltText() throws {
        let image = Image("chart", alt: "Sales chart showing upward trend")
        let node = image.toVNode()

        // Verify custom alt text
        if case .attribute(name: "alt", value: let alt) = node.props["alt"] {
            #expect(alt == "Sales chart showing upward trend")
        } else {
            Issue.record("Image should have alt attribute")
        }
    }

    @Test func imageLazyLoading() throws {
        let image = Image("photo")
        let node = image.toVNode()

        // Verify lazy loading attribute
        if case .attribute(name: "loading", value: let loading) = node.props["loading"] {
            #expect(loading == "lazy")
        } else {
            Issue.record("Image should have loading attribute")
        }
    }

    @Test func imageAccessibilityModifier() throws {
        let image = Image("icon")
            .accessibilityLabel("Custom label")
        let node = image.toVNode()

        // Verify accessibility label
        if case .attribute(name: "alt", value: let alt) = node.props["alt"] {
            #expect(alt == "Custom label")
        } else {
            Issue.record("Image should have alt attribute")
        }
    }

    // MARK: - Toggle Tests

    @Test func toggleWithTextLabel() throws {
        var isOn = false
        let binding = Binding<Bool>(
            get: { isOn },
            set: { isOn = $0 }
        )

        let toggle = Toggle("Test Toggle", isOn: binding)
        let node = toggle.toVNode()

        #expect(node.elementTag == "label")
        #expect(!node.children.isEmpty)

        // Find the input element
        let inputNode = node.children.first { child in
            child.elementTag == "input"
        }

        #expect(inputNode != nil)

        // Verify input properties
        if let input = inputNode {
            // Verify type
            if case .attribute(name: "type", value: let type) = input.props["type"] {
                #expect(type == "checkbox")
            } else {
                Issue.record("Input should have type attribute")
            }

            // Verify checked state
            if case .boolAttribute(name: "checked", value: let checked) = input.props["checked"] {
                #expect(!checked)
            } else {
                Issue.record("Input should have checked attribute")
            }

            // Verify role
            if case .attribute(name: "role", value: let role) = input.props["role"] {
                #expect(role == "switch")
            } else {
                Issue.record("Input should have role attribute")
            }

            // Verify onChange event handler
            #expect(input.props["onChange"] != nil)
        }
    }

    @Test func toggleCheckedState() throws {
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
                #expect(checked)
            } else {
                Issue.record("Input should have checked attribute")
            }
        } else {
            Issue.record("Toggle should contain input element")
        }
    }

    @Test func toggleChangeHandler() throws {
        var isOn = false
        let binding = Binding<Bool>(
            get: { isOn },
            set: { isOn = $0 }
        )

        let toggle = Toggle("Test", isOn: binding)

        // Execute change handler
        #expect(!isOn)
        toggle.changeHandler()
        #expect(isOn)
        toggle.changeHandler()
        #expect(!isOn)
    }

    @Test func toggleWithCustomLabel() throws {
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

        #expect(node.elementTag == "label")
        #expect(!node.children.isEmpty)

        // Verify input element exists
        let hasInput = node.children.contains { child in
            child.elementTag == "input"
        }
        #expect(hasInput)
    }

    @Test func toggleAriaAttributes() throws {
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
                #expect(ariaChecked == "true")
            } else {
                Issue.record("Input should have aria-checked attribute")
            }
        } else {
            Issue.record("Toggle should contain input element")
        }
    }

    @Test func toggleWithLocalizedStringKey() throws {
        var isOn = false
        let binding = Binding<Bool>(
            get: { isOn },
            set: { isOn = $0 }
        )

        let toggle = Toggle(LocalizedStringKey("toggle_key"), isOn: binding)
        let node = toggle.toVNode()

        #expect(node.elementTag == "label")
    }

    @Test func toggleIDModifier() throws {
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
                #expect(id == "custom-toggle-id")
            } else {
                Issue.record("Input should have id attribute")
            }
        } else {
            Issue.record("Toggle should contain input element")
        }
    }

    // MARK: - Integration Tests

    @Test func imageAndToggleTogether() throws {
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

        #expect(toggleNode.elementTag == "label")
        #expect(imageNode.elementTag == "img")
        #expect(showImage)

        // Test interaction
        toggle.changeHandler()
        #expect(!showImage)
    }
}
