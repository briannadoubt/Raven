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
public final class RenderCoordinator: Sendable {
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

    /// Gesture handler registry for tracking gesture state
    private var gestureHandlerRegistry: [UUID: @Sendable @MainActor (Any) -> Void] = [:]

    /// Gesture state tracking for ongoing gestures
    private var gestureStates: [UUID: Any] = [:]

    /// Stored reference to the current root view for re-rendering
    /// This is a type-erased closure that re-renders the current view
    private var rerenderClosure: (@MainActor () async -> Void)?

    // MARK: - Initialization

    /// Initialize the render coordinator
    public init() {
        self.differ = Differ()
    }

    // MARK: - Public API

    /// Main entry point for rendering a view
    /// - Parameter view: SwiftUI-style view to render
    public func render<V: View>(view: V) async {
        // Create a mutable copy for state setup
        var mutableView = view

        // Set up state update callbacks
        setupStateCallbacks(&mutableView)

        // Store a re-render closure that captures the view
        rerenderClosure = { [weak self] in
            guard let self = self else { return }
            // Re-render with the current view state
            await self.internalRender(view: mutableView)
        }

        // Perform initial render
        await internalRender(view: mutableView)
    }

    /// Set up state update callbacks for a view
    /// This uses reflection to find @State properties and connect them to re-renders
    /// - Parameter view: View to set up callbacks for
    private func setupStateCallbacks<V: View>(_ view: inout V) {
        // Use reflection to find all @State properties
        let mirror = Mirror(reflecting: view)

        for child in mirror.children {
            // Check if this child is a State property wrapper
            // State properties have a backing storage field
            if let stateValue = child.value as? any DynamicProperty {
                // For @State properties, we need to set up the update callback
                // This is a simplified approach - in a full implementation,
                // we would use property wrapper introspection

                // Try to access the internal storage and set callback
                // This requires reflection access to the State's internal structure
                let childMirror = Mirror(reflecting: stateValue)
                for innerChild in childMirror.children {
                    if innerChild.label == "storage" {
                        // Found the StateStorage - set up callback
                        // This is the connection point for state updates
                        if let storage = innerChild.value as? AnyObject {
                            // Use reflection to call setUpdateCallback
                            // In practice, this would be done through a protocol method
                        }
                    }
                }
            }
        }
    }

    /// Internal render method that performs the actual rendering
    /// - Parameter view: SwiftUI-style view to render
    private func internalRender<V: View>(view: V) async {
        let newRoot = convertViewToVNode(view)
        let newTree = VTree(root: newRoot)

        if let oldTree = currentTree {
            // Perform diff and update
            let patches = differ.diff(old: oldTree.root, new: newTree.root)
            await applyPatches(patches)
            currentTree = newTree
        } else {
            // Initial render - mount the entire tree
            await mountTree(newRoot)
            currentTree = newTree
        }
    }

