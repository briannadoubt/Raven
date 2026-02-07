import Testing
@testable import Raven

/// Tests for the animation modifier and value-based animation.
///
/// This test suite verifies:
/// - `.animation()` modifier with nil and non-nil animations
/// - `.animation(_:value:)` value-based animation
/// - CSS transition generation
/// - VNode property generation
/// - Animation timing and parameters
/// - Animation nesting and stacking
@MainActor
@Suite("Animation Modifier Tests")
struct AnimationModifierTests {

    // MARK: - Basic Animation Tests

    @Test("Animation modifier with nil creates view without transitions")
    @MainActor func animationWithNil() {
        let view = _AnimationView(
            content: Text("Hello"),
            animation: nil
        )

        let vnode = view.toVNode()

        // Should have animated marker even with nil animation
        #expect(vnode.props["data-animated"] != nil)

        // Should NOT have transition style
        #expect(vnode.props["transition"] == nil)

        // Should NOT have animation timing data attributes
        #expect(vnode.props["data-animation-duration"] == nil)
        #expect(vnode.props["data-animation-timing"] == nil)
    }

    @Test("Animation modifier with default animation generates CSS transition")
    @MainActor
    func animationWithDefault() {
        let view = _AnimationView(
            content: Text("Hello"),
            animation: .default
        )

        let vnode = view.toVNode()

        // Should have animated marker
        if case .attribute(let name, let value) = vnode.props["data-animated"] {
            #expect(name == "data-animated")
            #expect(value == "true")
        } else {
            Issue.record("Expected data-animated attribute")
        }

        // Should have transition style
        #expect(vnode.props["transition"] != nil)

        // Verify transition includes proper values
        if case .style(let name, let value) = vnode.props["transition"] {
            #expect(name == "transition")
            #expect(value.contains("all"))
            #expect(value.contains("0.35s"))
            #expect(value.contains("ease-in-out"))
        } else {
            Issue.record("Expected transition style property")
        }

        // Should have duration attribute
        if case .attribute(let name, let value) = vnode.props["data-animation-duration"] {
            #expect(name == "data-animation-duration")
            #expect(value == "0.35s")
        } else {
            Issue.record("Expected data-animation-duration attribute")
        }

        // Should have timing attribute
        if case .attribute(let name, let value) = vnode.props["data-animation-timing"] {
            #expect(name == "data-animation-timing")
            #expect(value == "ease-in-out")
        } else {
            Issue.record("Expected data-animation-timing attribute")
        }
    }

    @Test("Animation modifier with linear animation")
    @MainActor
    func animationWithLinear() {
        let view = _AnimationView(
            content: Text("Hello"),
            animation: .linear
        )

        let vnode = view.toVNode()

        // Verify timing function is linear
        if case .attribute(_, let value) = vnode.props["data-animation-timing"] {
            #expect(value == "linear")
        } else {
            Issue.record("Expected data-animation-timing attribute")
        }

        // Verify transition contains linear
        if case .style(_, let value) = vnode.props["transition"] {
            #expect(value.contains("linear"))
        } else {
            Issue.record("Expected transition style property")
        }
    }

    @Test("Animation modifier with spring animation")
    @MainActor
    func animationWithSpring() {
        let view = _AnimationView(
            content: Text("Hello"),
            animation: .spring()
        )

        let vnode = view.toVNode()

        // Spring should generate cubic-bezier
        if case .attribute(_, let value) = vnode.props["data-animation-timing"] {
            #expect(value.contains("cubic-bezier"))
        } else {
            Issue.record("Expected data-animation-timing attribute")
        }

        // Verify transition contains cubic-bezier
        if case .style(_, let value) = vnode.props["transition"] {
            #expect(value.contains("cubic-bezier"))
        } else {
            Issue.record("Expected transition style property")
        }
    }

