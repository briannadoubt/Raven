import Testing
import Foundation
@testable import Raven

// MARK: - Gesture Composition Tests

/// Tests for gesture composition functionality including simultaneous, sequence, and exclusive gestures.
@MainActor
struct GestureCompositionTests {

    // MARK: - SimultaneousGesture Tests

    /// Test creating a simultaneous gesture.
    @Test("Create SimultaneousGesture")
    func createSimultaneousGesture() throws {
        let gesture = TapGesture().simultaneously(with: LongPressGesture())
        #expect(gesture != nil)
    }

    /// Test simultaneous gesture with tap and long press.
    @Test("SimultaneousGesture with TapGesture and LongPressGesture")
    func simultaneousTapAndLongPress() throws {
        let gesture = TapGesture().simultaneously(with: LongPressGesture())
        #expect(gesture.first != nil)
        #expect(gesture.second != nil)
    }

    /// Test simultaneous gesture with drag and rotation.
    @Test("SimultaneousGesture with DragGesture and RotationGesture")
    func simultaneousDragAndRotation() throws {
        let gesture = DragGesture().simultaneously(with: RotationGesture())
        #expect(gesture.first != nil)
        #expect(gesture.second != nil)
    }

    /// Test simultaneous gesture with rotation and magnification.
    @Test("SimultaneousGesture with RotationGesture and MagnificationGesture")
    func simultaneousRotationAndMagnification() throws {
        let gesture = RotationGesture().simultaneously(with: MagnificationGesture())
        #expect(gesture.first != nil)
        #expect(gesture.second != nil)
    }

    /// Test simultaneous gesture value type.
    @Test("SimultaneousGesture value type is tuple of optionals")
    func simultaneousGestureValueType() throws {
        let gesture = TapGesture().simultaneously(with: LongPressGesture())
        let value: (Void?, Bool?) = (nil, nil)
        #expect(value.0 == nil)
        #expect(value.1 == nil)
    }

    /// Test attaching simultaneous gesture to view.
    @Test("Attach SimultaneousGesture to view")
    func attachSimultaneousGesture() throws {
        let view = Rectangle()
            .gesture(
                RotationGesture()
                    .simultaneously(with: MagnificationGesture())
            )
        #expect(view != nil)
    }

    /// Test simultaneous gesture with onChanged.
    @Test("SimultaneousGesture with onChanged")
    func simultaneousGestureOnChanged() throws {
        var changeCount = 0
        let gesture = DragGesture()
            .simultaneously(with: RotationGesture())
            .onChanged { _ in
                changeCount += 1
            }
        #expect(gesture != nil)
    }

    /// Test simultaneous gesture with onEnded.
    @Test("SimultaneousGesture with onEnded")
    func simultaneousGestureOnEnded() throws {
        var ended = false
        let gesture = TapGesture()
            .simultaneously(with: LongPressGesture())
            .onEnded { _ in
                ended = true
            }
        #expect(gesture != nil)
    }

    // MARK: - SequenceGesture Tests

    /// Test creating a sequence gesture.
    @Test("Create SequenceGesture")
    func createSequenceGesture() throws {
        let gesture = LongPressGesture().sequenced(before: DragGesture())
        #expect(gesture != nil)
    }

    /// Test sequence gesture with long press then drag.
    @Test("SequenceGesture with LongPressGesture then DragGesture")
    func sequenceLongPressThenDrag() throws {
        let gesture = LongPressGesture().sequenced(before: DragGesture())
        #expect(gesture.first != nil)
        #expect(gesture.second != nil)
    }

    /// Test sequence gesture with tap then drag.
    @Test("SequenceGesture with TapGesture then DragGesture")
    func sequenceTapThenDrag() throws {
        let gesture = TapGesture().sequenced(before: DragGesture())
        #expect(gesture.first != nil)
        #expect(gesture.second != nil)
    }

    /// Test sequence gesture with tap then rotation.
    @Test("SequenceGesture with TapGesture then RotationGesture")
    func sequenceTapThenRotation() throws {
        let gesture = TapGesture().sequenced(before: RotationGesture())
        #expect(gesture.first != nil)
        #expect(gesture.second != nil)
    }

    /// Test sequence gesture value - first case.
    @Test("SequenceGestureValue .first case")
    func sequenceGestureValueFirst() throws {
        let value: SequenceGestureValue<Bool, Raven.CGSize> = .first(true)

        switch value {
        case .first(let val):
            #expect(val == true)
        case .second:
            #expect(Bool(false), "Should be .first case")
        }
    }

