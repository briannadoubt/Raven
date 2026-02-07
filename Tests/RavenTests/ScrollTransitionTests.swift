import Testing
@testable import Raven

/// Tests for scroll transition modifier (.scrollTransition)
@MainActor
@Suite struct ScrollTransitionTests {

    // MARK: - ScrollTransitionPhase Tests

    @MainActor
    @Test func phaseEquality() {
        // Test that phases are properly equatable
        #expect(ScrollTransitionPhase.topLeading == ScrollTransitionPhase.topLeading)
        #expect(ScrollTransitionPhase.identity == ScrollTransitionPhase.identity)
        #expect(ScrollTransitionPhase.bottomTrailing == ScrollTransitionPhase.bottomTrailing)

        #expect(ScrollTransitionPhase.topLeading != ScrollTransitionPhase.identity)
        #expect(ScrollTransitionPhase.identity != ScrollTransitionPhase.bottomTrailing)
        #expect(ScrollTransitionPhase.topLeading != ScrollTransitionPhase.bottomTrailing)
    }

    @MainActor
    @Test func phaseIsIdentity() {
        // Test the isIdentity convenience property
        #expect(!ScrollTransitionPhase.topLeading.isIdentity)
        #expect(ScrollTransitionPhase.identity.isIdentity)
        #expect(!ScrollTransitionPhase.bottomTrailing.isIdentity)
    }

    // MARK: - Basic Transition Tests

    @MainActor
    @Test func basicScrollTransition() {
        // Test basic scroll transition without axis
        let view = Text("Content")
            .scrollTransition { content, phase in
                content.opacity(phase.isIdentity ? 1 : 0)
            }

        // Verify the type is correct
        #expect(view is _ScrollTransitionView<Text>)
    }

    @MainActor
    @Test func scrollTransitionWithAxis() {
        // Test scroll transition with explicit axis
        let view = Text("Content")
            .scrollTransition(axis: .vertical) { content, phase in
                content.scaleEffect(phase.isIdentity ? 1 : 0.8)
            }

        // Verify the type is correct
        #expect(view is _ScrollTransitionView<Text>)
    }

    @MainActor
    @Test func scrollTransitionWithHorizontalAxis() {
        // Test scroll transition with horizontal axis
        let view = Text("Content")
            .scrollTransition(axis: .horizontal) { content, phase in
                content.opacity(phase.isIdentity ? 1 : 0.5)
            }

        // Verify the type is correct
        #expect(view is _ScrollTransitionView<Text>)
    }

    @MainActor
    @Test func scrollTransitionWithNilAxis() {
        // Test scroll transition with explicit nil axis (same as basic)
        let view = Text("Content")
            .scrollTransition(axis: nil) { content, phase in
                content.blur(radius: phase.isIdentity ? 0 : 5)
            }

        // Verify the type is correct
        #expect(view is _ScrollTransitionView<Text>)
    }

    // MARK: - VNode Generation Tests

    @MainActor
    @Test func scrollTransitionVNode() {
        // Test VNode generation for basic scroll transition
        let baseView = Text("Content")
        let transitionView = _ScrollTransitionView(
            content: baseView,
            configuration: ScrollTransitionConfiguration(axis: nil)
        )
        let vnode = transitionView.toVNode()

        // Verify it's an element
        if case .element(let tag) = vnode.type {
            #expect(tag == "div")

            // Check for scroll transition data attribute
            if case .attribute(let name, _) = vnode.props["data-scroll-transition"] {
                #expect(name == "data-scroll-transition")
            } else {
                Issue.record("Expected data-scroll-transition attribute")
            }

            // Check for initial phase
            if case .attribute(let name, let value) = vnode.props["data-scroll-phase"] {
                #expect(name == "data-scroll-phase")
                #expect(value == "identity")
            } else {
                Issue.record("Expected data-scroll-phase attribute")
            }

            // Check for CSS class
            if case .attribute(let name, let value) = vnode.props["class"] {
                #expect(name == "class")
                #expect(value == "raven-scroll-transition")
            } else {
                Issue.record("Expected class attribute")
            }

            // Check for transition style
            if case .style(let name, let value) = vnode.props["transition"] {
                #expect(name == "transition")
                #expect(value == "all 0.3s ease-in-out")
            } else {
                Issue.record("Expected transition style")
            }

            // Check for will-change hint
            if case .style(let name, let value) = vnode.props["will-change"] {
                #expect(name == "will-change")
                #expect(value == "transform, opacity")
            } else {
                Issue.record("Expected will-change style")
            }
        } else {
            Issue.record("Expected element VNode")
        }
    }

