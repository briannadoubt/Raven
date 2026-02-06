import Foundation
import Raven
import JavaScriptKit

/// Main actor-isolated coordinator responsible for managing the render loop
/// and virtual DOM tree updates.
///
/// The RenderCoordinator is the central component that:
/// - Converts SwiftUI-style Views into VNodes
/// - Maintains the current VTree
/// - Batches and schedules updates
/// - Coordinates with DOMBridge for actual DOM manipulation
/// - Uses Differ to compute efficient patches
@MainActor
public final class RenderCoordinator: Sendable, _RenderContext {
    // MARK: - Properties

    /// Current virtual DOM tree
    private var currentTree: VTree?

    /// Root container element in the DOM
    private var rootContainer: JSObject?

    /// Differ instance for computing patches
    private let differ: Differ

    /// Flag indicating whether an update is already scheduled
    private var updatePending: Bool = false

    /// Queue of pending updates to batch together
    private var pendingUpdates: [() -> Void] = []

    /// Event handler registry mapping UUIDs to action closures
    private var eventHandlerRegistry: [UUID: @Sendable @MainActor () -> Void] = [:]

    /// Input event handler registry for handlers that need DOM event data (e.g., TextField)
    private var inputEventHandlerRegistry: [UUID: @Sendable @MainActor (JSValue) -> Void] = [:]

    /// Gesture handler registry for tracking gesture state
    private var gestureHandlerRegistry: [UUID: @Sendable @MainActor (Any) -> Void] = [:]

    /// Gesture state tracking for ongoing gestures
    private var gestureStates: [UUID: Any] = [:]

    /// Drag gesture state tracking
    private var dragGestureStates: [UUID: DragGestureState] = [:]

    /// Map of DOM element IDs to their associated gesture handler IDs and priorities
    private var elementGestureMap: [String: [(handlerID: UUID, priority: GesturePriority)]] = [:]

    /// Track which gestures have been recognized (for priority conflict resolution)
    private var recognizedGestures: Set<UUID> = []

    /// Stored reference to the current root view for re-rendering
    /// This is a type-erased closure that re-renders the current view
    private var rerenderClosure: (@MainActor () -> Void)?

    /// Counter for generating unique handler IDs (UUID doesn't work reliably in WASM)
    private var handlerIDCounter: UInt64 = 0

    /// Guard against reentrant renders (e.g., from stale event handlers firing during mount)
    private var isRendering: Bool = false

    // MARK: - Initialization

    /// Initialize the render coordinator
    public init() {
        self.differ = Differ()
    }

    /// Generate a unique handler ID
    private func generateHandlerID() -> UUID {
        handlerIDCounter += 1
        // String.format() is broken in WASM, so use manual hex conversion
        let highHex = String(handlerIDCounter >> 32, radix: 16, uppercase: false)
        let lowHex = String(handlerIDCounter & 0xFFFFFFFF, radix: 16, uppercase: false)
        let high = String(repeating: "0", count: max(0, 8 - highHex.count)) + highHex
        let low = String(repeating: "0", count: max(0, 12 - lowHex.count)) + lowHex
        let uuidString = "\(high)-0000-4000-8000-\(low)"
        return UUID(uuidString: uuidString) ?? UUID()
    }

    // MARK: - _RenderContext Conformance

    /// Recursively convert a child view into its VNode representation.
    public func renderChild(_ view: any View) -> VNode {
        return convertViewToVNode(view)
    }

    /// Register a click/action handler and return its unique ID.
    public func registerClickHandler(_ action: @escaping @Sendable @MainActor () -> Void) -> UUID {
        let id = generateHandlerID()
        eventHandlerRegistry[id] = action
        return id
    }

    /// Register an input handler that receives the raw DOM event and return its unique ID.
    public func registerInputHandler(_ handler: @escaping @Sendable @MainActor (JSValue) -> Void) -> UUID {
        let id = generateHandlerID()
        inputEventHandlerRegistry[id] = handler
        return id
    }

    // MARK: - Public API

    /// Main entry point for rendering a view
    /// - Parameter view: SwiftUI-style view to render
    public func render<V: View>(view: V) {
        // Create a mutable copy for state setup
        var mutableView = view

        // Set up state update callbacks
        setupStateCallbacks(&mutableView)

        // Store a re-render closure that captures the view
        rerenderClosure = { [weak self] in
            guard let self = self else { return }
            // Re-render with the current view state
            self.internalRender(view: mutableView)
        }

        // Perform initial render
        internalRender(view: mutableView)
    }

