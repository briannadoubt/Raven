import Foundation

/// Partitions VNode trees for parallel rendering across multiple workers.
///
/// `RenderPartition` implements intelligent tree splitting strategies to
/// distribute rendering work evenly while minimizing inter-worker dependencies
/// and maintaining cache locality.
///
/// ## Partitioning Strategies
///
/// - Depth-based: Split at fixed depth levels
/// - Size-based: Split when subtrees exceed size threshold
/// - Hybrid: Combines depth and size heuristics
/// - Work-balanced: Estimates work and balances load
///
/// ## Usage
///
/// ```swift
/// let partitioner = RenderPartition(workerCount: 4)
/// let partitions = partitioner.partition(rootNode: vnode)
///
/// for (index, partition) in partitions.enumerated() {
///     distributeToWorker(index, partition: partition)
/// }
/// ```
@MainActor
public struct RenderPartition: Sendable {

    // MARK: - Types

    /// A partition containing a subtree to be rendered
    public struct Partition: Sendable, Identifiable {
        /// Unique identifier
        public let id: UUID

        /// Root node of this partition
        public let root: VNode

        /// Estimated work units (node count)
        public let estimatedWork: Int

        /// Depth level in the original tree
        public let depth: Int

        /// Parent partition ID (if this is a child partition)
        public let parentID: UUID?

        /// Child partition IDs
        public let childIDs: [UUID]

        /// Dependency partition IDs (must complete before this)
        public let dependencyIDs: [UUID]

        /// Priority level
        public let priority: WorkerTask.Priority

        public init(
            id: UUID = UUID(),
            root: VNode,
            estimatedWork: Int,
            depth: Int,
            parentID: UUID? = nil,
            childIDs: [UUID] = [],
            dependencyIDs: [UUID] = [],
            priority: WorkerTask.Priority = .normal
        ) {
            self.id = id
            self.root = root
            self.estimatedWork = estimatedWork
            self.depth = depth
            self.parentID = parentID
            self.childIDs = childIDs
            self.dependencyIDs = dependencyIDs
            self.priority = priority
        }
    }

    /// Strategy for partitioning the tree
    public enum Strategy: Sendable {
        /// Split at fixed depth level
        case depth(level: Int)

        /// Split when subtrees exceed size
        case size(threshold: Int)

        /// Combine depth and size
        case hybrid(maxDepth: Int, minSize: Int, maxSize: Int)

        /// Balance work across workers
        case workBalanced(targetWork: Int)
    }

    /// Configuration for partitioning
    public struct Configuration: Sendable {
        /// Target number of partitions (typically worker count)
        public var targetPartitionCount: Int

        /// Partitioning strategy
        public var strategy: Strategy

        /// Minimum work units per partition
        public var minWorkPerPartition: Int

        /// Maximum work units per partition
        public var maxWorkPerPartition: Int

        /// Whether to respect component boundaries
        public var respectComponentBoundaries: Bool

        /// Maximum depth to traverse
        public var maxDepth: Int

        public init(
            targetPartitionCount: Int,
            strategy: Strategy = .hybrid(maxDepth: 3, minSize: 50, maxSize: 500),
            minWorkPerPartition: Int = 50,
            maxWorkPerPartition: Int = 1000,
            respectComponentBoundaries: Bool = true,
            maxDepth: Int = 100
        ) {
            self.targetPartitionCount = targetPartitionCount
            self.strategy = strategy
            self.minWorkPerPartition = minWorkPerPartition
            self.maxWorkPerPartition = maxWorkPerPartition
            self.respectComponentBoundaries = respectComponentBoundaries
            self.maxDepth = maxDepth
        }
    }

    // MARK: - Properties

    /// Partitioning configuration
    public let config: Configuration

    // MARK: - Initialization

    /// Initialize a render partitioner.
    ///
    /// - Parameters:
    ///   - workerCount: Number of available workers
    ///   - config: Optional custom configuration
    public init(workerCount: Int, config: Configuration? = nil) {
        if let config = config {
            self.config = config
        } else {
            self.config = Configuration(targetPartitionCount: workerCount)
        }
    }

