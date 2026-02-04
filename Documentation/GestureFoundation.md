# Gesture Foundation - Phase 13

## Overview

The Gesture foundation provides the core infrastructure for gesture recognition in Raven. This includes the fundamental `Gesture` protocol, state management through `@GestureState`, and supporting types for controlling gesture behavior.

## Architecture

### Core Components

1. **Gesture Protocol** - The foundation protocol all gestures conform to
2. **GestureState** - Property wrapper for temporary gesture-driven state
3. **Transaction** - Context for state changes and animations
4. **GestureMask** - Controls where gestures are recognized in the view hierarchy
5. **EventModifiers** - Detects keyboard modifier keys during gestures

### Design Principles

- **Composability**: Gestures can be combined and modified
- **Type Safety**: Strong typing through associated types
- **Automatic Cleanup**: `@GestureState` automatically resets when gestures end
- **Web Integration**: Maps to JavaScript pointer, mouse, and touch events
- **Swift Concurrency**: Full `@MainActor` isolation and `Sendable` conformance

## Gesture Protocol

```swift
public protocol Gesture: Sendable {
    associatedtype Value: Sendable
    associatedtype Body: Gesture

    @MainActor var body: Body { get }
}
```

### Key Features

- **Value Type**: Each gesture produces a value during recognition
- **Body Type**: Primitive gestures use `Never`, composite gestures compose others
- **Sendable**: All gestures must be thread-safe

### Example: Primitive Gesture

```swift
struct TapGesture: Gesture {
    typealias Value = Void
    typealias Body = Never  // Primitive gesture

    let count: Int
}
```

### Example: Composite Gesture

```swift
struct SimultaneousGesture<First: Gesture, Second: Gesture>: Gesture {
    typealias Value = (First.Value, Second.Value)

    let first: First
    let second: Second

    var body: some Gesture {
        // Composition logic
    }
}
```

## GestureState Property Wrapper

`@GestureState` manages temporary state that automatically resets when a gesture ends.

### Basic Usage

```swift
struct DraggableView: View {
    @GestureState private var dragOffset = CGSize.zero

    var body: some View {
        Circle()
            .offset(dragOffset)
            .gesture(
                DragGesture()
                    .updating($dragOffset) { value, state, _ in
                        state = value.translation
                    }
            )
    }
}
```

### Key Characteristics

1. **Automatic Reset**: Value resets to initial value when gesture ends
2. **Read-Only**: Cannot be set directly, only through `.updating()`
3. **Temporary**: Perfect for tracking gesture progress
4. **Transaction Integration**: Can modify animations during updates

### Custom Reset Behavior

```swift
@GestureState(
    reset: { value, transaction in
        print("Gesture ended with value: \(value)")
        transaction.animation = .spring()
    },
    initialValue: CGSize.zero
) private var offset
```

## Transaction

Represents the context for state changes and animations.

### Properties

```swift
public struct Transaction: Sendable {
    public var animation: Animation?
    public var disablesAnimations: Bool
}
```

### Usage with GestureState

```swift
DragGesture()
    .updating($dragOffset) { value, state, transaction in
        // Modify transaction to control animation
        transaction.animation = .spring()
        state = value.translation
    }
```

### Integration with withAnimation

Transactions are created automatically by `withAnimation`:

```swift
withAnimation(.easeOut) {
    // State changes here occur in a transaction
    isExpanded.toggle()
}
```

## GestureMask

Controls where in the view hierarchy gestures are recognized.

### Options

```swift
public struct GestureMask: OptionSet {
    static var none: GestureMask        // No gesture recognition
    static var gesture: GestureMask     // Only on the view itself
    static var subviews: GestureMask    // Only on subviews
    static var all: GestureMask         // On both view and subviews
}
```

### Usage

```swift
Rectangle()
    .gesture(
        TapGesture(),
        including: .gesture  // Only recognize on the rectangle, not children
    )
```

### Web Implementation

- `.gesture` → Event listeners on element itself
- `.subviews` → Event delegation to child elements
- `.all` → Listeners on both element and children
- `.none` → No event listeners attached

## EventModifiers

Detects keyboard modifier keys during gesture recognition.

### Available Modifiers

```swift
public struct EventModifiers: OptionSet {
    static var capsLock: EventModifiers
    static var shift: EventModifiers
    static var control: EventModifiers
    static var option: EventModifiers    // Alt on Windows/Linux
    static var command: EventModifiers   // Meta/Windows key
    static var numericPad: EventModifiers
    static var function: EventModifiers
}
```

### Usage Example

```swift
DragGesture()
    .onChanged { value in
        if value.modifiers.contains(.shift) {
            // Constrain drag to horizontal or vertical
            constrainedDrag(value)
        } else {
            // Free drag
            freeDrag(value)
        }
    }
```

### Platform Mapping

| Modifier  | macOS      | Windows   | Linux     | Web Event Property |
|-----------|------------|-----------|-----------|-------------------|
| shift     | Shift      | Shift     | Shift     | `shiftKey`        |
| control   | Control    | Ctrl      | Ctrl      | `ctrlKey`         |
| option    | Option (⌥) | Alt       | Alt       | `altKey`          |
| command   | Command (⌘)| Windows   | Super     | `metaKey`         |

## Web Integration

### Event Mapping

Gestures in Raven map to standard web events:

**Mouse Events**
- `mousedown` → Gesture begins
- `mousemove` → Gesture updates
- `mouseup` → Gesture ends

**Touch Events**
- `touchstart` → Gesture begins
- `touchmove` → Gesture updates
- `touchend` → Gesture ends

**Pointer Events** (Preferred)
- `pointerdown` → Gesture begins
- `pointermove` → Gesture updates
- `pointerup` → Gesture ends

