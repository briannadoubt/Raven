import Foundation

/// Per-component performance metrics tracker
///
/// ComponentMetrics tracks render times and call counts for individual components,
/// helping identify performance bottlenecks at the component level.
///
/// Example usage:
/// ```swift
/// let metrics = ComponentMetrics()
///
/// metrics.measure(componentName: "UserProfile") {
///     // Render UserProfile component
///     return profileView.body
/// }
///
/// let topComponents = metrics.getTopComponentsByDuration(limit: 10)
/// for (name, metric) in topComponents {
///     print("\(name): avg \(metric.averageDuration)ms")
/// }
/// ```
@MainActor
public final class ComponentMetrics: Sendable {

    // MARK: - Properties

    /// Per-component timing data
    private var componentData: [String: ComponentTimingData] = [:]

    /// Total number of component measurements
    private var totalMeasurements: Int = 0

    // MARK: - Initialization

    public init() {}

    // MARK: - Public API

    /// Measure a component render operation
    /// - Parameters:
    ///   - componentName: Name of the component being measured
    ///   - operation: The render operation to measure
    /// - Returns: The result of the operation
    @discardableResult
    public func measure<T>(
        componentName: String,
        _ operation: () -> T
    ) -> T {
        let startTime = getCurrentTime()
        let result = operation()
        let endTime = getCurrentTime()
        let duration = endTime - startTime

        recordMeasurement(componentName: componentName, duration: duration)

        return result
    }

    /// Measure an async component render operation
    /// - Parameters:
    ///   - componentName: Name of the component being measured
    ///   - operation: The async render operation to measure
    /// - Returns: The result of the operation
    @discardableResult
    public func measureAsync<T: Sendable>(
        componentName: String,
        _ operation: () async -> T
    ) async -> T {
        let startTime = getCurrentTime()
        let result = await operation()
        let endTime = getCurrentTime()
        let duration = endTime - startTime

        recordMeasurement(componentName: componentName, duration: duration)

        return result
    }

    /// Get metrics for a specific component
    /// - Parameter componentName: Name of the component
    /// - Returns: Component metric if available
    public func getMetric(for componentName: String) -> ComponentMetric? {
        guard let data = componentData[componentName] else { return nil }
        return createMetric(from: data, componentName: componentName)
    }

    /// Get metrics for all components
    /// - Returns: Dictionary mapping component names to their metrics
    public func getAllMetrics() -> [String: ComponentMetric] {
        var metrics: [String: ComponentMetric] = [:]
        for (name, data) in componentData {
            metrics[name] = createMetric(from: data, componentName: name)
        }
        return metrics
    }

    /// Get top N components by total duration
    /// - Parameter limit: Maximum number of components to return
    /// - Returns: Array of tuples with component names and metrics, sorted by total duration
    public func getTopComponentsByDuration(limit: Int = 10) -> [(String, ComponentMetric)] {
        let allMetrics = getAllMetrics()
        return allMetrics
            .map { ($0.key, $0.value) }
            .sorted { $0.1.totalDuration > $1.1.totalDuration }
            .prefix(limit)
            .map { $0 }
    }

    /// Get top N components by call count
    /// - Parameter limit: Maximum number of components to return
    /// - Returns: Array of tuples with component names and metrics, sorted by call count
    public func getTopComponentsByCallCount(limit: Int = 10) -> [(String, ComponentMetric)] {
        let allMetrics = getAllMetrics()
        return allMetrics
            .map { ($0.key, $0.value) }
            .sorted { $0.1.callCount > $1.1.callCount }
            .prefix(limit)
            .map { $0 }
    }

    /// Get components that exceed a duration threshold
    /// - Parameter thresholdMs: Duration threshold in milliseconds
    /// - Returns: Array of tuples with component names and metrics that exceed the threshold
    public func getSlowComponents(thresholdMs: Double = 16.0) -> [(String, ComponentMetric)] {
        let allMetrics = getAllMetrics()
        return allMetrics
            .map { ($0.key, $0.value) }
            .filter { $0.1.averageDuration > thresholdMs }
            .sorted { $0.1.averageDuration > $1.1.averageDuration }
    }

    /// Reset all component metrics
    public func reset() {
        componentData.removeAll()
        totalMeasurements = 0
    }

    /// Remove metrics for a specific component
    /// - Parameter componentName: Name of the component to remove
    public func removeMetric(for componentName: String) {
        if let data = componentData[componentName] {
            totalMeasurements -= data.callCount
            componentData.removeValue(forKey: componentName)
        }
    }

    // MARK: - Statistics

