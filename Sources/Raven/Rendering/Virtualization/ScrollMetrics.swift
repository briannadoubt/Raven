import Foundation

/// Tracks scroll position, velocity, and related metrics for virtual scrolling.
///
/// `ScrollMetrics` provides real-time scroll information needed for virtual scrolling
/// calculations, including position tracking, velocity estimation, and scroll direction.
/// All operations are isolated to the MainActor for safe DOM interaction.
///
/// Example:
/// ```swift
/// let metrics = ScrollMetrics()
/// metrics.update(scrollTop: 500, timestamp: Date())
/// print(metrics.velocity) // Pixels per second
/// print(metrics.scrollingUp) // Boolean
/// ```
@MainActor
public final class ScrollMetrics: Sendable {

    // MARK: - Properties

    /// Current scroll position in pixels from the top
    public private(set) var scrollTop: Double = 0

    /// Current scroll position in pixels from the left
    public private(set) var scrollLeft: Double = 0

    /// Estimated scroll velocity in pixels per second
    public private(set) var velocity: Double = 0

    /// Whether the user is currently scrolling upward
    public var scrollingUp: Bool {
        velocity < 0
    }

    /// Whether the user is currently scrolling downward
    public var scrollingDown: Bool {
        velocity > 0
    }

    /// Whether the scroll is currently stationary (no velocity)
    public var isStationary: Bool {
        abs(velocity) < 1.0
    }

    /// Total height of the scrollable content
    public private(set) var scrollHeight: Double = 0

    /// Height of the visible viewport
    public private(set) var clientHeight: Double = 0

    /// Total width of the scrollable content
    public private(set) var scrollWidth: Double = 0

    /// Width of the visible viewport
    public private(set) var clientWidth: Double = 0

    /// Whether scrolled to the top (with threshold)
    public var isAtTop: Bool {
        scrollTop < 5.0
    }

    /// Whether scrolled to the bottom (with threshold)
    public var isAtBottom: Bool {
        scrollTop + clientHeight >= scrollHeight - 5.0
    }

    // MARK: - Private State

    /// History of recent scroll positions for velocity calculation
    private var scrollHistory: [(position: Double, timestamp: TimeInterval)] = []

    /// Maximum number of history entries to maintain
    private let maxHistorySize = 5

    /// Time window (in seconds) for velocity calculation
    private let velocityWindow: TimeInterval = 0.1

    /// Timestamp of last update
    private var lastUpdateTime: TimeInterval = 0

    /// Threshold for considering velocity as zero (pixels per second)
    private let velocityThreshold: Double = 10.0

    // MARK: - Initialization

    public init() {}

    // MARK: - Public Methods

    /// Update scroll position and recalculate metrics.
    ///
    /// Call this method whenever a scroll event occurs. It automatically
    /// calculates velocity based on position changes over time.
    ///
    /// - Parameters:
    ///   - scrollTop: New vertical scroll position in pixels
    ///   - timestamp: Current timestamp (defaults to now)
    public func update(scrollTop: Double, timestamp: Date = Date()) {
        let timeInterval = timestamp.timeIntervalSince1970

        // Update scroll position
        self.scrollTop = scrollTop

        // Add to history
        scrollHistory.append((position: scrollTop, timestamp: timeInterval))

        // Trim history to max size
        if scrollHistory.count > maxHistorySize {
            scrollHistory.removeFirst()
        }

        // Calculate velocity
        calculateVelocity(currentTime: timeInterval)

        lastUpdateTime = timeInterval
    }

    /// Update horizontal scroll position.
    ///
    /// - Parameters:
    ///   - scrollLeft: New horizontal scroll position in pixels
    public func updateHorizontal(scrollLeft: Double) {
        self.scrollLeft = scrollLeft
    }

    /// Update viewport and content dimensions.
    ///
    /// Call this when the container or content size changes.
    ///
    /// - Parameters:
    ///   - scrollHeight: Total height of scrollable content
    ///   - clientHeight: Height of visible viewport
    ///   - scrollWidth: Total width of scrollable content
    ///   - clientWidth: Width of visible viewport
    public func updateDimensions(
        scrollHeight: Double,
        clientHeight: Double,
        scrollWidth: Double,
        clientWidth: Double
    ) {
        self.scrollHeight = scrollHeight
        self.clientHeight = clientHeight
        self.scrollWidth = scrollWidth
        self.clientWidth = clientWidth
    }

    /// Reset all metrics to initial state.
    ///
    /// Useful when the scrollable content changes completely.
    public func reset() {
        scrollTop = 0
        scrollLeft = 0
        velocity = 0
        scrollHeight = 0
        clientHeight = 0
        scrollWidth = 0
        clientWidth = 0
        scrollHistory.removeAll()
        lastUpdateTime = 0
    }

    /// Get the scroll progress as a percentage (0-100).
    ///
    /// - Returns: Scroll progress from 0 (top) to 100 (bottom)
    public func scrollProgress() -> Double {
        guard scrollHeight > clientHeight else { return 0 }
        let maxScroll = scrollHeight - clientHeight
        guard maxScroll > 0 else { return 0 }
        return (scrollTop / maxScroll) * 100.0
    }

    /// Calculate the estimated time to reach a target scroll position.
    ///
    /// Based on current velocity, estimates how long it would take
    /// to reach the target position. Returns nil if velocity is too low.
    ///
    /// - Parameter target: Target scroll position in pixels
    /// - Returns: Estimated time in seconds, or nil if velocity is near zero
    public func estimatedTimeToReach(_ target: Double) -> TimeInterval? {
        guard abs(velocity) > velocityThreshold else { return nil }
        let distance = target - scrollTop
        let time = abs(distance / velocity)
        return time
    }

    // MARK: - Private Methods

    /// Calculate scroll velocity from recent position history.
    ///
    /// Uses linear regression over the recent history window to estimate
    /// velocity in pixels per second. Applies smoothing and threshold filtering.
    ///
    /// - Parameter currentTime: Current timestamp
    private func calculateVelocity(currentTime: TimeInterval) {
        guard scrollHistory.count >= 2 else {
            velocity = 0
            return
        }

        // Filter history to recent window
        let cutoffTime = currentTime - velocityWindow
        let recentHistory = scrollHistory.filter { $0.timestamp >= cutoffTime }

        guard recentHistory.count >= 2 else {
            velocity = 0
            return
        }

        // Calculate velocity using first and last points in window
        let first = recentHistory.first!
        let last = recentHistory.last!

        let deltaPosition = last.position - first.position
        let deltaTime = last.timestamp - first.timestamp

        guard deltaTime > 0 else {
            velocity = 0
            return
        }

        // Velocity in pixels per second
        let rawVelocity = deltaPosition / deltaTime

        // Apply smoothing (exponential moving average)
        let alpha = 0.3 // Smoothing factor (0 = no change, 1 = instant change)
        velocity = alpha * rawVelocity + (1 - alpha) * velocity

        // Apply threshold to filter out noise
        if abs(velocity) < velocityThreshold {
            velocity = 0
        }
    }
}

