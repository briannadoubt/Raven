import Foundation

// MARK: - DynamicProperty Protocol

/// A protocol that marks types that can participate in the view update lifecycle.
///
/// Types conforming to `DynamicProperty` can be used within views and will be
/// notified when they need to update their state. This is primarily used by
/// property wrappers like `@State` and `@Binding` to track changes and trigger
/// view updates.
///
/// The rendering system uses this protocol to detect property wrapper types
/// that need special handling during the view lifecycle.
public protocol DynamicProperty: Sendable {
    /// Called when the property needs to update its internal state.
    ///
    /// This method is called by the rendering system when a view's dynamic
    /// properties need to be synchronized with the current render context.
    @MainActor mutating func update()
}

// MARK: - Default Implementation

extension DynamicProperty {
    /// Default implementation does nothing.
    ///
    /// Most dynamic properties don't need to do anything on update,
    /// so we provide a default empty implementation.
    @MainActor public mutating func update() {
        // Default implementation does nothing
    }
}

// MARK: - Render Scheduler

/// Global bridge between @State mutations and the render coordinator.
///
/// When a `StateStorage` value changes and no explicit `onUpdate` closure
/// is wired (the standard case — `onUpdate` is currently unused), it calls
/// `_RenderScheduler.current?.scheduleRender()` to trigger a batched render.
@MainActor
public enum _RenderScheduler {
    /// Weak reference to the active render coordinator.
    public static weak var current: (any _StateChangeReceiver)?

    /// The component path currently being evaluated during a render pass.
    /// Set by `RenderCoordinator.convertViewToVNode` so that `StateStorage`
    /// can lazily associate itself with the component that reads it.
    public static var currentComponentPath: String?
}

// MARK: - State Storage

/// Internal storage for @State property wrapper values.
///
/// This class holds the actual value and provides a mechanism to trigger
/// view updates when the value changes. It must be a class (reference type)
/// so that it can be shared between the property wrapper instances created
/// during view updates while maintaining identity.
@MainActor
private final class StateStorage<Value: Sendable>: @unchecked Sendable {
    /// The stored value
    private var value: Value

    /// Closure called when the value changes
    /// This will trigger a view update through the render coordinator
    private var onUpdate: (@Sendable @MainActor () -> Void)?

    /// The component path that owns this state, for selective re-rendering.
    /// Lazily captured on first read during a render pass.
    private var componentPath: String?

    /// Initialize with an initial value
    /// - Parameter value: The initial value to store
    init(initialValue: Value) {
        self.value = initialValue
        self.onUpdate = nil
    }

    /// Get the current value.
    /// On first access during a render pass, associates this storage with the
    /// current component path for selective re-rendering.
    var currentValue: Value {
        if componentPath == nil {
            componentPath = _RenderScheduler.currentComponentPath
        }
        return value
    }

    /// Set a new value and trigger update callback
    /// - Parameter newValue: The new value to store
    func setValue(_ newValue: Value) {
        value = newValue

        // If we know which component owns this state, mark it dirty
        // for selective re-rendering.
        if let path = componentPath {
            _RenderScheduler.current?.markDirty(path: path)
        }

        // Fire explicit onUpdate if wired (currently unused in standard path)
        if let onUpdate = onUpdate {
            onUpdate()
        } else if componentPath == nil {
            // Fallback: no component path and no onUpdate — schedule a full render
            _RenderScheduler.current?.scheduleRender()
        }
    }

    /// Set the update callback
    /// - Parameter callback: Closure to call when value changes
    func setUpdateCallback(_ callback: @escaping @Sendable @MainActor () -> Void) {
        self.onUpdate = callback
    }
}

// MARK: - State Property Wrapper