    /// Set up state update callbacks for a view.
    ///
    /// Note: Mirror-based reflection was removed because it crashes in Swift WASM.
    /// State updates are driven by Binding closures that trigger re-renders directly.
    private func setupStateCallbacks<V: View>(_ view: inout V) {
        // No-op: State callbacks are connected through Binding's set closure,
        // which calls the rerenderClosure stored on the coordinator.
    }

    /// Internal render method that performs the actual rendering
    /// - Parameter view: SwiftUI-style view to render
    private func internalRender<V: View>(view: V) {
        let console = JSObject.global.console

        // Guard against reentrant renders
        guard !isRendering else { return }
        isRendering = true
        defer { isRendering = false }

        let isRerender = currentTree != nil

        // Save focused element info before clearing DOM so we can restore focus after re-render.
        // Without this, typing in TextField/SecureField or dragging Slider causes focus loss
        // because the full DOM is cleared and rebuilt on every state change.
        var savedFocusInfo: (ariaLabel: String, tagName: String, inputType: String, selectionStart: Int?, selectionEnd: Int?)?
        if isRerender {
            let doc = JSObject.global["document"]
            if let activeEl = doc.activeElement.object {
                let tag = activeEl.tagName.string ?? ""
                let ariaLabel = activeEl.getAttribute!("aria-label").string ?? ""
                let inputType = activeEl.getAttribute!("type").string ?? ""
                let selStart = activeEl.selectionStart.number.flatMap { Int($0) }
                let selEnd = activeEl.selectionEnd.number.flatMap { Int($0) }
                if !ariaLabel.isEmpty {
                    savedFocusInfo = (ariaLabel: ariaLabel, tagName: tag, inputType: inputType, selectionStart: selStart, selectionEnd: selEnd)
                }
            }

            // Re-render: clear DOM and reset handler state BEFORE view conversion
            // convertViewToVNode registers handlers, so registry must be empty first
            if let container = rootContainer {
                DOMBridge.shared.clearChildren(container)
            }
            DOMBridge.shared.clearRegistry()
            eventHandlerRegistry.removeAll()
            inputEventHandlerRegistry.removeAll()
        }

        // Convert view to VNode tree (this registers event handlers in eventHandlerRegistry)
        let newRoot = convertViewToVNode(view)

        _ = console.log("[Raven] Render: \(newRoot.children.count) children, rerender=\(isRerender)")

        let newTree = VTree(root: newRoot)

        // Mount the tree to DOM (this uses eventHandlerRegistry to attach listeners)
        mountTree(newRoot)
        currentTree = newTree

        // Restore focus to the element that was focused before re-render
        if let focusInfo = savedFocusInfo,
           let doc = JSObject.global["document"].object {
            // Build a specific selector using tag, type, and aria-label
            var selector = focusInfo.tagName.lowercased()
            if !focusInfo.inputType.isEmpty {
                selector += "[type=\"\(focusInfo.inputType)\"]"
            }
            selector += "[aria-label=\"\(focusInfo.ariaLabel)\"]"
            if let el = doc.querySelector!(selector).object {
                _ = el.focus!()
                // Restore cursor position for text-like inputs (not range/color/etc.)
                let textTypes = ["text", "password", "email", "search", "url", "tel"]
                if textTypes.contains(focusInfo.inputType), let selStart = focusInfo.selectionStart, let selEnd = focusInfo.selectionEnd {
                    el.selectionStart = .number(Double(selStart))
                    el.selectionEnd = .number(Double(selEnd))
                }
            }
        }
    }

    /// Schedule an update to be batched with other pending updates
    /// Uses requestAnimationFrame-equivalent batching for performance
    public func scheduleUpdate() {
        guard !updatePending else { return }

        updatePending = true

        // In WASM environment, this would use requestAnimationFrame
        // For now, we execute immediately and synchronously
        performUpdate()
    }

    /// Execute all pending updates
    /// This is called after requestAnimationFrame equivalent
    private func performUpdate() {
        updatePending = false

        // Execute all pending update closures
        let updates = pendingUpdates
        pendingUpdates.removeAll()

        for update in updates {
            update()
        }
    }

    // MARK: - View to VNode Conversion

    /// Recursively convert a View into a VNode
    /// - Parameter view: View to convert
    /// - Returns: VNode representation
    private func convertViewToVNode<V: View>(_ view: V) -> VNode {
        if isPrimitiveView(view) {
            return convertPrimitiveView(view)
        }
        let bodyView = view.body
        return convertViewToVNode(bodyView)
    }

    /// Check if a view is a primitive (has no body to evaluate)
    /// - Parameter view: View to check
    /// - Returns: True if the view is primitive
    private func isPrimitiveView<V: View>(_ view: V) -> Bool {
        // Primitive views have Body == Never
        return V.Body.self == Never.self
    }

