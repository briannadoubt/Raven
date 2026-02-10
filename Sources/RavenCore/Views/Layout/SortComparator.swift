import Foundation

/// Internal wrapper to make KeyPath Sendable-compatible
/// KeyPaths are immutable and thread-safe, so this is safe
private struct UnsafeSendableKeyPath<Root, Value>: @unchecked Sendable {
    let keyPath: KeyPath<Root, Value>

    init(_ keyPath: KeyPath<Root, Value>) {
        self.keyPath = keyPath
    }
}

/// The order in which to sort items.
///
/// `SortOrder` specifies the direction of sorting operations, either ascending
/// (smallest to largest) or descending (largest to smallest).
public enum SortOrder: Sendable, Hashable, Codable {
    /// Sort in ascending order (smallest to largest).
    case forward

    /// Sort in descending order (largest to smallest).
    case reverse

    /// Returns the opposite sort order.
    public var reversed: SortOrder {
        switch self {
        case .forward: return .reverse
        case .reverse: return .forward
        }
    }
}

/// A comparator that compares values using a key path.
///
/// `KeyPathComparator` provides a type-safe way to compare values by extracting
/// a comparable property using a key path. It's the primary comparator type used
/// by Table columns for sorting.
///
/// Example:
/// ```swift
/// struct Person: Sendable {
///     let name: String
///     let age: Int
/// }
///
/// let nameComparator = KeyPathComparator(\Person.name, order: .forward)
/// let sortedPeople = people.sorted(using: nameComparator)
/// ```
public struct KeyPathComparator<Root: Sendable, Value: Comparable & Sendable>: Sendable, Hashable {
    /// The key path used to extract the comparable value
    private let keyPathString: String

    /// The actual key path (stored separately for use)
    private let keyPath: UnsafeSendableKeyPath<Root, Value>

    /// The sort order
    public let order: SortOrder

    /// Creates a key path comparator.
    ///
    /// - Parameters:
    ///   - keyPath: The key path to the property to compare.
    ///   - order: The sort order. Defaults to `.forward`.
    public init(_ keyPath: KeyPath<Root, Value>, order: SortOrder = .forward) {
        self.keyPath = UnsafeSendableKeyPath(keyPath)
        self.keyPathString = "\(keyPath)"
        self.order = order
    }

    /// Compares two values using the key path and sort order.
    ///
    /// - Parameters:
    ///   - lhs: The first value to compare.
    ///   - rhs: The second value to compare.
    /// - Returns: True if lhs should come before rhs in the sort order.
    public func compare(_ lhs: Root, _ rhs: Root) -> Bool {
        let lhsValue = lhs[keyPath: keyPath.keyPath]
        let rhsValue = rhs[keyPath: keyPath.keyPath]

        switch order {
        case .forward:
            return lhsValue < rhsValue
        case .reverse:
            return lhsValue > rhsValue
        }
    }

    /// Returns a new comparator with the order reversed.
    public func reversed() -> KeyPathComparator<Root, Value> {
        KeyPathComparator(keyPath.keyPath, order: order.reversed)
    }

    // MARK: - Hashable

    public static func == (lhs: KeyPathComparator<Root, Value>, rhs: KeyPathComparator<Root, Value>) -> Bool {
        lhs.keyPathString == rhs.keyPathString && lhs.order == rhs.order
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(keyPathString)
        hasher.combine(order)
    }
}

/// A type-erased comparator for sorting collections.
///
/// `SortComparator` wraps any comparator and provides a uniform interface for
/// comparing values. This is used internally by Table to manage multiple column
/// comparators with different value types.
public struct SortComparator<Root: Sendable>: Sendable {
    /// The comparison function
    private let compareFunc: @Sendable (Root, Root) -> Bool

    /// Unique identifier for this comparator
    internal let id: String

    /// The sort order
    public let order: SortOrder

    /// Creates a sort comparator from a key path comparator.
    ///
    /// - Parameter keyPathComparator: The key path comparator to wrap.
    public init<Value: Comparable & Sendable>(_ keyPathComparator: KeyPathComparator<Root, Value>) {
        self.compareFunc = keyPathComparator.compare
        self.id = "\(keyPathComparator)"
        self.order = keyPathComparator.order
    }

