import XCTest
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
@available(macOS 13.0, *)
@MainActor
final class SearchableTests: XCTestCase {

    // MARK: - Basic Functionality Tests (4 tests)

    func testBasicSearchable() {
        let searchText = Binding.constant("")

        let view = Text("Content")
            .searchable(text: searchText)

        let node = view.toVNode()

        // Verify root container structure
        XCTAssertEqual(node.elementTag, "div", "Searchable should create root container")
        XCTAssert(node.children.count >= 1, "Should have at least search field")

        // Verify flex layout
        if case .style(name: "display", value: let display) = node.props["display"] {
            XCTAssertEqual(display, "flex", "Root should use flex layout")
        } else {
            XCTFail("Root should have display flex")
        }

        if case .style(name: "flex-direction", value: let direction) = node.props["flex-direction"] {
            XCTAssertEqual(direction, "column", "Should stack vertically")
        } else {
            XCTFail("Root should have flex-direction column")
        }
    }

    func testSearchableWithPrompt() {
        let searchText = Binding.constant("")

        let view = Text("Content")
            .searchable(text: searchText, prompt: Text("Search items"))

        let node = view.toVNode()

        // Find the search field container
        guard node.children.count >= 1 else {
            XCTFail("Should have search field child")
            return
        }

        let searchField = node.children[0]

        // Verify role attribute
        if case .attribute(name: "role", value: let role) = searchField.props["role"] {
            XCTAssertEqual(role, "search", "Search field should have search role")
        } else {
            XCTFail("Search field should have role attribute")
        }

        // Find the input element (nested in wrapper)
        guard searchField.children.count >= 1 else {
            XCTFail("Search field should have children")
            return
        }

        let inputWrapper = searchField.children[0]

        // The input should be the second child (after the icon)
        guard inputWrapper.children.count >= 2 else {
            XCTFail("Input wrapper should have icon and input")
            return
        }

        let input = inputWrapper.children[1]

        // Verify placeholder
        if case .attribute(name: "placeholder", value: let placeholder) = input.props["placeholder"] {
            XCTAssertEqual(placeholder, "Search items", "Should use custom prompt")
        } else {
            XCTFail("Input should have placeholder")
        }
    }

    func testSearchableWithDefaultPrompt() {
        let searchText = Binding.constant("")

        let view = Text("Content")
            .searchable(text: searchText)

        let node = view.toVNode()

        // Navigate to input element
        guard node.children.count >= 1,
              node.children[0].children.count >= 1,
              node.children[0].children[0].children.count >= 2 else {
            XCTFail("Could not find input element")
            return
        }

        let input = node.children[0].children[0].children[1]

        // Verify default placeholder
        if case .attribute(name: "placeholder", value: let placeholder) = input.props["placeholder"] {
            XCTAssertEqual(placeholder, "Search", "Should use default 'Search' prompt")
        } else {
            XCTFail("Input should have default placeholder")
        }
    }

    func testSearchableBindingValue() {
        let searchText = Binding.constant("initial text")

        let view = Text("Content")
            .searchable(text: searchText)

        let node = view.toVNode()

        // Navigate to input element
        guard node.children.count >= 1,
              node.children[0].children.count >= 1,
              node.children[0].children[0].children.count >= 2 else {
            XCTFail("Could not find input element")
            return
        }

        let input = node.children[0].children[0].children[1]

        // Verify value attribute reflects binding
        if case .attribute(name: "value", value: let value) = input.props["value"] {
            XCTAssertEqual(value, "initial text", "Input value should reflect binding")
        } else {
            XCTFail("Input should have value attribute")
        }
    }

    // MARK: - Placement Tests (4 tests)

    func testAutomaticPlacement() {
        let searchText = Binding.constant("")

        let view = Text("Content")
            .searchable(text: searchText, placement: .automatic)

        let node = view.toVNode()

        guard node.children.count >= 1 else {
            XCTFail("Should have search field")
            return
        }

        let searchField = node.children[0]

        // Automatic placement should have background styling
        if case .style(name: "background", value: let bg) = searchField.props["background"] {
            XCTAssertEqual(bg, "#f9fafb", "Automatic placement should have light background")
        } else {
            XCTFail("Automatic placement should have background")
        }

        // Should have border-bottom
        XCTAssertNotNil(searchField.props["border-bottom"], "Should have bottom border")
    }

    func testNavigationBarDrawerPlacement() {
        let searchText = Binding.constant("")

        let view = Text("Content")
            .searchable(text: searchText, placement: .navigationBarDrawer)

        let node = view.toVNode()

        guard node.children.count >= 1 else {
            XCTFail("Should have search field")
            return
        }

        let searchField = node.children[0]

        // Navigation bar drawer should have similar styling to automatic
        if case .style(name: "padding", value: let padding) = searchField.props["padding"] {
            XCTAssertEqual(padding, "12px", "Navigation bar drawer should have padding")
        } else {
            XCTFail("Should have padding")
        }
    }

