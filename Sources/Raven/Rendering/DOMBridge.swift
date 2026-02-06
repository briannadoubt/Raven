import Foundation
import JavaScriptKit

/// Bridge for DOM manipulation and JavaScript interop
///
/// All DOM operations must run on the MainActor since JSObject is not Sendable
/// and all JavaScript interop must happen on the same thread.
@MainActor
public final class DOMBridge {
    public static let shared = DOMBridge()

    // MARK: - Properties

    /// Reference to the JavaScript document object
    private let document: JSObject

    /// Registry of event handlers mapped by UUID
    private var eventHandlers: [UUID: @Sendable @MainActor () -> Void] = [:]

    /// Registry of gesture event handlers that receive event data mapped by UUID
    private var gestureEventHandlers: [UUID: @Sendable @MainActor (JSValue) -> Void] = [:]

    /// Map of NodeID to JSObject for efficient lookups
    private var nodeRegistry: [NodeID: JSObject] = [:]

    /// Global event handler closure for event delegation
    private var eventClosure: JSClosure?

    /// Registry of JSClosures for event handlers (keeps them alive and allows removal)
    private var eventClosures: [UUID: JSClosure] = [:]

    /// Flag to track if event delegation is set up
    private var isEventDelegationSetup = false

    /// Render generation counter - incremented on each clearRegistry()
    /// JSClosures capture their creation generation and bail out if stale
    private var renderGeneration: UInt64 = 0

    // MARK: - Initialization

    private init() {
        guard let doc = JSObject.global.document.object else {
            fatalError("DOM not available - ensure DOMBridge runs in browser context")
        }
        self.document = doc
    }

    // MARK: - Event Delegation Setup

    private func setupEventDelegation() {
        guard !isEventDelegationSetup else { return }
        isEventDelegationSetup = true
        // Create a global event handler that delegates to registered handlers
        let closure = JSClosure { [weak self] args -> JSValue in
            guard let self = self,
                  args.count > 0,
                  let handlerIDString = args[0].string,
                  let handlerID = UUID(uuidString: handlerIDString) else {
                return .undefined
            }

            Task { @MainActor in
                self.invokeHandler(handlerID)
            }

            return .undefined
        }

        self.eventClosure = closure

        // Store the closure globally so JavaScript can access it
        JSObject.global.__ravenEventHandler = .object(closure)
    }

    /// Invoke a registered event handler
    private func invokeHandler(_ handlerID: UUID) {
        guard let handler = eventHandlers[handlerID] else {
            return
        }

        handler()
    }

    /// Invoke a registered gesture event handler with event data
    private func invokeGestureHandler(_ handlerID: UUID, event: JSValue) {
        guard let handler = gestureEventHandlers[handlerID] else {
            return
        }

        handler(event)
    }

    // MARK: - Core DOM Operations

    /// Create a new DOM element with the specified tag name
    public func createElement(tag: String) -> JSObject? {
        // Call method directly on document to preserve 'this' binding
        let result = document.createElement!(tag)
        return result.isNull || result.isUndefined ? nil : result.object
    }

    /// Create a text node with the specified content
    public func createTextNode(text: String) -> JSObject? {
        // Call method directly on document to preserve 'this' binding
        let result = document.createTextNode!(text)
        return result.isNull || result.isUndefined ? nil : result.object
    }

    /// Set an attribute on a DOM element
    public func setAttribute(element: JSObject, name: String, value: String) {
        // Call method directly on element to preserve 'this' binding
        _ = element.setAttribute!(name, value)
    }

    /// Remove an attribute from a DOM element
    public func removeAttribute(element: JSObject, name: String) {
        // Call method directly on element to preserve 'this' binding
        _ = element.removeAttribute!(name)
    }

    /// Set a style property on a DOM element
    public func setStyle(element: JSObject, name: String, value: String) {
        // Use setProperty() for reliable CSS property setting (supports hyphenated names)
        _ = element.style.setProperty(name, value)
    }

    /// Remove a style property from a DOM element
    public func removeStyle(element: JSObject, name: String) {
        _ = element.style.removeProperty(name)
    }

    /// Append a child node to a parent element
    public func appendChild(parent: JSObject, child: JSObject) {
        // Call method directly on parent to preserve 'this' binding
        _ = parent.appendChild!(child)
    }

