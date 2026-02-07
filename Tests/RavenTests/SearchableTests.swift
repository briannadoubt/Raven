import Testing
@testable import Raven

/// Tests for the searchable modifier
///
/// This test suite verifies the `.searchable()` modifier functionality:
/// - Basic searchable with text binding
/// - Search field with custom prompt
/// - Different placement options
/// - Searchable with suggestions
/// - VNode structure generation
/// - Event handler setup
/// - CSS styling and layout
///
/// The searchable modifier adds search functionality to views, typically used
/// with lists to enable filtering. It renders as an HTML `<input type="search">`
/// element with proper styling and event handlers.
@MainActor
@Suite struct SearchableTests {

    // MARK: - Basic Functionality Tests (4 tests)

    @Test func basicSearchable() {
        let searchText = Binding.constant("")

        let view = Text("Content")
            .searchable(text: searchText)

        let node = view.toVNode()

        // Verify root container structure
        #expect(node.elementTag == "div")
        #expect(node.children.count >= 1)

        // Verify flex layout
        if case .style(name: "display", value: let display) = node.props["display"] {
            #expect(display == "flex")
        } else {
            Issue.record("Root should have display flex")
        }

        if case .style(name: "flex-direction", value: let direction) = node.props["flex-direction"] {
            #expect(direction == "column")
        } else {
            Issue.record("Root should have flex-direction column")
        }
    }

    @Test func searchableWithPrompt() {
        let searchText = Binding.constant("")

        let view = Text("Content")
            .searchable(text: searchText, prompt: Text("Search items"))

        let node = view.toVNode()

        // Find the search field container
        guard node.children.count >= 1 else {
            Issue.record("Should have search field child")
            return
        }

        let searchField = node.children[0]

        // Verify role attribute
        if case .attribute(name: "role", value: let role) = searchField.props["role"] {
            #expect(role == "search")
        } else {
            Issue.record("Search field should have role attribute")
        }

        // Find the input element (nested in wrapper)
        guard searchField.children.count >= 1 else {
            Issue.record("Search field should have children")
            return
        }

        let inputWrapper = searchField.children[0]

        // The input should be the second child (after the icon)
        guard inputWrapper.children.count >= 2 else {
            Issue.record("Input wrapper should have icon and input")
            return
        }

        let input = inputWrapper.children[1]

        // Verify placeholder
        if case .attribute(name: "placeholder", value: let placeholder) = input.props["placeholder"] {
            #expect(placeholder == "Search items")
        } else {
            Issue.record("Input should have placeholder")
        }
    }

    @Test func searchableWithDefaultPrompt() {
        let searchText = Binding.constant("")

        let view = Text("Content")
            .searchable(text: searchText)

        let node = view.toVNode()

        // Navigate to input element
        guard node.children.count >= 1,
              node.children[0].children.count >= 1,
              node.children[0].children[0].children.count >= 2 else {
            Issue.record("Could not find input element")
            return
        }

        let input = node.children[0].children[0].children[1]

        // Verify default placeholder
        if case .attribute(name: "placeholder", value: let placeholder) = input.props["placeholder"] {
            #expect(placeholder == "Search")
        } else {
            Issue.record("Input should have default placeholder")
        }
    }

    @Test func searchableBindingValue() {
        let searchText = Binding.constant("initial text")

        let view = Text("Content")
            .searchable(text: searchText)

        let node = view.toVNode()

        // Navigate to input element
        guard node.children.count >= 1,
              node.children[0].children.count >= 1,
              node.children[0].children[0].children.count >= 2 else {
            Issue.record("Could not find input element")
            return
        }

        let input = node.children[0].children[0].children[1]

        // Verify value attribute reflects binding
        if case .attribute(name: "value", value: let value) = input.props["value"] {
            #expect(value == "initial text")
        } else {
            Issue.record("Input should have value attribute")
        }
    }

    // MARK: - Placement Tests (4 tests)

    @Test func automaticPlacement() {
        let searchText = Binding.constant("")

        let view = Text("Content")
            .searchable(text: searchText, placement: .automatic)

        let node = view.toVNode()

        guard node.children.count >= 1 else {
            Issue.record("Should have search field")
            return
        }

        let searchField = node.children[0]

        // Automatic placement should have background styling
        if case .style(name: "background", value: let bg) = searchField.props["background"] {
            #expect(bg == "#f9fafb")
        } else {
            Issue.record("Automatic placement should have background")
        }

        // Should have border-bottom
        #expect(searchField.props["border-bottom"] != nil)
    }

