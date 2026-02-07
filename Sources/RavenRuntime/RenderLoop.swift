import Foundation
import Raven
import JavaScriptKit

/// Main actor-isolated coordinator responsible for managing the render loop
/// and virtual DOM tree updates.
///
/// The RenderCoordinator is the central component that:
/// - Converts SwiftUI-style Views into VNodes
/// - Maintains a persistent fiber tree for incremental reconciliation
/// - Batches state changes via `requestAnimationFrame` (multiple state mutations → one render)
/// - Delegates platform DOM operations to a `PlatformRenderer`
/// - Skips clean subtrees for O(dirty) instead of O(total) reconciliation
@MainActor
public final class RenderCoordinator: Sendable, _RenderContext, _StateChangeReceiver {
    // MARK: - Properties

    /// Root container element in the DOM
    private var rootContainer: JSObject?

    /// Platform renderer that handles actual DOM/platform operations.
    private let renderer: any PlatformRenderer

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

    // MARK: - State Batching

    /// Whether a render has been scheduled via `queueMicrotask` but not yet flushed.
    private var needsRender: Bool = false

    /// JSClosure kept alive for the microtask callback.
    private var microtaskClosure: JSClosure?

    /// Animation context captured at `scheduleRender()` time so the deferred
    /// render applies the correct animation.
    private var pendingAnimation: Animation?

    // MARK: - Path Tracking (for stable handler & node IDs)

    /// Stack of path components describing the current position in the view tree.
    /// Example: ["VStack", "0", "HStack", "1", "Button"]
    private var pathStack: [String] = []

    /// Stack tracking how many children have been rendered at each nesting level.
    /// Each entry corresponds to a `convertViewToVNode` depth; the value is
    /// incremented each time `renderChild` is called at that depth.
    private var childCounterStack: [Int] = []

    /// Stack tracking how many handlers have been registered at each nesting level.
    /// Used to disambiguate multiple handlers in the same view (e.g., Stepper's
    /// decrement and increment buttons).
    private var handlerCounterStack: [Int] = []

    /// Set of handler IDs that were registered during the *current* render pass.
    /// After the render pass completes, any handler from the previous pass that
    /// is NOT in this set is stale and should be cleaned up.
    private var activeHandlerIDs: Set<UUID> = []

    /// Set of handler IDs from the *previous* render pass, used for stale cleanup.
    private var previousHandlerIDs: Set<UUID> = []

    // MARK: - Persistent State Storage

    /// Storage for persistent state objects keyed by view tree position.
    /// Objects survive across re-renders, enabling stateful controllers.
    private var persistentStateStorage: [String: AnyObject] = [:]

    // MARK: - Fiber Reconciler

    /// Current fiber root (the "current" tree in dual-tree terminology).
    private var currentFiberRoot: Fiber?

    /// Fiber tree builder for constructing/reconciling fiber trees.
    private let fiberTreeBuilder = FiberTreeBuilder()

    /// Reconcile pass for collecting mutations from dirty fibers.
    private let reconcilePass = ReconcilePass()

    /// Paused reconciliation state (for resumable traversal).
    private var pausedReconcileState: (fiber: Fiber, mutations: [FiberMutation])?

    // MARK: - Initialization

    /// Initialize the render coordinator with an optional platform renderer.
    /// - Parameter renderer: The platform renderer to use. Defaults to `DOMRenderer()`.
    public init(renderer: (any PlatformRenderer)? = nil) {
        self.renderer = renderer ?? DOMRenderer()

        // Wire up DOMRenderer callbacks if applicable
        if let domRenderer = self.renderer as? DOMRenderer {
            domRenderer.eventAttacher = { [weak self] element, event, handlerID in
                self?.attachEventToElement(element, event: event, handlerID: handlerID)
            }
            domRenderer.gestureAttacher = { [weak self] registration, element in
                self?.attachGestureListeners(registration, to: element)
            }
        }
    }

    /// Generate a unique handler ID (fallback for non-path contexts).
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

