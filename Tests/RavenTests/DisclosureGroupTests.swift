import Testing
import Foundation
@testable import Raven

/// Tests for the DisclosureGroup primitive view
@Suite("DisclosureGroup Tests")
struct DisclosureGroupTests {

    // MARK: - Basic Initialization Tests

    @Test("DisclosureGroup with internal state initializes correctly")
    @MainActor func testBasicInitialization() {
        let group = DisclosureGroup {
            Text("Content")
        } label: {
            Text("Label")
        }

        let vnode = group.toVNode()

        // Verify outer container
        #expect(vnode.elementTag == "div")
        #expect(vnode.props["class"] != nil)
        if case .attribute(_, let value) = vnode.props["class"] {
            #expect(value.contains("raven-disclosure-group"))
        }
    }

    @Test("DisclosureGroup with binding initializes correctly")
    @MainActor func testBindingInitialization() {
        var isExpanded = true
        let binding = Binding(get: { isExpanded }, set: { isExpanded = $0 })

        let group = DisclosureGroup(isExpanded: binding) {
            Text("Content")
        } label: {
            Text("Label")
        }

        let vnode = group.toVNode()

        // Verify outer container exists
        #expect(vnode.elementTag == "div")
    }

    @Test("DisclosureGroup with string label initializes correctly")
    @MainActor func testStringLabelInitialization() {
        let group = DisclosureGroup("Settings") {
            Text("Content")
        }

        let vnode = group.toVNode()

        // Verify structure
        #expect(vnode.elementTag == "div")
        #expect(vnode.children.count >= 1)
    }

    // MARK: - VNode Structure Tests

    @Test("DisclosureGroup has correct VNode structure")
    @MainActor func testVNodeStructure() {
        let group = DisclosureGroup("Label") {
            Text("Content")
        }

        let vnode = group.toVNode()

        // Should have outer container
        #expect(vnode.elementTag == "div")

        // Should have at least header and content children
        #expect(vnode.children.count >= 2)

        // First child should be header
        let header = vnode.children[0]
        #expect(header.elementTag == "div")
        if case .attribute(_, let value) = header.props["class"] {
            #expect(value.contains("raven-disclosure-header"))
        }

        // Second child should be content
        let content = vnode.children[1]
        #expect(content.elementTag == "div")
        if case .attribute(_, let value) = content.props["class"] {
            #expect(value.contains("raven-disclosure-content"))
        }
    }

    @Test("DisclosureGroup header has chevron indicator")
    @MainActor func testChevronIndicator() {
        let group = DisclosureGroup("Label") {
            Text("Content")
        }

        let vnode = group.toVNode()
        let header = vnode.children[0]

        // Header should have chevron as first child
        #expect(header.children.count >= 1)

        let chevron = header.children[0]
        #expect(chevron.elementTag == "span")
        if case .attribute(_, let value) = chevron.props["class"] {
            #expect(value.contains("raven-disclosure-chevron"))
        }
    }

    @Test("DisclosureGroup header has label content")
    @MainActor func testHeaderLabel() {
        let group = DisclosureGroup("Test Label") {
            Text("Content")
        }

        let vnode = group.toVNode()
        let header = vnode.children[0]

        // Header should have label as second child
        #expect(header.children.count >= 2)

        let labelContainer = header.children[1]
        #expect(labelContainer.elementTag == "span")
        if case .attribute(_, let value) = labelContainer.props["class"] {
            #expect(value.contains("raven-disclosure-label"))
        }
    }

    // MARK: - Accessibility Tests

    @Test("DisclosureGroup header has correct ARIA attributes")
    @MainActor func testHeaderARIAAttributes() {
        let group = DisclosureGroup("Label") {
            Text("Content")
        }

        let vnode = group.toVNode()
        let header = vnode.children[0]

        // Verify role="button"
        if case .attribute(_, let value) = header.props["role"] {
            #expect(value == "button")
        } else {
            Issue.record("Header should have role='button'")
        }

        // Verify aria-expanded exists
        #expect(header.props["aria-expanded"] != nil)

        // Verify aria-controls exists
        #expect(header.props["aria-controls"] != nil)

        // Verify tabindex for keyboard accessibility
        if case .attribute(_, let value) = header.props["tabindex"] {
            #expect(value == "0")
        } else {
            Issue.record("Header should have tabindex='0'")
        }
    }

    @Test("DisclosureGroup content has aria-labelledby attribute")
    @MainActor func testContentARIAAttributes() {
        let group = DisclosureGroup("Label") {
            Text("Content")
        }

        let vnode = group.toVNode()
        let content = vnode.children[1]

        // Verify aria-labelledby exists
        #expect(content.props["aria-labelledby"] != nil)

        // Verify it references the header ID
        if case .attribute(_, let headerID) = vnode.children[0].props["id"],
           case .attribute(_, let labelledBy) = content.props["aria-labelledby"] {
            #expect(headerID == labelledBy)
        }
    }

