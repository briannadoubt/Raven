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
        element.style[dynamicMember: name] = .string(value)
    }

    /// Remove a style property from a DOM element
    public func removeStyle(element: JSObject, name: String) {
        element.style[dynamicMember: name] = .string("")
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

        // Store the handler
        eventHandlers[handlerID] = handler

        // Create JSClosure for the event handler (safe, no dynamic member access)
        let jsClosure = JSClosure { _ in
            Task { @MainActor in
                handler()
            }
            return .undefined
        }

        // Store the closure in our registry to keep it alive
        eventClosures[handlerID] = jsClosure

        // Add the event listener using call to preserve 'this' binding
        // We need to use JavaScript's call method to ensure 'this' is the element
        let console = JSObject.global.console
        if let addEventListenerFn = element.addEventListener.function {
            // Call the function with the element as 'this'
            if let call = addEventListenerFn.call.function {
                _ = call(element, event, jsClosure)
                _ = console.log("[Swift] addEventListener called for event: \(event)")
            } else {
                _ = console.log("[Swift] Warning: call method not available")
            }
        } else {
            _ = console.log("[Swift] Warning: addEventListener not available on element")
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

        // Remove the DOM event listener - extract the function and call it
        if let removeEventListenerFn = element.removeEventListener.function {
            _ = removeEventListenerFn(event, jsClosure)
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

        // Create JSClosure for the gesture event handler (safe, no dynamic member access)
        let jsClosure = JSClosure { [weak self] args -> JSValue in
            guard let self = self, args.count > 0 else {
                return .undefined
            }

            let event = args[0]
            Task { @MainActor in
                handler(event)
            }

            return .undefined
        }

        // Store the closure in our registry to keep it alive
        eventClosures[handlerID] = jsClosure

        // Add the event listener using the closure directly
        _ = element.addEventListener!(event, jsClosure)
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

    /// Clear all registered nodes
    public func clearRegistry() {
        for (_, element) in nodeRegistry {
            removeAllEventListeners(element: element)
        }
        nodeRegistry.removeAll()
        eventHandlers.removeAll()
        gestureEventHandlers.removeAll()
        eventClosures.removeAll()
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

