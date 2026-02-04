import Testing
@testable import Raven

/// Tests for the Animation type system.
@Suite("Animation Tests")
struct AnimationTests {

    // MARK: - Standard Animation Tests

    @Test("Default animation has ease-in-out timing")
    func testDefaultAnimation() {
        let animation = Animation.default
        #expect(animation.cssTransitionTiming() == "ease-in-out")
        #expect(animation.cssDuration() == "0.35s")
        #expect(animation.cssDelay() == "0s")
    }

    @Test("Linear animation has linear timing")
    func testLinearAnimation() {
        let animation = Animation.linear
        #expect(animation.cssTransitionTiming() == "linear")
        #expect(animation.cssDuration() == "0.35s")
    }

    @Test("Ease-in animation has ease-in timing")
    func testEaseInAnimation() {
        let animation = Animation.easeIn
        #expect(animation.cssTransitionTiming() == "ease-in")
    }

    @Test("Ease-out animation has ease-out timing")
    func testEaseOutAnimation() {
        let animation = Animation.easeOut
        #expect(animation.cssTransitionTiming() == "ease-out")
    }

    @Test("Ease-in-out animation has ease-in-out timing")
    func testEaseInOutAnimation() {
        let animation = Animation.easeInOut
        #expect(animation.cssTransitionTiming() == "ease-in-out")
    }

    // MARK: - Spring Animation Tests

    @Test("Spring animation with default parameters")
    func testDefaultSpring() {
        let animation = Animation.spring()
        let timing = animation.cssTransitionTiming()

        // Should generate a cubic-bezier function
        #expect(timing.hasPrefix("cubic-bezier("))
        #expect(animation.cssDuration() == "0.55s") // Default response
    }

    @Test("Spring animation with custom parameters")
    func testCustomSpring() {
        let animation = Animation.spring(response: 0.3, dampingFraction: 0.6)
        #expect(animation.cssDuration() == "0.3s")

        let timing = animation.cssTransitionTiming()
        #expect(timing.hasPrefix("cubic-bezier("))
    }

    @Test("Spring animation with high damping")
    func testHighDampingSpring() {
        let animation = Animation.spring(response: 0.4, dampingFraction: 1.0)
        let timing = animation.cssTransitionTiming()

        // High damping should approximate to a smooth curve
        #expect(timing.hasPrefix("cubic-bezier("))
        #expect(animation.cssDuration() == "0.4s")
    }

    @Test("Spring animation with low damping")
    func testLowDampingSpring() {
        let animation = Animation.spring(response: 0.5, dampingFraction: 0.3)
        let timing = animation.cssTransitionTiming()

        // Low damping should create a bouncier curve
        #expect(timing.hasPrefix("cubic-bezier("))
    }

    // MARK: - Custom Timing Curve Tests

    @Test("Custom timing curve generates cubic-bezier")
    func testCustomTimingCurve() {
        let animation = Animation.timingCurve(0.4, 0.0, 0.2, 1.0, duration: 0.5)
        #expect(animation.cssTransitionTiming() == "cubic-bezier(0.4, 0.0, 0.2, 1.0)")
        #expect(animation.cssDuration() == "0.5s")
    }

    @Test("Custom timing curve with overshoot")
    func testCustomTimingCurveWithOvershoot() {
        let animation = Animation.timingCurve(0.5, -0.5, 0.5, 1.5, duration: 0.6)
        #expect(animation.cssTransitionTiming() == "cubic-bezier(0.5, -0.5, 0.5, 1.5)")
        #expect(animation.cssDuration() == "0.6s")
    }

    // MARK: - Delay Tests

    @Test("Animation with delay")
    func testAnimationDelay() {
        let animation = Animation.easeIn.delay(0.5)
        #expect(animation.cssDelay() == "0.5s")
        #expect(animation.cssTransitionTiming() == "ease-in")
    }

    @Test("Animation with multiple delays accumulate")
    func testMultipleDelays() {
        let animation = Animation.easeOut.delay(0.3).delay(0.2)
        #expect(animation.cssDelay() == "0.5s")
    }

    @Test("Animation with zero delay")
    func testZeroDelay() {
        let animation = Animation.linear.delay(0)
        #expect(animation.cssDelay() == "0s")
    }

    // MARK: - Speed Tests

    @Test("Animation with speed multiplier")
    func testAnimationSpeed() {
        let animation = Animation.default.speed(2.0)
        // Duration should be halved: 0.35 / 2.0 = 0.175
        #expect(animation.cssDuration() == "0.175s")
    }

    @Test("Animation with slow speed")
    func testSlowSpeed() {
        let animation = Animation.linear.speed(0.5)
        // Duration should be doubled: 0.35 / 0.5 = 0.7
        #expect(animation.cssDuration() == "0.7s")
    }

    @Test("Animation with multiple speed multipliers")
    func testMultipleSpeedMultipliers() {
        let animation = Animation.easeIn.speed(2.0).speed(0.5)
        // 2.0 * 0.5 = 1.0, so duration should be unchanged
        #expect(animation.cssDuration() == "0.35s")
    }

    // MARK: - Repeat Tests

    @Test("Animation with repeat count")
    func testAnimationRepeatCount() {
        let animation = Animation.easeInOut.repeatCount(3)
        #expect(animation.cssIterationCount() == "3")
        #expect(animation.cssAnimationDirection() == "alternate")
    }

    @Test("Animation with repeat count without autoreverse")
    func testRepeatCountWithoutAutoreverse() {
        let animation = Animation.linear.repeatCount(5, autoreverses: false)
        #expect(animation.cssIterationCount() == "5")
        #expect(animation.cssAnimationDirection() == "normal")
    }

