import Foundation

// MARK: - Environment Modifier

/// A view that applies environment values to its content.
///
/// This view wraps content and provides modified environment values
/// to all descendant views in the hierarchy.
public struct _EnvironmentModifierView<Content: View, Value: Sendable>: View, @unchecked Sendable {
    /// The content view to apply the environment to
    let content: Content

    /// The key path to the environment value to modify
    /// Note: KeyPath is not Sendable in Swift 6, but it's safe to use here
    /// because key paths are immutable and thread-safe
    nonisolated(unsafe) let keyPath: WritableKeyPath<EnvironmentValues, Value>

    /// The value to set in the environment
    let value: Value

    /// Environment modifier views don't have a body - they're handled specially by the rendering system
    public typealias Body = Never

    /// Creates an environment modifier view.
    ///
    /// - Parameters:
    ///   - content: The content view.
    ///   - keyPath: The key path to the environment value.
    ///   - value: The value to set.
    init(content: Content, keyPath: WritableKeyPath<EnvironmentValues, Value>, value: Value) {
        self.content = content
        self.keyPath = keyPath
        self.value = value
    }

    /// Gets the modified environment values.
    ///
    /// This method takes the current environment values and returns a new
    /// set with the modified value applied.
    ///
    /// - Parameter environmentValues: The current environment values.
    /// - Returns: The modified environment values.
    @MainActor
    func modifiedEnvironment(_ environmentValues: EnvironmentValues) -> EnvironmentValues {
        var modified = environmentValues
        modified[keyPath: keyPath] = value
        return modified
    }
}

// MARK: - View Extension

extension View {
    /// Sets an environment value for this view and its descendants.
    ///
    /// Use this modifier to set values in the environment that can be read
    /// by child views using the `@Environment` property wrapper.
    ///
    /// Example:
    /// ```swift
    /// VStack {
    ///     Text("Hello")  // Uses .dark color scheme
    ///     Text("World")  // Uses .dark color scheme
    /// }
    /// .environment(\.colorScheme, .dark)
    /// ```
    ///
    /// Environment values propagate down the view hierarchy. Child views
    /// can override values for their own descendants:
    /// ```swift
    /// VStack {
    ///     Text("Dark")  // Uses .dark
    ///     Text("Light")
    ///         .environment(\.colorScheme, .light)  // Overrides to .light
    /// }
    /// .environment(\.colorScheme, .dark)
    /// ```
    ///
    /// - Parameters:
    ///   - keyPath: A writable key path to the environment value to set.
    ///   - value: The value to set in the environment.
    /// - Returns: A view with the environment value set.
    @MainActor
    public func environment<V: Sendable>(
        _ keyPath: WritableKeyPath<EnvironmentValues, V>,
        _ value: V
    ) -> _EnvironmentModifierView<Self, V> {
        _EnvironmentModifierView(content: self, keyPath: keyPath, value: value)
    }
}
