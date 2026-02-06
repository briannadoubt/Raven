import Testing
import Foundation
@testable import Raven

// Type aliases to avoid ambiguity with CoreFoundation types
typealias RPoint = Raven.CGPoint
typealias RSize = Raven.CGSize
typealias RRect = Raven.CGRect

/// Comprehensive test suite for DragGesture.
///
/// This test suite verifies:
/// - DragGesture creation and configuration
/// - DragGesture.Value construction and properties
/// - Translation calculation
/// - Velocity calculation
/// - Predicted end location calculation
/// - Minimum distance threshold
/// - Coordinate space handling
/// - Internal state management
/// - Edge cases and boundary conditions
@Suite("DragGesture Tests")
@MainActor
struct DragGestureTests {

    // MARK: - DragGesture Creation Tests

    @Test("DragGesture default initialization")
    func testDragGestureDefaultInit() {
        let gesture = DragGesture()
        #expect(gesture.minimumDistance == 10.0)
        #expect(gesture.coordinateSpace == .local)
    }

    @Test("DragGesture with minimum distance parameter")
    func testDragGestureWithMinimumDistance() {
        let gesture = DragGesture(minimumDistance: 20)
        #expect(gesture.minimumDistance == 20.0)
        #expect(gesture.coordinateSpace == .local)
    }

    @Test("DragGesture with coordinate space parameter")
    func testDragGestureWithCoordinateSpace() {
        let localGesture = DragGesture(coordinateSpace: .local)
        let globalGesture = DragGesture(coordinateSpace: .global)
        let namedGesture = DragGesture(coordinateSpace: .named("container"))

        #expect(localGesture.minimumDistance == 10.0)
        #expect(localGesture.coordinateSpace == .local)

        #expect(globalGesture.minimumDistance == 10.0)
        #expect(globalGesture.coordinateSpace == .global)

        #expect(namedGesture.minimumDistance == 10.0)
        #expect(namedGesture.coordinateSpace == .named("container"))
    }

    @Test("DragGesture with both parameters")
    func testDragGestureWithBothParameters() {
        let gesture = DragGesture(minimumDistance: 15, coordinateSpace: .global)
        #expect(gesture.minimumDistance == 15.0)
        #expect(gesture.coordinateSpace == .global)
    }

    @Test("DragGesture clamps negative minimum distance to zero")
    func testDragGestureNegativeMinimumDistance() {
        let gesture = DragGesture(minimumDistance: -5)
        #expect(gesture.minimumDistance == 0.0)
    }

    @Test("DragGesture supports zero minimum distance")
    func testDragGestureZeroMinimumDistance() {
        let gesture = DragGesture(minimumDistance: 0)
        #expect(gesture.minimumDistance == 0.0)
    }

    @Test("DragGesture supports large minimum distance")
    func testDragGestureLargeMinimumDistance() {
        let gesture = DragGesture(minimumDistance: 1000)
        #expect(gesture.minimumDistance == 1000.0)
    }

    // MARK: - DragGesture Type Conformance Tests

    @Test("DragGesture conforms to Gesture protocol")
    func testDragGestureConformance() {
        let gesture = DragGesture()

        // Verify Value type is DragGesture.Value
        #expect(DragGesture.Value.self == DragGesture.Value.self)

        // Verify Body type is Never (primitive gesture)
        #expect(DragGesture.Body.self == Never.self)
    }

    @Test("DragGesture is Sendable")
    func testDragGestureSendable() {
        let gesture = DragGesture()
        let _: any Sendable = gesture
        #expect(true) // If this compiles, DragGesture is Sendable
    }

    // MARK: - DragGesture.Value Creation Tests

    @Test("DragGesture.Value basic initialization")
    func testValueBasicInit() {
        let start = RPoint(x: 100, y: 100)
        let current = RPoint(x: 150, y: 200)
        let value = DragGesture.Value(location: current, startLocation: start)

        #expect(value.location == current)
        #expect(value.startLocation == start)
        #expect(value.velocity == RSize(width: 0, height: 0))
        #expect(value.predictedEndLocation == current) // Defaults to current location
    }

    @Test("DragGesture.Value with velocity")
    func testValueWithVelocity() {
        let start = RPoint(x: 100, y: 100)
        let current = RPoint(x: 150, y: 200)
        let velocity = RSize(width: 500, height: -300)

        let value = DragGesture.Value(
            location: current,
            startLocation: start,
            velocity: velocity
        )

        #expect(value.velocity == velocity)
    }

