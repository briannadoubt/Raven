import Foundation

// MARK: - LongPressGesture

/// A gesture that recognizes a long press interaction.
///
/// `LongPressGesture` detects when a user presses and holds on a view for a minimum duration
/// without moving beyond a maximum distance threshold. This gesture is commonly used for
/// context menus, editing modes, and other interactions that require deliberate user intent.
///
/// ## Overview
///
/// The long press gesture begins when the user presses down on a view. If the user maintains
/// the press for at least the specified `minimumDuration` without moving more than the
/// `maximumDistance`, the gesture succeeds and produces a value of `true`.
///
/// ## Basic Usage
///
/// Add a long press gesture to a view:
///
/// ```swift
/// Text("Long press me")
///     .gesture(
///         LongPressGesture()
///             .onEnded { _ in
///                 print("Long pressed!")
///             }
///     )
/// ```
///
/// ## Customizing Duration
///
/// Adjust the minimum hold duration:
///
/// ```swift
/// Rectangle()
///     .gesture(
///         LongPressGesture(minimumDuration: 2.0)
///             .onEnded { _ in
///                 print("Held for 2 seconds!")
///             }
///     )
/// ```
///
/// ## Customizing Movement Tolerance
///
/// Control how far the user can move before the gesture cancels:
///
/// ```swift
/// Circle()
///     .gesture(
///         LongPressGesture(minimumDuration: 1.0, maximumDistance: 5)
///             .onEnded { pressed in
///                 print("Long pressed: \(pressed)")
///             }
///     )
/// ```
///
/// ## Gesture Value
///
/// The gesture produces a `Bool` value:
/// - `true`: The long press succeeded after the minimum duration
/// - The gesture only completes with `true` (cancellations don't produce values)
///
/// ## Tracking Progress
///
/// Use `@GestureState` to track whether a long press is in progress:
///
/// ```swift
/// struct ContentView: View {
///     @GestureState private var isDetectingLongPress = false
///
///     var body: some View {
///         Circle()
///             .fill(isDetectingLongPress ? Color.red : Color.blue)
///             .gesture(
///                 LongPressGesture(minimumDuration: 1.0)
///                     .updating($isDetectingLongPress) { currentState, gestureState, _ in
///                         gestureState = currentState
///                     }
///                     .onEnded { _ in
///                         print("Long press recognized!")
///                     }
///             )
///     }
/// }
/// ```
///
/// ## Web Implementation
///
/// In Raven's web environment, long press gestures map to pointer events:
///
/// - **pointerdown**: Starts the gesture and begins timing
/// - **pointermove**: Monitors movement distance from start position
/// - **pointerup**: Ends the gesture (success if duration threshold met)
/// - **pointercancel**: Cancels the gesture (e.g., scrolling starts)
///
/// The gesture uses `setTimeout` for duration tracking and calculates distance using
/// the Pythagorean theorem. Pointer events are used instead of mouse/touch events for
/// better cross-device support (mouse, touch, pen, etc.).
///
/// ## Cancellation Behavior
///
/// The gesture cancels if:
/// - The user releases before `minimumDuration` elapses
/// - The user moves more than `maximumDistance` from the starting point
/// - A system event interrupts (e.g., phone call, notification)
/// - The pointer is cancelled (e.g., scrolling begins)
///
/// ## Combining with Other Gestures
///
/// Long press can be combined with other gestures using gesture composition:
///
/// ```swift
/// Rectangle()
///     .gesture(
///         LongPressGesture()
///             .sequenced(before: DragGesture())
///     )
/// ```
///
/// This creates a gesture that requires a long press before dragging begins.
///
/// ## Performance Considerations
///
/// - Timer cleanup is automatic when the gesture ends or cancels
/// - Movement calculations are optimized to avoid unnecessary computation
/// - Event listeners are properly managed to prevent memory leaks
///
/// ## Accessibility
///
/// Long press gestures should be paired with alternative interaction methods for accessibility.
/// Consider providing:
/// - Button alternatives with explicit labels
/// - Keyboard shortcuts
/// - Voice control options
///
/// ## See Also
///
/// - ``TapGesture``
/// - ``DragGesture``
/// - ``GestureState``
/// - ``Gesture``
@MainActor
public struct LongPressGesture: Gesture, Sendable {
    /// The type of value produced by this gesture.
    ///
    /// Long press gestures produce a `Bool` value indicating successful recognition.
    /// The value is always `true` when the gesture completes successfully.
    public typealias Value = Bool

