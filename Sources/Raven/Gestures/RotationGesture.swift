import Foundation

// MARK: - RotationGesture

/// A gesture that recognizes a rotation motion.
///
/// `RotationGesture` tracks the angular rotation between two touch points. The gesture
/// begins when two fingers touch the screen and updates as the angle between them changes.
/// This is commonly used for rotating images, views, or other content.
///
/// ## Overview
///
/// The rotation gesture requires two simultaneous touch points to operate. It calculates
/// the angle of the line connecting the two touch points and tracks how that angle changes
/// over time. The gesture value is the cumulative rotation angle from the starting position.
///
/// ## Basic Usage
///
/// Track rotation and apply it to a view:
///
/// ```swift
/// struct RotatableView: View {
///     @State private var angle = Angle.zero
///
///     var body: some View {
///         Rectangle()
///             .rotationEffect(angle)
///             .gesture(
///                 RotationGesture()
///                     .onChanged { value in
///                         angle = value
///                     }
///             )
///     }
/// }
/// ```
///
/// ## Temporary Rotation with GestureState
///
/// Use `@GestureState` for rotation that resets when the gesture ends:
///
/// ```swift
/// struct ContentView: View {
///     @GestureState private var rotation = Angle.zero
///     @State private var permanentRotation = Angle.zero
///
///     var body: some View {
///         Image("photo")
///             .rotationEffect(rotation + permanentRotation)
///             .gesture(
///                 RotationGesture()
///                     .updating($rotation) { value, state, _ in
///                         state = value
///                     }
///                     .onEnded { finalRotation in
///                         permanentRotation = permanentRotation + finalRotation
///                     }
///             )
///     }
/// }
/// ```
///
/// ## Combining with Other Gestures
///
/// Combine rotation with magnification for a complete transform gesture:
///
/// ```swift
/// Image("photo")
///     .rotationEffect(rotation)
///     .scaleEffect(scale)
///     .gesture(
///         RotationGesture()
///             .simultaneously(with: MagnificationGesture())
///             .onChanged { value in
///                 rotation = value.first ?? .zero
///                 scale = value.second ?? 1.0
///             }
///     )
/// ```
///
/// ## Web Implementation
///
/// In Raven's web environment, rotation gestures map to touch and pointer events:
///
/// ### Touch Events (Mobile/Tablets)
/// - **touchstart**: Initializes the gesture when 2 touches are detected
/// - **touchmove**: Calculates angle changes as touches move
/// - **touchend/touchcancel**: Ends the gesture when touches are released
///
/// The angle is calculated using `atan2` on the vector between the two touch points:
/// ```javascript
/// const dx = touch2.clientX - touch1.clientX
/// const dy = touch2.clientY - touch1.clientY
/// const angle = Math.atan2(dy, dx)
/// ```
///
/// ### Desktop Fallback (Mouse/Trackpad)
/// - **wheel + Ctrl**: Ctrl+scroll to rotate (wheel deltaX or deltaY)
/// - The wheel delta is scaled to provide reasonable rotation increments
///
/// ## Gesture Value
///
/// The gesture produces an `Angle` value representing the total rotation from the
/// starting angle. The value accumulates throughout the gesture:
///
/// - At gesture start: Based on initial two-touch position angle
/// - During gesture: Difference from starting angle
/// - Positive values: Clockwise rotation
/// - Negative values: Counter-clockwise rotation
///
/// ## Minimum Touch Requirements
///
/// The gesture requires exactly 2 simultaneous touch points:
/// - 0-1 touches: Gesture does not begin
/// - 2 touches: Gesture active
/// - 3+ touches: Gesture typically cancels or ignores additional touches
///
/// ## Performance Considerations
///
/// - Angle calculations use efficient `atan2` operations
/// - Only active during two-finger touch
/// - Automatically cleans up event listeners when gesture ends
/// - Optimized for smooth, continuous updates during rotation
///
/// ## Accessibility
///
/// Rotation gestures are primarily two-finger touch gestures and may not be accessible
/// to all users. Consider providing alternative interaction methods:
/// - Rotation buttons (+/- 90 degrees)
/// - Keyboard shortcuts (arrow keys with modifier)
/// - Slider controls for precise rotation
/// - Voice commands
///
/// ## Thread Safety
///
/// `RotationGesture` is `@MainActor` isolated and `Sendable`, ensuring thread-safe usage
/// in SwiftUI's concurrent environment. All gesture updates occur on the main actor.
///
/// ## See Also
///
/// - ``MagnificationGesture``
/// - ``DragGesture``
/// - ``Angle``
/// - ``Gesture``
@MainActor
public struct RotationGesture: Gesture, Sendable {
    /// The type of value produced by this gesture.
    ///
    /// Rotation gestures produce an `Angle` value representing the rotation angle
    /// relative to the starting position.
    public typealias Value = Angle

    /// The body type for this gesture.
    ///
    /// This is a primitive gesture with no body composition.
    public typealias Body = Never