    @Test("DragGesture.Value with predicted end location")
    func testValueWithPredictedEndLocation() {
        let start = RPoint(x: 100, y: 100)
        let current = RPoint(x: 150, y: 200)
        let predicted = RPoint(x: 200, y: 300)

        let value = DragGesture.Value(
            location: current,
            startLocation: start,
            predictedEndLocation: predicted
        )

        #expect(value.predictedEndLocation == predicted)
    }

    // MARK: - Translation Calculation Tests

    @Test("DragGesture.Value translation calculation - positive values")
    func testTranslationCalculationPositive() {
        let start = RPoint(x: 100, y: 100)
        let current = RPoint(x: 150, y: 200)
        let value = DragGesture.Value(location: current, startLocation: start)

        let translation = value.translation
        #expect(translation.width == 50)
        #expect(translation.height == 100)
    }

    @Test("DragGesture.Value translation calculation - negative values")
    func testTranslationCalculationNegative() {
        let start = RPoint(x: 100, y: 100)
        let current = RPoint(x: 50, y: 25)
        let value = DragGesture.Value(location: current, startLocation: start)

        let translation = value.translation
        #expect(translation.width == -50)
        #expect(translation.height == -75)
    }

    @Test("DragGesture.Value translation calculation - no movement")
    func testTranslationCalculationNoMovement() {
        let start = RPoint(x: 100, y: 100)
        let value = DragGesture.Value(location: start, startLocation: start)

        let translation = value.translation
        #expect(translation.width == 0)
        #expect(translation.height == 0)
    }

    @Test("DragGesture.Value translation with fractional values")
    func testTranslationCalculationFractional() {
        let start = RPoint(x: 100.5, y: 100.25)
        let current = RPoint(x: 125.75, y: 150.5)
        let value = DragGesture.Value(location: current, startLocation: start)

        let translation = value.translation
        #expect(translation.width == 25.25)
        #expect(translation.height == 50.25)
    }

    // MARK: - Predicted End Translation Tests

    @Test("DragGesture.Value predicted end translation calculation")
    func testPredictedEndTranslationCalculation() {
        let start = RPoint(x: 100, y: 100)
        let current = RPoint(x: 150, y: 200)
        let predicted = RPoint(x: 200, y: 300)

        let value = DragGesture.Value(
            location: current,
            startLocation: start,
            predictedEndLocation: predicted
        )

        let predictedTranslation = value.predictedEndTranslation
        #expect(predictedTranslation.width == 100)
        #expect(predictedTranslation.height == 200)
    }

    @Test("DragGesture.Value predicted end translation with negative values")
    func testPredictedEndTranslationNegative() {
        let start = RPoint(x: 100, y: 100)
        let current = RPoint(x: 90, y: 80)
        let predicted = RPoint(x: 50, y: 25)

        let value = DragGesture.Value(
            location: current,
            startLocation: start,
            predictedEndLocation: predicted
        )

        let predictedTranslation = value.predictedEndTranslation
        #expect(predictedTranslation.width == -50)
        #expect(predictedTranslation.height == -75)
    }

    // MARK: - Value Equality Tests

    @Test("DragGesture.Value equality with identical values")
    func testValueEqualityIdentical() {
        let time = Date(timeIntervalSince1970: 1000)
        let value1 = DragGesture.Value(
            location: RPoint(x: 100, y: 100),
            startLocation: RPoint(x: 50, y: 50),
            velocity: RSize(width: 200, height: 300),
            predictedEndLocation: RPoint(x: 150, y: 200),
            time: time
        )
        let value2 = DragGesture.Value(
            location: RPoint(x: 100, y: 100),
            startLocation: RPoint(x: 50, y: 50),
            velocity: RSize(width: 200, height: 300),
            predictedEndLocation: RPoint(x: 150, y: 200),
            time: time
        )

        #expect(value1 == value2)
    }

    @Test("DragGesture.Value equality with different locations")
    func testValueEqualityDifferentLocations() {
        let time = Date()
        let value1 = DragGesture.Value(
            location: RPoint(x: 100, y: 100),
            startLocation: RPoint(x: 50, y: 50),
            time: time
        )
        let value2 = DragGesture.Value(
            location: RPoint(x: 101, y: 100),
            startLocation: RPoint(x: 50, y: 50),
            time: time
        )

        #expect(value1 != value2)
    }

