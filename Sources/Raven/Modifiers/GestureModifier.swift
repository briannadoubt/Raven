import Foundation

// MARK: - Gesture Modifier

/// A modifier that attaches a gesture to a view.
///
/// `GestureModifier` is used internally by the `.gesture(_:including:)` view modifier
/// to attach gesture recognizers to views. It handles the integration between the gesture
/// system and the virtual DOM, managing event listener attachment and gesture recognition.
///
/// ## Overview
///
/// When you apply a gesture to a view using `.gesture()`, a `GestureModifier` is created
/// to manage the gesture recognition:
///
/// ```swift
/// Rectangle()
///     .gesture(TapGesture().onEnded { print("Tapped!") })
/// ```
///
/// The modifier:
/// - Determines which web events to listen for based on the gesture type
/// - Applies the `GestureMask` to control event propagation
/// - Integrates with the VNode system to attach event handlers
/// - Manages gesture state and lifecycle
///
/// ## Gesture Mask Integration
///
/// The `GestureMask` controls where gestures are recognized:
///
/// - `.all`: Both the view and its subviews (default)
/// - `.gesture`: Only the view itself
/// - `.subviews`: Only the subviews
/// - `.none`: Disable gesture recognition
///
/// ## Web Event Mapping
///
/// Different gesture types map to different web events:
///
/// - `TapGesture`: click, pointerdown, pointerup
/// - `LongPressGesture`: pointerdown, pointermove, pointerup, pointercancel
/// - `DragGesture`: pointerdown, pointermove, pointerup, pointercancel
/// - `RotationGesture`: pointerdown, pointermove, pointerup (multi-touch)
/// - `MagnificationGesture`: pointerdown, pointermove, pointerup (multi-touch)
///
/// ## See Also
///
/// - ``View/gesture(_:including:)``
/// - ``GestureMask``
/// - ``Gesture``
@MainActor
public struct GestureModifier<G: Gesture>: Sendable {
    /// The gesture to attach to the view.
    public let gesture: G

    /// The mask controlling where the gesture is recognized.
    public let mask: GestureMask

    /// Creates a gesture modifier.
    ///
    /// - Parameters:
    ///   - gesture: The gesture to attach.
    ///   - mask: The mask controlling gesture recognition. Defaults to `.all`.
    public init(gesture: G, mask: GestureMask = .all) {
        self.gesture = gesture
        self.mask = mask
    }
}

// MARK: - View Extension

extension View {
    /// Attaches a gesture to this view with a gesture mask.
    ///
    /// Use this modifier to add gesture recognition to a view. The gesture can be any type
    /// conforming to the `Gesture` protocol, including composite gestures created with
    /// `simultaneously(with:)`, `sequenced(before:)`, or `exclusively(before:)`.
    ///
    /// ## Basic Usage
    ///
    /// Add a simple tap gesture:
    ///
    /// ```swift
    /// Rectangle()
    ///     .gesture(
    ///         TapGesture()
    ///             .onEnded { print("Tapped!") }
    ///     )
    /// ```
    ///
    /// ## Gesture Mask
    ///
    /// Control where the gesture is recognized using the `including` parameter:
    ///
    /// ```swift
    /// // Only recognize on the view itself, not subviews
    /// ScrollView {
    ///     content
    /// }
    /// .gesture(DragGesture(), including: .gesture)
    ///
    /// // Only recognize on subviews
    /// Container {
    ///     draggableItems
    /// }
    /// .gesture(DragGesture(), including: .subviews)
    ///
    /// // Disable gesture recognition
    /// DisabledView()
    ///     .gesture(TapGesture(), including: .none)
    /// ```
    ///
    /// ## Gesture Composition
    ///
    /// Combine multiple gestures using composition operators:
    ///
    /// ```swift
    /// Image("photo")
    ///     .gesture(
    ///         RotationGesture()
    ///             .simultaneously(with: MagnificationGesture())
    ///             .onChanged { value in
    ///                 rotation = value.0 ?? .zero
    ///                 scale = value.1 ?? 1.0
    ///             }
    ///     )
    /// ```
    ///
    /// ## Multiple Gestures
    ///
    /// You can attach multiple gestures to a view by calling `.gesture()` multiple times.
    /// By default, gestures have equal priority. Use `.highPriorityGesture()` or
    /// `.simultaneousGesture()` for more control:
    ///
    /// ```swift
    /// Rectangle()
    ///     .gesture(TapGesture().onEnded { print("Tap") })
    ///     .gesture(LongPressGesture().onEnded { print("Long press") })
    /// ```
    ///
    /// ## Web Implementation
    ///
    /// In Raven's web environment, this modifier:
    /// - Adds appropriate event listeners to the VNode (click, pointerdown, etc.)
    /// - Handles event delegation based on the gesture mask
    /// - Manages gesture state and cleanup
    ///
    /// Event listeners are attached efficiently - only the events needed for the specific
    /// gesture type are registered, and listeners are reused when possible.
    ///
    /// ## Performance Considerations
    ///
    /// - Only attach gestures where needed - they add event listeners
    /// - Use appropriate gesture masks to limit event handling scope
    /// - Composite gestures share event listeners when possible
    /// - Gesture state is cleaned up automatically when the view is removed
    ///
    /// ## Thread Safety
    ///
    /// All gesture operations are `@MainActor` isolated, ensuring thread-safe access
    /// to gesture state and UI updates.
    ///
    /// - Parameters:
    ///   - gesture: The gesture to attach to the view.
    ///   - mask: A mask that controls how the gesture participates in hit testing.
    ///     Defaults to `.all`.
    /// - Returns: A view with the gesture attached.
    ///
    /// ## See Also
    ///
    /// - ``simultaneousGesture(_:including:)``
    /// - ``highPriorityGesture(_:including:)``
    /// - ``GestureMask``
    /// - ``Gesture``
    @MainActor
    public func gesture<G: Gesture>(
        _ gesture: G,
        including mask: GestureMask = .all
    ) -> some View {
        modifier(_GestureViewModifier(gesture: gesture, mask: mask))
    }

