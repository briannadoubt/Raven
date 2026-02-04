import Testing
@testable import Raven

/// Comprehensive tests for LongPressGesture functionality.
///
/// These tests verify the long press gesture's behavior including:
/// - Initialization with different parameters
/// - Duration threshold validation
/// - Distance threshold validation
/// - State tracking during gesture progress
/// - Cancellation conditions
@Suite("LongPressGesture Tests")
@MainActor
struct LongPressGestureTests {

    // MARK: - Initialization Tests

    @Test("LongPressGesture default initialization")
    func defaultInitialization() {
        let gesture = LongPressGesture()
        #expect(gesture.minimumDuration == 0.5)
        #expect(gesture.maximumDistance == 10.0)
    }

    @Test("LongPressGesture initialization with custom duration")
    func customDurationInitialization() {
        let gesture = LongPressGesture(minimumDuration: 2.0)
        #expect(gesture.minimumDuration == 2.0)
        #expect(gesture.maximumDistance == 10.0)
    }

    @Test("LongPressGesture initialization with custom duration and distance")
    func customDurationAndDistanceInitialization() {
        let gesture = LongPressGesture(minimumDuration: 1.5, maximumDistance: 20.0)
        #expect(gesture.minimumDuration == 1.5)
        #expect(gesture.maximumDistance == 20.0)
    }

    @Test("LongPressGesture clamps negative duration to minimum")
    func clampNegativeDuration() {
        let gesture = LongPressGesture(minimumDuration: -1.0)
        #expect(gesture.minimumDuration >= 0.01)
    }

    @Test("LongPressGesture clamps zero duration to minimum")
    func clampZeroDuration() {
        let gesture = LongPressGesture(minimumDuration: 0.0)
        #expect(gesture.minimumDuration >= 0.01)
    }

    @Test("LongPressGesture clamps very small duration to minimum")
    func clampVerySmallDuration() {
        let gesture = LongPressGesture(minimumDuration: 0.001)
        #expect(gesture.minimumDuration >= 0.01)
    }

    @Test("LongPressGesture clamps negative distance to zero")
    func clampNegativeDistance() {
        let gesture = LongPressGesture(minimumDuration: 1.0, maximumDistance: -5.0)
        #expect(gesture.maximumDistance >= 0.0)
    }

    @Test("LongPressGesture allows zero distance")
    func allowZeroDistance() {
        let gesture = LongPressGesture(minimumDuration: 1.0, maximumDistance: 0.0)
        #expect(gesture.maximumDistance == 0.0)
    }

    @Test("LongPressGesture accepts large duration values")
    func largeDurationValues() {
        let gesture = LongPressGesture(minimumDuration: 10.0)
        #expect(gesture.minimumDuration == 10.0)
    }

    @Test("LongPressGesture accepts large distance values")
    func largeDistanceValues() {
        let gesture = LongPressGesture(minimumDuration: 1.0, maximumDistance: 1000.0)
        #expect(gesture.maximumDistance == 1000.0)
    }

    // MARK: - Internal State Tests

    @Test("LongPressGestureState initialization")
    func gestureStateInitialization() {
        let startPoint = CGPoint(x: 100, y: 200)
        let startTime = 1000.0
        let state = LongPressGestureState(
            startPoint: startPoint,
            startTime: startTime,
            minimumDuration: 1.0,
            maximumDistance: 10.0
        )

        #expect(state.startPoint == startPoint)
        #expect(state.startTime == startTime)
        #expect(state.minimumDuration == 1.0)
        #expect(state.maximumDistance == 10.0)
        #expect(state.hasCompleted == false)
    }

    @Test("LongPressGestureState shouldCancel with no movement")
    func shouldNotCancelWithNoMovement() {
        let state = LongPressGestureState(
            startPoint: CGPoint(x: 100, y: 100),
            startTime: 0,
            minimumDuration: 1.0,
            maximumDistance: 10.0
        )

        let currentPoint = CGPoint(x: 100, y: 100)
        #expect(!state.shouldCancel(at: currentPoint))
    }

    @Test("LongPressGestureState shouldCancel with small movement")
    func shouldNotCancelWithSmallMovement() {
        let state = LongPressGestureState(
            startPoint: CGPoint(x: 100, y: 100),
            startTime: 0,
            minimumDuration: 1.0,
            maximumDistance: 10.0
        )

        let currentPoint = CGPoint(x: 105, y: 105)
        #expect(!state.shouldCancel(at: currentPoint))
    }

    @Test("LongPressGestureState shouldCancel with horizontal movement exceeding threshold")
    func shouldCancelWithHorizontalMovement() {
        let state = LongPressGestureState(
            startPoint: CGPoint(x: 100, y: 100),
            startTime: 0,
            minimumDuration: 1.0,
            maximumDistance: 10.0
        )

        let currentPoint = CGPoint(x: 115, y: 100)
        #expect(state.shouldCancel(at: currentPoint))
    }

