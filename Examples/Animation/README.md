# Animation Example

An interactive gallery showcasing Raven's animation capabilities.

## What This Example Shows

- ✅ Linear animations
- ✅ Spring physics animations
- ✅ Rotation effects
- ✅ Scale effects
- ✅ Combined multi-property animations
- ✅ Animation timing curves
- ✅ Segmented picker for navigation
- ✅ Gradient fills

## Animation Types

### 1. Linear Animation
```swift
.animation(.linear(duration: 1), value: isMovedRight)
```
Constant-speed animation from start to finish.

### 2. Spring Animation
```swift
.animation(.spring(response: 0.6, dampingFraction: 0.7), value: isExpanded)
```
Physics-based animation with bounce/overshoot.

### 3. Ease In/Out
```swift
.animation(.easeInOut(duration: 0.8), value: rotationAngle)
```
Starts slow, speeds up, then slows down at the end.

### 4. Combined Animations
```swift
Circle()
    .scaleEffect(isAnimating ? 1.3 : 1.0)
    .rotationEffect(.degrees(isAnimating ? 360 : 0))
    .offset(y: isAnimating ? -50 : 50)
    .animation(.spring(...), value: isAnimating)
```
Multiple properties animated together.

## Key Concepts

### The `.animation()` Modifier
The animation modifier tells Raven to animate changes to the specified value:

```swift
.animation(.spring(), value: someState)
```

When `someState` changes, all affected properties animate smoothly.

### Animation Curves

- **linear**: Constant speed
- **easeIn**: Starts slow, accelerates
- **easeOut**: Starts fast, decelerates
- **easeInOut**: Slow start and end, fast middle
- **spring**: Physics-based with bounce

### Animatable Properties

- Position (`.offset()`)
- Scale (`.scaleEffect()`)
- Rotation (`.rotationEffect()`)
- Opacity (`.opacity()`)
- Size (frame width/height)
- Colors
- Corner radius

## Performance Tips

- Animate transforms (scale, rotation, position) for best performance
- Avoid animating layout-heavy operations
- Use spring animations sparingly on mobile
- Batch multiple property changes together

## Next Steps

- Add gesture-driven animations
- Implement custom animation curves
- Try particle effects (Phase 16+)
- Add physics-based interactions
