import Foundation

// MARK: - DragGesture.Value

extension DragGesture {
    /// The value produced by a drag gesture.
    ///
    /// This structure contains comprehensive information about the current state of a drag,
    /// including position, movement, velocity, and prediction data.
    ///
    /// ## Overview
    ///
    /// A `DragGesture.Value` is produced continuously as the user drags, providing real-time
    /// feedback about the drag state. The value includes:
    ///
    /// - **Position data**: `location`, `startLocation`
    /// - **Movement data**: `translation`
    /// - **Velocity data**: `velocity`
    /// - **Prediction data**: `predictedEndLocation`, `predictedEndTranslation`
    /// - **Timing data**: `time`
    ///
    /// ## Translation
    ///
    /// The translation represents the offset from the starting position:
    ///
    /// ```swift
    /// translation.width = location.x - startLocation.x
    /// translation.height = location.y - startLocation.y
    /// ```
    ///
    /// Translation is useful for implementing drag-to-move interactions:
    ///
    /// ```swift
    /// @GestureState private var dragOffset = CGSize.zero
    ///
    /// Circle()
    ///     .offset(dragOffset)
    ///     .gesture(
    ///         DragGesture()
    ///             .updating($dragOffset) { value, state, _ in
    ///                 state = value.translation
    ///             }
    ///     )
    /// ```
    ///
    /// ## Velocity
    ///
    /// Velocity is measured in points per second and indicates how fast the drag is moving:
    ///
    /// ```swift
    /// // Horizontal velocity (points/second)
    /// let horizontalSpeed = value.velocity.width
    ///
    /// // Vertical velocity (points/second)
    /// let verticalSpeed = value.velocity.height
    ///
    /// // Total speed
    /// let speed = sqrt(
    ///     horizontalSpeed * horizontalSpeed +
    ///     verticalSpeed * verticalSpeed
    /// )
    /// ```
    ///
    /// Use velocity for:
    /// - Detecting swipes (high velocity)
    /// - Implementing momentum scrolling
    /// - Adding physics-based animations
    ///
    /// ## Predicted End Position
    ///
    /// The predicted end position estimates where the drag would naturally come to rest
    /// based on current velocity and a friction model:
    ///
    /// ```swift
    /// DragGesture()
    ///     .onEnded { value in
    ///         withAnimation(.spring()) {
    ///             // Animate to predicted position
    ///             position = value.predictedEndLocation
    ///         }
    ///     }
    /// ```
    ///
    /// ## Time
    ///
    /// The `time` property records when each drag update occurred, useful for custom
    /// velocity calculations or time-based animations.
    ///
    /// ## Thread Safety
    ///
    /// `DragGesture.Value` is `@MainActor` isolated and `Sendable`, ensuring safe usage
    /// across concurrency contexts.
    ///
    /// ## See Also
    ///
    /// - ``DragGesture``
    /// - ``CGPoint``
    /// - ``CGSize``
    public struct Value: Sendable {
        /// The current location of the drag in the gesture's coordinate space.
        ///
        /// This is the current pointer position, reported in the coordinate space specified
        /// when creating the drag gesture (local, global, or named).
        public var location: CGPoint

        /// The location where the drag started.
        ///
        /// This is the initial pointer position where the user first pressed down, reported
        /// in the same coordinate space as `location`.
        public var startLocation: CGPoint

        /// The total translation from the start of the drag.
        ///
        /// Calculated as:
        /// - `width = location.x - startLocation.x`
        /// - `height = location.y - startLocation.y`
        ///
        /// Positive width means dragging right, negative means dragging left.
        /// Positive height means dragging down, negative means dragging up.
        public var translation: CGSize {
            CGSize(
                width: location.x - startLocation.x,
                height: location.y - startLocation.y
            )
        }

        /// The current velocity of the drag, in points per second.
        ///
        /// Velocity is calculated from recent position samples. Positive values indicate
        /// movement to the right (width) or down (height). Negative values indicate
        /// movement to the left or up.
        ///
        /// The magnitude of velocity can be used to detect swipes:
        /// ```swift
        /// let speed = sqrt(
        ///     velocity.width * velocity.width +
        ///     velocity.height * velocity.height
        /// )
        /// if speed > 1000 {
        ///     // Fast swipe detected
        /// }
        /// ```
        public var velocity: CGSize

        /// The predicted end location based on current velocity and friction.
        ///
        /// This estimates where the drag would naturally come to rest if the user released
        /// at this moment, assuming a standard friction model. Useful for momentum scrolling
        /// and throw gestures.
        public var predictedEndLocation: CGPoint

        /// The predicted end translation based on current velocity and friction.
        ///
        /// Calculated as `predictedEndLocation - startLocation`, this represents the total
        /// translation if the drag were released now with momentum.
        public var predictedEndTranslation: CGSize {
            CGSize(
                width: predictedEndLocation.x - startLocation.x,
                height: predictedEndLocation.y - startLocation.y
            )
        }

        /// The timestamp of this drag value.
        ///
        /// Records when this position was sampled, useful for custom timing calculations
        /// or animations.
        public var time: Date

        /// Creates a drag gesture value with the specified parameters.
        ///
        /// This initializer is primarily used internally by the gesture recognition system,
        /// but can be used for testing or manual gesture value creation.
        ///
        /// - Parameters:
        ///   - location: The current drag location.
        ///   - startLocation: The starting location.
        ///   - velocity: The current velocity in points per second.
        ///   - predictedEndLocation: The predicted end location.
        ///   - time: The timestamp of this value. Defaults to the current time.
        public init(
            location: CGPoint,
            startLocation: CGPoint,
            velocity: CGSize = CGSize(width: 0, height: 0),
            predictedEndLocation: CGPoint? = nil,
            time: Date = Date()
        ) {
            self.location = location
            self.startLocation = startLocation
            self.velocity = velocity
            self.predictedEndLocation = predictedEndLocation ?? location
            self.time = time
        }
    }
}

// MARK: - DragGesture.Value Equatable

extension DragGesture.Value: Equatable {
    /// Equality comparison for drag values.
    ///
    /// Two drag values are equal if all their properties match, except time which
    /// uses approximate comparison (within 0.001 seconds).
    nonisolated public static func == (lhs: DragGesture.Value, rhs: DragGesture.Value) -> Bool {
        let locationsEqual = lhs.location == rhs.location
        let startLocationsEqual = lhs.startLocation == rhs.startLocation
        let velocitiesEqual = lhs.velocity == rhs.velocity
        let predictedLocationsEqual = lhs.predictedEndLocation == rhs.predictedEndLocation
        let timeDiff = abs(lhs.time.timeIntervalSince1970 - rhs.time.timeIntervalSince1970)
        let timesEqual = timeDiff < 0.001

        return locationsEqual && startLocationsEqual && velocitiesEqual && predictedLocationsEqual && timesEqual
    }
}
