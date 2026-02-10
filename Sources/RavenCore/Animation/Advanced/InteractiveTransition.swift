import Foundation

/// A gesture-driven interactive transition that tracks user input and animates accordingly.
///
/// `InteractiveTransition` bridges gesture recognition with animation, allowing users to
/// drive animations through touch/drag input. The transition can be completed, cancelled,
/// or allowed to finish based on velocity thresholds.
///
/// ## Overview
///
/// Interactive transitions are commonly used for:
/// - Swipe-to-dismiss modals
/// - Pull-to-refresh
/// - Swipe-to-navigate
/// - Interactive drag animations
///
/// ## Usage
///
/// ```swift
/// var transition = InteractiveTransition(
///     from: 0,
///     to: 100,
///     threshold: 0.5
/// )
///
/// // User drags
/// transition.update(progress: 0.3, velocity: 50)
///
/// // User releases
/// if transition.shouldComplete {
///     transition.finish()
/// } else {
///     transition.cancel()
/// }
///
/// // Animate to final state
/// transition.animate(deltaTime: 1/60)
/// ```
///
/// ## Completion Logic
///
/// The transition uses smart completion logic based on:
/// - Progress threshold (e.g., 50% = auto-complete)
/// - Velocity threshold (fast swipes complete regardless of progress)
/// - Direction (whether movement is toward completion or cancellation)
@MainActor
public struct InteractiveTransition<Value: AnimatableValue>: Sendable, Hashable {
    /// The starting value.
    public let fromValue: Value

    /// The target value.
    public let toValue: Value

    /// The current animated value.
    private(set) public var currentValue: Value

    /// The current progress (0.0 = start, 1.0 = complete).
    private(set) public var progress: Double

    /// The current velocity (in progress units per second).
    private(set) public var velocity: Double

    /// Progress threshold for auto-completion (default 0.5).
    public var completionThreshold: Double

    /// Velocity threshold for auto-completion (in progress/second).
    public var velocityThreshold: Double

    /// The physics animation used for finishing.
    public var springAnimation: PhysicsAnimation

    /// The current state of the transition.
    private(set) public var state: State

    /// Internal physics state for animated completion.
    private var physicsState: PhysicsAnimation.State?

    /// Creates an interactive transition.
    ///
    /// - Parameters:
    ///   - from: Starting value.
    ///   - to: Target value.
    ///   - threshold: Progress threshold for completion (0.0 to 1.0).
    ///   - velocityThreshold: Velocity threshold for completion.
    ///   - spring: Physics animation for completion.
    public init(
        from: Value,
        to: Value,
        threshold: Double = 0.5,
        velocityThreshold: Double = 0.5,
        spring: PhysicsAnimation = .default
    ) {
        self.fromValue = from
        self.toValue = to
        self.currentValue = from
        self.progress = 0
        self.velocity = 0
        self.completionThreshold = threshold
        self.velocityThreshold = velocityThreshold
        self.springAnimation = spring
        self.state = .interactive
        self.physicsState = nil
    }

    // MARK: - State

    /// The state of an interactive transition.
    public enum State: Sendable, Hashable {
        /// User is actively controlling the transition.
        case interactive

        /// Animating to completion.
        case completing

        /// Animating to cancellation.
        case cancelling

        /// Transition has finished at the target.
        case completed

        /// Transition has finished at the start.
        case cancelled
    }

    // MARK: - Interactive Control

    /// Updates the transition progress during user interaction.
    ///
    /// - Parameters:
    ///   - progress: Current progress (0.0 to 1.0).
    ///   - velocity: Current velocity in progress/second.
    public mutating func update(progress: Double, velocity: Double) {
        guard state == .interactive else { return }

        self.progress = max(0, min(1, progress))
        self.velocity = velocity
        self.currentValue = Value.interpolate(
            from: fromValue,
            to: toValue,
            progress: self.progress
        )
    }

    /// Updates the transition based on a drag gesture value.
    ///
    /// This is a convenience method that calculates progress from a drag translation
    /// relative to a total distance.
    ///
    /// - Parameters:
    ///   - translation: Current drag translation.
    ///   - totalDistance: The distance representing 100% progress.
    ///   - gestureVelocity: The gesture velocity.
    public mutating func update(
        translation: Double,
        totalDistance: Double,
        gestureVelocity: Double
    ) {
        guard totalDistance > 0 else { return }

        let progress = translation / totalDistance
        let velocity = gestureVelocity / totalDistance

        update(progress: progress, velocity: velocity)
    }

    /// Determines whether the transition should complete based on current state.
    ///
    /// Returns `true` if:
    /// - Progress exceeds completion threshold, OR
    /// - Velocity exceeds velocity threshold in forward direction
    public var shouldComplete: Bool {
        progress >= completionThreshold || velocity >= velocityThreshold
    }

    /// Determines whether the transition should cancel based on current state.
    public var shouldCancel: Bool {
        !shouldComplete
    }

    // MARK: - Completion

    /// Begins animating to completion.
    public mutating func finish() {
        guard state == .interactive else { return }

        state = .completing
        physicsState = springAnimation.createState(
            from: progress,
            to: 1.0,
            velocity: velocity
        )
    }

    /// Begins animating to cancellation.
    public mutating func cancel() {
        guard state == .interactive else { return }

        state = .cancelling
        physicsState = springAnimation.createState(
            from: progress,
            to: 0.0,
            velocity: velocity
        )
    }

    /// Immediately completes the transition without animation.
    public mutating func completeImmediately() {
        state = .completed
        progress = 1.0
        currentValue = toValue
        physicsState = nil
    }

    /// Immediately cancels the transition without animation.
    public mutating func cancelImmediately() {
        state = .cancelled
        progress = 0.0
        currentValue = fromValue
        physicsState = nil
    }

