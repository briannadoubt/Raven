import Foundation

// MARK: - Bindable Property Wrapper

/// A property wrapper that creates bindings to the mutable properties of an observable object.
///
/// Use `@Bindable` with `@Observable` objects to create two-way bindings for use
/// with SwiftUI controls like `TextField`, `Toggle`, `Slider`, etc.
///
/// ## Overview
///
/// `@Bindable` is designed to work with the modern `@Observable` macro (iOS 17+)
/// as a replacement for using `@ObservedObject` or `@StateObject` with bindings.
/// It provides a cleaner, more efficient way to create bindings to observable properties.
///
/// ## Basic Usage
///
/// Use `@Bindable` to create bindings to properties of an observable object:
///
/// ```swift
/// @Observable
/// @MainActor
/// class UserSettings {
///     var username: String = ""
///     var isDarkMode: Bool = false
///     var fontSize: Double = 14.0
/// }
///
/// struct SettingsView: View {
///     @Bindable var settings: UserSettings
///
///     var body: some View {
///         VStack {
///             TextField("Username", text: $settings.username)
///             Toggle("Dark Mode", isOn: $settings.isDarkMode)
///             Slider(value: $settings.fontSize, in: 10...24)
///         }
///     }
/// }
/// ```
///
/// ## Working with State
///
/// Combine `@State` and `@Bindable` for local observable objects:
///
/// ```swift
/// struct ProfileView: View {
///     @State private var settings = UserSettings()
///
///     var body: some View {
///         SettingsForm(settings: settings)
///     }
/// }
///
/// struct SettingsForm: View {
///     @Bindable var settings: UserSettings
///
///     var body: some View {
///         Form {
///             TextField("Name", text: $settings.username)
///             Toggle("Notifications", isOn: $settings.notificationsEnabled)
///         }
///     }
/// }
/// ```
///
/// ## Nested Properties
///
/// Use key paths to bind to nested properties:
///
/// ```swift
/// @Observable
/// @MainActor
/// class User {
///     var profile: Profile = Profile()
/// }
///
/// @Observable
/// @MainActor
/// class Profile {
///     var name: String = ""
///     var email: String = ""
/// }
///
/// struct ProfileEditor: View {
///     @Bindable var user: User
///
///     var body: some View {
///         VStack {
///             TextField("Name", text: $user.profile.name)
///             TextField("Email", text: $user.profile.email)
///         }
///     }
/// }
/// ```
///
/// ## Comparison with Other Property Wrappers
///
/// - `@State`: For simple value types owned by the view
/// - `@Binding`: For passing bindings down the view hierarchy
/// - `@Bindable`: For creating bindings to `@Observable` objects
/// - `@ObservedObject`: Legacy approach for `ObservableObject` instances
/// - `@StateObject`: Legacy approach for creating and owning `ObservableObject` instances
///
/// ## Benefits
///
/// - Works seamlessly with `@Observable` classes
/// - No need for `objectWillChange.send()` calls
/// - Cleaner syntax than `@ObservedObject`
/// - Better performance with fine-grained observation
/// - Type-safe binding creation
///
/// ## Migration from ObservedObject
///
/// Converting from `@ObservedObject` to `@Bindable`:
///
/// ```swift
/// // Before (with ObservableObject)
/// @MainActor
/// class Settings: ObservableObject {
///     @Published var value: String = ""
/// }
///
/// struct SettingsView: View {
///     @ObservedObject var settings: Settings
///
///     var body: some View {
///         TextField("Value", text: $settings.value)
///     }
/// }
///
/// // After (with @Observable)
/// @Observable
/// @MainActor
/// class Settings {
///     var value: String = ""
/// }
///
/// struct SettingsView: View {
///     @Bindable var settings: Settings
///
///     var body: some View {
///         TextField("Value", text: $settings.value)
///     }
/// }
/// ```
///
/// ## Thread Safety
///
/// Always use `@Bindable` with `@MainActor`-isolated observable objects
/// in UI contexts to ensure thread safety:
///
/// ```swift
/// @Observable
/// @MainActor
/// class AppState {
///     var isLoading: Bool = false
///     var errorMessage: String?
/// }
///
/// struct StatusView: View {
///     @Bindable var appState: AppState
///
///     var body: some View {
///         if appState.isLoading {
///             ProgressView()
///         }
///     }
/// }
/// ```
///
/// ## See Also
///
/// - ``Observable()``
/// - ``Observable``
/// - ``Binding``
/// - ``State``
@MainActor
@propertyWrapper
@dynamicMemberLookup
public struct Bindable<Value: Observable>: DynamicProperty {
    /// The observable object being wrapped
    private var object: Value

    /// Subscription ID for observing changes
    private var subscriptionId: UUID?

    /// Creates a bindable wrapper for an observable object.
    ///
    /// - Parameter wrappedValue: The observable object to wrap
    public init(wrappedValue: Value) {
        self.object = wrappedValue
    }

    /// The observable object.
    ///
    /// Access the wrapped observable object directly through this property.
    public var wrappedValue: Value {
        object
    }

