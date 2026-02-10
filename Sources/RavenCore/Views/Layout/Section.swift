import Foundation

/// A semantic container for grouping related content, typically used within forms.
///
/// `Section` is a primitive view that renders to an HTML `<fieldset>` element
/// when used within forms, or a `<section>` element in other contexts. It can
/// include an optional header (rendered as `<legend>` in fieldsets) and footer.
///
/// Example:
/// ```swift
/// Section(header: Text("Account Settings")) {
///     TextField("Username", text: $username)
///     TextField("Email", text: $email)
/// }
///
/// Section {
///     Text("Content without header")
/// }
/// ```
///
/// - Note: The Section view provides semantic grouping and improved accessibility
///   by using appropriate HTML structural elements.
public struct Section<Content: View, Header: View, Footer: View>: View, PrimitiveView, Sendable {
    public typealias Body = Never

    /// The child views contained in the section
    let content: Content

    /// Optional header view for the section
    let header: Header?

    /// Optional footer view for the section
    let footer: Footer?

    // MARK: - Initializers

    /// Creates a section with custom header, footer, and content.
    ///
    /// - Parameters:
    ///   - header: A view builder that creates the section's header.
    ///   - footer: A view builder that creates the section's footer.
    ///   - content: A view builder that creates the section's content.
    @MainActor public init(
        @ViewBuilder header: () -> Header,
        @ViewBuilder footer: () -> Footer,
        @ViewBuilder content: () -> Content
    ) {
        self.header = header()
        self.footer = footer()
        self.content = content()
    }

    // MARK: - VNode Conversion

    /// Converts this Section view to a virtual DOM node.
    ///
    /// The Section is rendered as a `<fieldset>` element with:
    /// - Optional `<legend>` element for the header
    /// - Semantic grouping of content
    /// - Default styling for spacing and layout
    ///
    /// Note: The children are not converted here. The RenderCoordinator
    /// will handle rendering the header, content, and footer by accessing
    /// the respective properties.
    ///
    /// - Returns: A VNode configured as a fieldset element.
    @MainActor public func toVNode() -> VNode {
        let props: [String: VProperty] = [
            // Default section styling
            "display": .style(name: "display", value: "flex"),
            "flex-direction": .style(name: "flex-direction", value: "column"),
            "gap": .style(name: "gap", value: "12px"),
            "padding": .style(name: "padding", value: "16px"),
            "border": .style(name: "border", value: "1px solid #e0e0e0"),
            "border-radius": .style(name: "border-radius", value: "8px"),
            "margin": .style(name: "margin", value: "0")
        ]

        // Return fieldset element with empty children - the RenderCoordinator will populate them
        return VNode.element(
            "fieldset",
            props: props,
            children: []
        )
    }
}

// MARK: - Convenience Initializers

extension Section where Header == EmptyView, Footer == EmptyView {
    /// Creates a section with only content, no header or footer.
    ///
    /// - Parameter content: A view builder that creates the section's content.
    ///
    /// Example:
    /// ```swift
    /// Section {
    ///     Text("Simple content")
    ///     Button("Action") { }
    /// }
    /// ```
    @MainActor public init(
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.header = nil
        self.footer = nil
    }
}

extension Section where Footer == EmptyView {
    /// Creates a section with a header and content, no footer.
    ///
    /// - Parameters:
    ///   - header: A view builder that creates the section's header.
    ///   - content: A view builder that creates the section's content.
    ///
    /// Example:
    /// ```swift
    /// Section(header: Text("Settings")) {
    ///     Toggle("Enable Feature", isOn: $enabled)
    /// }
    /// ```
    @MainActor public init(
        @ViewBuilder header: () -> Header,
        @ViewBuilder content: () -> Content
    ) {
        self.header = header()
        self.footer = nil
        self.content = content()
    }
}

extension Section where Header == Text, Footer == EmptyView {
    /// Creates a section with a text header and content.
    ///
    /// This is a convenience initializer for the common case of a simple text header.
    ///
    /// - Parameters:
    ///   - header: The text to display as the section header.
    ///   - content: A view builder that creates the section's content.
    ///
    /// Example:
    /// ```swift
    /// Section(header: "Account Information") {
    ///     TextField("Username", text: $username)
    /// }
    /// ```
    @MainActor public init(
        header: String,
        @ViewBuilder content: () -> Content
    ) {
        self.header = Text(header)
        self.footer = nil
        self.content = content()
    }
}

extension Section where Header == EmptyView {
    /// Creates a section with content and a footer, no header.
    ///
    /// - Parameters:
    ///   - footer: A view builder that creates the section's footer.
    ///   - content: A view builder that creates the section's content.
    ///
    /// Example:
    /// ```swift
    /// Section(footer: Text("Additional info")) {
    ///     TextField("Input", text: $input)
    /// }
    /// ```
    @MainActor public init(
        @ViewBuilder footer: () -> Footer,
        @ViewBuilder content: () -> Content
    ) {
        self.header = nil
        self.footer = footer()
        self.content = content()
    }
}

extension Section where Header == Text {
    /// Creates a section with a text header, footer, and content.
    ///
    /// - Parameters:
    ///   - header: The text to display as the section header.
    ///   - footer: A view builder that creates the section's footer.
    ///   - content: A view builder that creates the section's content.
    ///
    /// Example:
    /// ```swift
    /// Section(header: "Settings", footer: Text("Changes apply immediately")) {
    ///     Toggle("Enable", isOn: $enabled)
    /// }
    /// ```
    @MainActor public init(
        header: String,
        @ViewBuilder footer: () -> Footer,
        @ViewBuilder content: () -> Content
    ) {
        self.header = Text(header)
        self.footer = footer()
        self.content = content()
    }
}

// MARK: - Coordinator Renderable

extension Section: _CoordinatorRenderable {
    @MainActor public func _render(with context: any _RenderContext) -> VNode {
        let wrapperNode = toVNode()
        var children: [VNode] = []

        // Render header as legend if present
        if let header = header, !(header is EmptyView) {
            let headerNode = context.renderChild(header)
            let legendProps: [String: VProperty] = [
                "class": .attribute(name: "class", value: "raven-section-legend"),
                "font-weight": .style(name: "font-weight", value: "600"),
                "font-size": .style(name: "font-size", value: "14px"),
                "color": .style(name: "color", value: "#374151"),
            ]
            children.append(VNode.element("legend", props: legendProps, children: [headerNode]))
        }

        // Render content
        let contentNode = context.renderChild(content)
        if case .fragment = contentNode.type {
            children.append(contentsOf: contentNode.children)
        } else {
            children.append(contentNode)
        }

        // Render footer if present
        if let footer = footer, !(footer is EmptyView) {
            let footerNode = context.renderChild(footer)
            let footerProps: [String: VProperty] = [
                "class": .attribute(name: "class", value: "raven-section-footer"),
                "font-size": .style(name: "font-size", value: "12px"),
                "color": .style(name: "color", value: "#6b7280"),
                "margin-top": .style(name: "margin-top", value: "8px"),
            ]
            children.append(VNode.element("div", props: footerProps, children: [footerNode]))
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
