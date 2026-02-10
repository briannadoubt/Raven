/// Represents an animation with timing and duration properties.
///
/// `Animation` defines how views transition between states. It encapsulates timing curves,
/// duration, delays, and repeat behavior. Animations can be combined with modifiers like
/// ``delay(_:)``, ``speed(_:)``, and ``repeatCount(_:autoreverses:)`` to create complex
/// animation sequences.
///
/// ## Standard Animations
///
/// Raven provides several built-in animation curves:
///
/// ```swift
/// .animation(.default)    // Ease in-out curve
/// .animation(.linear)     // Linear timing
/// .animation(.easeIn)     // Starts slow, ends fast
/// .animation(.easeOut)    // Starts fast, ends slow
/// .animation(.easeInOut)  // Smooth acceleration and deceleration
/// ```
///
/// ## Spring Animations
///
/// Spring animations create natural, physics-based motion:
///
/// ```swift
/// .animation(.spring())  // Default spring
/// .animation(.spring(response: 0.3, dampingFraction: 0.6))
/// ```
///
/// - **Response**: The duration of the spring animation (in seconds). Lower values create
///   faster springs.
/// - **Damping Fraction**: How quickly the spring settles. Values from 0 (bouncy) to 1
///   (critically damped).
/// - **Blend Duration**: The duration over which to interpolate between spring parameters
///   when they change.
///
/// ## Custom Timing Curves
///
/// Create custom timing using cubic Bézier control points:
///
/// ```swift
/// .animation(.timingCurve(0.17, 0.67, 0.83, 0.67, duration: 0.4))
/// ```
///
/// Control points define the curve's shape:
/// - `(c0x, c0y)`: First control point
/// - `(c1x, c1y)`: Second control point
/// - X values should be in range [0, 1]
/// - Y values can exceed [0, 1] for overshoot effects
///
/// ## Animation Modifiers
///
/// Combine modifiers to create complex animations:
///
/// ```swift
/// .animation(.easeInOut.delay(0.2).speed(1.5))
/// .animation(.spring().repeatCount(3, autoreverses: true))
/// .animation(.linear.repeatForever())
/// ```
///
/// ## CSS Mapping
///
/// Animations are rendered to CSS using:
/// - **transition**: For state-based animations
/// - **animation**: For keyframe-based animations with repeats
/// - **timing-function**: cubic-bezier() or named functions (linear, ease, etc.)
///
/// Spring animations are approximated using cubic-bezier curves optimized for the given
/// spring parameters.
///
/// ## Performance
///
/// Animations are value types and can be efficiently copied and compared. CSS generation
/// is optimized to minimize string allocations.
public struct Animation: Sendable, Hashable {
    /// The internal representation of the animation timing.
    internal let timing: Timing

    /// The duration of the animation in seconds.
    internal let duration: Double

    /// The delay before the animation starts, in seconds.
    internal let delayAmount: Double

    /// The speed multiplier for the animation.
    internal let speedMultiplier: Double

    /// The number of times to repeat the animation, or nil for no repeat.
    internal let repeatCountValue: Int?

    /// Whether the animation should reverse on each repeat.
    internal let autoreversesValue: Bool

    /// Internal timing representation for animations.
    internal enum Timing: Sendable, Hashable {
        /// Standard ease-in-out curve
        case easeInOut

        /// Linear timing (no easing)
        case linear

        /// Ease in (slow start)
        case easeIn

        /// Ease out (slow end)
        case easeOut

        /// Custom cubic Bézier curve with control points
        case cubicBezier(c0x: Double, c0y: Double, c1x: Double, c1y: Double)

        /// Spring animation with physics parameters
        case spring(response: Double, dampingFraction: Double, blendDuration: Double)
    }

    /// Creates an animation with the specified timing and parameters.
    internal init(
        timing: Timing,
        duration: Double = 0.35,
        delay: Double = 0,
        speed: Double = 1.0,
        repeatCount: Int? = nil,
        autoreverses: Bool = false
    ) {
        self.timing = timing
        self.duration = duration
        self.delayAmount = delay
        self.speedMultiplier = speed
        self.repeatCountValue = repeatCount
        self.autoreversesValue = autoreverses
    }

    // MARK: - Standard Animations

