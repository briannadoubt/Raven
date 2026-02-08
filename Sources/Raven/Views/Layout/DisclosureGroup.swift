import Foundation

/// A collapsible view that shows or hides content based on the state of a disclosure control.
///
/// `DisclosureGroup` is a primitive view that creates a disclosure widget containing
/// a label and content. The user can click the label to expand or collapse the content.
/// The control displays a chevron indicator that rotates to indicate the current state.
///
/// ## Overview
///
/// Use `DisclosureGroup` to create hierarchical content that users can show or hide.
/// The disclosure group automatically manages its expanded state or you can provide
/// your own binding to coordinate with other state in your app.
///
/// ## Basic Usage
///
/// Create a disclosure group with automatic state management:
///
/// ```swift
/// DisclosureGroup("Advanced Settings") {
///     Toggle("Enable Feature", isOn: $featureEnabled)
///     Toggle("Debug Mode", isOn: $debugMode)
/// }
/// ```
///
/// ## With Binding
///
/// Use a binding to control the expanded state:
///
/// ```swift
/// @State private var isExpanded = false
///
/// var body: some View {
///     DisclosureGroup(isExpanded: $isExpanded) {
///         Text("Hidden content")
///     } label: {
///         Text("Details")
///     }
/// }
/// ```
///
/// ## Nested Disclosure Groups
///
/// Disclosure groups can be nested for hierarchical content:
///
/// ```swift
/// DisclosureGroup("Settings") {
///     DisclosureGroup("Appearance") {
///         Toggle("Dark Mode", isOn: $darkMode)
///         Toggle("Use System Theme", isOn: $useSystemTheme)
///     }
///     DisclosureGroup("Privacy") {
///         Toggle("Share Analytics", isOn: $shareAnalytics)
///         Toggle("Location Services", isOn: $locationEnabled)
///     }
/// }
/// ```
///
/// ## Accessibility
///
/// The disclosure group automatically includes proper ARIA attributes:
/// - `role="button"` on the header for interactive control
/// - `aria-expanded` to indicate expanded/collapsed state
/// - `aria-controls` to associate header with content
///
/// ## Best Practices
///
/// - Use clear, descriptive labels that indicate what content will be revealed
/// - Consider initial expanded state based on content importance
/// - Nest disclosure groups sparingly to avoid deep hierarchies
/// - Provide visual feedback for the expanded state
///
/// ## See Also
///
/// - ``Section``
/// - ``List``
public struct DisclosureGroup<Label: View, Content: View>: View, PrimitiveView, Sendable {
    public typealias Body = Never

    /// The label content displayed in the header
    private let label: Label

    /// The content to show when expanded
    private let content: Content

    /// Binding to the expanded state
    private let isExpandedBinding: Binding<Bool>?

    /// Internal state for when no external binding is provided
    @State private var internalExpanded: Bool = false

    // MARK: - Initializers

    /// Creates a disclosure group with an external binding to control the expanded state.
    ///
    /// Use this initializer when you need to coordinate the disclosure state with
    /// other parts of your app or when you want to programmatically control the
    /// expanded state.
    ///
    /// - Parameters:
    ///   - isExpanded: A binding to a Boolean value that determines whether the content is expanded.
    ///   - content: A view builder that creates the content to show when expanded.
    ///   - label: A view builder that creates the disclosure group's label.
    ///
    /// Example:
    /// ```swift
    /// @State private var showDetails = false
    ///
    /// var body: some View {
    ///     DisclosureGroup(isExpanded: $showDetails) {
    ///         Text("Detailed information")
    ///     } label: {
    ///         Text("Show Details")
    ///     }
    /// }
    /// ```
    @MainActor public init(
        isExpanded: Binding<Bool>,
        @ViewBuilder content: () -> Content,
        @ViewBuilder label: () -> Label
    ) {
        self.isExpandedBinding = isExpanded
        self.content = content()
        self.label = label()
    }

    /// Creates a disclosure group with internal state management.
    ///
    /// Use this initializer when you don't need to coordinate the disclosure state
    /// with other parts of your app. The disclosure group will manage its own
    /// expanded state internally.
    ///
    /// - Parameters:
    ///   - content: A view builder that creates the content to show when expanded.
    ///   - label: A view builder that creates the disclosure group's label.
    ///
    /// Example:
    /// ```swift
    /// DisclosureGroup {
    ///     Text("Hidden content")
    ///     Text("More hidden content")
    /// } label: {
    ///     Text("Show More")
    /// }
    /// ```
    @MainActor public init(
        @ViewBuilder content: () -> Content,
        @ViewBuilder label: () -> Label
    ) {
        self.isExpandedBinding = nil
        self.content = content()
        self.label = label()
    }

    // MARK: - VNode Conversion