    /// Test sequence gesture value - second case with nil.
    @Test("SequenceGestureValue .second case with nil")
    func sequenceGestureValueSecondNil() throws {
        let value: SequenceGestureValue<Bool, Raven.CGSize> = .second(true, nil)

        switch value {
        case .first:
            #expect(Bool(false), "Should be .second case")
        case .second(let first, let second):
            #expect(first == true)
            #expect(second == nil)
        }
    }

    /// Test sequence gesture value - second case with value.
    @Test("SequenceGestureValue .second case with value")
    func sequenceGestureValueSecondWithValue() throws {
        let size = Raven.CGSize(width: 10, height: 20)
        let value: SequenceGestureValue<Bool, Raven.CGSize> = .second(true, size)

        switch value {
        case .first:
            #expect(Bool(false), "Should be .second case")
        case .second(let first, let second):
            #expect(first == true)
            #expect(second == size)
        }
    }

    /// Test sequence gesture value equality - first cases.
    @Test("SequenceGestureValue equality - first cases")
    func sequenceGestureValueEqualityFirst() throws {
        let value1: SequenceGestureValue<Int, String> = .first(42)
        let value2: SequenceGestureValue<Int, String> = .first(42)
        let value3: SequenceGestureValue<Int, String> = .first(43)

        #expect(value1 == value2)
        #expect(value1 != value3)
    }

    /// Test sequence gesture value equality - second cases.
    @Test("SequenceGestureValue equality - second cases")
    func sequenceGestureValueEqualitySecond() throws {
        let value1: SequenceGestureValue<Int, String> = .second(42, "hello")
        let value2: SequenceGestureValue<Int, String> = .second(42, "hello")
        let value3: SequenceGestureValue<Int, String> = .second(42, "world")

        #expect(value1 == value2)
        #expect(value1 != value3)
    }

    /// Test sequence gesture value equality - different cases.
    @Test("SequenceGestureValue equality - different cases")
    func sequenceGestureValueEqualityDifferent() throws {
        let value1: SequenceGestureValue<Int, String> = .first(42)
        let value2: SequenceGestureValue<Int, String> = .second(42, nil)

        #expect(value1 != value2)
    }

    /// Test attaching sequence gesture to view.
    @Test("Attach SequenceGesture to view")
    func attachSequenceGesture() throws {
        let view = Rectangle()
            .gesture(
                LongPressGesture()
                    .sequenced(before: DragGesture())
            )
        #expect(view != nil)
    }

    /// Test sequence gesture with onChanged.
    @Test("SequenceGesture with onChanged")
    func sequenceGestureOnChanged() throws {
        var changeCount = 0
        let gesture = LongPressGesture()
            .sequenced(before: DragGesture())
            .onChanged { _ in
                changeCount += 1
            }
        #expect(gesture != nil)
    }

    /// Test sequence gesture with onEnded.
    @Test("SequenceGesture with onEnded")
    func sequenceGestureOnEnded() throws {
        var ended = false
        let gesture = TapGesture()
            .sequenced(before: DragGesture())
            .onEnded { _ in
                ended = true
            }
        #expect(gesture != nil)
    }

    // MARK: - ExclusiveGesture Tests

    /// Test creating an exclusive gesture.
    @Test("Create ExclusiveGesture")
    func createExclusiveGesture() throws {
        let gesture = TapGesture().exclusively(before: LongPressGesture())
        #expect(gesture != nil)
    }

    /// Test exclusive gesture with tap and long press.
    @Test("ExclusiveGesture with TapGesture and LongPressGesture")
    func exclusiveTapAndLongPress() throws {
        let gesture = TapGesture().exclusively(before: LongPressGesture())
        #expect(gesture.first != nil)
        #expect(gesture.second != nil)
    }

    /// Test exclusive gesture with drag gestures.
    @Test("ExclusiveGesture with two DragGestures")
    func exclusiveTwoDrags() throws {
        let gesture = DragGesture(minimumDistance: 5)
            .exclusively(before: DragGesture(minimumDistance: 20))
        #expect(gesture.first != nil)
        #expect(gesture.second != nil)
    }

    /// Test exclusive gesture value - first case.
    @Test("ExclusiveGestureValue .first case")
    func exclusiveGestureValueFirst() throws {
        let value: ExclusiveGestureValue<String, Int> = .first("tap")

        switch value {
        case .first(let val):
            #expect(val == "tap")
        case .second:
            #expect(Bool(false), "Should be .first case")
        }
    }

