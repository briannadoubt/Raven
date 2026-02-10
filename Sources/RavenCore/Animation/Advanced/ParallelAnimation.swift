import Foundation

/// A system for running multiple animations concurrently with synchronized timing.
///
/// `ParallelAnimation` allows you to animate multiple properties simultaneously while
/// maintaining precise control over each animation's timing, duration, and easing.
/// This is essential for coordinated multi-property animations.
///
/// ## Overview
///
/// Parallel animations consist of:
/// - **Tracks**: Independent animation channels
/// - **Synchronization**: Unified timing control
/// - **Coordination**: All animations start and stop together
///
/// ## Usage
///
/// ```swift
/// var parallel = ParallelAnimation()
///
/// // Add animation tracks
/// parallel.addTrack(
///     identifier: "position",
///     from: CGPoint(x: 0, y: 0),
///     to: CGPoint(x: 100, y: 100),
///     duration: 1.0,
///     curve: .easeOut
/// )
///
/// parallel.addTrack(
///     identifier: "opacity",
///     from: 0.0,
///     to: 1.0,
///     duration: 0.5,
///     curve: .easeIn
/// )
///
/// // Play all tracks
/// parallel.play()
///
/// // Update each frame
/// parallel.update(deltaTime: 1/60)
/// let position: CGPoint? = parallel.value(for: "position")
/// let opacity: Double? = parallel.value(for: "opacity")
/// ```
///
/// ## Track Management
///
/// Tracks can be:
/// - Added with unique identifiers
/// - Removed by identifier
/// - Queried for current values
/// - Have different durations and curves
///
/// ## Playback Control
///
/// Parallel animations support:
/// - Play/pause/stop
/// - Speed control
/// - Looping
/// - Individual track access
@MainActor
public struct ParallelAnimation: Sendable, Hashable, Equatable {
    /// The animation tracks.
    private var tracks: [String: AnyTrack]

    /// The current playback time in seconds.
    private(set) public var currentTime: Double

    /// Playback speed multiplier.
    public var speed: Double

    /// Whether the animation is currently playing.
    private(set) public var isPlaying: Bool

    /// Whether the animation loops.
    public var loops: Bool

    /// The duration of the longest track.
    public var duration: Double {
        tracks.values.map(\.duration).max() ?? 0
    }

    /// Creates an empty parallel animation.
    public init() {
        self.tracks = [:]
        self.currentTime = 0
        self.speed = 1.0
        self.isPlaying = false
        self.loops = false
    }

    // MARK: - Track Management

    /// Adds an animation track.
    ///
    /// - Parameters:
    ///   - identifier: Unique identifier for this track.
    ///   - from: Starting value.
    ///   - to: Ending value.
    ///   - duration: Duration in seconds.
    ///   - curve: Easing curve.
    ///   - delay: Optional delay before starting this track.
    public mutating func addTrack<Value: AnimatableValue>(
        identifier: String,
        from: Value,
        to: Value,
        duration: Double,
        curve: AnimationCurve = .easeInOut,
        delay: Double = 0
    ) {
        let track = Track(
            from: from,
            to: to,
            duration: duration,
            curve: curve,
            delay: delay
        )
        tracks[identifier] = AnyTrack(track)
    }

    /// Removes a track by identifier.
    public mutating func removeTrack(identifier: String) {
        tracks.removeValue(forKey: identifier)
    }

    /// Gets the current value of a track.
    ///
    /// - Parameter identifier: The track identifier.
    /// - Returns: The current animated value, or nil if track doesn't exist.
    public func value<Value: AnimatableValue>(for identifier: String) -> Value? {
        guard let anyTrack = tracks[identifier] else { return nil }
        guard let track = anyTrack.track as? Track<Value> else { return nil }

        let trackTime = max(0, currentTime - track.delay)
        return track.value(at: trackTime)
    }

    /// Gets all track identifiers.
    public var trackIdentifiers: [String] {
        Array(tracks.keys)
    }