    /// Convert a primitive view to VNode using protocol dispatch.
    ///
    /// Views that conform to `_CoordinatorRenderable` render themselves using
    /// the coordinator as a `_RenderContext`. All other `PrimitiveView` types
    /// fall back to their `toVNode()` method. This replaces ~900 lines of
    /// Mirror-based extraction functions that crash in Swift WASM.
    private func convertPrimitiveView<V: View>(_ view: V) -> VNode {
        // 1. Protocol-based rendering (handles all views with _CoordinatorRenderable)
        if let renderable = view as? any _CoordinatorRenderable {
            return renderable._render(with: self)
        }

        // 2. AnyView — unwrap and render via coordinator for proper _CoordinatorRenderable dispatch
        if let anyView = view as? AnyView {
            return convertViewToVNode(anyView.wrappedView)
        }

        // 3. Leaf PrimitiveView fallback (Text, Spacer, Divider, Color, etc.)
        if let primitiveView = view as? any PrimitiveView {
            return primitiveView.toVNode()
        }

        // 4. Default: unknown primitive — create a placeholder component node
        return VNode.component(
            props: [:],
            children: [],
            key: String(describing: V.self)
        )
    }

    // MARK: - DOM Operations

    /// Set the root container element
    /// - Parameter container: JSObject representing the container DOM element
    public func setRootContainer(_ container: JSObject) {
        self.rootContainer = container
        AppRuntime.injectFrameworkCSSIfNeeded()
    }

    /// Mount a virtual tree to the DOM
    /// - Parameter node: Root VNode to mount
    private func mountTree(_ node: VNode) {
        guard let container = rootContainer else {
            print("Warning: No root container set for mounting")
            return
        }

        guard let domNode = createDOMNode(node) else {
            print("Warning: Failed to create DOM node")
            return
        }
        DOMBridge.shared.appendChild(parent: container, child: domNode)
        DOMBridge.shared.registerNode(id: node.id, element: domNode)
    }

    /// Recursively create DOM nodes from VNode
    /// - Parameter node: VNode to convert
    /// - Returns: JSObject representing the DOM node
    private func createDOMNode(_ node: VNode) -> JSObject? {
        let domNode: JSObject?

        switch node.type {
        case .element(let tag):
            guard let element = DOMBridge.shared.createElement(tag: tag) else {
                return nil
            }
            domNode = element

            // Apply properties
            for (_, property) in node.props {
                applyProperty(property, to: element)
            }

            // Attach gesture event listeners
            for gestureReg in node.gestures {
                attachGestureListeners(gestureReg, to: element)
            }

            // Create and append children
            for child in node.children {
                guard let childDOMNode = createDOMNode(child) else {
                    continue
                }
                DOMBridge.shared.appendChild(parent: element, child: childDOMNode)
                DOMBridge.shared.registerNode(id: child.id, element: childDOMNode)
            }

        case .text(let content):
            guard let textNode = DOMBridge.shared.createTextNode(text: content) else {
                return nil
            }
            domNode = textNode

        case .fragment:
            // Fragments don't create a wrapper element
            // Use display: contents so fragment div is invisible to flex layout
            guard let fragment = DOMBridge.shared.createElement(tag: "div") else {
                return nil
            }
            DOMBridge.shared.setStyle(element: fragment, name: "display", value: "contents")
            domNode = fragment
            for child in node.children {
                guard let childDOMNode = createDOMNode(child) else {
                    continue
                }
                DOMBridge.shared.appendChild(parent: fragment, child: childDOMNode)
                DOMBridge.shared.registerNode(id: child.id, element: childDOMNode)
            }

        case .component:
            // Components are already expanded during VNode conversion
            guard let component = DOMBridge.shared.createElement(tag: "div") else {
                return nil
            }
            domNode = component
        }

        return domNode
    }

    /// Apply a property to a DOM element
    /// - Parameters:
    ///   - property: VProperty to apply
    ///   - element: JSObject representing the DOM element
    private func applyProperty(_ property: VProperty, to element: JSObject) {
        switch property {
        case .attribute(let name, let value):
            DOMBridge.shared.setAttribute(element: element, name: name, value: value)

        case .style(let name, let value):
            DOMBridge.shared.setStyle(element: element, name: name, value: value)

        case .boolAttribute(let name, let value):
            if value {
                DOMBridge.shared.setAttribute(element: element, name: name, value: name)
            } else {
                DOMBridge.shared.removeAttribute(element: element, name: name)
            }

        case .eventHandler(let event, let handlerID):
            // Check if this is an input event handler that needs event data
            if let inputHandler = inputEventHandlerRegistry[handlerID] {
                DOMBridge.shared.addGestureEventListener(
                    element: element,
                    event: event,
                    handlerID: handlerID,
                    handler: inputHandler
                )
            } else if let handler = eventHandlerRegistry[handlerID] {
                DOMBridge.shared.addEventListener(
                    element: element,
                    event: event,
                    handlerID: handlerID,
                    handler: handler
                )
            }
        }
    }

