import XCTest
@testable import Raven

/// Tests for scroll behavior modifiers (.scrollBounceBehavior, .scrollClipDisabled)
final class ScrollBehaviorTests: XCTestCase {

    // MARK: - BounceBehavior Tests

    @MainActor
    func testBounceBehaviorAutomatic() {
        // Test automatic bounce behavior
        let view = Text("Content")
            .scrollBounceBehavior(.automatic)

        // Verify the type is correct
        XCTAssertTrue(view is _ScrollBounceBehaviorView<Text>)
    }

    @MainActor
    func testBounceBehaviorAlways() {
        // Test always bounce behavior
        let view = Text("Content")
            .scrollBounceBehavior(.always)

        // Verify the type is correct
        XCTAssertTrue(view is _ScrollBounceBehaviorView<Text>)
    }

    @MainActor
    func testBounceBehaviorBasedOnSize() {
        // Test basedOnSize bounce behavior
        let view = Text("Content")
            .scrollBounceBehavior(.basedOnSize)

        // Verify the type is correct
        XCTAssertTrue(view is _ScrollBounceBehaviorView<Text>)
    }

    @MainActor
    func testBounceBehaviorWithVerticalAxis() {
        // Test bounce behavior with explicit vertical axis
        let view = Text("Content")
            .scrollBounceBehavior(.always, axes: [.vertical])

        // Verify compilation and type
        XCTAssertTrue(view is _ScrollBounceBehaviorView<Text>)
    }

    @MainActor
    func testBounceBehaviorWithHorizontalAxis() {
        // Test bounce behavior with horizontal axis
        let view = Text("Content")
            .scrollBounceBehavior(.basedOnSize, axes: [.horizontal])

        // Verify compilation and type
        XCTAssertTrue(view is _ScrollBounceBehaviorView<Text>)
    }

    @MainActor
    func testBounceBehaviorWithBothAxes() {
        // Test bounce behavior with both axes
        let view = Text("Content")
            .scrollBounceBehavior(.always, axes: [.horizontal, .vertical])

        // Verify compilation and type
        XCTAssertTrue(view is _ScrollBounceBehaviorView<Text>)
    }

    // MARK: - VNode Generation Tests

    @MainActor
    func testBounceBehaviorAutomaticVNode() {
        // Test VNode generation for automatic behavior (default is vertical axis only)
        let view = Text("Content")
            .scrollBounceBehavior(.automatic)
        let vnode = view.toVNode()

        // Verify it's an element
        if case .element(let tag) = vnode.type {
            XCTAssertEqual(tag, "div")

            // Default is vertical axis only, so check for -y
            if case .style(let name, let value) = vnode.props["overscroll-behavior-y"] {
                XCTAssertEqual(name, "overscroll-behavior-y")
                XCTAssertEqual(value, "auto")
            } else {
                XCTFail("Expected overscroll-behavior-y style property")
            }

            // X should be set to none
            if case .style(let name, let value) = vnode.props["overscroll-behavior-x"] {
                XCTAssertEqual(name, "overscroll-behavior-x")
                XCTAssertEqual(value, "none")
            } else {
                XCTFail("Expected overscroll-behavior-x style property")
            }
        } else {
            XCTFail("Expected element VNode")
        }
    }

    @MainActor
    func testBounceBehaviorBasedOnSizeVNode() {
        // Test VNode generation for basedOnSize behavior (default is vertical axis only)
        let view = Text("Content")
            .scrollBounceBehavior(.basedOnSize)
        let vnode = view.toVNode()

        // Verify it's an element
        if case .element(let tag) = vnode.type {
            XCTAssertEqual(tag, "div")

            // Default is vertical axis only, so check for -y with 'contain' value
            if case .style(let name, let value) = vnode.props["overscroll-behavior-y"] {
                XCTAssertEqual(name, "overscroll-behavior-y")
                XCTAssertEqual(value, "contain")
            } else {
                XCTFail("Expected overscroll-behavior-y style property")
            }

            // X should be set to none
            if case .style(let name, let value) = vnode.props["overscroll-behavior-x"] {
                XCTAssertEqual(name, "overscroll-behavior-x")
                XCTAssertEqual(value, "none")
            } else {
                XCTFail("Expected overscroll-behavior-x style property")
            }
        } else {
            XCTFail("Expected element VNode")
        }
    }

    @MainActor
    func testBounceBehaviorHorizontalAxisVNode() {
        // Test VNode generation for horizontal axis only
        let view = Text("Content")
            .scrollBounceBehavior(.always, axes: [.horizontal])
        let vnode = view.toVNode()

        // Verify it's an element
        if case .element(let tag) = vnode.type {
            XCTAssertEqual(tag, "div")

            // Check for overscroll-behavior-x
            if case .style(let name, let value) = vnode.props["overscroll-behavior-x"] {
                XCTAssertEqual(name, "overscroll-behavior-x")
                XCTAssertEqual(value, "auto")
            } else {
                XCTFail("Expected overscroll-behavior-x style property")
            }

            // Check that vertical is set to 'none'
            if case .style(let name, let value) = vnode.props["overscroll-behavior-y"] {
                XCTAssertEqual(name, "overscroll-behavior-y")
                XCTAssertEqual(value, "none")
            } else {
                XCTFail("Expected overscroll-behavior-y to be 'none'")
            }
        } else {
            XCTFail("Expected element VNode")
        }
    }