    @Test("Chevron has aria-hidden attribute")
    @MainActor func testChevronARIAHidden() {
        let group = DisclosureGroup("Label") {
            Text("Content")
        }

        let vnode = group.toVNode()
        let header = vnode.children[0]
        let chevron = header.children[0]

        // Verify aria-hidden="true" on chevron
        if case .attribute(_, let value) = chevron.props["aria-hidden"] {
            #expect(value == "true")
        } else {
            Issue.record("Chevron should have aria-hidden='true'")
        }
    }

    // MARK: - State Management Tests

    @Test("Collapsed state renders correctly")
    @MainActor func testCollapsedState() {
        let group = DisclosureGroup("Label") {
            Text("Content")
        }

        let vnode = group.toVNode()
        let header = vnode.children[0]
        let content = vnode.children[1]

        // Verify aria-expanded="false"
        if case .attribute(_, let value) = header.props["aria-expanded"] {
            #expect(value == "false")
        }

        // Verify collapsed class
        if case .attribute(_, let value) = vnode.props["class"] {
            #expect(value.contains("raven-disclosure-collapsed"))
        }

        // Verify content is hidden
        if case .style(_, let value) = content.props["display"] {
            #expect(value == "none")
        }
    }

    @Test("Expanded state renders correctly with binding")
    @MainActor func testExpandedState() {
        var isExpanded = true
        let binding = Binding(get: { isExpanded }, set: { isExpanded = $0 })

        let group = DisclosureGroup(isExpanded: binding) {
            Text("Content")
        } label: {
            Text("Label")
        }

        let vnode = group.toVNode()
        let header = vnode.children[0]
        let content = vnode.children[1]

        // Verify aria-expanded="true"
        if case .attribute(_, let value) = header.props["aria-expanded"] {
            #expect(value == "true")
        }

        // Verify expanded class
        if case .attribute(_, let value) = vnode.props["class"] {
            #expect(value.contains("raven-disclosure-expanded"))
        }

        // Verify content is visible (no display:none)
        #expect(content.props["display"] == nil)
    }

    @Test("Chevron class changes with expanded state")
    @MainActor func testChevronStateClasses() {
        // Test collapsed
        let collapsedGroup = DisclosureGroup("Label") {
            Text("Content")
        }

        let collapsedVNode = collapsedGroup.toVNode()
        let collapsedChevron = collapsedVNode.children[0].children[0]

        if case .attribute(_, let value) = collapsedChevron.props["class"] {
            #expect(value.contains("raven-disclosure-chevron-collapsed"))
        }

        // Test expanded
        var isExpanded = true
        let binding = Binding(get: { isExpanded }, set: { isExpanded = $0 })

        let expandedGroup = DisclosureGroup(isExpanded: binding) {
            Text("Content")
        } label: {
            Text("Label")
        }

        let expandedVNode = expandedGroup.toVNode()
        let expandedChevron = expandedVNode.children[0].children[0]

        if case .attribute(_, let value) = expandedChevron.props["class"] {
            #expect(value.contains("raven-disclosure-chevron-expanded"))
        }
    }

    // MARK: - Event Handler Tests

    @Test("DisclosureGroup header has click event handler")
    @MainActor func testClickEventHandler() {
        let group = DisclosureGroup("Label") {
            Text("Content")
        }

        let vnode = group.toVNode()
        let header = vnode.children[0]

        // Verify onClick event handler exists
        if case .eventHandler(let event, _) = header.props["onClick"] {
            #expect(event == "click")
        } else {
            Issue.record("Header should have onClick event handler")
        }
    }

    @Test("Click handler is accessible via public API")
    @MainActor func testClickHandlerAPI() {
        var isExpanded = false
        let binding = Binding(get: { isExpanded }, set: { isExpanded = $0 })

        let group = DisclosureGroup(isExpanded: binding) {
            Text("Content")
        } label: {
            Text("Label")
        }

        // Verify clickHandler exists and is callable
        let handler = group.clickHandler
        #expect(isExpanded == false)

        handler()
        #expect(isExpanded == true)

        handler()
        #expect(isExpanded == false)
    }

    // MARK: - CSS Classes Tests

