import Foundation

/// A system for sequencing animations one after another with precise timing control.
///
/// `ChainedAnimation` allows you to create complex animation sequences where each step
/// starts after the previous one completes. This is ideal for choreographed UI animations,
/// onboarding sequences, and step-by-step reveals.
///
/// ## Overview
///
/// Chained animations consist of:
/// - **Steps**: Individual animation segments
/// - **Delays**: Optional pauses between steps
/// - **Coordination**: Automatic progression through the chain
///
/// ## Usage
///
/// ```swift
/// var chain = ChainedAnimation<Double>()
///
/// // Add animation steps
/// chain.addStep(from: 0, to: 100, duration: 1.0, curve: .easeOut)
/// chain.addDelay(0.5)
/// chain.addStep(from: 100, to: 50, duration: 0.5, curve: .easeIn)
///
/// // Play the chain
/// chain.play()
///
/// // Update each frame
/// chain.update(deltaTime: 1/60)
/// let currentValue = chain.currentValue
/// ```
///
/// ## Step Types
///
/// - **Animation**: Interpolates between values
/// - **Delay**: Pauses for a duration
/// - **Callback**: Executes a closure
///
/// ## Playback Control
///
/// Chains support:
/// - Play/pause/stop
/// - Speed control
/// - Looping
/// - Jump to specific steps
@MainActor
public struct ChainedAnimation<Value: AnimatableValue>: Sendable, Hashable, Equatable {
    /// The steps in the animation chain.
    private(set) public var steps: [Step]

    /// The current step index.
    private(set) public var currentStepIndex: Int

    /// Time elapsed in the current step.
    private(set) public var currentStepTime: Double

    /// The current animated value.
    private(set) public var currentValue: Value

    /// Playback speed multiplier.
    public var speed: Double

    /// Whether the chain is currently playing.
    private(set) public var isPlaying: Bool

    /// Whether the chain loops when it reaches the end.
    public var loops: Bool

    /// Creates an empty animation chain.
    public init(initialValue: Value = Value.zero) {
        self.steps = []
        self.currentStepIndex = 0
        self.currentStepTime = 0
        self.currentValue = initialValue
        self.speed = 1.0
        self.isPlaying = false
        self.loops = false
    }

    // MARK: - Building

    /// Adds an animation step to the chain.
    ///
    /// - Parameters:
    ///   - from: Starting value.
    ///   - to: Ending value.
    ///   - duration: Duration in seconds.
    ///   - curve: Easing curve.
    public mutating func addStep(
        from: Value,
        to: Value,
        duration: Double,
        curve: AnimationCurve = .easeInOut
    ) {
        steps.append(.animation(
            from: from,
            to: to,
            duration: duration,
            curve: curve
        ))
    }

    /// Adds a delay step to the chain.
    ///
    /// - Parameter duration: Delay duration in seconds.
    public mutating func addDelay(_ duration: Double) {
        steps.append(.delay(duration))
    }

    /// Adds a step that animates to a new value from the current value.
    ///
    /// - Parameters:
    ///   - to: Target value.
    ///   - duration: Duration in seconds.
    ///   - curve: Easing curve.
    public mutating func then(
        to: Value,
        duration: Double,
        curve: AnimationCurve = .easeInOut
    ) {
        // Use the last step's end value as the start
        let from = steps.last?.endValue ?? currentValue
        addStep(from: from, to: to, duration: duration, curve: curve)
    }

    // MARK: - Playback Control

    /// Starts playing the animation chain.
    public mutating func play() {
        isPlaying = true
    }

    /// Pauses the animation chain.
    public mutating func pause() {
        isPlaying = false
    }

    /// Stops the animation and resets to the beginning.
    public mutating func stop() {
        isPlaying = false
        currentStepIndex = 0
        currentStepTime = 0
        if let firstStep = steps.first {
            currentValue = firstStep.startValue
        }
    }