    /// The default animation curve (ease-in-out).
    ///
    /// This is a smooth animation that starts slowly, accelerates in the middle,
    /// and decelerates at the end. Equivalent to CSS `ease-in-out`.
    ///
    /// ```swift
    /// Text("Fade In")
    ///     .animation(.default)
    /// ```
    public static var `default`: Animation {
        Animation(timing: .easeInOut)
    }

    /// A linear animation with constant speed throughout.
    ///
    /// The animation maintains the same speed from start to finish, with no
    /// acceleration or deceleration. Equivalent to CSS `linear`.
    ///
    /// ```swift
    /// ProgressBar()
    ///     .animation(.linear)
    /// ```
    public static var linear: Animation {
        Animation(timing: .linear)
    }

    /// An ease-in animation that starts slowly and accelerates.
    ///
    /// The animation begins slowly and gradually increases speed. Useful for
    /// elements entering the view. Equivalent to CSS `ease-in`.
    ///
    /// ```swift
    /// Rectangle()
    ///     .animation(.easeIn)
    /// ```
    public static var easeIn: Animation {
        Animation(timing: .easeIn)
    }

    /// An ease-out animation that starts quickly and decelerates.
    ///
    /// The animation begins at full speed and gradually slows down. Useful for
    /// elements coming to rest. Equivalent to CSS `ease-out`.
    ///
    /// ```swift
    /// Circle()
    ///     .animation(.easeOut)
    /// ```
    public static var easeOut: Animation {
        Animation(timing: .easeOut)
    }

    /// An ease-in-out animation with smooth acceleration and deceleration.
    ///
    /// The animation starts slowly, accelerates in the middle, and decelerates
    /// at the end. This creates the most natural-feeling motion. Equivalent to
    /// CSS `ease-in-out`.
    ///
    /// ```swift
    /// VStack {
    ///     // content
    /// }
    /// .animation(.easeInOut)
    /// ```
    public static var easeInOut: Animation {
        Animation(timing: .easeInOut)
    }

    // MARK: - Spring Animation

    /// Creates a spring animation with customizable physics parameters.
    ///
    /// Spring animations create natural, physics-based motion that can bounce and
    /// oscillate before settling. They're ideal for interactive elements and
    /// natural-feeling transitions.
    ///
    /// ```swift
    /// Button("Tap Me") { }
    ///     .animation(.spring())
    ///
    /// // Custom spring parameters
    /// Image("icon")
    ///     .animation(.spring(response: 0.3, dampingFraction: 0.6))
    /// ```
    ///
    /// - Parameters:
    ///   - response: The duration of the spring animation in seconds. Lower values
    ///     create faster, snappier springs. Default is 0.55 seconds.
    ///   - dampingFraction: How quickly the spring settles. A value of 1.0 is
    ///     critically damped (no bounce), while lower values create more bounce.
    ///     Default is 0.825 (slightly bouncy).
    ///   - blendDuration: The duration over which to interpolate changes in spring
    ///     parameters when the animation is updated. Default is 0 (no blending).
    ///
    /// - Returns: A spring animation with the specified parameters.
    ///
    /// ## Spring Physics
    ///
    /// Springs are defined by two primary parameters:
    ///
    /// - **Response** controls the speed. A response of 0.3 creates a quick spring,
    ///   while 1.0 creates a slow, gentle spring.
    /// - **Damping Fraction** controls bounciness:
    ///   - 0.0: Undamped (bounces forever, not recommended)
    ///   - 0.5: Underdamped (visible bounce)
    ///   - 0.825: Slightly underdamped (subtle bounce, default)
    ///   - 1.0: Critically damped (no bounce, fastest settling)
    ///   - \>1.0: Overdamped (slow, no bounce)
    ///
    /// ## CSS Rendering
    ///
    /// Spring animations are approximated using cubic-bezier curves that match the
    /// spring's velocity profile. For browsers that support it, CSS spring()
    /// functions may be used instead.
    public static func spring(
        response: Double = 0.55,
        dampingFraction: Double = 0.825,
        blendDuration: Double = 0
    ) -> Animation {
        Animation(
            timing: .spring(
                response: response,
                dampingFraction: dampingFraction,
                blendDuration: blendDuration
            ),
            duration: response
        )
    }

