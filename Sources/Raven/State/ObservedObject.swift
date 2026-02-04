import Foundation

// MARK: - ObservedObject Property Wrapper

/// A property wrapper type that subscribes to an observable object and
/// invalidates a view whenever the observable object changes.
///
/// Use `@ObservedObject` when you want to observe an observable object that
/// is owned by a parent view or another source. Unlike `@StateObject`, this
/// property wrapper does not create or own the object - it only observes it.
///
/// ## Overview
///
/// `@ObservedObject` subscribes to an `ObservableObject` and triggers view
/// updates when the object changes. Use this for objects that are created
/// and owned by parent views.
///
/// ## Basic Usage
///
/// Observe an object passed from a parent view:
///
/// ```swift
/// @MainActor
/// class UserData: ObservableObject {
///     @Published var name: String = ""
///     @Published var age: Int = 0
///
///     init() {
///         setupPublished()
///     }
/// }
///
/// struct ParentView: View {
///     @StateObject private var userData = UserData()
///
///     var body: some View {
///         ProfileView(userData: userData)
///     }
/// }
///
/// struct ProfileView: View {
///     @ObservedObject var userData: UserData
///
///     var body: some View {
///         VStack {
///             TextField("Name", text: $userData.name)
///             Text("Age: \(userData.age)")
///         }
///     }
/// }
/// ```
///
/// ## Shared Observable Objects
///
/// Use `@ObservedObject` when multiple views observe the same object:
///
/// ```swift
/// @MainActor
/// class AppSettings: ObservableObject {
///     @Published var theme: Theme = .light
///     @Published var fontSize: Int = 14
///
///     init() {
///         setupPublished()
///     }
/// }
///
/// struct SettingsView: View {
///     @ObservedObject var settings: AppSettings
///
///     var body: some View {
///         VStack {
///             Picker("Theme", selection: $settings.theme) {
///                 Text("Light").tag(Theme.light)
///                 Text("Dark").tag(Theme.dark)
///             }
///             Stepper("Font Size: \(settings.fontSize)", value: $settings.fontSize)
///         }
///     }
/// }
///
/// struct PreviewView: View {
///     @ObservedObject var settings: AppSettings
///
///     var body: some View {
///         Text("Preview")
///             .font(.system(size: CGFloat(settings.fontSize)))
///     }
/// }
/// ```
///
/// ## Binding to Published Properties
///
/// Create bindings to published properties using the `$` prefix:
///
/// ```swift
/// struct EditView: View {
///     @ObservedObject var model: EditableModel
///
///     var body: some View {
///         Form {
///             TextField("Title", text: $model.title)
///             TextField("Description", text: $model.description)
///             Toggle("Published", isOn: $model.isPublished)
///         }
///     }
/// }
/// ```
///
/// ## Best Practices
///
/// - Don't declare `@ObservedObject` properties as `private` - they should be set from outside
/// - Use `@ObservedObject` for objects passed from parent views
/// - The parent view should own the object with `@StateObject`
/// - Multiple views can observe the same object
/// - Changes to the observed object trigger updates in all observing views
///
/// ## @StateObject vs @ObservedObject
///
/// **Use @ObservedObject when:**
/// - The object is created by a parent view or external source
/// - The object is passed as a parameter
/// - Multiple views need to observe the same object
/// - The view observes but doesn't own the object
///
/// **Use @StateObject when:**
/// - The view creates and owns the observable object
/// - The object should persist across view updates
/// - The object lifetime is tied to the view's lifetime
///
/// ## See Also
///
/// - ``StateObject``
/// - ``ObservableObject``
/// - ``Published``
@MainActor
@propertyWrapper
public struct ObservedObject<ObjectType: ObservableObject>: DynamicProperty {
    /// Storage for the observable object and subscription
    private final class Storage: @unchecked Sendable {
        /// The observable object being observed
        var object: ObjectType

