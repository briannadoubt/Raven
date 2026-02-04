import Testing
import Foundation
@testable import Raven

/// Comprehensive test suite for RotationGesture.
///
/// This test suite verifies:
/// - RotationGesture creation and configuration
/// - Angle calculation from two touch points
/// - Rotation tracking and state management
/// - Web event mapping (touch events)
/// - Desktop fallback (wheel events with modifiers)
/// - Edge cases and boundary conditions
@Suite("RotationGesture Tests")
@MainActor
struct RotationGestureTests {

    // MARK: - RotationGesture Creation Tests

    @Test("RotationGesture default initialization")
    func testRotationGestureDefaultInit() {
        let gesture = RotationGesture()
        // RotationGesture has no configurable properties in default init
        // Verify it compiles and creates successfully
        #expect(RotationGesture.Value.self == Angle.self)
    }

    // MARK: - RotationGesture Type Conformance Tests

    @Test("RotationGesture conforms to Gesture protocol")
    func testRotationGestureConformance() {
        let gesture = RotationGesture()

        // Verify Value type is Angle
        #expect(RotationGesture.Value.self == Angle.self)

        // Verify Body type is Never (primitive gesture)
        #expect(RotationGesture.Body.self == Never.self)
    }

    @Test("RotationGesture is Sendable")
    func testRotationGestureSendable() {
        let gesture = RotationGesture()
        let _: any Sendable = gesture
        #expect(true) // If this compiles, RotationGesture is Sendable
    }

    // MARK: - Angle Calculation Tests

    @Test("Calculate angle for horizontal line (0 degrees)")
    func testAngleCalculationHorizontal() {
        // Two points horizontally aligned (pointing right)
        // Touch 1: (100, 100), Touch 2: (200, 100)
        let angle = RotationGestureState.calculateAngle(
            x1: 100, y1: 100,
            x2: 200, y2: 100
        )

        // atan2(0, 100) = 0 radians = 0 degrees
        let expectedAngle = 0.0
        #expect(abs(angle - expectedAngle) < 0.001)
    }

    @Test("Calculate angle for vertical line (90 degrees)")
    func testAngleCalculationVertical() {
        // Two points vertically aligned (pointing down)
        // Touch 1: (100, 100), Touch 2: (100, 200)
        let angle = RotationGestureState.calculateAngle(
            x1: 100, y1: 100,
            x2: 100, y2: 200
        )

        // atan2(100, 0) = π/2 radians = 90 degrees
        let expectedAngle = Double.pi / 2.0
        #expect(abs(angle - expectedAngle) < 0.001)
    }

    @Test("Calculate angle for diagonal line (45 degrees)")
    func testAngleCalculationDiagonal45() {
        // Two points at 45-degree angle
        // Touch 1: (0, 0), Touch 2: (100, 100)
        let angle = RotationGestureState.calculateAngle(
            x1: 0, y1: 0,
            x2: 100, y2: 100
        )

        // atan2(100, 100) = π/4 radians = 45 degrees
        let expectedAngle = Double.pi / 4.0
        #expect(abs(angle - expectedAngle) < 0.001)
    }

    @Test("Calculate angle for 180 degrees")
    func testAngleCalculation180Degrees() {
        // Two points horizontally aligned (pointing left)
        // Touch 1: (200, 100), Touch 2: (100, 100)
        let angle = RotationGestureState.calculateAngle(
            x1: 200, y1: 100,
            x2: 100, y2: 100
        )

        // atan2(0, -100) = π radians = 180 degrees
        let expectedAngle = Double.pi
        #expect(abs(angle - expectedAngle) < 0.001)
    }

    @Test("Calculate angle for 270 degrees (-90 degrees)")
    func testAngleCalculation270Degrees() {
        // Two points vertically aligned (pointing up)
        // Touch 1: (100, 200), Touch 2: (100, 100)
        let angle = RotationGestureState.calculateAngle(
            x1: 100, y1: 200,
            x2: 100, y2: 100
        )

        // atan2(-100, 0) = -π/2 radians = -90 degrees (or 270 degrees)
        let expectedAngle = -Double.pi / 2.0
        #expect(abs(angle - expectedAngle) < 0.001)
    }