    /// Creates a rotation gesture.
    ///
    /// The gesture will track rotation between two touch points and produce
    /// angle values as the rotation changes.
    ///
    /// Example:
    /// ```swift
    /// RotationGesture()
    ///     .onChanged { angle in
    ///         print("Rotated by \(angle.degrees) degrees")
    ///     }
    /// ```
    public init() {
        // No configuration needed for basic rotation gesture
    }
}

// MARK: - Internal State

/// Internal state tracking for rotation gesture recognition.
///
/// This structure maintains the state needed to track an active rotation gesture,
/// including the initial angle between touch points and the current angle.
@MainActor
internal struct RotationGestureState: Sendable {
    /// The initial angle between the two touch points, in radians.
    ///
    /// This is calculated when the gesture begins using `atan2(dy, dx)` where
    /// `dx` and `dy` are the horizontal and vertical distances between the touches.
    var initialAngle: Double

    /// The current angle between the two touch points, in radians.
    ///
    /// Updated on each touch move event.
    var currentAngle: Double

    /// Creates a new rotation gesture state.
    ///
    /// - Parameters:
    ///   - initialAngle: The starting angle in radians.
    ///   - currentAngle: The current angle in radians (typically same as initial at start).
    init(initialAngle: Double, currentAngle: Double) {
        self.initialAngle = initialAngle
        self.currentAngle = currentAngle
    }

    /// Calculates the rotation angle from the initial position.
    ///
    /// Returns the difference between the current angle and the initial angle,
    /// which represents how much rotation has occurred since the gesture began.
    ///
    /// - Returns: The rotation as an `Angle` value.
    var rotation: Angle {
        Angle(radians: currentAngle - initialAngle)
    }

    /// Updates the current angle based on new touch positions.
    ///
    /// Calculates the angle using the arctangent of the vector between two touch points.
    ///
    /// - Parameters:
    ///   - x1: The x-coordinate of the first touch point.
    ///   - y1: The y-coordinate of the first touch point.
    ///   - x2: The x-coordinate of the second touch point.
    ///   - y2: The y-coordinate of the second touch point.
    mutating func updateAngle(x1: Double, y1: Double, x2: Double, y2: Double) {
        let dx = x2 - x1
        let dy = y2 - y1
        currentAngle = atan2(dy, dx)
    }

    /// Calculates the initial angle from two touch points.
    ///
    /// This is a helper function to compute the starting angle when the gesture begins.
    ///
    /// - Parameters:
    ///   - x1: The x-coordinate of the first touch point.
    ///   - y1: The y-coordinate of the first touch point.
    ///   - x2: The x-coordinate of the second touch point.
    ///   - y2: The y-coordinate of the second touch point.
    /// - Returns: The angle in radians.
    static func calculateAngle(x1: Double, y1: Double, x2: Double, y2: Double) -> Double {
        let dx = x2 - x1
        let dy = y2 - y1
        return atan2(dy, dx)
    }
}

// MARK: - Web Event Mapping

extension RotationGesture {
    /// The primary event name for touch-based rotation.
    ///
    /// The rotation gesture uses multiple events:
    /// - `touchstart`: Detect when two fingers touch the screen
    /// - `touchmove`: Track angle changes during rotation
    /// - `touchend`: Complete the gesture when fingers are lifted
    internal var primaryEventName: String {
        "touchstart"
    }

    /// The event names for tracking rotation movement.
    internal var moveEventNames: [String] {
        ["touchmove"]
    }

    /// The event names for ending the gesture.
    internal var endEventNames: [String] {
        ["touchend", "touchcancel"]
    }

    /// The wheel event name for desktop fallback.
    ///
    /// On desktop browsers, Ctrl+Wheel can be used as an alternative to
    /// two-finger rotation gestures.
    internal var wheelEventName: String {
        "wheel"
    }

    /// Determines if a touch event has the required number of touches.
    ///
    /// Rotation requires exactly 2 simultaneous touches.
    ///
    /// - Parameter touchCount: The number of active touches.
    /// - Returns: `true` if the touch count is valid for rotation (exactly 2).
    internal func isValidTouchCount(_ touchCount: Int) -> Bool {
        touchCount == 2
    }

    /// Checks if a wheel event should trigger rotation.
    ///
    /// For desktop rotation, we check if the Control key (Ctrl) is pressed
    /// during the wheel event.
    ///
    /// - Parameter ctrlKey: Whether the Control key is pressed.
    /// - Returns: `true` if this is a rotation wheel event.
    internal func isRotationWheelEvent(ctrlKey: Bool) -> Bool {
        ctrlKey
    }

    /// Converts wheel delta to rotation angle.
    ///
    /// Maps mouse wheel movement to rotation angles. The scale factor ensures
    /// reasonable rotation increments per wheel tick.
    ///
    /// - Parameter delta: The wheel delta value (typically deltaY or deltaX).
    /// - Returns: The rotation angle.
    internal func wheelDeltaToRotation(delta: Double) -> Angle {
        // Scale wheel delta to degrees (1 wheel tick ≈ 15 degrees)
        // Negative delta because wheel "up" typically means clockwise rotation
        Angle(degrees: -delta * 0.5)
    }
}

