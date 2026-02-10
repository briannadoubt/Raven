/// Type-erased snapshot of a view for equality comparison.
///
/// When a view conforms to `Equatable`, `AnyViewSnapshot` performs a real
/// equality check to determine whether re-evaluation is needed. For
/// non-`Equatable` views, comparison always returns `false` (meaning the
/// fiber is always re-evaluated).
@MainActor
public struct AnyViewSnapshot: @unchecked Sendable {
    /// The type-erased equality check.
    /// Returns `true` if the two underlying views are equal.
    private let _isEqual: @Sendable @MainActor (AnyViewSnapshot) -> Bool

    /// The boxed view value.
    private let _value: Any

    /// The view type name, for debugging.
    public let viewTypeName: String

    /// Whether this snapshot uses real equality (Equatable view).
    public let hasRealEquality: Bool

    /// Create a snapshot from an `Equatable & View`.
    public init<V: View & Equatable>(equatableView: V) {
        self.viewTypeName = String(describing: V.self)
        self._value = equatableView
        self.hasRealEquality = true
        self._isEqual = { other in
            guard let otherValue = other._value as? V else { return false }
            return equatableView == otherValue
        }
    }

    /// Create a snapshot from a non-`Equatable` `View`.
    /// Equality always returns `false` (the fiber is always dirty).
    public init<V: View>(view: V) {
        self.viewTypeName = String(describing: V.self)
        self._value = view
        self.hasRealEquality = false
        self._isEqual = { _ in false }
    }

    /// Check if another snapshot is equal to this one.
    public func isEqual(to other: AnyViewSnapshot) -> Bool {
        guard viewTypeName == other.viewTypeName else { return false }
        return _isEqual(other)
    }
}
