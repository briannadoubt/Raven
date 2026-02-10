import Foundation

// MARK: - SpatialTapGesture

/// A gesture that recognizes one or more taps and reports their location.
///
/// `SpatialTapGesture` extends tap recognition by providing the location of the tap
/// within a specified coordinate space. This is useful for interactive canvases,
/// drawing apps, or any scenario where you need to know where the user tapped.
///
/// ## Overview
///
/// Like `TapGesture`, spatial tap gestures can recognize single or multiple taps.
/// The key difference is that `SpatialTapGesture` produces a `CGPoint` value
/// representing the tap location in the requested coordinate space.
///
/// ## Basic Usage
///
/// Get tap location in local coordinates:
///
/// ```swift
/// Rectangle()
///     .fill(.blue)
///     .gesture(
///         SpatialTapGesture()
///             .onEnded { location in
///                 print("Tapped at: \(location)")
///             }
///     )
/// ```
///
/// ## Coordinate Spaces
///
/// Specify which coordinate space to use for the tap location:
///
/// ```swift
/// // Local coordinates (default) - relative to the view's bounds
/// SpatialTapGesture(coordinateSpace: .local)
///     .onEnded { location in
///         print("Local: \(location)")
///     }
///
/// // Global coordinates - relative to the window/document
/// SpatialTapGesture(coordinateSpace: .global)
///     .onEnded { location in
///         print("Global: \(location)")
///     }
///
/// // Named coordinate space - relative to a specific ancestor view
/// SpatialTapGesture(coordinateSpace: .named("container"))
///     .onEnded { location in
///         print("In container: \(location)")
///     }
/// ```
///
/// ## Multi-Tap with Location
///
/// Recognize multiple taps and get the location of the final tap:
///
/// ```swift
/// Canvas { context, size in
///     // Draw content
/// }
/// .gesture(
///     SpatialTapGesture(count: 2)
///         .onEnded { location in
///             print("Double-tapped at: \(location)")
///             // Add a marker at the double-tap location
///         }
/// )
/// ```
///
/// ## Interactive Drawing
///
/// Use spatial tap gestures for drawing or placing objects:
///
/// ```swift
/// struct DrawingView: View {
///     @State private var points: [CGPoint] = []
///
///     var body: some View {
///         Canvas { context, size in
///             for point in points {
///                 context.fill(
///                     Circle().path(in: CGRect(x: point.x - 5, y: point.y - 5,
///                                             width: 10, height: 10)),
///                     with: .color(.red)
///                 )
///             }
///         }
///         .gesture(
///             SpatialTapGesture()
///                 .onEnded { location in
///                     points.append(location)
///                 }
///         )
///     }
/// }
/// ```
///
/// ## Coordinate Space Relationship
///
/// The relationship between coordinate spaces:
/// - **Local**: (0, 0) is the top-left corner of the view
/// - **Global**: (0, 0) is the top-left corner of the window/document
/// - **Named**: (0, 0) is the top-left corner of the ancestor with that name
///
/// ## Web Implementation
///
/// In Raven's web environment, `SpatialTapGesture` maps to the `click` event
/// and uses the MouseEvent properties for coordinates:
///
/// - **Local coordinates**: Uses `offsetX` and `offsetY` or calculates relative
///   to the element's bounding box using `getBoundingClientRect()`
/// - **Global coordinates**: Uses `clientX` and `clientY` for viewport coordinates
/// - **Named coordinates**: Traverses the DOM tree to find the named ancestor and
///   calculates relative coordinates
///
/// The implementation:
/// 1. Listens for `click` events on the element
/// 2. Extracts coordinates from the MouseEvent
/// 3. Transforms coordinates based on the requested coordinate space
/// 4. Invokes the gesture handler with the calculated CGPoint
///
/// ## Performance Considerations
///
/// Spatial tap gestures have minimal performance impact:
/// - Coordinate transformation is done using cached element positions when possible
/// - Event listeners are shared across multiple gestures on the same element
/// - No continuous tracking - only fires on discrete tap events
///
/// ## Accessibility
///
/// When using spatial tap gestures:
/// - Ensure keyboard users can achieve the same functionality through alternative means
/// - Provide visual feedback for tappable areas
/// - Consider adding ARIA labels for screen readers
/// - Use appropriate cursor styles (pointer) to indicate interactivity
///
/// For purely interactive elements, consider using built-in controls when possible.
///
/// ## Thread Safety
///
/// `SpatialTapGesture` is `@MainActor` isolated and `Sendable`, ensuring thread-safe
/// usage. All gesture callbacks and coordinate calculations execute on the main actor.
///
/// ## See Also
///
/// - ``TapGesture``
/// - ``CoordinateSpace``
/// - ``CGPoint``
/// - ``DragGesture``
@MainActor
public struct SpatialTapGesture: Gesture, Sendable {
    /// The type of value produced by this gesture.
    ///
    /// Spatial tap gestures produce a `CGPoint` representing the tap location.
    public typealias Value = CGPoint

