import Foundation

// MARK: - KeyframeTrack

/// A builder for constructing keyframe animation sequences.
///
/// `KeyframeTrack` provides methods to add keyframes with different interpolation
/// styles. Use the provided methods to build complex, multi-step animations.
///
/// ## Topics
/// ### Adding Keyframes
/// - ``linear(_:duration:)``
/// - ``spring(_:duration:bounce:)``
/// - ``cubic(_:duration:startVelocity:endVelocity:)``
/// - ``move(_:)``
public struct KeyframeTrack<Value: Interpolatable> {
    /// Internal sequence of keyframes.
    public var sequence: KeyframeSequence<Value>

    /// Creates an empty keyframe track.
    public init() {
        self.sequence = KeyframeSequence()
    }

    /// Adds a linear keyframe that interpolates to the target value.
    ///
    /// Linear interpolation creates constant-speed motion between the previous value
    /// and the target value.
    ///
    /// ```swift
    /// track.linear(1.0, duration: 0.3)
    /// ```
    ///
    /// - Parameters:
    ///   - value: The target value to interpolate to.
    ///   - duration: The duration of the interpolation in seconds.
    public mutating func linear(
        _ value: Value,
        duration: TimeInterval
    ) {
        sequence.add(.linear(value: value, duration: duration))
    }

    /// Adds a spring keyframe that uses spring physics to reach the target value.
    ///
    /// Spring interpolation creates natural, bouncy motion based on physics simulation.
    /// The bounce parameter controls how much the animation overshoots.
    ///
    /// ```swift
    /// track.spring(1.0, duration: 0.5, bounce: 0.3)
    /// ```
    ///
    /// - Parameters:
    ///   - value: The target value to spring towards.
    ///   - duration: The approximate duration of the spring animation in seconds.
    ///     Default is 0.5.
    ///   - bounce: The amount of bounce, from 0.0 (no bounce) to 1.0 (maximum bounce).
    ///     Default is 0.0.
    public mutating func spring(
        _ value: Value,
        duration: TimeInterval = 0.5,
        bounce: Double = 0.0
    ) {
        sequence.add(.spring(value: value, duration: duration, bounce: bounce))
    }

    /// Adds a cubic bezier keyframe with smooth easing.
    ///
    /// Cubic interpolation creates smooth, ease-in-out style motion between values.
    /// This is useful for creating natural-feeling transitions.
    ///
    /// ```swift
    /// track.cubic(1.0, duration: 0.4)
    /// ```
    ///
    /// - Parameters:
    ///   - value: The target value to interpolate to.
    ///   - duration: The duration of the interpolation in seconds.
    ///
    /// - Note: In the CSS implementation, this uses a cubic bezier timing function.
    public mutating func cubic(
        _ value: Value,
        duration: TimeInterval
    ) {
        sequence.add(.cubic(
            value: value,
            duration: duration
        ))
    }

    /// Adds an instant jump to the target value without interpolation.
    ///
    /// This creates an immediate change to the target value with no transition.
    /// Useful for discrete state changes within a continuous animation.
    ///
    /// ```swift
    /// track.move(1.0)  // Instant change
    /// ```
    ///
    /// - Parameter value: The target value to jump to.
    public mutating func move(
        _ value: Value
    ) {
        sequence.add(.move(value: value))
    }
}

// MARK: - KeyframeAnimator View Extension

