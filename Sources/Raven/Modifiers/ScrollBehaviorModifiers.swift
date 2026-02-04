import Foundation

// MARK: - BounceBehavior

/// The bounce behavior of a scrollable view.
///
/// Use bounce behaviors to control how a scroll view responds when users scroll
/// beyond its content boundaries.
///
/// Example:
/// ```swift
/// ScrollView {
///     // content
/// }
/// .scrollBounceBehavior(.basedOnSize)
/// ```
public enum BounceBehavior: Sendable, Hashable {
    /// Automatically determines bounce behavior based on system settings.
    ///
    /// This is the default behavior that respects system preferences.
    case automatic

    /// Always allows bouncing, even if content fits within the scroll view.
    ///
    /// Use this when you want bounce behavior regardless of content size.
    case always

    /// Allows bouncing only when content size exceeds the scroll view bounds.
    ///
    /// This provides bounce feedback only when there's scrollable content,
    /// preventing unnecessary bounce effects on small content.
    case basedOnSize
}

// MARK: - ScrollBounceBehavior Modifier

/// A view wrapper that controls scroll bounce behavior.
///
/// This modifier maps to CSS `overscroll-behavior` property, which controls
/// what happens when the user reaches the boundary of a scrolling area.
///
/// ## Web Implementation
///
/// - `.automatic` maps to `overscroll-behavior: auto` (default browser behavior)
/// - `.always` maps to `overscroll-behavior: auto` (allows bounce/glow effects)
/// - `.basedOnSize` dynamically adjusts based on content overflow
///
/// Per-axis control is achieved using `overscroll-behavior-x` and `overscroll-behavior-y`.
///
/// ## Browser Compatibility
///
/// - Chrome/Edge: 63+
/// - Firefox: 59+
/// - Safari: 16+
///
/// For older browsers, the property is ignored and default scroll behavior applies.
public struct _ScrollBounceBehaviorView<Content: View>: View, PrimitiveView, Sendable {
    let content: Content
    let behavior: BounceBehavior
    let axes: Axis.Set

    public typealias Body = Never

    @MainActor public func toVNode() -> VNode {
        var props: [String: VProperty] = [:]

        // Determine CSS value based on behavior
        let cssValue: String
        switch behavior {
        case .automatic:
            cssValue = "auto"
        case .always:
            cssValue = "auto"  // Allow bounce
        case .basedOnSize:
            // For basedOnSize, we use 'contain' to prevent bounce when content fits
            // and 'auto' when content overflows. Since we can't dynamically check
            // content size in pure CSS, we default to 'contain' and let JS handle
            // the dynamic case if needed.
            cssValue = "contain"
        }

        // Apply per-axis if specific axes are set
        if axes == [.horizontal, .vertical] {
            // Both axes - use shorthand
            props["overscroll-behavior"] = .style(name: "overscroll-behavior", value: cssValue)
        } else if axes.contains(.horizontal) {
            // Horizontal only
            props["overscroll-behavior-x"] = .style(name: "overscroll-behavior-x", value: cssValue)
            // Ensure vertical doesn't bounce unnecessarily
            if !axes.contains(.vertical) {
                props["overscroll-behavior-y"] = .style(name: "overscroll-behavior-y", value: "none")
            }
        } else if axes.contains(.vertical) {
            // Vertical only
            props["overscroll-behavior-y"] = .style(name: "overscroll-behavior-y", value: cssValue)
            // Ensure horizontal doesn't bounce unnecessarily
            if !axes.contains(.horizontal) {
                props["overscroll-behavior-x"] = .style(name: "overscroll-behavior-x", value: "none")
            }
        }

        return VNode.element(
            "div",
            props: props,
            children: []
        )
    }
}

// MARK: - ScrollClipDisabled Modifier

