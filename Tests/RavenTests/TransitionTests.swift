import Testing
@testable import Raven

/// Tests for transition types and the transition modifier.
///
/// This test suite verifies:
/// - All basic transition types (.identity, .opacity, .scale, .slide, .move, .offset)
/// - Transition composition (.combined)
/// - Asymmetric transitions
/// - CSS animation generation
/// - Edge and UnitPoint types
@MainActor
@Suite("Transition Tests")
struct TransitionTests {

    // MARK: - Edge Tests

    @Test("Edge enum has all four directions")
    func edgeEnumCases() {
        let allEdges: [Edge] = [.top, .bottom, .leading, .trailing]
        #expect(allEdges.count == 4)
        #expect(Edge.allCases.count == 4)
    }

    @Test("Edge.Set has correct option set values")
    func edgeSetOptionSet() {
        let horizontal: Edge.Set = [.leading, .trailing]
        let vertical: Edge.Set = [.top, .bottom]
        let all: Edge.Set = .all

        #expect(horizontal.contains(.leading))
        #expect(horizontal.contains(.trailing))
        #expect(!horizontal.contains(.top))

        #expect(vertical.contains(.top))
        #expect(vertical.contains(.bottom))
        #expect(!vertical.contains(.leading))

        #expect(all.contains(.top))
        #expect(all.contains(.bottom))
        #expect(all.contains(.leading))
        #expect(all.contains(.trailing))
    }

    @Test("Edge provides CSS transform axis")
    func edgeCSSTransformAxis() {
        #expect(Edge.top.cssTransformAxis == "translateY(-100%)")
        #expect(Edge.bottom.cssTransformAxis == "translateY(100%)")
        #expect(Edge.leading.cssTransformAxis == "translateX(-100%)")
        #expect(Edge.trailing.cssTransformAxis == "translateX(100%)")
    }

    @Test("Edge provides opposite edge")
    func edgeOpposite() {
        #expect(Edge.top.opposite == .bottom)
        #expect(Edge.bottom.opposite == .top)
        #expect(Edge.leading.opposite == .trailing)
        #expect(Edge.trailing.opposite == .leading)
    }

    // MARK: - UnitPoint Tests

    @Test("UnitPoint initializes with x and y")
    func unitPointInit() {
        let point = UnitPoint(x: 0.25, y: 0.75)
        #expect(point.x == 0.25)
        #expect(point.y == 0.75)
    }

    @Test("UnitPoint common values are correct")
    func unitPointCommonValues() {
        #expect(UnitPoint.zero.x == 0 && UnitPoint.zero.y == 0)
        #expect(UnitPoint.center.x == 0.5 && UnitPoint.center.y == 0.5)
        #expect(UnitPoint.top.x == 0.5 && UnitPoint.top.y == 0)
        #expect(UnitPoint.bottom.x == 0.5 && UnitPoint.bottom.y == 1)
        #expect(UnitPoint.leading.x == 0 && UnitPoint.leading.y == 0.5)
        #expect(UnitPoint.trailing.x == 1 && UnitPoint.trailing.y == 0.5)
        #expect(UnitPoint.topLeading.x == 0 && UnitPoint.topLeading.y == 0)
        #expect(UnitPoint.topTrailing.x == 1 && UnitPoint.topTrailing.y == 0)
        #expect(UnitPoint.bottomLeading.x == 0 && UnitPoint.bottomLeading.y == 1)
        #expect(UnitPoint.bottomTrailing.x == 1 && UnitPoint.bottomTrailing.y == 1)
    }

    @Test("UnitPoint generates correct CSS transform-origin")
    func unitPointCSSTransformOrigin() {
        #expect(UnitPoint.center.cssTransformOrigin == "50.0% 50.0%")
        #expect(UnitPoint.topLeading.cssTransformOrigin == "0.0% 0.0%")
        #expect(UnitPoint.bottomTrailing.cssTransformOrigin == "100.0% 100.0%")

        let custom = UnitPoint(x: 0.25, y: 0.75)
        #expect(custom.cssTransformOrigin == "25.0% 75.0%")
    }

    // MARK: - Basic Transition Tests

    @Test("Identity transition creates correct type")
    func identityTransition() {
        let transition = AnyTransition.identity

        if case .identity = transition.storage {
            // Success
        } else {
            Issue.record("Expected identity transition")
        }

        #expect(transition.cssInsertionAnimation() == "none")
        #expect(transition.cssRemovalAnimation() == "none")
        #expect(transition.cssKeyframes() == "")
    }

