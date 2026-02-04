import XCTest
@testable import Raven

/// Tests for LazyVStack layout component.
///
/// These tests verify that:
/// 1. LazyVStack converts to VNode correctly
/// 2. Alignment options work as expected
/// 3. Spacing is applied correctly
/// 4. Pinned views configuration is set properly
@MainActor
final class LazyVStackTests: XCTestCase {

    // MARK: - Basic Structure Tests

    func testLazyVStackConvertsToVNode() async throws {
        let lazyVStack = LazyVStack {
            Text("First")
            Text("Second")
        }

        let vnode = lazyVStack.toVNode()

        // Verify it creates a div element
        XCTAssertTrue(vnode.isElement(tag: "div"), "LazyVStack should create a div element")

        // Verify CSS properties
        XCTAssertEqual(vnode.props["display"], .style(name: "display", value: "flex"))
        XCTAssertEqual(vnode.props["flex-direction"], .style(name: "flex-direction", value: "column"))
        XCTAssertEqual(vnode.props["align-items"], .style(name: "align-items", value: "center"))

        // Verify the class attribute for identification
        XCTAssertEqual(vnode.props["class"], .attribute(name: "class", value: "raven-lazy-vstack"))
    }

    // MARK: - Alignment Tests

    func testLazyVStackWithLeadingAlignment() async throws {
        let lazyVStack = LazyVStack(alignment: .leading) {
            Text("Leading")
        }

        let vnode = lazyVStack.toVNode()
        XCTAssertEqual(vnode.props["align-items"],
                       .style(name: "align-items", value: "flex-start"))
    }

    func testLazyVStackWithTrailingAlignment() async throws {
        let lazyVStack = LazyVStack(alignment: .trailing) {
            Text("Trailing")
        }

        let vnode = lazyVStack.toVNode()
        XCTAssertEqual(vnode.props["align-items"],
                       .style(name: "align-items", value: "flex-end"))
    }

    func testLazyVStackWithCenterAlignment() async throws {
        let lazyVStack = LazyVStack(alignment: .center) {
            Text("Center")
        }

        let vnode = lazyVStack.toVNode()
        XCTAssertEqual(vnode.props["align-items"],
                       .style(name: "align-items", value: "center"))
    }

    // MARK: - Spacing Tests

    func testLazyVStackWithSpacing() async throws {
        let lazyVStack = LazyVStack(spacing: 16) {
            Text("First")
            Text("Second")
        }

        let vnode = lazyVStack.toVNode()

        // Verify spacing is set as gap
        XCTAssertEqual(vnode.props["gap"], .style(name: "gap", value: "16.0px"))
    }

    func testLazyVStackWithoutSpacing() async throws {
        let lazyVStack = LazyVStack {
            Text("First")
            Text("Second")
        }

        let vnode = lazyVStack.toVNode()

        // Verify no gap is set
        XCTAssertNil(vnode.props["gap"])
    }

    // MARK: - Pinned Views Tests

    func testLazyVStackWithPinnedHeaders() async throws {
        let lazyVStack = LazyVStack(pinnedViews: .sectionHeaders) {
            Text("Content")
        }

        let vnode = lazyVStack.toVNode()

        // Verify pinned views data attribute
        XCTAssertEqual(vnode.props["data-pinned-views"],
                       .attribute(name: "data-pinned-views", value: "headers"))
    }

    func testLazyVStackWithPinnedFooters() async throws {
        let lazyVStack = LazyVStack(pinnedViews: .sectionFooters) {
            Text("Content")
        }

        let vnode = lazyVStack.toVNode()

        // Verify pinned views data attribute
        XCTAssertEqual(vnode.props["data-pinned-views"],
                       .attribute(name: "data-pinned-views", value: "footers"))
    }

    func testLazyVStackWithPinnedHeadersAndFooters() async throws {
        let lazyVStack = LazyVStack(pinnedViews: [.sectionHeaders, .sectionFooters]) {
            Text("Content")
        }

        let vnode = lazyVStack.toVNode()

        // Verify pinned views data attribute contains both
        if case let .attribute(_, value) = vnode.props["data-pinned-views"] {
            XCTAssertTrue(value.contains("headers"), "Should contain headers")
            XCTAssertTrue(value.contains("footers"), "Should contain footers")
        } else {
            XCTFail("Expected data-pinned-views attribute")
        }
    }

    func testLazyVStackWithoutPinnedViews() async throws {
        let lazyVStack = LazyVStack {
            Text("Content")
        }

        let vnode = lazyVStack.toVNode()

        // Verify no pinned views attribute is set
        XCTAssertNil(vnode.props["data-pinned-views"])
    }

    // MARK: - Complex Layout Tests

    func testLazyVStackWithComplexContent() async throws {
        let lazyVStack = LazyVStack(alignment: .leading, spacing: 20) {
            Text("Title")
            Text("Subtitle")
            Text("Description")
        }

        let vnode = lazyVStack.toVNode()

        // Verify all properties are set correctly
        XCTAssertTrue(vnode.isElement(tag: "div"))
        XCTAssertEqual(vnode.props["display"], .style(name: "display", value: "flex"))
        XCTAssertEqual(vnode.props["flex-direction"], .style(name: "flex-direction", value: "column"))
        XCTAssertEqual(vnode.props["align-items"], .style(name: "align-items", value: "flex-start"))
        XCTAssertEqual(vnode.props["gap"], .style(name: "gap", value: "20.0px"))
        XCTAssertEqual(vnode.props["class"], .attribute(name: "class", value: "raven-lazy-vstack"))
    }

    // MARK: - Integration with ForEach

    func testLazyVStackWithForEach() async throws {
        let items = ["Item 1", "Item 2", "Item 3"]

        let lazyVStack = LazyVStack(spacing: 12) {
            ForEach(items, id: \.self) { item in
                Text(item)
            }
        }

        let vnode = lazyVStack.toVNode()

        // Verify basic structure
        XCTAssertTrue(vnode.isElement(tag: "div"))
        XCTAssertEqual(vnode.props["gap"], .style(name: "gap", value: "12.0px"))
    }
}
