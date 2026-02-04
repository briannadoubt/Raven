import Foundation

/// A particle system that spawns, updates, and manages particles with physics simulation.
///
/// `ParticleEmitter` provides a flexible particle system for creating visual effects like
/// confetti, sparks, smoke, fire, rain, and more. Particles are spawned continuously or in
/// bursts, affected by forces (gravity, wind, drag), and removed when their lifetime expires.
///
/// ## Overview
///
/// A particle system consists of:
/// - **Emitter**: Configuration for how particles are spawned
/// - **Particles**: Individual entities with position, velocity, color, size, etc.
/// - **Forces**: Physical forces that affect particle motion
/// - **Modifiers**: Systems that modify particle behavior over time
///
/// ## Usage
///
/// ```swift
/// // Create a confetti emitter
/// var emitter = ParticleEmitter(
///     position: CGPoint(x: 200, y: 0),
///     rate: 50, // Particles per second
///     lifetime: 2.0,
///     config: ParticleConfig(
///         velocityRange: CGSize(width: 200, height: 400),
///         colorRange: [.red, .blue, .green, .yellow]
///     )
/// )
///
/// // Add gravity
/// emitter.addModifier(.gravity(strength: 200))
///
/// // Update at 60fps
/// emitter.update(deltaTime: 1/60)
/// let particles = emitter.particles
/// ```
///
/// ## Emitter Types
///
/// - **Continuous**: Spawns particles at a constant rate
/// - **Burst**: Spawns a fixed number of particles at once
/// - **Pulsed**: Alternates between emitting and pausing
///
/// ## Performance
///
/// The particle system is optimized for 60fps updates with hundreds of particles.
/// Particles are stored in a contiguous array and updated in batch. Dead particles
/// are efficiently removed using swap-and-pop.
///
/// ## Thread Safety
///
/// `ParticleEmitter` is marked as `@MainActor` and `Sendable` for use with Swift
/// strict concurrency.
@MainActor
public struct ParticleEmitter: Sendable, Hashable {
    /// The position where particles are emitted.
    public var position: CGPoint

    /// The emission rate in particles per second (0 = no emission).
    public var rate: Double

    /// Whether the emitter is currently active.
    public var isActive: Bool

    /// The particle configuration.
    public var config: ParticleConfig

    /// The active particles.
    private(set) public var particles: [Particle]

    /// Accumulated time for emission timing.
    private var emissionAccumulator: Double

    /// Applied force modifiers.
    private(set) public var modifiers: [ParticleModifier]

    /// The maximum number of particles allowed (prevents unbounded growth).
    public var maxParticles: Int

    /// Creates a particle emitter.
    ///
    /// - Parameters:
    ///   - position: The emission position.
    ///   - rate: Particles per second.
    ///   - config: Particle configuration.
    ///   - maxParticles: Maximum particle count. Default is 1000.
    public init(
        position: CGPoint = CGPoint.zero,
        rate: Double = 60,
        config: ParticleConfig = ParticleConfig(),
        maxParticles: Int = 1000
    ) {
        self.position = position
        self.rate = rate
        self.isActive = true
        self.config = config
        self.particles = []
        self.emissionAccumulator = 0
        self.modifiers = []
        self.maxParticles = maxParticles
    }

    // MARK: - Emission Control

    /// Starts particle emission.
    public mutating func start() {
        isActive = true
    }

    /// Stops particle emission (existing particles continue to animate).
    public mutating func stop() {
        isActive = false
    }

    /// Emits a burst of particles immediately.
    ///
    /// - Parameter count: The number of particles to emit.
    public mutating func burst(count: Int) {
        for _ in 0..<count {
            if particles.count < maxParticles {
                particles.append(spawnParticle())
            }
        }
    }

    /// Clears all existing particles.
    public mutating func clear() {
        particles.removeAll(keepingCapacity: true)
    }

    // MARK: - Modifiers

    /// Adds a force modifier to affect particle behavior.
    public mutating func addModifier(_ modifier: ParticleModifier) {
        modifiers.append(modifier)
    }

    /// Removes all modifiers.
    public mutating func clearModifiers() {
        modifiers.removeAll()
    }

    // MARK: - Update

    /// Updates the particle system by one time step.
    ///
    /// This performs:
    /// 1. Spawn new particles based on emission rate
    /// 2. Update existing particle physics
    /// 3. Apply force modifiers
    /// 4. Remove dead particles
    ///
    /// - Parameter deltaTime: Time step in seconds (typically 1/60).
    public mutating func update(deltaTime: Double) {
        // Spawn new particles
        if isActive && rate > 0 {
            emissionAccumulator += deltaTime * rate
            let particlesToSpawn = Int(emissionAccumulator)
            emissionAccumulator -= Double(particlesToSpawn)

            for _ in 0..<particlesToSpawn {
                if particles.count < maxParticles {
                    particles.append(spawnParticle())
                }
            }
        }

        // Update existing particles
        for i in 0..<particles.count {
            var particle = particles[i]

            // Apply modifiers
            for modifier in modifiers {
                particle = modifier.apply(to: particle, deltaTime: deltaTime)
            }

            // Update physics
            particle = updateParticlePhysics(particle, deltaTime: deltaTime)

            // Update lifetime
            particle.age += deltaTime

            particles[i] = particle
        }

        // Remove dead particles (swap-and-pop for efficiency)
        var i = 0
        while i < particles.count {
            if particles[i].age >= particles[i].lifetime {
                particles.swapAt(i, particles.count - 1)
                particles.removeLast()
            } else {
                i += 1
            }
        }
    }

