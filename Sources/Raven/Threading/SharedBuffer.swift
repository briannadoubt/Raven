import Foundation
import JavaScriptKit

/// A wrapper around JavaScript's SharedArrayBuffer for cross-thread data sharing.
///
/// `SharedBuffer` provides a type-safe interface to SharedArrayBuffer, enabling
/// multiple Web Workers to access the same memory concurrently. This is the
/// foundation for all multi-threaded communication in Raven.
///
/// ## Memory Layout
///
/// The buffer can be viewed as different typed arrays:
/// - `Int8Array` for byte-level access
/// - `Int32Array` for 32-bit integer operations (used by atomics)
/// - `Float64Array` for floating-point data
///
/// ## Thread Safety
///
/// The buffer itself is thread-safe and can be transferred between workers.
/// However, access to the data requires atomic operations (via `AtomicOperations`)
/// or explicit synchronization to avoid data races.
///
/// ## Usage
///
/// ```swift
/// // Create a shared buffer
/// let buffer = SharedBuffer(byteLength: 4096)
///
/// // Transfer to a worker
/// worker.postMessage(buffer.transferable())
///
/// // Perform atomic operations
/// let atomic = try AtomicOperations(buffer: buffer)
/// atomic.store(index: 0, value: 42)
/// ```
///
/// ## Browser Support
///
/// SharedArrayBuffer requires:
/// - Cross-Origin Isolation (COOP/COEP headers)
/// - Modern browser (Chrome 68+, Firefox 79+, Safari 15.2+)
@MainActor
public final class SharedBuffer: Sendable {

    // MARK: - Properties

    /// The underlying JavaScript SharedArrayBuffer
    public let jsBuffer: JSObject

    /// Byte length of the buffer
    public let byteLength: Int

    // MARK: - Initialization

    /// Create a new SharedArrayBuffer with the specified size.
    ///
    /// - Parameter byteLength: Size in bytes (must be aligned to 8 bytes for optimal performance)
    /// - Throws: If SharedArrayBuffer is not supported or allocation fails
    public init(byteLength: Int) throws {
        guard SharedBuffer.isSupported else {
            throw SharedBufferError.notSupported
        }

        guard byteLength > 0 else {
            throw SharedBufferError.invalidSize
        }

        guard let constructor = JSObject.global.SharedArrayBuffer.function else {
            throw SharedBufferError.constructorNotAvailable
        }

        let buffer = constructor.new(byteLength)
        self.jsBuffer = buffer
        self.byteLength = byteLength
    }

    /// Wrap an existing JavaScript SharedArrayBuffer.
    ///
    /// Used when receiving a buffer from a Web Worker or other source.
    ///
    /// - Parameter jsBuffer: The JavaScript SharedArrayBuffer object
    /// - Throws: If the object is not a valid SharedArrayBuffer
    public init(wrapping jsBuffer: JSObject) throws {
        // Verify it's a SharedArrayBuffer
        guard SharedBuffer.isSharedArrayBuffer(jsBuffer) else {
            throw SharedBufferError.notSharedArrayBuffer
        }

        guard let length = jsBuffer.byteLength.number else {
            throw SharedBufferError.invalidBuffer
        }

        self.jsBuffer = jsBuffer
        self.byteLength = Int(length)
    }

    // MARK: - Views

    /// Create an Int8Array view of the buffer.
    ///
    /// - Parameters:
    ///   - byteOffset: Byte offset in the buffer (default: 0)
    ///   - length: Number of elements (default: entire buffer)
    /// - Returns: JavaScript Int8Array view
    /// - Throws: If view creation fails
    public func int8Array(byteOffset: Int = 0, length: Int? = nil) throws -> JSObject {
        guard let constructor = JSObject.global.Int8Array.function else {
            throw SharedBufferError.typedArrayNotSupported
        }

        if let length = length {
            return constructor.new(jsBuffer, byteOffset, length)
        } else {
            return constructor.new(jsBuffer, byteOffset)
        }
    }

