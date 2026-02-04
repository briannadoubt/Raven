import Foundation

// MARK: - DragGesture

/// A gesture that recognizes a dragging motion and reports its value.
///
/// `DragGesture` detects when a user presses and drags their pointer across a view. The gesture
/// provides detailed information about the drag including location, translation, velocity, and
/// predicted end position. This makes it ideal for implementing interactive elements like sliders,
/// scrollable content, reorderable lists, and custom pan gestures.
///
/// ## Overview
///
/// A drag gesture begins when the user presses down and moves their pointer beyond a minimum
/// distance threshold. Once recognized, the gesture continuously reports updates as the user drags,
/// providing real-time position, velocity, and prediction data.
///
/// ## Basic Usage
///
/// Add a simple drag gesture to track movement:
///
/// ```swift
/// Rectangle()
///     .gesture(
///         DragGesture()
///             .onChanged { value in
///                 print("Dragging: \(value.translation)")
///             }
///             .onEnded { value in
///                 print("Drag ended at: \(value.location)")
///             }
///     )
/// ```
///
/// ## Minimum Distance
///
/// Control when the drag gesture begins by setting a minimum distance:
///
/// ```swift
/// // Requires 20 points of movement before recognizing
/// DragGesture(minimumDistance: 20)
///     .onChanged { value in
///         print("Dragging after 20pt threshold")
///     }
/// ```
///
/// The default minimum distance is 10 points, which provides a good balance between
/// responsiveness and preventing accidental drags.
///
/// ## Coordinate Spaces
///
/// Specify which coordinate space to use for locations:
///
/// ```swift
/// // Local coordinates (default) - relative to the view
/// DragGesture(coordinateSpace: .local)
///     .onChanged { value in
///         print("Local location: \(value.location)")
///     }
///
/// // Global coordinates - relative to the window
/// DragGesture(coordinateSpace: .global)
///     .onChanged { value in
///         print("Global location: \(value.location)")
///     }
///
/// // Named coordinate space - relative to an ancestor
/// DragGesture(coordinateSpace: .named("container"))
///     .onChanged { value in
///         print("In container: \(value.location)")
///     }
/// ```
///
/// ## Gesture State
///
/// Use `@GestureState` to track drag offset and automatically reset:
///
/// ```swift
/// struct DraggableView: View {
///     @GestureState private var dragOffset = CGSize.zero
///
///     var body: some View {
///         Circle()
///             .offset(dragOffset)
///             .gesture(
///                 DragGesture()
///                     .updating($dragOffset) { value, state, _ in
///                         state = value.translation
///                     }
///             )
///     }
/// }
/// ```
///
/// The `@GestureState` wrapper automatically resets `dragOffset` to zero when the drag ends.
///
/// ## Velocity and Prediction
///
/// Access velocity data to implement momentum-based interactions:
///
/// ```swift
/// DragGesture()
///     .onEnded { value in
///         let speed = sqrt(
///             value.velocity.width * value.velocity.width +
///             value.velocity.height * value.velocity.height
///         )
///         if speed > 1000 {
///             // Fast swipe detected - trigger action
///             print("Swipe detected!")
///         }
///
///         // Use predicted end location for animations
///         print("Will end at: \(value.predictedEndLocation)")
///     }
/// ```
///
/// ## Swipe Detection
///
/// Detect directional swipes by examining translation and velocity:
///
/// ```swift
/// DragGesture(minimumDistance: 50)
///     .onEnded { value in
///         let horizontal = abs(value.translation.width)
///         let vertical = abs(value.translation.height)
///
///         if horizontal > vertical {
///             if value.translation.width > 0 {
///                 print("Swiped right")
///             } else {
///                 print("Swiped left")
///             }
///         } else {
///             if value.translation.height > 0 {
///                 print("Swiped down")
///             } else {
///                 print("Swiped up")
///             }
///         }
///     }
/// ```
///
/// ## Web Implementation
///
/// In Raven's web environment, `DragGesture` maps to pointer events for cross-device support:
///
/// - **pointerdown**: Starts tracking the drag, records start position
/// - **pointermove**: Updates drag position, calculates translation and velocity
/// - **pointerup**: Ends the drag, provides final values
/// - **pointercancel**: Cancels the drag (e.g., system gesture takes over)
///
/// Pointer events provide unified handling for:
/// - Mouse input (desktop)
/// - Touch input (mobile/tablet)
/// - Pen/stylus input (drawing tablets)
///
/// ### Velocity Calculation
///
/// Velocity is calculated by tracking recent position samples. The implementation maintains
/// a rolling window of the last 5-10 samples over approximately 100ms, computing velocity
/// as the average delta per second. This approach provides smooth velocity values that work
/// well for momentum calculations and swipe detection.
///
/// ### Predicted End Position
///
/// The predicted end position uses the current velocity and applies a standard friction model
/// to estimate where the drag would naturally come to rest. This is useful for:
/// - Momentum scrolling
/// - Throwing/flicking gestures
/// - Predictive animations
///
/// ## Combining with Other Gestures
///
/// Combine drag gestures with other gestures for complex interactions:
///
/// ```swift
/// Rectangle()
///     .gesture(
///         DragGesture()
///             .simultaneously(with: MagnificationGesture())
///     )
/// ```
///
/// This allows simultaneous dragging and scaling, common in photo viewers and maps.
///
/// ## Performance Considerations
///
/// - Drag gestures fire frequently during movement - keep handlers lightweight
/// - Use `updating(_:body:)` instead of `onChanged` when possible for better performance
/// - Consider debouncing or throttling expensive operations triggered by drag updates
/// - Velocity calculation is optimized to use a small rolling window
///
/// ## Accessibility
///
/// When using drag gestures:
/// - Provide keyboard alternatives for drag-based interactions
/// - Ensure draggable elements are large enough (minimum 44x44 points)
/// - Add appropriate ARIA labels for screen readers
/// - Consider providing haptic feedback on mobile devices
///
/// ## Thread Safety
///
/// `DragGesture` and its `Value` type are `@MainActor` isolated and `Sendable`, ensuring
/// thread-safe usage in Swift's strict concurrency model. All gesture callbacks and updates
/// execute on the main actor.
///
/// ## See Also
///
/// - ``DragGesture/Value``
/// - ``LongPressGesture``
/// - ``MagnificationGesture``
/// - ``RotationGesture``
/// - ``GestureState``
@MainActor
public struct DragGesture: Gesture, Sendable {
    /// The body type for this gesture.
    ///
    /// This is a primitive gesture with no body composition.
    public typealias Body = Never

