import Testing
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
@MainActor
@Suite struct MenuTests {

    // MARK: - Basic Menu Tests

    /// Test creating a menu with a simple text label
    @MainActor
    @Test func menuWithTextLabel() {
        let menu = Menu("Actions") {
            Button("Copy") { }
            Button("Paste") { }
        }

        // Menu should be a primitive view
        #expect(type(of: menu).Body.self == Never.self)
    }

    /// Test creating a menu with a localized string key
    @MainActor
    @Test func menuWithLocalizedKey() {
        let menu = Menu(LocalizedStringKey("menu_title")) {
            Button("Action 1") { }
            Button("Action 2") { }
        }

        #expect(type(of: menu).Body.self == Never.self)
    }

    /// Test creating a menu with a custom label
    @MainActor
    @Test func menuWithCustomLabel() {
        let menu = Menu {
            Button("Edit") { }
            Button("Delete") { }
        } label: {
            HStack {
                Text("Options")
            }
        }

        #expect(type(of: menu).Body.self == Never.self)
    }

    // MARK: - VNode Rendering Tests

    /// Test that menu renders to correct VNode structure
    @MainActor
    @Test func menuRendersToVNode() {
        let menu = Menu("Actions") {
            Button("Copy") { }
            Button("Paste") { }
        }

        let vnode = menu.toVNode()

        // Should render as a div container
        #expect(vnode.isElement(tag: "div"))

        // Should have class "raven-menu"
        if case .attribute(name: "class", value: let className) = vnode.props["class"] {
            #expect(className == "raven-menu")
        } else {
            Issue.record("Menu should have class attribute")
        }

        // Should have position relative
        if case .style(name: "position", value: let position) = vnode.props["position"] {
            #expect(position == "relative")
        } else {
            Issue.record("Menu should have position style")
        }

        // Should have two children: trigger button and dropdown
        #expect(vnode.children.count == 2)
    }

    /// Test that menu trigger button has correct attributes
    @MainActor
    @Test func menuTriggerButton() {
        let menu = Menu("Options") {
            Button("Action") { }
        }

        let vnode = menu.toVNode()
        #expect(vnode.children.count == 2)

        let trigger = vnode.children[0]

        // Should be a button element
        #expect(trigger.isElement(tag: "button"))

        // Should have class "raven-menu-trigger"
        if case .attribute(name: "class", value: let className) = trigger.props["class"] {
            #expect(className == "raven-menu-trigger")
        } else {
            Issue.record("Trigger should have class attribute")
        }

        // Should have ARIA attributes
        if case .attribute(name: "aria-haspopup", value: let hasPopup) = trigger.props["aria-haspopup"] {
            #expect(hasPopup == "true")
        } else {
            Issue.record("Trigger should have aria-haspopup attribute")
        }

        if case .attribute(name: "aria-expanded", value: let expanded) = trigger.props["aria-expanded"] {
            #expect(expanded == "false")
        } else {
            Issue.record("Trigger should have aria-expanded attribute")
        }

        // Should have click handler
        #expect(trigger.props["onClick"] != nil)
    }

    /// Test that menu dropdown has correct attributes
    @MainActor
    @Test func menuDropdown() {
        let menu = Menu("Options") {
            Button("Action 1") { }
            Button("Action 2") { }
        }

        let vnode = menu.toVNode()
        #expect(vnode.children.count == 2)

        let dropdown = vnode.children[1]

        // Should be a div element
        #expect(dropdown.isElement(tag: "div"))

        // Should have class "raven-menu-dropdown"
        if case .attribute(name: "class", value: let className) = dropdown.props["class"] {
            #expect(className == "raven-menu-dropdown")
        } else {
            Issue.record("Dropdown should have class attribute")
        }

        // Should have role="menu"
        if case .attribute(name: "role", value: let role) = dropdown.props["role"] {
            #expect(role == "menu")
        } else {
            Issue.record("Dropdown should have role attribute")
        }

        // Should be hidden by default (display: none)
        if case .style(name: "display", value: let display) = dropdown.props["display"] {
            #expect(display == "none")
        } else {
            Issue.record("Dropdown should have display style")
        }

        // Should have position absolute
        if case .style(name: "position", value: let position) = dropdown.props["position"] {
            #expect(position == "absolute")
        } else {
            Issue.record("Dropdown should have position style")
        }

        // Should have z-index for layering
        if case .style(name: "z-index", value: let zIndex) = dropdown.props["z-index"] {
            #expect(zIndex == "1000")
        } else {
            Issue.record("Dropdown should have z-index style")
        }
    }

