import Foundation

/// A protocol marker for basic view modifiers.
///
/// This protocol is used for simple modifiers like `PaddingModifier`, `FrameModifier`, etc.
/// that don't implement the full `ViewModifier` protocol pattern. These modifiers are
/// used internally by specific wrapper views like `_PaddingView`, `_FrameView`, etc.
public protocol BasicViewModifier: Sendable {}

/// A view that applies a modifier to another view.
///
/// `ModifiedContent` is the result of calling `.modifier()` on a view. In SwiftUI,
/// this is the mechanism for applying `ViewModifier` protocol-based modifiers.
///
/// In Raven, we implement `ModifiedContent` as a primitive, coordinator-rendered
/// node so we can apply the modifier during `_render(with:)` without relying on
/// `body` being a single static witness (which would make all modifiers no-ops).
public struct ModifiedContent<Content: View, Modifier: Sendable>: View, PrimitiveView, Sendable {
    public typealias Body = Never

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

    @MainActor public func toVNode() -> VNode {
        // `_render(with:)` does the real work; this exists for `PrimitiveView`.
        VNode.fragment(children: [])
    }
}

extension ModifiedContent: _CoordinatorRenderable {
    @MainActor public func _render(with context: any _RenderContext) -> VNode {
        // If this is a `ViewModifier`, apply it by calling `body(content:)`.
        if let anyViewModifier = modifier as? any _AnyViewModifier {
            let modified = anyViewModifier._apply(to: AnyView(content))
            return context.renderChild(modified)
        }

        // Fallback: treat unknown modifier types as identity.
        return context.renderChild(content)
    }
}