    @Test("DragGesture.Value equality with similar timestamps")
    func testValueEqualitySimilarTimestamps() {
        let time1 = Date(timeIntervalSince1970: 1000.0000)
        let time2 = Date(timeIntervalSince1970: 1000.0005) // Within 0.001s threshold

        let value1 = DragGesture.Value(
            location: RPoint(x: 100, y: 100),
            startLocation: RPoint(x: 50, y: 50),
            time: time1
        )
        let value2 = DragGesture.Value(
            location: RPoint(x: 100, y: 100),
            startLocation: RPoint(x: 50, y: 50),
            time: time2
        )

        #expect(value1 == value2)
    }

    // MARK: - Coordinate Space Extraction Tests

    @Test("DragGesture extracts local coordinates")
    func testExtractLocationLocal() {
        let gesture = DragGesture(coordinateSpace: .local)
        let elementBounds = RRect(x: 100, y: 100, width: 200, height: 200)

        let location = gesture.extractLocation(
            clientX: 150,
            clientY: 200,
            elementBounds: elementBounds
        )

        #expect(location.x == 50)
        #expect(location.y == 100)
    }

    @Test("DragGesture extracts global coordinates")
    func testExtractLocationGlobal() {
        let gesture = DragGesture(coordinateSpace: .global)
        let elementBounds = RRect(x: 100, y: 100, width: 200, height: 200)

        let location = gesture.extractLocation(
            clientX: 250,
            clientY: 300,
            elementBounds: elementBounds
        )

        #expect(location.x == 250)
        #expect(location.y == 300)
    }

    @Test("DragGesture extracts named coordinates")
    func testExtractLocationNamed() {
        let gesture = DragGesture(coordinateSpace: .named("container"))
        let elementBounds = RRect(x: 200, y: 200, width: 100, height: 100)
        let ancestorBounds = RRect(x: 50, y: 50, width: 400, height: 400)

        let location = gesture.extractLocation(
            clientX: 225,
            clientY: 275,
            elementBounds: elementBounds,
            namedAncestorBounds: ancestorBounds
        )

        #expect(location.x == 175)
        #expect(location.y == 225)
    }

    @Test("DragGesture named coordinates fallback to global")
    func testExtractLocationNamedFallback() {
        let gesture = DragGesture(coordinateSpace: .named("missing"))
        let elementBounds = RRect(x: 100, y: 100, width: 200, height: 200)

        let location = gesture.extractLocation(
            clientX: 150,
            clientY: 200,
            elementBounds: elementBounds
        )

        // Should fallback to global coordinates
        #expect(location.x == 150)
        #expect(location.y == 200)
    }

    // MARK: - Internal State Tests

    @Test("DragGestureState initialization")
    func testDragGestureStateInit() {
        let startLocation = RPoint(x: 100, y: 100)
        let startTime = Date().timeIntervalSince1970
        let state = DragGestureState(
            startLocation: startLocation,
            startTime: startTime,
            minimumDistance: 10
        )

        #expect(state.startLocation == startLocation)
        #expect(state.startTime == startTime)
        #expect(state.minimumDistance == 10)
        #expect(state.isRecognized == false)
        #expect(state.positionSamples.count == 1)
        #expect(state.positionSamples[0].location == startLocation)
    }

    @Test("DragGestureState minimum distance check - below threshold")
    func testDragGestureStateMinimumDistanceBelowThreshold() {
        let startLocation = RPoint(x: 100, y: 100)
        let state = DragGestureState(
            startLocation: startLocation,
            startTime: Date().timeIntervalSince1970,
            minimumDistance: 10
        )

        // Move 5 points (below 10 point threshold)
        let currentLocation = RPoint(x: 105, y: 100)
        let exceeded = state.hasExceededMinimumDistance(to: currentLocation)

        #expect(!exceeded)
    }

    @Test("DragGestureState minimum distance check - at threshold")
    func testDragGestureStateMinimumDistanceAtThreshold() {
        let startLocation = RPoint(x: 100, y: 100)
        let state = DragGestureState(
            startLocation: startLocation,
            startTime: Date().timeIntervalSince1970,
            minimumDistance: 10
        )

        // Move exactly 10 points
        let currentLocation = RPoint(x: 110, y: 100)
        let exceeded = state.hasExceededMinimumDistance(to: currentLocation)

        #expect(exceeded)
    }