    // MARK: - Patch Application

    /// Apply patches to the DOM
    /// - Parameter patches: Array of patches from diffing algorithm
    private func applyPatches(_ patches: [Patch]) {
        for patch in patches {
            applyPatch(patch)
        }
    }

    /// Apply a single patch to the DOM
    /// - Parameter patch: Patch to apply
    private func applyPatch(_ patch: Patch) {
        switch patch {
        case .insert(let parentID, let node, let index):
            guard let parentElement = DOMBridge.shared.getNode(id: parentID) else {
                print("Warning: Parent node not found for insert: \(parentID)")
                return
            }

            guard let newElement = createDOMNode(node) else {
                print("Warning: Failed to create DOM node for insert")
                return
            }

            // Get the reference child at index
            if index < Int(parentElement.childNodes.length.number ?? 0) {
                let referenceChild = parentElement.childNodes[index].object
                DOMBridge.shared.insertBefore(parent: parentElement, new: newElement, reference: referenceChild)
            } else {
                DOMBridge.shared.appendChild(parent: parentElement, child: newElement)
            }

            DOMBridge.shared.registerNode(id: node.id, element: newElement)

        case .remove(let nodeID):
            guard let element = DOMBridge.shared.getNode(id: nodeID) else {
                print("Warning: Node not found for removal: \(nodeID)")
                return
            }

            if let parent = element.parentNode.object {
                DOMBridge.shared.removeChild(parent: parent, child: element)
            }
            DOMBridge.shared.unregisterNode(id: nodeID)

        case .replace(let oldID, let newNode):
            guard let oldElement = DOMBridge.shared.getNode(id: oldID),
                  let parent = oldElement.parentNode.object else {
                print("Warning: Old node not found for replacement: \(oldID)")
                return
            }

            guard let newElement = createDOMNode(newNode) else {
                print("Warning: Failed to create DOM node for replace")
                return
            }
            DOMBridge.shared.replaceChild(parent: parent, old: oldElement, new: newElement)
            DOMBridge.shared.unregisterNode(id: oldID)
            DOMBridge.shared.registerNode(id: newNode.id, element: newElement)

        case .updateProps(let nodeID, let propPatches):
            guard let element = DOMBridge.shared.getNode(id: nodeID) else {
                print("Warning: Node not found for property update: \(nodeID)")
                return
            }

            for propPatch in propPatches {
                applyPropPatch(propPatch, to: element)
            }

        case .reorder(let parentID, let moves):
            // Reordering children is complex and requires careful handling
            // For now, we'll skip this in the initial implementation
            print("Warning: Reorder patch not yet implemented for parent: \(parentID)")
        }
    }

    /// Apply a property patch to a DOM element
    /// - Parameters:
    ///   - patch: PropPatch to apply
    ///   - element: JSObject representing the DOM element
    private func applyPropPatch(_ patch: PropPatch, to element: JSObject) {
        switch patch {
        case .add(let key, let value), .update(let key, let value):
            applyProperty(value, to: element)

        case .remove(let key):
            // Determine the property type from the key and remove it
            // This is simplified; in a real implementation, we'd track property types
            DOMBridge.shared.removeAttribute(element: element, name: key)
        }
    }

    // MARK: - Gesture Support

    /// Attach gesture event listeners to a DOM element
    /// - Parameters:
    ///   - registration: Gesture registration with event names and handler ID
    ///   - element: DOM element to attach listeners to
    private func attachGestureListeners(_ registration: GestureRegistration, to element: JSObject) {
        // Get the element ID for gesture tracking
        let elementID = element.__ravenNodeID.string ?? UUID().uuidString

        // Register this gesture with the element
        var gestures = elementGestureMap[elementID] ?? []
        gestures.append((handlerID: registration.handlerID, priority: registration.priority))
        elementGestureMap[elementID] = gestures

        // For each event the gesture needs, attach a listener
        for eventName in registration.events {
            // Create a handler that will process the gesture event with event data
            let handler: @Sendable @MainActor (JSValue) -> Void = { [weak self] event in
                guard let self = self else { return }
                self.handleGestureEvent(
                    handlerID: registration.handlerID,
                    eventName: eventName,
                    priority: registration.priority,
                    event: event,
                    elementID: elementID
                )
            }

            // Register with DOMBridge using gesture event listener
            DOMBridge.shared.addGestureEventListener(
                element: element,
                event: eventName,
                handlerID: registration.handlerID,
                handler: handler
            )
        }
    }

