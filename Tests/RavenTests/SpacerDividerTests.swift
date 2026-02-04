import XCTest
@testable import Raven

/// Tests for Spacer and Divider layout views
@MainActor
final class SpacerDividerTests: XCTestCase {

    // MARK: - Spacer Tests

    func testBasicSpacerRendering() async throws {
        // Create a basic spacer
        let spacer = Spacer()

        // Convert to VNode
        let vnode = spacer.toVNode()

        // Verify it creates a div element
        XCTAssertTrue(vnode.isElement(tag: "div"), "Spacer should create a div element")
        XCTAssertEqual(vnode.elementTag, "div")

        // Verify flexbox properties
        XCTAssertNotNil(vnode.props["flex-grow"], "Spacer should have flex-grow property")
        XCTAssertNotNil(vnode.props["flex-shrink"], "Spacer should have flex-shrink property")
        XCTAssertNotNil(vnode.props["flex-basis"], "Spacer should have flex-basis property")

        // Verify correct flex values
        if case .style(name: "flex-grow", value: let value) = vnode.props["flex-grow"] {
            XCTAssertEqual(value, "1", "flex-grow should be 1")
        } else {
            XCTFail("flex-grow should be a style property with value '1'")
        }

        if case .style(name: "flex-shrink", value: let value) = vnode.props["flex-shrink"] {
            XCTAssertEqual(value, "1", "flex-shrink should be 1")
        } else {
            XCTFail("flex-shrink should be a style property with value '1'")
        }

        if case .style(name: "flex-basis", value: let value) = vnode.props["flex-basis"] {
            XCTAssertEqual(value, "0", "flex-basis should be 0")
        } else {
            XCTFail("flex-basis should be a style property with value '0'")
        }

        // Verify no children
        XCTAssertTrue(vnode.children.isEmpty, "Spacer should have no children")
    }

    func testSpacerWithMinLength() async throws {
        // Create a spacer with minimum length
        let spacer = Spacer(minLength: 20)

        // Convert to VNode
        let vnode = spacer.toVNode()

        // Verify min-width and min-height are set
        XCTAssertNotNil(vnode.props["min-width"], "Spacer with minLength should have min-width")
        XCTAssertNotNil(vnode.props["min-height"], "Spacer with minLength should have min-height")

        // Verify correct min-length values
        if case .style(name: "min-width", value: let value) = vnode.props["min-width"] {
            XCTAssertEqual(value, "20.0px", "min-width should be 20.0px")
        } else {
            XCTFail("min-width should be a style property with value '20.0px'")
        }

        if case .style(name: "min-height", value: let value) = vnode.props["min-height"] {
            XCTAssertEqual(value, "20.0px", "min-height should be 20.0px")
        } else {
            XCTFail("min-height should be a style property with value '20.0px'")
        }
    }

    func testSpacerWithoutMinLength() async throws {
        // Create a spacer without minimum length
        let spacer = Spacer()

        // Convert to VNode
        let vnode = spacer.toVNode()

        // Verify min-width and min-height are not set
        XCTAssertNil(vnode.props["min-width"], "Spacer without minLength should not have min-width")
        XCTAssertNil(vnode.props["min-height"], "Spacer without minLength should not have min-height")
    }

    func testSpacerWithCustomMinLength() async throws {
        // Create spacers with different min lengths
        let spacer1 = Spacer(minLength: 10)
        let spacer2 = Spacer(minLength: 50.5)

        let vnode1 = spacer1.toVNode()
        let vnode2 = spacer2.toVNode()

        // Verify spacer1
        if case .style(name: "min-width", value: let value) = vnode1.props["min-width"] {
            XCTAssertEqual(value, "10.0px")
        }

        // Verify spacer2
        if case .style(name: "min-width", value: let value) = vnode2.props["min-width"] {
            XCTAssertEqual(value, "50.5px")
        }
    }

    // MARK: - Divider Tests

