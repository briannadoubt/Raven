import Foundation

/// Comprehensive performance report with JSON export capabilities
///
/// PerformanceReport aggregates all performance metrics into a single
/// comprehensive report that can be analyzed or exported for further analysis.
///
/// Example usage:
/// ```swift
/// let report = profiler.generateReport()
///
/// // Print summary
/// print(report.summary)
///
/// // Export as JSON
/// let json = report.toJSON()
/// // Save or send to analytics
///
/// // Get specific metrics
/// if report.hasPerformanceIssues {
///     print("Performance issues detected!")
///     for issue in report.performanceIssues {
///         print("- \(issue.description)")
///     }
/// }
/// ```
public struct PerformanceReport: Sendable {

    // MARK: - Properties

    /// Optional profiling session information
    public let session: ProfilingSession?

    /// VNode diffing operation metrics
    public let diffingMetrics: OperationMetrics

    /// DOM patching operation metrics
    public let patchingMetrics: OperationMetrics

    /// Complete render cycle metrics
    public let renderMetrics: OperationMetrics

    /// Per-component metrics
    public let componentMetrics: [String: ComponentMetric]

    /// Memory usage metrics
    public let memoryMetrics: MemoryMetrics

    /// Frame rate metrics
    public let frameRateMetrics: FrameRateMetrics

    /// Current VNode count
    public let vnodeCount: Int

    /// Current DOM node count
    public let domNodeCount: Int

    /// Report generation timestamp
    public let timestamp: Date

    // MARK: - Computed Properties

    /// Whether there are any performance issues detected
    public var hasPerformanceIssues: Bool {
        !performanceIssues.isEmpty
    }

    /// List of detected performance issues
    public var performanceIssues: [PerformanceIssue] {
        var issues: [PerformanceIssue] = []

        // Check frame rate
        if frameRateMetrics.averageFPS < 55 {
            issues.append(.lowFrameRate(fps: frameRateMetrics.averageFPS))
        }

        // Check dropped frames
        if frameRateMetrics.droppedFramePercentage > 5 {
            issues.append(.highDroppedFrameRate(percentage: frameRateMetrics.droppedFramePercentage))
        }

        // Check render time
        if renderMetrics.averageDuration > 16.67 {
            issues.append(.slowRenderCycle(averageMs: renderMetrics.averageDuration))
        }

        // Check for slow components
        let slowComponents = componentMetrics.filter { $0.value.isSlow }
        if !slowComponents.isEmpty {
            issues.append(.slowComponents(count: slowComponents.count))
        }

        // Check diffing performance
        if diffingMetrics.p95Duration > 10.0 {
            issues.append(.slowDiffing(p95Ms: diffingMetrics.p95Duration))
        }

        // Check patching performance
        if patchingMetrics.p95Duration > 10.0 {
            issues.append(.slowPatching(p95Ms: patchingMetrics.p95Duration))
        }

        return issues
    }

    /// Overall performance score (0.0 to 1.0)
    public var performanceScore: Double {
        var score = 1.0

        // Deduct points for low FPS
        if frameRateMetrics.averageFPS < 60 {
            score -= (60 - frameRateMetrics.averageFPS) / 60.0 * 0.3
        }

        // Deduct points for dropped frames
        score -= frameRateMetrics.droppedFramePercentage / 100.0 * 0.2

        // Deduct points for slow render cycles
        if renderMetrics.averageDuration > 16.67 {
            score -= min((renderMetrics.averageDuration - 16.67) / 50.0, 0.3)
        }

        return max(score, 0.0)
    }

    /// Performance grade (A, B, C, D, F)
    public var performanceGrade: String {
        if performanceScore >= 0.9 {
            return "A"
        } else if performanceScore >= 0.75 {
            return "B"
        } else if performanceScore >= 0.6 {
            return "C"
        } else if performanceScore >= 0.5 {
            return "D"
        } else {
            return "F"
        }
    }

