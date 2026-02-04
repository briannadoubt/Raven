# @State Property Wrapper

The `@State` property wrapper is a fundamental building block for creating dynamic, interactive user interfaces in Raven. It enables views to own and manage mutable state, automatically triggering view updates when the state changes.

## Overview

`@State` is used to declare mutable state within a view. When you mark a property with `@State`, Raven manages the storage for that property and automatically re-renders the view whenever the value changes.

## Basic Usage

```swift
struct CounterView: View {
    @State private var count = 0

    var body: some View {
        VStack {
            Text("Count: \(count)")
            Button("Increment") {
                count += 1  // Automatically triggers view update
            }
        }
    }
}
```

### Key Points

1. **Always use `private`**: State properties should be private to the view that owns them
2. **Source of truth**: State represents the view's source of truth for that data
3. **Automatic updates**: Changing a state value automatically re-renders the view
4. **Value types**: Best used with value types (Int, String, Bool, structs, etc.)

## Creating State

There are two ways to initialize a `@State` property:

```swift
// Using wrappedValue (most common)
@State private var count = 0

// Using initialValue
@State(initialValue: 42) private var number
```

## Working with Different Types

`@State` works with any `Sendable` type:

```swift
struct FormView: View {
    @State private var username: String = ""
    @State private var age: Int = 0
    @State private var isActive: Bool = true
    @State private var score: Double = 0.0
    @State private var tags: [String] = []
    @State private var selection: String? = nil

    var body: some View {
        // Your view code
    }
}
```

## Projected Value ($)

The `$` prefix gives you access to a `Binding` to the state value. This is useful when you need to pass a two-way connection to child views:

```swift
struct ParentView: View {
    @State private var text = "Hello"

    var body: some View {
        ChildView(text: $text)  // Pass binding using $
    }
}

struct ChildView: View {
    @Binding var text: String

    var body: some View {
        Button("Change Text") {
            text = "Modified by child"  // Updates parent's state
        }
    }
}
```

## @Binding

`@Binding` creates a two-way connection to a value owned by another view. Unlike `@State`, which owns its data, `@Binding` references data owned elsewhere.

### Basic Binding Usage

```swift
struct ToggleView: View {
    @Binding var isOn: Bool

    var body: some View {
        Button(isOn ? "On" : "Off") {
            isOn.toggle()
        }
    }
}

struct ParentView: View {
    @State private var toggleState = false

    var body: some View {
        ToggleView(isOn: $toggleState)  // Create binding with $
    }
}
```

### Creating Custom Bindings

You can create bindings manually with custom get and set closures:

```swift
struct TemperatureView: View {
    @State private var celsius: Double = 20.0

    var fahrenheit: Binding<Double> {
        Binding(
            get: { celsius * 9/5 + 32 },
            set: { celsius = ($0 - 32) * 5/9 }
        )
    }

    var body: some View {
        VStack {
            Text("Celsius: \(celsius)°")
            Text("Fahrenheit: \(fahrenheit.wrappedValue)°")

            Button("Increase Celsius") {
                celsius += 1
            }

            Button("Increase Fahrenheit") {
                fahrenheit.wrappedValue += 1
            }
        }
    }
}
```

### Constant Bindings

Use `Binding.constant()` when you need to pass a binding that won't change:

```swift
struct ReadOnlyView: View {
    var body: some View {
        ChildView(text: .constant("Fixed text"))
    }
}
```

## DynamicProperty Protocol

Both `@State` and `@Binding` conform to the `DynamicProperty` protocol, which allows them to participate in the view update lifecycle:

```swift
public protocol DynamicProperty: Sendable {
    @MainActor mutating func update()
}
```

This protocol is used internally by the rendering system to manage property wrapper lifecycle.

## Thread Safety

All state operations are isolated to the `@MainActor`, ensuring thread safety:

```swift
@MainActor
@propertyWrapper
public struct State<Value: Sendable>: DynamicProperty {
    // Implementation...
}
```

