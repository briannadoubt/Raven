import XCTest
@testable import Raven

/// Tests for the gesture recognition state machine.
///
/// These tests verify the proper functioning of the GestureRecognitionState enum
/// and the DragGestureState struct's state machine behavior.
@MainActor
final class GestureStateMachineTests: XCTestCase {

    // MARK: - GestureRecognitionState Tests

    func testGestureRecognitionStateInitialState() {
        let state = GestureRecognitionState.possible
        switch state {
        case .possible:
            XCTAssertTrue(true, "State should be .possible initially")
        default:
            XCTFail("Expected .possible state")
        }
    }

    func testGestureRecognitionStateNormalFlow() {
        // Test normal flow: possible -> began -> changed -> ended
        var state = GestureRecognitionState.possible
        XCTAssertTrue(state == .possible, "Should start in .possible")

        state = .began
        XCTAssertTrue(state == .began, "Should transition to .began")

        state = .changed
        XCTAssertTrue(state == .changed, "Should transition to .changed")

        state = .ended
        XCTAssertTrue(state == .ended, "Should transition to .ended")
    }

    func testGestureRecognitionStateCancellationFlow() {
        // Test cancellation from possible
        var state = GestureRecognitionState.possible
        state = .cancelled
        XCTAssertTrue(state == .cancelled, "Should transition from .possible to .cancelled")

        // Test cancellation from began
        state = .began
        state = .cancelled
        XCTAssertTrue(state == .cancelled, "Should transition from .began to .cancelled")

        // Test cancellation from changed
        state = .changed
        state = .cancelled
        XCTAssertTrue(state == .cancelled, "Should transition from .changed to .cancelled")
    }

    func testGestureRecognitionStateFailureFlow() {
        // Test failure from possible
        var state = GestureRecognitionState.possible
        state = .failed
        XCTAssertTrue(state == .failed, "Should transition from .possible to .failed")
    }

    // MARK: - DragGestureState Tests

    func testDragGestureStateInitialization() {
        let startLocation = Raven.CGPoint(x: 100, y: 200)
        let startTime = Date().timeIntervalSince1970
        let minimumDistance = 10.0

        let state = DragGestureState(
            startLocation: startLocation,
            startTime: startTime,
            minimumDistance: minimumDistance
        )

        XCTAssertEqual(state.startLocation, startLocation)
        XCTAssertEqual(state.startTime, startTime)
        XCTAssertEqual(state.minimumDistance, minimumDistance)
        XCTAssertEqual(state.recognitionState, .possible, "Should start in .possible state")
        XCTAssertEqual(state.positionSamples.count, 1, "Should have one initial sample")
        XCTAssertEqual(state.positionSamples[0].location, startLocation)
    }

    func testDragGestureStateMinimumDistanceThreshold() {
        let startLocation = Raven.CGPoint(x: 0, y: 0)
        let state = DragGestureState(
            startLocation: startLocation,
            startTime: Date().timeIntervalSince1970,
            minimumDistance: 10.0
        )

        // Test point within minimum distance (should not exceed)
        let nearPoint = Raven.CGPoint(x: 5, y: 5)
        let distanceToNear = sqrt(5*5 + 5*5) // ~7.07
        XCTAssertLessThan(distanceToNear, 10.0)
        XCTAssertFalse(state.hasExceededMinimumDistance(to: nearPoint))

        // Test point exactly at minimum distance
        let exactPoint = Raven.CGPoint(x: 0, y: 10)
        XCTAssertTrue(state.hasExceededMinimumDistance(to: exactPoint))

        // Test point beyond minimum distance (should exceed)
        let farPoint = Raven.CGPoint(x: 10, y: 10)
        let distanceToFar = sqrt(10*10 + 10*10) // ~14.14
        XCTAssertGreaterThan(distanceToFar, 10.0)
        XCTAssertTrue(state.hasExceededMinimumDistance(to: farPoint))
    }

    func testDragGestureStateAddSample() {
        let startLocation = Raven.CGPoint(x: 0, y: 0)
        var state = DragGestureState(
            startLocation: startLocation,
            startTime: 0.0,
            minimumDistance: 10.0
        )

        XCTAssertEqual(state.positionSamples.count, 1, "Should have initial sample")

        // Add samples
        state.addSample(location: Raven.CGPoint(x: 10, y: 10), time: 0.1)
        XCTAssertEqual(state.positionSamples.count, 2)

        state.addSample(location: Raven.CGPoint(x: 20, y: 20), time: 0.2)
        XCTAssertEqual(state.positionSamples.count, 3)

        XCTAssertEqual(state.positionSamples.last?.location.x, 20)
        XCTAssertEqual(state.positionSamples.last?.location.y, 20)
    }

    func testDragGestureStateVelocityCalculation() {
        let startLocation = Raven.CGPoint(x: 0, y: 0)
        var state = DragGestureState(
            startLocation: startLocation,
            startTime: 0.0,
            minimumDistance: 10.0
        )

        // Add sample that moves 100 points in 0.1 seconds
        state.addSample(location: Raven.CGPoint(x: 100, y: 100), time: 0.1)

        let velocity = state.calculateVelocity()

        // Velocity should be 100 points / 0.1 seconds = 1000 points/second
        XCTAssertEqual(velocity.width, 1000, accuracy: 0.1)
        XCTAssertEqual(velocity.height, 1000, accuracy: 0.1)
    }

