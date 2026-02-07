import Testing
@testable import Raven

/// Tests for Form and Section views to verify their VNode conversion
/// and proper semantic structure.
@MainActor
@Suite struct FormSectionTests {

    // MARK: - Form Tests

    @Test func formBasicStructure() async throws {
        // Create a simple form
        let form = Form {
            Text("Form content")
        }

        // Convert it to VNode
        let vnode = form.toVNode()

        // Verify it's a form element
        #expect(vnode.isElement(tag: "form"))
        #expect(vnode.elementTag == "form")

        // Verify role attribute for accessibility
        if case .attribute(let name, let value) = vnode.props["role"] {
            #expect(name == "role")
            #expect(value == "form")
        } else {
            Issue.record("Form should have role attribute")
        }

        // Verify submit event handler is present
        #expect(vnode.props["onSubmit"] != nil)
        if case .eventHandler(let event, _) = vnode.props["onSubmit"] {
            #expect(event == "submit")
        } else {
            Issue.record("onSubmit should be an event handler")
        }
    }

    @Test func formStyling() async throws {
        let form = Form {
            Text("Styled form")
        }

        let vnode = form.toVNode()

        // Verify default styling
        if case .style(let name, let value) = vnode.props["display"] {
            #expect(name == "display")
            #expect(value == "flex")
        } else {
            Issue.record("Form should have display: flex")
        }

        if case .style(let name, let value) = vnode.props["flex-direction"] {
            #expect(name == "flex-direction")
            #expect(value == "column")
        } else {
            Issue.record("Form should have flex-direction: column")
        }

        if case .style(let name, let value) = vnode.props["gap"] {
            #expect(name == "gap")
            #expect(value == "16px")
        } else {
            Issue.record("Form should have gap: 16px")
        }

        if case .style(let name, let value) = vnode.props["width"] {
            #expect(name == "width")
            #expect(value == "100%")
        } else {
            Issue.record("Form should have width: 100%")
        }
    }

    // MARK: - Section Tests

    @Test func sectionBasicStructure() async throws {
        // Create a simple section
        let section = Section {
            Text("Section content")
        }

        // Convert it to VNode
        let vnode = section.toVNode()

        // Verify it's a fieldset element
        #expect(vnode.isElement(tag: "fieldset"))
        #expect(vnode.elementTag == "fieldset")
    }

    @Test func sectionWithTextHeader() async throws {
        // Create a section with a text header
        let section = Section(header: "Settings") {
            Text("Section content")
        }

        let vnode = section.toVNode()

        // Verify structure
        #expect(vnode.isElement(tag: "fieldset"))

        // The header should be accessible via the section's header property
        #expect(section.header != nil)
    }

    @Test func sectionWithCustomHeader() async throws {
        // Create a section with a custom header view
        let section = Section(header: { Text("Custom Header") }) {
            Text("Section content")
        }

        let vnode = section.toVNode()

        // Verify structure
        #expect(vnode.isElement(tag: "fieldset"))
        #expect(section.header != nil)
    }

    @Test func sectionStyling() async throws {
        let section = Section {
            Text("Styled section")
        }

        let vnode = section.toVNode()

        // Verify default styling
        if case .style(let name, let value) = vnode.props["display"] {
            #expect(name == "display")
            #expect(value == "flex")
        } else {
            Issue.record("Section should have display: flex")
        }

        if case .style(let name, let value) = vnode.props["flex-direction"] {
            #expect(name == "flex-direction")
            #expect(value == "column")
        } else {
            Issue.record("Section should have flex-direction: column")
        }

        if case .style(let name, let value) = vnode.props["gap"] {
            #expect(name == "gap")
            #expect(value == "12px")
        } else {
            Issue.record("Section should have gap: 12px")
        }

        if case .style(let name, let value) = vnode.props["border"] {
            #expect(name == "border")
            #expect(value == "1px solid #e0e0e0")
        } else {
            Issue.record("Section should have border")
        }

        if case .style(let name, let value) = vnode.props["border-radius"] {
            #expect(name == "border-radius")
            #expect(value == "8px")
        } else {
            Issue.record("Section should have border-radius")
        }
    }

    // MARK: - Integration Tests

    @Test func formWithSection() async throws {
        // Create a form with sections
        let form = Form {
            Section(header: "Personal Info") {
                Text("Name field")
            }
            Section(header: "Settings") {
                Text("Toggle")
            }
        }

        let formVNode = form.toVNode()

        // Verify form structure
        #expect(formVNode.isElement(tag: "form"))
        #expect(formVNode.props["role"] != nil)
        #expect(formVNode.props["onSubmit"] != nil)
    }

    @Test func sectionWithFooter() async throws {
        // Create a section with header and footer
        let section = Section(
            header: "Settings",
            footer: { Text("Footer info") }
        ) {
            Text("Content")
        }

        let vnode = section.toVNode()

        // Verify structure
        #expect(vnode.isElement(tag: "fieldset"))
        #expect(section.header != nil)
        #expect(section.footer != nil)
    }

    @Test func sectionOnlyFooter() async throws {
        // Create a section with only a footer
        let section = Section(footer: { Text("Footer only") }) {
            Text("Content")
        }

        let vnode = section.toVNode()

        // Verify structure
        #expect(vnode.isElement(tag: "fieldset"))
        #expect(section.header == nil)
        #expect(section.footer != nil)
    }
}
