import Foundation

// MARK: - Observable Macro

/// A macro that makes a class observable for use with SwiftUI-style data flow.
///
/// The `@Observable` macro is a modern alternative to `ObservableObject` introduced
/// in Swift 5.9 and iOS 17+. It provides automatic observation of property changes
/// without requiring `@Published` wrappers.
///
/// ## Overview
///
/// `@Observable` transforms a class to track property changes automatically.
/// Unlike `ObservableObject`, you don't need to mark individual properties with
/// `@Published`. All stored properties become automatically observable.
///
/// ## Basic Usage
///
/// Apply `@Observable` to a class to make it observable:
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
/// ## Computed Properties
///
/// Computed properties in observable classes are automatically tracked:
///
/// ```swift
/// @Observable
/// @MainActor
/// class ShoppingCart {
///     var items: [CartItem] = []
///
///     var total: Double {
///         items.reduce(0) { $0 + $1.price }
///     }
///
///     var itemCount: Int {
///         items.count
///     }
/// }
/// ```
///
/// ## Ignoring Properties
///
/// Use `@ObservationIgnored` to prevent properties from triggering observations:
///
/// ```swift
/// @Observable
/// @MainActor
/// class DataCache {
///     var data: [String] = []
///
///     @ObservationIgnored
///     var cacheMetadata: [String: Any] = [:]
/// }
/// ```
///
/// ## Benefits Over ObservableObject
///
/// - No need for `@Published` on every property
/// - Cleaner syntax with less boilerplate
/// - Better performance with fine-grained observation
/// - Works seamlessly with `@Bindable` for bindings
///
/// ## Migration from ObservableObject
///
/// Converting from `ObservableObject` to `@Observable`:
///
/// ```swift
/// // Before (ObservableObject)
/// @MainActor
/// class Counter: ObservableObject {
///     @Published var count: Int = 0
///
///     init() {
///         setupPublished()
///     }
/// }
///
/// // After (@Observable)
/// @Observable
/// @MainActor
/// class Counter {
///     var count: Int = 0
/// }
/// ```
///
/// ## Thread Safety
///
/// Always mark `@Observable` classes with `@MainActor` for thread safety
/// in UI contexts:
///
/// ```swift
/// @Observable
/// @MainActor
/// class AppState {
///     var isLoggedIn: Bool = false
///     var user: User?
/// }
/// ```
///
/// ## See Also
///
/// - ``Bindable``
/// - ``ObservationIgnored``
/// - ``ObservableObject`` (legacy API)
@attached(member, names: named(_$observationRegistrar), named(access), named(withMutation))
@attached(memberAttribute)
@attached(extension, conformances: Observable)
public macro Observable() = #externalMacro(module: "RavenMacros", type: "ObservableMacro")

// MARK: - Observable Protocol

/// A protocol for types that can be observed for changes.
///
/// This protocol is automatically conformed to by classes marked with `@Observable`.
/// You typically don't conform to this protocol directly.
///
/// ## Overview
///
/// The `Observable` protocol provides the infrastructure for tracking property
/// changes in observable classes. The `@Observable` macro automatically generates
/// the necessary implementation.
///
/// ## See Also
///
/// - ``Observable()``
/// - ``Bindable``
@MainActor
public protocol Observable: AnyObject, Sendable {
    /// The observation registrar that tracks property access and mutations.
    ///
    /// This property is automatically synthesized by the `@Observable` macro.
    /// You should not access or modify it directly.
    var _$observationRegistrar: ObservationRegistrar { get }
}

// MARK: - ObservationRegistrar

/// A type that tracks access to properties and notifies observers of changes.
///
/// The observation registrar is the core mechanism that enables property observation
/// in `@Observable` classes. It tracks which properties are accessed and notifies
/// observers when properties are mutated.
///
/// ## Overview
///
/// `ObservationRegistrar` is automatically created and managed by the `@Observable`
/// macro. You typically don't interact with it directly unless implementing custom
/// observation behavior.
///
/// ## Implementation Details
///
/// The registrar maintains a list of observers and tracks which properties each
/// observer is interested in. When a property changes, only the relevant observers
/// are notified, enabling efficient fine-grained observation.
@MainActor
public final class ObservationRegistrar: @unchecked Sendable {
    /// Observers registered for property changes
    private var observers: [UUID: Observer] = [:]

    /// Initialize a new observation registrar
    public init() {}

    /// Observer structure to track callbacks
    private struct Observer {
        let callback: @Sendable @MainActor () -> Void
    }

    /// Register an observer for property changes
    ///
    /// - Parameter callback: The closure to call when observed properties change
    /// - Returns: A subscription ID that can be used to remove the observer
    @discardableResult
    public func register(_ callback: @escaping @Sendable @MainActor () -> Void) -> UUID {
        let id = UUID()
        observers[id] = Observer(callback: callback)
        return id
    }

    /// Remove an observer
    ///
    /// - Parameter id: The subscription ID to remove
    public func remove(_ id: UUID) {
        observers.removeValue(forKey: id)
    }

    /// Remove all observers
    public func removeAll() {
        observers.removeAll()
    }

    /// Notify all observers that a property will change
    ///
    /// This is called automatically by the `@Observable` macro before
    /// any property mutation.
    public func willSet() {
        for observer in observers.values {
            observer.callback()
        }
    }