/// A property wrapper type that can read and write a value managed by Raven.
///
/// Use `@State` to create mutable state within a view. Raven manages the
/// storage for state properties and automatically updates the view when the
/// state changes.
///
/// ## Overview
///
/// `@State` is a property wrapper that manages simple value types within a view.
/// When you modify a state property, Raven automatically re-renders the view
/// to reflect the changes.
///
/// ## Basic Usage
///
/// Declare state properties as private to keep them local to the view:
///
/// ```swift
/// struct CounterView: View {
///     @State private var count = 0
///
///     var body: some View {
///         VStack {
///             Text("Count: \(count)")
///             Button("Increment") {
///                 count += 1
///             }
///         }
///     }
/// }
/// ```
///
/// ## Creating Bindings
///
/// Use the `$` prefix to create a binding to a state value:
///
/// ```swift
/// struct ToggleView: View {
///     @State private var isOn = false
///
///     var body: some View {
///         VStack {
///             Toggle("Enable", isOn: $isOn)
///             Text(isOn ? "Enabled" : "Disabled")
///         }
///     }
/// }
/// ```
///
/// ## State with Complex Types
///
/// `@State` works with any `Sendable` type, including structs and collections:
///
/// ```swift
/// struct TodoListView: View {
///     @State private var items: [String] = []
///     @State private var newItem = ""
///
///     var body: some View {
///         VStack {
///             TextField("New Item", text: $newItem)
///             Button("Add") {
///                 items.append(newItem)
///                 newItem = ""
///             }
///             List(items, id: \.self) { item in
///                 Text(item)
///             }
///         }
///     }
/// }
/// ```
///
/// ## Best Practices
///
/// - Always declare `@State` properties as `private` to prevent external modification
/// - Use `@State` for simple value types that are owned by a single view
/// - For complex objects or shared state, use `@StateObject` or `@ObservedObject`
/// - Keep state properties focused and specific to the view's needs
///
/// ## When to Use @State
///
/// Use `@State` when:
/// - Managing simple values like `Bool`, `Int`, `String`, or small structs
/// - The state is local to a single view
/// - You don't need to share the state with other views (except via bindings)
///
/// Consider alternatives when:
/// - Managing complex objects → Use `@StateObject`
/// - Receiving state from a parent view → Use `@Binding`
/// - Observing external state → Use `@ObservedObject`
///
/// ## See Also
///
/// - ``Binding``
/// - ``StateObject``
/// - ``ObservedObject``
@MainActor
@propertyWrapper
public struct State<Value: Sendable>: DynamicProperty {
    /// The underlying storage for the state value
    private let storage: StateStorage<Value>

    /// Creates a state with an initial value.
    ///
    /// - Parameter wrappedValue: The initial value of the state.
    public init(wrappedValue: Value) {
        self.storage = StateStorage(initialValue: wrappedValue)
    }

    /// Creates a state with an initial value using autoclosure.
    ///
    /// This initializer allows for lazy initialization of the state value.
    ///
    /// - Parameter initialValue: The initial value of the state.
    public init(initialValue: Value) {
        self.storage = StateStorage(initialValue: initialValue)
    }

    /// The current value of the state.
    ///
    /// Reading this property returns the current state value.
    /// Writing to this property updates the state and triggers a view update.
    public var wrappedValue: Value {
        get {
            storage.currentValue
        }
        nonmutating set {
            storage.setValue(newValue)
        }
    }

    /// A binding to the state value.
    ///
    /// Use the projected value (accessed with `$`) to pass a binding to a
    /// state value to a child view or to create a two-way connection.
    ///
    /// Example:
    /// ```swift
    /// @State private var text = ""
    ///
    /// var body: some View {
    ///     TextField("Enter text", text: $text)
    /// }
    /// ```
    public var projectedValue: Binding<Value> {
        Binding(
            get: { self.wrappedValue },
            set: { self.wrappedValue = $0 }
        )
    }

    /// Set the update callback for this state.
    ///
    /// This is called internally by the rendering system to establish the
    /// connection between state changes and view updates.
    ///
    /// - Parameter callback: Closure to call when the state value changes
    internal func setUpdateCallback(_ callback: @escaping @Sendable @MainActor () -> Void) {
        storage.setUpdateCallback(callback)
    }
}

// MARK: - Binding

/// A property wrapper type that can read and write a value owned by a source of truth.
///
/// Use a binding to create a two-way connection between a property that stores
/// data and a view that displays and changes the data. A binding connects a
/// property to a source of truth stored elsewhere, instead of storing data
/// directly.
///
/// ## Overview
///
/// `Binding` creates a reference to a value owned by another view, allowing
/// child views to read and modify that value without owning it. This enables
/// data to flow both up and down the view hierarchy.
///
/// ## Basic Usage
///
/// Create a binding by passing a state property with the `$` prefix:
///
/// ```swift
/// struct ToggleView: View {
///     @Binding var isOn: Bool
///
///     var body: some View {
///         Button(isOn ? "On" : "Off") {
///             isOn.toggle()
///         }
///     }
/// }
///
/// struct ParentView: View {
///     @State private var toggleState = false
///
///     var body: some View {
///         VStack {
///             Text("State: \(toggleState ? "On" : "Off")")
///             ToggleView(isOn: $toggleState)
///         }
///     }
/// }
/// ```
///
/// ## Accessing Nested Properties
///
/// Use key paths to create bindings to nested properties:
///
/// ```swift
/// struct User: Sendable {
///     var name: String
///     var email: String
/// }
///
/// struct ProfileView: View {
///     @State private var user = User(name: "", email: "")
///
///     var body: some View {
///         VStack {
///             TextField("Name", text: $user.name)
///             TextField("Email", text: $user.email)
///         }
///     }
/// }
/// ```
///
/// ## Custom Bindings
///
/// Create custom bindings with get and set closures for computed properties:
///
/// ```swift
/// struct TemperatureView: View {
///     @State private var celsius: Double = 20
///
///     var fahrenheitBinding: Binding<Double> {
///         Binding(
///             get: { celsius * 9/5 + 32 },
///             set: { newValue in celsius = (newValue - 32) * 5/9 }
///         )
///     }
///
///     var body: some View {
///         VStack {
///             TextField("Celsius", value: $celsius, format: .number)
///             TextField("Fahrenheit", value: fahrenheitBinding, format: .number)
///         }
///     }
/// }
/// ```
///
/// ## Constant Bindings
///
/// Use constant bindings for previews or read-only views:
///
/// ```swift
/// Toggle("Enabled", isOn: .constant(true))
/// ```
///
/// ## Best Practices
///
/// - Use `@Binding` when a child view needs to modify a parent's state
/// - Always pass bindings down the view hierarchy, never up
/// - Consider using `@ObservedObject` for complex shared state
/// - Use constant bindings for static previews
///
/// ## See Also
///
/// - ``State``
/// - ``StateObject``
/// - ``constant(_:)``
@MainActor
@propertyWrapper
@dynamicMemberLookup
public struct Binding<Value: Sendable>: DynamicProperty {
    /// Closure that reads the current value
    private let getValue: @Sendable @MainActor () -> Value

