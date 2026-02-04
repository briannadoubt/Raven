# Phase 13 API Quick Reference

## View Modifier Methods

### Basic Gesture Attachment
```swift
.gesture<G: Gesture>(_ gesture: G, including mask: GestureMask = .all) -> some View
```

### Simultaneous Gesture
```swift
.simultaneousGesture<G: Gesture>(_ gesture: G, including mask: GestureMask = .all) -> some View
```

### High Priority Gesture
```swift
.highPriorityGesture<G: Gesture>(_ gesture: G, including mask: GestureMask = .all) -> some View
```

## Gesture Composition Methods

### Simultaneous
```swift
func simultaneously<Other: Gesture>(with other: Other) -> SimultaneousGesture<Self, Other>
```

### Sequential
```swift
func sequenced<Other: Gesture>(before other: Other) -> SequenceGesture<Self, Other>
```

### Exclusive
```swift
func exclusively<Other: Gesture>(before other: Other) -> ExclusiveGesture<Self, Other>
```

## Composition Types

### SimultaneousGesture
```swift
struct SimultaneousGesture<First: Gesture, Second: Gesture>: Gesture {
    typealias Value = (First.Value?, Second.Value?)
    let first: First
    let second: Second
}
```

### SequenceGesture
```swift
struct SequenceGesture<First: Gesture, Second: Gesture>: Gesture {
    typealias Value = SequenceGestureValue<First.Value, Second.Value>
    let first: First
    let second: Second
}
```

### ExclusiveGesture
```swift
struct ExclusiveGesture<First: Gesture, Second: Gesture>: Gesture {
    typealias Value = ExclusiveGestureValue<First.Value, Second.Value>
    let first: First
    let second: Second
}
```

## Value Types

### SequenceGestureValue
```swift
@frozen enum SequenceGestureValue<First: Sendable, Second: Sendable>: Sendable {
    case first(First)
    case second(First, Second?)
}
```

### ExclusiveGestureValue
```swift
@frozen enum ExclusiveGestureValue<First: Sendable, Second: Sendable>: Sendable {
    case first(First)
    case second(Second)
}
```

## GestureMask

```swift
struct GestureMask: OptionSet {
    static let none: GestureMask      // No recognition
    static let gesture: GestureMask   // Only the view
    static let subviews: GestureMask  // Only subviews
    static let all: GestureMask       // Both (default)
}
```

## Quick Examples

### Tap
```swift
.gesture(TapGesture().onEnded { print("Tap") })
```

### Simultaneous Rotate + Zoom
```swift
.gesture(
    RotationGesture()
        .simultaneously(with: MagnificationGesture())
        .onChanged { rotation, scale in
            // Both at once
        }
)
```

### Sequential Long Press → Drag
```swift
.gesture(
    LongPressGesture()
        .sequenced(before: DragGesture())
        .onChanged { value in
            switch value {
            case .first: /* pressing */
            case .second(true, let drag): /* dragging */
            }
        }
)
```

### Exclusive Tap OR Long Press
```swift
.gesture(
    TapGesture()
        .exclusively(before: LongPressGesture())
        .onEnded { value in
            switch value {
            case .first: /* tap */
            case .second: /* long press */
            }
        }
)
```

### With Mask
```swift
.gesture(TapGesture(), including: .gesture)  // Only this view
```

## All Gesture Types

- `TapGesture` → `Void`
- `SpatialTapGesture` → `CGPoint`
- `LongPressGesture` → `Bool`
- `DragGesture` → `DragGesture.Value`
- `RotationGesture` → `Angle`
- `MagnificationGesture` → `Double`

## Files Created

1. `/Sources/Raven/Modifiers/GestureModifier.swift`
2. `/Sources/Raven/Gestures/GestureComposition.swift`
3. `/Tests/RavenTests/GestureModifierTests.swift` (32 tests)
4. `/Tests/RavenTests/GestureCompositionTests.swift` (49 tests)
5. `/Tests/RavenTests/Phase13Examples.swift` (11 tests)
