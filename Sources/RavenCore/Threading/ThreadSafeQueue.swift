import Foundation
import JavaScriptKit

/// A lock-free, thread-safe queue for task distribution between workers.
///
/// `ThreadSafeQueue` implements a multi-producer, multi-consumer (MPMC) queue
/// using atomic operations and a circular buffer. It's designed for high-throughput
/// task distribution in the work-stealing scheduler.
///
/// ## Implementation
///
/// Uses a ring buffer with atomic head/tail pointers:
/// - Head: Read position (consumer)
/// - Tail: Write position (producer)
/// - Empty: head == tail
/// - Full: (tail + 1) % capacity == head
///
/// ## Thread Safety
///
/// All operations are lock-free and wait-free (in the common case), making
/// them suitable for high-frequency access from multiple workers.
///
/// ## Usage
///
/// ```swift
/// let queue = try ThreadSafeQueue<Int>(capacity: 1024, buffer: buffer, offset: 0)
///
/// // Producer
/// try queue.enqueue(42)
///
/// // Consumer
/// if let value = queue.dequeue() {
///     processTask(value)
/// }
/// ```
@MainActor
public final class ThreadSafeQueue<Element: Sendable>: Sendable {

    // MARK: - Properties

    /// The shared buffer backing this queue
    private let buffer: SharedBuffer

    /// Atomic operations interface
    private let atomic: AtomicOperations

    /// Capacity of the queue (must be power of 2 for efficiency)
    public let capacity: Int

    /// Byte offset in the buffer where this queue starts
    private let baseOffset: Int

    // Memory layout offsets (in Int32 indices)
    private let headIndex: Int
    private let tailIndex: Int
    private let dataStartIndex: Int

    // Mask for fast modulo operations (capacity - 1)
    private let mask: Int

    // MARK: - Initialization

    /// Initialize a thread-safe queue in a shared buffer.
    ///
    /// - Parameters:
    ///   - capacity: Maximum number of elements (must be power of 2)
    ///   - buffer: Shared buffer to allocate queue in
    ///   - offset: Byte offset where queue data starts
    /// - Throws: If initialization fails or parameters are invalid
    public init(capacity: Int, buffer: SharedBuffer, offset: Int = 0) throws {
        guard capacity > 0 && (capacity & (capacity - 1)) == 0 else {
            throw QueueError.capacityMustBePowerOfTwo
        }

        guard offset >= 0 && offset % 4 == 0 else {
            throw QueueError.invalidOffset
        }

        self.buffer = buffer
        self.atomic = try AtomicOperations(buffer: buffer)
        self.capacity = capacity
        self.baseOffset = offset
        self.mask = capacity - 1

        // Calculate memory layout (in Int32 indices, not bytes)
        let baseIndex = offset / 4
        self.headIndex = baseIndex
        self.tailIndex = baseIndex + 1
        self.dataStartIndex = baseIndex + 2

        // Verify buffer is large enough
        let requiredBytes = offset + Self.requiredBytes(capacity: capacity)
        guard buffer.byteLength >= requiredBytes else {
            throw QueueError.bufferTooSmall
        }

        // Initialize head and tail to 0
        atomic.store(index: headIndex, value: 0)
        atomic.store(index: tailIndex, value: 0)
    }

    /// Calculate required bytes for a queue with given capacity.
    ///
    /// - Parameter capacity: Queue capacity
    /// - Returns: Number of bytes required
    public static func requiredBytes(capacity: Int) -> Int {
        // 2 Int32s for head/tail + capacity * elementSize
        // For now, we store Int32 indices, so element size is 4 bytes
        return 8 + (capacity * 4)
    }

    // MARK: - Queue Operations

    /// Attempt to enqueue an element.
    ///
    /// Non-blocking operation that fails if queue is full.
    ///
    /// - Parameter element: The element to enqueue
    /// - Returns: True if enqueued successfully, false if full
    public func tryEnqueue(_ element: Int32) -> Bool {
        let tail = atomic.load(index: tailIndex)
        let head = atomic.load(index: headIndex)

        // Calculate next tail position
        let nextTail = (tail + 1) & Int32(mask)

        // Check if queue is full
        if nextTail == head {
            return false
        }

        // Try to reserve this slot
        guard atomic.compareExchangeWeak(index: tailIndex, expected: tail, replacement: nextTail) else {
            // Another thread got there first, retry
            return tryEnqueue(element)
        }

        // We've reserved the slot, write the element
        let dataIndex = dataStartIndex + Int(tail & Int32(mask))
        atomic.store(index: dataIndex, value: element)

        return true
    }