    /// The minimum dragging distance before the gesture succeeds.
    ///
    /// The user must drag at least this many points from the starting position before
    /// the drag gesture is recognized. This helps distinguish drags from taps and prevents
    /// accidental drag initiation. The default value is 10 points.
    ///
    /// Distance is calculated as the straight-line distance from the start point:
    /// `distance = sqrt((x2 - x1)² + (y2 - y1)²)`
    public let minimumDistance: Double

    /// The coordinate space in which to report drag locations.
    ///
    /// Determines how locations are calculated:
    /// - `.local`: Relative to the view's own bounds (default)
    /// - `.global`: Relative to the window/document
    /// - `.named(String)`: Relative to an ancestor view with matching name
    public let coordinateSpace: CoordinateSpace

    /// Creates a drag gesture with the default minimum distance.
    ///
    /// The gesture uses a minimum distance of 10 points and reports locations in
    /// the local coordinate space.
    ///
    /// Example:
    /// ```swift
    /// DragGesture()
    ///     .onChanged { value in
    ///         print("Dragging: \(value.translation)")
    ///     }
    /// ```
    public init() {
        self.minimumDistance = 10.0
        self.coordinateSpace = .local
    }

    /// Creates a drag gesture with a custom minimum distance.
    ///
    /// Use this initializer to control how far the user must drag before recognition.
    /// The coordinate space defaults to `.local`.
    ///
    /// Example:
    /// ```swift
    /// DragGesture(minimumDistance: 20)
    ///     .onChanged { value in
    ///         print("Dragging after 20pt threshold")
    ///     }
    /// ```
    ///
    /// - Parameter minimumDistance: The minimum drag distance in points. Must be non-negative.
    ///   Values less than 0 will be clamped to 0.
    public init(minimumDistance: Double) {
        self.minimumDistance = max(0.0, minimumDistance)
        self.coordinateSpace = .local
    }

