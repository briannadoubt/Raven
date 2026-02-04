import Foundation
import JavaScriptKit

// MARK: - Focus Manager

/// Central coordinator for focus management across the application.
///
/// `FocusManager` is a singleton that coordinates focus state between views,
/// manages DOM focus, and handles keyboard navigation. It bridges SwiftUI-style
/// focus state with native DOM focus APIs.
///
/// ## Overview
///
/// The focus manager maintains a registry of focusable elements and their
/// associated focus states. When focus changes in the DOM (via user interaction
/// or keyboard navigation), the manager updates the corresponding SwiftUI state.
/// Conversely, when SwiftUI state changes programmatically, the manager updates
/// DOM focus.
///
/// ## Responsibilities
///
/// - Track focusable elements and their focus state bindings
/// - Synchronize DOM focus with SwiftUI @FocusState
/// - Handle tab order and keyboard navigation
/// - Manage focus scopes for hierarchical focus control
/// - Coordinate with FocusScope for scope-based focus management
@MainActor
public final class FocusManager {
    /// Shared singleton instance
    public static let shared = FocusManager()

    // MARK: - Properties

    /// Registry of focusable elements keyed by their unique ID
    private var focusableElements: [UUID: FocusableElement] = [:]

    /// Registry of focus scopes keyed by their scope ID
    private var focusScopes: [UUID: FocusScope] = [:]

    /// Currently focused element ID
    private var currentFocusedElement: UUID?

    /// Tab order tracking for keyboard navigation
    private var tabOrder: [UUID] = []

    /// Flag to prevent feedback loops during focus updates
    private var isUpdatingFocus = false

    // MARK: - Initialization

    private init() {
        setupGlobalFocusHandlers()
    }

    // MARK: - Focus Registration

    /// Register a focusable element with the focus manager.
    ///
    /// - Parameters:
    ///   - id: Unique identifier for the element
    ///   - element: The focusable element information
    public func registerFocusable(_ id: UUID, element: FocusableElement) {
        focusableElements[id] = element
        rebuildTabOrder()
    }

    /// Unregister a focusable element.
    ///
    /// - Parameter id: Unique identifier of the element to unregister
    public func unregisterFocusable(_ id: UUID) {
        focusableElements.removeValue(forKey: id)

        if currentFocusedElement == id {
            currentFocusedElement = nil
        }

        rebuildTabOrder()
    }

    /// Register a focus scope.
    ///
    /// - Parameters:
    ///   - id: Unique identifier for the scope
    ///   - scope: The focus scope information
    public func registerScope(_ id: UUID, scope: FocusScope) {
        focusScopes[id] = scope
    }

    /// Unregister a focus scope.
    ///
    /// - Parameter id: Unique identifier of the scope to unregister
    public func unregisterScope(_ id: UUID) {
        focusScopes.removeValue(forKey: id)
    }

    // MARK: - Focus Control

    /// Set focus to a specific element.
    ///
    /// - Parameter elementID: The unique identifier of the element to focus
    public func setFocus(to elementID: UUID) {
        guard !isUpdatingFocus else { return }
        guard let element = focusableElements[elementID] else { return }

        isUpdatingFocus = true
        defer { isUpdatingFocus = false }

        // Update DOM focus
        if let nodeID = element.nodeID,
           let domElement = DOMBridge.shared.getNode(id: nodeID) {
            _ = domElement.focus!()
        }

        // Update current focus tracking
        let previousFocus = currentFocusedElement
        currentFocusedElement = elementID

        // Notify previous element it lost focus
        if let previous = previousFocus,
           let previousElement = focusableElements[previous] {
            previousElement.onFocusChange(false)
        }

        // Notify new element it gained focus
        element.onFocusChange(true)
    }

    /// Remove focus from the currently focused element.
    public func clearFocus() {
        guard !isUpdatingFocus else { return }
        guard let current = currentFocusedElement else { return }

        isUpdatingFocus = true
        defer { isUpdatingFocus = false }

        // Blur the DOM element
        if let element = focusableElements[current],
           let nodeID = element.nodeID,
           let domElement = DOMBridge.shared.getNode(id: nodeID) {
            _ = domElement.blur!()
        }

        // Update state
        if let element = focusableElements[current] {
            element.onFocusChange(false)
        }

        currentFocusedElement = nil
    }

    /// Update focus based on @FocusState changes.
    ///
    /// This is called internally when a @FocusState value changes programmatically.
    ///
    /// - Parameters:
    ///   - value: The new focus state value
    ///   - storage: The storage object that changed
    internal func updateFocusFromState<Value: Sendable>(_ value: Value, storage: Any) {
        guard !isUpdatingFocus else { return }

        isUpdatingFocus = true
        defer { isUpdatingFocus = false }

        // Find elements matching this state
        for (id, element) in focusableElements {
            if element.matchesFocusState(value) {
                setFocus(to: id)
                return
            }
        }

        // If no match found and value is "false" or "nil", clear focus
        if let boolValue = value as? Bool, !boolValue {
            clearFocus()
        } else if value is (any OptionalProtocol), (value as? any OptionalProtocol)?.isNil == true {
            clearFocus()
        }
    }

    // MARK: - Tab Order Management

