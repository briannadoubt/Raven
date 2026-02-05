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
        // Pad with leading zeros
        let high = String(repeating: "0", count: max(0, 8 - highHex.count)) + highHex
        let low = String(repeating: "0", count: max(0, 12 - lowHex.count)) + lowHex
        let uuidString = "\(high)-0000-4000-8000-\(low)"
        let console = JSObject.global.console
        _ = console.log("[Swift generateHandlerID] ✅ Counter: \(handlerIDCounter), String: \(uuidString)")
        let result = UUID(uuidString: uuidString) ?? UUID()
        _ = console.log("[Swift generateHandlerID] ✅ Result UUID: \(result)")
        return result
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
    private func internalRender<V: View>(view: V) {
        let console = JSObject.global.console
        _ = console.log("[Swift Render] 🎨 internalRender called for: \(V.self)")

        let newRoot = convertViewToVNode(view)

        _ = console.log("[Swift Render] VNode type: \(newRoot.type)")
        _ = console.log("[Swift Render] VNode children count: \(newRoot.children.count)")

        let newTree = VTree(root: newRoot)

        if let oldTree = currentTree {
            // Perform diff and update
            _ = console.log("[Swift Render] 🔄 Re-render detected, computing diff...")
            let patches = differ.diff(old: oldTree.root, new: newTree.root)
            _ = console.log("[Swift Render] Generated \(patches.count) patches")
            applyPatches(patches)
            currentTree = newTree
            _ = console.log("[Swift Render] ✅ Patches applied, re-render complete!")
        } else {
            // Initial render - mount the entire tree
            _ = console.log("[Swift Render] Mounting tree to DOM")
            mountTree(newRoot)
            currentTree = newTree
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
        let console = JSObject.global.console
        _ = console.log("[Swift Render] convertViewToVNode: \(V.self)")

        // Check if this is a primitive view (Body == Never)
        if isPrimitiveView(view) {
            _ = console.log("[Swift Render] \(V.self) is primitive")
            return convertPrimitiveView(view)
        }

        // Otherwise, recursively walk the body
        _ = console.log("[Swift Render] \(V.self) is composite, getting body")
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

        // TextField view handling
        if let textFieldNode = extractTextField(view) {
            return textFieldNode
        }

        // VStack view handling
        if let vstackView = extractVStack(view) {
            return vstackView
        }

        // HStack view handling
        if let hstackView = extractHStack(view) {
            return hstackView
        }

        // List view handling
        if let listView = extractList(view) {
            return listView
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
        let handlerID = generateHandlerID()

        // Extract the action closure using a type-erased approach
        // We need to use reflection to get the actual closure
        let console = JSObject.global.console
        if let buttonAny = view as? any View {
            // Try to cast to Button with Text label (most common case)
            if let button = buttonAny as? Button<Text> {
                _ = console.log("[Swift RenderLoop] ✅ Button<Text> cast successful, registering action")
                registerEventHandler(id: handlerID, action: button.actionClosure)
            } else if let button = buttonAny as? Button<AnyView> {
                _ = console.log("[Swift RenderLoop] ✅ Button<AnyView> cast successful, registering action")
                registerEventHandler(id: handlerID, action: button.actionClosure)
            } else {
                _ = console.log("[Swift RenderLoop] ⚠️ Button cast failed, using placeholder action")
                // For other label types, we need a more generic approach
                // For now, register a placeholder that logs
                registerEventHandler(id: handlerID, action: {
                    _ = console.log("[Swift] Button clicked but action not properly extracted")
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
        let console = JSObject.global.console
        // Wrap the action to trigger a re-render after execution
        let wrappedAction: @Sendable @MainActor () -> Void = { [weak self] in
            _ = console.log("[Swift RenderLoop] 🎬 Wrapped action executing for handlerID: \(id)")
            // Execute the original action
            action()
            _ = console.log("[Swift RenderLoop] ✅ Original action completed")

            // Trigger a re-render (now synchronous)
            guard let self = self else {
                _ = console.log("[Swift RenderLoop] ⚠️ Self is nil, cannot re-render")
                return
            }
            if let rerender = self.rerenderClosure {
                _ = console.log("[Swift RenderLoop] 🔄 Triggering re-render...")
                rerender()
                _ = console.log("[Swift RenderLoop] ✅ Re-render completed")
            } else {
                _ = console.log("[Swift RenderLoop] ⚠️ No rerenderClosure available")
            }
        }

        eventHandlerRegistry[id] = wrappedAction
        _ = console.log("[Swift RenderLoop] ✅ Registered handler for ID: \(id)")
    }

    /// Extract and convert TextField with proper event handler registration
    /// - Parameter view: View that might be a TextField
    /// - Returns: VNode if this is a TextField, nil otherwise
    private func extractTextField<V: View>(_ view: V) -> VNode? {
        // Check if this is a TextField and extract its properties using reflection
        let mirror = Mirror(reflecting: view)

        var placeholder: String?
        var textBinding: Binding<String>?

        for child in mirror.children {
            switch child.label {
            case "placeholder":
                placeholder = child.value as? String
            case "text":
                textBinding = child.value as? Binding<String>
            default:
                break
            }
        }

        // If we found both required properties, this is a TextField
        guard let placeholderText = placeholder,
              let binding = textBinding else {
            return nil
        }

        // Generate a unique ID for the input event handler
        let handlerID = generateHandlerID()

        // Register the input event handler that updates the binding
        registerInputEventHandler(id: handlerID, binding: binding)

        // Reconstruct the VNode with our registered handler ID
        let inputHandler = VProperty.eventHandler(event: "input", handlerID: handlerID)

        var props: [String: VProperty] = [
            // Input type
            "type": .attribute(name: "type", value: "text"),

            // Placeholder from TextField
            "placeholder": .attribute(name: "placeholder", value: placeholderText),

            // Current value (reflects the binding)
            "value": .attribute(name: "value", value: binding.wrappedValue),

            // Input event handler
            "onInput": inputHandler,

            // Default styling
            "padding": .style(name: "padding", value: "8px"),
            "border": .style(name: "border", value: "1px solid #ccc"),
            "border-radius": .style(name: "border-radius", value: "4px"),
            "font-size": .style(name: "font-size", value: "14px"),
            "width": .style(name: "width", value: "100%"),
            "box-sizing": .style(name: "box-sizing", value: "border-box"),
        ]

        // ARIA attributes
        props["aria-label"] = .attribute(name: "aria-label", value: placeholderText)
        props["role"] = .attribute(name: "role", value: "textbox")

        return VNode.element(
            "input",
            props: props,
            children: []
        )
    }

    /// Register an input event handler that extracts the value and updates a binding
    /// - Parameters:
    ///   - id: Unique identifier for the handler
    ///   - binding: String binding to update when input changes
    private func registerInputEventHandler(id: UUID, binding: Binding<String>) {
        // Store the binding in a way we can access it from the event handler
        // For now, we'll use a simpler approach: register a handler that will
        // extract the value via JavaScript when the event fires

        // The handler needs to:
        // 1. Extract the new value from the input element
        // 2. Update the binding
        // 3. Trigger a re-render

        // Since our current architecture doesn't pass event objects to handlers,
        // we need to use a workaround. We'll use DOMBridge to find the element
        // by its handler ID and extract its value.

        // For now, create a simple handler that just triggers re-render
        // The actual value extraction will happen in the modified DOMBridge
        let wrappedAction: @Sendable @MainActor () -> Void = { [weak self] in
            // Note: In a proper implementation, we would extract event.target.value here
            // For now, this is a placeholder that shows the architecture needs updating

            guard let self = self else { return }

            // Trigger a re-render to reflect any state changes
            if let rerender = self.rerenderClosure {
                rerender()
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
            let childVNode = convertViewToVNode(contentView)
            // If the child is a fragment (like TupleView), use its children directly
            // Otherwise, use the child itself
            if case .fragment = childVNode.type {
                children = childVNode.children
            } else {
                children = [childVNode]
            }
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
            let childVNode = convertViewToVNode(contentView)
            // If the child is a fragment (like TupleView), use its children directly
            // Otherwise, use the child itself
            if case .fragment = childVNode.type {
                children = childVNode.children
            } else {
                children = [childVNode]
            }
        }

        return VNode.element("div", props: props, children: children)
    }

    // MARK: - ViewBuilder Construct Handlers

    /// Extract and convert TupleView using parameter pack iteration via _ViewTuple protocol
    /// The protocol conformance uses parameter packs to iterate over tuple elements
    private func extractTupleView<V: View>(_ view: V) -> VNode? {
        // Check if this view conforms to _ViewTuple protocol
        // TupleView conforms when T is a parameter pack of Views
        guard let viewTuple = view as? any _ViewTuple else {
            return nil
        }

        // Extract children using parameter packs (via protocol implementation)
        let childViews = viewTuple._extractChildren()
        let children = childViews.map { convertViewToVNode($0) }

        return VNode.fragment(children: children)
    }

    /// Extract and convert List with children
    private func extractList<V: View>(_ view: V) -> VNode? {
        // Use reflection to extract List and its content
        let mirror = Mirror(reflecting: view)

        var content: Any?

        for child in mirror.children {
            if child.label == "content" {
                content = child.value
                break
            }
        }

        // If we didn't find content, this might not be a List
        guard let contentView = content as? (any View) else {
            return nil
        }

        // Create the List container node with proper styling
        var props: [String: VProperty] = [
            // ARIA role for accessibility
            "role": .attribute(name: "role", value: "list"),

            // Layout styles
            "display": .style(name: "display", value: "flex"),
            "flex-direction": .style(name: "flex-direction", value: "column"),

            // Scrolling behavior
            "overflow-y": .style(name: "overflow-y", value: "auto"),

            // Default styling
            "width": .style(name: "width", value: "100%"),
            "gap": .style(name: "gap", value: "8px"),
        ]

        // Convert children
        var children: [VNode] = []
        let childVNode = convertViewToVNode(contentView)

        // If the child is a fragment (like ForEach), use its children directly
        // Otherwise, use the child itself
        if case .fragment = childVNode.type {
            children = childVNode.children
        } else {
            children = [childVNode]
        }

        return VNode.element("div", props: props, children: children)
    }

    /// Extract and convert ConditionalContent
    private func extractConditionalContent<V: View>(_ view: V) -> VNode? {
        // ConditionalContent represents if/else branches
        // We need to check which branch is active and render that

        let mirror = Mirror(reflecting: view)

        // ConditionalContent has a "storage" property that contains either
        // .trueContent or .falseContent
        for child in mirror.children {
            if child.label == "storage" {
                // Extract the storage enum
                let storageMirror = Mirror(reflecting: child.value)

                // Check which case is active
                if let caseName = storageMirror.children.first?.label {
                    // Get the associated value (the actual view)
                    if let content = storageMirror.children.first?.value as? (any View) {
                        // Render the active branch
                        return convertViewToVNode(content)
                    }
                }
            }
        }

        return nil
    }

    /// Extract and convert OptionalContent
    private func extractOptionalContent<V: View>(_ view: V) -> VNode? {
        // OptionalContent wraps an optional view
        // Render the view if present, otherwise return empty fragment

        let mirror = Mirror(reflecting: view)

        // OptionalContent has a "content" property that is Optional<some View>
        for child in mirror.children {
            if child.label == "content" {
                // Check if the optional has a value
                let contentMirror = Mirror(reflecting: child.value)

                if contentMirror.displayStyle == .optional {
                    // Check if it's nil or has a value
                    if contentMirror.children.isEmpty {
                        // nil - return empty fragment
                        return VNode.fragment(children: [])
                    } else if let some = contentMirror.children.first?.value as? (any View) {
                        // Has a value - render it
                        return convertViewToVNode(some)
                    }
                }
            }
        }

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
            // For now, create a document fragment or just return a div
            guard let fragment = DOMBridge.shared.createElement(tag: "div") else {
                return nil
            }
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
            // Look up the handler in our registry and register it with DOMBridge
            let console = JSObject.global.console
            if let handler = eventHandlerRegistry[handlerID] {
                _ = console.log("[Swift RenderLoop] 🔌 Adding \(event) listener to element, handlerID: \(handlerID)")
                DOMBridge.shared.addEventListener(
                    element: element,
                    event: event,
                    handlerID: handlerID,
                    handler: handler
                )
                _ = console.log("[Swift RenderLoop] ✅ addEventListener completed")
            } else {
                _ = console.log("[Swift RenderLoop] ⚠️ Event handler not found in registry: \(handlerID)")
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