// MARK: - Gesture Modifiers

extension RotationGesture {
    /// Adds an action to perform when the rotation gesture changes.
    ///
    /// The action is called with the current rotation angle each time the gesture updates.
    /// This typically happens many times per second during an active rotation.
    ///
    /// Example:
    /// ```swift
    /// RotationGesture()
    ///     .onChanged { angle in
    ///         print("Current rotation: \(angle.degrees)°")
    ///     }
    /// ```
    ///
    /// - Parameter action: The action to perform on each gesture update.
    /// - Returns: A gesture with the action attached.
    public func onChanged(
        _ action: @escaping @MainActor @Sendable (Value) -> Void
    ) -> _ModifiedGesture<RotationGesture, _ChangedGestureModifier<Value>> {
        _ModifiedGesture(
            gesture: self,
            modifier: _ChangedGestureModifier(action: action)
        )
    }

    /// Adds an action to perform when the rotation gesture ends.
    ///
    /// The action is called with the final rotation angle when the user lifts their
    /// fingers from the screen or otherwise completes the gesture.
    ///
    /// Example:
    /// ```swift
    /// RotationGesture()
    ///     .onEnded { finalAngle in
    ///         print("Total rotation: \(finalAngle.degrees)°")
    ///     }
    /// ```
    ///
    /// - Parameter action: The action to perform when the gesture ends.
    /// - Returns: A gesture with the action attached.
    public func onEnded(
        _ action: @escaping @MainActor @Sendable (Value) -> Void
    ) -> _ModifiedGesture<RotationGesture, _EndedGestureModifier<Value>> {
        _ModifiedGesture(
            gesture: self,
            modifier: _EndedGestureModifier(action: action)
        )
    }

    /// Updates gesture state values as the rotation changes.
    ///
    /// Use this modifier with `@GestureState` to track the rotation. The gesture state
    /// automatically resets when the gesture ends.
    ///
    /// Example:
    /// ```swift
    /// @GestureState private var rotation = Angle.zero
    ///
    /// RotationGesture()
    ///     .updating($rotation) { current, state, transaction in
    ///         state = current
    ///     }
    /// ```
    ///
    /// - Parameters:
    ///   - state: A binding to gesture state that will be updated.
    ///   - body: A closure that updates the gesture state. It receives the current
    ///     rotation angle, an inout parameter for the gesture state, and a transaction.
    /// - Returns: A gesture that updates the provided state.
    public func updating<State>(
        _ state: GestureState<State>,
        body: @escaping @MainActor @Sendable (Value, inout State, inout Transaction) -> Void
    ) -> _ModifiedGesture<RotationGesture, _UpdatingGestureModifier<State, Value>> {
        _ModifiedGesture(
            gesture: self,
            modifier: _UpdatingGestureModifier(state: state, body: body)
        )
    }
}

// MARK: - Documentation Examples

/*
Example: Basic rotation tracking

```swift
struct RotatableCard: View {
    @State private var rotation = Angle.zero

    var body: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color.blue)
            .frame(width: 200, height: 200)
            .rotationEffect(rotation)
            .gesture(
                RotationGesture()
                    .onChanged { angle in
                        rotation = angle
                    }
            )
    }
}
```

Example: Rotation with permanent state

```swift
struct PhotoView: View {
    @GestureState private var gestureRotation = Angle.zero
    @State private var permanentRotation = Angle.zero

    var totalRotation: Angle {
        permanentRotation + gestureRotation
    }

    var body: some View {
        Image("photo")
            .rotationEffect(totalRotation)
            .gesture(
                RotationGesture()
                    .updating($gestureRotation) { value, state, _ in
                        state = value
                    }
                    .onEnded { finalRotation in
                        permanentRotation = permanentRotation + finalRotation
                    }
            )
    }
}
```

Example: Combined rotation and magnification

```swift
struct TransformableImage: View {
    @State private var rotation = Angle.zero
    @State private var scale: CGFloat = 1.0

    var body: some View {
        Image("photo")
            .scaleEffect(scale)
            .rotationEffect(rotation)
            .gesture(
                RotationGesture()
                    .simultaneously(with: MagnificationGesture())
                    .onChanged { value in
                        rotation = value.first ?? .zero
                        scale = value.second ?? 1.0
                    }
            )
    }
}
```

Example: Rotation with snap-to angles

```swift
struct SnappingRotationView: View {
    @State private var rotation = Angle.zero

    var snappedRotation: Angle {
        let degrees = rotation.degrees
        let snapAngle = 45.0
        let snapped = round(degrees / snapAngle) * snapAngle
        return Angle(degrees: snapped)
    }

    var body: some View {
        Rectangle()
            .fill(Color.red)
            .frame(width: 150, height: 150)
            .rotationEffect(snappedRotation)
            .gesture(
                RotationGesture()
                    .onChanged { angle in
                        rotation = angle
                    }
            )
            .overlay(
                Text("\(Int(snappedRotation.degrees))°")
                    .foregroundColor(.white)
            )
    }
}
```
*/
