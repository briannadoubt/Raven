import Testing
@testable import Raven

/// Tests for the keyframe animator system.
@Suite("KeyframeAnimator Tests")
struct KeyframeAnimatorTests {

    // MARK: - Interpolatable Protocol Tests

    @Test("Double interpolation works correctly")
    func testDoubleInterpolation() {
        let start = 0.0
        let end = 10.0

        #expect(start.interpolated(to: end, amount: 0.0) == 0.0)
        #expect(start.interpolated(to: end, amount: 0.5) == 5.0)
        #expect(start.interpolated(to: end, amount: 1.0) == 10.0)
    }

    @Test("CGFloat interpolation works correctly")
    func testCGFloatInterpolation() {
        let start: CGFloat = 0.0
        let end: CGFloat = 100.0

        #expect(start.interpolated(to: end, amount: 0.0) == 0.0)
        #expect(start.interpolated(to: end, amount: 0.25) == 25.0)
        #expect(start.interpolated(to: end, amount: 1.0) == 100.0)
    }

    @Test("CGPoint interpolation works correctly")
    func testCGPointInterpolation() {
        let start = CGPoint(x: 0, y: 0)
        let end = CGPoint(x: 100, y: 200)

        let mid = start.interpolated(to: end, amount: 0.5)
        #expect(mid.x == 50)
        #expect(mid.y == 100)
    }

    @Test("CGSize interpolation works correctly")
    func testCGSizeInterpolation() {
        let start = CGSize(width: 10, height: 20)
        let end = CGSize(width: 50, height: 80)

        let mid = start.interpolated(to: end, amount: 0.5)
        #expect(mid.width == 30)
        #expect(mid.height == 50)
    }

    @Test("CGRect interpolation works correctly")
    func testCGRectInterpolation() {
        let start = CGRect(x: 0, y: 0, width: 10, height: 20)
        let end = CGRect(x: 100, y: 200, width: 50, height: 80)

        let mid = start.interpolated(to: end, amount: 0.5)
        #expect(mid.origin.x == 50)
        #expect(mid.origin.y == 100)
        #expect(mid.size.width == 30)
        #expect(mid.size.height == 50)
    }

    // MARK: - KeyframeTrack Tests

    @Test("Empty keyframe track has zero duration")
    func testEmptyKeyframeTrack() {
        var track = KeyframeTrack<Double>()
        #expect(track.sequence.totalDuration == 0)
        #expect(track.sequence.keyframes.isEmpty)
    }

    @Test("Linear keyframe is added correctly")
    func testLinearKeyframe() {
        var track = KeyframeTrack<Double>()
        track.linear(1.0, duration: 0.3)

        #expect(track.sequence.keyframes.count == 1)
        #expect(track.sequence.totalDuration == 0.3)

        if case .linear(let value, let duration) = track.sequence.keyframes[0] {
            #expect(value == 1.0)
            #expect(duration == 0.3)
        } else {
            Issue.record("Expected linear keyframe")
        }
    }

    @Test("Spring keyframe is added correctly")
    func testSpringKeyframe() {
        var track = KeyframeTrack<Double>()
        track.spring(2.0, duration: 0.5, bounce: 0.3)

        #expect(track.sequence.keyframes.count == 1)
        #expect(track.sequence.totalDuration == 0.5)

        if case .spring(let value, let duration, let bounce) = track.sequence.keyframes[0] {
            #expect(value == 2.0)
            #expect(duration == 0.5)
            #expect(bounce == 0.3)
        } else {
            Issue.record("Expected spring keyframe")
        }
    }

    @Test("Cubic keyframe is added correctly")
    func testCubicKeyframe() {
        var track = KeyframeTrack<Double>()
        track.cubic(3.0, duration: 0.4)

        #expect(track.sequence.keyframes.count == 1)
        #expect(track.sequence.totalDuration == 0.4)

        if case .cubic(let value, let duration) = track.sequence.keyframes[0] {
            #expect(value == 3.0)
            #expect(duration == 0.4)
        } else {
            Issue.record("Expected cubic keyframe")
        }
    }

    @Test("Move keyframe is added correctly")
    func testMoveKeyframe() {
        var track = KeyframeTrack<Double>()
        track.move(5.0)

        #expect(track.sequence.keyframes.count == 1)
        #expect(track.sequence.totalDuration == 0)  // Move has zero duration

        if case .move(let value) = track.sequence.keyframes[0] {
            #expect(value == 5.0)
        } else {
            Issue.record("Expected move keyframe")
        }
    }

