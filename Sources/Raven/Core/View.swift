/// The fundamental protocol for all views in Raven.
///
/// A view represents a piece of user interface that can be rendered to the DOM.
/// Types conforming to `View` must declare a `Body` associated type and implement
/// the `body` property to define their content and behavior.
///
/// Primitive views that render directly to DOM nodes use `Never` as their `Body` type
/// to indicate they have no further composition.
///
/// ## Creating Custom Views
///
/// Create custom views by conforming to the `View` protocol and implementing the `body` property:
///
/// ```swift
/// struct WelcomeView: View {
///     var body: some View {
///         VStack {
///             Text("Welcome to Raven")
///                 .font(.title)
///             Text("Build web apps with SwiftUI")
///                 .font(.body)
///         }
///     }
/// }
/// ```
///
/// ## Primitive Views
///
/// Primitive views render directly to DOM elements without further composition.
/// They use `Never` as their `Body` type:
///
/// ```swift
/// struct CustomButton: View {
///     typealias Body = Never
///
///     let title: String
///     let action: () -> Void
///
///     // Rendering logic implemented separately
/// }
/// ```
///
/// ## View Composition
///
/// Combine multiple views using layout containers like `VStack`, `HStack`, and `ZStack`:
///
/// ```swift
/// struct ProfileView: View {
///     var body: some View {
///         VStack {
///             Image("avatar")
///             Text("John Doe")
///             HStack {
///                 Button("Follow") { }
///                 Button("Message") { }
///             }
///         }
///     }
/// }
/// ```
///
/// - Note: Use `@ViewBuilder` in custom views to enable the same declarative syntax
///   used by built-in layout views.
///
/// ## See Also
///
/// - ``ViewBuilder``
/// - ``AnyView``
/// - ``body``
public protocol View: Sendable {
    /// The type of view representing the body of this view.
    ///
    /// When `Body` is `Never`, this view is a primitive that renders directly
    /// to the DOM without further composition.
    associatedtype Body: View

    /// The content and behavior of this view.
    ///
    /// Implement this property to define your view's structure and layout using
    /// declarative SwiftUI-style syntax. The `@ViewBuilder` attribute enables
    /// multi-statement closures and conditional logic.
    ///
    /// ## Example
    ///
    /// ```swift
    /// var body: some View {
    ///     VStack {
    ///         Text("Hello, World!")
    ///         if showButton {
    ///             Button("Tap Me") { }
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// - Note: This property is not required for primitive views where `Body` is `Never`.
    ///   Primitive views implement rendering logic directly rather than composing other views.
    @ViewBuilder @MainActor var body: Body { get }
}

// MARK: - Primitive View Protocol

/// A protocol for views that render directly to DOM elements without composition.
///
/// Primitive views implement their own `toVNode()` method to convert themselves
/// directly into virtual DOM nodes, rather than composing other views. These are
/// the building blocks of the view hierarchy.
///
/// ## Overview
///
/// Conforming to `PrimitiveView` marks a view as a leaf node in the view tree
/// that handles its own DOM rendering. Primitive views must:
/// - Have `Body` type of `Never`
/// - Implement `toVNode()` to produce a `VNode`
///
/// ## Example
///
/// ```swift
/// public struct Text: View, PrimitiveView {
///     public typealias Body = Never
///
///     @MainActor public func toVNode() -> VNode {
///         // Direct DOM rendering logic
///         return VNode.element("span", content: text)
///     }
/// }
/// ```
///
/// - Note: This protocol is used by the rendering system to identify views
///   that can be directly converted to DOM elements without recursion.
public protocol PrimitiveView: View where Body == Never {
    /// Converts this primitive view into a virtual DOM node.
    ///
    /// This method is called by the rendering system to produce the actual
    /// DOM representation of the view.
    ///
    /// - Returns: A VNode representing this view's DOM structure.
    @MainActor func toVNode() -> VNode
}

// MARK: - Never Extension

extension Never: View {
    /// Primitive views use `Never` as their body type to indicate
    /// they have no further composition.
    public typealias Body = Never

    /// This property is never called for primitive views.
    @MainActor public var body: Never {
        fatalError("Never.body should never be called")
    }
}

// MARK: - Default Implementations

extension View where Body == Never {
    /// Default implementation for primitive views.
    /// This property should never be accessed for primitive views.
    @MainActor public var body: Never {
        fatalError("\(type(of: self)).body should never be called for primitive views")
    }
}

// MARK: - Type Erasure Support

extension View {
    /// Wraps this view in a type-erased `AnyView`.
    ///
    /// Use this method when you need to return views of different types
    /// from a single code path. However, prefer `@ViewBuilder` with conditional
    /// statements when possible for better performance.
    ///
    /// ## Example
    ///
    /// ```swift
    /// func makeView(isLarge: Bool) -> AnyView {
    ///     if isLarge {
    ///         return Text("Large").font(.largeTitle).eraseToAnyView()
    ///     } else {
    ///         return Image("small").eraseToAnyView()
    ///     }
    /// }
    /// ```
    ///
    /// - Returns: A type-erased view wrapping this view.
    ///
    /// - Note: Type erasure has a small performance cost. When possible, use
    ///   `@ViewBuilder` or generics instead.
    @MainActor public func eraseToAnyView() -> AnyView {
        AnyView(self)
    }
}
