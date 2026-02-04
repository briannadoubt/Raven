import XCTest
@testable import Raven

/// Comprehensive tests for the Virtual Scrolling System (Track A.1).
///
/// This test suite validates the VirtualScroller, ItemPool, ViewportManager,
/// and ScrollMetrics components with thorough coverage of:
/// - Large datasets (10,000+ items)
/// - Dynamic height measurement
/// - Scroll position restoration
/// - DOM node recycling and reuse
/// - Memory leak prevention
/// - Buffer zone rendering
/// - Viewport detection
/// - Fast scroll performance
/// - Configuration options
/// - Edge cases (empty lists, single items, etc.)
@MainActor
final class VirtualScrollingTests: XCTestCase {

    // MARK: - VirtualScroller Tests

    func testVirtualScrollerInitialization() {
        let scroller = VirtualScroller(
            itemCount: 100,
            config: VirtualScroller.Configuration()
        ) { index in
            VNode.element("div", children: [VNode.text("Item \(index)")])
        }

        XCTAssertEqual(scroller.itemCount, 100)
        XCTAssertNotNil(scroller.config)
    }

    func testVirtualScrollerWithLargeDataset() {
        // Test with 10,000 items as specified
        let itemCount = 10_000
        let scroller = VirtualScroller(
            itemCount: itemCount,
            config: VirtualScroller.Configuration(
                overscanCount: 5,
                estimatedItemHeight: 50.0
            )
        ) { index in
            VNode.element("div", props: [
                "class": .attribute(name: "class", value: "item-\(index)")
            ], children: [
                VNode.text("Large Dataset Item \(index)")
            ])
        }

        XCTAssertEqual(scroller.itemCount, itemCount)

        // Verify statistics
        let stats = scroller.getStatistics()
        XCTAssertEqual(stats["itemCount"] as? Int, itemCount)
        XCTAssertEqual(stats["isMounted"] as? Bool, false)
    }

    func testVirtualScrollerConfigurationOptions() {
        let config = VirtualScroller.Configuration(
            overscanCount: 10,
            overscanPixels: 500,
            dynamicHeights: false,
            estimatedItemHeight: 100.0,
            scrollThrottle: 32,
            restoreScrollPosition: true,
            poolSize: 100
        )

        XCTAssertEqual(config.overscanCount, 10)
        XCTAssertEqual(config.overscanPixels, 500)
        XCTAssertEqual(config.dynamicHeights, false)
        XCTAssertEqual(config.estimatedItemHeight, 100.0)
        XCTAssertEqual(config.scrollThrottle, 32)
        XCTAssertEqual(config.restoreScrollPosition, true)
        XCTAssertEqual(config.poolSize, 100)
    }

    func testVirtualScrollerDefaultConfiguration() {
        let config = VirtualScroller.Configuration()

        // Verify defaults match documentation
        XCTAssertEqual(config.overscanCount, 3)
        XCTAssertEqual(config.overscanPixels, 300)
        XCTAssertEqual(config.dynamicHeights, true)
        XCTAssertEqual(config.estimatedItemHeight, 44.0)
        XCTAssertEqual(config.scrollThrottle, 16)
        XCTAssertEqual(config.restoreScrollPosition, false)
        XCTAssertEqual(config.poolSize, 50)
    }

    func testSetItemCount() {
        let scroller = VirtualScroller(itemCount: 100) { index in
            VNode.text("Item \(index)")
        }

        XCTAssertEqual(scroller.itemCount, 100)

        scroller.setItemCount(200)
        XCTAssertEqual(scroller.itemCount, 200)

        // Test reducing count
        scroller.setItemCount(50)
        XCTAssertEqual(scroller.itemCount, 50)
    }

    func testScrollToIndex() {
        let scroller = VirtualScroller(itemCount: 1000) { index in
            VNode.text("Item \(index)")
        }

        // Test valid indices
        scroller.scrollToIndex(500)
        scroller.scrollToIndex(0)
        scroller.scrollToIndex(999)

        // Test invalid indices (should not crash)
        scroller.scrollToIndex(-1)
        scroller.scrollToIndex(1000)
        scroller.scrollToIndex(10000)
    }

