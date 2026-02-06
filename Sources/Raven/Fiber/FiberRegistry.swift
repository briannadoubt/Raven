import Foundation

/// Thread-safe registry that maps component paths to their corresponding Fibers.
/// Used by StateStorage to mark components dirty when their state changes.
@MainActor
public final class FiberRegistry: Sendable {
    /// Shared singleton instance
    public static let shared = FiberRegistry()

    /// Maps component paths to their corresponding Fibers
    private var pathToFiber: [String: Fiber] = [:]

    private init() {}

    /// Registers a fiber for a given component path.
    /// - Parameters:
    ///   - fiber: The fiber to register
    ///   - path: The component path to associate with the fiber
    public func register(fiber: Fiber, forPath path: String) {
        pathToFiber[path] = fiber
    }

    /// Unregisters a fiber for a given component path.
    /// - Parameter path: The component path to unregister
    public func unregister(path: String) {
        pathToFiber.removeValue(forKey: path)
    }

    /// Looks up a fiber by component path.
    /// - Parameter path: The component path to look up
    /// - Returns: The fiber associated with the path, or nil if not found
    public func fiber(for path: String) -> Fiber? {
        return pathToFiber[path]
    }

    /// Marks a fiber dirty by component path.
    /// This is called by StateStorage when state changes occur.
    /// - Parameter path: The component path whose fiber should be marked dirty
    public func markDirty(path: String) {
        guard let fiber = pathToFiber[path] else {
            return
        }
        fiber.markDirty()
    }

    /// Clears all registered fibers.
    /// Can be used to reset the registry between render cycles if needed.
    public func clear() {
        pathToFiber.removeAll()
    }
}
