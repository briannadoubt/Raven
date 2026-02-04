import Raven

/// Example demonstrating LongPressGesture usage in Raven
///
/// This example shows various use cases for long press gestures:
/// - Basic long press detection
/// - Custom duration thresholds
/// - Custom distance thresholds
/// - Using GestureState to track press state
/// - Combining with visual feedback
@MainActor
struct LongPressGestureExample {

    // MARK: - Basic Long Press

    /// Simple long press gesture with default settings
    static var basicLongPress: some View {
        Text("Long press me")
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            .gesture(
                LongPressGesture()
                    .onEnded { _ in
                        print("Long pressed!")
                    }
            )
    }

    // MARK: - Custom Duration

    /// Long press requiring 2 seconds hold time
    static var customDuration: some View {
        Text("Hold for 2 seconds")
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(8)
            .gesture(
                LongPressGesture(minimumDuration: 2.0)
                    .onEnded { _ in
                        print("Held for 2 seconds!")
                    }
            )
    }

    // MARK: - Custom Distance

    /// Long press with strict movement tolerance (5 points)
    static var customDistance: some View {
        Text("Hold still (5pt tolerance)")
            .padding()
            .background(Color.orange)
            .foregroundColor(.white)
            .cornerRadius(8)
            .gesture(
                LongPressGesture(minimumDuration: 1.0, maximumDistance: 5)
                    .onEnded { _ in
                        print("Long pressed with minimal movement!")
                    }
            )
    }

    // MARK: - With GestureState

    /// Long press with visual feedback using GestureState
    struct VisualFeedbackExample: View {
        @GestureState private var isDetectingLongPress = false
        @State private var completedLongPress = false

        var body: some View {
            Circle()
                .fill(isDetectingLongPress ? Color.yellow : Color.blue)
                .frame(width: 100, height: 100)
                .scaleEffect(completedLongPress ? 1.2 : 1.0)
                .animation(.spring(), value: completedLongPress)
                .gesture(
                    LongPressGesture(minimumDuration: 1.0)
                        .updating($isDetectingLongPress) { currentState, gestureState, transaction in
                            gestureState = currentState
                        }
                        .onEnded { _ in
                            completedLongPress = true
                            // Reset after a delay
                            Task {
                                try? await Task.sleep(nanoseconds: 2_000_000_000)
                                completedLongPress = false
                            }
                        }
                )
        }
    }

    // MARK: - Context Menu Alternative

    /// Using long press as a context menu trigger
    struct ContextMenuExample: View {
        @State private var showMenu = false

        var body: some View {
            VStack {
                Rectangle()
                    .fill(Color.gray)
                    .frame(width: 200, height: 100)
                    .gesture(
                        LongPressGesture()
                            .onEnded { _ in
                                showMenu = true
                            }
                    )

                if showMenu {
                    VStack(alignment: .leading) {
                        Button("Option 1") {
                            print("Option 1")
                            showMenu = false
                        }
                        Button("Option 2") {
                            print("Option 2")
                            showMenu = false
                        }
                        Button("Cancel") {
                            showMenu = false
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)
                    .shadow(radius: 4)
                }
            }
        }
    }

    // MARK: - Quick Press vs Long Press

    /// Distinguishing between quick press and long press
    struct QuickVsLongPress: View {
        @State private var pressType = "No press yet"

        var body: some View {
            VStack(spacing: 20) {
                Text(pressType)
                    .font(.headline)

                Rectangle()
                    .fill(Color.purple)
                    .frame(width: 150, height: 150)
                    .gesture(
                        LongPressGesture(minimumDuration: 0.8)
                            .onEnded { _ in
                                pressType = "Long press!"
                            }
                    )
                    // Note: TapGesture would be added here to detect quick presses
                    // This demonstrates how gestures can work together
            }
        }
    }

    // MARK: - Very Short Duration

    /// Using a very short duration (almost like a delayed tap)
    static var veryShortDuration: some View {
        Text("Tap and hold briefly (0.1s)")
            .padding()
            .background(Color.red)
            .foregroundColor(.white)
            .cornerRadius(8)
            .gesture(
                LongPressGesture(minimumDuration: 0.1)
                    .onEnded { _ in
                        print("Quick hold detected!")
                    }
            )
    }