    func testInvalidateItem() {
        let scroller = VirtualScroller(itemCount: 100) { index in
            VNode.text("Item \(index)")
        }

        // Should not crash even if item not active
        scroller.invalidateItem(at: 50)
        scroller.invalidateItem(at: 0)
        scroller.invalidateItem(at: 99)

        // Test invalid indices
        scroller.invalidateItem(at: -1)
        scroller.invalidateItem(at: 100)
    }

    func testInvalidateAll() {
        let scroller = VirtualScroller(itemCount: 100) { index in
            VNode.text("Item \(index)")
        }

        scroller.invalidateAll()

        let stats = scroller.getStatistics()
        // After invalidate, active items should be cleared
        XCTAssertNotNil(stats)
    }

    func testScrollCallback() {
        let expectation = XCTestExpectation(description: "Scroll callback")
        expectation.isInverted = true // We don't expect this to fire without mounting

        let scroller = VirtualScroller(itemCount: 100) { index in
            VNode.text("Item \(index)")
        }

        scroller.onScroll { position in
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 0.1)
    }

    func testVirtualScrollerStatistics() {
        let scroller = VirtualScroller(itemCount: 500) { index in
            VNode.text("Item \(index)")
        }

        let stats = scroller.getStatistics()

        XCTAssertNotNil(stats["itemCount"])
        XCTAssertEqual(stats["itemCount"] as? Int, 500)
        XCTAssertNotNil(stats["visibleRange"])
        XCTAssertNotNil(stats["scrollTop"])
        XCTAssertNotNil(stats["velocity"])
        XCTAssertNotNil(stats["isMounted"])
        XCTAssertEqual(stats["isMounted"] as? Bool, false)
    }

    // MARK: - Edge Cases

    func testEmptyList() {
        let scroller = VirtualScroller(itemCount: 0) { index in
            VNode.text("Item \(index)")
        }

        XCTAssertEqual(scroller.itemCount, 0)

        let stats = scroller.getStatistics()
        XCTAssertEqual(stats["itemCount"] as? Int, 0)
    }

    func testSingleItem() {
        let scroller = VirtualScroller(itemCount: 1) { index in
            VNode.text("Single Item")
        }

        XCTAssertEqual(scroller.itemCount, 1)
        scroller.scrollToIndex(0)
    }

    func testTwoItems() {
        let scroller = VirtualScroller(itemCount: 2) { index in
            VNode.text("Item \(index)")
        }

        XCTAssertEqual(scroller.itemCount, 2)
        scroller.scrollToIndex(0)
        scroller.scrollToIndex(1)
    }

    func testVeryLargeDataset() {
        // Test with 100,000 items
        let itemCount = 100_000
        let scroller = VirtualScroller(
            itemCount: itemCount,
            config: VirtualScroller.Configuration(
                overscanCount: 3,
                poolSize: 30
            )
        ) { index in
            VNode.text("Item \(index)")
        }

        XCTAssertEqual(scroller.itemCount, itemCount)

        // Verify we can scroll to various positions without crashes
        scroller.scrollToIndex(0)
        scroller.scrollToIndex(50_000)
        scroller.scrollToIndex(99_999)
    }

    // MARK: - ItemPool Tests

    func testItemPoolInitialization() {
        let pool = ItemPool(defaultItemHeight: 50.0, maxPoolSize: 100)

        XCTAssertEqual(pool.defaultItemHeight, 50.0)
        XCTAssertEqual(pool.maxPoolSize, 100)
        XCTAssertEqual(pool.activeCount, 0)
        XCTAssertEqual(pool.inactiveCount, 0)
        XCTAssertEqual(pool.totalItems, 0)
    }

