import Testing
import Foundation
@testable import Raven

/// Comprehensive test suite for MagnificationGesture.
///
/// This test suite verifies:
/// - MagnificationGesture creation and configuration
/// - Distance calculation between two touch points
/// - Scale factor calculation
/// - Zoom tracking and state management
/// - Web event mapping (touch events)
/// - Desktop fallback (wheel events with modifiers)
/// - Minimum scale constraints
/// - Edge cases and boundary conditions
@Suite("MagnificationGesture Tests")
@MainActor
struct MagnificationGestureTests {

    // MARK: - MagnificationGesture Creation Tests

    @Test("MagnificationGesture default initialization")
    func testMagnificationGestureDefaultInit() {
        let gesture = MagnificationGesture()
        #expect(gesture.minimumScaleDelta == 0.01)
    }

    @Test("MagnificationGesture with custom minimum scale")
    func testMagnificationGestureCustomMinimum() {
        let gesture = MagnificationGesture(minimumScaleDelta: 0.5)
        #expect(gesture.minimumScaleDelta == 0.5)
    }

    @Test("MagnificationGesture clamps negative minimum scale")
    func testMagnificationGestureNegativeMinimum() {
        let gesture = MagnificationGesture(minimumScaleDelta: -0.5)
        #expect(gesture.minimumScaleDelta == 0.01)
    }

    @Test("MagnificationGesture clamps zero minimum scale")
    func testMagnificationGestureZeroMinimum() {
        let gesture = MagnificationGesture(minimumScaleDelta: 0.0)
        #expect(gesture.minimumScaleDelta == 0.01)
    }

    // MARK: - MagnificationGesture Type Conformance Tests

    @Test("MagnificationGesture conforms to Gesture protocol")
    func testMagnificationGestureConformance() {
        let gesture = MagnificationGesture()

        // Verify Value type is CGFloat
        #expect(MagnificationGesture.Value.self == CGFloat.self)

        // Verify Body type is Never (primitive gesture)
        #expect(MagnificationGesture.Body.self == Never.self)
    }

    @Test("MagnificationGesture is Sendable")
    func testMagnificationGestureSendable() {
        let gesture = MagnificationGesture()
        let _: any Sendable = gesture
        #expect(true) // If this compiles, MagnificationGesture is Sendable
    }

    // MARK: - Distance Calculation Tests

    @Test("Calculate distance for horizontal separation")
    func testDistanceCalculationHorizontal() {
        // Two points 100 units apart horizontally
        let distance = MagnificationGestureState.calculateDistance(
            x1: 0, y1: 0,
            x2: 100, y2: 0
        )

        #expect(distance == 100.0)
    }

    @Test("Calculate distance for vertical separation")
    func testDistanceCalculationVertical() {
        // Two points 100 units apart vertically
        let distance = MagnificationGestureState.calculateDistance(
            x1: 0, y1: 0,
            x2: 0, y2: 100
        )

        #expect(distance == 100.0)
    }

    @Test("Calculate distance for diagonal separation")
    func testDistanceCalculationDiagonal() {
        // Pythagorean theorem: 3-4-5 triangle
        let distance = MagnificationGestureState.calculateDistance(
            x1: 0, y1: 0,
            x2: 3, y2: 4
        )

        #expect(distance == 5.0)
    }

    @Test("Calculate distance for equal points")
    func testDistanceCalculationSamePoint() {
        let distance = MagnificationGestureState.calculateDistance(
            x1: 100, y1: 100,
            x2: 100, y2: 100
        )

        #expect(distance == 0.0)
    }

    @Test("Calculate distance with negative coordinates")
    func testDistanceCalculationNegativeCoordinates() {
        let distance = MagnificationGestureState.calculateDistance(
            x1: -50, y1: -50,
            x2: 50, y2: 50
        )

        // Distance should be sqrt(100^2 + 100^2) = sqrt(20000) ≈ 141.42
        let expectedDistance = sqrt(100.0 * 100.0 + 100.0 * 100.0)
        #expect(abs(distance - expectedDistance) < 0.01)
    }