    /// Closure that writes a new value
    private let setValue: @Sendable @MainActor (Value) -> Void

    /// Creates a binding with closures that read and write the binding value.
    ///
    /// - Parameters:
    ///   - get: A closure that retrieves the binding value.
    ///   - set: A closure that sets the binding value.
    public init(
        get: @escaping @Sendable @MainActor () -> Value,
        set: @escaping @Sendable @MainActor (Value) -> Void
    ) {
        self.getValue = get
        self.setValue = set
    }

    /// The current value of the binding.
    ///
    /// Reading this property returns the current binding value by calling
    /// the get closure. Writing to this property updates the binding value
    /// by calling the set closure.
    public var wrappedValue: Value {
        get { getValue() }
        nonmutating set { setValue(newValue) }
    }

    /// A binding to the binding's value.
    ///
    /// This allows you to pass a binding to a binding, which is useful
    /// when you need to transform or constrain binding values.
    public var projectedValue: Binding<Value> {
        self
    }

    /// Provides dynamic member lookup for accessing nested properties.
    ///
    /// This subscript allows you to create a binding to a property of the
    /// binding's wrapped value using key paths. This is useful for binding
    /// to nested properties without manually creating transformation bindings.
    ///
    /// Example:
    /// ```swift
    /// struct Person: Sendable {
    ///     var name: String
    ///     var age: Int
    /// }
    ///
    /// @State private var person = Person(name: "Alice", age: 30)
    ///
    /// var body: some View {
    ///     TextField("Name", text: $person.name)
    ///     // $person.name creates a Binding<String> from Binding<Person>
    /// }
    /// ```
    ///
    /// - Parameter keyPath: A writable key path to a property of the value.
    /// - Returns: A binding to the property at the specified key path.
    public subscript<Property: Sendable>(
        dynamicMember keyPath: WritableKeyPath<Value, Property>
    ) -> Binding<Property> {
        Binding<Property>(
            get: { self.wrappedValue[keyPath: keyPath] },
            set: { newValue in
                var value = self.wrappedValue
                value[keyPath: keyPath] = newValue
                self.wrappedValue = value
            }
        )
    }
}

// MARK: - Binding Transformations

extension Binding {
    /// Creates a binding by transforming the value of another binding.
    ///
    /// This allows you to create derived bindings that transform the value
    /// being read and written.
    ///
    /// Example:
    /// ```swift
    /// @State private var temperature: Double = 20.0
    ///
    /// var fahrenheit: Binding<Double> {
    ///     Binding(
    ///         get: { temperature * 9/5 + 32 },
    ///         set: { temperature = ($0 - 32) * 5/9 }
    ///     )
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - get: A closure that transforms the source value.
    ///   - set: A closure that transforms the value back.
    public init<T>(
        _ source: Binding<T>,
        get: @escaping @Sendable @MainActor (T) -> Value,
        set: @escaping @Sendable @MainActor (T, Value) -> T
    ) where T: Sendable {
        self.getValue = { get(source.wrappedValue) }
        self.setValue = { newValue in
            source.wrappedValue = set(source.wrappedValue, newValue)
        }
    }
}

// MARK: - Constant Binding

extension Binding {
    /// Creates a binding with a constant value.
    ///
    /// Use this when you need to pass a binding to a view but don't need
    /// the value to change or don't want to respond to changes.
    ///
    /// Example:
    /// ```swift
    /// ToggleView(isOn: .constant(true))
    /// ```
    ///
    /// - Parameter value: The constant value for the binding.
    /// - Returns: A binding that always returns the specified value.
    public static func constant(_ value: Value) -> Binding<Value> {
        Binding(
            get: { value },
            set: { _ in }
        )
    }
}

// MARK: - Sendable Conformance

// State is @unchecked Sendable because StateStorage is marked as such
// The MainActor isolation ensures thread safety
extension State: @unchecked Sendable {}

// Binding is @unchecked Sendable because its closures are marked @Sendable
// The MainActor isolation ensures thread safety
extension Binding: @unchecked Sendable {}
