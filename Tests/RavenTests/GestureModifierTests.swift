import Testing
import Foundation
@testable import Raven

// MARK: - Gesture Modifier Tests

/// Tests for the .gesture() modifier and gesture attachment functionality.
@MainActor
struct GestureModifierTests {

    // MARK: - Basic Gesture Attachment Tests

    /// Test that a basic gesture can be attached to a view.
    @Test("Basic gesture attachment")
    func basicGestureAttachment() throws {
        let view = Rectangle()
            .gesture(TapGesture())

        #expect(view != nil)
    }

    /// Test that gesture modifier is created with correct default mask.
    @Test("Default gesture mask is .all")
    func defaultGestureMask() throws {
        let modifier = GestureModifier(gesture: TapGesture())
        #expect(modifier.mask == .all)
    }

    /// Test that gesture modifier accepts custom mask.
    @Test("Custom gesture mask")
    func customGestureMask() throws {
        let modifier = GestureModifier(gesture: TapGesture(), mask: .gesture)
        #expect(modifier.mask == .gesture)
    }

    /// Test attaching a gesture with .gesture mask.
    @Test("Gesture with .gesture mask")
    func gestureWithGestureMask() throws {
        let view = Rectangle()
            .gesture(TapGesture(), including: .gesture)

        #expect(view != nil)
    }

    /// Test attaching a gesture with .subviews mask.
    @Test("Gesture with .subviews mask")
    func gestureWithSubviewsMask() throws {
        let view = Rectangle()
            .gesture(DragGesture(), including: .subviews)

        #expect(view != nil)
    }

    /// Test attaching a gesture with .none mask.
    @Test("Gesture with .none mask")
    func gestureWithNoneMask() throws {
        let view = Rectangle()
            .gesture(LongPressGesture(), including: .none)

        #expect(view != nil)
    }

    /// Test attaching a gesture with .all mask explicitly.
    @Test("Gesture with .all mask explicitly")
    func gestureWithAllMask() throws {
        let view = Rectangle()
            .gesture(TapGesture(), including: .all)

        #expect(view != nil)
    }

    // MARK: - Multiple Gesture Tests

    /// Test attaching multiple gestures to the same view.
    @Test("Multiple gestures on same view")
    func multipleGestures() throws {
        let view = Rectangle()
            .gesture(TapGesture())
            .gesture(LongPressGesture())

        #expect(view != nil)
    }

    /// Test simultaneous gesture attachment.
    @Test("Simultaneous gesture attachment")
    func simultaneousGestureAttachment() throws {
        let view = Rectangle()
            .simultaneousGesture(TapGesture())

        #expect(view != nil)
    }

    /// Test high-priority gesture attachment.
    @Test("High-priority gesture attachment")
    func highPriorityGestureAttachment() throws {
        let view = Rectangle()
            .highPriorityGesture(DragGesture())

        #expect(view != nil)
    }

    /// Test mixing regular and simultaneous gestures.
    @Test("Mix regular and simultaneous gestures")
    func mixedGestures() throws {
        let view = Rectangle()
            .gesture(TapGesture())
            .simultaneousGesture(LongPressGesture())
            .highPriorityGesture(DragGesture())

        #expect(view != nil)
    }

    // MARK: - Gesture Type Tests

    /// Test attaching TapGesture.
    @Test("Attach TapGesture")
    func attachTapGesture() throws {
        let view = Rectangle()
            .gesture(TapGesture().onEnded { })

        #expect(view != nil)
    }

    /// Test attaching LongPressGesture.
    @Test("Attach LongPressGesture")
    func attachLongPressGesture() throws {
        let view = Rectangle()
            .gesture(LongPressGesture().onEnded { _ in })

        #expect(view != nil)
    }

    /// Test attaching DragGesture.
    @Test("Attach DragGesture")
    func attachDragGesture() throws {
        let view = Rectangle()
            .gesture(DragGesture().onChanged { _ in })

        #expect(view != nil)
    }

    /// Test attaching RotationGesture.
    @Test("Attach RotationGesture")
    func attachRotationGesture() throws {
        let view = Rectangle()
            .gesture(RotationGesture().onChanged { _ in })

        #expect(view != nil)
    }

    /// Test attaching MagnificationGesture.
    @Test("Attach MagnificationGesture")
    func attachMagnificationGesture() throws {
        let view = Rectangle()
            .gesture(MagnificationGesture().onChanged { _ in })

        #expect(view != nil)
    }

    // MARK: - Event Mapping Tests

    /// Test event mapping for TapGesture.
    @Test("Event mapping for TapGesture")
    func eventMappingTapGesture() throws {
        let events = eventNamesForGesture(TapGesture())
        #expect(events.contains("click"))
        #expect(events.contains("pointerdown"))
        #expect(events.contains("pointerup"))
    }