    /// Converts this DisclosureGroup to a virtual DOM node.
    ///
    /// The DisclosureGroup is rendered as a `div` element with:
    /// - A header `div` with click handler and chevron indicator
    /// - A content `div` that shows/hides based on expanded state
    /// - Proper ARIA attributes for accessibility
    /// - CSS classes for styling
    ///
    /// The header includes:
    /// - `role="button"` for accessibility
    /// - `aria-expanded` attribute indicating state
    /// - `aria-controls` linking to content
    /// - Chevron indicator that rotates
    ///
    /// - Returns: A VNode configured as a disclosure group with interactive header and collapsible content.
    @MainActor public func toVNode() -> VNode {
        // Determine which state to use
        let expanded = isExpandedBinding?.wrappedValue ?? internalExpanded

        // Generate unique IDs for this disclosure group
        let groupID = UUID().uuidString
        let headerID = "disclosure-header-\(groupID)"
        let contentID = "disclosure-content-\(groupID)"
        let handlerID = UUID()

        // Create the chevron indicator
        let chevronClass = expanded
            ? "raven-disclosure-chevron raven-disclosure-chevron-expanded"
            : "raven-disclosure-chevron raven-disclosure-chevron-collapsed"

        let chevronProps: [String: VProperty] = [
            "class": .attribute(name: "class", value: chevronClass),
            "aria-hidden": .attribute(name: "aria-hidden", value: "true")
        ]

        // Use Unicode right-pointing triangle (▶) as chevron
        let chevronNode = VNode.element(
            "span",
            props: chevronProps,
            children: [VNode.text("▶")]
        )

        // Convert label to VNode
        let labelNodes: [VNode]
        if let textLabel = label as? Text {
            labelNodes = [textLabel.toVNode()]
        } else {
            // For complex labels, handled by render system
            labelNodes = []
        }

        // Create label container
        let labelContainerProps: [String: VProperty] = [
            "class": .attribute(name: "class", value: "raven-disclosure-label")
        ]

        let labelContainerNode = VNode.element(
            "span",
            props: labelContainerProps,
            children: labelNodes
        )

        // Create the header div
        let headerProps: [String: VProperty] = [
            "id": .attribute(name: "id", value: headerID),
            "class": .attribute(name: "class", value: "raven-disclosure-header"),
            "role": .attribute(name: "role", value: "button"),
            "aria-expanded": .attribute(name: "aria-expanded", value: expanded ? "true" : "false"),
            "aria-controls": .attribute(name: "aria-controls", value: contentID),
            "tabindex": .attribute(name: "tabindex", value: "0"),
            "onClick": .eventHandler(event: "click", handlerID: handlerID)
        ]

        let headerNode = VNode.element(
            "div",
            props: headerProps,
            children: [chevronNode, labelContainerNode]
        )

        // Create the content div
        let contentClass = expanded
            ? "raven-disclosure-content raven-disclosure-expanded"
            : "raven-disclosure-content raven-disclosure-collapsed"

        var contentProps: [String: VProperty] = [
            "id": .attribute(name: "id", value: contentID),
            "class": .attribute(name: "class", value: contentClass),
            "aria-labelledby": .attribute(name: "aria-labelledby", value: headerID)
        ]

        // When collapsed, hide the content
        if !expanded {
            contentProps["display"] = .style(name: "display", value: "none")
        }

        let contentNode = VNode.element(
            "div",
            props: contentProps,
            children: [] // Content will be populated by render system
        )

        // Create the outer container
        let containerClass = expanded
            ? "raven-disclosure-group raven-disclosure-expanded"
            : "raven-disclosure-group raven-disclosure-collapsed"

        let containerProps: [String: VProperty] = [
            "class": .attribute(name: "class", value: containerClass)
        ]

        return VNode.element(
            "div",
            props: containerProps,
            children: [headerNode, contentNode]
        )
    }

    // MARK: - Public API for Event Handling

    /// Gets the handler closure for the click event.
    ///
    /// This is used by the render coordinator to register the event handler
    /// that toggles the expanded state when the header is clicked.
    ///
    /// - Returns: A closure that toggles the expanded state.
    @MainActor public var clickHandler: @Sendable @MainActor () -> Void {
        { [self] in
            if let binding = isExpandedBinding {
                binding.wrappedValue.toggle()
            } else {
                internalExpanded.toggle()
            }
        }
    }
}

// MARK: - Convenience Initializers

extension DisclosureGroup where Label == Text {
    /// Creates a disclosure group with a text label and external binding.
    ///
    /// This is a convenience initializer for creating simple text-based disclosure groups
    /// with external state management.
    ///
    /// - Parameters:
    ///   - titleKey: A localized string key for the disclosure group's label.
    ///   - isExpanded: A binding to a Boolean value that determines whether the content is expanded.
    ///   - content: A view builder that creates the content to show when expanded.
    ///
    /// Example:
    /// ```swift
    /// @State private var showAdvanced = false
    ///
    /// var body: some View {
    ///     DisclosureGroup("Advanced Options", isExpanded: $showAdvanced) {
    ///         Toggle("Debug Mode", isOn: $debugMode)
    ///     }
    /// }
    /// ```
    @MainActor public init(
        _ titleKey: LocalizedStringKey,
        isExpanded: Binding<Bool>,
        @ViewBuilder content: () -> Content
    ) {
        self.isExpandedBinding = isExpanded
        self.content = content()
        self.label = Text(titleKey)
    }

