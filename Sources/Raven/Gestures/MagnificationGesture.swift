import Foundation

// MARK: - MagnificationGesture

/// A gesture that recognizes a magnification motion (pinch to zoom).
///
/// `MagnificationGesture` tracks the distance between two touch points to detect pinch
/// and zoom gestures. The gesture value is a scale factor where 1.0 represents no change,
/// values greater than 1.0 represent zooming in (pinching apart), and values less than
/// 1.0 represent zooming out (pinching together).
///
/// ## Overview
///
/// The magnification gesture requires two simultaneous touch points to operate. It measures
/// the distance between the two touches and calculates a scale factor based on how that
/// distance changes relative to the initial distance. This is the standard "pinch to zoom"
/// gesture found in photos apps and maps.
///
/// ## Basic Usage
///
/// Apply zoom to an image:
///
/// ```swift
/// struct ZoomableImage: View {
///     @State private var scale: CGFloat = 1.0
///
///     var body: some View {
///         Image("photo")
///             .scaleEffect(scale)
///             .gesture(
///                 MagnificationGesture()
///                     .onChanged { value in
///                         scale = value
///                     }
///             )
///     }
/// }
/// ```
///
/// ## Temporary Magnification with GestureState
///
/// Use `@GestureState` for magnification that resets when the gesture ends:
///
/// ```swift
/// struct ContentView: View {
///     @GestureState private var magnification: CGFloat = 1.0
///     @State private var permanentScale: CGFloat = 1.0
///
///     var body: some View {
///         Image("photo")
///             .scaleEffect(magnification * permanentScale)
///             .gesture(
///                 MagnificationGesture()
///                     .updating($magnification) { value, state, _ in
///                         state = value
///                     }
///                     .onEnded { finalScale in
///                         permanentScale *= finalScale
///                     }
///             )
///     }
/// }
/// ```
///
/// ## Combining with Other Gestures
///
/// Combine magnification with rotation for a complete transform gesture:
///
/// ```swift
/// Image("photo")
///     .scaleEffect(scale)
///     .rotationEffect(rotation)
///     .gesture(
///         MagnificationGesture()
///             .simultaneously(with: RotationGesture())
///             .onChanged { value in
///                 scale = value.first ?? 1.0
///                 rotation = value.second ?? .zero
///             }
///     )
/// ```
///
/// ## Minimum and Maximum Scale
///
/// Constrain the scale to prevent extreme zooming:
///
/// ```swift
/// @State private var scale: CGFloat = 1.0
///
/// MagnificationGesture()
///     .onChanged { value in
///         scale = min(max(value, 0.5), 3.0)  // Between 0.5x and 3x
///     }
/// ```
///
/// ## Web Implementation
///
/// In Raven's web environment, magnification gestures map to touch and pointer events:
///
/// ### Touch Events (Mobile/Tablets)
/// - **touchstart**: Initializes the gesture when 2 touches are detected
/// - **touchmove**: Calculates distance changes as touches move
/// - **touchend/touchcancel**: Ends the gesture when touches are released
///
/// The scale is calculated as the ratio of current to initial distance:
/// ```javascript
/// const dx = touch2.clientX - touch1.clientX
/// const dy = touch2.clientY - touch1.clientY
/// const currentDistance = Math.sqrt(dx * dx + dy * dy)
/// const scale = currentDistance / initialDistance
/// ```
///
/// ### Trackpad/Touchpad (Desktop)
/// - **wheel + Ctrl**: Ctrl+scroll for pinch zoom
/// - The wheel delta is interpreted as zoom in/out commands
/// - Typically uses `wheel` event with `ctrlKey` modifier
///
/// ## Gesture Value
///
/// The gesture produces a `CGFloat` value representing the scale factor:
///
/// - **1.0**: No magnification (initial state)
/// - **> 1.0**: Zooming in (fingers moving apart)
/// - **< 1.0**: Zooming out (fingers moving together)
/// - **0.5**: Half the original size
/// - **2.0**: Double the original size
///
/// The value is always relative to the gesture's starting point. If you want to accumulate
/// scale across multiple gestures, multiply the permanent scale by the gesture scale.
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
/// - Distance calculations use efficient Pythagorean theorem
/// - Only active during two-finger touch
/// - Automatically cleans up event listeners when gesture ends
/// - Optimized for smooth, continuous updates during pinch/zoom
///
/// ## Accessibility
///
/// Magnification gestures are primarily two-finger touch gestures and may not be
/// accessible to all users. Consider providing alternative interaction methods:
/// - Zoom buttons (+/- controls)
/// - Keyboard shortcuts (+ and - keys)
/// - Slider controls for precise zoom levels
/// - Double-tap to zoom presets
/// - Voice commands
///
/// ## Thread Safety
///
/// `MagnificationGesture` is `@MainActor` isolated and `Sendable`, ensuring thread-safe
/// usage in SwiftUI's concurrent environment. All gesture updates occur on the main actor.
///
/// ## See Also
///
/// - ``RotationGesture``
/// - ``DragGesture``
/// - ``Gesture``
@MainActor
public struct MagnificationGesture: Gesture, Sendable {
    /// The type of value produced by this gesture.
    ///
    /// Magnification gestures produce a `CGFloat` scale factor where 1.0 represents
    /// no magnification, values > 1.0 represent zoom in, and values < 1.0 represent
    /// zoom out.
    public typealias Value = CGFloat

