import XCTest
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
final class GestureTests: XCTestCase {

    // MARK: - GestureMask Tests

    func testGestureMaskNone() {
        let mask = GestureMask.none
        XCTAssertEqual(mask.rawValue, 0)
        XCTAssertFalse(mask.contains(.gesture))
        XCTAssertFalse(mask.contains(.subviews))
    }

    func testGestureMaskGesture() {
        let mask = GestureMask.gesture
        XCTAssertTrue(mask.contains(.gesture))
        XCTAssertFalse(mask.contains(.subviews))
    }

    func testGestureMaskSubviews() {
        let mask = GestureMask.subviews
        XCTAssertFalse(mask.contains(.gesture))
        XCTAssertTrue(mask.contains(.subviews))
    }

    func testGestureMaskAll() {
        let mask = GestureMask.all
        XCTAssertTrue(mask.contains(.gesture))
        XCTAssertTrue(mask.contains(.subviews))
    }

    func testGestureMaskCombination() {
        let mask: GestureMask = [.gesture, .subviews]
        XCTAssertEqual(mask, .all)
        XCTAssertTrue(mask.contains(.gesture))
        XCTAssertTrue(mask.contains(.subviews))
    }

    func testGestureMaskSubtraction() {
        var mask = GestureMask.all
        mask.subtract(.subviews)
        XCTAssertEqual(mask, .gesture)
        XCTAssertTrue(mask.contains(.gesture))
        XCTAssertFalse(mask.contains(.subviews))
    }

    // MARK: - EventModifiers Tests

    func testEventModifiersNone() {
        let modifiers = EventModifiers(rawValue: 0)
        XCTAssertFalse(modifiers.contains(.shift))
        XCTAssertFalse(modifiers.contains(.control))
        XCTAssertFalse(modifiers.contains(.option))
        XCTAssertFalse(modifiers.contains(.command))
    }

    func testEventModifiersShift() {
        let modifiers = EventModifiers.shift
        XCTAssertTrue(modifiers.contains(.shift))
        XCTAssertFalse(modifiers.contains(.control))
    }

    func testEventModifiersControl() {
        let modifiers = EventModifiers.control
        XCTAssertTrue(modifiers.contains(.control))
        XCTAssertFalse(modifiers.contains(.shift))
    }

    func testEventModifiersOption() {
        let modifiers = EventModifiers.option
        XCTAssertTrue(modifiers.contains(.option))
        XCTAssertFalse(modifiers.contains(.command))
    }

    func testEventModifiersCommand() {
        let modifiers = EventModifiers.command
        XCTAssertTrue(modifiers.contains(.command))
        XCTAssertFalse(modifiers.contains(.option))
    }

    func testEventModifiersCapsLock() {
        let modifiers = EventModifiers.capsLock
        XCTAssertTrue(modifiers.contains(.capsLock))
    }

    func testEventModifiersNumericPad() {
        let modifiers = EventModifiers.numericPad
        XCTAssertTrue(modifiers.contains(.numericPad))
    }

    func testEventModifiersFunction() {
        let modifiers = EventModifiers.function
        XCTAssertTrue(modifiers.contains(.function))
    }

    func testEventModifiersCombination() {
        let modifiers: EventModifiers = [.shift, .command]
        XCTAssertTrue(modifiers.contains(.shift))
        XCTAssertTrue(modifiers.contains(.command))
        XCTAssertFalse(modifiers.contains(.control))
    }

    func testEventModifiersAll() {
        let modifiers = EventModifiers.all
        XCTAssertTrue(modifiers.contains(.capsLock))
        XCTAssertTrue(modifiers.contains(.shift))
        XCTAssertTrue(modifiers.contains(.control))
        XCTAssertTrue(modifiers.contains(.option))
        XCTAssertTrue(modifiers.contains(.command))
        XCTAssertTrue(modifiers.contains(.numericPad))
        XCTAssertTrue(modifiers.contains(.function))
    }