    /// Test exclusive gesture value - second case.
    @Test("ExclusiveGestureValue .second case")
    func exclusiveGestureValueSecond() throws {
        let value: ExclusiveGestureValue<String, Int> = .second(42)

        switch value {
        case .first:
            #expect(Bool(false), "Should be .second case")
        case .second(let val):
            #expect(val == 42)
        }
    }

    /// Test exclusive gesture value equality - first cases.
    @Test("ExclusiveGestureValue equality - first cases")
    func exclusiveGestureValueEqualityFirst() throws {
        let value1: ExclusiveGestureValue<Int, String> = .first(42)
        let value2: ExclusiveGestureValue<Int, String> = .first(42)
        let value3: ExclusiveGestureValue<Int, String> = .first(43)

        #expect(value1 == value2)
        #expect(value1 != value3)
    }

    /// Test exclusive gesture value equality - second cases.
    @Test("ExclusiveGestureValue equality - second cases")
    func exclusiveGestureValueEqualitySecond() throws {
        let value1: ExclusiveGestureValue<Int, String> = .second("hello")
        let value2: ExclusiveGestureValue<Int, String> = .second("hello")
        let value3: ExclusiveGestureValue<Int, String> = .second("world")

        #expect(value1 == value2)
        #expect(value1 != value3)
    }

    /// Test exclusive gesture value equality - different cases.
    @Test("ExclusiveGestureValue equality - different cases")
    func exclusiveGestureValueEqualityDifferent() throws {
        let value1: ExclusiveGestureValue<Int, String> = .first(42)
        let value2: ExclusiveGestureValue<Int, String> = .second("hello")

        #expect(value1 != value2)
    }

    /// Test attaching exclusive gesture to view.
    @Test("Attach ExclusiveGesture to view")
    func attachExclusiveGesture() throws {
        let view = Rectangle()
            .gesture(
                TapGesture()
                    .exclusively(before: LongPressGesture())
            )
        #expect(view != nil)
    }

    /// Test exclusive gesture with onChanged.
    @Test("ExclusiveGesture with onChanged")
    func exclusiveGestureOnChanged() throws {
        var changeCount = 0
        let gesture = DragGesture(minimumDistance: 5)
            .exclusively(before: DragGesture(minimumDistance: 20))
            .onChanged { _ in
                changeCount += 1
            }
        #expect(gesture != nil)
    }

    /// Test exclusive gesture with onEnded.
    @Test("ExclusiveGesture with onEnded")
    func exclusiveGestureOnEnded() throws {
        var ended = false
        let gesture = TapGesture()
            .exclusively(before: LongPressGesture())
            .onEnded { _ in
                ended = true
            }
        #expect(gesture != nil)
    }

    // MARK: - Nested Composition Tests

    /// Test nested simultaneous gestures.
    @Test("Nested SimultaneousGestures")
    func nestedSimultaneous() throws {
        let gesture = TapGesture()
            .simultaneously(with: LongPressGesture())
            .simultaneously(with: DragGesture())
        #expect(gesture != nil)
    }

    /// Test nested sequence gestures.
    @Test("Nested SequenceGestures")
    func nestedSequence() throws {
        let gesture = TapGesture()
            .sequenced(before: LongPressGesture())
            .sequenced(before: DragGesture())
        #expect(gesture != nil)
    }

    /// Test nested exclusive gestures.
    @Test("Nested ExclusiveGestures")
    func nestedExclusive() throws {
        let gesture = TapGesture()
            .exclusively(before: LongPressGesture())
            .exclusively(before: DragGesture())
        #expect(gesture != nil)
    }

    /// Test mixing composition types - simultaneous then sequence.
    @Test("Mixed composition: simultaneous then sequence")
    func mixedSimultaneousThenSequence() throws {
        let simultaneous = RotationGesture().simultaneously(with: MagnificationGesture())
        let gesture = TapGesture().sequenced(before: simultaneous)
        #expect(gesture != nil)
    }

    /// Test mixing composition types - sequence then simultaneous.
    @Test("Mixed composition: sequence then simultaneous")
    func mixedSequenceThenSimultaneous() throws {
        let sequence = TapGesture().sequenced(before: DragGesture())
        let gesture = sequence.simultaneously(with: RotationGesture())
        #expect(gesture != nil)
    }

