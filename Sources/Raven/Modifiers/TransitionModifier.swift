import Foundation

// MARK: - Transition Modifier

/// A modifier that associates a transition with a view.
///
/// The transition modifier specifies how a view should animate when it
/// appears or disappears from the view hierarchy. This is typically used
/// with conditional view rendering.
///
/// Note: This is not used directly. The `.transition()` modifier creates
/// a `_TransitionView` wrapper instead of using this modifier type.

/// Internal view that applies transition metadata to content.
///
/// This view wraps the content and attaches transition information that
/// will be used by the rendering system to generate appropriate CSS
/// animations when the view is inserted or removed.
public struct _TransitionView<Content: View>: View, PrimitiveView, Sendable {
    let content: Content
    let transition: AnyTransition

    public typealias Body = Never

    @MainActor public func toVNode() -> VNode {
        var props: [String: VProperty] = [:]

        // Add data attributes to track transition state
        props["data-transition"] = .attribute(
            name: "data-transition",
            value: "true"
        )

        // Add CSS animation properties
        let insertionAnim = transition.cssInsertionAnimation()
        let removalAnim = transition.cssRemovalAnimation()

        if insertionAnim != "none" {
            props["data-transition-in"] = .attribute(
                name: "data-transition-in",
                value: insertionAnim
            )
        }

        if removalAnim != "none" {
            props["data-transition-out"] = .attribute(
                name: "data-transition-out",
                value: removalAnim
            )
        }

        // Add transform-origin if needed (for scale transitions)
        if let transformOrigin = transition.cssTransformOrigin() {
            props["transform-origin"] = .style(
                name: "transform-origin",
                value: transformOrigin
            )
        }

        // Add inline style for animation properties
        var styleValue = "animation-duration: 0.3s; animation-timing-function: ease-in-out;"

        // Include transform-origin in inline styles for scale transitions
        if let transformOrigin = transition.cssTransformOrigin() {
            styleValue += " transform-origin: \(transformOrigin);"
        }

        props["style"] = .attribute(name: "style", value: styleValue)

        return VNode.element(
            "div",
            props: props,
            children: []
        )
    }
}

// MARK: - View Extension

extension View {
    /// Associates a transition with this view.
    ///
    /// A transition specifies how the view animates when it appears or
    /// disappears from the view hierarchy. Transitions are most commonly
    /// used with conditional view rendering.
    ///
    /// ## Basic Usage
    ///
    /// ```swift
    /// if showDetails {
    ///     DetailView()
    ///         .transition(.opacity)
    /// }
    /// ```
    ///
    /// ## Available Transitions
    ///
    /// - `.identity` - No animation
    /// - `.opacity` - Fade in and out
    /// - `.scale()` - Scale from/to specified size
    /// - `.slide` - Slide from bottom edge
    /// - `.move(edge:)` - Slide from specified edge
    /// - `.offset(x:y:)` - Translate by specified amounts
    ///
    /// ## Combining Transitions
    ///
    /// Combine multiple transitions for more complex effects:
    ///
    /// ```swift
    /// if showDialog {
    ///     DialogView()
    ///         .transition(.opacity.combined(with: .scale))
    /// }
    /// ```
    ///
    /// ## Asymmetric Transitions
    ///
    /// Use different transitions for insertion and removal:
    ///
    /// ```swift
    /// if showNotification {
    ///     NotificationView()
    ///         .transition(
    ///             .asymmetric(
    ///                 insertion: .move(edge: .trailing),
    ///                 removal: .opacity
    ///             )
    ///         )
    /// }
    /// ```
    ///
    /// ## How It Works
    ///
    /// When a view with a transition is added to the view hierarchy,
    /// the rendering system:
    ///
    /// 1. Injects the necessary CSS keyframe animations
    /// 2. Applies the insertion animation to the view
    /// 3. When the view is removed, applies the removal animation
    /// 4. Removes the view from the DOM after the animation completes
    ///
    /// The default animation duration is 0.3 seconds with an ease-in-out
    /// timing function. To customize the animation timing, use the
    /// `.animation()` modifier in combination with `.transition()`:
    ///
    /// ```swift
    /// if showPanel {
    ///     PanelView()
    ///         .transition(.move(edge: .leading))
    ///         .animation(.easeInOut(duration: 0.5), value: showPanel)
    /// }
    /// ```
    ///
    /// - Parameter t: The transition to apply to this view.
    /// - Returns: A view with the transition applied.
    ///
    /// ## See Also
    ///
    /// - ``AnyTransition``
    /// - ``Animation``
    /// - ``withAnimation(_:_:)``
    ///
    /// - Note: Transitions only affect views that are conditionally
    ///   shown or hidden. Views that remain in the hierarchy but change
    ///   position or size should use the `.animation()` modifier instead.
    @MainActor public func transition(_ t: AnyTransition) -> _TransitionView<Self> {
        _TransitionView(content: self, transition: t)
    }
}
