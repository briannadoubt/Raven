import Foundation

// MARK: - FocusState Property Wrapper

/// A property wrapper type that can read and write focus state for a view hierarchy.
///
/// Use `@FocusState` to track and control keyboard focus within your views. The framework
/// manages the storage for focus state properties and automatically updates views when
/// focus changes.
///
/// ## Overview
///
/// `@FocusState` is a property wrapper that manages keyboard focus within a view hierarchy.
/// It works with the `focused(_:equals:)` and `focusable(_:)` modifiers to create a
/// bidirectional connection between focus state and specific views.
///
/// ## Basic Usage
///
/// Use `@FocusState` with a boolean value to track simple focus states:
///
/// ```swift
/// struct LoginForm: View {
///     @FocusState private var isUsernameFocused: Bool
///     @State private var username = ""
///
///     var body: some View {
///         TextField("Username", text: $username)
///             .focused($isUsernameFocused)
///             .onAppear {
///                 isUsernameFocused = true  // Focus username field on appear
///             }
///     }
/// }
/// ```
///
/// ## Focus with Enum Values
///
/// Use `@FocusState` with an optional Hashable type to manage focus across multiple fields:
///
/// ```swift
/// struct SignupForm: View {
///     enum Field: Hashable {
///         case username
///         case email
///         case password
///     }
///
///     @FocusState private var focusedField: Field?
///     @State private var username = ""
///     @State private var email = ""
///     @State private var password = ""
///
///     var body: some View {
///         VStack {
///             TextField("Username", text: $username)
///                 .focused($focusedField, equals: .username)
///
///             TextField("Email", text: $email)
///                 .focused($focusedField, equals: .email)
///
///             SecureField("Password", text: $password)
///                 .focused($focusedField, equals: .password)
///
///             Button("Next") {
///                 // Cycle through fields
///                 switch focusedField {
///                 case .username: focusedField = .email
///                 case .email: focusedField = .password
///                 case .password: focusedField = nil
///                 case nil: focusedField = .username
///                 }
///             }
///         }
///     }
/// }
/// ```
///
/// ## Best Practices
///
/// - Always declare `@FocusState` properties as `private` to prevent external modification
/// - Use enums for managing focus across multiple related fields
/// - Consider accessibility when programmatically changing focus
/// - Test focus behavior with keyboard navigation
///
/// ## See Also
///
/// - ``FocusManager``
/// - ``View/focused(_:)``
/// - ``View/focused(_:equals:)``
@MainActor
@propertyWrapper
public struct FocusState<Value: Sendable>: DynamicProperty {
    /// The underlying storage for the focus state value
    private let storage: FocusStateStorage<Value>

    /// Creates a focus state with an initial value.
    ///
    /// - Parameter wrappedValue: The initial value of the focus state.
    public init(wrappedValue: Value) {
        self.storage = FocusStateStorage(initialValue: wrappedValue)
    }

    /// The current value of the focus state.
    ///
    /// Reading this property returns the current focus state value.
    /// Writing to this property updates the focus state and triggers focus changes.
    public var wrappedValue: Value {
        get {
            storage.currentValue
        }
        nonmutating set {
            storage.setValue(newValue)
        }
    }

    /// A binding to the focus state value.
    ///
    /// Use the projected value (accessed with `$`) to pass a binding to the
    /// focus state to the `focused()` modifier.
    ///
    /// Example:
    /// ```swift
    /// @FocusState private var isFieldFocused: Bool
    ///
    /// var body: some View {
    ///     TextField("Name", text: $name)
    ///         .focused($isFieldFocused)
    /// }
    /// ```
    public var projectedValue: FocusBinding<Value> {
        FocusBinding(storage: storage)
    }

    /// Set the update callback for this focus state.
    ///
    /// This is called internally by the rendering system to establish the
    /// connection between focus state changes and view updates.
    ///
    /// - Parameter callback: Closure to call when the focus state value changes
    internal func setUpdateCallback(_ callback: @escaping @Sendable @MainActor () -> Void) {
        storage.setUpdateCallback(callback)
    }
}

