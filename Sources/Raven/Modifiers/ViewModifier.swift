import Foundation

// MARK: - ViewModifier Protocol

/// A modifier that you apply to a view or another view modifier, producing a different version of the original value.
///
/// View modifiers allow you to create reusable, composable modifications to views. Unlike the basic
/// modifier pattern which returns specific wrapper views, the `ViewModifier` protocol provides a way
/// to define custom modifiers with their own body implementation.
///
/// ## Creating Custom Modifiers
///
/// To create a custom modifier, conform to the `ViewModifier` protocol and implement the `body(content:)` method:
///
/// ```swift
/// struct BorderModifier: ViewModifier {
///     let color: Color
///     let width: Double
///
///     func body(content: Content) -> some View {
///         content
///             .padding(4)
///             .foregroundColor(color)
///     }
/// }
/// ```
///
/// ## Using Modifiers
///
/// Apply custom modifiers using the `.modifier()` method:
///
/// ```swift
/// Text("Hello")
///     .modifier(BorderModifier(color: .blue, width: 2))
/// ```
///
/// Or create convenience extensions:
///
/// ```swift
/// extension View {
///     func border(_ color: Color, width: Double = 1) -> some View {
///         self.modifier(BorderModifier(color: color, width: width))
///     }
/// }
///
/// Text("Hello").border(.blue)
/// ```
public protocol ViewModifier: Sendable {
    /// The type of view representing the body of this modifier.
    associatedtype Body: View

    /// The content view being modified.
    ///
    /// This is a type alias for `_ViewModifier_Content<Self>` which provides
    /// access to the view being modified.
    typealias Content = _ViewModifier_Content<Self>

    /// Gets the current body of the modifier for the specified content.
    ///
    /// The `content` parameter represents the view being modified. You can apply
    /// additional modifiers to it, wrap it in other views, or transform it in any way.
    ///
    /// - Parameter content: The content view being modified.
    /// - Returns: The modified view.
    @ViewBuilder @MainActor func body(content: Content) -> Body
}

// MARK: - ViewModifier Content

/// A proxy for the content view being modified.
///
/// This type provides access to the view being modified within a `ViewModifier`'s `body` method.
/// It acts as a transparent wrapper that forwards the original view's structure.
public struct _ViewModifier_Content<Modifier: ViewModifier>: View, Sendable {
    /// The actual view being modified (type-erased)
    let view: AnyView

    /// Creates a content proxy for a view.
    ///
    /// - Parameter view: The view to wrap.
    @MainActor init<V: View>(_ view: V) {
        self.view = AnyView(view)
    }

    /// The body of the content is the wrapped view itself.
    @MainActor public var body: some View {
        view
    }
}

// MARK: - ModifiedContent with ViewModifier Support

/// A view that applies a modifier to another view.
///
/// `ModifiedContent` is the result of calling `.modifier()` on a view. It stores both
/// the original content and the modifier, and implements `View` by calling the modifier's
/// `body(content:)` method.
///
/// You typically don't create `ModifiedContent` directly. Instead, use the `.modifier()` method:
///
/// ```swift
/// Text("Hello")
///     .modifier(MyCustomModifier())
/// ```
///
/// ## Generic Modifiers
///
/// For basic modifiers that don't implement the full `ViewModifier` protocol (like `PaddingModifier`),
/// use the specific wrapper views like `_PaddingView` instead.
extension ModifiedContent where Modifier: ViewModifier {
    /// The body of the modified content.
    ///
    /// This calls the modifier's `body(content:)` method with the wrapped content.
    @MainActor public var body: Modifier.Body {
        modifier.body(content: _ViewModifier_Content(content))
    }
}

// MARK: - View Extension

