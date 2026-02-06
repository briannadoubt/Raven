/// Global animation context for explicit animation blocks.
///
/// The `withAnimation` function creates a transaction context that applies an animation
/// to any state changes that occur within its body closure. This is the primary way to
/// create explicit, animated state changes in Raven.
///
/// ## Basic Usage
///
/// Wrap state changes in a `withAnimation` block to animate them:
///
/// ```swift
/// @State private var isExpanded = false
///
/// Button("Toggle") {
///     withAnimation {
///         isExpanded.toggle()
///     }
/// }
/// ```
///
/// ## Custom Animations
///
/// Specify a custom animation to control the timing and style:
///
/// ```swift
/// withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
///     opacity = 0.5
///     scale = 1.2
/// }
/// ```
///
/// ## Completion Callbacks
///
/// Use the completion callback variant to execute code after the animation finishes:
///
/// ```swift
/// withAnimation(.easeOut, {
///     showDetails = true
/// }, completion: {
///     print("Animation finished")
///     // Trigger next action
/// })
/// ```
///
/// ## How It Works
///
/// `withAnimation` creates a transaction context that:
///
/// 1. Sets the current animation in a global context
/// 2. Executes the body closure (which may change @State properties)
/// 3. Views that observe those state changes will use the current animation
/// 4. The animation context is automatically restored after the body completes
///
/// ## Difference from `.animation()` Modifier
///
/// - `withAnimation`: Explicitly animates specific state changes at the call site
/// - `.animation()` modifier: Automatically animates all changes to a value
///
/// Use `withAnimation` when you want fine-grained control over which state changes
/// should be animated. Use the `.animation()` modifier when you want a view to
/// always animate changes to a specific value.
///
/// ## Nested Animations
///
/// Nested `withAnimation` calls use the innermost animation:
///
/// ```swift
/// withAnimation(.easeIn) {
///     // This uses .easeIn
///     x = 100
///
///     withAnimation(.spring()) {
///         // This uses .spring()
///         y = 200
///     }
///
///     // Back to .easeIn
///     z = 300
/// }
/// ```
///
/// ## Thread Safety
///
/// `withAnimation` is `@MainActor` and must be called from the main thread, matching
/// SwiftUI's requirements for UI state changes.
///
/// ## CSS Rendering
///
/// When state changes occur inside a `withAnimation` block, the rendering system:
///
/// 1. Reads the current animation from the transaction context
/// 2. Applies CSS transitions to affected elements
/// 3. Uses the animation's timing, duration, and delay settings
/// 4. Triggers completion callbacks when CSS transitionend events fire
///
/// ## Performance
///
/// Animation contexts use thread-local storage for fast access and minimal overhead.
/// The body closure is executed inline with no additional allocations beyond the
/// animation value itself.

/// The main animation context that manages the current transaction.
///
/// This class maintains a stack of animation transactions, allowing nested
/// `withAnimation` calls to work correctly. The current animation can be
/// accessed and modified by the rendering system.
@MainActor
internal final class AnimationContext: Sendable {
    /// The current animation in the active transaction, if any.
    ///
    /// This is `nil` when no `withAnimation` block is active. Views can check
    /// this value to determine if they should animate their changes.
    nonisolated(unsafe) static var current: Animation? = nil

    /// The completion callback for the current animation, if any.
    ///
    /// This callback will be invoked when the animation completes. It's stored
    /// separately from the animation itself to keep `Animation` a simple value type.
    nonisolated(unsafe) static var currentCompletion: (@MainActor @Sendable () -> Void)? = nil

    /// Executes a closure within an animation transaction context.
    ///
    /// This method manages the animation context stack, ensuring that nested
    /// animations work correctly and the context is always restored.
    ///
    /// - Parameters:
    ///   - animation: The animation to use for state changes in the body, or `nil`
    ///     for no animation.
    ///   - body: The closure to execute with the animation context.
    ///   - completion: Optional completion callback to invoke when the animation finishes.
    ///
    /// - Returns: The result of the body closure.
    /// - Throws: Rethrows any error thrown by the body closure.
    static func withAnimation<T>(
        _ animation: Animation?,
        _ body: () throws -> T,
        completion: (@MainActor @Sendable () -> Void)? = nil
    ) rethrows -> T {
        // Save the previous animation context
        let previousAnimation = current

        // Set the new animation context
        current = animation
        currentCompletion = completion

        // Ensure we always restore the previous animation
        // Note: completion is intentionally NOT restored - it persists after
        // withAnimation returns so the render system can pick it up via
        // takeCompletionCallback()
        defer {
            current = previousAnimation
        }

        // Execute the body with the new context
        return try body()
    }

    /// Retrieves the current animation from the active transaction.
    ///
    /// Views and modifiers can call this to check if they should animate changes.
    ///
    /// - Returns: The current animation, or `nil` if no animation is active.
    static func getCurrentAnimation() -> Animation? {
        return current
    }

    /// Retrieves and clears the current completion callback.
    ///
    /// This is called by the rendering system after setting up the animation,
    /// ensuring the callback is invoked only once.
    ///
    /// - Returns: The completion callback, or `nil` if none is set.
    static func takeCompletionCallback() -> (@MainActor @Sendable () -> Void)? {
        let callback = currentCompletion
        currentCompletion = nil
        return callback
    }
}

// MARK: - Public API