    // MARK: - Lenient Distance

    /// Using a large distance threshold for accessibility
    static var lenientDistance: some View {
        Text("Long press (tremor-friendly)")
            .padding()
            .background(Color.teal)
            .foregroundColor(.white)
            .cornerRadius(8)
            .gesture(
                LongPressGesture(minimumDuration: 1.0, maximumDistance: 50)
                    .onEnded { _ in
                        print("Accessible long press!")
                    }
            )
    }

    // MARK: - Complete Demo

    /// Complete demonstration with all examples
    static var completeDemo: some View {
        VStack(spacing: 20) {
            Text("LongPressGesture Examples")
                .font(.title)
                .fontWeight(.bold)

            ScrollView {
                VStack(spacing: 15) {
                    Section(header: Text("Basic").font(.headline)) {
                        basicLongPress
                    }

                    Section(header: Text("Custom Settings").font(.headline)) {
                        customDuration
                        customDistance
                    }

                    Section(header: Text("Visual Feedback").font(.headline)) {
                        VisualFeedbackExample()
                    }

                    Section(header: Text("Practical Uses").font(.headline)) {
                        ContextMenuExample()
                        QuickVsLongPress()
                    }

                    Section(header: Text("Accessibility").font(.headline)) {
                        veryShortDuration
                        lenientDistance
                    }
                }
                .padding()
            }
        }
    }
}

// MARK: - Web Implementation Notes

/*
 ## Web Event Mapping

 LongPressGesture maps to the following web events:

 1. **pointerdown**: Captures the initial press
    - Records start position and time
    - Starts timer for minimum duration
    - Sets up movement tracking

 2. **pointermove**: Monitors movement during press
    - Calculates distance from start position
    - Cancels gesture if movement exceeds maximumDistance

 3. **pointerup**: Ends the gesture
    - Checks if minimum duration was met
    - Fires success callback if conditions met
    - Cleans up timer and listeners

 4. **pointercancel**: Cancels the gesture
    - Handles interruptions (scrolling, notifications)
    - Cleans up timer and listeners

 ## Distance Calculation

 Distance is calculated using the Pythagorean theorem:
 ```
 distance = sqrt((x2 - x1)² + (y2 - y1)²)
 ```

 This provides true straight-line distance regardless of movement direction.

 ## Timer Management

 The gesture uses `setTimeout` to track minimum duration:
 - Timer starts on pointerdown
 - Timer is cancelled on pointerup/pointercancel before duration
 - Timer callback marks gesture as successful if not cancelled

 ## Browser Compatibility

 Pointer events are supported in:
 - Chrome/Edge 55+
 - Firefox 59+
 - Safari 13+
 - All modern mobile browsers

 For older browsers, a polyfill would map mouse/touch events to pointer events.

 ## Performance Considerations

 - Movement tracking only occurs during active press
 - Timer cleanup is automatic
 - No memory leaks from event listeners
 - Efficient distance calculations
 */

// MARK: - Usage Patterns

/*
 ## When to Use LongPressGesture

 ✅ Good use cases:
 - Context menus
 - Edit mode activation
 - Revealing hidden options
 - Alternative actions (hold to delete)
 - Interactive tutorials ("hold to continue")

 ❌ Avoid for:
 - Primary actions (use TapGesture)
 - Time-sensitive interactions
 - Actions that need immediate feedback
 - Accessibility-only interfaces (provide alternatives)

 ## Accessibility Best Practices

 1. **Always provide alternatives**:
    - Keyboard shortcuts
    - Explicit buttons
    - Voice commands

 2. **Consider motor limitations**:
    - Use larger maximumDistance for hand tremor
    - Provide visual feedback during hold
    - Allow customizable durations

 3. **Provide feedback**:
    - Visual indication during hold (progress indicator)
    - Haptic feedback when gesture completes
    - Audio cues for screen reader users

 4. **Document behavior**:
    - Clear instructions ("Hold for 2 seconds")
    - Tooltip or help text
    - Consistent patterns across app
 */
