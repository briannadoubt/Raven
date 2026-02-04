# Virtual Scrolling System

High-performance virtual scrolling implementation for Raven, enabling smooth 60fps rendering of lists with 10,000+ items.

## Overview

The virtual scrolling system uses windowing techniques to render only visible items, dramatically reducing DOM node count and improving performance for large collections. It combines:

- **Viewport windowing**: Only render items within the visible viewport (plus overscan)
- **DOM node recycling**: Reuse DOM elements via ItemPool instead of creating/destroying
- **Dynamic height support**: Automatically measure and cache item heights
- **IntersectionObserver**: Browser-native viewport detection for optimal performance

## Architecture

```
VirtualScroller (Core Engine)
├── ViewportManager (IntersectionObserver wrapper)
├── ItemPool (VNode/DOM reuse pool)
└── ScrollMetrics (Position/velocity tracking)
```

### Key Components

#### VirtualScroller.swift (~400 lines)
The core engine that orchestrates virtual scrolling:
- Calculates visible item range based on scroll position
- Manages item lifecycle (acquire/release)
- Handles scroll events with throttling
- Integrates ResizeObserver for dynamic heights
- Provides public API for configuration and control

#### ViewportManager.swift (~200 lines)
Swift wrapper around IntersectionObserver API:
- Efficient viewport visibility detection
- Configurable root margin for overscan
- Multiple threshold support
- Factory methods for common use cases
- Proper lifecycle management and cleanup

#### ItemPool.swift (~150 lines)
Manages reusable VNode and DOM element pool:
- Active/inactive item tracking
- Height caching per item
- Configurable pool size with LRU eviction
- Statistics and memory usage tracking
- Prefill capability for smooth initial render

#### ScrollMetrics.swift (~100 lines)
Tracks scroll position and velocity:
- Real-time position updates
- Velocity calculation with smoothing
- Scroll direction detection
- Viewport dimension tracking
- Progress calculation and time estimation

#### VirtualizedModifier.swift (~150 lines)
SwiftUI-style modifier API:
- `.virtualized()` view modifier
- Configuration options for common use cases
- Integration with List, LazyVGrid, LazyHGrid
- Static factory methods for convenience

## Usage

### Basic Usage

```swift
// Simple virtualized list
List(0..<10000) { index in
    Text("Item \(index)")
}
.virtualized()
```

### Custom Configuration

```swift
List(largeDataset) { item in
    ComplexItemView(item: item)
}
.virtualized(
    estimatedItemHeight: 120,
    overscan: 5,
    dynamicHeights: true
)
```

### Advanced Configuration

```swift
let config = VirtualScroller.Configuration(
    overscanCount: 5,
    overscanPixels: 500,
    dynamicHeights: true,
    estimatedItemHeight: 80,
    scrollThrottle: 16,
    restoreScrollPosition: true,
    poolSize: 100
)

List(items) { item in
    ItemRow(item: item)
}
.virtualized(config: config)
```

### Direct Scroller API

```swift
let scroller = VirtualScroller(
    itemCount: 10000,
    estimatedItemHeight: 50
) { index in
    // Return VNode for item at index
    VNode.element("div", children: [
        VNode.text("Item \(index)")
    ])
}

scroller.mount(to: containerElement)
scroller.scrollToIndex(500)
scroller.onScroll { position in
    print("Scrolled to: \(position)")
}
```

## Performance Characteristics

### Target Performance
- **60fps** on 10,000+ items
- **<16ms** frame time for smooth scrolling
- **<100ms** initial render time
- **<50MB** memory overhead for 10,000 items

### Optimizations
1. **Windowing**: Only render visible + overscan items
2. **DOM Recycling**: Reuse elements instead of create/destroy
3. **Throttling**: Scroll events throttled to 16ms (60fps)
4. **IntersectionObserver**: Hardware-accelerated visibility detection
5. **Height Caching**: Avoid re-measurement of known heights
6. **Passive Event Listeners**: Non-blocking scroll handling

### Benchmarks (Expected)

| Item Count | DOM Nodes | Memory | Scroll FPS | Initial Render |
|------------|-----------|--------|------------|----------------|
| 100        | ~110      | 5MB    | 60         | <10ms          |
| 1,000      | ~110      | 15MB   | 60         | <50ms          |
| 10,000     | ~110      | 50MB   | 60         | <100ms         |
| 100,000    | ~110      | 150MB  | 60         | <200ms         |

*Note: DOM node count stays constant due to windowing*

## Configuration Options

### overscanCount
Number of items to render above/below viewport. Higher values provide smoother scrolling at the cost of more DOM nodes.
- **Default**: 3
- **Range**: 1-10
- **Use case**: Increase for fast scrolling scenarios

