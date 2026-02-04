import Foundation

// MARK: - Animation Modifier

/// A view wrapper that applies animation CSS to its content.
///
/// This modifier enables implicit animations on a view, automatically animating
/// any animatable property changes. There are two variants:
///
/// 1. **Universal animation**: Animates all property changes
/// 2. **Value-based animation**: Only animates when a specific value changes
///
/// ## Web Implementation
///
/// Animations are implemented using CSS transitions:
/// ```css
/// transition: all 0.3s cubic-bezier(0.42, 0, 0.58, 1);
/// ```
///
/// The modifier generates appropriate transition properties based on the
/// animation's timing curve, duration, delay, and other parameters.
///
/// ## Implicit vs Explicit Animations
///
/// - **Implicit** (`.animation()`): Automatically animates property changes
/// - **Explicit** (`withAnimation {}`): Animates only changes within the closure
///
/// Use implicit animations when a view should always animate its changes.
/// Use explicit animations when you want fine-grained control over what animates.
///
/// ## Performance
///
/// CSS transitions are GPU-accelerated for transform, opacity, and filter properties,
/// making them performant for most use cases. Layout properties (width, height, padding)
/// are less performant as they trigger reflow.
///
/// ## Example
///
/// ```swift
/// @State private var isExpanded = false
///
/// Circle()
///     .scaleEffect(isExpanded ? 1.5 : 1.0)
///     .animation(.spring())
///
/// // Value-based animation (recommended)
/// Text("Count: \(count)")
///     .opacity(count > 0 ? 1.0 : 0.5)
///     .animation(.easeInOut, value: count)
/// ```
///
/// ## See Also
///
/// - ``Animation``
/// - ``withAnimation(_:_:)``
/// - ``AnyTransition``
public struct _AnimationView<Content: View>: View, Sendable {
    let content: Content
    let animation: Animation?

    public typealias Body = Never

    @MainActor public func toVNode() -> VNode {
        var props: [String: VProperty] = [:]

        // Add animation tracking data attribute
        props["data-animated"] = .attribute(
            name: "data-animated",
            value: "true"
        )

        // Generate CSS transition if animation is non-nil
        if let animation = animation {
            // Use cssTransition() to generate the complete transition string
            let transitionValue = animation.cssTransition(property: "all")
            props["transition"] = .style(name: "transition", value: transitionValue)

            // Add animation timing details as data attributes for debugging/inspection
            props["data-animation-duration"] = .attribute(
                name: "data-animation-duration",
                value: animation.cssDuration()
            )
            props["data-animation-timing"] = .attribute(
                name: "data-animation-timing",
                value: animation.cssTransitionTiming()
            )
        }

        return VNode.element(
            "div",
            props: props,
            children: []
        )
    }
}

/// A view wrapper that applies value-based animation to its content.
///
/// This modifier only applies animations when a specific value changes,
/// providing fine-grained control over when animations occur.
///
/// ## Value-Based Animation
///
/// Unlike `.animation()` which animates all changes, `.animation(_:value:)`
/// only animates when the specified value changes. This is more efficient
/// and gives you precise control over animation timing.
///
/// ## Example
///
/// ```swift
/// @State private var score = 0
///
/// Text("Score: \(score)")
///     .font(.largeTitle)
///     .scaleEffect(score > 100 ? 1.2 : 1.0)
///     .animation(.spring(), value: score)
/// ```
///
/// In this example, the scale animation only occurs when `score` changes,
/// not when other state changes.
///
/// ## Performance
///
/// Value-based animations are more efficient than universal animations because
/// they avoid unnecessary animation triggers when unrelated state changes.
///
/// ## See Also
///
/// - ``Animation``
/// - ``_AnimationView``
/// - ``withAnimation(_:_:)``
public struct _ValueAnimationView<Content: View, V: Equatable & Sendable>: View, Sendable {
    let content: Content
    let animation: Animation?
    let value: V

    public typealias Body = Never

