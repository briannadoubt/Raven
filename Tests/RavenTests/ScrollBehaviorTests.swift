import Testing
@testable import Raven

/// Tests for scroll behavior modifiers (.scrollBounceBehavior, .scrollClipDisabled)
@MainActor
@Suite struct ScrollBehaviorTests {

    // MARK: - BounceBehavior Tests

    @MainActor
    @Test func bounceBehaviorAutomatic() {
        // Test automatic bounce behavior
        let view = Text("Content")
            .scrollBounceBehavior(.automatic)

        // Verify the type is correct
        #expect(view is _ScrollBounceBehaviorView<Text>)
    }

    @MainActor
    @Test func bounceBehaviorAlways() {
        // Test always bounce behavior
        let view = Text("Content")
            .scrollBounceBehavior(.always)

        // Verify the type is correct
        #expect(view is _ScrollBounceBehaviorView<Text>)
    }

    @MainActor
    @Test func bounceBehaviorBasedOnSize() {
        // Test basedOnSize bounce behavior
        let view = Text("Content")
            .scrollBounceBehavior(.basedOnSize)

        // Verify the type is correct
        #expect(view is _ScrollBounceBehaviorView<Text>)
    }

    @MainActor
    @Test func bounceBehaviorWithVerticalAxis() {
        // Test bounce behavior with explicit vertical axis
        let view = Text("Content")
            .scrollBounceBehavior(.always, axes: [.vertical])

        // Verify compilation and type
        #expect(view is _ScrollBounceBehaviorView<Text>)
    }

    @MainActor
    @Test func bounceBehaviorWithHorizontalAxis() {
        // Test bounce behavior with horizontal axis
        let view = Text("Content")
            .scrollBounceBehavior(.basedOnSize, axes: [.horizontal])

        // Verify compilation and type
        #expect(view is _ScrollBounceBehaviorView<Text>)
    }

    @MainActor
    @Test func bounceBehaviorWithBothAxes() {
        // Test bounce behavior with both axes
        let view = Text("Content")
            .scrollBounceBehavior(.always, axes: [.horizontal, .vertical])

        // Verify compilation and type
        #expect(view is _ScrollBounceBehaviorView<Text>)
    }

    // MARK: - VNode Generation Tests

    @MainActor
    @Test func bounceBehaviorAutomaticVNode() {
        // Test VNode generation for automatic behavior (default is vertical axis only)
        let view = Text("Content")
            .scrollBounceBehavior(.automatic)
        let vnode = view.toVNode()

        // Verify it's an element
        if case .element(let tag) = vnode.type {
            #expect(tag == "div")

            // Default is vertical axis only, so check for -y
            if case .style(let name, let value) = vnode.props["overscroll-behavior-y"] {
                #expect(name == "overscroll-behavior-y")
                #expect(value == "auto")
            } else {
                Issue.record("Expected overscroll-behavior-y style property")
            }

            // X should be set to none
            if case .style(let name, let value) = vnode.props["overscroll-behavior-x"] {
                #expect(name == "overscroll-behavior-x")
                #expect(value == "none")
            } else {
                Issue.record("Expected overscroll-behavior-x style property")
            }
        } else {
            Issue.record("Expected element VNode")
        }
    }

    @MainActor
    @Test func bounceBehaviorBasedOnSizeVNode() {
        // Test VNode generation for basedOnSize behavior (default is vertical axis only)
        let view = Text("Content")
            .scrollBounceBehavior(.basedOnSize)
        let vnode = view.toVNode()

        // Verify it's an element
        if case .element(let tag) = vnode.type {
            #expect(tag == "div")

            // Default is vertical axis only, so check for -y with 'contain' value
            if case .style(let name, let value) = vnode.props["overscroll-behavior-y"] {
                #expect(name == "overscroll-behavior-y")
                #expect(value == "contain")
            } else {
                Issue.record("Expected overscroll-behavior-y style property")
            }

            // X should be set to none
            if case .style(let name, let value) = vnode.props["overscroll-behavior-x"] {
                #expect(name == "overscroll-behavior-x")
                #expect(value == "none")
            } else {
                Issue.record("Expected overscroll-behavior-x style property")
            }
        } else {
            Issue.record("Expected element VNode")
        }
    }

    @MainActor
    @Test func bounceBehaviorHorizontalAxisVNode() {
        // Test VNode generation for horizontal axis only
        let view = Text("Content")
            .scrollBounceBehavior(.always, axes: [.horizontal])
        let vnode = view.toVNode()

        // Verify it's an element
        if case .element(let tag) = vnode.type {
            #expect(tag == "div")

            // Check for overscroll-behavior-x
            if case .style(let name, let value) = vnode.props["overscroll-behavior-x"] {
                #expect(name == "overscroll-behavior-x")
                #expect(value == "auto")
            } else {
                Issue.record("Expected overscroll-behavior-x style property")
            }

            // Check that vertical is set to 'none'
            if case .style(let name, let value) = vnode.props["overscroll-behavior-y"] {
                #expect(name == "overscroll-behavior-y")
                #expect(value == "none")
            } else {
                Issue.record("Expected overscroll-behavior-y to be 'none'")
            }
        } else {
            Issue.record("Expected element VNode")
        }
    }

