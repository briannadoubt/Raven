import Foundation
import JavaScriptKit

/// Provides atomic operations for thread-safe data access using Web Assembly atomics.
///
/// This module wraps JavaScript's `Atomics` API to provide thread-safe operations
/// on `SharedArrayBuffer` for coordination between Web Workers. All operations are
/// guaranteed to be atomic and provide memory ordering semantics.
///
/// ## Supported Operations
///
/// - Load and store with memory ordering
/// - Compare-and-swap (CAS)
/// - Fetch-and-add/sub/and/or/xor
/// - Wait and notify for futex-style synchronization
///
/// ## Usage
///
/// ```swift
/// let buffer = SharedBuffer(byteLength: 1024)
/// let atomic = AtomicOperations(buffer: buffer)
///
/// // Atomic increment
/// let oldValue = atomic.add(index: 0, value: 1)
///
/// // Compare-and-swap
/// let exchanged = atomic.compareExchange(index: 0, expected: 5, replacement: 10)
/// ```
///
/// ## Thread Safety
///
/// All operations in this module are thread-safe and can be called from
/// multiple Web Workers concurrently without additional synchronization.
@MainActor
public struct AtomicOperations: Sendable {

    // MARK: - Types

    /// Memory ordering for atomic operations
    public enum MemoryOrder: Sendable {
        /// Sequentially consistent ordering (strongest)
        case sequentiallyConsistent
        /// Acquire ordering for loads
        case acquire
        /// Release ordering for stores
        case release
        /// Relaxed ordering (weakest, no synchronization)
        case relaxed
    }

    /// Result of a wait operation
    public enum WaitResult: String, Sendable {
        /// Wait completed due to notify
        case ok = "ok"
        /// Wait timed out
        case timedOut = "timed-out"
        /// Value at index did not match expected value
        case notEqual = "not-equal"
    }

    // MARK: - Properties

    /// The shared buffer containing the atomic data
    private let buffer: SharedBuffer

    /// The Int32Array view for atomic operations
    private let int32View: JSObject

    /// JavaScript Atomics API reference
    private let atomics: JSObject

    // MARK: - Initialization

    /// Initialize atomic operations on a shared buffer.
    ///
    /// - Parameter buffer: The SharedBuffer to perform operations on
    /// - Throws: If the buffer is not suitable for atomic operations
    public init(buffer: SharedBuffer) throws {
        self.buffer = buffer

        guard let atomicsAPI = JSObject.global.Atomics.object else {
            throw AtomicError.atomicsNotSupported
        }
        self.atomics = atomicsAPI

        // Create Int32Array view for atomic operations
        guard let int32Constructor = JSObject.global.Int32Array.function else {
            throw AtomicError.typedArrayNotSupported
        }

        let view = int32Constructor.new(buffer.jsBuffer)
        self.int32View = view
    }

    // MARK: - Load and Store Operations

    /// Atomically load a value from the specified index.
    ///
    /// Provides memory ordering guarantees for reads in multi-threaded contexts.
    ///
    /// - Parameters:
    ///   - index: The index in the Int32Array (not byte offset)
    ///   - order: Memory ordering (default: sequentiallyConsistent)
    /// - Returns: The loaded value
    public func load(index: Int, order: MemoryOrder = .sequentiallyConsistent) -> Int32 {
        guard let loadFunc = atomics.load.function else {
            // Fallback to direct array access if Atomics.load unavailable
            return Int32(int32View[index].number ?? 0)
        }

        let result = loadFunc(int32View, index)
        return Int32(result.number ?? 0)
    }

    /// Atomically store a value at the specified index.
    ///
    /// Provides memory ordering guarantees for writes in multi-threaded contexts.
    ///
    /// - Parameters:
    ///   - index: The index in the Int32Array (not byte offset)
    ///   - value: The value to store
    ///   - order: Memory ordering (default: sequentiallyConsistent)
    /// - Returns: The value that was stored
    @discardableResult
    public func store(index: Int, value: Int32, order: MemoryOrder = .sequentiallyConsistent) -> Int32 {
        guard let storeFunc = atomics.store.function else {
            // Fallback to direct array access
            int32View[index] = .number(Double(value))
            return value
        }

        let result = storeFunc(int32View, index, Int(value))
        return Int32(result.number ?? Double(value))
    }

    /// Atomically exchange a value at the specified index.
    ///
    /// Sets the value at the index and returns the previous value atomically.
    ///
    /// - Parameters:
    ///   - index: The index in the Int32Array
    ///   - value: The new value to store
    /// - Returns: The previous value at the index
    @discardableResult
    public func exchange(index: Int, value: Int32) -> Int32 {
        guard let exchangeFunc = atomics.exchange.function else {
            let old = load(index: index)
            store(index: index, value: value)
            return old
        }

        let result = exchangeFunc(int32View, index, Int(value))
        return Int32(result.number ?? 0)
    }

    // MARK: - Compare and Exchange