    /// The type representing the body of this gesture.
    ///
    /// `SpatialTapGesture` is a primitive gesture and has no body.
    public typealias Body = Never

    /// The number of taps required to complete the gesture.
    ///
    /// Defaults to 1 for a single tap. Set to 2 for double-tap, 3 for triple-tap, etc.
    public let count: Int

    /// The coordinate space in which to report the tap location.
    ///
    /// Determines how the tap location is calculated:
    /// - `.local`: Relative to the view's own bounds (default)
    /// - `.global`: Relative to the window/document
    /// - `.named(String)`: Relative to an ancestor view with a matching coordinate space name
    public let coordinateSpace: CoordinateSpace

    /// Creates a spatial tap gesture with the specified parameters.
    ///
    /// Example:
    /// ```swift
    /// // Single tap in local coordinates (default)
    /// SpatialTapGesture()
    ///
    /// // Double tap in global coordinates
    /// SpatialTapGesture(count: 2, coordinateSpace: .global)
    ///
    /// // Single tap in named coordinate space
    /// SpatialTapGesture(coordinateSpace: .named("canvas"))
    /// ```
    ///
    /// - Parameters:
    ///   - count: The number of sequential taps required to trigger the gesture.
    ///     Must be at least 1. Defaults to 1.
    ///   - coordinateSpace: The coordinate space for reporting tap location.
    ///     Defaults to `.local`.
    public init(count: Int = 1, coordinateSpace: CoordinateSpace = .local) {
        self.count = max(1, count)
        self.coordinateSpace = coordinateSpace
    }
}

// MARK: - Gesture Modifiers

extension SpatialTapGesture {
    /// Adds an action to perform when the spatial tap gesture ends.
    ///
    /// - Parameter action: The action to perform when the gesture ends.
    /// - Returns: A gesture with the action attached.
    public func onEnded(
        _ action: @escaping @MainActor @Sendable (Value) -> Void
    ) -> _ModifiedGesture<SpatialTapGesture, _EndedGestureModifier<Value>> {
        _ModifiedGesture(
            gesture: self,
            modifier: _EndedGestureModifier(action: action)
        )
    }

    /// Adds an action to perform when the spatial tap gesture changes.
    ///
    /// - Parameter action: The action to perform when the gesture changes.
    /// - Returns: A gesture with the action attached.
    public func onChanged(
        _ action: @escaping @MainActor @Sendable (Value) -> Void
    ) -> _ModifiedGesture<SpatialTapGesture, _ChangedGestureModifier<Value>> {
        _ModifiedGesture(
            gesture: self,
            modifier: _ChangedGestureModifier(action: action)
        )
    }

    /// Adds a state update to perform during the gesture.
    ///
    /// - Parameters:
    ///   - state: The gesture state to update.
    ///   - body: The update closure.
    /// - Returns: A gesture with the state update attached.
    public func updating<State>(
        _ state: GestureState<State>,
        body: @escaping @MainActor @Sendable (Value, inout State, inout Transaction) -> Void
    ) -> _ModifiedGesture<SpatialTapGesture, _UpdatingGestureModifier<State, Value>> {
        _ModifiedGesture(
            gesture: self,
            modifier: _UpdatingGestureModifier(state: state, body: body)
        )
    }
}

// MARK: - Web Event Mapping

extension SpatialTapGesture {
    /// The name of the DOM event that triggers this gesture.
    ///
    /// For spatial tap gestures, we use the `click` event which provides
    /// coordinate information through the MouseEvent properties.
    internal var eventName: String {
        "click"
    }

    /// Determines if the given click event matches the required tap count.
    ///
    /// This method checks the `detail` property of the MouseEvent, which contains
    /// the number of consecutive clicks. The browser maintains this count automatically
    /// and resets it after a timeout period.
    ///
    /// - Parameter detail: The detail property from the MouseEvent (number of clicks)
    /// - Returns: `true` if the click count matches this gesture's required count
    internal func matchesEvent(detail: Int) -> Bool {
        detail == count
    }

