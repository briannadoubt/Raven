import Testing
import Foundation
@testable import Raven

/// Phase 11 Verification Tests
///
/// These integration tests verify that all Phase 11 features work together correctly:
/// - containerRelativeFrame() modifier for responsive sizing
/// - ViewThatFits container for adaptive layouts
/// - Scroll behavior modifiers (.scrollBounceBehavior, .scrollClipDisabled)
/// - scrollTransition() modifier for scroll-driven animations
/// - searchable() modifier for search functionality
///
/// Focus: Integration testing across features, real-world scenarios, edge cases
@Suite("Phase 11 Integration Tests")
struct Phase11VerificationTests {

    // MARK: - Container Relative Frame Integration

    @Test("Container relative frame with nested stacks")
    @MainActor func containerFrameWithNestedStacks() {
        let view = VStack {
            Text("Header")
            HStack {
                Text("Left")
                    .containerRelativeFrame(.horizontal) { width, _ in width * 0.5 }
                Text("Right")
                    .containerRelativeFrame(.horizontal) { width, _ in width * 0.5 }
            }
        }

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("Container relative frame with grid layout - three columns")
    @MainActor func containerFrameGridThreeColumns() {
        let view = HStack {
            Text("Column 1")
                .containerRelativeFrame(.horizontal, count: 3, spacing: 10)
            Text("Column 2")
                .containerRelativeFrame(.horizontal, count: 3, spacing: 10)
            Text("Column 3")
                .containerRelativeFrame(.horizontal, count: 3, spacing: 10)
        }

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("Container relative frame spanning multiple grid cells")
    @MainActor func containerFrameGridSpan() {
        let view = VStack {
            Text("Wide Item")
                .containerRelativeFrame(.horizontal, count: 4, span: 3, spacing: 8)
            Text("Narrow Item")
                .containerRelativeFrame(.horizontal, count: 4, span: 1, spacing: 8)
        }

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("Container relative frame with alignment variations")
    @MainActor func containerFrameAlignments() {
        let alignments: [Alignment] = [.leading, .center, .trailing, .topLeading, .bottomTrailing]

        for alignment in alignments {
            let view = Text("Test")
                .containerRelativeFrame(.horizontal, alignment: alignment) { width, _ in width * 0.8 }

            let vnode = view.toVNode()
            #expect(vnode.elementTag == "div")
        }
    }

    @Test("Container relative frame with Phase 9 modifiers")
    @MainActor func containerFrameWithPhase9Modifiers() {
        let view = Text("Interactive")
            .containerRelativeFrame(.horizontal) { width, _ in width * 0.5 }
            .padding()
            .background(Color.blue)
            .onTapGesture {
                // Tap handler
            }

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("Container relative frame with Phase 10 shapes")
    @MainActor func containerFrameWithShapes() {
        let view = Circle()
            .fill(Color.blue)
            .containerRelativeFrame([.horizontal, .vertical], count: 3, spacing: 10)

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    // MARK: - ViewThatFits Integration

    @Test("ViewThatFits with desktop to mobile responsive layout")
    @MainActor func viewThatFitsResponsiveLayout() {
        let view = ViewThatFits(in: .horizontal) {
            // Desktop: horizontal layout
            HStack {
                Text("Logo")
                Text("Navigation")
                Text("Search")
                Text("Profile")
            }

            // Tablet: compact layout
            HStack {
                Text("Logo")
                Text("Menu")
                Text("Profile")
            }

            // Mobile: minimal layout
            HStack {
                Text("☰")
                Text("Logo")
            }
        }

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")

        // Should have container-type set
        let containerType = vnode.props["container-type"]
        #expect(containerType != nil)
    }

    @Test("ViewThatFits with vertical constraint")
    @MainActor func viewThatFitsVertical() {
        let view = ViewThatFits(in: .vertical) {
            VStack {
                Text("Line 1")
                Text("Line 2")
                Text("Line 3")
                Text("Line 4")
            }

            VStack {
                Text("Line 1")
                Text("Line 2")
            }

            Text("...")
        }

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")

        let axesAttr = vnode.props["data-fit-axes"]
        #expect(axesAttr != nil)
    }

    @Test("ViewThatFits with both axes constraint")
    @MainActor func viewThatFitsBothAxes() {
        let view = ViewThatFits(in: [.horizontal, .vertical]) {
            VStack {
                HStack {
                    Text("A")
                    Text("B")
                    Text("C")
                }
                Text("Details")
            }

            HStack {
                Text("A")
                Text("B")
            }

            Text("A")
        }

        let vnode = view.toVNode()
        let axesAttr = vnode.props["data-fit-axes"]
        #expect(axesAttr != nil)
        if case .attribute(_, let value) = axesAttr {
            #expect(value == "both")
        }
    }

    @Test("ViewThatFits with containerRelativeFrame combination")
    @MainActor func viewThatFitsWithContainerFrame() {
        let view = ViewThatFits {
            HStack {
                Text("Full Width Item")
                    .containerRelativeFrame(.horizontal) { width, _ in width }
            }

            VStack {
                Text("Half Width Item")
                    .containerRelativeFrame(.horizontal) { width, _ in width * 0.5 }
            }
        }

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("ViewThatFits with Phase 10 visual effects")
    @MainActor func viewThatFitsWithVisualEffects() {
        let view = ViewThatFits {
            Circle()
                .fill(Color.blue)
                .frame(width: 200, height: 200)
                .blur(radius: 5)

            Circle()
                .fill(Color.blue)
                .frame(width: 100, height: 100)

            Circle()
                .fill(Color.blue)
                .frame(width: 50, height: 50)
        }

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("ViewThatFits nested within another ViewThatFits")
    @MainActor func nestedViewThatFits() {
        let view = ViewThatFits(in: .horizontal) {
            HStack {
                ViewThatFits(in: .vertical) {
                    VStack {
                        Text("A")
                        Text("B")
                    }
                    Text("A")
                }
            }

            Text("Compact")
        }

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    // MARK: - Scroll Behavior Modifiers Integration

    @Test("Scroll bounce behavior with container relative frame")
    @MainActor func scrollBounceWithContainerFrame() {
        let view = VStack {
            Text("Item 1")
                .containerRelativeFrame(.horizontal) { width, _ in width }
            Text("Item 2")
                .containerRelativeFrame(.horizontal) { width, _ in width }
        }
        .scrollBounceBehavior(.basedOnSize)

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")

        // Should have overscroll-behavior set
        let overscroll = vnode.props["overscroll-behavior-y"]
        #expect(overscroll != nil)
    }

    @Test("Scroll bounce behavior on horizontal axis only")
    @MainActor func scrollBounceHorizontalOnly() {
        let view = HStack {
            Text("Item 1")
            Text("Item 2")
            Text("Item 3")
        }
        .scrollBounceBehavior(.always, axes: [.horizontal])

        let vnode = view.toVNode()
        #expect(vnode.props["overscroll-behavior-x"] != nil)
    }

    @Test("Scroll clip disabled with shadows")
    @MainActor func scrollClipDisabledWithShadows() {
        let view = VStack {
            Text("Card 1")
                .padding()
                .background(Color.white)
                .shadow(radius: 10)
            Text("Card 2")
                .padding()
                .background(Color.white)
                .shadow(radius: 10)
        }
        .scrollClipDisabled()

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")

        // Should have overflow visible
        let overflow = vnode.props["overflow"]
        #expect(overflow != nil)
        if case .style(_, let value) = overflow {
            #expect(value == "visible")
        }
    }

    @Test("Scroll clip disabled set to false")
    @MainActor func scrollClipEnabledExplicitly() {
        let view = VStack {
            Text("Content")
        }
        .scrollClipDisabled(false)

        let vnode = view.toVNode()

        let overflow = vnode.props["overflow"]
        #expect(overflow != nil)
        if case .style(_, let value) = overflow {
            #expect(value == "hidden")
        }
    }

    @Test("Scroll behavior with ViewThatFits")
    @MainActor func scrollBehaviorWithViewThatFits() {
        let view = ViewThatFits {
            VStack {
                Text("Long Content")
                Text("More Content")
            }
            .scrollBounceBehavior(.always)

            Text("Short")
        }

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    // MARK: - Scroll Transition Integration

    @Test("Scroll transition with opacity change")
    @MainActor func scrollTransitionOpacity() {
        // Test that scrollTransition creates a _ScrollTransitionView
        let baseView = Text("Fade In")
        let transitionView = _ScrollTransitionView(
            content: baseView,
            configuration: ScrollTransitionConfiguration(axis: nil)
        )

        let vnode = transitionView.toVNode()
        #expect(vnode.elementTag == "div")

        // Should have scroll transition marker
        let marker = vnode.props["data-scroll-transition"]
        #expect(marker != nil)
    }

    @Test("Scroll transition with scale effect")
    @MainActor func scrollTransitionScale() {
        let baseView = Circle().fill(Color.blue)
        let transitionView = _ScrollTransitionView(
            content: baseView,
            configuration: ScrollTransitionConfiguration(axis: nil)
        )

        let vnode = transitionView.toVNode()

        // Should have transition CSS property
        let transition = vnode.props["transition"]
        #expect(transition != nil)
    }

    @Test("Scroll transition with axis constraint")
    @MainActor func scrollTransitionAxisConstraint() {
        let baseView = Text("Horizontal Scroll Animation")
        let transitionView = _ScrollTransitionView(
            content: baseView,
            configuration: ScrollTransitionConfiguration(axis: .horizontal)
        )

        let vnode = transitionView.toVNode()

        let axisAttr = vnode.props["data-scroll-axis"]
        #expect(axisAttr != nil)
        if case .attribute(_, let value) = axisAttr {
            #expect(value == "horizontal")
        }
    }

    @Test("Scroll transition with containerRelativeFrame")
    @MainActor func scrollTransitionWithContainerFrame() {
        let baseView = Text("Card")
            .containerRelativeFrame(.horizontal, count: 3, spacing: 10)

        let transitionView = _ScrollTransitionView(
            content: baseView,
            configuration: ScrollTransitionConfiguration(axis: nil)
        )

        let vnode = transitionView.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("Multiple scroll transitions on same view")
    @MainActor func multipleScrollTransitions() {
        // Test layering scroll transitions
        let baseView = Text("Animated")
        let horizontalTransition = _ScrollTransitionView(
            content: baseView,
            configuration: ScrollTransitionConfiguration(axis: .horizontal)
        )
        let verticalTransition = _ScrollTransitionView(
            content: horizontalTransition,
            configuration: ScrollTransitionConfiguration(axis: .vertical)
        )

        let vnode = verticalTransition.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("Scroll transition in ViewThatFits")
    @MainActor func scrollTransitionInViewThatFits() {
        // Test scroll transitions within ViewThatFits content
        let item1 = _ScrollTransitionView(
            content: Text("Item 1"),
            configuration: ScrollTransitionConfiguration(axis: nil)
        )
        let item2 = _ScrollTransitionView(
            content: Text("Item 2"),
            configuration: ScrollTransitionConfiguration(axis: nil)
        )

        let view = ViewThatFits {
            VStack {
                item1
                item2
            }

            Text("Compact")
        }

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    // MARK: - Searchable Integration

    @Test("Searchable with basic text binding")
    @MainActor func searchableBasic() {
        let searchText = Binding<String>(
            get: { "" },
            set: { _ in }
        )

        let view = VStack {
            Text("Item 1")
            Text("Item 2")
        }
        .searchable(text: searchText)

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")

        // Should have flex-direction column
        let flexDir = vnode.props["flex-direction"]
        #expect(flexDir != nil)
    }

    @Test("Searchable with custom prompt")
    @MainActor func searchableWithPrompt() {
        let searchText = Binding<String>(
            get: { "" },
            set: { _ in }
        )

        let view = VStack {
            Text("Contact 1")
            Text("Contact 2")
        }
        .searchable(text: searchText, prompt: Text("Search contacts"))

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("Searchable with navigation bar drawer placement")
    @MainActor func searchableNavigationBarDrawer() {
        let searchText = Binding<String>(
            get: { "" },
            set: { _ in }
        )

        let view = VStack {
            Text("Item")
        }
        .searchable(text: searchText, placement: .navigationBarDrawer, prompt: Text("Search"))

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("Searchable with ViewThatFits content")
    @MainActor func searchableWithViewThatFits() {
        let searchText = Binding<String>(
            get: { "" },
            set: { _ in }
        )

        let view = ViewThatFits {
            HStack {
                Text("Result 1")
                Text("Result 2")
            }

            VStack {
                Text("Result 1")
                Text("Result 2")
            }
        }
        .searchable(text: searchText)

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("Searchable with containerRelativeFrame items")
    @MainActor func searchableWithContainerFrameItems() {
        let searchText = Binding<String>(
            get: { "" },
            set: { _ in }
        )

        let view = VStack {
            Text("Item 1")
                .containerRelativeFrame(.horizontal) { width, _ in width * 0.9 }
            Text("Item 2")
                .containerRelativeFrame(.horizontal) { width, _ in width * 0.9 }
        }
        .searchable(text: searchText, prompt: Text("Find items"))

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("Searchable with scroll transitions")
    @MainActor func searchableWithScrollTransitions() {
        let searchText = Binding<String>(
            get: { "" },
            set: { _ in }
        )

        let result1 = _ScrollTransitionView(
            content: Text("Result 1"),
            configuration: ScrollTransitionConfiguration(axis: nil)
        )
        let result2 = _ScrollTransitionView(
            content: Text("Result 2"),
            configuration: ScrollTransitionConfiguration(axis: nil)
        )

        let view = VStack {
            result1
            result2
        }
        .searchable(text: searchText)

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    // MARK: - Full UI Scenarios

    @Test("Responsive photo gallery with search")
    @MainActor func responsivePhotoGallery() {
        let searchText = Binding<String>(
            get: { "" },
            set: { _ in }
        )

        let view = VStack {
            ViewThatFits(in: .horizontal) {
                // Desktop: 4 columns
                HStack {
                    Rectangle()
                        .fill(Color.blue)
                        .containerRelativeFrame(.horizontal, count: 4, spacing: 10)
                    Rectangle()
                        .fill(Color.blue)
                        .containerRelativeFrame(.horizontal, count: 4, spacing: 10)
                    Rectangle()
                        .fill(Color.blue)
                        .containerRelativeFrame(.horizontal, count: 4, spacing: 10)
                    Rectangle()
                        .fill(Color.blue)
                        .containerRelativeFrame(.horizontal, count: 4, spacing: 10)
                }

                // Tablet: 3 columns
                HStack {
                    Rectangle()
                        .fill(Color.blue)
                        .containerRelativeFrame(.horizontal, count: 3, spacing: 10)
                    Rectangle()
                        .fill(Color.blue)
                        .containerRelativeFrame(.horizontal, count: 3, spacing: 10)
                    Rectangle()
                        .fill(Color.blue)
                        .containerRelativeFrame(.horizontal, count: 3, spacing: 10)
                }

                // Mobile: 2 columns
                HStack {
                    Rectangle()
                        .fill(Color.blue)
                        .containerRelativeFrame(.horizontal, count: 2, spacing: 8)
                    Rectangle()
                        .fill(Color.blue)
                        .containerRelativeFrame(.horizontal, count: 2, spacing: 8)
                }
            }
        }
        .searchable(text: searchText, prompt: Text("Search photos"))

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("Responsive navigation with adaptive layout")
    @MainActor func responsiveNavigation() {
        let view = ViewThatFits(in: .horizontal) {
            // Wide: Full navigation
            HStack {
                Text("Home")
                Text("Products")
                Text("About")
                Text("Contact")
                Text("Blog")
            }
            .padding()

            // Medium: Compact navigation
            HStack {
                Text("Home")
                Text("Products")
                Text("More ▾")
            }
            .padding()

            // Narrow: Menu only
            HStack {
                Text("☰")
                Text("Menu")
            }
            .padding()
        }
        .containerRelativeFrame(.horizontal) { width, _ in width }

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("Scrollable card list with transitions")
    @MainActor func scrollableCardListWithTransitions() {
        let card1 = _ScrollTransitionView(
            content: Text("Card 1")
                .padding()
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(radius: 4),
            configuration: ScrollTransitionConfiguration(axis: nil)
        )

        let card2 = _ScrollTransitionView(
            content: Text("Card 2")
                .padding()
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(radius: 4),
            configuration: ScrollTransitionConfiguration(axis: nil)
        )

        let view = VStack {
            card1
            card2
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollClipDisabled()

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("Search results with responsive grid")
    @MainActor func searchResultsResponsiveGrid() {
        let searchText = Binding<String>(
            get: { "query" },
            set: { _ in }
        )

        let view = ViewThatFits {
            // Desktop: 3 column grid
            VStack {
                HStack {
                    Text("Result 1")
                        .containerRelativeFrame(.horizontal, count: 3, spacing: 16)
                    Text("Result 2")
                        .containerRelativeFrame(.horizontal, count: 3, spacing: 16)
                    Text("Result 3")
                        .containerRelativeFrame(.horizontal, count: 3, spacing: 16)
                }
            }

            // Mobile: Single column
            VStack {
                Text("Result 1")
                    .containerRelativeFrame(.horizontal) { width, _ in width }
                Text("Result 2")
                    .containerRelativeFrame(.horizontal) { width, _ in width }
                Text("Result 3")
                    .containerRelativeFrame(.horizontal) { width, _ in width }
            }
        }
        .searchable(text: searchText, prompt: Text("Search products"))

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("Complete responsive dashboard")
    @MainActor func completeDashboard() {
        let searchText = Binding<String>(
            get: { "" },
            set: { _ in }
        )

        let blueCircle = _ScrollTransitionView(
            content: Circle().fill(Color.blue),
            configuration: ScrollTransitionConfiguration(axis: nil)
        )

        let greenCircle = _ScrollTransitionView(
            content: Circle().fill(Color.green),
            configuration: ScrollTransitionConfiguration(axis: nil)
        )

        let view = VStack {
            // Header adapts to screen size
            ViewThatFits(in: .horizontal) {
                HStack {
                    Text("Dashboard")
                    Text("Analytics")
                    Text("Reports")
                    Text("Settings")
                }

                HStack {
                    Text("Dashboard")
                    Text("Menu ▾")
                }
            }
            .containerRelativeFrame(.horizontal) { width, _ in width }

            // Main content with responsive grid
            ViewThatFits {
                HStack {
                    // Desktop: side-by-side
                    VStack {
                        blueCircle
                    }
                    .containerRelativeFrame(.horizontal, count: 2, spacing: 20)

                    VStack {
                        greenCircle
                    }
                    .containerRelativeFrame(.horizontal, count: 2, spacing: 20)
                }

                // Mobile: stacked
                VStack {
                    Circle()
                        .fill(Color.blue)
                    Circle()
                        .fill(Color.green)
                }
            }
        }
        .searchable(text: searchText, placement: .navigationBarDrawer)
        .scrollBounceBehavior(.basedOnSize)

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    // MARK: - Edge Cases and Complex Scenarios

    @Test("Empty search text binding")
    @MainActor func emptySearchBinding() {
        let searchText = Binding<String>(
            get: { "" },
            set: { _ in }
        )

        let view = Text("Content")
            .searchable(text: searchText)

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("Container relative frame with zero spacing")
    @MainActor func containerFrameZeroSpacing() {
        let view = Text("Test")
            .containerRelativeFrame(.horizontal, count: 4, spacing: 0)

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("ViewThatFits with single option")
    @MainActor func viewThatFitsSingleOption() {
        let view = ViewThatFits {
            Text("Only Option")
        }

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("Scroll transition with all visual effects")
    @MainActor func scrollTransitionWithAllEffects() {
        let baseView = Rectangle()
            .fill(Color.blue)
            .blur(radius: 2)
            .brightness(1.1)
            .saturation(1.2)

        let view = _ScrollTransitionView(
            content: baseView,
            configuration: ScrollTransitionConfiguration(axis: nil)
        )

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("Nested container relative frames")
    @MainActor func nestedContainerFrames() {
        let view = VStack {
            HStack {
                Text("Nested")
                    .containerRelativeFrame(.horizontal, count: 2)
            }
            .containerRelativeFrame(.vertical, count: 2)
        }

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("All Phase 11 features combined")
    @MainActor func allPhase11FeaturesCombined() {
        let searchText = Binding<String>(
            get: { "test" },
            set: { _ in }
        )

        let blueCircleWithFrame = Circle()
            .fill(Color.blue)
            .containerRelativeFrame([.horizontal, .vertical], count: 3, spacing: 10)

        let blueCircleTransition = _ScrollTransitionView(
            content: blueCircleWithFrame,
            configuration: ScrollTransitionConfiguration(axis: nil)
        )

        let greenRectWithFrame = Rectangle()
            .fill(Color.green)
            .containerRelativeFrame([.horizontal, .vertical], count: 3, spacing: 10)

        let greenRectTransition = _ScrollTransitionView(
            content: greenRectWithFrame,
            configuration: ScrollTransitionConfiguration(axis: nil)
        )

        let view = ViewThatFits(in: .horizontal) {
            HStack {
                blueCircleTransition
                greenRectTransition
            }

            VStack {
                Circle()
                    .fill(Color.blue)
                    .containerRelativeFrame(.horizontal) { width, _ in width }
            }
        }
        .scrollBounceBehavior(.basedOnSize, axes: [.vertical])
        .scrollClipDisabled()
        .searchable(text: searchText, placement: .navigationBarDrawer, prompt: Text("Search"))

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }
}
