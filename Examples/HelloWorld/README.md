# Hello World Example

The simplest possible Raven application demonstrating core concepts.

## What This Example Shows

- ✅ Basic app structure with `RavenApp`
- ✅ State management with `@State`
- ✅ Layout with `VStack`
- ✅ Text styling with modifiers
- ✅ Button interactions
- ✅ Counter pattern (most common starter pattern)

## Running This Example

```bash
# Build for WASM
swift build --triple wasm32-unknown-wasi

# Serve with a local server
python3 -m http.server 8000

# Open in browser
open http://localhost:8000
```

## Key Concepts

### 1. Entry Point
```swift
@main
struct HelloWorldApp {
    static func main() async {
        await RavenApp(rootView: ContentView()).run()
    }
}
```

Every Raven app starts with `RavenApp` which sets up the WASM runtime and renders your root view.

### 2. State Management
```swift
@State private var count = 0
```

`@State` creates reactive state that automatically updates the UI when changed.

### 3. Layout
```swift
VStack(spacing: 20) {
    // Views arranged vertically
}
```

Raven uses the same layout system as SwiftUI - VStack, HStack, ZStack, etc.

### 4. Modifiers
```swift
.font(.largeTitle)
.foregroundColor(.blue)
```

Modifiers transform views by adding styling, layout constraints, and behavior.

## Next Steps

- Try the **Todo List** example for forms and lists
- Try the **Navigation** example for multi-screen apps
- Try the **Animation** example for interactive animations