    /// Enqueue an element, retrying on failure.
    ///
    /// Spins until successful. Use `tryEnqueue` for non-blocking behavior.
    ///
    /// - Parameter element: The element to enqueue
    public func enqueue(_ element: Int32) {
        while !tryEnqueue(element) {
            // Spin waiting for space
            // Note: In WASM, there's no thread yielding, so this is a busy wait
        }
    }

    /// Attempt to dequeue an element.
    ///
    /// Non-blocking operation that returns nil if queue is empty.
    ///
    /// - Returns: The dequeued element, or nil if empty
    public func tryDequeue() -> Int32? {
        let head = atomic.load(index: headIndex)
        let tail = atomic.load(index: tailIndex)

        // Check if queue is empty
        if head == tail {
            return nil
        }

        // Calculate next head position
        let nextHead = (head + 1) & Int32(mask)

        // Try to reserve this slot
        guard atomic.compareExchangeWeak(index: headIndex, expected: head, replacement: nextHead) else {
            // Another thread got there first, retry
            return tryDequeue()
        }

        // We've reserved the slot, read the element
        let dataIndex = dataStartIndex + Int(head & Int32(mask))
        let element = atomic.load(index: dataIndex)

        return element
    }

    /// Dequeue an element, waiting if empty.
    ///
    /// Blocks until an element is available.
    ///
    /// - Parameter timeout: Maximum time to wait in milliseconds (nil = forever)
    /// - Returns: The dequeued element, or nil on timeout
    public func dequeue(timeout: Int? = nil) -> Int32? {
        let startTime = timeout != nil ? Date().timeIntervalSince1970 : 0

        while true {
            if let element = tryDequeue() {
                return element
            }

            // Check timeout
            if let timeout = timeout {
                let elapsed = Date().timeIntervalSince1970 - startTime
                if elapsed * 1000 >= Double(timeout) {
                    return nil
                }
            }

            // Use futex-style wait for efficiency
            let tail = atomic.load(index: tailIndex)
            let head = atomic.load(index: headIndex)

            if head == tail {
                // Queue is empty, wait for notification
                _ = atomic.wait(index: tailIndex, expected: tail, timeout: timeout)
            }
        }
    }

    // MARK: - Queue State

    /// Check if the queue is empty.
    ///
    /// Note: Result may be stale immediately after return in multi-threaded context.
    ///
    /// - Returns: True if queue appears empty
    public var isEmpty: Bool {
        let head = atomic.load(index: headIndex)
        let tail = atomic.load(index: tailIndex)
        return head == tail
    }

    /// Check if the queue is full.
    ///
    /// Note: Result may be stale immediately after return in multi-threaded context.
    ///
    /// - Returns: True if queue appears full
    public var isFull: Bool {
        let head = atomic.load(index: headIndex)
        let tail = atomic.load(index: tailIndex)
        let nextTail = (tail + 1) & Int32(mask)
        return nextTail == head
    }

    /// Get approximate current size.
    ///
    /// Note: Result may be stale immediately after return in multi-threaded context.
    ///
    /// - Returns: Approximate number of elements in queue
    public var count: Int {
        let head = atomic.load(index: headIndex)
        let tail = atomic.load(index: tailIndex)

        if tail >= head {
            return Int(tail - head)
        } else {
            return capacity - Int(head - tail)
        }
    }

    // MARK: - Utility

    /// Clear the queue.
    ///
    /// Note: Not thread-safe with concurrent operations. Only call when
    /// no other threads are accessing the queue.
    public func clear() {
        atomic.store(index: headIndex, value: 0)
        atomic.store(index: tailIndex, value: 0)
    }