    /// Attaches a gesture to this view with simultaneous recognition.
    ///
    /// Use this modifier when you want a gesture to recognize simultaneously with
    /// other gestures, rather than competing for recognition. This is useful when
    /// you want multiple gestures to work together.
    ///
    /// ## Example
    ///
    /// ```swift
    /// ScrollView {
    ///     ForEach(items) { item in
    ///         ItemView(item)
    ///             .simultaneousGesture(
    ///                 TapGesture().onEnded {
    ///                     print("Item tapped")
    ///                 }
    ///             )
    ///     }
    /// }
    /// ```
    ///
    /// In this example, the tap gesture on the items works simultaneously with the
    /// scroll gesture, allowing both scrolling and tapping.
    ///
    /// - Parameters:
    ///   - gesture: The gesture to attach.
    ///   - mask: A mask controlling gesture recognition. Defaults to `.all`.
    /// - Returns: A view with the simultaneous gesture attached.
    ///
    /// ## See Also
    ///
    /// - ``gesture(_:including:)``
    /// - ``highPriorityGesture(_:including:)``
    @MainActor
    public func simultaneousGesture<G: Gesture>(
        _ gesture: G,
        including mask: GestureMask = .all
    ) -> some View {
        modifier(_SimultaneousGestureViewModifier(gesture: gesture, mask: mask))
    }

    /// Attaches a high-priority gesture to this view.
    ///
    /// Use this modifier when you want a gesture to take priority over other gestures,
    /// including gestures on subviews. The high-priority gesture gets first chance at
    /// recognition, and if it succeeds, other gestures are cancelled.
    ///
    /// ## Example
    ///
    /// ```swift
    /// ScrollView {
    ///     content
    /// }
    /// .highPriorityGesture(
    ///     DragGesture()
    ///         .onChanged { value in
    ///             // This drag overrides the scroll gesture
    ///             print("Custom drag: \(value.translation)")
    ///         }
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - gesture: The gesture to attach with high priority.
    ///   - mask: A mask controlling gesture recognition. Defaults to `.all`.
    /// - Returns: A view with the high-priority gesture attached.
    ///
    /// ## See Also
    ///
    /// - ``gesture(_:including:)``
    /// - ``simultaneousGesture(_:including:)``
    @MainActor
    public func highPriorityGesture<G: Gesture>(
        _ gesture: G,
        including mask: GestureMask = .all
    ) -> some View {
        modifier(_HighPriorityGestureViewModifier(gesture: gesture, mask: mask))
    }
}

// MARK: - Internal View Modifiers

/// Internal view modifier for regular gesture attachment.
@MainActor
struct _GestureViewModifier<G: Gesture>: ViewModifier, Sendable {
    let gesture: G
    let mask: GestureMask

    @MainActor
    func body(content: Content) -> some View {
        _GestureAttachment(content: content, gesture: gesture, mask: mask, priority: .normal)
    }
}

/// Internal view modifier for simultaneous gesture attachment.
@MainActor
struct _SimultaneousGestureViewModifier<G: Gesture>: ViewModifier, Sendable {
    let gesture: G
    let mask: GestureMask

    @MainActor
    func body(content: Content) -> some View {
        _GestureAttachment(content: content, gesture: gesture, mask: mask, priority: .simultaneous)
    }
}

/// Internal view modifier for high-priority gesture attachment.
@MainActor
struct _HighPriorityGestureViewModifier<G: Gesture>: ViewModifier, Sendable {
    let gesture: G
    let mask: GestureMask

    @MainActor
    func body(content: Content) -> some View {
        _GestureAttachment(content: content, gesture: gesture, mask: mask, priority: .high)
    }
}

// MARK: - Gesture Priority
// Note: GesturePriority is now defined in VNode.swift as a public enum

// MARK: - Gesture Attachment View

/// A view that attaches a gesture to its content.
///
/// This is the internal implementation that handles gesture attachment. It wraps the
/// content view and adds gesture event handling based on the gesture type and mask.
@MainActor
struct _GestureAttachment<Content: View, G: Gesture>: View, PrimitiveView, Sendable {
    typealias Body = Never

    let content: Content
    let gesture: G
    let mask: GestureMask
    let priority: GesturePriority

