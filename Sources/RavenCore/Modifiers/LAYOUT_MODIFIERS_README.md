# Layout Modifiers

This document describes the layout modifiers implemented for Raven, including `.clipped()`, `.aspectRatio()`, and `.fixedSize()`.

## Overview

Layout modifiers control how views are sized, clipped, and constrained within their containers. These modifiers are essential for creating precise, well-behaved layouts in SwiftUI applications.

## Implemented Modifiers

### 1. `.clipped()`

Clips a view to its bounding rectangular frame, preventing content from drawing outside the view's bounds.

**SwiftUI API:**
```swift
func clipped() -> some View
```

**Web Implementation:**
- CSS Property: `overflow: hidden`
- Applied to a wrapping `<div>` element

**Use Cases:**
- Preventing images from overflowing their frames
- Clipping long text to a specific area
- Ensuring content stays within rounded corners
- Constraining child views within a parent container

**Example:**
```swift
Image("wide-photo")
    .frame(width: 100, height: 100)
    .clipped()  // Prevents image from drawing outside 100x100 frame
```

### 2. `.aspectRatio(_:contentMode:)`

Constrains a view's dimensions to a specified aspect ratio or its intrinsic aspect ratio.

**SwiftUI API:**
```swift
func aspectRatio(_ aspectRatio: CGFloat? = nil, contentMode: ContentMode) -> some View
```

**Parameters:**
- `aspectRatio`: The width-to-height ratio (e.g., `16/9`, `1`, `nil` for intrinsic)
- `contentMode`: How content should be sized (`.fit` or `.fill`)

**ContentMode:**
- `.fit`: Scale content to fit within bounds while maintaining aspect ratio (may leave empty space)
- `.fill`: Scale content to fill bounds while maintaining aspect ratio (may crop content)

**Web Implementation:**
- Modern: CSS `aspect-ratio` property
- Content mode: `object-fit: contain` (fit) or `object-fit: cover` (fill)
- Sizing: `width: 100%` and `height: 100%` to fill container

**Use Cases:**
- Maintaining image proportions
- Creating square profile pictures
- Widescreen video containers (16:9)
- Responsive layout elements

**Examples:**
```swift
// 16:9 widescreen, fit within bounds
Rectangle()
    .fill(.blue)
    .aspectRatio(16/9, contentMode: .fit)

// Square, fill available space
Image("photo")
    .aspectRatio(1, contentMode: .fill)
    .frame(width: 200, height: 200)
    .clipped()  // Clip overflow from .fill

// Use intrinsic aspect ratio
Image("photo")
    .aspectRatio(contentMode: .fit)
```

### 3. `.fixedSize(horizontal:vertical:)`

Fixes a view at its ideal size on specified axes, preventing compression or expansion.

**SwiftUI API:**
```swift
func fixedSize(horizontal: Bool = true, vertical: Bool = true) -> some View
```

**Parameters:**
- `horizontal`: Whether to fix width (default: `true`)
- `vertical`: Whether to fix height (default: `true`)

**Web Implementation:**
- Horizontal: `width: fit-content` and `max-width: max-content`
- Vertical: `height: fit-content` and `max-height: max-content`
- Additional: `flex-shrink: 0` to prevent flex containers from shrinking the view

**Use Cases:**
- Preventing text from wrapping when it shouldn't
- Maintaining button sizes regardless of container
- Fixing one dimension while allowing the other to flex
- Preserving intrinsic content sizes

**Examples:**
```swift
// Fix both dimensions
Text("Do not resize")
    .fixedSize()

// Fix horizontal, allow vertical wrapping
Text("Long text that can wrap to multiple lines")
    .fixedSize(horizontal: false, vertical: true)

// Fix vertical, allow horizontal expansion
Text("Wide text")
    .fixedSize(horizontal: true, vertical: false)
```

## Modifier Composition

Layout modifiers can be combined with each other and other modifiers:

```swift
// Clipped aspect ratio image
Image("photo")
    .aspectRatio(16/9, contentMode: .fill)
    .frame(width: 300)
    .clipped()

// Fixed size with aspect ratio
Rectangle()
    .fill(.blue)
    .fixedSize()
    .aspectRatio(1, contentMode: .fit)

// Complex layout composition
VStack {
    Text("Card")
}
.padding()
.aspectRatio(1, contentMode: .fit)
.background(.white)
.cornerRadius(10)
.clipped()
.shadow(radius: 5)
```

## Implementation Details

### File Structure

- **Source:** `Sources/Raven/Modifiers/LayoutModifiers.swift`
- **Tests:** `Tests/RavenTests/LayoutModifiersTests.swift`
- **Examples:** `Examples/LayoutModifiersExample.swift`

### Type Definitions

#### ContentMode
```swift
public enum ContentMode: Sendable, Hashable {
    case fit
    case fill
}
```

#### View Wrappers
- `_ClippedView<Content: View>`: Applies clipping
- `_AspectRatioView<Content: View>`: Applies aspect ratio constraint
- `_FixedSizeView<Content: View>`: Applies fixed sizing

### CSS Translation

| Modifier | CSS Properties |
|----------|---------------|
| `.clipped()` | `overflow: hidden` |
| `.aspectRatio(r, .fit)` | `aspect-ratio: r`, `object-fit: contain` |
| `.aspectRatio(r, .fill)` | `aspect-ratio: r`, `object-fit: cover` |
| `.fixedSize()` | `width: fit-content`, `height: fit-content`, `flex-shrink: 0` |
| `.fixedSize(horizontal: true, vertical: false)` | `width: fit-content`, `flex-shrink: 0` |

### Browser Compatibility

- **aspect-ratio**: Supported in all modern browsers (Chrome 88+, Safari 15+, Firefox 89+)
- **object-fit**: Widely supported (Chrome 31+, Safari 10+, Firefox 36+)
- **fit-content**: Widely supported for width/height values

For older browsers that don't support `aspect-ratio`, the padding-hack technique could be added as a fallback in future iterations.

## Testing

The implementation includes comprehensive tests covering:

1. **Basic functionality**: Each modifier works independently
2. **VNode generation**: Correct CSS properties are generated
3. **ContentMode**: Both fit and fill modes work correctly
4. **Axis combinations**: All combinations of horizontal/vertical for fixedSize
5. **Composition**: Modifiers can be combined with each other
6. **Edge cases**: Zero ratios, large values, nil aspect ratios
7. **Sendable conformance**: All types are properly Sendable

### Test Coverage

- **Total tests**: 40+ test cases
- **Clipped tests**: 3
- **AspectRatio tests**: 8
- **FixedSize tests**: 6
- **ContentMode tests**: 4
- **Composition tests**: 4
- **VNode generation tests**: 4
- **Edge case tests**: 3
- **Sendable tests**: 1

## Future Enhancements

Potential improvements for future iterations:

1. **Fallback for aspect-ratio**: Implement padding-hack for older browsers
2. **ScaledToFit/ScaledToFill**: Add convenience methods (`.scaledToFit()`, `.scaledToFill()`)
3. **ClipShape support**: Allow custom clip shapes beyond rectangular
4. **Frame with alignment**: Extend `.frame()` to support aspect ratio constraints
5. **Debug borders**: Optional visual debugging for layout bounds

## See Also

- Basic modifiers: `.padding()`, `.frame()`, `.foregroundColor()`
- Advanced modifiers: `.background()`, `.overlay()`, `.cornerRadius()`
- Layout views: `VStack`, `HStack`, `ZStack`
- Interaction modifiers: `.disabled()`, `.onTapGesture()`
