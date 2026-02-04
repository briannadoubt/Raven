import XCTest
@testable import Raven

/// Tests for Form and Section views to verify their VNode conversion
/// and proper semantic structure.
@MainActor
final class FormSectionTests: XCTestCase {

    // MARK: - Form Tests

    func testFormBasicStructure() async throws {
        // Create a simple form
        let form = Form {
            Text("Form content")
        }

        // Convert it to VNode
        let vnode = form.toVNode()

        // Verify it's a form element
        XCTAssertTrue(vnode.isElement(tag: "form"), "Should be a form element")
        XCTAssertEqual(vnode.elementTag, "form", "Tag should be 'form'")

        // Verify role attribute for accessibility
        if case .attribute(let name, let value) = vnode.props["role"] {
            XCTAssertEqual(name, "role", "Attribute name should be 'role'")
            XCTAssertEqual(value, "form", "Role value should be 'form'")
        } else {
            XCTFail("Form should have role attribute")
        }

        // Verify submit event handler is present
        XCTAssertNotNil(vnode.props["onSubmit"], "Form should have submit event handler")
        if case .eventHandler(let event, _) = vnode.props["onSubmit"] {
            XCTAssertEqual(event, "submit", "Event should be 'submit'")
        } else {
            XCTFail("onSubmit should be an event handler")
        }
    }

    func testFormStyling() async throws {
        let form = Form {
            Text("Styled form")
        }

        let vnode = form.toVNode()

        // Verify default styling
        if case .style(let name, let value) = vnode.props["display"] {
            XCTAssertEqual(name, "display")
            XCTAssertEqual(value, "flex")
        } else {
            XCTFail("Form should have display: flex")
        }

        if case .style(let name, let value) = vnode.props["flex-direction"] {
            XCTAssertEqual(name, "flex-direction")
            XCTAssertEqual(value, "column")
        } else {
            XCTFail("Form should have flex-direction: column")
        }

        if case .style(let name, let value) = vnode.props["gap"] {
            XCTAssertEqual(name, "gap")
            XCTAssertEqual(value, "16px")
        } else {
            XCTFail("Form should have gap: 16px")
        }

        if case .style(let name, let value) = vnode.props["width"] {
            XCTAssertEqual(name, "width")
            XCTAssertEqual(value, "100%")
        } else {
            XCTFail("Form should have width: 100%")
        }
    }

    // MARK: - Section Tests

    func testSectionBasicStructure() async throws {
        // Create a simple section
        let section = Section {
            Text("Section content")
        }

        // Convert it to VNode
        let vnode = section.toVNode()

        // Verify it's a fieldset element
        XCTAssertTrue(vnode.isElement(tag: "fieldset"), "Should be a fieldset element")
        XCTAssertEqual(vnode.elementTag, "fieldset", "Tag should be 'fieldset'")
    }

    func testSectionWithTextHeader() async throws {
        // Create a section with a text header
        let section = Section(header: "Settings") {
            Text("Section content")
        }

        let vnode = section.toVNode()

        // Verify structure
        XCTAssertTrue(vnode.isElement(tag: "fieldset"), "Should be a fieldset element")

        // The header should be accessible via the section's header property
        XCTAssertNotNil(section.header, "Section should have a header")
    }

    func testSectionWithCustomHeader() async throws {
        // Create a section with a custom header view
        let section = Section(header: { Text("Custom Header") }) {
            Text("Section content")
        }

        let vnode = section.toVNode()

        // Verify structure
        XCTAssertTrue(vnode.isElement(tag: "fieldset"), "Should be a fieldset element")
        XCTAssertNotNil(section.header, "Section should have a custom header")
    }

    func testSectionStyling() async throws {
        let section = Section {
            Text("Styled section")
        }

        let vnode = section.toVNode()

        // Verify default styling
        if case .style(let name, let value) = vnode.props["display"] {
            XCTAssertEqual(name, "display")
            XCTAssertEqual(value, "flex")
        } else {
            XCTFail("Section should have display: flex")
        }

        if case .style(let name, let value) = vnode.props["flex-direction"] {
            XCTAssertEqual(name, "flex-direction")
            XCTAssertEqual(value, "column")
        } else {
            XCTFail("Section should have flex-direction: column")
        }

        if case .style(let name, let value) = vnode.props["gap"] {
            XCTAssertEqual(name, "gap")
            XCTAssertEqual(value, "12px")
        } else {
            XCTFail("Section should have gap: 12px")
        }

        if case .style(let name, let value) = vnode.props["border"] {
            XCTAssertEqual(name, "border")
            XCTAssertEqual(value, "1px solid #e0e0e0")
        } else {
            XCTFail("Section should have border")
        }

        if case .style(let name, let value) = vnode.props["border-radius"] {
            XCTAssertEqual(name, "border-radius")
            XCTAssertEqual(value, "8px")
        } else {
            XCTFail("Section should have border-radius")
        }
    }

    // MARK: - Integration Tests

    func testFormWithSection() async throws {
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
        XCTAssertTrue(formVNode.isElement(tag: "form"), "Should be a form element")
        XCTAssertNotNil(formVNode.props["role"], "Form should have role attribute")
        XCTAssertNotNil(formVNode.props["onSubmit"], "Form should have submit handler")
    }

    func testSectionWithFooter() async throws {
        // Create a section with header and footer
        let section = Section(
            header: "Settings",
            footer: { Text("Footer info") }
        ) {
            Text("Content")
        }

        let vnode = section.toVNode()

        // Verify structure
        XCTAssertTrue(vnode.isElement(tag: "fieldset"), "Should be a fieldset element")
        XCTAssertNotNil(section.header, "Section should have a header")
        XCTAssertNotNil(section.footer, "Section should have a footer")
    }

    func testSectionOnlyFooter() async throws {
        // Create a section with only a footer
        let section = Section(footer: { Text("Footer only") }) {
            Text("Content")
        }

        let vnode = section.toVNode()

        // Verify structure
        XCTAssertTrue(vnode.isElement(tag: "fieldset"), "Should be a fieldset element")
        XCTAssertNil(section.header, "Section should not have a header")
        XCTAssertNotNil(section.footer, "Section should have a footer")
    }
}