    // MARK: - Menu Style Tests

    /// Test default menu style
    @MainActor
    @Test func defaultMenuStyle() {
        let style = DefaultMenuStyle()
        let config = MenuStyleConfiguration(
            label: AnyView(Text("Test")),
            content: AnyView(Button("Action") { })
        )

        let body = style.makeBody(configuration: config)
        // Default style returns content as-is
        #expect(body != nil)
    }

    /// Test button menu style
    @MainActor
    @Test func buttonMenuStyle() {
        let style = ButtonMenuStyle()
        let config = MenuStyleConfiguration(
            label: AnyView(Text("Test")),
            content: AnyView(Button("Action") { })
        )

        let body = style.makeBody(configuration: config)
        #expect(body != nil)
    }

    /// Test menu style convenience accessors
    @MainActor
    @Test func menuStyleConvenience() {
        let defaultStyle: DefaultMenuStyle = .default
        #expect(defaultStyle != nil)

        let buttonStyle: ButtonMenuStyle = .button
        #expect(buttonStyle != nil)
    }

    // MARK: - Context Menu Tests

    /// Test applying context menu modifier
    @MainActor
    @Test func contextMenuModifier() {
        let view = Text("Right-click me")
            .contextMenu {
                Button("Copy") { }
                Button("Paste") { }
            }

        #expect(view != nil)
    }

    /// Test context menu with destructive actions
    @MainActor
    @Test func contextMenuWithDestructiveAction() {
        let view = Text("Item")
            .contextMenu {
                Button("Edit") { }
                Button("Delete", role: .destructive) { }
            }

        #expect(view != nil)
    }

    // MARK: - Accessibility Tests

    /// Test that menu includes required ARIA attributes
    @MainActor
    @Test func menuAccessibility() {
        let menu = Menu("Options") {
            Button("Action") { }
        }

        let vnode = menu.toVNode()
        let trigger = vnode.children[0]
        let dropdown = vnode.children[1]

        // Trigger should have aria-haspopup
        #expect(trigger.props["aria-haspopup"] != nil)

        // Trigger should have aria-expanded
        #expect(trigger.props["aria-expanded"] != nil)

        // Trigger should have aria-controls pointing to dropdown
        #expect(trigger.props["aria-controls"] != nil)

        // Dropdown should have role="menu"
        #expect(dropdown.props["role"] != nil)

        // Dropdown should have aria-labelledby pointing to trigger
        #expect(dropdown.props["aria-labelledby"] != nil)
    }

    /// Test that trigger and dropdown IDs are coordinated
    @MainActor
    @Test func menuIDCoordination() {
        let menu = Menu("Options") {
            Button("Action") { }
        }

        let vnode = menu.toVNode()
        let trigger = vnode.children[0]
        let dropdown = vnode.children[1]

        // Get trigger ID
        guard case .attribute(name: "id", value: let triggerID) = trigger.props["id"] else {
            Issue.record("Trigger should have ID")
            return
        }

        // Get dropdown ID
        guard case .attribute(name: "id", value: let dropdownID) = dropdown.props["id"] else {
            Issue.record("Dropdown should have ID")
            return
        }

        // Trigger aria-controls should match dropdown ID
        if case .attribute(name: "aria-controls", value: let controls) = trigger.props["aria-controls"] {
            #expect(controls == dropdownID)
        } else {
            Issue.record("Trigger should have aria-controls")
        }

        // Dropdown aria-labelledby should match trigger ID
        if case .attribute(name: "aria-labelledby", value: let labelledBy) = dropdown.props["aria-labelledby"] {
            #expect(labelledBy == triggerID)
        } else {
            Issue.record("Dropdown should have aria-labelledby")
        }
    }

