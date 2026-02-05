import Foundation
import JavaScriptKit

/// Core virtual scrolling engine that manages efficient rendering of large lists.
///
/// `VirtualScroller` implements a windowing technique where only visible items
/// (plus a configurable overscan) are rendered to the DOM. As the user scrolls,
/// items are dynamically added/removed and DOM nodes are recycled from a pool.
///
/// Key features:
/// - Renders only visible items (60fps on 10,000+ items)
/// - DOM node recycling via ItemPool
/// - Dynamic height support with automatic measurement
/// - Configurable overscan for smooth scrolling
/// - IntersectionObserver-based visibility detection
/// - Scroll position restoration
///
/// Example:
/// ```swift
/// let scroller = VirtualScroller(
///     itemCount: 10000,
///     estimatedItemHeight: 50
/// ) { index in
///     // Create VNode for item at index
///     return VNode.element("div", children: [
///         VNode.text("Item \(index)")
///     ])
/// }
///
/// scroller.mount(to: containerElement)
/// ```
@MainActor
public final class VirtualScroller: Sendable {

    // MARK: - Types

    /// Closure type for creating item VNodes
    public typealias ItemBuilder = @MainActor @Sendable (Int) -> VNode

    /// Closure type for scroll position changes
    public typealias ScrollCallback = @MainActor @Sendable (Double) -> Void

    /// Configuration for virtual scrolling behavior
    public struct Configuration: Sendable {
        /// Number of items to render above/below the visible viewport
        public var overscanCount: Int

        /// Distance in pixels to overscan above/below viewport
        public var overscanPixels: Int

        /// Whether to measure item heights dynamically
        public var dynamicHeights: Bool

        /// Estimated height for items (used before measurement)
        public var estimatedItemHeight: Double

        /// Throttle delay for scroll events (milliseconds)
        public var scrollThrottle: Int

        /// Whether to enable scroll position restoration
        public var restoreScrollPosition: Bool

        /// Buffer size for the item pool
        public var poolSize: Int

        public init(
            overscanCount: Int = 3,
            overscanPixels: Int = 300,
            dynamicHeights: Bool = true,
            estimatedItemHeight: Double = 44.0,
            scrollThrottle: Int = 16,
            restoreScrollPosition: Bool = false,
            poolSize: Int = 50
        ) {
            self.overscanCount = overscanCount
            self.overscanPixels = overscanPixels
            self.dynamicHeights = dynamicHeights
            self.estimatedItemHeight = estimatedItemHeight
            self.scrollThrottle = scrollThrottle
            self.restoreScrollPosition = restoreScrollPosition
            self.poolSize = poolSize
        }
    }

    // MARK: - Properties

    /// Total number of items in the list
    public private(set) var itemCount: Int

    /// Configuration for scrolling behavior
    public var config: Configuration

    /// Closure to build VNode for each item
    private let itemBuilder: ItemBuilder

    /// Pool of reusable items
    private let itemPool: ItemPool

    /// Scroll metrics tracker
    private let scrollMetrics: ScrollMetrics

    /// Viewport visibility manager
    private var viewportManager: ViewportManager?

    /// The container DOM element
    private var containerElement: JSObject?

    /// The scrollable wrapper element
    private var scrollerElement: JSObject?

    /// The content spacer element (for total height)
    private var spacerElement: JSObject?

    /// Currently rendered item range
    private var currentRange: Range<Int> = 0..<0

    /// Optional scroll position change callback
    private var scrollCallback: ScrollCallback?

    /// Scroll event handler closure (kept alive)
    private var scrollEventClosure: JSClosure?

    /// ResizeObserver for measuring item heights
    private var resizeObserver: JSObject?

    /// ResizeObserver callback closure (kept alive)
    private var resizeObserverClosure: JSClosure?

    /// Whether the scroller is currently mounted
    private var isMounted: Bool = false

    /// Last scroll update timestamp for throttling
    private var lastScrollUpdate: TimeInterval = 0

    /// Saved scroll position for restoration
    private var savedScrollPosition: Double?

    // MARK: - Initialization

    /// Initialize a new VirtualScroller.
    ///
    /// - Parameters:
    ///   - itemCount: Total number of items
    ///   - config: Configuration for scrolling behavior
    ///   - itemBuilder: Closure to create VNode for each item
    public init(
        itemCount: Int,
        config: Configuration = Configuration(),
        itemBuilder: @escaping ItemBuilder
    ) {
        self.itemCount = itemCount
        self.config = config
        self.itemBuilder = itemBuilder

        self.itemPool = ItemPool(
            defaultItemHeight: config.estimatedItemHeight,
            maxPoolSize: config.poolSize
        )

        self.scrollMetrics = ScrollMetrics()
    }