    /// Creates a drag gesture with a custom coordinate space.
    ///
    /// Use this initializer to specify which coordinate space to use for locations.
    /// The minimum distance defaults to 10 points.
    ///
    /// Example:
    /// ```swift
    /// DragGesture(coordinateSpace: .global)
    ///     .onChanged { value in
    ///         print("Global location: \(value.location)")
    ///     }
    /// ```
    ///
    /// - Parameter coordinateSpace: The coordinate space for locations.
    public init(coordinateSpace: CoordinateSpace) {
        self.minimumDistance = 10.0
        self.coordinateSpace = coordinateSpace
    }

    /// Creates a drag gesture with custom parameters.
    ///
    /// Use this initializer to fully customize both minimum distance and coordinate space.
    ///
    /// Example:
    /// ```swift
    /// DragGesture(minimumDistance: 20, coordinateSpace: .named("canvas"))
    ///     .onChanged { value in
    ///         print("Dragging in canvas: \(value.translation)")
    ///     }
    /// ```
    ///
    /// - Parameters:
    ///   - minimumDistance: The minimum drag distance in points. Must be non-negative.
    ///     Values less than 0 will be clamped to 0.
    ///   - coordinateSpace: The coordinate space for locations.
    public init(minimumDistance: Double, coordinateSpace: CoordinateSpace) {
        self.minimumDistance = max(0.0, minimumDistance)
        self.coordinateSpace = coordinateSpace
    }
}

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

// MARK: - Web Event Mapping

extension DragGesture {
    /// The web event names used for drag gesture recognition.
    ///
    /// Drag gestures use pointer events for comprehensive device support:
    /// - `pointerdown`: Initiates drag tracking
    /// - `pointermove`: Updates drag position
    /// - `pointerup`: Completes the drag
    /// - `pointercancel`: Cancels the drag
    internal struct EventNames {
        static let down = "pointerdown"
        static let move = "pointermove"
        static let up = "pointerup"
        static let cancel = "pointercancel"
    }

    /// Extracts the drag location from pointer event coordinates.
    ///
    /// This method transforms raw viewport coordinates into the requested coordinate space.
    ///
    /// - Parameters:
    ///   - clientX: The X coordinate in viewport space.
    ///   - clientY: The Y coordinate in viewport space.
    ///   - elementBounds: The bounds of the target element.
    ///   - namedAncestorBounds: The bounds of a named ancestor (if applicable).
    /// - Returns: A CGPoint in the requested coordinate space.
    internal func extractLocation(
        clientX: Double,
        clientY: Double,
        elementBounds: CGRect,
        namedAncestorBounds: CGRect? = nil
    ) -> CGPoint {
        switch coordinateSpace {
        case .local:
            return CGPoint(
                x: clientX - elementBounds.minX,
                y: clientY - elementBounds.minY
            )
        case .global:
            return CGPoint(x: clientX, y: clientY)
        case .named:
            if let ancestorBounds = namedAncestorBounds {
                return CGPoint(
                    x: clientX - ancestorBounds.minX,
                    y: clientY - ancestorBounds.minY
                )
            } else {
                // Fallback to global if named ancestor not found
                return CGPoint(x: clientX, y: clientY)
            }
        }
    }
}

// MARK: - Gesture Recognition State