    @Test("Calculate angle for 315 degrees (-45 degrees)")
    func testAngleCalculation315Degrees() {
        // Two points at -45-degree angle
        // Touch 1: (100, 100), Touch 2: (200, 0)
        let angle = RotationGestureState.calculateAngle(
            x1: 100, y1: 100,
            x2: 200, y2: 0
        )

        // atan2(-100, 100) = -π/4 radians = -45 degrees
        let expectedAngle = -Double.pi / 4.0
        #expect(abs(angle - expectedAngle) < 0.001)
    }

    // MARK: - RotationGestureState Tests

    @Test("RotationGestureState initialization")
    func testRotationGestureStateInit() {
        let state = RotationGestureState(
            initialAngle: 0.0,
            currentAngle: 0.0
        )

        #expect(state.initialAngle == 0.0)
        #expect(state.currentAngle == 0.0)
        #expect(state.rotation.degrees == 0.0)
    }

    @Test("RotationGestureState rotation calculation")
    func testRotationGestureStateRotationCalculation() {
        var state = RotationGestureState(
            initialAngle: 0.0,
            currentAngle: Double.pi / 4.0  // 45 degrees
        )

        // Rotation should be 45 degrees
        let rotation = state.rotation
        #expect(abs(rotation.degrees - 45.0) < 0.001)
    }

    @Test("RotationGestureState update angle")
    func testRotationGestureStateUpdateAngle() {
        var state = RotationGestureState(
            initialAngle: 0.0,
            currentAngle: 0.0
        )

        // Update to 90-degree position
        state.updateAngle(x1: 100, y1: 100, x2: 100, y2: 200)

        // Current angle should now be π/2
        #expect(abs(state.currentAngle - Double.pi / 2.0) < 0.001)
    }

    @Test("RotationGestureState clockwise rotation")
    func testRotationGestureStateClockwiseRotation() {
        // Start at 0 degrees (horizontal right)
        let state = RotationGestureState(
            initialAngle: 0.0,
            currentAngle: Double.pi / 2.0  // Rotate to 90 degrees (down)
        )

        // Clockwise rotation: positive angle
        let rotation = state.rotation
        #expect(rotation.degrees > 0)
        #expect(abs(rotation.degrees - 90.0) < 0.001)
    }

    @Test("RotationGestureState counter-clockwise rotation")
    func testRotationGestureStateCounterClockwiseRotation() {
        // Start at 0 degrees (horizontal right)
        let state = RotationGestureState(
            initialAngle: 0.0,
            currentAngle: -Double.pi / 2.0  // Rotate to -90 degrees (up)
        )

        // Counter-clockwise rotation: negative angle
        let rotation = state.rotation
        #expect(rotation.degrees < 0)
        #expect(abs(rotation.degrees - (-90.0)) < 0.001)
    }

    // MARK: - Web Event Mapping Tests

    @Test("RotationGesture primary event name is touchstart")
    func testRotationGesturePrimaryEventName() {
        let gesture = RotationGesture()
        #expect(gesture.primaryEventName == "touchstart")
    }

    @Test("RotationGesture move event names include touchmove")
    func testRotationGestureMoveEventNames() {
        let gesture = RotationGesture()
        #expect(gesture.moveEventNames.contains("touchmove"))
    }

    @Test("RotationGesture end event names")
    func testRotationGestureEndEventNames() {
        let gesture = RotationGesture()
        #expect(gesture.endEventNames.contains("touchend"))
        #expect(gesture.endEventNames.contains("touchcancel"))
    }

    @Test("RotationGesture wheel event name")
    func testRotationGestureWheelEventName() {
        let gesture = RotationGesture()
        #expect(gesture.wheelEventName == "wheel")
    }

    @Test("RotationGesture requires 2 touches")
    func testRotationGestureValidTouchCount() {
        let gesture = RotationGesture()

        #expect(!gesture.isValidTouchCount(0))
        #expect(!gesture.isValidTouchCount(1))
        #expect(gesture.isValidTouchCount(2))
        #expect(!gesture.isValidTouchCount(3))
        #expect(!gesture.isValidTouchCount(4))
    }

    @Test("RotationGesture wheel event requires Ctrl key")
    func testRotationGestureWheelEventModifier() {
        let gesture = RotationGesture()

        #expect(!gesture.isRotationWheelEvent(ctrlKey: false))
        #expect(gesture.isRotationWheelEvent(ctrlKey: true))
    }

