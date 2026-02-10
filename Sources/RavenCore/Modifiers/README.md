# ViewModifier System

This directory contains the ViewModifier protocol system for Raven, enabling reusable and composable view modifications.

## Files

- **`ViewModifier.swift`** - Core ViewModifier protocol, content proxy, and example modifiers
- **`ModifiedContent.swift`** - Generic container for modified views
- **`BasicModifiers.swift`** - Built-in modifiers (padding, frame, foreground color)

## Quick Start

### Using Built-in Modifiers

```swift
Text("Hello")
    .padding(10)
    .frame(width: 200, height: 100)
    .foregroundColor(.blue)
```

### Using Custom Modifiers

```swift
Text("Bordered")
    .border(.red, width: 2)

Text("Card Content")
    .card()

Text("Title")
    .title()
```

### Creating Your Own Modifier

```swift
struct MyModifier: ViewModifier, Sendable {
    let value: Double

    @MainActor
    func body(content: Content) -> some View {
        content
            .padding(value)
            .foregroundColor(.blue)
    }
}

// Use it:
Text("Custom")
    .modifier(MyModifier(value: 15))
```

### Creating Convenience Extensions

```swift
extension View {
    func myStyle(value: Double = 10) -> some View {
        self.modifier(MyModifier(value: value))
    }
}

// Use it:
Text("Styled")
    .myStyle(value: 20)
```

## Example Modifiers

The system includes three example modifiers:

1. **BorderModifier** - Adds colored border with padding
2. **CardModifier** - Applies card-like styling with padding and width
3. **TitleModifier** - Applies title styling with padding and color

## Architecture

### Two Types of Modifiers

1. **BasicViewModifier** - Simple internal modifiers
   - Used by system modifiers (padding, frame, etc.)
   - No body composition
   - Return specific wrapper views

2. **ViewModifier** - Full-featured custom modifiers
   - Public API for user-defined modifiers
   - Has `body(content:)` method
   - Supports composition
   - Used with `.modifier()` method

### How It Works

```
View → .modifier(M) → ModifiedContent<View, M> → M.body(content) → Transformed View
```

## API Reference

### ViewModifier Protocol

```swift
public protocol ViewModifier: Sendable {
    associatedtype Body: View
    typealias Content = _ViewModifier_Content<Self>

    @ViewBuilder @MainActor
    func body(content: Content) -> Body
}
```

### View Extension

```swift
extension View {
    func modifier<M: ViewModifier>(_ modifier: M) -> ModifiedContent<Self, M>
}
```

### Example Modifiers

```swift
// Border with color and width
func border(_ color: Color, width: Double = 1) -> some View

// Card styling
func card() -> some View

// Title styling
func title() -> some View
```

## See Also

- `Core/View.swift` - Base View protocol
- `VirtualDOM/VNode.swift` - Virtual DOM node structure
- `../Docs/ViewModifier-Implementation.md` - Detailed implementation docs