    @Test("Calculate distance with large coordinates")
    func testDistanceCalculationLargeCoordinates() {
        let distance = MagnificationGestureState.calculateDistance(
            x1: 0, y1: 0,
            x2: 1000000, y2: 1000000
        )

        let expectedDistance = sqrt(2.0) * 1000000.0
        #expect(abs(distance - expectedDistance) < 1.0)
    }

    // MARK: - MagnificationGestureState Tests

    @Test("MagnificationGestureState initialization")
    func testMagnificationGestureStateInit() {
        let state = MagnificationGestureState(
            initialDistance: 100.0,
            currentDistance: 100.0,
            minimumScale: 0.01
        )

        #expect(state.initialDistance == 100.0)
        #expect(state.currentDistance == 100.0)
        #expect(state.scale == 1.0)
    }

    @Test("MagnificationGestureState prevents zero initial distance")
    func testMagnificationGestureStateZeroInitialDistance() {
        let state = MagnificationGestureState(
            initialDistance: 0.0,
            currentDistance: 50.0,
            minimumScale: 0.01
        )

        // Should clamp to 1.0 to prevent division by zero
        #expect(state.initialDistance == 1.0)
    }

    @Test("MagnificationGestureState scale calculation - no change")
    func testMagnificationGestureStateScaleNoChange() {
        let state = MagnificationGestureState(
            initialDistance: 100.0,
            currentDistance: 100.0,
            minimumScale: 0.01
        )

        #expect(state.scale == 1.0)
    }

    @Test("MagnificationGestureState scale calculation - zoom in 2x")
    func testMagnificationGestureStateScaleZoomIn() {
        let state = MagnificationGestureState(
            initialDistance: 100.0,
            currentDistance: 200.0,
            minimumScale: 0.01
        )

        #expect(state.scale == 2.0)
    }

    @Test("MagnificationGestureState scale calculation - zoom out 0.5x")
    func testMagnificationGestureStateScaleZoomOut() {
        let state = MagnificationGestureState(
            initialDistance: 100.0,
            currentDistance: 50.0,
            minimumScale: 0.01
        )

        #expect(state.scale == 0.5)
    }

    @Test("MagnificationGestureState scale calculation - large zoom in")
    func testMagnificationGestureStateLargeZoomIn() {
        let state = MagnificationGestureState(
            initialDistance: 50.0,
            currentDistance: 500.0,
            minimumScale: 0.01
        )

        #expect(state.scale == 10.0)
    }

    @Test("MagnificationGestureState respects minimum scale")
    func testMagnificationGestureStateMinimumScale() {
        let state = MagnificationGestureState(
            initialDistance: 100.0,
            currentDistance: 1.0,  // Very small distance
            minimumScale: 0.1
        )

        // Scale would be 0.01, but should be clamped to 0.1
        #expect(state.scale == 0.1)
    }

    @Test("MagnificationGestureState update distance")
    func testMagnificationGestureStateUpdateDistance() {
        var state = MagnificationGestureState(
            initialDistance: 100.0,
            currentDistance: 100.0,
            minimumScale: 0.01
        )

        // Update to points 200 units apart horizontally
        state.updateDistance(x1: 0, y1: 0, x2: 200, y2: 0)

        #expect(state.currentDistance == 200.0)
        #expect(state.scale == 2.0)
    }

    // MARK: - Web Event Mapping Tests

    @Test("MagnificationGesture primary event name is touchstart")
    func testMagnificationGesturePrimaryEventName() {
        let gesture = MagnificationGesture()
        #expect(gesture.primaryEventName == "touchstart")
    }

    @Test("MagnificationGesture move event names include touchmove")
    func testMagnificationGestureMoveEventNames() {
        let gesture = MagnificationGesture()
        #expect(gesture.moveEventNames.contains("touchmove"))
    }

    @Test("MagnificationGesture end event names")
    func testMagnificationGestureEndEventNames() {
        let gesture = MagnificationGesture()
        #expect(gesture.endEventNames.contains("touchend"))
        #expect(gesture.endEventNames.contains("touchcancel"))
    }