    /// Initialize with explicit configuration.
    public init(config: Configuration) {
        self.config = config
    }

    // MARK: - Partitioning

    /// Partition a VNode tree for parallel rendering.
    ///
    /// Analyzes the tree structure and creates partitions suitable for
    /// distribution to workers.
    ///
    /// - Parameter root: Root VNode of the tree to partition
    /// - Returns: Array of partitions ready for distribution
    public func partition(root: VNode) -> [Partition] {
        switch config.strategy {
        case .depth(let level):
            return partitionByDepth(root: root, targetDepth: level)

        case .size(let threshold):
            return partitionBySize(root: root, threshold: threshold)

        case .hybrid(let maxDepth, let minSize, let maxSize):
            return partitionHybrid(root: root, maxDepth: maxDepth, minSize: minSize, maxSize: maxSize)

        case .workBalanced(let targetWork):
            return partitionWorkBalanced(root: root, targetWork: targetWork)
        }
    }

    // MARK: - Strategy Implementations

    /// Partition by depth level.
    ///
    /// Splits the tree at a fixed depth, creating one partition per subtree
    /// at that level.
    private func partitionByDepth(root: VNode, targetDepth: Int) -> [Partition] {
        var partitions: [Partition] = []
        var nextID: Int = 0

        func collectAtDepth(node: VNode, depth: Int, currentDepth: Int) {
            if currentDepth == depth {
                let work = estimateWork(node)
                let partition = Partition(
                    id: UUID(),
                    root: node,
                    estimatedWork: work,
                    depth: depth,
                    priority: .normal
                )
                partitions.append(partition)
                return
            }

            if currentDepth < depth {
                for child in node.children {
                    collectAtDepth(node: child, depth: depth, currentDepth: currentDepth + 1)
                }
            }
        }

        if targetDepth == 0 {
            // Single partition for entire tree
            let work = estimateWork(root)
            partitions.append(Partition(
                id: UUID(),
                root: root,
                estimatedWork: work,
                depth: 0,
                priority: .normal
            ))
        } else {
            collectAtDepth(node: root, depth: targetDepth, currentDepth: 0)
        }

        // If no partitions found at target depth, use root
        if partitions.isEmpty {
            let work = estimateWork(root)
            partitions.append(Partition(
                id: UUID(),
                root: root,
                estimatedWork: work,
                depth: 0,
                priority: .normal
            ))
        }

        return partitions
    }

    /// Partition by subtree size.
    ///
    /// Creates partitions when subtrees exceed the size threshold.
    private func partitionBySize(root: VNode, threshold: Int) -> [Partition] {
        var partitions: [Partition] = []

        func traverse(node: VNode, depth: Int) {
            let work = estimateWork(node)

            if work >= threshold {
                // Create partition for this subtree
                let partition = Partition(
                    id: UUID(),
                    root: node,
                    estimatedWork: work,
                    depth: depth,
                    priority: .normal
                )
                partitions.append(partition)
            } else {
                // Continue traversing children
                for child in node.children {
                    traverse(node: child, depth: depth + 1)
                }
            }
        }

        let rootWork = estimateWork(root)
        if rootWork < threshold {
            // Tree too small to partition
            partitions.append(Partition(
                id: UUID(),
                root: root,
                estimatedWork: rootWork,
                depth: 0,
                priority: .normal
            ))
        } else {
            traverse(node: root, depth: 0)
        }

        return partitions
    }

