import Foundation

/// A semantic container for grouping form controls and input elements.
///
/// `Form` is a primitive view that renders directly to an HTML `<form>` element.
/// It provides semantic structure for forms and includes accessibility attributes.
/// Form submission is handled in Swift rather than traditional HTML form submission.
///
/// Example:
/// ```swift
/// Form {
///     Section(header: Text("Personal Information")) {
///         TextField("Name", text: $name)
///         TextField("Email", text: $email)
///     }
///
///     Section(header: Text("Preferences")) {
///         Toggle("Notifications", isOn: $notificationsEnabled)
///         Toggle("Dark Mode", isOn: $darkMode)
///     }
/// }
/// ```
///
/// - Note: The form element prevents default submission behavior and handles
///   all interactions through Swift event handlers.
public struct Form<Content: View>: View, PrimitiveView, Sendable {
    public typealias Body = Never

    /// The child views contained in the form
    let content: Content

    // MARK: - Initializers

    /// Creates a form with the specified content.
    ///
    /// - Parameter content: A view builder that creates the form's content.
    @MainActor public init(
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
    }

    // MARK: - VNode Conversion

    /// Converts this Form view to a virtual DOM node.
    ///
    /// The Form is rendered as a `<form>` element with:
    /// - `role="form"` for enhanced accessibility
    /// - Default vertical layout styling (flexbox column)
    /// - Submit event prevention (handled in Swift)
    ///
    /// Note: The children are not converted here. The RenderCoordinator
    /// will handle rendering the content by accessing the `content` property.
    ///
    /// - Returns: A VNode configured as a form element.
    @MainActor public func toVNode() -> VNode {
        // Generate a unique ID for the submit event handler
        let handlerID = UUID()

        let props: [String: VProperty] = [
            // Accessibility
            "role": .attribute(name: "role", value: "form"),

            // Prevent default form submission
            "onSubmit": .eventHandler(event: "submit", handlerID: handlerID),

            // Default form styling - vertical layout
            "display": .style(name: "display", value: "flex"),
            "flex-direction": .style(name: "flex-direction", value: "column"),
            "gap": .style(name: "gap", value: "16px"),
            "width": .style(name: "width", value: "100%")
        ]

        // Return form element with empty children - the RenderCoordinator will populate them
        return VNode.element(
            "form",
            props: props,
            children: []
        )
    }
}

// MARK: - Coordinator Renderable

extension Form: _CoordinatorRenderable {
    @MainActor public func _render(with context: any _RenderContext) -> VNode {
        let wrapperNode = toVNode()
        let contentNode = context.renderChild(content)

        let children: [VNode]
        if case .fragment = contentNode.type {
            children = contentNode.children
        } else {
            children = [contentNode]
        }

        return VNode(
            id: wrapperNode.id,
            type: wrapperNode.type,
            props: wrapperNode.props,
            children: children,
            key: wrapperNode.key
        )
    }
}
