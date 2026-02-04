# Phase 12: Animation System

**Version:** 0.6.0
**Release Date:** 2026-02-03
**Status:** Complete ✅

## Table of Contents

- [Overview](#overview)
- [Animation System Architecture](#animation-system-architecture)
- [Animation Types & Curves](#animation-types--curves)
  - [Linear Animations](#linear-animations)
  - [Ease Animations](#ease-animations)
  - [Spring Animations](#spring-animations)
  - [Custom Timing Curves](#custom-timing-curves)
- [Implicit Animations (.animation())](#implicit-animations-animation)
  - [Basic Usage](#basic-usage)
  - [Value-Based Animations](#value-based-animations)
  - [Multiple Animations](#multiple-animations)
  - [Conditional Animations](#conditional-animations)
- [Explicit Animations (withAnimation())](#explicit-animations-withanimation)
  - [Basic withAnimation](#basic-withanimation)
  - [Completion Handlers](#completion-handlers)
  - [Nested Animations](#nested-animations)
  - [Animation Context](#animation-context)
- [Transition System](#transition-system)
  - [Built-in Transitions](#built-in-transitions)
  - [Combining Transitions](#combining-transitions)
  - [Asymmetric Transitions](#asymmetric-transitions)
  - [Advanced Transitions](#advanced-transitions)
  - [Custom Transitions](#custom-transitions)
- [Multi-Step Animations (keyframeAnimator())](#multi-step-animations-keyframeanimator)
  - [Keyframe Basics](#keyframe-basics)
  - [Keyframe Types](#keyframe-types)
  - [Multiple Tracks](#multiple-tracks)
  - [Triggers and Repeating](#triggers-and-repeating)
- [Web Implementation Details](#web-implementation-details)
  - [CSS Transitions](#css-transitions)
  - [CSS Animations](#css-animations)
  - [Transform Optimizations](#transform-optimizations)
  - [GPU Acceleration](#gpu-acceleration)
- [Performance Considerations](#performance-considerations)
- [Browser Compatibility](#browser-compatibility)
- [Common Patterns](#common-patterns)
- [Troubleshooting](#troubleshooting)
- [Migration Guide](#migration-guide)
- [Complete Examples](#complete-examples)
- [Testing & Quality](#testing--quality)
- [Future Enhancements](#future-enhancements)

---

## Overview

Phase 12 brings Raven's SwiftUI API compatibility from ~80% to ~85% by introducing a comprehensive animation system. This release focuses on six key areas:

1. **Animation Types** - Linear, ease, spring, and custom timing curves
2. **Implicit Animations** - .animation() modifier for automatic property animations
3. **Explicit Animations** - withAnimation() for controlled animation blocks
4. **Transitions** - View insertion and removal animations
5. **Keyframe Animations** - Multi-step animations with precise timing
6. **Web Platform Integration** - CSS transitions, animations, and GPU acceleration

### Key Highlights

- **50+ Integration Tests** - Comprehensive test coverage for all animation features
- **iOS 17+ Compatible** - Modern animation APIs including keyframeAnimator()
- **CSS-Based** - Efficient animations using native browser capabilities
- **GPU Accelerated** - Transform and opacity animations use hardware acceleration
- **Type-Safe** - Full Swift 6.2 concurrency support with @MainActor isolation
- **Interruptible** - Smooth animation interruption and cancellation
- **Flexible** - Multiple animation curves, timing functions, and composition

### Statistics

- **Files Added:** 7 new files
  - Animation.swift (567 lines) - Core animation types and curves
  - AnimationModifier.swift (289 lines) - .animation() modifier implementation
  - WithAnimation.swift (356 lines) - withAnimation() function
  - AnyTransition.swift (720 lines) - Transition system
  - TransitionModifier.swift (245 lines) - .transition() modifier
  - KeyframeAnimator.swift (487 lines) - keyframeAnimator() implementation
  - Phase12VerificationTests.swift (938 lines) - Integration tests
- **Lines of Code:** ~2,664 lines of production code
- **Test Coverage:** 50+ integration tests plus unit tests
- **Test Code:** ~938 lines of verification tests
- **Examples:** 10 complete working examples (~1,200+ lines)
- **API Coverage:** Increased from ~80% to ~85%

---

## Animation System Architecture

Raven's animation system is built on three core concepts:

1. **Animation Types** - Define how values change over time (linear, ease, spring)
2. **Animatable Properties** - Which properties can be animated (opacity, scale, position, etc.)
3. **Animation Context** - When and how animations are applied (implicit vs explicit)

### Animation Flow

```
User Action → State Change → Animation Trigger → CSS Generation → Browser Rendering
```

1. **User Action**: Button tap, gesture, timer, etc.
2. **State Change**: @State, @Binding, or other reactive property changes
3. **Animation Trigger**: .animation() modifier or withAnimation() block detects change
4. **CSS Generation**: Animation converted to CSS transitions or @keyframes
5. **Browser Rendering**: Native browser animation engine executes the animation

### Why CSS-Based?

Raven uses CSS for animations instead of JavaScript for several key reasons:

- **Performance**: CSS animations are GPU-accelerated and run on the compositor thread
- **Smooth**: 60fps animations even when JavaScript thread is busy
- **Native**: Browser optimization for CSS animations is mature and well-tested
- **Declarative**: Clean separation between animation definition and execution
- **Efficient**: No JavaScript overhead for animation frames

---

## Animation Types & Curves

Raven provides several animation curves that control how values change over time. Each curve creates a different visual feel and is appropriate for different UI scenarios.

### Linear Animations

Linear animations change values at a constant rate with no acceleration or deceleration.

#### Basic Linear

```swift
// Default linear animation (0.25 seconds)
Text("Fade In")
    .opacity(isVisible ? 1 : 0)
    .animation(.linear, value: isVisible)

// Custom duration
Text("Slow Fade")
    .opacity(isVisible ? 1 : 0)
    .animation(.linear(duration: 2.0), value: isVisible)
```

**Use cases:**
- Continuous rotations (loading spinners)
- Progress bars
- Scrolling animations
- When you want consistent, mechanical motion

**CSS Implementation:**
```css
transition: opacity 0.25s linear;
```

### Ease Animations

Ease animations add acceleration and deceleration for more natural motion. Raven provides four ease variants:

#### EaseIn

Starts slow and accelerates.

```swift
Text("Zoom In")
    .scaleEffect(isExpanded ? 1.5 : 1.0)
    .animation(.easeIn, value: isExpanded)

// Custom duration
.animation(.easeIn(duration: 0.5), value: isExpanded)
```

**Use cases:**
- Elements leaving the screen
- Dismissals and closures
- Zoom-outs

**CSS Implementation:**
```css
transition: transform 0.25s ease-in;
animation-timing-function: cubic-bezier(0.42, 0, 1.0, 1.0);
```

#### EaseOut

Starts fast and decelerates.

```swift
Text("Drop In")
    .offset(y: isShown ? 0 : -100)
    .animation(.easeOut, value: isShown)

// Custom duration
.animation(.easeOut(duration: 0.4), value: isShown)
```

**Use cases:**
- Elements entering the screen
- Reveals and presentations
- Zoom-ins
- Most button interactions

**CSS Implementation:**
```css
transition: transform 0.25s ease-out;
animation-timing-function: cubic-bezier(0, 0, 0.58, 1.0);
```

#### EaseInOut

Accelerates at the start and decelerates at the end.

```swift
Text("Smooth Move")
    .offset(x: position)
    .animation(.easeInOut, value: position)

// Custom duration
.animation(.easeInOut(duration: 0.6), value: position)
```

**Use cases:**
- Movements between states
- Page transitions
- Smooth repositioning
- General-purpose animation (most common choice)

**CSS Implementation:**
```css
transition: transform 0.25s ease-in-out;
animation-timing-function: cubic-bezier(0.42, 0, 0.58, 1.0);
```

#### Default (Ease)

Standard ease curve (similar to easeInOut but slightly different).

```swift
Text("Default Animation")
    .opacity(isVisible ? 1 : 0)
    .animation(.default, value: isVisible)
```

**CSS Implementation:**
```css
transition: opacity 0.25s ease;
animation-timing-function: cubic-bezier(0.25, 0.1, 0.25, 1.0);
```

### Spring Animations

Spring animations simulate physical spring behavior with damping and response characteristics. They create natural, bouncy motion and are Apple's recommended default for most animations.

#### Basic Spring

```swift
// Default spring (response: 0.5, damping: 1.0)
Circle()
    .scaleEffect(isPressed ? 0.9 : 1.0)
    .animation(.spring(), value: isPressed)
```

#### Custom Spring Parameters

```swift
// Bouncy spring (lower damping = more bounce)
Button("Tap Me") { }
    .scaleEffect(isPressed ? 0.95 : 1.0)
    .animation(
        .spring(response: 0.3, dampingFraction: 0.6),
        value: isPressed
    )

// Stiff spring (higher response = faster)
Text("Quick")
    .offset(x: position)
    .animation(
        .spring(response: 0.2, dampingFraction: 0.8),
        value: position
    )

// Loose spring (lower response = slower)
Text("Slow")
    .offset(y: position)
    .animation(
        .spring(response: 1.0, dampingFraction: 0.7),
        value: position
    )
```

#### Spring Parameters Explained

**Response** (duration):
- How long the spring takes to settle
- Lower values = faster animation
- Higher values = slower animation
- Typical range: 0.2 - 1.0 seconds

**Damping Fraction**:
- Controls bounciness
- 1.0 = critically damped (no bounce)
- 0.8 = slightly bouncy
- 0.6 = noticeably bouncy
- 0.4 = very bouncy
- < 0.3 = extreme bounce (usually too much)

#### Named Spring Configurations

```swift
// Predefined spring configurations
.animation(.spring(.bouncy), value: state)      // Bouncy, energetic
.animation(.spring(.smooth), value: state)      // Smooth, no bounce
.animation(.spring(.snappy), value: state)      // Quick, subtle bounce
```

**Use cases for springs:**
- Button press feedback (0.3s, 0.6-0.7 damping)
- Modal presentations (0.5s, 0.8 damping)
- Interactive dragging (0.4s, 0.7 damping)
- Natural motion (always prefer spring over ease when appropriate)
- Interruption-friendly animations

**CSS Implementation:**

Springs are approximated using CSS cubic-bezier curves since CSS doesn't have native spring physics:

```css
transition: transform 0.5s cubic-bezier(0.5, 1.8, 0.5, 0.8);
```

For true spring physics in critical scenarios, Raven can fall back to JavaScript-based animation (future enhancement).

### Custom Timing Curves

Create custom timing functions using cubic Bézier curves:

```swift
// Custom cubic curve
.animation(
    .timingCurve(0.17, 0.67, 0.83, 0.67, duration: 0.5),
    value: state
)
```

The four parameters (p1x, p1y, p2x, p2y) define the cubic Bézier control points:
- (0, 0) is the start
- (1, 1) is the end
- The two control points shape the curve

**Popular custom curves:**

```swift
// Material Design Standard
.timingCurve(0.4, 0.0, 0.2, 1.0, duration: 0.3)

// Material Design Deceleration
.timingCurve(0.0, 0.0, 0.2, 1.0, duration: 0.3)

// Material Design Acceleration
.timingCurve(0.4, 0.0, 1.0, 1.0, duration: 0.3)

// iOS Native (similar to default)
.timingCurve(0.25, 0.1, 0.25, 1.0, duration: 0.35)

// Bounce
.timingCurve(0.68, -0.55, 0.265, 1.55, duration: 0.5)
```

**CSS Implementation:**
```css
transition: transform 0.5s cubic-bezier(0.17, 0.67, 0.83, 0.67);
```

### Animation Comparison

| Animation | Speed | Bounce | Use Case | Default Duration |
|-----------|-------|--------|----------|------------------|
| `.linear` | Constant | None | Mechanical, continuous | 0.25s |
| `.easeIn` | Slow → Fast | None | Exits, zoom outs | 0.25s |
| `.easeOut` | Fast → Slow | None | Entries, zoom ins | 0.25s |
| `.easeInOut` | Slow → Fast → Slow | None | Transitions, moves | 0.25s |
| `.default` | Slight ease | None | General purpose | 0.25s |
| `.spring()` | Natural | Yes (variable) | Interactive, natural | ~0.5s |
| `.spring(.bouncy)` | Medium | High | Playful, energetic | ~0.5s |
| `.spring(.smooth)` | Smooth | None | Professional | ~0.5s |
| `.spring(.snappy)` | Fast | Subtle | Quick feedback | ~0.3s |

### Choosing an Animation Curve

**Quick Decision Tree:**

1. **Is it interactive/touchable?** → Spring (0.3s, 0.7 damping)
2. **Is it entering the screen?** → EaseOut or Spring
3. **Is it leaving the screen?** → EaseIn
4. **Is it moving between positions?** → EaseInOut or Spring
5. **Is it mechanical/continuous?** → Linear
6. **Not sure?** → Spring with default params (best general choice)

**Spring vs Ease:**

Use **Spring** when:
- Animation might be interrupted
- Element is interactive
- You want natural, physics-based motion
- Animation feels more important/prominent

Use **Ease** when:
- Animation is brief and simple
- Exact timing is critical
- You want mechanical, controlled motion
- Performance is critical (spring approximation has slight overhead)

---

## Implicit Animations (.animation())

The `.animation()` modifier automatically animates changes to animatable properties when a specified value changes.

### Basic Usage

```swift
@State private var isExpanded = false

var body: some View {
    Circle()
        .fill(Color.blue)
        .scaleEffect(isExpanded ? 1.5 : 1.0)
        .animation(.spring(), value: isExpanded)
        .onTapGesture {
            isExpanded.toggle()
        }
}
```

When `isExpanded` changes, the scale animates smoothly.

### Value-Based Animations

The `value` parameter determines when animations trigger:

```swift
@State private var rotation = 0.0

var body: some View {
    Rectangle()
        .fill(Color.red)
        .rotationEffect(.degrees(rotation))
        .animation(.easeInOut, value: rotation)  // Animate when rotation changes

    Button("Rotate") {
        rotation += 45
    }
}
```

**Important**: The animation only triggers when the `value` parameter changes. This prevents animations on every state change in your view.

### Multiple Animations

Apply different animations to different properties:

```swift
@State private var scale = 1.0
@State private var opacity = 1.0

var body: some View {
    Circle()
        .scaleEffect(scale)
        .animation(.spring(), value: scale)  // Spring for scale
        .opacity(opacity)
        .animation(.easeOut, value: opacity)  // EaseOut for opacity
}
```

### Conditional Animations

Disable animation by passing `nil`:

```swift
@State private var animated = true
@State private var position = 0.0

var body: some View {
    Circle()
        .offset(x: position)
        .animation(animated ? .spring() : nil, value: position)

    Toggle("Animate", isOn: $animated)
    Slider(value: $position, in: 0...200)
}
```

### Animation Inheritance

Animations don't inherit by default. Each animated property needs its own `.animation()` modifier:

```swift
// ❌ Wrong - child animations won't inherit
VStack {
    Text("Child 1")
        .opacity(value)
    Text("Child 2")
        .scaleEffect(value)
}
.animation(.spring(), value: value)  // Only affects VStack properties

// ✅ Correct - each animated property has modifier
VStack {
    Text("Child 1")
        .opacity(value)
        .animation(.spring(), value: value)
    Text("Child 2")
        .scaleEffect(value)
        .animation(.spring(), value: value)
}
```

### Animatable Properties

Properties that can be animated with `.animation()`:

**Transform Properties:**
- `.scaleEffect()` - Scale (supports GPU acceleration)
- `.rotationEffect()` - Rotation (supports GPU acceleration)
- `.rotation3DEffect()` - 3D rotation (supports GPU acceleration)
- `.offset()` - Position (supports GPU acceleration)

**Visual Properties:**
- `.opacity()` - Transparency (supports GPU acceleration)
- `.foregroundColor()` - Text/element color
- `.background()` - Background color
- `.frame()` - Width and height

**Shape Properties:**
- `.cornerRadius()` - Corner rounding
- `.padding()` - Padding amount
- `.shadow()` - Shadow parameters

**Note**: Properties using GPU-accelerated transforms (scale, rotation, offset, opacity) perform best. Color and size animations are slightly less performant but still smooth.

### Common Patterns

**Button Press Feedback:**
```swift
@State private var isPressed = false

Button("Press Me") { }
    .scaleEffect(isPressed ? 0.95 : 1.0)
    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
    .onTapGesture {
        isPressed = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isPressed = false
        }
    }
```

**Toggle Visibility:**
```swift
@State private var isVisible = true

VStack {
    if isVisible {
        Text("Hello")
            .transition(.opacity)
    }
}
.animation(.easeInOut, value: isVisible)
```

**Smooth Value Changes:**
```swift
@State private var progress = 0.0

Rectangle()
    .fill(Color.blue)
    .frame(width: progress * 300, height: 20)
    .animation(.easeInOut(duration: 0.5), value: progress)

Slider(value: $progress, in: 0...1)
```

---

## Explicit Animations (withAnimation())

The `withAnimation()` function wraps state changes in an animation block, animating all affected properties simultaneously.

### Basic withAnimation

```swift
@State private var isExpanded = false

var body: some View {
    VStack {
        if isExpanded {
            Text("Details")
                .transition(.opacity)
        }

        Button("Toggle") {
            withAnimation(.spring()) {
                isExpanded.toggle()
            }
        }
    }
}
```

All state changes inside the closure are animated together with the specified animation.

### Completion Handlers

Execute code when the animation completes:

```swift
@State private var isLoading = false
@State private var showSuccess = false

Button("Submit") {
    withAnimation(.easeOut(duration: 0.3), {
        isLoading = true
    }, completion: {
        // Called when animation completes
        fetchData()
        withAnimation {
            isLoading = false
            showSuccess = true
        }
    })
}
```

**Note**: Completion handlers are called after the animation duration, but browser timing may vary slightly.

### Nested Animations

Nest withAnimation blocks for complex sequences:

```swift
@State private var step = 0

Button("Start Sequence") {
    withAnimation(.easeOut) {
        step = 1
    } completion: {
        withAnimation(.spring()) {
            step = 2
        } completion: {
            withAnimation(.easeIn) {
                step = 3
            }
        }
    }
}
```

### Animation Context

`withAnimation()` creates an animation context that affects:

1. **State Changes**: All state changes in the closure
2. **Transitions**: View insertion/removal animations
3. **Modifiers**: Property changes on existing views

```swift
@State private var items = ["A", "B", "C"]
@State private var scale = 1.0

Button("Animate All") {
    withAnimation(.spring()) {
        items.append("D")  // List insertion animated
        scale = 1.2        // Scale change animated
    }
}
```

### withAnimation vs .animation()

**Use `.animation()` when:**
- Single property animation
- Want different animations for different properties
- Animation tied to specific value changes
- Simpler, more localized control

**Use `withAnimation()` when:**
- Multiple related state changes
- View insertions/removals (transitions)
- Coordinating animations across views
- Need completion handlers
- More complex animation sequences

**Example comparison:**

```swift
// Using .animation()
@State private var rotation = 0.0

Circle()
    .rotationEffect(.degrees(rotation))
    .animation(.spring(), value: rotation)

Button("Rotate") {
    rotation += 45
}

// Using withAnimation()
@State private var rotation = 0.0

Circle()
    .rotationEffect(.degrees(rotation))

Button("Rotate") {
    withAnimation(.spring()) {
        rotation += 45
    }
}
```

Both work, but `.animation()` is more declarative and localized.

### Common Patterns

**Loading State Transitions:**
```swift
@State private var isLoading = false

Button("Load") {
    withAnimation(.easeOut(duration: 0.2)) {
        isLoading = true
    }

    // Simulate network request
    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
        withAnimation(.spring()) {
            isLoading = false
        }
    }
}

if isLoading {
    ProgressView()
        .transition(.opacity)
}
```

**List Mutations:**
```swift
@State private var items: [String] = []

Button("Add Item") {
    withAnimation(.spring()) {
        items.append("Item \(items.count + 1)")
    }
}

Button("Remove Last") {
    withAnimation(.spring()) {
        if !items.isEmpty {
            items.removeLast()
        }
    }
}

ForEach(items, id: \.self) { item in
    Text(item)
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
}
```

**Multi-Step Animation:**
```swift
@State private var progress = 0

Button("Start") {
    withAnimation(.easeIn(duration: 0.5)) {
        progress = 33
    } completion: {
        withAnimation(.linear(duration: 1.0)) {
            progress = 66
        } completion: {
            withAnimation(.spring()) {
                progress = 100
            }
        }
    }
}

ProgressBar(value: progress)
```

---

## Transition System

Transitions define how views animate when they appear or disappear from the view hierarchy. They work with conditional rendering and the animation system.

### Built-in Transitions

#### .opacity

Fades the view in and out:

```swift
if showDetails {
    DetailView()
        .transition(.opacity)
}
```

**CSS Implementation:**
```css
@keyframes fadeIn {
    from { opacity: 0; }
    to { opacity: 1; }
}

@keyframes fadeOut {
    from { opacity: 1; }
    to { opacity: 0; }
}
```

#### .scale

Scales the view from/to a specified size:

```swift
// Default: scale from 0
if showPopup {
    PopupView()
        .transition(.scale)
}

// Custom scale and anchor
if showMenu {
    MenuView()
        .transition(.scale(scale: 0.5, anchor: .topLeading))
}
```

**Parameters:**
- `scale`: Initial/final scale factor (default: 0.0)
- `anchor`: Transform origin point (default: .center)

**Anchor points:**
- `.center` - Scale from center
- `.topLeading` - Scale from top-left
- `.bottomTrailing` - Scale from bottom-right
- `.top`, `.bottom`, `.leading`, `.trailing` - Scale from edges

**CSS Implementation:**
```css
@keyframes scaleIn {
    from { transform: scale(0); }
    to { transform: scale(1); }
}

@keyframes scaleOut {
    from { transform: scale(1); }
    to { transform: scale(0); }
}

.element {
    transform-origin: center;  /* or top left, etc. */
}
```

#### .slide

Slides the view from the bottom edge:

```swift
if showSheet {
    SheetView()
        .transition(.slide)
}
```

Equivalent to `.move(edge: .bottom)`.

**CSS Implementation:**
```css
@keyframes slideIn {
    from { transform: translateY(100%); }
    to { transform: translateY(0); }
}

@keyframes slideOut {
    from { transform: translateY(0); }
    to { transform: translateY(100%); }
}
```

#### .move(edge:)

Slides the view from a specified edge:

```swift
// Slide from leading (left in LTR)
if showSidebar {
    SidebarView()
        .transition(.move(edge: .leading))
}

// Slide from top
if showBanner {
    BannerView()
        .transition(.move(edge: .top))
}

// Slide from trailing
if showPanel {
    PanelView()
        .transition(.move(edge: .trailing))
}
```

**Edge options:**
- `.top` - Slide down from top
- `.bottom` - Slide up from bottom
- `.leading` - Slide in from leading edge (left in LTR, right in RTL)
- `.trailing` - Slide in from trailing edge (right in LTR, left in RTL)

**CSS Implementation:**
```css
/* For .move(edge: .leading) */
@keyframes slideIn {
    from { transform: translateX(-100%); }
    to { transform: translateX(0); }
}

/* For .move(edge: .top) */
@keyframes slideIn {
    from { transform: translateY(-100%); }
    to { transform: translateY(0); }
}
```

#### .offset(x:y:)

Slides the view by specific pixel amounts:

```swift
// Offset from top-right
if showNotification {
    NotificationView()
        .transition(.offset(x: 100, y: -50))
}

// Horizontal slide only
if showTooltip {
    TooltipView()
        .transition(.offset(x: 20, y: 0))
}
```

**Parameters:**
- `x`: Horizontal offset in pixels (positive = right)
- `y`: Vertical offset in pixels (positive = down)

**Difference from .move():**
- `.move()` uses percentages (adapts to view size)
- `.offset()` uses fixed pixels

**CSS Implementation:**
```css
@keyframes offsetIn {
    from { transform: translate(100px, -50px); }
    to { transform: translate(0, 0); }
}
```

#### .identity

No animation (instant appearance/disappearance):

```swift
if showContent {
    ContentView()
        .transition(.identity)
}
```

### Combining Transitions

Combine multiple transitions to create complex effects:

```swift
// Fade and scale together
if showDialog {
    DialogView()
        .transition(.opacity.combined(with: .scale))
}

// Fade, scale, and move
if showPanel {
    PanelView()
        .transition(
            .opacity
                .combined(with: .scale)
                .combined(with: .move(edge: .bottom))
        )
}
```

**Combined transitions apply all effects simultaneously** with the same timing and animation curve.

**CSS Implementation:**

Combined transitions generate multiple CSS animations:

```css
animation: fadeIn 0.3s ease-in-out, scaleIn 0.3s ease-in-out;
```

### Asymmetric Transitions

Use different transitions for insertion and removal:

```swift
if showNotification {
    NotificationView()
        .transition(.asymmetric(
            insertion: .move(edge: .trailing),
            removal: .opacity
        ))
}
```

**Common patterns:**

**Slide in, fade out:**
```swift
.transition(.asymmetric(
    insertion: .move(edge: .bottom),
    removal: .opacity
))
```

**Scale in, slide out:**
```swift
.transition(.asymmetric(
    insertion: .scale,
    removal: .move(edge: .trailing)
))
```

**Complex asymmetric:**
```swift
.transition(.asymmetric(
    insertion: .opacity.combined(with: .scale),
    removal: .move(edge: .leading).combined(with: .opacity)
))
```

### Advanced Transitions

Phase 12 introduces two advanced transition types:

#### .push(from:)

Similar to `.move()` but stays fully opaque throughout:

```swift
if showPanel {
    PanelView()
        .transition(.push(from: .trailing))
}
```

**Difference from .move():**
- `.move()` may have opacity changes during transition
- `.push()` maintains opacity: 1.0 throughout
- Creates a more solid, "pushing" effect
- Ideal for navigation-style transitions

**CSS Implementation:**
```css
@keyframes pushIn {
    from { transform: translateX(100%); opacity: 1; }
    to { transform: translateX(0); opacity: 1; }
}
```

#### .modifier(active:identity:)

Create custom transitions using view modifiers:

```swift
struct BlurModifier: ViewModifier {
    let amount: Double

    func body(content: Content) -> some View {
        content.blur(radius: amount)
    }
}

let blurTransition = AnyTransition.modifier(
    active: BlurModifier(amount: 10),
    identity: BlurModifier(amount: 0)
)

if showView {
    MyView()
        .transition(blurTransition)
}
```

**How it works:**

During insertion:
1. View starts with `active` modifier applied
2. Animates to `identity` modifier

During removal:
1. View starts with `identity` modifier
2. Animates to `active` modifier

**Complex example:**

```swift
struct RotateScaleModifier: ViewModifier {
    let rotation: Double
    let scale: Double

    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(rotation))
            .scaleEffect(scale)
    }
}

let spinTransition = AnyTransition.modifier(
    active: RotateScaleModifier(rotation: 360, scale: 0),
    identity: RotateScaleModifier(rotation: 0, scale: 1)
)

if showSpinner {
    LoadingView()
        .transition(spinTransition)
}
```

**Animatable properties for custom transitions:**
- Opacity
- Scale
- Rotation
- Offset
- Color
- Blur
- Any combination of the above

### Custom Transitions

Create reusable transition extensions:

```swift
extension AnyTransition {
    static var slideAndFade: AnyTransition {
        .opacity.combined(with: .move(edge: .bottom))
    }

    static var popIn: AnyTransition {
        .scale(scale: 0.5).combined(with: .opacity)
    }

    static func slideFrom(_ edge: Edge, withFade: Bool = true) -> AnyTransition {
        let slide = AnyTransition.move(edge: edge)
        return withFade ? slide.combined(with: .opacity) : slide
    }
}

// Usage
if showView {
    MyView()
        .transition(.slideAndFade)
}

if showPopup {
    PopupView()
        .transition(.popIn)
}

if showMenu {
    MenuView()
        .transition(.slideFrom(.trailing))
}
```

### Transition Animation Control

Transitions use the ambient animation from `withAnimation()` or `.animation()`:

```swift
// Slow fade with easeOut
withAnimation(.easeOut(duration: 1.0)) {
    showDetails = true
}

if showDetails {
    DetailView()
        .transition(.opacity)  // Uses easeOut animation
}

// Or use .animation() modifier
VStack {
    if showDetails {
        DetailView()
            .transition(.opacity)
    }
}
.animation(.spring(), value: showDetails)  // Uses spring animation
```

### Transition Best Practices

1. **Match transition to context:**
   - Modals: Scale with opacity
   - Side panels: Move from edge
   - Notifications: Slide from top with opacity
   - Tooltips: Scale from anchor point

2. **Use asymmetric transitions thoughtfully:**
   - Entrance should feel natural for the element type
   - Exit should feel conclusive
   - Consider user expectation

3. **Combine with opacity for smoothness:**
   - Pure movement can feel jarring
   - Adding opacity fade makes transitions smoother

4. **Consider directionality:**
   - Next/forward: Slide from trailing
   - Back/previous: Slide from leading
   - New content: Slide from bottom
   - Dismissals: Fade out or slide down

5. **Keep it fast:**
   - Transitions should be 0.2-0.4s
   - Longer feels sluggish
   - Shorter feels abrupt

6. **Test both directions:**
   - Always test insertion AND removal
   - Asymmetric transitions must work both ways

---

## Multi-Step Animations (keyframeAnimator())

The `keyframeAnimator()` modifier enables complex, multi-step animations with precise timing control. Available in iOS 17+, it's perfect for choreographed animations and loading indicators.

### Keyframe Basics

```swift
struct AnimationValues {
    var scale = 1.0
    var opacity = 1.0
}

Circle()
    .keyframeAnimator(initialValue: AnimationValues()) { content, value in
        // Apply animated values to content
        content
            .scaleEffect(value.scale)
            .opacity(value.opacity)
    } keyframes: { _ in
        // Define animation keyframes
        KeyframeTrack(\.scale) {
            LinearKeyframe(1.5, duration: 0.3)
            SpringKeyframe(1.0, duration: 0.5)
        }
        KeyframeTrack(\.opacity) {
            LinearKeyframe(0.5, duration: 0.4)
            LinearKeyframe(1.0, duration: 0.4)
        }
    }
```

**Components:**

1. **AnimationValues**: Struct holding animated properties
2. **Content closure**: Applies values to the view
3. **Keyframes closure**: Defines the animation sequence

### Keyframe Types

#### LinearKeyframe

Changes value linearly over time:

```swift
KeyframeTrack(\.position) {
    LinearKeyframe(100, duration: 0.5)  // Move to 100 over 0.5s
    LinearKeyframe(200, duration: 0.5)  // Move to 200 over next 0.5s
    LinearKeyframe(0, duration: 0.5)    // Move back to 0
}
```

**Use cases:**
- Constant speed movements
- Progress indicators
- Continuous rotations

#### SpringKeyframe

Animates with spring physics:

```swift
KeyframeTrack(\.scale) {
    SpringKeyframe(1.5, duration: 0.3)         // Default spring
    SpringKeyframe(1.0, duration: 0.5, spring: .bouncy)  // Bouncy spring
    SpringKeyframe(0.8, duration: 0.3, spring: .smooth)  // Smooth spring
}
```

**Spring configurations:**
- `.bouncy` - High energy, playful
- `.smooth` - Professional, no bounce
- `.snappy` - Quick, subtle bounce
- Custom: `.init(duration: 0.5, bounce: 0.3)`

**Use cases:**
- Natural motion
- Interactive feel
- Attention-grabbing effects

#### CubicKeyframe

Custom cubic Bézier timing:

```swift
KeyframeTrack(\.rotation) {
    CubicKeyframe(180, duration: 0.5)  // Rotate with ease curve
    CubicKeyframe(360, duration: 0.5)  // Continue rotation
}
```

**Use cases:**
- Custom easing curves
- Matching specific motion design
- Fine-tuned timing control

### Multiple Tracks

Animate multiple properties independently:

```swift
struct ComplexValues {
    var x = 0.0
    var y = 0.0
    var rotation = 0.0
    var scale = 1.0
    var opacity = 1.0
}

Rectangle()
    .keyframeAnimator(initialValue: ComplexValues()) { content, value in
        content
            .offset(x: value.x, y: value.y)
            .rotationEffect(.degrees(value.rotation))
            .scaleEffect(value.scale)
            .opacity(value.opacity)
    } keyframes: { _ in
        // X position
        KeyframeTrack(\.x) {
            LinearKeyframe(100, duration: 0.5)
            SpringKeyframe(0, duration: 0.5)
        }

        // Y position
        KeyframeTrack(\.y) {
            LinearKeyframe(50, duration: 0.5)
            SpringKeyframe(0, duration: 0.5)
        }

        // Rotation
        KeyframeTrack(\.rotation) {
            LinearKeyframe(180, duration: 0.5)
            CubicKeyframe(360, duration: 0.5)
        }

        // Scale
        KeyframeTrack(\.scale) {
            SpringKeyframe(1.5, duration: 0.5)
            SpringKeyframe(1.0, duration: 0.5)
        }

        // Opacity
        KeyframeTrack(\.opacity) {
            LinearKeyframe(0.5, duration: 0.3)
            LinearKeyframe(1.0, duration: 0.7)
        }
    }
```

**Each track runs independently** but starts at the same time.

### Triggers and Repeating

#### Trigger-Based Animations

Re-trigger the animation when a value changes:

```swift
@State private var trigger = 0

Circle()
    .keyframeAnimator(
        initialValue: AnimationValues(),
        trigger: trigger  // Re-run when this changes
    ) { content, value in
        content.scaleEffect(value.scale)
    } keyframes: { _ in
        KeyframeTrack(\.scale) {
            SpringKeyframe(1.2, duration: 0.3)
            SpringKeyframe(1.0, duration: 0.3)
        }
    }

Button("Animate") {
    trigger += 1  // Increment to re-trigger
}
```

#### Repeating Animations

For continuous animations, use a timer or onAppear with repeating triggers:

```swift
@State private var isAnimating = false

Circle()
    .keyframeAnimator(
        initialValue: AnimationValues(),
        trigger: isAnimating
    ) { content, value in
        content.rotationEffect(.degrees(value.rotation))
    } keyframes: { _ in
        KeyframeTrack(\.rotation) {
            LinearKeyframe(360, duration: 1.0)
        }
    }
    .onAppear {
        isAnimating = true
        // In production, use a timer to continuously re-trigger
    }
```

### Common Patterns

**Loading Spinner:**
```swift
struct SpinnerValues {
    var rotation = 0.0
    var scale = 1.0
}

Circle()
    .trim(from: 0, to: 0.7)
    .stroke(Color.blue, lineWidth: 4)
    .frame(width: 50, height: 50)
    .keyframeAnimator(initialValue: SpinnerValues()) { content, value in
        content
            .rotationEffect(.degrees(value.rotation))
            .scaleEffect(value.scale)
    } keyframes: { _ in
        KeyframeTrack(\.rotation) {
            LinearKeyframe(360, duration: 1.0)
        }
        KeyframeTrack(\.scale) {
            SpringKeyframe(1.2, duration: 0.5)
            SpringKeyframe(1.0, duration: 0.5)
        }
    }
```

**Bounce Animation:**
```swift
struct BounceValues {
    var y = 0.0
    var scale = 1.0
}

Circle()
    .keyframeAnimator(initialValue: BounceValues()) { content, value in
        content
            .offset(y: value.y)
            .scaleEffect(value.scale)
    } keyframes: { _ in
        KeyframeTrack(\.y) {
            SpringKeyframe(-50, duration: 0.3, spring: .bouncy)
            SpringKeyframe(0, duration: 0.3, spring: .bouncy)
        }
        KeyframeTrack(\.scale) {
            SpringKeyframe(0.8, duration: 0.3)
            SpringKeyframe(1.0, duration: 0.3)
        }
    }
```

**Pulse Effect:**
```swift
struct PulseValues {
    var scale = 1.0
    var opacity = 1.0
}

Circle()
    .keyframeAnimator(initialValue: PulseValues()) { content, value in
        content
            .scaleEffect(value.scale)
            .opacity(value.opacity)
    } keyframes: { _ in
        KeyframeTrack(\.scale) {
            LinearKeyframe(1.2, duration: 0.5)
            LinearKeyframe(1.0, duration: 0.5)
        }
        KeyframeTrack(\.opacity) {
            LinearKeyframe(0.7, duration: 0.5)
            LinearKeyframe(1.0, duration: 0.5)
        }
    }
```

**Complex Choreography:**
```swift
struct ChoreographyValues {
    var x = 0.0
    var y = 0.0
    var rotation = 0.0
    var scale = 1.0
}

Rectangle()
    .fill(Color.blue)
    .frame(width: 50, height: 50)
    .keyframeAnimator(initialValue: ChoreographyValues()) { content, value in
        content
            .offset(x: value.x, y: value.y)
            .rotationEffect(.degrees(value.rotation))
            .scaleEffect(value.scale)
    } keyframes: { _ in
        // Move right and rotate
        KeyframeTrack(\.x) {
            LinearKeyframe(100, duration: 0.5)
            LinearKeyframe(100, duration: 0.5)  // Hold
            SpringKeyframe(0, duration: 0.5)
        }
        KeyframeTrack(\.rotation) {
            LinearKeyframe(90, duration: 0.5)
            LinearKeyframe(180, duration: 0.5)
            LinearKeyframe(0, duration: 0.5)
        }

        // Pulse scale throughout
        KeyframeTrack(\.scale) {
            SpringKeyframe(1.2, duration: 0.5)
            SpringKeyframe(0.8, duration: 0.5)
            SpringKeyframe(1.0, duration: 0.5)
        }
    }
```

### Keyframe Timing

Total animation duration is the **sum of all keyframe durations in the longest track**:

```swift
KeyframeTrack(\.x) {
    LinearKeyframe(100, duration: 0.5)  // 0.0 - 0.5s
    LinearKeyframe(0, duration: 0.3)    // 0.5 - 0.8s
}
// Total: 0.8s

KeyframeTrack(\.y) {
    LinearKeyframe(50, duration: 1.0)   // 0.0 - 1.0s
}
// Total: 1.0s

// Overall animation duration: 1.0s (longest track)
```

### Web Implementation

keyframeAnimator() generates CSS @keyframes animations:

```css
@keyframes complexAnimation {
    0% {
        transform: translateX(0) rotate(0deg) scale(1);
        opacity: 1;
    }
    50% {
        transform: translateX(100px) rotate(90deg) scale(1.2);
        opacity: 0.7;
    }
    100% {
        transform: translateX(0) rotate(0deg) scale(1);
        opacity: 1;
    }
}

.element {
    animation: complexAnimation 1.5s cubic-bezier(0.5, 0, 0.5, 1);
}
```

---

## Web Implementation Details

Raven's animation system leverages modern CSS features for optimal performance.

### CSS Transitions

Used for simple property animations triggered by `.animation()`:

```css
.element {
    transition: transform 0.3s ease-out,
                opacity 0.3s ease-out;
}

.element.animated {
    transform: scale(1.2);
    opacity: 0.5;
}
```

**Advantages:**
- Simple to implement
- Good browser support
- Hardware accelerated (transform, opacity)
- Automatic interpolation

### CSS Animations

Used for complex animations (keyframeAnimator) and transitions:

```css
@keyframes slideIn {
    from {
        transform: translateX(-100%);
        opacity: 0;
    }
    to {
        transform: translateX(0);
        opacity: 1;
    }
}

.element {
    animation: slideIn 0.3s ease-out;
}
```

**Advantages:**
- Multi-step animations
- Fine-grained control
- Can specify keyframe percentages
- Reusable animation definitions

### Transform Optimizations

Raven prioritizes GPU-accelerated properties:

**GPU-Accelerated (Fast):**
- `transform: translateX()` / `translateY()` / `translateZ()`
- `transform: scale()`
- `transform: rotate()`
- `opacity`

**CPU-Only (Slower):**
- `width` / `height`
- `top` / `left` / `right` / `bottom`
- `margin` / `padding`
- `color` / `background-color` (partially accelerated)

**Best Practice:**

```swift
// ✅ Good - uses GPU acceleration
Circle()
    .offset(x: position)  // transform: translateX()
    .scaleEffect(scale)   // transform: scale()

// ❌ Avoid - triggers layout
Circle()
    .frame(width: width)  // width animation (slower)
    .padding(.leading, padding)  // padding animation (slower)
```

### GPU Acceleration

Raven automatically enables GPU acceleration for transforms:

```css
.animated-element {
    /* Force GPU layer */
    transform: translateZ(0);
    will-change: transform, opacity;

    /* Actual animation */
    transition: transform 0.3s ease-out,
                opacity 0.3s ease-out;
}
```

**`will-change` property:**
- Tells browser which properties will animate
- Browser creates optimized rendering layer
- Use sparingly (memory overhead)

### CSS Variables

Raven uses CSS variables for dynamic animation values:

```css
:root {
    --animation-duration: 0.3s;
    --spring-timing: cubic-bezier(0.5, 1.8, 0.5, 0.8);
}

.element {
    transition: transform var(--animation-duration) var(--spring-timing);
}
```

### Browser-Specific Optimizations

**Safari/WebKit:**
```css
.element {
    -webkit-transform: translateX(100px);
    transform: translateX(100px);
}
```

**Performance Hints:**
```css
.element {
    /* Prevent anti-aliasing issues during animation */
    -webkit-font-smoothing: antialiased;
    -moz-osx-font-smoothing: grayscale;

    /* Improve rendering performance */
    backface-visibility: hidden;
    perspective: 1000px;
}
```

---

## Performance Considerations

### Animation Performance Tips

1. **Use GPU-Accelerated Properties:**
   - Prefer `transform` over `width`/`height`/`top`/`left`
   - Use `opacity` for visibility changes
   - Combine transforms: `transform: translateX(10px) scale(1.2) rotate(45deg);`

2. **Limit Animated Elements:**
   - Too many simultaneous animations tax the GPU
   - Consider staggering animations
   - Disable animations during fast scrolling

3. **Use `will-change` Sparingly:**
   - Only for elements that will actually animate
   - Remove when animation completes
   - Creates memory overhead

4. **Avoid Layout Thrashing:**
   - Don't animate properties that trigger layout (width, height, padding)
   - Batch DOM reads before writes
   - Use transform for positioning instead of left/top

5. **Choose Appropriate Durations:**
   - Fast: 0.15-0.25s (subtle feedback)
   - Medium: 0.3-0.4s (standard transitions)
   - Slow: 0.5-1.0s (dramatic effects)
   - Longer than 1s feels sluggish

6. **Consider Mobile Performance:**
   - Mobile GPUs are less powerful
   - Test on actual devices
   - Reduce complexity on mobile if needed

7. **Monitor Frame Rate:**
   - Target 60fps (16.67ms per frame)
   - Use browser DevTools Performance tab
   - Watch for dropped frames (janky animations)

### Performance Measurement

Check animation performance in browser DevTools:

**Chrome DevTools:**
1. Open DevTools (F12)
2. Performance tab
3. Record while animation plays
4. Look for:
   - FPS graph (should stay at 60fps)
   - Layout/Paint events (minimize these)
   - GPU usage

**Safari Web Inspector:**
1. Develop → Show Web Inspector
2. Timelines tab
3. Record rendering frames
4. Check for dropped frames

### Common Performance Issues

**Issue: Janky animations (dropped frames)**
- **Cause**: Animating layout properties (width, height, padding)
- **Fix**: Use transform and opacity only

**Issue: High memory usage**
- **Cause**: Too many `will-change` properties
- **Fix**: Remove will-change when not animating

**Issue: Slow animation start**
- **Cause**: Large initial layout/paint
- **Fix**: Simplify DOM, reduce initial render complexity

**Issue: Animation lag on mobile**
- **Cause**: Mobile GPU limitations
- **Fix**: Reduce number of simultaneous animations, simplify effects

---

## Browser Compatibility

### Modern Browsers (Full Support)

All Phase 12 animation features work in:

- **Chrome 90+** ✅
- **Firefox 90+** ✅
- **Safari 14+** ✅
- **Edge 90+** ✅

### Feature Support Matrix

| Feature | Chrome | Firefox | Safari | Edge |
|---------|--------|---------|--------|------|
| CSS Transitions | ✅ | ✅ | ✅ | ✅ |
| CSS Animations | ✅ | ✅ | ✅ | ✅ |
| Transform (2D) | ✅ | ✅ | ✅ | ✅ |
| Transform (3D) | ✅ | ✅ | ✅ | ✅ |
| `will-change` | ✅ | ✅ | ✅ | ✅ |
| GPU Acceleration | ✅ | ✅ | ✅ | ✅ |
| Cubic Bézier | ✅ | ✅ | ✅ | ✅ |

### Vendor Prefixes

Raven automatically adds vendor prefixes where needed:

```css
/* Raven generates both */
-webkit-transform: scale(1.2);
transform: scale(1.2);
```

### Fallbacks

For older browsers, Raven provides graceful degradation:

```css
/* If animations not supported, elements appear instantly */
@supports not (animation: name 1s) {
    .element {
        /* Fallback: no animation, just final state */
        opacity: 1;
        transform: scale(1);
    }
}
```

---

## Common Patterns

### Button Press Feedback

```swift
struct PressableButton: View {
    @State private var isPressed = false

    var body: some View {
        Text("Press Me")
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
            .onTapGesture {
                isPressed = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isPressed = false
                }
            }
    }
}
```

### Toggle Animation

```swift
struct AnimatedToggle: View {
    @State private var isOn = false

    var body: some View {
        Circle()
            .fill(isOn ? Color.green : Color.gray)
            .frame(width: 50, height: 50)
            .overlay(
                Circle()
                    .fill(Color.white)
                    .frame(width: 40, height: 40)
                    .offset(x: isOn ? 5 : -5)
            )
            .animation(.spring(), value: isOn)
            .onTapGesture {
                isOn.toggle()
            }
    }
}
```

### Progress Bar

```swift
struct ProgressBar: View {
    let progress: Double  // 0.0 to 1.0

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))

                Rectangle()
                    .fill(Color.blue)
                    .frame(width: geometry.size.width * progress)
                    .animation(.easeInOut(duration: 0.5), value: progress)
            }
        }
        .frame(height: 20)
        .cornerRadius(10)
    }
}
```

### Modal Presentation

```swift
struct ModalView: View {
    @State private var showModal = false

    var body: some View {
        ZStack {
            Button("Show Modal") {
                withAnimation(.spring()) {
                    showModal = true
                }
            }

            if showModal {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation {
                            showModal = false
                        }
                    }
                    .transition(.opacity)

                VStack {
                    Text("Modal Content")
                        .padding()
                }
                .frame(width: 300, height: 400)
                .background(Color.white)
                .cornerRadius(20)
                .transition(.scale.combined(with: .opacity))
            }
        }
    }
}
```

### List Item Animation

```swift
struct AnimatedList: View {
    @State private var items = ["Item 1", "Item 2", "Item 3"]

    var body: some View {
        VStack {
            ForEach(items, id: \.self) { item in
                Text(item)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            }

            Button("Add Item") {
                withAnimation(.spring()) {
                    items.append("Item \(items.count + 1)")
                }
            }
        }
        .padding()
    }
}
```

### Skeleton Loading

```swift
struct SkeletonView: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 12) {
            ForEach(0..<5) { _ in
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 20)
                    .cornerRadius(4)
                    .opacity(isAnimating ? 0.5 : 1.0)
            }
        }
        .animation(.easeInOut(duration: 1.0).repeatForever(), value: isAnimating)
        .onAppear {
            isAnimating = true
        }
    }
}
```

---

## Troubleshooting

### Animation Not Working

**Problem**: Animation doesn't play.

**Checklist:**
1. ✓ Is the animated property actually changing?
2. ✓ Is `.animation()` modifier present with correct value parameter?
3. ✓ Is the value parameter actually changing?
4. ✓ For transitions: Is view inside conditional (if statement)?
5. ✓ Is withAnimation() wrapping the state change?

**Debug:**
```swift
@State private var scale = 1.0

var body: some View {
    Circle()
        .scaleEffect(scale)
        .animation(.spring(), value: scale)
        .onTapGesture {
            print("Before: \(scale)")
            scale = 2.0
            print("After: \(scale)")  // Should be different
        }
}
```

### Janky/Stuttering Animation

**Problem**: Animation drops frames, looks choppy.

**Causes & Fixes:**

1. **Animating layout properties:**
   ```swift
   // ❌ Bad - animates width (layout)
   .frame(width: value)

   // ✅ Good - animates transform (GPU)
   .scaleEffect(value)
   ```

2. **Too many simultaneous animations:**
   - Reduce number of animated elements
   - Stagger animations

3. **Complex view hierarchy:**
   - Simplify views being animated
   - Avoid deep nesting during animation

### Transition Not Appearing

**Problem**: View appears/disappears instantly without transition.

**Fixes:**

1. **Add animation context:**
   ```swift
   // ✅ Add withAnimation
   Button("Toggle") {
       withAnimation {
           showView.toggle()
       }
   }

   // OR add .animation() modifier
   VStack {
       if showView {
           MyView().transition(.opacity)
       }
   }
   .animation(.spring(), value: showView)
   ```

2. **Check transition placement:**
   ```swift
   // ✅ Transition on conditional view
   if showView {
       Text("Hello")
           .transition(.opacity)
   }

   // ❌ Wrong - transition on container
   VStack {
       if showView {
           Text("Hello")
       }
   }
   .transition(.opacity)  // Won't work
   ```

### Animation Completes Too Fast/Slow

**Problem**: Animation duration doesn't feel right.

**Guidelines:**
- **Micro-interactions**: 0.15-0.25s
- **Standard transitions**: 0.3-0.4s
- **Significant changes**: 0.5-0.8s
- **Dramatic effects**: 1.0s+

**Adjust duration:**
```swift
// Too fast
.animation(.spring(), value: state)

// Just right
.animation(.spring(response: 0.5), value: state)
```

### Animations Conflict

**Problem**: Multiple animations on same element interfere.

**Solution**: Use single animation for related changes:

```swift
// ❌ Conflicting animations
.opacity(opacity1)
.animation(.easeIn, value: opacity1)
.opacity(opacity2)
.animation(.easeOut, value: opacity2)

// ✅ Single animation
@State private var state = MyState()

.opacity(state.opacity)
.scaleEffect(state.scale)
.animation(.spring(), value: state)
```

---

## Migration Guide

### From Static to Animated

**Before (No Animation):**
```swift
@State private var isExpanded = false

var body: some View {
    VStack {
        if isExpanded {
            Text("Details")
        }
        Button("Toggle") {
            isExpanded.toggle()
        }
    }
}
```

**After (With Animation):**
```swift
@State private var isExpanded = false

var body: some View {
    VStack {
        if isExpanded {
            Text("Details")
                .transition(.opacity.combined(with: .move(edge: .top)))
        }
        Button("Toggle") {
            withAnimation(.spring()) {
                isExpanded.toggle()
            }
        }
    }
}
```

### From JavaScript Animations

If migrating from web code using JavaScript animations:

**JavaScript:**
```javascript
element.addEventListener('click', () => {
    element.style.transition = 'transform 0.3s ease-out';
    element.style.transform = 'scale(1.2)';
});
```

**Raven:**
```swift
@State private var isPressed = false

Button("Click") {
    isPressed = true
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
        isPressed = false
    }
}
.scaleEffect(isPressed ? 1.2 : 1.0)
.animation(.easeOut(duration: 0.3), value: isPressed)
```

---

## Complete Examples

### Example 1: Animated Button

```swift
struct AnimatedButton: View {
    @State private var isPressed = false

    var body: some View {
        Text("Tap Me!")
            .font(.headline)
            .foregroundColor(.white)
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
            .background(isPressed ? Color.blue : Color.green)
            .cornerRadius(25)
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
            .onTapGesture {
                isPressed.toggle()
            }
    }
}
```

### Example 2: Loading Spinner

```swift
struct LoadingSpinner: View {
    struct SpinnerValues {
        var rotation = 0.0
        var scale = 1.0
    }

    var body: some View {
        Circle()
            .trim(from: 0, to: 0.7)
            .stroke(Color.blue, lineWidth: 4)
            .frame(width: 60, height: 60)
            .keyframeAnimator(initialValue: SpinnerValues()) { content, value in
                content
                    .rotationEffect(.degrees(value.rotation))
                    .scaleEffect(value.scale)
            } keyframes: { _ in
                KeyframeTrack(\.rotation) {
                    LinearKeyframe(360, duration: 1.0)
                }
                KeyframeTrack(\.scale) {
                    SpringKeyframe(1.2, duration: 0.5)
                    SpringKeyframe(1.0, duration: 0.5)
                }
            }
    }
}
```

### Example 3: Animated List

See Examples/Phase12Examples.swift for 10 complete, working examples including:
- Animated button with spring bounce
- List with insert/remove transitions
- Loading spinner with keyframes
- Animated counter/progress bar
- Page transition demo
- Shape morphing
- Complete animated UI flow
- Interactive card stack
- Expandable card
- Animated tab bar

---

## Testing & Quality

### Test Coverage

Phase 12 includes comprehensive testing:

- **50+ Integration Tests** (Phase12VerificationTests.swift)
  - Animation curves with modifiers
  - .animation() with state changes
  - withAnimation() blocks
  - Transitions on conditional views
  - keyframeAnimator() multi-step animations
  - Animation interruption
  - Transition composition
  - Cross-feature integration
  - Complex UI scenarios
  - Edge cases and error conditions
  - Performance scenarios

- **Unit Tests**
  - AnimationTests.swift - Animation types and curves
  - AnimationModifierTests.swift - .animation() modifier
  - WithAnimationTests.swift - withAnimation() function
  - TransitionTests.swift - Transition system
  - KeyframeAnimatorTests.swift - Keyframe animations

- **Integration Tests**
  - WithAnimationIntegrationTests.swift
  - Phase12VerificationTests.swift

### Quality Metrics

- **Production Code**: ~2,664 lines
- **Test Code**: ~938 lines (Phase 12 verification) + existing unit tests
- **Test-to-Code Ratio**: ~35%
- **Code Coverage**: High coverage across all animation features
- **Documentation**: Full DocC comments with examples
- **Working Examples**: 10 complete examples (~1,200+ lines)

### Running Tests

```bash
# Run all tests
swift test

# Run specific test suite
swift test --filter Phase12VerificationTests

# Run specific test
swift test --filter Phase12VerificationTests.animationCurvesWithOpacity
```

---

## Future Enhancements

Potential improvements for future releases:

### Phase 12.1: Enhanced Spring Physics

- True spring physics simulation (JavaScript-based)
- More spring configuration options
- Gesture-driven springs with velocity tracking
- Spring interruption with momentum preservation

### Phase 12.2: Advanced Keyframes

- MoveKeyframe for path-based animations
- RotationKeyframe for circular paths
- BlendMode keyframes for visual effects
- Custom keyframe types

### Phase 12.3: Animation Groups

- TimelineView for coordinated animations
- Animation groups with stagger effects
- Parallel vs sequential animation control
- Animation orchestration API

### Phase 12.4: Gesture Animations

- matchedGeometryEffect() for hero transitions
- DragGesture with spring animations
- Scroll-linked animations (enhanced)
- Interactive spring animations

### Phase 12.5: Performance Tools

- Animation performance profiler
- FPS monitoring
- Animation debugging tools
- Automatic optimization suggestions

---

## Summary

Phase 12 delivers a comprehensive animation system for Raven, bringing SwiftUI API compatibility from 80% to 85%. Key achievements:

✅ **Complete animation curve support** - Linear, ease, spring, custom timing
✅ **Implicit animations** - .animation() modifier with value-based triggering
✅ **Explicit animations** - withAnimation() with completion handlers
✅ **Full transition system** - 8 transition types with composition
✅ **Multi-step animations** - keyframeAnimator() with multiple keyframe types
✅ **CSS-based implementation** - GPU-accelerated, 60fps performance
✅ **50+ integration tests** - Comprehensive verification of all features
✅ **10 working examples** - Real-world animation patterns
✅ **Complete documentation** - This guide plus full DocC comments

The animation system is production-ready and provides a solid foundation for creating beautiful, performant animated UIs in Raven.

---

**Version:** 0.6.0
**Last Updated:** 2026-02-03
**Status:** Complete ✅
