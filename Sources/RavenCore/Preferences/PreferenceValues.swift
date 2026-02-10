import Foundation

/// A snapshot of reduced preference values for a rendered subtree.
public struct PreferenceValues: Sendable {
    @MainActor
    package let _boxes: [ObjectIdentifier: _AnyPreferenceBox]

    @MainActor
    package init(_boxes: [ObjectIdentifier: _AnyPreferenceBox] = [:]) {
        self._boxes = _boxes
    }

    /// Read the reduced value for a preference key.
    @MainActor
    public subscript<K: PreferenceKey>(_ key: K.Type) -> K.Value {
        if let box = _boxes[ObjectIdentifier(key)] as? _PreferenceBox<K> {
            return box.reducedValue()
        }
        return K.defaultValue
    }
}