    @MainActor
    @Test func bounceBehaviorVerticalAxisVNode() {
        // Test VNode generation for vertical axis only
        let view = Text("Content")
            .scrollBounceBehavior(.automatic, axes: [.vertical])
        let vnode = view.toVNode()

        // Verify it's an element
        if case .element(let tag) = vnode.type {
            #expect(tag == "div")

            // Check for overscroll-behavior-y
            if case .style(let name, let value) = vnode.props["overscroll-behavior-y"] {
                #expect(name == "overscroll-behavior-y")
                #expect(value == "auto")
            } else {
                Issue.record("Expected overscroll-behavior-y style property")
            }

            // Check that horizontal is set to 'none'
            if case .style(let name, let value) = vnode.props["overscroll-behavior-x"] {
                #expect(name == "overscroll-behavior-x")
                #expect(value == "none")
            } else {
                Issue.record("Expected overscroll-behavior-x to be 'none'")
            }
        } else {
            Issue.record("Expected element VNode")
        }
    }

    @MainActor
    @Test func bounceBehaviorBothAxesVNode() {
        // Test VNode generation for both axes
        let view = Text("Content")
            .scrollBounceBehavior(.always, axes: [.horizontal, .vertical])
        let vnode = view.toVNode()

        // Verify it's an element
        if case .element(let tag) = vnode.type {
            #expect(tag == "div")

            // Check for shorthand overscroll-behavior (not per-axis)
            if case .style(let name, let value) = vnode.props["overscroll-behavior"] {
                #expect(name == "overscroll-behavior")
                #expect(value == "auto")
            } else {
                Issue.record("Expected overscroll-behavior style property")
            }
        } else {
            Issue.record("Expected element VNode")
        }
    }

    // MARK: - ScrollClipDisabled Tests

    @MainActor
    @Test func scrollClipDisabled() {
        // Test scroll clip disabled modifier
        let view = Text("Content")
            .scrollClipDisabled()

        // Verify the type is correct
        #expect(view is _ScrollClipDisabledView<Text>)
    }

    @MainActor
    @Test func scrollClipDisabledWithFalse() {
        // Test scroll clip disabled with explicit false
        let view = Text("Content")
            .scrollClipDisabled(false)

        // Verify the type is correct
        #expect(view is _ScrollClipDisabledView<Text>)
    }

    @MainActor
    @Test func scrollClipDisabledVNode() {
        // Test VNode generation for clip disabled
        let view = Text("Content")
            .scrollClipDisabled()
        let vnode = view.toVNode()

        // Verify it's an element
        if case .element(let tag) = vnode.type {
            #expect(tag == "div")

            // Check for overflow: visible
            if case .style(let name, let value) = vnode.props["overflow"] {
                #expect(name == "overflow")
                #expect(value == "visible")
            } else {
                Issue.record("Expected overflow style property")
            }

            // Check for clip-path: none
            if case .style(let name, let value) = vnode.props["clip-path"] {
                #expect(name == "clip-path")
                #expect(value == "none")
            } else {
                Issue.record("Expected clip-path style property")
            }
        } else {
            Issue.record("Expected element VNode")
        }
    }

    @MainActor
    @Test func scrollClipEnabledVNode() {
        // Test VNode generation for clip enabled (disabled = false)
        let view = Text("Content")
            .scrollClipDisabled(false)
        let vnode = view.toVNode()

        // Verify it's an element
        if case .element(let tag) = vnode.type {
            #expect(tag == "div")

            // Check for overflow: hidden
            if case .style(let name, let value) = vnode.props["overflow"] {
                #expect(name == "overflow")
                #expect(value == "hidden")
            } else {
                Issue.record("Expected overflow style property")
            }
        } else {
            Issue.record("Expected element VNode")
        }
    }

    // MARK: - Integration Tests

    @MainActor
    @Test func bounceBehaviorWithOtherModifiers() {
        // Test bounce behavior combined with other modifiers
        let view = Text("Content")
            .padding(16)
            .scrollBounceBehavior(.basedOnSize)
            .frame(width: 200, height: 300)

        // Should compile and chain correctly
        let _ = view
    }

    @MainActor
    @Test func scrollClipDisabledWithOtherModifiers() {
        // Test scroll clip disabled combined with other modifiers
        let view = Text("Content")
            .padding(16)
            .scrollClipDisabled()
            .foregroundColor(.blue)

        // Should compile and chain correctly
        let _ = view
    }

    @MainActor
    @Test func combinedScrollModifiers() {
        // Test both scroll modifiers together
        let view = Text("Content")
            .scrollBounceBehavior(.always, axes: [.vertical])
            .scrollClipDisabled()

        // Should compile and chain correctly
        let _ = view
    }

    // MARK: - Axis Tests

    @MainActor
    @Test func axisSetHorizontal() {
        // Test Axis.Set with horizontal
        let axes: Axis.Set = [.horizontal]
        #expect(axes.contains(.horizontal))
        #expect(!axes.contains(.vertical))
    }

    @MainActor
    @Test func axisSetVertical() {
        // Test Axis.Set with vertical
        let axes: Axis.Set = [.vertical]
        #expect(!axes.contains(.horizontal))
        #expect(axes.contains(.vertical))
    }

    @MainActor
    @Test func axisSetBoth() {
        // Test Axis.Set with both axes
        let axes: Axis.Set = [.horizontal, .vertical]
        #expect(axes.contains(.horizontal))
        #expect(axes.contains(.vertical))
    }
}