/// Executes a closure with an animation applied to any state changes.
///
/// Use `withAnimation` to explicitly animate state changes that occur within the
/// body closure. This is the primary way to create smooth, animated transitions
/// in response to user interactions or other events.
///
/// ## Basic Example
///
/// ```swift
/// @State private var isExpanded = false
/// @State private var opacity: Double = 1.0
///
/// Button("Animate") {
///     withAnimation {
///         isExpanded.toggle()
///         opacity = 0.5
///     }
/// }
/// ```
///
/// ## Custom Animation
///
/// Specify a custom animation to control the timing:
///
/// ```swift
/// withAnimation(.spring(response: 0.3)) {
///     scale = 1.5
/// }
///
/// withAnimation(.easeInOut) {
///     offset = 100
/// }
///
/// withAnimation(.linear.delay(0.5)) {
///     rotation = 45
/// }
/// ```
///
/// ## Disabling Animation
///
/// Pass `nil` to temporarily disable animations:
///
/// ```swift
/// withAnimation(nil) {
///     // These changes won't animate
///     x = 0
///     y = 0
/// }
/// ```
///
/// ## How It Works
///
/// The function creates a transaction context that:
///
/// 1. Sets the current animation in a global context accessible to views
/// 2. Executes the body closure where state changes occur
/// 3. Views that render with changed state will check for an active animation
/// 4. If found, they apply CSS transitions with the animation's parameters
/// 5. The animation context is automatically restored when the body completes
///
/// ## Nested Animations
///
/// You can nest `withAnimation` calls - the innermost animation takes precedence:
///
/// ```swift
/// withAnimation(.default) {
///     a = 1  // Uses .default
///
///     withAnimation(.spring()) {
///         b = 2  // Uses .spring()
///     }
///
///     c = 3  // Back to .default
/// }
/// ```
///
/// ## Thread Safety
///
/// This function must be called from the main thread, as indicated by the
/// `@MainActor` attribute. This matches SwiftUI's requirements for UI updates.
///
/// ## Performance
///
/// The function has minimal overhead - it simply sets a thread-local variable,
/// executes the body inline, and restores the previous value. No additional
/// memory allocations occur beyond the animation value itself.
///
/// - Parameters:
///   - animation: The animation to apply to state changes within the body.
///     If `nil`, changes will not be animated. Default is `.default`.
///   - body: A closure containing state changes to animate.
///
/// - Returns: The result of the body closure.
/// - Throws: Rethrows any error thrown by the body closure.
///
/// ## See Also
///
/// - ``Animation``
/// - ``withAnimation(_:_:completion:)``
/// - ``View/animation(_:value:)``
@MainActor
public func withAnimation<Result>(
    _ animation: Animation? = .default,
    _ body: () throws -> Result
) rethrows -> Result {
    try AnimationContext.withAnimation(animation, body)
}

/// Executes a closure with an animation and a completion callback.
///
/// This variant of `withAnimation` allows you to execute code after the animation
/// completes. The completion callback is invoked when the CSS transition ends,
/// allowing you to chain animations or trigger follow-up actions.
///
/// ## Example
///
/// ```swift
/// @State private var isVisible = false
/// @State private var hasAppeared = false
///
/// Button("Show") {
///     withAnimation(.easeOut, {
///         isVisible = true
///     }, completion: {
///         hasAppeared = true
///         print("View has fully appeared")
///     })
/// }
/// ```
///
/// ## Chaining Animations
///
/// Use completion callbacks to create sequential animations:
///
/// ```swift
/// func animateSequence() {
///     withAnimation(.easeIn, {
///         step1 = true
///     }, completion: {
///         withAnimation(.spring(), {
///             step2 = true
///         }, completion: {
///             print("Sequence complete")
///         })
///     })
/// }
/// ```
///
/// ## Multiple State Changes
///
/// When multiple views animate from a single `withAnimation` block, the completion
/// is called after the longest animation finishes:
///
/// ```swift
/// withAnimation(.default, {
///     view1Opacity = 0.5  // Animates for 0.35s
///     view2Scale = 1.2    // Animates for 0.35s
/// }, completion: {
///     // Called after both animations complete (~0.35s)
/// })
/// ```
///
/// ## Thread Safety
///
/// The completion callback is guaranteed to be called on the main thread, making
/// it safe to perform UI updates directly within the callback.
///
/// ## Implementation Note
///
/// Completion callbacks are tracked using CSS `transitionend` events. If no
/// transitions are triggered (e.g., the state change doesn't affect any views),
/// the callback may not be invoked. For reliable completion callbacks, ensure
/// that the state changes actually trigger view updates.
///
/// - Parameters:
///   - animation: The animation to apply to state changes within the body.
///     If `nil`, changes will not be animated. Default is `.default`.
///   - body: A closure containing state changes to animate.
///   - completion: A callback to invoke when the animation completes.
///     Must be sendable and will be called on the main thread.
///
/// - Returns: The result of the body closure.
/// - Throws: Rethrows any error thrown by the body closure.
///
/// ## See Also
///
/// - ``withAnimation(_:_:)``
/// - ``Animation``
@MainActor
public func withAnimation<Result>(
    _ animation: Animation? = .default,
    _ body: () throws -> Result,
    completion: @escaping @MainActor @Sendable () -> Void
) rethrows -> Result {
    try AnimationContext.withAnimation(animation, body, completion: completion)
}
