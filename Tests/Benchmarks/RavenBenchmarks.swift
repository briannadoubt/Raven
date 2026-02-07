import Foundation
@testable import Raven

/// Performance benchmarks for Raven framework
///
/// These benchmarks measure the performance characteristics of core Raven operations:
/// - VNode creation overhead
/// - Property diffing
/// - List rendering with ForEach
///
/// ## Running Benchmarks
///
/// Run from command line:
/// ```bash
/// swift run RavenBenchmarks
/// ```
///
/// ## Expected Performance Characteristics
///
/// - **Node Creation**: < 1ms for 1000 nodes
///
/// - **List Rendering**: Linear with number of items
///   - 100 items: < 5ms
///   - 1000 items: < 50ms
///
/// ## Methodology
///
/// - Each benchmark runs 10 times to average results
/// - Times are measured using ContinuousClock for accuracy
/// - Results include min, max, mean, and median times
@MainActor
public struct RavenBenchmarks: Sendable {

    public init() {}

    // MARK: - Benchmark Results

    public struct BenchmarkResult: Sendable {
        public let name: String
        public let iterations: Int
        public let times: [Duration]

        public var min: Duration { times.min() ?? .zero }
        public var max: Duration { times.max() ?? .zero }
        public var mean: Duration {
            let total = times.reduce(Duration.zero) { $0 + $1 }
            return total / iterations
        }
        public var median: Duration {
            let sorted = times.sorted()
            let mid = sorted.count / 2
            return sorted.count % 2 == 0 ? sorted[mid] : sorted[mid]
        }

        public func report() -> String {
            """
            \(name):
              Iterations: \(iterations)
              Min: \(formatDuration(min))
              Max: \(formatDuration(max))
              Mean: \(formatDuration(mean))
              Median: \(formatDuration(median))
            """
        }

        private func formatDuration(_ duration: Duration) -> String {
            let nanoseconds = duration.components.seconds * 1_000_000_000 + duration.components.attoseconds / 1_000_000_000
            if nanoseconds < 1_000 {
                return "\(nanoseconds)ns"
            } else if nanoseconds < 1_000_000 {
                return String(format: "%.2fµs", Double(nanoseconds) / 1_000.0)
            } else if nanoseconds < 1_000_000_000 {
                return String(format: "%.2fms", Double(nanoseconds) / 1_000_000.0)
            } else {
                return String(format: "%.2fs", Double(nanoseconds) / 1_000_000_000.0)
            }
        }
    }

    // MARK: - List Rendering Benchmark

    /// Benchmark list rendering with ForEach
    ///
    /// Measures the time to create VNodes for a large list.
    /// Expected: < 5ms for 100 items
    public func benchmarkListRendering(iterations: Int = 10) -> BenchmarkResult {
        var times: [Duration] = []

        for _ in 0..<iterations {
            let items = (0..<100).map { "Item \($0)" }

            let clock = ContinuousClock()
            let elapsed = clock.measure {
                // Simulate list rendering
                let _ = createListNodes(items: items)
            }

            times.append(elapsed)
        }

        return BenchmarkResult(
            name: "List Rendering (100 items)",
            iterations: iterations,
            times: times
        )
    }

    /// Benchmark large list rendering
    ///
    /// Tests performance with 1000 items.
    /// Expected: < 50ms
    public func benchmarkLargeListRendering(iterations: Int = 10) -> BenchmarkResult {
        var times: [Duration] = []

        for _ in 0..<iterations {
            let items = (0..<1000).map { "Item \($0)" }

            let clock = ContinuousClock()
            let elapsed = clock.measure {
                let _ = createListNodes(items: items)
            }

            times.append(elapsed)
        }

        return BenchmarkResult(
            name: "Large List Rendering (1000 items)",
            iterations: iterations,
            times: times
        )
    }

    private func createListNodes(items: [String]) -> VNode {
        let children = items.map { item in
            VNode.element("li", children: [VNode.text(item)])
        }

        return VNode.element("ul", children: children)
    }

    // MARK: - Node Creation Benchmark

    /// Benchmark VNode creation overhead
    ///
    /// Measures the cost of creating VNode instances.
    /// Expected: < 1ms for 1000 nodes
    public func benchmarkNodeCreation(iterations: Int = 10) -> BenchmarkResult {
        var times: [Duration] = []

        for _ in 0..<iterations {
            let clock = ContinuousClock()
            let elapsed = clock.measure {
                for i in 0..<1000 {
                    let _ = VNode.element(
                        "div",
                        props: ["id": .attribute(name: "id", value: "node-\(i)")],
                        children: [VNode.text("Content \(i)")]
                    )
                }
            }

            times.append(elapsed)
        }

        return BenchmarkResult(
            name: "VNode Creation (1000 nodes)",
            iterations: iterations,
            times: times
        )
    }

    // MARK: - Property Diffing Benchmark

    /// Benchmark property diffing
    ///
    /// Measures the time to diff node properties.
    /// Expected: < 0.1ms for typical property sets
    public func benchmarkPropertyDiffing(iterations: Int = 100) -> BenchmarkResult {
        var times: [Duration] = []

        let oldProps: [String: VProperty] = [
            "class": .attribute(name: "class", value: "old-class"),
            "id": .attribute(name: "id", value: "element-1"),
            "color": .style(name: "color", value: "red"),
            "disabled": .boolAttribute(name: "disabled", value: false)
        ]

        let newProps: [String: VProperty] = [
            "class": .attribute(name: "class", value: "new-class"),
            "id": .attribute(name: "id", value: "element-1"),
            "color": .style(name: "color", value: "blue"),
            "fontSize": .style(name: "font-size", value: "16px")
        ]

        for _ in 0..<iterations {
            let clock = ContinuousClock()
            let elapsed = clock.measure {
                let _ = diffProperties(old: oldProps, new: newProps)
            }

            times.append(elapsed)
        }

        return BenchmarkResult(
            name: "Property Diffing",
            iterations: iterations,
            times: times
        )
    }

    private func diffProperties(
        old: [String: VProperty],
        new: [String: VProperty]
    ) -> [PropPatch] {
        var patches: [PropPatch] = []

        for (key, oldValue) in old {
            if let newValue = new[key] {
                if oldValue != newValue {
                    patches.append(.update(key: key, value: newValue))
                }
            } else {
                patches.append(.remove(key: key))
            }
        }

        for (key, newValue) in new {
            if old[key] == nil {
                patches.append(.add(key: key, value: newValue))
            }
        }

        return patches
    }

    // MARK: - Run All Benchmarks

    /// Run all benchmarks and print results
    public func runAll() async {
        print("🚀 Raven Performance Benchmarks")
        print("================================\n")

        let results = [
            benchmarkNodeCreation(),
            benchmarkPropertyDiffing(),
            benchmarkListRendering(),
            benchmarkLargeListRendering()
        ]

        for result in results {
            print(result.report())
            print()
        }

        print("================================")
        print("✅ Benchmarks complete")
    }
}

// MARK: - Executable

@main
struct BenchmarkRunner {
    static func main() async {
        let benchmarks = await RavenBenchmarks()
        await benchmarks.runAll()
    }
}
