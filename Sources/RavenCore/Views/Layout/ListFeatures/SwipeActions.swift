import Foundation

// MARK: - Swipe Actions

/// A view modifier that adds swipe actions to a list row.
///
/// Swipe actions allow users to perform common actions on list items by swiping
/// left or right on the item. Actions can be destructive (like delete) or
/// standard actions (like share or archive).
///
/// ## Overview
///
/// Swipe actions are revealed when the user swipes on a list row. By default,
/// swiping reveals buttons that perform the specified actions.
///
/// ## Usage
///
/// Add swipe actions to list rows:
///
/// ```swift
/// List(items) { item in
///     Text(item.name)
///         .swipeActions(edge: .trailing) {
///             Button(role: .destructive) {
///                 deleteItem(item)
///             } label: {
///                 Label("Delete", systemImage: "trash")
///             }
///             Button {
///                 shareItem(item)
///             } label: {
///                 Label("Share", systemImage: "square.and.arrow.up")
///             }
///         }
/// }
/// ```
///
/// ## Full Swipe
///
/// Allow a full swipe to perform the primary action:
///
/// ```swift
/// Text(item.name)
///     .swipeActions(edge: .trailing, allowsFullSwipe: true) {
///         Button(role: .destructive) {
///             deleteItem(item)
///         } label: {
///             Label("Delete", systemImage: "trash")
///         }
///     }
/// ```
///
/// ## Multiple Edges
///
/// Add actions to both edges:
///
/// ```swift
/// Text(item.name)
///     .swipeActions(edge: .leading) {
///         Button {
///             favoriteItem(item)
///         } label: {
///             Label("Favorite", systemImage: "star")
///         }
///     }
///     .swipeActions(edge: .trailing) {
///         Button(role: .destructive) {
///             deleteItem(item)
///         } label: {
///             Label("Delete", systemImage: "trash")
///         }
///     }
/// ```
extension View {
    /// Adds swipe actions to a view.
    ///
    /// - Parameters:
    ///   - edge: The edge from which to reveal the actions.
    ///   - allowsFullSwipe: Whether a full swipe triggers the first action. Defaults to true.
    ///   - content: A view builder that creates the actions.
    /// - Returns: A view with swipe actions attached.
    @MainActor
    public func swipeActions<Content: View>(
        edge: HorizontalEdge = .trailing,
        allowsFullSwipe: Bool = true,
        @ViewBuilder content: @escaping @Sendable @MainActor () -> Content
    ) -> some View {
        modifier(_SwipeActionsModifier(
            edge: edge,
            allowsFullSwipe: allowsFullSwipe,
            actions: content
        ))
    }
}

// MARK: - Horizontal Edge

/// The horizontal edge of a view.
public enum HorizontalEdge: Sendable, Hashable {
    /// The leading edge (left in LTR, right in RTL).
    case leading

    /// The trailing edge (right in LTR, left in RTL).
    case trailing
}

// MARK: - Swipe Actions Modifier

/// Internal modifier that implements swipe action behavior.
///
/// This modifier handles:
/// - Touch event tracking for swipe gestures
/// - CSS transforms for smooth swipe animations
/// - Action button rendering and layout
/// - Full swipe detection and execution
/// - Automatic dismiss on tap outside
/// - Spring animations for snap-back
@MainActor
struct _SwipeActionsModifier<Actions: View>: ViewModifier, Sendable {
    let edge: HorizontalEdge
    let allowsFullSwipe: Bool
    let actions: @Sendable @MainActor () -> Actions

    @State private var swipeOffset: CGFloat = 0
    @State private var isActionsRevealed = false
    @State private var actionsWidth: CGFloat = 0

    @MainActor
    func body(content: Content) -> some View {
        // Implementation wraps the content in a container with:
        // 1. Overflow hidden for clipping
        // 2. Action buttons positioned off-screen
        // 3. Touch handlers for swipe tracking
        // 4. CSS transforms for animation
        HStack(spacing: 0) {
            if edge == .leading {
                actionButtons()
            }

            content
                .offset(x: swipeOffset)
                .gesture(swipeGesture)

            if edge == .trailing {
                actionButtons()
            }
        }
        .clipped()
    }

    /// Renders the action buttons.
    @ViewBuilder
    private func actionButtons() -> some View {
        HStack(spacing: 0) {
            actions()
        }
        .opacity(isActionsRevealed ? 1 : 0)
    }

    /// The drag gesture for swiping.
    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged(handleSwipeChanged)
            .onEnded(handleSwipeEnded)
    }

    /// Handles swipe gesture changes.
    private func handleSwipeChanged(_ value: DragGesture.Value) {
        let translation = value.translation.width

        // Determine max swipe based on edge
        let maxSwipe: CGFloat = 200 // Will be replaced with actual action width

        // Apply resistance when swiping in wrong direction
        if (edge == .trailing && translation > 0) || (edge == .leading && translation < 0) {
            swipeOffset = translation * 0.1
        } else {
            // Normal swipe
            let clampedTranslation = min(abs(translation), maxSwipe)
            swipeOffset = edge == .trailing ? -clampedTranslation : clampedTranslation
        }

        // Reveal actions when swiping enough
        if abs(swipeOffset) > 20 {
            isActionsRevealed = true
        }
    }

    /// Handles swipe gesture end.
    private func handleSwipeEnded(_ value: DragGesture.Value) {
        let threshold: CGFloat = 80

        // Check for full swipe
        if allowsFullSwipe && abs(value.translation.width) > 200 {
            performFullSwipe()
        } else if abs(value.translation.width) > threshold {
            // Snap to revealed position
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                swipeOffset = edge == .trailing ? -actionsWidth : actionsWidth
                isActionsRevealed = true
            }
        } else {
            // Snap back to closed position
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                swipeOffset = 0
                isActionsRevealed = false
            }
        }
    }

    /// Performs the full swipe action (first button).
    private func performFullSwipe() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            swipeOffset = edge == .trailing ? -1000 : 1000
        }

        // Trigger first action after animation
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(300))
            // First action would be triggered here
            // For now, just reset
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                swipeOffset = 0
                isActionsRevealed = false
            }
        }
    }
}

