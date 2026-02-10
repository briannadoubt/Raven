import Foundation

/// Stable identity for a fiber node, derived from its position in the view tree.
///
/// Uses FNV-1a hashing (same scheme as `NodeID(stablePath:)`) so that the
/// same structural position always produces the same ID across renders.
public struct FiberID: Hashable, Sendable, CustomStringConvertible {
    /// The raw 64-bit FNV-1a hash of the path.
    public let rawValue: UInt64

    /// The path string this ID was derived from (kept for debugging).
    public let path: String

    /// Create a FiberID from a view-tree path string.
    ///
    /// - Parameter path: Dot-separated position, e.g. `"root.VStack.0.Button"`.
    public init(path: String) {
        self.path = path
        self.rawValue = Self.fnv1a(path)
    }

    /// FNV-1a hash matching the scheme used by `NodeID(stablePath:)`.
    private static func fnv1a(_ string: String) -> UInt64 {
        var hash: UInt64 = 14695981039346656037 // FNV-1a offset basis
        for byte in string.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 1099511628211 // FNV-1a prime
        }
        return hash
    }

    /// Derive a child FiberID by appending a path component.
    ///
    /// - Parameter component: The child component (index string, type name, or key).
    /// - Returns: A new `FiberID` with the extended path.
    public func child(_ component: String) -> FiberID {
        FiberID(path: "\(path).\(component)")
    }

    public var description: String {
        "FiberID(\(path))"
    }
}