    // MARK: - Animation

    /// Updates the transition animation by one frame.
    ///
    /// This should be called from requestAnimationFrame loop when the transition
    /// is in completing or cancelling state.
    ///
    /// - Parameter deltaTime: Time step in seconds (typically 1/60).
    /// - Returns: Whether the animation is still active.
    @discardableResult
    public mutating func animate(deltaTime: Double) -> Bool {
        guard state == .completing || state == .cancelling else {
            return false
        }

        guard var physics = physicsState else {
            return false
        }

        // Update physics
        physics = springAnimation.update(physics, deltaTime: deltaTime)
        physicsState = physics

        // Update current values
        progress = physics.value
        velocity = physics.velocity
        currentValue = Value.interpolate(
            from: fromValue,
            to: toValue,
            progress: progress
        )

        // Check if settled
        if physics.isSettled {
            if state == .completing {
                state = .completed
                progress = 1.0
                currentValue = toValue
            } else {
                state = .cancelled
                progress = 0.0
                currentValue = fromValue
            }
            physicsState = nil
            return false
        }

        return true
    }

    // MARK: - State Queries

    /// Whether the transition is currently active (interactive or animating).
    public var isActive: Bool {
        switch state {
        case .interactive, .completing, .cancelling:
            return true
        case .completed, .cancelled:
            return false
        }
    }

    /// Whether the transition has finished (completed or cancelled).
    public var isFinished: Bool {
        state == .completed || state == .cancelled
    }

    /// Whether the transition completed successfully.
    public var didComplete: Bool {
        state == .completed
    }

    /// Whether the transition was cancelled.
    public var didCancel: Bool {
        state == .cancelled
    }
}

// MARK: - 2D Interactive Transition

/// A 2D interactive transition for animating points, sizes, or offsets.
@MainActor
public struct InteractiveTransition2D: Sendable, Hashable {
    /// X-axis transition.
    public var x: InteractiveTransition<Double>

    /// Y-axis transition.
    public var y: InteractiveTransition<Double>

    /// Creates a 2D interactive transition for a point.
    public init(
        from: CGPoint,
        to: CGPoint,
        threshold: Double = 0.5,
        velocityThreshold: Double = 0.5,
        spring: PhysicsAnimation = .default
    ) {
        self.x = InteractiveTransition(
            from: from.x,
            to: to.x,
            threshold: threshold,
            velocityThreshold: velocityThreshold,
            spring: spring
        )
        self.y = InteractiveTransition(
            from: from.y,
            to: to.y,
            threshold: threshold,
            velocityThreshold: velocityThreshold,
            spring: spring
        )
    }

    /// Creates a 2D interactive transition for a size.
    public init(
        from: CGSize,
        to: CGSize,
        threshold: Double = 0.5,
        velocityThreshold: Double = 0.5,
        spring: PhysicsAnimation = .default
    ) {
        self.x = InteractiveTransition(
            from: from.width,
            to: to.width,
            threshold: threshold,
            velocityThreshold: velocityThreshold,
            spring: spring
        )
        self.y = InteractiveTransition(
            from: from.height,
            to: to.height,
            threshold: threshold,
            velocityThreshold: velocityThreshold,
            spring: spring
        )
    }

    /// The current animated point.
    public var point: CGPoint {
        CGPoint(x: x.currentValue, y: y.currentValue)
    }

    /// The current animated size.
    public var size: CGSize {
        CGSize(width: x.currentValue, height: y.currentValue)
    }

    /// The current progress (average of X and Y).
    public var progress: Double {
        (x.progress + y.progress) / 2
    }

    /// Whether both axes should complete.
    public var shouldComplete: Bool {
        x.shouldComplete || y.shouldComplete
    }

    /// Updates both axes with a drag gesture.
    public mutating func update(
        translation: CGSize,
        totalDistance: CGSize,
        velocity: CGSize
    ) {
        x.update(
            translation: translation.width,
            totalDistance: totalDistance.width,
            gestureVelocity: velocity.width
        )
        y.update(
            translation: translation.height,
            totalDistance: totalDistance.height,
            gestureVelocity: velocity.height
        )
    }

    /// Finishes both axes.
    public mutating func finish() {
        x.finish()
        y.finish()
    }

    /// Cancels both axes.
    public mutating func cancel() {
        x.cancel()
        y.cancel()
    }

    /// Animates both axes.
    @discardableResult
    public mutating func animate(deltaTime: Double) -> Bool {
        let xActive = x.animate(deltaTime: deltaTime)
        let yActive = y.animate(deltaTime: deltaTime)
        return xActive || yActive
    }

    /// Whether the transition is active.
    public var isActive: Bool {
        x.isActive || y.isActive
    }

    /// Whether the transition completed.
    public var didComplete: Bool {
        x.didComplete && y.didComplete
    }
}

// MARK: - Preset Transitions

extension InteractiveTransition {
    /// A quick, snappy transition for responsive UI.
    public static func snappy(from: Value, to: Value) -> InteractiveTransition<Value> {
        InteractiveTransition(
            from: from,
            to: to,
            threshold: 0.4,
            velocityThreshold: 1.0,
            spring: .snappy
        )
    }

    /// A gentle, smooth transition.
    public static func gentle(from: Value, to: Value) -> InteractiveTransition<Value> {
        InteractiveTransition(
            from: from,
            to: to,
            threshold: 0.6,
            velocityThreshold: 0.3,
            spring: .gentle
        )
    }

    /// A bouncy, playful transition.
    public static func bouncy(from: Value, to: Value) -> InteractiveTransition<Value> {
        InteractiveTransition(
            from: from,
            to: to,
            threshold: 0.5,
            velocityThreshold: 0.8,
            spring: .bouncy
        )
    }
}
