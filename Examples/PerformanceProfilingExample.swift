import Foundation
import Raven

/// Example demonstrating the Performance Profiling Infrastructure
///
/// This example shows how to use the profiling system to monitor
/// rendering performance and identify bottlenecks.

@MainActor
struct PerformanceProfilingExample {

    // MARK: - Basic Profiling Example

    static func basicProfilingExample() async {
        print("=== Basic Profiling Example ===\n")

        let profiler = RenderProfiler.shared

        // Start profiling session
        profiler.startProfiling(label: "Basic Example")

        // Simulate some render operations
        for i in 1...10 {
            await profiler.measureRender(label: "Render \(i)") {
                // Simulate diffing
                profiler.measureDiffing(label: "Diff \(i)") {
                    simulateWork(duration: 0.003) // 3ms
                }

                // Simulate patching
                await profiler.measurePatching(label: "Patch \(i)") {
                    simulateWork(duration: 0.008) // 8ms
                }
            }

            // Update tree metrics
            profiler.updateVNodeCount(100 + i * 10)
            profiler.updateDOMNodeCount(95 + i * 10)
        }

        // Generate and print report
        let report = profiler.generateReport()
        print(report.summary)
        print("\n")

        // Stop profiling
        profiler.stopProfiling()
    }

    // MARK: - Component Profiling Example

    static func componentProfilingExample() {
        print("=== Component Profiling Example ===\n")

        let profiler = RenderProfiler.shared
        profiler.startProfiling(label: "Component Analysis")

        // Simulate rendering different components
        let components = [
            ("Header", 0.002),
            ("UserProfile", 0.015),
            ("ProductList", 0.025),
            ("Footer", 0.001),
            ("Sidebar", 0.008),
            ("SearchBar", 0.005)
        ]

        // Render each component multiple times
        for _ in 1...20 {
            for (name, duration) in components {
                profiler.measureComponent(name) {
                    simulateWork(duration: duration)
                }
            }
        }

        // Get slow components
        let metrics = ComponentMetrics()
        let slowComponents = profiler.generateReport().componentMetrics
            .filter { $0.value.isSlow }
            .sorted { $0.value.averageDuration > $1.value.averageDuration }

        print("Slow Components (>16ms):")
        for (name, metric) in slowComponents {
            print("  - \(name): \(String(format: "%.2f", metric.averageDuration))ms avg")
        }
        print("\n")

        profiler.stopProfiling()
    }

    // MARK: - Memory Monitoring Example

    static func memoryMonitoringExample() async {
        print("=== Memory Monitoring Example ===\n")

        let monitor = MemoryMonitor()

        // Start monitoring
        monitor.start()

        // Simulate memory-intensive operations
        print("Simulating memory allocations...")
        for i in 1...5 {
            // Take sample
            let usage = monitor.sampleMemory()
            print("Sample \(i): \(usage / 1_000_000) MB")

            // Simulate some work
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
        }

        // Get metrics
        let metrics = monitor.getMetrics()
        print("\nMemory Metrics:")
        print("  - Current: \(String(format: "%.2f", metrics.currentUsageMB)) MB")
        print("  - Peak: \(String(format: "%.2f", metrics.peakUsageMB)) MB")
        print("  - Average: \(String(format: "%.2f", metrics.averageUsageMB)) MB")

        // Check for leaks
        if let warning = monitor.detectMemoryLeaks() {
            print("\n⚠️  Memory Leak Warning:")
            print("  - Severity: \(warning.severity)")
            print("  - Message: \(warning.message)")
        }

        // Get trend
        let trend = monitor.getMemoryTrend()
        print("  - Trend: \(trend.rawValue)")
        print("\n")

        monitor.stop()
    }

    // MARK: - Frame Rate Monitoring Example

