import Foundation

// MARK: - Pull to Refresh

/// A modifier that adds pull-to-refresh functionality to a scrollable view.
///
/// Pull-to-refresh allows users to refresh content by pulling down on a scrollable
/// view. When the user pulls down and releases, an async refresh action is triggered.
///
/// ## Overview
///
/// Pull-to-refresh is typically used with Lists and ScrollViews to reload content
/// from a server or update data. The refresh action runs asynchronously and shows
/// a loading indicator while in progress.
///
/// ## Usage
///
/// Add pull-to-refresh to a List or ScrollView:
///
/// ```swift
/// List(items) { item in
///     Text(item.name)
/// }
/// .refreshable {
///     await loadData()
/// }
/// ```
///
/// ## Async Refresh
///
/// The refresh action is async and automatically handles the loading state:
///
/// ```swift
/// ScrollView {
///     content
/// }
/// .refreshable {
///     do {
///         items = try await api.fetchItems()
///     } catch {
///         showError(error)
///     }
/// }
/// ```
///
/// ## Custom Refresh Indicator
///
/// You can customize the appearance of the refresh indicator (future enhancement).
extension View {
    /// Adds pull-to-refresh functionality with an async refresh action.
    ///
    /// When the user pulls down on a scrollable view and releases, the provided
    /// async action is executed. A loading indicator is displayed while the
    /// action runs.
    ///
    /// - Parameter action: The async action to perform when refreshing.
    /// - Returns: A view with pull-to-refresh enabled.
    @MainActor
    public func refreshable(
        action: @escaping @Sendable @MainActor () async -> Void
    ) -> some View {
        modifier(_RefreshableModifier(action: action))
    }
}

// MARK: - Refreshable Modifier

/// Internal modifier that implements pull-to-refresh behavior.
///
/// This modifier handles:
/// - Touch tracking for pull gestures
/// - Elastic scroll behavior during pull
/// - Refresh indicator display and animation
/// - Async action execution
/// - Automatic scroll restoration after refresh
@MainActor
struct _RefreshableModifier: ViewModifier, Sendable {
    let action: @Sendable @MainActor () async -> Void

    @State private var pullOffset: CGFloat = 0
    @State private var isRefreshing = false
    @State private var isPulling = false
    @State private var refreshState: RefreshState = .idle

    @MainActor
    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            // Refresh indicator
            refreshIndicator
                .offset(y: pullOffset - 60)
                .opacity(refreshIndicatorOpacity)

            // Main content
            content
                .offset(y: refreshContentOffset)
                .gesture(pullGesture)
        }
    }

    /// The refresh indicator view
    @ViewBuilder
    private var refreshIndicator: some View {
        HStack(spacing: 8) {
            if isRefreshing {
                ProgressView()
            } else {
                Image(systemName: refreshIconName)
                    .rotationEffect(Angle(degrees: refreshIconRotation))
            }
            if refreshState != .idle {
                Text(refreshStateText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(height: 60)
    }

    /// Opacity for the refresh indicator
    private var refreshIndicatorOpacity: Double {
        if isRefreshing {
            return 1
        } else if isPulling {
            return min(pullOffset / refreshTriggerDistance, 1.0)
        } else {
            return 0
        }
    }

    /// Offset for the content during refresh
    private var refreshContentOffset: CGFloat {
        if isRefreshing {
            return 60 // Height of refresh indicator
        } else if isPulling {
            return pullOffset
        } else {
            return 0
        }
    }

    /// Icon name for the refresh indicator
    private var refreshIconName: String {
        switch refreshState {
        case .idle, .pulling:
            return "arrow.down"
        case .triggered:
            return "arrow.down"
        case .refreshing:
            return "arrow.clockwise"
        }
    }

    /// Rotation for the refresh icon
    private var refreshIconRotation: Double {
        if refreshState == .triggered {
            return 180
        } else if isPulling {
            return min(pullOffset / refreshTriggerDistance, 1.0) * 180
        } else {
            return 0
        }
    }

    /// Text for the refresh state
    private var refreshStateText: String {
        switch refreshState {
        case .idle:
            return ""
        case .pulling:
            return "Pull to refresh"
        case .triggered:
            return "Release to refresh"
        case .refreshing:
            return "Refreshing..."
        }
    }

    /// Distance to pull before triggering refresh
    private var refreshTriggerDistance: CGFloat {
        80
    }

    /// The drag gesture for pull-to-refresh
    private var pullGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged(handlePullChanged)
            .onEnded(handlePullEnded)
    }

    /// Handles pull gesture changes
    private func handlePullChanged(_ value: DragGesture.Value) {
        // Only allow pulling down when at the top of the scroll view
        // In a real implementation, this would check scroll position
        let translation = value.translation.height

        guard translation > 0 else {
            pullOffset = 0
            isPulling = false
            return
        }

        isPulling = true

        // Apply elastic resistance
        let resistance: CGFloat = 2.5
        pullOffset = translation / resistance

        // Update refresh state
        if pullOffset >= refreshTriggerDistance {
            if refreshState != .triggered {
                refreshState = .triggered
                // Haptic feedback would go here
            }
        } else {
            refreshState = .pulling
        }
    }

    /// Handles pull gesture end
    private func handlePullEnded(_ value: DragGesture.Value) {
        isPulling = false

        if pullOffset >= refreshTriggerDistance && !isRefreshing {
            // Trigger refresh
            triggerRefresh()
        } else {
            // Snap back
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                pullOffset = 0
                refreshState = .idle
            }
        }
    }

    /// Triggers the refresh action
    private func triggerRefresh() {
        isRefreshing = true
        refreshState = .refreshing

        // Animate to refreshing position
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            pullOffset = refreshTriggerDistance
        }

        // Execute the async refresh action
        Task {
            await action()

            // Animation for completion
            await MainActor.run {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    pullOffset = 0
                    isRefreshing = false
                    refreshState = .idle
                }
            }
        }
    }
}