extension View {
    /// Applies a custom modifier to this view.
    ///
    /// Use this method to apply custom view modifiers that conform to the `ViewModifier` protocol.
    /// The modifier can transform the view in any way by implementing its `body(content:)` method.
    ///
    /// Example:
    /// ```swift
    /// struct TitleModifier: ViewModifier {
    ///     func body(content: Content) -> some View {
    ///         content
    ///             .padding()
    ///             .foregroundColor(.blue)
    ///     }
    /// }
    ///
    /// Text("Hello")
    ///     .modifier(TitleModifier())
    /// ```
    ///
    /// - Parameter modifier: The modifier to apply to this view.
    /// - Returns: A view with the modifier applied.
    @MainActor public func modifier<M: ViewModifier>(_ modifier: M) -> ModifiedContent<Self, M> {
        ModifiedContent(content: self, modifier: modifier)
    }
}

// MARK: - Example Custom Modifiers

/// A modifier that adds a colored border effect around a view.
///
/// This example demonstrates how to create a custom modifier that composes multiple
/// basic modifiers to create a reusable styling pattern.
///
/// Example:
/// ```swift
/// Text("Bordered Text")
///     .modifier(BorderModifier(color: .blue, width: 2))
/// ```
public struct BorderModifier: ViewModifier, Sendable {
    /// The color of the border
    public let color: Color

    /// The width of the border in pixels
    public let width: Double

    /// Creates a border modifier.
    ///
    /// - Parameters:
    ///   - color: The color of the border.
    ///   - width: The width of the border in pixels. Defaults to 1.
    @MainActor public init(color: Color, width: Double = 1) {
        self.color = color
        self.width = width
    }

    /// Applies the border styling to the content.
    @MainActor public func body(content: Content) -> some View {
        content
            .padding(width)
            .foregroundColor(color)
    }
}

/// A modifier that applies card-like styling to a view.
///
/// This example demonstrates a more complex custom modifier that combines multiple
/// styling properties to create a cohesive visual design pattern.
///
/// Example:
/// ```swift
/// VStack {
///     Text("Card Title")
///     Text("Card content goes here")
/// }
/// .modifier(CardModifier())
/// ```
public struct CardModifier: ViewModifier, Sendable {
    /// Creates a card modifier with default styling.
    @MainActor public init() {}

    /// Applies card styling to the content.
    @MainActor public func body(content: Content) -> some View {
        content
            .padding(16)
            .frame(width: 300)
    }
}

/// A modifier that adds title styling to text content.
///
/// This example shows how to create semantic modifiers that apply consistent
/// styling for specific purposes in your UI.
///
/// Example:
/// ```swift
/// Text("Page Title")
///     .modifier(TitleModifier())
/// ```
public struct TitleModifier: ViewModifier, Sendable {
    /// Creates a title modifier.
    @MainActor public init() {}

    /// Applies title styling to the content.
    @MainActor public func body(content: Content) -> some View {
        content
            .padding(8)
            .foregroundColor(.blue)
    }
}

// MARK: - Convenience Extensions

extension View {
    /// Applies a colored border around this view.
    ///
    /// This convenience method wraps the `BorderModifier` for easier use.
    ///
    /// Example:
    /// ```swift
    /// Text("Bordered")
    ///     .border(.red, width: 2)
    /// ```
    ///
    /// - Parameters:
    ///   - color: The color of the border.
    ///   - width: The width of the border in pixels. Defaults to 1.
    /// - Returns: A view with a colored border.
    @MainActor public func border(_ color: Color, width: Double = 1) -> some View {
        self.modifier(BorderModifier(color: color, width: width))
    }

    /// Applies card styling to this view.
    ///
    /// This convenience method wraps the `CardModifier` for easier use.
    ///
    /// Example:
    /// ```swift
    /// VStack {
    ///     Text("Card Content")
    /// }
    /// .card()
    /// ```
    ///
    /// - Returns: A view styled as a card.
    @MainActor public func card() -> some View {
        self.modifier(CardModifier())
    }

    /// Applies title styling to this view.
    ///
    /// This convenience method wraps the `TitleModifier` for easier use.
    ///
    /// Example:
    /// ```swift
    /// Text("Title")
    ///     .title()
    /// ```
    ///
    /// - Returns: A view styled as a title.
    @MainActor public func title() -> some View {
        self.modifier(TitleModifier())
    }
}
