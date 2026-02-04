import Foundation

/// An interactive control that toggles between on and off states.
///
/// `Toggle` is a primitive view that renders directly to a checkbox input element
/// in the virtual DOM. It provides two-way data binding through a `Binding<Bool>`.
///
/// Example:
/// ```swift
/// @State private var isEnabled = false
///
/// var body: some View {
///     Toggle("Enable Feature", isOn: $isEnabled)
/// }
/// ```
///
/// You can also provide custom label content:
/// ```swift
/// Toggle(isOn: $isEnabled) {
///     HStack {
///         Image(systemName: "bell")
///         Text("Notifications")
///     }
/// }
/// ```
///
/// Because `Toggle` is a primitive view with `Body == Never`, it converts directly
/// to a VNode without further composition.
public struct Toggle<Label: View>: View, Sendable {
    public typealias Body = Never

    /// The binding to the toggle's state
    private let isOn: Binding<Bool>

    /// The label content to display
    private let label: Label

    /// Optional identifier for the toggle
    private let id: String?

    // MARK: - Initializers

    /// Creates a toggle with a custom label.
    ///
    /// - Parameters:
    ///   - isOn: A binding to a Boolean value that determines whether the toggle is on or off.
    ///   - label: A view builder that creates the toggle's label.
    @MainActor public init(
        isOn: Binding<Bool>,
        @ViewBuilder label: () -> Label
    ) {
        self.isOn = isOn
        self.label = label()
        self.id = nil
    }

    /// Private initializer with ID support.
    private init(
        isOn: Binding<Bool>,
        label: Label,
        id: String?
    ) {
        self.isOn = isOn
        self.label = label
        self.id = id
    }

    // MARK: - VNode Conversion

    /// Converts this Toggle view to a virtual DOM node.
    ///
    /// This method is used internally by the rendering system to convert
    /// the Toggle primitive into its VNode representation.
    ///
    /// The toggle is rendered as a label element containing:
    /// - An input[type="checkbox"] element with change event handler
    /// - The label content
    ///
    /// - Returns: A label element VNode containing the checkbox and label content.
    @MainActor public func toVNode() -> VNode {
        // Generate unique IDs for this toggle
        let toggleID = id ?? UUID().uuidString
        let handlerID = UUID()

        // Create the checkbox input element with proper ARIA switch role
        var inputProps: [String: VProperty] = [
            "type": .attribute(name: "type", value: "checkbox"),
            "id": .attribute(name: "id", value: toggleID),
            // Use switch role for toggle-style controls (WCAG 2.1 requirement)
            "role": .attribute(name: "role", value: "switch"),
        ]

        // Set checked state (both as HTML attribute and ARIA state)
        inputProps["checked"] = .boolAttribute(name: "checked", value: isOn.wrappedValue)

        // Add change event handler
        inputProps["onChange"] = .eventHandler(event: "change", handlerID: handlerID)

        // Add ARIA attributes for accessibility (WCAG 2.1 AA compliance)
        // aria-checked is essential for switch role
        inputProps["aria-checked"] = .attribute(
            name: "aria-checked",
            value: isOn.wrappedValue ? "true" : "false"
        )

        let inputNode = VNode.element(
            "input",
            props: inputProps,
            children: []
        )

        // Convert label to VNode
        let labelNodes: [VNode]
        if let textLabel = label as? Text {
            // Optimize for simple text labels
            labelNodes = [textLabel.toVNode()]
        } else {
            // For complex labels, we'll need to render them
            // For now, create a placeholder that will be handled by the render system
            // This will be properly implemented when the render system is connected
            labelNodes = []
        }

        // Create label element wrapping the checkbox and label content
        let labelProps: [String: VProperty] = [
            "for": .attribute(name: "for", value: toggleID),
            "class": .attribute(name: "class", value: "raven-toggle")
        ]

        // Combine input and label nodes as children of the label element
        let children = [inputNode] + labelNodes

        return VNode.element(
            "label",
            props: labelProps,
            children: children
        )
    }

    // MARK: - Public API for Event Handling