/// The state of gesture recognition.
///
/// This enum represents the lifecycle of a gesture as it progresses from initial
/// detection through completion or cancellation. The state machine ensures gestures
/// only fire callbacks after proper recognition.
///
/// ## State Transitions
///
/// Normal flow:
/// ```
/// .possible -> .began -> .changed -> .ended
/// ```
///
/// Cancellation flow:
/// ```
/// .possible -> .cancelled (gesture failed to recognize)
/// .began -> .cancelled (gesture interrupted)
/// .changed -> .cancelled (gesture interrupted)
/// ```
///
/// Failure flow:
/// ```
/// .possible -> .failed (gesture recognition failed)
/// ```
public enum GestureRecognitionState: Sendable {
    /// The gesture might happen but hasn't been recognized yet.
    ///
    /// This is the initial state when touch/pointer begins. The system is tracking
    /// movement but hasn't yet determined if this will become a recognized gesture.
    /// No callbacks are fired in this state.
    case possible

    /// The gesture has been recognized and is starting.
    ///
    /// Transition to this state occurs when the gesture's recognition criteria are met
    /// (e.g., minimum distance threshold for drag). The first `onChanged` callback
    /// fires when entering this state.
    case began

    /// The gesture is actively ongoing.
    ///
    /// After `.began`, subsequent updates transition to `.changed`. The `onChanged`
    /// callback fires for each update while in this state.
    case changed

    /// The gesture completed successfully.
    ///
    /// The user released the pointer/touch and the gesture finished normally.
    /// The `onEnded` callback fires when entering this state.
    case ended

    /// The gesture was interrupted or cancelled.
    ///
    /// This occurs when:
    /// - The pointer leaves the window or element
    /// - The escape key is pressed
    /// - Another gesture wins priority
    /// - A system gesture takes over
    ///
    /// The `onEnded` callback may fire with the last known state.
    case cancelled

    /// The gesture recognition failed.
    ///
    /// The gesture started tracking but failed to meet recognition criteria
    /// and won't proceed further. No callbacks fire for failed gestures.
    case failed
}

// MARK: - Internal State

/// Internal state for tracking an active drag gesture.
///
/// This structure maintains the state needed during drag recognition, including position
/// history for velocity calculation and timing information.
@MainActor
public struct DragGestureState: Sendable {
    /// Position sample for velocity calculation.
    public struct PositionSample: Sendable {
        public var location: CGPoint
        public var time: Double
    }

    /// The starting location of the drag.
    public var startLocation: CGPoint

    /// The time when the drag started.
    public var startTime: Double

    /// The minimum distance threshold for recognition.
    public let minimumDistance: Double

    /// The current recognition state of the gesture.
    public var recognitionState: GestureRecognitionState

    /// Whether the gesture has been recognized (passed minimum distance).
    @available(*, deprecated, message: "Use recognitionState instead")
    public var isRecognized: Bool {
        get {
            recognitionState == .began || recognitionState == .changed || recognitionState == .ended
        }
        set {
            if newValue && recognitionState == .possible {
                recognitionState = .began
            }
        }
    }

    /// Recent position samples for velocity calculation (rolling window).
    public var positionSamples: [PositionSample]

    /// Maximum number of samples to keep for velocity calculation.
    public static let maxSamples = 10

    /// Time window for velocity calculation (in seconds).
    public static let velocityWindow: Double = 0.1 // 100ms

    /// Friction coefficient for predicted end position (0.0 to 1.0).
    /// Higher values = more friction = shorter momentum.
    public static let frictionCoefficient: Double = 0.92

    /// Creates a new drag gesture state.
    ///
    /// - Parameters:
    ///   - startLocation: The initial drag location.
    ///   - startTime: The time when the drag began.
    ///   - minimumDistance: The minimum distance threshold.
    public init(
        startLocation: CGPoint,
        startTime: Double,
        minimumDistance: Double
    ) {
        self.startLocation = startLocation
        self.startTime = startTime
        self.minimumDistance = minimumDistance
        self.recognitionState = .possible
        self.positionSamples = [PositionSample(location: startLocation, time: startTime)]
    }

    /// Checks whether the minimum distance has been exceeded.
    ///
    /// - Parameter currentLocation: The current drag location.
    /// - Returns: `true` if the drag has moved beyond the minimum distance.
    public func hasExceededMinimumDistance(to currentLocation: CGPoint) -> Bool {
        let dx = currentLocation.x - startLocation.x
        let dy = currentLocation.y - startLocation.y
        let distance = sqrt(dx * dx + dy * dy)
        return distance >= minimumDistance
    }