    /// Handle a gesture event
    /// - Parameters:
    ///   - handlerID: ID of the gesture handler
    ///   - eventName: Name of the DOM event that triggered
    ///   - priority: Priority of the gesture
    ///   - event: The DOM event object from JavaScript
    ///   - elementID: The ID of the element that has this gesture
    private func handleGestureEvent(
        handlerID: UUID,
        eventName: String,
        priority: GesturePriority,
        event: JSValue,
        elementID: String
    ) {
        // Look up the gesture handler
        guard let handler = gestureHandlerRegistry[handlerID] else {
            return
        }

        // Perform hit testing - check if event target matches gesture's element
        guard let eventObj = event.object else { return }
        if !performHitTest(event: eventObj, elementID: elementID) {
            return
        }

        // Get all gestures on this element
        let elementGestures = elementGestureMap[elementID] ?? []

        // Check for priority conflicts
        if !shouldProcessGesture(
            handlerID: handlerID,
            priority: priority,
            elementGestures: elementGestures,
            eventName: eventName
        ) {
            return
        }

        // Extract event data and build gesture value based on event type
        // For now, we focus on drag gestures with pointer events
        if eventName == "pointerdown" {
            handlePointerDown(handlerID: handlerID, event: event, handler: handler, priority: priority, elementGestures: elementGestures)
        } else if eventName == "pointermove" {
            handlePointerMove(handlerID: handlerID, event: event, handler: handler)
        } else if eventName == "pointerup" || eventName == "pointercancel" {
            handlePointerUp(handlerID: handlerID, event: event, handler: handler)
        } else {
            // For other gesture types, use placeholder for now
            let gestureValue: Any = ()
            handler(gestureValue)
        }

        // Trigger re-render if needed
        if let rerender = rerenderClosure {
            rerender()
        }
    }

    /// Perform hit testing to verify the event target matches the gesture's element
    /// - Parameters:
    ///   - event: The DOM event object
    ///   - elementID: The ID of the element that has the gesture
    /// - Returns: True if the hit test passes
    private func performHitTest(event: JSObject, elementID: String) -> Bool {
        // Get the event target
        guard let target = event.target.object else {
            return false
        }

        // Check if the target is the element or a descendant of it
        // For now, we use a simple check - in a full implementation, we would walk the DOM tree
        let targetNodeID = target.__ravenNodeID.string

        // If the target has the same node ID, it's a direct hit
        if targetNodeID == elementID {
            return true
        }

        // Check if target is a descendant by walking up the tree
        var current = target
        while !current.parentNode.isNull && !current.parentNode.isUndefined {
            guard let parent = current.parentNode.object else { break }
            let parentNodeID = parent.__ravenNodeID.string
            if parentNodeID == elementID {
                return true
            }
            current = parent
        }

        return false
    }

    /// Determine if a gesture should be processed based on priority and recognition state
    /// - Parameters:
    ///   - handlerID: The gesture handler ID
    ///   - priority: The gesture's priority
    ///   - elementGestures: All gestures on this element
    ///   - eventName: The event name being processed
    /// - Returns: True if the gesture should be processed
    private func shouldProcessGesture(
        handlerID: UUID,
        priority: GesturePriority,
        elementGestures: [(handlerID: UUID, priority: GesturePriority)],
        eventName: String
    ) -> Bool {
        // Simultaneous gestures always get to process events
        if priority == .simultaneous {
            return true
        }

        // If this gesture has already been recognized, let it continue
        if recognizedGestures.contains(handlerID) {
            return true
        }

        // Check if any high-priority gesture has been recognized
        let recognizedHighPriority = elementGestures.first { gesture in
            gesture.priority == .high && recognizedGestures.contains(gesture.handlerID)
        }

        // If a high-priority gesture is recognized and this is normal priority, block it
        if let _ = recognizedHighPriority, priority == .normal {
            return false
        }

        // Check if any normal-priority gesture (not this one) has been recognized
        if priority == .normal {
            let otherRecognizedNormal = elementGestures.first { gesture in
                gesture.priority == .normal &&
                gesture.handlerID != handlerID &&
                recognizedGestures.contains(gesture.handlerID)
            }
            if otherRecognizedNormal != nil {
                return false
            }
        }

        // If we're still in pointerdown phase, everyone gets a chance
        if eventName == "pointerdown" {
            return true
        }

        return true
    }

