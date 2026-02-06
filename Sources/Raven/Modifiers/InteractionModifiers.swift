import Foundation

// MARK: - Disabled Modifier

/// A view wrapper that disables user interaction with its content.
///
/// The disabled modifier prevents user interaction by setting CSS pointer-events to none,
/// reducing opacity, and changing the cursor style.
public struct _DisabledView<Content: View>: View, PrimitiveView, Sendable {
    let content: Content
    let disabled: Bool

    public typealias Body = Never

    @MainActor public func toVNode() -> VNode {
        guard disabled else {
            // If not disabled, return a transparent wrapper
            return VNode.element("div", props: [:], children: [])
        }

        let props: [String: VProperty] = [
            "pointer-events": .style(name: "pointer-events", value: "none"),
            "opacity": .style(name: "opacity", value: "0.5"),
            "cursor": .style(name: "cursor", value: "not-allowed")
        ]

        return VNode.element("div", props: props, children: [])
    }
}

// MARK: - OnTapGesture Modifier

/// A view wrapper that handles tap/click events.
///
/// The onTapGesture modifier adds a click event handler to the view.
public struct _OnTapGestureView<Content: View>: View, PrimitiveView, Sendable {
    let content: Content
    let count: Int
    let action: @Sendable @MainActor () -> Void

    public typealias Body = Never

    @MainActor public func toVNode() -> VNode {
        // Generate a unique ID for this event handler
        let handlerID = UUID()

        // Create the click event handler property
        let clickHandler = VProperty.eventHandler(event: "click", handlerID: handlerID)

        // For multi-tap gestures (count > 1), we would need additional JavaScript logic
        // For now, we'll handle single taps and double taps with standard events
        let eventName = count == 2 ? "dblclick" : "click"
        let props: [String: VProperty] = [
            "on\(eventName.prefix(1).uppercased())\(eventName.dropFirst())": clickHandler
        ]

        return VNode.element("div", props: props, children: [])
    }
}

// MARK: - OnAppear Modifier

/// A view wrapper that runs an action when the view appears.
///
/// The onAppear modifier uses IntersectionObserver or mount callbacks to detect
/// when the view becomes visible in the DOM.
public struct _OnAppearView<Content: View>: View, PrimitiveView, Sendable {
    let content: Content
    let action: @Sendable @MainActor () -> Void

    public typealias Body = Never

    @MainActor public func toVNode() -> VNode {
        // Generate a unique ID for the lifecycle handler
        let handlerID = UUID()

        // Create a lifecycle event handler property
        // In the actual implementation, this would be handled by the renderer
        let lifecycleHandler = VProperty.eventHandler(event: "appear", handlerID: handlerID)

        let props: [String: VProperty] = [
            "data-on-appear": lifecycleHandler
        ]

        return VNode.element("div", props: props, children: [])
    }
}

// MARK: - OnDisappear Modifier

/// A view wrapper that runs an action when the view disappears.
///
/// The onDisappear modifier uses IntersectionObserver or unmount callbacks to detect
/// when the view is removed from the DOM.
public struct _OnDisappearView<Content: View>: View, PrimitiveView, Sendable {
    let content: Content
    let action: @Sendable @MainActor () -> Void

    public typealias Body = Never

    @MainActor public func toVNode() -> VNode {
        // Generate a unique ID for the lifecycle handler
        let handlerID = UUID()

        // Create a lifecycle event handler property
        let lifecycleHandler = VProperty.eventHandler(event: "disappear", handlerID: handlerID)

        let props: [String: VProperty] = [
            "data-on-disappear": lifecycleHandler
        ]

        return VNode.element("div", props: props, children: [])
    }
}

// MARK: - OnChange Modifier

/// A storage structure for onChange callbacks.
///
/// This stores the previous value and the action to perform when the value changes.
public struct OnChangeAction<V: Equatable & Sendable>: Sendable {
    let action: @Sendable @MainActor (V) -> Void
    var previousValue: V?

    init(action: @escaping @Sendable @MainActor (V) -> Void) {
        self.action = action
        self.previousValue = nil
    }
}

/// A view wrapper that monitors value changes and runs an action.
///
/// The onChange modifier watches a value and triggers an action when it changes.
public struct _OnChangeView<Content: View, V: Equatable & Sendable>: View, PrimitiveView, Sendable {
    let content: Content
    let value: V
    let action: @Sendable @MainActor (V) -> Void

    public typealias Body = Never

    @MainActor public func toVNode() -> VNode {
        // The onChange modifier doesn't add any visual elements
        // The actual change detection would be handled by the rendering system
        // which would compare the value between renders

        // For now, we create a transparent wrapper with a data attribute
        // that the renderer can use to track the value
        let handlerID = UUID()

        let props: [String: VProperty] = [
            "data-on-change": .eventHandler(event: "change", handlerID: handlerID),
            "data-change-id": .attribute(name: "data-change-id", value: handlerID.uuidString)
        ]

        return VNode.element("div", props: props, children: [])
    }
}

// MARK: - View Extensions