    static func frameRateMonitoringExample() async {
        print("=== Frame Rate Monitoring Example ===\n")

        let monitor = FrameRateMonitor()

        // Start monitoring
        monitor.start()

        // Simulate 60 frames with varying durations
        print("Simulating 60 frames...")
        for i in 1...60 {
            // Most frames are good (12-15ms)
            var duration = Double.random(in: 12.0...15.0)

            // Every 10th frame is slower (simulating heavy work)
            if i % 10 == 0 {
                duration = Double.random(in: 18.0...25.0)
            }

            monitor.recordFrame(duration: duration)

            // Small delay between frames
            try? await Task.sleep(nanoseconds: 16_666_666) // ~60 FPS
        }

        // Get metrics
        let metrics = monitor.getMetrics()
        print("\nFrame Rate Metrics:")
        print("  - Current FPS: \(String(format: "%.1f", metrics.currentFPS))")
        print("  - Average FPS: \(String(format: "%.1f", metrics.averageFPS))")
        print("  - Dropped Frames: \(metrics.droppedFrameCount) (\(String(format: "%.1f", metrics.droppedFramePercentage))%)")
        print("  - Performance Grade: \(metrics.performanceGrade)")

        // Get percentiles
        let percentiles = monitor.getFrameTimePercentiles()
        print("\nFrame Time Percentiles:")
        print("  - P50: \(String(format: "%.2f", percentiles.p50))ms")
        print("  - P95: \(String(format: "%.2f", percentiles.p95))ms")
        print("  - P99: \(String(format: "%.2f", percentiles.p99))ms")

        // Check performance
        if monitor.isFrameRateAcceptable() {
            print("\n✅ Frame rate is acceptable")
        } else {
            print("\n⚠️  Frame rate needs improvement")
        }

        if monitor.hasPerformanceIssues() {
            print("⚠️  Performance issues detected")
        }

        print("\n")
        monitor.stop()
    }

    // MARK: - Full Report Example

    static func fullReportExample() async {
        print("=== Full Performance Report Example ===\n")

        let profiler = RenderProfiler.shared

        // Start comprehensive profiling
        profiler.startProfiling(label: "Full Test")

        // Simulate a realistic workload
        for cycle in 1...30 {
            await profiler.measureRender(label: "Cycle \(cycle)") {
                // Diffing phase
                profiler.measureDiffing {
                    simulateWork(duration: Double.random(in: 0.002...0.008))
                }

                // Patching phase
                await profiler.measurePatching {
                    simulateWork(duration: Double.random(in: 0.005...0.012))
                }

                // Update metrics
                profiler.updateVNodeCount(Int.random(in: 100...500))
                profiler.updateDOMNodeCount(Int.random(in: 95...480))
            }

            // Simulate component renders
            profiler.measureComponent("Header") {
                simulateWork(duration: 0.002)
            }
            profiler.measureComponent("MainContent") {
                simulateWork(duration: Double.random(in: 0.008...0.015))
            }
            profiler.measureComponent("Sidebar") {
                simulateWork(duration: 0.005)
            }

            // Small delay between cycles
            try? await Task.sleep(nanoseconds: 16_666_666)
        }

        // Generate comprehensive report
        let report = profiler.generateReport()

        // Print full summary
        print(report.summary)
        print("\n")

        // Export as JSON (for analytics)
        let json = report.toJSON()
        print("JSON Report Preview:")
        print(json.prefix(500) + "...\n")

        // Check for specific issues
        if report.hasPerformanceIssues {
            print("⚠️  Detected Issues:")
            for issue in report.performanceIssues {
                print("  - \(issue.description)")
            }
            print("\n")
        }

        // Performance recommendations
        print("Performance Score: \(String(format: "%.2f", report.performanceScore)) (\(report.performanceGrade))")
        if report.performanceScore < 0.8 {
            print("💡 Recommendations:")
            print("  - Optimize slow components")
            print("  - Reduce VNode tree depth")
            print("  - Batch DOM updates")
            print("  - Consider virtual scrolling for lists")
        }

        profiler.stopProfiling()
    }

    // MARK: - DevTools Integration Example

    static func devToolsIntegrationExample() {
        print("=== DevTools Integration Example ===\n")

        print("The profiler exposes the following API at window.__RAVEN_PERF__:")
        print("")
        print("JavaScript Console Commands:")
        print("  window.__RAVEN_PERF__.startProfiling()")
        print("  window.__RAVEN_PERF__.stopProfiling()")
        print("  window.__RAVEN_PERF__.getReport()")
        print("  window.__RAVEN_PERF__.reset()")
        print("")
        print("Try these commands in your browser's developer console!")
        print("\n")
    }

    // MARK: - Helper Methods

    /// Simulate work by blocking for a duration
    private static func simulateWork(duration: TimeInterval) {
        let start = Date()
        while Date().timeIntervalSince(start) < duration {
            // Busy wait to simulate CPU work
        }
    }
}

// MARK: - Example Runner

#if canImport(JavaScriptKit)
@main
@MainActor
struct PerformanceProfilingExampleRunner {
    static func main() async {
        print("🔍 Raven Performance Profiling Examples\n")

        // Run all examples
        await PerformanceProfilingExample.basicProfilingExample()
        PerformanceProfilingExample.componentProfilingExample()
        await PerformanceProfilingExample.memoryMonitoringExample()
        await PerformanceProfilingExample.frameRateMonitoringExample()
        await PerformanceProfilingExample.fullReportExample()
        PerformanceProfilingExample.devToolsIntegrationExample()

        print("✅ All examples completed!")
    }
}
#endif
