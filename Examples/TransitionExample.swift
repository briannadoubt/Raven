import Raven

/// Example demonstrating SwiftUI transitions in Raven.
///
/// This example shows how to use various transition types to animate
/// views when they appear and disappear from the view hierarchy.
@main
@MainActor
struct TransitionExampleApp {
    static func main() {
        print("Transition Example")
        print("==================")
        print()

        // Example 1: Basic opacity transition
        print("1. Opacity Transition")
        print("   - Fade in and out smoothly")
        print()

        struct OpacityExample: View {
            @State private var showDetails = false

            var body: some View {
                VStack {
                    Button("Toggle Details") {
                        showDetails.toggle()
                    }

                    if showDetails {
                        Text("Details appear here")
                            .transition(.opacity)
                    }
                }
            }
        }

        // Example 2: Scale transition with custom anchor
        print("2. Scale Transition")
        print("   - Scale from specified anchor point")
        print()

        struct ScaleExample: View {
            @State private var showPopup = false

            var body: some View {
                VStack {
                    Button("Show Popup") {
                        showPopup.toggle()
                    }

                    if showPopup {
                        VStack {
                            Text("Popup Content")
                            Text("Scales from center")
                        }
                        .padding()
                        .transition(.scale())
                    }
                }
            }
        }

        // Example 3: Move transition from different edges
        print("3. Move Transition")
        print("   - Slide from specific edges")
        print()

        struct MoveExample: View {
            @State private var showSidebar = false
            @State private var showBanner = false
            @State private var showSheet = false

            var body: some View {
                VStack {
                    Button("Toggle Sidebar") {
                        showSidebar.toggle()
                    }

                    Button("Toggle Banner") {
                        showBanner.toggle()
                    }

                    Button("Toggle Sheet") {
                        showSheet.toggle()
                    }

                    if showSidebar {
                        Text("Sidebar from leading")
                            .transition(.move(edge: .leading))
                    }

                    if showBanner {
                        Text("Banner from top")
                            .transition(.move(edge: .top))
                    }

                    if showSheet {
                        Text("Sheet from bottom")
                            .transition(.slide)  // Same as .move(edge: .bottom)
                    }
                }
            }
        }

        // Example 4: Combined transitions
        print("4. Combined Transitions")
        print("   - Multiple effects simultaneously")
        print()

        struct CombinedExample: View {
            @State private var showDialog = false

            var body: some View {
                VStack {
                    Button("Show Dialog") {
                        showDialog.toggle()
                    }

                    if showDialog {
                        VStack {
                            Text("Dialog Title")
                            Text("Fades and scales together")
                        }
                        .padding()
                        .transition(.opacity.combined(with: .scale()))
                    }
                }
            }
        }

        // Example 5: Asymmetric transitions
        print("5. Asymmetric Transitions")
        print("   - Different effects for insertion and removal")
        print()

        struct AsymmetricExample: View {
            @State private var showNotification = false

            var body: some View {
                VStack {
                    Button("Show Notification") {
                        showNotification.toggle()
                    }

                    if showNotification {
                        HStack {
                            Text("New Message")
                            Button("Dismiss") {
                                showNotification = false
                            }
                        }
                        .padding()
                        .transition(
                            .asymmetric(
                                insertion: .move(edge: .trailing),
                                removal: .opacity
                            )
                        )
                    }
                }
            }
        }

        // Example 6: Complex combined asymmetric transition
        print("6. Complex Transitions")
        print("   - Combining multiple techniques")
        print()

        struct ComplexExample: View {
            @State private var showCard = false

            var body: some View {
                VStack {
                    Button("Show Card") {
                        showCard.toggle()
                    }

                    if showCard {
                        VStack {
                            Text("Card Title")
                            Text("Multiple effects combined")
                        }
                        .padding()
                        .transition(
                            .asymmetric(
                                insertion: .opacity.combined(with: .scale(scale: 0.5)),
                                removal: .move(edge: .bottom).combined(with: .opacity)
                            )
                        )
                    }
                }
            }
        }

        // Example 7: Offset transition
        print("7. Offset Transition")
        print("   - Custom x/y translation")
        print()

        struct OffsetExample: View {
            @State private var showTooltip = false

            var body: some View {
                VStack {
                    Button("Show Tooltip") {
                        showTooltip.toggle()
                    }

                    if showTooltip {
                        Text("Tooltip text")
                            .padding()
                            .transition(.offset(x: 20, y: -10))
                    }
                }
            }
        }

        // Example 8: Scale with different anchor points
        print("8. Scale with Anchors")
        print("   - Using different transform origins")
        print()

        struct AnchorExample: View {
            @State private var showTopLeft = false
            @State private var showBottomRight = false

            var body: some View {
                VStack {
                    Button("Top-Leading Scale") {
                        showTopLeft.toggle()
                    }

                    Button("Bottom-Trailing Scale") {
                        showBottomRight.toggle()
                    }

                    if showTopLeft {
                        Text("Scales from top-leading")
                            .padding()
                            .transition(.scale(scale: 0.0, anchor: .topLeading))
                    }

                    if showBottomRight {
                        Text("Scales from bottom-trailing")
                            .padding()
                            .transition(.scale(scale: 0.0, anchor: .bottomTrailing))
                    }
                }
            }
        }

        // Example 9: Identity transition (no animation)
        print("9. Identity Transition")
        print("   - Instant appearance/disappearance")
        print()

        struct IdentityExample: View {
            @State private var showContent = false

            var body: some View {
                VStack {
                    Button("Toggle Content") {
                        showContent.toggle()
                    }

                    if showContent {
                        Text("Appears instantly")
                            .transition(.identity)
                    }
                }
            }
        }

        print()
        print("CSS Implementation Details:")
        print("===========================")
        print()

        // Show CSS keyframe generation
        let opacityTransition = AnyTransition.opacity
        print("Opacity Transition CSS:")
        print(opacityTransition.cssKeyframes())
        print()

        let scaleTransition = AnyTransition.scale(scale: 0.5)
        print("Scale Transition CSS:")
        print(scaleTransition.cssKeyframes())
        print()

        let slideTransition = AnyTransition.slide
        print("Slide Transition CSS:")
        print(slideTransition.cssKeyframes())
        print()

        let moveTransition = AnyTransition.move(edge: .leading)
        print("Move (Leading) Transition CSS:")
        print(moveTransition.cssKeyframes())
        print()

        let offsetTransition = AnyTransition.offset(x: 50, y: -30)
        print("Offset Transition CSS:")
        print(offsetTransition.cssKeyframes())
        print()

        let combinedTransition = AnyTransition.opacity.combined(with: .scale())
        print("Combined Transition CSS:")
        print(combinedTransition.cssKeyframes())
        print()

        print()
        print("All transition examples completed!")
    }
}