    // MARK: - Playback Control

    /// Starts playing all tracks.
    public mutating func play() {
        isPlaying = true
    }

    /// Pauses all tracks.
    public mutating func pause() {
        isPlaying = false
    }

    /// Stops all tracks and resets to the beginning.
    public mutating func stop() {
        isPlaying = false
        currentTime = 0
    }

    /// Seeks to a specific time.
    ///
    /// - Parameter time: The time in seconds.
    public mutating func seek(to time: Double) {
        currentTime = max(0, min(time, duration))
    }

    // MARK: - Update

    /// Updates all tracks by one frame.
    ///
    /// - Parameter deltaTime: Time step in seconds (typically 1/60).
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

    // MARK: - State Queries

    /// The overall progress (0.0 to 1.0).
    public var progress: Double {
        guard duration > 0 else { return 0 }
        return min(1.0, currentTime / duration)
    }

    /// Whether all tracks have completed.
    public var isComplete: Bool {
        currentTime >= duration && !isPlaying
    }

    /// Gets the progress of a specific track (0.0 to 1.0, or nil if not started).
    public func trackProgress(identifier: String) -> Double? {
        guard let anyTrack = tracks[identifier] else { return nil }

        let trackTime = max(0, currentTime - anyTrack.delay)

        if trackTime < 0 {
            return nil // Not started yet
        }

        if trackTime >= anyTrack.duration {
            return 1.0 // Completed
        }

        return trackTime / anyTrack.duration
    }

    // MARK: - Track

    /// An individual animation track with a specific value type.
    private struct Track<Value: AnimatableValue>: Sendable, Hashable {
        let from: Value
        let to: Value
        let duration: Double
        let curve: AnimationCurve
        let delay: Double

        func value(at time: Double) -> Value {
            if time < 0 {
                return from
            }

            if time >= duration {
                return to
            }

            let progress = time / duration
            let curveValue = curve.value(at: progress)
            return Value.interpolate(from: from, to: to, progress: curveValue)
        }
    }

    /// Type-erased track wrapper.
    private struct AnyTrack: Sendable, Hashable {
        let track: any Sendable & Hashable
        let duration: Double
        let delay: Double

        init<Value: AnimatableValue>(_ track: Track<Value>) {
            self.track = track
            self.duration = track.duration
            self.delay = track.delay
        }

        static func == (lhs: AnyTrack, rhs: AnyTrack) -> Bool {
            lhs.duration == rhs.duration && lhs.delay == rhs.delay
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(duration)
            hasher.combine(delay)
        }
    }
}

// MARK: - Builder API

extension ParallelAnimation {
    /// A builder for creating parallel animations with a fluent API.
    @MainActor
    public struct Builder {
        private var parallel: ParallelAnimation

        /// Creates a new builder.
        public init() {
            self.parallel = ParallelAnimation()
        }

        /// Adds an animation track.
        public func animate<Value: AnimatableValue>(
            _ identifier: String,
            from: Value,
            to: Value,
            duration: Double,
            curve: AnimationCurve = .easeInOut,
            delay: Double = 0
        ) -> Builder {
            var builder = self
            builder.parallel.addTrack(
                identifier: identifier,
                from: from,
                to: to,
                duration: duration,
                curve: curve,
                delay: delay
            )
            return builder
        }

        /// Enables looping.
        public func loop() -> Builder {
            var builder = self
            builder.parallel.loops = true
            return builder
        }

        /// Sets the playback speed.
        public func speed(_ speed: Double) -> Builder {
            var builder = self
            builder.parallel.speed = speed
            return builder
        }

        /// Builds the final parallel animation.
        public func build() -> ParallelAnimation {
            parallel
        }
    }

    /// Creates a builder for fluent API.
    public static func builder() -> Builder {
        Builder()
    }
}

// MARK: - Preset Animations

