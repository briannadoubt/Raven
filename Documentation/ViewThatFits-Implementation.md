# ViewThatFits Implementation

## Overview

`ViewThatFits` is a responsive layout container that automatically selects the first child view that fits within available space. This implementation enables SwiftUI-style responsive design without explicit breakpoints.

## Implementation Details

### Files Created

1. **Sources/Raven/Views/Layout/ViewThatFits.swift**
   - Main `ViewThatFits` struct implementing the container
   - Internal `_ViewThatFitsOption` wrapper for individual view options
   - Helper methods for extracting view options from tuples

2. **Tests/RavenTests/ViewThatFitsTests.swift**
   - 23 comprehensive tests covering all functionality
   - Tests for axis control, initialization, container queries, and edge cases

3. **Examples/ViewThatFitsExample.swift**
   - Practical examples demonstrating real-world usage
   - Best practices and usage notes
   - Advanced patterns including nested ViewThatFits

### Architecture

#### Core Concept

`ViewThatFits` uses CSS Container Queries to efficiently determine which view option fits:

```swift
ViewThatFits(in: .horizontal) {
    DesktopLayout()   // Tried first
    TabletLayout()    // Tried if desktop doesn't fit
    MobileLayout()    // Fallback - always used if others don't fit
}
```

#### Web Implementation Strategy

The implementation uses modern CSS Container Queries:

1. **Outer Container**:
   - Sets `container-type: size` to enable container queries
   - Fills available space based on specified axes
   - Marked with `data-view-that-fits="true"` for render coordination

2. **View Options**:
   - Each option wrapped in a container with visibility rules
   - CSS `@container` rules determine which option displays
   - First fitting option is shown; last option used as fallback

3. **Measurement Axes**:
   - `.horizontal`: Container fills width, measures horizontal space
   - `.vertical`: Container fills height, measures vertical space
   - `.all` or `[.horizontal, .vertical]`: Measures both dimensions

#### VNode Structure

```swift
VNode.element("div", props: [
    "display": .style("display", "block"),
    "container-type": .style("container-type", "size"),
    "position": .style("position", "relative"),
    "data-view-that-fits": .attribute("data-view-that-fits", "true"),
    "data-fit-axes": .attribute("data-fit-axes", "horizontal|vertical|both"),
    "width": .style("width", "100%"),  // if horizontal or both
    "height": .style("height", "100%")  // if vertical or both
])
```

### API Design

#### Initializer

```swift
public init(
    in axes: Axis.Set = .vertical,
    @ViewBuilder content: () -> Content
)
```

**Parameters:**
- `axes`: The axes to consider when determining fit (default: `.vertical`)
- `content`: ViewBuilder providing view options in preference order

#### Supported Axes

- `Axis.Set.horizontal`: Check horizontal space only
- `Axis.Set.vertical`: Check vertical space (default)
- `Axis.Set.all`: Check both dimensions
- Custom: `[.horizontal, .vertical]`

### Browser Compatibility

ViewThatFits uses CSS Container Queries, supported in:
- **Chrome/Edge**: 105+ (September 2022)
- **Safari**: 16+ (September 2022)
- **Firefox**: 110+ (February 2023)

**Fallback Behavior**: For browsers without container query support, the last (most compact) option is displayed.

### Testing Coverage

The test suite includes 23 tests covering:

1. **Basic Initialization** (4 tests)
   - Default axis initialization
   - Single view option
   - Two view options
   - Multiple view options

2. **Axis Control** (5 tests)
   - Horizontal axis
   - Vertical axis
   - Both axes
   - All axes shorthand
   - Axis attribute generation

3. **Container Query Setup** (3 tests)
   - Container-type property
   - Position property
   - Display property

4. **Responsive Layouts** (3 tests)
   - Navigation layouts
   - Form layouts
   - Header layouts

5. **Nesting** (3 tests)
   - ViewThatFits inside VStack
   - ViewThatFits inside HStack
   - Nested ViewThatFits containers

6. **Complex Content** (1 test)
   - Complex view hierarchies

7. **Edge Cases** (1 test)
   - Empty content