    /// Atomically compare and exchange a value (CAS operation).
    ///
    /// Compares the value at the index with the expected value. If they match,
    /// stores the replacement value. Returns the original value.
    ///
    /// This is the fundamental primitive for lock-free algorithms.
    ///
    /// - Parameters:
    ///   - index: The index in the Int32Array
    ///   - expected: The expected current value
    ///   - replacement: The new value to store if comparison succeeds
    /// - Returns: The original value at the index
    @discardableResult
    public func compareExchange(index: Int, expected: Int32, replacement: Int32) -> Int32 {
        guard let casFunc = atomics.compareExchange.function else {
            let current = load(index: index)
            if current == expected {
                store(index: index, value: replacement)
            }
            return current
        }

        let result = casFunc(int32View, index, Int(expected), Int(replacement))
        return Int32(result.number ?? 0)
    }

    /// Check if compare-and-exchange succeeded.
    ///
    /// Convenience method that returns true if the CAS operation succeeded.
    ///
    /// - Parameters:
    ///   - index: The index in the Int32Array
    ///   - expected: The expected current value
    ///   - replacement: The new value to store if comparison succeeds
    /// - Returns: True if the exchange succeeded
    public func compareExchangeWeak(index: Int, expected: Int32, replacement: Int32) -> Bool {
        let original = compareExchange(index: index, expected: expected, replacement: replacement)
        return original == expected
    }

    // MARK: - Arithmetic Operations

    /// Atomically add a value and return the previous value.
    ///
    /// - Parameters:
    ///   - index: The index in the Int32Array
    ///   - value: The value to add
    /// - Returns: The previous value before addition
    @discardableResult
    public func add(index: Int, value: Int32) -> Int32 {
        guard let addFunc = atomics.add.function else {
            // Fallback using CAS loop
            var current: Int32
            repeat {
                current = load(index: index)
            } while !compareExchangeWeak(index: index, expected: current, replacement: current &+ value)
            return current
        }

        let result = addFunc(int32View, index, Int(value))
        return Int32(result.number ?? 0)
    }

    /// Atomically subtract a value and return the previous value.
    ///
    /// - Parameters:
    ///   - index: The index in the Int32Array
    ///   - value: The value to subtract
    /// - Returns: The previous value before subtraction
    @discardableResult
    public func sub(index: Int, value: Int32) -> Int32 {
        guard let subFunc = atomics.sub.function else {
            return add(index: index, value: -value)
        }

        let result = subFunc(int32View, index, Int(value))
        return Int32(result.number ?? 0)
    }

    /// Atomically increment and return the new value.
    ///
    /// - Parameter index: The index in the Int32Array
    /// - Returns: The new value after incrementing
    @discardableResult
    public func increment(index: Int) -> Int32 {
        return add(index: index, value: 1) &+ 1
    }

    /// Atomically decrement and return the new value.
    ///
    /// - Parameter index: The index in the Int32Array
    /// - Returns: The new value after decrementing
    @discardableResult
    public func decrement(index: Int) -> Int32 {
        return sub(index: index, value: 1) &- 1
    }

    // MARK: - Bitwise Operations

    /// Atomically perform bitwise AND and return the previous value.
    ///
    /// - Parameters:
    ///   - index: The index in the Int32Array
    ///   - value: The value to AND with
    /// - Returns: The previous value before the operation
    @discardableResult
    public func and(index: Int, value: Int32) -> Int32 {
        guard let andFunc = atomics.and.function else {
            var current: Int32
            repeat {
                current = load(index: index)
            } while !compareExchangeWeak(index: index, expected: current, replacement: current & value)
            return current
        }

        let result = andFunc(int32View, index, Int(value))
        return Int32(result.number ?? 0)
    }

    /// Atomically perform bitwise OR and return the previous value.
    ///
    /// - Parameters:
    ///   - index: The index in the Int32Array
    ///   - value: The value to OR with
    /// - Returns: The previous value before the operation
    @discardableResult
    public func or(index: Int, value: Int32) -> Int32 {
        guard let orFunc = atomics.or.function else {
            var current: Int32
            repeat {
                current = load(index: index)
            } while !compareExchangeWeak(index: index, expected: current, replacement: current | value)
            return current
        }

        let result = orFunc(int32View, index, Int(value))
        return Int32(result.number ?? 0)
    }

    /// Atomically perform bitwise XOR and return the previous value.
    ///
    /// - Parameters:
    ///   - index: The index in the Int32Array
    ///   - value: The value to XOR with
    /// - Returns: The previous value before the operation
    @discardableResult
    public func xor(index: Int, value: Int32) -> Int32 {
        guard let xorFunc = atomics.xor.function else {
            var current: Int32
            repeat {
                current = load(index: index)
            } while !compareExchangeWeak(index: index, expected: current, replacement: current ^ value)
            return current
        }

        let result = xorFunc(int32View, index, Int(value))
        return Int32(result.number ?? 0)
    }

    // MARK: - Wait and Notify (Futex Operations)