    func testBasicDividerRendering() async throws {
        // Create a basic divider
        let divider = Divider()

        // Convert to VNode
        let vnode = divider.toVNode()

        // Verify it creates a div element
        XCTAssertTrue(vnode.isElement(tag: "div"), "Divider should create a div element")
        XCTAssertEqual(vnode.elementTag, "div")

        // Verify border styling
        XCTAssertNotNil(vnode.props["border-top"], "Divider should have border-top property")

        if case .style(name: "border-top", value: let value) = vnode.props["border-top"] {
            XCTAssertEqual(value, "1px solid #d1d5db", "border-top should be 1px solid with gray color")
        } else {
            XCTFail("border-top should be a style property")
        }

        // Verify dimensions
        XCTAssertNotNil(vnode.props["height"], "Divider should have height property")
        XCTAssertNotNil(vnode.props["width"], "Divider should have width property")

        if case .style(name: "height", value: let value) = vnode.props["height"] {
            XCTAssertEqual(value, "0", "height should be 0")
        } else {
            XCTFail("height should be a style property")
        }

        if case .style(name: "width", value: let value) = vnode.props["width"] {
            XCTAssertEqual(value, "100%", "width should be 100%")
        } else {
            XCTFail("width should be a style property")
        }

        // Verify no children
        XCTAssertTrue(vnode.children.isEmpty, "Divider should have no children")
    }

    func testDividerFlexShrink() async throws {
        // Create a divider
        let divider = Divider()

        // Convert to VNode
        let vnode = divider.toVNode()

        // Verify flex-shrink is set to prevent growing in flex layouts
        XCTAssertNotNil(vnode.props["flex-shrink"], "Divider should have flex-shrink property")

        if case .style(name: "flex-shrink", value: let value) = vnode.props["flex-shrink"] {
            XCTAssertEqual(value, "0", "flex-shrink should be 0 to prevent shrinking")
        } else {
            XCTFail("flex-shrink should be a style property with value '0'")
        }
    }

    func testDividerMargins() async throws {
        // Create a divider
        let divider = Divider()

        // Convert to VNode
        let vnode = divider.toVNode()

        // Verify margins are set
        XCTAssertNotNil(vnode.props["margin-top"], "Divider should have margin-top property")
        XCTAssertNotNil(vnode.props["margin-bottom"], "Divider should have margin-bottom property")

        if case .style(name: "margin-top", value: let value) = vnode.props["margin-top"] {
            XCTAssertEqual(value, "0", "margin-top should be 0")
        }

        if case .style(name: "margin-bottom", value: let value) = vnode.props["margin-bottom"] {
            XCTAssertEqual(value, "0", "margin-bottom should be 0")
        }
    }

    // MARK: - Integration Tests

    func testMultipleSpacersHaveUniqueIDs() async throws {
        // Create multiple spacers
        let spacer1 = Spacer()
        let spacer2 = Spacer()
        let spacer3 = Spacer(minLength: 10)

        // Convert to VNodes
        let vnode1 = spacer1.toVNode()
        let vnode2 = spacer2.toVNode()
        let vnode3 = spacer3.toVNode()

        // Verify unique IDs
        XCTAssertNotEqual(vnode1.id, vnode2.id, "Different spacers should have unique IDs")
        XCTAssertNotEqual(vnode1.id, vnode3.id, "Different spacers should have unique IDs")
        XCTAssertNotEqual(vnode2.id, vnode3.id, "Different spacers should have unique IDs")
    }

    func testMultipleDividersHaveUniqueIDs() async throws {
        // Create multiple dividers
        let divider1 = Divider()
        let divider2 = Divider()

        // Convert to VNodes
        let vnode1 = divider1.toVNode()
        let vnode2 = divider2.toVNode()

        // Verify unique IDs
        XCTAssertNotEqual(vnode1.id, vnode2.id, "Different dividers should have unique IDs")
    }

    func testSpacerAndDividerAreViews() async throws {
        // Verify that Spacer and Divider conform to View protocol
        func acceptsView<V: View>(_ view: V) -> Bool {
            return true
        }

        XCTAssertTrue(acceptsView(Spacer()), "Spacer should conform to View")
        XCTAssertTrue(acceptsView(Divider()), "Divider should conform to View")
    }

    func testSpacerAndDividerAreSendable() async throws {
        // Verify that Spacer and Divider conform to Sendable
        func acceptsSendable<S: Sendable>(_ value: S) -> Bool {
            return true
        }

        XCTAssertTrue(acceptsSendable(Spacer()), "Spacer should conform to Sendable")
        XCTAssertTrue(acceptsSendable(Divider()), "Divider should conform to Sendable")
    }
}