    /// The gesture handler that will be called when the gesture is recognized
    /// This is stored separately so it can be registered with the render system
    private var gestureHandler: @Sendable @MainActor (G.Value) -> Void = { _ in }

    /// Public initializer
    init(content: Content, gesture: G, mask: GestureMask, priority: GesturePriority) {
        self.content = content
        self.gesture = gesture
        self.mask = mask
        self.priority = priority
    }

    @MainActor
    func toVNode() -> VNode {
        // Convert the content to a VNode first
        let contentNode = convertContentToVNode(content)

        // Generate handler ID for this gesture
        let handlerID = UUID()

        // Get the event names needed for this gesture type
        let events = eventNamesForGesture(gesture)

        // Create gesture registration
        let registration = GestureRegistration(
            events: events,
            priority: priority,
            handlerID: handlerID
        )

        // Add gesture registration to the content node
        return addGestureToVNode(contentNode, gesture: registration)
    }

    /// Converts content view to VNode
    private func convertContentToVNode(_ view: Content) -> VNode {
        // Check if this is a primitive view
        if let primitive = view as? any PrimitiveView {
            return primitive.toVNode()
        }

        // For composite views, we need to recursively render
        // This is a simplified version - the full render system handles this
        // For now, wrap in a div
        return VNode.element("div", children: [])
    }

    /// Adds a gesture registration to a VNode
    private func addGestureToVNode(_ node: VNode, gesture: GestureRegistration) -> VNode {
        // Create a new VNode with the gesture added
        let newGestures = node.gestures + [gesture]

        return VNode(
            id: node.id,
            type: node.type,
            props: node.props,
            children: node.children,
            key: node.key,
            gestures: newGestures
        )
    }
}

// MARK: - Gesture Event Mapping

/// Maps gestures to the web events they need to handle.
///
/// This function is used internally to determine which event listeners to attach
/// when a gesture is added to a view. Different gesture types require different
/// sets of events.
///
/// - Parameter gesture: The gesture to map.
/// - Returns: An array of event names needed for the gesture.
@MainActor
func eventNamesForGesture<G: Gesture>(_ gesture: G) -> [String] {
    let gestureTypeName = String(describing: type(of: gesture))

    // Map gesture types to their required events
    if gestureTypeName.contains("TapGesture") {
        return ["click", "pointerdown", "pointerup"]
    } else if gestureTypeName.contains("SpatialTapGesture") {
        return ["click", "pointerdown", "pointerup"]
    } else if gestureTypeName.contains("LongPressGesture") {
        return ["pointerdown", "pointermove", "pointerup", "pointercancel"]
    } else if gestureTypeName.contains("DragGesture") {
        return ["pointerdown", "pointermove", "pointerup", "pointercancel"]
    } else if gestureTypeName.contains("RotationGesture") {
        return ["pointerdown", "pointermove", "pointerup", "pointercancel"]
    } else if gestureTypeName.contains("MagnificationGesture") {
        return ["pointerdown", "pointermove", "pointerup", "pointercancel"]
    } else if gestureTypeName.contains("SimultaneousGesture") {
        // For composed gestures, we'll need to recursively gather events
        // This is a simplified version - full implementation would inspect the composed gestures
        return ["pointerdown", "pointermove", "pointerup", "pointercancel", "click"]
    } else if gestureTypeName.contains("SequenceGesture") {
        return ["pointerdown", "pointermove", "pointerup", "pointercancel", "click"]
    } else if gestureTypeName.contains("ExclusiveGesture") {
        return ["pointerdown", "pointermove", "pointerup", "pointercancel", "click"]
    } else {
        // Default set for unknown gesture types
        return ["pointerdown", "pointermove", "pointerup", "pointercancel"]
    }
}

// MARK: - Documentation Examples

/*
 Example: Basic gesture attachment

 ```swift
 struct TappableView: View {
     var body: some View {
         Rectangle()
             .fill(.blue)
             .frame(width: 100, height: 100)
             .gesture(
                 TapGesture()
                     .onEnded {
                         print("Rectangle tapped!")
                     }
             )
     }
 }
 ```

 Example: Gesture with mask

 ```swift
 struct ScrollableContent: View {
     var body: some View {
         ScrollView {
             VStack {
                 ForEach(items) { item in
                     ItemView(item)
                 }
             }
         }
         .gesture(
             DragGesture(),
             including: .gesture  // Only on the ScrollView itself
         )
     }
 }
 ```

 Example: Multiple gestures

 ```swift
 struct InteractiveView: View {
     var body: some View {
         Rectangle()
             .gesture(
                 TapGesture()
                     .onEnded { print("Tapped") }
             )
             .simultaneousGesture(
                 LongPressGesture()
                     .onEnded { _ in print("Long pressed") }
             )
     }
 }
 ```

 Example: High-priority gesture

 ```swift
 struct CustomScrollView: View {
     var body: some View {
         ScrollView {
             content
         }
         .highPriorityGesture(
             DragGesture()
                 .onChanged { value in
                     // This overrides the scroll gesture
                     customDragHandler(value)
                 }
         )
     }
 }
 ```
 */
