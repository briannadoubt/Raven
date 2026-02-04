import Testing
import Foundation
@testable import Raven

/// Comprehensive test suite for TapGesture and SpatialTapGesture.
///
/// This test suite verifies:
/// - TapGesture creation and configuration
/// - Single tap recognition
/// - Multi-tap recognition (double, triple, etc.)
/// - SpatialTapGesture coordinate mapping
/// - Coordinate space handling
/// - Event matching logic
/// - Edge cases and boundary conditions
@Suite("TapGesture Tests")
@MainActor
struct TapGestureTests {

    // MARK: - TapGesture Creation Tests

    @Test("TapGesture default initialization creates single tap")
    func testTapGestureDefaultInit() {
        let gesture = TapGesture()
        #expect(gesture.count == 1)
    }

    @Test("TapGesture with explicit count")
    func testTapGestureWithCount() {
        let singleTap = TapGesture(count: 1)
        let doubleTap = TapGesture(count: 2)
        let tripleTap = TapGesture(count: 3)

        #expect(singleTap.count == 1)
        #expect(doubleTap.count == 2)
        #expect(tripleTap.count == 3)
    }

    @Test("TapGesture clamps negative count to 1")
    func testTapGestureNegativeCount() {
        let gesture = TapGesture(count: -1)
        #expect(gesture.count == 1)
    }

    @Test("TapGesture clamps zero count to 1")
    func testTapGestureZeroCount() {
        let gesture = TapGesture(count: 0)
        #expect(gesture.count == 1)
    }

    @Test("TapGesture supports large tap counts")
    func testTapGestureLargeCounts() {
        let gesture = TapGesture(count: 10)
        #expect(gesture.count == 10)
    }

    // MARK: - TapGesture Type Conformance Tests

    @Test("TapGesture conforms to Gesture protocol")
    func testTapGestureConformance() {
        let gesture = TapGesture()

        // Verify Value type is Void
        #expect(TapGesture.Value.self == Void.self)

        // Verify Body type is Never (primitive gesture)
        #expect(TapGesture.Body.self == Never.self)
    }

    @Test("TapGesture is Sendable")
    func testTapGestureSendable() {
        // Verify TapGesture conforms to Sendable
        let gesture = TapGesture()
        let _: any Sendable = gesture
        #expect(true) // If this compiles, TapGesture is Sendable
    }

    // MARK: - TapGesture Event Matching Tests

    @Test("TapGesture event name is 'click'")
    func testTapGestureEventName() {
        let gesture = TapGesture()
        #expect(gesture.eventName == "click")
    }

    @Test("TapGesture matches single click event")
    func testTapGestureMatchesSingleClick() {
        let gesture = TapGesture()
        #expect(gesture.matchesEvent(detail: 1))
        #expect(!gesture.matchesEvent(detail: 2))
        #expect(!gesture.matchesEvent(detail: 0))
    }

    @Test("TapGesture matches double click event")
    func testTapGestureMatchesDoubleClick() {
        let gesture = TapGesture(count: 2)
        #expect(!gesture.matchesEvent(detail: 1))
        #expect(gesture.matchesEvent(detail: 2))
        #expect(!gesture.matchesEvent(detail: 3))
    }

    @Test("TapGesture matches triple click event")
    func testTapGestureMatchesTripleClick() {
        let gesture = TapGesture(count: 3)
        #expect(!gesture.matchesEvent(detail: 1))
        #expect(!gesture.matchesEvent(detail: 2))
        #expect(gesture.matchesEvent(detail: 3))
        #expect(!gesture.matchesEvent(detail: 4))
    }

    // MARK: - SpatialTapGesture Creation Tests

    @Test("SpatialTapGesture default initialization")
    func testSpatialTapGestureDefaultInit() {
        let gesture = SpatialTapGesture()
        #expect(gesture.count == 1)
        #expect(gesture.coordinateSpace == .local)
    }

    @Test("SpatialTapGesture with count parameter")
    func testSpatialTapGestureWithCount() {
        let gesture = SpatialTapGesture(count: 2)
        #expect(gesture.count == 2)
        #expect(gesture.coordinateSpace == .local)
    }

    @Test("SpatialTapGesture with coordinate space parameter")
    func testSpatialTapGestureWithCoordinateSpace() {
        let localGesture = SpatialTapGesture(coordinateSpace: .local)
        let globalGesture = SpatialTapGesture(coordinateSpace: .global)
        let namedGesture = SpatialTapGesture(coordinateSpace: .named("test"))

        #expect(localGesture.coordinateSpace == .local)
        #expect(globalGesture.coordinateSpace == .global)
        #expect(namedGesture.coordinateSpace == .named("test"))
    }

