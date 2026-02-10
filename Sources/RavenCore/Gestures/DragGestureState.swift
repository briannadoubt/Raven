import Foundation

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