    /// Create an Int32Array view of the buffer.
    ///
    /// Used for atomic operations. Byte offset must be aligned to 4 bytes.
    ///
    /// - Parameters:
    ///   - byteOffset: Byte offset in the buffer (must be multiple of 4, default: 0)
    ///   - length: Number of Int32 elements (default: entire buffer)
    /// - Returns: JavaScript Int32Array view
    /// - Throws: If view creation fails or offset is misaligned
    public func int32Array(byteOffset: Int = 0, length: Int? = nil) throws -> JSObject {
        guard byteOffset % 4 == 0 else {
            throw SharedBufferError.misalignedAccess
        }

        guard let constructor = JSObject.global.Int32Array.function else {
            throw SharedBufferError.typedArrayNotSupported
        }

        if let length = length {
            return constructor.new(jsBuffer, byteOffset, length)
        } else {
            return constructor.new(jsBuffer, byteOffset)
        }
    }

    /// Create a Float64Array view of the buffer.
    ///
    /// Used for floating-point data. Byte offset must be aligned to 8 bytes.
    ///
    /// - Parameters:
    ///   - byteOffset: Byte offset in the buffer (must be multiple of 8, default: 0)
    ///   - length: Number of Float64 elements (default: entire buffer)
    /// - Returns: JavaScript Float64Array view
    /// - Throws: If view creation fails or offset is misaligned
    public func float64Array(byteOffset: Int = 0, length: Int? = nil) throws -> JSObject {
        guard byteOffset % 8 == 0 else {
            throw SharedBufferError.misalignedAccess
        }

        guard let constructor = JSObject.global.Float64Array.function else {
            throw SharedBufferError.typedArrayNotSupported
        }

        if let length = length {
            return constructor.new(jsBuffer, byteOffset, length)
        } else {
            return constructor.new(jsBuffer, byteOffset)
        }
    }

    /// Create a Uint8Array view of the buffer.
    ///
    /// - Parameters:
    ///   - byteOffset: Byte offset in the buffer (default: 0)
    ///   - length: Number of elements (default: entire buffer)
    /// - Returns: JavaScript Uint8Array view
    /// - Throws: If view creation fails
    public func uint8Array(byteOffset: Int = 0, length: Int? = nil) throws -> JSObject {
        guard let constructor = JSObject.global.Uint8Array.function else {
            throw SharedBufferError.typedArrayNotSupported
        }

        if let length = length {
            return constructor.new(jsBuffer, byteOffset, length)
        } else {
            return constructor.new(jsBuffer, byteOffset)
        }
    }

    // MARK: - Data Transfer

    /// Get the buffer in a form suitable for postMessage to a Web Worker.
    ///
    /// SharedArrayBuffer can be cloned in postMessage without being neutered.
    ///
    /// - Returns: The JavaScript buffer object
    public func transferable() -> JSObject {
        return jsBuffer
    }

    /// Clone this buffer (creates a new SharedArrayBuffer with same data).
    ///
    /// Note: This creates a new buffer and copies data. For sharing between
    /// workers, use `transferable()` instead.
    ///
    /// - Returns: A new SharedBuffer with copied data
    /// - Throws: If cloning fails
    public func clone() throws -> SharedBuffer {
        let newBuffer = try SharedBuffer(byteLength: byteLength)

        // Copy data using Uint8Array
        let sourceView = try uint8Array()
        let destView = try newBuffer.uint8Array()

        // Use JavaScript array copy
        _ = destView.set!(sourceView)

        return newBuffer
    }

    // MARK: - Utility Methods

    /// Check if SharedArrayBuffer is supported in the environment.
    ///
    /// - Returns: True if SharedArrayBuffer is available
    public static var isSupported: Bool {
        let sab = JSObject.global.SharedArrayBuffer
        return !sab.isUndefined && !sab.isNull
    }

    /// Check if cross-origin isolation is enabled.
    ///
    /// SharedArrayBuffer requires COOP and COEP headers to be set.
    ///
    /// - Returns: True if cross-origin isolated
    public static var isCrossOriginIsolated: Bool {
        guard let crossOriginIsolated = JSObject.global.crossOriginIsolated.boolean else {
            return false
        }
        return crossOriginIsolated
    }