### overscanPixels
Pixel distance to overscan beyond viewport. Used by IntersectionObserver.
- **Default**: 300px
- **Range**: 100-1000px
- **Use case**: Match to expected scroll velocity

### dynamicHeights
Whether to measure actual item heights. Disable for fixed-height items for better performance.
- **Default**: true
- **Use case**: Set to false for uniform-height lists

### estimatedItemHeight
Initial height assumption for unmeasured items.
- **Default**: 44px (iOS standard row height)
- **Use case**: Match to your typical item height

### scrollThrottle
Throttle delay for scroll events in milliseconds.
- **Default**: 16ms (60fps)
- **Range**: 8-32ms
- **Use case**: Increase on slower devices

### poolSize
Maximum number of inactive items to keep in the pool.
- **Default**: 50
- **Range**: 20-200
- **Use case**: Increase for complex items with expensive creation

## Integration with Rendering Pipeline

The virtual scrolling system integrates with Raven's rendering pipeline through:

1. **Modifier Detection**: RenderCoordinator detects `VirtualizedModifier`
2. **Scroller Creation**: Creates `VirtualScroller` for the list
3. **Item Building**: Uses the list's content builder as `itemBuilder`
4. **Lifecycle Management**: Handles mount/unmount based on view lifecycle
5. **VNode Generation**: Generates VNodes for visible items only

## Browser Compatibility

### Required APIs
- ✅ IntersectionObserver (Chrome 51+, Firefox 55+, Safari 12.1+)
- ✅ ResizeObserver (Chrome 64+, Firefox 69+, Safari 13.1+)
- ✅ Passive Event Listeners (Chrome 51+, Firefox 49+, Safari 10+)

### Fallbacks
- IntersectionObserver: Falls back to scroll-based detection
- ResizeObserver: Falls back to fixed heights
- Passive listeners: Gracefully degrades to regular listeners

## Threading & Concurrency

All virtual scrolling components are `@MainActor` isolated:
- DOM operations must run on main thread (JSObject not Sendable)
- Scroll events arrive on main thread
- Safe concurrent access through actor isolation
- Callbacks are `@Sendable @MainActor` for safety

## Future Enhancements

### Planned
- [ ] Horizontal scrolling support for LazyHGrid
- [ ] Sticky headers/footers
- [ ] Section-based virtualization
- [ ] Variable-width items for grids
- [ ] Scroll position anchoring during data updates
- [ ] Keyboard navigation optimization
- [ ] Accessibility improvements (ARIA live regions)

### Under Consideration
- [ ] Multi-column virtualization (table view)
- [ ] Infinite scrolling with data loading
- [ ] Scroll position restoration across sessions
- [ ] Performance profiling integration
- [ ] Debug overlay for development

## Testing

Comprehensive tests should cover:
- ✅ ScrollMetrics accuracy and velocity calculation
- ✅ ItemPool recycling and memory management
- ✅ ViewportManager observer lifecycle
- ✅ VirtualScroller range calculation
- ✅ Dynamic height measurement and caching
- ✅ Scroll position restoration
- ✅ Edge cases (empty lists, single items, etc.)

## Debugging

Enable debug logging:
```swift
scroller.getStatistics()
// Returns:
// [
//   "activeItems": 15,
//   "inactiveItems": 35,
//   "cachedHeights": 1000,
//   "itemCount": 10000,
//   "visibleRange": "95..<110",
//   "scrollTop": 4500.0,
//   "velocity": 1200.0
// ]
```

Visual debugging:
```css
/* Add to your CSS to visualize items */
.raven-virtual-scroller { border: 2px solid red; }
.raven-virtual-spacer { border: 2px solid blue; }
.raven-virtual-item { border: 1px solid green; }
```

## Performance Tips

1. **Use fixed heights when possible**: Disable `dynamicHeights` for uniform items
2. **Tune overscan**: Balance smoothness vs memory usage
3. **Optimize item rendering**: Keep item VNodes simple
4. **Batch updates**: Update multiple items together when possible
5. **Prefill pool**: Call `prefill()` before first render for smoother startup
6. **Monitor statistics**: Use `getStatistics()` to track pool efficiency

## Contributing

When modifying the virtual scrolling system:
1. Maintain Swift 6.2 strict concurrency compliance
2. Keep all components `@MainActor` isolated
3. Add comprehensive documentation
4. Update benchmarks if performance changes
5. Test with 10,000+ item lists
6. Profile with Instruments or browser DevTools

## References

- [Virtual Scrolling Concepts](https://web.dev/virtualize-long-lists-react-window/)
- [IntersectionObserver API](https://developer.mozilla.org/en-US/docs/Web/API/Intersection_Observer_API)
- [ResizeObserver API](https://developer.mozilla.org/en-US/docs/Web/API/ResizeObserver)
- [Web Performance Best Practices](https://web.dev/fast/)