    /// Remove a child node from a parent element
    public func removeChild(parent: JSObject, child: JSObject) {
        // Call method directly on parent to preserve 'this' binding
        _ = parent.removeChild!(child)
    }

    /// Clear all children from an element
    public func clearChildren(_ element: JSObject) {
        // Use innerHTML = "" to clear all children efficiently
        element.innerHTML = .string("")
    }

    /// Replace an old child node with a new one
    public func replaceChild(parent: JSObject, old: JSObject, new: JSObject) {
        // Call method directly on parent to preserve 'this' binding
        _ = parent.replaceChild!(new, old)
    }

    /// Insert a new node before a reference node
    public func insertBefore(parent: JSObject, new: JSObject, reference: JSObject?) {
        // Call method directly on parent to preserve 'this' binding
        if let reference = reference {
            _ = parent.insertBefore!(new, reference)
        } else {
            _ = parent.appendChild!(new)
        }
    }

    /// Set the text content of a DOM node
    public func setTextContent(element: JSObject, text: String) {
        element.textContent = .string(text)
    }

    /// Get the text content of a DOM node
    public func getTextContent(element: JSObject) -> String? {
        element.textContent.string
    }

    // MARK: - Event Handling

    /// Add an event listener to a DOM element
    public func addEventListener(
        element: JSObject,
        event: String,
        handlerID: UUID,
        handler: @escaping @Sendable @MainActor () -> Void
    ) {
        // Ensure event delegation is set up
        setupEventDelegation()

        // Store the handler in the registry FIRST
        eventHandlers[handlerID] = handler

        // Capture current render generation to detect stale closures
        let creationGeneration = self.renderGeneration
        let jsClosure = JSClosure { [weak self] _ in
            guard let self = self else { return .undefined }
            // Check generation - if mismatched, this closure is from a previous render
            guard self.renderGeneration == creationGeneration else {
                return .undefined
            }
            guard let handler = self.eventHandlers[handlerID] else {
                return .undefined
            }
            handler()
            return .undefined
        }

        // Store the closure in our registry to keep it alive
        eventClosures[handlerID] = jsClosure

        // Use JavaScript helper to add event listener with proper 'this' binding
        let helperValue = JSObject.global.__ravenAddEventListener
        if helperValue.isUndefined || helperValue.isNull {
            print("Warning: __ravenAddEventListener helper not available")
            return
        }
        // Call the helper function directly through dynamic member
        let result = JSObject.global.__ravenAddEventListener!(element, event, jsClosure)
        if result.boolean == false {
            print("Warning: addEventListener failed for event: \(event)")
        }
    }

    /// Remove an event listener from a DOM element
    public func removeEventListener(
        element: JSObject,
        event: String,
        handlerID: UUID
    ) {
        // Remove from registries
        eventHandlers.removeValue(forKey: handlerID)

        // Get the closure and remove the listener
        guard let jsClosure = eventClosures.removeValue(forKey: handlerID) else {
            return
        }

        // Use JavaScript helper to remove event listener
        let helperValue = JSObject.global.__ravenRemoveEventListener
        if !helperValue.isUndefined && !helperValue.isNull {
            _ = JSObject.global.__ravenRemoveEventListener!(element, event, jsClosure)
        }
    }

    /// Remove all event listeners from a DOM element
    public func removeAllEventListeners(element: JSObject) {
        // Clean up all closures for this element
        // Note: We don't have a way to map element -> handler IDs efficiently,
        // so this is a simplified version that clears all handlers
        eventHandlers.removeAll()
        gestureEventHandlers.removeAll()
        eventClosures.removeAll()
    }

