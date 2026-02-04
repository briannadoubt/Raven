# Raven API Documentation

Complete API reference for the Raven SwiftUI-for-Web framework.

## Table of Contents

### Core APIs
- [Views](./Views.md) - Text, Image, Button, etc.
- [Layout](./Layout.md) - VStack, HStack, ZStack, Grid, List
- [State Management](./State.md) - @State, @Binding, @ObservedObject, @StateObject
- [Modifiers](./Modifiers.md) - Styling, layout, and behavior modifiers

### Advanced Features
- [Animation](./Animation.md) - Transitions, springs, timing curves
- [Gestures](./Gestures.md) - Tap, drag, long press, magnification
- [Navigation](./Navigation.md) - NavigationView, TabView, routing
- [Forms](./Forms.md) - TextField, Toggle, Picker, validation
- [Presentation](./Presentation.md) - Sheet, Alert, Popover

### Web Platform Features
- [Canvas](./Canvas.md) - 2D drawing and graphics
- [WebGL](./WebGL.md) - 3D graphics and shaders
- [Offline](./Offline.md) - Service workers, IndexedDB, caching
- [PWA](./PWA.md) - Install prompts, notifications, sharing
- [WebRTC](./WebRTC.md) - Real-time communication
- [Performance](./Performance.md) - Profiling, optimization, metrics

## Quick Reference

### Basic View Creation

```swift
struct ContentView: View {
    var body: some View {
        VStack {
            Text("Hello, World!")
            Button("Click me") {
                print("Clicked!")
            }
        }
    }
}
```

### State Management

```swift
struct CounterView: View {
    @State private var count = 0

    var body: some View {
        VStack {
            Text("Count: \(count)")
            Button("+1") {
                count += 1
            }
        }
    }
}
```

### Layout

```swift
HStack(spacing: 20) {
    Text("Left")
    Spacer()
    Text("Right")
}
.padding()
```

### Animation

```swift
Circle()
    .scaleEffect(isLarge ? 2.0 : 1.0)
    .animation(.spring(), value: isLarge)
```

## API Stability

Raven v1.0 follows semantic versioning:

- **Major version** (1.x.x): Breaking changes
- **Minor version** (x.1.x): New features, backward compatible
- **Patch version** (x.x.1): Bug fixes

All public APIs documented here are considered stable unless marked as:
- `@experimental` - May change in future versions
- `@deprecated` - Will be removed in next major version

## Platform Compatibility

Raven targets modern web browsers with WebAssembly support:

- ✅ Chrome 87+
- ✅ Firefox 89+
- ✅ Safari 15+
- ✅ Edge 87+

Some features require newer browser versions:
- **WebGL 2.0**: Chrome 56+, Firefox 51+, Safari 15+
- **WebRTC**: Chrome 74+, Firefox 66+, Safari 14.3+
- **IndexedDB v3**: Chrome 58+, Firefox 53+, Safari 15+

## Getting Help

- **Issues**: [GitHub Issues](https://github.com/YourOrg/Raven/issues)
- **Discussions**: [GitHub Discussions](https://github.com/YourOrg/Raven/discussions)
- **Examples**: [Example Apps](../../Examples/)
- **Guides**: [Getting Started](../getting-started.md)

---

*Raven v1.0 API Documentation*
*Generated: February 4, 2026*
