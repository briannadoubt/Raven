import Foundation

/// A type-erased list representing a navigation stack.
///
/// Raven supports two styles of `NavigationPath`:
/// - View-based: `append(_ view: some View)` (legacy Raven behavior)
/// - Value-based: `append(_ value: some Hashable)` (SwiftUI-style API surface)
///
/// Note: Raven's `NavigationStack` currently uses view-based destinations when
/// provided. Value-based path elements are stored for API parity and route-style
/// workflows, but require destination mapping elsewhere.
public struct NavigationPath: Sendable, Equatable {
    private final class _ViewBox: @unchecked Sendable {
        let id: UUID = UUID()
        let view: AnyView
        init(_ view: AnyView) { self.view = view }
    }

    private enum _Item: @unchecked Sendable, Equatable {
        case value(AnyHashable)
        case view(_ViewBox)

        static func == (lhs: _Item, rhs: _Item) -> Bool {
            switch (lhs, rhs) {
            case (.value(let a), .value(let b)):
                return a == b
            case (.view(let a), .view(let b)):
                return a.id == b.id
            default:
                return false
            }
        }
    }

    private var items: [_Item]

    /// Creates an empty navigation path.
    public init() {
        self.items = []
    }

    /// The number of elements in the navigation path.
    public var count: Int { items.count }

    /// Whether the navigation path is empty.
    public var isEmpty: Bool { items.isEmpty }

    // MARK: - Append

    /// Appends a view to the navigation stack (legacy Raven behavior).
    @MainActor
    public mutating func append<V: View>(_ view: V) {
        items.append(.view(_ViewBox(AnyView(view))))
    }

    /// Appends a hashable value to the navigation path (SwiftUI-style).
    public mutating func append<T: Hashable>(_ value: T) {
        items.append(.value(AnyHashable(value)))
    }

    // MARK: - Remove

    /// Removes the last element from the navigation path.
    @discardableResult
    public mutating func removeLast() -> AnyView? {
        guard let last = items.popLast() else { return nil }
        if case .view(let box) = last {
            return box.view
        }
        return nil
    }

    /// Removes the given number of elements from the end of the path.
    public mutating func removeLast(_ k: Int) {
        guard k > 0 else { return }
        let n = min(k, items.count)
        items.removeLast(n)
    }

    /// Removes all elements from the navigation path.
    public mutating func removeAll() {
        items.removeAll()
    }

    // MARK: - Peek/Indexing

    /// Returns the view at the top of the stack without removing it (if the last item is a view).
    public func peek() -> AnyView? {
        guard let last = items.last else { return nil }
        if case .view(let box) = last { return box.view }
        return nil
    }

    /// Returns the view destination at the specified index (view-only).
    @MainActor public subscript(index: Int) -> AnyView {
        switch items[index] {
        case .view(let box):
            return box.view
        case .value:
            return AnyView(EmptyView())
        }
    }

    // MARK: - Internal Access (NavigationStack)

    /// Access to all view-based destinations for iteration.
    internal var allDestinations: [AnyView] {
        items.compactMap { item in
            if case .view(let box) = item { return box.view }
            return nil
        }
    }

    /// Access to all value-based elements for route-style workflows.
    public var elements: [AnyHashable] {
        items.compactMap { item in
            if case .value(let v) = item { return v }
            return nil
        }
    }
}