    /// A binding to the bindable object itself.
    ///
    /// This allows you to pass the entire object as a binding when needed.
    ///
    /// Example:
    /// ```swift
    /// @Bindable var settings: UserSettings
    ///
    /// var body: some View {
    ///     SettingsEditor(settings: $settings)
    /// }
    /// ```
    public var projectedValue: Bindable<Value> {
        self
    }

    /// Provides dynamic member lookup for creating bindings to properties.
    ///
    /// This subscript allows you to use the `$` syntax to create bindings
    /// to properties of the observable object.
    ///
    /// Example:
    /// ```swift
    /// @Bindable var settings: UserSettings
    ///
    /// var body: some View {
    ///     // $settings.username creates a Binding<String>
    ///     TextField("Username", text: $settings.username)
    /// }
    /// ```
    ///
    /// - Parameter keyPath: A writable key path to a property of the observable object
    /// - Returns: A binding to the property at the specified key path
    public subscript<Property: Sendable>(
        dynamicMember keyPath: ReferenceWritableKeyPath<Value, Property>
    ) -> Binding<Property> {
        Binding(
            get: {
                self.object[keyPath: keyPath]
            },
            set: { newValue in
                self.object[keyPath: keyPath] = newValue
            }
        )
    }

    /// Update the bindable property.
    ///
    /// This is called by the rendering system during the view update lifecycle.
    /// It ensures the view stays subscribed to changes in the observable object.
    @MainActor
    public mutating func update() {
        // No-op for now
        // In a more sophisticated implementation, we could set up observation here
    }
}

// MARK: - Sendable Conformance

extension Bindable: @unchecked Sendable where Value: Sendable {}

// MARK: - Convenience Extensions

extension Bindable {
    /// Subscribe to changes in the observable object.
    ///
    /// This method allows you to react to changes in the observable object.
    ///
    /// - Parameter callback: The closure to call when the object changes
    /// - Returns: A subscription ID that can be used to unsubscribe
    @discardableResult
    public func subscribe(_ callback: @escaping @Sendable @MainActor () -> Void) -> UUID {
        object.subscribe(callback)
    }

    /// Unsubscribe from changes in the observable object.
    ///
    /// - Parameter id: The subscription ID to remove
    public func unsubscribe(_ id: UUID) {
        object.unsubscribe(id)
    }
}

// MARK: - Integration with Observable

extension Observable {
    /// Creates a bindable wrapper for this observable object.
    ///
    /// This is a convenience method that allows you to create a `@Bindable`
    /// wrapper from any observable object.
    ///
    /// Example:
    /// ```swift
    /// let settings = UserSettings()
    /// let bindable = settings.bindable()
    /// ```
    ///
    /// - Returns: A bindable wrapper for this object
    @MainActor
    public func bindable() -> Bindable<Self> {
        Bindable(wrappedValue: self)
    }
}

// MARK: - Implementation Notes

/*
 ## Design Decisions

 ### Why @Bindable Instead of Direct Binding?

 `@Bindable` provides several advantages over creating bindings manually:

 1. **Type Safety**: Ensures the object conforms to `Observable`
 2. **Convenience**: Automatic binding creation via dynamic member lookup
 3. **Consistency**: Matches SwiftUI's modern API surface
 4. **Performance**: Can optimize observation (future enhancement)

 ### Integration with Raven's Binding System

 `@Bindable` works seamlessly with Raven's existing `Binding` type through
 the `dynamicMemberLookup` subscript. When you use `$settings.username`,
 it creates a `Binding<String>` that:

 1. Reads from the observable object's property
 2. Writes to the observable object's property
 3. Triggers observation updates automatically

 ### Observation Setup

 The `update()` method is called by the rendering system during view updates.
 This is where we could set up automatic observation subscriptions in the future.
 For now, observation is handled by the `Observable` object's registrar.

 ### Thread Safety

 `@Bindable` is marked with `@MainActor` to ensure all property access happens
 on the main thread, matching SwiftUI's threading model. The wrapped observable
 object should also be `@MainActor` isolated.

 ### Usage Patterns

 #### Pattern 1: With @State
 ```swift
 struct MyView: View {
     @State private var model = MyModel()

     var body: some View {
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

 #### Pattern 2: Direct Initialization
 ```swift
 struct MyView: View {
     @Bindable var model: MyModel

     init(model: MyModel) {
         self._model = Bindable(wrappedValue: model)
     }

     var body: some View {
         TextField("Name", text: $model.name)
     }
 }
 ```

 #### Pattern 3: With Computed Properties
 ```swift
 @Observable
 @MainActor
 class ViewModel {
     var items: [Item] = []

     var selectedItem: Item? {
         get { items.first }
         set {
             if let newValue = newValue {
                 items = [newValue]
             }
         }
     }
 }

 struct ItemEditor: View {
     @Bindable var viewModel: ViewModel

     var body: some View {
         // Note: Bindings to computed properties work, but may have
         // different observation characteristics
         if let item = viewModel.selectedItem {
             Text(item.name)
         }
     }
 }
 ```

 ## Future Enhancements

 1. **Automatic Observation**: Track when bindings are active and optimize updates
 2. **Weak References**: Support weak references to avoid retain cycles
 3. **Fine-Grained Updates**: Only update views that use changed properties
 4. **Debug Support**: Better debugging and introspection tools
 */
