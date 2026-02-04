import XCTest
@testable import Raven

/// Tests for scroll transition modifier (.scrollTransition)
final class ScrollTransitionTests: XCTestCase {

    // MARK: - ScrollTransitionPhase Tests

    @MainActor
    func testPhaseEquality() {
        // Test that phases are properly equatable
        XCTAssertEqual(ScrollTransitionPhase.topLeading, ScrollTransitionPhase.topLeading)
        XCTAssertEqual(ScrollTransitionPhase.identity, ScrollTransitionPhase.identity)
        XCTAssertEqual(ScrollTransitionPhase.bottomTrailing, ScrollTransitionPhase.bottomTrailing)

        XCTAssertNotEqual(ScrollTransitionPhase.topLeading, ScrollTransitionPhase.identity)
        XCTAssertNotEqual(ScrollTransitionPhase.identity, ScrollTransitionPhase.bottomTrailing)
        XCTAssertNotEqual(ScrollTransitionPhase.topLeading, ScrollTransitionPhase.bottomTrailing)
    }

    @MainActor
    func testPhaseIsIdentity() {
        // Test the isIdentity convenience property
        XCTAssertFalse(ScrollTransitionPhase.topLeading.isIdentity)
        XCTAssertTrue(ScrollTransitionPhase.identity.isIdentity)
        XCTAssertFalse(ScrollTransitionPhase.bottomTrailing.isIdentity)
    }

    // MARK: - Basic Transition Tests

    @MainActor
    func testBasicScrollTransition() {
        // Test basic scroll transition without axis
        let view = Text("Content")
            .scrollTransition { content, phase in
                content.opacity(phase.isIdentity ? 1 : 0)
            }

        // Verify the type is correct
        XCTAssertTrue(view is _ScrollTransitionView<Text>)
    }

    @MainActor
    func testScrollTransitionWithAxis() {
        // Test scroll transition with explicit axis
        let view = Text("Content")
            .scrollTransition(axis: .vertical) { content, phase in
                content.scaleEffect(phase.isIdentity ? 1 : 0.8)
            }

        // Verify the type is correct
        XCTAssertTrue(view is _ScrollTransitionView<Text>)
    }

    @MainActor
    func testScrollTransitionWithHorizontalAxis() {
        // Test scroll transition with horizontal axis
        let view = Text("Content")
            .scrollTransition(axis: .horizontal) { content, phase in
                content.opacity(phase.isIdentity ? 1 : 0.5)
            }

        // Verify the type is correct
        XCTAssertTrue(view is _ScrollTransitionView<Text>)
    }

    @MainActor
    func testScrollTransitionWithNilAxis() {
        // Test scroll transition with explicit nil axis (same as basic)
        let view = Text("Content")
            .scrollTransition(axis: nil) { content, phase in
                content.blur(radius: phase.isIdentity ? 0 : 5)
            }

        // Verify the type is correct
        XCTAssertTrue(view is _ScrollTransitionView<Text>)
    }

    // MARK: - VNode Generation Tests

    @MainActor
    func testScrollTransitionVNode() {
        // Test VNode generation for basic scroll transition
        let baseView = Text("Content")
        let transitionView = _ScrollTransitionView(
            content: baseView,
            configuration: ScrollTransitionConfiguration(axis: nil)
        )
        let vnode = transitionView.toVNode()

        // Verify it's an element
        if case .element(let tag) = vnode.type {
            XCTAssertEqual(tag, "div")

            // Check for scroll transition data attribute
            if case .attribute(let name, _) = vnode.props["data-scroll-transition"] {
                XCTAssertEqual(name, "data-scroll-transition")
            } else {
                XCTFail("Expected data-scroll-transition attribute")
            }

            // Check for initial phase
            if case .attribute(let name, let value) = vnode.props["data-scroll-phase"] {
                XCTAssertEqual(name, "data-scroll-phase")
                XCTAssertEqual(value, "identity")
            } else {
                XCTFail("Expected data-scroll-phase attribute")
            }

            // Check for CSS class
            if case .attribute(let name, let value) = vnode.props["class"] {
                XCTAssertEqual(name, "class")
                XCTAssertEqual(value, "raven-scroll-transition")
            } else {
                XCTFail("Expected class attribute")
            }

            // Check for transition style
            if case .style(let name, let value) = vnode.props["transition"] {
                XCTAssertEqual(name, "transition")
                XCTAssertEqual(value, "all 0.3s ease-in-out")
            } else {
                XCTFail("Expected transition style")
            }

            // Check for will-change hint
            if case .style(let name, let value) = vnode.props["will-change"] {
                XCTAssertEqual(name, "will-change")
                XCTAssertEqual(value, "transform, opacity")
            } else {
                XCTFail("Expected will-change style")
            }
        } else {
            XCTFail("Expected element VNode")
        }
    }