    /// Hybrid partitioning strategy.
    ///
    /// Combines depth and size constraints for balanced partitions.
    private func partitionHybrid(
        root: VNode,
        maxDepth: Int,
        minSize: Int,
        maxSize: Int
    ) -> [Partition] {
        var partitions: [Partition] = []

        func traverse(node: VNode, depth: Int, parentID: UUID? = nil) -> UUID? {
            let work = estimateWork(node)

            // Check if we should create a partition
            let shouldPartition = (depth >= maxDepth && work >= minSize) || work >= maxSize

            if shouldPartition {
                let partition = Partition(
                    id: UUID(),
                    root: node,
                    estimatedWork: work,
                    depth: depth,
                    parentID: parentID,
                    priority: depth < 2 ? .high : .normal
                )
                partitions.append(partition)
                return partition.id
            }

            // Continue traversing if we haven't hit limits
            if depth < config.maxDepth && work < maxSize {
                for child in node.children {
                    _ = traverse(node: child, depth: depth + 1, parentID: parentID)
                }
            } else if work < minSize {
                // Too small, but at max depth - create partition anyway
                let partition = Partition(
                    id: UUID(),
                    root: node,
                    estimatedWork: work,
                    depth: depth,
                    parentID: parentID,
                    priority: .normal
                )
                partitions.append(partition)
                return partition.id
            }

            return nil
        }

        let rootWork = estimateWork(root)
        if rootWork < minSize || config.targetPartitionCount == 1 {
            // Single partition
            partitions.append(Partition(
                id: UUID(),
                root: root,
                estimatedWork: rootWork,
                depth: 0,
                priority: .high
            ))
        } else {
            _ = traverse(node: root, depth: 0)

            // Ensure we have at least one partition
            if partitions.isEmpty {
                partitions.append(Partition(
                    id: UUID(),
                    root: root,
                    estimatedWork: rootWork,
                    depth: 0,
                    priority: .high
                ))
            }
        }

        return partitions
    }

    /// Work-balanced partitioning strategy.
    ///
    /// Creates partitions with approximately equal work distribution.
    private func partitionWorkBalanced(root: VNode, targetWork: Int) -> [Partition] {
        var partitions: [Partition] = []
        var currentBatch: [VNode] = []
        var currentWork = 0

        func traverse(node: VNode, depth: Int) {
            let nodeWork = estimateWork(node)

            if currentWork + nodeWork <= targetWork {
                currentBatch.append(node)
                currentWork += nodeWork
            } else {
                // Flush current batch
                if !currentBatch.isEmpty {
                    let batchRoot = createBatchRoot(nodes: currentBatch)
                    partitions.append(Partition(
                        id: UUID(),
                        root: batchRoot,
                        estimatedWork: currentWork,
                        depth: depth,
                        priority: .normal
                    ))
                }

                // Start new batch
                currentBatch = [node]
                currentWork = nodeWork
            }

            // Traverse children if node is small enough
            if nodeWork < targetWork / 2 {
                for child in node.children {
                    traverse(node: child, depth: depth + 1)
                }
            }
        }

        traverse(node: root, depth: 0)

        // Flush remaining batch
        if !currentBatch.isEmpty {
            let batchRoot = createBatchRoot(nodes: currentBatch)
            partitions.append(Partition(
                id: UUID(),
                root: batchRoot,
                estimatedWork: currentWork,
                depth: 0,
                priority: .normal
            ))
        }

        return partitions
    }

    // MARK: - Work Estimation

    /// Estimate work units for a VNode subtree.
    ///
    /// Work estimation considers:
    /// - Node count
    /// - Node type complexity
    /// - Depth
    ///
    /// - Parameter node: Root node to estimate
    /// - Returns: Estimated work units
    private func estimateWork(_ node: VNode) -> Int {
        var work = 0

        func traverse(_ node: VNode, depth: Int) {
            // Base cost per node
            work += 1

            // Additional cost based on node type
            switch node.type {
            case .element:
                work += 2 + node.props.count
            case .text:
                work += 1
            case .component:
                work += 5  // Components are more expensive
            case .fragment:
                work += 0  // Fragments are cheap
            }

            // Traverse children
            for child in node.children {
                traverse(child, depth: depth + 1)
            }
        }

        traverse(node, depth: 0)
        return work
    }

    /// Create a synthetic root node for a batch of nodes.
    private func createBatchRoot(nodes: [VNode]) -> VNode {
        return VNode.fragment(children: nodes)
    }

