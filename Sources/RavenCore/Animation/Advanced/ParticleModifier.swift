import Foundation

/// A modifier that applies forces and effects to particles.
///
/// `ParticleModifier` defines how particles are affected over their lifetime, including
/// physical forces (gravity, wind, drag), visual changes (color fading, size changes),
/// and behavioral effects (attraction, turbulence).
///
/// ## Overview
///
/// Modifiers are applied to particles each frame during the update loop. Multiple
/// modifiers can be combined to create complex effects. The order of modifiers matters
/// as they are applied sequentially.
///
/// ## Usage
///
/// ```swift
/// var emitter = ParticleEmitter(...)
///
/// // Add gravity
/// emitter.addModifier(.gravity(strength: 200))
///
/// // Add wind
/// emitter.addModifier(.wind(velocity: CGSize(width: 50, height: 0)))
///
/// // Fade out over lifetime
/// emitter.addModifier(.fadeOut)
///
/// // Shrink over lifetime
/// emitter.addModifier(.scale(from: 1.0, to: 0.0))
/// ```
///
/// ## Modifier Types
///
/// - **Forces**: Gravity, wind, drag, attraction
/// - **Visual**: Fade, color transition, scale
/// - **Behavioral**: Turbulence, vortex, bounds
///
/// ## Performance
///
/// Modifiers are designed for 60fps updates with minimal overhead. Complex modifiers
/// like turbulence use fast approximations rather than expensive noise functions.
public enum ParticleModifier: Sendable, Hashable {
    // MARK: - Physical Forces

    /// Applies constant downward acceleration (gravity).
    ///
    /// - Parameter strength: Acceleration in units per second² (default 200).
    case gravity(strength: Double = 200)

    /// Applies constant wind force in a direction.
    ///
    /// - Parameter velocity: Wind velocity vector.
    case wind(velocity: CGSize)

    /// Applies drag/air resistance proportional to velocity.
    ///
    /// Drag force = -drag * velocity
    ///
    /// - Parameter coefficient: Drag coefficient (0 = no drag, 1 = heavy drag).
    case drag(coefficient: Double)

    /// Attracts particles toward a point.
    ///
    /// - Parameters:
    ///   - point: The attraction point.
    ///   - strength: Attraction strength.
    ///   - radius: Maximum effective radius (beyond this, no effect).
    case attraction(point: CGPoint, strength: Double, radius: Double)

    /// Repels particles from a point.
    ///
    /// - Parameters:
    ///   - point: The repulsion point.
    ///   - strength: Repulsion strength.
    ///   - radius: Maximum effective radius.
    case repulsion(point: CGPoint, strength: Double, radius: Double)

    // MARK: - Visual Modifiers

    /// Fades particles out as they age (linear).
    case fadeOut

    /// Fades particles in at the start of their life.
    ///
    /// - Parameter duration: Fade-in duration as fraction of lifetime (0.0 to 1.0).
    case fadeIn(duration: Double = 0.2)

    /// Transitions particle color over lifetime.
    ///
    /// - Parameters:
    ///   - from: Starting color.
    ///   - to: Ending color.
    case colorTransition(from: ParticleColor, to: ParticleColor)

    /// Scales particles over lifetime.
    ///
    /// - Parameters:
    ///   - from: Starting scale multiplier.
    ///   - to: Ending scale multiplier.
    case scale(from: Double, to: Double)

    // MARK: - Behavioral Modifiers

    /// Adds random turbulent motion using simplified noise.
    ///
    /// - Parameters:
    ///   - strength: Turbulence force strength.
    ///   - frequency: Noise frequency (higher = more chaotic).
    case turbulence(strength: Double, frequency: Double = 1.0)

    /// Creates a vortex/swirl effect around a point.
    ///
    /// - Parameters:
    ///   - center: The vortex center.
    ///   - strength: Rotational force strength.
    ///   - radius: Maximum effective radius.
    case vortex(center: CGPoint, strength: Double, radius: Double)

    /// Confines particles within bounds (bounces or wraps).
    ///
    /// - Parameters:
    ///   - rect: The bounding rectangle.
    ///   - mode: Behavior at boundaries.
    case bounds(rect: CGRect, mode: BoundsMode)

    /// Applies acceleration in a specific direction.
    ///
    /// - Parameter acceleration: Acceleration vector.
    case acceleration(CGSize)

    // MARK: - Application

