import Foundation

/// A protocol marker for basic view modifiers.
///
/// This protocol is used for simple modifiers like `PaddingModifier`, `FrameModifier`, etc.
/// that don't implement the full `ViewModifier` protocol pattern. These modifiers are
/// used internally by specific wrapper views like `_PaddingView`, `_FrameView`, etc.
///
/// For custom modifiers with composable bodies, use the `ViewModifier` protocol instead,
/// which is defined in `ViewModifier.swift`.
///
/// Example of a basic modifier:
/// ```swift
/// public struct PaddingModifier: BasicViewModifier {
///     let edges: EdgeInsets
/// }
/// ```
public protocol BasicViewModifier: Sendable {
}

/// A view that wraps another view with a basic modifier applied.
///
/// `ModifiedContent` is a generic container that stores a view and its modifier.
/// It can work with both `BasicViewModifier` types (for internal use) and
/// `ViewModifier` types (for custom user-defined modifiers).
///
/// ## Usage with BasicViewModifier
///
/// Basic modifiers are used internally and return specific wrapper views:
/// ```swift
/// Text("Hello")
///     .padding()  // Returns _PaddingView<Text>
/// ```
///
/// ## Usage with ViewModifier
///
/// Custom modifiers use the full ViewModifier protocol:
/// ```swift
/// Text("Hello")
///     .modifier(MyCustomModifier())  // Returns ModifiedContent<Text, MyCustomModifier>
/// ```
///
/// The implementation of `body` for ViewModifier is provided as an extension
/// in `ViewModifier.swift`.
public struct ModifiedContent<Content: View, Modifier: Sendable>: View, Sendable {
    /// The original content being modified
    public let content: Content

    /// The modifier to apply
    public let modifier: Modifier

    /// Creates a modified content view.
    ///
    /// - Parameters:
    ///   - content: The view to modify.
    ///   - modifier: The modifier to apply.
    @MainActor public init(content: Content, modifier: Modifier) {
        self.content = content
        self.modifier = modifier
    }

    /// Default body type for basic modifiers that don't use the ViewModifier protocol.
    ///
    /// This is overridden by the extension in ViewModifier.swift for modifiers that
    /// conform to the ViewModifier protocol.
    public typealias Body = Never
}
