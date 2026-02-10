# @Observable and @Bindable Quick Reference

Modern Swift state management for Raven (iOS 17+ style)

## Quick Start

### 1. Create an Observable Class

```swift
@MainActor
final class UserSettings: Observable {
    let _$observationRegistrar = ObservationRegistrar()

    var username: String = "" {
        willSet { _$observationRegistrar.willSet() }
    }

    var isDarkMode: Bool = false {
        willSet { _$observationRegistrar.willSet() }
    }

    init() {
        setupObservation()
    }
}
```

### 2. Use with @Bindable in Views

```swift
struct SettingsView: View {
    @Bindable var settings: UserSettings

    var body: some View {
        VStack {
            TextField("Username", text: $settings.username)
            Toggle("Dark Mode", isOn: $settings.isDarkMode)
        }
    }
}
```

### 3. Create and Pass to Child Views

```swift
struct ContentView: View {
    @State private var settings = UserSettings()

    var body: some View {
        SettingsView(settings: settings)
    }
}
```

## Key Differences from ObservableObject

| Feature | ObservableObject | @Observable |
|---------|-----------------|-------------|
| Property Declaration | `@Published var name = ""` | `var name = ""` |
| Setup Required | `init() { setupPublished() }` | `init() { setupObservation() }` |
| View Property Wrapper | `@ObservedObject` or `@StateObject` | `@Bindable` |
| Boilerplate | More | Less |
| Performance | Good | Better (fine-grained) |

## Advanced Patterns

### Computed Properties

```swift
@MainActor
final class ShoppingCart: Observable {
    let _$observationRegistrar = ObservationRegistrar()

    var items: [Item] = [] {
        willSet { _$observationRegistrar.willSet() }
    }

    // Automatically observed
    var total: Double {
        items.reduce(0) { $0 + $1.price }
    }

    init() {
        setupObservation()
    }
}
```

### Ignoring Properties

```swift
@MainActor
final class DataManager: Observable {
    let _$observationRegistrar = ObservationRegistrar()

    var data: [String] = [] {
        willSet { _$observationRegistrar.willSet() }
    }

    // This property won't trigger observations
    @ObservationIgnored
    var cacheMetadata: [String: Any] = [:]

    init() {
        setupObservation()
    }
}
```

### Manual Getters/Setters (More Control)

```swift
@MainActor
final class Counter: Observable {
    let _$observationRegistrar = ObservationRegistrar()

    private var _count: Int

    var count: Int {
        get { _count }
        set {
            _$observationRegistrar.willSet()
            _count = newValue
        }
    }

    init(count: Int = 0) {
        self._count = count
        setupObservation()
    }
}
```

## Subscription API

```swift
let settings = UserSettings()

// Subscribe to changes
let id = settings.subscribe {
    print("Settings changed!")
}

// Unsubscribe
settings.unsubscribe(id)
```

## Integration with @State

```swift
struct MyView: View {
    @State private var model = MyModel()

    var body: some View {
        // Pass to child with @Bindable
        EditorView(model: model)
    }
}

struct EditorView: View {
    @Bindable var model: MyModel

    var body: some View {
        TextField("Name", text: $model.name)
    }
}
```

## Common Patterns

### Toggle Pattern

```swift
@Bindable var settings: UserSettings

Toggle("Dark Mode", isOn: $settings.isDarkMode)
```

### TextField Pattern

```swift
@Bindable var settings: UserSettings

TextField("Username", text: $settings.username)
```

### Slider Pattern

```swift
@Bindable var settings: UserSettings

Slider(value: $settings.fontSize, in: 8...32)
```

### List Pattern

```swift
@Bindable var cart: ShoppingCart

List(cart.items) { item in
    Text(item.name)
}
```

## Files

- **Observable.swift**: Core Observable protocol and infrastructure
- **Bindable.swift**: @Bindable property wrapper
- **ObservableTests.swift**: Comprehensive test suite (31 tests)
- **ObservableBindableVerification.swift**: Quick verification tests (10 tests)
- **ObservableBindableExample.swift**: Complete usage examples

## See Also

- [ObservableObject](./ObservableObject.swift) - Legacy pattern
- [State](./State.swift) - Simple value state
- [Binding](./State.swift) - Two-way bindings
- [OBSERVABLE_BINDABLE_IMPLEMENTATION.md](../../OBSERVABLE_BINDABLE_IMPLEMENTATION.md) - Full documentation

## Requirements

- Swift 6.2+
- Raven framework
- @MainActor isolation for UI contexts

## Future: Swift Macros

When Swift macros become available in SwiftWasm, you'll be able to use:

```swift
@Observable
@MainActor
class Settings {
    var username = ""
    var isDarkMode = false
}
```

The macro will automatically generate all the observation infrastructure!