    @Test("DragGestureState minimum distance check - above threshold")
    func testDragGestureStateMinimumDistanceAboveThreshold() {
        let startLocation = RPoint(x: 100, y: 100)
        let state = DragGestureState(
            startLocation: startLocation,
            startTime: Date().timeIntervalSince1970,
            minimumDistance: 10
        )

        // Move 15 points (above 10 point threshold)
        let currentLocation = RPoint(x: 100, y: 115)
        let exceeded = state.hasExceededMinimumDistance(to: currentLocation)

        #expect(exceeded)
    }

    @Test("DragGestureState minimum distance with diagonal movement")
    func testDragGestureStateMinimumDistanceDiagonal() {
        let startLocation = RPoint(x: 0, y: 0)
        let state = DragGestureState(
            startLocation: startLocation,
            startTime: Date().timeIntervalSince1970,
            minimumDistance: 10
        )

        // Move 6 points right, 8 points up = 10 points diagonal (3-4-5 triangle)
        let currentLocation = RPoint(x: 6, y: 8)
        let exceeded = state.hasExceededMinimumDistance(to: currentLocation)

        #expect(exceeded)
    }

    @Test("DragGestureState adding position samples")
    func testDragGestureStateAddingSamples() {
        var state = DragGestureState(
            startLocation: RPoint(x: 0, y: 0),
            startTime: 1000.0,
            minimumDistance: 10
        )

        state.addSample(location: RPoint(x: 10, y: 10), time: 1000.05)
        state.addSample(location: RPoint(x: 20, y: 20), time: 1000.10)

        #expect(state.positionSamples.count == 3) // Initial + 2 added
    }

    @Test("DragGestureState removes old samples")
    func testDragGestureStateRemovesOldSamples() {
        var state = DragGestureState(
            startLocation: RPoint(x: 0, y: 0),
            startTime: 1000.0,
            minimumDistance: 10
        )

        // Add samples over time
        state.addSample(location: RPoint(x: 10, y: 10), time: 1000.05)
        state.addSample(location: RPoint(x: 20, y: 20), time: 1000.10)
        state.addSample(location: RPoint(x: 30, y: 30), time: 1000.15)

        // Add a sample well outside the 100ms velocity window
        state.addSample(location: RPoint(x: 100, y: 100), time: 1000.50)

        // Old samples should be removed (outside 100ms window)
        #expect(state.positionSamples.count < 5)
        #expect(state.positionSamples.last?.location == RPoint(x: 100, y: 100))
    }

    @Test("DragGestureState limits maximum samples")
    func testDragGestureStateLimitsMaxSamples() {
        var state = DragGestureState(
            startLocation: RPoint(x: 0, y: 0),
            startTime: 1000.0,
            minimumDistance: 10
        )

        // Add more than maxSamples (10)
        for i in 1...15 {
            state.addSample(
                location: RPoint(x: Double(i * 10), y: Double(i * 10)),
                time: 1000.0 + Double(i) * 0.01
            )
        }

        // Should be limited to maxSamples
        #expect(state.positionSamples.count <= DragGestureState.maxSamples)
    }

    // MARK: - Velocity Calculation Tests

    @Test("DragGestureState velocity calculation with no movement")
    func testVelocityCalculationNoMovement() {
        let state = DragGestureState(
            startLocation: RPoint(x: 100, y: 100),
            startTime: 1000.0,
            minimumDistance: 10
        )

        let velocity = state.calculateVelocity()
        #expect(velocity == RSize(width: 0, height: 0))
    }

    @Test("DragGestureState velocity calculation with single sample")
    func testVelocityCalculationSingleSample() {
        let state = DragGestureState(
            startLocation: RPoint(x: 100, y: 100),
            startTime: 1000.0,
            minimumDistance: 10
        )

        let velocity = state.calculateVelocity()
        #expect(velocity == RSize(width: 0, height: 0))
    }

    @Test("DragGestureState velocity calculation with two samples")
    func testVelocityCalculationTwoSamples() {
        var state = DragGestureState(
            startLocation: RPoint(x: 0, y: 0),
            startTime: 1000.0,
            minimumDistance: 10
        )

        // Move 100 points in 0.1 seconds = 1000 points/second
        state.addSample(location: RPoint(x: 100, y: 0), time: 1000.1)

        let velocity = state.calculateVelocity()
        #expect(abs(velocity.width - 1000.0) < 0.01)
        #expect(velocity.height == 0.0)
    }

