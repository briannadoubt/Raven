# Layout Modifiers API Reference

## Overview

This document provides a complete API reference for the layout modifiers implemented in Task #5.

## ContentMode Enum

```swift
public enum ContentMode: Sendable, Hashable
```

Defines how content should be resized to fit within a container.

### Cases

#### `case fit`
Scale the content to fit the available space while maintaining aspect ratio. This mode ensures the entire content is visible, potentially leaving empty space.

#### `case fill`
Scale the content to fill the available space while maintaining aspect ratio. This mode may crop parts of the content to fill the entire space.

---

## View Extension Methods

### .clipped()

```swift
@MainActor public func clipped() -> _ClippedView<Self>
```

Clips this view to its bounding rectangular frame.

**Returns:** A view that clips to its bounding frame.

**Example:**
```swift
Image("wide-image")
    .frame(width: 100, height: 100)
    .clipped()
```

**CSS Output:**
```css
overflow: hidden;
```

---

### .aspectRatio(_:contentMode:)

```swift
@MainActor public func aspectRatio(
    _ aspectRatio: CGFloat? = nil,
    contentMode: ContentMode
) -> _AspectRatioView<Self>
```

Constrains this view's dimensions to the aspect ratio of the specified size.

**Parameters:**
- `aspectRatio`: The ratio of width to height. Pass `nil` to use the content's intrinsic aspect ratio.
- `contentMode`: How the content should be resized.

**Returns:** A view with constrained dimensions.

**Examples:**
```swift
// 16:9 aspect ratio, fit mode
Rectangle()
    .fill(.blue)
    .aspectRatio(16/9, contentMode: .fit)

// Square aspect ratio, fill mode
Image("photo")
    .aspectRatio(1, contentMode: .fill)

// Intrinsic aspect ratio
Image("photo")
    .aspectRatio(contentMode: .fit)
```

**CSS Output (fit mode):**
```css
aspect-ratio: 1.777777;
object-fit: contain;
width: 100%;
height: 100%;
```

**CSS Output (fill mode):**
```css
aspect-ratio: 1.0;
object-fit: cover;
width: 100%;
height: 100%;
```

---

### .fixedSize(horizontal:vertical:)

```swift
@MainActor public func fixedSize(
    horizontal: Bool = true,
    vertical: Bool = true
) -> _FixedSizeView<Self>
```

Fixes this view at its ideal size.

**Parameters:**
- `horizontal`: Whether to fix the width. Defaults to `true`.
- `vertical`: Whether to fix the height. Defaults to `true`.

**Returns:** A view with fixed dimensions.

**Examples:**
```swift
// Fix both dimensions
Text("Fixed")
    .fixedSize()

// Fix only horizontal dimension
Text("Long text that can wrap to multiple lines")
    .fixedSize(horizontal: false, vertical: true)

// Fix only vertical dimension
Text("Wide")
    .fixedSize(horizontal: true, vertical: false)
```

**CSS Output (both axes):**
```css
width: fit-content;
max-width: max-content;
height: fit-content;
max-height: max-content;
flex-shrink: 0;
```

**CSS Output (horizontal only):**
```css
width: fit-content;
max-width: max-content;
flex-shrink: 0;
```

**CSS Output (vertical only):**
```css
height: fit-content;
max-height: max-content;
flex-shrink: 0;
```

---

## View Wrapper Types

These types are returned by the modifier methods. You typically don't create these directly.

### _ClippedView<Content: View>

```swift
public struct _ClippedView<Content: View>: View, Sendable
```

A view wrapper that clips its content to its bounding rectangle.

### _AspectRatioView<Content: View>

```swift
public struct _AspectRatioView<Content: View>: View, Sendable
```

A view wrapper that constrains the aspect ratio of its content.

### _FixedSizeView<Content: View>

```swift
public struct _FixedSizeView<Content: View>: View, Sendable
```

A view wrapper that fixes the size of its content to its ideal size.

---

## Type Aliases

### CGFloat

```swift
public typealias CGFloat = Double
```

A type alias for Double to match SwiftUI's CGFloat usage. In Swift on WebAssembly, CGFloat is not available, so we use Double as a replacement.

---

## Common Patterns

### Clipped Image in Frame

```swift
Image("photo")
    .frame(width: 200, height: 200)
    .aspectRatio(1, contentMode: .fill)
    .clipped()
```

### Responsive Video Container

```swift
VideoPlayer(url: videoURL)
    .aspectRatio(16/9, contentMode: .fit)
```

### Fixed-Width Button

```swift
Button("Submit") {
    submit()
}
.fixedSize(horizontal: true, vertical: false)
```

### Non-Wrapping Text

```swift
Text("This text will not wrap")
    .fixedSize()
```

### Card with Fixed Aspect Ratio

```swift
VStack {
    Text("Card Content")
        .padding()
}
.aspectRatio(4/3, contentMode: .fit)
.background(.white)
.cornerRadius(10)
.clipped()
.shadow(radius: 5)
```

---

## Modifier Chaining

All layout modifiers can be chained with other modifiers:

```swift
Text("Example")
    .padding(10)                          // Basic modifier
    .aspectRatio(1, contentMode: .fit)    // Layout modifier
    .background(.blue)                    // Advanced modifier
    .clipped()                            // Layout modifier
    .cornerRadius(8)                      // Advanced modifier
    .fixedSize(horizontal: true, vertical: false)  // Layout modifier
    .shadow(radius: 5)                    // Advanced modifier
```

---

## Performance Considerations

- **clipped()**: Minimal performance impact, uses native CSS overflow
- **aspectRatio()**: Modern CSS property, excellent performance in supported browsers
- **fixedSize()**: Uses CSS sizing values, no performance concerns

---

## Browser Support

### Modern Browsers (Recommended)
- Chrome 88+ (aspect-ratio support)
- Safari 15+ (aspect-ratio support)
- Firefox 89+ (aspect-ratio support)
- Edge 88+ (aspect-ratio support)

### Legacy Support
- object-fit: Chrome 31+, Safari 10+, Firefox 36+
- fit-content: Wide support across all modern browsers
- overflow: hidden: Universal support

---

## Swift Concurrency

All types conform to `Sendable` and are safe to use with Swift Concurrency:

```swift
@MainActor
func createView() -> some View {
    Text("Concurrent")
        .clipped()
        .aspectRatio(1, contentMode: .fit)
        .fixedSize()
}
```

---

## See Also

- **Basic Modifiers**: `.padding()`, `.frame()`, `.foregroundColor()`
- **Advanced Modifiers**: `.background()`, `.overlay()`, `.cornerRadius()`, `.opacity()`, `.shadow()`
- **Interaction Modifiers**: `.disabled()`, `.onTapGesture()`
- **Text Modifiers**: `.lineLimit()`, `.multilineTextAlignment()`, `.truncationMode()`