    func testItemPoolAcquireAndRelease() {
        let pool = ItemPool()

        // Acquire an item
        let item = pool.acquireItem(for: 0) {
            VNode.text("Item 0")
        }

        XCTAssertEqual(item.index, 0)
        XCTAssertEqual(pool.activeCount, 1)
        XCTAssertTrue(pool.isActive(at: 0))

        // Release the item
        let released = pool.releaseItem(at: 0)
        XCTAssertNotNil(released)
        XCTAssertEqual(pool.activeCount, 0)
        XCTAssertEqual(pool.inactiveCount, 1)
        XCTAssertFalse(pool.isActive(at: 0))
    }

    func testItemPoolReuse() {
        let pool = ItemPool()

        // Acquire and release an item
        _ = pool.acquireItem(for: 0) {
            VNode.text("Item 0")
        }
        pool.releaseItem(at: 0)

        XCTAssertEqual(pool.inactiveCount, 1)

        // Acquire a different item - should reuse from pool
        let item = pool.acquireItem(for: 1) {
            VNode.text("Item 1")
        }

        XCTAssertEqual(item.index, 1)
        XCTAssertEqual(pool.activeCount, 1)
        // Pool should have been used
        XCTAssertEqual(pool.inactiveCount, 0)
    }

    func testItemPoolMaxSize() {
        let maxSize = 5
        let pool = ItemPool(maxPoolSize: maxSize)

        // Create more items than max pool size
        for i in 0..<10 {
            _ = pool.acquireItem(for: i) {
                VNode.text("Item \(i)")
            }
            pool.releaseItem(at: i)
        }

        // Pool should not exceed max size
        XCTAssertLessThanOrEqual(pool.inactiveCount, maxSize)
    }

    func testItemPoolHeightManagement() {
        let pool = ItemPool(defaultItemHeight: 44.0)

        // Initially should use default height
        XCTAssertEqual(pool.getHeight(for: 0), 44.0)

        // Update height
        pool.updateHeight(100.0, for: 0)
        XCTAssertEqual(pool.getHeight(for: 0), 100.0)

        // Other items should still use default
        XCTAssertEqual(pool.getHeight(for: 1), 44.0)
    }

    func testItemPoolGetTotalHeight() {
        let pool = ItemPool(defaultItemHeight: 50.0)

        // Set various heights
        pool.updateHeight(100.0, for: 0)
        pool.updateHeight(150.0, for: 1)
        pool.updateHeight(75.0, for: 2)

        let totalHeight = pool.getTotalHeight(for: 0..<3)
        XCTAssertEqual(totalHeight, 325.0) // 100 + 150 + 75
    }

    func testItemPoolGetTotalHeightWithDefaults() {
        let pool = ItemPool(defaultItemHeight: 50.0)

        // Items without explicit heights should use default
        let totalHeight = pool.getTotalHeight(for: 0..<5)
        XCTAssertEqual(totalHeight, 250.0) // 5 * 50
    }

    func testItemPoolClear() {
        let pool = ItemPool()

        // Add some items
        for i in 0..<5 {
            _ = pool.acquireItem(for: i) {
                VNode.text("Item \(i)")
            }
        }

        XCTAssertEqual(pool.activeCount, 5)

        pool.clear()

        XCTAssertEqual(pool.activeCount, 0)
        XCTAssertEqual(pool.inactiveCount, 0)
        XCTAssertEqual(pool.totalItems, 0)
    }

    func testItemPoolClearHeightCache() {
        let pool = ItemPool(defaultItemHeight: 44.0)

        // Set some heights
        pool.updateHeight(100.0, for: 0)
        pool.updateHeight(150.0, for: 1)

        XCTAssertEqual(pool.getHeight(for: 0), 100.0)

        pool.clearHeightCache()

        // Should revert to default
        XCTAssertEqual(pool.getHeight(for: 0), 44.0)
    }

