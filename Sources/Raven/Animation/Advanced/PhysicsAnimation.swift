import Foundation

/// A physics-based animation system that simulates real spring dynamics with mass, stiffness, and damping.
///
/// `PhysicsAnimation` provides accurate spring physics simulation that can be updated at 60fps using
/// requestAnimationFrame. Unlike the standard `Animation.spring()` which approximates springs with
/// cubic bezier curves, this implementation uses actual physics calculations.
///
/// ## Overview
///
/// Physics animations solve the spring differential equation:
/// ```
/// F = -k*x - c*v
/// a = F/m
/// ```
/// Where:
/// - `k` is stiffness (spring constant)
/// - `c` is damping coefficient
/// - `m` is mass
/// - `x` is displacement from target
/// - `v` is velocity
/// - `a` is acceleration
///
/// ## Usage
///
/// ```swift
/// let spring = PhysicsAnimation.spring(
///     mass: 1.0,
///     stiffness: 200,
///     damping: 20
/// )
///
/// var state = spring.createState(from: 0, to: 100)
/// state = spring.update(state, deltaTime: 1/60)
/// print(state.value) // Current animated value
/// ```
///
/// ## Spring Presets
///
/// The library includes several preset spring configurations:
/// - `.gentle`: Slow, smooth spring with minimal bounce
/// - `.default`: Balanced spring suitable for most UI
/// - `.snappy`: Fast, responsive spring with quick settling
/// - `.bouncy`: Playful spring with visible oscillation
///
/// ## Performance
///
/// Physics animations are optimized for 60fps updates with minimal overhead. The simulation
/// uses Euler integration by default, which is fast and stable for typical UI springs.
///
/// ## Thread Safety
///
/// All types are `Sendable` and use value semantics for safe concurrent access.
@MainActor
public struct PhysicsAnimation: Sendable, Hashable {
    /// The mass of the spring system (affects inertia).
    public let mass: Double

    /// The stiffness of the spring (spring constant k).
    public let stiffness: Double

    /// The damping coefficient (friction/resistance).
    public let damping: Double

    /// Velocity threshold below which the animation is considered settled.
    public let velocityThreshold: Double

    /// Position threshold below which the animation is considered settled.
    public let positionThreshold: Double

    /// Creates a physics animation with explicit spring parameters.
    ///
    /// - Parameters:
    ///   - mass: The mass of the spring system. Higher mass = more inertia. Default is 1.0.
    ///   - stiffness: The spring constant. Higher stiffness = tighter spring. Default is 200.
    ///   - damping: The damping coefficient. Higher damping = less oscillation. Default is 20.
    ///   - velocityThreshold: Velocity below which animation is settled. Default is 0.01.
    ///   - positionThreshold: Position delta below which animation is settled. Default is 0.001.
    public init(
        mass: Double = 1.0,
        stiffness: Double = 200,
        damping: Double = 20,
        velocityThreshold: Double = 0.01,
        positionThreshold: Double = 0.001
    ) {
        self.mass = max(0.001, mass) // Prevent division by zero
        self.stiffness = max(0, stiffness)
        self.damping = max(0, damping)
        self.velocityThreshold = velocityThreshold
        self.positionThreshold = positionThreshold
    }

    // MARK: - Presets

    /// A gentle, smooth spring with minimal bounce.
    ///
    /// Characteristics:
    /// - Low stiffness for slow movement
    /// - High damping for smooth deceleration
    /// - Suitable for subtle animations
    public static var gentle: PhysicsAnimation {
        PhysicsAnimation(mass: 1.0, stiffness: 100, damping: 25)
    }

    /// The default spring configuration.
    ///
    /// Characteristics:
    /// - Balanced stiffness and damping
    /// - Slight bounce for natural feel
    /// - Suitable for most UI animations
    public static var `default`: PhysicsAnimation {
        PhysicsAnimation(mass: 1.0, stiffness: 200, damping: 20)
    }

    /// A fast, responsive spring with quick settling.
    ///
    /// Characteristics:
    /// - High stiffness for quick response
    /// - Moderate damping for fast settling
    /// - Suitable for interactive elements
    public static var snappy: PhysicsAnimation {
        PhysicsAnimation(mass: 1.0, stiffness: 400, damping: 30)
    }

