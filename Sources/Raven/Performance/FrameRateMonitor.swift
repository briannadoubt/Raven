import Foundation

/// Frame rate monitor for tracking FPS and dropped frames
///
/// FrameRateMonitor tracks rendering performance by measuring frame times
/// and detecting dropped frames (frames that exceed the target 16.67ms budget).
///
/// Example usage:
/// ```swift
/// let monitor = FrameRateMonitor()
/// monitor.start()
///
/// // ... render frames ...
/// monitor.recordFrame(duration: 12.5)
/// monitor.recordFrame(duration: 18.3) // Dropped frame!
///
/// let metrics = monitor.getMetrics()
/// print("FPS: \(metrics.averageFPS)")
/// print("Dropped: \(metrics.droppedFrameCount)")
///
/// monitor.stop()
/// ```
@MainActor
public final class FrameRateMonitor: Sendable {

    // MARK: - Constants

    /// Target frame duration for 60 FPS (16.67ms)
    private let targetFrameDuration: Double = 1000.0 / 60.0

    /// Number of frames to keep in history for rolling average
    private let frameHistorySize: Int = 120 // 2 seconds at 60 FPS

    // MARK: - Properties

    /// Whether monitoring is currently active
    private var isMonitoring: Bool = false

    /// Current frames per second
    private var currentFPS: Double = 0.0

    /// Frame duration history (milliseconds)
    private var frameDurations: [Double] = []

    /// Total number of frames recorded
    private var totalFrames: Int = 0

    /// Number of dropped frames
    private var droppedFrames: Int = 0

    /// Timestamp of last frame
    private var lastFrameTime: Date?

    /// Start time of monitoring session
    private var monitoringStartTime: Date?

    // MARK: - Initialization

    public init() {}

    // MARK: - Public API

    /// Start frame rate monitoring
    public func start() {
        guard !isMonitoring else { return }
        isMonitoring = true
        monitoringStartTime = Date()
        lastFrameTime = Date()

        print("🎬 FrameRateMonitor: Started monitoring")
    }

    /// Stop frame rate monitoring
    public func stop() {
        guard isMonitoring else { return }
        isMonitoring = false

        print("🎬 FrameRateMonitor: Stopped monitoring")
    }

    /// Record a frame with its render duration
    /// - Parameter duration: Frame render duration in milliseconds
    public func recordFrame(duration: Double) {
        guard isMonitoring else { return }

        totalFrames += 1
        frameDurations.append(duration)

        // Check if frame was dropped (exceeded target duration)
        if duration > targetFrameDuration {
            droppedFrames += 1
        }

        // Trim history if needed
        if frameDurations.count > frameHistorySize {
            frameDurations.removeFirst(frameDurations.count - frameHistorySize)
        }

        // Update FPS calculation
        updateFPS()
        lastFrameTime = Date()
    }

    /// Record a dropped frame (when frame budget was exceeded)
    public func recordDroppedFrame() {
        guard isMonitoring else { return }
        droppedFrames += 1
    }

    /// Get current frame rate metrics
    /// - Returns: Frame rate metrics
    public func getMetrics() -> FrameRateMetrics {
        let sessionDuration = monitoringStartTime.map { Date().timeIntervalSince($0) } ?? 0

        return FrameRateMetrics(
            currentFPS: currentFPS,
            averageFPS: calculateAverageFPS(),
            minFPS: calculateMinFPS(),
            maxFPS: calculateMaxFPS(),
            droppedFrameCount: droppedFrames,
            totalFrameCount: totalFrames,
            droppedFramePercentage: calculateDroppedFramePercentage(),
            averageFrameDuration: calculateAverageFrameDuration(),
            sessionDuration: sessionDuration
        )
    }

    /// Reset all frame rate statistics
    public func reset() {
        stop()
        currentFPS = 0.0
        frameDurations.removeAll()
        totalFrames = 0
        droppedFrames = 0
        lastFrameTime = nil
        monitoringStartTime = nil
    }

    /// Check if current frame rate is acceptable (>= 55 FPS)
    /// - Returns: True if frame rate is acceptable
    public func isFrameRateAcceptable() -> Bool {
        return currentFPS >= 55.0
    }

    /// Check if there are performance issues (dropped frame percentage > 5%)
    /// - Returns: True if there are performance issues
    public func hasPerformanceIssues() -> Bool {
        return calculateDroppedFramePercentage() > 5.0
    }

    /// Get performance rating (0.0 to 1.0)
    /// - Returns: Performance rating based on FPS and dropped frames
    public func getPerformanceRating() -> Double {
        guard totalFrames > 0 else { return 1.0 }

        let fpsRating = min(currentFPS / 60.0, 1.0)
        let droppedFrameRating = 1.0 - (calculateDroppedFramePercentage() / 100.0)

        // Weight FPS more heavily (70%) than dropped frames (30%)
        return (fpsRating * 0.7) + (droppedFrameRating * 0.3)
    }