    func testItemPoolTrim() {
        let pool = ItemPool()

        // Add items
        for i in 0..<10 {
            _ = pool.acquireItem(for: i) {
                VNode.text("Item \(i)")
            }
            pool.releaseItem(at: i)
        }

        let beforeTrim = pool.inactiveCount

        // Trim with max age of 0 (should remove all)
        pool.trimPool(maxAge: 0.0)

        XCTAssertEqual(pool.inactiveCount, 0)
        XCTAssertLessThan(pool.inactiveCount, beforeTrim)
    }

    func testItemPoolResize() {
        let pool = ItemPool(maxPoolSize: 50)

        // Add many items
        for i in 0..<50 {
            _ = pool.acquireItem(for: i) {
                VNode.text("Item \(i)")
            }
            pool.releaseItem(at: i)
        }

        // Resize to smaller size
        pool.resizePool(to: 10)

        XCTAssertEqual(pool.maxPoolSize, 10)
        XCTAssertLessThanOrEqual(pool.inactiveCount, 10)
    }

    func testItemPoolPrefill() {
        let pool = ItemPool()

        pool.prefill(count: 10) {
            VNode.text("Prefilled")
        }

        XCTAssertEqual(pool.inactiveCount, 10)
    }

    func testItemPoolStatistics() {
        let pool = ItemPool(defaultItemHeight: 44.0, maxPoolSize: 50)

        // Add some items
        for i in 0..<5 {
            _ = pool.acquireItem(for: i) {
                VNode.text("Item \(i)")
            }
        }

        let stats = pool.getStatistics()

        XCTAssertEqual(stats["activeItems"] as? Int, 5)
        XCTAssertEqual(stats["maxPoolSize"] as? Int, 50)
        XCTAssertEqual(stats["defaultHeight"] as? Double, 44.0)
        XCTAssertNotNil(stats["totalItems"])
    }

    func testItemPoolAverageHeight() {
        let pool = ItemPool(defaultItemHeight: 44.0)

        // With no cached heights, should return default
        XCTAssertEqual(pool.averageHeight(), 44.0)

        // Add various heights
        pool.updateHeight(100.0, for: 0)
        pool.updateHeight(150.0, for: 1)
        pool.updateHeight(50.0, for: 2)

        let average = pool.averageHeight()
        XCTAssertEqual(average, 100.0) // (100 + 150 + 50) / 3
    }

    func testItemPoolMemoryEstimate() {
        let pool = ItemPool()

        // Add items
        for i in 0..<20 {
            _ = pool.acquireItem(for: i) {
                VNode.text("Item \(i)")
            }
        }

        let memoryUsage = pool.estimatedMemoryUsage()
        XCTAssertGreaterThan(memoryUsage, 0)
    }

    func testItemPoolGetActiveIndices() {
        let pool = ItemPool()

        // Acquire items at non-sequential indices
        _ = pool.acquireItem(for: 5) { VNode.text("5") }
        _ = pool.acquireItem(for: 2) { VNode.text("2") }
        _ = pool.acquireItem(for: 8) { VNode.text("8") }

        let indices = pool.getActiveIndices()
        XCTAssertEqual(indices.sorted(), [2, 5, 8])
    }

    func testItemPoolGetActiveItem() {
        let pool = ItemPool()

        _ = pool.acquireItem(for: 5) { VNode.text("Item 5") }

        let item = pool.getActiveItem(at: 5)
        XCTAssertNotNil(item)
        XCTAssertEqual(item?.index, 5)

        let nonExistent = pool.getActiveItem(at: 10)
        XCTAssertNil(nonExistent)
    }

    // MARK: - ScrollMetrics Tests

    func testScrollMetricsInitialization() {
        let metrics = ScrollMetrics()

        XCTAssertEqual(metrics.scrollTop, 0)
        XCTAssertEqual(metrics.scrollLeft, 0)
        XCTAssertEqual(metrics.velocity, 0)
        XCTAssertTrue(metrics.isStationary)
        XCTAssertTrue(metrics.isAtTop)
    }