    @Test("Opacity transition creates correct type")
    func opacityTransition() {
        let transition = AnyTransition.opacity

        if case .opacity = transition.storage {
            // Success
        } else {
            Issue.record("Expected opacity transition")
        }

        #expect(transition.cssInsertionAnimation() == "fadeIn")
        #expect(transition.cssRemovalAnimation() == "fadeOut")
        #expect(transition.cssKeyframes().contains("@keyframes fadeIn"))
        #expect(transition.cssKeyframes().contains("@keyframes fadeOut"))
        #expect(transition.cssKeyframes().contains("opacity: 0"))
        #expect(transition.cssKeyframes().contains("opacity: 1"))
    }

    @Test("Scale transition with default parameters")
    func scaleTransitionDefault() {
        let transition = AnyTransition.scale()

        if case .scale(let scale, let anchor) = transition.storage {
            #expect(scale == 0.0)
            #expect(anchor.x == 0.5 && anchor.y == 0.5) // center
        } else {
            Issue.record("Expected scale transition")
        }

        #expect(transition.cssInsertionAnimation() == "scaleIn")
        #expect(transition.cssRemovalAnimation() == "scaleOut")
        #expect(transition.cssKeyframes().contains("@keyframes scaleIn"))
        #expect(transition.cssKeyframes().contains("transform: scale(0.0)"))
        #expect(transition.cssKeyframes().contains("transform: scale(1)"))
        #expect(transition.cssTransformOrigin() == "50.0% 50.0%")
    }

    @Test("Scale transition with custom parameters")
    func scaleTransitionCustom() {
        let transition = AnyTransition.scale(scale: 0.5, anchor: .topLeading)

        if case .scale(let scale, let anchor) = transition.storage {
            #expect(scale == 0.5)
            #expect(anchor.x == 0 && anchor.y == 0)
        } else {
            Issue.record("Expected scale transition")
        }

        #expect(transition.cssKeyframes().contains("transform: scale(0.5)"))
        #expect(transition.cssTransformOrigin() == "0.0% 0.0%")
    }

    @Test("Slide transition")
    func slideTransition() {
        let transition = AnyTransition.slide

        if case .slide = transition.storage {
            // Success
        } else {
            Issue.record("Expected slide transition")
        }

        #expect(transition.cssInsertionAnimation() == "slideIn")
        #expect(transition.cssRemovalAnimation() == "slideOut")
        #expect(transition.cssKeyframes().contains("@keyframes slideIn"))
        #expect(transition.cssKeyframes().contains("translateY(100%)"))
        #expect(transition.cssKeyframes().contains("translateY(0)"))
    }

    @Test("Move transition from top edge")
    func moveTransitionTop() {
        let transition = AnyTransition.move(edge: .top)

        if case .move(let edge) = transition.storage {
            #expect(edge == .top)
        } else {
            Issue.record("Expected move transition")
        }

        #expect(transition.cssKeyframes().contains("translateY(-100%)"))
    }

    @Test("Move transition from bottom edge")
    func moveTransitionBottom() {
        let transition = AnyTransition.move(edge: .bottom)

        if case .move(let edge) = transition.storage {
            #expect(edge == .bottom)
        } else {
            Issue.record("Expected move transition")
        }

        #expect(transition.cssKeyframes().contains("translateY(100%)"))
    }

    @Test("Move transition from leading edge")
    func moveTransitionLeading() {
        let transition = AnyTransition.move(edge: .leading)

        if case .move(let edge) = transition.storage {
            #expect(edge == .leading)
        } else {
            Issue.record("Expected move transition")
        }

        #expect(transition.cssKeyframes().contains("translateX(-100%)"))
    }

    @Test("Move transition from trailing edge")
    func moveTransitionTrailing() {
        let transition = AnyTransition.move(edge: .trailing)

        if case .move(let edge) = transition.storage {
            #expect(edge == .trailing)
        } else {
            Issue.record("Expected move transition")
        }

        #expect(transition.cssKeyframes().contains("translateX(100%)"))
    }

    @Test("Offset transition with default parameters")
    func offsetTransitionDefault() {
        let transition = AnyTransition.offset()

        if case .offset(let x, let y) = transition.storage {
            #expect(x == 0)
            #expect(y == 0)
        } else {
            Issue.record("Expected offset transition")
        }

        #expect(transition.cssInsertionAnimation() == "offsetIn")
        #expect(transition.cssRemovalAnimation() == "offsetOut")
    }

    @Test("Offset transition with custom values")
    func offsetTransitionCustom() {
        let transition = AnyTransition.offset(x: 50, y: -100)

        if case .offset(let x, let y) = transition.storage {
            #expect(x == 50)
            #expect(y == -100)
        } else {
            Issue.record("Expected offset transition")
        }

        #expect(transition.cssKeyframes().contains("translate(50.0px, -100.0px)"))
        #expect(transition.cssKeyframes().contains("translate(0, 0)"))
    }

