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

    /// Flag to track if event delegation is set up
    private var isEventDelegationSetup = false

    // MARK: - Initialization

    private init() {
        self.document = JSObject.global.document.object!
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
    public func createElement(tag: String) -> JSObject {
        document.createElement!(tag).object!
    }

    /// Create a text node with the specified content
    public func createTextNode(text: String) -> JSObject {
        document.createTextNode!(text).object!
    }

    /// Set an attribute on a DOM element
    public func setAttribute(element: JSObject, name: String, value: String) {
        _ = element.setAttribute!(name, value)
    }

    /// Remove an attribute from a DOM element
    public func removeAttribute(element: JSObject, name: String) {
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
        _ = parent.appendChild!(child)
    }

    /// Remove a child node from a parent element
    public func removeChild(parent: JSObject, child: JSObject) {
        _ = parent.removeChild!(child)
    }

    /// Replace an old child node with a new one
    public func replaceChild(parent: JSObject, old: JSObject, new: JSObject) {
        _ = parent.replaceChild!(new, old)
    }

    /// Insert a new node before a reference node
    public func insertBefore(parent: JSObject, new: JSObject, reference: JSObject?) {
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

        // Create an inline event handler that calls our global handler
        let handlerScript = """
        function(e) {
            if (window.__ravenEventHandler) {
                window.__ravenEventHandler('\(handlerID.uuidString)');
            }
        }
        """

        // Create a JavaScript function from the script
        let jsHandler = JSObject.global.Function.function!("e", "return \(handlerScript)")
        let boundHandler = jsHandler.new()

        // Add the event listener
        _ = element.addEventListener!(event, boundHandler)

        // Store the bound handler on the element for cleanup
        if element.__ravenHandlers.isUndefined {
            element.__ravenHandlers = .object(JSObject.global.Object.function!.new())
        }
        element.__ravenHandlers[dynamicMember: handlerID.uuidString] = boundHandler
    }

    /// Remove an event listener from a DOM element
    public func removeEventListener(
        element: JSObject,
        event: String,
        handlerID: UUID
    ) {
        // Remove from registry
        eventHandlers.removeValue(forKey: handlerID)

        // Remove the DOM event listener
        if let boundHandler = element.__ravenHandlers[dynamicMember: handlerID.uuidString].object {
            _ = element.removeEventListener!(event, boundHandler)
            element.__ravenHandlers[dynamicMember: handlerID.uuidString] = .undefined
        }
    }

    /// Remove all event listeners from a DOM element
    public func removeAllEventListeners(element: JSObject) {
        guard let handlers = element.__ravenHandlers.object else {
            return
        }

        // Get all handler IDs
        let keys = JSObject.global.Object.keys(handlers)
        let length = keys.length.number ?? 0

        for i in 0..<Int(length) {
            if let handlerIDString = keys[i].string,
               let handlerID = UUID(uuidString: handlerIDString) {
                eventHandlers.removeValue(forKey: handlerID)
                gestureEventHandlers.removeValue(forKey: handlerID)
            }
        }

        // Clear the handlers object
        element.__ravenHandlers = .undefined
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

        // Create an inline event handler that calls our global handler with event data
        // We need to store a reference to the handler that can be called with the event
        let handlerScript = """
        function(e) {
            if (window.__ravenGestureEventHandler_\(handlerID.uuidString)) {
                window.__ravenGestureEventHandler_\(handlerID.uuidString)(e);
            }
        }
        """

        // Create a JavaScript closure that can receive the event
        let closure = JSClosure { [weak self] args -> JSValue in
            guard let self = self, args.count > 0 else {
                return .undefined
            }

            let event = args[0]
            Task { @MainActor in
                self.invokeGestureHandler(handlerID, event: event)
            }

            return .undefined
        }

        // Store the closure globally
        JSObject.global[dynamicMember: "__ravenGestureEventHandler_\(handlerID.uuidString)"] = .object(closure)

        // Create a JavaScript function from the script
        let jsHandler = JSObject.global.Function.function!("e", "return \(handlerScript)")
        let boundHandler = jsHandler.new()

        // Add the event listener
        _ = element.addEventListener!(event, boundHandler)

        // Store the bound handler on the element for cleanup
        if element.__ravenHandlers.isUndefined {
            element.__ravenHandlers = .object(JSObject.global.Object.function!.new())
        }
        element.__ravenHandlers[dynamicMember: handlerID.uuidString] = boundHandler
    }

    // MARK: - Node Tracking

    /// Register a DOM node with a NodeID for efficient lookups
    public func registerNode(id: NodeID, element: JSObject) {
        nodeRegistry[id] = element

        // Store the NodeID on the element for debugging
        element.__ravenNodeID = .string(id.uuidString)
    }

    /// Unregister a DOM node
    public func unregisterNode(id: NodeID) {
        if let element = nodeRegistry[id] {
            element.__ravenNodeID = .undefined
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
            element.__ravenNodeID = .undefined
        }
        nodeRegistry.removeAll()
        eventHandlers.removeAll()
        gestureEventHandlers.removeAll()
    }

    // MARK: - Query Methods

    /// Query the DOM for an element by ID
    public func getElementById(_ id: String) -> JSObject? {
        let result = document.getElementById!(id)
        return result.isNull || result.isUndefined ? nil : result.object
    }

    /// Query the DOM for elements by selector
    public func querySelector(_ selector: String) -> JSObject? {
        let result = document.querySelector!(selector)
        return result.isNull || result.isUndefined ? nil : result.object
    }

    /// Query the DOM for all elements matching a selector
    public func querySelectorAll(_ selector: String) -> [JSObject] {
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