    @Test("Animation modifier with custom timing curve")
    @MainActor
    func animationWithCustomCurve() {
        let animation = Animation.timingCurve(0.17, 0.67, 0.83, 0.67, duration: 0.4)
        let view = _AnimationView(
            content: Text("Hello"),
            animation: animation
        )

        let vnode = view.toVNode()

        // Should have correct duration
        if case .attribute(_, let value) = vnode.props["data-animation-duration"] {
            #expect(value == "0.4s")
        } else {
            Issue.record("Expected data-animation-duration attribute")
        }

        // Should have cubic-bezier with correct control points
        if case .attribute(_, let value) = vnode.props["data-animation-timing"] {
            #expect(value.contains("0.17"))
            #expect(value.contains("0.67"))
            #expect(value.contains("0.83"))
        } else {
            Issue.record("Expected data-animation-timing attribute")
        }
    }

    @Test("Animation modifier with delay")
    @MainActor
    func animationWithDelay() {
        let animation = Animation.default.delay(0.5)
        let view = _AnimationView(
            content: Text("Hello"),
            animation: animation
        )

        let vnode = view.toVNode()

        // Transition should include delay
        if case .style(_, let value) = vnode.props["transition"] {
            #expect(value.contains("0.5s"))
        } else {
            Issue.record("Expected transition style property")
        }
    }

    @Test("Animation modifier with speed multiplier")
    @MainActor
    func animationWithSpeed() {
        let animation = Animation.default.speed(2.0)
        let view = _AnimationView(
            content: Text("Hello"),
            animation: animation
        )

        let vnode = view.toVNode()

        // Duration should be halved (0.35 / 2.0 = 0.175)
        if case .attribute(_, let value) = vnode.props["data-animation-duration"] {
            #expect(value == "0.175s")
        } else {
            Issue.record("Expected data-animation-duration attribute")
        }
    }

    @Test("Animation modifier with combined modifiers")
    @MainActor
    func animationWithCombinedModifiers() {
        let animation = Animation.easeIn
            .delay(0.2)
            .speed(1.5)
        let view = _AnimationView(
            content: Text("Hello"),
            animation: animation
        )

        let vnode = view.toVNode()

        // Should have ease-in timing
        if case .attribute(_, let value) = vnode.props["data-animation-timing"] {
            #expect(value == "ease-in")
        } else {
            Issue.record("Expected data-animation-timing attribute")
        }

        // Transition should include delay
        if case .style(_, let value) = vnode.props["transition"] {
            #expect(value.contains("0.2s"))
        } else {
            Issue.record("Expected transition style property")
        }

        // Duration should reflect speed multiplier
        if case .attribute(_, let value) = vnode.props["data-animation-duration"] {
            // 0.35 / 1.5 ≈ 0.233s
            #expect(value.hasPrefix("0.2"))
        } else {
            Issue.record("Expected data-animation-duration attribute")
        }
    }

    // MARK: - Value-Based Animation Tests

    @Test("Value-based animation creates correct VNode")
    @MainActor
    func valueBasedAnimationCreatesVNode() {
        let view = _ValueAnimationView(
            content: Text("Hello"),
            animation: .default,
            value: 42
        )

        let vnode = view.toVNode()

        // Should have animated marker
        #expect(vnode.props["data-animated"] != nil)

        // Should have value-based marker
        if case .attribute(let name, let value) = vnode.props["data-animation-value-based"] {
            #expect(name == "data-animation-value-based")
            #expect(value == "true")
        } else {
            Issue.record("Expected data-animation-value-based attribute")
        }

        // Should have value hash
        #expect(vnode.props["data-animation-value-hash"] != nil)
    }

    @Test("Value-based animation stores value hash")
    @MainActor
    func valueBasedAnimationStoresHash() {
        let value = "test-value"
        let view = _ValueAnimationView(
            content: Text("Hello"),
            animation: .default,
            value: value
        )

        let vnode = view.toVNode()

        if case .attribute(let name, let attrValue) = vnode.props["data-animation-value-hash"] {
            #expect(name == "data-animation-value-hash")
            #expect(attrValue == "\(value)")
        } else {
            Issue.record("Expected data-animation-value-hash attribute")
        }
    }