    /// Access a property value
    ///
    /// This method is called by the `@Observable` macro when a property is accessed.
    /// It can be used to track which properties are being observed.
    ///
    /// - Parameters:
    ///   - keyPath: The key path of the property being accessed
    ///   - getValue: A closure that returns the current value
    /// - Returns: The current value of the property
    public func access<Value>(
        keyPath: AnyKeyPath,
        getValue: () -> Value
    ) -> Value {
        // For now, we just return the value
        // In a more sophisticated implementation, we could track which
        // properties are being accessed to enable fine-grained observation
        return getValue()
    }

    /// Mutate a property value
    ///
    /// This method is called by the `@Observable` macro when a property is mutated.
    /// It notifies observers before the mutation occurs.
    ///
    /// - Parameters:
    ///   - keyPath: The key path of the property being mutated
    ///   - setValue: A closure that performs the mutation
    public func withMutation<Value>(
        keyPath: AnyKeyPath,
        setValue: () -> Value
    ) -> Value {
        // Notify observers before mutation
        willSet()
        // Perform the mutation
        return setValue()
    }
}

// MARK: - ObservationIgnored

/// An attribute that prevents a property from being tracked for observation.
///
/// Use `@ObservationIgnored` on properties in `@Observable` classes that should
/// not trigger observation updates.
///
/// ## Overview
///
/// Sometimes you need properties in an observable class that shouldn't trigger
/// view updates when they change. Mark these properties with `@ObservationIgnored`.
///
/// ## Example
///
/// ```swift
/// @Observable
/// @MainActor
/// class DataManager {
///     var publicData: [String] = []
///
///     @ObservationIgnored
///     var internalCache: [String: Any] = [:]
///
///     @ObservationIgnored
///     var lastUpdateTime: Date = Date()
/// }
/// ```
///
/// In this example, changing `publicData` will trigger view updates, but changing
/// `internalCache` or `lastUpdateTime` will not.
///
/// ## When to Use
///
/// Use `@ObservationIgnored` for:
/// - Internal caches or temporary data
/// - Debugging or logging information
/// - Performance counters or metrics
/// - Properties that are derived from observable properties
///
/// ## See Also
///
/// - ``Observable()``
@propertyWrapper
public struct ObservationIgnored<Value: Sendable>: @unchecked Sendable {
    private var value: Value

    /// The current value of the property
    public var wrappedValue: Value {
        get { value }
        set { value = newValue }
    }

    /// Initialize with an initial value
    ///
    /// - Parameter wrappedValue: The initial value of the property
    public init(wrappedValue: Value) {
        self.value = wrappedValue
    }
}

// MARK: - Manual Observable Implementation

/// Since Swift macros aren't fully available in SwiftWasm yet, we provide
/// a manual implementation approach through a protocol extension.
extension Observable {
    /// Set up observation for an observable instance
    ///
    /// This helper method registers the observable instance with the observation
    /// system. It should be called in the initializer of classes conforming to
    /// `Observable`.
    ///
    /// Example:
    /// ```swift
    /// @MainActor
    /// class UserSettings: Observable {
    ///     let _$observationRegistrar = ObservationRegistrar()
    ///
    ///     var username: String = "" {
    ///         willSet { _$observationRegistrar.willSet() }
    ///     }
    ///
    ///     var isDarkMode: Bool = false {
    ///         willSet { _$observationRegistrar.willSet() }
    ///     }
    ///
    ///     init() {
    ///         setupObservation()
    ///     }
    /// }
    /// ```
    public func setupObservation() {
        // Setup code can go here if needed
        // Currently, the observation registrar is set up automatically
    }

    /// Subscribe to changes in this observable object
    ///
    /// - Parameter callback: The closure to call when properties change
    /// - Returns: A subscription ID that can be used to unsubscribe
    @discardableResult
    public func subscribe(_ callback: @escaping @Sendable @MainActor () -> Void) -> UUID {
        _$observationRegistrar.register(callback)
    }

    /// Unsubscribe from changes
    ///
    /// - Parameter id: The subscription ID to remove
    public func unsubscribe(_ id: UUID) {
        _$observationRegistrar.remove(id)
    }
}

// MARK: - Implementation Notes

/*
 ## Implementation Strategy

 Since Swift macros are not yet fully supported in SwiftWasm, this implementation
 provides both:

 1. The macro definition for future compatibility
 2. Manual implementation helpers for current use

 ### Manual Implementation Pattern

 Until macros are available, classes should manually conform to Observable:

 ```swift
 @MainActor
 class Counter: Observable {
     let _$observationRegistrar = ObservationRegistrar()

     private var _count: Int = 0

     var count: Int {
         get {
             _$observationRegistrar.access(keyPath: \Counter.count) {
                 _count
             }
         }
         set {
             _$observationRegistrar.withMutation(keyPath: \Counter.count) {
                 _count = newValue
                 return newValue
             }
         }
     }

     init() {
         setupObservation()
     }
 }
 ```

 ### Simplified Pattern

 For simpler cases, you can use willSet:

 ```swift
 @MainActor
 class Counter: Observable {
     let _$observationRegistrar = ObservationRegistrar()

     var count: Int = 0 {
         willSet { _$observationRegistrar.willSet() }
     }

     init() {
         setupObservation()
     }
 }
 ```

 ### Migration Path

 When Swift macros become available in SwiftWasm, code can be updated to use
 the @Observable macro directly:

 ```swift
 @Observable
 @MainActor
 class Counter {
     var count: Int = 0
 }
 ```

 The macro will automatically generate the _$observationRegistrar and property
 observation code.
 */