    func testDragGestureStateVelocityWithMultipleSamples() {
        let startLocation = Raven.CGPoint(x: 0, y: 0)
        var state = DragGestureState(
            startLocation: startLocation,
            startTime: 0.0,
            minimumDistance: 10.0
        )

        // Add multiple samples
        state.addSample(location: Raven.CGPoint(x: 25, y: 25), time: 0.025)
        state.addSample(location: Raven.CGPoint(x: 50, y: 50), time: 0.05)
        state.addSample(location: Raven.CGPoint(x: 75, y: 75), time: 0.075)
        state.addSample(location: Raven.CGPoint(x: 100, y: 100), time: 0.1)

        let velocity = state.calculateVelocity()

        // Average velocity should be 100 points / 0.1 seconds = 1000 points/second
        XCTAssertEqual(velocity.width, 1000, accuracy: 10.0)
        XCTAssertEqual(velocity.height, 1000, accuracy: 10.0)
    }

    func testDragGestureStateRecognitionStateTransitions() {
        let startLocation = Raven.CGPoint(x: 0, y: 0)
        var state = DragGestureState(
            startLocation: startLocation,
            startTime: Date().timeIntervalSince1970,
            minimumDistance: 10.0
        )

        // Initial state should be .possible
        XCTAssertEqual(state.recognitionState, .possible)

        // Transition to .began
        state.recognitionState = .began
        XCTAssertEqual(state.recognitionState, .began)

        // Transition to .changed
        state.recognitionState = .changed
        XCTAssertEqual(state.recognitionState, .changed)

        // Transition to .ended
        state.recognitionState = .ended
        XCTAssertEqual(state.recognitionState, .ended)
    }

    func testDragGestureStateRecognitionFromPossibleToCancelled() {
        let startLocation = Raven.CGPoint(x: 0, y: 0)
        var state = DragGestureState(
            startLocation: startLocation,
            startTime: Date().timeIntervalSince1970,
            minimumDistance: 10.0
        )

        // Gesture in .possible state can be cancelled
        XCTAssertEqual(state.recognitionState, .possible)
        state.recognitionState = .cancelled
        XCTAssertEqual(state.recognitionState, .cancelled)
    }

    func testDragGestureStateRecognitionFromPossibleToFailed() {
        let startLocation = Raven.CGPoint(x: 0, y: 0)
        var state = DragGestureState(
            startLocation: startLocation,
            startTime: Date().timeIntervalSince1970,
            minimumDistance: 10.0
        )

        // Gesture in .possible state can fail
        XCTAssertEqual(state.recognitionState, .possible)
        state.recognitionState = .failed
        XCTAssertEqual(state.recognitionState, .failed)
    }

    func testDragGestureStateDeprecatedIsRecognizedGetter() {
        let startLocation = Raven.CGPoint(x: 0, y: 0)
        var state = DragGestureState(
            startLocation: startLocation,
            startTime: Date().timeIntervalSince1970,
            minimumDistance: 10.0
        )

        // .possible -> not recognized
        XCTAssertEqual(state.recognitionState, .possible)
        XCTAssertFalse(state.isRecognized)

        // .began -> recognized
        state.recognitionState = .began
        XCTAssertTrue(state.isRecognized)

        // .changed -> recognized
        state.recognitionState = .changed
        XCTAssertTrue(state.isRecognized)

        // .ended -> recognized
        state.recognitionState = .ended
        XCTAssertTrue(state.isRecognized)

        // .cancelled -> not recognized
        state.recognitionState = .cancelled
        XCTAssertFalse(state.isRecognized)

        // .failed -> not recognized
        state.recognitionState = .failed
        XCTAssertFalse(state.isRecognized)
    }

    func testDragGestureStateSampleWindowManagement() {
        let startLocation = Raven.CGPoint(x: 0, y: 0)
        var state = DragGestureState(
            startLocation: startLocation,
            startTime: 0.0,
            minimumDistance: 10.0
        )

        // Add many samples over a long time period
        for i in 1...20 {
            let time = Double(i) * 0.01 // 10ms intervals
            state.addSample(
                location: Raven.CGPoint(x: Double(i) * 5, y: Double(i) * 5),
                time: time
            )
        }

        // Should limit to maxSamples
        XCTAssertLessThanOrEqual(
            state.positionSamples.count,
            DragGestureState.maxSamples,
            "Should not exceed maxSamples limit"
        )
    }

    func testDragGestureStateRealisticDragScenario() {
        // Simulate a realistic drag gesture
        let startLocation = Raven.CGPoint(x: 100, y: 100)
        var state = DragGestureState(
            startLocation: startLocation,
            startTime: 0.0,
            minimumDistance: 10.0
        )

        // Initial state is .possible
        XCTAssertEqual(state.recognitionState, .possible)

        // Small movements shouldn't exceed threshold
        state.addSample(location: Raven.CGPoint(x: 102, y: 103), time: 0.016)
        XCTAssertFalse(state.hasExceededMinimumDistance(to: Raven.CGPoint(x: 102, y: 103)))

        // Larger movement exceeds threshold
        state.addSample(location: Raven.CGPoint(x: 115, y: 115), time: 0.032)
        XCTAssertTrue(state.hasExceededMinimumDistance(to: Raven.CGPoint(x: 115, y: 115)))

        // Would transition to .began in actual implementation
        state.recognitionState = .began
        XCTAssertEqual(state.recognitionState, .began)

        // Continue dragging
        state.addSample(location: Raven.CGPoint(x: 130, y: 130), time: 0.048)
        state.recognitionState = .changed
        XCTAssertEqual(state.recognitionState, .changed)

        // Release
        state.recognitionState = .ended
        XCTAssertEqual(state.recognitionState, .ended)
    }
}