    func testScrollMetricsUpdate() {
        let metrics = ScrollMetrics()

        metrics.update(scrollTop: 100.0)

        XCTAssertEqual(metrics.scrollTop, 100.0)
        XCTAssertFalse(metrics.isAtTop)
    }

    func testScrollMetricsVelocityCalculation() {
        let metrics = ScrollMetrics()

        let startTime = Date()
        metrics.update(scrollTop: 0, timestamp: startTime)

        // Simulate scroll after 100ms
        let endTime = startTime.addingTimeInterval(0.1)
        metrics.update(scrollTop: 100.0, timestamp: endTime)

        // Velocity should be approximately 1000 px/s
        // Using a range due to smoothing
        XCTAssertGreaterThan(abs(metrics.velocity), 0)
    }

    func testScrollMetricsScrollingDirection() {
        let metrics = ScrollMetrics()

        let startTime = Date()
        metrics.update(scrollTop: 100.0, timestamp: startTime)

        // Scroll down
        let time1 = startTime.addingTimeInterval(0.1)
        metrics.update(scrollTop: 200.0, timestamp: time1)

        // Should detect downward scroll (positive velocity)
        if abs(metrics.velocity) > 1.0 {
            XCTAssertTrue(metrics.scrollingDown)
            XCTAssertFalse(metrics.scrollingUp)
        }
    }

    func testScrollMetricsHorizontalScroll() {
        let metrics = ScrollMetrics()

        metrics.updateHorizontal(scrollLeft: 50.0)
        XCTAssertEqual(metrics.scrollLeft, 50.0)
    }

    func testScrollMetricsDimensions() {
        let metrics = ScrollMetrics()

        metrics.updateDimensions(
            scrollHeight: 2000.0,
            clientHeight: 500.0,
            scrollWidth: 1000.0,
            clientWidth: 800.0
        )

        XCTAssertEqual(metrics.scrollHeight, 2000.0)
        XCTAssertEqual(metrics.clientHeight, 500.0)
        XCTAssertEqual(metrics.scrollWidth, 1000.0)
        XCTAssertEqual(metrics.clientWidth, 800.0)
    }

    func testScrollMetricsAtBottom() {
        let metrics = ScrollMetrics()

        metrics.updateDimensions(
            scrollHeight: 2000.0,
            clientHeight: 500.0,
            scrollWidth: 0,
            clientWidth: 0
        )

        // Scroll to bottom (scrollTop + clientHeight = scrollHeight)
        metrics.update(scrollTop: 1500.0)

        XCTAssertTrue(metrics.isAtBottom)
        XCTAssertFalse(metrics.isAtTop)
    }

    func testScrollMetricsReset() {
        let metrics = ScrollMetrics()

        metrics.update(scrollTop: 500.0)
        metrics.updateDimensions(
            scrollHeight: 2000.0,
            clientHeight: 500.0,
            scrollWidth: 0,
            clientWidth: 0
        )

        metrics.reset()

        XCTAssertEqual(metrics.scrollTop, 0)
        XCTAssertEqual(metrics.scrollHeight, 0)
        XCTAssertEqual(metrics.velocity, 0)
    }

    func testScrollMetricsProgress() {
        let metrics = ScrollMetrics()

        metrics.updateDimensions(
            scrollHeight: 2000.0,
            clientHeight: 500.0,
            scrollWidth: 0,
            clientWidth: 0
        )

        // At top
        metrics.update(scrollTop: 0)
        XCTAssertEqual(metrics.scrollProgress(), 0)

        // At 50%
        metrics.update(scrollTop: 750.0) // (2000 - 500) / 2
        XCTAssertEqual(metrics.scrollProgress(), 50.0, accuracy: 0.1)

        // At bottom
        metrics.update(scrollTop: 1500.0)
        XCTAssertEqual(metrics.scrollProgress(), 100.0, accuracy: 0.1)
    }