    /// The body type for this gesture.
    ///
    /// This is a primitive gesture with no body composition.
    public typealias Body = Never

    /// The minimum scale value that can be produced.
    ///
    /// This prevents the scale from becoming too small or negative. Defaults to 0.01
    /// (1% of original size) which is effectively fully zoomed out while remaining
    /// mathematically valid.
    public let minimumScaleDelta: CGFloat

    /// Creates a magnification gesture with default settings.
    ///
    /// The gesture will track pinch/zoom between two touch points and produce
    /// scale factor values as the distance changes.
    ///
    /// Example:
    /// ```swift
    /// MagnificationGesture()
    ///     .onChanged { scale in
    ///         print("Current scale: \(scale)")
    ///     }
    /// ```
    public init() {
        self.minimumScaleDelta = 0.01
    }

    /// Creates a magnification gesture with a custom minimum scale.
    ///
    /// Use this initializer to control the minimum scale value that the gesture
    /// can produce. This is useful for preventing extreme zoom-out scenarios.
    ///
    /// Example:
    /// ```swift
    /// // Prevent scaling below 50% of original size
    /// MagnificationGesture(minimumScaleDelta: 0.5)
    /// ```
    ///
    /// - Parameter minimumScaleDelta: The minimum scale value. Must be positive.
    ///   Values less than or equal to 0 will be clamped to 0.01.
    public init(minimumScaleDelta: CGFloat) {
        self.minimumScaleDelta = max(0.01, minimumScaleDelta)
    }
}

// MARK: - Internal State

/// Internal state tracking for magnification gesture recognition.
///
/// This structure maintains the state needed to track an active magnification gesture,
/// including the initial distance between touch points and the current distance.
@MainActor
internal struct MagnificationGestureState: Sendable {
    /// The initial distance between the two touch points, in points.
    ///
    /// This is calculated when the gesture begins using the Pythagorean theorem:
    /// `distance = sqrt((x2 - x1)² + (y2 - y1)²)`
    var initialDistance: Double

    /// The current distance between the two touch points, in points.
    ///
    /// Updated on each touch move event.
    var currentDistance: Double

    /// The minimum allowed scale value.
    let minimumScale: Double

    /// Creates a new magnification gesture state.
    ///
    /// - Parameters:
    ///   - initialDistance: The starting distance between touches.
    ///   - currentDistance: The current distance (typically same as initial at start).
    ///   - minimumScale: The minimum allowed scale value.
    init(initialDistance: Double, currentDistance: Double, minimumScale: Double) {
        self.initialDistance = max(1.0, initialDistance) // Prevent division by near-zero
        self.currentDistance = currentDistance
        self.minimumScale = minimumScale
    }

    /// Calculates the scale factor from the initial distance.
    ///
    /// Returns the ratio of the current distance to the initial distance, which
    /// represents the magnification factor. A value of 1.0 means no change,
    /// greater than 1.0 means zooming in, less than 1.0 means zooming out.
    ///
    /// - Returns: The scale factor as a `CGFloat`.
    var scale: CGFloat {
        let rawScale = currentDistance / initialDistance
        return max(minimumScale, rawScale)
    }

