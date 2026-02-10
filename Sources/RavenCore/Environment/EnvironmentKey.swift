import Foundation

/// A protocol that defines a key for accessing values in the environment.
///
/// Create custom environment keys by conforming to this protocol and
/// implementing the `defaultValue` property. The key is then used with
/// `EnvironmentValues` to store and retrieve typed values.
///
/// Example:
/// ```swift
/// struct MyCustomKey: EnvironmentKey {
///     static let defaultValue: String = "default"
/// }
///
/// extension EnvironmentValues {
///     var myCustomValue: String {
///         get { self[MyCustomKey.self] }
///         set { self[MyCustomKey.self] = newValue }
///     }
/// }
/// ```
public protocol EnvironmentKey: Sendable {
    /// The type of value stored by this key.
    associatedtype Value: Sendable

    /// The default value for this environment key.
    ///
    /// This value is returned when the key has not been set in the environment.
    static var defaultValue: Value { get }
}

// MARK: - EnvironmentValues Extension

extension EnvironmentValues {
    /// Accesses environment values using an `EnvironmentKey` type.
    ///
    /// This subscript provides type-safe access to environment values.
    /// If a value hasn't been set for the given key, the key's default value is returned.
    ///
    /// - Parameter key: The type of the environment key to access.
    /// - Returns: The value associated with the key, or the key's default value.
    public subscript<Key: EnvironmentKey>(key: Key.Type) -> Key.Value {
        get {
            let keyName = String(describing: key)
            if let value = storage[keyName] as? Key.Value {
                return value
            }
            return Key.defaultValue
        }
        set {
            let keyName = String(describing: key)
            storage[keyName] = newValue
        }
    }
}
