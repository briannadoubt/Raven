import Testing
@testable import Raven

/// Tests for LazyVStack layout component.
///
/// These tests verify that:
/// 1. LazyVStack converts to VNode correctly
/// 2. Alignment options work as expected
/// 3. Spacing is applied correctly
/// 4. Pinned views configuration is set properly
@MainActor
@Suite struct LazyVStackTests {

    // MARK: - Basic Structure Tests

    @Test func lazyVStackConvertsToVNode() async throws {
        let lazyVStack = LazyVStack {
            Text("First")
            Text("Second")
        }

        let vnode = lazyVStack.toVNode()

        // Verify it creates a div element
        #expect(vnode.isElement(tag: "div"))

        // Verify CSS properties
        #expect(vnode.props["display"] == .style(name: "display", value: "flex"))
        #expect(vnode.props["flex-direction"] == .style(name: "flex-direction", value: "column"))
        #expect(vnode.props["align-items"] == .style(name: "align-items", value: "center"))

        // Verify the class attribute for identification
        #expect(vnode.props["class"] == .attribute(name: "class", value: "raven-lazy-vstack"))
    }

    // MARK: - Alignment Tests

    @Test func lazyVStackWithLeadingAlignment() async throws {
        let lazyVStack = LazyVStack(alignment: .leading) {
            Text("Leading")
        }

        let vnode = lazyVStack.toVNode()
        #expect(vnode.props["align-items"] ==
                       .style(name: "align-items", value: "flex-start"))
    }

    @Test func lazyVStackWithTrailingAlignment() async throws {
        let lazyVStack = LazyVStack(alignment: .trailing) {
            Text("Trailing")
        }

        let vnode = lazyVStack.toVNode()
        #expect(vnode.props["align-items"] ==
                       .style(name: "align-items", value: "flex-end"))
    }

    @Test func lazyVStackWithCenterAlignment() async throws {
        let lazyVStack = LazyVStack(alignment: .center) {
            Text("Center")
        }

        let vnode = lazyVStack.toVNode()
        #expect(vnode.props["align-items"] ==
                       .style(name: "align-items", value: "center"))
    }

    // MARK: - Spacing Tests

    @Test func lazyVStackWithSpacing() async throws {
        let lazyVStack = LazyVStack(spacing: 16) {
            Text("First")
            Text("Second")
        }

        let vnode = lazyVStack.toVNode()

        // Verify spacing is set as gap
        #expect(vnode.props["gap"] == .style(name: "gap", value: "16.0px"))
    }

    @Test func lazyVStackWithoutSpacing() async throws {
        let lazyVStack = LazyVStack {
            Text("First")
            Text("Second")
        }

        let vnode = lazyVStack.toVNode()

        // Verify no gap is set
        #expect(vnode.props["gap"] == nil)
    }

    // MARK: - Pinned Views Tests

    @Test func lazyVStackWithPinnedHeaders() async throws {
        let lazyVStack = LazyVStack(pinnedViews: .sectionHeaders) {
            Text("Content")
        }

        let vnode = lazyVStack.toVNode()

        // Verify pinned views data attribute
        #expect(vnode.props["data-pinned-views"] ==
                       .attribute(name: "data-pinned-views", value: "headers"))
    }

    @Test func lazyVStackWithPinnedFooters() async throws {
        let lazyVStack = LazyVStack(pinnedViews: .sectionFooters) {
            Text("Content")
        }

        let vnode = lazyVStack.toVNode()

        // Verify pinned views data attribute
        #expect(vnode.props["data-pinned-views"] ==
                       .attribute(name: "data-pinned-views", value: "footers"))
    }

    @Test func lazyVStackWithPinnedHeadersAndFooters() async throws {
        let lazyVStack = LazyVStack(pinnedViews: [.sectionHeaders, .sectionFooters]) {
            Text("Content")
        }

        let vnode = lazyVStack.toVNode()

        // Verify pinned views data attribute contains both
        if case let .attribute(_, value) = vnode.props["data-pinned-views"] {
            #expect(value.contains("headers"))
            #expect(value.contains("footers"))
        } else {
            Issue.record("Expected data-pinned-views attribute")
        }
    }

    @Test func lazyVStackWithoutPinnedViews() async throws {
        let lazyVStack = LazyVStack {
            Text("Content")
        }

        let vnode = lazyVStack.toVNode()

        // Verify no pinned views attribute is set
        #expect(vnode.props["data-pinned-views"] == nil)
    }

    // MARK: - Complex Layout Tests

    @Test func lazyVStackWithComplexContent() async throws {
        let lazyVStack = LazyVStack(alignment: .leading, spacing: 20) {
            Text("Title")
            Text("Subtitle")
            Text("Description")
        }

        let vnode = lazyVStack.toVNode()

        // Verify all properties are set correctly
        #expect(vnode.isElement(tag: "div"))
        #expect(vnode.props["display"] == .style(name: "display", value: "flex"))
        #expect(vnode.props["flex-direction"] == .style(name: "flex-direction", value: "column"))
        #expect(vnode.props["align-items"] == .style(name: "align-items", value: "flex-start"))
        #expect(vnode.props["gap"] == .style(name: "gap", value: "20.0px"))
        #expect(vnode.props["class"] == .attribute(name: "class", value: "raven-lazy-vstack"))
    }

    // MARK: - Integration with ForEach

    @Test func lazyVStackWithForEach() async throws {
        let items = ["Item 1", "Item 2", "Item 3"]

        let lazyVStack = LazyVStack(spacing: 12) {
            ForEach(items, id: \.self) { item in
                Text(item)
            }
        }

        let vnode = lazyVStack.toVNode()

        // Verify basic structure
        #expect(vnode.isElement(tag: "div"))
        #expect(vnode.props["gap"] == .style(name: "gap", value: "12.0px"))
    }
}