    /// Updates the current distance based on new touch positions.
    ///
    /// Calculates the Euclidean distance between two touch points.
    ///
    /// - Parameters:
    ///   - x1: The x-coordinate of the first touch point.
    ///   - y1: The y-coordinate of the first touch point.
    ///   - x2: The x-coordinate of the second touch point.
    ///   - y2: The y-coordinate of the second touch point.
    mutating func updateDistance(x1: Double, y1: Double, x2: Double, y2: Double) {
        currentDistance = Self.calculateDistance(x1: x1, y1: y1, x2: x2, y2: y2)
    }

    /// Calculates the distance between two points.
    ///
    /// Uses the Pythagorean theorem to compute the straight-line distance.
    ///
    /// - Parameters:
    ///   - x1: The x-coordinate of the first point.
    ///   - y1: The y-coordinate of the first point.
    ///   - x2: The x-coordinate of the second point.
    ///   - y2: The y-coordinate of the second point.
    /// - Returns: The distance in points.
    static func calculateDistance(x1: Double, y1: Double, x2: Double, y2: Double) -> Double {
        let dx = x2 - x1
        let dy = y2 - y1
        return sqrt(dx * dx + dy * dy)
    }
}

// MARK: - Web Event Mapping

extension MagnificationGesture {
    /// The primary event name for touch-based magnification.
    ///
    /// The magnification gesture uses multiple events:
    /// - `touchstart`: Detect when two fingers touch the screen
    /// - `touchmove`: Track distance changes during pinch
    /// - `touchend`: Complete the gesture when fingers are lifted
    internal var primaryEventName: String {
        "touchstart"
    }

    /// The event names for tracking magnification movement.
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
    /// pinch gestures for zooming.
    internal var wheelEventName: String {
        "wheel"
    }

    /// Determines if a touch event has the required number of touches.
    ///
    /// Magnification requires exactly 2 simultaneous touches.
    ///
    /// - Parameter touchCount: The number of active touches.
    /// - Returns: `true` if the touch count is valid for magnification (exactly 2).
    internal func isValidTouchCount(_ touchCount: Int) -> Bool {
        touchCount == 2
    }

    /// Checks if a wheel event should trigger magnification.
    ///
    /// For desktop zoom, we check if the Control key (Ctrl) is pressed
    /// during the wheel event, which is the standard modifier for zoom
    /// on most platforms.
    ///
    /// - Parameter ctrlKey: Whether the Control key is pressed.
    /// - Returns: `true` if this is a magnification wheel event.
    internal func isMagnificationWheelEvent(ctrlKey: Bool) -> Bool {
        ctrlKey
    }

    /// Converts wheel delta to scale factor.
    ///
    /// Maps mouse wheel movement to scale changes. Positive delta (wheel down)
    /// typically means zoom out, negative delta (wheel up) means zoom in.
    ///
    /// - Parameter delta: The wheel delta value (typically deltaY).
    /// - Returns: A scale factor adjustment (multiplier).
    internal func wheelDeltaToScale(delta: Double) -> CGFloat {
        // Each wheel tick adjusts scale by approximately 10%
        // Negative delta (wheel up) = zoom in (scale > 1)
        // Positive delta (wheel down) = zoom out (scale < 1)
        let scaleFactor = 1.0 + (-delta * 0.01)
        return max(minimumScaleDelta, scaleFactor)
    }
}

// MARK: - Gesture Modifiers

extension MagnificationGesture {
    /// Adds an action to perform when the magnification gesture changes.
    ///
    /// The action is called with the current scale factor each time the gesture updates.
    /// This typically happens many times per second during an active pinch gesture.
    ///
    /// Example:
    /// ```swift
    /// MagnificationGesture()
    ///     .onChanged { scale in
    ///         print("Current scale: \(scale)")
    ///     }
    /// ```
    ///
    /// - Parameter action: The action to perform on each gesture update.
    /// - Returns: A gesture with the action attached.
    public func onChanged(
        _ action: @escaping @MainActor @Sendable (Value) -> Void
    ) -> _ModifiedGesture<MagnificationGesture, _ChangedGestureModifier<Value>> {
        _ModifiedGesture(
            gesture: self,
            modifier: _ChangedGestureModifier(action: action)
        )
    }

