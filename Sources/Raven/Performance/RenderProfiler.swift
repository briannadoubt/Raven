import Foundation
import JavaScriptKit

/// Main actor-isolated performance profiler for tracking rendering operations
///
/// RenderProfiler provides comprehensive performance monitoring for the Raven
/// rendering pipeline, including VNode diffing, DOM patching, and frame rate tracking.
///
/// Example usage:
/// ```swift
/// let profiler = RenderProfiler.shared
/// profiler.startProfiling()
///
/// profiler.measureDiffing {
///     let patches = differ.diff(old: oldTree, new: newTree)
/// }
///
/// profiler.measurePatching {
///     await applyPatches(patches)
/// }
///
/// let report = profiler.generateReport()
/// print(report.summary)
/// ```
@MainActor
public final class RenderProfiler: Sendable {

    // MARK: - Singleton

    /// Shared profiler instance
    public static let shared = RenderProfiler()

    // MARK: - Public Properties

    /// Whether profiling is currently active
    public private(set) var isActive: Bool = false

    /// Current frame rate (FPS)
    public private(set) var currentFPS: Double = 0.0

    /// Current memory usage in bytes
    public private(set) var memoryUsage: Int64 = 0

    /// Total number of VNodes in current tree
    public private(set) var vnodeCount: Int = 0

    /// Total number of DOM nodes
    public private(set) var domNodeCount: Int = 0

    // MARK: - Private Properties

    /// Component-level metrics tracker
    private let componentMetrics: ComponentMetrics

    /// Memory monitor for tracking memory usage
    private let memoryMonitor: MemoryMonitor

    /// Frame rate monitor for FPS tracking
    private let frameRateMonitor: FrameRateMonitor

    /// Historical data for diffing operations
    private var diffingHistory: [TimingMeasurement] = []

    /// Historical data for patching operations
    private var patchingHistory: [TimingMeasurement] = []

    /// Historical data for render operations
    private var renderHistory: [TimingMeasurement] = []

    /// Current profiling session
    private var currentSession: ProfilingSession?

    /// Maximum history entries to keep
    private let maxHistorySize: Int = 1000

    /// Reference to JavaScript Performance API
    private let jsPerformance: JSObject?

    // MARK: - Initialization

    private init() {
        self.componentMetrics = ComponentMetrics()
        self.memoryMonitor = MemoryMonitor()
        self.frameRateMonitor = FrameRateMonitor()

        // Get JavaScript Performance API reference
        #if arch(wasm32)
        self.jsPerformance = JSObject.global.performance.isUndefined ? nil : JSObject.global.performance.object
        #else
        self.jsPerformance = nil
        #endif

        // Set up DevTools integration
        setupDevToolsIntegration()
    }

    // MARK: - Public API - Session Management

    /// Start a new profiling session
    /// - Parameter label: Optional label for the session
    public func startProfiling(label: String? = nil) {
        guard !isActive else {
            print("Warning: Profiling session already active")
            return
        }

        isActive = true
        currentSession = ProfilingSession(label: label)

        // Start monitoring subsystems
        frameRateMonitor.start()
        memoryMonitor.start()

        // Mark the start in JavaScript Performance API
        if let perf = jsPerformance {
            let markName = "raven-profiling-start-\(currentSession!.id.uuidString)"
            _ = perf.mark!(markName)
        }

        print("🔍 Raven Profiler: Started profiling session\(label.map { " '\($0)'" } ?? "")")
    }

    /// Stop the current profiling session
    /// - Returns: Profiling session data if a session was active
    @discardableResult
    public func stopProfiling() -> ProfilingSession? {
        guard isActive, let session = currentSession else {
            print("Warning: No active profiling session to stop")
            return nil
        }

        isActive = false

        // Stop monitoring subsystems
        frameRateMonitor.stop()
        memoryMonitor.stop()

        // Mark the end in JavaScript Performance API
        if let perf = jsPerformance {
            let markName = "raven-profiling-end-\(session.id.uuidString)"
            _ = perf.mark!(markName)
        }

        // Finalize session
        var finalSession = session
        finalSession.finalize()

        print("🔍 Raven Profiler: Stopped profiling session (duration: \(String(format: "%.2f", finalSession.duration))ms)")

        currentSession = nil

        return finalSession
    }

    /// Reset all profiling data
    public func reset() {
        stopProfiling()
        diffingHistory.removeAll()
        patchingHistory.removeAll()
        renderHistory.removeAll()
        componentMetrics.reset()
        memoryMonitor.reset()
        frameRateMonitor.reset()

        print("🔍 Raven Profiler: Reset all profiling data")
    }

    // MARK: - Public API - Measurements