    /// Get queue statistics.
    ///
    /// - Returns: Dictionary with queue metrics
    public func statistics() -> [String: Any] {
        return [
            "capacity": capacity,
            "count": count,
            "isEmpty": isEmpty,
            "isFull": isFull,
            "baseOffset": baseOffset
        ]
    }
}

// MARK: - Queue Errors

/// Errors that can occur with thread-safe queues
public enum QueueError: Error, Sendable {
    /// Queue capacity must be a power of 2
    case capacityMustBePowerOfTwo

    /// Invalid offset (must be non-negative and 4-byte aligned)
    case invalidOffset

    /// Buffer is too small for the queue
    case bufferTooSmall

    /// Queue is full
    case queueFull

    /// Queue is empty
    case queueEmpty
}

// MARK: - Work Stealing Queue

/// A specialized queue for work-stealing schedulers.
///
/// Supports both LIFO (stack-like) access by the owner and FIFO stealing by others.
/// This provides better cache locality for the owner thread.
///
/// ```swift
/// let wsQueue = try WorkStealingQueue(capacity: 1024, buffer: buffer, offset: 0)
///
/// // Owner pushes and pops (LIFO)
/// wsQueue.push(task)
/// if let task = wsQueue.pop() {
///     execute(task)
/// }
///
/// // Thieves steal (FIFO from bottom)
/// if let stolenTask = wsQueue.steal() {
///     execute(stolenTask)
/// }
/// ```
@MainActor
public final class WorkStealingQueue: Sendable {

    // MARK: - Properties

    private let buffer: SharedBuffer
    private let atomic: AtomicOperations
    public let capacity: Int
    private let baseOffset: Int

    private let topIndex: Int      // Owner's end (LIFO)
    private let bottomIndex: Int   // Stealers' end (FIFO)
    private let dataStartIndex: Int
    private let mask: Int

    // MARK: - Initialization

    public init(capacity: Int, buffer: SharedBuffer, offset: Int = 0) throws {
        guard capacity > 0 && (capacity & (capacity - 1)) == 0 else {
            throw QueueError.capacityMustBePowerOfTwo
        }

        guard offset >= 0 && offset % 4 == 0 else {
            throw QueueError.invalidOffset
        }

        self.buffer = buffer
        self.atomic = try AtomicOperations(buffer: buffer)
        self.capacity = capacity
        self.baseOffset = offset
        self.mask = capacity - 1

        let baseIndex = offset / 4
        self.topIndex = baseIndex
        self.bottomIndex = baseIndex + 1
        self.dataStartIndex = baseIndex + 2

        let requiredBytes = offset + ThreadSafeQueue<Int32>.requiredBytes(capacity: capacity)
        guard buffer.byteLength >= requiredBytes else {
            throw QueueError.bufferTooSmall
        }

        atomic.store(index: topIndex, value: 0)
        atomic.store(index: bottomIndex, value: 0)
    }

    // MARK: - Owner Operations (LIFO)

    /// Push a task (owner only, LIFO).
    ///
    /// Should only be called by the owning worker thread.
    ///
    /// - Parameter task: Task ID to push
    /// - Returns: True if pushed successfully
    public func push(_ task: Int32) -> Bool {
        let bottom = atomic.load(index: bottomIndex)
        let top = atomic.load(index: topIndex)

        // Check if full
        if bottom - top >= Int32(capacity) {
            return false
        }

        // Write task
        let dataIndex = dataStartIndex + Int(bottom & Int32(mask))
        atomic.store(index: dataIndex, value: task)

        // Increment bottom
        atomic.store(index: bottomIndex, value: bottom + 1)

        return true
    }

    /// Pop a task (owner only, LIFO).
    ///
    /// Should only be called by the owning worker thread.
    ///
    /// - Returns: The popped task, or nil if empty
    public func pop() -> Int32? {
        var bottom = atomic.load(index: bottomIndex)
        bottom -= 1
        atomic.store(index: bottomIndex, value: bottom)

        let top = atomic.load(index: topIndex)

        if bottom < top {
            // Queue is empty, restore bottom
            atomic.store(index: bottomIndex, value: top)
            return nil
        }

        // Read the task
        let dataIndex = dataStartIndex + Int(bottom & Int32(mask))
        let task = atomic.load(index: dataIndex)

        if bottom == top {
            // This was the last task, race with stealers
            if !atomic.compareExchangeWeak(index: topIndex, expected: top, replacement: top + 1) {
                // Stealer won, queue is empty
                return nil
            }
            atomic.store(index: bottomIndex, value: top + 1)
        }

        return task
    }