    @Test("Multiple keyframes accumulate duration")
    func testMultipleKeyframes() {
        var track = KeyframeTrack<Double>()
        track.linear(1.0, duration: 0.3)
        track.spring(2.0, duration: 0.5, bounce: 0.2)
        track.linear(0.5, duration: 0.2)

        #expect(track.sequence.keyframes.count == 3)
        #expect(track.sequence.totalDuration == 1.0)  // 0.3 + 0.5 + 0.2
    }

    // MARK: - CSS Timing Function Tests

    @Test("Linear keyframe generates linear timing")
    func testLinearTimingFunction() {
        let keyframe = Keyframe<Double>.linear(value: 1.0, duration: 0.3)
        #expect(keyframe.cssTimingFunction() == "linear")
    }

    @Test("Spring with zero bounce generates smooth curve")
    func testSpringZeroBounceTimingFunction() {
        let keyframe = Keyframe<Double>.spring(value: 1.0, duration: 0.5, bounce: 0.0)
        let timing = keyframe.cssTimingFunction()
        #expect(timing.hasPrefix("cubic-bezier("))
    }

    @Test("Spring with medium bounce generates cubic-bezier")
    func testSpringMediumBounceTimingFunction() {
        let keyframe = Keyframe<Double>.spring(value: 1.0, duration: 0.5, bounce: 0.3)
        let timing = keyframe.cssTimingFunction()
        #expect(timing.hasPrefix("cubic-bezier("))
    }

    @Test("Spring with high bounce generates cubic-bezier")
    func testSpringHighBounceTimingFunction() {
        let keyframe = Keyframe<Double>.spring(value: 1.0, duration: 0.5, bounce: 0.8)
        let timing = keyframe.cssTimingFunction()
        #expect(timing.hasPrefix("cubic-bezier("))
    }

    @Test("Cubic keyframe generates cubic-bezier timing")
    func testCubicTimingFunction() {
        let keyframe = Keyframe<Double>.cubic(
            value: 1.0,
            duration: 0.4
        )
        let timing = keyframe.cssTimingFunction()
        #expect(timing.hasPrefix("cubic-bezier("))
    }

    @Test("Move keyframe generates step-end timing")
    func testMoveTimingFunction() {
        let keyframe = Keyframe<Double>.move(value: 1.0)
        #expect(keyframe.cssTimingFunction() == "step-end")
    }

    // MARK: - KeyframeSequence Tests

    @Test("CSS keyframe stops are generated correctly")
    func testCSSKeyframeStops() {
        var sequence = KeyframeSequence<Double>()
        sequence.add(.linear(value: 0.0, duration: 0.0))  // Start
        sequence.add(.linear(value: 1.0, duration: 0.5))
        sequence.add(.spring(value: 0.5, duration: 0.5, bounce: 0.2))

        let stops = sequence.generateCSSKeyframeStops { value in
            ["opacity": "\(value)"]
        }

        #expect(stops.count >= 2)
        #expect(stops[0].percentage == 0)  // Start at 0%
        #expect(stops.last?.percentage == 100)  // End at 100%
    }

    @Test("CSS keyframe stops include properties")
    func testCSSKeyframeStopsProperties() {
        var sequence = KeyframeSequence<CGFloat>()
        sequence.add(.linear(value: 1.0, duration: 0.5))
        sequence.add(.linear(value: 2.0, duration: 0.5))

        let stops = sequence.generateCSSKeyframeStops { value in
            ["scale": "\(value)"]
        }

        #expect(!stops.isEmpty)
        for stop in stops {
            #expect(stop.properties["scale"] != nil)
        }
    }

    // MARK: - KeyframeAnimator View Extension Tests

    @Test("KeyframeAnimator creates view with animation")
    func testKeyframeAnimatorBasic() {
        // Just verify it compiles and creates a view
        _ = Text("Hello")
            .keyframeAnimator(
                initialValue: 1.0,
                repeating: false
            ) { content, value in
                content.opacity(value)
            } keyframes: { track in
                track.linear(0.5, duration: 0.3)
            }
    }

    @Test("KeyframeAnimator with repeating creates infinite animation")
    func testKeyframeAnimatorRepeating() {
        _ = Circle()
            .keyframeAnimator(
                initialValue: 1.0,
                repeating: true
            ) { content, value in
                content.scaleEffect(value)
            } keyframes: { track in
                track.spring(1.2, duration: 0.5, bounce: 0.3)
                track.linear(1.0, duration: 0.3)
            }
    }

    @Test("KeyframeAnimator with CGPoint values")
    func testKeyframeAnimatorWithCGPoint() {
        _ = Rectangle()
            .keyframeAnimator(
                initialValue: CGPoint(x: 0, y: 0),
                repeating: false
            ) { content, value in
                content.offset(x: value.x, y: value.y)
            } keyframes: { track in
                track.linear(CGPoint(x: 100, y: 50), duration: 0.5)
                track.spring(CGPoint(x: 0, y: 0), duration: 0.5, bounce: 0.2)
            }
    }

