import Foundation

/// A key that defines a value type to propagate from child views to ancestors.
///
/// Raven's preferences are modeled after SwiftUI's preference system: child views
/// can emit values for a `PreferenceKey`, and ancestors can observe or read the
/// reduced result.
///
/// Preferences are collected during coordinator-based rendering. They do not
/// participate in `AnyView.render()` (non-coordinator) paths.
public protocol PreferenceKey {
    associatedtype Value: Sendable

    /// The default value when no descendant provides a preference for this key.
    @MainActor static var defaultValue: Value { get }

    /// Combine multiple preference values into a single value.
    ///
    /// Raven calls `reduce` in view-tree order as emitted values propagate from
    /// descendants towards the root.
    @MainActor static func reduce(value: inout Value, nextValue: () -> Value)
}

// MARK: - Internal Plumbing (package)

/// Type-erased box for storing a preference value with key-specific merge logic.
@MainActor
package class _AnyPreferenceBox: @unchecked Sendable {
    package func clone() -> _AnyPreferenceBox { fatalError("override") }
    package func merge(from other: _AnyPreferenceBox) { fatalError("override") }
}

@MainActor
package final class _PreferenceBox<K: PreferenceKey>: _AnyPreferenceBox, @unchecked Sendable {
    // Store the raw emitted values in order. We reduce on demand so that
    // reductions reflect the same "flattened" view-tree ordering as SwiftUI.
    package var values: [K.Value]

    private var cacheIsValid: Bool = false
    private var cachedReduced: K.Value? = nil

    package init(values: [K.Value]) {
        self.values = values
    }

    package override func clone() -> _AnyPreferenceBox {
        _PreferenceBox<K>(values: values)
    }

    package override func merge(from other: _AnyPreferenceBox) {
        guard let other = other as? _PreferenceBox<K> else { return }
        values.append(contentsOf: other.values)
        cacheIsValid = false
        cachedReduced = nil
    }

    package func append(_ value: K.Value) {
        values.append(value)
        cacheIsValid = false
        cachedReduced = nil
    }

    package func override(with value: K.Value) {
        values = [value]
        cacheIsValid = false
        cachedReduced = nil
    }

    package func reducedValue() -> K.Value {
        if cacheIsValid, let cachedReduced {
            return cachedReduced
        }

        var reduced = K.defaultValue
        for v in values {
            K.reduce(value: &reduced, nextValue: { v })
        }
        cachedReduced = reduced
        cacheIsValid = true
        return reduced
    }
}

@MainActor
package final class _PreferenceCollector: @unchecked Sendable {
    private var boxes: [ObjectIdentifier: _AnyPreferenceBox] = [:]

    package init() {}

    package func snapshot() -> PreferenceValues {
        // Detach from collector mutation by cloning all boxes.
        var cloned: [ObjectIdentifier: _AnyPreferenceBox] = [:]
        cloned.reserveCapacity(boxes.count)
        for (k, v) in boxes {
            cloned[k] = v.clone()
        }
        return PreferenceValues(_boxes: cloned)
    }

    package func merge(_ values: PreferenceValues) {
        for (key, otherBox) in values._boxes {
            if let existing = boxes[key] {
                existing.merge(from: otherBox)
            } else {
                boxes[key] = otherBox.clone()
            }
        }
    }

    package func emit<K: PreferenceKey>(_ key: K.Type, value newValue: K.Value) {
        let id = ObjectIdentifier(key)
        if let existing = boxes[id] as? _PreferenceBox<K> {
            existing.append(newValue)
            return
        }

        boxes[id] = _PreferenceBox<K>(values: [newValue])
    }

    package func override<K: PreferenceKey>(_ key: K.Type, value newValue: K.Value) {
        let id = ObjectIdentifier(key)
        if let existing = boxes[id] as? _PreferenceBox<K> {
            existing.override(with: newValue)
        } else {
            boxes[id] = _PreferenceBox<K>(values: [newValue])
        }
    }
}

/// Package-visible bridge that the runtime uses to connect coordinator rendering
/// to preference collection.
@MainActor
package enum _PreferenceContext {
    package static var currentCollector: _PreferenceCollector? = nil

    package static func emit<K: PreferenceKey>(_ key: K.Type, value: K.Value) {
        guard let collector = currentCollector else { return }
        collector.emit(key, value: value)
    }

    package static func override<K: PreferenceKey>(_ key: K.Type, value: K.Value) {
        guard let collector = currentCollector else { return }
        collector.override(key, value: value)
    }
}
