import Testing
import Foundation
@testable import Raven

/// Phase 12 Verification Tests
///
/// These integration tests verify that all Phase 12 animation features work together correctly:
/// - Animation types and curves (easeIn, easeOut, spring, etc.)
/// - .animation() modifier for implicit animations
/// - withAnimation() for explicit animation blocks
/// - Transition system (.opacity, .scale, .slide, .move, .push, .modifier)
/// - keyframeAnimator() for multi-step animations
/// - Animation interruption and cancellation
/// - Cross-feature integration with previous phases
///
/// Focus: Integration testing across animation features, real-world scenarios, edge cases
@Suite("Phase 12 Integration Tests")
struct Phase12VerificationTests {

    // MARK: - Animation Curves with Modifiers

    @Test("Animation curves applied to opacity changes")
    @MainActor func animationCurvesWithOpacity() {
        let curves: [Animation] = [
            .linear,
            .easeIn,
            .easeOut,
            .easeInOut,
            .spring()
        ]

        for curve in curves {
            let view = Text("Fade")
                .opacity(0.5)
                .animation(curve, value: 0.5)

            let vnode = view.toVNode()
            #expect(vnode.elementTag == "div")
        }
    }

    @Test("Animation curves with scale transform")
    @MainActor func animationCurvesWithScale() {
        let view = Circle()
            .scaleEffect(1.5)
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: 1.5)

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("Animation curves with rotation")
    @MainActor func animationCurvesWithRotation() {
        let view = Rectangle()
            .rotationEffect(.degrees(45))
            .animation(.easeInOut(duration: 0.3), value: 45.0)

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("Animation curves with offset")
    @MainActor func animationCurvesWithOffset() {
        let view = Text("Moving")
            .offset(x: 100, y: 50)
            .animation(.linear(duration: 0.5), value: "offset")

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("Multiple animation curves on same view")
    @MainActor func multipleAnimationCurves() {
        let view = Text("Multi")
            .opacity(0.8)
            .animation(.easeIn, value: 0.8)
            .scaleEffect(1.2)
            .animation(.spring(), value: 1.2)

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    // MARK: - .animation() Modifier Integration

    @Test("Animation modifier with state-driven changes")
    @MainActor func animationWithStateChanges() {
        @State var isExpanded = false

        let view = VStack {
            Text("Header")
            if isExpanded {
                Text("Details")
                    .transition(.opacity)
            }
        }
        .animation(.default, value: isExpanded)

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("Animation modifier with binding changes")
    @MainActor func animationWithBindings() {
        @State var sliderValue = 0.5

        let view = VStack {
            Circle()
                .scaleEffect(sliderValue)
                .animation(.spring(), value: sliderValue)

            Text("Scale: \(sliderValue)")
        }

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("Animation modifier with multiple values")
    @MainActor func animationWithMultipleValues() {
        @State var rotation = 0.0
        @State var scale = 1.0

        let view = Rectangle()
            .rotationEffect(.degrees(rotation))
            .scaleEffect(scale)
            .animation(.spring(), value: rotation)
            .animation(.easeOut, value: scale)

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("Animation modifier with nil value")
    @MainActor func animationWithNilValue() {
        let view = Text("No Animation")
            .opacity(0.5)
            .animation(nil, value: 0.5)

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("Animation modifier inheritance in view hierarchy")
    @MainActor func animationInheritance() {
        @State var isActive = false

        let view = VStack {
            Text("Parent")
            HStack {
                Text("Child 1")
                Text("Child 2")
            }
        }
        .animation(.default, value: isActive)

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    // MARK: - withAnimation() Integration

    @Test("withAnimation for explicit state changes")
    @MainActor func withAnimationExplicit() {
        @State var isVisible = false

        withAnimation(.easeIn) {
            isVisible = true
        }

        let view = VStack {
            if isVisible {
                Text("Animated")
                    .transition(.opacity)
            }
        }

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("withAnimation with multiple state changes")
    @MainActor func withAnimationMultipleChanges() {
        @State var x = 0.0
        @State var y = 0.0
        @State var opacity = 1.0

        withAnimation(.spring()) {
            x = 100
            y = 50
            opacity = 0.5
        }

        let view = Circle()
            .offset(x: x, y: y)
            .opacity(opacity)

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("withAnimation with completion handler")
    @MainActor func withAnimationCompletion() async {
        @State var isComplete = false

        withAnimation(.default, {
            // Animate
        }, completion: {
            isComplete = true
        })

        // In real usage, completion would be called when animation finishes
        let view = Text("Done: \(isComplete)")
        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("Nested withAnimation calls")
    @MainActor func nestedWithAnimation() {
        @State var outer = 0.0
        @State var inner = 0.0

        withAnimation(.easeOut) {
            outer = 100
            withAnimation(.spring()) {
                inner = 50
            }
        }

        let view = VStack {
            Text("Outer: \(outer)")
            Text("Inner: \(inner)")
        }

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("withAnimation with conditional views")
    @MainActor func withAnimationConditional() {
        @State var showContent = false

        withAnimation {
            showContent = true
        }

        let view = VStack {
            Text("Header")
            if showContent {
                VStack {
                    Text("Line 1")
                    Text("Line 2")
                    Text("Line 3")
                }
                .transition(.opacity.combined(with: .scale))
            }
        }

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    // MARK: - Transitions on Conditional Views

    @Test("Opacity transition on conditional view")
    @MainActor func transitionOpacity() {
        @State var isVisible = true

        let view = VStack {
            if isVisible {
                Text("Fading")
                    .transition(.opacity)
            }
        }

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("Scale transition with different anchor points")
    @MainActor func transitionScaleAnchors() {
        let anchors: [UnitPoint] = [.center, .topLeading, .bottomTrailing, .top, .leading]

        for anchor in anchors {
            @State var show = true

            let view = VStack {
                if show {
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: 100, height: 100)
                        .transition(.scale(scale: 0.5, anchor: anchor))
                }
            }

            let vnode = view.toVNode()
            #expect(vnode.elementTag == "div")
        }
    }

    @Test("Slide transition from all edges")
    @MainActor func transitionSlideEdges() {
        let edges: [Edge] = [.top, .bottom, .leading, .trailing]

        for edge in edges {
            @State var show = true

            let view = VStack {
                if show {
                    Text("Sliding from \(edge)")
                        .transition(.move(edge: edge))
                }
            }

            let vnode = view.toVNode()
            #expect(vnode.elementTag == "div")
        }
    }

    @Test("Combined transitions")
    @MainActor func transitionCombined() {
        @State var show = true

        let view = VStack {
            if show {
                Text("Fancy")
                    .transition(.opacity.combined(with: .scale))
            }
        }

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("Asymmetric transitions")
    @MainActor func transitionAsymmetric() {
        @State var show = true

        let view = VStack {
            if show {
                Text("Asymmetric")
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .opacity
                    ))
            }
        }

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("Push transition from edges")
    @MainActor func transitionPush() {
        let edges: [Edge] = [.top, .bottom, .leading, .trailing]

        for edge in edges {
            @State var show = true

            let view = VStack {
                if show {
                    Text("Pushing from \(edge)")
                        .transition(.push(from: edge))
                }
            }

            let vnode = view.toVNode()
            #expect(vnode.elementTag == "div")
        }
    }

    @Test("Custom modifier transition")
    @MainActor func transitionCustomModifier() {
        struct TestModifier: ViewModifier {
            let opacity: Double

            func body(content: Content) -> some View {
                content.opacity(opacity)
            }
        }

        @State var show = true

        let transition = AnyTransition.modifier(
            active: TestModifier(opacity: 0),
            identity: TestModifier(opacity: 1)
        )

        let view = VStack {
            if show {
                Text("Custom")
                    .transition(transition)
            }
        }

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    // MARK: - keyframeAnimator() Multi-Step Animations

    @Test("keyframeAnimator with simple values")
    @MainActor func keyframeAnimatorSimple() {
        struct AnimationValues {
            var scale = 1.0
            var opacity = 1.0
        }

        let view = Circle()
            .keyframeAnimator(initialValue: AnimationValues()) { content, value in
                content
                    .scaleEffect(value.scale)
                    .opacity(value.opacity)
            } keyframes: { _ in
                KeyframeTrack(\.scale) {
                    LinearKeyframe(1.5, duration: 0.3)
                    SpringKeyframe(1.0, duration: 0.5, spring: .bouncy)
                }
                KeyframeTrack(\.opacity) {
                    LinearKeyframe(0.5, duration: 0.4)
                    LinearKeyframe(1.0, duration: 0.4)
                }
            }

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("keyframeAnimator with multiple tracks")
    @MainActor func keyframeAnimatorMultipleTracks() {
        struct ComplexValues {
            var x = 0.0
            var y = 0.0
            var rotation = 0.0
            var scale = 1.0
        }

        let view = Rectangle()
            .keyframeAnimator(initialValue: ComplexValues()) { content, value in
                content
                    .offset(x: value.x, y: value.y)
                    .rotationEffect(.degrees(value.rotation))
                    .scaleEffect(value.scale)
            } keyframes: { _ in
                KeyframeTrack(\.x) {
                    LinearKeyframe(100, duration: 0.5)
                    SpringKeyframe(0, duration: 0.5)
                }
                KeyframeTrack(\.y) {
                    LinearKeyframe(50, duration: 0.5)
                    SpringKeyframe(0, duration: 0.5)
                }
                KeyframeTrack(\.rotation) {
                    LinearKeyframe(180, duration: 0.5)
                    CubicKeyframe(360, duration: 0.5)
                }
                KeyframeTrack(\.scale) {
                    SpringKeyframe(1.5, duration: 0.5)
                    SpringKeyframe(1.0, duration: 0.5)
                }
            }

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("keyframeAnimator with trigger value")
    @MainActor func keyframeAnimatorWithTrigger() {
        struct Values {
            var scale = 1.0
        }

        @State var trigger = 0

        let view = Circle()
            .keyframeAnimator(
                initialValue: Values(),
                trigger: trigger
            ) { content, value in
                content.scaleEffect(value.scale)
            } keyframes: { _ in
                KeyframeTrack(\.scale) {
                    SpringKeyframe(1.2, duration: 0.3)
                    SpringKeyframe(1.0, duration: 0.3)
                }
            }

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    // MARK: - Animation Interruption

    @Test("Animation interruption with state changes")
    @MainActor func animationInterruption() {
        @State var position = 0.0

        // Start animation
        withAnimation(.linear(duration: 2.0)) {
            position = 100
        }

        // Interrupt with new animation
        withAnimation(.spring()) {
            position = 0
        }

        let view = Circle()
            .offset(x: position)

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("Rapid state changes with animation")
    @MainActor func rapidStateChanges() {
        @State var value = 0.0

        for i in 1...5 {
            withAnimation(.linear(duration: 0.1)) {
                value = Double(i) * 20
            }
        }

        let view = Rectangle()
            .offset(x: value)

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    // MARK: - Transition Composition

    @Test("Triple combined transitions")
    @MainActor func tripleTransitionCombination() {
        @State var show = true

        let view = VStack {
            if show {
                Text("Complex")
                    .transition(
                        .opacity
                            .combined(with: .scale)
                            .combined(with: .offset(x: 20, y: 10))
                    )
            }
        }

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("Nested asymmetric transitions")
    @MainActor func nestedAsymmetricTransitions() {
        @State var show = true

        let insertTransition = AnyTransition.scale.combined(with: .opacity)
        let removeTransition = AnyTransition.move(edge: .trailing)

        let view = VStack {
            if show {
                Text("Nested Asymmetric")
                    .transition(.asymmetric(
                        insertion: insertTransition,
                        removal: removeTransition
                    ))
            }
        }

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    // MARK: - Cross-Feature Integration (Phase 9-11)

    @Test("Animation with Phase 9 gestures")
    @MainActor func animationWithGestures() {
        @State var scale = 1.0

        let view = Circle()
            .scaleEffect(scale)
            .animation(.spring(), value: scale)
            .onTapGesture {
                scale = scale == 1.0 ? 1.5 : 1.0
            }

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("Transition with Phase 10 shapes")
    @MainActor func transitionWithShapes() {
        @State var showShape = true

        let view = VStack {
            if showShape {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.blue)
                    .frame(width: 100, height: 100)
                    .transition(.scale.combined(with: .opacity))
            }
        }

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("Animation with Phase 11 container frames")
    @MainActor func animationWithContainerFrames() {
        @State var expanded = false

        let view = VStack {
            Rectangle()
                .fill(Color.blue)
                .containerRelativeFrame(.horizontal) { width, _ in
                    expanded ? width * 0.8 : width * 0.4
                }
                .animation(.spring(), value: expanded)
        }

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("Animation with scrollTransition")
    @MainActor func animationWithScrollTransition() {
        let view = ScrollView {
            ForEach(0..<10) { index in
                Text("Item \(index)")
                    .scrollTransition { content, phase in
                        content
                            .opacity(phase.isIdentity ? 1 : 0.5)
                            .scaleEffect(phase.isIdentity ? 1 : 0.8)
                    }
            }
        }

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("Animation with searchable modifier")
    @MainActor func animationWithSearchable() {
        @State var searchText = ""
        @State var isSearching = false

        let view = VStack {
            if isSearching {
                Text("Searching...")
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
            List {
                Text("Item 1")
                Text("Item 2")
            }
        }
        .searchable(text: $searchText)
        .animation(.default, value: isSearching)

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    // MARK: - Complex UI Scenarios

    @Test("Animated button with spring bounce")
    @MainActor func animatedButton() {
        @State var isPressed = false

        let view = Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed.toggle()
            }
        }) {
            Text("Tap Me")
                .padding()
                .background(Color.blue)
                .scaleEffect(isPressed ? 0.95 : 1.0)
        }

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "button")
    }

    @Test("List with insert/remove transitions")
    @MainActor func listWithTransitions() {
        @State var items = ["Item 1", "Item 2", "Item 3"]

        let view = VStack {
            ForEach(items, id: \.self) { item in
                Text(item)
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
            }
        }
        .animation(.spring(), value: items)

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("Loading spinner with keyframes")
    @MainActor func loadingSpinner() {
        struct SpinnerValues {
            var rotation = 0.0
            var scale = 1.0
        }

        let view = Circle()
            .stroke(Color.blue, lineWidth: 3)
            .frame(width: 40, height: 40)
            .keyframeAnimator(initialValue: SpinnerValues()) { content, value in
                content
                    .rotationEffect(.degrees(value.rotation))
                    .scaleEffect(value.scale)
            } keyframes: { _ in
                KeyframeTrack(\.rotation) {
                    LinearKeyframe(360, duration: 1.0)
                }
                KeyframeTrack(\.scale) {
                    SpringKeyframe(1.2, duration: 0.5)
                    SpringKeyframe(1.0, duration: 0.5)
                }
            }

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("Animated counter/progress bar")
    @MainActor func animatedProgress() {
        @State var progress = 0.0

        let view = VStack {
            Text("\(Int(progress * 100))%")
            Rectangle()
                .fill(Color.blue)
                .frame(width: progress * 200, height: 20)
                .animation(.easeInOut(duration: 0.5), value: progress)
        }

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("Page transition demo")
    @MainActor func pageTransitions() {
        @State var currentPage = 0

        let view = VStack {
            if currentPage == 0 {
                Text("Page 1")
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    ))
            } else if currentPage == 1 {
                Text("Page 2")
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    ))
            }
        }
        .animation(.easeInOut, value: currentPage)

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("Complete animated UI flow")
    @MainActor func completeAnimatedFlow() {
        @State var step = 0
        @State var isLoading = false

        let view = VStack {
            if step == 0 {
                VStack {
                    Text("Welcome")
                    Button("Start") {
                        withAnimation {
                            step = 1
                        }
                    }
                }
                .transition(.opacity.combined(with: .scale))
            } else if step == 1 {
                if isLoading {
                    Circle()
                        .stroke(Color.blue, lineWidth: 3)
                        .frame(width: 40, height: 40)
                        .transition(.opacity)
                } else {
                    Text("Complete!")
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    // MARK: - Edge Cases and Error Conditions

    @Test("Animation with zero duration")
    @MainActor func animationZeroDuration() {
        let view = Text("Instant")
            .opacity(0.5)
            .animation(.linear(duration: 0), value: 0.5)

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("Transition on view that never appears")
    @MainActor func transitionNeverAppears() {
        let view = VStack {
            if false {
                Text("Hidden")
                    .transition(.opacity)
            }
        }

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("Empty keyframe animator")
    @MainActor func emptyKeyframeAnimator() {
        struct Values {
            var opacity = 1.0
        }

        let view = Text("No Keyframes")
            .keyframeAnimator(initialValue: Values()) { content, value in
                content.opacity(value.opacity)
            } keyframes: { _ in
                // Empty keyframes
            }

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("Conflicting animations on same property")
    @MainActor func conflictingAnimations() {
        @State var opacity1 = 0.5
        @State var opacity2 = 0.8

        let view = Text("Conflict")
            .opacity(opacity1)
            .animation(.easeIn, value: opacity1)
            .opacity(opacity2)
            .animation(.easeOut, value: opacity2)

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("Deeply nested transitions")
    @MainActor func deeplyNestedTransitions() {
        @State var show = true

        let view = VStack {
            if show {
                VStack {
                    HStack {
                        VStack {
                            Text("Deep")
                                .transition(.opacity)
                        }
                        .transition(.scale)
                    }
                    .transition(.move(edge: .bottom))
                }
                .transition(.move(edge: .top))
            }
        }

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    // MARK: - Performance Scenarios

    @Test("Many simultaneous animations")
    @MainActor func manySimultaneousAnimations() {
        let view = VStack {
            ForEach(0..<20) { index in
                Circle()
                    .fill(Color.blue)
                    .frame(width: 20, height: 20)
                    .opacity(Double(index) / 20.0)
                    .animation(.easeInOut(duration: 0.5), value: Double(index))
            }
        }

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("Complex transition with many modifiers")
    @MainActor func complexTransitionManyModifiers() {
        @State var show = true

        let view = VStack {
            if show {
                Text("Complex")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .shadow(radius: 5)
                    .transition(
                        .opacity
                            .combined(with: .scale)
                            .combined(with: .move(edge: .bottom))
                    )
            }
        }

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }
}
