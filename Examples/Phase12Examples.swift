import Foundation
@testable import Raven

/// Phase 12 Animation System Examples
///
/// This file contains comprehensive examples demonstrating all Phase 12 animation features:
/// - Animation curves and timing functions
/// - .animation() modifier for implicit animations
/// - withAnimation() for explicit animation blocks
/// - Transition system with all transition types
/// - keyframeAnimator() for multi-step animations
/// - Real-world UI patterns
///
/// These examples can be used as:
/// - Learning resources for animation system usage
/// - Templates for common animation patterns
/// - Test cases for animation functionality
/// - Documentation of animation capabilities

// MARK: - Example 1: Animated Button with Spring Bounce

/// Demonstrates spring-based button animation with scale feedback.
///
/// Key features:
/// - Spring animation with custom response and damping
/// - Scale effect for press feedback
/// - State-driven animation with .animation() modifier
struct AnimatedButtonExample {
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            isPressed.toggle()
        }) {
            Text("Tap Me!")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(isPressed ? Color.blue : Color.green)
                .cornerRadius(25)
                .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
    }
}

// MARK: - Example 2: List with Insert/Remove Transitions

/// Demonstrates dynamic list with smooth insert and remove animations.
///
/// Key features:
/// - Asymmetric transitions (different for insertion and removal)
/// - Combined transitions (move + opacity)
/// - State-driven list updates
/// - Spring animation for natural motion
struct AnimatedListExample {
    @State private var items: [String] = ["Apple", "Banana", "Cherry"]
    @State private var nextId = 4

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Button("Add Item") {
                    withAnimation(.spring()) {
                        items.append("Item \(nextId)")
                        nextId += 1
                    }
                }

                Button("Remove Last") {
                    withAnimation(.spring()) {
                        if !items.isEmpty {
                            items.removeLast()
                        }
                    }
                }
            }

            VStack(spacing: 8) {
                ForEach(items, id: \.self) { item in
                    Text(item)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                        .transition(.asymmetric(
                            insertion: .move(edge: .leading).combined(with: .opacity),
                            removal: .move(edge: .trailing).combined(with: .opacity)
                        ))
                }
            }
        }
        .padding()
    }
}

// MARK: - Example 3: Loading Spinner with Keyframes

/// Demonstrates rotating loading spinner with scale pulse effect.
///
/// Key features:
/// - keyframeAnimator() for multi-track animation
/// - Continuous rotation with LinearKeyframe
/// - Pulsing scale with SpringKeyframe
/// - Infinite animation loop
struct LoadingSpinnerExample {
    struct SpinnerValues {
        var rotation = 0.0
        var scale = 1.0
    }

    @State private var isAnimating = true

    var body: some View {
        VStack(spacing: 24) {
            Circle()
                .trim(from: 0, to: 0.7)
                .stroke(Color.blue, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .frame(width: 60, height: 60)
                .keyframeAnimator(
                    initialValue: SpinnerValues(),
                    trigger: isAnimating
                ) { content, value in
                    content
                        .rotationEffect(.degrees(value.rotation))
                        .scaleEffect(value.scale)
                } keyframes: { _ in
                    KeyframeTrack(\.rotation) {
                        LinearKeyframe(360, duration: 1.0)
                    }
                    KeyframeTrack(\.scale) {
                        SpringKeyframe(1.2, duration: 0.5, spring: .bouncy)
                        SpringKeyframe(1.0, duration: 0.5, spring: .bouncy)
                    }
                }

            Text("Loading...")
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

// MARK: - Example 4: Animated Counter/Progress Bar

/// Demonstrates animated number counter with progress bar.
///
/// Key features:
/// - Smooth number transitions
/// - Width-based progress animation
/// - EaseInOut timing for smooth acceleration/deceleration
/// - Color gradient based on progress
struct AnimatedProgressExample {
    @State private var progress: Double = 0.0

    var progressColor: Color {
        if progress < 0.33 { return .red }
        if progress < 0.66 { return .orange }
        return .green
    }

    var body: some View {
        VStack(spacing: 24) {
            // Counter
            Text("\(Int(progress * 100))%")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(progressColor)

            // Progress bar
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 20)
                    .cornerRadius(10)

                Rectangle()
                    .fill(progressColor)
                    .frame(width: progress * 300, height: 20)
                    .cornerRadius(10)
                    .animation(.easeInOut(duration: 0.5), value: progress)
            }
            .frame(width: 300)

            // Controls
            HStack(spacing: 16) {
                Button("25%") {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        progress = 0.25
                    }
                }

                Button("50%") {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        progress = 0.5
                    }
                }

                Button("75%") {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        progress = 0.75
                    }
                }

                Button("100%") {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        progress = 1.0
                    }
                }
            }
        }
        .padding()
    }
}

