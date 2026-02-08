import Foundation

/// An interactive button view that triggers an action when clicked.
///
/// `Button` is a primitive view that renders directly to a button element in the virtual DOM.
/// It supports both simple text labels and complex custom label content.
///
/// ## Overview
///
/// Use `Button` to create interactive elements that perform actions when clicked.
/// Buttons can contain simple text labels or complex view hierarchies.
///
/// ## Basic Usage
///
/// Create a button with a text label and action:
///
/// ```swift
/// Button("Click Me") {
///     print("Button clicked!")
/// }
/// ```
///
/// ## Custom Labels
///
/// Use the action-label initializer for custom button content:
///
/// ```swift
/// Button(action: { handleTap() }) {
///     HStack {
///         Image(systemName: "star.fill")
///         Text("Favorite")
///     }
/// }
/// ```
///
/// ## With State
///
/// Buttons commonly modify state when clicked:
///
/// ```swift
/// struct CounterView: View {
///     @State private var count = 0
///
///     var body: some View {
///         VStack {
///             Text("Count: \(count)")
///             Button("Increment") {
///                 count += 1
///             }
///         }
///     }
/// }
/// ```
///
/// ## Button Styles
///
/// Style buttons using view modifiers:
///
/// ```swift
/// Button("Save") {
///     save()
/// }
/// .padding()
/// .background(Color.blue)
/// .foregroundColor(.white)
/// .cornerRadius(8)
/// ```
///
/// ## Common Patterns
///
/// **Submit form:**
/// ```swift
/// Button("Submit") {
///     submitForm()
/// }
/// .disabled(username.isEmpty)
/// ```
///
/// **Delete action:**
/// ```swift
/// Button("Delete") {
///     deleteItem()
/// }
/// .foregroundColor(.red)
/// ```
///
/// **Navigation:**
/// ```swift
/// Button("Go Back") {
///     navigateBack()
/// }
/// ```
///
/// **Complex interactive button:**
/// ```swift
/// Button(action: {
///     toggleFavorite()
/// }) {
///     VStack {
///         Image(systemName: isFavorite ? "heart.fill" : "heart")
///             .font(.title)
///         Text(isFavorite ? "Favorited" : "Favorite")
///             .font(.caption)
///     }
///     .foregroundColor(isFavorite ? .red : .gray)
/// }
/// ```
///
/// ## Best Practices
///
/// - Use clear, action-oriented labels ("Save", "Delete", "Submit")
/// - Provide visual feedback for button states
/// - Disable buttons when actions aren't available
/// - Use appropriate button styles for context (primary, secondary, destructive)
///
/// ## See Also
///
/// - ``Text``
/// - ``Image``
///
/// Because `Button` is a primitive view with `Body == Never`, it converts directly
/// to a VNode without further composition.
public struct Button<Label: View>: View, PrimitiveView, Sendable {
    public typealias Body = Never

    @Environment(\.buttonStyle) private var buttonStyle
    @Environment(\.primitiveButtonStyle) private var primitiveButtonStyle

    /// The action to perform when the button is clicked
    private let action: @Sendable @MainActor () -> Void

    /// The label content to display in the button
    private let label: Label

    /// Public access to the action for the render coordinator
    public var actionClosure: @Sendable @MainActor () -> Void {
        action
    }

    // MARK: - Initializers

    /// Creates a button with a custom label.
    ///
    /// - Parameters:
    ///   - action: The action to perform when the button is clicked.
    ///   - label: A view builder that creates the button's label.
    @MainActor public init(
        action: @escaping @Sendable @MainActor () -> Void,
        @ViewBuilder label: () -> Label
    ) {
        self.action = action
        self.label = label()
    }

    // MARK: - VNode Conversion