    /// Creates a sort comparator with a custom comparison function.
    ///
    /// - Parameters:
    ///   - id: A unique identifier for this comparator.
    ///   - order: The sort order.
    ///   - compare: The comparison function.
    internal init(id: String, order: SortOrder, compare: @escaping @Sendable (Root, Root) -> Bool) {
        self.compareFunc = compare
        self.id = id
        self.order = order
    }

    /// Compares two values.
    ///
    /// - Parameters:
    ///   - lhs: The first value to compare.
    ///   - rhs: The second value to compare.
    /// - Returns: True if lhs should come before rhs in the sort order.
    public func compare(_ lhs: Root, _ rhs: Root) -> Bool {
        compareFunc(lhs, rhs)
    }
}

/// A descriptor for a sort operation, combining a comparator with metadata.
///
/// `SortDescriptor` is used by Table to track which columns are being used for
/// sorting and in what order. It's part of the sortOrder binding that allows
/// external control of table sorting.
public struct SortDescriptor<Root: Sendable>: Sendable, Identifiable, Equatable {
    /// Unique identifier for this sort descriptor
    public let id: String

    /// The sort order
    public let order: SortOrder

    /// The comparator to use for sorting
    internal let comparator: SortComparator<Root>

    /// Creates a sort descriptor from a key path comparator.
    ///
    /// - Parameter keyPathComparator: The key path comparator to use.
    public init<Value: Comparable & Sendable>(_ keyPathComparator: KeyPathComparator<Root, Value>) {
        self.comparator = SortComparator(keyPathComparator)
        self.id = comparator.id
        self.order = keyPathComparator.order
    }

    /// Compares two values using this descriptor's comparator.
    ///
    /// - Parameters:
    ///   - lhs: The first value to compare.
    ///   - rhs: The second value to compare.
    /// - Returns: True if lhs should come before rhs in the sort order.
    public func compare(_ lhs: Root, _ rhs: Root) -> Bool {
        comparator.compare(lhs, rhs)
    }

    // MARK: - Equatable

    public static func == (lhs: SortDescriptor<Root>, rhs: SortDescriptor<Root>) -> Bool {
        lhs.id == rhs.id && lhs.order == rhs.order
    }
}

// MARK: - Collection Sorting Extensions

extension RandomAccessCollection where Element: Sendable {
    /// Sorts the collection using a key path comparator.
    ///
    /// - Parameter comparator: The comparator to use for sorting.
    /// - Returns: A sorted array of elements.
    public func sorted<Value: Comparable & Sendable>(
        using comparator: KeyPathComparator<Element, Value>
    ) -> [Element] {
        sorted { comparator.compare($0, $1) }
    }

    /// Sorts the collection using a sort comparator.
    ///
    /// - Parameter comparator: The comparator to use for sorting.
    /// - Returns: A sorted array of elements.
    public func sorted(using comparator: SortComparator<Element>) -> [Element] {
        sorted { comparator.compare($0, $1) }
    }

    /// Sorts the collection using multiple sort descriptors.
    ///
    /// Sort descriptors are applied in order, with later descriptors used as
    /// tiebreakers when earlier descriptors consider elements equal.
    ///
    /// - Parameter descriptors: The sort descriptors to apply.
    /// - Returns: A sorted array of elements.
    public func sorted(using descriptors: [SortDescriptor<Element>]) -> [Element] {
        guard !descriptors.isEmpty else { return Array(self) }

        return sorted { lhs, rhs in
            for descriptor in descriptors {
                // If lhs < rhs according to this descriptor, lhs comes first
                if descriptor.compare(lhs, rhs) {
                    return true
                }
                // If rhs < lhs according to this descriptor, rhs comes first
                if descriptor.compare(rhs, lhs) {
                    return false
                }
                // Equal according to this descriptor, try the next one
            }
            // All descriptors consider them equal
            return false
        }
    }
}
