import Foundation

// MARK: - ObservableObjectPublisher

/// A publisher that emits before the object has changed.
///
/// This is a simple publisher implementation that works with WASM runtime.
/// Since Combine is not fully supported in SwiftWasm, we implement our own
/// minimal publisher that provides the same functionality.
@MainActor
public final class ObservableObjectPublisher: @unchecked Sendable {
    /// Subscribers to notify when the object will change
    private var subscribers: [UUID: @Sendable @MainActor () -> Void] = [:]

    /// Send a notification that the object will change
    ///
    /// This should be called before any properties change to allow subscribers
    /// (typically views) to prepare for the update.
    public func send() {
        for subscriber in subscribers.values {
            subscriber()
        }
    }

    /// Subscribe to changes with a callback
    ///
    /// - Parameter callback: Closure to call when object will change
    /// - Returns: A subscription ID that can be used to unsubscribe
    @discardableResult
    public func subscribe(_ callback: @escaping @Sendable @MainActor () -> Void) -> UUID {
        let id = UUID()
        subscribers[id] = callback
        return id
    }

    /// Unsubscribe from changes
    ///
    /// - Parameter id: The subscription ID to remove
    public func unsubscribe(_ id: UUID) {
        subscribers.removeValue(forKey: id)
    }

    /// Remove all subscribers
    public func removeAllSubscribers() {
        subscribers.removeAll()
    }
}

// MARK: - ObservableObject Protocol

/// A type of object with a publisher that emits before the object has changed.
///
/// By default, an `ObservableObject` synthesizes an `objectWillChange`
/// publisher that emits the changed value before any of its `@Published`
/// properties changes.
///
/// ## Overview
///
/// Use `ObservableObject` for reference types that contain complex state or
/// business logic. Unlike `@State`, which manages value types, observable
/// objects are classes that can be shared across multiple views.
///
/// ## Basic Usage
///
/// Create a class conforming to `ObservableObject` and use `@Published` for
/// properties that should trigger view updates:
///
/// ```swift
/// @MainActor
/// class UserSettings: ObservableObject {
///     @Published var username: String = ""
///     @Published var isDarkMode: Bool = false
///
///     init() {
///         setupPublished()
///     }
/// }
///
/// struct SettingsView: View {
///     @ObservedObject var settings: UserSettings
///
///     var body: some View {
///         VStack {
///             TextField("Username", text: $settings.username)
///             Toggle("Dark Mode", isOn: $settings.isDarkMode)
///         }
///     }
/// }
/// ```
///
/// ## Manual Change Notifications
///
/// Manually emit change notifications for properties that don't use `@Published`:
///
/// ```swift
/// @MainActor
/// class DataStore: ObservableObject {
///     var items: [String] = [] {
///         willSet {
///             objectWillChange.send()
///         }
///     }
///
///     func addItem(_ item: String) {
///         objectWillChange.send()
///         items.append(item)
///     }
/// }
/// ```
///
/// ## Complex State Management
///
/// Use observable objects for business logic and complex state:
///
/// ```swift
/// @MainActor
/// class ShoppingCart: ObservableObject {
///     @Published var items: [CartItem] = []
///     @Published var total: Double = 0
///
///     init() {
///         setupPublished()
///     }
///
///     func addItem(_ item: CartItem) {
///         items.append(item)
///         calculateTotal()
///     }
///
///     func removeItem(at index: Int) {
///         items.remove(at: index)
///         calculateTotal()
///     }
///
///     private func calculateTotal() {
///         total = items.reduce(0) { $0 + $1.price }
///     }
/// }
/// ```
///
/// ## Best Practices
///
/// - Always call `setupPublished()` in your initializer to connect `@Published` properties
/// - Mark your class with `@MainActor` for thread safety
/// - Use `@StateObject` in the view that creates the object
/// - Use `@ObservedObject` in child views that receive the object
/// - Keep business logic in observable objects, not in views
///
/// ## When to Use ObservableObject
///
/// Use `ObservableObject` when:
/// - Managing complex state with multiple related properties
/// - Implementing business logic and data operations
/// - Sharing state across multiple views
/// - Working with reference types
///
/// Consider alternatives when:
/// - Managing simple values → Use `@State`
/// - Working with value types → Use `@State` with structs
/// - State is local to a single view → Use `@State`
///
/// ## See Also
///
/// - ``Published``
/// - ``StateObject``
/// - ``ObservedObject``
/// - ``ObservableObjectPublisher``
@MainActor
public protocol ObservableObject: AnyObject, Sendable {
    /// A publisher that emits before the object has changed.
    ///
    /// The default implementation creates a new publisher for each conforming type.
    /// You can provide your own implementation if you need custom behavior.
    var objectWillChange: ObservableObjectPublisher { get }
}

// MARK: - Default Implementation

extension ObservableObject {
    /// Default implementation provides a stored publisher.
    ///
    /// Note: This uses a global dictionary to store publishers per object instance.
    /// This is necessary because protocol extensions cannot have stored properties.
    public var objectWillChange: ObservableObjectPublisher {
        // Use ObjectIdentifier to look up the publisher for this instance
        let key = ObjectIdentifier(self)
        return ObservableObjectPublisherStorage.shared.publisher(for: key)
    }
}

// MARK: - Publisher Storage

/// Internal storage for ObservableObjectPublisher instances.
///
/// This singleton maintains publishers for ObservableObject instances
/// since protocol extensions cannot have stored properties.
@MainActor
private final class ObservableObjectPublisherStorage: @unchecked Sendable {
    static let shared = ObservableObjectPublisherStorage()

    private var publishers: [ObjectIdentifier: ObservableObjectPublisher] = [:]

