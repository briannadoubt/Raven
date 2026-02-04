# ObservableObject Implementation

This document describes the implementation of the `ObservableObject` protocol and related components in Raven.

## Overview

Since Combine framework is not fully supported in SwiftWasm (OpenCombine has limitations on WASM), we've implemented a custom, minimal ObservableObject protocol that provides the same functionality while being compatible with Swift 6.2 strict concurrency and the WASM runtime.

## Components

### 1. ObservableObjectPublisher

A custom publisher that emits before an object changes. This replaces Combine's `ObservableObjectPublisher`.

```swift
@MainActor
public final class ObservableObjectPublisher: @unchecked Sendable {
    public func send()
    public func subscribe(_ callback: @escaping @Sendable @MainActor () -> Void) -> UUID
    public func unsubscribe(_ id: UUID)
    public func removeAllSubscribers()
}
```

Features:
- Thread-safe subscription management
- MainActor isolated for UI updates
- UUID-based subscription tracking
- Multiple subscriber support

### 2. ObservableObject Protocol

The main protocol that objects conform to when they want to publish changes.

```swift
@MainActor
public protocol ObservableObject: AnyObject, Sendable {
    var objectWillChange: ObservableObjectPublisher { get }
}
```

Features:
- Automatic publisher via default implementation
- Uses a global storage dictionary keyed by ObjectIdentifier
- MainActor isolated for consistency with SwiftUI
- Sendable for Swift 6 concurrency

### 3. @Published Property Wrapper

A property wrapper that automatically publishes changes through the parent ObservableObject.

```swift
@MainActor
@propertyWrapper
public struct Published<Value: Sendable>: @unchecked Sendable {
    public var wrappedValue: Value { get nonmutating set }
    public var projectedValue: Binding<Value> { get }
}
```

Features:
- Automatically calls `objectWillChange.send()` before value changes
- Provides a `Binding` through projected value (`$`)
- Works with `setupPublished()` helper method
- Swift 6 strict concurrency compliant

### 4. setupPublished() Helper

A convenience method for ObservableObject classes to automatically connect @Published properties.

```swift
extension ObservableObject {
    @MainActor
    public func setupPublished()
}
```

Usage:
```swift
@MainActor
final class MyData: ObservableObject {
    @Published var value: Int = 0

    init() {
        setupPublished()  // Call in init to connect @Published properties
    }
}
```

## Usage Examples

### Basic ObservableObject

```swift
@MainActor
final class Counter: ObservableObject {
    @Published var count: Int = 0
    @Published var name: String = "Counter"

    init() {
        setupPublished()
    }

    func increment() {
        count += 1
    }
}
```

### Manual Notifications

```swift
@MainActor
final class DataStore: ObservableObject {
    private var _items: [String] = []

    var items: [String] {
        get { _items }
        set {
            objectWillChange.send()  // Manual notification
            _items = newValue
        }
    }

    init() {
        setupPublished()
    }
}
```

### Subscribing to Changes

```swift
let counter = Counter()

let subscriptionId = counter.objectWillChange.subscribe {
    print("Counter will change")
}

counter.count = 5  // Prints: "Counter will change"

// Later, unsubscribe
counter.objectWillChange.unsubscribe(subscriptionId)
```

### With Views (Future: @ObservedObject, @StateObject)

```swift
struct CounterView: View {
    @ObservedObject var counter: Counter  // Future implementation

    var body: some View {
        VStack {
            Text("Count: \(counter.count)")
            Button("Increment") {
                counter.increment()
            }
        }
    }
}
```

## Implementation Details

### Swift 6 Concurrency

- All types are `@MainActor` isolated to ensure UI thread safety
- Properties use `nonmutating set` where appropriate
- `@unchecked Sendable` is used carefully with proper synchronization
- Closures are marked `@Sendable` for thread safety

### WASM Compatibility

- No dependency on Combine framework
- No dependency on Dispatch (not available in WASM)
- Pure Swift implementation using standard library only
- Compatible with JavaScriptKit for WASM interop

### Memory Management

- Uses `weak` reference in Published to prevent retain cycles
- ObservableObjectPublisher instances managed by global storage
- Automatic cleanup when objects are deallocated

## Testing

All functionality is tested in `ObservableObjectTests.swift`:

- ✅ Publisher send/subscribe/unsubscribe
- ✅ @Published property changes
- ✅ Multiple @Published properties
- ✅ Manual objectWillChange notifications
- ✅ Multiple subscribers
- ✅ Counter, UserSettings, DataStore examples
- ✅ TodoItem and TodoList with nested objects
- ✅ MainActor isolation

All 12 tests pass successfully.

## Next Steps

The following property wrappers will build on this foundation:

1. **@StateObject** - Creates and owns an ObservableObject instance
2. **@ObservedObject** - References an existing ObservableObject instance

Both will use the `objectWillChange` publisher to trigger view updates.

## References

- SwiftWasm documentation: https://book.swiftwasm.org/
- OpenCombine limitations: https://github.com/OpenCombine/OpenCombine
- Swift Concurrency: https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html