    // MARK: - Analysis

    /// Analyze partitioning quality.
    ///
    /// Returns statistics about work distribution.
    public func analyzePartitions(_ partitions: [Partition]) -> PartitionStatistics {
        let totalWork = partitions.reduce(0) { $0 + $1.estimatedWork }
        let avgWork = totalWork / max(1, partitions.count)
        let maxWork = partitions.map(\.estimatedWork).max() ?? 0
        let minWork = partitions.map(\.estimatedWork).min() ?? 0

        let variance = partitions.reduce(0.0) { sum, partition in
            let diff = Double(partition.estimatedWork - avgWork)
            return sum + (diff * diff)
        } / Double(max(1, partitions.count))

        let stdDev = sqrt(variance)
        let balance = minWork > 0 ? Double(maxWork) / Double(minWork) : Double.infinity

        return PartitionStatistics(
            totalWork: totalWork,
            averageWork: avgWork,
            maxWork: maxWork,
            minWork: minWork,
            standardDeviation: stdDev,
            balanceFactor: balance,
            partitionCount: partitions.count
        )
    }
}

// MARK: - Statistics

/// Statistics about partition quality
public struct PartitionStatistics: Sendable {
    /// Total work units across all partitions
    public let totalWork: Int

    /// Average work units per partition
    public let averageWork: Int

    /// Maximum work in any partition
    public let maxWork: Int

    /// Minimum work in any partition
    public let minWork: Int

    /// Standard deviation of work distribution
    public let standardDeviation: Double

    /// Balance factor (maxWork / minWork, lower is better, 1.0 is perfect)
    public let balanceFactor: Double

    /// Number of partitions
    public let partitionCount: Int

    /// Whether partitioning is well-balanced (balance factor < 2.0)
    public var isWellBalanced: Bool {
        return balanceFactor < 2.0
    }

    /// Efficiency score (0.0 to 1.0, higher is better)
    public var efficiency: Double {
        if balanceFactor.isInfinite {
            return 0.0
        }
        return 1.0 / balanceFactor
    }
}

// MARK: - Partition Graph

/// Represents dependencies between partitions for execution ordering.
///
/// Used by the scheduler to respect rendering order and dependencies.
@MainActor
public final class PartitionGraph: Sendable {
    private var nodes: [UUID: RenderPartition.Partition]
    private var edges: [UUID: Set<UUID>]

    public init(partitions: [RenderPartition.Partition]) {
        self.nodes = [:]
        self.edges = [:]

        for partition in partitions {
            nodes[partition.id] = partition
            edges[partition.id] = Set(partition.dependencyIDs)
        }
    }

    /// Get partitions in topological order (respecting dependencies).
    public func topologicalOrder() -> [RenderPartition.Partition] {
        var result: [RenderPartition.Partition] = []
        var visited = Set<UUID>()
        var visiting = Set<UUID>()

        func visit(_ id: UUID) {
            if visited.contains(id) {
                return
            }

            if visiting.contains(id) {
                // Cycle detected - break it
                return
            }

            visiting.insert(id)

            // Visit dependencies first
            if let deps = edges[id] {
                for depID in deps {
                    visit(depID)
                }
            }

            visiting.remove(id)
            visited.insert(id)

            if let partition = nodes[id] {
                result.append(partition)
            }
        }

        for id in nodes.keys {
            visit(id)
        }

        return result
    }

    /// Get partitions ready to execute (no pending dependencies).
    public func readyPartitions(completed: Set<UUID>) -> [RenderPartition.Partition] {
        var ready: [RenderPartition.Partition] = []

        for (id, partition) in nodes {
            if completed.contains(id) {
                continue
            }

            let dependencies = edges[id] ?? []
            let allDepsCompleted = dependencies.allSatisfy { completed.contains($0) }

            if allDepsCompleted {
                ready.append(partition)
            }
        }

        return ready.sorted { $0.priority > $1.priority }
    }
}