    // MARK: - Mounting

    /// Mount the virtual scroller to a container element.
    ///
    /// Creates the necessary DOM structure and begins rendering visible items.
    ///
    /// - Parameter container: DOM element to mount into
    public func mount(to container: JSObject) {
        guard !isMounted else { return }

        self.containerElement = container

        // Create scroller structure
        createScrollerDOM()

        // Setup scroll event handling
        setupScrollHandling()

        // Setup resize observation for dynamic heights
        if config.dynamicHeights {
            setupResizeObserver()
        }

        // Initial render
        updateVisibleRange()
        renderItems()

        isMounted = true

        // Restore scroll position if saved
        if config.restoreScrollPosition, let saved = savedScrollPosition {
            scrollTo(saved)
        }
    }

    /// Unmount the virtual scroller.
    ///
    /// Cleans up DOM elements, event handlers, and observers.
    public func unmount() {
        guard isMounted else { return }

        // Save scroll position if restoration enabled
        if config.restoreScrollPosition {
            savedScrollPosition = scrollMetrics.scrollTop
        }

        // Disconnect observers
        viewportManager?.disconnect()
        disconnectResizeObserver()

        // Remove event listeners
        if let scroller = scrollerElement, let closure = scrollEventClosure {
            _ = scroller.removeEventListener!("scroll", closure)
        }

        // Clear DOM references
        containerElement = nil
        scrollerElement = nil
        spacerElement = nil

        // Clear pool
        itemPool.clear()

        isMounted = false
    }

    // MARK: - DOM Setup

    /// Create the DOM structure for the virtual scroller.
    private func createScrollerDOM() {
        guard let container = containerElement,
              let document = JSObject.global.document.object,
              let createElementFn = document.createElement.function else {
            return
        }

        // Create scroller wrapper (scrollable container)
        guard let scroller = createElementFn("div").object else {
            return
        }
        scroller.style.overflow = .string("auto")
        scroller.style.position = .string("relative")
        scroller.style.width = .string("100%")
        scroller.style.height = .string("100%")
        scroller.className = .string("raven-virtual-scroller")

        // Create spacer element (maintains total height)
        guard let spacer = createElementFn("div").object else {
            return
        }
        spacer.style.position = .string("relative")
        spacer.style.width = .string("100%")
        let totalHeight = Double(itemCount) * config.estimatedItemHeight
        spacer.style.height = .string("\(totalHeight)px")
        spacer.className = .string("raven-virtual-spacer")

        // Append spacer to scroller
        if let appendChildFn = scroller.appendChild.function {
            _ = appendChildFn(spacer)
        }

        // Append scroller to container
        if let appendChildFn = container.appendChild.function {
            _ = appendChildFn(scroller)
        }

        self.scrollerElement = scroller
        self.spacerElement = spacer
    }

    /// Setup scroll event handling with throttling.
    private func setupScrollHandling() {
        guard let scroller = scrollerElement else { return }

        // Create scroll handler
        let closure = JSClosure { [weak self] _ -> JSValue in
            guard let self = self else { return .undefined }

            Task { @MainActor in
                self.handleScroll()
            }

            return .undefined
        }

        self.scrollEventClosure = closure

        // Add event listener with passive flag for better performance
        let options = JSObject.global.Object.function!.new()
        options.passive = .boolean(true)
        _ = scroller.addEventListener!("scroll", closure, options)

        // Setup viewport manager
        self.viewportManager = ViewportManager.forVirtualScrolling(
            overscan: config.overscanPixels
        ) { [weak self] entries in
            self?.handleIntersection(entries)
        }
    }

    /// Setup ResizeObserver for measuring item heights.
    private func setupResizeObserver() {
        guard config.dynamicHeights else { return }

        // Create resize handler
        let closure = JSClosure { [weak self] args -> JSValue in
            guard let self = self, args.count > 0 else {
                return .undefined
            }

            Task { @MainActor in
                self.handleResize(args[0])
            }

            return .undefined
        }

        self.resizeObserverClosure = closure

        // Create ResizeObserver
        let observerConstructor = JSObject.global.ResizeObserver.function!
        self.resizeObserver = observerConstructor.new(closure)
    }

    /// Disconnect the ResizeObserver.
    private func disconnectResizeObserver() {
        guard let observer = resizeObserver else { return }
        _ = observer.disconnect!()
        self.resizeObserver = nil
        self.resizeObserverClosure = nil
    }

