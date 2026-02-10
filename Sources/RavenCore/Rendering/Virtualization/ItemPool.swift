import Foundation
import JavaScriptKit

/// Manages a pool of reusable VNodes and their corresponding DOM elements for virtual scrolling.
///
/// `ItemPool` optimizes rendering performance by recycling DOM nodes instead of creating
/// and destroying them repeatedly. It maintains a pool of inactive nodes that can be
/// reused when items scroll into view, significantly reducing garbage collection pressure
/// and DOM manipulation overhead.
///
/// The pool tracks:
/// - Active items currently visible in the viewport
/// - Inactive items available for reuse
/// - Item heights for accurate positioning
///
/// Example:
/// ```swift
/// let pool = ItemPool()
///
/// // Get or create an item for index 5
/// let item = pool.acquireItem(for: 5, create: {
///     // Create new VNode if needed
///     return VNode.element("div", children: [VNode.text("Item 5")])
/// })
///
/// // Release item when it scrolls out of view
/// pool.releaseItem(at: 5)
/// ```
@MainActor
public final class ItemPool: Sendable {

    // MARK: - Types

    /// Represents a pooled item with its associated metadata
    public struct PooledItem {
        /// The virtual DOM node
        public let vnode: VNode

        /// The actual DOM element (if rendered)
        public let element: JSObject?

        /// Index in the data collection
        public let index: Int

        /// Measured height of the item in pixels
        public var height: Double

        /// Timestamp when this item was last used
        public var lastUsed: TimeInterval

        public init(vnode: VNode, element: JSObject?, index: Int, height: Double) {
            self.vnode = vnode
            self.element = element
            self.index = index
            self.height = height
            self.lastUsed = Date().timeIntervalSince1970
        }
    }

    // MARK: - Properties

    /// Currently active (visible) items mapped by index
    private var activeItems: [Int: PooledItem] = [:]

    /// Pool of inactive items available for reuse
    private var inactivePool: [PooledItem] = []

    /// Cache of measured item heights mapped by index
    private var heightCache: [Int: Double] = [:]

    /// Default height to use for unmeasured items
    public var defaultItemHeight: Double = 44.0

    /// Maximum size of the inactive pool (prevents unbounded growth)
    public var maxPoolSize: Int = 50

    /// Total number of items currently managed (active + inactive)
    public var totalItems: Int {
        activeItems.count + inactivePool.count
    }

    /// Number of active (visible) items
    public var activeCount: Int {
        activeItems.count
    }

    /// Number of inactive (pooled) items
    public var inactiveCount: Int {
        inactivePool.count
    }

    // MARK: - Initialization

    public init(defaultItemHeight: Double = 44.0, maxPoolSize: Int = 50) {
        self.defaultItemHeight = defaultItemHeight
        self.maxPoolSize = maxPoolSize
    }

    // MARK: - Item Management

    /// Acquire an item for the specified index, creating it if necessary.
    ///
    /// This method first checks if the item is already active. If not, it attempts
    /// to reuse an item from the inactive pool. If the pool is empty, it creates
    /// a new item using the provided closure.
    ///
    /// - Parameters:
    ///   - index: Index in the data collection
    ///   - create: Closure to create a new VNode if needed
    /// - Returns: The pooled item for this index
    public func acquireItem(
        for index: Int,
        create: () -> VNode
    ) -> PooledItem {
        // Check if already active
        if let existing = activeItems[index] {
            return existing
        }

        // Try to reuse from pool
        let vnode: VNode
        let element: JSObject?

        if let pooled = inactivePool.popLast() {
            // Reuse from pool - create new VNode but could reuse element
            vnode = create()
            element = pooled.element
        } else {
            // Create new
            vnode = create()
            element = nil
        }

        // Get cached height or use default
        let height = heightCache[index] ?? defaultItemHeight

        let item = PooledItem(
            vnode: vnode,
            element: element,
            index: index,
            height: height
        )

        activeItems[index] = item
        return item
    }

    /// Release an item at the specified index, returning it to the pool.
    ///
    /// The item is moved from active to inactive status and becomes available
    /// for reuse. If the pool exceeds maxPoolSize, the oldest item is discarded.
    ///
    /// - Parameter index: Index of the item to release
    /// - Returns: The released item, or nil if not found
    @discardableResult
    public func releaseItem(at index: Int) -> PooledItem? {
        guard let item = activeItems.removeValue(forKey: index) else {
            return nil
        }

        // Add to inactive pool if under limit
        if inactivePool.count < maxPoolSize {
            var releasedItem = item
            releasedItem.lastUsed = Date().timeIntervalSince1970
            inactivePool.append(releasedItem)
        }
        // Otherwise discard (will be garbage collected)

        return item
    }

