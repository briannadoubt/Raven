import Foundation
import Testing
@testable import Raven

/// Tests for the Gesture protocol and foundation types.
///
/// These tests verify the core gesture infrastructure including:
/// - Gesture protocol conformance
/// - GestureMask option set operations
/// - EventModifiers option set operations
/// - Transaction behavior
/// - @GestureState property wrapper functionality
@MainActor
@Suite struct GestureTests {

    // MARK: - GestureMask Tests

    @Test func gestureMaskNone() {
        let mask = GestureMask.none
        #expect(mask.rawValue == 0)
        #expect(!mask.contains(.gesture))
        #expect(!mask.contains(.subviews))
    }

    @Test func gestureMaskGesture() {
        let mask = GestureMask.gesture
        #expect(mask.contains(.gesture))
        #expect(!mask.contains(.subviews))
    }

    @Test func gestureMaskSubviews() {
        let mask = GestureMask.subviews
        #expect(!mask.contains(.gesture))
        #expect(mask.contains(.subviews))
    }

    @Test func gestureMaskAll() {
        let mask = GestureMask.all
        #expect(mask.contains(.gesture))
        #expect(mask.contains(.subviews))
    }

    @Test func gestureMaskCombination() {
        let mask: GestureMask = [.gesture, .subviews]
        #expect(mask == .all)
        #expect(mask.contains(.gesture))
        #expect(mask.contains(.subviews))
    }

    @Test func gestureMaskSubtraction() {
        var mask = GestureMask.all
        mask.subtract(.subviews)
        #expect(mask == .gesture)
        #expect(mask.contains(.gesture))
        #expect(!mask.contains(.subviews))
    }

    // MARK: - EventModifiers Tests

    @Test func eventModifiersNone() {
        let modifiers = EventModifiers(rawValue: 0)
        #expect(!modifiers.contains(.shift))
        #expect(!modifiers.contains(.control))
        #expect(!modifiers.contains(.option))
        #expect(!modifiers.contains(.command))
    }

    @Test func eventModifiersShift() {
        let modifiers = EventModifiers.shift
        #expect(modifiers.contains(.shift))
        #expect(!modifiers.contains(.control))
    }

    @Test func eventModifiersControl() {
        let modifiers = EventModifiers.control
        #expect(modifiers.contains(.control))
        #expect(!modifiers.contains(.shift))
    }

    @Test func eventModifiersOption() {
        let modifiers = EventModifiers.option
        #expect(modifiers.contains(.option))
        #expect(!modifiers.contains(.command))
    }

    @Test func eventModifiersCommand() {
        let modifiers = EventModifiers.command
        #expect(modifiers.contains(.command))
        #expect(!modifiers.contains(.option))
    }

    @Test func eventModifiersCapsLock() {
        let modifiers = EventModifiers.capsLock
        #expect(modifiers.contains(.capsLock))
    }

    @Test func eventModifiersNumericPad() {
        let modifiers = EventModifiers.numericPad
        #expect(modifiers.contains(.numericPad))
    }

    @Test func eventModifiersFunction() {
        let modifiers = EventModifiers.function
        #expect(modifiers.contains(.function))
    }

    @Test func eventModifiersCombination() {
        let modifiers: EventModifiers = [.shift, .command]
        #expect(modifiers.contains(.shift))
        #expect(modifiers.contains(.command))
        #expect(!modifiers.contains(.control))
    }

    @Test func eventModifiersAll() {
        let modifiers = EventModifiers.all
        #expect(modifiers.contains(.capsLock))
        #expect(modifiers.contains(.shift))
        #expect(modifiers.contains(.control))
        #expect(modifiers.contains(.option))
        #expect(modifiers.contains(.command))
        #expect(modifiers.contains(.numericPad))
        #expect(modifiers.contains(.function))
    }

    @Test func eventModifiersSubtraction() {
        var modifiers: EventModifiers = [.shift, .command, .option]
        modifiers.subtract(.command)
        #expect(modifiers.contains(.shift))
        #expect(modifiers.contains(.option))
        #expect(!modifiers.contains(.command))
    }

    // MARK: - Transaction Tests

    @Test func transactionInitialization() {
        let transaction = Transaction()
        #expect(transaction.animation == nil)
        #expect(!transaction.disablesAnimations)
    }

    @Test func transactionWithAnimation() {
        let transaction = Transaction(animation: .default)
        #expect(transaction.animation != nil)
        #expect(!transaction.disablesAnimations)
    }

    @Test func transactionWithDisabledAnimations() {
        let transaction = Transaction(disablesAnimations: true)
        #expect(transaction.animation == nil)
        #expect(transaction.disablesAnimations)
    }

    @Test func transactionModification() {
        var transaction = Transaction()
        transaction.animation = .easeIn
        transaction.disablesAnimations = true

        #expect(transaction.animation != nil)
        #expect(transaction.disablesAnimations)
    }

    // MARK: - GestureState Tests

    @Test func gestureStateInitialization() {
        let gestureState = GestureState(wrappedValue: 10)
        #expect(gestureState.wrappedValue == 10)
    }

    @Test func gestureStateInitialValue() {
        let gestureState = GestureState(initialValue: 42)
        #expect(gestureState.wrappedValue == 42)
    }

    @Test func gestureStateWithCGSize() {
        let gestureState = GestureState(wrappedValue: Raven.CGSize(width: 0, height: 0))
        #expect(gestureState.wrappedValue.width == 0)
        #expect(gestureState.wrappedValue.height == 0)
    }