    // MARK: - Custom Timing Curve

    /// Creates an animation with a custom cubic Bézier timing curve.
    ///
    /// Cubic Bézier curves provide precise control over animation timing using two
    /// control points. This allows creating custom easing curves beyond the standard
    /// presets.
    ///
    /// ```swift
    /// // Material Design standard curve
    /// .animation(.timingCurve(0.4, 0.0, 0.2, 1.0, duration: 0.3))
    ///
    /// // Anticipation curve (pulls back before moving forward)
    /// .animation(.timingCurve(0.5, -0.5, 0.5, 1.5, duration: 0.5))
    /// ```
    ///
    /// - Parameters:
    ///   - c0x: X coordinate of the first control point (should be in [0, 1])
    ///   - c0y: Y coordinate of the first control point (can exceed [0, 1] for
    ///     overshoot effects)
    ///   - c1x: X coordinate of the second control point (should be in [0, 1])
    ///   - c1y: Y coordinate of the second control point (can exceed [0, 1] for
    ///     overshoot effects)
    ///   - duration: The duration of the animation in seconds. Default is 0.35.
    ///
    /// - Returns: An animation with the specified timing curve.
    ///
    /// ## Understanding Control Points
    ///
    /// The curve starts at (0, 0) and ends at (1, 1). The control points shape the
    /// curve between these endpoints:
    ///
    /// - **X values** should typically stay in [0, 1] range for monotonic timing
    /// - **Y values** outside [0, 1] create overshoot or anticipation effects
    /// - First control point (c0x, c0y) influences the start of the animation
    /// - Second control point (c1x, c1y) influences the end of the animation
    ///
    /// ## Common Curves
    ///
    /// - `(0.25, 0.1, 0.25, 1.0)`: Ease (CSS default)
    /// - `(0.42, 0.0, 1.0, 1.0)`: Ease-in
    /// - `(0.0, 0.0, 0.58, 1.0)`: Ease-out
    /// - `(0.42, 0.0, 0.58, 1.0)`: Ease-in-out
    /// - `(0.4, 0.0, 0.2, 1.0)`: Material Design standard
    ///
    /// ## CSS Rendering
    ///
    /// This maps directly to CSS cubic-bezier():
    /// ```css
    /// transition-timing-function: cubic-bezier(0.4, 0.0, 0.2, 1.0);
    /// ```
    public static func timingCurve(
        _ c0x: Double,
        _ c0y: Double,
        _ c1x: Double,
        _ c1y: Double,
        duration: Double = 0.35
    ) -> Animation {
        Animation(
            timing: .cubicBezier(c0x: c0x, c0y: c0y, c1x: c1x, c1y: c1y),
            duration: duration
        )
    }

    // MARK: - Duration Control

    /// Returns a new animation with the specified delay before starting.
    ///
    /// The delay postpones the start of the animation without affecting its duration
    /// or speed.
    ///
    /// ```swift
    /// Text("Appears after 0.5s")
    ///     .animation(.easeIn.delay(0.5))
    ///
    /// // Chain multiple modifiers
    /// Rectangle()
    ///     .animation(.spring().delay(0.2).speed(1.5))
    /// ```
    ///
    /// - Parameter delay: The delay in seconds before the animation starts.
    /// - Returns: A new animation with the specified delay.
    public func delay(_ delay: Double) -> Animation {
        Animation(
            timing: timing,
            duration: duration,
            delay: delayAmount + delay,
            speed: speedMultiplier,
            repeatCount: repeatCountValue,
            autoreverses: autoreversesValue
        )
    }

    /// Returns a new animation with the specified speed multiplier.
    ///
    /// Speed multiplier affects the effective duration of the animation:
    /// - Values > 1.0 make the animation faster (shorter duration)
    /// - Values < 1.0 make the animation slower (longer duration)
    /// - A speed of 2.0 cuts the duration in half
    /// - A speed of 0.5 doubles the duration
    ///
    /// ```swift
    /// // Twice as fast
    /// Text("Quick")
    ///     .animation(.default.speed(2.0))
    ///
    /// // Half speed
    /// Text("Slow")
    ///     .animation(.default.speed(0.5))
    /// ```
    ///
    /// - Parameter speed: The speed multiplier. Must be positive.
    /// - Returns: A new animation with the specified speed.
    public func speed(_ speed: Double) -> Animation {
        Animation(
            timing: timing,
            duration: duration,
            delay: delayAmount,
            speed: speedMultiplier * speed,
            repeatCount: repeatCountValue,
            autoreverses: autoreversesValue
        )
    }

