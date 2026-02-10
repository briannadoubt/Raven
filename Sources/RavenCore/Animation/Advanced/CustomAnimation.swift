import Foundation

/// A keyframe-based custom animation system with precise control over timing and values.
///
/// `CustomAnimation` allows you to define animations using keyframes at specific time points,
/// with interpolation between them. This is ideal for complex, choreographed animations that
/// go beyond simple state transitions.
///
/// ## Overview
///
/// Custom animations consist of:
/// - **Keyframes**: Value points at specific times
/// - **Interpolation**: How values blend between keyframes
/// - **Timeline**: The overall duration and timing
///
/// ## Usage
///
/// ```swift
/// let animation = CustomAnimation<Double>(
///     keyframes: [
///         AnimationKeyframe(time: 0.0, value: 0, curve: .linear),
///         AnimationKeyframe(time: 0.5, value: 100, curve: .easeOut),
///         AnimationKeyframe(time: 1.0, value: 50, curve: .easeIn)
///     ],
///     duration: 2.0
/// )
///
/// let value = animation.value(at: 0.5) // Get value at 50% progress
/// ```
///
/// ## Timeline Control
///
/// Timelines provide sequencing and control:
///
/// ```swift
/// let timeline = AnimationTimeline()
/// timeline.add(animation, at: 0.0)
/// timeline.add(anotherAnimation, at: 1.5)
/// timeline.update(deltaTime: 1/60)
/// ```
@MainActor
public struct CustomAnimation<Value: AnimatableValue>: Sendable, Hashable, Equatable {
    /// The keyframes defining the animation.
    public let keyframes: [AnimationKeyframe<Value>]

    /// The total duration of the animation in seconds.
    public let duration: Double

    /// Whether the animation loops.
    public let loops: Bool

    /// Creates a custom animation from keyframes.
    ///
    /// - Parameters:
    ///   - keyframes: The keyframes (must be sorted by time).
    ///   - duration: Total animation duration.
    ///   - loops: Whether to loop the animation.
    public init(keyframes: [AnimationKeyframe<Value>], duration: Double, loops: Bool = false) {
        // Ensure keyframes are sorted by time
        self.keyframes = keyframes.sorted { $0.time < $1.time }
        self.duration = duration
        self.loops = loops
    }

    /// Gets the animated value at a specific time.
    ///
    /// - Parameter time: The time in seconds (0 to duration).
    /// - Returns: The interpolated value at that time.
    public func value(at time: Double) -> Value {
        let t = loops ? time.truncatingRemainder(dividingBy: duration) : min(time, duration)
        let progress = t / duration

        // Find the surrounding keyframes
        guard !keyframes.isEmpty else {
            return Value.zero
        }

        if keyframes.count == 1 {
            return keyframes[0].value
        }

        // Find keyframes before and after current time
        var beforeIndex = 0
        var afterIndex = 0

        for (i, keyframe) in keyframes.enumerated() {
            if keyframe.time <= progress {
                beforeIndex = i
            }
            if keyframe.time >= progress {
                afterIndex = i
                break
            }
        }

        // If we're before the first keyframe
        if progress <= keyframes[0].time {
            return keyframes[0].value
        }

        // If we're after the last keyframe
        if progress >= keyframes[keyframes.count - 1].time {
            return keyframes[keyframes.count - 1].value
        }

        // Interpolate between keyframes
        let before = keyframes[beforeIndex]
        let after = keyframes[afterIndex]

        if before.time == after.time {
            return after.value
        }

        let segmentProgress = (progress - before.time) / (after.time - before.time)
        let curveValue = before.curve.value(at: segmentProgress)

        return Value.interpolate(from: before.value, to: after.value, progress: curveValue)
    }

    /// Gets the value at a progress point (0.0 to 1.0).
    public func value(atProgress progress: Double) -> Value {
        value(at: progress * duration)
    }
}

// MARK: - AnimationKeyframe

/// A keyframe defines a value at a specific point in time.
public struct AnimationKeyframe<Value: AnimatableValue>: Sendable, Hashable, Equatable {
    /// The time of this keyframe (0.0 to 1.0, relative to animation duration).
    public let time: Double

    /// The value at this keyframe.
    public let value: Value

    /// The easing curve to use when transitioning to this keyframe.
    public let curve: AnimationCurve