    // MARK: - Internal Helpers

    /// Spawns a new particle with randomized properties based on config.
    private func spawnParticle() -> Particle {
        // Random angle within emission cone
        let angleVariance = config.emissionAngleVariance
        let baseAngle = config.emissionAngle
        let angle = baseAngle + Double.random(in: -angleVariance...angleVariance)

        // Random speed
        let speed = Double.random(in: config.speedRange.lowerBound...config.speedRange.upperBound)

        // Calculate velocity from angle and speed
        let velocity = CGSize(
            width: cos(angle) * speed,
            height: sin(angle) * speed
        )

        // Random lifetime
        let lifetime = Double.random(
            in: config.lifetimeRange.lowerBound...config.lifetimeRange.upperBound
        )

        // Random size
        let size = Double.random(
            in: config.sizeRange.lowerBound...config.sizeRange.upperBound
        )

        // Random color from palette
        let color = config.colors.randomElement() ?? ParticleColor(r: 1, g: 1, b: 1, a: 1)

        // Random position offset within emission radius
        let offsetAngle = Double.random(in: 0...(2 * .pi))
        let offsetRadius = Double.random(in: 0...config.emissionRadius)
        let positionOffset = CGPoint(
            x: cos(offsetAngle) * offsetRadius,
            y: sin(offsetAngle) * offsetRadius
        )

        return Particle(
            position: CGPoint(
                x: position.x + positionOffset.x,
                y: position.y + positionOffset.y
            ),
            velocity: velocity,
            acceleration: CGSize.zero,
            color: color,
            size: size,
            rotation: Double.random(in: 0...(2 * .pi)),
            rotationSpeed: Double.random(
                in: config.rotationSpeedRange.lowerBound...config.rotationSpeedRange.upperBound
            ),
            lifetime: lifetime,
            age: 0
        )
    }

    /// Updates a particle's physics (position, velocity, rotation).
    private func updateParticlePhysics(_ particle: Particle, deltaTime: Double) -> Particle {
        var p = particle

        // Update velocity with acceleration
        p.velocity = CGSize(
            width: p.velocity.width + p.acceleration.width * deltaTime,
            height: p.velocity.height + p.acceleration.height * deltaTime
        )

        // Update position with velocity
        p.position = CGPoint(
            x: p.position.x + p.velocity.width * deltaTime,
            y: p.position.y + p.velocity.height * deltaTime
        )

        // Update rotation
        p.rotation += p.rotationSpeed * deltaTime

        return p
    }
}

// MARK: - Particle

/// A single particle with physical properties.
public struct Particle: Sendable, Hashable {
    /// Current position.
    public var position: CGPoint

    /// Current velocity (units per second).
    public var velocity: CGSize

    /// Current acceleration (units per second²).
    public var acceleration: CGSize

    /// Current color.
    public var color: ParticleColor

    /// Current size (radius or width/height).
    public var size: Double

    /// Current rotation in radians.
    public var rotation: Double

    /// Rotation speed in radians per second.
    public var rotationSpeed: Double

    /// Total lifetime in seconds.
    public var lifetime: Double

    /// Current age in seconds.
    public var age: Double

    /// Progress through lifetime (0.0 to 1.0).
    public var progress: Double {
        age / lifetime
    }

    /// Whether the particle is still alive.
    public var isAlive: Bool {
        age < lifetime
    }
}

// MARK: - Particle Color

/// A color representation for particles.
public struct ParticleColor: Sendable, Hashable {
    /// Red component (0.0 to 1.0).
    public var r: Double

    /// Green component (0.0 to 1.0).
    public var g: Double

    /// Blue component (0.0 to 1.0).
    public var b: Double

    /// Alpha component (0.0 to 1.0).
    public var a: Double

    /// Creates a particle color.
    public init(r: Double, g: Double, b: Double, a: Double = 1.0) {
        self.r = max(0, min(1, r))
        self.g = max(0, min(1, g))
        self.b = max(0, min(1, b))
        self.a = max(0, min(1, a))
    }

    // MARK: - Presets

    public static let red = ParticleColor(r: 1, g: 0, b: 0)
    public static let green = ParticleColor(r: 0, g: 1, b: 0)
    public static let blue = ParticleColor(r: 0, g: 0, b: 1)
    public static let yellow = ParticleColor(r: 1, g: 1, b: 0)
    public static let cyan = ParticleColor(r: 0, g: 1, b: 1)
    public static let magenta = ParticleColor(r: 1, g: 0, b: 1)
    public static let white = ParticleColor(r: 1, g: 1, b: 1)
    public static let black = ParticleColor(r: 0, g: 0, b: 0)
    public static let orange = ParticleColor(r: 1, g: 0.5, b: 0)
    public static let purple = ParticleColor(r: 0.5, g: 0, b: 1)