    @MainActor
    func testScrollTransitionVNodeWithVerticalAxis() {
        // Test VNode generation with vertical axis
        let baseView = Text("Content")
        let transitionView = _ScrollTransitionView(
            content: baseView,
            configuration: ScrollTransitionConfiguration(axis: .vertical)
        )
        let vnode = transitionView.toVNode()

        // Verify it's an element
        if case .element(let tag) = vnode.type {
            XCTAssertEqual(tag, "div")

            // Check for axis data attribute
            if case .attribute(let name, let value) = vnode.props["data-scroll-axis"] {
                XCTAssertEqual(name, "data-scroll-axis")
                XCTAssertEqual(value, "vertical")
            } else {
                XCTFail("Expected data-scroll-axis attribute")
            }
        } else {
            XCTFail("Expected element VNode")
        }
    }

    @MainActor
    func testScrollTransitionVNodeWithHorizontalAxis() {
        // Test VNode generation with horizontal axis
        let baseView = Text("Content")
        let transitionView = _ScrollTransitionView(
            content: baseView,
            configuration: ScrollTransitionConfiguration(axis: .horizontal)
        )
        let vnode = transitionView.toVNode()

        // Verify it's an element
        if case .element(let tag) = vnode.type {
            XCTAssertEqual(tag, "div")

            // Check for axis data attribute
            if case .attribute(let name, let value) = vnode.props["data-scroll-axis"] {
                XCTAssertEqual(name, "data-scroll-axis")
                XCTAssertEqual(value, "horizontal")
            } else {
                XCTFail("Expected data-scroll-axis attribute")
            }
        } else {
            XCTFail("Expected element VNode")
        }
    }

    @MainActor
    func testScrollTransitionVNodeWithoutAxis() {
        // Test VNode generation without axis (should not have axis attribute)
        let baseView = Text("Content")
        let transitionView = _ScrollTransitionView(
            content: baseView,
            configuration: ScrollTransitionConfiguration(axis: nil)
        )
        let vnode = transitionView.toVNode()

        // Verify it's an element
        if case .element(let tag) = vnode.type {
            XCTAssertEqual(tag, "div")

            // Should NOT have axis data attribute
            XCTAssertNil(vnode.props["data-scroll-axis"])
        } else {
            XCTFail("Expected element VNode")
        }
    }

    // MARK: - Common Pattern Tests

    @MainActor
    func testFadeTransitionPattern() {
        // Test fade in/out pattern
        let view = Text("Content")
            .scrollTransition { content, phase in
                content.opacity(phase.isIdentity ? 1 : 0)
            }

        // Should compile without errors
        let _ = view
    }

    @MainActor
    func testScaleTransitionPattern() {
        // Test scale effect pattern
        let view = Text("Content")
            .scrollTransition { content, phase in
                content.scaleEffect(phase.isIdentity ? 1 : 0.75)
            }

        // Should compile without errors
        let _ = view
    }

    @MainActor
    func testCombinedTransitionPattern() {
        // Test combined animations pattern
        let view = Text("Content")
            .scrollTransition { content, phase in
                content
                    .opacity(phase.isIdentity ? 1 : 0)
                    .scaleEffect(phase.isIdentity ? 1 : 0.8)
                    .offset(y: phase == .topLeading ? -50 : 0)
            }

        // Should compile without errors
        let _ = view
    }

