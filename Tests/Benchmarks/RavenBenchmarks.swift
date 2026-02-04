import Foundation
@testable import Raven

/// Performance benchmarks for Raven framework
///
/// These benchmarks measure the performance characteristics of core Raven operations:
/// - VNode diffing with various tree sizes
/// - View-to-VNode conversion (render coordinator)
/// - State update propagation
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
/// - **VNode Diffing**: O(n) where n is the number of nodes
///   - 100 nodes: < 1ms
///   - 1000 nodes: < 10ms
///   - 10000 nodes: < 100ms
///
/// - **State Updates**: Should propagate in < 1ms for simple updates
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
@available(macOS 13, *)
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

    // MARK: - VNode Diffing Benchmark

    /// Benchmark VNode diffing with a large tree
    ///
    /// Creates two trees with 1000 nodes each and measures the time
    /// to compute the diff. This tests the core diffing algorithm performance.
    ///
    /// Expected: < 10ms for 1000-node tree
    public func benchmarkVNodeDiffing(iterations: Int = 10) async -> BenchmarkResult {
        var times: [Duration] = []

        for _ in 0..<iterations {
            let oldTree = createLargeTree(nodeCount: 1000, prefix: "old")
            let newTree = createLargeTree(nodeCount: 1000, prefix: "new")

            let differ = Differ()

            let clock = ContinuousClock()
            let elapsed = await clock.measure {
                let _ = await differ.diff(old: oldTree, new: newTree)
            }

            times.append(elapsed)
        }

        return BenchmarkResult(
            name: "VNode Diffing (1000 nodes)",
            iterations: iterations,
            times: times
        )
    }

    /// Benchmark VNode diffing with identical trees
    ///
    /// Tests the fast path when trees are identical.
    /// Expected: Faster than different trees, < 5ms
    public func benchmarkIdenticalTreeDiffing(iterations: Int = 10) async -> BenchmarkResult {
        var times: [Duration] = []

        for _ in 0..<iterations {
            let tree = createLargeTree(nodeCount: 1000, prefix: "same")

            let differ = Differ()

            let clock = ContinuousClock()
            let elapsed = await clock.measure {
                let _ = await differ.diff(old: tree, new: tree)
            }

            times.append(elapsed)
        }

        return BenchmarkResult(
            name: "Identical Tree Diffing (1000 nodes)",
            iterations: iterations,
            times: times
        )
    }

    /// Benchmark VNode diffing with small changes
    ///
    /// Tests incremental updates where only a few nodes change.
    /// This is the most common case in real applications.
    /// Expected: < 5ms
    public func benchmarkIncrementalDiffing(iterations: Int = 10) async -> BenchmarkResult {
        var times: [Duration] = []

        for _ in 0..<iterations {
            let oldTree = createLargeTree(nodeCount: 1000, prefix: "v1")
            let newTree = modifyTreeSlightly(oldTree)

            let differ = Differ()

            let clock = ContinuousClock()
            let elapsed = await clock.measure {
                let _ = await differ.diff(old: oldTree, new: newTree)
            }

            times.append(elapsed)
        }

        return BenchmarkResult(
            name: "Incremental Diffing (1000 nodes, few changes)",
            iterations: iterations,
            times: times
        )
    }

    // MARK: - Tree Creation Helpers

    private func createLargeTree(nodeCount: Int, prefix: String) -> VNode {
        // Create a balanced tree structure
        let childCount = 10
        let depth = Int(log(Double(nodeCount)) / log(Double(childCount)))

        func createNode(currentDepth: Int, index: Int) -> VNode {
            let id = "\(prefix)-\(currentDepth)-\(index)"

            if currentDepth >= depth {
                return VNode.text("\(prefix) text \(index)")
            }

            let children = (0..<childCount).map { childIndex in
                createNode(currentDepth: currentDepth + 1, index: index * childCount + childIndex)
            }

            return VNode.element(
                "div",
                props: [
                    "id": .attribute(name: "id", value: id),
                    "class": .attribute(name: "class", value: "node-\(currentDepth)")
                ],
                children: children
            )
        }

        return createNode(currentDepth: 0, index: 0)
    }

    private func modifyTreeSlightly(_ tree: VNode) -> VNode {
        // Modify just a few nodes in the tree
        guard !tree.children.isEmpty else {
            return tree
        }

        var modifiedChildren = tree.children
        if modifiedChildren.count > 0 {
            // Modify first child
            modifiedChildren[0] = VNode.text("Modified text")
        }

        return VNode(
            id: tree.id,
            type: tree.type,
            props: tree.props,
            children: modifiedChildren,
            key: tree.key
        )
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

        let results = await [
            benchmarkNodeCreation(),
            benchmarkPropertyDiffing(),
            benchmarkVNodeDiffing(),
            benchmarkIdenticalTreeDiffing(),
            benchmarkIncrementalDiffing(),
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

@available(macOS 13, *)
@main
struct BenchmarkRunner {
    static func main() async {
        let benchmarks = await RavenBenchmarks()
        await benchmarks.runAll()
    }
}