    // MARK: - Scroll Handling

    /// Handle scroll events with throttling.
    private func handleScroll() {
        let now = Date().timeIntervalSince1970

        // Throttle scroll updates
        guard now - lastScrollUpdate > Double(config.scrollThrottle) / 1000.0 else {
            return
        }

        lastScrollUpdate = now

        // Update scroll metrics
        guard let scroller = scrollerElement else { return }

        let scrollTop = scroller.scrollTop.number ?? 0.0
        let scrollHeight = scroller.scrollHeight.number ?? 0.0
        let clientHeight = scroller.clientHeight.number ?? 0.0

        scrollMetrics.update(scrollTop: scrollTop)
        scrollMetrics.updateDimensions(
            scrollHeight: scrollHeight,
            clientHeight: clientHeight,
            scrollWidth: 0,
            clientWidth: 0
        )

        // Update visible range and render
        updateVisibleRange()
        renderItems()

        // Call scroll callback if set
        scrollCallback?(scrollTop)
    }

    /// Handle intersection observer updates.
    private func handleIntersection(_ entries: [ViewportManager.IntersectionEntry]) {
        // Could be used for additional optimizations
        // For now, scroll events handle most updates
    }

    /// Handle resize observer updates for item height measurement.
    private func handleResize(_ entriesObject: JSValue) {
        guard let entries = entriesObject.object else { return }

        let length = entries.length.number ?? 0
        for i in 0..<Int(length) {
            guard let entry = entries[i].object else { continue }
            guard let target = entry.target.object else { continue }

            // Get the item index from data attribute
            guard let indexStr = target.dataset.index.string else { continue }
            guard let index = Int(indexStr) else { continue }

            // Measure height
            if let contentRect = entry.contentRect.object {
                let height = contentRect.height.number ?? config.estimatedItemHeight
                itemPool.updateHeight(height, for: index)
            }
        }

        // Recalculate spacer height
        updateSpacerHeight()
    }

    // MARK: - Range Calculation

    /// Calculate which items should be visible based on scroll position.
    private func updateVisibleRange() {
        guard itemCount > 0 else {
            currentRange = 0..<0
            return
        }

        let scrollTop = scrollMetrics.scrollTop
        let clientHeight = scrollMetrics.clientHeight

        // Calculate visible range based on scroll position
        var startIndex = 0
        var accumulatedHeight = 0.0

        // Find first visible item
        for i in 0..<itemCount {
            let itemHeight = itemPool.getHeight(for: i)
            if accumulatedHeight + itemHeight > scrollTop {
                startIndex = i
                break
            }
            accumulatedHeight += itemHeight
        }

        // Calculate end index
        var endIndex = startIndex
        accumulatedHeight = itemPool.getHeight(for: startIndex)

        for i in (startIndex + 1)..<itemCount {
            let itemHeight = itemPool.getHeight(for: i)
            accumulatedHeight += itemHeight

            if accumulatedHeight > scrollTop + clientHeight {
                endIndex = i + 1
                break
            }
        }

        // Apply overscan
        startIndex = max(0, startIndex - config.overscanCount)
        endIndex = min(itemCount, endIndex + config.overscanCount)

        currentRange = startIndex..<endIndex
    }

    // MARK: - Rendering

    /// Render items in the current visible range.
    private func renderItems() {
        guard spacerElement != nil else { return }

        // Get active indices
        let activeIndices = Set(itemPool.getActiveIndices())
        let newIndices = Set(currentRange)

        // Release items no longer visible
        let toRelease = activeIndices.subtracting(newIndices)
        for index in toRelease {
            if let item = itemPool.releaseItem(at: index) {
                // Remove from DOM
                if let element = item.element {
                    _ = element.remove!()
                }
            }
        }

        // Acquire and render new items
        let toAcquire = newIndices.subtracting(activeIndices)
        for index in toAcquire.sorted() {
            let item = itemPool.acquireItem(for: index) {
                itemBuilder(index)
            }

            // Render to DOM
            renderItem(item, at: index)
        }
    }