// MARK: - FocusState Storage

/// Internal storage for @FocusState property wrapper values.
///
/// This class holds the actual value and provides a mechanism to trigger
/// view updates when the value changes. It must be a class (reference type)
/// so that it can be shared between property wrapper instances.
@MainActor
internal final class FocusStateStorage<Value: Sendable>: @unchecked Sendable {
    /// The stored value
    private var value: Value

    /// Closure called when the value changes
    private var onUpdate: (@Sendable @MainActor () -> Void)?

    /// Focus scope ID for tracking which scope owns this state
    private var scopeID: UUID?

    /// Initialize with an initial value
    /// - Parameter value: The initial value to store
    init(initialValue: Value) {
        self.value = initialValue
        self.onUpdate = nil
        self.scopeID = nil
    }

    /// Get the current value
    var currentValue: Value {
        value
    }

    /// Set a new value and trigger update callback
    /// - Parameter newValue: The new value to store
    func setValue(_ newValue: Value) {
        value = newValue

        // Notify the focus manager about the change
        Task { @MainActor in
            FocusManager.shared.updateFocusFromState(newValue, storage: self)
            onUpdate?()
        }
    }

    /// Set the update callback
    /// - Parameter callback: Closure to call when value changes
    func setUpdateCallback(_ callback: @escaping @Sendable @MainActor () -> Void) {
        self.onUpdate = callback
    }

    /// Get the scope ID
    var currentScopeID: UUID? {
        scopeID
    }

    /// Set the scope ID
    func setScopeID(_ id: UUID) {
        scopeID = id
    }
}

// MARK: - FocusBinding

/// A binding type specifically for focus state management.
///
/// `FocusBinding` provides a type-safe way to connect focus state with view modifiers.
/// It wraps the underlying storage and provides read/write access to the focus value.
@MainActor
public struct FocusBinding<Value: Sendable>: Sendable {
    /// Reference to the underlying storage
    internal let storage: FocusStateStorage<Value>

    /// Internal initializer
    /// - Parameter storage: The focus state storage to bind to
    @MainActor
    internal init(storage: FocusStateStorage<Value>) {
        self.storage = storage
    }

    /// The current value of the binding
    public var wrappedValue: Value {
        get { storage.currentValue }
        nonmutating set { storage.setValue(newValue) }
    }

    /// Access the storage (internal use only)
    internal var internalStorage: FocusStateStorage<Value> {
        storage
    }
}

// MARK: - FocusState Boolean Extension

extension FocusState where Value == Bool {
    /// Creates a focus state for a boolean value.
    ///
    /// This is the most common form of `@FocusState`, used to track whether
    /// a single view has focus.
    ///
    /// Example:
    /// ```swift
    /// @FocusState private var isFocused: Bool
    /// ```
    public init() {
        self.init(wrappedValue: false)
    }
}

// MARK: - FocusState Optional Extension

extension FocusState where Value: Hashable {
    /// Creates a focus state for an optional hashable value.
    ///
    /// This form of `@FocusState` is commonly used with enums to manage
    /// focus across multiple related fields.
    ///
    /// Example:
    /// ```swift
    /// enum Field: Hashable {
    ///     case name, email, password
    /// }
    /// @FocusState private var focusedField: Field?
    /// ```
    public init<Wrapped>() where Value == Wrapped?, Wrapped: Hashable {
        self.init(wrappedValue: nil)
    }
}

// MARK: - Sendable Conformance

// FocusState is @unchecked Sendable because FocusStateStorage is marked as such
// The MainActor isolation ensures thread safety
// Note: FocusState already conforms to Sendable via DynamicProperty
// extension FocusState: @unchecked Sendable {}

// FocusBinding already conforms to Sendable in its declaration