    @Test("DragGestureState velocity calculation with multiple samples")
    func testVelocityCalculationMultipleSamples() {
        var state = DragGestureState(
            startLocation: RPoint(x: 0, y: 0),
            startTime: 1000.0,
            minimumDistance: 10
        )

        state.addSample(location: RPoint(x: 25, y: 0), time: 1000.025)
        state.addSample(location: RPoint(x: 50, y: 0), time: 1000.050)
        state.addSample(location: RPoint(x: 75, y: 0), time: 1000.075)
        state.addSample(location: RPoint(x: 100, y: 0), time: 1000.100)

        let velocity = state.calculateVelocity()
        // Should be approximately 1000 points/second
        #expect(abs(velocity.width - 1000.0) < 1.0)
        #expect(velocity.height == 0.0)
    }

    @Test("DragGestureState velocity calculation with vertical movement")
    func testVelocityCalculationVertical() {
        var state = DragGestureState(
            startLocation: RPoint(x: 0, y: 0),
            startTime: 1000.0,
            minimumDistance: 10
        )

        // Move 50 points down in 0.1 seconds = 500 points/second
        state.addSample(location: RPoint(x: 0, y: 50), time: 1000.1)

        let velocity = state.calculateVelocity()
        #expect(velocity.width == 0.0)
        #expect(abs(velocity.height - 500.0) < 0.01)
    }

    @Test("DragGestureState velocity calculation with negative movement")
    func testVelocityCalculationNegative() {
        var state = DragGestureState(
            startLocation: RPoint(x: 100, y: 100),
            startTime: 1000.0,
            minimumDistance: 10
        )

        // Move -100 points in 0.1 seconds = -1000 points/second
        state.addSample(location: RPoint(x: 0, y: 0), time: 1000.1)

        let velocity = state.calculateVelocity()
        #expect(abs(velocity.width - (-1000.0)) < 0.01)
        #expect(abs(velocity.height - (-1000.0)) < 0.01)
    }

    // MARK: - Predicted End Location Tests

    @Test("DragGestureState predicted end location with zero velocity")
    func testPredictedEndLocationZeroVelocity() {
        let state = DragGestureState(
            startLocation: RPoint(x: 0, y: 0),
            startTime: 1000.0,
            minimumDistance: 10
        )

        let currentLocation = RPoint(x: 50, y: 50)
        let velocity = RSize(width: 0, height: 0)
        let predicted = state.predictEndLocation(from: currentLocation, velocity: velocity)

        // With zero velocity, should predict current location
        #expect(predicted == currentLocation)
    }

    @Test("DragGestureState predicted end location with low velocity")
    func testPredictedEndLocationLowVelocity() {
        let state = DragGestureState(
            startLocation: RPoint(x: 0, y: 0),
            startTime: 1000.0,
            minimumDistance: 10
        )

        let currentLocation = RPoint(x: 50, y: 50)
        let velocity = RSize(width: 5, height: 5) // Below 10 threshold
        let predicted = state.predictEndLocation(from: currentLocation, velocity: velocity)

        // With very low velocity, should predict current location
        #expect(predicted == currentLocation)
    }

    @Test("DragGestureState predicted end location with horizontal velocity")
    func testPredictedEndLocationHorizontalVelocity() {
        let state = DragGestureState(
            startLocation: RPoint(x: 0, y: 0),
            startTime: 1000.0,
            minimumDistance: 10
        )

        let currentLocation = RPoint(x: 100, y: 100)
        let velocity = RSize(width: 1000, height: 0)
        let predicted = state.predictEndLocation(from: currentLocation, velocity: velocity)

        // Should predict movement in the direction of velocity
        #expect(predicted.x > currentLocation.x)
        #expect(predicted.y == currentLocation.y)
    }

    @Test("DragGestureState predicted end location with negative velocity")
    func testPredictedEndLocationNegativeVelocity() {
        let state = DragGestureState(
            startLocation: RPoint(x: 0, y: 0),
            startTime: 1000.0,
            minimumDistance: 10
        )

        let currentLocation = RPoint(x: 100, y: 100)
        let velocity = RSize(width: -500, height: -500)
        let predicted = state.predictEndLocation(from: currentLocation, velocity: velocity)

        // Should predict movement in the direction of negative velocity
        #expect(predicted.x < currentLocation.x)
        #expect(predicted.y < currentLocation.y)
    }