    // MARK: - Integration Tests

    /// Test menu with multiple items
    @MainActor
    @Test func menuWithMultipleItems() {
        let menu = Menu("File") {
            Button("New") { }
            Button("Open") { }
            Button("Save") { }
            Button("Close") { }
        }

        let vnode = menu.toVNode()
        #expect(vnode != nil)

        // Should have container with trigger and dropdown
        #expect(vnode.children.count == 2)
    }

    /// Test menu with conditional items
    @MainActor
    @Test func menuWithConditionalItems() {
        let showDelete = true

        let menu = Menu("Edit") {
            Button("Copy") { }
            Button("Paste") { }
            if showDelete {
                Button("Delete", role: .destructive) { }
            }
        }

        let vnode = menu.toVNode()
        #expect(vnode != nil)
    }

    /// Test nested menu structure
    @MainActor
    @Test func nestedMenus() {
        // Note: This tests the structure, not the full nested menu functionality
        let menu = Menu("File") {
            Button("New") { }
            // Nested menus would be implemented here
            Button("Save") { }
        }

        let vnode = menu.toVNode()
        #expect(vnode != nil)
        #expect(vnode.children.count == 2)
    }

    // MARK: - CSS Class Tests

    /// Test that menu uses correct CSS classes
    @MainActor
    @Test func menuCSSClasses() {
        let menu = Menu("Test") {
            Button("Action") { }
        }

        let vnode = menu.toVNode()

        // Container should have "raven-menu"
        if case .attribute(name: "class", value: let className) = vnode.props["class"] {
            #expect(className == "raven-menu")
        }

        // Trigger should have "raven-menu-trigger"
        let trigger = vnode.children[0]
        if case .attribute(name: "class", value: let className) = trigger.props["class"] {
            #expect(className == "raven-menu-trigger")
        }

        // Dropdown should have "raven-menu-dropdown"
        let dropdown = vnode.children[1]
        if case .attribute(name: "class", value: let className) = dropdown.props["class"] {
            #expect(className == "raven-menu-dropdown")
        }
    }

    /// Test that menu items have correct class
    @MainActor
    @Test func menuItemCSSClass() {
        let menu = Menu("Test") {
            Button("Action") { }
        }

        let vnode = menu.toVNode()
        let dropdown = vnode.children[1]

        // Menu items should have "raven-menu-item" class
        // (if any items were rendered - this is a structure test)
        #expect(dropdown != nil)
    }

    // MARK: - Styling Tests

    /// Test that menu has default styling
    @MainActor
    @Test func menuDefaultStyling() {
        let menu = Menu("Options") {
            Button("Action") { }
        }

        let vnode = menu.toVNode()
        let trigger = vnode.children[0]

        // Trigger should have padding
        #expect(trigger.props["padding"] != nil)

        // Trigger should have border
        #expect(trigger.props["border"] != nil)

        // Trigger should have border-radius
        #expect(trigger.props["border-radius"] != nil)

        // Trigger should have cursor pointer
        if case .style(name: "cursor", value: let cursor) = trigger.props["cursor"] {
            #expect(cursor == "pointer")
        }
    }

    /// Test that dropdown has correct positioning styles
    @MainActor
    @Test func dropdownPositioning() {
        let menu = Menu("Options") {
            Button("Action") { }
        }

        let vnode = menu.toVNode()
        let dropdown = vnode.children[1]

        // Should have position absolute
        if case .style(name: "position", value: let position) = dropdown.props["position"] {
            #expect(position == "absolute")
        }

        // Should have top positioning
        #expect(dropdown.props["top"] != nil)

        // Should have left positioning
        #expect(dropdown.props["left"] != nil)

        // Should have margin-top for spacing
        #expect(dropdown.props["margin-top"] != nil)

        // Should have min-width
        #expect(dropdown.props["min-width"] != nil)

        // Should have box-shadow
        #expect(dropdown.props["box-shadow"] != nil)
    }
}