    /// A bouncy, playful spring with visible oscillation.
    ///
    /// Characteristics:
    /// - High stiffness for responsive motion
    /// - Low damping for pronounced bounce
    /// - Suitable for playful, attention-grabbing animations
    public static var bouncy: PhysicsAnimation {
        PhysicsAnimation(mass: 1.0, stiffness: 300, damping: 10)
    }

    /// Creates a spring with custom response and damping fraction (SwiftUI-style).
    ///
    /// This method provides compatibility with SwiftUI's spring parameters.
    ///
    /// - Parameters:
    ///   - response: The duration of the spring in seconds (inverse of frequency).
    ///   - dampingFraction: The damping ratio (0 = undamped, 1 = critically damped).
    /// - Returns: A physics animation configured to match the specified parameters.
    public static func spring(response: Double, dampingFraction: Double) -> PhysicsAnimation {
        let mass = 1.0
        let stiffness = pow(2 * .pi / response, 2) * mass
        let damping = 4 * .pi * dampingFraction * mass / response

        return PhysicsAnimation(
            mass: mass,
            stiffness: stiffness,
            damping: damping
        )
    }

    // MARK: - State Management

    /// Creates an initial animation state for the given range.
    ///
    /// - Parameters:
    ///   - from: The starting value.
    ///   - to: The target value.
    ///   - velocity: The initial velocity. Default is 0.
    /// - Returns: A new animation state ready for updates.
    public func createState(from: Double, to: Double, velocity: Double = 0) -> State {
        State(
            value: from,
            target: to,
            velocity: velocity,
            animation: self
        )
    }

    /// Updates the animation state by one time step.
    ///
    /// Uses Euler integration to solve the spring differential equation:
    /// - Calculate spring force: F = -k * x - c * v
    /// - Calculate acceleration: a = F / m
    /// - Update velocity: v += a * dt
    /// - Update position: x += v * dt
    ///
    /// - Parameters:
    ///   - state: The current animation state.
    ///   - deltaTime: The time step in seconds (typically 1/60 for 60fps).
    /// - Returns: The updated animation state.
    public func update(_ state: State, deltaTime: Double) -> State {
        // If already settled, return unchanged
        if state.isSettled {
            return state
        }

        // Calculate displacement from target
        let displacement = state.value - state.target

        // Calculate spring force: F = -kx - cv
        let springForce = -stiffness * displacement
        let dampingForce = -damping * state.velocity
        let totalForce = springForce + dampingForce

        // Calculate acceleration: a = F/m
        let acceleration = totalForce / mass

        // Update velocity: v += a * dt
        let newVelocity = state.velocity + acceleration * deltaTime

        // Update position: x += v * dt
        let newValue = state.value + newVelocity * deltaTime

        // Check if settled
        let velocitySettled = abs(newVelocity) < velocityThreshold
        let positionSettled = abs(newValue - state.target) < positionThreshold
        let isSettled = velocitySettled && positionSettled

        return State(
            value: isSettled ? state.target : newValue,
            target: state.target,
            velocity: isSettled ? 0 : newVelocity,
            animation: self,
            isSettled: isSettled
        )
    }

    /// Calculates the approximate duration until the spring settles.
    ///
    /// Uses the damping ratio to estimate settling time. This is approximate as
    /// actual settling depends on initial conditions.
    ///
    /// - Returns: The estimated settling time in seconds.
    public func estimatedDuration() -> Double {
        // Calculate damping ratio
        let criticalDamping = 2 * sqrt(stiffness * mass)
        let dampingRatio = damping / criticalDamping

        // Estimate settling time based on damping ratio
        // For critically damped or overdamped: ~4-5 time constants
        // For underdamped: slightly longer due to oscillation
        let naturalFrequency = sqrt(stiffness / mass)
        let timeConstant = 1 / (dampingRatio * naturalFrequency)

        return dampingRatio >= 1.0 ? timeConstant * 4 : timeConstant * 5
    }
}

// MARK: - Animation State

extension PhysicsAnimation {
    /// The state of a physics animation at a point in time.
    ///
    /// This structure tracks the current value, target, velocity, and whether
    /// the animation has settled. It's designed to be updated frame-by-frame.
    public struct State: Sendable, Hashable {
        /// The current animated value.
        public let value: Double

        /// The target value the animation is moving toward.
        public let target: Double

        /// The current velocity (rate of change per second).
        public let velocity: Double

        /// The animation parameters.
        public let animation: PhysicsAnimation

        /// Whether the animation has settled (velocity and position within thresholds).
        public let isSettled: Bool

