import Foundation
import JavaScriptKit

/// A control that displays an editable text interface.
///
/// `TextField` is a primitive view that renders directly to an HTML `input` element.
/// It provides two-way data binding through a `Binding<String>` that updates when
/// the user types and reflects external changes to the bound value.
///
/// Example:
/// ```swift
/// struct LoginView: View {
///     @State private var username = ""
///
///     var body: some View {
///         TextField("Enter username", text: $username)
///     }
/// }
/// ```
///
/// The text field automatically updates the binding when the user types, enabling
/// reactive UI updates. The placeholder text provides a hint about what to enter.
///
/// Because `TextField` is a primitive view with `Body == Never`, it converts directly
/// to a VNode without further composition.
public struct TextField: View, PrimitiveView, Sendable {
    public typealias Body = Never

    /// The placeholder text to display when the field is empty
    private let placeholder: String

    /// Two-way binding to the text value
    private let text: Binding<String>

    // MARK: - Initializers

    /// Creates a text field with a placeholder string and text binding.
    ///
    /// - Parameters:
    ///   - placeholder: The placeholder text to display when the field is empty.
    ///   - text: A binding to the text value.
    ///
    /// Example:
    /// ```swift
    /// @State private var email = ""
    ///
    /// TextField("user@example.com", text: $email)
    /// ```
    @MainActor public init(
        _ placeholder: String,
        text: Binding<String>
    ) {
        self.placeholder = placeholder
        self.text = text
    }

    /// Creates a text field with a localized placeholder and text binding.
    ///
    /// - Parameters:
    ///   - titleKey: The localized string key for the placeholder text.
    ///   - text: A binding to the text value.
    ///
    /// Example:
    /// ```swift
    /// @State private var name = ""
    ///
    /// TextField("name_placeholder", text: $name)
    /// ```
    @MainActor public init(
        _ titleKey: LocalizedStringKey,
        text: Binding<String>
    ) {
        self.placeholder = titleKey.stringValue
        self.text = text
    }

    // MARK: - VNode Conversion

    /// Converts this TextField to a virtual DOM node.
    ///
    /// The TextField is rendered as an `input` element with:
    /// - `type="text"` attribute
    /// - `placeholder` attribute for the hint text
    /// - `value` attribute bound to the current text value
    /// - `input` event handler for two-way data binding
    ///
    /// When the user types, the input event triggers an update to the binding,
    /// which can cause the view to re-render and reflect the new value.
    ///
    /// - Returns: A VNode configured as a text input element with event handlers.
    @MainActor public func toVNode() -> VNode {
        // Generate a unique ID for the input event handler
        let handlerID = UUID()

        // Create properties for the input element
        var props: [String: VProperty] = [
            // Input type
            "type": .attribute(name: "type", value: "text"),

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

        // ARIA attributes for accessibility (WCAG 2.1 AA compliance)
        // Use placeholder as aria-label if no explicit label is provided
        props["aria-label"] = .attribute(name: "aria-label", value: placeholder)

        // Mark as textbox role for clarity
        props["role"] = .attribute(name: "role", value: "textbox")

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

// MARK: - Multi-line Text Field

/// A control that displays an editable multi-line text interface.
///
/// `TextEditor` is similar to `TextField` but allows multiple lines of text.
/// It renders as an HTML `textarea` element.
///
/// Example:
/// ```swift
/// struct NotesView: View {
///     @State private var notes = ""
///
///     var body: some View {
///         TextEditor(text: $notes)
///     }
/// }
/// ```
public struct TextEditor: View, PrimitiveView, Sendable {
    public typealias Body = Never

    /// Two-way binding to the text value
    private let text: Binding<String>

    // MARK: - Initializers

    /// Creates a multi-line text editor with a text binding.
    ///
    /// - Parameter text: A binding to the text value.
    ///
    /// Example:
    /// ```swift
    /// @State private var description = ""
    ///
    /// TextEditor(text: $description)
    /// ```
    @MainActor public init(
        text: Binding<String>
    ) {
        self.text = text
    }

    // MARK: - VNode Conversion

    /// Converts this TextEditor to a virtual DOM node.
    ///
    /// The TextEditor is rendered as a `textarea` element with:
    /// - `input` event handler for two-way data binding
    /// - The current text value as the element's text content
    ///
    /// - Returns: A VNode configured as a textarea element with event handlers.
    @MainActor public func toVNode() -> VNode {
        // Generate a unique ID for the input event handler
        let handlerID = UUID()

        // Create properties for the textarea element
        var props: [String: VProperty] = [
            // Input event handler for two-way binding
            "onInput": .eventHandler(event: "input", handlerID: handlerID),

            // Default styling
            "padding": .style(name: "padding", value: "8px"),
            "border": .style(name: "border", value: "1px solid #ccc"),
            "border-radius": .style(name: "border-radius", value: "4px"),
            "font-size": .style(name: "font-size", value: "14px"),
            "font-family": .style(name: "font-family", value: "inherit"),
            "resize": .style(name: "resize", value: "vertical"),
            "min-height": .style(name: "min-height", value: "100px"),
        ]

        // ARIA attributes for accessibility (WCAG 2.1 AA compliance)
        props["role"] = .attribute(name: "role", value: "textbox")
        props["aria-multiline"] = .attribute(name: "aria-multiline", value: "true")

        // Create a text node with the current value
        let textNode = VNode.text(text.wrappedValue)

        return VNode.element(
            "textarea",
            props: props,
            children: [textNode]
        )
    }

    // MARK: - Internal Access

    /// Provides access to the text binding for the render coordinator.
    @MainActor public var textBinding: Binding<String> {
        text
    }
}

// MARK: - Coordinator Renderable

extension TextField: _CoordinatorRenderable {
    @MainActor public func _render(with context: any _RenderContext) -> VNode {
        let binding = text
        let handlerID = context.registerInputHandler { event in
            if let newValue = event.target.value.string {
                binding.wrappedValue = newValue
            }
        }

        var props: [String: VProperty] = [
            "type": .attribute(name: "type", value: "text"),
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
        props["aria-label"] = .attribute(name: "aria-label", value: placeholder)
        props["role"] = .attribute(name: "role", value: "textbox")
        return VNode.element("input", props: props, children: [])
    }
}