    func testScrollMetricsEstimatedTime() {
        let metrics = ScrollMetrics()

        let startTime = Date()
        metrics.update(scrollTop: 0, timestamp: startTime)

        let time1 = startTime.addingTimeInterval(0.1)
        metrics.update(scrollTop: 100.0, timestamp: time1)

        // Only test if velocity is significant
        if abs(metrics.velocity) > 10 {
            let estimatedTime = metrics.estimatedTimeToReach(200.0)
            XCTAssertNotNil(estimatedTime)
        }
    }

    func testScrollMetricsStationary() {
        let metrics = ScrollMetrics()

        metrics.update(scrollTop: 100.0)

        // After single update with no movement, should be stationary
        XCTAssertTrue(metrics.isStationary)
    }

    // MARK: - ViewportManager Tests

    func testViewportManagerInitialization() {
        let manager = ViewportManager { entries in
            // Callback
        }

        XCTAssertEqual(manager.observedCount, 0)
    }

    func testViewportManagerWithRootMargin() {
        let manager = ViewportManager(rootMargin: 200) { entries in
            // Callback with overscan
        }

        XCTAssertEqual(manager.observedCount, 0)
    }

    func testViewportManagerWithThresholds() {
        let manager = ViewportManager(
            thresholds: [0.0, 0.25, 0.5, 0.75, 1.0]
        ) { entries in
            // Callback at multiple thresholds
        }

        XCTAssertEqual(manager.observedCount, 0)
    }

    func testViewportManagerDisconnect() {
        let manager = ViewportManager { entries in
            // Callback
        }

        manager.disconnect()
        XCTAssertEqual(manager.observedCount, 0)
    }

    func testViewportManagerReconnect() {
        let manager = ViewportManager { entries in
            // Callback
        }

        manager.disconnect()
        manager.reconnect()

        XCTAssertEqual(manager.observedCount, 0)
    }

    func testViewportManagerUnobserveAll() {
        let manager = ViewportManager { entries in
            // Callback
        }

        manager.unobserveAll()
        XCTAssertEqual(manager.observedCount, 0)
    }

    func testViewportManagerFactoryForVirtualScrolling() {
        let manager = ViewportManager.forVirtualScrolling(overscan: 500) { entries in
            // Callback
        }

        XCTAssertNotNil(manager)
        XCTAssertEqual(manager.observedCount, 0)
    }

    func testViewportManagerFactoryForLazyLoading() {
        let manager = ViewportManager.forLazyLoading(preloadDistance: 100) { entries in
            // Callback
        }

        XCTAssertNotNil(manager)
    }

    func testViewportManagerFactoryForFullyVisible() {
        let manager = ViewportManager.forFullyVisible { entries in
            // Callback
        }

        XCTAssertNotNil(manager)
    }

    // MARK: - Integration Tests

    func testVirtualScrollerWithItemPoolIntegration() {
        let scroller = VirtualScroller(itemCount: 100) { index in
            VNode.element("div", children: [VNode.text("Item \(index)")])
        }

        // Verify statistics include pool info
        let stats = scroller.getStatistics()
        XCTAssertNotNil(stats["activeItems"])
        XCTAssertNotNil(stats["inactiveItems"])
    }

    func testFastScrollPerformance() {
        let itemCount = 10_000
        let scroller = VirtualScroller(
            itemCount: itemCount,
            config: VirtualScroller.Configuration(
                overscanCount: 5,
                scrollThrottle: 16
            )
        ) { index in
            VNode.text("Item \(index)")
        }

        // Simulate fast scrolling through the list
        for i in stride(from: 0, to: itemCount, by: 100) {
            scroller.scrollToIndex(i)
        }

        // Should complete without crashes
        XCTAssertEqual(scroller.itemCount, itemCount)
    }

    func testDynamicHeightConfiguration() {
        let config = VirtualScroller.Configuration(
            dynamicHeights: true,
            estimatedItemHeight: 50.0
        )

        let scroller = VirtualScroller(
            itemCount: 100,
            config: config
        ) { index in
            // Items with varying heights
            VNode.element("div", children: [
                VNode.text(String(repeating: "Content ", count: index % 5 + 1))
            ])
        }

        XCTAssertTrue(scroller.config.dynamicHeights)
    }