// MARK: - Example 5: Page Transition Demo

/// Demonstrates page navigation with slide transitions.
///
/// Key features:
/// - Asymmetric transitions for natural page flow
/// - Edge-based sliding (trailing to leading)
/// - State-driven page changes
/// - Smooth easeInOut timing
struct PageTransitionExample {
    @State private var currentPage = 0

    var body: some View {
        VStack(spacing: 24) {
            // Page content
            ZStack {
                if currentPage == 0 {
                    pageView(title: "Welcome", color: .blue, pageNumber: 1)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing),
                            removal: .move(edge: .leading)
                        ))
                } else if currentPage == 1 {
                    pageView(title: "Features", color: .green, pageNumber: 2)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing),
                            removal: .move(edge: .leading)
                        ))
                } else if currentPage == 2 {
                    pageView(title: "Get Started", color: .purple, pageNumber: 3)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing),
                            removal: .move(edge: .leading)
                        ))
                }
            }
            .frame(height: 300)
            .animation(.easeInOut(duration: 0.4), value: currentPage)

            // Navigation
            HStack(spacing: 16) {
                Button("Previous") {
                    if currentPage > 0 {
                        currentPage -= 1
                    }
                }
                .disabled(currentPage == 0)

                Text("Page \(currentPage + 1) of 3")
                    .foregroundColor(.secondary)

                Button("Next") {
                    if currentPage < 2 {
                        currentPage += 1
                    }
                }
                .disabled(currentPage == 2)
            }
        }
        .padding()
    }

    private func pageView(title: String, color: Color, pageNumber: Int) -> some View {
        VStack(spacing: 16) {
            Text(title)
                .font(.system(size: 32, weight: .bold))
            Text("This is page \(pageNumber)")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(color.opacity(0.1))
        .cornerRadius(16)
    }
}

// MARK: - Example 6: Animated Shape Morphing

/// Demonstrates shape transformations with smooth animations.
///
/// Key features:
/// - Corner radius animation
/// - Rotation effect
/// - Scale animation
/// - Combined spring animations
struct ShapeMorphingExample {
    @State private var isCircle = true

    var body: some View {
        VStack(spacing: 32) {
            RoundedRectangle(cornerRadius: isCircle ? 60 : 10)
                .fill(isCircle ? Color.blue : Color.purple)
                .frame(width: 120, height: 120)
                .rotationEffect(.degrees(isCircle ? 0 : 180))
                .scaleEffect(isCircle ? 1.0 : 1.2)
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isCircle)

            Button("Morph") {
                isCircle.toggle()
            }
        }
        .padding()
    }
}

// MARK: - Example 7: Complete Animated UI Flow

/// Demonstrates multi-step UI flow with various animations.
///
/// Key features:
/// - State machine for UI steps
/// - Different transitions for each step
/// - Loading states
/// - Success confirmation
struct AnimatedUIFlowExample {
    enum FlowStep {
        case start
        case loading
        case success
    }

    @State private var currentStep: FlowStep = .start
    @State private var spinnerRotation = 0.0

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                // Start step
                if currentStep == .start {
                    VStack(spacing: 16) {
                        Text("Welcome!")
                            .font(.system(size: 32, weight: .bold))

                        Text("Click below to begin")
                            .foregroundColor(.secondary)

                        Button("Get Started") {
                            withAnimation(.easeOut(duration: 0.3)) {
                                currentStep = .loading
                            }

                            // Simulate loading
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation(.spring()) {
                                    currentStep = .success
                                }
                            }
                        }
                    }
                    .transition(.opacity.combined(with: .scale))
                }

                // Loading step
                if currentStep == .loading {
                    VStack(spacing: 16) {
                        Circle()
                            .trim(from: 0, to: 0.7)
                            .stroke(Color.blue, lineWidth: 4)
                            .frame(width: 50, height: 50)
                            .rotationEffect(.degrees(spinnerRotation))
                            .onAppear {
                                withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                                    spinnerRotation = 360
                                }
                            }

                        Text("Processing...")
                            .foregroundColor(.secondary)
                    }
                    .transition(.opacity)
                }

                // Success step
                if currentStep == .success {
                    VStack(spacing: 16) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 80, height: 80)
                            .overlay(
                                Text("✓")
                                    .font(.system(size: 48))
                                    .foregroundColor(.white)
                            )

                        Text("Success!")
                            .font(.system(size: 28, weight: .semibold))

                        Button("Start Over") {
                            withAnimation {
                                currentStep = .start
                            }
                        }
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(height: 300)
        }
        .padding()
    }
}

// MARK: - Example 8: Interactive Card Stack