    /// Jumps to a specific step in the chain.
    ///
    /// - Parameter index: The step index.
    public mutating func jumpToStep(_ index: Int) {
        guard index >= 0 && index < steps.count else { return }
        currentStepIndex = index
        currentStepTime = 0
        currentValue = steps[index].startValue
    }

    // MARK: - Update

    /// Updates the animation chain by one frame.
    ///
    /// - Parameter deltaTime: Time step in seconds (typically 1/60).
    public mutating func update(deltaTime: Double) {
        guard isPlaying && !steps.isEmpty else { return }

        var remainingTime = deltaTime * speed

        while remainingTime > 0 {
            if currentStepIndex >= steps.count {
                // Reached the end
                if loops {
                    currentStepIndex = 0
                    currentStepTime = 0
                    if let firstStep = steps.first {
                        currentValue = firstStep.startValue
                    }
                    continue
                } else {
                    isPlaying = false
                    return
                }
            }

            let step = steps[currentStepIndex]
            let stepDuration = step.duration
            let timeInStep = currentStepTime + remainingTime

            if timeInStep >= stepDuration {
                // Complete current step and move to next
                remainingTime = timeInStep - stepDuration
                currentValue = step.endValue
                currentStepIndex += 1
                currentStepTime = 0
            } else {
                // Continue current step
                currentStepTime = timeInStep
                currentValue = step.value(at: currentStepTime)
                remainingTime = 0
            }
        }
    }

    // MARK: - State Queries

    /// The total duration of the entire chain.
    public var totalDuration: Double {
        steps.reduce(0) { $0 + $1.duration }
    }

    /// The current overall progress (0.0 to 1.0).
    public var progress: Double {
        guard totalDuration > 0 else { return 0 }

        var elapsed = 0.0
        for i in 0..<currentStepIndex {
            elapsed += steps[i].duration
        }
        elapsed += currentStepTime

        return min(1.0, elapsed / totalDuration)
    }

    /// Whether the chain has completed.
    public var isComplete: Bool {
        currentStepIndex >= steps.count && !isPlaying
    }

    // MARK: - Step

    /// A step in an animation chain.
    public enum Step: Sendable, Hashable {
        /// An animation step that interpolates between values.
        case animation(from: Value, to: Value, duration: Double, curve: AnimationCurve)

        /// A delay step that pauses for a duration.
        case delay(Double)

        /// The duration of this step.
        var duration: Double {
            switch self {
            case .animation(_, _, let duration, _):
                return duration
            case .delay(let duration):
                return duration
            }
        }

        /// The starting value of this step.
        var startValue: Value {
            switch self {
            case .animation(let from, _, _, _):
                return from
            case .delay:
                return Value.zero
            }
        }

        /// The ending value of this step.
        var endValue: Value {
            switch self {
            case .animation(_, let to, _, _):
                return to
            case .delay:
                return Value.zero
            }
        }

        /// Gets the value at a specific time within this step.
        func value(at time: Double) -> Value {
            switch self {
            case .animation(let from, let to, let duration, let curve):
                let progress = min(1.0, time / duration)
                let curveValue = curve.value(at: progress)
                return Value.interpolate(from: from, to: to, progress: curveValue)
            case .delay:
                return Value.zero
            }
        }
    }
}

// MARK: - Builder API

extension ChainedAnimation {
    /// A builder for creating chained animations with a fluent API.
    @MainActor
    public struct Builder {
        private var chain: ChainedAnimation<Value>

        /// Creates a builder with an initial value.
        public init(from: Value) {
            self.chain = ChainedAnimation(initialValue: from)
        }

        /// Adds an animation step.
        public func then(
            to: Value,
            duration: Double,
            curve: AnimationCurve = .easeInOut
        ) -> Builder {
            var builder = self
            builder.chain.then(to: to, duration: duration, curve: curve)
            return builder
        }

