import Foundation

/// A convenience app wrapper for simple single-view apps.
///
/// `RavenApp` provides a simpler way to create basic apps without needing to define
/// a custom `App` type. It automatically wraps your root view in a `WindowGroup`.
///
/// Example:
/// ```swift
/// @main
/// struct MyApp {
///     static func main() async {
///         await RavenApp {
///             ContentView()
///         }.run()
///     }
/// }
/// ```
///
/// For more complex apps with multiple scenes or custom configuration,
/// implement the `App` protocol directly instead.
///
/// Note: The `run()` method is provided by RavenRuntime module.
public struct RavenApp<Content: View>: App {
    private let _body: WindowGroup<Content>

    /// Required by App protocol but should not be used directly.
    public init() {
        fatalError("RavenApp should be initialized with init(rootView:) or init(@ViewBuilder rootView:)")
    }

    /// Creates a simple app with the given root view.
    ///
    /// - Parameter rootView: A closure that creates the root view of the app.
    @MainActor public init(@ViewBuilder rootView: @MainActor @Sendable @escaping () -> Content) {
        self._body = WindowGroup(content: rootView)
    }

    /// Creates a simple app with the given root view.
    ///
    /// This initializer is provided for backward compatibility with existing examples.
    ///
    /// - Parameter rootView: The root view of the app.
    @MainActor public init(rootView: Content) {
        // Create a closure that returns the root view
        let closure: @MainActor @Sendable () -> Content = { rootView }
        self._body = WindowGroup(content: closure)
    }

    /// The scene for this app, containing a single window group.
    @MainActor public var body: WindowGroup<Content> {
        _body
    }
}
