import Foundation
import JavaScriptKit

/// Manages app badge notifications for installed PWAs
///
/// AppBadge provides control over the app icon badge, allowing apps to
/// display unread counts or notification indicators on the installed app icon.
///
/// Example usage:
/// ```swift
/// let appBadge = AppBadge()
///
/// // Set badge count
/// do {
///     try await appBadge.set(count: 5)
///     print("Badge set to 5")
/// } catch {
///     print("Failed to set badge: \(error)")
/// }
///
/// // Clear badge
/// try await appBadge.clear()
///
/// // Check if badge is supported
/// if appBadge.isSupported {
///     print("Badge API is supported")
/// }
/// ```
@MainActor
public final class AppBadge: Sendable {

    // MARK: - Properties

    /// Whether the Badge API is supported
    public var isSupported: Bool {
        let navigator = JSObject.global.navigator
        return !navigator.setAppBadge.isUndefined
    }

    /// Current badge count (cached)
    private var currentCount: Int = 0

    // MARK: - Public API

    /// Set the app badge to a specific count
    /// - Parameter count: Badge count (0 or higher)
    /// - Throws: BadgeError if operation fails
    public func set(count: Int) async throws {
        guard isSupported else {
            throw BadgeError.notSupported
        }

        guard count >= 0 else {
            throw BadgeError.invalidCount
        }

        let navigator = JSObject.global.navigator

        do {
            if count == 0 {
                // Clear badge when count is 0
                let clearPromise = navigator.clearAppBadge.function!()
                _ = try await JSPromise(from: clearPromise)!.getValue()
            } else {
                // Set badge to count
                let setBadgePromise = navigator.setAppBadge.function!(count)
                _ = try await JSPromise(from: setBadgePromise)!.getValue()
            }

            currentCount = count
        } catch {
            throw BadgeError.operationFailed(error.localizedDescription)
        }
    }

    /// Clear the app badge
    /// - Throws: BadgeError if operation fails
    public func clear() async throws {
        guard isSupported else {
            throw BadgeError.notSupported
        }

        let navigator = JSObject.global.navigator

        do {
            let clearPromise = navigator.clearAppBadge.function!()
            _ = try await JSPromise(from: clearPromise)!.getValue()
            currentCount = 0
        } catch {
            throw BadgeError.operationFailed(error.localizedDescription)
        }
    }

    /// Increment the badge count
    /// - Parameter by: Amount to increment by (default: 1)
    /// - Throws: BadgeError if operation fails
    public func increment(by amount: Int = 1) async throws {
        try await set(count: currentCount + amount)
    }

    /// Decrement the badge count
    /// - Parameter by: Amount to decrement by (default: 1)
    /// - Throws: BadgeError if operation fails
    public func decrement(by amount: Int = 1) async throws {
        let newCount = max(0, currentCount - amount)
        try await set(count: newCount)
    }

    /// Get the current cached badge count
    /// - Returns: Current badge count
    public func getCurrentCount() -> Int {
        currentCount
    }

    /// Reset badge to initial state
    public func reset() async throws {
        try await clear()
    }
}

// MARK: - Supporting Types

/// Errors that can occur with badge operations
public enum BadgeError: Error, Sendable {
    /// Badge API is not supported
    case notSupported

    /// Invalid badge count provided
    case invalidCount

    /// Operation failed with error message
    case operationFailed(String)
}

// MARK: - Badge Manager

/// Centralized manager for app badge state across the application
///
/// BadgeManager provides a singleton for managing badge state and coordinating
/// badge updates from different parts of the application.
@MainActor
public final class BadgeManager: Sendable {

    // MARK: - Singleton

    public static let shared = BadgeManager()

    // MARK: - Properties

    private let badge: AppBadge
    private var counters: [String: Int] = [:]

    // MARK: - Initialization

    private init() {
        self.badge = AppBadge()
    }

    // MARK: - Public API

    /// Update a specific counter and refresh badge
    /// - Parameters:
    ///   - key: Counter identifier
    ///   - count: New count for this counter
    public func updateCounter(key: String, count: Int) async throws {
        counters[key] = count
        try await refreshBadge()
    }

    /// Increment a specific counter
    /// - Parameters:
    ///   - key: Counter identifier
    ///   - by: Amount to increment (default: 1)
    public func incrementCounter(key: String, by amount: Int = 1) async throws {
        let current = counters[key] ?? 0
        counters[key] = current + amount
        try await refreshBadge()
    }

    /// Decrement a specific counter
    /// - Parameters:
    ///   - key: Counter identifier
    ///   - by: Amount to decrement (default: 1)
    public func decrementCounter(key: String, by amount: Int = 1) async throws {
        let current = counters[key] ?? 0
        counters[key] = max(0, current - amount)
        try await refreshBadge()
    }

    /// Clear a specific counter
    /// - Parameter key: Counter identifier
    public func clearCounter(key: String) async throws {
        counters.removeValue(forKey: key)
        try await refreshBadge()
    }

    /// Clear all counters
    public func clearAllCounters() async throws {
        counters.removeAll()
        try await badge.clear()
    }

    /// Get count for a specific counter
    /// - Parameter key: Counter identifier
    /// - Returns: Count for the counter
    public func getCounter(key: String) -> Int {
        counters[key] ?? 0
    }

    /// Get total count across all counters
    /// - Returns: Sum of all counter values
    public func getTotalCount() -> Int {
        counters.values.reduce(0, +)
    }

    /// Get all counters
    /// - Returns: Dictionary of all counters
    public func getAllCounters() -> [String: Int] {
        counters
    }

    /// Check if badge API is supported
    public var isSupported: Bool {
        badge.isSupported
    }

    // MARK: - Private Methods

    /// Refresh the badge with the sum of all counters
    private func refreshBadge() async throws {
        let total = getTotalCount()
        try await badge.set(count: total)
    }
}