    /// Creates a disclosure group with a string label and external binding.
    ///
    /// - Parameters:
    ///   - title: The string to display as the disclosure group's label.
    ///   - isExpanded: A binding to a Boolean value that determines whether the content is expanded.
    ///   - content: A view builder that creates the content to show when expanded.
    ///
    /// Example:
    /// ```swift
    /// @State private var showDetails = true
    ///
    /// var body: some View {
    ///     DisclosureGroup("Details", isExpanded: $showDetails) {
    ///         Text("Detailed information here")
    ///     }
    /// }
    /// ```
    @MainActor public init(
        _ title: String,
        isExpanded: Binding<Bool>,
        @ViewBuilder content: () -> Content
    ) {
        self.isExpandedBinding = isExpanded
        self.content = content()
        self.label = Text(title)
    }

    /// Creates a disclosure group with a text label and internal state management.
    ///
    /// This is a convenience initializer for creating simple text-based disclosure groups
    /// that manage their own expanded state.
    ///
    /// - Parameters:
    ///   - titleKey: A localized string key for the disclosure group's label.
    ///   - content: A view builder that creates the content to show when expanded.
    ///
    /// Example:
    /// ```swift
    /// DisclosureGroup("More Options") {
    ///     Toggle("Option 1", isOn: $option1)
    ///     Toggle("Option 2", isOn: $option2)
    /// }
    /// ```
    @MainActor public init(
        _ titleKey: LocalizedStringKey,
        @ViewBuilder content: () -> Content
    ) {
        self.isExpandedBinding = nil
        self.content = content()
        self.label = Text(titleKey)
    }

    /// Creates a disclosure group with a string label and internal state management.
    ///
    /// - Parameters:
    ///   - title: The string to display as the disclosure group's label.
    ///   - content: A view builder that creates the content to show when expanded.
    ///
    /// Example:
    /// ```swift
    /// DisclosureGroup("Settings") {
    ///     Text("Setting 1")
    ///     Text("Setting 2")
    /// }
    /// ```
    @MainActor public init(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) {
        self.isExpandedBinding = nil
        self.content = content()
        self.label = Text(title)
    }
}

// MARK: - Coordinator Renderable

extension DisclosureGroup: _CoordinatorRenderable {
    @MainActor public func _render(with context: any _RenderContext) -> VNode {
        let expanded = isExpandedBinding?.wrappedValue ?? internalExpanded
        let handlerID = context.registerClickHandler(clickHandler)

        // Generate unique IDs
        let groupID = UUID().uuidString
        let contentID = "disclosure-content-\(groupID)"

        // Chevron indicator
        let chevronProps: [String: VProperty] = [
            "aria-hidden": .attribute(name: "aria-hidden", value: "true"),
            "display": .style(name: "display", value: "inline-block"),
            "transition": .style(name: "transition", value: "transform 0.2s ease"),
            "transform": .style(name: "transform", value: expanded ? "rotate(90deg)" : "rotate(0deg)"),
            "margin-right": .style(name: "margin-right", value: "8px"),
        ]
        let chevronNode = VNode.element("span", props: chevronProps, children: [VNode.text("\u{25B6}")])

        // Render label
        let labelNode = context.renderChild(label)

        // Header div (clickable)
        let headerProps: [String: VProperty] = [
            "class": .attribute(name: "class", value: "raven-disclosure-header"),
            "role": .attribute(name: "role", value: "button"),
            "aria-expanded": .attribute(name: "aria-expanded", value: expanded ? "true" : "false"),
            "aria-controls": .attribute(name: "aria-controls", value: contentID),
            "tabindex": .attribute(name: "tabindex", value: "0"),
            "onClick": .eventHandler(event: "click", handlerID: handlerID),
            "cursor": .style(name: "cursor", value: "pointer"),
            "display": .style(name: "display", value: "flex"),
            "align-items": .style(name: "align-items", value: "center"),
            "padding": .style(name: "padding", value: "8px 0"),
            "user-select": .style(name: "user-select", value: "none"),
        ]
        let headerNode = VNode.element("div", props: headerProps, children: [chevronNode, labelNode])

        // Content div (conditionally displayed)
        var contentChildren: [VNode] = []
        if expanded {
            let contentNode = context.renderChild(content)
            if case .fragment = contentNode.type {
                contentChildren = contentNode.children
            } else {
                contentChildren = [contentNode]
            }
        }

        var contentProps: [String: VProperty] = [
            "id": .attribute(name: "id", value: contentID),
            "class": .attribute(name: "class", value: "raven-disclosure-content"),
            "padding-left": .style(name: "padding-left", value: "24px"),
        ]
        if !expanded {
            contentProps["display"] = .style(name: "display", value: "none")
        }
        let contentDiv = VNode.element("div", props: contentProps, children: contentChildren)

        // Container
        let containerProps: [String: VProperty] = [
            "class": .attribute(name: "class", value: "raven-disclosure-group"),
            "border-bottom": .style(name: "border-bottom", value: "1px solid #e5e7eb"),
        ]

        return VNode.element("div", props: containerProps, children: [headerNode, contentDiv])
    }
}