    func testToolbarPlacement() {
        let searchText = Binding.constant("")

        let view = Text("Content")
            .searchable(text: searchText, placement: .toolbar)

        let node = view.toVNode()

        guard node.children.count >= 1 else {
            XCTFail("Should have search field")
            return
        }

        let searchField = node.children[0]

        // Toolbar placement should have different padding
        if case .style(name: "padding", value: let padding) = searchField.props["padding"] {
            XCTAssertEqual(padding, "8px", "Toolbar placement should have reduced padding")
        } else {
            XCTFail("Should have padding")
        }

        // Should have align-items
        if case .style(name: "align-items", value: let align) = searchField.props["align-items"] {
            XCTAssertEqual(align, "center", "Toolbar should center items")
        } else {
            XCTFail("Should have align-items")
        }
    }

    func testSidebarPlacement() {
        let searchText = Binding.constant("")

        let view = Text("Content")
            .searchable(text: searchText, placement: .sidebar)

        let node = view.toVNode()

        guard node.children.count >= 1 else {
            XCTFail("Should have search field")
            return
        }

        let searchField = node.children[0]

        // Sidebar placement should have border
        XCTAssertNotNil(searchField.props["border-bottom"], "Sidebar should have bottom border")
    }

    // MARK: - Input Element Tests (4 tests)

    func testInputElementType() {
        let searchText = Binding.constant("")

        let view = Text("Content")
            .searchable(text: searchText)

        let node = view.toVNode()

        // Navigate to input element
        guard node.children.count >= 1,
              node.children[0].children.count >= 1,
              node.children[0].children[0].children.count >= 2 else {
            XCTFail("Could not find input element")
            return
        }

        let input = node.children[0].children[0].children[1]

        // Verify input tag and type
        XCTAssertEqual(input.elementTag, "input", "Should be an input element")

        if case .attribute(name: "type", value: let type) = input.props["type"] {
            XCTAssertEqual(type, "search", "Input type should be search")
        } else {
            XCTFail("Input should have type attribute")
        }
    }

    func testInputEventHandler() {
        let searchText = Binding.constant("")

        let view = Text("Content")
            .searchable(text: searchText)

        let node = view.toVNode()

        // Navigate to input element
        guard node.children.count >= 1,
              node.children[0].children.count >= 1,
              node.children[0].children[0].children.count >= 2 else {
            XCTFail("Could not find input element")
            return
        }

        let input = node.children[0].children[0].children[1]

        // Verify event handler exists
        if case .eventHandler(event: let event, handlerID: _) = input.props["onInput"] {
            XCTAssertEqual(event, "input", "Should have input event handler")
        } else {
            XCTFail("Input should have onInput event handler")
        }
    }

    func testInputStyling() {
        let searchText = Binding.constant("")

        let view = Text("Content")
            .searchable(text: searchText)

        let node = view.toVNode()

        // Navigate to input element
        guard node.children.count >= 1,
              node.children[0].children.count >= 1,
              node.children[0].children[0].children.count >= 2 else {
            XCTFail("Could not find input element")
            return
        }

        let input = node.children[0].children[0].children[1]

        // Verify key styling properties
        if case .style(name: "border-radius", value: let radius) = input.props["border-radius"] {
            XCTAssertEqual(radius, "8px", "Should have rounded corners")
        } else {
            XCTFail("Input should have border-radius")
        }

        if case .style(name: "width", value: let width) = input.props["width"] {
            XCTAssertEqual(width, "100%", "Should fill available width")
        } else {
            XCTFail("Input should have width")
        }

        // Verify padding for icon space
        if case .style(name: "padding-left", value: let paddingLeft) = input.props["padding-left"] {
            XCTAssertEqual(paddingLeft, "36px", "Should have space for search icon")
        } else {
            XCTFail("Input should have padding-left for icon")
        }
    }

    func testInputAccessibility() {
        let searchText = Binding.constant("")

        let view = Text("Content")
            .searchable(text: searchText, prompt: Text("Find items"))

        let node = view.toVNode()

        // Navigate to input element
        guard node.children.count >= 1,
              node.children[0].children.count >= 1,
              node.children[0].children[0].children.count >= 2 else {
            XCTFail("Could not find input element")
            return
        }

        let input = node.children[0].children[0].children[1]

        // Verify aria-label
        if case .attribute(name: "aria-label", value: let label) = input.props["aria-label"] {
            XCTAssertEqual(label, "Find items", "Should have aria-label matching prompt")
        } else {
            XCTFail("Input should have aria-label")
        }
    }

    // MARK: - Search Icon Tests (2 tests)

