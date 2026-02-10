import Foundation

/// A view that overlays its children, aligning them in both axes.
///
/// `ZStack` is a layout container that layers its child views on top of each other,
/// similar to CSS `position: absolute` layering. The first child appears at the back,
/// and subsequent children are layered on top.
///
/// ## Overview
///
/// Use `ZStack` to layer views on top of each other, creating overlays, badges,
/// watermarks, or any design that requires view layering.
///
/// ## Basic Usage
///
/// Layer views on top of each other:
///
/// ```swift
/// ZStack {
///     Rectangle()
///         .fill(Color.blue)
///         .frame(width: 100, height: 100)
///     Text("Overlay")
///         .foregroundColor(.white)
/// }
/// ```
///
/// ## Alignment
///
/// Control how children are aligned within the stack:
///
/// ```swift
/// ZStack(alignment: .topLeading) {
///     Image("background")
///     Text("Badge")
///         .padding(4)
///         .background(Color.red)
///         .foregroundColor(.white)
/// }
///
/// ZStack(alignment: .bottomTrailing) {
///     Image("profile")
///     Image(systemName: "checkmark.circle.fill")
///         .foregroundColor(.green)
/// }
/// ```
///
/// ## Common Patterns
///
/// **Image with overlay:**
/// ```swift
/// ZStack(alignment: .bottom) {
///     Image("photo")
///         .frame(width: 300, height: 200)
///
///     VStack {
///         Text("Title")
///             .font(.title)
///         Text("Description")
///             .font(.caption)
///     }
///     .frame(maxWidth: .infinity)
///     .padding()
///     .background(Color.black.opacity(0.6))
///     .foregroundColor(.white)
/// }
/// ```
///
/// **Badge on icon:**
/// ```swift
/// ZStack(alignment: .topTrailing) {
///     Image(systemName: "bell")
///         .font(.title)
///
///     if unreadCount > 0 {
///         Text("\(unreadCount)")
///             .font(.caption2)
///             .padding(4)
///             .background(Color.red)
///             .foregroundColor(.white)
///             .clipShape(Circle())
///             .offset(x: 10, y: -10)
///     }
/// }
/// ```
///
/// **Loading indicator:**
/// ```swift
/// ZStack {
///     ContentView()
///
///     if isLoading {
///         Color.black.opacity(0.4)
///
///         VStack {
///             ProgressView()
///             Text("Loading...")
///                 .foregroundColor(.white)
///         }
///     }
/// }
/// ```
///
/// **Background with content:**
/// ```swift
/// ZStack {
///     // Background
///     LinearGradient(
///         colors: [.blue, .purple],
///         startPoint: .topLeading,
///         endPoint: .bottomTrailing
///     )
///     .ignoresSafeArea()
///
///     // Content
///     VStack(spacing: 20) {
///         Text("Welcome")
///             .font(.largeTitle)
///         Button("Get Started") {
///             startApp()
///         }
///     }
///     .foregroundColor(.white)
/// }
/// ```
///
/// **Card with corner badge:**
/// ```swift
/// ZStack(alignment: .topLeading) {
///     VStack(alignment: .leading) {
///         Text("Title")
///             .font(.headline)
///         Text("Description")
///     }
///     .padding()
///     .frame(maxWidth: .infinity)
///     .background(Color.white)
///     .cornerRadius(12)
///
///     Text("NEW")
///         .font(.caption)
///         .padding(4)
///         .background(Color.green)
///         .foregroundColor(.white)
///         .offset(x: 8, y: -8)
/// }
/// ```
///
/// ## Layering Order
///
/// Views are layered from back to front in the order they appear:
///
/// ```swift
/// ZStack {
///     Circle().fill(Color.blue)   // Back layer
///     Circle().fill(Color.red).scaleEffect(0.7)   // Middle
///     Circle().fill(Color.yellow).scaleEffect(0.4) // Front layer
/// }
/// ```
///
/// ## See Also
///
/// - ``VStack``
/// - ``HStack``
/// - ``Alignment``
///
/// - Parameters:
///   - alignment: The alignment guide for positioning child views. Defaults to `.center`.
///   - content: A view builder that creates the child views.
public struct ZStack<Content: View>: View, PrimitiveView, Sendable {
    public typealias Body = Never

    /// The alignment of child views within the stack
    let alignment: Alignment

    /// The child views
    let content: Content

    // MARK: - Initializers

    /// Creates a depth-based stack with optional alignment.
    ///
    /// - Parameters:
    ///   - alignment: The alignment of child views. Defaults to `.center`.
    ///   - content: A view builder that creates the child views.
    @MainActor public init(
        alignment: Alignment = .center,
        @ViewBuilder content: () -> Content
    ) {
        self.alignment = alignment
        self.content = content()
    }

    // MARK: - VNode Conversion

    /// Converts this ZStack to a virtual DOM node.
    ///
    /// The ZStack is rendered as a `div` element with positioning:
    /// - Container: `position: relative` with alignment settings
    /// - Children: Will be rendered with `position: absolute` and positioned based on alignment
    ///
    /// The alignment determines how children are positioned:
    /// - Horizontal alignment (leading, center, trailing) maps to left/right positioning
    /// - Vertical alignment (top, center, bottom) maps to top/bottom positioning
    ///
    /// Note: The children are not converted here. The RenderCoordinator
    /// will handle rendering the content by accessing the `content` property.
    ///
    /// - Returns: A VNode configured as a layered container.
    @MainActor public func toVNode() -> VNode {
        let props: [String: VProperty] = [
            "display": .style(name: "display", value: "grid"),
            "grid-template-columns": .style(name: "grid-template-columns", value: "1fr"),
            "grid-template-rows": .style(name: "grid-template-rows", value: "1fr"),
            "place-items": .style(name: "place-items", value: alignment.cssValue)
        ]

        // Return element with empty children - the RenderCoordinator will populate them
        return VNode.element(
            "div",
            props: props,
            children: []
        )
    }
}

extension ZStack: _CoordinatorRenderable {
    @MainActor public func _render(with context: any _RenderContext) -> VNode {
        let props: [String: VProperty] = [
            "display": .style(name: "display", value: "grid"),
            "grid-template-columns": .style(name: "grid-template-columns", value: "1fr"),
            "grid-template-rows": .style(name: "grid-template-rows", value: "1fr"),
            "place-items": .style(name: "place-items", value: alignment.cssValue)
        ]
        let contentNode = context.renderChild(content)
        let rawChildren: [VNode]
        if case .fragment = contentNode.type {
            rawChildren = contentNode.children
        } else {
            rawChildren = [contentNode]
        }
        let children = rawChildren.map { child in
            VNode.element("div", props: [
                "grid-row": .style(name: "grid-row", value: "1 / -1"),
                "grid-column": .style(name: "grid-column", value: "1 / -1")
            ], children: [child])
        }
        return VNode.element("div", props: props, children: children)
    }
}