    /// Generate a stable UUID from a path string using FNV-1a hash.
    /// The same path always produces the same UUID across renders.
    private func stableUUID(from path: String) -> UUID {
        var hash: UInt64 = 14695981039346656037 // FNV-1a offset basis
        for byte in path.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 1099511628211 // FNV-1a prime
        }
        let highHex = String(hash >> 32, radix: 16, uppercase: false)
        let lowHex = String(hash & 0xFFFFFFFF, radix: 16, uppercase: false)
        let high = String(repeating: "0", count: max(0, 8 - highHex.count)) + highHex
        let low = String(repeating: "0", count: max(0, 12 - lowHex.count)) + lowHex
        let uuidString = "\(high)-0000-4000-8000-\(low)"
        return UUID(uuidString: uuidString) ?? UUID()
    }

    /// Build the current path string from the path stack and append a handler
    /// suffix (e.g., ".h0", ".h1") to disambiguate multiple handlers in the
    /// same view.
    private func nextStableHandlerID() -> UUID {
        let handlerIdx: Int
        if !handlerCounterStack.isEmpty {
            handlerIdx = handlerCounterStack[handlerCounterStack.count - 1]
            handlerCounterStack[handlerCounterStack.count - 1] += 1
        } else {
            handlerIdx = 0
        }
        let path = pathStack.joined(separator: ".") + ".h\(handlerIdx)"
        return stableUUID(from: path)
    }

    // MARK: - _StateChangeReceiver Conformance

    /// Schedule a batched render via `requestAnimationFrame`.
    ///
    /// Multiple `scheduleRender()` calls within the same animation frame are
    /// coalesced into a single `flushRender()` invocation. Unlike `queueMicrotask`
    /// (which drains between each JS event), `requestAnimationFrame` fires once
    /// per frame (~16ms), properly batching rapid events like keystrokes.
    public func scheduleRender() {
        // Capture animation context at schedule time
        if pendingAnimation == nil {
            pendingAnimation = AnimationContext.current
        }

        guard !needsRender else { return }
        needsRender = true

        // Use requestAnimationFrame for batching — it fires once before the
        // next repaint, coalescing all state changes within the current frame.
        if microtaskClosure == nil {
            microtaskClosure = JSClosure { [weak self] _ -> JSValue in
                self?.flushRender()
                return .undefined
            }
        }
        _ = JSObject.global.requestAnimationFrame!(microtaskClosure!)
    }

    /// Mark a component path as dirty and schedule a batched render.
    public func markDirty(path: String) {
        FiberRegistry.shared.markDirty(path: path)
        scheduleRender()
    }

    /// Flush the pending render (called from the microtask).
    private func flushRender() {
        guard needsRender else { return }
        needsRender = false

        // Restore animation context that was active when scheduleRender was called
        let animation = pendingAnimation
        pendingAnimation = nil

        if let animation = animation {
            AnimationContext.withAnimation(animation) {
                rerenderClosure?()
            }
        } else {
            rerenderClosure?()
        }
    }

    // MARK: - _RenderContext Conformance

    /// Recursively convert a child view into its VNode representation.
    /// Automatically tracks the child index in the path stack for stable IDs.
    public func renderChild(_ view: any View) -> VNode {
        // Record the child index at the current level
        let childIdx: Int
        if !childCounterStack.isEmpty {
            childIdx = childCounterStack[childCounterStack.count - 1]
            childCounterStack[childCounterStack.count - 1] += 1
        } else {
            childIdx = 0
        }
        pathStack.append(String(childIdx))
        defer { pathStack.removeLast() }
        return convertViewToVNode(view)
    }

    /// Register a click/action handler and return a stable ID.
    /// On first render the handler is stored; on re-renders the closure is
    /// updated in-place so the existing JSClosure picks it up.
    public func registerClickHandler(_ action: @escaping @Sendable @MainActor () -> Void) -> UUID {
        let id = nextStableHandlerID()
        eventHandlerRegistry[id] = action
        activeHandlerIDs.insert(id)
        // Update renderer's closure so existing JSClosure invokes the latest action
        renderer.updateEventHandler(id: id, handler: action)
        return id
    }

    /// Retrieve or create a persistent state object keyed by the current view tree position.
    public func persistentState<T: AnyObject>(create: () -> T) -> T {
        let key = pathStack.joined(separator: ".")
        if let existing = persistentStateStorage[key] as? T {
            return existing
        }
        let obj = create()
        persistentStateStorage[key] = obj
        return obj
    }

    /// Register an input handler that receives the raw DOM event and return a stable ID.
    public func registerInputHandler(_ handler: @escaping @Sendable @MainActor (JSValue) -> Void) -> UUID {
        let id = nextStableHandlerID()
        inputEventHandlerRegistry[id] = handler
        activeHandlerIDs.insert(id)
        renderer.updateInputEventHandler(id: id) { value in
            if let jsValue = value as? JSValue {
                handler(jsValue)
            }
        }
        return id
    }

    // MARK: - Event Handler Wiring

    /// Wire a DOM event listener on an element, choosing the right DOMBridge
    /// method based on whether it's an input or click handler.
    /// Called by the DOMRenderer's `eventAttacher` callback.
    private func attachEventToElement(_ element: JSObject, event: String, handlerID: UUID) {
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

    // MARK: - Public API

    /// Main entry point for rendering a view
    /// - Parameter view: SwiftUI-style view to render
    public func render<V: View>(view: V) {
        // Register this coordinator as the global state change receiver
        _RenderScheduler.current = self

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

        // Perform initial render (immediate, not batched)
        internalRender(view: mutableView)
    }

    /// Set up state update callbacks for a view.
    ///
    /// Note: Mirror-based reflection was removed because it crashes in Swift WASM.
    /// State changes now flow through `_RenderScheduler` → `scheduleRender()`.
    private func setupStateCallbacks<V: View>(_ view: inout V) {
        // No-op: State callbacks are connected through _RenderScheduler.current
        // and Binding closures that trigger re-renders via scheduleRender().
    }

    /// Internal render method that performs the actual rendering.
    ///
    /// On the first render the full VNode tree is mounted to the DOM.
    /// On subsequent renders the Differ computes a minimal set of patches
    /// and only the changed DOM nodes are touched (incremental reconciliation).
    ///
    /// - Parameter view: SwiftUI-style view to render
    private func internalRender<V: View>(view: V) {
        let console = JSObject.global.console

        // Guard against reentrant renders
        guard !isRendering else { return }
        isRendering = true
        defer { isRendering = false }

        let isRerender = currentFiberRoot != nil

        // -- Reset path tracking for this render pass --
        pathStack.removeAll()
        childCounterStack.removeAll()
        handlerCounterStack.removeAll()
        previousHandlerIDs = activeHandlerIDs
        activeHandlerIDs.removeAll()

        // -- Convert view to VNode tree --
        // This registers event handlers (populating activeHandlerIDs)
        let rawRoot = convertViewToVNode(view)

        // Assign stable node IDs based on tree position.
        let newRoot = assignStableIDs(rawRoot, path: "root")

        _ = console.log("[Raven] Render: \(newRoot.children.count) children, rerender=\(isRerender)")

        // -- Fiber reconciliation --
        fiberRender(newRoot: newRoot, isRerender: isRerender)

        // -- Clean up stale handlers --
        // Any handler that was active last render but not this render is stale.
        let staleHandlers = previousHandlerIDs.subtracting(activeHandlerIDs)
        for id in staleHandlers {
            eventHandlerRegistry.removeValue(forKey: id)
            inputEventHandlerRegistry.removeValue(forKey: id)
            renderer.cleanupHandler(id: id)
        }
    }

    /// Walk a VNode tree and replace every random NodeID with a deterministic
    /// one derived from the node's structural position.
    private func assignStableIDs(_ node: VNode, path: String) -> VNode {
        let stableID = NodeID(stablePath: path)
        let children = node.children.enumerated().map { (i, child) in
            let childKey = child.key ?? String(i)
            return assignStableIDs(child, path: "\(path).\(childKey)")
        }
        return VNode(
            id: stableID,
            type: node.type,
            props: node.props,
            children: children,
            key: node.key,
            gestures: node.gestures
        )
    }

    // MARK: - View to VNode Conversion

    /// Recursively convert a View into a VNode.
    /// Pushes the view type name onto the path stack so that handler and node
    /// IDs produced inside this subtree are deterministic.
    ///
    /// For selective re-rendering: before evaluating a composite view's `.body`,
    /// checks whether this component path is dirty. If the path is clean and a
    /// cached VNode exists, returns the cached version without calling `.body`.
    ///
    /// - Parameter view: View to convert
    /// - Returns: VNode representation
    private func convertViewToVNode<V: View>(_ view: V) -> VNode {
        // Push the (simplified) type name for path tracking
        let typeName = _typeName(V.self)
        pathStack.append(typeName)
        childCounterStack.append(0)
        handlerCounterStack.append(0)
        defer {
            pathStack.removeLast()
            childCounterStack.removeLast()
            handlerCounterStack.removeLast()
        }

        // Compute the current component path for selective re-rendering
        let componentPath = pathStack.joined(separator: ".")

        // Set the current component path so State reads can associate
        _RenderScheduler.currentComponentPath = componentPath

        if isPrimitiveView(view) {
            return convertPrimitiveView(view)
        }

        let bodyView = view.body
        return convertViewToVNode(bodyView)
    }

    /// Short, human-readable type name without module prefix or generic params.
    private func _typeName<T>(_ type: T.Type) -> String {
        let full = String(describing: type)
        // Strip generic parameters: "VStack<TupleView<...>>" → "VStack"
        if let idx = full.firstIndex(of: "<") {
            return String(full[full.startIndex..<idx])
        }
        return full
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

    // MARK: - DOM Operations (delegated to renderer)

    /// Set the root container element
    /// - Parameter container: JSObject representing the container DOM element
    public func setRootContainer(_ container: JSObject) {
        self.rootContainer = container
        renderer.setRootContainer(container)
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

        // Trigger re-render via batching
        scheduleRender()
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
    private func failGesture(handlerID: UUID) {
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

        let clientX = eventObj.clientX.number ?? 0.0
        let clientY = eventObj.clientY.number ?? 0.0
        let timestamp = Date().timeIntervalSince1970
        let startLocation = Raven.CGPoint(x: clientX, y: clientY)
        let state = DragGestureState(
            startLocation: startLocation,
            startTime: timestamp,
            minimumDistance: 10.0
        )

        dragGestureStates[handlerID] = state
        setupGestureCancellation(handlerID: handlerID)
    }

    /// Set up cancellation handling for an active gesture
    private func setupGestureCancellation(handlerID: UUID) {
        // Note: In a full implementation, we would:
        // 1. Add a keydown listener for Escape key
        // 2. Add pointerleave listener to the window
        // 3. Store these listeners to clean up later
        //
        // For now, pointercancel events from the browser handle most cases
    }

    /// Handle pointermove event for drag gestures
    private func handlePointerMove(handlerID: UUID, event: JSValue, handler: @Sendable @MainActor (Any) -> Void) {
        guard let eventObj = event.object else { return }
        guard var state = dragGestureStates[handlerID] else { return }

        let clientX = eventObj.clientX.number ?? 0.0
        let clientY = eventObj.clientY.number ?? 0.0
        let currentLocation = Raven.CGPoint(x: clientX, y: clientY)
        let timestamp = Date().timeIntervalSince1970

        state.addSample(location: currentLocation, time: timestamp)

        switch state.recognitionState {
        case .possible:
            if state.hasExceededMinimumDistance(to: currentLocation) {
                state.recognitionState = .began

                if let elementID = findElementIDForGesture(handlerID: handlerID),
                   let elementGestures = elementGestureMap[elementID] {
                    if let gestureInfo = elementGestures.first(where: { $0.handlerID == handlerID }) {
                        failCompetingGestures(
                            recognizedHandlerID: handlerID,
                            priority: gestureInfo.priority,
                            elementGestures: elementGestures
                        )
                        preventDefaultIfNeeded(event: eventObj, priority: gestureInfo.priority)
                    }
                }

                let velocity = state.calculateVelocity()
                let predictedEndLocation = state.predictEndLocation(from: currentLocation, velocity: velocity)
                let dragValue = DragGesture.Value(
                    location: currentLocation,
                    startLocation: state.startLocation,
                    velocity: velocity,
                    predictedEndLocation: predictedEndLocation,
                    time: Date(timeIntervalSince1970: timestamp)
                )

                dragGestureStates[handlerID] = state
                handler(dragValue)
            } else {
                dragGestureStates[handlerID] = state
            }

        case .began, .changed:
            state.recognitionState = .changed
            let velocity = state.calculateVelocity()
            let predictedEndLocation = state.predictEndLocation(from: currentLocation, velocity: velocity)
            let dragValue = DragGesture.Value(
                location: currentLocation,
                startLocation: state.startLocation,
                velocity: velocity,
                predictedEndLocation: predictedEndLocation,
                time: Date(timeIntervalSince1970: timestamp)
            )

            dragGestureStates[handlerID] = state
            handler(dragValue)

        case .ended, .cancelled, .failed:
            break
        }
    }

    /// Find the element ID for a gesture handler
    private func findElementIDForGesture(handlerID: UUID) -> String? {
        for (elementID, gestures) in elementGestureMap {
            if gestures.contains(where: { $0.handlerID == handlerID }) {
                return elementID
            }
        }
        return nil
    }

    /// Prevent default browser behavior if needed for gesture recognition
    private func preventDefaultIfNeeded(event: JSObject, priority: GesturePriority) {
        _ = event.preventDefault?()
    }

    /// Handle pointerup/pointercancel event for drag gestures
    private func handlePointerUp(handlerID: UUID, event: JSValue, handler: @Sendable @MainActor (Any) -> Void) {
        guard let eventObj = event.object else { return }
        guard var state = dragGestureStates[handlerID] else { return }

        let eventName = eventObj.type.string ?? "pointerup"
        let isCancelled = eventName == "pointercancel"

        switch state.recognitionState {
        case .possible:
            state.recognitionState = .failed

        case .began, .changed:
            if isCancelled {
                state.recognitionState = .cancelled
            } else {
                state.recognitionState = .ended
            }

            let clientX = eventObj.clientX.number ?? 0.0
            let clientY = eventObj.clientY.number ?? 0.0
            let currentLocation = Raven.CGPoint(x: clientX, y: clientY)
            let timestamp = Date().timeIntervalSince1970
            let velocity = state.calculateVelocity()
            let predictedEndLocation = state.predictEndLocation(from: currentLocation, velocity: velocity)
            let dragValue = DragGesture.Value(
                location: currentLocation,
                startLocation: state.startLocation,
                velocity: velocity,
                predictedEndLocation: predictedEndLocation,
                time: Date(timeIntervalSince1970: timestamp)
            )

            handler(dragValue)

        case .ended, .cancelled, .failed:
            break
        }

        dragGestureStates.removeValue(forKey: handlerID)
        recognizedGestures.remove(handlerID)
    }

    /// Register a gesture handler
    public func registerGestureHandler<Value>(
        id: UUID,
        handler: @escaping @Sendable @MainActor (Value) -> Void
    ) {
        let anyHandler: @Sendable @MainActor (Any) -> Void = { value in
            if let typedValue = value as? Value {
                handler(typedValue)
            }
        }
        gestureHandlerRegistry[id] = anyHandler
    }

    /// Cancel all active gestures
    public func cancelAllGestures() {
        for (handlerID, var state) in dragGestureStates {
            switch state.recognitionState {
            case .possible, .began, .changed:
                state.recognitionState = .cancelled

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

            case .ended, .cancelled, .failed:
                break
            }
        }

        dragGestureStates.removeAll()
        recognizedGestures.removeAll()
    }

    /// Cancel a specific gesture by ID
    public func cancelGesture(handlerID: UUID) {
        guard var state = dragGestureStates[handlerID] else { return }

        switch state.recognitionState {
        case .possible, .began, .changed:
            state.recognitionState = .cancelled

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

            dragGestureStates.removeValue(forKey: handlerID)
            recognizedGestures.remove(handlerID)

        case .ended, .cancelled, .failed:
            break
        }
    }

    // MARK: - Rerender

    /// Triggers a full re-render of the current view hierarchy.
    ///
    /// Called by AppRuntime when the system color scheme changes
    /// so that views using `@Environment(\.colorScheme)` update.
    public func triggerRerender() {
        scheduleRender()
    }

    // MARK: - Environment Updates

    /// Update an environment value and trigger re-render.
    public func updateEnvironment<Value>(_ keyPath: WritableKeyPath<EnvironmentValues, Value>, _ value: Value) {
        // TODO: Implement environment value storage and propagation
        scheduleRender()
    }

    // MARK: - Fiber Reconciliation

    /// Fiber-based render path.
    ///
    /// On first render: builds a full fiber tree, marks all dirty, collects
    /// insert mutations, and commits.
    /// On re-render: reconciles dirty fibers only, collects mutations, commits.
    private func fiberRender(newRoot: VNode, isRerender: Bool) {
        if isRerender, let currentRoot = currentFiberRoot {
            // -- Re-render: reconcile existing fiber tree --
            // Update the existing fiber tree with the new VNode
            fiberTreeBuilder.reconcileChildren(
                of: currentRoot,
                newChildren: newRoot.children,
                pathPrefix: "root"
            )
            currentRoot.elementDesc = newRoot
            currentRoot.stableNodeID = newRoot.id

            // Run reconciliation pass — skip clean subtrees
            let result = reconcilePass.run(root: currentRoot)

            switch result {
            case .complete(let mutations):
                // Apply all mutations and swap trees
                if !mutations.isEmpty {
                    renderer.applyMutations(mutations)
                }
                currentRoot.clearDirtyFlagsRecursive()
                pausedReconcileState = nil

            case .paused(let resumeFiber, let mutations):
                // Store paused state for continuation in next frame
                pausedReconcileState = (fiber: resumeFiber, mutations: mutations)
                scheduleRender()
            }
        } else {
            // -- First render: build full fiber tree and mount --
            let rootFiber = fiberTreeBuilder.buildTree(from: newRoot)
            rootFiber.elementDesc = newRoot
            rootFiber.stableNodeID = newRoot.id

            // On first render, use mountTree (same as legacy path)
            renderer.mountTree(newRoot)

            rootFiber.clearDirtyFlagsRecursive()
            currentFiberRoot = rootFiber
        }
    }
}