        /// Creates a new animation state.
        ///
        /// - Parameters:
        ///   - value: The current value.
        ///   - target: The target value.
        ///   - velocity: The current velocity.
        ///   - animation: The animation parameters.
        ///   - isSettled: Whether the animation is settled.
        internal init(
            value: Double,
            target: Double,
            velocity: Double,
            animation: PhysicsAnimation,
            isSettled: Bool = false
        ) {
            self.value = value
            self.target = target
            self.velocity = velocity
            self.animation = animation
            self.isSettled = isSettled
        }

        /// Updates the target value while preserving velocity.
        ///
        /// This allows for smooth retargeting during animation, common in
        /// gesture-driven interactions.
        ///
        /// - Parameter newTarget: The new target value.
        /// - Returns: A new state with the updated target.
        public func withTarget(_ newTarget: Double) -> State {
            State(
                value: value,
                target: newTarget,
                velocity: velocity,
                animation: animation,
                isSettled: false
            )
        }

        /// Updates the velocity (useful for gesture-driven animations).
        ///
        /// - Parameter newVelocity: The new velocity.
        /// - Returns: A new state with the updated velocity.
        public func withVelocity(_ newVelocity: Double) -> State {
            State(
                value: value,
                target: target,
                velocity: newVelocity,
                animation: animation,
                isSettled: false
            )
        }
    }
}

// MARK: - 2D Physics

/// Two-dimensional physics animation for animating points, sizes, and offsets.
///
/// This extends the single-dimensional `PhysicsAnimation` to work with 2D values
/// by independently animating X and Y components.
@MainActor
public struct Physics2D: Sendable, Hashable {
    /// The X-axis animation.
    public let x: PhysicsAnimation

    /// The Y-axis animation.
    public let y: PhysicsAnimation

    /// Creates a 2D physics animation with the same parameters for both axes.
    ///
    /// - Parameter animation: The animation to use for both X and Y.
    public init(_ animation: PhysicsAnimation) {
        self.x = animation
        self.y = animation
    }

    /// Creates a 2D physics animation with different parameters for each axis.
    ///
    /// - Parameters:
    ///   - x: The X-axis animation.
    ///   - y: The Y-axis animation.
    public init(x: PhysicsAnimation, y: PhysicsAnimation) {
        self.x = x
        self.y = y
    }

    // MARK: - State Management

    /// Creates an initial animation state for a CGPoint range.
    public func createState(from: CGPoint, to: CGPoint, velocity: CGSize = CGSize.zero) -> State {
        State(
            x: x.createState(from: from.x, to: to.x, velocity: velocity.width),
            y: y.createState(from: from.y, to: to.y, velocity: velocity.height)
        )
    }

    /// Creates an initial animation state for a CGSize range.
    public func createState(from: CGSize, to: CGSize, velocity: CGSize = CGSize.zero) -> State {
        State(
            x: x.createState(from: from.width, to: to.width, velocity: velocity.width),
            y: y.createState(from: from.height, to: to.height, velocity: velocity.height)
        )
    }

    /// Updates the 2D animation state by one time step.
    public func update(_ state: State, deltaTime: Double) -> State {
        State(
            x: x.update(state.x, deltaTime: deltaTime),
            y: y.update(state.y, deltaTime: deltaTime)
        )
    }

    /// The state of a 2D physics animation.
    public struct State: Sendable, Hashable {
        /// The X-axis state.
        public let x: PhysicsAnimation.State

        /// The Y-axis state.
        public let y: PhysicsAnimation.State

        /// Whether both axes have settled.
        public var isSettled: Bool {
            x.isSettled && y.isSettled
        }

        /// The current animated point.
        public var point: CGPoint {
            CGPoint(x: x.value, y: y.value)
        }

        /// The current animated size.
        public var size: CGSize {
            CGSize(width: x.value, height: y.value)
        }

        /// The current velocity.
        public var velocity: CGSize {
            CGSize(width: x.velocity, height: y.velocity)
        }

        /// Updates the target point while preserving velocity.
        public func withTarget(_ target: CGPoint) -> State {
            State(
                x: x.withTarget(target.x),
                y: y.withTarget(target.y)
            )
        }

        /// Updates the target size while preserving velocity.
        public func withTarget(_ target: CGSize) -> State {
            State(
                x: x.withTarget(target.width),
                y: y.withTarget(target.height)
            )
        }
    }
}