    /// Fail competing gestures when a gesture is recognized
    /// - Parameters:
    ///   - recognizedHandlerID: The handler ID of the gesture that was recognized
    ///   - priority: The priority of the recognized gesture
    ///   - elementGestures: All gestures on the element
    private func failCompetingGestures(
        recognizedHandlerID: UUID,
        priority: GesturePriority,
        elementGestures: [(handlerID: UUID, priority: GesturePriority)]
    ) {
        // Mark this gesture as recognized
        recognizedGestures.insert(recognizedHandlerID)

        // If this is a high-priority gesture, fail all normal-priority gestures
        if priority == .high {
            for gesture in elementGestures {
                if gesture.priority == .normal && gesture.handlerID != recognizedHandlerID {
                    failGesture(handlerID: gesture.handlerID)
                }
            }
        }

        // If this is a normal-priority gesture, fail other normal-priority gestures
        if priority == .normal {
            for gesture in elementGestures {
                if gesture.priority == .normal && gesture.handlerID != recognizedHandlerID {
                    failGesture(handlerID: gesture.handlerID)
                }
            }
        }

        // Simultaneous gestures don't fail others
    }

    /// Fail a gesture by transitioning it to the failed state
    /// - Parameter handlerID: The handler ID of the gesture to fail
    private func failGesture(handlerID: UUID) {
        // Transition drag gestures to failed state
        if var state = dragGestureStates[handlerID] {
            if state.recognitionState == .possible {
                state.recognitionState = .failed
                dragGestureStates[handlerID] = state
            }
        }
    }

    /// Handle pointerdown event for drag gestures
    private func handlePointerDown(
        handlerID: UUID,
        event: JSValue,
        handler: @Sendable @MainActor (Any) -> Void,
        priority: GesturePriority,
        elementGestures: [(handlerID: UUID, priority: GesturePriority)]
    ) {
        guard let eventObj = event.object else { return }

        // Extract pointer coordinates
        let clientX = eventObj.clientX.number ?? 0.0
        let clientY = eventObj.clientY.number ?? 0.0

        // Get current timestamp
        let timestamp = Date().timeIntervalSince1970

        // Create initial drag gesture state in .possible state
        let startLocation = Raven.CGPoint(x: clientX, y: clientY)
        let state = DragGestureState(
            startLocation: startLocation,
            startTime: timestamp,
            minimumDistance: 10.0 // Default minimum distance
        )

        // Store the state (initialized with .possible state)
        dragGestureStates[handlerID] = state

        // Set up escape key listener to cancel gesture if needed
        setupGestureCancellation(handlerID: handlerID)

        // Don't call the handler yet - wait for movement beyond minimum distance
        // State: .possible -> waiting for movement to transition to .began
    }

    /// Set up cancellation handling for an active gesture
    /// This includes escape key handling and pointer leave events
    private func setupGestureCancellation(handlerID: UUID) {
        // Note: In a full implementation, we would:
        // 1. Add a keydown listener for Escape key
        // 2. Add pointerleave listener to the window
        // 3. Store these listeners to clean up later
        //
        // For now, pointercancel events from the browser handle most cases
        // Future enhancement: Add explicit escape key and pointer leave handling
    }

