# @StateObject and @ObservedObject Property Wrappers

This document describes the implementation and usage of `@StateObject` and `@ObservedObject` property wrappers in Raven.

## Overview

Both property wrappers enable views to observe and respond to changes in `ObservableObject` instances, but they differ in ownership semantics:

- **@StateObject**: Creates and owns an observable object
- **@ObservedObject**: Observes an object owned elsewhere

## Implementation Details

### @StateObject

`@StateObject` is a property wrapper that creates and manages the lifecycle of an `ObservableObject` instance.

**Key Features:**

1. **Ownership**: The view creates and owns the object
2. **Lazy Initialization**: Object is created on first access using an autoclosure
3. **Lifecycle**: Object persists for the lifetime of the view
4. **Subscription**: Automatically subscribes to `objectWillChange` publisher
5. **View Updates**: Triggers view re-renders when the object emits changes

**Storage Implementation:**

```swift
private final class Storage: @unchecked Sendable {
    var object: ObjectType?                          // Lazily initialized object
    let initializer: @Sendable @MainActor () -> ObjectType  // Creation closure
    var subscriptionID: UUID?                        // Publisher subscription
    var updateCallback: (@Sendable @MainActor () -> Void)?  // View update trigger
}
```

**Initialization:**

```swift
public init(wrappedValue: @autoclosure @escaping @Sendable @MainActor () -> ObjectType)
```

The `@autoclosure` parameter allows natural syntax:

```swift
@StateObject private var model = MyModel()
// Instead of: @StateObject private var model = { MyModel() }
```

**Projected Value:**

```swift
public var projectedValue: ObjectType { wrappedValue }
```

Returns the object itself (not a binding), allowing you to pass it to child views.

### @ObservedObject

`@ObservedObject` is a property wrapper that observes an existing `ObservableObject` instance.

**Key Features:**

1. **No Ownership**: The view does not own the object
2. **Immediate Initialization**: Object must be provided during initialization
3. **Lifecycle**: Object lifecycle is managed by the owner
4. **Subscription**: Automatically subscribes to `objectWillChange` publisher
5. **View Updates**: Triggers view re-renders when the object emits changes

**Storage Implementation:**

```swift
private final class Storage: @unchecked Sendable {
    var object: ObjectType                           // The observed object
    var subscriptionID: UUID?                        // Publisher subscription
    var updateCallback: (@Sendable @MainActor () -> Void)?  // View update trigger
}
```

**Initialization:**

```swift
public init(wrappedValue: ObjectType)
```

The object must be provided when the property is initialized:

```swift
struct ChildView: View {
    @ObservedObject var model: MyModel  // Passed from parent
}
```

**Projected Value:**

```swift
public var projectedValue: ObjectType { wrappedValue }
```

Returns the object itself, allowing access to the object directly.

## Integration with Rendering System

Both property wrappers conform to `DynamicProperty`, integrating with Raven's rendering lifecycle:

```swift
public protocol DynamicProperty: Sendable {
    @MainActor mutating func update()
}
```

### Update Callback Mechanism

The rendering system can set update callbacks on these property wrappers:

```swift
internal func setUpdateCallback(_ callback: @escaping @Sendable @MainActor () -> Void)
```

When the observable object's `objectWillChange` publisher emits:

1. The subscription callback is triggered
2. This calls the `updateCallback` closure
3. The callback triggers a view re-render through the `RenderCoordinator`

### Subscription Lifecycle

**For @StateObject:**

1. Object is created lazily on first access
2. Subscription is established when object is created
3. Subscription persists for view lifetime
4. Object is retained until view is destroyed

**For @ObservedObject:**

1. Subscription is established immediately in `init`
2. Subscription can be updated if `wrappedValue` is reassigned
3. Old subscriptions are properly cleaned up
4. Object lifecycle is managed externally

## Usage Patterns

### Pattern 1: Basic @StateObject Usage

The owning view creates the object:

```swift
@MainActor
final class CounterModel: ObservableObject {
    @Published var count: Int = 0

    init() {
        setupPublished()
    }

    func increment() {
        count += 1
    }
}

struct CounterView: View {
    @StateObject private var model = CounterModel()

    var body: some View {
        VStack {
            Text("Count: \(model.count)")
            Button("Increment") {
                model.increment()
            }
        }
    }
}
```

### Pattern 2: Parent-Child Communication

Parent owns the object, child observes it:

```swift
struct ParentView: View {
    @StateObject private var settings = AppSettings()

    var body: some View {
        VStack {
            Text("Parent View")
            ChildView(settings: settings)  // Pass object to child
        }
    }
}

struct ChildView: View {
    @ObservedObject var settings: AppSettings  // Observe parent's object

    var body: some View {
        Text("Theme: \(settings.theme)")
    }
}
```

### Pattern 3: Multiple Child Observers