    /// Human-readable summary of the report
    public var summary: String {
        var lines: [String] = []

        lines.append("=== Raven Performance Report ===")
        lines.append("Timestamp: \(timestamp)")
        lines.append("Performance Grade: \(performanceGrade) (Score: \(String(format: "%.2f", performanceScore)))")
        lines.append("")

        // Frame Rate
        lines.append("Frame Rate:")
        lines.append("  - Current: \(String(format: "%.1f", frameRateMetrics.currentFPS)) FPS")
        lines.append("  - Average: \(String(format: "%.1f", frameRateMetrics.averageFPS)) FPS")
        lines.append("  - Dropped: \(frameRateMetrics.droppedFrameCount) (\(String(format: "%.1f", frameRateMetrics.droppedFramePercentage))%)")
        lines.append("")

        // Render Metrics
        lines.append("Render Cycles:")
        lines.append("  - Count: \(renderMetrics.count)")
        lines.append("  - Average: \(String(format: "%.2f", renderMetrics.averageDuration))ms")
        lines.append("  - P95: \(String(format: "%.2f", renderMetrics.p95Duration))ms")
        lines.append("  - P99: \(String(format: "%.2f", renderMetrics.p99Duration))ms")
        lines.append("")

        // Diffing Metrics
        lines.append("VNode Diffing:")
        lines.append("  - Count: \(diffingMetrics.count)")
        lines.append("  - Average: \(String(format: "%.2f", diffingMetrics.averageDuration))ms")
        lines.append("  - P95: \(String(format: "%.2f", diffingMetrics.p95Duration))ms")
        lines.append("")

        // Patching Metrics
        lines.append("DOM Patching:")
        lines.append("  - Count: \(patchingMetrics.count)")
        lines.append("  - Average: \(String(format: "%.2f", patchingMetrics.averageDuration))ms")
        lines.append("  - P95: \(String(format: "%.2f", patchingMetrics.p95Duration))ms")
        lines.append("")

        // Tree Size
        lines.append("Tree Size:")
        lines.append("  - VNodes: \(vnodeCount)")
        lines.append("  - DOM Nodes: \(domNodeCount)")
        lines.append("")

        // Memory
        lines.append("Memory:")
        lines.append("  - Current: \(String(format: "%.2f", memoryMetrics.currentUsageMB)) MB")
        lines.append("  - Peak: \(String(format: "%.2f", memoryMetrics.peakUsageMB)) MB")
        lines.append("")

        // Components
        if !componentMetrics.isEmpty {
            lines.append("Top Components by Duration:")
            let topComponents = componentMetrics
                .sorted { $0.value.totalDuration > $1.value.totalDuration }
                .prefix(5)
            for (name, metric) in topComponents {
                lines.append("  - \(name): \(String(format: "%.2f", metric.averageDuration))ms avg (\(metric.callCount) calls)")
            }
            lines.append("")
        }

        // Issues
        if hasPerformanceIssues {
            lines.append("⚠️ Performance Issues:")
            for issue in performanceIssues {
                lines.append("  - \(issue.description)")
            }
        } else {
            lines.append("✅ No performance issues detected")
        }

        return lines.joined(separator: "\n")
    }

    // MARK: - JSON Export

    /// Export report as JSON string
    /// - Returns: JSON string representation of the report
    public func toJSON() -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        guard let data = try? encoder.encode(self.toEncodable()),
              let json = String(data: data, encoding: .utf8) else {
            return "{\"error\": \"Failed to encode report\"}"
        }

        return json
    }

    /// Convert report to an encodable structure
    private func toEncodable() -> EncodableReport {
        EncodableReport(
            timestamp: timestamp.ISO8601Format(),
            performanceScore: performanceScore,
            performanceGrade: performanceGrade,
            session: session.map { sessionData in
                EncodableSession(
                    id: sessionData.id.uuidString,
                    label: sessionData.label,
                    startTime: sessionData.startTime.ISO8601Format(),
                    endTime: sessionData.endTime?.ISO8601Format(),
                    duration: sessionData.duration
                )
            },
            rendering: EncodableRenderingMetrics(
                diffing: toEncodableOperationMetrics(diffingMetrics),
                patching: toEncodableOperationMetrics(patchingMetrics),
                render: toEncodableOperationMetrics(renderMetrics)
            ),
            components: componentMetrics.mapValues { metric in
                EncodableComponentMetric(
                    callCount: metric.callCount,
                    totalDuration: metric.totalDuration,
                    averageDuration: metric.averageDuration,
                    minDuration: metric.minDuration,
                    maxDuration: metric.maxDuration,
                    isSlow: metric.isSlow
                )
            },
            memory: EncodableMemoryMetrics(
                currentUsageMB: memoryMetrics.currentUsageMB,
                peakUsageMB: memoryMetrics.peakUsageMB,
                averageUsageMB: memoryMetrics.averageUsageMB
            ),
            frameRate: EncodableFrameRateMetrics(
                currentFPS: frameRateMetrics.currentFPS,
                averageFPS: frameRateMetrics.averageFPS,
                minFPS: frameRateMetrics.minFPS,
                maxFPS: frameRateMetrics.maxFPS,
                droppedFrameCount: frameRateMetrics.droppedFrameCount,
                totalFrameCount: frameRateMetrics.totalFrameCount,
                droppedFramePercentage: frameRateMetrics.droppedFramePercentage,
                performanceGrade: frameRateMetrics.performanceGrade
            ),
            tree: EncodableTreeMetrics(
                vnodeCount: vnodeCount,
                domNodeCount: domNodeCount
            ),
            issues: performanceIssues.map { $0.description }
        )
    }

    private func toEncodableOperationMetrics(_ metrics: OperationMetrics) -> EncodableOperationMetrics {
        EncodableOperationMetrics(
            count: metrics.count,
            totalDuration: metrics.totalDuration,
            averageDuration: metrics.averageDuration,
            minDuration: metrics.minDuration,
            maxDuration: metrics.maxDuration,
            p50Duration: metrics.p50Duration,
            p95Duration: metrics.p95Duration,
            p99Duration: metrics.p99Duration
        )
    }
}

