# Debug Tools

Developer-friendly debugging and diagnostic tools for Raven applications. Only active in DEBUG builds.

## Overview

The Debug module provides comprehensive development tools including:

- **Debug Overlay** - Real-time performance metrics display
- **View Extensions** - Debugging modifiers for Views
- **Performance Monitoring** - Render time and frequency tracking
- **Layout Visualization** - Visual debugging aids

## Features

### Debug Overlay

Real-time performance metrics overlay that displays in the top-right corner of your app.

#### Metrics Displayed

- **FPS** - Current frame rate with color coding:
  - 🟢 Green: ≥55 FPS (Good)
  - 🟡 Orange: 30-54 FPS (Moderate)
  - 🔴 Red: <30 FPS (Poor)

- **VNodes** - Current VNode tree size
- **DOM Nodes** - Number of actual DOM elements
- **Render Time** - Last render cycle duration with color coding:
  - 🟢 Green: <16.67ms (60 FPS budget)
  - 🟡 Orange: 16.67-33.33ms (30+ FPS)
  - 🔴 Red: >33.33ms (Poor)

- **Memory** - Current JavaScript heap usage

#### Usage

```swift
import Raven

// Toggle overlay programmatically
DebugOverlay.shared.show()
DebugOverlay.shared.hide()
DebugOverlay.shared.toggle()

// Or use keyboard shortcut: Cmd+Shift+D (Mac) or Ctrl+Shift+D (Others)
```

#### Updating Metrics

The debug overlay automatically receives updates from the performance profiler. You can also manually update metrics:

```swift
DebugOverlay.shared.updateFPS(59.5)
DebugOverlay.shared.updateVNodeCount(1234)
DebugOverlay.shared.updateDOMNodeCount(1189)
DebugOverlay.shared.updateRenderTime(12.5)
DebugOverlay.shared.updateMemoryUsage(15.2)
```

### View Debug Extensions

Convenient modifiers for debugging individual views.

#### debugOverlay(label:)

Displays performance statistics for a specific view.

```swift
struct ProfileView: View {
    var body: some View {
        VStack {
            // ... content
        }
        .debugOverlay(label: "ProfileView")
    }
}
```

**Output:**
```
[Debug Overlay] ProfileView - Renders: 5, Avg: 12.34ms, Last: 11.52ms
```

#### debugPrint(label:)

Logs when a view renders, useful for tracking re-renders.

```swift
struct UserCard: View {
    var body: some View {
        HStack {
            // ... content
        }
        .debugPrint()
    }
}
```

**Output:**
```
[Debug Print] 🔍 UserCard rendered (count: 3) at 2026-02-04 12:34:56
```

#### debugBorder(_:width:)

Adds a colored border to visualize view boundaries.

```swift
struct LayoutDebugView: View {
    var body: some View {
        VStack {
            Text("Header")
                .debugBorder(.red)

            Text("Content")
                .debugBorder(.green)

            Text("Footer")
                .debugBorder(.blue)
        }
    }
}
```

**Available Colors:**
- `.red` - Default, for primary views
- `.green` - For content areas
- `.blue` - For containers
- `.yellow` - For warnings
- `.purple` - For special sections
- `.orange` - For interactive elements
- `.cyan` - For data displays
- `.magenta` - For overlays

#### debugHierarchy(depth:)

Logs the view hierarchy for understanding composition.

```swift
struct ComplexView: View {
    var body: some View {
        NavigationView {
            List {
                // ... items
            }
        }
        .debugHierarchy(depth: 3)
    }
}
```

**Output:**
```
[Debug Hierarchy]   NavigationView
[Debug Hierarchy]     List
[Debug Hierarchy]       ForEach
```

#### debugPerformance(threshold:)

Monitors view performance and warns about slow renders.

```swift
struct ExpensiveView: View {
    var body: some View {
        // Complex rendering logic
        computeExpensiveLayout()
            .debugPerformance(threshold: 16.0)
    }
}
```

**Output:**
```
[Debug Performance] 🐌 ExpensiveView took 18.45ms (avg: 17.23ms, threshold: 16.0ms)
[Debug Performance] ⚠️ ExpensiveView re-rendered after 12.34ms - potential excessive re-renders
```

## Integration with Performance Profiler

The debug overlay integrates seamlessly with the performance profiler:

```swift
import Raven

@MainActor
class AppCoordinator {
    func setupDebugTools() {
        #if DEBUG
        // Show debug overlay
        DebugOverlay.shared.show()

        // Start performance profiling
        let profiler = RenderProfiler.shared
        profiler.startProfiling(label: "App Session")

        // Profiler automatically updates debug overlay
        #endif
    }
}
```

## Hot Reload Integration

The debug overlay persists across hot reloads and displays reload metrics:

- Build time notification
- Reload count tracking
- Average build time
- State preservation status

## Development Workflow

### Typical Debug Session

1. **Start Development Server**
   ```bash
   raven dev
   ```

2. **Enable Debug Overlay**
   - Press `Cmd+Shift+D` in browser
   - Or call `DebugOverlay.shared.show()` in code

3. **Add Debug Modifiers**
   ```swift
   struct MyView: View {
       var body: some View {
           VStack {
               // ... content
           }
           .debugPerformance()
           .debugPrint()
       }
   }
   ```

4. **Monitor Performance**
   - Watch FPS in overlay
   - Check render times
   - Identify slow views from console

5. **Optimize**
   - Address views exceeding 16ms render time
   - Reduce unnecessary re-renders
   - Optimize expensive computations

### Performance Optimization Checklist

Use debug tools to identify:

- ✅ Views rendering in <16ms (60 FPS)
- ⚠️ Views rendering in 16-33ms (30-60 FPS)
- ❌ Views rendering in >33ms (<30 FPS)

- ✅ Re-renders spaced >16ms apart
- ⚠️ Re-renders spaced 8-16ms apart
- ❌ Re-renders spaced <8ms apart (excessive)

## Best Practices

### 1. Use Debug Modifiers During Development

```swift
#if DEBUG
    .debugPerformance()
    .debugPrint()
#endif
```

### 2. Remove Debug Code Before Production

The compiler automatically strips debug code in release builds, but it's good practice to wrap debug-specific logic:

```swift
#if DEBUG
DebugOverlay.shared.show()
#endif
```

### 3. Set Appropriate Thresholds

Adjust performance thresholds based on view complexity:

```swift
// Simple view - strict threshold
SimpleView()
    .debugPerformance(threshold: 8.0)

// Complex view - relaxed threshold
ComplexDashboard()
    .debugPerformance(threshold: 32.0)
```

### 4. Use Color Coding Effectively

```swift
VStack {
    // Container
    containerView.debugBorder(.blue)

    // Content
    contentView.debugBorder(.green)

    // Interactive
    buttonView.debugBorder(.orange)

    // Problem area
    slowView.debugBorder(.red)
}
```

### 5. Combine Tools for Deep Debugging

```swift
struct DebuggedView: View {
    var body: some View {
        content
            .debugBorder(.red)          // Visual boundary
            .debugPrint()               // Render tracking
            .debugPerformance()         // Performance monitoring
            .debugOverlay()             // Stats display
    }
}
```

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Cmd+Shift+D` (Mac) | Toggle debug overlay |
| `Ctrl+Shift+D` (Others) | Toggle debug overlay |
| `ESC` | Close error overlay |

## Console API

Access debug tools from browser console:

```javascript
// Toggle debug overlay
window.__ravenDebugOverlay.toggle()

// Get reload metrics
window.__ravenReloadMetrics.get()
// Returns: { totalReloads, lastReloadTime, averageBuildTime, buildTimes }

// Reset reload metrics
window.__ravenReloadMetrics.reset()
```

## Troubleshooting

### Debug Overlay Not Showing

1. Ensure you're in a DEBUG build
2. Check console for JavaScript errors
3. Verify keyboard shortcut is not blocked
4. Try calling `DebugOverlay.shared.show()` directly

### Performance Metrics Not Updating

1. Ensure performance profiler is running
2. Check that metrics are being recorded
3. Verify overlay is visible (not hidden)

### Debug Modifiers Not Logging

1. Check console output destination
2. Ensure view is actually rendering
3. Verify DEBUG flag is set

## API Reference

### DebugOverlay

```swift
@MainActor
public final class DebugOverlay: Sendable {
    public static let shared: DebugOverlay

    public func show()
    public func hide()
    public func toggle()

    public func updateFPS(_ fps: Double)
    public func updateVNodeCount(_ count: Int)
    public func updateDOMNodeCount(_ count: Int)
    public func updateRenderTime(_ milliseconds: Double)
    public func updateMemoryUsage(_ megabytes: Double)
}
```

### View Extensions

```swift
extension View {
    public func debugOverlay(label: String? = nil) -> some View
    public func debugPrint(label: String? = nil) -> some View
    public func debugBorder(_ color: DebugColor = .red, width: Double = 1) -> some View
    public func debugHierarchy(depth: Int = 3) -> some View
    public func debugPerformance(threshold: Double = 16.0) -> some View
}
```

## See Also

- [Performance Profiling](../Performance/README.md) - Comprehensive performance monitoring
- [Hot Reload Guide](../../Sources/RavenCLI/DevServer/README.md) - Development server features
- [Error Overlay](../../Sources/RavenCLI/Generator/ErrorOverlay.swift) - Compilation error display