Multiple children can observe the same object:

```swift
struct DashboardView: View {
    @StateObject private var dataStore = DataStore()

    var body: some View {
        VStack {
            SummaryView(dataStore: dataStore)      // Child 1
            DetailView(dataStore: dataStore)       // Child 2
            ActionsView(dataStore: dataStore)      // Child 3
        }
    }
}

// All children use @ObservedObject to observe the same dataStore
```

### Pattern 4: Multiple Independent @StateObjects

A view can own multiple independent objects:

```swift
struct ComplexView: View {
    @StateObject private var userProfile = UserProfile()
    @StateObject private var settings = Settings()
    @StateObject private var analytics = Analytics()

    var body: some View {
        VStack {
            ProfileSection(profile: userProfile)
            SettingsSection(settings: settings)
            AnalyticsSection(analytics: analytics)
        }
    }
}
```

## Thread Safety

Both property wrappers are designed for Swift 6.2 strict concurrency:

1. **MainActor Isolation**: All types are `@MainActor`-isolated
2. **Sendable Conformance**: Use `@unchecked Sendable` with proper isolation
3. **Closure Annotations**: All closures are marked `@Sendable @MainActor`
4. **Storage Classes**: Internal storage classes are `@unchecked Sendable`

The `@MainActor` isolation ensures all access happens on the main actor, making the implementations thread-safe without additional synchronization.

## Comparison Table

| Feature | @StateObject | @ObservedObject |
|---------|--------------|-----------------|
| **Ownership** | View owns the object | View does not own |
| **Creation** | View creates object | Object passed from parent |
| **Initialization** | Lazy (`@autoclosure`) | Immediate (required parameter) |
| **Lifecycle** | Tied to view lifetime | External lifecycle |
| **Use Case** | Object source of truth | Object consumer/observer |
| **Typical Location** | Root/parent views | Child views |
| **Projected Value** | The object itself | The object itself |

## Best Practices

1. **Use @StateObject When:**
   - The view should create and own the object
   - The object represents the view's source of truth
   - The object should persist for the view's lifetime

2. **Use @ObservedObject When:**
   - The object is passed from a parent view
   - The object is owned by another component
   - Multiple views need to observe the same object

3. **Always Call setupPublished():**
   ```swift
   @MainActor
   final class MyModel: ObservableObject {
       @Published var value: Int = 0

       init() {
           setupPublished()  // Required!
       }
   }
   ```

4. **Don't Mix Ownership:**
   ```swift
   // ❌ Wrong: Using @StateObject for passed object
   struct ChildView: View {
       @StateObject var settings: Settings  // Should be @ObservedObject
   }

   // ✅ Correct: Using @ObservedObject for passed object
   struct ChildView: View {
       @ObservedObject var settings: Settings
   }
   ```

5. **Projected Value Access:**
   ```swift
   struct ParentView: View {
       @StateObject private var model = MyModel()

       var body: some View {
           ChildView(model: model)   // Pass wrappedValue
           // or
           ChildView(model: $model)  // Pass projectedValue (same thing)
       }
   }
   ```

## Implementation Notes

### Memory Management

- Storage classes are reference types to maintain identity across view updates
- Weak references are not used because object lifecycle is clear:
  - `@StateObject`: View owns object (strong reference)
  - `@ObservedObject`: External owner manages lifecycle
- Subscriptions are properly cleaned up when objects change or are destroyed

### Sendable and Concurrency

The implementation uses `@unchecked Sendable` for storage classes because:

1. All access is `@MainActor`-isolated
2. No concurrent mutation is possible
3. Swift's actor isolation provides safety guarantees

All closures are marked `@Sendable @MainActor` to satisfy Swift 6.2 strict concurrency checks.

### Lazy Initialization Strategy

`@StateObject` uses lazy initialization because:

1. Avoids unnecessary object creation if view is never rendered
2. Allows inline initialization syntax with `@autoclosure`
3. Ensures object is created on the main actor
4. Matches SwiftUI's behavior

The object is created on first access to `wrappedValue`, and the same instance is returned on subsequent accesses.

### DynamicProperty Integration

The `update()` method from `DynamicProperty` ensures:

1. Objects are initialized before view rendering
2. Subscriptions are active
3. Proper integration with Raven's rendering lifecycle

The rendering system can call `update()` during the view update phase to ensure all dynamic properties are synchronized.

## Testing

See `/Examples/StateObjectExample.swift` for comprehensive usage examples including:

- Basic counter with `@StateObject`
- Parent-child communication with both property wrappers
- Multiple observable objects in one view
- Shared data stores across multiple child views
- Complex state management scenarios

## See Also

- `ObservableObject.swift` - The observable object protocol
- `Published.swift` - The `@Published` property wrapper
- `State.swift` - The `@State` property wrapper
- `Environment.swift` - The `@Environment` property wrapper