    /// Extracts the tap location from a click event in the requested coordinate space.
    ///
    /// This method would be called by the gesture recognition system to convert
    /// the raw MouseEvent coordinates into a CGPoint in the appropriate coordinate space.
    ///
    /// In the web implementation, this would:
    /// 1. Extract clientX/clientY from the MouseEvent (global viewport coordinates)
    /// 2. If local coordinates are requested:
    ///    - Get the element's bounding rect
    ///    - Subtract the element's position from the click coordinates
    /// 3. If global coordinates are requested:
    ///    - Use clientX/clientY directly
    /// 4. If named coordinates are requested:
    ///    - Find the ancestor element with the matching coordinate space name
    ///    - Calculate coordinates relative to that ancestor
    ///
    /// - Parameters:
    ///   - clientX: The X coordinate of the click in viewport coordinates
    ///   - clientY: The Y coordinate of the click in viewport coordinates
    ///   - elementBounds: The bounding rect of the target element
    ///   - namedAncestorBounds: The bounding rect of the named ancestor (if applicable)
    /// - Returns: A CGPoint representing the tap location in the requested coordinate space
    internal func extractLocation(
        clientX: Double,
        clientY: Double,
        elementBounds: CGRect,
        namedAncestorBounds: CGRect? = nil
    ) -> CGPoint {
        switch coordinateSpace {
        case .local:
            // Convert from viewport coordinates to element-local coordinates
            return CGPoint(
                x: clientX - elementBounds.minX,
                y: clientY - elementBounds.minY
            )
        case .global:
            // Use viewport coordinates directly
            return CGPoint(x: clientX, y: clientY)
        case .named:
            // Convert to named ancestor's coordinate space
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

// MARK: - Documentation Examples

/*
 Example: Interactive canvas

 ```swift
 struct CanvasView: View {
     @State private var dots: [CGPoint] = []

     var body: some View {
         Canvas { context, size in
             // Draw background
             context.fill(
                 Rectangle().path(in: CGRect(origin: .zero, size: size)),
                 with: .color(.white)
             )

             // Draw dots
             for dot in dots {
                 let rect = CGRect(x: dot.x - 5, y: dot.y - 5, width: 10, height: 10)
                 context.fill(Circle().path(in: rect), with: .color(.blue))
             }
         }
         .frame(width: 400, height: 400)
         .border(.gray)
         .gesture(
             SpatialTapGesture()
                 .onEnded { location in
                     dots.append(location)
                 }
         )
     }
 }
 ```

 Example: Color picker with coordinate-based selection

 ```swift
 struct ColorPickerView: View {
     @State private var selectedColor: Color = .white

     var body: some View {
         VStack {
             Rectangle()
                 .fill(
                     LinearGradient(
                         colors: [.red, .yellow, .green, .blue, .purple],
                         startPoint: .leading,
                         endPoint: .trailing
                     )
                 )
                 .frame(height: 50)
                 .gesture(
                     SpatialTapGesture(coordinateSpace: .local)
                         .onEnded { location in
                             // location.x ranges from 0 to width
                             // Use to pick color from gradient
                             selectedColor = colorAt(location: location)
                         }
                 )

             Rectangle()
                 .fill(selectedColor)
                 .frame(height: 100)
         }
     }

     func colorAt(location: CGPoint) -> Color {
         // Calculate color based on location
         // This is a simplified example
         .blue
     }
 }
 ```

 Example: Game with tap-to-shoot mechanics

 ```swift
 struct ShootingGame: View {
     @State private var projectiles: [CGPoint] = []
     @State private var targets: [CGPoint] = [
         CGPoint(x: 100, y: 100),
         CGPoint(x: 200, y: 150),
         CGPoint(x: 300, y: 100)
     ]

     var body: some View {
         ZStack {
             // Game area
             Rectangle()
                 .fill(.black)
                 .gesture(
                     SpatialTapGesture(coordinateSpace: .local)
                         .onEnded { location in
                             shoot(at: location)
                         }
                 )

             // Render targets
             ForEach(targets.indices, id: \.self) { index in
                 Circle()
                     .fill(.red)
                     .frame(width: 30, height: 30)
                     .position(targets[index])
             }

             // Render projectiles
             ForEach(projectiles.indices, id: \.self) { index in
                 Circle()
                     .fill(.yellow)
                     .frame(width: 10, height: 10)
                     .position(projectiles[index])
             }
         }
         .coordinateSpace(name: "game")
     }

     func shoot(at location: CGPoint) {
         projectiles.append(location)
         // Check for hits, animate projectiles, etc.
     }
 }
 ```

 Example: Multi-tap zoom

 ```swift
 struct ZoomableImage: View {
     @State private var zoomLevel: CGFloat = 1.0
     @State private var zoomCenter: CGPoint = .zero

     var body: some View {
         Image("photo")
             .scaleEffect(zoomLevel, anchor: UnitPoint(
                 x: zoomCenter.x / 400,  // Assuming 400pt width
                 y: zoomCenter.y / 400
             ))
             .gesture(
                 SpatialTapGesture(count: 2, coordinateSpace: .local)
                     .onEnded { location in
                         if zoomLevel == 1.0 {
                             zoomLevel = 2.0
                             zoomCenter = location
                         } else {
                             zoomLevel = 1.0
                             zoomCenter = .zero
                         }
                     }
             )
     }
 }
 ```
 */