    @Test func navigationBarDrawerPlacement() {
        let searchText = Binding.constant("")

        let view = Text("Content")
            .searchable(text: searchText, placement: .navigationBarDrawer)

        let node = view.toVNode()

        guard node.children.count >= 1 else {
            Issue.record("Should have search field")
            return
        }

        let searchField = node.children[0]

        // Navigation bar drawer should have similar styling to automatic
        if case .style(name: "padding", value: let padding) = searchField.props["padding"] {
            #expect(padding == "12px")
        } else {
            Issue.record("Should have padding")
        }
    }

    @Test func toolbarPlacement() {
        let searchText = Binding.constant("")

        let view = Text("Content")
            .searchable(text: searchText, placement: .toolbar)

        let node = view.toVNode()

        guard node.children.count >= 1 else {
            Issue.record("Should have search field")
            return
        }

        let searchField = node.children[0]

        // Toolbar placement should have different padding
        if case .style(name: "padding", value: let padding) = searchField.props["padding"] {
            #expect(padding == "8px")
        } else {
            Issue.record("Should have padding")
        }

        // Should have align-items
        if case .style(name: "align-items", value: let align) = searchField.props["align-items"] {
            #expect(align == "center")
        } else {
            Issue.record("Should have align-items")
        }
    }

    @Test func sidebarPlacement() {
        let searchText = Binding.constant("")

        let view = Text("Content")
            .searchable(text: searchText, placement: .sidebar)

        let node = view.toVNode()

        guard node.children.count >= 1 else {
            Issue.record("Should have search field")
            return
        }

        let searchField = node.children[0]

        // Sidebar placement should have border
        #expect(searchField.props["border-bottom"] != nil)
    }

    // MARK: - Input Element Tests (4 tests)

    @Test func inputElementType() {
        let searchText = Binding.constant("")

        let view = Text("Content")
            .searchable(text: searchText)

        let node = view.toVNode()

        // Navigate to input element
        guard node.children.count >= 1,
              node.children[0].children.count >= 1,
              node.children[0].children[0].children.count >= 2 else {
            Issue.record("Could not find input element")
            return
        }

        let input = node.children[0].children[0].children[1]

        // Verify input tag and type
        #expect(input.elementTag == "input")

        if case .attribute(name: "type", value: let type) = input.props["type"] {
            #expect(type == "search")
        } else {
            Issue.record("Input should have type attribute")
        }
    }

    @Test func inputEventHandler() {
        let searchText = Binding.constant("")

        let view = Text("Content")
            .searchable(text: searchText)

        let node = view.toVNode()

        // Navigate to input element
        guard node.children.count >= 1,
              node.children[0].children.count >= 1,
              node.children[0].children[0].children.count >= 2 else {
            Issue.record("Could not find input element")
            return
        }

        let input = node.children[0].children[0].children[1]

        // Verify event handler exists
        if case .eventHandler(event: let event, handlerID: _) = input.props["onInput"] {
            #expect(event == "input")
        } else {
            Issue.record("Input should have onInput event handler")
        }
    }

    @Test func inputStyling() {
        let searchText = Binding.constant("")

        let view = Text("Content")
            .searchable(text: searchText)

        let node = view.toVNode()

        // Navigate to input element
        guard node.children.count >= 1,
              node.children[0].children.count >= 1,
              node.children[0].children[0].children.count >= 2 else {
            Issue.record("Could not find input element")
            return
        }

        let input = node.children[0].children[0].children[1]

        // Verify key styling properties
        if case .style(name: "border-radius", value: let radius) = input.props["border-radius"] {
            #expect(radius == "8px")
        } else {
            Issue.record("Input should have border-radius")
        }

        if case .style(name: "width", value: let width) = input.props["width"] {
            #expect(width == "100%")
        } else {
            Issue.record("Input should have width")
        }

        // Verify padding for icon space
        if case .style(name: "padding-left", value: let paddingLeft) = input.props["padding-left"] {
            #expect(paddingLeft == "36px")
        } else {
            Issue.record("Input should have padding-left for icon")
        }
    }

    @Test func inputAccessibility() {
        let searchText = Binding.constant("")

        let view = Text("Content")
            .searchable(text: searchText, prompt: Text("Find items"))

        let node = view.toVNode()

        // Navigate to input element
        guard node.children.count >= 1,
              node.children[0].children.count >= 1,
              node.children[0].children[0].children.count >= 2 else {
            Issue.record("Could not find input element")
            return
        }

        let input = node.children[0].children[0].children[1]

        // Verify aria-label
        if case .attribute(name: "aria-label", value: let label) = input.props["aria-label"] {
            #expect(label == "Find items")
        } else {
            Issue.record("Input should have aria-label")
        }
    }

    // MARK: - Search Icon Tests (2 tests)

