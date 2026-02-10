# Interaction Modifiers

This document describes the interaction and lifecycle modifiers implemented for Raven's SwiftUI-to-DOM cross-compilation.

## Overview

Interaction modifiers provide essential user interaction and lifecycle management capabilities for Raven views. These modifiers bridge SwiftUI's declarative API with DOM event handling and lifecycle management.

## Implemented Modifiers

### 1. `.disabled(_:)`

Disables user interaction with a view.

**SwiftUI API:**
```swift
func disabled(_ disabled: Bool) -> some View
```

**Web Implementation:**
- CSS `pointer-events: none` - Prevents all mouse/touch events
- CSS `opacity: 0.5` - Visual feedback that the view is disabled
- CSS `cursor: not-allowed` - Shows appropriate cursor on hover

**Example:**
```swift
Button("Submit") {
    submitForm()
}
.disabled(isProcessing)
```

**Implementation Details:**
- When `disabled` is `true`, wraps the view in a div with the above CSS properties
- When `disabled` is `false`, creates a transparent wrapper without the disabled styles
- Works with any view type (buttons, forms, complex hierarchies)

---

### 2. `.onTapGesture(count:perform:)`

Adds tap/click gesture recognition to a view.

**SwiftUI API:**
```swift
func onTapGesture(count: Int = 1, perform action: @escaping () -> Void) -> some View
```

**Web Implementation:**
- Single tap (`count: 1`) → JavaScript `click` event
- Double tap (`count: 2`) → JavaScript `dblclick` event
- Higher counts would require custom JavaScript logic (future enhancement)

**Example:**
```swift
Text("Tap me")
    .onTapGesture {
        print("Single tap")
    }

Image("photo")
    .onTapGesture(count: 2) {
        print("Double tap")
    }
```

**Implementation Details:**
- Wraps content in a div with the appropriate event handler
- Generates unique handler IDs for the event system
- Different event names based on tap count (click vs dblclick)

---

### 3. `.onAppear(perform:)`

Executes an action when the view appears in the DOM.

**SwiftUI API:**
```swift
func onAppear(perform action: @escaping () -> Void) -> some View
```

**Web Implementation:**
- IntersectionObserver API to detect when view becomes visible
- Mount callback for immediate execution when view is added to DOM
- Custom lifecycle tracking via data attributes

**Example:**
```swift
List {
    ForEach(items) { item in
        Text(item.name)
    }
}
.onAppear {
    loadData()
}
```

**Implementation Details:**
- Creates a div wrapper with `data-on-appear` attribute
- Lifecycle handler registered with unique ID
- Renderer manages actual lifecycle callback execution

---

### 4. `.onDisappear(perform:)`

Executes an action when the view disappears from the DOM.

**SwiftUI API:**
```swift
func onDisappear(perform action: @escaping () -> Void) -> some View
```

**Web Implementation:**
- IntersectionObserver API to detect when view becomes hidden
- Unmount callback for cleanup when view is removed from DOM
- Custom lifecycle tracking via data attributes

**Example:**
```swift
VStack {
    // Complex view
}
.onDisappear {
    cleanup()
    saveState()
}
```

**Implementation Details:**
- Creates a div wrapper with `data-on-disappear` attribute
- Lifecycle handler registered with unique ID
- Paired with onAppear for complete lifecycle management

---

### 5. `.onChange(of:perform:)`

Monitors a value and executes an action when it changes.

**SwiftUI API:**
```swift
func onChange<V: Equatable>(of value: V, perform action: @escaping (V) -> Void) -> some View
```

**Web Implementation:**
- Property observer pattern
- Value comparison between renders
- Custom change tracking via data attributes

**Example:**
```swift
TextField("Search", text: $searchText)
    .onChange(of: searchText) { newValue in
        performSearch(newValue)
    }

Slider(value: $volume, in: 0...100)
    .onChange(of: volume) { newVolume in
        updateVolume(newVolume)
    }
```

**Implementation Details:**
- Creates a div wrapper with `data-on-change` attribute
- Stores change handler with unique ID
- Renderer compares values between renders and triggers action on change
- Supports any `Equatable & Sendable` type

---

## Architecture

### View Wrappers

All interaction modifiers follow the same pattern:

1. **View Wrapper Struct**: Each modifier creates a wrapper view (e.g., `_DisabledView`, `_OnTapGestureView`)
2. **Content Preservation**: The wrapper stores the original content view
3. **Action Storage**: Callbacks are stored as `@Sendable @MainActor` closures
4. **VNode Generation**: The `toVNode()` method creates appropriate DOM representation

### VNode Properties

Modifiers use different `VProperty` types:

- **Style Properties**: For visual changes (`.disabled`)
  ```swift
  .style(name: "pointer-events", value: "none")
  ```

- **Event Handlers**: For user interactions (`.onTapGesture`)
  ```swift
  .eventHandler(event: "click", handlerID: uuid)
  ```

- **Data Attributes**: For lifecycle tracking (`.onAppear`, `.onDisappear`, `.onChange`)
  ```swift
  .attribute(name: "data-on-appear", value: handlerID)
  ```

### Sendable Conformance

All modifier types conform to `Sendable` for Swift 6 concurrency:

```swift
public struct _DisabledView<Content: View>: View, Sendable {
    let content: Content
    let disabled: Bool
    // ...
}
```

All action closures use `@Sendable @MainActor`:

```swift
let action: @Sendable @MainActor () -> Void
```

---

## Testing

Comprehensive test coverage includes:

1. **Type Verification**: Ensure modifiers return correct wrapper types
2. **VNode Generation**: Verify correct DOM element creation
3. **Property Verification**: Check CSS styles and event handlers
4. **Composition**: Test modifier chaining and interaction
5. **Edge Cases**: Optional values, complex hierarchies, etc.

**Test File**: `Tests/RavenTests/InteractionModifierTests.swift`
- 22 test functions
- Coverage: All 5 modifiers with various scenarios
- Tests for composition, Sendable conformance, and edge cases

---

## Examples

**Example File**: `Examples/InteractionModifiersExample.swift`

Includes:
- Basic usage of each modifier
- Real-world patterns (forms, lists, search)
- Complete task manager app example
- Composition and advanced usage

---

## Future Enhancements

1. **Multi-tap Gestures**: Better support for tap counts > 2
2. **Gesture Customization**: Parameters for tap duration, delay
3. **Lifecycle Context**: Pass additional context to lifecycle callbacks
4. **Change Throttling**: Built-in debounce/throttle for onChange
5. **Accessibility**: ARIA attributes for disabled states
6. **Animation Integration**: Coordinate with view transitions

---

## Related Modifiers

- **Basic Modifiers**: `.padding()`, `.frame()`, `.foregroundColor()`
- **Advanced Modifiers**: `.background()`, `.opacity()`, `.shadow()`
- **Layout Modifiers**: `.clipped()`, `.aspectRatio()`, `.fixedSize()` (Phase 9 Task #5)
- **Text Modifiers**: `.lineLimit()`, `.multilineTextAlignment()` (Phase 9 Task #6)

---

## Implementation Notes

### Renderer Integration

The actual event handling and lifecycle management requires:

1. **Event Registration**: Renderer must register event handlers with the DOM
2. **Lifecycle Tracking**: IntersectionObserver or mutation observer setup
3. **Value Comparison**: onChange requires storing previous values and comparing
4. **Cleanup**: Proper cleanup of event listeners and observers

### Performance Considerations

- **Wrapper Overhead**: Each modifier adds a DOM wrapper div
- **Event Delegation**: Could optimize with event delegation patterns
- **Observer Efficiency**: IntersectionObserver is efficient but has overhead
- **Memory Management**: Event handlers must be properly cleaned up

### Browser Compatibility

- **Click Events**: Universal support
- **Double Click**: Universal support
- **IntersectionObserver**: Modern browsers (IE11+ with polyfill)
- **CSS Properties**: All widely supported

---

## References

- **SwiftUI Documentation**: [View Modifiers](https://developer.apple.com/documentation/swiftui/view-modifiers)
- **MDN Web Docs**: [Event Reference](https://developer.mozilla.org/en-US/docs/Web/Events)
- **IntersectionObserver API**: [MDN](https://developer.mozilla.org/en-US/docs/Web/API/Intersection_Observer_API)
- **Pointer Events**: [MDN](https://developer.mozilla.org/en-US/docs/Web/CSS/pointer-events)
