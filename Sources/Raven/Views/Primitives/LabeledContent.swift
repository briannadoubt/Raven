import Foundation

/// A labeled content view that displays a label alongside custom content in a two-column layout.
///
/// `LabeledContent` is a primitive view that renders a label-content pair in a horizontal layout,
/// commonly used in forms and preference panes for displaying key-value pairs or associated information.
///
/// ## Overview
///
/// Use `LabeledContent` to create form fields where a label describes the adjacent content.
/// The view automatically arranges the label and content in a two-column layout.
///
/// ## Basic Usage
///
/// Display a simple key-value pair with string values:
///
/// ```swift
/// LabeledContent("Name", value: user.name)
/// LabeledContent("Email", value: user.email)
/// LabeledContent("Age", value: "\(user.age)")
/// ```
///
/// ## Custom Content
///
/// Use a view builder for custom content beyond simple text:
///
/// ```swift
/// LabeledContent("Status") {
///     Text("Active")
///         .foregroundColor(.green)
/// }
///
/// LabeledContent("Rating") {
///     HStack(spacing: 2) {
///         ForEach(0..<5, id: \.self) { i in
///             Image(systemName: i < rating ? "star.fill" : "star")
///                 .foregroundColor(.yellow)
///         }
///     }
/// }
/// ```
///
/// ## In Forms
///
/// Use with Form containers for organized data entry:
///
/// ```swift
/// Form {
///     LabeledContent("Username", value: username)
///     LabeledContent("Email", value: email)
///     LabeledContent("Account Status") {
///         Text(accountActive ? "Active" : "Inactive")
///             .foregroundColor(accountActive ? .green : .red)
///     }
/// }
/// ```
///
/// ## Custom Labels
///
/// Use view builders for both label and content:
///
/// ```swift
/// LabeledContent(
///     content: {
///         Text(value)
///             .font(.body)
///     },
///     label: {
///         HStack {
///             Image(systemName: "person")
///             Text("Name")
///         }
///     }
/// )
/// ```
///
/// ## Best Practices
///
/// - Keep labels concise and descriptive
/// - Use consistent label width for aligned layouts
/// - Use with Form for better visual hierarchy
/// - Pair with appropriate content types for clarity
///
/// ## See Also
///
/// - ``Form``
/// - ``Text``
/// - ``Label``
public struct LabeledContent<Label: View, Content: View>: View, PrimitiveView, Sendable {
    public typealias Body = Never

    /// The label view
    private let label: Label

    /// The content view
    private let content: Content

    // MARK: - Initializers

    /// Creates a labeled content view with custom label and content views.
    ///
    /// - Parameters:
    ///   - content: A view builder that creates the content.
    ///   - label: A view builder that creates the label.
    @MainActor public init(
        @ViewBuilder content: () -> Content,
        @ViewBuilder label: () -> Label
    ) {
        self.content = content()
        self.label = label()
    }

    // MARK: - VNode Conversion

    /// Converts this LabeledContent to a virtual DOM node.
    ///
    /// The LabeledContent is rendered as a `<div>` with flexbox row layout containing:
    /// - A label `<div>` with flex-basis for consistent width
    /// - A content `<div>` that fills remaining space
    /// - CSS classes for styling
    /// - Proper spacing between label and content
    ///
    /// - Returns: A VNode configured as a horizontal labeled content container.
    @MainActor public func toVNode() -> VNode {
        // Create label container
        let labelProps: [String: VProperty] = [
            "class": .attribute(name: "class", value: "raven-labeled-content-label"),
            "style": .style(name: "style", value: "flex: 0 0 auto; margin-right: 12px; min-width: 100px;")
        ]

        let labelNode = VNode.element(
            "div",
            props: labelProps,
            children: []
        )

        // Create content container
        let contentProps: [String: VProperty] = [
            "class": .attribute(name: "class", value: "raven-labeled-content-content"),
            "style": .style(name: "style", value: "flex: 1 1 auto;")
        ]

        let contentNode = VNode.element(
            "div",
            props: contentProps,
            children: []
        )

        // Create outer container with flexbox layout
        let containerProps: [String: VProperty] = [
            "class": .attribute(name: "class", value: "raven-labeled-content"),
            "style": .style(name: "style", value: "display: flex; flex-direction: row; align-items: center; gap: 8px;")
        ]

        return VNode.element(
            "div",
            props: containerProps,
            children: [labelNode, contentNode]
        )
    }
}

// MARK: - Convenience Initializers

extension LabeledContent where Label == Text, Content == Text {
    /// Creates a labeled content view with text label and string value.
    ///
    /// - Parameters:
    ///   - titleKey: A localized string key for the label.
    ///   - value: The string value to display as content.
    ///
    /// Example:
    /// ```swift
    /// LabeledContent("Name", value: user.name)
    /// LabeledContent("Email", value: user.email)
    /// ```
    @MainActor public init(
        _ titleKey: LocalizedStringKey,
        value: String
    ) {
        self.label = Text(titleKey)
        self.content = Text(value)
    }

    /// Creates a labeled content view with text label and string value.
    ///
    /// - Parameters:
    ///   - title: The string to display as the label.
    ///   - value: The string value to display as content.
    ///
    /// Example:
    /// ```swift
    /// LabeledContent("Username", value: username)
    /// LabeledContent("Status", value: "Active")
    /// ```
    @MainActor public init(
        _ title: String,
        value: String
    ) {
        self.label = Text(title)
        self.content = Text(value)
    }
}

extension LabeledContent where Label == Text {
    /// Creates a labeled content view with a text label and custom content.
    ///
    /// - Parameters:
    ///   - titleKey: A localized string key for the label.
    ///   - content: A view builder that creates the content.
    ///
    /// Example:
    /// ```swift
    /// LabeledContent("Status") {
    ///     Text("Active")
    ///         .foregroundColor(.green)
    /// }
    /// ```
    @MainActor public init(
        _ titleKey: LocalizedStringKey,
        @ViewBuilder content: () -> Content
    ) {
        self.label = Text(titleKey)
        self.content = content()
    }

    /// Creates a labeled content view with a text label and custom content.
    ///
    /// - Parameters:
    ///   - title: The string to display as the label.
    ///   - content: A view builder that creates the content.
    ///
    /// Example:
    /// ```swift
    /// LabeledContent("Rating") {
    ///     HStack {
    ///         ForEach(0..<5, id: \.self) { _ in
    ///             Image(systemName: "star.fill")
    ///         }
    ///     }
    /// }
    /// ```
    @MainActor public init(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) {
        self.label = Text(title)
        self.content = content()
    }
}
