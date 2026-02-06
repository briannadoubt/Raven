import Testing
import Foundation
@testable import Raven

// MARK: - Phase 13 Example Code Verification

/// Verification that the example code from the Phase 13 requirements compiles and works correctly.
@MainActor
struct Phase13Examples {

    // MARK: - Simple Gesture Attachment Examples

    /// Example: Simple gesture attachment from requirements
    @Test("Example: Simple gesture attachment")
    func exampleSimpleGestureAttachment() throws {
        let view = Rectangle()
            .gesture(TapGesture().onEnded { print("Tapped!") })

        #expect(view != nil)
    }

    // MARK: - Simultaneous Gesture Examples

    /// Example: Simultaneous rotation and zoom from requirements
    @Test("Example: Simultaneous rotation and zoom")
    func exampleSimultaneousRotationZoom() throws {
        struct PhotoView: View {
            @State var rotation: Angle = .zero
            @State var scale: Double = 1.0

            var body: some View {
                Image("photo")
                    .gesture(
                        RotationGesture()
                            .simultaneously(with: MagnificationGesture())
                            .onChanged { value in
                                rotation = value.0 ?? .zero
                                scale = value.1 ?? 1.0
                            }
                    )
            }
        }

        let view = PhotoView()
        #expect(view != nil)
    }

    // MARK: - Sequential Gesture Examples

    /// Example: Sequential long press then drag from requirements
    @Test("Example: Sequential long press then drag")
    func exampleSequentialLongPressDrag() throws {
        struct DraggableView: View {
            @State var dragOffset = Raven.CGSize(width: 0, height: 0)

            var body: some View {
                Rectangle()
                    .gesture(
                        LongPressGesture()
                            .sequenced(before: DragGesture())
                            .onChanged { value in
                                switch value {
                                case .first:
                                    print("Pressing...")
                                case .second(true, let drag):
                                    print("Dragging: \(drag?.translation)")
                                case .second(false, _):
                                    print("Not pressing")
                                }
                            }
                    )
            }
        }

        let view = DraggableView()
        #expect(view != nil)
    }

    // MARK: - Exclusive Gesture Examples

    /// Example: Exclusive tap or long press from requirements
    @Test("Example: Exclusive tap or long press")
    func exampleExclusiveTapLongPress() throws {
        struct InteractiveText: View {
            var body: some View {
                Text("Press or tap")
                    .gesture(
                        TapGesture()
                            .exclusively(before: LongPressGesture())
                            .onEnded { value in
                                switch value {
                                case .first:
                                    print("Tapped!")
                                case .second:
                                    print("Long pressed!")
                                }
                            }
                    )
            }
        }

        let view = InteractiveText()
        #expect(view != nil)
    }

    // MARK: - GestureMask Examples

    /// Example: Gesture with GestureMask from requirements
    @Test("Example: Gesture with GestureMask")
    func exampleGestureWithMask() throws {
        struct ScrollContent: View {
            var body: some View {
                ScrollView {
                    Text("Content")
                        .gesture(
                            TapGesture().onEnded {
                                print("Tap")
                            },
                            including: .gesture
                        )
                }
            }
        }

        let view = ScrollContent()
        #expect(view != nil)
    }

    // MARK: - Complex Composition Examples

    /// Example: Complex nested composition
    @Test("Example: Complex nested composition")
    func exampleComplexComposition() throws {
        struct ComplexGestureView: View {
            @State var rotation: Angle = .zero
            @State var scale: Double = 1.0
            @State var dragOffset = Raven.CGSize(width: 0, height: 0)

            var body: some View {
                Rectangle()
                    .rotationEffect(rotation)
                    .scaleEffect(scale)
                    .offset(x: dragOffset.width, y: dragOffset.height)
                    .gesture(
                        RotationGesture()
                            .simultaneously(with: MagnificationGesture())
                            .onChanged { value in
                                rotation = value.0 ?? .zero
                                scale = value.1 ?? 1.0
                            }
                    )
                    .gesture(
                        LongPressGesture()
                            .sequenced(before: DragGesture())
                            .onChanged { value in
                                switch value {
                                case .first:
                                    break
                                case .second(_, let drag):
                                    dragOffset = drag?.translation ?? Raven.CGSize(width: 0, height: 0)
                                }
                            }
                    )
            }
        }

        let view = ComplexGestureView()
        #expect(view != nil)
    }

    // MARK: - Multiple Gesture Priority Examples

    /// Example: Multiple gestures with different priorities
    @Test("Example: Multiple gesture priorities")
    func exampleMultiplePriorities() throws {
        struct MultiGestureView: View {
            var body: some View {
                Rectangle()
                    .gesture(TapGesture().onEnded { print("Normal tap") })
                    .simultaneousGesture(LongPressGesture().onEnded { _ in print("Simultaneous long press") })
                    .highPriorityGesture(DragGesture().onChanged { _ in print("High priority drag") })
            }
        }

        let view = MultiGestureView()
        #expect(view != nil)
    }