    // MARK: - Transition Composition Tests

    @Test("Combined transition creates correct type")
    func combinedTransition() {
        let transition = AnyTransition.opacity.combined(with: .scale())

        if case .combined(let first, let second) = transition.storage {
            if case .opacity = first.storage {
                // Success
            } else {
                Issue.record("Expected first transition to be opacity")
            }

            if case .scale = second.storage {
                // Success
            } else {
                Issue.record("Expected second transition to be scale")
            }
        } else {
            Issue.record("Expected combined transition")
        }

        let insertionAnim = transition.cssInsertionAnimation()
        #expect(insertionAnim.contains("fadeIn"))
        #expect(insertionAnim.contains("scaleIn"))

        let removalAnim = transition.cssRemovalAnimation()
        #expect(removalAnim.contains("fadeOut"))
        #expect(removalAnim.contains("scaleOut"))
    }

    @Test("Multiple combined transitions")
    func multipleCombinedTransitions() {
        let transition = AnyTransition.opacity
            .combined(with: .scale())
            .combined(with: .offset(x: 0, y: 20))

        // Should have nested combined structures
        if case .combined = transition.storage {
            // Success
        } else {
            Issue.record("Expected combined transition")
        }

        let insertionAnim = transition.cssInsertionAnimation()
        #expect(insertionAnim.contains("fadeIn"))
        #expect(insertionAnim.contains("scaleIn"))
        #expect(insertionAnim.contains("offsetIn"))
    }

    @Test("Combined transition preserves transform-origin")
    func combinedTransitionTransformOrigin() {
        let transition = AnyTransition.scale(scale: 0.5, anchor: .bottomTrailing)
            .combined(with: .opacity)

        #expect(transition.cssTransformOrigin() == "100.0% 100.0%")
    }

    // MARK: - Asymmetric Transition Tests

    @Test("Asymmetric transition creates correct type")
    func asymmetricTransition() {
        let transition = AnyTransition.asymmetric(
            insertion: .move(edge: .trailing),
            removal: .opacity
        )

        if case .asymmetric(let insertion, let removal) = transition.storage {
            if case .move(let edge) = insertion.storage {
                #expect(edge == .trailing)
            } else {
                Issue.record("Expected insertion to be move")
            }

            if case .opacity = removal.storage {
                // Success
            } else {
                Issue.record("Expected removal to be opacity")
            }
        } else {
            Issue.record("Expected asymmetric transition")
        }
    }

    @Test("Asymmetric transition uses correct animations")
    func asymmetricTransitionAnimations() {
        let transition = AnyTransition.asymmetric(
            insertion: .scale(),
            removal: .slide
        )

        #expect(transition.cssInsertionAnimation() == "scaleIn")
        #expect(transition.cssRemovalAnimation() == "slideOut")

        let keyframes = transition.cssKeyframes()
        #expect(keyframes.contains("@keyframes scaleIn"))
        #expect(keyframes.contains("@keyframes slideOut"))
    }

    @Test("Asymmetric transition with combined effects")
    func asymmetricTransitionWithCombined() {
        let transition = AnyTransition.asymmetric(
            insertion: .opacity.combined(with: .scale()),
            removal: .move(edge: .bottom)
        )

        let insertionAnim = transition.cssInsertionAnimation()
        #expect(insertionAnim.contains("fadeIn"))
        #expect(insertionAnim.contains("scaleIn"))

        #expect(transition.cssRemovalAnimation() == "slideOut")
    }

    // MARK: - Transition Modifier Tests

    @Test("Transition modifier can be applied to view")
    @MainActor func transitionModifier() {
        let view = Text("Hello")
            .transition(.opacity)

        // Verify the modifier wraps the view
        #expect(view is _TransitionView<Text>)
    }

    @Test("Transition view generates VNode with attributes")
    @MainActor func transitionViewVNode() {
        let view = Text("Hello")
            .transition(.opacity)

        let vnode = view.toVNode()

        // Check for transition data attributes
        if case .element = vnode.type {
            #expect(vnode.props["data-transition"] != nil)
            #expect(vnode.props["data-transition-in"] != nil)
            #expect(vnode.props["data-transition-out"] != nil)
        } else {
            Issue.record("Expected element VNode")
        }
    }