    /// Applies this modifier to a particle.
    ///
    /// - Parameters:
    ///   - particle: The particle to modify.
    ///   - deltaTime: Time step in seconds.
    /// - Returns: The modified particle.
    public func apply(to particle: Particle, deltaTime: Double) -> Particle {
        var p = particle

        switch self {
        case .gravity(let strength):
            p.acceleration = CGSize(
                width: p.acceleration.width,
                height: p.acceleration.height + strength
            )

        case .wind(let velocity):
            p.acceleration = CGSize(
                width: p.acceleration.width + velocity.width / deltaTime,
                height: p.acceleration.height + velocity.height / deltaTime
            )

        case .drag(let coefficient):
            let dragForce = CGSize(
                width: -p.velocity.width * coefficient,
                height: -p.velocity.height * coefficient
            )
            p.acceleration = CGSize(
                width: p.acceleration.width + dragForce.width / deltaTime,
                height: p.acceleration.height + dragForce.height / deltaTime
            )

        case .attraction(let point, let strength, let radius):
            let dx = point.x - p.position.x
            let dy = point.y - p.position.y
            let distance = sqrt(dx * dx + dy * dy)

            if distance > 0 && distance < radius {
                let force = strength / (distance * distance)
                let forceX = (dx / distance) * force
                let forceY = (dy / distance) * force

                p.acceleration = CGSize(
                    width: p.acceleration.width + forceX,
                    height: p.acceleration.height + forceY
                )
            }

        case .repulsion(let point, let strength, let radius):
            let dx = p.position.x - point.x
            let dy = p.position.y - point.y
            let distance = sqrt(dx * dx + dy * dy)

            if distance > 0 && distance < radius {
                let force = strength / (distance * distance)
                let forceX = (dx / distance) * force
                let forceY = (dy / distance) * force

                p.acceleration = CGSize(
                    width: p.acceleration.width + forceX,
                    height: p.acceleration.height + forceY
                )
            }

        case .fadeOut:
            let alpha = 1.0 - p.progress
            p.color.a = alpha

        case .fadeIn(let duration):
            if p.progress < duration {
                let alpha = p.progress / duration
                p.color.a = min(p.color.a, alpha)
            }

        case .colorTransition(let from, let to):
            let t = p.progress
            p.color = ParticleColor(
                r: from.r + (to.r - from.r) * t,
                g: from.g + (to.g - from.g) * t,
                b: from.b + (to.b - from.b) * t,
                a: from.a + (to.a - from.a) * t
            )

        case .scale(let from, let to):
            let scale = from + (to - from) * p.progress
            p.size = p.size * scale

        case .turbulence(let strength, let frequency):
            // Simple turbulence using particle position and age
            let noiseX = sin(p.position.x * frequency + p.age * 10) * strength
            let noiseY = cos(p.position.y * frequency + p.age * 10) * strength

            p.acceleration = CGSize(
                width: p.acceleration.width + noiseX,
                height: p.acceleration.height + noiseY
            )

        case .vortex(let center, let strength, let radius):
            let dx = p.position.x - center.x
            let dy = p.position.y - center.y
            let distance = sqrt(dx * dx + dy * dy)

            if distance > 0 && distance < radius {
                // Perpendicular vector for rotation
                let force = strength / distance
                let forceX = -dy * force
                let forceY = dx * force

                p.acceleration = CGSize(
                    width: p.acceleration.width + forceX,
                    height: p.acceleration.height + forceY
                )
            }

        case .bounds(let rect, let mode):
            switch mode {
            case .bounce:
                // Bounce off bounds
                if p.position.x < rect.minX {
                    p.position.x = rect.minX
                    p.velocity.width = abs(p.velocity.width)
                } else if p.position.x > rect.maxX {
                    p.position.x = rect.maxX
                    p.velocity.width = -abs(p.velocity.width)
                }

                if p.position.y < rect.minY {
                    p.position.y = rect.minY
                    p.velocity.height = abs(p.velocity.height)
                } else if p.position.y > rect.maxY {
                    p.position.y = rect.maxY
                    p.velocity.height = -abs(p.velocity.height)
                }

            case .wrap:
                // Wrap around bounds
                if p.position.x < rect.minX {
                    p.position.x = rect.maxX
                } else if p.position.x > rect.maxX {
                    p.position.x = rect.minX
                }

                if p.position.y < rect.minY {
                    p.position.y = rect.maxY
                } else if p.position.y > rect.maxY {
                    p.position.y = rect.minY
                }

            case .kill:
                // Kill particles outside bounds
                if p.position.x < rect.minX || p.position.x > rect.maxX ||
                   p.position.y < rect.minY || p.position.y > rect.maxY {
                    p.age = p.lifetime // Mark as dead
                }
            }

        case .acceleration(let accel):
            p.acceleration = CGSize(
                width: p.acceleration.width + accel.width,
                height: p.acceleration.height + accel.height
            )
        }

        return p
    }
}

// MARK: - Bounds Mode

/// Defines how particles behave at boundaries.
public enum BoundsMode: Sendable, Hashable {
    /// Particles bounce off boundaries.
    case bounce

    /// Particles wrap around to the opposite side.
    case wrap

    /// Particles are killed when they leave bounds.
    case kill
}

// MARK: - Preset Modifier Combinations

extension ParticleModifier {
    /// Standard gravity and drag (realistic falling motion).
    public static var standardPhysics: [ParticleModifier] {
        [
            .gravity(strength: 200),
            .drag(coefficient: 0.5)
        ]
    }

    /// Floating upward with drag (smoke-like).
    public static var floatingUp: [ParticleModifier] {
        [
            .gravity(strength: -50), // Negative = upward
            .drag(coefficient: 1.0)
        ]
    }

    /// Rising with turbulence (fire-like).
    public static var risingFire: [ParticleModifier] {
        [
            .gravity(strength: -100),
            .turbulence(strength: 30, frequency: 0.5),
            .fadeOut
        ]
    }

    /// Explosion effect (burst outward then fall).
    public static var explosion: [ParticleModifier] {
        [
            .gravity(strength: 300),
            .drag(coefficient: 0.3),
            .fadeOut
        ]
    }

    /// Gentle floating particles.
    public static var gentleFloat: [ParticleModifier] {
        [
            .gravity(strength: 20),
            .turbulence(strength: 10, frequency: 1.0),
            .drag(coefficient: 0.8)
        ]
    }
}

// MARK: - Composite Modifier

/// A modifier that combines multiple modifiers in sequence.
///
/// This allows for creating complex modifier chains that can be reused.
public struct CompositeModifier: Sendable, Hashable {
    /// The modifiers to apply in order.
    public let modifiers: [ParticleModifier]

    /// Creates a composite modifier.
    public init(_ modifiers: [ParticleModifier]) {
        self.modifiers = modifiers
    }

    /// Applies all modifiers to a particle in sequence.
    public func apply(to particle: Particle, deltaTime: Double) -> Particle {
        var p = particle
        for modifier in modifiers {
            p = modifier.apply(to: p, deltaTime: deltaTime)
        }
        return p
    }
}
