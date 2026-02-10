import Foundation
import JavaScriptKit

/// Memory usage monitor for tracking JavaScript heap and DOM memory
///
/// MemoryMonitor provides insights into memory consumption during rendering,
/// helping identify memory leaks and optimize resource usage.
///
/// Example usage:
/// ```swift
/// let monitor = MemoryMonitor()
/// monitor.start()
///
/// // ... perform operations ...
///
/// let metrics = monitor.getMetrics()
/// print("Used memory: \(metrics.currentUsage / 1_000_000) MB")
/// print("Peak memory: \(metrics.peakUsage / 1_000_000) MB")
///
/// monitor.stop()
/// ```
@MainActor
public final class MemoryMonitor: Sendable {

    // MARK: - Properties

    /// Whether monitoring is currently active
    private var isMonitoring: Bool = false

    /// Current memory usage in bytes
    private var currentUsage: Int64 = 0

    /// Peak memory usage in bytes
    private var peakUsage: Int64 = 0

    /// Historical memory usage samples
    private var usageHistory: [MemorySample] = []

    /// Maximum number of samples to keep
    private let maxSamples: Int = 500

    /// Sampling interval in seconds
    private let samplingInterval: Double = 0.5

    /// Reference to JavaScript performance.memory API
    private let jsMemory: JSObject?

    // MARK: - Initialization

    public init() {
        // Try to access JavaScript performance.memory API (non-standard but widely supported)
        if let performance = JSObject.global.performance.object,
           !performance.memory.isUndefined {
            self.jsMemory = performance.memory.object
        } else {
            self.jsMemory = nil
            print("⚠️ MemoryMonitor: performance.memory API not available")
        }
    }

    // MARK: - Public API

    /// Start memory monitoring
    public func start() {
        guard !isMonitoring else { return }
        isMonitoring = true
        usageHistory.removeAll()

        // Take initial sample
        sampleMemory()

        // Start periodic sampling
        scheduleNextSample()

        print("📊 MemoryMonitor: Started monitoring")
    }

    /// Stop memory monitoring
    public func stop() {
        guard isMonitoring else { return }
        isMonitoring = false

        print("📊 MemoryMonitor: Stopped monitoring")
    }

    /// Get current memory metrics
    /// - Returns: Current memory metrics
    public func getMetrics() -> MemoryMetrics {
        let samples = usageHistory
        let avgUsage = samples.isEmpty ? 0 : samples.reduce(0) { $0 + $1.usage } / Int64(samples.count)

        return MemoryMetrics(
            currentUsage: currentUsage,
            peakUsage: peakUsage,
            averageUsage: avgUsage,
            sampleCount: samples.count,
            samples: samples
        )
    }

    /// Force a memory sample to be taken
    /// - Returns: Current memory usage in bytes
    @discardableResult
    public func sampleMemory() -> Int64 {
        let usage = getCurrentMemoryUsage()

        currentUsage = usage
        peakUsage = max(peakUsage, usage)

        let sample = MemorySample(
            timestamp: Date(),
            usage: usage
        )

        usageHistory.append(sample)
        trimHistoryIfNeeded()

        return usage
    }

    /// Reset all memory statistics
    public func reset() {
        stop()
        currentUsage = 0
        peakUsage = 0
        usageHistory.removeAll()
    }

    /// Estimate memory used by VNodes
    /// - Parameter vnodeCount: Number of VNodes in the tree
    /// - Returns: Estimated memory usage in bytes
    public func estimateVNodeMemory(vnodeCount: Int) -> Int64 {
        // Rough estimate: each VNode takes ~200 bytes (struct + properties + children array)
        // This is a heuristic and may vary based on actual node complexity
        return Int64(vnodeCount) * 200
    }

    /// Estimate memory used by DOM nodes
    /// - Parameter domNodeCount: Number of DOM nodes
    /// - Returns: Estimated memory usage in bytes
    public func estimateDOMMemory(domNodeCount: Int) -> Int64 {
        // Rough estimate: each DOM node takes ~500 bytes (element + attributes + listeners)
        // This is a heuristic and actual size varies significantly by browser
        return Int64(domNodeCount) * 500
    }

    // MARK: - Memory Analysis