    /// The body type for this gesture.
    ///
    /// This is a primitive gesture with no body composition.
    public typealias Body = Never

    /// The minimum duration the user must hold the press, in seconds.
    ///
    /// The default value is 0.5 seconds. This matches SwiftUI's default long press duration.
    /// Values should be positive; negative or zero values will be clamped to a minimum
    /// of 0.01 seconds.
    public let minimumDuration: Double

    /// The maximum distance in points the user can move before the gesture cancels.
    ///
    /// The default value is 10 points. This provides a reasonable tolerance for hand tremor
    /// and minor movements while still ensuring deliberate intent. Distance is calculated
    /// as the straight-line distance from the initial press location.
    public let maximumDistance: Double

    /// Creates a long press gesture with the default minimum duration.
    ///
    /// The gesture uses the default minimum duration of 0.5 seconds and maximum distance
    /// of 10 points.
    ///
    /// Example:
    /// ```swift
    /// LongPressGesture()
    ///     .onEnded { _ in
    ///         print("Long press detected")
    ///     }
    /// ```
    public init() {
        self.minimumDuration = 0.5
        self.maximumDistance = 10.0
    }

    /// Creates a long press gesture with a custom minimum duration.
    ///
    /// Use this initializer to specify how long the user must hold the press.
    /// The maximum distance defaults to 10 points.
    ///
    /// Example:
    /// ```swift
    /// LongPressGesture(minimumDuration: 2.0)
    ///     .onEnded { _ in
    ///         print("Held for 2 seconds")
    ///     }
    /// ```
    ///
    /// - Parameter minimumDuration: The minimum duration in seconds. Must be positive.
    ///   Values less than 0.01 will be clamped to 0.01.
    public init(minimumDuration: Double) {
        self.minimumDuration = max(0.01, minimumDuration)
        self.maximumDistance = 10.0
    }

    /// Creates a long press gesture with custom duration and distance parameters.
    ///
    /// Use this initializer to fully customize the gesture recognition thresholds.
    ///
    /// Example:
    /// ```swift
    /// LongPressGesture(minimumDuration: 1.0, maximumDistance: 5)
    ///     .onEnded { _ in
    ///         print("Held for 1 second within 5 points")
    ///     }
    /// ```
    ///
    /// - Parameters:
    ///   - minimumDuration: The minimum duration in seconds. Must be positive.
    ///     Values less than 0.01 will be clamped to 0.01.
    ///   - maximumDistance: The maximum movement distance in points. Must be positive.
    ///     Values less than 0 will be clamped to 0.
    public init(minimumDuration: Double, maximumDistance: Double) {
        self.minimumDuration = max(0.01, minimumDuration)
        self.maximumDistance = max(0.0, maximumDistance)
    }
}

// MARK: - Internal State

/// Internal state tracking for long press gesture recognition.
///
/// This structure maintains the state needed to track an active long press gesture,
/// including the start position, timing information, and whether the gesture has
/// completed successfully.
@MainActor
internal struct LongPressGestureState: Sendable {
    /// The starting point of the gesture in client coordinates.
    var startPoint: CGPoint

    /// The time when the gesture started, as a Unix timestamp in seconds.
    var startTime: Double

    /// The minimum duration required for gesture success, in seconds.
    let minimumDuration: Double

    /// The maximum allowed movement distance in points.
    let maximumDistance: Double

    /// Whether the gesture has completed successfully.
    var hasCompleted: Bool