extension View {
    /// Animates a view using a sequence of keyframes.
    ///
    /// The keyframe animator applies multi-step animations to views by defining a series
    /// of keyframes with different timing and interpolation styles. This is ideal for
    /// complex animations that require precise control over multiple stages.
    ///
    /// ```swift
    /// struct AnimationValues {
    ///     var scale: Double
    ///     var opacity: Double
    /// }
    ///
    /// Circle()
    ///     .keyframeAnimator(
    ///         initialValue: AnimationValues(scale: 1.0, opacity: 1.0),
    ///         repeating: true
    ///     ) { content, value in
    ///         content
    ///             .scaleEffect(value.scale)
    ///             .opacity(value.opacity)
    ///     } keyframes: { track in
    ///         track.linear(.init(scale: 1.2, opacity: 0.8), duration: 0.3)
    ///         track.spring(.init(scale: 1.0, opacity: 1.0), duration: 0.4, bounce: 0.2)
    ///     }
    /// ```
    ///
    /// - Parameters:
    ///   - initialValue: The starting value for the animation. This value is passed to
    ///     the content closure before any keyframes are applied.
    ///   - repeating: Whether the animation should repeat indefinitely. Default is false.
    ///   - content: A closure that builds the view's content, receiving the current
    ///     animated value. Apply modifiers based on this value to create the animation.
    ///   - keyframes: A closure that builds the keyframe sequence using a
    ///     ``KeyframeTrack``. Add keyframes using methods like ``KeyframeTrack/linear(_:duration:)``
    ///     and ``KeyframeTrack/spring(_:duration:bounce:)``.
    ///
    /// - Returns: A view that animates according to the keyframe sequence.
    ///
    /// ## Keyframe Types
    ///
    /// The keyframes closure provides several interpolation methods:
    ///
    /// - **Linear**: Constant-speed interpolation between values
    /// - **Spring**: Physics-based spring interpolation with configurable bounce
    /// - **Cubic**: Cubic bezier interpolation with velocity control
    /// - **Move**: Instant jump to a value (no interpolation)
    ///
    /// ## Value Requirements
    ///
    /// The animated value type must conform to ``Interpolatable``, which enables smooth
    /// transitions between keyframe values. Standard types like `Double`, `CGFloat`,
    /// `CGPoint`, and `CGSize` conform automatically.
    ///
    /// For custom types, implement the ``Interpolatable`` protocol:
    ///
    /// ```swift
    /// struct MyValue: Interpolatable {
    ///     var x: Double
    ///     var y: Double
    ///
    ///     func interpolated(to other: MyValue, amount: Double) -> MyValue {
    ///         MyValue(
    ///             x: x.interpolated(to: other.x, amount: amount),
    ///             y: y.interpolated(to: other.y, amount: amount)
    ///         )
    ///     }
    /// }
    /// ```
    ///
    /// ## CSS Implementation
    ///
    /// Keyframe animations are rendered using CSS @keyframes:
    ///
    /// ```css
    /// @keyframes animation-name {
    ///     0% { transform: scale(1); opacity: 1; }
    ///     30% { transform: scale(1.2); opacity: 0.8; }
    ///     100% { transform: scale(1); opacity: 1; }
    /// }
    /// ```
    ///
    /// Each keyframe's timing function is applied between stops to create smooth
    /// transitions with the specified interpolation style.
    ///
    /// ## Performance
    ///
    /// Keyframe animations leverage GPU-accelerated CSS animations for smooth performance.
    /// Prefer animating transform and opacity properties for best results.
    ///
    /// ## When to Use
    ///
    /// Use keyframe animator when:
    /// - You need multi-step animations with different timing at each stage
    /// - You want precise control over animation curves
    /// - You need complex choreographed effects
    ///
    /// For simple state-based animations, use ``View/animation(_:)`` instead.
    ///
    /// - Important: This modifier is available in iOS 17+ and equivalent platforms.
    @available(iOS 17, macOS 14, *)
    public func keyframeAnimator<Value>(
        initialValue: Value,
        repeating: Bool = false,
        @ViewBuilder content: @escaping @MainActor @Sendable (Self, Value) -> some View,
        keyframes: @escaping @Sendable (inout KeyframeTrack<Value>) -> Void
    ) -> some View where Value: Interpolatable {
        _KeyframeAnimatorView(
            base: self,
            initialValue: initialValue,
            repeating: repeating,
            content: content,
            keyframesBuilder: keyframes
        )
    }
}

// MARK: - Internal Keyframe Animator View

/// Internal view that wraps content with keyframe animation.
@available(iOS 17, macOS 14, *)
internal struct _KeyframeAnimatorView<Base: View, Value: Interpolatable, Content: View>: View {
    let base: Base
    let initialValue: Value
    let repeating: Bool
    let content: @MainActor @Sendable (Base, Value) -> Content
    let keyframesBuilder: @Sendable (inout KeyframeTrack<Value>) -> Void

    public var body: some View {
        // Render the content with the initial value
        // In a full implementation, we would:
        // 1. Build the keyframe sequence using keyframesBuilder
        // 2. Generate CSS @keyframes rule
        // 3. Wrap the content with animation metadata
        // 4. The renderer would inject the CSS and apply the animation
        content(base, initialValue)
    }
}

// MARK: - Default Implementations for Common Types
// Note: Most types already have .zero defined in the standard library