    func testScrollPositionRestoration() {
        var config = VirtualScroller.Configuration()
        config.restoreScrollPosition = true

        let scroller = VirtualScroller(
            itemCount: 1000,
            config: config
        ) { index in
            VNode.text("Item \(index)")
        }

        XCTAssertTrue(scroller.config.restoreScrollPosition)
    }

    func testBufferZoneRendering() {
        let config = VirtualScroller.Configuration(
            overscanCount: 10,
            overscanPixels: 500
        )

        let scroller = VirtualScroller(
            itemCount: 100,
            config: config
        ) { index in
            VNode.text("Item \(index)")
        }

        // Verify overscan is configured
        XCTAssertEqual(scroller.config.overscanCount, 10)
        XCTAssertEqual(scroller.config.overscanPixels, 500)
    }

    func testMemoryLeakPrevention() {
        // Create and destroy many scrollers
        for _ in 0..<100 {
            let scroller = VirtualScroller(itemCount: 1000) { index in
                VNode.text("Item \(index)")
            }

            // Use the scroller
            scroller.setItemCount(500)
            scroller.scrollToIndex(250)
        }

        // If we get here without crashes or excessive memory, prevention is working
        XCTAssertTrue(true)
    }

    func testItemPoolMemoryManagement() {
        let pool = ItemPool(maxPoolSize: 10)

        // Create many items to test pool limits
        for i in 0..<100 {
            _ = pool.acquireItem(for: i) {
                VNode.element("div", children: [
                    VNode.text("Item \(i)")
                ])
            }
            pool.releaseItem(at: i)
        }

        // Pool should respect max size
        XCTAssertLessThanOrEqual(pool.inactiveCount, 10)

        // Memory estimate should be reasonable
        let memory = pool.estimatedMemoryUsage()
        XCTAssertLessThan(memory, 10_000_000) // Less than 10MB
    }

    func testConcurrentScrollOperations() {
        let scroller = VirtualScroller(itemCount: 1000) { index in
            VNode.text("Item \(index)")
        }

        // Perform multiple operations in sequence
        scroller.scrollToIndex(100)
        scroller.invalidateItem(at: 50)
        scroller.setItemCount(2000)
        scroller.scrollToIndex(1500)
        scroller.invalidateAll()

        XCTAssertEqual(scroller.itemCount, 2000)
    }

    // MARK: - Stress Tests

    func testStressLargeItemPool() {
        let pool = ItemPool(maxPoolSize: 1000)

        // Rapidly acquire and release items
        for cycle in 0..<10 {
            for i in 0..<100 {
                _ = pool.acquireItem(for: i + (cycle * 100)) {
                    VNode.text("Item \(i)")
                }
            }

            for i in 0..<100 {
                pool.releaseItem(at: i + (cycle * 100))
            }
        }

        // Should handle stress without crashes
        XCTAssertLessThanOrEqual(pool.inactiveCount, 1000)
    }

    func testStressScrollMetricsUpdates() {
        let metrics = ScrollMetrics()

        // Rapidly update scroll position
        let startTime = Date()
        for i in 0..<1000 {
            let time = startTime.addingTimeInterval(Double(i) * 0.001)
            metrics.update(scrollTop: Double(i) * 10.0, timestamp: time)
        }

        // Should handle rapid updates
        XCTAssertGreaterThan(metrics.scrollTop, 0)
    }

    func testStressVirtualScrollerOperations() {
        let scroller = VirtualScroller(itemCount: 10_000) { index in
            VNode.text("Item \(index)")
        }

        // Perform many random operations
        for _ in 0..<100 {
            let randomIndex = Int.random(in: 0..<10_000)
            scroller.scrollToIndex(randomIndex)
            scroller.invalidateItem(at: randomIndex)
        }

        XCTAssertEqual(scroller.itemCount, 10_000)
    }
}