8. **Internal Helpers** (3 tests)
   - Option wrapper structure
   - Last option marking
   - Index handling

### Integration with Raven

ViewThatFits integrates seamlessly with existing Raven components:

1. **ViewBuilder Support**: Accepts any ViewBuilder content, including:
   - Multiple individual views
   - TupleView for up to 10 options
   - Conditional content
   - Nested containers

2. **Axis System**: Uses existing `Axis.Set` from Raven's core

3. **VNode Generation**: Follows standard primitive view pattern:
   - `Body = Never` indicates primitive view
   - `toVNode()` generates virtual DOM structure
   - RenderCoordinator handles children population

4. **Works With Other Modifiers**:
   - `.containerRelativeFrame()` for precise sizing
   - `.padding()` for spacing
   - `.frame()` for explicit dimensions

### Usage Patterns

#### Responsive Navigation

```swift
ViewThatFits(in: .horizontal) {
    // Wide: All items visible
    HStack { /* all nav items */ }

    // Medium: Some items + menu
    HStack { /* priority items + "More" menu */ }

    // Narrow: Menu only
    Menu("Menu") { /* all items */ }
}
```

#### Adaptive Forms

```swift
ViewThatFits {
    // Wide: Multi-column
    HStack(alignment: .top) {
        VStack { /* column 1 */ }
        VStack { /* column 2 */ }
    }

    // Narrow: Single column
    VStack { /* all fields */ }
}
```

#### Dashboard Layouts

```swift
ViewThatFits {
    // Desktop: Sidebar + content
    HStack {
        Sidebar()
        MainContent()
    }

    // Tablet: Top nav + content
    VStack {
        TopNav()
        MainContent()
    }

    // Mobile: Compact view
    CompactView()
}
```

### Performance Considerations

1. **Native Browser Support**: CSS container queries are handled natively by the browser, providing excellent performance

2. **No JavaScript Measurement**: Unlike some alternatives, ViewThatFits doesn't require JavaScript resize listeners or measurements

3. **Efficient Re-layout**: Browser automatically handles size changes without virtual DOM diffing

4. **Minimal DOM Nodes**: Creates only one wrapper container plus option containers

### Future Enhancements

Potential improvements for future versions:

1. **Custom Sizing Logic**: Support for custom fit determination beyond container size
2. **Animation Support**: Smooth transitions between layout options
3. **Measurement Callbacks**: Expose size information to parent views
4. **Priority Hints**: Allow marking preferred options with weights
5. **Debug Mode**: Visual indicators showing which option is selected and why

### Known Limitations

1. **Browser Support**: Requires modern browsers with container query support
2. **Tuple Size**: Limited to 10 view options (ViewBuilder limitation)
3. **Measurement Timing**: First render uses last option as fallback until measurement completes
4. **No Custom Predicates**: Cannot provide custom logic for determining fit

### Comparison with SwiftUI

This implementation closely matches SwiftUI's ViewThatFits API:

**Matches:**
- Same initializer signature
- Same axis control
- Same ViewBuilder support
- Same behavior of selecting first fitting option

**Differences:**
- Web uses CSS container queries (SwiftUI uses native layout)
- Browser compatibility requirements
- Fallback behavior for unsupported browsers

### Documentation

Full DocC documentation included covering:
- API reference with parameter descriptions
- Multiple usage examples
- Best practices
- Browser compatibility
- Integration with other modifiers
- Common patterns and recipes

### Testing Strategy

Tests verify:
1. ✅ Correct VNode structure generation
2. ✅ Proper axis handling and attribute setting
3. ✅ Container query CSS properties
4. ✅ Integration with other views
5. ✅ Edge cases and error conditions
6. ✅ Internal helper functionality

All tests use the Swift Testing framework with `@Test` and `@MainActor` attributes, matching Raven's testing patterns.

## Conclusion

The ViewThatFits implementation provides a powerful, performant solution for responsive layouts in Raven. By leveraging modern CSS container queries, it delivers SwiftUI-like responsive design capabilities with excellent browser performance and minimal overhead.