    @Test("RotationGesture wheel delta to rotation conversion")
    func testRotationGestureWheelDeltaConversion() {
        let gesture = RotationGesture()

        // Positive delta (wheel down) should give negative rotation
        let rotation1 = gesture.wheelDeltaToRotation(delta: 100)
        #expect(rotation1.degrees < 0)

        // Negative delta (wheel up) should give positive rotation
        let rotation2 = gesture.wheelDeltaToRotation(delta: -100)
        #expect(rotation2.degrees > 0)

        // Zero delta should give zero rotation
        let rotation3 = gesture.wheelDeltaToRotation(delta: 0)
        #expect(rotation3.degrees == 0)
    }

    // MARK: - Rotation Scenarios

    @Test("Full 360-degree rotation")
    func testFullRotation() {
        let state = RotationGestureState(
            initialAngle: 0.0,
            currentAngle: 2.0 * Double.pi
        )

        let rotation = state.rotation
        #expect(abs(rotation.degrees - 360.0) < 0.001)
    }

    @Test("Negative full rotation")
    func testNegativeFullRotation() {
        let state = RotationGestureState(
            initialAngle: 0.0,
            currentAngle: -2.0 * Double.pi
        )

        let rotation = state.rotation
        #expect(abs(rotation.degrees - (-360.0)) < 0.001)
    }

    @Test("Small rotation increments")
    func testSmallRotationIncrements() {
        let state = RotationGestureState(
            initialAngle: 0.0,
            currentAngle: 0.1  // Small angle in radians
        )

        let rotation = state.rotation
        #expect(rotation.degrees > 0)
        #expect(rotation.degrees < 10)  // Less than 10 degrees
    }

    // MARK: - Edge Cases

    @Test("Rotation with same start and end points")
    func testRotationSamePoints() {
        let angle = RotationGestureState.calculateAngle(
            x1: 100, y1: 100,
            x2: 100, y2: 100
        )

        // atan2(0, 0) = 0
        #expect(angle == 0.0)
    }

    @Test("Rotation with very small distance")
    func testRotationSmallDistance() {
        let angle = RotationGestureState.calculateAngle(
            x1: 100.0, y1: 100.0,
            x2: 100.1, y2: 100.1
        )

        // Should still calculate correctly
        let expectedAngle = Double.pi / 4.0  // 45 degrees
        #expect(abs(angle - expectedAngle) < 0.001)
    }

    @Test("Rotation with very large coordinates")
    func testRotationLargeCoordinates() {
        let angle = RotationGestureState.calculateAngle(
            x1: 1000000, y1: 1000000,
            x2: 2000000, y2: 2000000
        )

        // Should still be 45 degrees
        let expectedAngle = Double.pi / 4.0
        #expect(abs(angle - expectedAngle) < 0.001)
    }

    @Test("Rotation with negative coordinates")
    func testRotationNegativeCoordinates() {
        let angle = RotationGestureState.calculateAngle(
            x1: -100, y1: -100,
            x2: 0, y2: 0
        )

        // Should be 45 degrees
        let expectedAngle = Double.pi / 4.0
        #expect(abs(angle - expectedAngle) < 0.001)
    }

    @Test("Rotation crossing 180-degree boundary")
    func testRotationCrossingBoundary() {
        // Start at 170 degrees
        let initialAngle = 170.0 * Double.pi / 180.0

        // End at -170 degrees (or 190 degrees)
        let currentAngle = -170.0 * Double.pi / 180.0

        let state = RotationGestureState(
            initialAngle: initialAngle,
            currentAngle: currentAngle
        )

        let rotation = state.rotation
        // Should be -340 degrees (or equivalent to 20 degrees)
        #expect(abs(rotation.degrees - (-340.0)) < 0.1)
    }

    // MARK: - Angle Type Integration

    @Test("RotationGesture produces Angle values")
    func testRotationGestureAngleValue() {
        let state = RotationGestureState(
            initialAngle: 0.0,
            currentAngle: Double.pi / 2.0
        )

        let rotation = state.rotation
        #expect(rotation.degrees == 90.0)
        #expect(abs(rotation.radians - Double.pi / 2.0) < 0.001)
    }

    @Test("Angle conversion in rotation context")
    func testAngleConversionInRotation() {
        var state = RotationGestureState(
            initialAngle: 0.0,
            currentAngle: 0.0
        )

        // Update to 30 degrees
        let targetRadians = 30.0 * Double.pi / 180.0
        state.currentAngle = targetRadians

        let rotation = state.rotation
        #expect(abs(rotation.degrees - 30.0) < 0.001)
    }
}