### Event Flow

1. **Attachment**: `.gesture()` modifier attaches event listeners
2. **Begin**: Pointer down creates gesture instance
3. **Update**: Pointer move calls `.updating()` and `.onChanged()` callbacks
4. **End**: Pointer up calls `.onEnded()` and resets `@GestureState`
5. **Cleanup**: Event listeners removed when view unmounts

### Example Implementation

```javascript
// Conceptual JavaScript event handling
element.addEventListener('pointerdown', (event) => {
    const modifiers = {
        shift: event.shiftKey,
        control: event.ctrlKey,
        option: event.altKey,
        command: event.metaKey
    };

    gesture.begin({ x: event.clientX, y: event.clientY, modifiers });
});

element.addEventListener('pointermove', (event) => {
    gesture.update({ x: event.clientX, y: event.clientY });
});

element.addEventListener('pointerup', (event) => {
    gesture.end();
    gestureState.reset();  // Automatic reset
});
```

## Swift 6 Concurrency

All gesture types are designed for Swift 6 strict concurrency:

### MainActor Isolation

```swift
@MainActor
public protocol Gesture: Sendable {
    // All gesture operations happen on main actor
}

@MainActor
@propertyWrapper
public struct GestureState<Value: Sendable>: DynamicProperty {
    // Gesture state is main-actor isolated
}
```

### Sendable Conformance

All gesture values and callbacks must be `Sendable`:

```swift
// ✅ Valid - Int is Sendable
struct CountGesture: Gesture {
    typealias Value = Int
}

// ✅ Valid - Custom Sendable struct
struct DragValue: Sendable {
    let location: CGPoint
    let translation: CGSize
}

// ❌ Invalid - Non-Sendable class
class GestureData {  // Missing @Sendable
    var value: Int
}
```

## Performance Considerations

### Gesture State Storage

`@GestureState` uses efficient internal storage:

```swift
@MainActor
private final class GestureStateStorage<Value: Sendable>: @unchecked Sendable {
    private var value: Value
    private let initialValue: Value
    // Minimal overhead, just two values
}
```

### Event Listener Optimization

- Event listeners only attached when needed
- Automatic cleanup when views unmount
- Gesture masks prevent unnecessary event processing
- Pointer events preferred over mouse/touch for unified handling

### Memory Management

- Gesture instances are value types (structs)
- No retain cycles in callbacks (all `@Sendable`)
- Automatic deallocation when views disappear

## Best Practices

### 1. Use @GestureState for Temporary Values

```swift
// ✅ Good - Temporary gesture state
@GestureState private var dragOffset = CGSize.zero

// ❌ Bad - Use @State instead for persistent values
@GestureState private var totalOffset = CGSize.zero  // Won't persist!
```

### 2. Combine Temporary and Persistent State

```swift
@State private var totalOffset = CGSize.zero     // Persists
@GestureState private var dragOffset = CGSize.zero  // Resets

var body: some View {
    Rectangle()
        .offset(
            x: totalOffset.width + dragOffset.width,
            y: totalOffset.height + dragOffset.height
        )
        .gesture(
            DragGesture()
                .updating($dragOffset) { value, state, _ in
                    state = value.translation
                }
                .onEnded { value in
                    totalOffset.width += value.translation.width
                    totalOffset.height += value.translation.height
                }
        )
}
```

### 3. Use Gesture Masks Appropriately

```swift
// ✅ Good - Prevent gesture conflicts
ScrollView {
    ForEach(items) { item in
        ItemView()
            .gesture(
                DragGesture(),
                including: .gesture  // Don't interfere with scroll
            )
    }
}

// ❌ Bad - Gestures will conflict with scroll
ScrollView {
    ForEach(items) { item in
        ItemView()
            .gesture(DragGesture())  // Uses .all by default
    }
}
```

### 4. Leverage Event Modifiers

```swift
// ✅ Good - Different behaviors with modifiers
DragGesture()
    .onChanged { value in
        if value.modifiers.contains(.shift) {
            // Constrained drag
        } else if value.modifiers.contains(.option) {
            // Copy drag
        } else {
            // Normal drag
        }
    }
```

## Testing

The gesture foundation includes comprehensive tests:

### GestureMask Tests
- Option set operations
- Combination and subtraction
- Contains checks

### EventModifiers Tests
- Individual modifiers
- Modifier combinations
- Platform-specific modifiers

### Transaction Tests
- Initialization
- Property modification
- Animation context

### GestureState Tests
- Initialization patterns
- Update and reset behavior
- Custom reset callbacks
- Transaction modification

### Example Test

```swift
func testGestureStateReset() {
    let state = GestureState(wrappedValue: 0)
    var transaction = Transaction()

    state.update(value: 100, transaction: &transaction)
    XCTAssertEqual(state.wrappedValue, 100)

    state.reset(transaction: &transaction)
    XCTAssertEqual(state.wrappedValue, 0)  // Automatically reset!
}
```

## Next Steps

With the gesture foundation in place, the following components can now be implemented:

1. **TapGesture** - Single and multi-tap recognition
2. **DragGesture** - Track pointer/finger movement
3. **LongPressGesture** - Detect and track long presses
4. **MagnificationGesture** - Pinch-to-zoom gestures
5. **RotationGesture** - Two-finger rotation
6. **Gesture Composition** - Combine gestures with modifiers
7. **View Extensions** - `.gesture()`, `.simultaneousGesture()`, etc.

## See Also

- [Animation System](./Phase12.md) - Integration with animations
- [State Management](./State.md) - Understanding @State vs @GestureState
- [View Modifiers](./API-Overview.md) - How gestures integrate with views