    @Test("MagnificationGesture wheel event name")
    func testMagnificationGestureWheelEventName() {
        let gesture = MagnificationGesture()
        #expect(gesture.wheelEventName == "wheel")
    }

    @Test("MagnificationGesture requires 2 touches")
    func testMagnificationGestureValidTouchCount() {
        let gesture = MagnificationGesture()

        #expect(!gesture.isValidTouchCount(0))
        #expect(!gesture.isValidTouchCount(1))
        #expect(gesture.isValidTouchCount(2))
        #expect(!gesture.isValidTouchCount(3))
        #expect(!gesture.isValidTouchCount(4))
    }

    @Test("MagnificationGesture wheel event requires Ctrl key")
    func testMagnificationGestureWheelEventModifier() {
        let gesture = MagnificationGesture()

        #expect(!gesture.isMagnificationWheelEvent(ctrlKey: false))
        #expect(gesture.isMagnificationWheelEvent(ctrlKey: true))
    }

    @Test("MagnificationGesture wheel delta to scale conversion")
    func testMagnificationGestureWheelDeltaConversion() {
        let gesture = MagnificationGesture()

        // Positive delta (wheel down) should give scale < 1 (zoom out)
        let scale1 = gesture.wheelDeltaToScale(delta: 100)
        #expect(scale1 < 1.0)

        // Negative delta (wheel up) should give scale > 1 (zoom in)
        let scale2 = gesture.wheelDeltaToScale(delta: -100)
        #expect(scale2 > 1.0)

        // Zero delta should give scale = 1 (no change)
        let scale3 = gesture.wheelDeltaToScale(delta: 0)
        #expect(scale3 == 1.0)
    }

    @Test("MagnificationGesture wheel delta respects minimum scale")
    func testMagnificationGestureWheelDeltaMinimum() {
        let gesture = MagnificationGesture(minimumScaleDelta: 0.5)

        // Large positive delta would normally give very small scale
        let scale = gesture.wheelDeltaToScale(delta: 10000)

        // Should be clamped to minimum
        #expect(scale >= 0.5)
    }

    // MARK: - Magnification Scenarios

    @Test("Pinch to zoom in - fingers moving apart")
    func testPinchZoomIn() {
        var state = MagnificationGestureState(
            initialDistance: 100.0,
            currentDistance: 100.0,
            minimumScale: 0.01
        )

        // Fingers move apart to 150 units
        state.updateDistance(x1: 0, y1: 0, x2: 150, y2: 0)

        #expect(state.scale == 1.5)
    }

    @Test("Pinch to zoom out - fingers moving together")
    func testPinchZoomOut() {
        var state = MagnificationGestureState(
            initialDistance: 200.0,
            currentDistance: 200.0,
            minimumScale: 0.01
        )

        // Fingers move together to 100 units
        state.updateDistance(x1: 0, y1: 0, x2: 100, y2: 0)

        #expect(state.scale == 0.5)
    }

    @Test("Progressive zoom in")
    func testProgressiveZoomIn() {
        var state = MagnificationGestureState(
            initialDistance: 100.0,
            currentDistance: 100.0,
            minimumScale: 0.01
        )

        // Step 1: Zoom to 1.2x
        state.currentDistance = 120.0
        #expect(abs(state.scale - 1.2) < 0.001)

        // Step 2: Zoom to 1.5x
        state.currentDistance = 150.0
        #expect(abs(state.scale - 1.5) < 0.001)

        // Step 3: Zoom to 2x
        state.currentDistance = 200.0
        #expect(state.scale == 2.0)
    }

    @Test("Progressive zoom out")
    func testProgressiveZoomOut() {
        var state = MagnificationGestureState(
            initialDistance: 100.0,
            currentDistance: 100.0,
            minimumScale: 0.01
        )

        // Step 1: Zoom to 0.8x
        state.currentDistance = 80.0
        #expect(abs(state.scale - 0.8) < 0.001)

        // Step 2: Zoom to 0.5x
        state.currentDistance = 50.0
        #expect(abs(state.scale - 0.5) < 0.001)

        // Step 3: Zoom to 0.25x
        state.currentDistance = 25.0
        #expect(abs(state.scale - 0.25) < 0.001)
    }