/// Demonstrates interactive card stack with drag and swipe animations.
///
/// Key features:
/// - Stacked card layout with offset
/// - Scale effect for depth
/// - Remove cards with slide transition
/// - Spring animation for natural motion
struct CardStackExample {
    struct Card: Identifiable {
        let id = UUID()
        let title: String
        let color: Color
    }

    @State private var cards: [Card] = [
        Card(title: "Card 1", color: .red),
        Card(title: "Card 2", color: .blue),
        Card(title: "Card 3", color: .green),
        Card(title: "Card 4", color: .purple)
    ]

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                    cardView(card: card)
                        .offset(y: Double(index) * 10)
                        .scaleEffect(1.0 - (Double(index) * 0.05))
                        .zIndex(Double(cards.count - index))
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                }
            }
            .frame(height: 250)

            HStack(spacing: 16) {
                Button("Remove Top") {
                    withAnimation(.spring()) {
                        if !cards.isEmpty {
                            cards.removeFirst()
                        }
                    }
                }
                .disabled(cards.isEmpty)

                Button("Add Card") {
                    withAnimation(.spring()) {
                        let newCard = Card(
                            title: "Card \(cards.count + 1)",
                            color: [.red, .blue, .green, .purple, .orange].randomElement()!
                        )
                        cards.append(newCard)
                    }
                }
            }
        }
        .padding()
    }

    private func cardView(card: Card) -> some View {
        VStack {
            Text(card.title)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(width: 200, height: 120)
        .background(card.color)
        .cornerRadius(16)
        .shadow(radius: 5)
    }
}

// MARK: - Example 9: Expandable Card

/// Demonstrates expandable card with animated content reveal.
///
/// Key features:
/// - Frame height animation
/// - Conditional content with transitions
/// - Rotation animation for indicator
/// - Spring animation for natural feel
struct ExpandableCardExample {
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 16) {
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text("Details")
                        .font(.headline)

                    Spacer()

                    Text(isExpanded ? "▲" : "▼")
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
            }

            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Additional Information")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text("This is the expanded content that appears when you tap the button above. It can contain any amount of information.")
                        .foregroundColor(.secondary)

                    HStack {
                        Button("Action 1") { }
                        Button("Action 2") { }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(12)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .frame(maxWidth: 400)
    }
}

// MARK: - Example 10: Animated Tab Bar

/// Demonstrates animated tab bar with selection indicator.
///
/// Key features:
/// - Sliding indicator animation
/// - Color transitions
/// - Scale effect for active tab
/// - Spring animation for bouncy feel
struct AnimatedTabBarExample {
    enum Tab {
        case home, search, profile
    }

    @State private var selectedTab: Tab = .home

    var body: some View {
        VStack(spacing: 32) {
            // Content
            ZStack {
                if selectedTab == .home {
                    contentView(title: "Home", color: .blue)
                        .transition(.opacity.combined(with: .scale))
                } else if selectedTab == .search {
                    contentView(title: "Search", color: .green)
                        .transition(.opacity.combined(with: .scale))
                } else {
                    contentView(title: "Profile", color: .purple)
                        .transition(.opacity.combined(with: .scale))
                }
            }
            .frame(height: 200)
            .animation(.spring(), value: selectedTab)

            // Tab bar
            HStack(spacing: 0) {
                tabButton(tab: .home, icon: "🏠", title: "Home")
                tabButton(tab: .search, icon: "🔍", title: "Search")
                tabButton(tab: .profile, icon: "👤", title: "Profile")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(16)
        }
        .padding()
    }

    private func tabButton(tab: Tab, icon: String, title: String) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = tab
            }
        }) {
            VStack(spacing: 4) {
                Text(icon)
                    .font(.system(size: 24))
                Text(title)
                    .font(.caption)
                    .fontWeight(selectedTab == tab ? .semibold : .regular)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                selectedTab == tab
                    ? Color.blue.opacity(0.2)
                    : Color.clear
            )
            .cornerRadius(12)
            .scaleEffect(selectedTab == tab ? 1.05 : 1.0)
        }
    }

    private func contentView(title: String, color: Color) -> some View {
        VStack {
            Text(title)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(color.opacity(0.1))
        .cornerRadius(16)
    }
}

// MARK: - Usage Examples

/// Example usage of all animation examples.
///
/// These can be rendered individually or combined in a showcase view.
struct Phase12ShowcaseView {
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Text("Phase 12 Animation Examples")
                    .font(.system(size: 32, weight: .bold))
                    .padding(.top)

                AnimatedButtonExample()
                AnimatedListExample()
                LoadingSpinnerExample()
                AnimatedProgressExample()
                PageTransitionExample()
                ShapeMorphingExample()
                AnimatedUIFlowExample()
                CardStackExample()
                ExpandableCardExample()
                AnimatedTabBarExample()
            }
            .padding()
        }
    }
}
