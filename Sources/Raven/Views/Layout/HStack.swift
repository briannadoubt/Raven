import Foundation

/// A view that arranges its children in a horizontal line.
///
/// `HStack` is a layout container that stacks its child views horizontally,
/// from left to right (in LTR locales). It's a primitive view that renders
/// directly to a flexbox `div` element with `flex-direction: row`.
///
/// ## Overview
///
/// Use `HStack` to arrange views horizontally. It's commonly used for creating
/// rows of content, toolbars, navigation bars, and side-by-side layouts.
///
/// ## Basic Usage
///
/// Create a simple horizontal stack:
///
/// ```swift
/// HStack {
///     Text("Name:")
///     Text("John Doe")
///     Text("✓")
/// }
/// ```
///
/// ## Alignment
///
/// Control vertical alignment of children:
///
/// ```swift
/// HStack(alignment: .top) {
///     Image("avatar")
///         .frame(width: 50, height: 50)
///     VStack(alignment: .leading) {
///         Text("John Doe")
///         Text("Software Engineer")
///     }
/// }
///
/// HStack(alignment: .bottom) {
///     Text("Left")
///     Text("Right").font(.title)
/// }
/// ```
///
/// ## Spacing
///
/// Add consistent spacing between views:
///
/// ```swift
/// HStack(spacing: 12) {
///     Button("Cancel") { }
///     Button("OK") { }
/// }
/// ```
///
/// ## Common Patterns
///
/// **Navigation bar:**
/// ```swift
/// HStack {
///     Button(action: goBack) {
///         Image(systemName: "chevron.left")
///     }
///     Spacer()
///     Text("Title")
///         .font(.headline)
///     Spacer()
///     Button("Done") {
///         save()
///     }
/// }
/// .padding()
/// ```
///
/// **Label-value pairs:**
/// ```swift
/// VStack(spacing: 8) {
///     HStack {
///         Text("Name:")
///         Spacer()
///         Text(user.name)
///     }
///     HStack {
///         Text("Email:")
///         Spacer()
///         Text(user.email)
///     }
///     HStack {
///         Text("Role:")
///         Spacer()
///         Text(user.role)
///     }
/// }
/// ```
///
/// **Icon-text combination:**
/// ```swift
/// HStack(spacing: 8) {
///     Image(systemName: "star.fill")
///         .foregroundColor(.yellow)
///     Text("Favorites")
///     Spacer()
///     Text("\(favoriteCount)")
///         .foregroundColor(.gray)
/// }
/// ```
///
/// **Button toolbar:**
/// ```swift
/// HStack(spacing: 16) {
///     Button(action: { }) {
///         Image(systemName: "square.and.arrow.up")
///     }
///     Button(action: { }) {
///         Image(systemName: "heart")
///     }
///     Button(action: { }) {
///         Image(systemName: "bookmark")
///     }
///     Spacer()
///     Button(action: { }) {
///         Image(systemName: "ellipsis")
///     }
/// }
/// .padding()
/// ```
///
/// ## Using Spacer
///
/// Push views apart with `Spacer()`:
///
/// ```swift
/// HStack {
///     Text("Left")
///     Spacer()
///     Text("Right")
/// }
/// ```
///
/// ## See Also
///
/// - ``VStack``
///   - ``ZStack``
/// - ``Spacer``
///
/// - Parameters:
///   - alignment: The vertical alignment of child views. Defaults to `.center`.
///   - spacing: The horizontal spacing between child views in pixels. Defaults to `nil` (no explicit spacing).
///   - content: A view builder that creates the child views.
public struct HStack<Content: View>: View, PrimitiveView, Sendable {
    public typealias Body = Never

    /// The vertical alignment of child views
    let alignment: VerticalAlignment

    /// The spacing between child views in pixels
    let spacing: Double?

    /// The child views
    let content: Content

    // MARK: - Initializers

    /// Creates a horizontal stack with optional alignment and spacing.
    ///
    /// - Parameters:
    ///   - alignment: The vertical alignment of child views. Defaults to `.center`.
    ///   - spacing: The horizontal spacing between child views in pixels. Defaults to `nil`.
    ///   - content: A view builder that creates the child views.
    @MainActor public init(
        alignment: VerticalAlignment = .center,
        spacing: Double? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.alignment = alignment
        self.spacing = spacing
        self.content = content()
    }

    // MARK: - VNode Conversion

    /// Converts this HStack to a virtual DOM node.
    ///
    /// The HStack is rendered as a `div` element with flexbox styling:
    /// - `display: flex`
    /// - `flex-direction: row`
    /// - `align-items: <alignment>` (based on the alignment parameter)
    /// - `gap: <spacing>px` (if spacing is provided)
    ///
    /// Note: The children are not converted here. The RenderCoordinator
    /// will handle rendering the content by accessing the `content` property.
    ///
    /// - Returns: A VNode configured as a horizontal flexbox container.
    @MainActor public func toVNode() -> VNode {
        var props: [String: VProperty] = [
            "display": .style(name: "display", value: "flex"),
            "flex-direction": .style(name: "flex-direction", value: "row"),
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