    /// Creates a keyframe.
    ///
    /// - Parameters:
    ///   - time: Time position (0.0 to 1.0).
    ///   - value: The value at this time.
    ///   - curve: Easing curve for transition to this keyframe.
    public init(time: Double, value: Value, curve: AnimationCurve = .linear) {
        self.time = max(0, min(1, time))
        self.value = value
        self.curve = curve
    }
}

// MARK: - Animatable Value

/// A type that can be animated using interpolation.
public protocol AnimatableValue: Sendable, Hashable {
    /// A zero/identity value for this type.
    static var zero: Self { get }

    /// Interpolates between two values.
    ///
    /// - Parameters:
    ///   - from: Starting value.
    ///   - to: Ending value.
    ///   - progress: Interpolation progress (0.0 to 1.0).
    /// - Returns: The interpolated value.
    static func interpolate(from: Self, to: Self, progress: Double) -> Self
}

// MARK: - AnimatableValue Implementations

extension Double: AnimatableValue {
    public static var zero: Double { 0.0 }

    public static func interpolate(from: Double, to: Double, progress: Double) -> Double {
        from + (to - from) * progress
    }
}

extension CGPoint: AnimatableValue {
    public static func interpolate(from: CGPoint, to: CGPoint, progress: Double) -> CGPoint {
        CGPoint(
            x: from.x + (to.x - from.x) * progress,
            y: from.y + (to.y - from.y) * progress
        )
    }
}

extension CGSize: AnimatableValue {
    public static func interpolate(from: CGSize, to: CGSize, progress: Double) -> CGSize {
        CGSize(
            width: from.width + (to.width - from.width) * progress,
            height: from.height + (to.height - from.height) * progress
        )
    }
}

extension CGRect: AnimatableValue {
    public static func interpolate(from: CGRect, to: CGRect, progress: Double) -> CGRect {
        CGRect(
            origin: CGPoint.interpolate(from: from.origin, to: to.origin, progress: progress),
            size: CGSize.interpolate(from: from.size, to: to.size, progress: progress)
        )
    }
}

// MARK: - Animation Timeline

/// A timeline that manages multiple animations with precise timing control.
///
/// Timelines allow you to sequence animations, control playback speed, and synchronize
/// multiple animations.
@MainActor
public struct AnimationTimeline: Sendable, Hashable, Equatable {
    /// Tracks in the timeline.
    private(set) public var tracks: [Track]

    /// Current playback time in seconds.
    private(set) public var currentTime: Double

    /// Playback speed multiplier (1.0 = normal, 2.0 = double speed).
    public var speed: Double

    /// Whether the timeline is playing.
    private(set) public var isPlaying: Bool

    /// Whether the timeline loops.
    public var loops: Bool

    /// The total duration of the timeline.
    public var duration: Double {
        tracks.map { $0.endTime }.max() ?? 0
    }

    /// Creates an empty timeline.
    public init() {
        self.tracks = []
        self.currentTime = 0
        self.speed = 1.0
        self.isPlaying = false
        self.loops = false
    }

    /// Adds a track to the timeline.
    ///
    /// - Parameters:
    ///   - identifier: A unique identifier for this track.
    ///   - startTime: When the track starts in seconds.
    ///   - duration: How long the track lasts in seconds.
    public mutating func addTrack(
        identifier: String,
        startTime: Double,
        duration: Double
    ) {
        let track = Track(
            identifier: identifier,
            startTime: startTime,
            duration: duration
        )
        tracks.append(track)
    }

    /// Removes a track by identifier.
    public mutating func removeTrack(identifier: String) {
        tracks.removeAll { $0.identifier == identifier }
    }

    /// Starts playback.
    public mutating func play() {
        isPlaying = true
    }

    /// Pauses playback.
    public mutating func pause() {
        isPlaying = false
    }

    /// Stops playback and resets to beginning.
    public mutating func stop() {
        isPlaying = false
        currentTime = 0
    }

    /// Seeks to a specific time.
    public mutating func seek(to time: Double) {
        currentTime = max(0, min(time, duration))
    }

    /// Updates the timeline by one frame.
    ///
    /// - Parameter deltaTime: Time step in seconds.
    public mutating func update(deltaTime: Double) {
        guard isPlaying else { return }

        currentTime += deltaTime * speed

        if currentTime >= duration {
            if loops {
                currentTime = currentTime.truncatingRemainder(dividingBy: duration)
            } else {
                currentTime = duration
                isPlaying = false
            }
        }
    }