    @Test("DisclosureGroup has correct CSS classes")
    @MainActor func testCSSClasses() {
        let group = DisclosureGroup("Label") {
            Text("Content")
        }

        let vnode = group.toVNode()

        // Verify outer container class
        if case .attribute(_, let value) = vnode.props["class"] {
            #expect(value.contains("raven-disclosure-group"))
        }

        // Verify header class
        let header = vnode.children[0]
        if case .attribute(_, let value) = header.props["class"] {
            #expect(value.contains("raven-disclosure-header"))
        }

        // Verify content class
        let content = vnode.children[1]
        if case .attribute(_, let value) = content.props["class"] {
            #expect(value.contains("raven-disclosure-content"))
        }
    }

    // MARK: - Convenience Initializer Tests

    @Test("String title initializer with binding works")
    @MainActor func testStringTitleWithBinding() {
        var isExpanded = false
        let binding = Binding(get: { isExpanded }, set: { isExpanded = $0 })

        let group = DisclosureGroup("Settings", isExpanded: binding) {
            Text("Content")
        }

        let vnode = group.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("LocalizedStringKey initializer with binding works")
    @MainActor func testLocalizedStringKeyWithBinding() {
        var isExpanded = true
        let binding = Binding(get: { isExpanded }, set: { isExpanded = $0 })

        let titleKey: LocalizedStringKey = "settings"
        let group = DisclosureGroup(titleKey, isExpanded: binding) {
            Text("Content")
        }

        let vnode = group.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("String title initializer without binding works")
    @MainActor func testStringTitleWithoutBinding() {
        let group = DisclosureGroup("Options") {
            Text("Content")
        }

        let vnode = group.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("LocalizedStringKey initializer without binding works")
    @MainActor func testLocalizedStringKeyWithoutBinding() {
        let titleKey: LocalizedStringKey = "options"
        let group = DisclosureGroup(titleKey) {
            Text("Content")
        }

        let vnode = group.toVNode()
        #expect(vnode.elementTag == "div")
    }

    // MARK: - Unique ID Tests

    @Test("Multiple disclosure groups have unique IDs")
    @MainActor func testUniqueIDs() {
        let group1 = DisclosureGroup("Group 1") {
            Text("Content 1")
        }

        let group2 = DisclosureGroup("Group 2") {
            Text("Content 2")
        }

        let vnode1 = group1.toVNode()
        let vnode2 = group2.toVNode()

        // Get header IDs
        if case .attribute(_, let id1) = vnode1.children[0].props["id"],
           case .attribute(_, let id2) = vnode2.children[0].props["id"] {
            #expect(id1 != id2)
        } else {
            Issue.record("Headers should have unique IDs")
        }

        // Get content IDs
        if case .attribute(_, let id1) = vnode1.children[1].props["id"],
           case .attribute(_, let id2) = vnode2.children[1].props["id"] {
            #expect(id1 != id2)
        } else {
            Issue.record("Content sections should have unique IDs")
        }
    }

    // MARK: - Integration Tests

    @Test("Nested disclosure groups are supported")
    @MainActor func testNestedDisclosureGroups() {
        let outerGroup = DisclosureGroup("Outer") {
            DisclosureGroup("Inner") {
                Text("Nested Content")
            }
        }

        let vnode = outerGroup.toVNode()

        // Verify outer structure exists
        #expect(vnode.elementTag == "div")
        #expect(vnode.children.count >= 2)
    }

    @Test("DisclosureGroup with complex label")
    @MainActor func testComplexLabel() {
        let group = DisclosureGroup {
            Text("Content")
        } label: {
            HStack {
                Text("Icon")
                Text("Label")
            }
        }

        let vnode = group.toVNode()

        // Verify structure is valid
        #expect(vnode.elementTag == "div")
        #expect(vnode.children.count >= 2)
    }

    @Test("DisclosureGroup with multiple content views")
    @MainActor func testMultipleContentViews() {
        let group = DisclosureGroup("Settings") {
            Text("Setting 1")
            Text("Setting 2")
            Text("Setting 3")
        }

        let vnode = group.toVNode()

        // Verify structure
        #expect(vnode.elementTag == "div")
        #expect(vnode.children.count >= 2)
    }

    // MARK: - Binding Tests

    @Test("External binding updates correctly")
    @MainActor func testExternalBindingUpdates() {
        var isExpanded = false
        let binding = Binding(get: { isExpanded }, set: { isExpanded = $0 })

        let group = DisclosureGroup("Label", isExpanded: binding) {
            Text("Content")
        }

        // Initial state
        var vnode = group.toVNode()
        var header = vnode.children[0]

        if case .attribute(_, let value) = header.props["aria-expanded"] {
            #expect(value == "false")
        }

        // Toggle via binding
        isExpanded = true

        vnode = group.toVNode()
        header = vnode.children[0]

        if case .attribute(_, let value) = header.props["aria-expanded"] {
            #expect(value == "true")
        }
    }
}