    /// Measure the time taken for VNode diffing
    /// - Parameter operation: The diffing operation to measure
    /// - Returns: The result of the operation
    @discardableResult
    public func measureDiffing<T>(
        label: String = "diff",
        _ operation: () -> T
    ) -> T {
        guard isActive else { return operation() }

        let startTime = getCurrentTime()
        let result = operation()
        let endTime = getCurrentTime()
        let duration = endTime - startTime

        let measurement = TimingMeasurement(
            label: label,
            startTime: startTime,
            endTime: endTime,
            duration: duration
        )

        diffingHistory.append(measurement)
        if var session = currentSession {
            session.recordDiffing(measurement)
            currentSession = session
        }

        trimHistoryIfNeeded(&diffingHistory)

        return result
    }

    /// Measure the time taken for DOM patching
    /// - Parameter operation: The patching operation to measure
    /// - Returns: The result of the operation
    @discardableResult
    public func measurePatching<T: Sendable>(
        label: String = "patch",
        _ operation: () async -> T
    ) async -> T {
        guard isActive else { return await operation() }

        let startTime = getCurrentTime()
        let result = await operation()
        let endTime = getCurrentTime()
        let duration = endTime - startTime

        let measurement = TimingMeasurement(
            label: label,
            startTime: startTime,
            endTime: endTime,
            duration: duration
        )

        patchingHistory.append(measurement)
        if var session = currentSession {
            session.recordPatching(measurement)
            currentSession = session
        }

        trimHistoryIfNeeded(&patchingHistory)

        return result
    }

    /// Measure a complete render cycle (diffing + patching)
    /// - Parameter operation: The render operation to measure
    /// - Returns: The result of the operation
    @discardableResult
    public func measureRender<T: Sendable>(
        label: String = "render",
        _ operation: () async -> T
    ) async -> T {
        guard isActive else { return await operation() }

        let startTime = getCurrentTime()
        let result = await operation()
        let endTime = getCurrentTime()
        let duration = endTime - startTime

        let measurement = TimingMeasurement(
            label: label,
            startTime: startTime,
            endTime: endTime,
            duration: duration
        )

        renderHistory.append(measurement)
        if var session = currentSession {
            session.recordRender(measurement)
            currentSession = session
        }

        trimHistoryIfNeeded(&renderHistory)

        // Update FPS based on render time
        frameRateMonitor.recordFrame(duration: duration)

        return result
    }

    /// Measure a component-specific operation
    /// - Parameters:
    ///   - componentName: Name of the component being measured
    ///   - operation: The operation to measure
    /// - Returns: The result of the operation
    @discardableResult
    public func measureComponent<T>(
        _ componentName: String,
        _ operation: () -> T
    ) -> T {
        guard isActive else { return operation() }

        return componentMetrics.measure(componentName: componentName, operation)
    }

    // MARK: - Public API - Tree Metrics

    /// Update VNode count metric
    /// - Parameter count: Current number of VNodes in the tree
    public func updateVNodeCount(_ count: Int) {
        vnodeCount = count
        if var session = currentSession {
            session.recordVNodeCount(count)
            currentSession = session
        }
    }

    /// Update DOM node count metric
    /// - Parameter count: Current number of DOM nodes
    public func updateDOMNodeCount(_ count: Int) {
        domNodeCount = count
        if var session = currentSession {
            session.recordDOMNodeCount(count)
            currentSession = session
        }
    }

    /// Record a dropped frame
    public func recordDroppedFrame() {
        frameRateMonitor.recordDroppedFrame()
    }

    // MARK: - Public API - Reports

    /// Generate a comprehensive performance report
    /// - Returns: Performance report with all collected metrics
    public func generateReport() -> PerformanceReport {
        PerformanceReport(
            session: currentSession,
            diffingMetrics: calculateMetrics(from: diffingHistory),
            patchingMetrics: calculateMetrics(from: patchingHistory),
            renderMetrics: calculateMetrics(from: renderHistory),
            componentMetrics: componentMetrics.getAllMetrics(),
            memoryMetrics: memoryMonitor.getMetrics(),
            frameRateMetrics: frameRateMonitor.getMetrics(),
            vnodeCount: vnodeCount,
            domNodeCount: domNodeCount,
            timestamp: Date()
        )
    }

    /// Export profiling data as JSON
    /// - Returns: JSON string representation of the performance report
    public func exportJSON() -> String {
        let report = generateReport()
        return report.toJSON()
    }

    // MARK: - Private Methods

    /// Get current high-resolution timestamp
    private func getCurrentTime() -> Double {
        if let perf = jsPerformance, let now = perf.now!().number {
            return now
        }
        // Fallback to Date timestamp (less precise)
        return Date().timeIntervalSince1970 * 1000.0
    }

