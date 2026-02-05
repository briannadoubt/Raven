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