        /// Adds a delay.
        public func wait(_ duration: Double) -> Builder {
            var builder = self
            builder.chain.addDelay(duration)
            return builder
        }

        /// Enables looping.
        public func loop() -> Builder {
            var builder = self
            builder.chain.loops = true
            return builder
        }

        /// Sets the playback speed.
        public func speed(_ speed: Double) -> Builder {
            var builder = self
            builder.chain.speed = speed
            return builder
        }

        /// Builds the final chain.
        public func build() -> ChainedAnimation<Value> {
            chain
        }
    }

    /// Creates a builder starting from a value.
    public static func from(_ value: Value) -> Builder {
        Builder(from: value)
    }
}

// MARK: - Preset Chains

extension ChainedAnimation where Value == Double {
    /// A heartbeat animation (two pulses).
    public static func heartbeat(amplitude: Double = 1.2, duration: Double = 1.0) -> ChainedAnimation<Double> {
        ChainedAnimation.from(1.0)
            .then(to: amplitude, duration: duration * 0.2, curve: .easeOut)
            .then(to: 1.0, duration: duration * 0.2, curve: .easeIn)
            .wait(duration * 0.1)
            .then(to: amplitude, duration: duration * 0.2, curve: .easeOut)
            .then(to: 1.0, duration: duration * 0.3, curve: .easeIn)
            .build()
    }

    /// A shake animation (oscillates left-right).
    public static func shake(amplitude: Double = 10, duration: Double = 0.5) -> ChainedAnimation<Double> {
        let stepDuration = duration / 8
        return ChainedAnimation.from(0)
            .then(to: amplitude, duration: stepDuration, curve: .linear)
            .then(to: -amplitude, duration: stepDuration, curve: .linear)
            .then(to: amplitude, duration: stepDuration, curve: .linear)
            .then(to: -amplitude, duration: stepDuration, curve: .linear)
            .then(to: amplitude * 0.5, duration: stepDuration, curve: .linear)
            .then(to: -amplitude * 0.5, duration: stepDuration, curve: .linear)
            .then(to: amplitude * 0.25, duration: stepDuration, curve: .linear)
            .then(to: 0, duration: stepDuration, curve: .linear)
            .build()
    }

    /// A typewriter reveal animation (0 to 1 with pauses).
    public static func typewriter(characterCount: Int, delayPerChar: Double = 0.05) -> ChainedAnimation<Double> {
        let builder = ChainedAnimation.from(0.0)

        var result = builder
        for i in 1...characterCount {
            let progress = Double(i) / Double(characterCount)
            result = result.then(to: progress, duration: delayPerChar, curve: .linear)
        }

        return result.build()
    }
}

extension ChainedAnimation where Value == CGPoint {
    /// A path-following animation.
    public static func followPath(
        _ points: [CGPoint],
        duration: Double,
        curve: AnimationCurve = .easeInOut
    ) -> ChainedAnimation<CGPoint> {
        guard !points.isEmpty else {
            return ChainedAnimation(initialValue: .zero)
        }

        var builder = ChainedAnimation.from(points[0])
        let stepDuration = duration / Double(max(1, points.count - 1))

        for i in 1..<points.count {
            builder = builder.then(to: points[i], duration: stepDuration, curve: curve)
        }

        return builder.build()
    }

    /// A zigzag path animation.
    public static func zigzag(
        start: CGPoint,
        amplitude: Double,
        segments: Int,
        duration: Double
    ) -> ChainedAnimation<CGPoint> {
        var builder = ChainedAnimation.from(start)
        let stepDuration = duration / Double(segments)

        for i in 1...segments {
            let x = start.x + (Double(i) / Double(segments)) * amplitude * Double(segments)
            let y = start.y + (i % 2 == 0 ? amplitude : -amplitude)
            builder = builder.then(to: CGPoint(x: x, y: y), duration: stepDuration, curve: .linear)
        }

        return builder.build()
    }
}
