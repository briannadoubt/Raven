import Testing
@testable import Raven

/// Tests for Spacer and Divider layout views
@MainActor
@Suite struct SpacerDividerTests {

    // MARK: - Spacer Tests

    @Test func basicSpacerRendering() async throws {
        // Create a basic spacer
        let spacer = Spacer()

        // Convert to VNode
        let vnode = spacer.toVNode()

        // Verify it creates a div element
        #expect(vnode.isElement(tag: "div"))
        #expect(vnode.elementTag == "div")

        // Verify flexbox properties
        #expect(vnode.props["flex-grow"] != nil)
        #expect(vnode.props["flex-shrink"] != nil)
        #expect(vnode.props["flex-basis"] != nil)

        // Verify correct flex values
        if case .style(name: "flex-grow", value: let value) = vnode.props["flex-grow"] {
            #expect(value == "1")
        } else {
            Issue.record("flex-grow should be a style property with value '1'")
        }

        if case .style(name: "flex-shrink", value: let value) = vnode.props["flex-shrink"] {
            #expect(value == "1")
        } else {
            Issue.record("flex-shrink should be a style property with value '1'")
        }

        if case .style(name: "flex-basis", value: let value) = vnode.props["flex-basis"] {
            #expect(value == "0")
        } else {
            Issue.record("flex-basis should be a style property with value '0'")
        }

        // Verify no children
        #expect(vnode.children.isEmpty)
    }

    @Test func spacerWithMinLength() async throws {
        // Create a spacer with minimum length
        let spacer = Spacer(minLength: 20)

        // Convert to VNode
        let vnode = spacer.toVNode()

        // Verify min-width and min-height are set
        #expect(vnode.props["min-width"] != nil)
        #expect(vnode.props["min-height"] != nil)

        // Verify correct min-length values
        if case .style(name: "min-width", value: let value) = vnode.props["min-width"] {
            #expect(value == "20.0px")
        } else {
            Issue.record("min-width should be a style property with value '20.0px'")
        }

        if case .style(name: "min-height", value: let value) = vnode.props["min-height"] {
            #expect(value == "20.0px")
        } else {
            Issue.record("min-height should be a style property with value '20.0px'")
        }
    }

    @Test func spacerWithoutMinLength() async throws {
        // Create a spacer without minimum length
        let spacer = Spacer()

        // Convert to VNode
        let vnode = spacer.toVNode()

        // Verify min-width and min-height are not set
        #expect(vnode.props["min-width"] == nil)
        #expect(vnode.props["min-height"] == nil)
    }

    @Test func spacerWithCustomMinLength() async throws {
        // Create spacers with different min lengths
        let spacer1 = Spacer(minLength: 10)
        let spacer2 = Spacer(minLength: 50.5)

        let vnode1 = spacer1.toVNode()
        let vnode2 = spacer2.toVNode()

        // Verify spacer1
        if case .style(name: "min-width", value: let value) = vnode1.props["min-width"] {
            #expect(value == "10.0px")
        }

        // Verify spacer2
        if case .style(name: "min-width", value: let value) = vnode2.props["min-width"] {
            #expect(value == "50.5px")
        }
    }

    // MARK: - Divider Tests

    @Test func basicDividerRendering() async throws {
        // Create a basic divider
        let divider = Divider()

        // Convert to VNode
        let vnode = divider.toVNode()

        // Verify it creates a div element
        #expect(vnode.isElement(tag: "div"))
        #expect(vnode.elementTag == "div")

        // Verify border styling
        #expect(vnode.props["border-top"] != nil)

        if case .style(name: "border-top", value: let value) = vnode.props["border-top"] {
            #expect(value == "1px solid #d1d5db")
        } else {
            Issue.record("border-top should be a style property")
        }

        // Verify dimensions
        #expect(vnode.props["height"] != nil)
        #expect(vnode.props["width"] != nil)

        if case .style(name: "height", value: let value) = vnode.props["height"] {
            #expect(value == "0")
        } else {
            Issue.record("height should be a style property")
        }

        if case .style(name: "width", value: let value) = vnode.props["width"] {
            #expect(value == "100%")
        } else {
            Issue.record("width should be a style property")
        }

        // Verify no children
        #expect(vnode.children.isEmpty)
    }

    @Test func dividerFlexShrink() async throws {
        // Create a divider
        let divider = Divider()

        // Convert to VNode
        let vnode = divider.toVNode()

        // Verify flex-shrink is set to prevent growing in flex layouts
        #expect(vnode.props["flex-shrink"] != nil)

        if case .style(name: "flex-shrink", value: let value) = vnode.props["flex-shrink"] {
            #expect(value == "0")
        } else {
            Issue.record("flex-shrink should be a style property with value '0'")
        }
    }

    @Test func dividerMargins() async throws {
        // Create a divider
        let divider = Divider()

        // Convert to VNode
        let vnode = divider.toVNode()

        // Verify margins are set
        #expect(vnode.props["margin-top"] != nil)
        #expect(vnode.props["margin-bottom"] != nil)

        if case .style(name: "margin-top", value: let value) = vnode.props["margin-top"] {
            #expect(value == "0")
        }

        if case .style(name: "margin-bottom", value: let value) = vnode.props["margin-bottom"] {
            #expect(value == "0")
        }
    }

    // MARK: - Integration Tests

    @Test func multipleSpacersHaveUniqueIDs() async throws {
        // Create multiple spacers
        let spacer1 = Spacer()
        let spacer2 = Spacer()
        let spacer3 = Spacer(minLength: 10)

        // Convert to VNodes
        let vnode1 = spacer1.toVNode()
        let vnode2 = spacer2.toVNode()
        let vnode3 = spacer3.toVNode()

        // Verify unique IDs
        #expect(vnode1.id != vnode2.id)
        #expect(vnode1.id != vnode3.id)
        #expect(vnode2.id != vnode3.id)
    }

    @Test func multipleDividersHaveUniqueIDs() async throws {
        // Create multiple dividers
        let divider1 = Divider()
        let divider2 = Divider()

        // Convert to VNodes
        let vnode1 = divider1.toVNode()
        let vnode2 = divider2.toVNode()

        // Verify unique IDs
        #expect(vnode1.id != vnode2.id)
    }

    @Test func spacerAndDividerAreViews() async throws {
        // Verify that Spacer and Divider conform to View protocol
        func acceptsView<V: View>(_ view: V) -> Bool {
            return true
        }

        #expect(acceptsView(Spacer()))
        #expect(acceptsView(Divider()))
    }

    @Test func spacerAndDividerAreSendable() async throws {
        // Verify that Spacer and Divider conform to Sendable
        func acceptsSendable<S: Sendable>(_ value: S) -> Bool {
            return true
        }

        #expect(acceptsSendable(Spacer()))
        #expect(acceptsSendable(Divider()))
    }
}