    /// Handle pointermove event for drag gestures
    private func handlePointerMove(handlerID: UUID, event: JSValue, handler: @Sendable @MainActor (Any) -> Void) {
        guard let eventObj = event.object else { return }
        guard var state = dragGestureStates[handlerID] else { return }

        // Extract pointer coordinates
        let clientX = eventObj.clientX.number ?? 0.0
        let clientY = eventObj.clientY.number ?? 0.0
        let currentLocation = Raven.CGPoint(x: clientX, y: clientY)

        // Get current timestamp
        let timestamp = Date().timeIntervalSince1970

        // Add sample for velocity calculation
        state.addSample(location: currentLocation, time: timestamp)

        // State machine logic
        switch state.recognitionState {
        case .possible:
            // Check if minimum distance threshold is exceeded
            if state.hasExceededMinimumDistance(to: currentLocation) {
                // Transition: .possible -> .began
                state.recognitionState = .began

                // Get the element ID and gestures for conflict resolution
                if let elementID = findElementIDForGesture(handlerID: handlerID),
                   let elementGestures = elementGestureMap[elementID] {
                    // Find this gesture's priority
                    if let gestureInfo = elementGestures.first(where: { $0.handlerID == handlerID }) {
                        // Fail competing gestures
                        failCompetingGestures(
                            recognizedHandlerID: handlerID,
                            priority: gestureInfo.priority,
                            elementGestures: elementGestures
                        )

                        // Prevent default browser behavior if needed
                        preventDefaultIfNeeded(event: eventObj, priority: gestureInfo.priority)
                    }
                }

                // Calculate velocity
                let velocity = state.calculateVelocity()

                // Calculate predicted end location
                let predictedEndLocation = state.predictEndLocation(from: currentLocation, velocity: velocity)

                // Create DragGesture.Value
                let dragValue = DragGesture.Value(
                    location: currentLocation,
                    startLocation: state.startLocation,
                    velocity: velocity,
                    predictedEndLocation: predictedEndLocation,
                    time: Date(timeIntervalSince1970: timestamp)
                )

                // Update state
                dragGestureStates[handlerID] = state

                // Fire onChanged for the first time (gesture recognized)
                handler(dragValue)
            } else {
                // Stay in .possible state, don't trigger handler yet
                dragGestureStates[handlerID] = state
            }

        case .began, .changed:
            // Transition: .began/.changed -> .changed
            state.recognitionState = .changed

            // Calculate velocity
            let velocity = state.calculateVelocity()

            // Calculate predicted end location
            let predictedEndLocation = state.predictEndLocation(from: currentLocation, velocity: velocity)

            // Create DragGesture.Value
            let dragValue = DragGesture.Value(
                location: currentLocation,
                startLocation: state.startLocation,
                velocity: velocity,
                predictedEndLocation: predictedEndLocation,
                time: Date(timeIntervalSince1970: timestamp)
            )

            // Update state
            dragGestureStates[handlerID] = state

            // Fire onChanged (gesture is ongoing)
            handler(dragValue)

        case .ended, .cancelled, .failed:
            // Gesture already finished, ignore further moves
            break
        }
    }

    /// Find the element ID for a gesture handler
    /// - Parameter handlerID: The gesture handler ID
    /// - Returns: The element ID if found
    private func findElementIDForGesture(handlerID: UUID) -> String? {
        for (elementID, gestures) in elementGestureMap {
            if gestures.contains(where: { $0.handlerID == handlerID }) {
                return elementID
            }
        }
        return nil
    }

    /// Prevent default browser behavior if needed for gesture recognition
    /// - Parameters:
    ///   - event: The DOM event object
    ///   - priority: The gesture's priority
    private func preventDefaultIfNeeded(event: JSObject, priority: GesturePriority) {
        // Call preventDefault to prevent default scroll/swipe behavior
        // This is especially important for high-priority gestures
        _ = event.preventDefault?()
    }

    /// Handle pointerup/pointercancel event for drag gestures
    private func handlePointerUp(handlerID: UUID, event: JSValue, handler: @Sendable @MainActor (Any) -> Void) {
        guard let eventObj = event.object else { return }
        guard var state = dragGestureStates[handlerID] else { return }

        // Determine if this is a cancel or normal end
        let eventName = eventObj.type.string ?? "pointerup"
        let isCancelled = eventName == "pointercancel"

        // State machine logic
        switch state.recognitionState {
        case .possible:
            // Gesture never recognized - transition to .failed
            state.recognitionState = .failed
            // Don't call handler - gesture failed to meet recognition criteria

        case .began, .changed:
            // Gesture was recognized and is ending
            if isCancelled {
                // Transition: .began/.changed -> .cancelled
                state.recognitionState = .cancelled
            } else {
                // Transition: .began/.changed -> .ended
                state.recognitionState = .ended
            }

            // Extract final pointer coordinates
            let clientX = eventObj.clientX.number ?? 0.0
            let clientY = eventObj.clientY.number ?? 0.0
            let currentLocation = Raven.CGPoint(x: clientX, y: clientY)

            // Get current timestamp
            let timestamp = Date().timeIntervalSince1970

            // Calculate final velocity
            let velocity = state.calculateVelocity()

            // Calculate predicted end location
            let predictedEndLocation = state.predictEndLocation(from: currentLocation, velocity: velocity)

            // Create final DragGesture.Value
            let dragValue = DragGesture.Value(
                location: currentLocation,
                startLocation: state.startLocation,
                velocity: velocity,
                predictedEndLocation: predictedEndLocation,
                time: Date(timeIntervalSince1970: timestamp)
            )

            // Fire onEnded callback
            handler(dragValue)

        case .ended, .cancelled, .failed:
            // Already in terminal state, shouldn't happen but handle gracefully
            break
        }

        // Clean up state
        dragGestureStates.removeValue(forKey: handlerID)

        // Remove from recognized gestures set
        recognizedGestures.remove(handlerID)
    }