    @Test("Value-based animation with different value types")
    @MainActor
    func valueBasedAnimationWithDifferentTypes() {
        // Test with Int
        let intView = _ValueAnimationView(
            content: Text("Hello"),
            animation: .default,
            value: 100
        )
        #expect(intView.toVNode().props["data-animation-value-hash"] != nil)

        // Test with String
        let stringView = _ValueAnimationView(
            content: Text("Hello"),
            animation: .default,
            value: "test"
        )
        #expect(stringView.toVNode().props["data-animation-value-hash"] != nil)

        // Test with Bool
        let boolView = _ValueAnimationView(
            content: Text("Hello"),
            animation: .default,
            value: true
        )
        #expect(boolView.toVNode().props["data-animation-value-hash"] != nil)

        // Test with Double
        let doubleView = _ValueAnimationView(
            content: Text("Hello"),
            animation: .default,
            value: 3.14
        )
        #expect(doubleView.toVNode().props["data-animation-value-hash"] != nil)
    }

    @Test("Value-based animation with nil animation")
    @MainActor
    func valueBasedAnimationWithNil() {
        let view = _ValueAnimationView(
            content: Text("Hello"),
            animation: nil,
            value: 42
        )

        let vnode = view.toVNode()

        // Should have animated marker
        #expect(vnode.props["data-animated"] != nil)

        // Should have value-based marker
        #expect(vnode.props["data-animation-value-based"] != nil)

        // Should NOT have transition
        #expect(vnode.props["transition"] == nil)

        // Should NOT have animation timing attributes
        #expect(vnode.props["data-animation-duration"] == nil)
        #expect(vnode.props["data-animation-timing"] == nil)
    }

    @Test("Value-based animation hash changes with value")
    @MainActor
    func valueBasedAnimationHashChanges() {
        let view1 = _ValueAnimationView(
            content: Text("Hello"),
            animation: .default,
            value: 1
        )

        let view2 = _ValueAnimationView(
            content: Text("Hello"),
            animation: .default,
            value: 2
        )

        let vnode1 = view1.toVNode()
        let vnode2 = view2.toVNode()

        // Extract hash values
        var hash1: String?
        var hash2: String?

        if case .attribute(_, let value) = vnode1.props["data-animation-value-hash"] {
            hash1 = value
        }

        if case .attribute(_, let value) = vnode2.props["data-animation-value-hash"] {
            hash2 = value
        }

        // Hashes should be different for different values
        #expect(hash1 != nil)
        #expect(hash2 != nil)
        #expect(hash1 != hash2)
    }

    // MARK: - View Extension Tests

    @Test("View extension animation() creates AnimationView")
    @MainActor
    func viewExtensionAnimation() {
        let base = Text("Hello")
        let animated = base.animation(.default)

        // Type should be _AnimationView
        #expect(animated is _AnimationView<Text>)

        // Should generate proper VNode
        let vnode = animated.toVNode()
        #expect(vnode.props["data-animated"] != nil)
        #expect(vnode.props["transition"] != nil)
    }

    @Test("View extension animation with value creates ValueAnimationView")
    @MainActor
    func viewExtensionAnimationWithValue() {
        let base = Text("Hello")
        let animated = base.animation(.default, value: 42)

        // Type should be _ValueAnimationView
        #expect(animated is _ValueAnimationView<Text, Int>)

        // Should generate proper VNode
        let vnode = animated.toVNode()
        #expect(vnode.props["data-animated"] != nil)
        #expect(vnode.props["data-animation-value-based"] != nil)
        #expect(vnode.props["data-animation-value-hash"] != nil)
    }

    @Test("View extension animation with nil")
    @MainActor
    func viewExtensionAnimationNil() {
        let base = Text("Hello")
        let animated = base.animation(nil)

        let vnode = animated.toVNode()

        // Should have marker but no transition
        #expect(vnode.props["data-animated"] != nil)
        #expect(vnode.props["transition"] == nil)
    }

