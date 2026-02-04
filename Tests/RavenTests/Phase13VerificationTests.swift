import Testing
import Foundation
@testable import Raven

/// Phase 13 Verification Tests
///
/// These integration tests verify that all Phase 13 gesture features work together correctly:
/// - Basic gesture types (TapGesture, SpatialTapGesture, LongPressGesture)
/// - Drag and transform gestures (DragGesture, RotationGesture, MagnificationGesture)
/// - Gesture composition (.simultaneously, .sequenced, .exclusively)
/// - Gesture modifiers (.gesture, .simultaneousGesture, .highPriorityGesture)
/// - GestureState property wrapper (@GestureState)
/// - Gesture masks and event modifiers
/// - Real-world gesture scenarios and edge cases
///
/// Focus: Integration testing across gesture features, real-world scenarios, edge cases
@Suite("Phase 13 Integration Tests")
struct Phase13VerificationTests {

    // MARK: - Basic Tap Gestures

    @Test("Single tap gesture recognition")
    @MainActor func singleTapGesture() {
        let gesture = TapGesture()
        #expect(gesture.count == 1)

        let view = Text("Tap me")
            .gesture(gesture.onEnded { })

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("Double tap gesture recognition")
    @MainActor func doubleTapGesture() {
        let gesture = TapGesture(count: 2)
        #expect(gesture.count == 2)

        let view = Text("Double tap")
            .gesture(gesture.onEnded { })

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("Triple tap gesture recognition")
    @MainActor func tripleTapGesture() {
        let gesture = TapGesture(count: 3)
        #expect(gesture.count == 3)

        let view = Circle()
            .gesture(gesture.onEnded { })

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("Tap gesture with negative count defaults to 1")
    @MainActor func tapGestureNegativeCount() {
        let gesture = TapGesture(count: -1)
        #expect(gesture.count == 1)
    }

    @Test("Tap gesture with zero count defaults to 1")
    @MainActor func tapGestureZeroCount() {
        let gesture = TapGesture(count: 0)
        #expect(gesture.count == 1)
    }

    // MARK: - Spatial Tap Gestures

    @Test("Spatial tap gesture with location")
    @MainActor func spatialTapGesture() {
        let gesture = SpatialTapGesture()
        #expect(gesture.count == 1)
        #expect(gesture.coordinateSpace == .local)

        let view = Rectangle()
            .gesture(
                gesture.onEnded { value in
                    // Should receive location
                }
            )

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("Spatial tap gesture with global coordinates")
    @MainActor func spatialTapGlobalCoordinates() {
        let gesture = SpatialTapGesture(coordinateSpace: .global)
        #expect(gesture.coordinateSpace == .global)

        let view = Text("Tap")
            .gesture(gesture.onEnded { _ in })

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("Spatial tap gesture with named coordinate space")
    @MainActor func spatialTapNamedCoordinates() {
        let gesture = SpatialTapGesture(coordinateSpace: .named("container"))

        let view = VStack {
            Text("Child")
                .gesture(gesture.onEnded { _ in })
        }
        .coordinateSpace(name: "container")

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("Spatial tap double tap")
    @MainActor func spatialTapDoubleTap() {
        let gesture = SpatialTapGesture(count: 2)
        #expect(gesture.count == 2)

        let view = Image(systemName: "heart")
            .gesture(gesture.onEnded { _ in })

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "img")
    }

    // MARK: - Long Press Gestures

    @Test("Long press gesture with default duration")
    @MainActor func longPressDefault() {
        let gesture = LongPressGesture()
        #expect(gesture.minimumDuration == 0.5)
        #expect(gesture.maximumDistance == 10.0)

        let view = Button("Hold me") { }
            .gesture(gesture.onEnded { _ in })

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "button")
    }

    @Test("Long press gesture with custom duration")
    @MainActor func longPressCustomDuration() {
        let gesture = LongPressGesture(minimumDuration: 1.0)
        #expect(gesture.minimumDuration == 1.0)

        let view = Text("Long press")
            .gesture(gesture.onEnded { _ in })

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("Long press gesture with custom distance")
    @MainActor func longPressCustomDistance() {
        let gesture = LongPressGesture(minimumDuration: 0.5, maximumDistance: 20.0)
        #expect(gesture.maximumDistance == 20.0)

        let view = Rectangle()
            .gesture(gesture.onEnded { _ in })

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("Long press gesture with pressed callback")
    @MainActor func longPressWithCallback() {
        let gesture = LongPressGesture()

        let view = Circle()
            .gesture(
                gesture
                    .onChanged { pressing in
                        // Track pressing state
                    }
                    .onEnded { success in
                        // Handle completion
                    }
            )

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    // MARK: - Drag Gestures

    @Test("Drag gesture with default parameters")
    @MainActor func dragGestureDefault() {
        let gesture = DragGesture()
        #expect(gesture.minimumDistance == 10.0)
        #expect(gesture.coordinateSpace == .local)

        let view = Rectangle()
            .gesture(gesture.onChanged { _ in })

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("Drag gesture with custom minimum distance")
    @MainActor func dragGestureCustomDistance() {
        let gesture = DragGesture(minimumDistance: 20.0)
        #expect(gesture.minimumDistance == 20.0)

        let view = Circle()
            .gesture(gesture.onChanged { _ in })

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("Drag gesture with zero minimum distance")
    @MainActor func dragGestureZeroDistance() {
        let gesture = DragGesture(minimumDistance: 0)
        #expect(gesture.minimumDistance == 0)

        let view = Text("Drag")
            .gesture(gesture.onChanged { _ in })

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("Drag gesture with global coordinates")
    @MainActor func dragGestureGlobalCoordinates() {
        let gesture = DragGesture(coordinateSpace: .global)
        #expect(gesture.coordinateSpace == .global)

        let view = Rectangle()
            .gesture(gesture.onChanged { _ in })

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("Drag gesture with named coordinates")
    @MainActor func dragGestureNamedCoordinates() {
        let gesture = DragGesture(minimumDistance: 15, coordinateSpace: .named("scroll"))

        let view = ScrollView {
            Text("Content")
                .gesture(gesture.onChanged { _ in })
        }
        .coordinateSpace(name: "scroll")

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("Drag gesture value structure")
    @MainActor func dragGestureValue() {
        let startLocation = CGPoint(x: 10, y: 20)
        let currentLocation = CGPoint(x: 50, y: 80)
        let velocity = CGSize(width: 100, height: 200)

        let value = DragGesture.Value(
            location: currentLocation,
            startLocation: startLocation,
            velocity: velocity,
            predictedEndLocation: currentLocation,
            time: Date()
        )

        #expect(value.translation.width == 40)
        #expect(value.translation.height == 60)
        #expect(value.velocity.width == 100)
        #expect(value.velocity.height == 200)
    }

    @Test("Drag gesture with onEnded callback")
    @MainActor func dragGestureOnEnded() {
        let gesture = DragGesture()

        let view = Rectangle()
            .gesture(
                gesture
                    .onChanged { value in
                        // Track drag
                    }
                    .onEnded { value in
                        // Handle end
                    }
            )

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    // MARK: - Rotation Gestures

    @Test("Rotation gesture recognition")
    @MainActor func rotationGesture() {
        let gesture = RotationGesture()

        let view = Image(systemName: "photo")
            .gesture(gesture.onChanged { _ in })

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "img")
    }

    @Test("Rotation gesture with angle value")
    @MainActor func rotationGestureValue() {
        let gesture = RotationGesture()

        let view = Rectangle()
            .gesture(
                gesture
                    .onChanged { angle in
                        // Rotate view
                    }
                    .onEnded { angle in
                        // Finalize rotation
                    }
            )

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    // MARK: - Magnification Gestures

    @Test("Magnification gesture recognition")
    @MainActor func magnificationGesture() {
        let gesture = MagnificationGesture()

        let view = Image(systemName: "photo")
            .gesture(gesture.onChanged { _ in })

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "img")
    }

    @Test("Magnification gesture with scale value")
    @MainActor func magnificationGestureValue() {
        let gesture = MagnificationGesture()

        let view = Circle()
            .gesture(
                gesture
                    .onChanged { scale in
                        // Scale view
                    }
                    .onEnded { scale in
                        // Finalize scale
                    }
            )

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    // MARK: - GestureState Property Wrapper

    @Test("GestureState with default value")
    @MainActor func gestureStateDefault() {
        @GestureState var dragOffset = CGSize.zero

        #expect(dragOffset == .zero)
    }

    @Test("GestureState with custom initial value")
    @MainActor func gestureStateInitialValue() {
        @GestureState var scale: Double = 1.0

        #expect(scale == 1.0)
    }

    @Test("GestureState updating with drag")
    @MainActor func gestureStateUpdating() {
        @GestureState var dragOffset = CGSize.zero

        let view = Circle()
            .offset(dragOffset)
            .gesture(
                DragGesture()
                    .updating($dragOffset) { value, state, transaction in
                        state = value.translation
                    }
            )

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("GestureState with custom reset function")
    @MainActor func gestureStateCustomReset() {
        @GestureState(
            reset: { value, transaction in
                transaction.animation = .spring()
            },
            initialValue: 0.0
        ) var rotation: Double

        #expect(rotation == 0.0)
    }

    @Test("GestureState with multiple properties")
    @MainActor func gestureStateMultiple() {
        @GestureState var offset = CGSize.zero
        @GestureState var isDragging = false

        let view = Rectangle()
            .offset(offset)
            .opacity(isDragging ? 0.5 : 1.0)
            .gesture(
                DragGesture()
                    .updating($offset) { value, state, _ in
                        state = value.translation
                    }
                    .updating($isDragging) { _, state, _ in
                        state = true
                    }
            )

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    // MARK: - Gesture Composition - Simultaneous

    @Test("Simultaneous gesture composition")
    @MainActor func simultaneousComposition() {
        let gesture = RotationGesture()
            .simultaneously(with: MagnificationGesture())

        let view = Image(systemName: "photo")
            .gesture(gesture.onChanged { _ in })

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "img")
    }

    @Test("Simultaneous drag and tap")
    @MainActor func simultaneousDragTap() {
        let gesture = DragGesture()
            .simultaneously(with: TapGesture())

        let view = Rectangle()
            .gesture(
                gesture.onChanged { value in
                    // Handle both gestures
                }
            )

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("Triple simultaneous gestures")
    @MainActor func tripleSimultaneous() {
        let rotation = RotationGesture()
        let magnification = MagnificationGesture()
        let combined = rotation.simultaneously(with: magnification)

        let view = Rectangle()
            .gesture(combined.onChanged { _ in })

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    // MARK: - Gesture Composition - Sequence

    @Test("Sequence gesture composition")
    @MainActor func sequenceComposition() {
        let gesture = LongPressGesture()
            .sequenced(before: DragGesture())

        let view = Rectangle()
            .gesture(gesture.onChanged { _ in })

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("Sequence gesture value states")
    @MainActor func sequenceGestureStates() {
        let gesture = LongPressGesture()
            .sequenced(before: DragGesture())

        let view = Circle()
            .gesture(
                gesture.onChanged { value in
                    switch value {
                    case .first:
                        // Long press in progress
                        break
                    case .second:
                        // Drag in progress
                        break
                    }
                }
            )

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("Sequence tap then drag")
    @MainActor func sequenceTapDrag() {
        let gesture = TapGesture()
            .sequenced(before: DragGesture())

        let view = Text("Tap then drag")
            .gesture(gesture.onChanged { _ in })

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    // MARK: - Gesture Composition - Exclusive

    @Test("Exclusive gesture composition")
    @MainActor func exclusiveComposition() {
        let gesture = TapGesture()
            .exclusively(before: LongPressGesture())

        let view = Button("Tap or hold") { }
            .gesture(gesture.onEnded { _ in })

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "button")
    }

    @Test("Exclusive gesture value types")
    @MainActor func exclusiveGestureTypes() {
        let gesture = TapGesture()
            .exclusively(before: LongPressGesture())

        let view = Rectangle()
            .gesture(
                gesture.onEnded { value in
                    switch value {
                    case .first:
                        // Tap won
                        break
                    case .second:
                        // Long press won
                        break
                    }
                }
            )

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("Exclusive double vs single tap")
    @MainActor func exclusiveDoubleSingleTap() {
        let gesture = TapGesture(count: 2)
            .exclusively(before: TapGesture())

        let view = Image(systemName: "heart")
            .gesture(gesture.onEnded { _ in })

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "img")
    }

    // MARK: - Gesture Modifiers

    @Test("Basic gesture modifier")
    @MainActor func basicGestureModifier() {
        let view = Text("Tap me")
            .gesture(
                TapGesture()
                    .onEnded { }
            )

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("Gesture with mask - gesture only")
    @MainActor func gestureModifierGestureOnly() {
        let view = ScrollView {
            Text("Content")
        }
        .gesture(
            DragGesture(),
            including: .gesture
        )

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("Gesture with mask - subviews only")
    @MainActor func gestureModifierSubviewsOnly() {
        let view = VStack {
            ForEach(0..<5) { index in
                Text("Item \(index)")
            }
        }
        .gesture(
            TapGesture().onEnded { },
            including: .subviews
        )

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("Gesture with mask - all (default)")
    @MainActor func gestureModifierAll() {
        let view = Rectangle()
            .gesture(
                DragGesture().onChanged { _ in },
                including: .all
            )

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("Gesture with mask - none (disabled)")
    @MainActor func gestureModifierNone() {
        let view = Button("Disabled") { }
            .gesture(
                TapGesture().onEnded { },
                including: .none
            )

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "button")
    }

    @Test("Simultaneous gesture modifier")
    @MainActor func simultaneousGestureModifier() {
        let view = ScrollView {
            ForEach(0..<10) { index in
                Text("Item \(index)")
                    .simultaneousGesture(
                        TapGesture().onEnded { }
                    )
            }
        }

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("High priority gesture modifier")
    @MainActor func highPriorityGestureModifier() {
        let view = ScrollView {
            Text("Content")
        }
        .highPriorityGesture(
            DragGesture().onChanged { _ in }
        )

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("Multiple gesture modifiers on same view")
    @MainActor func multipleGestureModifiers() {
        let view = Rectangle()
            .gesture(TapGesture().onEnded { })
            .simultaneousGesture(LongPressGesture().onEnded { _ in })
            .highPriorityGesture(DragGesture().onChanged { _ in })

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    // MARK: - Gesture Masks

    @Test("GestureMask option set operations")
    @MainActor func gestureMaskOperations() {
        let none = GestureMask.none
        let gesture = GestureMask.gesture
        let subviews = GestureMask.subviews
        let all = GestureMask.all

        #expect(none.rawValue == 0)
        #expect(gesture.contains(.gesture))
        #expect(subviews.contains(.subviews))
        #expect(all == [.gesture, .subviews])
    }

    @Test("GestureMask combination")
    @MainActor func gestureMaskCombination() {
        let mask: GestureMask = [.gesture, .subviews]
        #expect(mask == .all)
        #expect(mask.contains(.gesture))
        #expect(mask.contains(.subviews))
    }

    // MARK: - Event Modifiers

    @Test("EventModifiers option set")
    @MainActor func eventModifiersOptions() {
        let shift = EventModifiers.shift
        let control = EventModifiers.control
        let option = EventModifiers.option
        let command = EventModifiers.command

        #expect(shift.contains(.shift))
        #expect(control.contains(.control))
        #expect(option.contains(.option))
        #expect(command.contains(.command))
    }

    @Test("EventModifiers combination")
    @MainActor func eventModifiersCombination() {
        let modifiers: EventModifiers = [.shift, .command]
        #expect(modifiers.contains(.shift))
        #expect(modifiers.contains(.command))
        #expect(!modifiers.contains(.control))
    }

    // MARK: - Real-World Scenarios

    @Test("Draggable card with snap back")
    @MainActor func draggableCard() {
        @GestureState var dragOffset = CGSize.zero
        @State var permanentOffset = CGSize.zero

        let view = RoundedRectangle(cornerRadius: 20)
            .fill(Color.blue)
            .frame(width: 300, height: 400)
            .offset(
                x: permanentOffset.width + dragOffset.width,
                y: permanentOffset.height + dragOffset.height
            )
            .gesture(
                DragGesture()
                    .updating($dragOffset) { value, state, _ in
                        state = value.translation
                    }
                    .onEnded { value in
                        permanentOffset.width += value.translation.width
                        permanentOffset.height += value.translation.height
                    }
            )

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("Photo viewer with pinch zoom")
    @MainActor func photoViewer() {
        @State var scale: Double = 1.0
        @State var rotation: Angle = .zero

        let view = Image(systemName: "photo")
            .scaleEffect(scale)
            .rotationEffect(rotation)
            .gesture(
                RotationGesture()
                    .simultaneously(with: MagnificationGesture())
                    .onChanged { value in
                        rotation = value.0 ?? .zero
                        scale = value.1 ?? 1.0
                    }
            )

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "img")
    }

    @Test("Swipe to delete list item")
    @MainActor func swipeToDelete() {
        @State var offset: CGFloat = 0

        let view = HStack {
            Text("Swipe me")
                .padding()
                .background(Color.white)
                .offset(x: offset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if value.translation.width < 0 {
                                offset = value.translation.width
                            }
                        }
                        .onEnded { value in
                            if abs(offset) > 100 {
                                // Delete
                            } else {
                                offset = 0
                            }
                        }
                )

            Spacer()

            Button(action: {}) {
                Image(systemName: "trash")
            }
            .padding()
            .background(Color.red)
        }

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("Long press then drag reorder")
    @MainActor func longPressDragReorder() {
        @GestureState var dragOffset = CGSize.zero
        @State var isLongPressing = false

        let view = RoundedRectangle(cornerRadius: 10)
            .fill(isLongPressing ? Color.blue : Color.gray)
            .frame(width: 200, height: 60)
            .offset(dragOffset)
            .gesture(
                LongPressGesture(minimumDuration: 0.5)
                    .sequenced(before: DragGesture())
                    .updating($dragOffset) { value, state, _ in
                        switch value {
                        case .first:
                            state = .zero
                        case .second(true, let drag):
                            state = drag?.translation ?? .zero
                        case .second(false, _):
                            state = .zero
                        }
                    }
                    .onChanged { value in
                        switch value {
                        case .first:
                            isLongPressing = true
                        case .second:
                            break
                        }
                    }
                    .onEnded { _ in
                        isLongPressing = false
                    }
            )

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("Custom slider with drag")
    @MainActor func customSlider() {
        @State var value: Double = 0.5
        let width: Double = 300

        let view = ZStack(alignment: .leading) {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: width, height: 4)

            Circle()
                .fill(Color.blue)
                .frame(width: 30, height: 30)
                .offset(x: value * (width - 30))
                .gesture(
                    DragGesture(coordinateSpace: .local)
                        .onChanged { gesture in
                            let newValue = gesture.location.x / (width - 30)
                            value = min(max(newValue, 0), 1)
                        }
                )
        }

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("Interactive button with tap feedback")
    @MainActor func interactiveButton() {
        @State var isPressed = false

        let view = Button(action: {}) {
            Text("Tap Me")
                .padding()
                .background(Color.blue)
                .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0)
                .onChanged { pressing in
                    isPressed = pressing
                }
                .onEnded { _ in
                    isPressed = false
                }
        )

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "button")
    }

    // MARK: - Cross-Feature Integration

    @Test("Gesture with Phase 12 animation")
    @MainActor func gestureWithAnimation() {
        @State var scale = 1.0

        let view = Circle()
            .scaleEffect(scale)
            .animation(.spring(), value: scale)
            .gesture(
                TapGesture()
                    .onEnded {
                        scale = scale == 1.0 ? 1.5 : 1.0
                    }
            )

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("Gesture with Phase 10 shapes")
    @MainActor func gestureWithShapes() {
        @GestureState var dragOffset = CGSize.zero

        let view = RoundedRectangle(cornerRadius: 20)
            .fill(Color.blue)
            .frame(width: 100, height: 100)
            .offset(dragOffset)
            .gesture(
                DragGesture()
                    .updating($dragOffset) { value, state, _ in
                        state = value.translation
                    }
            )

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("Gesture in ScrollView")
    @MainActor func gestureInScrollView() {
        let view = ScrollView {
            ForEach(0..<10) { index in
                Text("Item \(index)")
                    .padding()
                    .simultaneousGesture(
                        TapGesture()
                            .onEnded { }
                    )
            }
        }

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("Gesture in List")
    @MainActor func gestureInList() {
        let view = List {
            ForEach(0..<5) { index in
                HStack {
                    Text("Item \(index)")
                    Spacer()
                }
                .gesture(
                    DragGesture()
                        .onEnded { _ in }
                )
            }
        }

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "ul")
    }

    // MARK: - Edge Cases

    @Test("Gesture on empty view")
    @MainActor func gestureOnEmptyView() {
        let view = EmptyView()
            .gesture(TapGesture().onEnded { })

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("Multiple gestures of same type")
    @MainActor func multipleGesturesSameType() {
        let view = Rectangle()
            .gesture(TapGesture().onEnded { })
            .gesture(TapGesture(count: 2).onEnded { })

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("Nested gesture modifiers")
    @MainActor func nestedGestureModifiers() {
        let view = VStack {
            HStack {
                Text("Child")
                    .gesture(TapGesture().onEnded { })
            }
            .gesture(LongPressGesture().onEnded { _ in })
        }
        .gesture(DragGesture().onChanged { _ in })

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("Gesture with conditional view")
    @MainActor func gestureWithConditional() {
        @State var showContent = true

        let view = VStack {
            if showContent {
                Text("Tap to hide")
                    .gesture(
                        TapGesture()
                            .onEnded {
                                showContent = false
                            }
                    )
            } else {
                Text("Tap to show")
                    .gesture(
                        TapGesture()
                            .onEnded {
                                showContent = true
                            }
                    )
            }
        }

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("Drag gesture with negative minimum distance")
    @MainActor func dragGestureNegativeDistance() {
        let gesture = DragGesture(minimumDistance: -5)
        #expect(gesture.minimumDistance == 0)
    }

    @Test("Long press with zero duration")
    @MainActor func longPressZeroDuration() {
        let gesture = LongPressGesture(minimumDuration: 0)
        #expect(gesture.minimumDuration >= 0)
    }

    @Test("Complex gesture composition nesting")
    @MainActor func complexGestureNesting() {
        let tap = TapGesture()
        let longPress = LongPressGesture()
        let drag = DragGesture()

        let composed = tap
            .exclusively(before: longPress)
            .sequenced(before: drag)

        let view = Rectangle()
            .gesture(composed.onChanged { _ in })

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }
}