    @Test("Animation repeat forever")
    func testRepeatForever() {
        let animation = Animation.easeOut.repeatForever()
        #expect(animation.cssIterationCount() == "infinite")
        #expect(animation.cssAnimationDirection() == "alternate")
    }

    @Test("Animation repeat forever without autoreverse")
    func testRepeatForeverWithoutAutoreverse() {
        let animation = Animation.spring().repeatForever(autoreverses: false)
        #expect(animation.cssIterationCount() == "infinite")
        #expect(animation.cssAnimationDirection() == "normal")
    }

    // MARK: - CSS Generation Tests

    @Test("CSS transition generation")
    func testCSSTransition() {
        let animation = Animation.easeInOut
        let transition = animation.cssTransition()
        #expect(transition == "all 0.35s ease-in-out 0s")
    }

    @Test("CSS transition with custom property")
    func testCSSTransitionCustomProperty() {
        let animation = Animation.linear
        let transition = animation.cssTransition(property: "opacity")
        #expect(transition == "opacity 0.35s linear 0s")
    }

    @Test("CSS transition with delay and speed")
    func testCSSTransitionWithDelayAndSpeed() {
        let animation = Animation.easeIn.delay(0.2).speed(1.5)
        let transition = animation.cssTransition()

        // Duration: 0.35 / 1.5 ≈ 0.23333...
        #expect(transition.hasPrefix("all "))
        #expect(transition.contains("ease-in"))
        #expect(transition.contains("0.2s"))
    }

    @Test("CSS animation generation")
    func testCSSAnimation() {
        let animation = Animation.easeOut.repeatCount(2)
        let cssAnimation = animation.cssAnimation(name: "fadeIn")

        #expect(cssAnimation.contains("fadeIn"))
        #expect(cssAnimation.contains("0.35s"))
        #expect(cssAnimation.contains("ease-out"))
        #expect(cssAnimation.contains("0s"))
        #expect(cssAnimation.contains("2"))
        #expect(cssAnimation.contains("alternate"))
    }

    @Test("CSS animation with infinite repeat")
    func testCSSAnimationInfinite() {
        let animation = Animation.linear.repeatForever(autoreverses: false)
        let cssAnimation = animation.cssAnimation(name: "spin")

        #expect(cssAnimation.contains("infinite"))
        #expect(cssAnimation.contains("normal"))
    }

    // MARK: - Animation Composition Tests

    @Test("Chained animation modifiers")
    func testChainedModifiers() {
        let animation = Animation.spring()
            .delay(0.1)
            .speed(1.5)
            .repeatCount(3, autoreverses: true)

        #expect(animation.cssDelay() == "0.1s")
        #expect(animation.cssIterationCount() == "3")
        #expect(animation.cssAnimationDirection() == "alternate")

        // Duration should be response / speed = 0.55 / 1.5 ≈ 0.36666...
        let duration = animation.cssDuration()
        #expect(duration.hasPrefix("0.36"))
    }

    @Test("Complex custom animation")
    func testComplexCustomAnimation() {
        let animation = Animation.timingCurve(0.17, 0.67, 0.83, 0.67, duration: 0.4)
            .delay(0.5)
            .speed(2.0)

        #expect(animation.cssTransitionTiming() == "cubic-bezier(0.17, 0.67, 0.83, 0.67)")
        #expect(animation.cssDelay() == "0.5s")

        // Duration: 0.4 / 2.0 = 0.2
        #expect(animation.cssDuration() == "0.2s")
    }

    // MARK: - Hashable and Sendable Tests

    @Test("Animations are hashable")
    func testAnimationHashable() {
        let anim1 = Animation.easeIn.delay(0.5)
        let anim2 = Animation.easeIn.delay(0.5)
        let anim3 = Animation.easeOut.delay(0.5)

        #expect(anim1 == anim2)
        #expect(anim1 != anim3)

        // Can be used in Sets
        let animationSet: Set<Animation> = [anim1, anim2, anim3]
        #expect(animationSet.count == 2)
    }

    @Test("Animation is a value type")
    func testAnimationValueType() {
        var animation1 = Animation.linear
        let animation2 = animation1.delay(0.5)

        // Original should be unchanged
        #expect(animation1.cssDelay() == "0s")
        #expect(animation2.cssDelay() == "0.5s")
    }

    // MARK: - Edge Cases

    @Test("Very fast animation")
    func testVeryFastAnimation() {
        let animation = Animation.default.speed(10.0)
        // 0.35 / 10 = 0.035
        #expect(animation.cssDuration() == "0.035s")
    }

    @Test("Very slow animation")
    func testVerySlowAnimation() {
        let animation = Animation.default.speed(0.1)
        // 0.35 / 0.1 = 3.5
        #expect(animation.cssDuration() == "3.5s")
    }

    @Test("Animation with large delay")
    func testLargeDelay() {
        let animation = Animation.linear.delay(5.0)
        #expect(animation.cssDelay() == "5.0s")
    }

    @Test("Animation timing function matches cssAnimationTiming")
    func testTimingFunctionConsistency() {
        let animations: [Animation] = [
            .default, .linear, .easeIn, .easeOut, .easeInOut,
            .spring(), .timingCurve(0.1, 0.2, 0.3, 0.4)
        ]

        for animation in animations {
            #expect(animation.cssTransitionTiming() == animation.cssAnimationTiming())
        }
    }
}