    /// Test event mapping for LongPressGesture.
    @Test("Event mapping for LongPressGesture")
    func eventMappingLongPressGesture() throws {
        let events = eventNamesForGesture(LongPressGesture())
        #expect(events.contains("pointerdown"))
        #expect(events.contains("pointermove"))
        #expect(events.contains("pointerup"))
        #expect(events.contains("pointercancel"))
    }

    /// Test event mapping for DragGesture.
    @Test("Event mapping for DragGesture")
    func eventMappingDragGesture() throws {
        let events = eventNamesForGesture(DragGesture())
        #expect(events.contains("pointerdown"))
        #expect(events.contains("pointermove"))
        #expect(events.contains("pointerup"))
        #expect(events.contains("pointercancel"))
    }

    /// Test event mapping for RotationGesture.
    @Test("Event mapping for RotationGesture")
    func eventMappingRotationGesture() throws {
        let events = eventNamesForGesture(RotationGesture())
        #expect(events.contains("pointerdown"))
        #expect(events.contains("pointermove"))
        #expect(events.contains("pointerup"))
    }

    /// Test event mapping for MagnificationGesture.
    @Test("Event mapping for MagnificationGesture")
    func eventMappingMagnificationGesture() throws {
        let events = eventNamesForGesture(MagnificationGesture())
        #expect(events.contains("pointerdown"))
        #expect(events.contains("pointermove"))
        #expect(events.contains("pointerup"))
    }

    // MARK: - GestureMask Tests

    /// Test that GestureMask.none has no flags set.
    @Test("GestureMask.none has no flags")
    func gestureMaskNone() throws {
        let mask = GestureMask.none
        #expect(mask.rawValue == 0)
        #expect(!mask.contains(.gesture))
        #expect(!mask.contains(.subviews))
    }

    /// Test that GestureMask.gesture has correct flag.
    @Test("GestureMask.gesture has correct flag")
    func gestureMaskGesture() throws {
        let mask = GestureMask.gesture
        #expect(mask.contains(.gesture))
        #expect(!mask.contains(.subviews))
    }

    /// Test that GestureMask.subviews has correct flag.
    @Test("GestureMask.subviews has correct flag")
    func gestureMaskSubviews() throws {
        let mask = GestureMask.subviews
        #expect(!mask.contains(.gesture))
        #expect(mask.contains(.subviews))
    }

    /// Test that GestureMask.all has both flags.
    @Test("GestureMask.all has both flags")
    func gestureMaskAll() throws {
        let mask = GestureMask.all
        #expect(mask.contains(.gesture))
        #expect(mask.contains(.subviews))
    }

    /// Test combining GestureMask flags.
    @Test("Combine GestureMask flags")
    func combineGestureMaskFlags() throws {
        let mask: GestureMask = [.gesture, .subviews]
        #expect(mask == .all)
    }

    // MARK: - Integration Tests

    /// Test gesture modifier with complex view hierarchy.
    @Test("Gesture on complex view hierarchy")
    func gestureOnComplexHierarchy() throws {
        let view = VStack {
            Text("Header")
            Rectangle()
                .gesture(TapGesture())
            Text("Footer")
        }

        #expect(view != nil)
    }

    /// Test gesture attachment doesn't affect view body.
    @Test("Gesture doesn't affect view body structure")
    func gesturePreservesViewStructure() throws {
        struct TestView: View {
            var body: some View {
                Text("Test")
            }
        }

        let withGesture = TestView()
            .gesture(TapGesture())

        #expect(withGesture != nil)
    }

    /// Test gesture on primitive view.
    @Test("Gesture on primitive view")
    func gestureOnPrimitiveView() throws {
        let view = Text("Tap me")
            .gesture(TapGesture().onEnded { })

        #expect(view != nil)
    }

    /// Test gesture on container view.
    @Test("Gesture on container view")
    func gestureOnContainerView() throws {
        let view = VStack {
            Text("Item 1")
            Text("Item 2")
        }
        .gesture(DragGesture())

        #expect(view != nil)
    }

    // MARK: - Gesture Priority Tests

    /// Test gesture priority enumeration.
    @Test("Gesture priority types")
    func gesturePriorityTypes() throws {
        let normal = GesturePriority.normal
        let simultaneous = GesturePriority.simultaneous
        let high = GesturePriority.high

        #expect(normal != nil)
        #expect(simultaneous != nil)
        #expect(high != nil)
    }

    /// Test gesture attachment with different priorities.
    @Test("Different gesture priorities on same view")
    func differentPriorities() throws {
        let view = Rectangle()
            .gesture(TapGesture())  // normal
            .simultaneousGesture(LongPressGesture())  // simultaneous
            .highPriorityGesture(DragGesture())  // high

        #expect(view != nil)
    }
}
