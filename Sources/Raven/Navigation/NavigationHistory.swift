import Foundation
import JavaScriptKit

/// Wrapper for the browser's HTML5 History API.
///
/// `NavigationHistory` provides Swift-friendly access to browser history operations
/// including push state, replace state, and listening to popstate events.
///
/// ## Overview
///
/// The History API allows web applications to manipulate the browser's session history,
/// enabling proper back/forward button support and URL-based navigation.
///
/// ## Basic Usage
///
/// ```swift
/// let history = NavigationHistory.shared
///
/// // Push a new state
/// history.pushState(path: "/products/123", state: ["id": "123"])
///
/// // Listen for back/forward navigation
/// history.onPopState { state in
///     // Handle navigation
/// }
/// ```
///
/// ## Browser Integration
///
/// This class integrates with the browser's `window.history` object via JavaScriptKit.
/// All operations run on the main actor to ensure thread safety with JavaScript interop.
@MainActor
public final class NavigationHistory {
    // MARK: - Singleton

    /// Shared instance for accessing navigation history
    public static let shared = NavigationHistory()

    // MARK: - Properties

    /// Reference to the browser's history object
    private let history: JSObject

    /// Reference to the browser's window object
    private let window: JSObject

    /// Closure to invoke when popstate event occurs
    private var popStateHandler: (@Sendable @MainActor (HistoryState) -> Void)?

    /// JavaScript closure for popstate events
    private var popStateClosure: JSClosure?

    /// Current history state
    private var currentState: HistoryState?

    // MARK: - Initialization

    private init() {
        self.window = JSObject.global.window.object!
        self.history = window.history.object!
        setupPopStateListener()
    }

    // MARK: - History Operations

    /// Pushes a new state onto the history stack.
    ///
    /// This creates a new entry in the browser's history, allowing the user to
    /// navigate back to the previous state using the back button.
    ///
    /// - Parameters:
    ///   - path: The URL path to display (without the origin)
    ///   - state: Optional state data to associate with this history entry
    ///   - title: Optional title (mostly ignored by browsers, use empty string)
    public func pushState(
        path: String,
        state: [String: String] = [:],
        title: String = ""
    ) {
        let historyState = HistoryState(path: path, data: state)
        currentState = historyState

        // Convert state to JavaScript object
        let jsState = createJSState(from: historyState)

        // Call history.pushState(state, title, url)
        _ = history.pushState!(jsState, title, path)
    }

    /// Replaces the current history state.
    ///
    /// This modifies the current history entry without creating a new one.
    /// Useful for updating URL parameters without adding to the history stack.
    ///
    /// - Parameters:
    ///   - path: The URL path to display (without the origin)
    ///   - state: Optional state data to associate with this history entry
    ///   - title: Optional title (mostly ignored by browsers, use empty string)
    public func replaceState(
        path: String,
        state: [String: String] = [:],
        title: String = ""
    ) {
        let historyState = HistoryState(path: path, data: state)
        currentState = historyState

        // Convert state to JavaScript object
        let jsState = createJSState(from: historyState)

        // Call history.replaceState(state, title, url)
        _ = history.replaceState!(jsState, title, path)
    }

    /// Navigates back in history.
    ///
    /// Equivalent to the browser's back button.
    public func back() {
        _ = history.back!()
    }

    /// Navigates forward in history.
    ///
    /// Equivalent to the browser's forward button.
    public func forward() {
        _ = history.forward!()
    }

    /// Navigates to a specific position in history.
    ///
    /// - Parameter delta: The number of steps to move (negative for backward, positive for forward)
    public func go(_ delta: Int) {
        _ = history.go!(delta)
    }

    // MARK: - State Access

    /// Gets the current history state.
    ///
    /// - Returns: The current history state, or nil if none exists
    public func getCurrentState() -> HistoryState? {
        // Try to read from browser's history.state
        let jsState = history.state
        if jsState.isNull || jsState.isUndefined {
            return currentState
        }

        return parseJSState(jsState)
    }

