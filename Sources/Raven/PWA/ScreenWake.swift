import Foundation
import JavaScriptKit

/// Manages screen wake lock to prevent device from sleeping
///
/// ScreenWake provides control over the device's screen wake lock,
/// allowing apps to prevent the screen from turning off during activities
/// that require continuous display, such as video playback, reading, or navigation.
///
/// Example usage:
/// ```swift
/// let screenWake = ScreenWake()
///
/// // Check if supported
/// if screenWake.isSupported {
///     // Request wake lock
///     try await screenWake.request()
///     print("Screen will stay awake")
///
///     // ... perform long-running task ...
///
///     // Release wake lock
///     await screenWake.release()
/// }
///
/// // Listen for state changes
/// screenWake.onStateChanged = { state in
///     print("Wake lock state: \(state)")
/// }
/// ```
@MainActor
public final class ScreenWake: Sendable {

    // MARK: - Properties

    /// Current wake lock sentinel
    private var wakeLock: JSObject?

    /// Whether wake lock is currently active
    public private(set) var isActive: Bool = false

    /// Whether wake lock API is supported
    public var isSupported: Bool {
        let navigator = JSObject.global.navigator
        return !navigator.wakeLock.isUndefined
    }

    /// Callback for state changes
    public var onStateChanged: (@Sendable @MainActor (WakeLockState) -> Void)?

    /// Callback for wake lock release (system-initiated)
    public var onReleased: (@Sendable @MainActor (WakeLockReleaseReason) -> Void)?

    // MARK: - Public API

    /// Request screen wake lock
    /// - Parameter type: Type of wake lock (default: screen)
    /// - Throws: WakeLockError if request fails
    public func request(type: WakeLockType = .screen) async throws {
        guard isSupported else {
            throw WakeLockError.notSupported
        }

        // Release existing lock if any
        if isActive {
            await release()
        }

        let navigator = JSObject.global.navigator

        do {
            let requestPromise = navigator.wakeLock.request.function!(type.rawValue)
            let sentinel = try await JSPromise(from: requestPromise)!.getValue()

            wakeLock = sentinel.object
            isActive = true
            updateState(.active)

            // Listen for release event
            setupReleaseListener()
        } catch {
            throw WakeLockError.requestFailed(error.localizedDescription)
        }
    }

    /// Release screen wake lock
    public func release() async {
        guard let lock = wakeLock, isActive else {
            return
        }

        do {
            let releasePromise = lock.release.function!()
            _ = try? await JSPromise(from: releasePromise)?.getValue()

            wakeLock = nil
            isActive = false
            updateState(.released)
        } catch {
            print("⚠️ ScreenWake: Failed to release wake lock: \(error)")
        }
    }

    /// Get wake lock state
    /// - Returns: Current wake lock state
    public func getState() -> WakeLockState {
        isActive ? .active : .released
    }

    // MARK: - Visibility Handling

    /// Set up automatic reacquisition on visibility change
    /// - Parameter enabled: Whether to enable auto-reacquisition
    public func setAutoReacquire(_ enabled: Bool) {
        if enabled {
            setupVisibilityListener()
        } else {
            removeVisibilityListener()
        }
    }

    // MARK: - Private Methods

    /// Set up listener for wake lock release
    private func setupReleaseListener() {
        guard let lock = wakeLock else { return }

        let releaseClosure = JSClosure { [weak self] args -> JSValue in
            Task { @MainActor in
                guard let self = self else { return }

                self.isActive = false
                self.updateState(.released)

                // Determine release reason from event
                let reason = WakeLockReleaseReason.systemReleased
                self.onReleased?(reason)
            }
            return .undefined
        }

        _ = lock.addEventListener!("release", releaseClosure)

        // Store closure to prevent deallocation
        lock.__ravenReleaseClosure = JSValue.object(releaseClosure)
    }

    /// Set up listener for page visibility changes
    private func setupVisibilityListener() {
        let document = JSObject.global.document

        let visibilityHandler = JSClosure { [weak self] _ -> JSValue in
            Task { @MainActor in
                await self?.handleVisibilityChange()
            }
            return .undefined
        }

        _ = document.addEventListener.function!("visibilitychange", visibilityHandler)

        // Store closure
        JSObject.global.__ravenWakeLockVisibilityHandler = JSValue.object(visibilityHandler)
    }

    /// Remove visibility listener
    private func removeVisibilityListener() {
        let document = JSObject.global.document

        if let handler = JSObject.global.__ravenWakeLockVisibilityHandler.object {
            _ = document.removeEventListener.function!("visibilitychange", handler)
            JSObject.global.__ravenWakeLockVisibilityHandler = .undefined
        }
    }

