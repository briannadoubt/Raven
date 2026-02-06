import Foundation

/// A view that controls navigation to a destination view.
///
/// `NavigationLink` is a primitive view that renders as an interactive element
/// (typically a button or anchor tag) that triggers navigation when activated.
/// It works within a `NavigationView` to push new views onto the navigation stack.
///
/// Example:
/// ```swift
/// NavigationView {
///     VStack {
///         NavigationLink("Go to Detail", destination: DetailView())
///         NavigationLink(destination: SettingsView()) {
///             HStack {
///                 Image("settings")
///                 Text("Settings")
///             }
///         }
///     }
/// }
/// ```
///
/// For Phase 4, `NavigationLink` implements basic navigation with an in-memory stack.
/// Future phases will integrate with the browser's HTML5 History API for URL-based routing.
public struct NavigationLink<Label: View, Destination: View>: View, PrimitiveView, Sendable {
    public typealias Body = Never

    /// The label content to display
    private let label: Label

    /// The destination view to navigate to
    private let destination: Destination

    /// Whether this link is currently active
    private let isActive: Bool

    // MARK: - Initializers

    /// Creates a navigation link with a custom label.
    ///
    /// - Parameters:
    ///   - destination: The view to navigate to when the link is activated.
    ///   - label: A view builder that creates the link's label.
    @MainActor
    public init(
        destination: Destination,
        @ViewBuilder label: () -> Label
    ) {
        self.destination = destination
        self.label = label()
        self.isActive = false
    }

    /// Creates a navigation link with an active binding.
    ///
    /// Use this initializer when you need programmatic control over navigation.
    ///
    /// - Parameters:
    ///   - destination: The view to navigate to when active.
    ///   - isActive: A binding that controls whether the link is active.
    ///   - label: A view builder that creates the link's label.
    @MainActor
    public init(
        destination: Destination,
        isActive: Binding<Bool>,
        @ViewBuilder label: () -> Label
    ) {
        self.destination = destination
        self.label = label()
        self.isActive = isActive.wrappedValue
    }

    // MARK: - VNode Conversion

    /// Converts this NavigationLink to a virtual DOM node.
    ///
    /// For Phase 4, this renders as a button element with a click handler
    /// that will push the destination onto the navigation stack.
    /// Future phases may render as an anchor tag with proper href attributes.
    ///
    /// - Returns: A VNode representation of this navigation link.
    @MainActor
    public func toVNode() -> VNode {
        // Generate a unique ID for this navigation handler
        let handlerID = UUID()

        // Create the click event handler property
        let clickHandler = VProperty.eventHandler(event: "click", handlerID: handlerID)

        // Create properties for the navigation link
        var props: [String: VProperty] = [
            "onClick": clickHandler
        ]

        // Add a class to identify navigation links for styling
        props["class"] = .attribute(name: "class", value: "raven-navigation-link")

        // For Phase 4, render as a styled anchor-like button
        // The role attribute helps with accessibility
        props["role"] = .attribute(name: "role", value: "link")

        // Convert label to children nodes
        let children: [VNode]
        if let textLabel = label as? Text {
            // Optimize for simple text labels
            children = [textLabel.toVNode()]
        } else {
            // For complex labels, create a placeholder that will be handled by the render system
            children = []
        }

        return VNode.element(
            "button",
            props: props,
            children: children
        )
    }

    /// Access the destination view for navigation.
    ///
    /// This is used internally by the NavigationView to handle navigation actions.
    internal var destinationView: Destination {
        destination
    }

    /// Access the label view.
    ///
    /// This is used internally by the rendering system.
    internal var labelView: Label {
        label
    }
}

// MARK: - CoordinatorRenderable

extension NavigationLink: _CoordinatorRenderable {
    @MainActor public func _render(with context: any _RenderContext) -> VNode {
        // Register a click handler (no-op for now; actual push/pop navigation deferred)
        let handlerID = context.registerClickHandler({ })

        // Render the label content
        let labelNode = context.renderChild(label)

        // Spacer between label and chevron
        let spacerProps: [String: VProperty] = [
            "flex": .style(name: "flex", value: "1"),
        ]
        let spacerNode = VNode.element("div", props: spacerProps, children: [])

        // Chevron indicator
        let chevronNode = VNode.text(" \u{203A}")

        // Button element
        let props: [String: VProperty] = [
            "class": .attribute(name: "class", value: "raven-navigation-link"),
            "role": .attribute(name: "role", value: "link"),
            "onClick": .eventHandler(event: "click", handlerID: handlerID),
            "display": .style(name: "display", value: "flex"),
            "align-items": .style(name: "align-items", value: "center"),
            "width": .style(name: "width", value: "100%"),
            "padding": .style(name: "padding", value: "12px 16px"),
            "border": .style(name: "border", value: "none"),
            "background": .style(name: "background", value: "transparent"),
            "cursor": .style(name: "cursor", value: "pointer"),
            "color": .style(name: "color", value: "#007AFF"),
            "font-size": .style(name: "font-size", value: "inherit"),
            "text-align": .style(name: "text-align", value: "left"),
            "gap": .style(name: "gap", value: "8px"),
        ]
        return VNode.element("button", props: props, children: [labelNode, spacerNode, chevronNode])
    }
}

// MARK: - Text Label Convenience

extension NavigationLink where Label == Text {
    /// Creates a navigation link with a text label.
    ///
    /// This is a convenience initializer for creating simple text-based navigation links.
    ///
    /// - Parameters:
    ///   - title: The string to display as the link's label.
    ///   - destination: The view to navigate to when the link is activated.
    ///
    /// Example:
    /// ```swift
    /// NavigationLink("Show Details", destination: DetailView())
    /// ```
    @MainActor
    public init(
        _ title: String,
        destination: Destination
    ) {
        self.destination = destination
        self.label = Text(title)
        self.isActive = false
    }

    /// Creates a navigation link with a localized text label.
    ///
    /// - Parameters:
    ///   - titleKey: The localized string key for the link's label.
    ///   - destination: The view to navigate to when the link is activated.
    @MainActor
    public init(
        _ titleKey: LocalizedStringKey,
        destination: Destination
    ) {
        self.destination = destination
        self.label = Text(titleKey)
        self.isActive = false
    }

    /// Creates a navigation link with a text label and active binding.
    ///
    /// - Parameters:
    ///   - title: The string to display as the link's label.
    ///   - destination: The view to navigate to when active.
    ///   - isActive: A binding that controls whether the link is active.
    @MainActor
    public init(
        _ title: String,
        destination: Destination,
        isActive: Binding<Bool>
    ) {
        self.destination = destination
        self.label = Text(title)
        self.isActive = isActive.wrappedValue
    }
}