    /// Get frame time percentiles
    /// - Returns: Frame time percentiles (p50, p95, p99)
    public func getFrameTimePercentiles() -> FrameTimePercentiles {
        guard !frameDurations.isEmpty else {
            return FrameTimePercentiles(p50: 0, p95: 0, p99: 0)
        }

        let sorted = frameDurations.sorted()
        return FrameTimePercentiles(
            p50: percentile(sorted, 0.5),
            p95: percentile(sorted, 0.95),
            p99: percentile(sorted, 0.99)
        )
    }

    // MARK: - Private Methods

    /// Update current FPS calculation based on recent frame durations
    private func updateFPS() {
        guard !frameDurations.isEmpty else {
            currentFPS = 0.0
            return
        }

        // Calculate FPS from rolling average of frame durations
        let recentFrames = frameDurations.suffix(min(60, frameDurations.count))
        let avgDuration = recentFrames.reduce(0, +) / Double(recentFrames.count)

        if avgDuration > 0 {
            currentFPS = 1000.0 / avgDuration
        } else {
            currentFPS = 60.0 // Assume 60 FPS if duration is negligible
        }
    }

    /// Calculate average FPS across all recorded frames
    private func calculateAverageFPS() -> Double {
        guard !frameDurations.isEmpty else { return 0.0 }

        let avgDuration = frameDurations.reduce(0, +) / Double(frameDurations.count)
        return avgDuration > 0 ? 1000.0 / avgDuration : 60.0
    }

    /// Calculate minimum FPS (from maximum frame duration)
    private func calculateMinFPS() -> Double {
        guard let maxDuration = frameDurations.max(), maxDuration > 0 else {
            return 0.0
        }
        return 1000.0 / maxDuration
    }

    /// Calculate maximum FPS (from minimum frame duration)
    private func calculateMaxFPS() -> Double {
        guard let minDuration = frameDurations.min(), minDuration > 0 else {
            return 60.0
        }
        return 1000.0 / minDuration
    }

    /// Calculate percentage of dropped frames
    private func calculateDroppedFramePercentage() -> Double {
        guard totalFrames > 0 else { return 0.0 }
        return (Double(droppedFrames) / Double(totalFrames)) * 100.0
    }

    /// Calculate average frame duration
    private func calculateAverageFrameDuration() -> Double {
        guard !frameDurations.isEmpty else { return 0.0 }
        return frameDurations.reduce(0, +) / Double(frameDurations.count)
    }

    /// Calculate percentile from sorted array
    private func percentile(_ sortedValues: [Double], _ p: Double) -> Double {
        guard !sortedValues.isEmpty else { return 0 }
        let index = Int(Double(sortedValues.count - 1) * p)
        return sortedValues[index]
    }
}

// MARK: - Supporting Types

/// Frame rate metrics summary
public struct FrameRateMetrics: Sendable {
    /// Current frames per second
    public let currentFPS: Double

    /// Average FPS across session
    public let averageFPS: Double

    /// Minimum FPS recorded
    public let minFPS: Double

    /// Maximum FPS recorded
    public let maxFPS: Double

    /// Number of dropped frames
    public let droppedFrameCount: Int

    /// Total number of frames
    public let totalFrameCount: Int

    /// Percentage of dropped frames
    public let droppedFramePercentage: Double

    /// Average frame duration in milliseconds
    public let averageFrameDuration: Double

    /// Total session duration in seconds
    public let sessionDuration: TimeInterval

    /// Whether frame rate is acceptable (>= 55 FPS)
    public var isAcceptable: Bool {
        averageFPS >= 55.0
    }

    /// Whether there are performance issues
    public var hasIssues: Bool {
        droppedFramePercentage > 5.0
    }

    /// Performance grade (A, B, C, D, F)
    public var performanceGrade: String {
        if averageFPS >= 58 && droppedFramePercentage < 2 {
            return "A"
        } else if averageFPS >= 50 && droppedFramePercentage < 5 {
            return "B"
        } else if averageFPS >= 40 && droppedFramePercentage < 10 {
            return "C"
        } else if averageFPS >= 30 {
            return "D"
        } else {
            return "F"
        }
    }
}

/// Frame time percentiles
public struct FrameTimePercentiles: Sendable {
    /// 50th percentile (median) frame time in milliseconds
    public let p50: Double

    /// 95th percentile frame time in milliseconds
    public let p95: Double

    /// 99th percentile frame time in milliseconds
    public let p99: Double

    /// Whether p95 frame time is within budget (< 16.67ms)
    public var p95WithinBudget: Bool {
        p95 <= 16.67
    }

    /// Whether p99 frame time is within budget (< 16.67ms)
    public var p99WithinBudget: Bool {
        p99 <= 16.67
    }
}
