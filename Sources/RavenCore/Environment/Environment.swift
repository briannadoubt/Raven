import Foundation

/// A property wrapper that reads a value from the environment.
///
/// Use the `@Environment` property wrapper to read values that have been
/// set in the environment using the `.environment()` modifier. The wrapper
/// takes a key path to a property on `EnvironmentValues`.
///
/// Example:
/// ```swift
/// struct MyView: View {
///     @Environment(\.colorScheme) var colorScheme
///     @Environment(\.font) var font
///
///     var body: some View {
///         Text(colorScheme == .dark ? "Dark" : "Light")
///     }
/// }
/// ```
///
/// Environment values propagate down the view hierarchy, so child views
/// inherit values from their parent views unless overridden.
@propertyWrapper
public struct Environment<Value: Sendable>: @unchecked Sendable {
    /// The key path to the environment value
    private let keyPath: KeyPath<EnvironmentValues, Value>

    /// The cached environment values (set by the rendering system)
    private var environmentValues: EnvironmentValues?

    /// The current value read from the environment.
    ///
    /// This property provides read-only access to the environment value.
    /// The value is resolved using the key path on the current environment values.
    @MainActor
    public var wrappedValue: Value {
        guard let environmentValues = environmentValues else {
            // No injected values: fall back to dynamically-scoped environment.
            return EnvironmentValues._current[keyPath: keyPath]
        }
        return environmentValues[keyPath: keyPath]
    }

    /// Creates an environment property that reads the value at the specified key path.
    ///
    /// - Parameter keyPath: A key path to a property on `EnvironmentValues`.
    public init(_ keyPath: KeyPath<EnvironmentValues, Value>) {
        self.keyPath = keyPath
        self.environmentValues = nil
    }

    /// Updates the cached environment values.
    ///
    /// This method is called internally by the rendering system to inject
    /// environment values into views.
    ///
    /// - Parameter environmentValues: The environment values to cache.
    internal mutating func update(environmentValues: EnvironmentValues) {
        self.environmentValues = environmentValues
    }
}

// MARK: - EnvironmentReader View

/// A view that reads environment values and passes them to a content closure.
///
/// This is an internal utility for accessing environment values in the rendering system.
/// It's similar to SwiftUI's approach but adapted for Raven's architecture.
internal struct EnvironmentReader<Content: View>: View {
    /// The closure that builds content based on environment values
    private let content: @Sendable (EnvironmentValues) -> Content

    init(@ViewBuilder content: @escaping @Sendable (EnvironmentValues) -> Content) {
        self.content = content
    }

    var body: Never {
        fatalError("EnvironmentReader.body should never be called")
    }

    /// Builds the content view using the provided environment values.
    @MainActor
    func build(with environmentValues: EnvironmentValues) -> Content {
        content(environmentValues)
    }
}
