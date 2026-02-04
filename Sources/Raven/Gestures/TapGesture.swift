import Foundation

// MARK: - TapGesture

/// A gesture that recognizes one or more taps.
///
/// `TapGesture` is a discrete gesture that succeeds when the user taps on a view.
/// It can be configured to recognize single taps, double taps, or any number of
/// sequential taps.
///
/// ## Overview
///
/// Tap gestures are the simplest form of user interaction. They complete immediately
/// when the required number of taps is detected, producing no value (their `Value`
/// type is `Void`).
///
/// ## Basic Usage
///
/// Recognize a single tap:
///
/// ```swift
/// Text("Tap me")
///     .gesture(
///         TapGesture()
///             .onEnded {
///                 print("Tapped!")
///             }
///     )
/// ```
///
/// ## Multi-Tap Recognition
///
/// Recognize multiple taps by specifying a count:
///
/// ```swift
/// // Double tap
/// Text("Double tap me")
///     .gesture(
///         TapGesture(count: 2)
///             .onEnded {
///                 print("Double tapped!")
///             }
///     )
///
/// // Triple tap
/// Text("Triple tap me")
///     .gesture(
///         TapGesture(count: 3)
///             .onEnded {
///                 print("Triple tapped!")
///             }
///     )
/// ```
///
/// ## Modifier Keys
///
/// Detect modifier keys during a tap by accessing the gesture value in a more complex
/// gesture composition (Note: basic TapGesture doesn't directly provide modifier access,
/// but you can use `SpatialTapGesture` for more advanced scenarios or handle modifiers
/// in web event handlers):
///
/// ```swift
/// TapGesture()
///     .onEnded {
///         // Tap completed
///         // Modifier key handling would need custom implementation
///     }
/// ```
///
/// ## Combining with Other Gestures
///
/// Combine tap gestures with other gestures for complex interactions:
///
/// ```swift
/// let singleTap = TapGesture()
///     .onEnded { print("Single tap") }
///
/// let doubleTap = TapGesture(count: 2)
///     .onEnded { print("Double tap") }
///
/// // Exclusive - only one gesture succeeds
/// view.gesture(
///     doubleTap.exclusively(before: singleTap)
/// )
/// ```
///
/// ## Web Implementation
///
/// In Raven's web environment, `TapGesture` maps to the `click` event:
/// - Single tap: Triggered on the first `click` event
/// - Multi-tap: Uses the `detail` property of the MouseEvent to detect multiple clicks
///   within the browser's double-click timeout
///
/// The implementation listens for:
/// - `click` events for tap detection
/// - `detail` property to count sequential taps
///
/// ## Performance Considerations
///
/// Tap gestures are lightweight and have minimal performance impact. The gesture
/// system automatically:
/// - Registers event listeners only when needed
/// - Cleans up listeners when views are unmounted
/// - Handles event delegation for better performance
///
/// ## Accessibility
///
/// Tap gestures automatically work with keyboard navigation:
/// - Enter key triggers tap on focused elements
/// - Space key triggers tap on buttons and other interactive elements
///
/// For the best accessibility, prefer using `Button` for tap interactions when possible,
/// as it provides built-in keyboard and screen reader support.
///
/// ## Thread Safety
///
/// `TapGesture` is `@MainActor` isolated and `Sendable`, ensuring thread-safe usage
/// in SwiftUI's concurrent environment. All gesture callbacks execute on the main actor.
///
/// ## See Also
///
/// - ``SpatialTapGesture``
/// - ``LongPressGesture``
/// - ``Gesture``
/// - ``GestureMask``
@MainActor
public struct TapGesture: Gesture, Sendable {
    /// The type of value produced by this gesture.
    ///
    /// Tap gestures produce no value - they simply indicate that a tap occurred.
    public typealias Value = Void

    /// The type representing the body of this gesture.
    ///
    /// `TapGesture` is a primitive gesture and has no body.
    public typealias Body = Never

    /// The number of taps required to complete the gesture.
    ///
    /// Defaults to 1 for a single tap. Set to 2 for double-tap, 3 for triple-tap, etc.
    public let count: Int

    /// Creates a tap gesture with the specified number of required taps.
    ///
    /// Example:
    /// ```swift
    /// // Single tap (default)
    /// TapGesture()
    ///
    /// // Double tap
    /// TapGesture(count: 2)
    ///
    /// // Triple tap
    /// TapGesture(count: 3)
    /// ```
    ///
    /// - Parameter count: The number of sequential taps required to trigger the gesture.
    ///   Must be at least 1. Defaults to 1.
    public init(count: Int = 1) {
        self.count = max(1, count)
    }
}

// MARK: - Web Event Mapping

extension TapGesture {
    /// The name of the DOM event that triggers this gesture.
    ///
    /// For tap gestures, we use the `click` event which fires after a complete
    /// tap (mousedown + mouseup on the same element).
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
}

// MARK: - Documentation Examples

/*
 Example: Basic single tap

 ```swift
 struct ContentView: View {
     @State private var tapCount = 0

     var body: some View {
         Text("Taps: \(tapCount)")
             .gesture(
                 TapGesture()
                     .onEnded {
                         tapCount += 1
                     }
             )
     }
 }
 ```

 Example: Double tap to like

 ```swift
 struct PhotoView: View {
     @State private var isLiked = false

     var body: some View {
         Image("photo")
             .overlay(
                 Image(systemName: "heart.fill")
                     .foregroundColor(.red)
                     .opacity(isLiked ? 1 : 0)
             )
             .gesture(
                 TapGesture(count: 2)
                     .onEnded {
                         isLiked.toggle()
                     }
             )
     }
 }
 ```

 Example: Different actions for single and double tap

 ```swift
 struct SmartTapView: View {
     @State private var singleTapCount = 0
     @State private var doubleTapCount = 0

     var body: some View {
         VStack {
             Text("Single: \(singleTapCount), Double: \(doubleTapCount)")
         }
         .gesture(
             TapGesture(count: 2)
                 .onEnded {
                     doubleTapCount += 1
                 }
                 .exclusively(before:
                     TapGesture()
                         .onEnded {
                             singleTapCount += 1
                         }
                 )
         )
     }
 }
 ```
 */