    /// Gets the current URL path.
    ///
    /// - Returns: The current URL path from window.location.pathname
    public func getCurrentPath() -> String {
        let location = window.location.object!
        return location.pathname.string ?? "/"
    }

    // MARK: - PopState Listener

    /// Sets up the popstate event listener.
    ///
    /// The popstate event fires when the user navigates using browser
    /// back/forward buttons or when `go()` is called.
    private func setupPopStateListener() {
        let closure = JSClosure { [weak self] args -> JSValue in
            guard let self = self else { return .undefined }

            Task { @MainActor in
                // Extract state from the event
                var state: HistoryState?
                if args.count > 0,
                   let event = args[0].object,
                   !event.state.isNull && !event.state.isUndefined {
                    state = self.parseJSState(event.state)
                }

                // If no state, create one from current URL
                if state == nil {
                    let currentPath = self.getCurrentPath()
                    state = HistoryState(path: currentPath, data: [:])
                }

                if let state = state {
                    self.currentState = state
                    self.popStateHandler?(state)
                }
            }

            return .undefined
        }

        self.popStateClosure = closure

        // Add event listener
        _ = window.addEventListener?("popstate", closure)
    }

    /// Sets the handler for popstate events.
    ///
    /// This handler is called when the user navigates using browser back/forward
    /// buttons or when programmatic navigation occurs via `go()`.
    ///
    /// - Parameter handler: Closure to invoke with the new history state
    public func onPopState(_ handler: @escaping @Sendable @MainActor (HistoryState) -> Void) {
        self.popStateHandler = handler
    }

    // MARK: - JavaScript Conversion

    /// Converts a HistoryState to a JavaScript object.
    private func createJSState(from state: HistoryState) -> JSObject {
        let jsObject = JSObject.global.Object.function!.new()
        jsObject.__ravenPath = .string(state.path)

        // Convert data dictionary
        if !state.data.isEmpty {
            let dataObject = JSObject.global.Object.function!.new()
            for (key, value) in state.data {
                dataObject[dynamicMember: key] = .string(value)
            }
            jsObject.__ravenData = .object(dataObject)
        }

        return jsObject
    }

    /// Parses a JavaScript state object into a HistoryState.
    private func parseJSState(_ jsState: JSValue) -> HistoryState? {
        guard let jsObject = jsState.object else { return nil }

        let path = jsObject.__ravenPath.string ?? getCurrentPath()
        var data: [String: String] = [:]

        // Extract data if present
        if let dataObject = jsObject.__ravenData.object {
            let keys = JSObject.global.Object.keys(dataObject)
            let length = keys.length.number ?? 0

            for i in 0..<Int(length) {
                if let key = keys[i].string,
                   let value = dataObject[dynamicMember: key].string {
                    data[key] = value
                }
            }
        }

        return HistoryState(path: path, data: data)
    }

    // MARK: - Cleanup

    deinit {
        // Remove event listener if needed
        // Note: We can't call removeEventListener in deinit as it requires MainActor isolation
        // The closure will be cleaned up by garbage collection
        // In a production system, consider using a separate cleanup method
    }
}

// MARK: - History State

/// Represents a state in the browser's history.
///
/// Each history entry can have an associated path and arbitrary data.
@MainActor
public struct HistoryState: Sendable {
    /// The URL path for this history entry
    public let path: String

    /// Associated data for this history entry
    public let data: [String: String]

    /// Creates a history state.
    ///
    /// - Parameters:
    ///   - path: The URL path
    ///   - data: Associated data dictionary
    public init(path: String, data: [String: String] = [:]) {
        self.path = path
        self.data = data
    }
}

// MARK: - CustomStringConvertible

extension HistoryState: @preconcurrency CustomStringConvertible {
    @MainActor
    public var description: String {
        if data.isEmpty {
            return "HistoryState(path: \(path))"
        } else {
            let dataDesc = data.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
            return "HistoryState(path: \(path), data: [\(dataDesc)])"
        }
    }
}