    @Test("KeyframeAnimator with multiple keyframe types")
    func testKeyframeAnimatorMixedKeyframes() {
        _ = Text("Animate")
            .keyframeAnimator(
                initialValue: 1.0,
                repeating: false
            ) { content, value in
                content.scaleEffect(value)
            } keyframes: { track in
                track.linear(1.2, duration: 0.2)
                track.move(1.5)  // Instant jump
                track.spring(1.0, duration: 0.4, bounce: 0.3)
                track.cubic(0.8, duration: 0.3)
            }
    }

    // MARK: - Complex Value Type Tests

    struct AnimationValues: Interpolatable, Sendable {
        var scale: Double
        var opacity: Double

        func interpolated(to other: AnimationValues, amount: Double) -> AnimationValues {
            AnimationValues(
                scale: scale.interpolated(to: other.scale, amount: amount),
                opacity: opacity.interpolated(to: other.opacity, amount: amount)
            )
        }
    }

    @Test("Custom interpolatable type works correctly")
    func testCustomInterpolatableType() {
        let start = AnimationValues(scale: 1.0, opacity: 1.0)
        let end = AnimationValues(scale: 2.0, opacity: 0.5)

        let mid = start.interpolated(to: end, amount: 0.5)
        #expect(mid.scale == 1.5)
        #expect(mid.opacity == 0.75)
    }

    @Test("KeyframeAnimator with custom interpolatable type")
    func testKeyframeAnimatorWithCustomType() {
        _ = Circle()
            .keyframeAnimator(
                initialValue: AnimationValues(scale: 1.0, opacity: 1.0),
                repeating: true
            ) { content, value in
                content
                    .scaleEffect(value.scale)
                    .opacity(value.opacity)
            } keyframes: { track in
                track.linear(.init(scale: 1.2, opacity: 0.8), duration: 0.3)
                track.spring(.init(scale: 1.0, opacity: 1.0), duration: 0.4, bounce: 0.2)
            }
    }

    // MARK: - Edge Cases

    @Test("Empty keyframe sequence creates valid view")
    func testEmptyKeyframeSequence() {
        _ = Text("Hello")
            .keyframeAnimator(
                initialValue: 1.0,
                repeating: false
            ) { content, value in
                content.opacity(value)
            } keyframes: { _ in
                // No keyframes added
            }
    }

    @Test("Single move keyframe creates valid sequence")
    func testSingleMoveKeyframe() {
        var track = KeyframeTrack<Double>()
        track.move(1.0)

        #expect(track.sequence.keyframes.count == 1)
        #expect(track.sequence.totalDuration == 0)
    }

    @Test("Keyframes with zero duration")
    func testKeyframesWithZeroDuration() {
        var track = KeyframeTrack<Double>()
        track.linear(1.0, duration: 0.0)
        track.linear(2.0, duration: 0.0)

        #expect(track.sequence.keyframes.count == 2)
        #expect(track.sequence.totalDuration == 0)
    }

    @Test("Very long keyframe sequence")
    func testLongKeyframeSequence() {
        var track = KeyframeTrack<Double>()
        for i in 0..<10 {
            track.linear(Double(i), duration: 0.1)
        }

        #expect(track.sequence.keyframes.count == 10)
        #expect(track.sequence.totalDuration == 1.0)
    }

    @Test("Keyframe value property returns correct value")
    func testKeyframeValueProperty() {
        let linear = Keyframe<Double>.linear(value: 1.5, duration: 0.3)
        let spring = Keyframe<Double>.spring(value: 2.5, duration: 0.5, bounce: 0.2)
        let cubic = Keyframe<Double>.cubic(value: 3.5, duration: 0.4)
        let move = Keyframe<Double>.move(value: 4.5)

        #expect(linear.value == 1.5)
        #expect(spring.value == 2.5)
        #expect(cubic.value == 3.5)
        #expect(move.value == 4.5)
    }

    @Test("Keyframe duration property returns correct duration")
    func testKeyframeDurationProperty() {
        let linear = Keyframe<Double>.linear(value: 1.0, duration: 0.3)
        let spring = Keyframe<Double>.spring(value: 1.0, duration: 0.5, bounce: 0.2)
        let cubic = Keyframe<Double>.cubic(value: 1.0, duration: 0.4)
        let move = Keyframe<Double>.move(value: 1.0)

        #expect(linear.duration == 0.3)
        #expect(spring.duration == 0.5)
        #expect(cubic.duration == 0.4)
        #expect(move.duration == 0)
    }
}
