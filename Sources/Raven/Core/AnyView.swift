// MARK: - AnyView

/// A type-erased view.
///
/// `AnyView` wraps any view and erases its specific type, allowing you to return
/// different view types from a single code path. This is useful when branches
/// of your view logic need to return different concrete types.
///
/// ## Overview
///
/// Use `AnyView` when you need to return views of different types from a function
/// or computed property. While Swift's type system normally requires consistent
/// return types, `AnyView` provides type erasure to work around this constraint.
///
/// ## Basic Usage
///
/// Wrap different view types in `AnyView` to return them from a single function:
///
/// ```swift
/// func makeView(condition: Bool) -> AnyView {
///     if condition {
///         return AnyView(Text("True"))
///     } else {
///         return AnyView(Image("false"))
///     }
/// }
/// ```
///
/// ## Using eraseToAnyView()
///
/// Use the `eraseToAnyView()` method for more concise type erasure:
///
/// ```swift
/// func makeView(style: ViewStyle) -> AnyView {
///     switch style {
///     case .text:
///         return Text("Hello").font(.title).eraseToAnyView()
///     case .image:
///         return Image("icon").frame(width: 100).eraseToAnyView()
///     case .button:
///         return Button("Tap") { }.eraseToAnyView()
///     }
/// }
/// ```
///
/// ## When to Use AnyView
///
/// Use `AnyView` when:
/// - Returning different view types from complex conditional logic
/// - Storing views of different types in a collection
/// - Working with dynamic view hierarchies
///
/// ## Alternatives to AnyView
///
/// Prefer these approaches when possible for better performance:
///
/// **Use @ViewBuilder instead:**
/// ```swift
/// @ViewBuilder
/// func makeView(condition: Bool) -> some View {
///     if condition {
///         Text("True")
///     } else {
///         Image("false")
///     }
/// }
/// ```
///
/// **Use Group for simple cases:**
/// ```swift
/// var body: some View {
///     Group {
///         if condition {
///             Text("True")
///         } else {
///             Image("false")
///         }
///     }
/// }
/// ```
///
/// - Important: Type erasure has a performance cost. When possible, use
///   `@ViewBuilder`, generics, or conditional view modifiers instead.
///
/// ## See Also
///
/// - ``View/eraseToAnyView()``
/// - ``ViewBuilder``
public struct AnyView: View, PrimitiveView, Sendable {
    public typealias Body = Never

    /// The type-erased rendering closure.
    ///
    /// This closure captures the original view and will be called during
    /// the rendering phase to produce the virtual DOM node.
    private let _render: @Sendable @MainActor () -> VNode

    /// Creates a type-erased view from the given view.
    ///
    /// Use this initializer to wrap any view in an `AnyView`, erasing its
    /// specific type information.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let textView = AnyView(Text("Hello"))
    /// let imageView = AnyView(Image("icon"))
    /// let views: [AnyView] = [textView, imageView]
    /// ```
    ///
    /// - Parameter view: The view to wrap.
    @MainActor public init<Content: View>(_ view: Content) {
        // Capture the view in the closure and use recursive rendering
        self._render = { @MainActor in
            renderView(view)
        }
    }

    /// Renders the type-erased view to a virtual DOM node.
    ///
    /// This method is called by the rendering system to produce the actual
    /// DOM representation of the wrapped view.
    @MainActor public func render() -> VNode {
        _render()
    }

    /// Converts this type-erased view into a virtual DOM node.
    ///
    /// This is required by the PrimitiveView protocol and delegates to the render() method.
    ///
    /// - Returns: A VNode representing this view's DOM structure.
    @MainActor public func toVNode() -> VNode {
        render()
    }
}

// MARK: - Recursive View Rendering

/// Recursively renders a view to a VNode.
///
/// This function handles both primitive views (with `Body == Never`) and
/// composite views (which have a body property). For primitive views, it
/// attempts to call `toVNode()` if the view conforms to `PrimitiveView`.
/// For composite views, it recursively renders the body.
///
/// - Parameter view: The view to render.
/// - Returns: A VNode representing the view.
@MainActor internal func renderView<V: View>(_ view: V) -> VNode {
    // Check if this is a primitive view (Body == Never)
    if V.Body.self == Never.self {
        // Try to cast to PrimitiveView and call toVNode()
        if let primitive = view as? any PrimitiveView {
            return primitive.toVNode()
        }

        // Fallback for primitive views that don't conform to PrimitiveView yet
        // This shouldn't happen in practice, but provides a safe fallback
        return VNode.element("div", props: [:], children: [
            VNode.text("AnyView: primitive view without toVNode()")
        ])
    } else {
        // Composite view - recursively render its body
        let body = view.body
        return renderView(body)
    }
}