    /// Check if a JavaScript object is a SharedArrayBuffer.
    ///
    /// - Parameter object: The object to check
    /// - Returns: True if the object is a SharedArrayBuffer
    public static func isSharedArrayBuffer(_ object: JSObject) -> Bool {
        guard let constructor = JSObject.global.SharedArrayBuffer.function else {
            return false
        }

        // Simple check using constructor name
        let constructorName = object.constructor.name.string
        return constructorName == "SharedArrayBuffer"
    }

    /// Get diagnostic information about the buffer.
    ///
    /// - Returns: Dictionary with buffer statistics
    public func diagnostics() -> [String: Any] {
        return [
            "byteLength": byteLength,
            "isShared": true,
            "type": "SharedArrayBuffer"
        ]
    }

    // MARK: - Memory Regions

    /// Allocate a region within the buffer with alignment.
    ///
    /// Helper for partitioning the buffer into logical sections.
    ///
    /// - Parameters:
    ///   - size: Size in bytes
    ///   - alignment: Required alignment (default: 8 bytes)
    /// - Returns: Tuple of (offset, aligned size)
    public static func allocateRegion(size: Int, alignment: Int = 8) -> (offset: Int, size: Int) {
        let alignedSize = (size + alignment - 1) / alignment * alignment
        return (0, alignedSize)
    }

    /// Calculate aligned offset for a given base offset.
    ///
    /// - Parameters:
    ///   - offset: Current offset
    ///   - alignment: Required alignment
    /// - Returns: Next aligned offset
    public static func alignOffset(_ offset: Int, to alignment: Int) -> Int {
        return (offset + alignment - 1) / alignment * alignment
    }
}

// MARK: - Shared Buffer Errors

/// Errors that can occur when working with shared buffers
public enum SharedBufferError: Error, Sendable {
    /// SharedArrayBuffer is not supported in the environment
    case notSupported

    /// Cross-origin isolation is not enabled
    case notCrossOriginIsolated

    /// SharedArrayBuffer constructor is not available
    case constructorNotAvailable

    /// Invalid buffer size (must be > 0)
    case invalidSize

    /// Memory allocation failed
    case allocationFailed

    /// Object is not a SharedArrayBuffer
    case notSharedArrayBuffer

    /// Invalid buffer object
    case invalidBuffer

    /// TypedArray constructors not available
    case typedArrayNotSupported

    /// Access is not properly aligned
    case misalignedAccess

    /// Index out of bounds
    case indexOutOfBounds
}

// MARK: - Buffer Layout

/// Helper for managing structured layouts in shared buffers.
///
/// Provides compile-time type safety for accessing specific regions.
///
/// ```swift
/// struct RenderState: BufferLayout {
///     static let frameCountOffset = 0
///     static let taskCountOffset = 4
///     static let statusOffset = 8
///     static let totalSize = 12
/// }
///
/// let buffer = try SharedBuffer(byteLength: RenderState.totalSize)
/// let atomic = try AtomicOperations(buffer: buffer)
/// atomic.store(index: RenderState.frameCountOffset / 4, value: 0)
/// ```
public protocol BufferLayout {
    /// Total size in bytes required for this layout
    static var totalSize: Int { get }
}

// MARK: - Common Buffer Layouts

/// Standard header layout for shared buffers
public struct BufferHeader: BufferLayout {
    /// Version number (4 bytes)
    public static let versionOffset = 0

    /// Magic number for validation (4 bytes)
    public static let magicOffset = 4

    /// Status flags (4 bytes)
    public static let statusOffset = 8

    /// Reserved for future use (4 bytes)
    public static let reservedOffset = 12

    /// Total header size
    public static let totalSize = 16

    /// Magic number value for validation
    public static let magicValue: Int32 = 0x52564E54  // "RVNT" in ASCII
}

/// Layout for a simple lock using atomics
public struct SpinLockLayout: BufferLayout {
    /// Lock state (0 = unlocked, 1 = locked)
    public static let lockOffset = 0

    /// Total size (one Int32)
    public static let totalSize = 4
}

/// Layout for a semaphore using atomics
public struct SemaphoreLayout: BufferLayout {
    /// Count value
    public static let countOffset = 0

    /// Maximum count
    public static let maxCountOffset = 4

    /// Total size
    public static let totalSize = 8
}