    /// Creates a new gesture state with the specified parameters.
    ///
    /// - Parameters:
    ///   - startPoint: The initial pointer position.
    ///   - startTime: The time when the gesture began.
    ///   - minimumDuration: The minimum hold duration.
    ///   - maximumDistance: The maximum movement threshold.
    init(
        startPoint: CGPoint,
        startTime: Double,
        minimumDuration: Double,
        maximumDistance: Double
    ) {
        self.startPoint = startPoint
        self.startTime = startTime
        self.minimumDuration = minimumDuration
        self.maximumDistance = maximumDistance
        self.hasCompleted = false
    }

    /// Checks whether the gesture should cancel based on current pointer position.
    ///
    /// The gesture cancels if the pointer has moved beyond the maximum distance threshold.
    /// Distance is calculated using the Pythagorean theorem:
    /// `distance = sqrt((x2 - x1)² + (y2 - y1)²)`
    ///
    /// - Parameter currentPoint: The current pointer position.
    /// - Returns: `true` if the gesture should cancel, `false` otherwise.
    func shouldCancel(at currentPoint: CGPoint) -> Bool {
        let dx = currentPoint.x - startPoint.x
        let dy = currentPoint.y - startPoint.y
        let distance = sqrt(dx * dx + dy * dy)
        return distance > maximumDistance
    }

    /// Checks whether the minimum duration has elapsed.
    ///
    /// - Parameter currentTime: The current time as a Unix timestamp in seconds.
    /// - Returns: `true` if the minimum duration has been met, `false` otherwise.
    func hasMetDuration(at currentTime: Double) -> Bool {
        return currentTime - startTime >= minimumDuration
    }
}

// MARK: - Gesture Modifiers

extension LongPressGesture {
    /// Adds an action to perform when the long press gesture ends successfully.
    ///
    /// The action is called with the gesture's value (always `true` for successful completion)
    /// when the user has held the press for at least the minimum duration without exceeding
    /// the maximum movement distance.
    ///
    /// Example:
    /// ```swift
    /// LongPressGesture()
    ///     .onEnded { success in
    ///         print("Long press ended: \(success)")
    ///     }
    /// ```
    ///
    /// - Parameter action: The action to perform when the gesture ends successfully.
    /// - Returns: A gesture with the action attached.
    public func onEnded(
        _ action: @escaping @MainActor @Sendable (Value) -> Void
    ) -> _ModifiedGesture<LongPressGesture, _EndedGestureModifier<Value>> {
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
    /// @GestureState private var isPressed = false
    ///
    /// LongPressGesture()
    ///     .updating($isPressed) { current, state, transaction in
    ///         state = current
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
    ) -> _ModifiedGesture<LongPressGesture, _UpdatingGestureModifier<State, Value>> {
        _ModifiedGesture(
            gesture: self,
            modifier: _UpdatingGestureModifier(state: state, body: body)
        )
    }
}

// MARK: - Placeholder Modifier Types

/// A gesture that has been modified with additional behavior.
///
/// This is a placeholder implementation for gesture composition. A full implementation
/// would integrate with the view system to attach event handlers.
@MainActor
public struct _ModifiedGesture<G: Gesture, M: Sendable>: Gesture {
    public typealias Value = G.Value
    public typealias Body = Never

    public let gesture: G
    public let modifier: M

    public init(gesture: G, modifier: M) {
        self.gesture = gesture
        self.modifier = modifier
    }
}

/// A modifier that adds an onEnded action to a gesture.
@MainActor
public struct _EndedGestureModifier<Value: Sendable>: Sendable {
    public let action: @MainActor @Sendable (Value) -> Void

    public init(action: @escaping @MainActor @Sendable (Value) -> Void) {
        self.action = action
    }
}

/// A modifier that updates gesture state as a gesture changes.
@MainActor
public struct _UpdatingGestureModifier<State: Sendable, Value: Sendable>: Sendable {
    public let state: GestureState<State>
    public let body: @MainActor @Sendable (Value, inout State, inout Transaction) -> Void

    public init(
        state: GestureState<State>,
        body: @escaping @MainActor @Sendable (Value, inout State, inout Transaction) -> Void
    ) {
        self.state = state
        self.body = body
    }
}