    /// Converts to CSS rgba string.
    public func toCSSString() -> String {
        "rgba(\(Int(r * 255)), \(Int(g * 255)), \(Int(b * 255)), \(a))"
    }
}

// MARK: - Particle Config

/// Configuration for particle emission.
public struct ParticleConfig: Sendable, Hashable {
    /// Range of possible particle speeds.
    public var speedRange: ClosedRange<Double>

    /// Range of possible particle lifetimes in seconds.
    public var lifetimeRange: ClosedRange<Double>

    /// Range of possible particle sizes.
    public var sizeRange: ClosedRange<Double>

    /// Range of rotation speeds in radians per second.
    public var rotationSpeedRange: ClosedRange<Double>

    /// Base emission angle in radians (0 = right, π/2 = down).
    public var emissionAngle: Double

    /// Variance in emission angle (±radians).
    public var emissionAngleVariance: Double

    /// Radius around emission position where particles can spawn.
    public var emissionRadius: Double

    /// Color palette for particles.
    public var colors: [ParticleColor]

    /// Creates a particle configuration.
    public init(
        speedRange: ClosedRange<Double> = 100...300,
        lifetimeRange: ClosedRange<Double> = 1.0...3.0,
        sizeRange: ClosedRange<Double> = 4...12,
        rotationSpeedRange: ClosedRange<Double> = -2...2,
        emissionAngle: Double = .pi / 2, // Down
        emissionAngleVariance: Double = .pi / 4,
        emissionRadius: Double = 0,
        colors: [ParticleColor] = [.white]
    ) {
        self.speedRange = speedRange
        self.lifetimeRange = lifetimeRange
        self.sizeRange = sizeRange
        self.rotationSpeedRange = rotationSpeedRange
        self.emissionAngle = emissionAngle
        self.emissionAngleVariance = emissionAngleVariance
        self.emissionRadius = emissionRadius
        self.colors = colors
    }

    // MARK: - Presets

    /// Confetti effect configuration.
    public static var confetti: ParticleConfig {
        ParticleConfig(
            speedRange: 200...500,
            lifetimeRange: 2...4,
            sizeRange: 6...14,
            rotationSpeedRange: -4...4,
            emissionAngle: -.pi / 2, // Up
            emissionAngleVariance: .pi / 3,
            emissionRadius: 20,
            colors: [.red, .blue, .green, .yellow, .cyan, .magenta, .orange, .purple]
        )
    }

    /// Fire effect configuration.
    public static var fire: ParticleConfig {
        ParticleConfig(
            speedRange: 50...150,
            lifetimeRange: 0.5...1.5,
            sizeRange: 8...20,
            rotationSpeedRange: -1...1,
            emissionAngle: -.pi / 2, // Up
            emissionAngleVariance: .pi / 6,
            emissionRadius: 10,
            colors: [
                .red,
                .orange,
                .yellow,
                ParticleColor(r: 1, g: 0.3, b: 0) // Red-orange
            ]
        )
    }

    /// Smoke effect configuration.
    public static var smoke: ParticleConfig {
        ParticleConfig(
            speedRange: 30...80,
            lifetimeRange: 2...4,
            sizeRange: 15...40,
            rotationSpeedRange: -0.5...0.5,
            emissionAngle: -.pi / 2, // Up
            emissionAngleVariance: .pi / 8,
            emissionRadius: 5,
            colors: [
                ParticleColor(r: 0.5, g: 0.5, b: 0.5, a: 0.3),
                ParticleColor(r: 0.6, g: 0.6, b: 0.6, a: 0.4),
                ParticleColor(r: 0.7, g: 0.7, b: 0.7, a: 0.2)
            ]
        )
    }

    /// Rain effect configuration.
    public static var rain: ParticleConfig {
        ParticleConfig(
            speedRange: 400...600,
            lifetimeRange: 1...2,
            sizeRange: 2...4,
            rotationSpeedRange: 0...0,
            emissionAngle: .pi / 2, // Down
            emissionAngleVariance: .pi / 32,
            emissionRadius: 0,
            colors: [
                ParticleColor(r: 0.7, g: 0.8, b: 1, a: 0.6)
            ]
        )
    }

    /// Sparkles effect configuration.
    public static var sparkles: ParticleConfig {
        ParticleConfig(
            speedRange: 50...200,
            lifetimeRange: 0.5...1.5,
            sizeRange: 3...8,
            rotationSpeedRange: -5...5,
            emissionAngle: 0,
            emissionAngleVariance: 2 * .pi, // All directions
            emissionRadius: 10,
            colors: [
                .white,
                .yellow,
                ParticleColor(r: 1, g: 1, b: 0.8)
            ]
        )
    }
}