    @Test func gestureStateWithCGPoint() {
        let gestureState = GestureState(wrappedValue: Raven.CGPoint(x: 0, y: 0))
        #expect(gestureState.wrappedValue.x == 0)
        #expect(gestureState.wrappedValue.y == 0)
    }

    @Test func gestureStateUpdate() {
        let gestureState = GestureState(wrappedValue: 0)
        var transaction = Transaction()

        gestureState.update(value: 100, transaction: &transaction)
        #expect(gestureState.wrappedValue == 100)
    }

    @Test func gestureStateReset() {
        let gestureState = GestureState(wrappedValue: 0)
        var transaction = Transaction()

        // Update the value
        gestureState.update(value: 100, transaction: &transaction)
        #expect(gestureState.wrappedValue == 100)

        // Reset should restore initial value
        gestureState.reset(transaction: &transaction)
        #expect(gestureState.wrappedValue == 0)
    }

    @Test func gestureStateCustomReset() {
        var resetCalled = false
        var capturedValue: Int?

        let gestureState = GestureState(
            reset: { value, transaction in
                resetCalled = true
                capturedValue = value
            },
            initialValue: 0
        )

        var transaction = Transaction()

        // Update the value
        gestureState.update(value: 50, transaction: &transaction)
        #expect(gestureState.wrappedValue == 50)

        // Reset should call custom reset function
        gestureState.reset(transaction: &transaction)
        #expect(resetCalled)
        #expect(capturedValue == 50)
        #expect(gestureState.wrappedValue == 0) // Value should be reset
    }

    @Test func gestureStateCustomResetModifiesTransaction() {
        let gestureState = GestureState(
            reset: { _, transaction in
                transaction.animation = .spring()
            },
            initialValue: Raven.CGSize(width: 0, height: 0)
        )

        var transaction = Transaction()
        #expect(transaction.animation == nil)

        gestureState.update(
            value: Raven.CGSize(width: 100, height: 100),
            transaction: &transaction
        )
        gestureState.reset(transaction: &transaction)

        #expect(transaction.animation != nil)
    }

    @Test func gestureStateProjectedValue() {
        let gestureState = GestureState(wrappedValue: 10)
        let projected = gestureState.projectedValue

        // Projected value should be the same wrapper
        #expect(projected.wrappedValue == gestureState.wrappedValue)
    }

    @Test func gestureStateWithBool() {
        let gestureState = GestureState(wrappedValue: false)
        var transaction = Transaction()

        gestureState.update(value: true, transaction: &transaction)
        #expect(gestureState.wrappedValue)

        gestureState.reset(transaction: &transaction)
        #expect(!gestureState.wrappedValue)
    }

    @Test func gestureStateWithDouble() {
        let gestureState = GestureState(wrappedValue: 1.0)
        var transaction = Transaction()

        gestureState.update(value: 2.5, transaction: &transaction)
        #expect(abs(gestureState.wrappedValue - 2.5) < 0.001)

        gestureState.reset(transaction: &transaction)
        #expect(abs(gestureState.wrappedValue - 1.0) < 0.001)
    }

    // MARK: - Gesture Protocol Tests

    @Test func primitiveGestureConformance() {
        // Test that we can create a simple gesture type
        struct TestGesture: Gesture {
            typealias Value = Int
        }

        let gesture = TestGesture()

        // This would crash if we tried to access body, but that's expected
        // for primitive gestures
        #expect(TestGesture.Body.self == Never.self)
    }

    @Test func gestureValueType() {
        struct TestGesture: Gesture {
            typealias Value = Raven.CGPoint
        }

        // Verify the associated type is what we expect
        #expect(TestGesture.Value.self == Raven.CGPoint.self)
    }

    @Test func gestureWithCustomValueType() {
        struct CustomValue: Sendable, Equatable {
            let x: Double
            let y: Double
        }

        struct TestGesture: Gesture {
            typealias Value = CustomValue
        }

        #expect(TestGesture.Value.self == CustomValue.self)
    }

    // MARK: - GestureRecognitionState Tests

    @Test func gestureRecognitionStateInitialState() {
        let state = GestureRecognitionState.possible
        switch state {
        case .possible:
            #expect(true)
        default:
            Issue.record("Expected .possible state")
        }
    }

    @Test func gestureRecognitionStateTransitions() {
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

    @Test func gestureRecognitionStateCancellation() {
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

    @Test func gestureRecognitionStateFailure() {
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

    @Test func dragGestureStateMinimumDistanceCheck() {
        let startLocation = Raven.CGPoint(x: 0, y: 0)
        let state = DragGestureState(
            startLocation: startLocation,
            startTime: Date().timeIntervalSince1970,
            minimumDistance: 10.0
        )

        // Test point within minimum distance
        let nearPoint = Raven.CGPoint(x: 5, y: 5)
        #expect(!state.hasExceededMinimumDistance(to: nearPoint))

        // Test point beyond minimum distance
        let farPoint = Raven.CGPoint(x: 10, y: 10)
        #expect(state.hasExceededMinimumDistance(to: farPoint))
    }

    @Test func dragGestureStateAddSample() {
        let startLocation = Raven.CGPoint(x: 0, y: 0)
        var state = DragGestureState(
            startLocation: startLocation,
            startTime: 0.0,
            minimumDistance: 10.0
        )

        // Add samples
        state.addSample(location: Raven.CGPoint(x: 10, y: 10), time: 0.1)
        state.addSample(location: Raven.CGPoint(x: 20, y: 20), time: 0.2)

        #expect(state.positionSamples.count == 3)
        #expect(state.positionSamples.last?.location.x == 20)
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
}