The `Value` type must conform to `Sendable` to ensure safe concurrent access.

## Best Practices

### 1. Keep State Local

State should be private to the view that owns it:

```swift
// ✅ Good
@State private var count = 0

// ❌ Bad
@State var count = 0  // Should be private
```

### 2. Use Binding for Shared State

When multiple views need to access the same state, use bindings:

```swift
// ✅ Good
struct ParentView: View {
    @State private var value = 0

    var body: some View {
        ChildView(value: $value)
    }
}

struct ChildView: View {
    @Binding var value: Int
    // ...
}
```

### 3. Initialize with Default Values

Provide sensible default values for state:

```swift
// ✅ Good
@State private var username = ""
@State private var count = 0

// ❌ Less ideal - requires optional handling
@State private var username: String?
```

### 4. Avoid Large State Objects

Keep state focused and lightweight. For complex state, consider breaking it into smaller pieces:

```swift
// ✅ Good - Focused state
@State private var firstName = ""
@State private var lastName = ""
@State private var age = 0

// ❌ Could be better - Large state object
struct UserData: Sendable {
    var firstName: String
    var lastName: String
    var age: Int
    // ... many more fields
}
@State private var userData = UserData(...)
```

## Examples

### Toggle Example

```swift
struct ToggleExample: View {
    @State private var isOn = false

    var body: some View {
        VStack {
            Text(isOn ? "ON" : "OFF")
            Button("Toggle") {
                isOn.toggle()
            }
        }
    }
}
```

### Form Example

```swift
struct LoginForm: View {
    @State private var username = ""
    @State private var password = ""
    @State private var rememberMe = false

    var body: some View {
        VStack {
            Text("Username: \(username)")
            Text("Password: \(password.isEmpty ? "" : "***")")
            Text("Remember: \(rememberMe ? "Yes" : "No")")

            Button("Login") {
                // Handle login
            }
        }
    }
}
```

### List Example

```swift
struct TodoList: View {
    @State private var todos: [String] = []
    @State private var newTodo = ""

    var body: some View {
        VStack {
            Button("Add Todo") {
                if !newTodo.isEmpty {
                    todos.append(newTodo)
                    newTodo = ""
                }
            }

            // Display todos...
        }
    }
}
```

## Comparison with SwiftUI

Raven's `@State` implementation follows SwiftUI's semantics closely:

| Feature | Raven | SwiftUI |
|---------|-------|---------|
| Basic state management | ✅ | ✅ |
| Projected value ($) | ✅ | ✅ |
| Binding support | ✅ | ✅ |
| MainActor isolation | ✅ | ✅ |
| DynamicProperty protocol | ✅ | ✅ |
| Sendable conformance | ✅ | Partial |

## Implementation Details

### Internal Storage

`@State` uses a class-based storage mechanism to maintain identity across view updates:

```swift
@MainActor
private final class StateStorage<Value: Sendable>: @unchecked Sendable {
    private var value: Value
    private var onUpdate: (@Sendable @MainActor () -> Void)?

    // Implementation...
}
```

### Update Callbacks

The rendering system can register callbacks to be notified when state changes:

```swift
state.setUpdateCallback {
    // Trigger view re-render
    renderCoordinator.scheduleUpdate()
}
```

This mechanism allows the rendering system to efficiently batch updates and minimize re-renders.

## Future Enhancements

Planned improvements for future versions:

1. **Automatic update callback registration**: Connect state changes directly to the render coordinator
2. **State observation**: More granular change detection
3. **Transaction support**: Animate state changes
4. **State persistence**: Save/restore state across sessions
5. **State debugging**: Better tools for tracking state changes

## Related Documentation

- [View Protocol](./View.md)
- [ViewBuilder](./ViewBuilder.md)
- [Rendering System](./Rendering.md)
- [Event Handling](./Events.md)

## See Also

- `DynamicProperty` protocol
- `Binding` property wrapper
- `RenderCoordinator` class