    /// Schedule an update to be batched with other pending updates
    /// Uses requestAnimationFrame-equivalent batching for performance
    public func scheduleUpdate() {
        guard !updatePending else { return }

        updatePending = true

        // In WASM environment, this would use requestAnimationFrame
        // For now, we execute immediately but maintain the batching flag
        Task { @MainActor in
            self.performUpdate()
        }
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
        // Check if this is a primitive view (Body == Never)
        if isPrimitiveView(view) {
            return convertPrimitiveView(view)
        }

        // Otherwise, recursively walk the body
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

    /// Convert a primitive view to VNode
    /// This handles the base cases like Text, Image, etc.
    /// - Parameter view: Primitive view to convert
    /// - Returns: VNode representation
    private func convertPrimitiveView<V: View>(_ view: V) -> VNode {
        // Handle specific primitive types

        // Text view handling (for now, basic implementation)
        if let textView = view as? Text {
            return convertTextView(textView)
        }

        // Button view handling
        if let buttonNode = extractButtonView(view) {
            return buttonNode
        }

        // VStack view handling
        if let vstackView = extractVStack(view) {
            return vstackView
        }

        // HStack view handling
        if let hstackView = extractHStack(view) {
            return hstackView
        }

        // EmptyView
        if view is EmptyView {
            return VNode.fragment(children: [])
        }

        // TupleView - handle multiple children
        if let tupleView = extractTupleView(view) {
            return tupleView
        }

        // ConditionalContent - handle if/else branches
        if let conditionalNode = extractConditionalContent(view) {
            return conditionalNode
        }

        // OptionalContent - handle optional views
        if let optionalNode = extractOptionalContent(view) {
            return optionalNode
        }

        // ForEachView - handle arrays of views (from ViewBuilder)
        if let forEachNode = extractForEachView(view) {
            return forEachNode
        }

        // ForEach - handle ForEach views
        if let forEachNode = extractForEach(view) {
            return forEachNode
        }

        // AnyView - handle type-erased views
        if let anyView = view as? AnyView {
            return anyView.render()
        }

        // Default: create a component node with type information
        return VNode.component(
            props: [:],
            children: [],
            key: String(describing: V.self)
        )
    }

    /// Convert a Text view to VNode
    /// - Parameter text: Text view to convert
    /// - Returns: VNode representing the text
    private func convertTextView(_ text: Text) -> VNode {
        // Text views render as text nodes
        // Use the Text view's built-in toVNode method
        return text.toVNode()
    }

    /// Extract and convert Button view with proper event handler registration
    /// - Parameter view: View that might be a Button
    /// - Returns: VNode if this is a Button, nil otherwise
    private func extractButtonView<V: View>(_ view: V) -> VNode? {
        // Use reflection to check if this is a Button
        let mirror = Mirror(reflecting: view)

        // Check for Button properties
        var action: Any?
        var label: Any?

        for child in mirror.children {
            switch child.label {
            case "action":
                action = child.value
            case "label":
                label = child.value
            default:
                break
            }
        }

        // If we found both action and label, this is a Button
        guard action != nil, let labelView = label as? (any View) else {
            return nil
        }

        // Generate a unique ID for this event handler
        let handlerID = UUID()

        // Extract the action closure using a type-erased approach
        // We need to use reflection to get the actual closure
        if let buttonAny = view as? any View {
            // Try to cast to Button with Text label (most common case)
            if let button = buttonAny as? Button<Text> {
                registerEventHandler(id: handlerID, action: button.actionClosure)
            } else if let button = buttonAny as? Button<AnyView> {
                registerEventHandler(id: handlerID, action: button.actionClosure)
            } else {
                // For other label types, we need a more generic approach
                // For now, register a placeholder that logs
                registerEventHandler(id: handlerID, action: {
                    print("Button clicked but action not properly extracted")
                })
            }
        }

        // Create the click event handler property
        let clickHandler = VProperty.eventHandler(event: "click", handlerID: handlerID)

        // Create button element with event handler
        let props: [String: VProperty] = [
            "onClick": clickHandler
        ]

        // Convert label to children nodes
        let children = [convertViewToVNode(labelView)]

        return VNode.element(
            "button",
            props: props,
            children: children
        )
    }

    /// Register an event handler in the registry
    /// - Parameters:
    ///   - id: Unique identifier for the handler
    ///   - action: Action closure to register
    private func registerEventHandler(id: UUID, action: @escaping @Sendable @MainActor () -> Void) {
        // Wrap the action to trigger a re-render after execution
        let wrappedAction: @Sendable @MainActor () -> Void = { [weak self] in
            // Execute the original action
            action()

            // Trigger a re-render
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                if let rerender = self.rerenderClosure {
                    await rerender()
                }
            }
        }

        eventHandlerRegistry[id] = wrappedAction
    }

    /// Extract and convert VStack with children
    private func extractVStack<V: View>(_ view: V) -> VNode? {
        // Use reflection to extract VStack and its content
        let mirror = Mirror(reflecting: view)

        // Check if this is a VStack by looking for the required properties
        var alignment: HorizontalAlignment?
        var spacingOpt: Double??
        var content: Any?

        for child in mirror.children {
            switch child.label {
            case "alignment":
                alignment = child.value as? HorizontalAlignment
            case "spacing":
                spacingOpt = child.value as? Double?
            case "content":
                content = child.value
            default:
                break
            }
        }

        // If we found the required VStack properties, convert it
        guard alignment != nil else { return nil }

        // Create the VStack container node using its toVNode method
        // We need to use a type-specific approach here
        // For now, create a basic flexbox div manually
        var props: [String: VProperty] = [
            "display": .style(name: "display", value: "flex"),
            "flex-direction": .style(name: "flex-direction", value: "column"),
            "align-items": .style(name: "align-items", value: alignment!.cssValue)
        ]

        if let spacing = spacingOpt ?? nil {
            props["gap"] = .style(name: "gap", value: "\(spacing)px")
        }

        // Convert children
        var children: [VNode] = []
        if let contentView = content as? (any View) {
            children = [convertViewToVNode(contentView)]
        }

        return VNode.element("div", props: props, children: children)
    }