    /// Adds a new position sample and maintains the rolling window.
    ///
    /// - Parameters:
    ///   - location: The current drag location.
    ///   - time: The current time.
    public mutating func addSample(location: CGPoint, time: Double) {
        positionSamples.append(PositionSample(location: location, time: time))

        // Remove old samples outside the velocity window
        let cutoffTime = time - Self.velocityWindow
        positionSamples.removeAll { $0.time < cutoffTime }

        // Limit total samples
        if positionSamples.count > Self.maxSamples {
            positionSamples.removeFirst(positionSamples.count - Self.maxSamples)
        }
    }

    /// Calculates the current velocity from position samples.
    ///
    /// Velocity is computed as the average change in position over time using all samples
    /// in the rolling window.
    ///
    /// - Returns: The velocity in points per second.
    public func calculateVelocity() -> CGSize {
        guard positionSamples.count >= 2 else {
            return CGSize(width: 0, height: 0)
        }

        let first = positionSamples.first!
        let last = positionSamples.last!

        let deltaTime = last.time - first.time
        guard deltaTime > 0 else {
            return CGSize(width: 0, height: 0)
        }

        let deltaX = last.location.x - first.location.x
        let deltaY = last.location.y - first.location.y

        return CGSize(
            width: deltaX / deltaTime,
            height: deltaY / deltaTime
        )
    }

    /// Predicts the end location based on current velocity and friction.
    ///
    /// Uses a simple deceleration model where velocity decreases exponentially with friction.
    ///
    /// - Parameters:
    ///   - currentLocation: The current drag location.
    ///   - velocity: The current velocity.
    /// - Returns: The predicted end location.
    public func predictEndLocation(from currentLocation: CGPoint, velocity: CGSize) -> CGPoint {
        // If velocity is very small, predict current location
        let speed = sqrt(velocity.width * velocity.width + velocity.height * velocity.height)
        guard speed > 10 else {
            return currentLocation
        }

        // Calculate how far the drag will travel with friction
        // Using geometric series sum for exponential decay:
        // distance = velocity / (1 - friction)
        let frictionFactor = 1.0 - Self.frictionCoefficient
        let travelX = velocity.width / frictionFactor / 60.0 // Assuming 60fps
        let travelY = velocity.height / frictionFactor / 60.0

        return CGPoint(
            x: currentLocation.x + travelX,
            y: currentLocation.y + travelY
        )
    }
}

// MARK: - Gesture Modifiers

extension DragGesture {
    /// Adds an action to perform when the drag gesture changes.
    ///
    /// The action is called continuously as the user drags, providing updated values
    /// with current position, velocity, and prediction information.
    ///
    /// Example:
    /// ```swift
    /// DragGesture()
    ///     .onChanged { value in
    ///         print("Dragging: \(value.translation)")
    ///     }
    /// ```
    ///
    /// - Parameter action: The action to perform with each drag update.
    /// - Returns: A gesture with the action attached.
    public func onChanged(
        _ action: @escaping @MainActor @Sendable (Value) -> Void
    ) -> _ModifiedGesture<DragGesture, _ChangedGestureModifier<Value>> {
        _ModifiedGesture(
            gesture: self,
            modifier: _ChangedGestureModifier(action: action)
        )
    }

    /// Adds an action to perform when the drag gesture ends.
    ///
    /// The action is called once when the user releases the drag, providing final
    /// values including velocity and predicted end position.
    ///
    /// Example:
    /// ```swift
    /// DragGesture()
    ///     .onEnded { value in
    ///         print("Drag ended: \(value.translation)")
    ///         print("Final velocity: \(value.velocity)")
    ///     }
    /// ```
    ///
    /// - Parameter action: The action to perform when the gesture ends.
    /// - Returns: A gesture with the action attached.
    public func onEnded(
        _ action: @escaping @MainActor @Sendable (Value) -> Void
    ) -> _ModifiedGesture<DragGesture, _EndedGestureModifier<Value>> {
        _ModifiedGesture(
            gesture: self,
            modifier: _EndedGestureModifier(action: action)
        )
    }