    func testEventModifiersSubtraction() {
        var modifiers: EventModifiers = [.shift, .command, .option]
        modifiers.subtract(.command)
        XCTAssertTrue(modifiers.contains(.shift))
        XCTAssertTrue(modifiers.contains(.option))
        XCTAssertFalse(modifiers.contains(.command))
    }

    // MARK: - Transaction Tests

    func testTransactionInitialization() {
        let transaction = Transaction()
        XCTAssertNil(transaction.animation)
        XCTAssertFalse(transaction.disablesAnimations)
    }

    func testTransactionWithAnimation() {
        let transaction = Transaction(animation: .default)
        XCTAssertNotNil(transaction.animation)
        XCTAssertFalse(transaction.disablesAnimations)
    }

    func testTransactionWithDisabledAnimations() {
        let transaction = Transaction(disablesAnimations: true)
        XCTAssertNil(transaction.animation)
        XCTAssertTrue(transaction.disablesAnimations)
    }

    func testTransactionModification() {
        var transaction = Transaction()
        transaction.animation = .easeIn
        transaction.disablesAnimations = true

        XCTAssertNotNil(transaction.animation)
        XCTAssertTrue(transaction.disablesAnimations)
    }

    // MARK: - GestureState Tests

    func testGestureStateInitialization() {
        let gestureState = GestureState(wrappedValue: 10)
        XCTAssertEqual(gestureState.wrappedValue, 10)
    }

    func testGestureStateInitialValue() {
        let gestureState = GestureState(initialValue: 42)
        XCTAssertEqual(gestureState.wrappedValue, 42)
    }

    func testGestureStateWithCGSize() {
        let gestureState = GestureState(wrappedValue: Raven.CGSize(width: 0, height: 0))
        XCTAssertEqual(gestureState.wrappedValue.width, 0)
        XCTAssertEqual(gestureState.wrappedValue.height, 0)
    }

    func testGestureStateWithCGPoint() {
        let gestureState = GestureState(wrappedValue: Raven.CGPoint(x: 0, y: 0))
        XCTAssertEqual(gestureState.wrappedValue.x, 0)
        XCTAssertEqual(gestureState.wrappedValue.y, 0)
    }

    func testGestureStateUpdate() {
        let gestureState = GestureState(wrappedValue: 0)
        var transaction = Transaction()

        gestureState.update(value: 100, transaction: &transaction)
        XCTAssertEqual(gestureState.wrappedValue, 100)
    }

    func testGestureStateReset() {
        let gestureState = GestureState(wrappedValue: 0)
        var transaction = Transaction()

        // Update the value
        gestureState.update(value: 100, transaction: &transaction)
        XCTAssertEqual(gestureState.wrappedValue, 100)

        // Reset should restore initial value
        gestureState.reset(transaction: &transaction)
        XCTAssertEqual(gestureState.wrappedValue, 0)
    }

    func testGestureStateCustomReset() {
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
        XCTAssertEqual(gestureState.wrappedValue, 50)

        // Reset should call custom reset function
        gestureState.reset(transaction: &transaction)
        XCTAssertTrue(resetCalled)
        XCTAssertEqual(capturedValue, 50)
        XCTAssertEqual(gestureState.wrappedValue, 0) // Value should be reset
    }

    func testGestureStateCustomResetModifiesTransaction() {
        let gestureState = GestureState(
            reset: { _, transaction in
                transaction.animation = .spring()
            },
            initialValue: Raven.CGSize(width: 0, height: 0)
        )

        var transaction = Transaction()
        XCTAssertNil(transaction.animation)

        gestureState.update(
            value: Raven.CGSize(width: 100, height: 100),
            transaction: &transaction
        )
        gestureState.reset(transaction: &transaction)

        XCTAssertNotNil(transaction.animation)
    }

    func testGestureStateProjectedValue() {
        let gestureState = GestureState(wrappedValue: 10)
        let projected = gestureState.projectedValue

        // Projected value should be the same wrapper
        XCTAssertEqual(projected.wrappedValue, gestureState.wrappedValue)
    }