    private init() {}

    func publisher(for key: ObjectIdentifier) -> ObservableObjectPublisher {
        if let existing = publishers[key] {
            return existing
        }
        let new = ObservableObjectPublisher()
        publishers[key] = new
        return new
    }

    func removePublisher(for key: ObjectIdentifier) {
        publishers.removeValue(forKey: key)
    }
}

// MARK: - Published Property Wrapper

/// A property wrapper that publishes changes to an observable object's publisher.
///
/// When you use `@Published` on a property of an `ObservableObject`, the object's
/// `objectWillChange` publisher emits before the property changes.
///
/// ## Overview
///
/// `@Published` is a property wrapper that automatically notifies observers
/// when a property's value changes. It's designed to work with `ObservableObject`
/// to trigger view updates in Raven.
///
/// ## Basic Usage
///
/// Use `@Published` on properties of an `ObservableObject` that should trigger updates:
///
/// ```swift
/// @MainActor
/// class Counter: ObservableObject {
///     @Published var count: Int = 0
///     @Published var name: String = "Counter"
///
///     init() {
///         setupPublished()
///     }
/// }
/// ```
///
/// ## Creating Bindings
///
/// Use the `$` prefix to create a binding to a published property:
///
/// ```swift
/// @MainActor
/// class Settings: ObservableObject {
///     @Published var text: String = ""
///
///     init() {
///         setupPublished()
///     }
/// }
///
/// struct SettingsView: View {
///     @ObservedObject var settings: Settings
///
///     var body: some View {
///         TextField("Text", text: $settings.text)
///     }
/// }
/// ```
///
/// ## Change Notifications
///
/// `@Published` automatically sends notifications before the value changes:
///
/// ```swift
/// @MainActor
/// class DataModel: ObservableObject {
///     @Published var value: Int = 0
///
///     init() {
///         setupPublished()
///         objectWillChange.subscribe {
///             print("Value will change")
///         }
///     }
/// }
///
/// let model = DataModel()
/// model.value = 10  // Prints: "Value will change"
/// ```
///
/// ## Important Notes
///
/// - `@Published` is only available on properties of classes conforming to `ObservableObject`
/// - Always call `setupPublished()` in your `ObservableObject` initializer
/// - The property value type must conform to `Sendable`
/// - Changes trigger view updates automatically
///
/// ## See Also
///
/// - ``ObservableObject``
/// - ``ObservableObjectPublisher``
/// - ``StateObject``
/// - ``ObservedObject``
@MainActor
@propertyWrapper
public struct Published<Value: Sendable>: @unchecked Sendable {
    /// The underlying storage for the published value
    private final class Storage: @unchecked Sendable {
        var value: Value
        weak var owner: (any ObservableObject)?

        init(value: Value) {
            self.value = value
        }
    }

    private let storage: Storage

    /// Creates a published property with an initial value.
    ///
    /// - Parameter wrappedValue: The initial value of the property.
    public init(wrappedValue: Value) {
        self.storage = Storage(value: wrappedValue)
    }

    /// The current value of the published property.
    ///
    /// When you access this property, you get the current value.
    /// When you set this property, it publishes the change to the
    /// observable object's `objectWillChange` publisher before updating.
    @MainActor
    public var wrappedValue: Value {
        get {
            storage.value
        }
        nonmutating set {
            // Send willChange notification before updating
            storage.owner?.objectWillChange.send()
            storage.value = newValue
        }
    }

    /// A binding to the published property.
    ///
    /// Use the projected value (accessed with `$`) to create a binding
    /// to the published property.
    ///
    /// Example:
    /// ```swift
    /// @MainActor
    /// class Settings: ObservableObject {
    ///     @Published var text: String = ""
    /// }
    ///
    /// struct SettingsView: View {
    ///     @ObservedObject var settings: Settings
    ///
    ///     var body: some View {
    ///         TextField("Text", text: $settings.text)
    ///     }
    /// }
    /// ```
    public var projectedValue: Binding<Value> {
        Binding(
            get: { self.wrappedValue },
            set: { newValue in
                self.wrappedValue = newValue
            }
        )
    }

    /// Internal method to set the owner of this published property.
    ///
    /// This is called by the rendering system to establish the connection
    /// between the published property and its owning observable object.
    ///
    /// - Parameter owner: The observable object that owns this property
    @MainActor
    internal mutating func setOwner(_ owner: any ObservableObject) {
        storage.owner = owner
    }
}

// MARK: - Published + EnclosedSelf

/// Internal protocol for accessing the enclosing instance.
///
/// This is used by the rendering system to automatically set up
/// the connection between @Published properties and their owning
/// ObservableObject.
@MainActor
public protocol _PublishedProperty {
    /// Set the owner of this published property
    mutating func _setOwner(_ owner: any ObservableObject)
}

@MainActor
extension Published: _PublishedProperty {
    public mutating func _setOwner(_ owner: any ObservableObject) {
        setOwner(owner)
    }
}

// MARK: - ObservableObject Initialization Helper

extension ObservableObject {
    /// Initialize all @Published properties with this object as their owner.
    ///
    /// This should be called in the init() of classes conforming to ObservableObject
    /// to ensure @Published properties are properly connected.
    ///
    /// Example:
    /// ```swift
    /// @MainActor
    /// class MyData: ObservableObject {
    ///     @Published var value: Int = 0
    ///
    ///     init() {
    ///         setupPublished()
    ///     }
    /// }
    /// ```
    @MainActor
    public func setupPublished() {
        let mirror = Mirror(reflecting: self)
        for child in mirror.children {
            if var published = child.value as? _PublishedProperty {
                published._setOwner(self)
            }
        }
    }
}