    /// Get overall statistics across all components
    /// - Returns: Overall component statistics
    public func getOverallStatistics() -> ComponentStatistics {
        let allMetrics = getAllMetrics()
        let totalComponents = allMetrics.count

        guard totalComponents > 0 else {
            return ComponentStatistics(
                totalComponents: 0,
                totalMeasurements: 0,
                totalDuration: 0,
                averageDuration: 0,
                slowestComponent: nil,
                fastestComponent: nil,
                mostCalledComponent: nil
            )
        }

        let totalDuration = allMetrics.values.reduce(0) { $0 + $1.totalDuration }
        let averageDuration = totalDuration / Double(totalMeasurements)

        let slowest = allMetrics.max { $0.value.averageDuration < $1.value.averageDuration }
        let fastest = allMetrics.min { $0.value.averageDuration < $1.value.averageDuration }
        let mostCalled = allMetrics.max { $0.value.callCount < $1.value.callCount }

        return ComponentStatistics(
            totalComponents: totalComponents,
            totalMeasurements: totalMeasurements,
            totalDuration: totalDuration,
            averageDuration: averageDuration,
            slowestComponent: slowest.map { ($0.key, $0.value) },
            fastestComponent: fastest.map { ($0.key, $0.value) },
            mostCalledComponent: mostCalled.map { ($0.key, $0.value) }
        )
    }

    // MARK: - Private Methods

    /// Record a measurement for a component
    private func recordMeasurement(componentName: String, duration: Double) {
        if componentData[componentName] == nil {
            componentData[componentName] = ComponentTimingData()
        }

        componentData[componentName]!.recordDuration(duration)
        totalMeasurements += 1
    }

    /// Create a ComponentMetric from timing data
    private func createMetric(from data: ComponentTimingData, componentName: String) -> ComponentMetric {
        ComponentMetric(
            componentName: componentName,
            callCount: data.callCount,
            totalDuration: data.totalDuration,
            averageDuration: data.averageDuration,
            minDuration: data.minDuration,
            maxDuration: data.maxDuration,
            lastDuration: data.lastDuration
        )
    }

    /// Get current high-resolution timestamp (milliseconds)
    private func getCurrentTime() -> Double {
        // Use Date for timestamp (JavaScript Performance API access should be through RenderProfiler)
        return Date().timeIntervalSince1970 * 1000.0
    }
}

// MARK: - Supporting Types

/// Internal timing data for a component
private struct ComponentTimingData {
    var callCount: Int = 0
    var totalDuration: Double = 0
    var minDuration: Double = Double.infinity
    var maxDuration: Double = 0
    var lastDuration: Double = 0

    var averageDuration: Double {
        guard callCount > 0 else { return 0 }
        return totalDuration / Double(callCount)
    }

    mutating func recordDuration(_ duration: Double) {
        callCount += 1
        totalDuration += duration
        minDuration = min(minDuration, duration)
        maxDuration = max(maxDuration, duration)
        lastDuration = duration
    }
}

/// Public metric data for a component
public struct ComponentMetric: Sendable {
    /// Name of the component
    public let componentName: String

    /// Number of times this component was rendered
    public let callCount: Int

    /// Total time spent rendering this component (milliseconds)
    public let totalDuration: Double

    /// Average render time (milliseconds)
    public let averageDuration: Double

    /// Minimum render time (milliseconds)
    public let minDuration: Double

    /// Maximum render time (milliseconds)
    public let maxDuration: Double

    /// Most recent render time (milliseconds)
    public let lastDuration: Double

    /// Whether this component is considered slow (>16ms average)
    public var isSlow: Bool {
        averageDuration > 16.0
    }

    /// Percentage of total render time spent in this component
    /// Note: This requires context from ComponentMetrics to calculate
    public func percentageOfTotal(_ totalDuration: Double) -> Double {
        guard totalDuration > 0 else { return 0 }
        return (self.totalDuration / totalDuration) * 100.0
    }
}

/// Overall statistics across all components
public struct ComponentStatistics: Sendable {
    /// Total number of unique components measured
    public let totalComponents: Int

    /// Total number of measurements across all components
    public let totalMeasurements: Int

    /// Total duration across all components (milliseconds)
    public let totalDuration: Double

    /// Average duration per measurement (milliseconds)
    public let averageDuration: Double

    /// Slowest component by average duration
    public let slowestComponent: (name: String, metric: ComponentMetric)?

    /// Fastest component by average duration
    public let fastestComponent: (name: String, metric: ComponentMetric)?

    /// Most frequently called component
    public let mostCalledComponent: (name: String, metric: ComponentMetric)?
}