    // MARK: - Edge Cases

    @Test("Magnification with very small initial distance")
    func testMagnificationSmallInitialDistance() {
        let state = MagnificationGestureState(
            initialDistance: 0.5,
            currentDistance: 1.0,
            minimumScale: 0.01
        )

        // Should still calculate correctly (clamped to 1.0)
        #expect(state.scale == 1.0)
    }

    @Test("Magnification with very large distances")
    func testMagnificationLargeDistances() {
        let state = MagnificationGestureState(
            initialDistance: 1000.0,
            currentDistance: 2000.0,
            minimumScale: 0.01
        )

        #expect(state.scale == 2.0)
    }

    @Test("Magnification approaching zero distance")
    func testMagnificationApproachingZero() {
        let state = MagnificationGestureState(
            initialDistance: 100.0,
            currentDistance: 0.1,
            minimumScale: 0.01
        )

        // Scale would be 0.001, clamped to minimum
        #expect(state.scale >= 0.01)
    }

    @Test("Magnification with diagonal touch movement")
    func testMagnificationDiagonalMovement() {
        var state = MagnificationGestureState(
            initialDistance: 100.0,
            currentDistance: 100.0,
            minimumScale: 0.01
        )

        // Update with diagonal separation (3-4-5 triangle scaled to 300-400-500)
        state.updateDistance(x1: 0, y1: 0, x2: 300, y2: 400)

        #expect(state.currentDistance == 500.0)
        #expect(state.scale == 5.0)
    }

    @Test("Magnification fractional scales")
    func testMagnificationFractionalScales() {
        let state = MagnificationGestureState(
            initialDistance: 100.0,
            currentDistance: 133.33,
            minimumScale: 0.01
        )

        #expect(abs(state.scale - 1.3333) < 0.001)
    }

    // MARK: - Scale Factor Integration

    @Test("Scale factor 1.0 means no magnification")
    func testScaleFactorNoChange() {
        let state = MagnificationGestureState(
            initialDistance: 200.0,
            currentDistance: 200.0,
            minimumScale: 0.01
        )

        #expect(state.scale == 1.0)
    }

    @Test("Scale factor greater than 1 means zoom in")
    func testScaleFactorZoomIn() {
        let state = MagnificationGestureState(
            initialDistance: 100.0,
            currentDistance: 250.0,
            minimumScale: 0.01
        )

        #expect(state.scale > 1.0)
        #expect(state.scale == 2.5)
    }

    @Test("Scale factor less than 1 means zoom out")
    func testScaleFactorZoomOut() {
        let state = MagnificationGestureState(
            initialDistance: 100.0,
            currentDistance: 25.0,
            minimumScale: 0.01
        )

        #expect(state.scale < 1.0)
        #expect(state.scale == 0.25)
    }

    @Test("Multiple minimum scale values")
    func testMultipleMinimumScales() {
        let state1 = MagnificationGestureState(
            initialDistance: 100.0,
            currentDistance: 1.0,
            minimumScale: 0.1
        )
        #expect(state1.scale == 0.1)

        let state2 = MagnificationGestureState(
            initialDistance: 100.0,
            currentDistance: 1.0,
            minimumScale: 0.5
        )
        #expect(state2.scale == 0.5)

        let state3 = MagnificationGestureState(
            initialDistance: 100.0,
            currentDistance: 1.0,
            minimumScale: 1.0
        )
        #expect(state3.scale == 1.0)
    }

    @Test("Extreme zoom levels")
    func testExtremeZoomLevels() {
        // 10x zoom
        let state1 = MagnificationGestureState(
            initialDistance: 10.0,
            currentDistance: 100.0,
            minimumScale: 0.01
        )
        #expect(state1.scale == 10.0)

        // 0.1x zoom
        let state2 = MagnificationGestureState(
            initialDistance: 100.0,
            currentDistance: 10.0,
            minimumScale: 0.01
        )
        #expect(state2.scale == 0.1)
    }
}
