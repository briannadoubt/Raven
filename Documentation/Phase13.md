# Phase 13: Gesture System

**Version:** 0.7.0
**Release Date:** 2026-02-03
**Status:** Complete ✅

## Table of Contents

- [Overview](#overview)
- [Gesture System Architecture](#gesture-system-architecture)
- [Gesture Protocol](#gesture-protocol)
  - [Core Concepts](#core-concepts)
  - [Creating Custom Gestures](#creating-custom-gestures)
  - [Gesture Values](#gesture-values)
- [Built-in Gestures](#built-in-gestures)
  - [TapGesture](#tapgesture)
  - [SpatialTapGesture](#spatialtapgesture)
  - [LongPressGesture](#longpressgesture)
  - [DragGesture](#draggesture)
  - [RotationGesture](#rotationgesture)
  - [MagnificationGesture](#magnificationgesture)
- [GestureState](#gesturestate)
  - [Property Wrapper Basics](#property-wrapper-basics)
  - [Automatic Reset](#automatic-reset)
  - [Transaction Support](#transaction-support)
- [Gesture Modifiers](#gesture-modifiers)
  - [onChanged](#onchanged)
  - [onEnded](#onended)
  - [updating](#updating)
- [View Gesture Integration](#view-gesture-integration)
  - [.gesture()](#gesture)
  - [.simultaneousGesture()](#simultaneousgesture)
  - [.highPriorityGesture()](#highprioritygesture)
  - [GestureMask Options](#gesturemask-options)
- [Gesture Composition](#gesture-composition)
  - [simultaneously(with:)](#simultaneouslywith)
  - [sequenced(before:)](#sequencedbefore)
  - [exclusively(before:)](#exclusivelybefore)
- [Event Modifiers](#event-modifiers)
- [Web Implementation Details](#web-implementation-details)
- [Browser Compatibility](#browser-compatibility)
- [Performance Considerations](#performance-considerations)
- [Common Patterns](#common-patterns)
- [Testing & Quality](#testing--quality)
- [Future Enhancements](#future-enhancements)

---

## Overview

Phase 13 brings Raven's SwiftUI API compatibility from ~85% to ~90% by introducing a comprehensive gesture recognition system. This release focuses on six key areas:

1. **Gesture Protocol** - Foundation for all gesture types with composability
2. **6 Built-in Gestures** - Tap, spatial tap, long press, drag, rotation, magnification
3. **GestureState** - Property wrapper for transient gesture state management
4. **Gesture Modifiers** - onChanged, onEnded, updating for gesture lifecycle
5. **View Integration** - Three gesture attachment methods with priority control
6. **Gesture Composition** - Combine gestures with simultaneously, sequenced, exclusively

### Key Highlights

- **194+ Comprehensive Tests** - Full test coverage for all gesture features
- **iOS 17+ Compatible** - Modern gesture APIs with full SwiftUI alignment
- **Web Platform Integration** - Mouse, touch, and pointer event mapping
- **Type-Safe** - Full Swift 6.2 concurrency support with `@MainActor` isolation
- **Composable** - Rich gesture composition system for complex interactions
- **Transaction Support** - Gesture state updates integrate with animation system

### Statistics

- **Files Added:** 10 new files
  - Gesture.swift (458 lines) - Protocol and foundation types
  - GestureState.swift (247 lines) - @GestureState property wrapper
  - TapGesture.swift (203 lines) - Tap gesture implementation
  - SpatialTapGesture.swift (225 lines) - Location-aware tap gesture
  - LongPressGesture.swift (311 lines) - Long press gesture
  - DragGesture.swift (589 lines) - Drag gesture with full value tracking
  - RotationGesture.swift (287 lines) - Two-finger rotation gesture
  - MagnificationGesture.swift (255 lines) - Pinch-to-zoom gesture
  - GestureComposition.swift (1,171 lines) - Gesture composition operators
  - GestureModifier.swift (778 lines) - View gesture integration
- **Lines of Code:** ~5,224 lines of production code
- **Test Coverage:** 194+ tests across 9 test files
- **Test Code:** ~3,782 lines of test code
- **API Coverage:** Increased from ~85% to ~90%

---

## Gesture System Architecture

Raven's gesture system is built on a protocol-oriented architecture that enables composition and reusability:

```
┌─────────────────────────────────────┐
│         Gesture Protocol            │
│   (Value type, composability)       │
└──────────────┬──────────────────────┘
               │
               ├──────────────────────────────────────┐
               ▼                                      ▼
┌─────────────────────────────────┐  ┌─────────────────────────────────┐
│     Primitive Gestures          │  │    Composed Gestures            │
│  (Tap, Drag, LongPress, etc.)   │  │  (Simultaneously, Sequenced,    │
│                                 │  │   Exclusively)                  │
└──────────────┬──────────────────┘  └──────────────┬──────────────────┘
               │                                      │
               └──────────────┬───────────────────────┘
                              ▼
               ┌─────────────────────────────────────┐
               │      Gesture Modifiers              │
               │  (.onChanged, .onEnded, .updating)  │
               └──────────────┬──────────────────────┘
                              ▼
               ┌─────────────────────────────────────┐
               │     View Integration                │
               │  (.gesture, .simultaneousGesture,   │
               │   .highPriorityGesture)             │
               └──────────────┬──────────────────────┘
                              ▼
               ┌─────────────────────────────────────┐
               │      Web Event System               │
               │  (Mouse, Touch, Pointer Events)     │
               └─────────────────────────────────────┘
```

### How It Works

1. **Gesture Definition**: Define gestures using the `Gesture` protocol
2. **Gesture Composition**: Combine gestures using composition operators
3. **Lifecycle Modifiers**: Add `onChanged`, `onEnded`, or `updating` handlers
4. **View Attachment**: Attach to views using `.gesture()` family of modifiers
5. **Event Mapping**: Web events trigger gesture recognition
6. **State Updates**: Gesture values flow through `@GestureState` or callbacks
7. **UI Response**: Views update based on gesture state changes

---

## Gesture Protocol

The `Gesture` protocol is the foundation of gesture recognition in Raven. It defines a gesture as something that can track user interaction and produce a value over time.

### Core Concepts

```swift
@MainActor
public protocol Gesture: Sendable {
    associatedtype Value: Sendable
    associatedtype Body: Gesture

    @MainActor
    var body: Body { get }
}
```

**Key Properties:**

- **Value**: The type of data produced during gesture recognition
  - `Void` for simple taps
  - `CGPoint` for location-based gestures
  - Complex structs for gestures with rich data (drag, rotation)

- **Body**: The gesture composition body
  - `Never` for primitive gestures (tap, drag, etc.)
  - Composed gesture type for composite gestures

- **Sendable**: All gestures must be thread-safe
  - Ensures safe concurrent access
  - Required by Swift 6.2 strict concurrency

### Creating Custom Gestures

To create a custom gesture, conform to the `Gesture` protocol:

```swift
struct MyCustomGesture: Gesture {
    typealias Value = CGPoint

    var body: Never {
        fatalError("This gesture has no body")
    }
}
```

**Primitive gestures** have `Never` as their body type and perform their work directly:

```swift
struct TripleTapGesture: Gesture {
    typealias Value = Void

    var body: Never {
        fatalError("Primitive gesture")
    }
}
```

**Composite gestures** combine other gestures:

```swift
struct DragAndRotateGesture: Gesture {
    typealias Value = (DragGesture.Value, Angle)

    var body: some Gesture {
        DragGesture()
            .simultaneously(with: RotationGesture())
    }
}
```

### Gesture Values

Each gesture produces a specific value type during recognition:

| Gesture | Value Type | Contains |
|---------|------------|----------|
| `TapGesture` | `Void` | Nothing (tap happened) |
| `SpatialTapGesture` | `CGPoint` | Tap location |
| `LongPressGesture` | `Bool` | Whether minimum duration met |
| `DragGesture` | `DragGesture.Value` | Location, translation, velocity |
| `RotationGesture` | `Angle` | Rotation angle |
| `MagnificationGesture` | `CGFloat` | Scale/magnification amount |

---

## Built-in Gestures

Raven provides 6 built-in gesture types covering the most common interaction patterns.

### TapGesture

A gesture that recognizes one or more taps.

#### Basic Usage

```swift
@State private var tapCount = 0

var body: some View {
    Circle()
        .fill(Color.blue)
        .frame(width: 100, height: 100)
        .gesture(
            TapGesture()
                .onEnded {
                    tapCount += 1
                }
        )
}
```

#### Multiple Taps

```swift
// Double-tap gesture
TapGesture(count: 2)
    .onEnded {
        print("Double tapped!")
    }

// Triple-tap gesture
TapGesture(count: 3)
    .onEnded {
        print("Triple tapped!")
    }
```

#### Properties

- **count**: Number of taps required (default: 1)
- **Value**: `Void` (no data, just that tap occurred)

#### Web Implementation

Maps to JavaScript `click` event:
- Single tap: Standard click detection
- Multiple taps: Track clicks within time window (~300ms)
- Touch support: Handles both mouse and touch events

#### Use Cases

- Button-like interactions
- Toggle actions
- Menu item selection
- Dismissing overlays

---

### SpatialTapGesture

A gesture that recognizes taps and provides the location where the tap occurred.

#### Basic Usage

```swift
@State private var tapLocation: CGPoint = .zero

var body: some View {
    Rectangle()
        .fill(Color.gray)
        .frame(width: 300, height: 200)
        .gesture(
            SpatialTapGesture()
                .onEnded { location in
                    tapLocation = location
                }
        )
        .overlay(
            Circle()
                .fill(Color.red)
                .frame(width: 10, height: 10)
                .position(tapLocation)
        )
}
```

#### Coordinate Systems

```swift
SpatialTapGesture(coordinateSpace: .local)  // Default
SpatialTapGesture(coordinateSpace: .global)
SpatialTapGesture(coordinateSpace: .named("custom"))
```

**Coordinate spaces:**
- `.local` - Relative to the view (0,0 at top-left of view)
- `.global` - Relative to window (0,0 at top-left of window)
- `.named(_)` - Relative to named coordinate space

#### Properties

- **count**: Number of taps required (default: 1)
- **coordinateSpace**: Where to measure tap location
- **Value**: `CGPoint` (tap location in specified space)

#### Web Implementation

Uses `MouseEvent` / `TouchEvent` coordinates:
- `event.offsetX`, `event.offsetY` for local coordinates
- `event.clientX`, `event.clientY` for global coordinates
- Transforms coordinates based on coordinate space

#### Use Cases

- Drawing and painting apps
- Interactive maps
- Placing objects at tap location
- Click-to-position interactions

---

### LongPressGesture

A gesture that recognizes a long press (touch and hold).

#### Basic Usage

```swift
@State private var isPressed = false

var body: some View {
    Text("Press and hold")
        .padding()
        .background(isPressed ? Color.red : Color.blue)
        .gesture(
            LongPressGesture(minimumDuration: 1.0)
                .onChanged { isPressing in
                    isPressed = isPressing
                }
                .onEnded { _ in
                    print("Long press completed!")
                    isPressed = false
                }
        )
}
```

#### Custom Parameters

```swift
// Shorter duration
LongPressGesture(minimumDuration: 0.5)

// With maximum distance (prevents accidental movement)
LongPressGesture(
    minimumDuration: 1.0,
    maximumDistance: 10  // Cancel if moved more than 10 points
)
```

#### Value Type

`LongPressGesture.Value` is a `Bool`:
- `false` - Initial press, minimum duration not yet met
- `true` - Minimum duration met, gesture succeeded

#### Properties

- **minimumDuration**: Time (in seconds) required for long press
- **maximumDistance**: Maximum movement allowed (in points)
- **Value**: `Bool` (has minimum duration been met?)

#### Web Implementation

- Timer-based detection
- Tracks `pointerdown` → wait → `pointerup`
- Cancels if pointer moves beyond maximum distance
- Uses `setTimeout` for duration tracking

#### Use Cases

- Context menus
- Drag-and-drop initiation
- Alternative actions (vs. tap)
- Haptic feedback triggers

---

### DragGesture

A gesture that recognizes a dragging motion and provides location, translation, and velocity information.

#### Basic Usage

```swift
@State private var offset = CGSize.zero

var body: some View {
    Circle()
        .fill(Color.blue)
        .frame(width: 100, height: 100)
        .offset(offset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    offset = value.translation
                }
                .onEnded { _ in
                    offset = .zero
                }
        )
}
```

#### DragGesture.Value

Rich value type containing all drag information:

```swift
public struct Value {
    /// The location of the drag gesture's current event.
    public var location: CGPoint

    /// The time at which the drag gesture's current event occurred.
    public var time: Date

    /// The location of the drag gesture's first event.
    public var startLocation: CGPoint

    /// The translation of the drag gesture from start to current event.
    public var translation: CGSize

    /// The velocity of the drag gesture.
    public var velocity: CGSize

    /// The predicted end location if the drag gesture continues.
    public var predictedEndLocation: CGPoint

    /// The predicted translation if the drag gesture continues.
    public var predictedEndTranslation: CGSize
}
```

#### Minimum Distance

Control when drag starts:

```swift
// Start immediately (default)
DragGesture()

// Require 10 points of movement before starting
DragGesture(minimumDistance: 10)

// Require 20 points (prevents accidental drags)
DragGesture(minimumDistance: 20)
```

#### Coordinate Spaces

```swift
// Local coordinates (relative to view)
DragGesture(coordinateSpace: .local)

// Global coordinates (relative to window)
DragGesture(coordinateSpace: .global)

// Named coordinate space
DragGesture(coordinateSpace: .named("container"))
```

#### Advanced Patterns

**Constrained Dragging:**
```swift
@State private var position = CGPoint(x: 150, y: 150)

DragGesture()
    .onChanged { value in
        // Constrain to horizontal axis
        position.x = value.location.x
        // Keep y fixed
    }
```

**Snap Back Animation:**
```swift
@State private var offset = CGSize.zero

DragGesture()
    .onChanged { value in
        offset = value.translation
    }
    .onEnded { value in
        withAnimation(.spring()) {
            offset = .zero
        }
    }
```

**Velocity-Based Flick:**
```swift
DragGesture()
    .onEnded { value in
        let speed = sqrt(
            value.velocity.width * value.velocity.width +
            value.velocity.height * value.velocity.height
        )

        if speed > 1000 {
            // Fast flick detected
            dismissView()
        }
    }
```

#### Web Implementation

- Uses `pointermove` events for tracking
- Calculates velocity from position history
- Predicts end location using velocity
- Handles coordinate space transformations
- Efficient event throttling for performance

#### Use Cases

- Draggable elements
- Swipe to dismiss
- Reorderable lists
- Pan gestures for maps/images
- Custom sliders and controls

---

### RotationGesture

A gesture that recognizes a rotation motion made with two fingers (pinch and rotate).

#### Basic Usage

```swift
@State private var rotation = Angle.zero

var body: some View {
    Rectangle()
        .fill(Color.blue)
        .frame(width: 200, height: 200)
        .rotationEffect(rotation)
        .gesture(
            RotationGesture()
                .onChanged { angle in
                    rotation = angle
                }
        )
}
```

#### Value Type

- **Value**: `Angle` (rotation amount from start of gesture)
- Positive angles: Clockwise rotation
- Negative angles: Counter-clockwise rotation

#### With @GestureState

```swift
@GestureState private var rotationAngle = Angle.zero
@State private var finalRotation = Angle.zero

var body: some View {
    Rectangle()
        .fill(Color.blue)
        .rotationEffect(finalRotation + rotationAngle)
        .gesture(
            RotationGesture()
                .updating($rotationAngle) { value, state, _ in
                    state = value
                }
                .onEnded { value in
                    finalRotation += value
                }
        )
}
```

#### Web Implementation

- Tracks two-finger touch gestures
- Calculates angle between touch points
- Uses `atan2` for angle computation
- Handles touch point updates in real-time
- Falls back gracefully on desktop (no two-finger support)

#### Use Cases

- Rotating images and objects
- Photo editing apps
- Interactive 3D viewers
- Orientation-based games
- Multi-touch interfaces

---

### MagnificationGesture

A gesture that recognizes a scaling motion (pinch-to-zoom) made with two fingers.

#### Basic Usage

```swift
@State private var scale: CGFloat = 1.0

var body: some View {
    Image("photo")
        .resizable()
        .aspectRatio(contentMode: .fit)
        .scaleEffect(scale)
        .gesture(
            MagnificationGesture()
                .onChanged { value in
                    scale = value
                }
        )
}
```

#### Value Type

- **Value**: `CGFloat` (magnification/scale factor)
- `1.0` = No scaling (initial size)
- `> 1.0` = Zoomed in (larger)
- `< 1.0` = Zoomed out (smaller)

#### Minimum Scale Delta

Control gesture sensitivity:

```swift
// Start immediately (default: 0.01)
MagnificationGesture()

// Require more movement before starting
MagnificationGesture(minimumScaleDelta: 0.1)
```

#### Combined with Drag

```swift
@State private var scale: CGFloat = 1.0
@State private var offset = CGSize.zero

var body: some View {
    Image("photo")
        .scaleEffect(scale)
        .offset(offset)
        .gesture(
            MagnificationGesture()
                .simultaneously(with: DragGesture())
                .onChanged { value in
                    if let magnification = value.first {
                        scale = magnification
                    }
                    if let drag = value.second {
                        offset = drag.translation
                    }
                }
        )
}
```

#### Web Implementation

- Tracks distance between two touch points
- Calculates scale ratio from initial distance
- Uses Pythagorean theorem for distance
- Updates scale in real-time as fingers move
- Desktop: Falls back to mouse wheel zoom (optional)

#### Use Cases

- Photo/image viewers
- Maps with zoom
- PDF readers
- Drawing canvas zoom
- Multi-touch zoom interfaces

---

## GestureState

A property wrapper that manages transient gesture state that automatically resets when the gesture ends.

### Property Wrapper Basics

```swift
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
```

**Key Characteristics:**

1. **Transient**: State only exists during gesture
2. **Auto-Reset**: Returns to initial value when gesture ends
3. **No Manual Reset**: Don't need to reset in `onEnded`
4. **Read-Only in View**: Only updated via `.updating()` modifier

### Automatic Reset

`@GestureState` automatically resets to its initial value when the gesture ends:

```swift
@GestureState private var isPressed = false

// isPressed becomes true during long press
// Automatically resets to false when gesture ends
LongPressGesture()
    .updating($isPressed) { current, state, _ in
        state = current
    }
```

**Reset Timing:**
- Gesture completes → Reset to initial value
- Gesture cancels → Reset to initial value
- New gesture starts → Uses fresh initial value

### Transaction Support

The `.updating()` modifier provides a `Transaction` parameter for animation control:

```swift
@GestureState private var dragOffset = CGSize.zero

DragGesture()
    .updating($dragOffset) { value, state, transaction in
        transaction.animation = .spring()
        state = value.translation
    }
```

**Transaction Properties:**
- `animation`: Animation to apply to state updates
- `disablesAnimations`: Disable animations for this update

### Initial Value Patterns

**With Default Value:**
```swift
@GestureState private var scale: CGFloat = 1.0
```

**With Complex Type:**
```swift
struct DragInfo {
    var translation = CGSize.zero
    var isPressing = false
}

@GestureState private var dragInfo = DragInfo()
```

**With Optional:**
```swift
@GestureState private var activeLocation: CGPoint?

SpatialTapGesture()
    .updating($activeLocation) { value, state, _ in
        state = value
    }
```

### GestureState vs State

| Feature | @GestureState | @State |
|---------|---------------|--------|
| Auto-reset | ✅ Yes | ❌ No |
| Persistent | ❌ No | ✅ Yes |
| Manual reset | Not needed | Required |
| Use case | Transient gesture state | Persistent view state |
| Update method | `.updating()` | Direct assignment |

### Common Patterns

**Temporary Offset:**
```swift
@GestureState private var offset = CGSize.zero
@State private var position = CGSize.zero

var body: some View {
    Circle()
        .offset(x: position.width + offset.width,
                y: position.height + offset.height)
        .gesture(
            DragGesture()
                .updating($offset) { value, state, _ in
                    state = value.translation
                }
                .onEnded { value in
                    position.width += value.translation.width
                    position.height += value.translation.height
                }
        )
}
```

**Temporary Scale:**
```swift
@GestureState private var magnification: CGFloat = 1.0
@State private var scale: CGFloat = 1.0

var body: some View {
    Image("photo")
        .scaleEffect(scale * magnification)
        .gesture(
            MagnificationGesture()
                .updating($magnification) { value, state, _ in
                    state = value
                }
                .onEnded { value in
                    scale *= value
                }
        )
}
```

**Press Indication:**
```swift
@GestureState private var isDetectingLongPress = false

var body: some View {
    Text("Press Me")
        .foregroundColor(isDetectingLongPress ? .red : .blue)
        .gesture(
            LongPressGesture(minimumDuration: 1.0)
                .updating($isDetectingLongPress) { current, state, _ in
                    state = current
                }
                .onEnded { _ in
                    // Action after long press
                }
        )
}
```

---

## Gesture Modifiers

Gesture modifiers allow you to respond to gesture lifecycle events and update state.

### onChanged

Called continuously as the gesture value changes during recognition.

```swift
DragGesture()
    .onChanged { value in
        print("Dragging to: \(value.location)")
    }
```

**When it's called:**
- As soon as gesture begins
- Every time gesture value updates
- Until gesture ends or cancels

**Use cases:**
- Real-time visual feedback
- Continuous updates (drag, rotate, magnify)
- Progress tracking

### onEnded

Called once when the gesture successfully completes.

```swift
DragGesture()
    .onEnded { value in
        print("Drag ended at: \(value.location)")
        finalizePosition(value)
    }
```

**When it's called:**
- When gesture completes successfully
- NOT called if gesture is canceled
- After all `onChanged` calls

**Use cases:**
- Commit changes
- Trigger actions after gesture
- Finalize state

### updating

Updates a `@GestureState` value during gesture recognition with automatic reset.

```swift
@GestureState private var offset = CGSize.zero

DragGesture()
    .updating($offset) { value, state, transaction in
        state = value.translation
    }
```

**Parameters:**
- `value`: Current gesture value
- `state`: `inout` binding to update
- `transaction`: Transaction for animation control

**When it's called:**
- Same timing as `onChanged`
- Automatically resets when gesture ends

**Use cases:**
- Temporary visual changes
- Preview effects
- State that should reset after gesture

### Chaining Modifiers

You can chain multiple modifiers:

```swift
LongPressGesture()
    .onChanged { isPressing in
        // Update visual feedback
        isActive = isPressing
    }
    .onEnded { _ in
        // Trigger action
        performLongPressAction()
    }
```

Or use with `@GestureState` and `onEnded`:

```swift
@GestureState private var dragOffset = CGSize.zero

DragGesture()
    .updating($dragOffset) { value, state, _ in
        state = value.translation  // Temporary offset
    }
    .onEnded { value in
        finalPosition += value.translation  // Commit final position
    }
```

---

## View Gesture Integration

Attach gestures to views using three modifier methods, each with different priority behavior.

### .gesture()

Standard gesture attachment with normal priority.

```swift
Circle()
    .gesture(
        TapGesture()
            .onEnded {
                print("Tapped!")
            }
    )
```

**Priority:**
- Normal priority
- Can be blocked by child gestures
- Most common usage

**With GestureMask:**
```swift
VStack {
    Text("Tap the circle")
    Circle()
        .gesture(
            TapGesture().onEnded { print("Circle tapped") },
            including: .gesture  // Only circle, not text
        )
}
```

### .simultaneousGesture()

Allows gesture to run simultaneously with other gestures in the hierarchy.

```swift
ScrollView {
    ForEach(items) { item in
        ItemRow(item: item)
            .simultaneousGesture(
                TapGesture()
                    .onEnded {
                        selectItem(item)
                    }
            )
    }
}
```

**Behavior:**
- Runs at same time as scroll gesture
- Doesn't block or cancel other gestures
- Both gestures can succeed

**Use cases:**
- Taps within scrollable areas
- Multiple independent interactions
- Non-conflicting gestures

### .highPriorityGesture()

Gives gesture higher priority than child gestures.

```swift
VStack {
    Button("Click Me") {
        print("Button action")
    }
}
.highPriorityGesture(
    TapGesture()
        .onEnded {
            print("Container tapped")
        }
)
```

**Priority:**
- Takes precedence over child gestures
- Blocks children from receiving gesture
- Parent wins in conflicts

**Use cases:**
- Override child gesture behavior
- Container-level gesture handling
- Gesture hijacking

### GestureMask Options

Control where gestures are recognized:

```swift
.gesture(drag, including: .all)        // View and subviews (default)
.gesture(drag, including: .gesture)     // Only this view
.gesture(drag, including: .subviews)    // Only subviews
.gesture(drag, including: .none)        // Disable gesture
```

**Options:**

| Mask | View | Subviews | Use Case |
|------|------|----------|----------|
| `.all` | ✅ | ✅ | Default behavior |
| `.gesture` | ✅ | ❌ | Gesture only on this view |
| `.subviews` | ❌ | ✅ | Gesture only in children |
| `.none` | ❌ | ❌ | Disable gesture |

**Example - Prevent Subview Gestures:**
```swift
ScrollView {
    ForEach(items) { item in
        ItemView(item: item)
    }
}
.gesture(
    DragGesture(),
    including: .gesture  // Only ScrollView, not items
)
```

---

## Gesture Composition

Combine multiple gestures to create complex interactions.

### simultaneously(with:)

Both gestures recognize at the same time.

```swift
Rectangle()
    .gesture(
        DragGesture()
            .simultaneously(with: MagnificationGesture())
            .onChanged { value in
                // value.first is Optional<DragGesture.Value>
                // value.second is Optional<MagnificationGesture.Value>
                if let drag = value.first {
                    position = drag.translation
                }
                if let magnification = value.second {
                    scale = magnification
                }
            }
    )
```

**Value Type:**
- `SimultaneousGesture<G1, G2>.Value`
- Tuple: `(first: G1.Value?, second: G2.Value?)`
- Both values optional (gestures may not be active simultaneously)

**Behavior:**
- Both gestures run in parallel
- Neither blocks the other
- Both can succeed or fail independently

**Use cases:**
- Pan and zoom together
- Drag and rotate simultaneously
- Independent multi-touch interactions

### sequenced(before:)

Second gesture begins after first gesture ends.

```swift
Circle()
    .gesture(
        LongPressGesture()
            .sequenced(before: DragGesture())
            .onEnded { value in
                switch value {
                case .first(let longPress):
                    print("Long press ended: \(longPress)")
                case .second(let longPress, let drag):
                    print("Sequence complete")
                    if let drag = drag {
                        print("Dragged: \(drag.translation)")
                    }
                }
            }
    )
```

**Value Type:**
- `SequenceGesture<G1, G2>.Value`
- Enum with two cases:
  - `.first(G1.Value)` - First gesture completed
  - `.second(G1.Value, G2.Value?)` - Sequence complete

**Behavior:**
- First gesture must complete successfully
- Second gesture then activates
- If first fails, sequence fails
- Second gesture is optional

**Use cases:**
- Long press then drag (reordering lists)
- Tap then hold (custom interactions)
- Multi-step gestures

### exclusively(before:)

First gesture to recognize wins, blocking the other.

```swift
Rectangle()
    .gesture(
        DragGesture(minimumDistance: 0)
            .exclusively(before: TapGesture())
            .onEnded { value in
                switch value {
                case .first(let drag):
                    print("Dragged: \(drag.translation)")
                case .second(let tap):
                    print("Tapped!")
                }
            }
    )
```

**Value Type:**
- `ExclusiveGesture<G1, G2>.Value`
- Enum with two cases:
  - `.first(G1.Value)` - First gesture won
  - `.second(G2.Value)` - Second gesture won

**Behavior:**
- First gesture gets first chance
- If first fails/delays, second gesture can activate
- Only one gesture succeeds
- Winner blocks the other

**Use cases:**
- Drag vs tap disambiguation
- Swipe vs scroll
- Custom vs default behavior

### Complex Compositions

Nest compositions for sophisticated interactions:

```swift
Circle()
    .gesture(
        DragGesture()
            .simultaneously(
                with: MagnificationGesture()
                    .simultaneously(with: RotationGesture())
            )
    )
```

**Multi-level composition:**
```swift
let dragAndZoom = DragGesture()
    .simultaneously(with: MagnificationGesture())

let rotateOrTap = RotationGesture()
    .exclusively(before: TapGesture())

let complexGesture = dragAndZoom
    .simultaneously(with: rotateOrTap)
```

---

## Event Modifiers

Detect keyboard modifier keys pressed during gestures.

### EventModifiers Type

```swift
public struct EventModifiers: OptionSet {
    public static let capsLock: EventModifiers
    public static let shift: EventModifiers
    public static let control: EventModifiers
    public static let option: EventModifiers
    public static let command: EventModifiers
    public static let numericPad: EventModifiers
    public static let function: EventModifiers
}
```

### Usage in Gestures

Available in gesture values that support modifiers (like `DragGesture`):

```swift
DragGesture()
    .onChanged { value in
        if value.modifiers.contains(.shift) {
            // Constrain drag to one axis
            let dx = abs(value.translation.width)
            let dy = abs(value.translation.height)
            offset = dx > dy
                ? CGSize(width: value.translation.width, height: 0)
                : CGSize(width: 0, height: value.translation.height)
        } else {
            // Free drag
            offset = value.translation
        }
    }
```

### Platform Mappings

| Modifier | macOS | Windows | Linux | Web |
|----------|-------|---------|-------|-----|
| `.shift` | Shift | Shift | Shift | `shiftKey` |
| `.control` | Control | Control | Control | `ctrlKey` |
| `.option` | Option (⌥) | Alt | Alt | `altKey` |
| `.command` | Command (⌘) | Windows | Super/Meta | `metaKey` |

### Common Patterns

**Constrained Movement:**
```swift
if value.modifiers.contains(.shift) {
    // Snap to 45-degree angles or axis-aligned
}
```

**Alternative Actions:**
```swift
.onEnded { value in
    if value.modifiers.contains(.option) {
        duplicate(at: value.location)
    } else {
        move(to: value.location)
    }
}
```

**Multi-Selection:**
```swift
if value.modifiers.contains(.command) {
    addToSelection(item)
} else {
    selectOnly(item)
}
```

---

## Web Implementation Details

Raven's gesture system maps to native web events for optimal performance.

### Event Mapping

| Gesture | Primary Events | Secondary Events |
|---------|----------------|------------------|
| **Tap** | `click` | `pointerdown`, `pointerup` |
| **SpatialTap** | `click` | `MouseEvent` coordinates |
| **LongPress** | `pointerdown` + timer | `pointerup`, `pointermove` |
| **Drag** | `pointermove` | `pointerdown`, `pointerup` |
| **Rotation** | `touchmove` (2 fingers) | `touchstart`, `touchend` |
| **Magnification** | `touchmove` (2 fingers) | `touchstart`, `touchend` |

### Pointer Events

Raven uses Pointer Events API for unified mouse/touch handling:

```javascript
element.addEventListener('pointerdown', handleStart);
element.addEventListener('pointermove', handleMove);
element.addEventListener('pointerup', handleEnd);
element.addEventListener('pointercancel', handleCancel);
```

**Benefits:**
- Single API for mouse, touch, and pen
- Automatic touch point tracking
- Pointer capture support
- Better performance than mouse + touch

### Touch Gesture Detection

Multi-touch gestures (rotation, magnification) use touch events:

```javascript
element.addEventListener('touchstart', handleTouchStart);
element.addEventListener('touchmove', handleTouchMove);
element.addEventListener('touchend', handleTouchEnd);

// Track two-finger gestures
function handleTouchMove(event) {
    if (event.touches.length === 2) {
        // Calculate rotation or magnification
    }
}
```

### Coordinate Transformations

Gesture coordinates are transformed based on coordinate space:

```javascript
// Local coordinates
const rect = element.getBoundingClientRect();
const localX = event.clientX - rect.left;
const localY = event.clientY - rect.top;

// Global coordinates
const globalX = event.clientX;
const globalY = event.clientY;

// Named coordinate space
const container = document.querySelector('[data-coordinate-space="name"]');
const containerRect = container.getBoundingClientRect();
const namedX = event.clientX - containerRect.left;
const namedY = event.clientY - containerRect.top;
```

### Velocity Calculation

Drag gesture calculates velocity from position history:

```javascript
const history = [];
const maxHistoryLength = 5;

function updatePosition(x, y, time) {
    history.push({ x, y, time });
    if (history.length > maxHistoryLength) {
        history.shift();
    }
}

function calculateVelocity() {
    if (history.length < 2) return { width: 0, height: 0 };

    const first = history[0];
    const last = history[history.length - 1];
    const dt = (last.time - first.time) / 1000; // Convert to seconds

    return {
        width: (last.x - first.x) / dt,
        height: (last.y - first.y) / dt
    };
}
```

### Event Cleanup

Gestures automatically clean up event listeners:

```javascript
class GestureRecognizer {
    attach() {
        this.element.addEventListener('pointerdown', this.handleStart);
        // ... other listeners
    }

    detach() {
        this.element.removeEventListener('pointerdown', this.handleStart);
        // ... remove all listeners
    }
}

// Automatic cleanup when view is removed
onViewRemoved() {
    recognizer.detach();
}
```

---

## Browser Compatibility

All Phase 13 gesture features support modern browsers:

### Event API Support

| Feature | Chrome | Firefox | Safari | Edge |
|---------|--------|---------|--------|------|
| **Pointer Events** | 55+ | 59+ | 13+ | 79+ |
| **Touch Events** | All | All | All | All |
| **Mouse Events** | All | All | All | All |
| **Event Modifiers** | All | All | All | All |

### Gesture Support Matrix

| Gesture | Desktop | Mobile | Tablet | Notes |
|---------|---------|--------|--------|-------|
| **Tap** | ✅ | ✅ | ✅ | Universal support |
| **SpatialTap** | ✅ | ✅ | ✅ | Universal support |
| **LongPress** | ✅ | ✅ | ✅ | Universal support |
| **Drag** | ✅ | ✅ | ✅ | Universal support |
| **Rotation** | ❌ | ✅ | ✅ | Requires multi-touch |
| **Magnification** | ❌ | ✅ | ✅ | Requires multi-touch |

### Fallback Strategies

**Desktop Rotation/Magnification:**
- No two-finger touch support
- Can implement using modifier keys:
  - Shift+Drag for rotation
  - Ctrl+Scroll for magnification
- Or use alternative UI (buttons, sliders)

**Touch Detection:**
```javascript
const hasTouch = 'ontouchstart' in window ||
                 navigator.maxTouchPoints > 0;

if (hasTouch) {
    // Enable multi-touch gestures
} else {
    // Use alternative input methods
}
```

### Progressive Enhancement

Gestures degrade gracefully:

1. **Best**: Pointer Events + Touch Events (modern browsers)
2. **Good**: Mouse Events + Touch Events (older browsers)
3. **Fallback**: Mouse Events only (very old browsers)

---

## Performance Considerations

### Event Throttling

High-frequency events (drag, rotate, magnify) are throttled:

```javascript
const throttle = (func, delay) => {
    let lastCall = 0;
    return (...args) => {
        const now = Date.now();
        if (now - lastCall >= delay) {
            lastCall = now;
            func(...args);
        }
    };
};

element.addEventListener('pointermove',
    throttle(handleMove, 16) // ~60fps
);
```

**Benefits:**
- Reduces CPU usage
- Maintains smooth 60fps
- Prevents UI thread blocking

### Touch Point Limits

Limit tracked touch points to essential gestures:

```javascript
const MAX_TOUCH_POINTS = 2; // Most gestures need 2

function handleTouchStart(event) {
    if (event.touches.length > MAX_TOUCH_POINTS) {
        // Ignore additional touches
        return;
    }
    // Process touches
}
```

### Memory Management

Gesture state is cleaned up automatically:

- Event listeners removed when view unmounts
- Gesture state released when gesture ends
- No memory leaks from long-running gestures

### Best Practices

1. **Use @GestureState for temporary values**
   - Automatic cleanup
   - No manual reset needed
   - Memory efficient

2. **Throttle high-frequency gestures**
   - Drag, rotate, magnify update frequently
   - Throttle to 60fps (16ms)
   - Balance responsiveness vs performance

3. **Minimize gesture nesting**
   - Deep gesture hierarchies slow recognition
   - Keep gesture trees shallow
   - Use composition instead of nesting

4. **Choose appropriate minimum distances**
   - Prevents accidental gesture activation
   - Reduces false positives
   - Improves gesture disambiguation

5. **Cancel gestures when appropriate**
   - Release resources early
   - Improve responsiveness
   - Better user experience

---

## Common Patterns

### Draggable Card

```swift
struct DraggableCard: View {
    @State private var offset = CGSize.zero
    @State private var isDragging = false

    var body: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color.blue)
            .frame(width: 300, height: 200)
            .offset(offset)
            .scaleEffect(isDragging ? 1.05 : 1.0)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        offset = value.translation
                        isDragging = true
                    }
                    .onEnded { value in
                        withAnimation(.spring()) {
                            // Snap back if dragged less than threshold
                            if abs(value.translation.width) < 100 {
                                offset = .zero
                            } else {
                                // Dismiss card
                                dismissCard()
                            }
                            isDragging = false
                        }
                    }
            )
    }
}
```

### Zoomable Image

```swift
struct ZoomableImage: View {
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0

    var body: some View {
        Image("photo")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .scaleEffect(scale)
            .gesture(
                MagnificationGesture()
                    .onChanged { value in
                        scale = lastScale * value
                    }
                    .onEnded { _ in
                        lastScale = scale

                        // Clamp scale
                        if scale < 1.0 {
                            withAnimation {
                                scale = 1.0
                                lastScale = 1.0
                            }
                        } else if scale > 5.0 {
                            withAnimation {
                                scale = 5.0
                                lastScale = 5.0
                            }
                        }
                    }
            )
    }
}
```

### Long Press Menu

```swift
struct LongPressMenu: View {
    @State private var showMenu = false
    @State private var menuPosition = CGPoint.zero

    var body: some View {
        ZStack {
            Color.blue
                .frame(width: 200, height: 200)
                .simultaneousGesture(
                    LongPressGesture(minimumDuration: 0.5)
                        .simultaneously(with: SpatialTapGesture())
                        .onEnded { value in
                            if let location = value.second {
                                menuPosition = location
                                withAnimation {
                                    showMenu = true
                                }
                            }
                        }
                )

            if showMenu {
                ContextMenu(at: menuPosition)
                    .transition(.opacity)
            }
        }
    }
}
```

### Reorderable List

```swift
struct ReorderableList: View {
    @State private var items = ["A", "B", "C", "D"]
    @GestureState private var dragOffset = CGSize.zero
    @State private var draggingItem: String?

    var body: some View {
        VStack(spacing: 0) {
            ForEach(items, id: \.self) { item in
                ItemRow(item: item)
                    .offset(draggingItem == item ? dragOffset : .zero)
                    .gesture(
                        LongPressGesture(minimumDuration: 0.5)
                            .sequenced(before: DragGesture())
                            .updating($dragOffset) { value, state, _ in
                                switch value {
                                case .second(_, let drag):
                                    state = drag?.translation ?? .zero
                                default:
                                    break
                                }
                            }
                            .onChanged { value in
                                if case .second(_, let drag) = value {
                                    draggingItem = item
                                    // Update order based on drag?.translation
                                }
                            }
                            .onEnded { _ in
                                withAnimation {
                                    draggingItem = nil
                                }
                            }
                    )
            }
        }
    }
}
```

### Dismissible Modal

```swift
struct DismissibleModal: View {
    @Binding var isPresented: Bool
    @GestureState private var dragOffset = CGSize.zero

    var body: some View {
        VStack {
            Capsule()
                .fill(Color.gray)
                .frame(width: 40, height: 5)
                .padding(.top)

            Text("Modal Content")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color.white)
        .cornerRadius(20, corners: [.topLeft, .topRight])
        .offset(y: dragOffset.height)
        .gesture(
            DragGesture()
                .updating($dragOffset) { value, state, _ in
                    if value.translation.height > 0 {
                        state = value.translation
                    }
                }
                .onEnded { value in
                    if value.translation.height > 100 {
                        withAnimation {
                            isPresented = false
                        }
                    }
                }
        )
    }
}
```

---

## Testing & Quality

### Test Coverage

Phase 13 includes 194+ comprehensive tests across all gesture features:

#### Gesture Protocol Tests (20+ tests)
- Gesture conformance and type safety
- Value type validation
- Body type correctness
- Never gesture behavior
- Sendable compliance

#### Individual Gesture Tests (120+ tests)
- **TapGesture** (18 tests): Single/multiple taps, timing, cancellation
- **SpatialTapGesture** (20 tests): Location tracking, coordinate spaces
- **LongPressGesture** (22 tests): Duration, distance, cancellation
- **DragGesture** (35 tests): Translation, velocity, prediction, coordinate spaces
- **RotationGesture** (15 tests): Angle calculation, two-finger tracking
- **MagnificationGesture** (12 tests): Scale calculation, minimum delta

#### GestureState Tests (15+ tests)
- Property wrapper behavior
- Automatic reset on gesture end
- Transaction support
- Initial value handling
- Update mechanics

#### Gesture Modifier Tests (20+ tests)
- onChanged callback timing
- onEnded callback timing
- updating with @GestureState
- Modifier chaining
- Error cases

#### Gesture Composition Tests (25+ tests)
- simultaneously composition
- sequenced composition
- exclusively composition
- Nested compositions
- Complex multi-gesture scenarios

#### Integration Tests (15+ tests)
- View gesture attachment
- simultaneousGesture behavior
- highPriorityGesture priority
- GestureMask options
- Cross-gesture interactions

### Quality Metrics

- **Production Code**: ~5,224 lines
- **Test Code**: ~3,782 lines
- **Test-to-Code Ratio**: 0.72 (excellent coverage)
- **API Documentation**: 100% DocC coverage
- **Working Examples**: Multiple real-world patterns
- **Thread Safety**: Full `@MainActor` isolation
- **Sendable Compliance**: All types properly marked

### Running Tests

```bash
# Run all tests
swift test

# Run gesture-specific tests
swift test --filter GestureTests

# Run individual gesture tests
swift test --filter TapGestureTests
swift test --filter DragGestureTests
swift test --filter GestureCompositionTests
```

---

## Future Enhancements

### Planned Features

#### Additional Gesture Types
- **ScrollGesture** - Scroll wheel gesture recognition
- **HoverGesture** - Mouse hover detection
- **SwipeGesture** - Directional swipe recognition
- **EdgeGesture** - Screen edge swipe (for navigation)

#### Enhanced Recognition
- **Gesture priorities** - Fine-grained priority control
- **Gesture exclusivity** - Prevent gesture conflicts
- **Gesture requirements** - Conditional gesture activation
- **Gesture failure** - Custom failure conditions

#### Advanced Composition
- **Gesture groups** - Named gesture collections
- **Gesture sets** - Multiple alternative gestures
- **Gesture chains** - Extended sequence support
- **Dynamic composition** - Runtime gesture modification

#### Platform Features
- **Haptic feedback** - Gesture-triggered haptics (iOS/macOS)
- **Accessibility** - VoiceOver gesture support
- **Keyboard shortcuts** - Gesture keyboard equivalents
- **Trackpad gestures** - Force Touch, three-finger gestures

#### Developer Tools
- **Gesture debugger** - Visual gesture state inspection
- **Recognition visualizer** - See active gesture regions
- **Performance profiler** - Gesture recognition overhead
- **Testing utilities** - Gesture simulation for tests

### Under Consideration

- **Gesture recording** - Record and replay gestures
- **Machine learning** - Custom gesture training
- **3D gestures** - Depth-based interactions (VisionPro)
- **Voice gestures** - Voice + gesture combinations
- **Multi-device** - Gestures across devices

---

## Summary

Phase 13 delivers a comprehensive gesture system for Raven, bringing SwiftUI API compatibility from 85% to 90%. Key achievements:

✅ **Complete gesture protocol** - Foundation for all gesture types
✅ **6 built-in gestures** - Tap, spatial tap, long press, drag, rotation, magnification
✅ **@GestureState support** - Automatic state management with reset
✅ **Gesture modifiers** - onChanged, onEnded, updating
✅ **View integration** - Three attachment methods with priority control
✅ **Gesture composition** - simultaneously, sequenced, exclusively operators
✅ **Web implementation** - Pointer Events, Touch Events, coordinate transforms
✅ **194+ tests** - Comprehensive verification of all features
✅ **Complete documentation** - This guide plus full DocC comments

The gesture system is production-ready and provides a solid foundation for creating rich, interactive user interfaces in Raven.

---

**Version:** 0.7.0
**Last Updated:** 2026-02-03
**Status:** Complete ✅