    /// Extract and convert HStack with children
    private func extractHStack<V: View>(_ view: V) -> VNode? {
        // Use reflection to extract HStack and its content
        let mirror = Mirror(reflecting: view)

        // Check if this is an HStack by looking for the required properties
        var alignment: VerticalAlignment?
        var spacingOpt: Double??
        var content: Any?

        for child in mirror.children {
            switch child.label {
            case "alignment":
                alignment = child.value as? VerticalAlignment
            case "spacing":
                spacingOpt = child.value as? Double?
            case "content":
                content = child.value
            default:
                break
            }
        }

        // If we found the required HStack properties, convert it
        guard alignment != nil else { return nil }

        // Create the HStack container node
        var props: [String: VProperty] = [
            "display": .style(name: "display", value: "flex"),
            "flex-direction": .style(name: "flex-direction", value: "row"),
            "align-items": .style(name: "align-items", value: alignment!.cssValue)
        ]

        if let spacing = spacingOpt ?? nil {
            props["gap"] = .style(name: "gap", value: "\(spacing)px")
        }

        // Convert children
        var children: [VNode] = []
        if let contentView = content as? (any View) {
            children = [convertViewToVNode(contentView)]
        }

        return VNode.element("div", props: props, children: children)
    }

    // MARK: - ViewBuilder Construct Handlers

    /// Extract and convert TupleView
    private func extractTupleView<V: View>(_ view: V) -> VNode? {
        // Handle different tuple sizes
        // TupleView wraps multiple views in a tuple

        if let tuple2 = view as? TupleView<(any View, any View)> {
            let children = extractTuple2(tuple2.content)
            return VNode.fragment(children: children)
        }

        if let tuple3 = view as? TupleView<(any View, any View, any View)> {
            let children = extractTuple3(tuple3.content)
            return VNode.fragment(children: children)
        }

        // Add more tuple sizes as needed...
        // For now, return nil for unsupported sizes
        return nil
    }

    /// Extract views from a 2-element tuple
    private func extractTuple2(_ tuple: (any View, any View)) -> [VNode] {
        [
            convertViewToVNode(tuple.0),
            convertViewToVNode(tuple.1)
        ]
    }

    /// Extract views from a 3-element tuple
    private func extractTuple3(_ tuple: (any View, any View, any View)) -> [VNode] {
        [
            convertViewToVNode(tuple.0),
            convertViewToVNode(tuple.1),
            convertViewToVNode(tuple.2)
        ]
    }

    /// Extract and convert ConditionalContent
    private func extractConditionalContent<V: View>(_ view: V) -> VNode? {
        // ConditionalContent represents if/else branches
        // We need to check which branch is active and render that

        // This is a simplified implementation
        // In reality, we'd need to use reflection or a different approach
        // to extract the actual conditional content

        return nil
    }

    /// Extract and convert OptionalContent
    private func extractOptionalContent<V: View>(_ view: V) -> VNode? {
        // OptionalContent wraps an optional view
        // Render the view if present, otherwise return empty fragment

        return nil
    }

    /// Extract and convert ForEachView (from ViewBuilder)
    private func extractForEachView<V: View>(_ view: V) -> VNode? {
        // ForEachView contains an array of views
        // Render each view and collect into a fragment

        let mirror = Mirror(reflecting: view)

        for child in mirror.children {
            if child.label == "views" {
                // Extract the array of views
                if let views = child.value as? [any View] {
                    let children = views.map { convertViewToVNode($0) }
                    return VNode.fragment(children: children)
                }
            }
        }

        return nil
    }

    /// Extract and convert ForEach view
    private func extractForEach<V: View>(_ view: V) -> VNode? {
        // Use reflection to extract ForEach properties
        let mirror = Mirror(reflecting: view)

        var data: Any?
        var idKeyPath: Any?
        var content: Any?

        for child in mirror.children {
            switch child.label {
            case "data":
                data = child.value
            case "idKeyPath":
                idKeyPath = child.value
            case "content":
                content = child.value
            default:
                break
            }
        }

        // If we found the ForEach properties, iterate and generate children
        guard let contentClosure = content else {
            return nil
        }

        // We need to iterate over the data collection
        // This is complex due to Swift's type system, so we use a simplified approach
        // In a real implementation, we would use a more robust reflection mechanism

        var children: [VNode] = []

        // Try to handle common cases: Range<Int> and Array
        if let range = data as? Range<Int> {
            // Handle Range<Int>
            for index in range {
                // Create a view by calling the content closure with the index
                // This requires runtime casting which is not type-safe
                // For now, we'll use a workaround with reflection

                // Try to call the closure - this is the tricky part
                // We'll need to use a generic approach here
                if let view = callContentClosure(contentClosure, with: index) {
                    var node = convertViewToVNode(view)
                    // Set stable key
                    node = VNode(
                        id: node.id,
                        type: node.type,
                        props: node.props,
                        children: node.children,
                        key: "\(index)"
                    )
                    children.append(node)
                }
            }
        } else if let array = data as? [any Sendable] {
            // Handle array collections
            for (index, element) in array.enumerated() {
                if let view = callContentClosure(contentClosure, with: element) {
                    var node = convertViewToVNode(view)
                    // Try to extract ID for stable key
                    let key = extractID(from: element, keyPath: idKeyPath) ?? "\(index)"
                    node = VNode(
                        id: node.id,
                        type: node.type,
                        props: node.props,
                        children: node.children,
                        key: key
                    )
                    children.append(node)
                }
            }
        }

        return VNode.fragment(children: children)
    }

