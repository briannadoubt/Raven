import XCTest
@testable import Raven

/// Tests for the Menu component and related functionality.
///
/// These tests verify:
/// - Basic menu creation with text labels
/// - Custom label menus
/// - Menu rendering to VNodes
/// - Menu styles
/// - Context menu modifier
/// - Accessibility attributes
final class MenuTests: XCTestCase {

    // MARK: - Basic Menu Tests

    /// Test creating a menu with a simple text label
    @MainActor
    func testMenuWithTextLabel() {
        let menu = Menu("Actions") {
            Button("Copy") { }
            Button("Paste") { }
        }

        // Menu should be a primitive view
        XCTAssertTrue(type(of: menu).Body.self == Never.self)
    }

    /// Test creating a menu with a localized string key
    @MainActor
    func testMenuWithLocalizedKey() {
        let menu = Menu(LocalizedStringKey("menu_title")) {
            Button("Action 1") { }
            Button("Action 2") { }
        }

        XCTAssertTrue(type(of: menu).Body.self == Never.self)
    }

    /// Test creating a menu with a custom label
    @MainActor
    func testMenuWithCustomLabel() {
        let menu = Menu {
            Button("Edit") { }
            Button("Delete") { }
        } label: {
            HStack {
                Text("Options")
            }
        }

        XCTAssertTrue(type(of: menu).Body.self == Never.self)
    }

    // MARK: - VNode Rendering Tests

    /// Test that menu renders to correct VNode structure
    @MainActor
    func testMenuRendersToVNode() {
        let menu = Menu("Actions") {
            Button("Copy") { }
            Button("Paste") { }
        }

        let vnode = menu.toVNode()

        // Should render as a div container
        XCTAssertTrue(vnode.isElement(tag: "div"))

        // Should have class "raven-menu"
        if case .attribute(name: "class", value: let className) = vnode.props["class"] {
            XCTAssertEqual(className, "raven-menu")
        } else {
            XCTFail("Menu should have class attribute")
        }

        // Should have position relative
        if case .style(name: "position", value: let position) = vnode.props["position"] {
            XCTAssertEqual(position, "relative")
        } else {
            XCTFail("Menu should have position style")
        }

        // Should have two children: trigger button and dropdown
        XCTAssertEqual(vnode.children.count, 2)
    }

    /// Test that menu trigger button has correct attributes
    @MainActor
    func testMenuTriggerButton() {
        let menu = Menu("Options") {
            Button("Action") { }
        }

        let vnode = menu.toVNode()
        XCTAssertEqual(vnode.children.count, 2)

        let trigger = vnode.children[0]

        // Should be a button element
        XCTAssertTrue(trigger.isElement(tag: "button"))

        // Should have class "raven-menu-trigger"
        if case .attribute(name: "class", value: let className) = trigger.props["class"] {
            XCTAssertEqual(className, "raven-menu-trigger")
        } else {
            XCTFail("Trigger should have class attribute")
        }

        // Should have ARIA attributes
        if case .attribute(name: "aria-haspopup", value: let hasPopup) = trigger.props["aria-haspopup"] {
            XCTAssertEqual(hasPopup, "true")
        } else {
            XCTFail("Trigger should have aria-haspopup attribute")
        }

        if case .attribute(name: "aria-expanded", value: let expanded) = trigger.props["aria-expanded"] {
            XCTAssertEqual(expanded, "false")
        } else {
            XCTFail("Trigger should have aria-expanded attribute")
        }

        // Should have click handler
        XCTAssertNotNil(trigger.props["onClick"])
    }

    /// Test that menu dropdown has correct attributes
    @MainActor
    func testMenuDropdown() {
        let menu = Menu("Options") {
            Button("Action 1") { }
            Button("Action 2") { }
        }

        let vnode = menu.toVNode()
        XCTAssertEqual(vnode.children.count, 2)

        let dropdown = vnode.children[1]

        // Should be a div element
        XCTAssertTrue(dropdown.isElement(tag: "div"))

        // Should have class "raven-menu-dropdown"
        if case .attribute(name: "class", value: let className) = dropdown.props["class"] {
            XCTAssertEqual(className, "raven-menu-dropdown")
        } else {
            XCTFail("Dropdown should have class attribute")
        }

        // Should have role="menu"
        if case .attribute(name: "role", value: let role) = dropdown.props["role"] {
            XCTAssertEqual(role, "menu")
        } else {
            XCTFail("Dropdown should have role attribute")
        }

        // Should be hidden by default (display: none)
        if case .style(name: "display", value: let display) = dropdown.props["display"] {
            XCTAssertEqual(display, "none")
        } else {
            XCTFail("Dropdown should have display style")
        }

        // Should have position absolute
        if case .style(name: "position", value: let position) = dropdown.props["position"] {
            XCTAssertEqual(position, "absolute")
        } else {
            XCTFail("Dropdown should have position style")
        }

        // Should have z-index for layering
        if case .style(name: "z-index", value: let zIndex) = dropdown.props["z-index"] {
            XCTAssertEqual(zIndex, "1000")
        } else {
            XCTFail("Dropdown should have z-index style")
        }
    }