    @Test("Identity transition doesn't add animation attributes")
    @MainActor func identityTransitionVNode() {
        let view = Text("Hello")
            .transition(.identity)

        let vnode = view.toVNode()

        // Identity transition should not add animation attributes
        if let transitionIn = vnode.props["data-transition-in"] {
            if case .attribute(_, let value) = transitionIn {
                #expect(value == "none" || value.isEmpty)
            }
        }
    }

    @Test("Scale transition includes transform-origin")
    @MainActor func scaleTransitionIncludesTransformOrigin() {
        let view = Text("Hello")
            .transition(.scale(anchor: .topLeading))

        let vnode = view.toVNode()

        // Check for transform-origin style
        if let transformOrigin = vnode.props["transform-origin"] {
            if case .style(_, let value) = transformOrigin {
                #expect(value.contains("0.0%"))
            }
        } else {
            Issue.record("Expected transform-origin style")
        }
    }

    // MARK: - Transition Description Tests

    @Test("Transitions have readable descriptions")
    func transitionDescriptions() {
        #expect(AnyTransition.identity.description.contains("identity"))
        #expect(AnyTransition.opacity.description.contains("opacity"))
        #expect(AnyTransition.scale().description.contains("scale"))
        #expect(AnyTransition.slide.description.contains("slide"))
        #expect(AnyTransition.move(edge: .top).description.contains("move"))
        #expect(AnyTransition.offset(x: 10, y: 20).description.contains("offset"))
    }

    @Test("Combined transition description shows both parts")
    func combinedTransitionDescription() {
        let transition = AnyTransition.opacity.combined(with: .scale())
        let description = transition.description

        #expect(description.contains("opacity"))
        #expect(description.contains("scale"))
        #expect(description.contains("combined"))
    }

    @Test("Asymmetric transition description shows both parts")
    func asymmetricTransitionDescription() {
        let transition = AnyTransition.asymmetric(
            insertion: .move(edge: .leading),
            removal: .opacity
        )
        let description = transition.description

        #expect(description.contains("asymmetric"))
        #expect(description.contains("move"))
        #expect(description.contains("opacity"))
    }

    // MARK: - Equality and Hashing Tests

    @Test("Identical transitions are equal")
    func transitionEquality() {
        #expect(AnyTransition.identity == AnyTransition.identity)
        #expect(AnyTransition.opacity == AnyTransition.opacity)
        #expect(AnyTransition.slide == AnyTransition.slide)
        #expect(AnyTransition.scale() == AnyTransition.scale())
        #expect(AnyTransition.move(edge: .top) == AnyTransition.move(edge: .top))
        #expect(AnyTransition.offset(x: 10, y: 20) == AnyTransition.offset(x: 10, y: 20))
    }

    @Test("Different transitions are not equal")
    func transitionInequality() {
        #expect(AnyTransition.identity != AnyTransition.opacity)
        #expect(AnyTransition.scale(scale: 0.5) != AnyTransition.scale(scale: 0.8))
        #expect(AnyTransition.move(edge: .top) != AnyTransition.move(edge: .bottom))
        #expect(AnyTransition.offset(x: 10) != AnyTransition.offset(x: 20))
    }

    @Test("Transitions can be hashed")
    func transitionHashing() {
        let transitions: [AnyTransition] = [
            .identity,
            .opacity,
            .scale(),
            .slide,
            .move(edge: .top),
            .offset(x: 10, y: 20)
        ]

        let set = Set(transitions)
        #expect(set.count == transitions.count)
    }

    // MARK: - Edge Cases

    @Test("UnitPoint with extreme values")
    func unitPointExtremeValues() {
        let point = UnitPoint(x: -0.5, y: 1.5)
        #expect(point.x == -0.5)
        #expect(point.y == 1.5)
        // Should still generate valid CSS even with out-of-bounds values
        #expect(point.cssTransformOrigin == "-50.0% 150.0%")
    }

    @Test("Offset transition with zero values")
    func offsetTransitionZero() {
        let transition = AnyTransition.offset(x: 0, y: 0)

        if case .offset(let x, let y) = transition.storage {
            #expect(x == 0)
            #expect(y == 0)
        } else {
            Issue.record("Expected offset transition")
        }

        #expect(transition.cssKeyframes().contains("translate(0.0px, 0.0px)"))
    }

    @Test("Scale transition with scale of 1.0")
    func scaleTransitionIdentityScale() {
        let transition = AnyTransition.scale(scale: 1.0)

        if case .scale(let scale, _) = transition.storage {
            #expect(scale == 1.0)
        } else {
            Issue.record("Expected scale transition")
        }

        // Even with scale 1.0, should generate keyframes (though visually no effect)
        #expect(transition.cssKeyframes().contains("transform: scale(1.0)"))
    }
}
