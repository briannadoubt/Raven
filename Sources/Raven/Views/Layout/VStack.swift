import Foundation

/// A view that arranges its children in a vertical line.
///
/// `VStack` is a layout container that stacks its child views vertically,
/// from top to bottom. It's a primitive view that renders directly to a
/// flexbox `div` element with `flex-direction: column`.
///
/// ## Overview
///
/// Use `VStack` to arrange views vertically. It's one of the most commonly
/// used layout containers in Raven, perfect for creating vertical lists,
/// forms, and content hierarchies.
///
/// ## Basic Usage
///
/// Create a simple vertical stack:
///
/// ```swift
/// VStack {
///     Text("Title")
///     Text("Subtitle")
///     Text("Description")
/// }
/// ```
///
/// ## Alignment
///
/// Control horizontal alignment of children:
///
/// ```swift
/// VStack(alignment: .leading) {
///     Text("Left aligned")
///     Text("Also left aligned")
/// }
///
/// VStack(alignment: .trailing) {
///     Text("Right aligned")
///     Text("Also right aligned")
/// }
/// ```
///
/// ## Spacing
///
/// Add consistent spacing between views:
///
/// ```swift
/// VStack(spacing: 16) {
///     Text("Item 1")
///     Text("Item 2")
///     Text("Item 3")
/// }
/// ```
///
/// ## Common Patterns
///
/// **Form layout:**
/// ```swift
/// VStack(alignment: .leading, spacing: 12) {
///     Text("Name")
///         .font(.headline)
///     TextField("Enter name", text: $name)
///
///     Text("Email")
///         .font(.headline)
///     TextField("Enter email", text: $email)
///
///     Button("Submit") {
///         submit()
///     }
/// }
/// ```
///
/// **Card content:**
/// ```swift
/// VStack(spacing: 8) {
///     Text("Card Title")
///         .font(.title)
///     Text("Card description goes here")
///         .font(.body)
///     Divider()
///     HStack {
///         Button("Action 1") { }
///         Button("Action 2") { }
///     }
/// }
/// .padding()
/// ```
///
/// **List of items:**
/// ```swift
/// VStack(spacing: 0) {
///     ForEach(items) { item in
///         HStack {
///             Text(item.title)
///             Spacer()
///             Image(systemName: "chevron.right")
///         }
///         .padding()
///         Divider()
///     }
/// }
/// ```
///
/// ## Nesting Stacks
///
/// Combine `VStack` with `HStack` for complex layouts:
///
/// ```swift
/// VStack(spacing: 20) {
///     HStack {
///         Text("Header Left")
///         Spacer()
///         Text("Header Right")
///     }
///
///     VStack(alignment: .leading) {
///         Text("Content line 1")
///         Text("Content line 2")
///     }
///
///     HStack {
///         Button("Cancel") { }
///         Button("OK") { }
///     }
/// }
/// ```
///
/// ## See Also
///
/// - ``HStack``
/// - ``ZStack``
/// - ``Spacer``
/// - ``Divider``
///
/// - Parameters:
///   - alignment: The horizontal alignment of child views. Defaults to `.center`.
///   - spacing: The vertical spacing between child views in pixels. Defaults to `nil` (no explicit spacing).
///   - content: A view builder that creates the child views.
public struct VStack<Content: View>: View, Sendable {
    public typealias Body = Never

    /// The horizontal alignment of child views
    let alignment: HorizontalAlignment

    /// The spacing between child views in pixels
    let spacing: Double?

    /// The child views
    let content: Content

    // MARK: - Initializers

    /// Creates a vertical stack with optional alignment and spacing.
    ///
    /// - Parameters:
    ///   - alignment: The horizontal alignment of child views. Defaults to `.center`.
    ///   - spacing: The vertical spacing between child views in pixels. Defaults to `nil`.
    ///   - content: A view builder that creates the child views.
    @MainActor public init(
        alignment: HorizontalAlignment = .center,
        spacing: Double? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.alignment = alignment
        self.spacing = spacing
        self.content = content()
    }

    // MARK: - VNode Conversion

    /// Converts this VStack to a virtual DOM node.
    ///
    /// The VStack is rendered as a `div` element with flexbox styling:
    /// - `display: flex`
    /// - `flex-direction: column`
    /// - `align-items: <alignment>` (based on the alignment parameter)
    /// - `gap: <spacing>px` (if spacing is provided)
    ///
    /// Note: The children are not converted here. The RenderCoordinator
    /// will handle rendering the content by accessing the `content` property.
    ///
    /// - Returns: A VNode configured as a vertical flexbox container.
    @MainActor public func toVNode() -> VNode {
        var props: [String: VProperty] = [
            "display": .style(name: "display", value: "flex"),
            "flex-direction": .style(name: "flex-direction", value: "column"),
            "align-items": .style(name: "align-items", value: alignment.cssValue)
        ]

        // Add gap spacing if provided
        if let spacing = spacing {
            props["gap"] = .style(name: "gap", value: "\(spacing)px")
        }

        // Return element with empty children - the RenderCoordinator will populate them
        return VNode.element(
            "div",
            props: props,
            children: []
        )
    }
}
