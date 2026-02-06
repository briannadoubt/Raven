import Foundation
import JavaScriptKit

/// A control that displays a secure text interface for password input.
///
/// `SecureField` is a primitive view that renders directly to an HTML `input` element
/// with `type="password"`. It provides two-way data binding through a `Binding<String>`
/// that updates when the user types and reflects external changes to the bound value.
/// The entered text is visually obscured for security.
///
/// Example:
/// ```swift
/// struct LoginView: View {
///     @State private var password = ""
///
///     var body: some View {
///         SecureField("Enter password", text: $password)
///     }
/// }
/// ```
///
/// The secure field automatically updates the binding when the user types, enabling
/// reactive UI updates. The placeholder text provides a hint about what to enter.
/// The actual characters typed are hidden from view for security purposes.
///
/// Because `SecureField` is a primitive view with `Body == Never`, it converts directly
/// to a VNode without further composition.
public struct SecureField: View, PrimitiveView, Sendable {
    public typealias Body = Never

    /// The placeholder text to display when the field is empty
    private let placeholder: String

    /// Two-way binding to the text value
    private let text: Binding<String>

    // MARK: - Initializers

    /// Creates a secure field with a placeholder string and text binding.
    ///
    /// - Parameters:
    ///   - placeholder: The placeholder text to display when the field is empty.
    ///   - text: A binding to the text value.
    ///
    /// Example:
    /// ```swift
    /// @State private var password = ""
    ///
    /// SecureField("Password", text: $password)
    /// ```
    @MainActor public init(
        _ placeholder: String,
        text: Binding<String>
    ) {
        self.placeholder = placeholder
        self.text = text
    }

    /// Creates a secure field with a localized placeholder and text binding.
    ///
    /// - Parameters:
    ///   - titleKey: The localized string key for the placeholder text.
    ///   - text: A binding to the text value.
    ///
    /// Example:
    /// ```swift
    /// @State private var password = ""
    ///
    /// SecureField("password_placeholder", text: $password)
    /// ```
    @MainActor public init(
        _ titleKey: LocalizedStringKey,
        text: Binding<String>
    ) {
        self.placeholder = titleKey.stringValue
        self.text = text
    }

    // MARK: - VNode Conversion

    /// Converts this SecureField to a virtual DOM node.
    ///
    /// The SecureField is rendered as an `input` element with:
    /// - `type="password"` attribute to obscure the entered text
    /// - `placeholder` attribute for the hint text
    /// - `value` attribute bound to the current text value
    /// - `input` event handler for two-way data binding
    ///
    /// When the user types, the input event triggers an update to the binding,
    /// which can cause the view to re-render and reflect the new value.
    ///
    /// - Returns: A VNode configured as a password input element with event handlers.
    @MainActor public func toVNode() -> VNode {
        // Generate a unique ID for the input event handler
        let handlerID = UUID()

        // Create properties for the input element
        let props: [String: VProperty] = [
            // Input type - password for secure entry
            "type": .attribute(name: "type", value: "password"),

            // Placeholder text
            "placeholder": .attribute(name: "placeholder", value: placeholder),

            // Current value (reflects the binding)
            "value": .attribute(name: "value", value: text.wrappedValue),

            // Input event handler for two-way binding
            "onInput": .eventHandler(event: "input", handlerID: handlerID),

            // Default styling
            "padding": .style(name: "padding", value: "8px"),
            "border": .style(name: "border", value: "1px solid #ccc"),
            "border-radius": .style(name: "border-radius", value: "4px"),
            "font-size": .style(name: "font-size", value: "14px"),
        ]

        return VNode.element(
            "input",
            props: props,
            children: []
        )
    }

    // MARK: - Internal Access

    /// Provides access to the text binding for the render coordinator.
    ///
    /// The rendering system needs access to the binding to properly set up
    /// the event handler that updates the bound value when the user types.
    @MainActor public var textBinding: Binding<String> {
        text
    }
}

// MARK: - Coordinator Renderable

extension SecureField: _CoordinatorRenderable {
    @MainActor public func _render(with context: any _RenderContext) -> VNode {
        let binding = text
        let handlerID = context.registerInputHandler { event in
            if let newValue = event.target.value.string {
                binding.wrappedValue = newValue
            }
        }

        let props: [String: VProperty] = [
            "type": .attribute(name: "type", value: "password"),
            "placeholder": .attribute(name: "placeholder", value: placeholder),
            "value": .attribute(name: "value", value: binding.wrappedValue),
            "onInput": .eventHandler(event: "input", handlerID: handlerID),
            "padding": .style(name: "padding", value: "8px"),
            "border": .style(name: "border", value: "1px solid #ccc"),
            "border-radius": .style(name: "border-radius", value: "4px"),
            "font-size": .style(name: "font-size", value: "14px"),
            "width": .style(name: "width", value: "100%"),
            "box-sizing": .style(name: "box-sizing", value: "border-box"),
        ]
        return VNode.element("input", props: props, children: [])
    }
}
