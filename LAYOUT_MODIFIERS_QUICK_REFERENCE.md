# Layout Modifiers Quick Reference

## At a Glance

| Modifier | Purpose | CSS |
|----------|---------|-----|
| `.clipped()` | Clip to bounds | `overflow: hidden` |
| `.aspectRatio(r, .fit)` | Maintain ratio, fit | `aspect-ratio: r; object-fit: contain` |
| `.aspectRatio(r, .fill)` | Maintain ratio, fill | `aspect-ratio: r; object-fit: cover` |
| `.fixedSize()` | Fix both dimensions | `width/height: fit-content` |
| `.fixedSize(h, v)` | Fix specific axes | Conditional width/height |

## Quick Examples

```swift
// Clip overflow
view.clipped()

// Square with fit
view.aspectRatio(1, contentMode: .fit)

// 16:9 with fill
view.aspectRatio(16/9, contentMode: .fill)

// Fix both
view.fixedSize()

// Fix horizontal only
view.fixedSize(horizontal: true, vertical: false)
```

## Common Use Cases

### 1. Clipped Image
```swift
Image("photo")
    .frame(width: 100, height: 100)
    .clipped()
```

### 2. Square Profile Picture
```swift
Image("avatar")
    .aspectRatio(1, contentMode: .fill)
    .frame(width: 50, height: 50)
    .clipped()
    .cornerRadius(25)
```

### 3. Video Container
```swift
VideoPlayer(url: url)
    .aspectRatio(16/9, contentMode: .fit)
```

### 4. Non-Wrapping Button
```swift
Button("Submit") { }
    .fixedSize()
```

### 5. Wrapped Text with Fixed Width
```swift
Text("Long text...")
    .fixedSize(horizontal: false, vertical: true)
```

## ContentMode

- `.fit` - Entire content visible (may have empty space)
- `.fill` - Fill entire space (may crop content)

## Tips

✓ Use `.clipped()` after `.aspectRatio(..., .fill)` to prevent overflow
✓ Combine with `.frame()` for precise sizing
✓ Use `.fixedSize(horizontal: false, vertical: true)` for wrapping text
✓ Chain modifiers in logical order: size → aspect → clip