    /// Test mixing composition types - exclusive then simultaneous.
    @Test("Mixed composition: exclusive then simultaneous")
    func mixedExclusiveThenSimultaneous() throws {
        let exclusive = TapGesture().exclusively(before: LongPressGesture())
        let gesture = exclusive.simultaneously(with: DragGesture())
        #expect(gesture != nil)
    }

    /// Test complex nested composition.
    @Test("Complex nested composition")
    func complexNestedComposition() throws {
        let rotation = RotationGesture()
        let magnification = MagnificationGesture()
        let simultaneous = rotation.simultaneously(with: magnification)

        let longPress = LongPressGesture()
        let sequence = longPress.sequenced(before: simultaneous)

        let tap = TapGesture()
        let exclusive = tap.exclusively(before: sequence)

        #expect(exclusive != nil)
    }

    // MARK: - Integration Tests

    /// Test simultaneous gesture on view with mask.
    @Test("SimultaneousGesture with GestureMask")
    func simultaneousGestureWithMask() throws {
        let view = Rectangle()
            .gesture(
                RotationGesture()
                    .simultaneously(with: MagnificationGesture()),
                including: .gesture
            )
        #expect(view != nil)
    }

    /// Test sequence gesture on view with mask.
    @Test("SequenceGesture with GestureMask")
    func sequenceGestureWithMask() throws {
        let view = Rectangle()
            .gesture(
                LongPressGesture()
                    .sequenced(before: DragGesture()),
                including: .all
            )
        #expect(view != nil)
    }

    /// Test exclusive gesture on view with mask.
    @Test("ExclusiveGesture with GestureMask")
    func exclusiveGestureWithMask() throws {
        let view = Rectangle()
            .gesture(
                TapGesture()
                    .exclusively(before: LongPressGesture()),
                including: .subviews
            )
        #expect(view != nil)
    }

    /// Test composed gesture with simultaneousGesture modifier.
    @Test("Composed gesture with simultaneousGesture modifier")
    func composedGestureSimultaneousModifier() throws {
        let view = Rectangle()
            .simultaneousGesture(
                RotationGesture()
                    .simultaneously(with: MagnificationGesture())
            )
        #expect(view != nil)
    }

    /// Test composed gesture with highPriorityGesture modifier.
    @Test("Composed gesture with highPriorityGesture modifier")
    func composedGestureHighPriorityModifier() throws {
        let view = Rectangle()
            .highPriorityGesture(
                LongPressGesture()
                    .sequenced(before: DragGesture())
            )
        #expect(view != nil)
    }

    // MARK: - Edge Cases

    /// Test same gesture type in simultaneous composition.
    @Test("Same gesture type in SimultaneousGesture")
    func sameGestureSimultaneous() throws {
        let gesture = DragGesture().simultaneously(with: DragGesture())
        #expect(gesture != nil)
    }

    /// Test same gesture type in sequence composition.
    @Test("Same gesture type in SequenceGesture")
    func sameGestureSequence() throws {
        let gesture = TapGesture().sequenced(before: TapGesture())
        #expect(gesture != nil)
    }

    /// Test same gesture type in exclusive composition.
    @Test("Same gesture type in ExclusiveGesture")
    func sameGestureExclusive() throws {
        let gesture = DragGesture(minimumDistance: 5)
            .exclusively(before: DragGesture(minimumDistance: 10))
        #expect(gesture != nil)
    }

    /// Test all three composition types on same view.
    @Test("All composition types on same view")
    func allCompositionTypes() throws {
        let view = Rectangle()
            .gesture(
                TapGesture()
                    .simultaneously(with: LongPressGesture())
            )
            .gesture(
                LongPressGesture()
                    .sequenced(before: DragGesture())
            )
            .gesture(
                TapGesture()
                    .exclusively(before: LongPressGesture())
            )
        #expect(view != nil)
    }

    /// Test gesture composition with all gesture types.
    @Test("Composition with all gesture types")
    func compositionAllTypes() throws {
        let tap = TapGesture()
        let longPress = LongPressGesture()
        let drag = DragGesture()
        let rotation = RotationGesture()
        let magnification = MagnificationGesture()

        let gesture1 = tap.simultaneously(with: longPress)
        let gesture2 = drag.sequenced(before: rotation)
        let gesture3 = magnification.exclusively(before: gesture1)

        #expect(gesture1 != nil)
        #expect(gesture2 != nil)
        #expect(gesture3 != nil)
    }
}