extension ParallelAnimation {
    /// A fade and scale animation (common for modal presentations).
    public static func fadeAndScale(
        from fromScale: Double = 0.8,
        to toScale: Double = 1.0,
        duration: Double = 0.3
    ) -> ParallelAnimation {
        ParallelAnimation.builder()
            .animate("opacity", from: 0.0, to: 1.0, duration: duration, curve: .easeOut)
            .animate("scale", from: fromScale, to: toScale, duration: duration, curve: .easeOut)
            .build()
    }

    /// A slide and fade animation (common for view transitions).
    public static func slideAndFade(
        from: CGPoint,
        to: CGPoint,
        duration: Double = 0.4
    ) -> ParallelAnimation {
        ParallelAnimation.builder()
            .animate("position", from: from, to: to, duration: duration, curve: .easeOut)
            .animate("opacity", from: 0.0, to: 1.0, duration: duration * 0.6, curve: .easeOut)
            .build()
    }

    /// A complex entrance animation (scale, rotate, fade).
    public static func entrance(duration: Double = 0.5) -> ParallelAnimation {
        ParallelAnimation.builder()
            .animate("scale", from: 0.5, to: 1.0, duration: duration, curve: .easeOutBack)
            .animate("rotation", from: -0.3, to: 0.0, duration: duration, curve: .easeOut)
            .animate("opacity", from: 0.0, to: 1.0, duration: duration * 0.5, curve: .easeOut)
            .build()
    }

    /// A pulse animation (scale up and fade in).
    public static func pulse(
        scale: Double = 1.2,
        duration: Double = 0.6
    ) -> ParallelAnimation {
        ParallelAnimation.builder()
            .animate("scale", from: 1.0, to: scale, duration: duration / 2, curve: .easeOut)
            .animate("opacity", from: 1.0, to: 0.5, duration: duration / 2, curve: .easeOut)
            .loop()
            .build()
    }
}

// MARK: - Group Animation Controller

/// A controller for managing multiple parallel animations with lifecycle control.
///
/// This is useful when you need to coordinate several parallel animations with
/// different durations and want unified control over all of them.
@MainActor
public struct AnimationGroup: Sendable, Hashable, Equatable {
    /// Named parallel animations in this group.
    private var animations: [String: ParallelAnimation]

    /// Whether all animations in the group are playing.
    private(set) public var isPlaying: Bool

    /// Creates an empty animation group.
    public init() {
        self.animations = [:]
        self.isPlaying = false
    }

    /// Adds a parallel animation to the group.
    public mutating func add(_ animation: ParallelAnimation, named: String) {
        animations[named] = animation
    }

    /// Removes an animation from the group.
    public mutating func remove(named: String) {
        animations.removeValue(forKey: named)
    }

    /// Plays all animations in the group.
    public mutating func playAll() {
        isPlaying = true
        for key in animations.keys {
            animations[key]?.play()
        }
    }

    /// Pauses all animations in the group.
    public mutating func pauseAll() {
        isPlaying = false
        for key in animations.keys {
            animations[key]?.pause()
        }
    }

    /// Stops all animations in the group.
    public mutating func stopAll() {
        isPlaying = false
        for key in animations.keys {
            animations[key]?.stop()
        }
    }

    /// Updates all animations in the group.
    public mutating func update(deltaTime: Double) {
        guard isPlaying else { return }

        for key in animations.keys {
            animations[key]?.update(deltaTime: deltaTime)
        }

        // Check if all animations are complete
        let allComplete = animations.values.allSatisfy { $0.isComplete }
        if allComplete {
            isPlaying = false
        }
    }

    /// Gets a value from a specific animation track.
    public func value<Value: AnimatableValue>(
        from animation: String,
        track: String
    ) -> Value? {
        animations[animation]?.value(for: track)
    }

    /// Gets all animation names in the group.
    public var animationNames: [String] {
        Array(animations.keys)
    }

    /// Whether all animations have completed.
    public var allComplete: Bool {
        animations.values.allSatisfy { $0.isComplete }
    }
}