    /// Rebuild the tab order based on current focusable elements.
    private func rebuildTabOrder() {
        // Sort elements by their tab index
        tabOrder = focusableElements
            .filter { $0.value.isFocusable }
            .sorted { lhs, rhs in
                lhs.value.tabIndex < rhs.value.tabIndex
            }
            .map { $0.key }
    }

    /// Move focus to the next element in tab order.
    public func focusNext() {
        guard let current = currentFocusedElement else {
            // Focus the first element
            if let first = tabOrder.first {
                setFocus(to: first)
            }
            return
        }

        guard let currentIndex = tabOrder.firstIndex(of: current) else { return }
        let nextIndex = currentIndex + 1

        if nextIndex < tabOrder.count {
            setFocus(to: tabOrder[nextIndex])
        }
    }

    /// Move focus to the previous element in tab order.
    public func focusPrevious() {
        guard let current = currentFocusedElement else {
            // Focus the last element
            if let last = tabOrder.last {
                setFocus(to: last)
            }
            return
        }

        guard let currentIndex = tabOrder.firstIndex(of: current) else { return }

        if currentIndex > 0 {
            setFocus(to: tabOrder[currentIndex - 1])
        }
    }

    // MARK: - DOM Event Handling

    /// Setup global focus event handlers to track DOM focus changes.
    private func setupGlobalFocusHandlers() {
        // Create closures for focus and blur events
        let focusInClosure = JSClosure { [weak self] args -> JSValue in
            guard let self = self else { return .undefined }

            Task { @MainActor in
                self.handleDOMFocusIn()
            }

            return .undefined
        }

        let focusOutClosure = JSClosure { [weak self] args -> JSValue in
            guard let self = self else { return .undefined }

            Task { @MainActor in
                self.handleDOMFocusOut()
            }

            return .undefined
        }

        // Register global event listeners
        _ = JSObject.global.document.addEventListener("focusin", focusInClosure)
        _ = JSObject.global.document.addEventListener("focusout", focusOutClosure)
    }

    /// Handle DOM focusin events.
    private func handleDOMFocusIn() {
        guard !isUpdatingFocus else { return }

        // Get the currently focused DOM element
        guard let activeElement = JSObject.global.document.activeElement.object else { return }

        // Find the Raven element corresponding to this DOM element
        guard let nodeIDString = activeElement.__ravenNodeID.string,
              let nodeID = UUID(uuidString: nodeIDString) else { return }

        // Find the focusable element with this node ID
        for (id, element) in focusableElements {
            if element.nodeID?.uuidString == nodeID.uuidString {
                isUpdatingFocus = true
                currentFocusedElement = id
                element.onFocusChange(true)
                isUpdatingFocus = false
                break
            }
        }
    }

    /// Handle DOM focusout events.
    private func handleDOMFocusOut() {
        guard !isUpdatingFocus else { return }
        guard let current = currentFocusedElement else { return }

        isUpdatingFocus = true
        if let element = focusableElements[current] {
            element.onFocusChange(false)
        }
        currentFocusedElement = nil
        isUpdatingFocus = false
    }
}

// MARK: - Focusable Element

/// Information about a focusable element.
public struct FocusableElement: Sendable {
    /// Unique identifier for this element
    public let id: UUID

    /// Node ID in the virtual DOM
    public let nodeID: NodeID?

    /// Whether this element is currently focusable
    public let isFocusable: Bool

    /// Tab index for keyboard navigation order
    public let tabIndex: Int

    /// Callback when focus state changes
    public let onFocusChange: @Sendable @MainActor (Bool) -> Void

    /// Focus state matcher for @FocusState synchronization
    private let focusStateMatcher: (@Sendable @MainActor (Any) -> Bool)?

    /// Creates a focusable element.
    ///
    /// - Parameters:
    ///   - id: Unique identifier
    ///   - nodeID: Virtual DOM node ID
    ///   - isFocusable: Whether element can receive focus
    ///   - tabIndex: Tab order index
    ///   - onFocusChange: Callback when focus changes
    ///   - focusStateMatcher: Optional matcher for focus state
    public init(
        id: UUID,
        nodeID: NodeID?,
        isFocusable: Bool = true,
        tabIndex: Int = 0,
        onFocusChange: @escaping @Sendable @MainActor (Bool) -> Void,
        focusStateMatcher: (@Sendable @MainActor (Any) -> Bool)? = nil
    ) {
        self.id = id
        self.nodeID = nodeID
        self.isFocusable = isFocusable
        self.tabIndex = tabIndex
        self.onFocusChange = onFocusChange
        self.focusStateMatcher = focusStateMatcher
    }

    /// Check if this element matches a given focus state value.
    ///
    /// - Parameter value: The focus state value to check
    /// - Returns: True if this element matches the state
    @MainActor
    public func matchesFocusState<Value: Sendable>(_ value: Value) -> Bool {
        guard let matcher = focusStateMatcher else { return false }
        return matcher(value)
    }
}

// MARK: - Optional Protocol Helper

/// Internal protocol to detect optional types
private protocol OptionalProtocol {
    var isNil: Bool { get }
}

extension Optional: OptionalProtocol {
    var isNil: Bool {
        self == nil
    }
}