    /// Add a gesture event listener that receives event data
    public func addGestureEventListener(
        element: JSObject,
        event: String,
        handlerID: UUID,
        handler: @escaping @Sendable @MainActor (JSValue) -> Void
    ) {
        // Ensure event delegation is set up
        setupEventDelegation()

        // Store the handler
        gestureEventHandlers[handlerID] = handler

        // Capture current render generation to detect stale closures
        let creationGeneration = self.renderGeneration
        let jsClosure = JSClosure { [weak self] args -> JSValue in
            guard let self = self, args.count > 0 else {
                return .undefined
            }
            // Check generation - if mismatched, this closure is from a previous render
            guard self.renderGeneration == creationGeneration else {
                return .undefined
            }

            let event = args[0]
            // Call handler synchronously - Task{} doesn't execute in WASM event loop
            handler(event)

            return .undefined
        }

        // Store the closure in our registry to keep it alive
        eventClosures[handlerID] = jsClosure

        // Use JavaScript helper to add event listener with proper 'this' binding
        let helperValue = JSObject.global.__ravenAddEventListener
        if helperValue.isUndefined || helperValue.isNull {
            print("Warning: __ravenAddEventListener helper not available")
            return
        }
        // Call the helper function directly through dynamic member
        let result = JSObject.global.__ravenAddEventListener!(element, event, jsClosure)
        if result.boolean == false {
            print("Warning: addGestureEventListener failed for event: \(event)")
        }
    }

    // MARK: - Node Tracking

    /// Register a DOM node with a NodeID for efficient lookups
    public func registerNode(id: NodeID, element: JSObject) {
        nodeRegistry[id] = element
        // Note: We no longer store NodeID on the element to avoid dynamic member access issues
    }

    /// Unregister a DOM node
    public func unregisterNode(id: NodeID) {
        if let element = nodeRegistry[id] {
            removeAllEventListeners(element: element)
        }
        nodeRegistry.removeValue(forKey: id)
    }

    /// Get a registered DOM node by ID
    public func getNode(id: NodeID) -> JSObject? {
        nodeRegistry[id]
    }

    /// Get all registered node IDs
    public func getRegisteredNodeIDs() -> [NodeID] {
        Array(nodeRegistry.keys)
    }

    /// Clear all registered nodes and invalidate stale closures
    public func clearRegistry() {
        // Increment generation FIRST so any in-flight closures become stale
        renderGeneration += 1
        for (_, element) in nodeRegistry {
            removeAllEventListeners(element: element)
        }
        nodeRegistry.removeAll()
        eventHandlers.removeAll()
        gestureEventHandlers.removeAll()
        eventClosures.removeAll()
    }

    // MARK: - Incremental Handler Updates

    /// Update the Swift closure for an existing click/action handler without
    /// re-creating the JSClosure or DOM event listener.
    /// The JSClosure looks up ``eventHandlers[id]`` on each invocation, so
    /// swapping the entry is sufficient.
    public func updateEventHandler(id: UUID, handler: @escaping @Sendable @MainActor () -> Void) {
        eventHandlers[id] = handler
    }

    /// Update the Swift closure for an existing input/gesture handler.
    public func updateInputEventHandler(id: UUID, handler: @escaping @Sendable @MainActor (JSValue) -> Void) {
        gestureEventHandlers[id] = handler
    }

    /// Remove a single handler and its JSClosure.
    /// Called for handlers that were active in the previous render but are no
    /// longer present in the current render.
    public func cleanupStaleHandler(id: UUID) {
        eventHandlers.removeValue(forKey: id)
        gestureEventHandlers.removeValue(forKey: id)
        eventClosures.removeValue(forKey: id)
    }

    // MARK: - Query Methods

    /// Query the DOM for an element by ID
    public func getElementById(_ id: String) -> JSObject? {
        // Call method directly on document to preserve 'this' binding
        let result = document.getElementById!(id)
        return result.isNull || result.isUndefined ? nil : result.object
    }

    /// Query the DOM for elements by selector
    public func querySelector(_ selector: String) -> JSObject? {
        // Call method directly on document to preserve 'this' binding
        let result = document.querySelector!(selector)
        return result.isNull || result.isUndefined ? nil : result.object
    }

    /// Query the DOM for all elements matching a selector
    public func querySelectorAll(_ selector: String) -> [JSObject] {
        // Call method directly on document to preserve 'this' binding
        let nodeList = document.querySelectorAll!(selector)
        let length = nodeList.length.number ?? 0

        var elements: [JSObject] = []
        for i in 0..<Int(length) {
            if let element = nodeList[i].object {
                elements.append(element)
            }
        }

        return elements
    }

    // MARK: - Body Access

    /// Get the document body element
    public func getBody() -> JSObject? {
        let body = document.body
        return body.isNull || body.isUndefined ? nil : body.object
    }

    /// Get the document head element
    public func getHead() -> JSObject? {
        let head = document.head
        return head.isNull || head.isUndefined ? nil : head.object
    }
}

