import Foundation

// MARK: - StateObject Property Wrapper

/// A property wrapper type that instantiates an observable object.
///
/// Use `@StateObject` to create an observable object that is owned by a view.
/// The view creates and owns the object, and maintains it across view updates.
/// The object is created only once during the lifetime of the view.
///
/// ## Overview
///
/// `@StateObject` is the property wrapper for creating and owning an
/// `ObservableObject` within a view. It ensures the object is created only
/// once and persists across view updates.
///
/// ## Basic Usage
///
/// Create an observable object that's owned by the view:
///
/// ```swift
/// @MainActor
/// class TimerModel: ObservableObject {
///     @Published var count: Int = 0
///
///     init() {
///         setupPublished()
///     }
///
///     func increment() {
///         count += 1
///     }
/// }
///
/// struct TimerView: View {
///     @StateObject private var timer = TimerModel()
///
///     var body: some View {
///         VStack {
///             Text("Count: \(timer.count)")
///             Button("Increment") {
///                 timer.increment()
///             }
///         }
///     }
/// }
/// ```
///
/// ## Passing to Child Views
///
/// Pass the state object to child views using `@ObservedObject`:
///
/// ```swift
/// struct ParentView: View {
///     @StateObject private var model = DataModel()
///
///     var body: some View {
///         VStack {
///             HeaderView(model: model)
///             ContentView(model: model)
///         }
///     }
/// }
///
/// struct ContentView: View {
///     @ObservedObject var model: DataModel
///
///     var body: some View {
///         Text("Value: \(model.value)")
///     }
/// }
/// ```
///
/// ## Initialization with Parameters
///
/// Create state objects with initialization parameters:
///
/// ```swift
/// @MainActor
/// class UserProfile: ObservableObject {
///     @Published var name: String
///     @Published var bio: String
///
///     init(name: String) {
///         self.name = name
///         self.bio = ""
///         setupPublished()
///     }
/// }
///
/// struct ProfileView: View {
///     let username: String
///     @StateObject private var profile: UserProfile
///
///     init(username: String) {
///         self.username = username
///         _profile = StateObject(wrappedValue: UserProfile(name: username))
///     }
///
///     var body: some View {
///         VStack {
///             Text(profile.name)
///             TextField("Bio", text: $profile.bio)
///         }
///     }
/// }
/// ```
///
/// ## Best Practices
///
/// - Always declare `@StateObject` properties as `private` to prevent external modification
/// - Use `@StateObject` in the view that creates and owns the object
/// - Pass the object to child views using `@ObservedObject`
/// - The object is created once and persists for the view's lifetime
/// - Always call `setupPublished()` in your `ObservableObject` initializer
///
/// ## @StateObject vs @ObservedObject
///
/// **Use @StateObject when:**
/// - The view creates and owns the observable object
/// - The object should persist across view updates
/// - The object lifetime is tied to the view's lifetime
///
/// **Use @ObservedObject when:**
/// - The object is created by a parent view
/// - The object is passed as a parameter
/// - The view observes but doesn't own the object
///
/// ## See Also
///
/// - ``ObservedObject``
/// - ``ObservableObject``
/// - ``Published``
@MainActor
@propertyWrapper
public struct StateObject<ObjectType: ObservableObject>: DynamicProperty {
    /// Storage for the observable object
    private final class Storage: @unchecked Sendable {
        /// The observable object instance
        var object: ObjectType?

        /// The initializer closure to create the object lazily
        let initializer: @Sendable @MainActor () -> ObjectType

        /// Subscription ID for the objectWillChange publisher
        var subscriptionID: UUID?

        /// Callback to trigger view updates
        var updateCallback: (@Sendable @MainActor () -> Void)?

        init(initializer: @escaping @Sendable @MainActor () -> ObjectType) {
            self.initializer = initializer
        }
    }

    /// Internal storage for the object
    private let storage: Storage

    /// Creates a state object with a wrapped value initializer.
    ///
    /// The initializer is called lazily on first access to create the object.
    /// The object is then retained for the lifetime of the view.
    ///
    /// - Parameter wrappedValue: An autoclosure that creates the observable object.
    public init(wrappedValue: @autoclosure @escaping @Sendable @MainActor () -> ObjectType) {
        self.storage = Storage(initializer: wrappedValue)
    }

    /// The underlying observable object.
    ///
    /// On first access, this creates the object using the initializer and sets up
    /// the subscription to objectWillChange. Subsequent accesses return the same object.
    public var wrappedValue: ObjectType {
        // Lazy initialization: create object on first access
        if storage.object == nil {
            let object = storage.initializer()
            storage.object = object

            // Subscribe to objectWillChange to trigger view updates
            let subscriptionID = object.objectWillChange.subscribe { [storage] in
                // Trigger view update when object changes
                storage.updateCallback?()
            }
            storage.subscriptionID = subscriptionID
        }

        return storage.object!
    }

    /// A projection of the state object that returns the object itself.
    ///
    /// Use the projected value (accessed with `$`) to pass the observable object
    /// to child views that need to observe it.
    ///
    /// Example:
    /// ```swift
    /// struct ParentView: View {
    ///     @StateObject private var model = MyModel()
    ///
    ///     var body: some View {
    ///         ChildView(model: model)  // Passes the object directly
    ///     }
    /// }
    ///
    /// struct ChildView: View {
    ///     @ObservedObject var model: MyModel
    ///
    ///     var body: some View {
    ///         Text("\(model.value)")
    ///     }
    /// }
    /// ```
    public var projectedValue: ObjectType {
        wrappedValue
    }

    /// Called by the rendering system to update the property.
    ///
    /// This implementation ensures the object is initialized and subscribed to changes.
    @MainActor
    public mutating func update() {
        // Ensure object is initialized by accessing wrappedValue
        _ = wrappedValue
    }

    /// Set the update callback for this state object.
    ///
    /// This is called internally by the rendering system to establish the
    /// connection between object changes and view updates.
    ///
    /// - Parameter callback: Closure to call when the object changes
    internal func setUpdateCallback(_ callback: @escaping @Sendable @MainActor () -> Void) {
        storage.updateCallback = callback

        // If object is already initialized, update the subscription
        if storage.object != nil, let subscriptionID = storage.subscriptionID {
            // Re-subscribe with new callback
            storage.object?.objectWillChange.unsubscribe(subscriptionID)
            let newID = storage.object?.objectWillChange.subscribe { [storage] in
                storage.updateCallback?()
            }
            storage.subscriptionID = newID
        }
    }
}

// MARK: - Sendable Conformance

// StateObject is @unchecked Sendable because Storage is marked as such
// The MainActor isolation ensures thread safety
extension StateObject: @unchecked Sendable {}

// MARK: - Integration with Rendering System

/// Internal protocol for accessing StateObject update callback
@MainActor
public protocol _StateObjectProperty {
    /// Set the update callback for this state object
    mutating func _setUpdateCallback(_ callback: @escaping @Sendable @MainActor () -> Void)
}

@MainActor
extension StateObject: _StateObjectProperty {
    public mutating func _setUpdateCallback(_ callback: @escaping @Sendable @MainActor () -> Void) {
        setUpdateCallback(callback)
    }
}
