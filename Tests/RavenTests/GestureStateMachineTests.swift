import Foundation
import Testing
@testable import Raven

/// Tests for the gesture recognition state machine.
///
/// These tests verify the proper functioning of the GestureRecognitionState enum
/// and the DragGestureState struct's state machine behavior.
@MainActor
@Suite struct GestureStateMachineTests {

    // MARK: - GestureRecognitionState Tests

    @Test func gestureRecognitionStateInitialState() {
        let state = GestureRecognitionState.possible
        switch state {
        case .possible:
            #expect(Bool(true))
        default:
            Issue.record("Expected .possible state")
        }
    }

    @Test func gestureRecognitionStateNormalFlow() {
        // Test normal flow: possible -> began -> changed -> ended
        var state = GestureRecognitionState.possible
        #expect(state == .possible)

        state = .began
        #expect(state == .began)

        state = .changed
        #expect(state == .changed)

        state = .ended
        #expect(state == .ended)
    }

    @Test func gestureRecognitionStateCancellationFlow() {
        // Test cancellation from possible
        var state = GestureRecognitionState.possible
        state = .cancelled
        #expect(state == .cancelled)

        // Test cancellation from began
        state = .began
        state = .cancelled
        #expect(state == .cancelled)

        // Test cancellation from changed
        state = .changed
        state = .cancelled
        #expect(state == .cancelled)
    }

    @Test func gestureRecognitionStateFailureFlow() {
        // Test failure from possible
        var state = GestureRecognitionState.possible
        state = .failed
        #expect(state == .failed)
    }

    // MARK: - DragGestureState Tests

    @Test func dragGestureStateInitialization() {
        let startLocation = Raven.CGPoint(x: 100, y: 200)
        let startTime = Date().timeIntervalSince1970
        let minimumDistance = 10.0

        let state = DragGestureState(
            startLocation: startLocation,
            startTime: startTime,
            minimumDistance: minimumDistance
        )

        #expect(state.startLocation == startLocation)
        #expect(state.startTime == startTime)
        #expect(state.minimumDistance == minimumDistance)
        #expect(state.recognitionState == .possible)
        #expect(state.positionSamples.count == 1)
        #expect(state.positionSamples[0].location == startLocation)
    }

    @Test func dragGestureStateMinimumDistanceThreshold() {
        let startLocation = Raven.CGPoint(x: 0, y: 0)
        let state = DragGestureState(
            startLocation: startLocation,
            startTime: Date().timeIntervalSince1970,
            minimumDistance: 10.0
        )

        // Test point within minimum distance (should not exceed)
        let nearPoint = Raven.CGPoint(x: 5, y: 5)
        let distanceToNear = sqrt(5*5 + 5*5) // ~7.07
        #expect(distanceToNear < 10.0)
        #expect(!state.hasExceededMinimumDistance(to: nearPoint))

        // Test point exactly at minimum distance
        let exactPoint = Raven.CGPoint(x: 0, y: 10)
        #expect(state.hasExceededMinimumDistance(to: exactPoint))

        // Test point beyond minimum distance (should exceed)
        let farPoint = Raven.CGPoint(x: 10, y: 10)
        let distanceToFar = sqrt(10*10 + 10*10) // ~14.14
        #expect(distanceToFar > 10.0)
        #expect(state.hasExceededMinimumDistance(to: farPoint))
    }

    @Test func dragGestureStateAddSample() {
        let startLocation = Raven.CGPoint(x: 0, y: 0)
        var state = DragGestureState(
            startLocation: startLocation,
            startTime: 0.0,
            minimumDistance: 10.0
        )

        #expect(state.positionSamples.count == 1)

        // Add samples
        state.addSample(location: Raven.CGPoint(x: 10, y: 10), time: 0.1)
        #expect(state.positionSamples.count == 2)

        state.addSample(location: Raven.CGPoint(x: 20, y: 20), time: 0.2)
        // The rolling velocity window is 100ms, so the initial 0.0 sample is evicted.
        #expect(state.positionSamples.count == 2)

        #expect(state.positionSamples.last?.location.x == 20)
        #expect(state.positionSamples.last?.location.y == 20)
    }

    @Test func dragGestureStateVelocityCalculation() {
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
        #expect(abs(velocity.width - 1000) < 0.1)
        #expect(abs(velocity.height - 1000) < 0.1)
    }