    @Test("LongPressGestureState shouldCancel with vertical movement exceeding threshold")
    func shouldCancelWithVerticalMovement() {
        let state = LongPressGestureState(
            startPoint: CGPoint(x: 100, y: 100),
            startTime: 0,
            minimumDuration: 1.0,
            maximumDistance: 10.0
        )

        let currentPoint = CGPoint(x: 100, y: 115)
        #expect(state.shouldCancel(at: currentPoint))
    }

    @Test("LongPressGestureState shouldCancel with diagonal movement exceeding threshold")
    func shouldCancelWithDiagonalMovement() {
        let state = LongPressGestureState(
            startPoint: CGPoint(x: 100, y: 100),
            startTime: 0,
            minimumDuration: 1.0,
            maximumDistance: 10.0
        )

        // Move 8 points in X and 8 points in Y
        // Distance = sqrt(64 + 64) = sqrt(128) ≈ 11.3 > 10
        let currentPoint = CGPoint(x: 108, y: 108)
        #expect(state.shouldCancel(at: currentPoint))
    }

    @Test("LongPressGestureState shouldCancel at exact threshold boundary")
    func shouldNotCancelAtExactThreshold() {
        let state = LongPressGestureState(
            startPoint: CGPoint(x: 100, y: 100),
            startTime: 0,
            minimumDuration: 1.0,
            maximumDistance: 10.0
        )

        // Move exactly 10 points (should not cancel as it's not > threshold)
        let currentPoint = CGPoint(x: 110, y: 100)
        #expect(!state.shouldCancel(at: currentPoint))
    }

    @Test("LongPressGestureState shouldCancel just beyond threshold")
    func shouldCancelJustBeyondThreshold() {
        let state = LongPressGestureState(
            startPoint: CGPoint(x: 100, y: 100),
            startTime: 0,
            minimumDuration: 1.0,
            maximumDistance: 10.0
        )

        // Move 10.1 points (should cancel)
        let currentPoint = CGPoint(x: 110.1, y: 100)
        #expect(state.shouldCancel(at: currentPoint))
    }

    @Test("LongPressGestureState shouldCancel with negative movement")
    func shouldCancelWithNegativeMovement() {
        let state = LongPressGestureState(
            startPoint: CGPoint(x: 100, y: 100),
            startTime: 0,
            minimumDuration: 1.0,
            maximumDistance: 10.0
        )

        let currentPoint = CGPoint(x: 85, y: 100)
        #expect(state.shouldCancel(at: currentPoint))
    }

    @Test("LongPressGestureState hasMetDuration before duration elapses")
    func hasNotMetDurationBeforeElapsed() {
        let startTime = 1000.0
        let state = LongPressGestureState(
            startPoint: CGPoint(x: 100, y: 100),
            startTime: startTime,
            minimumDuration: 1.0,
            maximumDistance: 10.0
        )

        let currentTime = startTime + 0.5
        #expect(!state.hasMetDuration(at: currentTime))
    }

    @Test("LongPressGestureState hasMetDuration at exact duration")
    func hasMetDurationAtExactTime() {
        let startTime = 1000.0
        let state = LongPressGestureState(
            startPoint: CGPoint(x: 100, y: 100),
            startTime: startTime,
            minimumDuration: 1.0,
            maximumDistance: 10.0
        )

        let currentTime = startTime + 1.0
        #expect(state.hasMetDuration(at: currentTime))
    }

    @Test("LongPressGestureState hasMetDuration after duration elapses")
    func hasMetDurationAfterElapsed() {
        let startTime = 1000.0
        let state = LongPressGestureState(
            startPoint: CGPoint(x: 100, y: 100),
            startTime: startTime,
            minimumDuration: 1.0,
            maximumDistance: 10.0
        )

        let currentTime = startTime + 2.0
        #expect(state.hasMetDuration(at: currentTime))
    }

    // MARK: - Type Conformance Tests

    @Test("LongPressGesture conforms to Gesture protocol")
    func conformsToGesture() {
        let gesture = LongPressGesture()
        let _: any Gesture = gesture
        // If this compiles, the test passes
    }

    @Test("LongPressGesture Value type is Bool")
    func valueTypeIsBool() {
        let _: LongPressGesture = LongPressGesture()
        let value: LongPressGesture.Value = true
        #expect(value == true)
    }

    @Test("LongPressGesture is Sendable")
    func isSendable() {
        let gesture = LongPressGesture()
        let _: any Sendable = gesture
        // If this compiles, the test passes
    }

    // MARK: - Edge Case Tests

    @Test("LongPressGestureState with zero maximum distance cancels on any movement")
    func zeroDistanceCancelsOnMovement() {
        let state = LongPressGestureState(
            startPoint: CGPoint(x: 100, y: 100),
            startTime: 0,
            minimumDuration: 1.0,
            maximumDistance: 0.0
        )

        // Even tiny movement should cancel
        let currentPoint = CGPoint(x: 100.1, y: 100)
        #expect(state.shouldCancel(at: currentPoint))
    }