    @MainActor public func toVNode() -> VNode {
        var props: [String: VProperty] = [:]

        // Add animation tracking data attribute
        props["data-animated"] = .attribute(
            name: "data-animated",
            value: "true"
        )

        // Add value-based animation marker
        props["data-animation-value-based"] = .attribute(
            name: "data-animation-value-based",
            value: "true"
        )

        // Generate CSS transition if animation is non-nil
        if let animation = animation {
            // Use cssTransition() to generate the complete transition string
            let transitionValue = animation.cssTransition(property: "all")
            props["transition"] = .style(name: "transition", value: transitionValue)

            // Add animation timing details as data attributes for debugging/inspection
            props["data-animation-duration"] = .attribute(
                name: "data-animation-duration",
                value: animation.cssDuration()
            )
            props["data-animation-timing"] = .attribute(
                name: "data-animation-timing",
                value: animation.cssTransitionTiming()
            )

            // Store a hash of the value to detect changes in the DOM
            // This allows the JavaScript runtime to detect when animations should trigger
            // Use ObjectIdentifier to get a stable hash
            props["data-animation-value-hash"] = .attribute(
                name: "data-animation-value-hash",
                value: "\(value)"
            )
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
    /// Applies the given animation to all animatable values within this view.
    ///
    /// Use this modifier to animate all changes to animatable properties of the view
    /// and its children. The animation applies to properties like opacity, scale,
    /// position, color, and other visual attributes.
    ///
    /// ## When to Use
    ///
    /// Use this modifier when you want all property changes on a view to animate:
    /// - Interactive elements that should always animate (buttons, toggles)
    /// - Views that frequently change state
    /// - Simple animations without complex timing requirements
    ///
    /// For more control, use `.animation(_:value:)` to only animate when specific
    /// values change, or use `withAnimation {}` to explicitly animate specific state changes.
    ///
    /// ## Animatable Properties
    ///
    /// The following properties are animatable in Raven:
    /// - **Transform**: scale, rotation, translation, skew
    /// - **Opacity**: alpha transparency
    /// - **Color**: foreground, background, border colors
    /// - **Layout**: width, height, padding, margin
    /// - **Visual Effects**: blur, brightness, contrast, saturation
    /// - **Border**: width, radius, style
    ///
    /// ## Performance Considerations
    ///
    /// CSS transitions are GPU-accelerated for transform and opacity, making them
    /// very performant. Layout properties (width, height, padding) are less performant
    /// as they trigger browser reflow.
    ///
    /// For best performance, prefer animating transform and opacity over layout properties.
    ///
    /// ## Example
    ///
    /// ```swift
    /// @State private var isHovered = false
    ///
    /// Button("Hover Me") {
    ///     // action
    /// }
    /// .scaleEffect(isHovered ? 1.1 : 1.0)
    /// .animation(.spring())
    /// .onHover { hovering in
    ///     isHovered = hovering
    /// }
    ///
    /// // Disable animation by passing nil
    /// Circle()
    ///     .fill(color)
    ///     .animation(nil)  // No animation
    /// ```
    ///
    /// ## Combining with Transitions
    ///
    /// Animations work alongside transitions. Use `.animation()` for property changes
    /// and `.transition()` for insertion/removal animations:
    ///
    /// ```swift
    /// if isVisible {
    ///     DetailView()
    ///         .transition(.opacity)      // Fade in/out
    ///         .animation(.easeInOut)     // Animate property changes
    /// }
    /// ```
    ///
    /// ## Timing Customization
    ///
    /// Customize animation timing using Animation modifiers:
    ///
    /// ```swift
    /// Text("Delayed")
    ///     .animation(.easeIn.delay(0.5))
    ///
    /// Text("Fast")
    ///     .animation(.default.speed(2.0))
    ///
    /// Text("Repeating")
    ///     .animation(.linear.repeatForever(autoreverses: true))
    /// ```
    ///
    /// - Parameter animation: The animation to apply, or `nil` to disable animation.
    /// - Returns: A view that animates all animatable changes.
    ///
    /// ## See Also
    ///
    /// - ``animation(_:value:)``
    /// - ``withAnimation(_:_:)``
    /// - ``Animation``
    /// - ``AnyTransition``
    ///
    /// - Note: This modifier applies the animation to all descendant views until
    ///   overridden by another animation modifier. For more precise control over
    ///   animation timing, use `.animation(_:value:)` instead.
    @MainActor public func animation(_ animation: Animation?) -> _AnimationView<Self> {
        _AnimationView(content: self, animation: animation)
    }

    /// Applies the given animation to all animatable values within this view
    /// whenever the specified value changes.
    ///
    /// Use this modifier to conditionally animate changes based on a specific value.
    /// The animation only triggers when the value changes, providing precise control
    /// over animation timing and improving performance.
    ///
    /// ## Value-Based Animation
    ///
    /// This is the **recommended** way to use implicit animations. By tying animations
    /// to specific value changes, you:
    /// - Avoid unnecessary animations when unrelated state changes
    /// - Make animation triggers explicit and predictable
    /// - Improve performance by reducing animation overhead
    /// - Follow SwiftUI best practices
    ///
    /// ## When to Use
    ///
    /// Use this modifier when you want to animate in response to specific state changes:
    /// - Counter increments/decrements
    /// - Toggle state changes
    /// - Selection changes
    /// - Any state-driven animations
    ///
    /// ## Example
    ///
    /// ```swift
    /// @State private var score = 0
    /// @State private var isHighlighted = false
    ///
    /// Text("Score: \(score)")
    ///     .font(.largeTitle)
    ///     .foregroundColor(isHighlighted ? .yellow : .white)
    ///     .scaleEffect(isHighlighted ? 1.2 : 1.0)
    ///     .animation(.spring(), value: score)
    ///     // Only animates when score changes, not when isHighlighted changes
    ///
    /// // Multiple values
    /// Circle()
    ///     .fill(color)
    ///     .scaleEffect(scale)
    ///     .animation(.easeInOut, value: color)
    ///     .animation(.spring(), value: scale)
    /// ```
    ///
    /// ## Comparing to withAnimation
    ///
    /// There are two ways to create animations:
    ///
    /// **Implicit (this modifier)**:
    /// ```swift
    /// Toggle("Enabled", isOn: $isEnabled)
    ///     .animation(.easeInOut, value: isEnabled)
    /// ```
    ///
    /// **Explicit (withAnimation)**:
    /// ```swift
    /// Toggle("Enabled", isOn: $isEnabled)
    /// // In some action:
    /// withAnimation(.easeInOut) {
    ///     isEnabled.toggle()
    /// }
    /// ```
    ///
    /// Use implicit animations for view-local behavior, and explicit animations
    /// when orchestrating multiple state changes together.
    ///
    /// ## Performance
    ///
    /// Value-based animations are more efficient than universal `.animation()`
    /// because they only trigger when the specified value changes. This reduces
    /// unnecessary CSS updates and improves rendering performance.
    ///
    /// ## Multiple Value Dependencies
    ///
    /// To animate when multiple values change, chain multiple `.animation(_:value:)` calls:
    ///
    /// ```swift
    /// Rectangle()
    ///     .fill(backgroundColor)
    ///     .frame(width: width, height: height)
    ///     .animation(.easeIn, value: backgroundColor)
    ///     .animation(.spring(), value: width)
    ///     .animation(.spring(), value: height)
    /// ```
    ///
    /// Each animation modifier is independent and triggers only when its
    /// associated value changes.
    ///
    /// - Parameters:
    ///   - animation: The animation to apply when the value changes, or `nil` to
    ///     disable animation.
    ///   - value: The value to monitor for changes. When this value changes, the
    ///     animation is applied to any animatable properties that have changed.
    ///
    /// - Returns: A view that animates changes when the specified value changes.
    ///
    /// ## See Also
    ///
    /// - ``animation(_:)``
    /// - ``withAnimation(_:_:)``
    /// - ``Animation``
    /// - ``AnyTransition``
    ///
    /// - Note: The value parameter must conform to `Equatable` and `Sendable`. Changes
    ///   are detected using the `==` operator. For custom types, ensure your `Equatable`
    ///   conformance correctly identifies meaningful changes.
    @MainActor public func animation<V: Equatable & Sendable>(
        _ animation: Animation?,
        value: V
    ) -> _ValueAnimationView<Self, V> {
        _ValueAnimationView(content: self, animation: animation, value: value)
    }
}