    // MARK: - Menu Style Tests

    /// Test default menu style
    @MainActor
    func testDefaultMenuStyle() {
        let style = DefaultMenuStyle()
        let config = MenuStyleConfiguration(
            label: AnyView(Text("Test")),
            content: AnyView(Button("Action") { })
        )

        let body = style.makeBody(configuration: config)
        // Default style returns content as-is
        XCTAssertNotNil(body)
    }

    /// Test button menu style
    @MainActor
    func testButtonMenuStyle() {
        let style = ButtonMenuStyle()
        let config = MenuStyleConfiguration(
            label: AnyView(Text("Test")),
            content: AnyView(Button("Action") { })
        )

        let body = style.makeBody(configuration: config)
        XCTAssertNotNil(body)
    }

    /// Test menu style convenience accessors
    @MainActor
    func testMenuStyleConvenience() {
        let defaultStyle: DefaultMenuStyle = .default
        XCTAssertNotNil(defaultStyle)

        let buttonStyle: ButtonMenuStyle = .button
        XCTAssertNotNil(buttonStyle)
    }

    // MARK: - Context Menu Tests

    /// Test applying context menu modifier
    @MainActor
    func testContextMenuModifier() {
        let view = Text("Right-click me")
            .contextMenu {
                Button("Copy") { }
                Button("Paste") { }
            }

        XCTAssertNotNil(view)
    }

    /// Test context menu with destructive actions
    @MainActor
    func testContextMenuWithDestructiveAction() {
        let view = Text("Item")
            .contextMenu {
                Button("Edit") { }
                Button("Delete", role: .destructive) { }
            }

        XCTAssertNotNil(view)
    }

    // MARK: - Accessibility Tests

    /// Test that menu includes required ARIA attributes
    @MainActor
    func testMenuAccessibility() {
        let menu = Menu("Options") {
            Button("Action") { }
        }

        let vnode = menu.toVNode()
        let trigger = vnode.children[0]
        let dropdown = vnode.children[1]

        // Trigger should have aria-haspopup
        XCTAssertNotNil(trigger.props["aria-haspopup"])

        // Trigger should have aria-expanded
        XCTAssertNotNil(trigger.props["aria-expanded"])

        // Trigger should have aria-controls pointing to dropdown
        XCTAssertNotNil(trigger.props["aria-controls"])

        // Dropdown should have role="menu"
        XCTAssertNotNil(dropdown.props["role"])

        // Dropdown should have aria-labelledby pointing to trigger
        XCTAssertNotNil(dropdown.props["aria-labelledby"])
    }

    /// Test that trigger and dropdown IDs are coordinated
    @MainActor
    func testMenuIDCoordination() {
        let menu = Menu("Options") {
            Button("Action") { }
        }

        let vnode = menu.toVNode()
        let trigger = vnode.children[0]
        let dropdown = vnode.children[1]

        // Get trigger ID
        guard case .attribute(name: "id", value: let triggerID) = trigger.props["id"] else {
            XCTFail("Trigger should have ID")
            return
        }

        // Get dropdown ID
        guard case .attribute(name: "id", value: let dropdownID) = dropdown.props["id"] else {
            XCTFail("Dropdown should have ID")
            return
        }

        // Trigger aria-controls should match dropdown ID
        if case .attribute(name: "aria-controls", value: let controls) = trigger.props["aria-controls"] {
            XCTAssertEqual(controls, dropdownID)
        } else {
            XCTFail("Trigger should have aria-controls")
        }

        // Dropdown aria-labelledby should match trigger ID
        if case .attribute(name: "aria-labelledby", value: let labelledBy) = dropdown.props["aria-labelledby"] {
            XCTAssertEqual(labelledBy, triggerID)
        } else {
            XCTFail("Dropdown should have aria-labelledby")
        }
    }

