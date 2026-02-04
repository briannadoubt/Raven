# @State Quick Reference

## Basic Usage

```swift
// Declare state
@State private var count = 0

// Read state
Text("Count: \(count)")

// Write state
count += 1
```

## Common Patterns

### Counter
```swift
@State private var count = 0

Button("Increment") {
    count += 1
}
```

### Toggle
```swift
@State private var isOn = false

Button(isOn ? "On" : "Off") {
    isOn.toggle()
}
```

### Text Input
```swift
@State private var text = ""

TextField("Enter text", text: $text)
```

## Bindings

### Pass to Child
```swift
// Parent
@State private var value = 0
ChildView(value: $value)

// Child
@Binding var value: Int
```

### Constant
```swift
ChildView(value: .constant(42))
```

### Custom
```swift
Binding(
    get: { sourceValue },
    set: { sourceValue = $0 }
)
```

## Key Rules

1. Always use `private`
2. Only in structs that conform to `View`
3. For local, mutable state only
4. Use `@Binding` for shared state
5. All on `@MainActor`

## Files

- **Source:** `Sources/Raven/State/State.swift`
- **Tests:** `Tests/RavenTests/StateTests.swift`
- **Docs:** `Documentation/State.md`
- **Examples:** `Examples/StateExample.swift`

## API

```swift
// State
@State var value: Value
value.wrappedValue  // Get/set
$value              // Binding

// Binding
@Binding var value: Value
value.wrappedValue  // Get/set
$value              // Self

// DynamicProperty
protocol DynamicProperty {
    mutating func update()
}
```
