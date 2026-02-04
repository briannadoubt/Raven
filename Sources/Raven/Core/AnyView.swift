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
public struct AnyView: View, Sendable {
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
        // Capture the view in the closure
        self._render = { @MainActor in
            // This will be implemented by the rendering system
            // For now, we create a placeholder VNode
            VNode.component(key: String(describing: type(of: view)))
        }
    }

    /// Renders the type-erased view to a virtual DOM node.
    ///
    /// This method is called by the rendering system to produce the actual
    /// DOM representation of the wrapped view.
    @MainActor public func render() -> VNode {
        _render()
    }
}

