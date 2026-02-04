import Foundation

/// Debounces rapid successive calls by waiting for a quiet period before executing the handler.
actor ChangeDebouncer {
    /// Handler to execute after debounce period
    private let handler: @Sendable () async -> Void

    /// Debounce delay in nanoseconds
    private let delay: UInt64

    /// Task handling the current debounce delay
    private var debounceTask: Task<Void, Never>?

    /// Timestamp of the last change event
    private var lastChangeTime: ContinuousClock.Instant?

    /// Initialize debouncer with handler and delay
    /// - Parameters:
    ///   - delayMilliseconds: Milliseconds to wait after last change before executing handler
    ///   - handler: Async handler to execute after quiet period
    init(delayMilliseconds: Int = 100, handler: @escaping @Sendable () async -> Void) {
        self.handler = handler
        self.delay = UInt64(delayMilliseconds) * 1_000_000 // Convert ms to nanoseconds
    }

    /// Trigger a change event. This will reset the debounce timer.
    func trigger() {
        // Cancel existing debounce task
        debounceTask?.cancel()

        // Record change time
        lastChangeTime = ContinuousClock.now

        // Create new debounce task
        debounceTask = Task {
            // Wait for the debounce period
            try? await Task.sleep(nanoseconds: delay)

            // Check if we weren't cancelled
            guard !Task.isCancelled else { return }

            // Execute the handler
            await handler()
        }
    }

    /// Cancel any pending debounced execution
    func cancel() {
        debounceTask?.cancel()
        debounceTask = nil
        lastChangeTime = nil
    }
}