    // MARK: - Stealer Operations (FIFO)

    /// Steal a task (thieves, FIFO from bottom).
    ///
    /// Can be called by any worker thread to steal work.
    ///
    /// - Returns: The stolen task, or nil if empty or contention
    public func steal() -> Int32? {
        let top = atomic.load(index: topIndex)
        let bottom = atomic.load(index: bottomIndex)

        // Check if empty
        if top >= bottom {
            return nil
        }

        // Read the task
        let dataIndex = dataStartIndex + Int(top & Int32(mask))
        let task = atomic.load(index: dataIndex)

        // Try to increment top
        guard atomic.compareExchangeWeak(index: topIndex, expected: top, replacement: top + 1) else {
            // Failed to steal (contention)
            return nil
        }

        return task
    }

    // MARK: - State

    /// Check if the queue is empty.
    public var isEmpty: Bool {
        let top = atomic.load(index: topIndex)
        let bottom = atomic.load(index: bottomIndex)
        return top >= bottom
    }

    /// Get approximate size.
    public var count: Int {
        let top = atomic.load(index: topIndex)
        let bottom = atomic.load(index: bottomIndex)
        return max(0, Int(bottom - top))
    }
}

// MARK: - Multi-Producer Single-Consumer Queue

/// A specialized queue optimized for multiple producers and a single consumer.
///
/// More efficient than MPMC queue when you have a single consumer.
///
/// ```swift
/// let mpscQueue = try MPSCQueue(capacity: 1024, buffer: buffer)
///
/// // Multiple producers
/// mpscQueue.enqueue(task)
///
/// // Single consumer
/// if let task = mpscQueue.dequeue() {
///     process(task)
/// }
/// ```
@MainActor
public final class MPSCQueue: Sendable {
    private let buffer: SharedBuffer
    private let atomic: AtomicOperations
    public let capacity: Int
    private let baseOffset: Int

    private let headIndex: Int
    private let tailIndex: Int
    private let dataStartIndex: Int
    private let mask: Int

    public init(capacity: Int, buffer: SharedBuffer, offset: Int = 0) throws {
        guard capacity > 0 && (capacity & (capacity - 1)) == 0 else {
            throw QueueError.capacityMustBePowerOfTwo
        }

        self.buffer = buffer
        self.atomic = try AtomicOperations(buffer: buffer)
        self.capacity = capacity
        self.baseOffset = offset
        self.mask = capacity - 1

        let baseIndex = offset / 4
        self.headIndex = baseIndex
        self.tailIndex = baseIndex + 1
        self.dataStartIndex = baseIndex + 2

        atomic.store(index: headIndex, value: 0)
        atomic.store(index: tailIndex, value: 0)
    }

    /// Enqueue from any producer thread.
    public func enqueue(_ element: Int32) -> Bool {
        let tail = atomic.load(index: tailIndex)
        let head = atomic.load(index: headIndex)

        let nextTail = (tail + 1) & Int32(mask)
        if nextTail == head {
            return false
        }

        guard atomic.compareExchangeWeak(index: tailIndex, expected: tail, replacement: nextTail) else {
            return enqueue(element)
        }

        let dataIndex = dataStartIndex + Int(tail & Int32(mask))
        atomic.store(index: dataIndex, value: element)

        // Notify consumer
        atomic.notify(index: tailIndex)

        return true
    }

    /// Dequeue from single consumer thread.
    public func dequeue() -> Int32? {
        let head = atomic.load(index: headIndex)
        let tail = atomic.load(index: tailIndex)

        if head == tail {
            return nil
        }

        let dataIndex = dataStartIndex + Int(head & Int32(mask))
        let element = atomic.load(index: dataIndex)

        // Consumer is single-threaded, no CAS needed
        atomic.store(index: headIndex, value: head + 1)

        return element
    }
}
