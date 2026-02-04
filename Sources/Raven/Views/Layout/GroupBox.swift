import Foundation

/// A container that groups related content with an optional label and styled border.
///
/// `GroupBox` is a primitive view that renders directly to a `<fieldset>` element in the DOM,
/// with an optional `<legend>` for the label. It provides visual grouping of related content
/// and is particularly useful in forms for organizing related controls.
///
/// ## Overview
///
/// Use `GroupBox` to visually group related controls and content. The group box automatically
/// provides a border and background styling, and can display an optional label.
///
/// ## Basic Usage
///
/// Create a group box with content only:
///
/// ```swift
/// GroupBox {
///     Toggle("Enable Notifications", isOn: $notificationsEnabled)
///     Toggle("Enable Sounds", isOn: $soundsEnabled)
/// }
/// ```
///
/// ## With Label
///
/// Add a text label to the group box:
///
/// ```swift
/// GroupBox("Settings") {
///     Toggle("Enable Feature", isOn: $featureEnabled)
///     Slider(value: $volume, in: 0...100)
/// }
/// ```
///
/// ## Custom Label
///
/// Use a custom view as the label:
///
/// ```swift
/// GroupBox {
///     Text("Description of settings")
///     Toggle("Option 1", isOn: $option1)
///     Toggle("Option 2", isOn: $option2)
/// } label: {
///     Label("Advanced Options", systemImage: "gearshape")
/// }
/// ```
///
/// ## In Forms
///
/// Group related form fields:
///
/// ```swift
/// Form {
///     GroupBox("Personal Information") {
///         TextField("First Name", text: $firstName)
///         TextField("Last Name", text: $lastName)
///         TextField("Email", text: $email)
///     }
///
///     GroupBox("Preferences") {
///         Toggle("Newsletter", isOn: $newsletter)
///         Picker("Theme", selection: $theme) {
///             Text("Light").tag("light")
///             Text("Dark").tag("dark")
///         }
///     }
/// }
/// ```
///
/// ## Best Practices
///
/// - Use group boxes to organize logically related controls
/// - Keep labels concise and descriptive
/// - Avoid overly nesting group boxes
/// - Use appropriate styling for visual hierarchy
///
/// ## See Also
///
/// - ``Form``
/// - ``Section``
/// - ``DisclosureGroup``
public struct GroupBox<Label: View, Content: View>: View, PrimitiveView, Sendable {
    public typealias Body = Never

    /// The label content displayed in the legend
    private let label: Label?

    /// The content to display inside the group box
    private let content: Content

    /// Flag indicating if a label is present
    private let hasLabel: Bool

    // MARK: - Initializers

    /// Creates a group box with content and a custom label.
    ///
    /// - Parameters:
    ///   - content: A view builder that creates the content inside the group box.
    ///   - label: A view builder that creates the group box's label.
    @MainActor public init(
        @ViewBuilder content: () -> Content,
        @ViewBuilder label: () -> Label
    ) {
        self.content = content()
        self.label = label()
        self.hasLabel = true
    }

    /// Creates a group box with content only (no label).
    ///
    /// - Parameter content: A view builder that creates the content inside the group box.
    @MainActor public init(
        @ViewBuilder content: () -> Content
    ) where Label == EmptyView {
        self.content = content()
        self.label = nil
        self.hasLabel = false
    }

    // MARK: - VNode Conversion

    /// Converts this GroupBox to a virtual DOM node.
    ///
    /// The GroupBox is rendered as a `<fieldset>` element with:
    /// - An optional `<legend>` for the label if provided
    /// - The content inside the fieldset
    /// - CSS classes for styling
    /// - ARIA attributes for accessibility
    ///
    /// - Returns: A VNode configured as a fieldset with legend and content.
    @MainActor public func toVNode() -> VNode {
        // Build the children of the fieldset
        var children: [VNode] = []

        // Add legend if label is present
        if hasLabel, let label = label {
            let legendProps: [String: VProperty] = [
                "class": .attribute(name: "class", value: "raven-groupbox-legend")
            ]

            let legendNode = VNode.element(
                "legend",
                props: legendProps,
                children: []
            )
            children.append(legendNode)
        }

        // Create the fieldset properties
        let fieldsetProps: [String: VProperty] = [
            "class": .attribute(name: "class", value: "raven-groupbox"),
            "style": .style(name: "style", value: "border: 1px solid #e0e0e0; border-radius: 4px; padding: 12px; margin: 8px 0;")
        ]

        return VNode.element(
            "fieldset",
            props: fieldsetProps,
            children: children
        )
    }
}

// MARK: - Convenience Initializers

extension GroupBox where Label == Text {
    /// Creates a group box with a text label.
    ///
    /// - Parameters:
    ///   - titleKey: A localized string key for the group box's label.
    ///   - content: A view builder that creates the content inside the group box.
    ///
    /// Example:
    /// ```swift
    /// GroupBox("Settings") {
    ///     Toggle("Enable Feature", isOn: $featureEnabled)
    ///     Slider(value: $volume, in: 0...100)
    /// }
    /// ```
    @MainActor public init(
        _ titleKey: LocalizedStringKey,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.label = Text(titleKey)
        self.hasLabel = true
    }

    /// Creates a group box with a string label.
    ///
    /// - Parameters:
    ///   - title: The string to display as the group box's label.
    ///   - content: A view builder that creates the content inside the group box.
    ///
    /// Example:
    /// ```swift
    /// GroupBox("Preferences") {
    ///     Toggle("Dark Mode", isOn: $darkMode)
    /// }
    /// ```
    @MainActor public init(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.label = Text(title)
        self.hasLabel = true
    }
}