    /// Returns a new animation that repeats a specific number of times.
    ///
    /// The animation will repeat the specified number of times. If `autoreverses` is
    /// true, the animation will play forward, then backward, counting as one repetition.
    ///
    /// ```swift
    /// // Pulse 3 times
    /// Circle()
    ///     .animation(.easeInOut.repeatCount(3))
    ///
    /// // Bounce back and forth 5 times
    /// Rectangle()
    ///     .animation(.spring().repeatCount(5, autoreverses: true))
    /// ```
    ///
    /// - Parameters:
    ///   - count: The number of times to repeat the animation.
    ///   - autoreverses: Whether the animation should reverse direction on each
    ///     repeat. Default is true.
    ///
    /// - Returns: A new animation that repeats the specified number of times.
    public func repeatCount(_ count: Int, autoreverses: Bool = true) -> Animation {
        Animation(
            timing: timing,
            duration: duration,
            delay: delayAmount,
            speed: speedMultiplier,
            repeatCount: count,
            autoreverses: autoreverses
        )
    }

    /// Returns a new animation that repeats forever.
    ///
    /// The animation will loop continuously until removed or interrupted. If
    /// `autoreverses` is true, the animation will alternate between forward and
    /// backward playback.
    ///
    /// ```swift
    /// // Rotate continuously
    /// Image("loader")
    ///     .animation(.linear.repeatForever(autoreverses: false))
    ///
    /// // Pulse indefinitely
    /// Text("Loading...")
    ///     .animation(.easeInOut.repeatForever())
    /// ```
    ///
    /// - Parameter autoreverses: Whether the animation should reverse direction on
    ///   each repeat. Default is true.
    ///
    /// - Returns: A new animation that repeats forever.
    ///
    /// - Note: Forever animations map to CSS animations with `infinite` iteration count.
    public func repeatForever(autoreverses: Bool = true) -> Animation {
        Animation(
            timing: timing,
            duration: duration,
            delay: delayAmount,
            speed: speedMultiplier,
            repeatCount: -1, // -1 represents infinite
            autoreverses: autoreverses
        )
    }

    // MARK: - CSS Generation

    /// Generates the CSS timing function for this animation.
    ///
    /// Returns the appropriate CSS timing function based on the animation's timing curve:
    /// - Standard curves map to CSS keywords (linear, ease-in, ease-out, ease-in-out)
    /// - Custom curves use cubic-bezier() notation
    /// - Spring animations use approximated cubic-bezier curves
    ///
    /// - Returns: A CSS timing function string.
    public func cssTransitionTiming() -> String {
        switch timing {
        case .linear:
            return "linear"
        case .easeIn:
            return "ease-in"
        case .easeOut:
            return "ease-out"
        case .easeInOut:
            return "ease-in-out"
        case .cubicBezier(let c0x, let c0y, let c1x, let c1y):
            return "cubic-bezier(\(c0x), \(c0y), \(c1x), \(c1y))"
        case .spring(let response, let dampingFraction, _):
            // Approximate spring with cubic-bezier
            let bezier = approximateSpring(response: response, dampingFraction: dampingFraction)
            return "cubic-bezier(\(bezier.c0x), \(bezier.c0y), \(bezier.c1x), \(bezier.c1y))"
        }
    }

    /// Generates the CSS animation timing function for keyframe animations.
    ///
    /// This is identical to ``cssTransitionTiming()`` but semantically used for
    /// CSS @keyframes animations rather than transitions.
    ///
    /// - Returns: A CSS animation timing function string.
    public func cssAnimationTiming() -> String {
        cssTransitionTiming()
    }

    /// Returns the effective duration of the animation in CSS format.
    ///
    /// The duration accounts for the speed multiplier:
    /// - Effective duration = duration / speed
    ///
    /// Returns a CSS duration string with "s" suffix.
    ///
    /// - Returns: A CSS duration string (e.g., "0.35s", "0.7s").
    public func cssDuration() -> String {
        let effectiveDuration = duration / speedMultiplier
        // Round to avoid floating point precision issues
        let rounded = (effectiveDuration * 1000).rounded() / 1000
        return "\(rounded)s"
    }

