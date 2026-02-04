# State Management in Raven

This directory contains the state management system for Raven, implementing SwiftUI-compatible property wrappers for reactive UI updates.

## Files

### State.swift

Contains the core state management implementation:

- **DynamicProperty Protocol**: Marks types that participate in the view update lifecycle
- **@State Property Wrapper**: Manages owned, mutable state within a view
- **@Binding Property Wrapper**: Creates two-way connections to external state
- **StateStorage**: Internal class for managing state value storage and update callbacks

## Architecture

### State Storage

State values are stored in a class-based storage system that maintains identity across view updates:

```
┌─────────────┐
│   @State    │
│  (struct)   │
└──────┬──────┘
       │ owns
       ▼
┌─────────────┐
│StateStorage │
│   (class)   │
├─────────────┤
│ - value     │
│ - onUpdate  │
└─────────────┘
```

The storage class allows the property wrapper to be recreated during view updates while maintaining the same underlying storage.

### Update Flow

When state changes, updates flow through the system:

```
State Value Change
       │
       ▼
Storage.setValue()
       │
       ▼
onUpdate callback
       │
       ▼
RenderCoordinator.scheduleUpdate()
       │
       ▼
View Re-render
```

## Usage Examples

### Basic State

```swift
@State private var count = 0
```

### State with Binding

```swift
struct Parent: View {
    @State private var text = ""

    var body: some View {
        Child(text: $text)
    }
}

struct Child: View {
    @Binding var text: String
    // ...
}
```

### Custom Binding

```swift
var derived: Binding<String> {
    Binding(
        get: { baseValue.uppercased() },
        set: { baseValue = $0.lowercased() }
    )
}
```

## Integration with Rendering System

The state management system integrates with the rendering system through update callbacks. When a view is initialized, the rendering system can register callbacks with each `@State` property:

```swift
// Pseudocode - actual implementation may vary
view.state.setUpdateCallback {
    renderCoordinator.scheduleUpdate()
}
```

This ensures that any state change triggers a view update through the render coordinator's batching system.

## Thread Safety

All state operations are isolated to the `@MainActor`:

- State values can only be accessed on the main thread
- Update callbacks execute on the main thread
- The `Value` type must conform to `Sendable` for safe concurrent access

## Performance Considerations

### Efficient Updates

- State changes are batched through the render coordinator
- Multiple state changes in the same frame are coalesced
- Only changed views are re-rendered (through virtual DOM diffing)

### Best Practices

1. Keep state values small and focused
2. Use value types (structs) for state when possible
3. Avoid storing large objects in state
4. Consider breaking complex state into multiple `@State` properties

## Future Enhancements

Planned improvements:

1. **Automatic callback registration**: Connect state to render coordinator automatically
2. **Observation system**: More granular change detection
3. **Transaction support**: Animate state changes
4. **State persistence**: Save/restore across sessions
5. **State debugging**: Tools for tracking changes

## Testing

See `Tests/RavenTests/StateTests.swift` for comprehensive test coverage including:

- Basic state operations
- Binding creation and modification
- Update callbacks
- Thread safety (MainActor isolation)
- DynamicProperty conformance

## See Also

- [View Protocol](../Core/View.swift)
- [RenderCoordinator](../../RavenRuntime/RenderLoop.swift)
- [State Documentation](../../Documentation/State.md)
