import Foundation

/// A type that represents the structure and behavior of an app.
///
/// Create an app by declaring a structure that conforms to the `App` protocol.
/// Implement the required `body` property to define the app's scenes:
///
/// ```swift
/// @main
/// struct MyApp: App {
///     var body: some Scene {
///         WindowGroup {
///             ContentView()
///         }
///     }
/// }
/// ```
///
/// The system calls your app's `body` property to obtain the scenes that define
/// the app's user interface. Each scene contains a root view and has a lifecycle
/// managed by the system.
@MainActor public protocol App: Sendable {
    /// The type of scene representing the body of this app.
    associatedtype Body: Scene

    /// The content and behavior of this app.
    ///
    /// Define your app's scenes in the body property:
    /// ```swift
    /// var body: some Scene {
    ///     WindowGroup {
    ///         ContentView()
    ///     }
    /// }
    /// ```
    @SceneBuilder @MainActor var body: Self.Body { get }

    /// Creates an instance of the app.
    ///
    /// The system calls this initializer to create an instance of your app when
    /// the app launches.
    init()
}

// MARK: - App Lifecycle Modifiers

extension App {
    /// Adds an action to perform when the given value changes.
    ///
    /// Use this modifier to trigger actions in response to state changes at the app level:
    ///
    /// ```swift
    /// @main
    /// struct MyApp: App {
    ///     @State private var userData: UserData = .default
    ///
    ///     var body: some Scene {
    ///         WindowGroup {
    ///             ContentView()
    ///         }
    ///         .onChange(of: userData) { newValue in
    ///             saveUserData(newValue)
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - value: The value to monitor for changes.
    ///   - action: The action to perform when the value changes.
    /// - Returns: A modified app that triggers the action when the value changes.
    public func onChange<V: Equatable & Sendable>(of value: V, perform action: @escaping @Sendable (V) -> Void) -> some App {
        ModifiedApp(base: self, modifier: OnChangeAppModifier(value: value, action: action))
    }

    /// Adds an action to perform when the app receives a URL.
    ///
    /// Use this modifier to handle URL schemes and deep links:
    ///
    /// ```swift
    /// @main
    /// struct MyApp: App {
    ///     var body: some Scene {
    ///         WindowGroup {
    ///             ContentView()
    ///         }
    ///         .onOpenURL { url in
    ///             handleDeepLink(url)
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// - Parameter perform: The action to perform when a URL is received.
    /// - Returns: A modified app that handles URL events.
    public func onOpenURL(perform: @escaping @Sendable (URL) -> Void) -> some App {
        ModifiedApp(base: self, modifier: OnOpenURLAppModifier(action: perform))
    }
}

// MARK: - App Modifiers

/// A modifier applied to an app.
internal protocol AppModifier: Sendable {
    func apply<A: App>(to app: A)
}

/// An app that has been modified.
internal struct ModifiedApp<Base: App, Modifier: AppModifier>: App {
    let base: Base
    let modifier: Modifier

    init(base: Base, modifier: Modifier) {
        self.base = base
        self.modifier = modifier
    }

    // Required by App protocol
    init() {
        fatalError("ModifiedApp should never be initialized directly")
    }

    @MainActor var body: Base.Body {
        base.body
    }
}

/// Modifier for onChange behavior.
internal struct OnChangeAppModifier<V: Equatable & Sendable>: AppModifier {
    let value: V
    let action: @Sendable (V) -> Void

    func apply<A: App>(to app: A) {
        // Implementation would track value changes and call action
        // This is a placeholder for the infrastructure
    }
}

/// Modifier for onOpenURL behavior.
internal struct OnOpenURLAppModifier: AppModifier {
    let action: @Sendable (URL) -> Void

    func apply<A: App>(to app: A) {
        // Implementation would register URL handler
        // This is a placeholder for the infrastructure
    }
}