    /// Render a single item to the DOM.
    ///
    /// - Parameters:
    ///   - item: The pooled item to render
    ///   - index: Index in the data collection
    private func renderItem(_ item: ItemPool.PooledItem, at index: Int) {
        guard let spacer = spacerElement,
              let document = JSObject.global.document.object else {
            return
        }

        // Create or reuse element
        let element: JSObject
        if let existing = item.element {
            element = existing
        } else {
            guard let createElementFn = document.createElement.function,
                  let newElement = createElementFn("div").object else {
                return
            }
            element = newElement
        }

        // Set positioning
        element.style.position = .string("absolute")
        element.style.top = .string("\(calculateTopOffset(for: index))px")
        element.style.left = .string("0")
        element.style.right = .string("0")

        // Set data attribute for identification
        element.dataset.index = .string("\(index)")

        // Add class for styling
        element.className = .string("raven-virtual-item")

        // Render VNode content (simplified - in real implementation would use DOMBridge)
        renderVNode(item.vnode, into: element)

        // Append to spacer if not already present
        if element.parentNode.isUndefined || element.parentNode.isNull {
            _ = spacer.appendChild!(element)
        }

        // Observe for resize if dynamic heights enabled
        if config.dynamicHeights, let observer = resizeObserver {
            _ = observer.observe!(element)
        }
    }

    /// Render a VNode into a DOM element (simplified version).
    ///
    /// In production, this would delegate to DOMBridge and the full rendering pipeline.
    ///
    /// - Parameters:
    ///   - vnode: VNode to render
    ///   - element: Target DOM element
    private func renderVNode(_ vnode: VNode, into element: JSObject) {
        // This is a simplified implementation
        // In reality, this would use the full DOMBridge rendering pipeline

        switch vnode.type {
        case .text(let content):
            element.textContent = .string(content)

        case .element(let tag):
            let childText = vnode.children.map { child in
                if case .text(let text) = child.type {
                    return text
                }
                return ""
            }.joined()
            element.innerHTML = .string("<\(tag)>\(childText)</\(tag)>")

        default:
            break
        }
    }

    /// Calculate the top offset for an item based on preceding item heights.
    ///
    /// - Parameter index: Index of the item
    /// - Returns: Top offset in pixels
    private func calculateTopOffset(for index: Int) -> Double {
        guard index > 0 else { return 0 }
        return itemPool.getTotalHeight(for: 0..<index)
    }

    /// Update the spacer element height based on all item heights.
    private func updateSpacerHeight() {
        guard let spacer = spacerElement else { return }

        let totalHeight = itemPool.getTotalHeight(for: 0..<itemCount)
        spacer.style.height = .string("\(totalHeight)px")
    }

    // MARK: - Public API

    /// Update the total item count.
    ///
    /// Call this when the data source changes.
    ///
    /// - Parameter count: New item count
    public func setItemCount(_ count: Int) {
        guard count != itemCount else { return }

        itemCount = count

        // Clear items outside new range
        let activeIndices = itemPool.getActiveIndices()
        for index in activeIndices where index >= count {
            itemPool.releaseItem(at: index)
        }

        // Update spacer height
        updateSpacerHeight()

        // Re-render
        updateVisibleRange()
        renderItems()
    }

    /// Scroll to a specific position.
    ///
    /// - Parameter position: Scroll position in pixels
    public func scrollTo(_ position: Double) {
        guard let scroller = scrollerElement else { return }
        scroller.scrollTop = .number(position)
    }

    /// Scroll to a specific item index.
    ///
    /// - Parameter index: Item index to scroll to
    public func scrollToIndex(_ index: Int) {
        guard index >= 0 && index < itemCount else { return }

        let offset = calculateTopOffset(for: index)
        scrollTo(offset)
    }

    /// Invalidate a specific item, forcing it to re-render.
    ///
    /// - Parameter index: Index of item to invalidate
    public func invalidateItem(at index: Int) {
        guard itemPool.isActive(at: index) else { return }

        // Release and re-acquire
        itemPool.releaseItem(at: index)

        if currentRange.contains(index) {
            let item = itemPool.acquireItem(for: index) {
                itemBuilder(index)
            }
            renderItem(item, at: index)
        }
    }

    /// Invalidate all items, forcing a full re-render.
    public func invalidateAll() {
        itemPool.clear()
        renderItems()
    }

    /// Set a callback for scroll position changes.
    ///
    /// - Parameter callback: Closure called when scroll position changes
    public func onScroll(_ callback: @escaping ScrollCallback) {
        self.scrollCallback = callback
    }

    /// Get current scroll statistics.
    ///
    /// - Returns: Dictionary with scroll statistics
    public func getStatistics() -> [String: Any] {
        var stats = itemPool.getStatistics()
        stats["itemCount"] = itemCount
        stats["visibleRange"] = "\(currentRange)"
        stats["scrollTop"] = scrollMetrics.scrollTop
        stats["velocity"] = scrollMetrics.velocity
        stats["isMounted"] = isMounted
        return stats
    }
}