    @Test("View extension animation stacking")
    @MainActor
    func viewExtensionAnimationStacking() {
        let base = Text("Hello")
        let animated1 = base.animation(.default)
        let animated2 = animated1.animation(.spring())

        // Both should be animation views
        #expect(animated1 is _AnimationView<Text>)
        #expect(animated2 is _AnimationView<_AnimationView<Text>>)

        // Inner animation should use spring
        let vnode = animated2.toVNode()
        if case .attribute(_, let value) = vnode.props["data-animation-timing"] {
            #expect(value.contains("cubic-bezier"))
        } else {
            Issue.record("Expected spring animation (cubic-bezier)")
        }
    }

    // MARK: - Animation Type Integration Tests

    @Test("Animation modifier works with all animation types")
    @MainActor
    func animationModifierWithAllTypes() {
        let animations: [Animation] = [
            .default,
            .linear,
            .easeIn,
            .easeOut,
            .easeInOut,
            .spring(),
            .spring(response: 0.3, dampingFraction: 0.6),
            .timingCurve(0.4, 0.0, 0.2, 1.0, duration: 0.3)
        ]

        for animation in animations {
            let view = _AnimationView(
                content: Text("Test"),
                animation: animation
            )

            let vnode = view.toVNode()

            // All should have transition
            #expect(vnode.props["transition"] != nil)

            // All should have timing
            #expect(vnode.props["data-animation-timing"] != nil)

            // All should have duration
            #expect(vnode.props["data-animation-duration"] != nil)
        }
    }

    @Test("Animation modifier with repeat count")
    @MainActor
    func animationModifierWithRepeat() {
        let animation = Animation.linear.repeatCount(3)
        let view = _AnimationView(
            content: Text("Hello"),
            animation: animation
        )

        let vnode = view.toVNode()

        // Should still generate transition (repeats are for keyframe animations)
        #expect(vnode.props["transition"] != nil)

        // Note: Repeat count affects keyframe animations, not transitions
        // For transitions, this would need special handling in the runtime
    }

    @Test("Animation modifier with repeatForever")
    @MainActor
    func animationModifierWithRepeatForever() {
        let animation = Animation.linear.repeatForever(autoreverses: true)
        let view = _AnimationView(
            content: Text("Hello"),
            animation: animation
        )

        let vnode = view.toVNode()

        // Should still generate transition
        #expect(vnode.props["transition"] != nil)
    }

    // MARK: - CSS Generation Tests

    @Test("Animation generates valid CSS transition syntax")
    @MainActor
    func animationGeneratesValidCSS() {
        let view = _AnimationView(
            content: Text("Hello"),
            animation: .easeInOut
        )

        let vnode = view.toVNode()

        if case .style(_, let value) = vnode.props["transition"] {
            // CSS transition format: property duration timing-function delay
            let parts = value.split(separator: " ")
            #expect(parts.count >= 3)  // At minimum: property, duration, timing

            // First part should be property
            #expect(parts[0] == "all")

            // Second part should be duration (ends with 's')
            #expect(parts[1].hasSuffix("s"))

            // Third part should be timing function
            #expect(parts[2].contains("ease") || parts[2].contains("linear") || parts[2].contains("cubic-bezier"))
        } else {
            Issue.record("Expected transition style property")
        }
    }

    @Test("VNode is an element node")
    @MainActor
    func vnodeIsElement() {
        let view = _AnimationView(
            content: Text("Hello"),
            animation: .default
        )

        let vnode = view.toVNode()

        // Should be a div element
        #expect(vnode.isElement(tag: "div"))
    }

    @Test("VNode has no children")
    @MainActor
    func vnodeHasNoChildren() {
        let view = _AnimationView(
            content: Text("Hello"),
            animation: .default
        )

        let vnode = view.toVNode()

        // Children array should be empty (content rendered separately)
        #expect(vnode.children.isEmpty)
    }
}