    func testSearchIconPresence() {
        let searchText = Binding.constant("")

        let view = Text("Content")
            .searchable(text: searchText)

        let node = view.toVNode()

        // Navigate to input wrapper
        guard node.children.count >= 1,
              node.children[0].children.count >= 1 else {
            XCTFail("Could not find input wrapper")
            return
        }

        let inputWrapper = node.children[0].children[0]

        // Verify wrapper has relative positioning
        if case .style(name: "position", value: let position) = inputWrapper.props["position"] {
            XCTAssertEqual(position, "relative", "Input wrapper should be relatively positioned")
        } else {
            XCTFail("Input wrapper should have position")
        }

        // First child should be the icon
        guard inputWrapper.children.count >= 2 else {
            XCTFail("Should have icon and input")
            return
        }

        let icon = inputWrapper.children[0]
        XCTAssertEqual(icon.elementTag, "div", "Icon should be in a div")

        // Verify icon has absolute positioning
        if case .style(name: "position", value: let iconPos) = icon.props["position"] {
            XCTAssertEqual(iconPos, "absolute", "Icon should be absolutely positioned")
        } else {
            XCTFail("Icon should have absolute position")
        }
    }

    func testSearchIconSVG() {
        let searchText = Binding.constant("")

        let view = Text("Content")
            .searchable(text: searchText)

        let node = view.toVNode()

        // Navigate to icon container
        guard node.children.count >= 1,
              node.children[0].children.count >= 1,
              node.children[0].children[0].children.count >= 1 else {
            XCTFail("Could not find icon")
            return
        }

        let iconContainer = node.children[0].children[0].children[0]

        // Verify SVG element exists
        guard iconContainer.children.count >= 1 else {
            XCTFail("Icon should contain SVG")
            return
        }

        let svg = iconContainer.children[0]
        XCTAssertEqual(svg.elementTag, "svg", "Should contain SVG element")

        // Verify SVG has viewBox
        if case .attribute(name: "viewBox", value: let viewBox) = svg.props["viewBox"] {
            XCTAssertEqual(viewBox, "0 0 16 16", "SVG should have correct viewBox")
        } else {
            XCTFail("SVG should have viewBox")
        }

        // Verify SVG has children (circle and path)
        XCTAssert(svg.children.count >= 2, "SVG should have circle and path elements")
    }

    // MARK: - Suggestions Tests (2 tests)

    func testSearchableWithoutSuggestions() {
        let searchText = Binding.constant("")

        let view = Text("Content")
            .searchable(text: searchText)

        let node = view.toVNode()

        // Navigate to input
        guard node.children.count >= 1,
              node.children[0].children.count >= 1,
              node.children[0].children[0].children.count >= 2 else {
            XCTFail("Could not find input")
            return
        }

        let input = node.children[0].children[0].children[1]

        // Should not have a list attribute
        XCTAssertNil(input.props["list"], "Should not have datalist reference without suggestions")
    }

    func testSearchableWithSuggestions() {
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
            XCTFail("Could not find input")
            return
        }

        let input = node.children[0].children[0].children[1]

        // Should have a list attribute when suggestions present
        if case .attribute(name: "list", value: let listId) = input.props["list"] {
            XCTAssert(listId.hasPrefix("suggestions-"), "Should reference suggestions datalist")
        } else {
            XCTFail("Input should have list attribute when suggestions provided")
        }

        // Verify datalist exists in search field children
        guard node.children[0].children.count >= 2 else {
            XCTFail("Should have datalist in search field")
            return
        }

        let datalist = node.children[0].children[1]
        XCTAssertEqual(datalist.elementTag, "datalist", "Should have datalist element")

        if case .attribute(name: "id", value: let id) = datalist.props["id"] {
            XCTAssert(id.hasPrefix("suggestions-"), "Datalist should have suggestions ID")
        } else {
            XCTFail("Datalist should have id")
        }
    }

    // MARK: - Integration Tests (1 test)

    func testSearchableIntegration() {
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
        XCTAssertEqual(node.elementTag, "div", "Root should be div")
        XCTAssert(node.children.count >= 1, "Should have search field")

        let searchField = node.children[0]

        // Verify search field has correct role
        if case .attribute(name: "role", value: let role) = searchField.props["role"] {
            XCTAssertEqual(role, "search", "Should have search role")
        }

        // Navigate to input and verify it's properly configured
        guard searchField.children.count >= 1,
              searchField.children[0].children.count >= 2 else {
            XCTFail("Could not find input structure")
            return
        }

        let input = searchField.children[0].children[1]

        // Verify input is properly bound
        if case .attribute(name: "value", value: let value) = input.props["value"] {
            XCTAssertEqual(value, "test", "Input should reflect binding value")
        }

        // Verify event handler
        XCTAssertNotNil(input.props["onInput"], "Should have input handler")
    }
}