    /// Converts this Button view to a virtual DOM node.
    ///
    /// This method is used internally by the rendering system to convert
    /// the Button primitive into its VNode representation.
    ///
    /// - Returns: A button element VNode with event handler and label content.
    @MainActor public func toVNode() -> VNode {
        // Generate a unique ID for this event handler
        let handlerID = UUID()

        // Create the click event handler property
        let clickHandler = VProperty.eventHandler(event: "click", handlerID: handlerID)

        // Create button element with event handler
        let props: [String: VProperty] = [
            "onClick": clickHandler
        ]

        // ARIA attributes for accessibility (WCAG 2.1 AA compliance)
        // Note: HTML <button> already has implicit role="button", but we can add
        // additional ARIA attributes if needed (e.g., aria-pressed, aria-expanded, aria-controls)
        // These will be set by accessibility modifiers when needed

        // Convert label to children nodes
        let children: [VNode]
        if let textLabel = label as? Text {
            // Optimize for simple text labels
            children = [VNode.text(textLabel.textContent)]
        } else {
            // For complex labels, we'll need to render them
            // For now, create a placeholder that will be handled by the render system
            // This will be properly implemented when the render system is connected
            children = []
        }

        return VNode.element(
            "button",
            props: props,
            children: children
        )
    }
}

// MARK: - Convenience Initializers

extension Button where Label == Text {
    /// Creates a button with a text label.
    ///
    /// This is a convenience initializer for creating simple text-based buttons.
    ///
    /// - Parameters:
    ///   - title: The string to display as the button's label.
    ///   - action: The action to perform when the button is clicked.
    ///
    /// Example:
    /// ```swift
    /// Button("Submit") {
    ///     submitForm()
    /// }
    /// ```
    @MainActor public init(
        _ title: String,
        action: @escaping @Sendable @MainActor () -> Void
    ) {
        self.action = action
        self.label = Text(title)
    }

    /// Creates a button with a localized text label.
    ///
    /// - Parameters:
    ///   - titleKey: The localized string key for the button's label.
    ///   - action: The action to perform when the button is clicked.
    @MainActor public init(
        _ titleKey: LocalizedStringKey,
        action: @escaping @Sendable @MainActor () -> Void
    ) {
        self.action = action
        self.label = Text(titleKey)
    }

    /// Creates a button with a text label and optional role.
    ///
    /// The role parameter affects how the button is styled in presentations like alerts
    /// and confirmation dialogs, but doesn't affect the button's standalone appearance.
    ///
    /// - Parameters:
    ///   - title: The string to display as the button's label.
    ///   - role: The semantic role of the button (e.g., .destructive, .cancel).
    ///   - action: The action to perform when the button is clicked.
    ///
    /// Example:
    /// ```swift
    /// Button("Delete", role: .destructive) {
    ///     deleteItem()
    /// }
    /// ```
    @MainActor public init(
        _ title: String,
        role: ButtonRole? = nil,
        action: @escaping @Sendable @MainActor () -> Void
    ) {
        self.action = action
        self.label = Text(title)
        // Note: role is currently stored but not used in rendering
        // It's primarily used by presentation modifiers (alerts, sheets, etc.)
    }
}

// MARK: - Style Support

/// A style for customizing the appearance and interaction of buttons.
public protocol ButtonStyle: Sendable {
    /// The body of the button style.
    associatedtype Body: View

    /// Creates a view representing the body of a button.
    ///
    /// - Parameter configuration: The properties of the button.
    @MainActor func makeBody(configuration: Configuration) -> Body

    /// The properties of a button.
    typealias Configuration = ButtonStyleConfiguration
}

/// The properties of a button.
public struct ButtonStyleConfiguration: Sendable {
    /// A type-erased label for the button.
    public let label: AnyView

    /// Whether the button is currently pressed.
    public let isPressed: Bool

    /// Creates a button style configuration.
    public init(label: AnyView, isPressed: Bool) {
        self.label = label
        self.isPressed = isPressed
    }
}

/// A default button style.
public struct DefaultButtonStyle: ButtonStyle {
    public init() {}

    @MainActor public func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}

/// A primitive style for customizing low-level button behavior.
public protocol PrimitiveButtonStyle: Sendable {
    associatedtype Body: View

    @MainActor func makeBody(configuration: PrimitiveButtonStyleConfiguration) -> Body
}

/// Configuration values for primitive button styles.
public struct PrimitiveButtonStyleConfiguration: Sendable {
    /// A type-erased label for the button.
    public let label: AnyView

    /// Creates a primitive button style configuration.
    public init(label: AnyView) {
        self.label = label
    }
}

/// A bordered primitive button style.
public struct BorderedButtonStyle: PrimitiveButtonStyle {
    public init() {}

    @MainActor public func makeBody(configuration: PrimitiveButtonStyleConfiguration) -> some View {
        configuration.label
    }
}

/// A prominent bordered primitive button style.
public struct BorderedProminentButtonStyle: PrimitiveButtonStyle {
    public init() {}