    /// Block the thread until notified or timeout occurs.
    ///
    /// This operation puts the calling thread to sleep if the value at the index
    /// matches the expected value. The thread will wake up when:
    /// - Another thread calls `notify` on the same index
    /// - The timeout expires (if specified)
    /// - The value no longer matches expected
    ///
    /// This is similar to futex operations in Linux.
    ///
    /// - Parameters:
    ///   - index: The index in the Int32Array to wait on
    ///   - expected: The expected value at the index
    ///   - timeout: Timeout in milliseconds (nil = infinite)
    /// - Returns: The result of the wait operation
    public func wait(index: Int, expected: Int32, timeout: Int? = nil) -> WaitResult {
        guard let waitFunc = atomics.wait.function else {
            return .notEqual
        }

        let result: JSValue
        if let timeout = timeout {
            result = waitFunc(int32View, index, Int(expected), timeout)
        } else {
            result = waitFunc(int32View, index, Int(expected))
        }

        guard let resultString = result.string else {
            return .notEqual
        }

        return WaitResult(rawValue: resultString) ?? .notEqual
    }

    /// Wake up threads waiting on the specified index.
    ///
    /// Wakes up threads that are blocked in a `wait` call on the same index.
    ///
    /// - Parameters:
    ///   - index: The index in the Int32Array to notify
    ///   - count: Number of threads to wake (default: 1, use Int.max for all)
    /// - Returns: The number of threads that were woken up
    @discardableResult
    public func notify(index: Int, count: Int = 1) -> Int {
        guard let notifyFunc = atomics.notify.function else {
            return 0
        }

        let result = notifyFunc(int32View, index, count)
        return Int(result.number ?? 0)
    }

    /// Wake up all threads waiting on the specified index.
    ///
    /// Convenience method to wake all waiting threads.
    ///
    /// - Parameter index: The index in the Int32Array to notify
    /// - Returns: The number of threads that were woken up
    @discardableResult
    public func notifyAll(index: Int) -> Int {
        return notify(index: index, count: Int.max)
    }

    // MARK: - Utility Methods

    /// Check if atomics are supported in the current environment.
    ///
    /// - Returns: True if Web Assembly atomics are available
    public static func isSupported() -> Bool {
        return !JSObject.global.Atomics.isUndefined && !JSObject.global.Atomics.isNull
    }

    /// Check if shared memory is supported.
    ///
    /// - Returns: True if SharedArrayBuffer is available
    public static func isSharedMemorySupported() -> Bool {
        return !JSObject.global.SharedArrayBuffer.isUndefined && !JSObject.global.SharedArrayBuffer.isNull
    }
}

// MARK: - Atomic Errors

/// Errors that can occur during atomic operations
public enum AtomicError: Error, Sendable {
    /// Atomics API is not supported in the environment
    case atomicsNotSupported

    /// TypedArray constructors not available
    case typedArrayNotSupported

    /// Failed to create typed array view
    case viewCreationFailed

    /// Buffer is not a SharedArrayBuffer
    case notSharedBuffer

    /// Index out of bounds
    case indexOutOfBounds
}

// MARK: - Atomic Reference Type

/// A thread-safe wrapper for atomic Int32 values.
///
/// Provides a higher-level interface for atomic operations on a single value.
///
/// ```swift
/// let counter = AtomicInt32(buffer: buffer, index: 0)
/// counter.increment()
/// let value = counter.load()
/// ```
@MainActor
public final class AtomicInt32: Sendable {
    private let operations: AtomicOperations
    private let index: Int

    /// Initialize an atomic Int32 at a specific index in a shared buffer.
    ///
    /// - Parameters:
    ///   - buffer: The shared buffer
    ///   - index: The index in the Int32Array (not byte offset)
    public init(buffer: SharedBuffer, index: Int) throws {
        self.operations = try AtomicOperations(buffer: buffer)
        self.index = index
    }

    /// Load the current value.
    public func load() -> Int32 {
        return operations.load(index: index)
    }

    /// Store a new value.
    @discardableResult
    public func store(_ value: Int32) -> Int32 {
        return operations.store(index: index, value: value)
    }

    /// Atomically increment and return the new value.
    @discardableResult
    public func increment() -> Int32 {
        return operations.increment(index: index)
    }

    /// Atomically decrement and return the new value.
    @discardableResult
    public func decrement() -> Int32 {
        return operations.decrement(index: index)
    }

    /// Atomically add a value and return the previous value.
    @discardableResult
    public func fetchAdd(_ value: Int32) -> Int32 {
        return operations.add(index: index, value: value)
    }

    /// Compare and exchange (CAS operation).
    @discardableResult
    public func compareExchange(expected: Int32, replacement: Int32) -> Int32 {
        return operations.compareExchange(index: index, expected: expected, replacement: replacement)
    }

    /// Wait for the value to change from expected.
    public func wait(expected: Int32, timeout: Int? = nil) -> AtomicOperations.WaitResult {
        return operations.wait(index: index, expected: expected, timeout: timeout)
    }

    /// Notify waiting threads.
    @discardableResult
    public func notify(count: Int = 1) -> Int {
        return operations.notify(index: index, count: count)
    }
}