    /// Calculate statistical metrics from timing measurements
    private func calculateMetrics(from measurements: [TimingMeasurement]) -> OperationMetrics {
        guard !measurements.isEmpty else {
            return OperationMetrics(
                count: 0,
                totalDuration: 0,
                averageDuration: 0,
                minDuration: 0,
                maxDuration: 0,
                p50Duration: 0,
                p95Duration: 0,
                p99Duration: 0
            )
        }

        let durations = measurements.map { $0.duration }.sorted()
        let total = durations.reduce(0, +)
        let average = total / Double(durations.count)

        return OperationMetrics(
            count: durations.count,
            totalDuration: total,
            averageDuration: average,
            minDuration: durations.first ?? 0,
            maxDuration: durations.last ?? 0,
            p50Duration: percentile(durations, 0.5),
            p95Duration: percentile(durations, 0.95),
            p99Duration: percentile(durations, 0.99)
        )
    }

    /// Calculate percentile from sorted array
    private func percentile(_ sortedValues: [Double], _ p: Double) -> Double {
        guard !sortedValues.isEmpty else { return 0 }
        let index = Int(Double(sortedValues.count - 1) * p)
        return sortedValues[index]
    }

    /// Trim history arrays if they exceed maximum size
    private func trimHistoryIfNeeded(_ history: inout [TimingMeasurement]) {
        if history.count > maxHistorySize {
            history.removeFirst(history.count - maxHistorySize)
        }
    }

    /// Set up DevTools integration via window.__RAVEN_PERF__
    private func setupDevToolsIntegration() {
        #if !arch(wasm32)
        return
        #else
        guard let window = JSObject.global.window.object else { return }

        // Create Raven performance object
        let perfObject = JSObject.global.Object.function!.new()

        // Expose methods to JavaScript
        let getReportClosure = JSClosure { [weak self] _ -> JSValue in
            guard let self = self else { return .undefined }
            let report = self.generateReport()
            return .string(report.toJSON())
        }

        let startProfilingClosure = JSClosure { [weak self] _ -> JSValue in
            guard let self = self else { return .undefined }
            self.startProfiling()
            return .boolean(true)
        }

        let stopProfilingClosure = JSClosure { [weak self] _ -> JSValue in
            guard let self = self else { return .undefined }
            self.stopProfiling()
            return .boolean(true)
        }

        let resetClosure = JSClosure { [weak self] _ -> JSValue in
            guard let self = self else { return .undefined }
            self.reset()
            return .boolean(true)
        }

        perfObject.getReport = .object(getReportClosure)
        perfObject.startProfiling = .object(startProfilingClosure)
        perfObject.stopProfiling = .object(stopProfilingClosure)
        perfObject.reset = .object(resetClosure)

        // Expose to window
        window.__RAVEN_PERF__ = .object(perfObject)

        print("🔍 Raven Profiler: DevTools integration enabled at window.__RAVEN_PERF__")
        #endif
    }
}

// MARK: - Supporting Types

/// A single timing measurement
public struct TimingMeasurement: Sendable {
    public let label: String
    public let startTime: Double
    public let endTime: Double
    public let duration: Double

    public init(label: String, startTime: Double, endTime: Double, duration: Double) {
        self.label = label
        self.startTime = startTime
        self.endTime = endTime
        self.duration = duration
    }
}

/// Statistical metrics for an operation type
public struct OperationMetrics: Sendable {
    public let count: Int
    public let totalDuration: Double
    public let averageDuration: Double
    public let minDuration: Double
    public let maxDuration: Double
    public let p50Duration: Double
    public let p95Duration: Double
    public let p99Duration: Double
}

/// A profiling session tracking a period of measurements
public struct ProfilingSession: Sendable {
    public let id: UUID
    public let label: String?
    public let startTime: Date
    public var endTime: Date?

    var diffingMeasurements: [TimingMeasurement] = []
    var patchingMeasurements: [TimingMeasurement] = []
    var renderMeasurements: [TimingMeasurement] = []
    var vnodeCounts: [Int] = []
    var domNodeCounts: [Int] = []

    public var duration: Double {
        let end = endTime ?? Date()
        return end.timeIntervalSince(startTime) * 1000.0 // milliseconds
    }

    public init(label: String? = nil) {
        self.id = UUID()
        self.label = label
        self.startTime = Date()
    }

    mutating func recordDiffing(_ measurement: TimingMeasurement) {
        diffingMeasurements.append(measurement)
    }

    mutating func recordPatching(_ measurement: TimingMeasurement) {
        patchingMeasurements.append(measurement)
    }

    mutating func recordRender(_ measurement: TimingMeasurement) {
        renderMeasurements.append(measurement)
    }

    mutating func recordVNodeCount(_ count: Int) {
        vnodeCounts.append(count)
    }

    mutating func recordDOMNodeCount(_ count: Int) {
        domNodeCounts.append(count)
    }

    mutating func finalize() {
        endTime = Date()
    }
}
