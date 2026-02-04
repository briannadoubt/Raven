import Foundation

/// A type-erased list of views representing a navigation stack.
///
/// `NavigationPath` maintains a stack of views for navigation purposes.
/// For Phase 4, this is a simple in-memory stack. Future phases will integrate
/// with the browser's HTML5 History API for proper URL-based navigation.
///
/// Example:
/// ```swift
/// var path = NavigationPath()
/// path.append(DetailView())
/// path.removeLast()
/// ```
public struct NavigationPath: Sendable {
    /// Type-erased storage for navigation destinations
    private var destinations: [AnyView]

    /// Creates an empty navigation path.
    public init() {
        self.destinations = []
    }

    /// The number of views in the navigation stack.
    public var count: Int {
        destinations.count
    }

    /// Whether the navigation stack is empty.
    public var isEmpty: Bool {
        destinations.isEmpty
    }

    /// Appends a view to the navigation stack.
    ///
    /// - Parameter view: The view to push onto the stack.
    @MainActor
    public mutating func append<V: View>(_ view: V) {
        destinations.append(AnyView(view))
    }

    /// Removes the last view from the navigation stack.
    ///
    /// This method does nothing if the stack is already empty.
    @discardableResult
    public mutating func removeLast() -> AnyView? {
        guard !destinations.isEmpty else { return nil }
        return destinations.removeLast()
    }

    /// Returns the view at the top of the stack without removing it.
    public func peek() -> AnyView? {
        destinations.last
    }

    /// Removes all views from the navigation stack.
    public mutating func removeAll() {
        destinations.removeAll()
    }

    /// Returns the view at the specified index.
    ///
    /// - Parameter index: The position of the view to access.
    /// - Returns: The view at the specified index.
    public subscript(index: Int) -> AnyView {
        destinations[index]
    }

    /// Access to all destinations for iteration
    internal var allDestinations: [AnyView] {
        destinations
    }
}