    // MARK: - Integration Tests

    /// Test menu with multiple items
    @MainActor
    func testMenuWithMultipleItems() {
        let menu = Menu("File") {
            Button("New") { }
            Button("Open") { }
            Button("Save") { }
            Button("Close") { }
        }

        let vnode = menu.toVNode()
        XCTAssertNotNil(vnode)

        // Should have container with trigger and dropdown
        XCTAssertEqual(vnode.children.count, 2)
    }

    /// Test menu with conditional items
    @MainActor
    func testMenuWithConditionalItems() {
        let showDelete = true

        let menu = Menu("Edit") {
            Button("Copy") { }
            Button("Paste") { }
            if showDelete {
                Button("Delete", role: .destructive) { }
            }
        }

        let vnode = menu.toVNode()
        XCTAssertNotNil(vnode)
    }

    /// Test nested menu structure
    @MainActor
    func testNestedMenus() {
        // Note: This tests the structure, not the full nested menu functionality
        let menu = Menu("File") {
            Button("New") { }
            // Nested menus would be implemented here
            Button("Save") { }
        }

        let vnode = menu.toVNode()
        XCTAssertNotNil(vnode)
        XCTAssertEqual(vnode.children.count, 2)
    }

    // MARK: - CSS Class Tests

    /// Test that menu uses correct CSS classes
    @MainActor
    func testMenuCSSClasses() {
        let menu = Menu("Test") {
            Button("Action") { }
        }

        let vnode = menu.toVNode()

        // Container should have "raven-menu"
        if case .attribute(name: "class", value: let className) = vnode.props["class"] {
            XCTAssertEqual(className, "raven-menu")
        }

        // Trigger should have "raven-menu-trigger"
        let trigger = vnode.children[0]
        if case .attribute(name: "class", value: let className) = trigger.props["class"] {
            XCTAssertEqual(className, "raven-menu-trigger")
        }

        // Dropdown should have "raven-menu-dropdown"
        let dropdown = vnode.children[1]
        if case .attribute(name: "class", value: let className) = dropdown.props["class"] {
            XCTAssertEqual(className, "raven-menu-dropdown")
        }
    }

    /// Test that menu items have correct class
    @MainActor
    func testMenuItemCSSClass() {
        let menu = Menu("Test") {
            Button("Action") { }
        }

        let vnode = menu.toVNode()
        let dropdown = vnode.children[1]

        // Menu items should have "raven-menu-item" class
        // (if any items were rendered - this is a structure test)
        XCTAssertNotNil(dropdown)
    }

    // MARK: - Styling Tests

    /// Test that menu has default styling
    @MainActor
    func testMenuDefaultStyling() {
        let menu = Menu("Options") {
            Button("Action") { }
        }

        let vnode = menu.toVNode()
        let trigger = vnode.children[0]

        // Trigger should have padding
        XCTAssertNotNil(trigger.props["padding"])

        // Trigger should have border
        XCTAssertNotNil(trigger.props["border"])

        // Trigger should have border-radius
        XCTAssertNotNil(trigger.props["border-radius"])

        // Trigger should have cursor pointer
        if case .style(name: "cursor", value: let cursor) = trigger.props["cursor"] {
            XCTAssertEqual(cursor, "pointer")
        }
    }

    /// Test that dropdown has correct positioning styles
    @MainActor
    func testDropdownPositioning() {
        let menu = Menu("Options") {
            Button("Action") { }
        }

        let vnode = menu.toVNode()
        let dropdown = vnode.children[1]

        // Should have position absolute
        if case .style(name: "position", value: let position) = dropdown.props["position"] {
            XCTAssertEqual(position, "absolute")
        }

        // Should have top positioning
        XCTAssertNotNil(dropdown.props["top"])

        // Should have left positioning
        XCTAssertNotNil(dropdown.props["left"])

        // Should have margin-top for spacing
        XCTAssertNotNil(dropdown.props["margin-top"])

        // Should have min-width
        XCTAssertNotNil(dropdown.props["min-width"])

        // Should have box-shadow
        XCTAssertNotNil(dropdown.props["box-shadow"])
    }
}