    /// Get an active item by index.
    ///
    /// - Parameter index: Index of the item
    /// - Returns: The active item, or nil if not active
    public func getActiveItem(at index: Int) -> PooledItem? {
        activeItems[index]
    }

    /// Check if an item is currently active.
    ///
    /// - Parameter index: Index to check
    /// - Returns: True if the item is active
    public func isActive(at index: Int) -> Bool {
        activeItems[index] != nil
    }

    /// Get all active item indices.
    ///
    /// - Returns: Array of indices for all active items
    public func getActiveIndices() -> [Int] {
        Array(activeItems.keys).sorted()
    }

    // MARK: - Height Management

    /// Update the measured height for an item.
    ///
    /// Call this after an item is rendered and its actual height is measured.
    /// The height is cached for future use.
    ///
    /// - Parameters:
    ///   - height: Measured height in pixels
    ///   - index: Index of the item
    public func updateHeight(_ height: Double, for index: Int) {
        heightCache[index] = height

        // Update active item if present
        if var item = activeItems[index] {
            item.height = height
            activeItems[index] = item
        }
    }

    /// Get the cached height for an item.
    ///
    /// - Parameter index: Index of the item
    /// - Returns: Cached height, or default height if not cached
    public func getHeight(for index: Int) -> Double {
        heightCache[index] ?? defaultItemHeight
    }

    /// Get the total estimated height for a range of items.
    ///
    /// - Parameter range: Range of indices
    /// - Returns: Sum of heights for all items in range
    public func getTotalHeight(for range: Range<Int>) -> Double {
        range.reduce(0.0) { sum, index in
            sum + getHeight(for: index)
        }
    }

    /// Clear all cached heights.
    ///
    /// Useful when item content changes significantly.
    public func clearHeightCache() {
        heightCache.removeAll()
    }

    // MARK: - Pool Management

    /// Clear all items from the pool.
    ///
    /// Removes both active and inactive items. Use with caution as this
    /// will cause all items to be recreated on next render.
    public func clear() {
        activeItems.removeAll()
        inactivePool.removeAll()
        heightCache.removeAll()
    }

    /// Trim the inactive pool to remove least recently used items.
    ///
    /// Reduces memory usage by removing old items from the pool.
    ///
    /// - Parameter maxAge: Maximum age in seconds for pooled items
    public func trimPool(maxAge: TimeInterval = 60.0) {
        let now = Date().timeIntervalSince1970
        inactivePool.removeAll { item in
            now - item.lastUsed > maxAge
        }
    }

    /// Resize the pool, removing excess items if necessary.
    ///
    /// - Parameter newSize: New maximum pool size
    public func resizePool(to newSize: Int) {
        maxPoolSize = newSize

        // Trim if current pool is larger
        if inactivePool.count > newSize {
            // Sort by last used time and keep newest
            inactivePool.sort { $0.lastUsed > $1.lastUsed }
            inactivePool = Array(inactivePool.prefix(newSize))
        }
    }

    /// Prefill the pool with a specified number of items.
    ///
    /// Useful for warming up the pool before scrolling begins.
    ///
    /// - Parameters:
    ///   - count: Number of items to prefill
    ///   - create: Closure to create VNodes
    public func prefill(count: Int, create: () -> VNode) {
        for _ in 0..<count {
            let vnode = create()
            let item = PooledItem(
                vnode: vnode,
                element: nil,
                index: -1, // Not associated with any index yet
                height: defaultItemHeight
            )
            inactivePool.append(item)
        }
    }

    // MARK: - Statistics

    /// Get statistics about the pool for debugging and optimization.
    ///
    /// - Returns: Dictionary with pool statistics
    public func getStatistics() -> [String: Any] {
        [
            "activeItems": activeItems.count,
            "inactiveItems": inactivePool.count,
            "cachedHeights": heightCache.count,
            "maxPoolSize": maxPoolSize,
            "defaultHeight": defaultItemHeight,
            "totalItems": totalItems
        ]
    }

    /// Calculate the average cached item height.
    ///
    /// - Returns: Average height, or default height if no items cached
    public func averageHeight() -> Double {
        guard !heightCache.isEmpty else {
            return defaultItemHeight
        }

        let sum = heightCache.values.reduce(0.0, +)
        return sum / Double(heightCache.count)
    }

    /// Get memory usage estimate in bytes.
    ///
    /// Rough estimate based on item counts and data structures.
    ///
    /// - Returns: Estimated memory usage in bytes
    public func estimatedMemoryUsage() -> Int {
        // Rough estimate: each item ~200 bytes, each cache entry ~16 bytes
        let itemMemory = totalItems * 200
        let cacheMemory = heightCache.count * 16
        return itemMemory + cacheMemory
    }
}