    /// Gets the progress of a specific track (0.0 to 1.0, or nil if not active).
    public func trackProgress(identifier: String) -> Double? {
        guard let track = tracks.first(where: { $0.identifier == identifier }) else {
            return nil
        }

        if currentTime < track.startTime {
            return nil // Not started yet
        }

        if currentTime >= track.endTime {
            return 1.0 // Completed
        }

        let elapsed = currentTime - track.startTime
        return elapsed / track.duration
    }

    /// A track in the timeline.
    public struct Track: Sendable, Hashable {
        /// Unique identifier for this track.
        public let identifier: String

        /// Start time in seconds.
        public let startTime: Double

        /// Duration in seconds.
        public let duration: Double

        /// End time in seconds.
        public var endTime: Double {
            startTime + duration
        }
    }
}

// MARK: - Preset Animations

extension CustomAnimation where Value == Double {
    /// A pulse animation (0 → 1 → 0).
    public static func pulse(duration: Double = 1.0) -> CustomAnimation<Double> {
        CustomAnimation(
            keyframes: [
                AnimationKeyframe(time: 0.0, value: 0, curve: .easeInOutSine),
                AnimationKeyframe(time: 0.5, value: 1, curve: .easeInOutSine),
                AnimationKeyframe(time: 1.0, value: 0, curve: .easeInOutSine)
            ],
            duration: duration
        )
    }

    /// A wave animation (oscillates).
    public static func wave(amplitude: Double = 1.0, duration: Double = 2.0) -> CustomAnimation<Double> {
        CustomAnimation(
            keyframes: [
                AnimationKeyframe(time: 0.00, value: 0, curve: .easeInOutSine),
                AnimationKeyframe(time: 0.25, value: amplitude, curve: .easeInOutSine),
                AnimationKeyframe(time: 0.50, value: 0, curve: .easeInOutSine),
                AnimationKeyframe(time: 0.75, value: -amplitude, curve: .easeInOutSine),
                AnimationKeyframe(time: 1.00, value: 0, curve: .easeInOutSine)
            ],
            duration: duration,
            loops: true
        )
    }

    /// A bounce animation (jumps up and down).
    public static func bounce(height: Double = 100, duration: Double = 1.0) -> CustomAnimation<Double> {
        CustomAnimation(
            keyframes: [
                AnimationKeyframe(time: 0.00, value: 0, curve: .easeOutQuad),
                AnimationKeyframe(time: 0.40, value: height, curve: .easeInQuad),
                AnimationKeyframe(time: 0.80, value: 0, curve: .easeOutQuad),
                AnimationKeyframe(time: 0.90, value: height * 0.3, curve: .easeInQuad),
                AnimationKeyframe(time: 1.00, value: 0, curve: .linear)
            ],
            duration: duration
        )
    }
}

extension CustomAnimation where Value == CGPoint {
    /// A circular path animation.
    public static func circle(
        center: CGPoint,
        radius: Double,
        duration: Double = 2.0
    ) -> CustomAnimation<CGPoint> {
        let steps = 8
        var keyframes: [AnimationKeyframe<CGPoint>] = []

        for i in 0...steps {
            let t = Double(i) / Double(steps)
            let angle = t * 2 * .pi
            let point = CGPoint(
                x: center.x + cos(angle) * radius,
                y: center.y + sin(angle) * radius
            )
            keyframes.append(AnimationKeyframe(time: t, value: point, curve: .linear))
        }

        return CustomAnimation(keyframes: keyframes, duration: duration, loops: true)
    }

    /// A figure-8 path animation.
    public static func figureEight(
        center: CGPoint,
        size: CGSize,
        duration: Double = 3.0
    ) -> CustomAnimation<CGPoint> {
        let steps = 16
        var keyframes: [AnimationKeyframe<CGPoint>] = []

        for i in 0...steps {
            let t = Double(i) / Double(steps)
            let angle = t * 2 * .pi
            let point = CGPoint(
                x: center.x + sin(angle) * size.width,
                y: center.y + sin(2 * angle) * size.height
            )
            keyframes.append(AnimationKeyframe(time: t, value: point, curve: .linear))
        }

        return CustomAnimation(keyframes: keyframes, duration: duration, loops: true)
    }
}