    /// Adds an action to perform when the magnification gesture ends.
    ///
    /// The action is called with the final scale factor when the user lifts their
    /// fingers from the screen or otherwise completes the gesture.
    ///
    /// Example:
    /// ```swift
    /// MagnificationGesture()
    ///     .onEnded { finalScale in
    ///         print("Final scale: \(finalScale)")
    ///     }
    /// ```
    ///
    /// - Parameter action: The action to perform when the gesture ends.
    /// - Returns: A gesture with the action attached.
    public func onEnded(
        _ action: @escaping @MainActor @Sendable (Value) -> Void
    ) -> _ModifiedGesture<MagnificationGesture, _EndedGestureModifier<Value>> {
        _ModifiedGesture(
            gesture: self,
            modifier: _EndedGestureModifier(action: action)
        )
    }

    /// Updates gesture state values as the magnification changes.
    ///
    /// Use this modifier with `@GestureState` to track the scale. The gesture state
    /// automatically resets when the gesture ends.
    ///
    /// Example:
    /// ```swift
    /// @GestureState private var scale: CGFloat = 1.0
    ///
    /// MagnificationGesture()
    ///     .updating($scale) { current, state, transaction in
    ///         state = current
    ///     }
    /// ```
    ///
    /// - Parameters:
    ///   - state: A binding to gesture state that will be updated.
    ///   - body: A closure that updates the gesture state. It receives the current
    ///     scale factor, an inout parameter for the gesture state, and a transaction.
    /// - Returns: A gesture that updates the provided state.
    public func updating<State>(
        _ state: GestureState<State>,
        body: @escaping @MainActor @Sendable (Value, inout State, inout Transaction) -> Void
    ) -> _ModifiedGesture<MagnificationGesture, _UpdatingGestureModifier<State, Value>> {
        _ModifiedGesture(
            gesture: self,
            modifier: _UpdatingGestureModifier(state: state, body: body)
        )
    }
}

// MARK: - Documentation Examples

/*
Example: Basic magnification

```swift
struct ZoomablePhoto: View {
    @State private var scale: CGFloat = 1.0

    var body: some View {
        Image("photo")
            .scaleEffect(scale)
            .gesture(
                MagnificationGesture()
                    .onChanged { value in
                        scale = value
                    }
            )
    }
}
```

Example: Magnification with min/max constraints

```swift
struct ConstrainedZoomView: View {
    @State private var scale: CGFloat = 1.0

    var body: some View {
        Image("photo")
            .scaleEffect(scale)
            .gesture(
                MagnificationGesture()
                    .onChanged { value in
                        // Constrain between 0.5x and 4x
                        scale = min(max(value, 0.5), 4.0)
                    }
            )
    }
}
```

Example: Cumulative magnification

```swift
struct AccumulatingZoomView: View {
    @GestureState private var magnification: CGFloat = 1.0
    @State private var permanentScale: CGFloat = 1.0

    var finalScale: CGFloat {
        permanentScale * magnification
    }

    var body: some View {
        Rectangle()
            .fill(Color.blue)
            .frame(width: 100, height: 100)
            .scaleEffect(finalScale)
            .gesture(
                MagnificationGesture()
                    .updating($magnification) { value, state, _ in
                        state = value
                    }
                    .onEnded { value in
                        permanentScale *= value
                    }
            )
    }
}
```

Example: Combined zoom and rotation

```swift
struct TransformableView: View {
    @State private var scale: CGFloat = 1.0
    @State private var rotation = Angle.zero

    var body: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color.purple)
            .frame(width: 200, height: 200)
            .scaleEffect(scale)
            .rotationEffect(rotation)
            .gesture(
                MagnificationGesture()
                    .simultaneously(with: RotationGesture())
                    .onChanged { value in
                        scale = value.first ?? 1.0
                        rotation = value.second ?? .zero
                    }
            )
    }
}
```

Example: Zoom with feedback

```swift
struct ZoomWithFeedback: View {
    @State private var scale: CGFloat = 1.0
    @State private var showScaleLabel = false

    var body: some View {
        VStack {
            Image("photo")
                .scaleEffect(scale)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            scale = value
                            showScaleLabel = true
                        }
                        .onEnded { _ in
                            showScaleLabel = false
                        }
                )

            if showScaleLabel {
                Text("\(Int(scale * 100))%")
                    .font(.caption)
                    .padding(8)
                    .background(Color.black.opacity(0.7))
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
    }
}
```
*/