    @Test func searchIconPresence() {
        let searchText = Binding.constant("")

        let view = Text("Content")
            .searchable(text: searchText)

        let node = view.toVNode()

        // Navigate to input wrapper
        guard node.children.count >= 1,
              node.children[0].children.count >= 1 else {
            Issue.record("Could not find input wrapper")
            return
        }

        let inputWrapper = node.children[0].children[0]

        // Verify wrapper has relative positioning
        if case .style(name: "position", value: let position) = inputWrapper.props["position"] {
            #expect(position == "relative")
        } else {
            Issue.record("Input wrapper should have position")
        }

        // First child should be the icon
        guard inputWrapper.children.count >= 2 else {
            Issue.record("Should have icon and input")
            return
        }

        let icon = inputWrapper.children[0]
        #expect(icon.elementTag == "div")

        // Verify icon has absolute positioning
        if case .style(name: "position", value: let iconPos) = icon.props["position"] {
            #expect(iconPos == "absolute")
        } else {
            Issue.record("Icon should have absolute position")
        }
    }

    @Test func searchIconSVG() {
        let searchText = Binding.constant("")

        let view = Text("Content")
            .searchable(text: searchText)

        let node = view.toVNode()

        // Navigate to icon container
        guard node.children.count >= 1,
              node.children[0].children.count >= 1,
              node.children[0].children[0].children.count >= 1 else {
            Issue.record("Could not find icon")
            return
        }

        let iconContainer = node.children[0].children[0].children[0]

        // Verify SVG element exists
        guard iconContainer.children.count >= 1 else {
            Issue.record("Icon should contain SVG")
            return
        }

        let svg = iconContainer.children[0]
        #expect(svg.elementTag == "svg")

        // Verify SVG has viewBox
        if case .attribute(name: "viewBox", value: let viewBox) = svg.props["viewBox"] {
            #expect(viewBox == "0 0 16 16")
        } else {
            Issue.record("SVG should have viewBox")
        }

        // Verify SVG has children (circle and path)
        #expect(svg.children.count >= 2)
    }

    // MARK: - Suggestions Tests (2 tests)

    @Test func searchableWithoutSuggestions() {
        let searchText = Binding.constant("")

        let view = Text("Content")
            .searchable(text: searchText)

        let node = view.toVNode()

        // Navigate to input
        guard node.children.count >= 1,
              node.children[0].children.count >= 1,
              node.children[0].children[0].children.count >= 2 else {
            Issue.record("Could not find input")
            return
        }

        let input = node.children[0].children[0].children[1]

        // Should not have a list attribute
        #expect(input.props["list"] == nil)
    }

    @Test func searchableWithSuggestions() {
        let searchText = Binding.constant("")

        let view = Text("Content")
            .searchable(text: searchText) {
                Text("Suggestion 1")
                Text("Suggestion 2")
            }

        let node = view.toVNode()

        // Navigate to input
        guard node.children.count >= 1,
              node.children[0].children.count >= 1,
              node.children[0].children[0].children.count >= 2 else {
            Issue.record("Could not find input")
            return
        }

        let input = node.children[0].children[0].children[1]

        // Should have a list attribute when suggestions present
        if case .attribute(name: "list", value: let listId) = input.props["list"] {
            #expect(listId.hasPrefix("suggestions-"))
        } else {
            Issue.record("Input should have list attribute when suggestions provided")
        }

        // Verify datalist exists in search field children
        guard node.children[0].children.count >= 2 else {
            Issue.record("Should have datalist in search field")
            return
        }

        let datalist = node.children[0].children[1]
        #expect(datalist.elementTag == "datalist")

        if case .attribute(name: "id", value: let id) = datalist.props["id"] {
            #expect(id.hasPrefix("suggestions-"))
        } else {
            Issue.record("Datalist should have id")
        }
    }

    // MARK: - Integration Tests (1 test)

    @Test func searchableIntegration() {
        let searchText = Binding.constant("test")

        // Simulate a typical list with search
        let view = Text("Item 1")
            .searchable(
                text: searchText,
                placement: .navigationBarDrawer,
                prompt: Text("Search items")
            )

        let node = view.toVNode()

        // Verify complete structure
        #expect(node.elementTag == "div")
        #expect(node.children.count >= 1)

        let searchField = node.children[0]

        // Verify search field has correct role
        if case .attribute(name: "role", value: let role) = searchField.props["role"] {
            #expect(role == "search")
        }

        // Navigate to input and verify it's properly configured
        guard searchField.children.count >= 1,
              searchField.children[0].children.count >= 2 else {
            Issue.record("Could not find input structure")
            return
        }

        let input = searchField.children[0].children[1]

        // Verify input is properly bound
        if case .attribute(name: "value", value: let value) = input.props["value"] {
            #expect(value == "test")
        }

        // Verify event handler
        #expect(input.props["onInput"] != nil)
    }
}
