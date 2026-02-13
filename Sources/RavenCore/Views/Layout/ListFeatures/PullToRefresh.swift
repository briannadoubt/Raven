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

/// Internal modifier that injects refresh behavior into the environment.
@MainActor
struct _RefreshableModifier: ViewModifier, Sendable {
    let action: @Sendable @MainActor () async -> Void
    @Environment(\.refreshConfiguration) private var configuration

    @State private var isRefreshing = false

    @MainActor
    func body(content: Content) -> some View {
        content
        .environment(\.refresh, RefreshAction {
            await performRefreshIfNeeded()
        })
        .environment(
            \.refreshProgress,
            RefreshProgress(
                isRefreshing: isRefreshing,
                pullProgress: isRefreshing ? 1 : 0
            )
        )
    }

    /// Triggers the refresh action if one is not already in progress.
    private func performRefreshIfNeeded() async {
        guard !isRefreshing else { return }

        let refreshStart = Date()

        isRefreshing = true

        // Execute the async refresh action
        await action()

        // Keep spinner visible for a minimum duration to avoid visual flicker.
        let elapsed = Date().timeIntervalSince(refreshStart)
        if elapsed < configuration.minimumRefreshDuration {
            let remaining = configuration.minimumRefreshDuration - elapsed
            try? await Task.sleep(nanoseconds: UInt64(remaining * 1_000_000_000))
        }

        isRefreshing = false
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

/// An action that refreshes the current view's data.
///
/// Retrieve this from the environment with `@Environment(\.refresh)` and invoke
/// it with `await refresh?()` to trigger the same logic as `.refreshable`.
@MainActor
public struct RefreshAction: Sendable {
    private let action: @Sendable @MainActor () async -> Void
    private let syncAction: (@Sendable @MainActor () -> Void)?

    public init(_ action: @escaping @Sendable @MainActor () async -> Void) {
        self.action = action
        self.syncAction = nil
    }

    public init(_ action: @escaping @Sendable @MainActor () -> Void) {
        self.action = {
            action()
        }
        self.syncAction = action
    }

    /// Executes refresh from synchronous contexts (for example, button handlers).
    ///
    /// SwiftUI requires `Task { await refresh?() }` from sync handlers. On current
    /// Swift/WASM toolchains, nested `Task {}` from DOM callbacks can be unreliable,
    /// so Raven provides this overload as a compatibility bridge.
    public func callAsFunction() {
        if let syncAction {
            AsyncHostBridge.run(syncAction)
            return
        }
        AsyncHostBridge.runAsync(action)
    }

    public func callAsFunction() async {
        await action()
    }
}

/// Environment key for refresh action.
private struct RefreshActionKey: EnvironmentKey {
    static let defaultValue: RefreshAction? = nil
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
    public var refresh: RefreshAction? {
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