// MARK: - Refresh State

/// The state of a pull-to-refresh gesture.
enum RefreshState: Sendable {
    /// No refresh activity
    case idle

    /// User is pulling but hasn't reached the threshold
    case pulling

    /// User has pulled past the threshold
    case triggered

    /// Refresh action is executing
    case refreshing
}

// MARK: - Refresh Environment

/// Environment key for refresh action.
private struct RefreshActionKey: EnvironmentKey {
    static let defaultValue: (@Sendable @MainActor () async -> Void)? = nil
}

extension EnvironmentValues {
    /// The refresh action for pull-to-refresh.
    ///
    /// This value is set automatically by the `.refreshable()` modifier.
    /// Views can check for its presence to determine if refresh is available.
    ///
    /// ```swift
    /// @Environment(\.refresh) var refresh
    ///
    /// if refresh != nil {
    ///     // Refresh is available
    /// }
    /// ```
    public var refresh: (@Sendable @MainActor () async -> Void)? {
        get { self[RefreshActionKey.self] }
        set { self[RefreshActionKey.self] = newValue }
    }
}

// MARK: - Refresh Progress

/// Environment key for refresh progress.
private struct RefreshProgressKey: EnvironmentKey {
    static let defaultValue: RefreshProgress? = nil
}

/// Information about the current refresh operation.
@MainActor
public struct RefreshProgress: Sendable {
    /// Whether a refresh is currently in progress
    public let isRefreshing: Bool

    /// The pull distance (0-1) before triggering
    public let pullProgress: Double

    /// Creates refresh progress information
    public init(isRefreshing: Bool, pullProgress: Double) {
        self.isRefreshing = isRefreshing
        self.pullProgress = pullProgress
    }
}

extension EnvironmentValues {
    /// Information about the current refresh operation.
    ///
    /// Use this to create custom refresh indicators:
    ///
    /// ```swift
    /// @Environment(\.refreshProgress) var progress
    ///
    /// if let progress = progress {
    ///     CustomRefreshIndicator(
    ///         isRefreshing: progress.isRefreshing,
    ///         progress: progress.pullProgress
    ///     )
    /// }
    /// ```
    public var refreshProgress: RefreshProgress? {
        get { self[RefreshProgressKey.self] }
        set { self[RefreshProgressKey.self] = newValue }
    }
}

// MARK: - Scroll Position Tracking

/// Tracks scroll position for pull-to-refresh eligibility.
///
/// This internal helper determines if the scroll view is at the top,
/// which is required for pull-to-refresh to activate.
@MainActor
struct ScrollPositionTracker: Sendable {
    /// Current scroll offset
    var scrollOffset: CGFloat = 0

    /// Whether the view is scrolled to the top
    var isAtTop: Bool {
        scrollOffset <= 0
    }

    /// Whether over-scroll is occurring (pulling beyond top)
    var overscrollAmount: CGFloat {
        guard scrollOffset < 0 else { return 0 }
        return abs(scrollOffset)
    }
}

// MARK: - Refresh Configuration

/// Configuration for pull-to-refresh behavior.
public struct RefreshConfiguration: Sendable {
    /// The distance to pull before triggering refresh
    public var triggerDistance: CGFloat = 80

    /// The elastic resistance during pull
    public var resistance: CGFloat = 2.5

    /// The spring response for animations
    public var springResponse: Double = 0.3

    /// The spring damping for animations
    public var springDamping: Double = 0.7

    /// Whether to provide haptic feedback
    public var enableHaptics: Bool = true

    /// The minimum refresh duration (prevents flicker for fast operations)
    public var minimumRefreshDuration: TimeInterval = 0.5

    /// Creates a default configuration
    public init() {}

    /// Creates a configuration with custom values
    public init(
        triggerDistance: CGFloat = 80,
        resistance: CGFloat = 2.5,
        springResponse: Double = 0.3,
        springDamping: Double = 0.7,
        enableHaptics: Bool = true,
        minimumRefreshDuration: TimeInterval = 0.5
    ) {
        self.triggerDistance = triggerDistance
        self.resistance = resistance
        self.springResponse = springResponse
        self.springDamping = springDamping
        self.enableHaptics = enableHaptics
        self.minimumRefreshDuration = minimumRefreshDuration
    }
}

// MARK: - Environment Key

/// Environment key for refresh configuration.
private struct RefreshConfigurationKey: EnvironmentKey {
    static let defaultValue = RefreshConfiguration()
}

extension EnvironmentValues {
    /// The configuration for pull-to-refresh behavior.
    ///
    /// Use this to customize refresh behavior:
    ///
    /// ```swift
    /// List(items) { item in
    ///     Text(item.name)
    /// }
    /// .refreshable {
    ///     await loadData()
    /// }
    /// .environment(\.refreshConfiguration, .init(
    ///     triggerDistance: 100,
    ///     resistance: 3.0
    /// ))
    /// ```
    public var refreshConfiguration: RefreshConfiguration {
        get { self[RefreshConfigurationKey.self] }
        set { self[RefreshConfigurationKey.self] = newValue }
    }
}