        /// Subscription ID for the objectWillChange publisher
        var subscriptionID: UUID?

        /// Callback to trigger view updates
        var updateCallback: (@Sendable @MainActor () -> Void)?

        init(object: ObjectType) {
            self.object = object
        }
    }

    /// Internal storage for the object
    private let storage: Storage

    /// Creates an observed object with an initial value.
    ///
    /// - Parameter wrappedValue: The observable object to observe.
    public init(wrappedValue: ObjectType) {
        self.storage = Storage(object: wrappedValue)

        // Subscribe to objectWillChange to trigger view updates
        let subscriptionID = wrappedValue.objectWillChange.subscribe { [storage] in
            // Trigger view update when object changes
            storage.updateCallback?()
        }
        storage.subscriptionID = subscriptionID
    }

    /// The underlying observable object.
    ///
    /// Reading this property returns the observed object.
    /// Writing to this property updates the observed object and re-establishes
    /// the subscription to the new object.
    public var wrappedValue: ObjectType {
        get {
            storage.object
        }
        nonmutating set {
            // Unsubscribe from old object
            if let subscriptionID = storage.subscriptionID {
                storage.object.objectWillChange.unsubscribe(subscriptionID)
            }

            // Update to new object
            storage.object = newValue

            // Subscribe to new object
            let newID = newValue.objectWillChange.subscribe { [storage] in
                storage.updateCallback?()
            }
            storage.subscriptionID = newID

            // Trigger immediate update for the object change
            storage.updateCallback?()
        }
    }

    /// A projection of the observed object that returns the object itself.
    ///
    /// Use the projected value (accessed with `$`) to pass the observable object
    /// to child views or to access the object directly.
    ///
    /// Example:
    /// ```swift
    /// struct SettingsView: View {
    ///     @ObservedObject var settings: UserSettings
    ///
    ///     var body: some View {
    ///         VStack {
    ///             Text("Settings for: \(settings.username)")
    ///             // Pass the object to another view
    ///             DetailsView(settings: $settings)
    ///         }
    ///     }
    /// }
    /// ```
    public var projectedValue: ObjectType {
        wrappedValue
    }

    /// Called by the rendering system to update the property.
    ///
    /// This implementation ensures the subscription is active.
    @MainActor
    public mutating func update() {
        // Ensure subscription is active
        if storage.subscriptionID == nil {
            let subscriptionID = storage.object.objectWillChange.subscribe { [storage] in
                storage.updateCallback?()
            }
            storage.subscriptionID = subscriptionID
        }
    }

    /// Set the update callback for this observed object.
    ///
    /// This is called internally by the rendering system to establish the
    /// connection between object changes and view updates.
    ///
    /// - Parameter callback: Closure to call when the object changes
    internal func setUpdateCallback(_ callback: @escaping @Sendable @MainActor () -> Void) {
        storage.updateCallback = callback

        // If subscription exists, re-subscribe with new callback
        if let subscriptionID = storage.subscriptionID {
            storage.object.objectWillChange.unsubscribe(subscriptionID)
            let newID = storage.object.objectWillChange.subscribe { [storage] in
                storage.updateCallback?()
            }
            storage.subscriptionID = newID
        }
    }
}

// MARK: - Sendable Conformance

// ObservedObject is @unchecked Sendable because Storage is marked as such
// The MainActor isolation ensures thread safety
extension ObservedObject: @unchecked Sendable {}

// MARK: - Integration with Rendering System

/// Internal protocol for accessing ObservedObject update callback
@MainActor
public protocol _ObservedObjectProperty {
    /// Set the update callback for this observed object
    mutating func _setUpdateCallback(_ callback: @escaping @Sendable @MainActor () -> Void)
}

@MainActor
extension ObservedObject: _ObservedObjectProperty {
    public mutating func _setUpdateCallback(_ callback: @escaping @Sendable @MainActor () -> Void) {
        setUpdateCallback(callback)
    }
}