// MARK: - Encodable Types for JSON Export

private struct EncodableReport: Codable {
    let timestamp: String
    let performanceScore: Double
    let performanceGrade: String
    let session: EncodableSession?
    let rendering: EncodableRenderingMetrics
    let components: [String: EncodableComponentMetric]
    let memory: EncodableMemoryMetrics
    let frameRate: EncodableFrameRateMetrics
    let tree: EncodableTreeMetrics
    let issues: [String]
}

private struct EncodableSession: Codable {
    let id: String
    let label: String?
    let startTime: String
    let endTime: String?
    let duration: Double
}

private struct EncodableRenderingMetrics: Codable {
    let diffing: EncodableOperationMetrics
    let patching: EncodableOperationMetrics
    let render: EncodableOperationMetrics
}

private struct EncodableOperationMetrics: Codable {
    let count: Int
    let totalDuration: Double
    let averageDuration: Double
    let minDuration: Double
    let maxDuration: Double
    let p50Duration: Double
    let p95Duration: Double
    let p99Duration: Double
}

private struct EncodableComponentMetric: Codable {
    let callCount: Int
    let totalDuration: Double
    let averageDuration: Double
    let minDuration: Double
    let maxDuration: Double
    let isSlow: Bool
}

private struct EncodableMemoryMetrics: Codable {
    let currentUsageMB: Double
    let peakUsageMB: Double
    let averageUsageMB: Double
}

private struct EncodableFrameRateMetrics: Codable {
    let currentFPS: Double
    let averageFPS: Double
    let minFPS: Double
    let maxFPS: Double
    let droppedFrameCount: Int
    let totalFrameCount: Int
    let droppedFramePercentage: Double
    let performanceGrade: String
}

private struct EncodableTreeMetrics: Codable {
    let vnodeCount: Int
    let domNodeCount: Int
}

// MARK: - Performance Issues

/// Types of performance issues that can be detected
public enum PerformanceIssue: Sendable {
    case lowFrameRate(fps: Double)
    case highDroppedFrameRate(percentage: Double)
    case slowRenderCycle(averageMs: Double)
    case slowComponents(count: Int)
    case slowDiffing(p95Ms: Double)
    case slowPatching(p95Ms: Double)

    public var description: String {
        switch self {
        case .lowFrameRate(let fps):
            return "Low frame rate: \(String(format: "%.1f", fps)) FPS (target: 60 FPS)"
        case .highDroppedFrameRate(let percentage):
            return "High dropped frame rate: \(String(format: "%.1f", percentage))% (target: <5%)"
        case .slowRenderCycle(let averageMs):
            return "Slow render cycles: \(String(format: "%.2f", averageMs))ms average (target: <16.67ms)"
        case .slowComponents(let count):
            return "Slow components detected: \(count) component(s) exceeding 16ms render time"
        case .slowDiffing(let p95Ms):
            return "Slow VNode diffing: P95 \(String(format: "%.2f", p95Ms))ms (target: <10ms)"
        case .slowPatching(let p95Ms):
            return "Slow DOM patching: P95 \(String(format: "%.2f", p95Ms))ms (target: <10ms)"
        }
    }
}
