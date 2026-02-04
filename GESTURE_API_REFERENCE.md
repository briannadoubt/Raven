# Raven Gesture System API Reference

## Overview

The Raven gesture system provides SwiftUI-compatible gesture recognition and composition APIs for web applications. This reference covers all public APIs introduced in Phase 13.

## Table of Contents

1. [View Extensions](#view-extensions)
2. [Gesture Composition](#gesture-composition)
3. [Composition Types](#composition-types)
4. [Value Types](#value-types)
5. [GestureMask](#gesturemask)
6. [Complete Examples](#complete-examples)

---

## View Extensions

### .gesture(_:including:)

Attaches a gesture to a view with optional mask control.

```swift
func gesture<G: Gesture>(
    _ gesture: G,
    including mask: GestureMask = .all
) -> some View
```

**Parameters**:
- `gesture`: The gesture to attach
- `mask`: Controls where the gesture is recognized (default: `.all`)

**Example**:
```swift
Rectangle()
    .gesture(TapGesture().onEnded { print("Tapped") })
```

---

### .simultaneousGesture(_:including:)

Attaches a gesture that recognizes simultaneously with other gestures.

```swift
func simultaneousGesture<G: Gesture>(
    _ gesture: G,
    including mask: GestureMask = .all
) -> some View
```

**Parameters**:
- `gesture`: The gesture to attach
- `mask`: Controls where the gesture is recognized (default: `.all`)

**Example**:
```swift
ScrollView {
    ForEach(items) { item in
        ItemView(item)
            .simultaneousGesture(TapGesture().onEnded {
                print("Tapped while scrolling")
            })
    }
}
```

---

### .highPriorityGesture(_:including:)

Attaches a gesture with high priority over other gestures.

```swift
func highPriorityGesture<G: Gesture>(
    _ gesture: G,
    including mask: GestureMask = .all
) -> some View
```

**Parameters**:
- `gesture`: The gesture to attach
- `mask`: Controls where the gesture is recognized (default: `.all`)

**Example**:
```swift
ScrollView {
    content
}
.highPriorityGesture(
    DragGesture().onChanged { value in
        // Overrides scroll gesture
        customDragHandler(value)
    }
)
```

---

## Gesture Composition

### .simultaneously(with:)

Combines two gestures to recognize at the same time.

```swift
extension Gesture {
    func simultaneously<Other: Gesture>(
        with other: Other
    ) -> SimultaneousGesture<Self, Other>
}
```

**Returns**: A gesture that produces `(Self.Value?, Other.Value?)`

**Example**:
```swift
RotationGesture()
    .simultaneously(with: MagnificationGesture())
    .onChanged { value in
        rotation = value.0 ?? .zero
        scale = value.1 ?? 1.0
    }
```

**Use Cases**:
- Rotate and zoom simultaneously
- Pan and rotate together
- Multiple independent gestures

---

### .sequenced(before:)

Combines two gestures to recognize in sequence.

```swift
extension Gesture {
    func sequenced<Other: Gesture>(
        before other: Other
    ) -> SequenceGesture<Self, Other>
}
```

**Returns**: A gesture that produces `SequenceGestureValue<Self.Value, Other.Value>`

**Example**:
```swift
LongPressGesture()
    .sequenced(before: DragGesture())
    .onChanged { value in
        switch value {
        case .first:
            print("Long pressing...")
        case .second(true, let drag):
            print("Dragging: \(drag?.translation)")
        case .second(false, _):
            print("Not long pressed")
        }
    }
```

**Use Cases**:
- Long press then drag (reordering)
- Double tap then drag (selection)
- Multi-stage interactions

---

### .exclusively(before:)

Combines two gestures where only one can recognize.

```swift
extension Gesture {
    func exclusively<Other: Gesture>(
        before other: Other
    ) -> ExclusiveGesture<Self, Other>
}
```

**Returns**: A gesture that produces `ExclusiveGestureValue<Self.Value, Other.Value>`

**Example**:
```swift
TapGesture()
    .exclusively(before: LongPressGesture())
    .onEnded { value in
        switch value {
        case .first:
            print("Quick tap")
        case .second:
            print("Long press")
        }
    }
```

**Use Cases**:
- Tap vs. long press
- Fast swipe vs. slow drag
- Alternative interaction methods

---

## Composition Types

### SimultaneousGesture<First, Second>

A gesture that recognizes two gestures at the same time.

```swift
public struct SimultaneousGesture<First: Gesture, Second: Gesture>: Gesture {
    public typealias Value = (First.Value?, Second.Value?)
    public let first: First
    public let second: Second
}
```

**Value**: Tuple of optional values
- `.0`: Value from first gesture (or `nil`)
- `.1`: Value from second gesture (or `nil`)

**Modifiers**:
- `.onChanged((Value) -> Void)`: Called when either gesture changes
- `.onEnded((Value) -> Void)`: Called when both gestures end

---

### SequenceGesture<First, Second>

A gesture that recognizes two gestures in sequence.

```swift
public struct SequenceGesture<First: Gesture, Second: Gesture>: Gesture {
    public typealias Value = SequenceGestureValue<First.Value, Second.Value>
    public let first: First
    public let second: Second
}
```

**Value**: See `SequenceGestureValue` below

**Modifiers**:
- `.onChanged((Value) -> Void)`: Called during both stages
- `.onEnded((Value) -> Void)`: Called when sequence completes

---

### ExclusiveGesture<First, Second>

A gesture where only one of two gestures recognizes.

```swift
public struct ExclusiveGesture<First: Gesture, Second: Gesture>: Gesture {
    public typealias Value = ExclusiveGestureValue<First.Value, Second.Value>
    public let first: First
    public let second: Second
}
```

**Value**: See `ExclusiveGestureValue` below

**Modifiers**:
- `.onChanged((Value) -> Void)`: Called during recognition
- `.onEnded((Value) -> Void)`: Called when gesture ends

---

## Value Types

### SequenceGestureValue<First, Second>

Represents the state of a sequence gesture.

```swift
@frozen
public enum SequenceGestureValue<First: Sendable, Second: Sendable>: Sendable {
    case first(First)
    case second(First, Second?)
}
```

**Cases**:
- `.first(First)`: First gesture is active
- `.second(First, Second?)`: First completed, second is active or about to start

**Example**:
```swift
.onChanged { value in
    switch value {
    case .first(let pressing):
        // First gesture active
        print("Pressing: \(pressing)")

    case .second(let pressCompleted, let drag):
        // Second gesture active
        if pressCompleted {
            if let dragValue = drag {
                print("Dragging: \(dragValue.translation)")
            } else {
                print("Press done, waiting for drag")
            }
        }
    }
}
```

**Conformances**: `Sendable`, `Equatable` (when First and Second are Equatable)

---

### ExclusiveGestureValue<First, Second>

Represents which gesture won in an exclusive combination.

```swift
@frozen
public enum ExclusiveGestureValue<First: Sendable, Second: Sendable>: Sendable {
    case first(First)
    case second(Second)
}
```

**Cases**:
- `.first(First)`: First gesture won
- `.second(Second)`: Second gesture won

**Example**:
```swift
.onEnded { value in
    switch value {
    case .first:
        print("Tap detected")
        performTapAction()

    case .second:
        print("Long press detected")
        showContextMenu()
    }
}
```

**Conformances**: `Sendable`, `Equatable` (when First and Second are Equatable)

---

## GestureMask

Controls where gestures are recognized in a view hierarchy.

```swift
public struct GestureMask: OptionSet {
    public static let none: GestureMask
    public static let gesture: GestureMask
    public static let subviews: GestureMask
    public static let all: GestureMask
}
```

**Options**:
- `.none`: No gesture recognition
- `.gesture`: Only on the view itself
- `.subviews`: Only on subviews
- `.all`: Both the view and subviews (default)

**Examples**:
```swift
// Only recognize on the view itself
.gesture(TapGesture(), including: .gesture)

// Only recognize on subviews
.gesture(TapGesture(), including: .subviews)

// Disable gesture recognition
.gesture(TapGesture(), including: .none)

// Both view and subviews (default)
.gesture(TapGesture(), including: .all)
// or simply:
.gesture(TapGesture())
```

---

## Complete Examples

### Photo Editor with Multi-Touch

```swift
struct PhotoEditor: View {
    @State private var rotation: Angle = .zero
    @State private var scale: Double = 1.0
    @State private var offset = CGSize.zero

    var body: some View {
        Image("photo")
            .rotationEffect(rotation)
            .scaleEffect(scale)
            .offset(offset)
            .gesture(
                // Simultaneous rotation and zoom
                RotationGesture()
                    .simultaneously(with: MagnificationGesture())
                    .onChanged { value in
                        rotation = value.0 ?? .zero
                        scale = value.1 ?? 1.0
                    }
            )
            .gesture(
                // Drag to move
                DragGesture()
                    .onChanged { value in
                        offset = value.translation
                    }
                    .onEnded { value in
                        // Snap or animate
                        withAnimation(.spring()) {
                            offset = .zero
                        }
                    }
            )
    }
}
```

### Reorderable List Item

```swift
struct ReorderableItem: View {
    @State private var isReordering = false
    @State private var offset = CGSize.zero

    var body: some View {
        HStack {
            Image(systemName: "line.3.horizontal")
            Text("Drag to reorder")
        }
        .offset(isReordering ? offset : .zero)
        .gesture(
            LongPressGesture(minimumDuration: 0.5)
                .sequenced(before: DragGesture())
                .onChanged { value in
                    switch value {
                    case .first:
                        isReordering = true
                    case .second(true, let drag):
                        offset = drag?.translation ?? .zero
                    case .second(false, _):
                        isReordering = false
                    }
                }
                .onEnded { _ in
                    withAnimation {
                        isReordering = false
                        offset = .zero
                    }
                }
        )
    }
}
```

### Interactive Button with Context Menu

```swift
struct SmartButton: View {
    @State private var action = ""

    var body: some View {
        Text(action.isEmpty ? "Tap or hold" : action)
            .padding()
            .background(.blue)
            .foregroundColor(.white)
            .gesture(
                TapGesture()
                    .exclusively(before: LongPressGesture(minimumDuration: 0.8))
                    .onEnded { value in
                        switch value {
                        case .first:
                            action = "Quick action"
                            performQuickAction()
                        case .second:
                            action = "Context menu"
                            showContextMenu()
                        }
                    }
            )
    }

    func performQuickAction() { /* ... */ }
    func showContextMenu() { /* ... */ }
}
```

### Nested Gesture Composition

```swift
struct ComplexGestureView: View {
    var body: some View {
        Rectangle()
            .gesture(
                // Combine multiple gestures
                TapGesture()
                    .simultaneously(with:
                        RotationGesture()
                            .simultaneously(with: MagnificationGesture())
                    )
                    .onChanged { value in
                        // value is ((Void?, Angle?), Double?)
                        let rotation = value.0?.1
                        let scale = value.1
                        // Handle complex interaction
                    }
            )
    }
}
```

### Scroll View with Item Tap

```swift
struct ScrollableList: View {
    var body: some View {
        ScrollView {
            ForEach(items) { item in
                ItemView(item)
                    .simultaneousGesture(
                        TapGesture().onEnded {
                            print("Item tapped while scroll active")
                        }
                    )
            }
        }
    }
}
```

### Custom Gesture Priority

```swift
struct PriorityExample: View {
    var body: some View {
        Rectangle()
            .gesture(
                TapGesture().onEnded {
                    print("Normal priority tap")
                }
            )
            .simultaneousGesture(
                LongPressGesture().onEnded { _ in
                    print("Simultaneous long press")
                }
            )
            .highPriorityGesture(
                DragGesture().onChanged { _ in
                    print("High priority drag - blocks others")
                }
            )
    }
}
```

---

## Gesture Type Reference

All existing gesture types work with composition:

| Gesture | Value Type | Use Case |
|---------|-----------|----------|
| `TapGesture` | `Void` | Click/tap actions |
| `LongPressGesture` | `Bool` | Context menus, reordering |
| `DragGesture` | `DragGesture.Value` | Pan, swipe, move |
| `RotationGesture` | `Angle` | Rotate objects |
| `MagnificationGesture` | `Double` | Zoom, scale |
| `SpatialTapGesture` | `CGPoint` | Location-aware taps |

---

## Best Practices

### 1. Choose the Right Composition

- **Simultaneous**: When gestures should work together (rotate + zoom)
- **Sequence**: When one gesture must complete first (long press + drag)
- **Exclusive**: When only one should recognize (tap vs. long press)

### 2. Use Appropriate Masks

- Use `.gesture` for view-only recognition
- Use `.subviews` for child-only recognition
- Use `.all` (default) when both should work
- Use `.none` to temporarily disable

### 3. Handle All Value Cases

Always handle all cases in sequence/exclusive gesture values:

```swift
.onChanged { value in
    switch value {
    case .first(let val):
        // Handle first
    case .second(let first, let second):
        // Handle second
    }
}
```

### 4. Consider Priority

- Normal: Equal competition with other gestures
- Simultaneous: Works alongside others
- High: Takes precedence over normal priority

### 5. Clean Up State

Use `@GestureState` for automatic cleanup:

```swift
@GestureState private var isDragging = false

.gesture(
    DragGesture()
        .updating($isDragging) { _, state, _ in
            state = true
        }
)
// isDragging automatically resets when gesture ends
```

---

## Migration from SwiftUI

Raven's gesture API is 100% compatible with SwiftUI. Code should work without changes:

```swift
// SwiftUI code
Image("photo")
    .gesture(
        RotationGesture()
            .simultaneously(with: MagnificationGesture())
    )

// Same code works in Raven
Image("photo")
    .gesture(
        RotationGesture()
            .simultaneously(with: MagnificationGesture())
    )
```

The only difference is the underlying implementation (web vs. native), which is transparent to your code.