    @Test("SpatialTapGesture with both parameters")
    func testSpatialTapGestureWithBothParameters() {
        let gesture = SpatialTapGesture(count: 3, coordinateSpace: .global)
        #expect(gesture.count == 3)
        #expect(gesture.coordinateSpace == .global)
    }

    @Test("SpatialTapGesture clamps negative count")
    func testSpatialTapGestureNegativeCount() {
        let gesture = SpatialTapGesture(count: -5)
        #expect(gesture.count == 1)
    }

    // MARK: - SpatialTapGesture Type Conformance Tests

    @Test("SpatialTapGesture conforms to Gesture protocol")
    func testSpatialTapGestureConformance() {
        let gesture = SpatialTapGesture()

        // Verify Value type is CGPoint
        #expect(SpatialTapGesture.Value.self == CGPoint.self)

        // Verify Body type is Never (primitive gesture)
        #expect(SpatialTapGesture.Body.self == Never.self)
    }

    @Test("SpatialTapGesture is Sendable")
    func testSpatialTapGestureSendable() {
        let gesture = SpatialTapGesture()
        let _: any Sendable = gesture
        #expect(true)
    }

    // MARK: - SpatialTapGesture Event Matching Tests

    @Test("SpatialTapGesture event name is 'click'")
    func testSpatialTapGestureEventName() {
        let gesture = SpatialTapGesture()
        #expect(gesture.eventName == "click")
    }

    @Test("SpatialTapGesture matches click events correctly")
    func testSpatialTapGestureMatchesEvents() {
        let singleTap = SpatialTapGesture()
        let doubleTap = SpatialTapGesture(count: 2)

        #expect(singleTap.matchesEvent(detail: 1))
        #expect(!singleTap.matchesEvent(detail: 2))

        #expect(!doubleTap.matchesEvent(detail: 1))
        #expect(doubleTap.matchesEvent(detail: 2))
    }

    // MARK: - SpatialTapGesture Coordinate Extraction Tests

    @Test("SpatialTapGesture extracts local coordinates")
    func testSpatialTapGestureLocalCoordinates() {
        let gesture = SpatialTapGesture(coordinateSpace: .local)

        // Element bounds at (100, 100) with size 200x200
        let elementBounds = Raven.CGRect(x: 100, y: 100, width: 200, height: 200)

        // Click at viewport coordinates (150, 150)
        let location = gesture.extractLocation(
            clientX: 150,
            clientY: 150,
            elementBounds: elementBounds
        )

        // Local coordinates should be (50, 50) - relative to element
        #expect(location.x == 50)
        #expect(location.y == 50)
    }

    @Test("SpatialTapGesture extracts global coordinates")
    func testSpatialTapGestureGlobalCoordinates() {
        let gesture = SpatialTapGesture(coordinateSpace: .global)

        let elementBounds = Raven.CGRect(x: 100, y: 100, width: 200, height: 200)

        // Click at viewport coordinates (250, 300)
        let location = gesture.extractLocation(
            clientX: 250,
            clientY: 300,
            elementBounds: elementBounds
        )

        // Global coordinates should match viewport coordinates
        #expect(location.x == 250)
        #expect(location.y == 300)
    }

    @Test("SpatialTapGesture extracts named coordinates")
    func testSpatialTapGestureNamedCoordinates() {
        let gesture = SpatialTapGesture(coordinateSpace: .named("container"))

        let elementBounds = Raven.CGRect(x: 200, y: 200, width: 100, height: 100)
        let ancestorBounds = Raven.CGRect(x: 50, y: 50, width: 400, height: 400)

        // Click at viewport coordinates (225, 275)
        let location = gesture.extractLocation(
            clientX: 225,
            clientY: 275,
            elementBounds: elementBounds,
            namedAncestorBounds: ancestorBounds
        )

        // Named coordinates should be relative to ancestor (175, 225)
        #expect(location.x == 175)
        #expect(location.y == 225)
    }

    @Test("SpatialTapGesture named coordinates fallback to global")
    func testSpatialTapGestureNamedCoordinatesFallback() {
        let gesture = SpatialTapGesture(coordinateSpace: .named("missing"))

        let elementBounds = Raven.CGRect(x: 100, y: 100, width: 200, height: 200)

        // Click at viewport coordinates (150, 200)
        // No ancestor bounds provided - should fallback to global
        let location = gesture.extractLocation(
            clientX: 150,
            clientY: 200,
            elementBounds: elementBounds
        )

        // Should use global coordinates as fallback
        #expect(location.x == 150)
        #expect(location.y == 200)
    }