    /// Updates gesture state values as the gesture changes.
    ///
    /// Use this modifier with `@GestureState` to track the gesture's progress.
    /// The gesture state automatically resets when the gesture ends or cancels.
    ///
    /// Example:
    /// ```swift
    /// @GestureState private var dragOffset = CGSize.zero
    ///
    /// DragGesture()
    ///     .updating($dragOffset) { value, state, transaction in
    ///         state = value.translation
    ///     }
    /// ```
    ///
    /// - Parameters:
    ///   - state: A binding to gesture state that will be updated.
    ///   - body: A closure that updates the gesture state. It receives the current
    ///     gesture value, an inout parameter for the gesture state, and a transaction.
    /// - Returns: A gesture that updates the provided state.
    public func updating<State>(
        _ state: GestureState<State>,
        body: @escaping @MainActor @Sendable (Value, inout State, inout Transaction) -> Void
    ) -> _ModifiedGesture<DragGesture, _UpdatingGestureModifier<State, Value>> {
        _ModifiedGesture(
            gesture: self,
            modifier: _UpdatingGestureModifier(state: state, body: body)
        )
    }
}

// MARK: - Documentation Examples

/*
 Example: Draggable card

 ```swift
 struct DraggableCard: View {
     @State private var offset = CGSize.zero

     var body: some View {
         RoundedRectangle(cornerRadius: 20)
             .fill(.blue)
             .frame(width: 300, height: 400)
             .offset(offset)
             .gesture(
                 DragGesture()
                     .onChanged { value in
                         offset = value.translation
                     }
                     .onEnded { value in
                         // Snap back or dismiss based on velocity
                         if abs(value.velocity.width) > 500 {
                             // Dismiss card
                             offset = CGSize(
                                 width: value.velocity.width > 0 ? 1000 : -1000,
                                 height: 0
                             )
                         } else {
                             // Snap back
                             withAnimation(.spring()) {
                                 offset = .zero
                             }
                         }
                     }
             )
     }
 }
 ```

 Example: Custom slider

 ```swift
 struct CustomSlider: View {
     @State private var value: Double = 0.5
     let width: Double = 300

     var body: some View {
         GeometryReader { geometry in
             ZStack(alignment: .leading) {
                 // Track
                 Rectangle()
                     .fill(.gray.opacity(0.3))
                     .frame(height: 4)

                 // Thumb
                 Circle()
                     .fill(.blue)
                     .frame(width: 30, height: 30)
                     .offset(x: value * (width - 30))
                     .gesture(
                         DragGesture(coordinateSpace: .local)
                             .onChanged { gesture in
                                 let newValue = gesture.location.x / (width - 30)
                                 value = min(max(newValue, 0), 1)
                             }
                     )
             }
         }
         .frame(width: width, height: 30)
     }
 }
 ```

 Example: Swipe to delete

 ```swift
 struct SwipeToDelete: View {
     @State private var offset: CGFloat = 0
     @State private var isDeleted = false

     var body: some View {
         if !isDeleted {
             HStack {
                 Text("Swipe to delete")
                     .padding()
                     .background(.white)
                     .offset(x: offset)
                     .gesture(
                         DragGesture()
                             .onChanged { value in
                                 // Only allow swiping left
                                 if value.translation.width < 0 {
                                     offset = value.translation.width
                                 }
                             }
                             .onEnded { value in
                                 if offset < -100 {
                                     // Delete threshold reached
                                     withAnimation {
                                         isDeleted = true
                                     }
                                 } else {
                                     // Snap back
                                     withAnimation(.spring()) {
                                         offset = 0
                                     }
                                 }
                             }
                     )

                 Spacer()

                 // Delete button revealed by swipe
                 Button(action: {
                     withAnimation {
                         isDeleted = true
                     }
                 }) {
                     Image(systemName: "trash")
                         .foregroundColor(.white)
                 }
                 .padding()
                 .background(.red)
             }
         }
     }
 }
 ```
 */