    /// Returns the delay before the animation starts in CSS format.
    ///
    /// Returns a CSS delay string with "s" suffix, or "0s" if no delay is set.
    ///
    /// - Returns: A CSS delay string (e.g., "0s", "0.5s", "1.2s").
    public func cssDelay() -> String {
        // Return "0s" for zero delay, otherwise format the delay value
        if delayAmount == 0 {
            return "0s"
        }
        return "\(delayAmount)s"
    }

    /// Returns the CSS iteration count for animations.
    ///
    /// - Returns: "infinite" for forever animations, the count as a string for
    ///   finite repeats, or "1" for non-repeating animations.
    public func cssIterationCount() -> String {
        if let count = repeatCountValue {
            return count == -1 ? "infinite" : "\(count)"
        }
        return "1"
    }

    /// Returns the CSS animation direction.
    ///
    /// - Returns: "alternate" if autoreverses is true, "normal" otherwise.
    public func cssAnimationDirection() -> String {
        return autoreversesValue ? "alternate" : "normal"
    }

    /// Generates a complete CSS transition property value.
    ///
    /// Creates a CSS transition string suitable for the `transition` property:
    /// ```css
    /// transition: all 0.35s cubic-bezier(0.42, 0, 0.58, 1) 0s;
    /// ```
    ///
    /// - Parameter property: The CSS property to transition. Default is "all".
    /// - Returns: A complete CSS transition string.
    public func cssTransition(property: String = "all") -> String {
        return "\(property) \(cssDuration()) \(cssTransitionTiming()) \(cssDelay())"
    }

    /// Generates CSS animation property values.
    ///
    /// Creates CSS animation properties for use with @keyframes:
    /// ```css
    /// animation: name 0.35s ease-in-out 0s 3 alternate;
    /// ```
    ///
    /// - Parameter name: The name of the @keyframes animation.
    /// - Returns: A complete CSS animation string.
    public func cssAnimation(name: String) -> String {
        let parts = [
            name,
            cssDuration(),
            cssAnimationTiming(),
            cssDelay(),
            cssIterationCount(),
            cssAnimationDirection()
        ]
        return parts.joined(separator: " ")
    }

    // MARK: - Spring Approximation

    /// Approximates a spring animation with a cubic Bézier curve.
    ///
    /// Spring animations use physics equations that can't be perfectly represented
    /// by cubic Bézier curves. This method generates a cubic Bézier that closely
    /// matches the spring's velocity profile.
    ///
    /// - Parameters:
    ///   - response: The spring response (duration).
    ///   - dampingFraction: The spring damping fraction.
    ///
    /// - Returns: Control points for a cubic Bézier approximation.
    private func approximateSpring(
        response: Double,
        dampingFraction: Double
    ) -> (c0x: Double, c0y: Double, c1x: Double, c1y: Double) {
        // This is a simplified approximation. A more accurate approximation would
        // solve the spring differential equation and fit a cubic Bézier to it.
        //
        // For now, we use heuristics based on the damping fraction:
        // - High damping (>= 1.0): Similar to ease-out
        // - Medium damping (0.5-1.0): Balanced curve
        // - Low damping (< 0.5): More aggressive initial curve

        if dampingFraction >= 1.0 {
            // Critically damped or overdamped - similar to ease-out
            return (0.25, 0.1, 0.25, 1.0)
        } else if dampingFraction >= 0.7 {
            // Slightly underdamped - subtle bounce
            // Use a curve that starts quickly and settles smoothly
            let c0x = 0.3
            let c0y = 0.0
            let c1x = 0.2
            let c1y = 1.0 + (1.0 - dampingFraction) * 0.3 // Slight overshoot
            return (c0x, c0y, c1x, c1y)
        } else {
            // More underdamped - visible bounce
            // More aggressive curve with overshoot
            let c0x = 0.4
            let c0y = 0.0
            let c1x = 0.1
            let c1y = 1.0 + (1.0 - dampingFraction) * 0.8 // More overshoot
            return (c0x, c0y, c1x, c1y)
        }
    }
}