    @Test("SpatialTapGesture handles top-left corner tap")
    func testSpatialTapGestureTopLeftCorner() {
        let gesture = SpatialTapGesture(coordinateSpace: .local)
        let elementBounds = Raven.CGRect(x: 100, y: 100, width: 200, height: 200)

        // Tap exactly at element's top-left corner
        let location = gesture.extractLocation(
            clientX: 100,
            clientY: 100,
            elementBounds: elementBounds
        )

        #expect(location.x == 0)
        #expect(location.y == 0)
    }

    @Test("SpatialTapGesture handles bottom-right corner tap")
    func testSpatialTapGestureBottomRightCorner() {
        let gesture = SpatialTapGesture(coordinateSpace: .local)
        let elementBounds = Raven.CGRect(x: 100, y: 100, width: 200, height: 200)

        // Tap at element's bottom-right corner (300, 300)
        let location = gesture.extractLocation(
            clientX: 300,
            clientY: 300,
            elementBounds: elementBounds
        )

        #expect(location.x == 200)
        #expect(location.y == 200)
    }

    @Test("SpatialTapGesture handles center tap")
    func testSpatialTapGestureCenter() {
        let gesture = SpatialTapGesture(coordinateSpace: .local)
        let elementBounds = Raven.CGRect(x: 100, y: 100, width: 200, height: 200)

        // Tap at element's center (200, 200)
        let location = gesture.extractLocation(
            clientX: 200,
            clientY: 200,
            elementBounds: elementBounds
        )

        #expect(location.x == 100)
        #expect(location.y == 100)
    }

    @Test("SpatialTapGesture handles fractional coordinates")
    func testSpatialTapGestureFractionalCoordinates() {
        let gesture = SpatialTapGesture(coordinateSpace: .local)
        let elementBounds = Raven.CGRect(x: 50.5, y: 75.25, width: 100, height: 100)

        // Tap at fractional coordinates
        let location = gesture.extractLocation(
            clientX: 100.75,
            clientY: 125.5,
            elementBounds: elementBounds
        )

        #expect(location.x == 50.25)
        #expect(location.y == 50.25)
    }

    // MARK: - Edge Cases and Integration Tests

    @Test("Multiple TapGestures with different counts")
    func testMultipleTapGesturesWithDifferentCounts() {
        let gestures = [
            TapGesture(count: 1),
            TapGesture(count: 2),
            TapGesture(count: 3),
            TapGesture(count: 4)
        ]

        for (index, gesture) in gestures.enumerated() {
            #expect(gesture.count == index + 1)
        }
    }

    @Test("TapGesture and SpatialTapGesture have same event name")
    func testGesturesShareEventName() {
        let tap = TapGesture()
        let spatialTap = SpatialTapGesture()

        #expect(tap.eventName == spatialTap.eventName)
        #expect(tap.eventName == "click")
    }

    @Test("CoordinateSpace equality works correctly")
    func testCoordinateSpaceEquality() {
        #expect(CoordinateSpace.local == CoordinateSpace.local)
        #expect(CoordinateSpace.global == CoordinateSpace.global)
        #expect(CoordinateSpace.named("test") == CoordinateSpace.named("test"))
        #expect(CoordinateSpace.named("test") != CoordinateSpace.named("other"))
        #expect(CoordinateSpace.local != CoordinateSpace.global)
    }

    @Test("CGPoint extraction handles zero-sized elements")
    func testCGPointExtractionZeroSizedElement() {
        let gesture = SpatialTapGesture(coordinateSpace: .local)
        let elementBounds = Raven.CGRect(x: 100, y: 100, width: 0, height: 0)

        let location = gesture.extractLocation(
            clientX: 100,
            clientY: 100,
            elementBounds: elementBounds
        )

        #expect(location.x == 0)
        #expect(location.y == 0)
    }

    @Test("SpatialTapGesture with very large coordinates")
    func testSpatialTapGestureLargeCoordinates() {
        let gesture = SpatialTapGesture(coordinateSpace: .global)
        let elementBounds = Raven.CGRect(x: 0, y: 0, width: 100, height: 100)

        let location = gesture.extractLocation(
            clientX: 10000,
            clientY: 10000,
            elementBounds: elementBounds
        )

        #expect(location.x == 10000)
        #expect(location.y == 10000)
    }

    @Test("SpatialTapGesture with negative element bounds")
    func testSpatialTapGestureNegativeBounds() {
        let gesture = SpatialTapGesture(coordinateSpace: .local)
        let elementBounds = Raven.CGRect(x: -100, y: -100, width: 200, height: 200)

        let location = gesture.extractLocation(
            clientX: 0,
            clientY: 0,
            elementBounds: elementBounds
        )

        #expect(location.x == 100)
        #expect(location.y == 100)
    }
}