    @MainActor
    func testBounceBehaviorVerticalAxisVNode() {
        // Test VNode generation for vertical axis only
        let view = Text("Content")
            .scrollBounceBehavior(.automatic, axes: [.vertical])
        let vnode = view.toVNode()

        // Verify it's an element
        if case .element(let tag) = vnode.type {
            XCTAssertEqual(tag, "div")

            // Check for overscroll-behavior-y
            if case .style(let name, let value) = vnode.props["overscroll-behavior-y"] {
                XCTAssertEqual(name, "overscroll-behavior-y")
                XCTAssertEqual(value, "auto")
            } else {
                XCTFail("Expected overscroll-behavior-y style property")
            }

            // Check that horizontal is set to 'none'
            if case .style(let name, let value) = vnode.props["overscroll-behavior-x"] {
                XCTAssertEqual(name, "overscroll-behavior-x")
                XCTAssertEqual(value, "none")
            } else {
                XCTFail("Expected overscroll-behavior-x to be 'none'")
            }
        } else {
            XCTFail("Expected element VNode")
        }
    }

    @MainActor
    func testBounceBehaviorBothAxesVNode() {
        // Test VNode generation for both axes
        let view = Text("Content")
            .scrollBounceBehavior(.always, axes: [.horizontal, .vertical])
        let vnode = view.toVNode()

        // Verify it's an element
        if case .element(let tag) = vnode.type {
            XCTAssertEqual(tag, "div")

            // Check for shorthand overscroll-behavior (not per-axis)
            if case .style(let name, let value) = vnode.props["overscroll-behavior"] {
                XCTAssertEqual(name, "overscroll-behavior")
                XCTAssertEqual(value, "auto")
            } else {
                XCTFail("Expected overscroll-behavior style property")
            }
        } else {
            XCTFail("Expected element VNode")
        }
    }

    // MARK: - ScrollClipDisabled Tests

    @MainActor
    func testScrollClipDisabled() {
        // Test scroll clip disabled modifier
        let view = Text("Content")
            .scrollClipDisabled()

        // Verify the type is correct
        XCTAssertTrue(view is _ScrollClipDisabledView<Text>)
    }

    @MainActor
    func testScrollClipDisabledWithFalse() {
        // Test scroll clip disabled with explicit false
        let view = Text("Content")
            .scrollClipDisabled(false)

        // Verify the type is correct
        XCTAssertTrue(view is _ScrollClipDisabledView<Text>)
    }

    @MainActor
    func testScrollClipDisabledVNode() {
        // Test VNode generation for clip disabled
        let view = Text("Content")
            .scrollClipDisabled()
        let vnode = view.toVNode()

        // Verify it's an element
        if case .element(let tag) = vnode.type {
            XCTAssertEqual(tag, "div")

            // Check for overflow: visible
            if case .style(let name, let value) = vnode.props["overflow"] {
                XCTAssertEqual(name, "overflow")
                XCTAssertEqual(value, "visible")
            } else {
                XCTFail("Expected overflow style property")
            }

            // Check for clip-path: none
            if case .style(let name, let value) = vnode.props["clip-path"] {
                XCTAssertEqual(name, "clip-path")
                XCTAssertEqual(value, "none")
            } else {
                XCTFail("Expected clip-path style property")
            }
        } else {
            XCTFail("Expected element VNode")
        }
    }

    @MainActor
    func testScrollClipEnabledVNode() {
        // Test VNode generation for clip enabled (disabled = false)
        let view = Text("Content")
            .scrollClipDisabled(false)
        let vnode = view.toVNode()

        // Verify it's an element
        if case .element(let tag) = vnode.type {
            XCTAssertEqual(tag, "div")

            // Check for overflow: hidden
            if case .style(let name, let value) = vnode.props["overflow"] {
                XCTAssertEqual(name, "overflow")
                XCTAssertEqual(value, "hidden")
            } else {
                XCTFail("Expected overflow style property")
            }
        } else {
            XCTFail("Expected element VNode")
        }
    }

    // MARK: - Integration Tests

    @MainActor
    func testBounceBehaviorWithOtherModifiers() {
        // Test bounce behavior combined with other modifiers
        let view = Text("Content")
            .padding(16)
            .scrollBounceBehavior(.basedOnSize)
            .frame(width: 200, height: 300)

        // Should compile and chain correctly
        let _ = view
    }

    @MainActor
    func testScrollClipDisabledWithOtherModifiers() {
        // Test scroll clip disabled combined with other modifiers
        let view = Text("Content")
            .padding(16)
            .scrollClipDisabled()
            .foregroundColor(.blue)

        // Should compile and chain correctly
        let _ = view
    }

    @MainActor
    func testCombinedScrollModifiers() {
        // Test both scroll modifiers together
        let view = Text("Content")
            .scrollBounceBehavior(.always, axes: [.vertical])
            .scrollClipDisabled()

        // Should compile and chain correctly
        let _ = view
    }

    // MARK: - Axis Tests

    @MainActor
    func testAxisSetHorizontal() {
        // Test Axis.Set with horizontal
        let axes: Axis.Set = [.horizontal]
        XCTAssertTrue(axes.contains(.horizontal))
        XCTAssertFalse(axes.contains(.vertical))
    }

    @MainActor
    func testAxisSetVertical() {
        // Test Axis.Set with vertical
        let axes: Axis.Set = [.vertical]
        XCTAssertFalse(axes.contains(.horizontal))
        XCTAssertTrue(axes.contains(.vertical))
    }

    @MainActor
    func testAxisSetBoth() {
        // Test Axis.Set with both axes
        let axes: Axis.Set = [.horizontal, .vertical]
        XCTAssertTrue(axes.contains(.horizontal))
        XCTAssertTrue(axes.contains(.vertical))
    }
}