    /// Detect potential memory leaks
    /// - Returns: Memory leak warning if detected
    public func detectMemoryLeaks() -> MemoryLeakWarning? {
        guard usageHistory.count >= 10 else { return nil }

        // Check if memory is consistently growing over the last 10 samples
        let recentSamples = usageHistory.suffix(10)
        let isGrowing = zip(recentSamples, recentSamples.dropFirst()).allSatisfy { $0.usage < $1.usage }

        if isGrowing {
            let firstSample = recentSamples.first!
            let lastSample = recentSamples.last!
            let growthRate = Double(lastSample.usage - firstSample.usage) / Double(firstSample.usage)

            if growthRate > 0.5 { // 50% growth over last 10 samples
                return MemoryLeakWarning(
                    severity: .high,
                    message: "Memory usage increased by \(Int(growthRate * 100))% over \(recentSamples.count) samples",
                    initialUsage: firstSample.usage,
                    currentUsage: lastSample.usage,
                    growthRate: growthRate
                )
            } else if growthRate > 0.2 { // 20% growth
                return MemoryLeakWarning(
                    severity: .medium,
                    message: "Memory usage increased by \(Int(growthRate * 100))% over \(recentSamples.count) samples",
                    initialUsage: firstSample.usage,
                    currentUsage: lastSample.usage,
                    growthRate: growthRate
                )
            }
        }

        return nil
    }

    /// Get memory usage trend
    /// - Returns: Trend direction (growing, stable, shrinking)
    public func getMemoryTrend() -> MemoryTrend {
        guard usageHistory.count >= 5 else { return .stable }

        let recentSamples = usageHistory.suffix(5)
        let avgFirst = recentSamples.prefix(2).reduce(0) { $0 + $1.usage } / 2
        let avgLast = recentSamples.suffix(2).reduce(0) { $0 + $1.usage } / 2

        let change = Double(avgLast - avgFirst) / Double(avgFirst)

        if change > 0.1 {
            return .growing
        } else if change < -0.1 {
            return .shrinking
        } else {
            return .stable
        }
    }

    // MARK: - Private Methods

    /// Get current memory usage from JavaScript API
    private func getCurrentMemoryUsage() -> Int64 {
        guard let memory = jsMemory else {
            // Fallback: return 0 if API not available
            return 0
        }

        // Use usedJSHeapSize if available
        if let usedHeapSize = memory.usedJSHeapSize.number {
            return Int64(usedHeapSize)
        }

        return 0
    }

    /// Schedule next memory sample
    private func scheduleNextSample() {
        guard isMonitoring else { return }

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(samplingInterval * 1_000_000_000))
            if self.isMonitoring {
                self.sampleMemory()
                self.scheduleNextSample()
            }
        }
    }

    /// Trim history if it exceeds maximum size
    private func trimHistoryIfNeeded() {
        if usageHistory.count > maxSamples {
            usageHistory.removeFirst(usageHistory.count - maxSamples)
        }
    }
}

// MARK: - Supporting Types

/// A single memory usage sample
public struct MemorySample: Sendable {
    /// Timestamp when the sample was taken
    public let timestamp: Date

    /// Memory usage in bytes
    public let usage: Int64

    public init(timestamp: Date, usage: Int64) {
        self.timestamp = timestamp
        self.usage = usage
    }
}

/// Memory metrics summary
public struct MemoryMetrics: Sendable {
    /// Current memory usage in bytes
    public let currentUsage: Int64

    /// Peak memory usage in bytes
    public let peakUsage: Int64

    /// Average memory usage in bytes
    public let averageUsage: Int64

    /// Number of samples collected
    public let sampleCount: Int

    /// Historical samples
    public let samples: [MemorySample]

    /// Current usage in megabytes
    public var currentUsageMB: Double {
        Double(currentUsage) / 1_000_000.0
    }

    /// Peak usage in megabytes
    public var peakUsageMB: Double {
        Double(peakUsage) / 1_000_000.0
    }

    /// Average usage in megabytes
    public var averageUsageMB: Double {
        Double(averageUsage) / 1_000_000.0
    }
}

/// Memory leak warning
public struct MemoryLeakWarning: Sendable {
    public enum Severity: String, Sendable {
        case low
        case medium
        case high
    }

    /// Severity of the warning
    public let severity: Severity

    /// Human-readable message
    public let message: String

    /// Initial memory usage
    public let initialUsage: Int64

    /// Current memory usage
    public let currentUsage: Int64

    /// Growth rate (0.0 to 1.0+)
    public let growthRate: Double
}

/// Memory usage trend
public enum MemoryTrend: String, Sendable {
    case growing
    case stable
    case shrinking
}