    @MainActor public func makeBody(configuration: PrimitiveButtonStyleConfiguration) -> some View {
        configuration.label
    }
}

/// A borderless primitive button style.
public struct BorderlessButtonStyle: PrimitiveButtonStyle {
    public init() {}

    @MainActor public func makeBody(configuration: PrimitiveButtonStyleConfiguration) -> some View {
        configuration.label
    }
}

extension PrimitiveButtonStyle where Self == BorderedButtonStyle {
    /// A bordered button style.
    public static var bordered: BorderedButtonStyle {
        BorderedButtonStyle()
    }
}

extension PrimitiveButtonStyle where Self == BorderedProminentButtonStyle {
    /// A prominent bordered button style.
    public static var borderedProminent: BorderedProminentButtonStyle {
        BorderedProminentButtonStyle()
    }
}

extension PrimitiveButtonStyle where Self == BorderlessButtonStyle {
    /// A borderless button style.
    public static var borderless: BorderlessButtonStyle {
        BorderlessButtonStyle()
    }
}

private struct ButtonStyleEnvironmentKey: EnvironmentKey {
    static let defaultValue: any ButtonStyle = DefaultButtonStyle()
}

private struct PrimitiveButtonStyleEnvironmentKey: EnvironmentKey {
    static let defaultValue: any PrimitiveButtonStyle = BorderedButtonStyle()
}

extension EnvironmentValues {
    var buttonStyle: any ButtonStyle {
        get { self[ButtonStyleEnvironmentKey.self] }
        set { self[ButtonStyleEnvironmentKey.self] = newValue }
    }

    var primitiveButtonStyle: any PrimitiveButtonStyle {
        get { self[PrimitiveButtonStyleEnvironmentKey.self] }
        set { self[PrimitiveButtonStyleEnvironmentKey.self] = newValue }
    }
}

extension View {
    /// Sets the style for buttons within this view.
    ///
    /// - Parameter style: The button style to apply.
    /// - Returns: A view with the specified button style.
    @MainActor public func buttonStyle(_ style: some ButtonStyle) -> some View {
        environment(\.buttonStyle, style)
    }

    /// Sets a primitive style for buttons within this view.
    @MainActor public func buttonStyle(_ style: some PrimitiveButtonStyle) -> some View {
        environment(\.primitiveButtonStyle, style)
    }
}

// MARK: - Coordinator Renderable

extension Button: _CoordinatorRenderable {
    @MainActor public func _render(with context: any _RenderContext) -> VNode {
        let handlerID = context.registerClickHandler(action)
        let clickHandler = VProperty.eventHandler(event: "click", handlerID: handlerID)
        var props: [String: VProperty] = [
            "onClick": clickHandler,
            // Reset browser default button styles — modifiers handle all styling
            "border": .style(name: "border", value: "none"),
            "background": .style(name: "background", value: "transparent"),
            "padding": .style(name: "padding", value: "0"),
            "font": .style(name: "font", value: "inherit"),
            "color": .style(name: "color", value: "inherit"),
            "cursor": .style(name: "cursor", value: "pointer"),
            "text-align": .style(name: "text-align", value: "inherit"),
        ]
        if primitiveButtonStyle is BorderedButtonStyle {
            props["border"] = .style(name: "border", value: "1px solid var(--system-control-border)")
            props["padding"] = .style(name: "padding", value: "8px 12px")
            props["border-radius"] = .style(name: "border-radius", value: "8px")
            props["background"] = .style(name: "background", value: "var(--system-control-background)")
        } else if primitiveButtonStyle is BorderedProminentButtonStyle {
            props["border"] = .style(name: "border", value: "1px solid var(--system-accent)")
            props["padding"] = .style(name: "padding", value: "8px 12px")
            props["border-radius"] = .style(name: "border-radius", value: "8px")
            props["background"] = .style(name: "background", value: "var(--system-accent)")
            props["color"] = .style(name: "color", value: "white")
        } else if primitiveButtonStyle is BorderlessButtonStyle {
            props["border"] = .style(name: "border", value: "none")
            props["padding"] = .style(name: "padding", value: "4px 6px")
            props["background"] = .style(name: "background", value: "transparent")
        }
        let children = [context.renderChild(label)]
        return VNode.element("button", props: props, children: children)
    }
}