    @Test func dragGestureStateVelocityWithMultipleSamples() {
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
        #expect(abs(velocity.width - 1000) < 10.0)
        #expect(abs(velocity.height - 1000) < 10.0)
    }

    @Test func dragGestureStateRecognitionStateTransitions() {
        let startLocation = Raven.CGPoint(x: 0, y: 0)
        var state = DragGestureState(
            startLocation: startLocation,
            startTime: Date().timeIntervalSince1970,
            minimumDistance: 10.0
        )

        // Initial state should be .possible
        #expect(state.recognitionState == .possible)

        // Transition to .began
        state.recognitionState = .began
        #expect(state.recognitionState == .began)

        // Transition to .changed
        state.recognitionState = .changed
        #expect(state.recognitionState == .changed)

        // Transition to .ended
        state.recognitionState = .ended
        #expect(state.recognitionState == .ended)
    }

    @Test func dragGestureStateRecognitionFromPossibleToCancelled() {
        let startLocation = Raven.CGPoint(x: 0, y: 0)
        var state = DragGestureState(
            startLocation: startLocation,
            startTime: Date().timeIntervalSince1970,
            minimumDistance: 10.0
        )

        // Gesture in .possible state can be cancelled
        #expect(state.recognitionState == .possible)
        state.recognitionState = .cancelled
        #expect(state.recognitionState == .cancelled)
    }

    @Test func dragGestureStateRecognitionFromPossibleToFailed() {
        let startLocation = Raven.CGPoint(x: 0, y: 0)
        var state = DragGestureState(
            startLocation: startLocation,
            startTime: Date().timeIntervalSince1970,
            minimumDistance: 10.0
        )

        // Gesture in .possible state can fail
        #expect(state.recognitionState == .possible)
        state.recognitionState = .failed
        #expect(state.recognitionState == .failed)
    }

    @Test func dragGestureStateDeprecatedIsRecognizedGetter() {
        let startLocation = Raven.CGPoint(x: 0, y: 0)
        var state = DragGestureState(
            startLocation: startLocation,
            startTime: Date().timeIntervalSince1970,
            minimumDistance: 10.0
        )

        // .possible -> not recognized
        #expect(state.recognitionState == .possible)
        #expect(!state.isRecognized)

        // .began -> recognized
        state.recognitionState = .began
        #expect(state.isRecognized)

        // .changed -> recognized
        state.recognitionState = .changed
        #expect(state.isRecognized)

        // .ended -> recognized
        state.recognitionState = .ended
        #expect(state.isRecognized)

        // .cancelled -> not recognized
        state.recognitionState = .cancelled
        #expect(!state.isRecognized)

        // .failed -> not recognized
        state.recognitionState = .failed
        #expect(!state.isRecognized)
    }

    @Test func dragGestureStateSampleWindowManagement() {
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
        #expect(
            state.positionSamples.count <=
            DragGestureState.maxSamples
        )
    }

    @Test func dragGestureStateRealisticDragScenario() {
        // Simulate a realistic drag gesture
        let startLocation = Raven.CGPoint(x: 100, y: 100)
        var state = DragGestureState(
            startLocation: startLocation,
            startTime: 0.0,
            minimumDistance: 10.0
        )

        // Initial state is .possible
        #expect(state.recognitionState == .possible)

        // Small movements shouldn't exceed threshold
        state.addSample(location: Raven.CGPoint(x: 102, y: 103), time: 0.016)
        #expect(!state.hasExceededMinimumDistance(to: Raven.CGPoint(x: 102, y: 103)))

        // Larger movement exceeds threshold
        state.addSample(location: Raven.CGPoint(x: 115, y: 115), time: 0.032)
        #expect(state.hasExceededMinimumDistance(to: Raven.CGPoint(x: 115, y: 115)))

        // Would transition to .began in actual implementation
        state.recognitionState = .began
        #expect(state.recognitionState == .began)

        // Continue dragging
        state.addSample(location: Raven.CGPoint(x: 130, y: 130), time: 0.048)
        state.recognitionState = .changed
        #expect(state.recognitionState == .changed)

        // Release
        state.recognitionState = .ended
        #expect(state.recognitionState == .ended)
    }
}