    /// Handle page visibility change
    private func handleVisibilityChange() async {
        let document = JSObject.global.document
        let hidden = document.hidden.boolean ?? false

        if !hidden && !isActive {
            // Page became visible and wake lock is not active, reacquire
            do {
                try await request()
            } catch {
                print("⚠️ ScreenWake: Failed to reacquire wake lock: \(error)")
            }
        }
    }

    /// Update wake lock state and notify listeners
    private func updateState(_ state: WakeLockState) {
        onStateChanged?(state)
    }
}

// MARK: - Supporting Types

/// Wake lock type
public enum WakeLockType: String, Sendable {
    /// Screen wake lock (prevents display from sleeping)
    case screen
}

/// Wake lock state
public enum WakeLockState: String, Sendable {
    /// Wake lock is active
    case active

    /// Wake lock is released
    case released
}

/// Wake lock release reason
public enum WakeLockReleaseReason: Sendable {
    /// User explicitly released
    case userReleased

    /// System released (e.g., page hidden, battery low)
    case systemReleased

    /// Permission denied
    case permissionDenied
}

/// Wake lock errors
public enum WakeLockError: Error, Sendable {
    case notSupported
    case requestFailed(String)
    case alreadyActive
}

// MARK: - Wake Lock Manager

/// Centralized manager for wake lock with automatic lifecycle management
///
/// WakeLockManager provides automatic wake lock management with visibility
/// tracking and error recovery.
@MainActor
public final class WakeLockManager: Sendable {

    // MARK: - Singleton

    public static let shared = WakeLockManager()

    // MARK: - Properties

    private let screenWake: ScreenWake
    private var activeRequests: Set<String> = []

    // MARK: - Initialization

    private init() {
        self.screenWake = ScreenWake()
        #if arch(wasm32)
        setupAutomaticManagement()
        #endif
    }

    // MARK: - Public API

    /// Request wake lock with identifier
    /// - Parameter id: Unique identifier for this request
    /// - Throws: WakeLockError if request fails
    public func request(id: String) async throws {
        activeRequests.insert(id)

        if !screenWake.isActive {
            try await screenWake.request()
        }
    }

    /// Release wake lock for identifier
    /// - Parameter id: Identifier of the request to release
    public func release(id: String) async {
        activeRequests.remove(id)

        // Release wake lock if no active requests
        if activeRequests.isEmpty {
            await screenWake.release()
        }
    }

    /// Release all wake locks
    public func releaseAll() async {
        activeRequests.removeAll()
        await screenWake.release()
    }

    /// Get active request count
    /// - Returns: Number of active requests
    public func getActiveRequestCount() -> Int {
        activeRequests.count
    }

    /// Check if specific request is active
    /// - Parameter id: Request identifier
    /// - Returns: True if request is active
    public func isRequestActive(id: String) -> Bool {
        activeRequests.contains(id)
    }

    /// Check if wake lock is supported
    public var isSupported: Bool {
        screenWake.isSupported
    }

    // MARK: - Private Methods

    /// Set up automatic wake lock management
    private func setupAutomaticManagement() {
        // Enable auto-reacquisition on visibility change
        screenWake.setAutoReacquire(true)

        // Handle release events
        screenWake.onReleased = { [weak self] reason in
            guard let self = self else { return }

            print("⚠️ WakeLockManager: Wake lock released: \(reason)")

            // Try to reacquire if we still have active requests
            if !self.activeRequests.isEmpty {
                Task { @MainActor in
                    do {
                        try await self.screenWake.request()
                    } catch {
                        print("⚠️ WakeLockManager: Failed to reacquire: \(error)")
                    }
                }
            }
        }
    }
}

// MARK: - Scoped Wake Lock

/// Scoped wake lock that automatically releases when deallocated
///
/// ScopedWakeLock provides RAII-style wake lock management, automatically
/// acquiring the lock on creation and releasing it on deallocation.
@MainActor
public final class ScopedWakeLock: Sendable {

    private let id: String
    private let manager: WakeLockManager
    private var isReleased: Bool = false

    /// Initialize and request wake lock
    /// - Throws: WakeLockError if request fails
    public init() async throws {
        self.id = UUID().uuidString
        self.manager = WakeLockManager.shared

        try await manager.request(id: id)
    }

    /// Manually release wake lock
    public func release() async {
        guard !isReleased else { return }

        await manager.release(id: id)
        isReleased = true
    }

    deinit {
        // Note: We can't await in deinit, so we can't guarantee cleanup
        // Users should call release() manually for clean release
        if !isReleased {
            print("⚠️ ScopedWakeLock: Deallocated without explicit release")
        }
    }
}