extension View {
    /// Disables user interaction with this view.
    ///
    /// When disabled, the view cannot receive user input and appears dimmed.
    /// This is commonly used to prevent interaction with buttons or forms
    /// while waiting for an operation to complete.
    ///
    /// Example:
    /// ```swift
    /// Button("Submit") {
    ///     submitForm()
    /// }
    /// .disabled(isSubmitting)
    /// ```
    ///
    /// - Parameter disabled: A Boolean value that determines whether this view
    ///   should be disabled. When `true`, user interaction is disabled.
    /// - Returns: A view that prevents user interaction when disabled.
    @MainActor public func disabled(_ disabled: Bool) -> _DisabledView<Self> {
        _DisabledView(content: self, disabled: disabled)
    }

    /// Adds an action to perform when this view recognizes a tap gesture.
    ///
    /// Use this modifier to add tap gesture recognition to any view.
    /// The action is triggered after the specified number of taps.
    ///
    /// Example:
    /// ```swift
    /// Text("Tap me")
    ///     .onTapGesture {
    ///         print("Tapped!")
    ///     }
    ///
    /// Image("photo")
    ///     .onTapGesture(count: 2) {
    ///         print("Double tapped!")
    ///     }
    /// ```
    ///
    /// - Parameters:
    ///   - count: The number of taps required to trigger the action. Defaults to 1.
    ///   - perform: The action to perform when the gesture is recognized.
    /// - Returns: A view that recognizes tap gestures.
    @MainActor public func onTapGesture(
        count: Int = 1,
        perform action: @escaping @Sendable @MainActor () -> Void
    ) -> _OnTapGestureView<Self> {
        _OnTapGestureView(content: self, count: count, action: action)
    }

    /// Adds an action to perform when this view appears.
    ///
    /// Use this modifier to perform setup or initialization when the view
    /// becomes visible in the DOM. This is commonly used for loading data
    /// or starting animations.
    ///
    /// Example:
    /// ```swift
    /// Text("Content")
    ///     .onAppear {
    ///         print("View appeared")
    ///         loadData()
    ///     }
    /// ```
    ///
    /// - Parameter perform: The action to perform when the view appears.
    /// - Returns: A view that runs the specified action when it appears.
    ///
    /// - Note: The action may be called multiple times if the view appears
    ///   and disappears multiple times during its lifetime.
    @MainActor public func onAppear(
        perform action: @escaping @Sendable @MainActor () -> Void
    ) -> _OnAppearView<Self> {
        _OnAppearView(content: self, action: action)
    }

    /// Adds an action to perform when this view disappears.
    ///
    /// Use this modifier to perform cleanup or teardown when the view
    /// is removed from the DOM. This is commonly used for releasing resources
    /// or stopping timers.
    ///
    /// Example:
    /// ```swift
    /// Text("Content")
    ///     .onDisappear {
    ///         print("View disappeared")
    ///         cleanup()
    ///     }
    /// ```
    ///
    /// - Parameter perform: The action to perform when the view disappears.
    /// - Returns: A view that runs the specified action when it disappears.
    ///
    /// - Note: The action may be called multiple times if the view appears
    ///   and disappears multiple times during its lifetime.
    @MainActor public func onDisappear(
        perform action: @escaping @Sendable @MainActor () -> Void
    ) -> _OnDisappearView<Self> {
        _OnDisappearView(content: self, action: action)
    }

    /// Adds an action to perform when the specified value changes.
    ///
    /// Use this modifier to respond to changes in a specific value.
    /// The action receives the new value as a parameter.
    ///
    /// Example:
    /// ```swift
    /// struct ContentView: View {
    ///     @State private var searchText = ""
    ///
    ///     var body: some View {
    ///         TextField("Search", text: $searchText)
    ///             .onChange(of: searchText) { newValue in
    ///                 performSearch(newValue)
    ///             }
    ///     }
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - value: The value to monitor for changes.
    ///   - perform: The action to perform when the value changes.
    ///     The action receives the new value as its parameter.
    /// - Returns: A view that runs the specified action when the value changes.
    ///
    /// - Note: The action is only called when the new value is different from
    ///   the previous value, as determined by the `Equatable` conformance.
    @MainActor public func onChange<V: Equatable & Sendable>(
        of value: V,
        perform action: @escaping @Sendable @MainActor (V) -> Void
    ) -> _OnChangeView<Self, V> {
        _OnChangeView(content: self, value: value, action: action)
    }
}

// MARK: - Modifier Renderable Conformances

extension _DisabledView: _ModifierRenderable {
    public var _modifiedContent: Content { content }
}

extension _OnTapGestureView: _ModifierRenderable {
    public var _modifiedContent: Content { content }
}

extension _OnAppearView: _ModifierRenderable {
    public var _modifiedContent: Content { content }
}

extension _OnDisappearView: _ModifierRenderable {
    public var _modifiedContent: Content { content }
}

extension _OnChangeView: _ModifierRenderable {
    public var _modifiedContent: Content { content }
}