    @MainActor
    @Test func scrollTransitionVNodeWithVerticalAxis() {
        // Test VNode generation with vertical axis
        let baseView = Text("Content")
        let transitionView = _ScrollTransitionView(
            content: baseView,
            configuration: ScrollTransitionConfiguration(axis: .vertical)
        )
        let vnode = transitionView.toVNode()

        // Verify it's an element
        if case .element(let tag) = vnode.type {
            #expect(tag == "div")

            // Check for axis data attribute
            if case .attribute(let name, let value) = vnode.props["data-scroll-axis"] {
                #expect(name == "data-scroll-axis")
                #expect(value == "vertical")
            } else {
                Issue.record("Expected data-scroll-axis attribute")
            }
        } else {
            Issue.record("Expected element VNode")
        }
    }

    @MainActor
    @Test func scrollTransitionVNodeWithHorizontalAxis() {
        // Test VNode generation with horizontal axis
        let baseView = Text("Content")
        let transitionView = _ScrollTransitionView(
            content: baseView,
            configuration: ScrollTransitionConfiguration(axis: .horizontal)
        )
        let vnode = transitionView.toVNode()

        // Verify it's an element
        if case .element(let tag) = vnode.type {
            #expect(tag == "div")

            // Check for axis data attribute
            if case .attribute(let name, let value) = vnode.props["data-scroll-axis"] {
                #expect(name == "data-scroll-axis")
                #expect(value == "horizontal")
            } else {
                Issue.record("Expected data-scroll-axis attribute")
            }
        } else {
            Issue.record("Expected element VNode")
        }
    }

    @MainActor
    @Test func scrollTransitionVNodeWithoutAxis() {
        // Test VNode generation without axis (should not have axis attribute)
        let baseView = Text("Content")
        let transitionView = _ScrollTransitionView(
            content: baseView,
            configuration: ScrollTransitionConfiguration(axis: nil)
        )
        let vnode = transitionView.toVNode()

        // Verify it's an element
        if case .element(let tag) = vnode.type {
            #expect(tag == "div")

            // Should NOT have axis data attribute
            #expect(vnode.props["data-scroll-axis"] == nil)
        } else {
            Issue.record("Expected element VNode")
        }
    }

    // MARK: - Common Pattern Tests

    @MainActor
    @Test func fadeTransitionPattern() {
        // Test fade in/out pattern
        let view = Text("Content")
            .scrollTransition { content, phase in
                content.opacity(phase.isIdentity ? 1 : 0)
            }

        // Should compile without errors
        let _ = view
    }

    @MainActor
    @Test func scaleTransitionPattern() {
        // Test scale effect pattern
        let view = Text("Content")
            .scrollTransition { content, phase in
                content.scaleEffect(phase.isIdentity ? 1 : 0.75)
            }

        // Should compile without errors
        let _ = view
    }

    @MainActor
    @Test func combinedTransitionPattern() {
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
    @Test func blurTransitionPattern() {
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
    @Test func scrollTransitionWithOtherModifiers() {
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
    @Test func multipleScrollTransitions() {
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
    @Test func scrollTransitionInScrollView() {
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
    @Test func topLeadingPhaseTransition() {
        // Test transition specific to topLeading phase
        let view = Text("Content")
            .scrollTransition { content, phase in
                content.offset(y: phase == .topLeading ? -50 : 0)
            }

        // Should compile without errors
        let _ = view
    }

    @MainActor
    @Test func bottomTrailingPhaseTransition() {
        // Test transition specific to bottomTrailing phase
        let view = Text("Content")
            .scrollTransition { content, phase in
                content.offset(y: phase == .bottomTrailing ? 50 : 0)
            }

        // Should compile without errors
        let _ = view
    }

    @MainActor
    @Test func allPhasesTransition() {
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
    @Test func scrollTransitionConfiguration() {
        // Test that configuration is created properly
        let config1 = ScrollTransitionConfiguration(axis: nil)
        let config2 = ScrollTransitionConfiguration(axis: .vertical)
        let config3 = ScrollTransitionConfiguration(axis: .horizontal)

        // Each configuration should have a unique ID
        #expect(config1.id != config2.id)
        #expect(config2.id != config3.id)
        #expect(config1.id != config3.id)

        // Test axis values
        #expect(config1.axis == nil)
        #expect(config2.axis == .vertical)
        #expect(config3.axis == .horizontal)
    }
}