    @Test("LongPressGestureState with very large distance tolerates large movement")
    func largeDistanceToleratesMovement() {
        let state = LongPressGestureState(
            startPoint: CGPoint(x: 100, y: 100),
            startTime: 0,
            minimumDuration: 1.0,
            maximumDistance: 1000.0
        )

        let currentPoint = CGPoint(x: 500, y: 500)
        #expect(!state.shouldCancel(at: currentPoint))
    }

    @Test("LongPressGestureState handles negative coordinates")
    func handlesNegativeCoordinates() {
        let state = LongPressGestureState(
            startPoint: CGPoint(x: -50, y: -50),
            startTime: 0,
            minimumDuration: 1.0,
            maximumDistance: 10.0
        )

        let currentPoint = CGPoint(x: -45, y: -45)
        #expect(!state.shouldCancel(at: currentPoint))
    }

    @Test("LongPressGestureState handles very large coordinates")
    func handlesLargeCoordinates() {
        let state = LongPressGestureState(
            startPoint: CGPoint(x: 10000, y: 10000),
            startTime: 0,
            minimumDuration: 1.0,
            maximumDistance: 10.0
        )

        let currentPoint = CGPoint(x: 10005, y: 10005)
        #expect(!state.shouldCancel(at: currentPoint))
    }

    // MARK: - Gesture Modifier Tests

    @Test("LongPressGesture can attach onEnded modifier")
    func canAttachOnEndedModifier() {
        var called = false
        let gesture = LongPressGesture()
            .onEnded { _ in
                called = true
            }

        // Type check - if this compiles, the modifier works
        let _: any Gesture = gesture
        #expect(called == false) // Not called yet, just verifying compilation
    }

    @Test("LongPressGesture can attach updating modifier")
    func canAttachUpdatingModifier() {
        let gestureState = GestureState(wrappedValue: false)
        let gesture = LongPressGesture()
            .updating(gestureState) { value, state, transaction in
                state = value
            }

        // Type check - if this compiles, the modifier works
        let _: any Gesture = gesture
    }

    @Test("LongPressGesture can chain multiple modifiers")
    func canChainModifiers() {
        let gestureState = GestureState(wrappedValue: false)

        // Note: Full gesture composition/chaining is not yet implemented
        // This test verifies that each modifier type works independently
        let gesture1 = LongPressGesture()
            .updating(gestureState) { value, state, _ in
                state = value
            }

        var endedCalled = false
        let gesture2 = LongPressGesture()
            .onEnded { _ in
                endedCalled = true
            }

        // Type check - if this compiles, modifiers work
        let _: any Gesture = gesture1
        let _: any Gesture = gesture2
        #expect(endedCalled == false) // Not called yet, just verifying compilation
    }

    // MARK: - Distance Calculation Tests

    @Test("LongPressGestureState distance calculation precision")
    func distanceCalculationPrecision() {
        let state = LongPressGestureState(
            startPoint: CGPoint(x: 0, y: 0),
            startTime: 0,
            minimumDuration: 1.0,
            maximumDistance: 10.0
        )

        // Test Pythagorean theorem: 3-4-5 triangle scaled by 2
        let currentPoint = CGPoint(x: 6, y: 8)
        // Distance should be 10 (exactly at threshold)
        #expect(!state.shouldCancel(at: currentPoint))
    }

    @Test("LongPressGestureState distance calculation with fractional coordinates")
    func distanceCalculationWithFractionalCoordinates() {
        let state = LongPressGestureState(
            startPoint: CGPoint(x: 0.5, y: 0.5),
            startTime: 0,
            minimumDuration: 1.0,
            maximumDistance: 10.0
        )

        let currentPoint = CGPoint(x: 5.5, y: 5.5)
        // Distance = sqrt(25 + 25) = sqrt(50) ≈ 7.07 < 10
        #expect(!state.shouldCancel(at: currentPoint))
    }

    // MARK: - Time Calculation Tests

    @Test("LongPressGestureState time calculation with fractional seconds")
    func timeCalculationWithFractionalSeconds() {
        let startTime = 1234.567
        let state = LongPressGestureState(
            startPoint: CGPoint(x: 100, y: 100),
            startTime: startTime,
            minimumDuration: 0.5,
            maximumDistance: 10.0
        )

        let currentTime = startTime + 0.5
        #expect(state.hasMetDuration(at: currentTime))
    }

    @Test("LongPressGestureState time calculation just before threshold")
    func timeCalculationJustBeforeThreshold() {
        let startTime = 1000.0
        let state = LongPressGestureState(
            startPoint: CGPoint(x: 100, y: 100),
            startTime: startTime,
            minimumDuration: 1.0,
            maximumDistance: 10.0
        )

        let currentTime = startTime + 0.999
        #expect(!state.hasMetDuration(at: currentTime))
    }
}