    func testGestureStateWithBool() {
        let gestureState = GestureState(wrappedValue: false)
        var transaction = Transaction()

        gestureState.update(value: true, transaction: &transaction)
        XCTAssertTrue(gestureState.wrappedValue)

        gestureState.reset(transaction: &transaction)
        XCTAssertFalse(gestureState.wrappedValue)
    }

    func testGestureStateWithDouble() {
        let gestureState = GestureState(wrappedValue: 1.0)
        var transaction = Transaction()

        gestureState.update(value: 2.5, transaction: &transaction)
        XCTAssertEqual(gestureState.wrappedValue, 2.5, accuracy: 0.001)

        gestureState.reset(transaction: &transaction)
        XCTAssertEqual(gestureState.wrappedValue, 1.0, accuracy: 0.001)
    }

    // MARK: - Gesture Protocol Tests

    func testPrimitiveGestureConformance() {
        // Test that we can create a simple gesture type
        struct TestGesture: Gesture {
            typealias Value = Int
        }

        let gesture = TestGesture()

        // This would crash if we tried to access body, but that's expected
        // for primitive gestures
        XCTAssertTrue(type(of: gesture.body) == Never.self)
    }

    func testGestureValueType() {
        struct TestGesture: Gesture {
            typealias Value = Raven.CGPoint
        }

        // Verify the associated type is what we expect
        XCTAssertTrue(TestGesture.Value.self == Raven.CGPoint.self)
    }

    func testGestureWithCustomValueType() {
        struct CustomValue: Sendable, Equatable {
            let x: Double
            let y: Double
        }

        struct TestGesture: Gesture {
            typealias Value = CustomValue
        }

        XCTAssertTrue(TestGesture.Value.self == CustomValue.self)
    }

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

    func testGestureRecognitionStateTransitions() {
        // Test normal flow: possible -> began -> changed -> ended
        var state = GestureRecognitionState.possible
        XCTAssertTrue(state == .possible)

        state = .began
        XCTAssertTrue(state == .began)

        state = .changed
        XCTAssertTrue(state == .changed)

        state = .ended
        XCTAssertTrue(state == .ended)
    }

    func testGestureRecognitionStateCancellation() {
        // Test cancellation from possible
        var state = GestureRecognitionState.possible
        state = .cancelled
        XCTAssertTrue(state == .cancelled)

        // Test cancellation from began
        state = .began
        state = .cancelled
        XCTAssertTrue(state == .cancelled)

        // Test cancellation from changed
        state = .changed
        state = .cancelled
        XCTAssertTrue(state == .cancelled)
    }

    func testGestureRecognitionStateFailure() {
        // Test failure from possible
        var state = GestureRecognitionState.possible
        state = .failed
        XCTAssertTrue(state == .failed)
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
        XCTAssertEqual(state.recognitionState, .possible)
        XCTAssertEqual(state.positionSamples.count, 1)
        XCTAssertEqual(state.positionSamples[0].location, startLocation)
    }

    func testDragGestureStateMinimumDistanceCheck() {
        let startLocation = Raven.CGPoint(x: 0, y: 0)
        let state = DragGestureState(
            startLocation: startLocation,
            startTime: Date().timeIntervalSince1970,
            minimumDistance: 10.0
        )

        // Test point within minimum distance
        let nearPoint = Raven.CGPoint(x: 5, y: 5)
        XCTAssertFalse(state.hasExceededMinimumDistance(to: nearPoint))

        // Test point beyond minimum distance
        let farPoint = Raven.CGPoint(x: 10, y: 10)
        XCTAssertTrue(state.hasExceededMinimumDistance(to: farPoint))
    }

    func testDragGestureStateAddSample() {
        let startLocation = Raven.CGPoint(x: 0, y: 0)
        var state = DragGestureState(
            startLocation: startLocation,
            startTime: 0.0,
            minimumDistance: 10.0
        )

        // Add samples
        state.addSample(location: Raven.CGPoint(x: 10, y: 10), time: 0.1)
        state.addSample(location: Raven.CGPoint(x: 20, y: 20), time: 0.2)

        XCTAssertEqual(state.positionSamples.count, 3)
        XCTAssertEqual(state.positionSamples.last?.location.x, 20)
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
}