    // MARK: - Event Names Tests

    @Test("DragGesture event names are correct")
    func testEventNames() {
        #expect(DragGesture.EventNames.down == "pointerdown")
        #expect(DragGesture.EventNames.move == "pointermove")
        #expect(DragGesture.EventNames.up == "pointerup")
        #expect(DragGesture.EventNames.cancel == "pointercancel")
    }

    // MARK: - Edge Cases and Boundary Conditions

    @Test("DragGesture with zero-sized element")
    func testDragGestureZeroSizedElement() {
        let gesture = DragGesture(coordinateSpace: .local)
        let elementBounds = RRect(x: 100, y: 100, width: 0, height: 0)

        let location = gesture.extractLocation(
            clientX: 100,
            clientY: 100,
            elementBounds: elementBounds
        )

        #expect(location.x == 0)
        #expect(location.y == 0)
    }

    @Test("DragGesture with negative element bounds")
    func testDragGestureNegativeElementBounds() {
        let gesture = DragGesture(coordinateSpace: .local)
        let elementBounds = RRect(x: -100, y: -100, width: 200, height: 200)

        let location = gesture.extractLocation(
            clientX: 0,
            clientY: 0,
            elementBounds: elementBounds
        )

        #expect(location.x == 100)
        #expect(location.y == 100)
    }

    @Test("DragGesture with very large coordinates")
    func testDragGestureVeryLargeCoordinates() {
        let gesture = DragGesture(coordinateSpace: .global)
        let elementBounds = RRect(x: 0, y: 0, width: 100, height: 100)

        let location = gesture.extractLocation(
            clientX: 100000,
            clientY: 100000,
            elementBounds: elementBounds
        )

        #expect(location.x == 100000)
        #expect(location.y == 100000)
    }

    @Test("DragGesture.Value with fractional coordinates")
    func testValueWithFractionalCoordinates() {
        let start = RPoint(x: 100.123, y: 100.456)
        let current = RPoint(x: 150.789, y: 200.321)
        let value = DragGesture.Value(location: current, startLocation: start)

        let translation = value.translation
        #expect(abs(translation.width - 50.666) < 0.001)
        #expect(abs(translation.height - 99.865) < 0.001)
    }

    @Test("DragGestureState velocity with zero time delta")
    func testVelocityWithZeroTimeDelta() {
        var state = DragGestureState(
            startLocation: RPoint(x: 0, y: 0),
            startTime: 1000.0,
            minimumDistance: 10
        )

        // Add sample at same time (zero delta)
        state.addSample(location: RPoint(x: 100, y: 100), time: 1000.0)

        let velocity = state.calculateVelocity()
        // Should return zero velocity when time delta is zero
        #expect(velocity == RSize(width: 0, height: 0))
    }

    @Test("DragGesture.Value is Sendable")
    func testValueSendable() {
        let value = DragGesture.Value(
            location: RPoint(x: 100, y: 100),
            startLocation: RPoint(x: 50, y: 50)
        )
        let _: any Sendable = value
        #expect(true) // If this compiles, Value is Sendable
    }

    @Test("Multiple DragGestures with different coordinate spaces")
    func testMultipleDragGesturesWithDifferentSpaces() {
        let gestures = [
            DragGesture(coordinateSpace: .local),
            DragGesture(coordinateSpace: .global),
            DragGesture(coordinateSpace: .named("space1")),
            DragGesture(coordinateSpace: .named("space2"))
        ]

        #expect(gestures[0].coordinateSpace == .local)
        #expect(gestures[1].coordinateSpace == .global)
        #expect(gestures[2].coordinateSpace == .named("space1"))
        #expect(gestures[3].coordinateSpace == .named("space2"))
    }

    @Test("DragGestureState constants are reasonable")
    func testDragGestureStateConstants() {
        #expect(DragGestureState.maxSamples == 10)
        #expect(DragGestureState.velocityWindow == 0.1)
        #expect(DragGestureState.frictionCoefficient > 0.0)
        #expect(DragGestureState.frictionCoefficient < 1.0)
    }
}