    /// Gets the handler closure for the change event.
    ///
    /// This is used by the render coordinator to register the event handler
    /// that updates the binding when the checkbox state changes.
    ///
    /// - Returns: A closure that toggles the binding value.
    @MainActor public var changeHandler: @Sendable @MainActor () -> Void {
        { [isOn] in
            isOn.wrappedValue.toggle()
        }
    }
}

// MARK: - Convenience Initializers

extension Toggle where Label == Text {
    /// Creates a toggle with a text label.
    ///
    /// This is a convenience initializer for creating simple text-based toggles.
    ///
    /// - Parameters:
    ///   - titleKey: A localized string key for the toggle's label.
    ///   - isOn: A binding to a Boolean value that determines whether the toggle is on or off.
    ///
    /// Example:
    /// ```swift
    /// @State private var wifiEnabled = true
    ///
    /// var body: some View {
    ///     Toggle("Wi-Fi", isOn: $wifiEnabled)
    /// }
    /// ```
    @MainActor public init(
        _ titleKey: LocalizedStringKey,
        isOn: Binding<Bool>
    ) {
        self.isOn = isOn
        self.label = Text(titleKey)
        self.id = nil
    }

    /// Creates a toggle with a string label.
    ///
    /// - Parameters:
    ///   - title: The string to display as the toggle's label.
    ///   - isOn: A binding to a Boolean value that determines whether the toggle is on or off.
    ///
    /// Example:
    /// ```swift
    /// @State private var darkMode = false
    ///
    /// var body: some View {
    ///     Toggle("Dark Mode", isOn: $darkMode)
    /// }
    /// ```
    @MainActor public init(
        _ title: String,
        isOn: Binding<Bool>
    ) {
        self.isOn = isOn
        self.label = Text(title)
        self.id = nil
    }
}

// MARK: - View Modifiers

extension Toggle {
    /// Sets a custom identifier for this toggle.
    ///
    /// This can be useful for testing or when you need stable DOM IDs.
    ///
    /// - Parameter id: The identifier string.
    /// - Returns: A toggle with the specified identifier.
    public func toggleID(_ id: String) -> Toggle {
        Toggle(
            isOn: self.isOn,
            label: self.label,
            id: id
        )
    }
}

// MARK: - Style Support

/// A style for customizing the appearance of toggles.
///
/// This protocol can be extended in the future to support different
/// toggle appearances (e.g., switch style, checkbox style, button style).
public protocol ToggleStyle: Sendable {
    /// The body of the toggle style.
    associatedtype Body: View

    /// Creates a view representing the body of a toggle.
    ///
    /// - Parameter configuration: The properties of the toggle.
    @MainActor func makeBody(configuration: Configuration) -> Body

    /// The properties of a toggle.
    typealias Configuration = ToggleStyleConfiguration
}

/// The properties of a toggle.
public struct ToggleStyleConfiguration: Sendable {
    /// A view that describes the effect of toggling `isOn`.
    public let label: AnyView

    /// Whether the toggle is currently on.
    public var isOn: Bool
}

// MARK: - Default Toggle Styles

/// The default toggle style that renders as a checkbox.
public struct DefaultToggleStyle: ToggleStyle {
    public init() {}

    @MainActor public func makeBody(configuration: Configuration) -> some View {
        // Default implementation would use the checkbox rendering
        // This is a placeholder for future style system integration
        configuration.label
    }
}

/// A toggle style that renders as a switch.
///
/// This style would render a switch-like appearance similar to iOS toggles.
/// Implementation would be added when CSS styling support is available.
public struct SwitchToggleStyle: ToggleStyle {
    public init() {}

    @MainActor public func makeBody(configuration: Configuration) -> some View {
        // Switch style implementation would go here
        // This is a placeholder for future style system integration
        configuration.label
    }
}

// MARK: - Toggle Style Modifier

extension View {
    /// Sets the style for toggles within this view.
    ///
    /// - Parameter style: The toggle style to apply.
    /// - Returns: A view with the specified toggle style.
    @MainActor public func toggleStyle<S: ToggleStyle>(_ style: S) -> some View {
        // This would be implemented as a view modifier that applies
        // the toggle style to child toggles through the environment
        // For now, return self as a placeholder
        self
    }
}