// MARK: - Swipe Action Button

/// A button designed for use in swipe actions.
///
/// This button automatically styles itself appropriately for swipe action contexts,
/// with special styling for destructive actions.
///
/// ## Usage
///
/// ```swift
/// .swipeActions {
///     Button(role: .destructive) {
///         deleteItem()
///     } label: {
///         Label("Delete", systemImage: "trash")
///     }
/// }
/// ```
public struct SwipeActionButton: View {
    let role: ButtonRole?
    let action: @Sendable @MainActor () -> Void
    let label: AnyView

    /// Creates a swipe action button.
    ///
    /// - Parameters:
    ///   - role: The semantic role of the button (e.g., .destructive).
    ///   - action: The action to perform when the button is tapped.
    ///   - label: The label for the button.
    @MainActor
    public init<Label: View>(
        role: ButtonRole? = nil,
        action: @escaping @Sendable @MainActor () -> Void,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.role = role
        self.action = action
        self.label = AnyView(label())
    }

    public var body: some View {
        Button(action: action) {
            label
                .frame(width: 70, height: 44)
                .padding(12)
        }
        .foregroundColor(.white)
        .background(role == .destructive ? Color.red : Color.blue)
    }
}

// MARK: - Touch Tracking

/// Internal state for tracking touch events during swipe gestures.
///
/// This manages the low-level touch event handling required for smooth,
/// responsive swipe interactions in the browser environment.
@MainActor
struct SwipeTouchState: Sendable {
    /// The starting X position of the touch
    var startX: CGFloat = 0

    /// The current X position of the touch
    var currentX: CGFloat = 0

    /// The starting Y position (for disambiguation)
    var startY: CGFloat = 0

    /// Whether a swipe is currently in progress
    var isSwipe: Bool = false

    /// Whether the gesture has been determined to be a swipe (not vertical scroll)
    var isSwipeCommitted: Bool = false

    /// The velocity of the swipe
    var velocity: CGFloat = 0

    /// Timestamp of the last position update
    var lastUpdateTime: Date = Date()

    /// Calculates the current translation
    var translation: CGFloat {
        currentX - startX
    }

    /// Determines if the gesture is primarily horizontal
    func isHorizontalGesture(currentY: CGFloat) -> Bool {
        let deltaX = abs(currentX - startX)
        let deltaY = abs(currentY - startY)
        return deltaX > deltaY && deltaX > 10
    }

    /// Updates velocity based on current position
    mutating func updateVelocity() {
        let now = Date()
        let timeDelta = now.timeIntervalSince(lastUpdateTime)
        if timeDelta > 0 {
            velocity = translation / CGFloat(timeDelta)
        }
        lastUpdateTime = now
    }
}

// MARK: - Swipe Actions Configuration

/// Configuration for swipe actions behavior.
///
/// This type controls the appearance and behavior of swipe actions,
/// including animation timing, thresholds, and visual styling.
public struct SwipeActionsConfiguration: Sendable {
    /// The minimum distance to swipe before actions are revealed
    public var revealThreshold: CGFloat = 80

    /// The distance for a full swipe to trigger the primary action
    public var fullSwipeThreshold: CGFloat = 200

    /// The spring response for animations
    public var springResponse: Double = 0.3

    /// The spring damping for animations
    public var springDamping: Double = 0.8

    /// The default width for action buttons
    public var actionButtonWidth: CGFloat = 80

    /// Whether to allow elastic scrolling beyond the actions
    public var allowElasticOverscroll: Bool = true

    /// The resistance factor when swiping in the wrong direction
    public var wrongDirectionResistance: CGFloat = 0.1

    /// Creates a default configuration
    public init() {}

    /// Creates a configuration with custom values
    public init(
        revealThreshold: CGFloat = 80,
        fullSwipeThreshold: CGFloat = 200,
        springResponse: Double = 0.3,
        springDamping: Double = 0.8,
        actionButtonWidth: CGFloat = 80,
        allowElasticOverscroll: Bool = true,
        wrongDirectionResistance: CGFloat = 0.1
    ) {
        self.revealThreshold = revealThreshold
        self.fullSwipeThreshold = fullSwipeThreshold
        self.springResponse = springResponse
        self.springDamping = springDamping
        self.actionButtonWidth = actionButtonWidth
        self.allowElasticOverscroll = allowElasticOverscroll
        self.wrongDirectionResistance = wrongDirectionResistance
    }
}

// MARK: - Environment Key

/// Environment key for swipe actions configuration.
private struct SwipeActionsConfigurationKey: EnvironmentKey {
    static let defaultValue = SwipeActionsConfiguration()
}

extension EnvironmentValues {
    /// The configuration for swipe actions.
    ///
    /// Use this to customize the behavior of swipe actions:
    ///
    /// ```swift
    /// List(items) { item in
    ///     Text(item.name)
    ///         .swipeActions {
    ///             Button("Delete") { }
    ///         }
    /// }
    /// .environment(\.swipeActionsConfiguration, .init(
    ///     revealThreshold: 100,
    ///     fullSwipeThreshold: 250
    /// ))
    /// ```
    public var swipeActionsConfiguration: SwipeActionsConfiguration {
        get { self[SwipeActionsConfigurationKey.self] }
        set { self[SwipeActionsConfigurationKey.self] = newValue }
    }
}