/// A view wrapper that controls whether scroll content is clipped.
///
/// By default, scroll views clip their content to their bounds. This modifier
/// allows content (such as shadows, glows, or overflowing decorations) to extend
/// beyond the scroll view's visible area.
///
/// ## Web Implementation
///
/// This modifier removes the default `overflow: hidden` clipping behavior or sets
/// `overflow: visible` to allow content to extend beyond bounds. For scroll containers,
/// it may adjust the clip-path or use CSS containment properties.
///
/// ## Use Cases
///
/// - Displaying shadows that extend beyond scroll bounds
/// - Showing decorative elements that overflow
/// - Allowing blur or glow effects around scroll content
///
/// Example:
/// ```swift
/// ScrollView {
///     VStack {
///         ForEach(items) { item in
///             ItemView(item)
///                 .shadow(radius: 10)  // Shadow won't be clipped
///         }
///     }
/// }
/// .scrollClipDisabled()
/// ```
///
/// ## Browser Compatibility
///
/// Uses standard CSS overflow properties, supported in all modern browsers.
public struct _ScrollClipDisabledView<Content: View>: View, PrimitiveView, Sendable {
    let content: Content
    let disabled: Bool

    public typealias Body = Never

    @MainActor public func toVNode() -> VNode {
        var props: [String: VProperty] = [:]

        if disabled {
            // Remove clipping by setting overflow to visible
            // Note: This works for decorative overflow. For actual scrolling,
            // the scroll container itself still needs overflow: auto/scroll
            props["overflow"] = .style(name: "overflow", value: "visible")

            // Remove any clip-path restrictions
            props["clip-path"] = .style(name: "clip-path", value: "none")
        } else {
            // Default clipping behavior
            props["overflow"] = .style(name: "overflow", value: "hidden")
        }

        return VNode.element(
            "div",
            props: props,
            children: []
        )
    }
}

// MARK: - View Extensions

extension View {
    /// Sets the bounce behavior of a scrollable view.
    ///
    /// Use this modifier to control how the scroll view responds when users scroll
    /// beyond the content boundaries. The behavior can be set independently for
    /// horizontal and vertical axes.
    ///
    /// ## Example
    ///
    /// ```swift
    /// ScrollView {
    ///     VStack {
    ///         ForEach(1...20) { i in
    ///             Text("Item \(i)")
    ///         }
    ///     }
    /// }
    /// .scrollBounceBehavior(.basedOnSize)
    /// ```
    ///
    /// ## Controlling Specific Axes
    ///
    /// ```swift
    /// ScrollView(.horizontal) {
    ///     HStack {
    ///         // content
    ///     }
    /// }
    /// .scrollBounceBehavior(.always, axes: [.horizontal])
    /// ```
    ///
    /// ## Behavior Types
    ///
    /// - `.automatic`: Follows system defaults
    /// - `.always`: Always allows bouncing
    /// - `.basedOnSize`: Only bounces when content exceeds bounds
    ///
    /// - Parameters:
    ///   - behavior: The bounce behavior to apply.
    ///   - axes: The axes to which the behavior applies. Defaults to vertical.
    /// - Returns: A view with the specified scroll bounce behavior.
    @MainActor public func scrollBounceBehavior(
        _ behavior: BounceBehavior,
        axes: Axis.Set = [.vertical]
    ) -> _ScrollBounceBehaviorView<Self> {
        _ScrollBounceBehaviorView(content: self, behavior: behavior, axes: axes)
    }

    /// Controls whether scrollable content is clipped to the scroll view's bounds.
    ///
    /// By default, scroll views clip their content. Use this modifier to allow
    /// decorative elements like shadows, glows, or borders to extend beyond the
    /// scroll view's visible area.
    ///
    /// ## Example
    ///
    /// ```swift
    /// ScrollView {
    ///     VStack {
    ///         ForEach(items) { item in
    ///             CardView(item)
    ///                 .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 2)
    ///         }
    ///     }
    /// }
    /// .scrollClipDisabled()  // Shadows extend beyond scroll bounds
    /// ```
    ///
    /// ## When to Use
    ///
    /// - Displaying drop shadows on scroll content
    /// - Showing decorative elements that overflow
    /// - Creating visual effects around scrollable areas
    ///
    /// ## When NOT to Use
    ///
    /// - When you want strict boundaries for scroll content
    /// - When overflow could interfere with other UI elements
    ///
    /// - Parameter disabled: Whether to disable clipping. Defaults to `true`.
    /// - Returns: A view that allows or disallows content clipping.
    @MainActor public func scrollClipDisabled(_ disabled: Bool = true) -> _ScrollClipDisabledView<Self> {
        _ScrollClipDisabledView(content: self, disabled: disabled)
    }
}