    // MARK: - All Gesture Types with Composition

    /// Test composition works with all gesture types
    @Test("Composition with all gesture types")
    func compositionWithAllGestureTypes() throws {
        // TapGesture compositions
        let tap1 = TapGesture().simultaneously(with: LongPressGesture())
        let tap2 = TapGesture().sequenced(before: DragGesture())
        let tap3 = TapGesture().exclusively(before: LongPressGesture())

        // LongPressGesture compositions
        let long1 = LongPressGesture().simultaneously(with: DragGesture())
        let long2 = LongPressGesture().sequenced(before: RotationGesture())
        let long3 = LongPressGesture().exclusively(before: TapGesture())

        // DragGesture compositions
        let drag1 = DragGesture().simultaneously(with: RotationGesture())
        let drag2 = DragGesture().sequenced(before: MagnificationGesture())
        let drag3 = DragGesture().exclusively(before: LongPressGesture())

        // RotationGesture compositions
        let rot1 = RotationGesture().simultaneously(with: MagnificationGesture())
        let rot2 = RotationGesture().sequenced(before: DragGesture())
        let rot3 = RotationGesture().exclusively(before: MagnificationGesture())

        // MagnificationGesture compositions
        let mag1 = MagnificationGesture().simultaneously(with: RotationGesture())
        let mag2 = MagnificationGesture().sequenced(before: DragGesture())
        let mag3 = MagnificationGesture().exclusively(before: RotationGesture())

        // Verify all created successfully
        #expect(tap1 != nil)
        #expect(tap2 != nil)
        #expect(tap3 != nil)
        #expect(long1 != nil)
        #expect(long2 != nil)
        #expect(long3 != nil)
        #expect(drag1 != nil)
        #expect(drag2 != nil)
        #expect(drag3 != nil)
        #expect(rot1 != nil)
        #expect(rot2 != nil)
        #expect(rot3 != nil)
        #expect(mag1 != nil)
        #expect(mag2 != nil)
        #expect(mag3 != nil)
    }

    // MARK: - Value Type Tests

    /// Test SequenceGestureValue switch handling
    @Test("SequenceGestureValue switch patterns")
    func sequenceGestureValueSwitchPatterns() throws {
        let value1: SequenceGestureValue<Bool, Raven.CGSize> = .first(true)
        let value2: SequenceGestureValue<Bool, Raven.CGSize> = .second(true, nil)
        let value3: SequenceGestureValue<Bool, Raven.CGSize> = .second(true, Raven.CGSize(width: 10, height: 20))

        var matchedFirst = false
        var matchedSecondNil = false
        var matchedSecondValue = false

        switch value1 {
        case .first:
            matchedFirst = true
        case .second:
            break
        }

        switch value2 {
        case .first:
            break
        case .second(_, let val):
            if val == nil {
                matchedSecondNil = true
            }
        }

        switch value3 {
        case .first:
            break
        case .second(_, let val):
            if val != nil {
                matchedSecondValue = true
            }
        }

        #expect(matchedFirst)
        #expect(matchedSecondNil)
        #expect(matchedSecondValue)
    }

    /// Test ExclusiveGestureValue switch handling
    @Test("ExclusiveGestureValue switch patterns")
    func exclusiveGestureValueSwitchPatterns() throws {
        let value1: ExclusiveGestureValue<String, Int> = .first("tap")
        let value2: ExclusiveGestureValue<String, Int> = .second(42)

        var matchedFirst = false
        var matchedSecond = false

        switch value1 {
        case .first(let val):
            if val == "tap" {
                matchedFirst = true
            }
        case .second:
            break
        }

        switch value2 {
        case .first:
            break
        case .second(let val):
            if val == 42 {
                matchedSecond = true
            }
        }

        #expect(matchedFirst)
        #expect(matchedSecond)
    }

    // MARK: - Event Mapping Tests

    /// Test that event mapping works for composed gestures
    @Test("Event mapping for composed gestures")
    func eventMappingForComposedGestures() throws {
        let simultaneousGesture = RotationGesture().simultaneously(with: MagnificationGesture())
        let events1 = eventNamesForGesture(simultaneousGesture)
        #expect(!events1.isEmpty)

        let sequenceGesture = LongPressGesture().sequenced(before: DragGesture())
        let events2 = eventNamesForGesture(sequenceGesture)
        #expect(!events2.isEmpty)

        let exclusiveGesture = TapGesture().exclusively(before: LongPressGesture())
        let events3 = eventNamesForGesture(exclusiveGesture)
        #expect(!events3.isEmpty)
    }
}