    /// Helper to call a content closure with an element (uses reflection)
    private func callContentClosure(_ closure: Any, with element: Any) -> (any View)? {
        // This is a simplified implementation
        // In a real implementation, we would use proper type-safe mechanisms
        // For now, we return nil to indicate this needs proper implementation
        // The actual implementation would require more sophisticated reflection
        // or a protocol-based approach
        return nil
    }

    /// Helper to extract ID from an element using a key path
    private func extractID(from element: Any, keyPath: Any?) -> String? {
        // Try to extract the ID using the key path
        // This requires reflection or a protocol-based approach

        // Check if element is Identifiable
        if let identifiable = element as? any Identifiable {
            return String(describing: identifiable.id)
        }

        return nil
    }

    // MARK: - DOM Operations

    /// Set the root container element
    /// - Parameter container: JSObject representing the container DOM element
    public func setRootContainer(_ container: JSObject) {
        self.rootContainer = container
    }

    /// Mount a virtual tree to the DOM
    /// - Parameter node: Root VNode to mount
    private func mountTree(_ node: VNode) async {
        guard let container = rootContainer else {
            print("Warning: No root container set for mounting")
            return
        }

        let domNode = await createDOMNode(node)
        await DOMBridge.shared.appendChild(parent: container, child: domNode)
        await DOMBridge.shared.registerNode(id: node.id, element: domNode)
    }

    /// Recursively create DOM nodes from VNode
    /// - Parameter node: VNode to convert
    /// - Returns: JSObject representing the DOM node
    private func createDOMNode(_ node: VNode) async -> JSObject {
        let domNode: JSObject

        switch node.type {
        case .element(let tag):
            domNode = await DOMBridge.shared.createElement(tag: tag)

            // Apply properties
            for (_, property) in node.props {
                await applyProperty(property, to: domNode)
            }

            // Attach gesture event listeners
            for gestureReg in node.gestures {
                await attachGestureListeners(gestureReg, to: domNode)
            }

            // Create and append children
            for child in node.children {
                let childDOMNode = await createDOMNode(child)
                await DOMBridge.shared.appendChild(parent: domNode, child: childDOMNode)
                await DOMBridge.shared.registerNode(id: child.id, element: childDOMNode)
            }

        case .text(let content):
            domNode = await DOMBridge.shared.createTextNode(text: content)

        case .fragment:
            // Fragments don't create a wrapper element
            // For now, create a document fragment or just return a div
            domNode = await DOMBridge.shared.createElement(tag: "div")
            for child in node.children {
                let childDOMNode = await createDOMNode(child)
                await DOMBridge.shared.appendChild(parent: domNode, child: childDOMNode)
                await DOMBridge.shared.registerNode(id: child.id, element: childDOMNode)
            }

        case .component:
            // Components are already expanded during VNode conversion
            domNode = await DOMBridge.shared.createElement(tag: "div")
        }

        return domNode
    }

    /// Apply a property to a DOM element
    /// - Parameters:
    ///   - property: VProperty to apply
    ///   - element: JSObject representing the DOM element
    private func applyProperty(_ property: VProperty, to element: JSObject) async {
        switch property {
        case .attribute(let name, let value):
            await DOMBridge.shared.setAttribute(element: element, name: name, value: value)

        case .style(let name, let value):
            await DOMBridge.shared.setStyle(element: element, name: name, value: value)

        case .boolAttribute(let name, let value):
            if value {
                await DOMBridge.shared.setAttribute(element: element, name: name, value: name)
            } else {
                await DOMBridge.shared.removeAttribute(element: element, name: name)
            }

        case .eventHandler(let event, let handlerID):
            // Look up the handler in our registry and register it with DOMBridge
            if let handler = eventHandlerRegistry[handlerID] {
                await DOMBridge.shared.addEventListener(
                    element: element,
                    event: event,
                    handlerID: handlerID,
                    handler: handler
                )
            } else {
                print("Warning: Event handler not found in registry: \(handlerID)")
            }
        }
    }