    @MainActor
    func testBlurTransitionPattern() {
        // Test blur effect pattern
        let view = Text("Content")
            .scrollTransition { content, phase in
                content
                    .blur(radius: phase.isIdentity ? 0 : 10)
                    .brightness(phase.isIdentity ? 1 : 0.7)
            }

        // Should compile without errors
        let _ = view
    }

    // MARK: - Integration Tests

    @MainActor
    func testScrollTransitionWithOtherModifiers() {
        // Test scroll transition combined with other modifiers
        let view = Text("Content")
            .padding(16)
            .scrollTransition { content, phase in
                content.opacity(phase.isIdentity ? 1 : 0)
            }
            .frame(width: 200)

        // Should compile and chain correctly
        let _ = view
    }

    @MainActor
    func testMultipleScrollTransitions() {
        // Test multiple scroll transitions on the same view
        let view = Text("Content")
            .scrollTransition(axis: .horizontal) { content, phase in
                content.offset(x: phase == .topLeading ? -30 : 0)
            }
            .scrollTransition(axis: .vertical) { content, phase in
                content.opacity(phase.isIdentity ? 1 : 0.5)
            }

        // Should compile and chain correctly
        let _ = view
    }

    @MainActor
    func testScrollTransitionInScrollView() {
        // Test realistic usage in a scroll view context
        struct Item: Identifiable {
            let id: Int
            let name: String
        }

        let items = [
            Item(id: 1, name: "First"),
            Item(id: 2, name: "Second"),
            Item(id: 3, name: "Third")
        ]

        // This would be the typical pattern in a real app
        // Note: We're just testing compilation, not actual scrolling behavior
        let _ = items.map { item in
            Text(item.name)
                .scrollTransition { content, phase in
                    content
                        .opacity(phase.isIdentity ? 1 : 0)
                        .scaleEffect(phase.isIdentity ? 1 : 0.75)
                }
        }
    }

    // MARK: - Phase-Specific Tests

    @MainActor
    func testTopLeadingPhaseTransition() {
        // Test transition specific to topLeading phase
        let view = Text("Content")
            .scrollTransition { content, phase in
                content.offset(y: phase == .topLeading ? -50 : 0)
            }

        // Should compile without errors
        let _ = view
    }

    @MainActor
    func testBottomTrailingPhaseTransition() {
        // Test transition specific to bottomTrailing phase
        let view = Text("Content")
            .scrollTransition { content, phase in
                content.offset(y: phase == .bottomTrailing ? 50 : 0)
            }

        // Should compile without errors
        let _ = view
    }

    @MainActor
    func testAllPhasesTransition() {
        // Test transition handling all three phases
        let view = Text("Content")
            .scrollTransition { content, phase in
                switch phase {
                case .topLeading:
                    return content.offset(y: -20).opacity(0.5)
                case .identity:
                    return content.offset(y: 0).opacity(1)
                case .bottomTrailing:
                    return content.offset(y: 20).opacity(0.5)
                }
            }

        // Should compile without errors
        let _ = view
    }

    // MARK: - Configuration Tests

    @MainActor
    func testScrollTransitionConfiguration() {
        // Test that configuration is created properly
        let config1 = ScrollTransitionConfiguration(axis: nil)
        let config2 = ScrollTransitionConfiguration(axis: .vertical)
        let config3 = ScrollTransitionConfiguration(axis: .horizontal)

        // Each configuration should have a unique ID
        XCTAssertNotEqual(config1.id, config2.id)
        XCTAssertNotEqual(config2.id, config3.id)
        XCTAssertNotEqual(config1.id, config3.id)

        // Test axis values
        XCTAssertNil(config1.axis)
        XCTAssertEqual(config2.axis, .vertical)
        XCTAssertEqual(config3.axis, .horizontal)
    }
}