    /// Register a gesture handler
    /// - Parameters:
    ///   - id: Unique identifier for the gesture
    ///   - handler: Handler closure that processes gesture values
    public func registerGestureHandler<Value>(
        id: UUID,
        handler: @escaping @Sendable @MainActor (Value) -> Void
    ) {
        // Type-erase the handler
        let anyHandler: @Sendable @MainActor (Any) -> Void = { value in
            if let typedValue = value as? Value {
                handler(typedValue)
            }
        }
        gestureHandlerRegistry[id] = anyHandler
    }

    /// Cancel all active gestures
    /// This is useful when:
    /// - The view is about to be removed
    /// - Navigation occurs
    /// - A modal is presented
    public func cancelAllGestures() {
        // Cancel all active drag gestures
        for (handlerID, var state) in dragGestureStates {
            // Only cancel if gesture is active (not already in terminal state)
            switch state.recognitionState {
            case .possible, .began, .changed:
                state.recognitionState = .cancelled

                // If gesture was recognized, fire final callback
                if state.recognitionState == .began || state.recognitionState == .changed {
                    if let handler = gestureHandlerRegistry[handlerID] {
                        // Create final gesture value at last known position
                        let lastSample = state.positionSamples.last ?? state.positionSamples.first!
                        let velocity = state.calculateVelocity()
                        let predictedEndLocation = state.predictEndLocation(
                            from: lastSample.location,
                            velocity: velocity
                        )

                        let dragValue = DragGesture.Value(
                            location: lastSample.location,
                            startLocation: state.startLocation,
                            velocity: velocity,
                            predictedEndLocation: predictedEndLocation,
                            time: Date(timeIntervalSince1970: lastSample.time)
                        )

                        handler(dragValue)
                    }
                }

            case .ended, .cancelled, .failed:
                // Already in terminal state
                break
            }
        }

        // Clear all gesture states
        dragGestureStates.removeAll()

        // Clear recognized gestures
        recognizedGestures.removeAll()
    }

    /// Cancel a specific gesture by ID
    /// - Parameter handlerID: The gesture handler ID to cancel
    public func cancelGesture(handlerID: UUID) {
        guard var state = dragGestureStates[handlerID] else { return }

        // Only cancel if gesture is active
        switch state.recognitionState {
        case .possible, .began, .changed:
            state.recognitionState = .cancelled

            // If gesture was recognized, fire final callback
            if state.recognitionState == .began || state.recognitionState == .changed {
                if let handler = gestureHandlerRegistry[handlerID] {
                    let lastSample = state.positionSamples.last ?? state.positionSamples.first!
                    let velocity = state.calculateVelocity()
                    let predictedEndLocation = state.predictEndLocation(
                        from: lastSample.location,
                        velocity: velocity
                    )

                    let dragValue = DragGesture.Value(
                        location: lastSample.location,
                        startLocation: state.startLocation,
                        velocity: velocity,
                        predictedEndLocation: predictedEndLocation,
                        time: Date(timeIntervalSince1970: lastSample.time)
                    )

                    handler(dragValue)
                }
            }

            // Remove the gesture state
            dragGestureStates.removeValue(forKey: handlerID)

            // Remove from recognized gestures
            recognizedGestures.remove(handlerID)

        case .ended, .cancelled, .failed:
            // Already in terminal state
            break
        }
    }

    // MARK: - Rerender

    /// Triggers a full re-render of the current view hierarchy.
    ///
    /// Called by AppRuntime when the system color scheme changes
    /// so that views using `@Environment(\.colorScheme)` update.
    public func triggerRerender() {
        if let rerender = rerenderClosure {
            rerender()
        }
    }

    // MARK: - Environment Updates

    /// Update an environment value and trigger re-render.
    ///
    /// This method updates a specific environment value and triggers a re-render
    /// of the view hierarchy to propagate the change.
    ///
    /// - Parameters:
    ///   - keyPath: The key path to the environment value to update.
    ///   - value: The new value to set.
    public func updateEnvironment<Value>(_ keyPath: WritableKeyPath<EnvironmentValues, Value>, _ value: Value) {
        // TODO: Implement environment value storage and propagation
        // This requires:
        // 1. Storing EnvironmentValues in RenderCoordinator
        // 2. Propagating environment values through the view hierarchy during rendering
        // 3. Triggering a re-render after environment update

        // For now, this is a placeholder that would trigger a re-render (now synchronous)
        if let rerender = rerenderClosure {
            rerender()
        }
    }
}