    // MARK: - Patch Application

    /// Apply patches to the DOM
    /// - Parameter patches: Array of patches from diffing algorithm
    private func applyPatches(_ patches: [Patch]) async {
        for patch in patches {
            await applyPatch(patch)
        }
    }

    /// Apply a single patch to the DOM
    /// - Parameter patch: Patch to apply
    private func applyPatch(_ patch: Patch) async {
        switch patch {
        case .insert(let parentID, let node, let index):
            guard let parentElement = await DOMBridge.shared.getNode(id: parentID) else {
                print("Warning: Parent node not found for insert: \(parentID)")
                return
            }

            let newElement = await createDOMNode(node)

            // Get the reference child at index
            if index < Int(parentElement.childNodes.length.number ?? 0) {
                let referenceChild = parentElement.childNodes[index].object
                await DOMBridge.shared.insertBefore(parent: parentElement, new: newElement, reference: referenceChild)
            } else {
                await DOMBridge.shared.appendChild(parent: parentElement, child: newElement)
            }

            await DOMBridge.shared.registerNode(id: node.id, element: newElement)

        case .remove(let nodeID):
            guard let element = await DOMBridge.shared.getNode(id: nodeID) else {
                print("Warning: Node not found for removal: \(nodeID)")
                return
            }

            if let parent = element.parentNode.object {
                await DOMBridge.shared.removeChild(parent: parent, child: element)
            }
            await DOMBridge.shared.unregisterNode(id: nodeID)

        case .replace(let oldID, let newNode):
            guard let oldElement = await DOMBridge.shared.getNode(id: oldID),
                  let parent = oldElement.parentNode.object else {
                print("Warning: Old node not found for replacement: \(oldID)")
                return
            }

            let newElement = await createDOMNode(newNode)
            await DOMBridge.shared.replaceChild(parent: parent, old: oldElement, new: newElement)
            await DOMBridge.shared.unregisterNode(id: oldID)
            await DOMBridge.shared.registerNode(id: newNode.id, element: newElement)

        case .updateProps(let nodeID, let propPatches):
            guard let element = await DOMBridge.shared.getNode(id: nodeID) else {
                print("Warning: Node not found for property update: \(nodeID)")
                return
            }

            for propPatch in propPatches {
                await applyPropPatch(propPatch, to: element)
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
    private func applyPropPatch(_ patch: PropPatch, to element: JSObject) async {
        switch patch {
        case .add(let key, let value), .update(let key, let value):
            await applyProperty(value, to: element)

        case .remove(let key):
            // Determine the property type from the key and remove it
            // This is simplified; in a real implementation, we'd track property types
            await DOMBridge.shared.removeAttribute(element: element, name: key)
        }
    }

    // MARK: - Gesture Support

    /// Attach gesture event listeners to a DOM element
    /// - Parameters:
    ///   - registration: Gesture registration with event names and handler ID
    ///   - element: DOM element to attach listeners to
    private func attachGestureListeners(_ registration: GestureRegistration, to element: JSObject) async {
        // For each event the gesture needs, attach a listener
        for eventName in registration.events {
            // Create a handler that will process the gesture event
            let handler: @Sendable @MainActor () -> Void = { [weak self] in
                guard let self = self else { return }
                Task { @MainActor in
                    await self.handleGestureEvent(
                        handlerID: registration.handlerID,
                        eventName: eventName,
                        priority: registration.priority
                    )
                }
            }

            // Register with DOMBridge
            await DOMBridge.shared.addEventListener(
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
    private func handleGestureEvent(
        handlerID: UUID,
        eventName: String,
        priority: GesturePriority
    ) async {
        // Look up the gesture handler
        guard let handler = gestureHandlerRegistry[handlerID] else {
            return
        }

        // Create a placeholder gesture value
        // In a real implementation, this would extract event data from the DOM event
        // and convert it to the appropriate gesture value type
        let gestureValue: Any = ()

        // Invoke the handler
        handler(gestureValue)

        // Trigger re-render if needed
        if let rerender = rerenderClosure {
            await rerender()
        }
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
}

