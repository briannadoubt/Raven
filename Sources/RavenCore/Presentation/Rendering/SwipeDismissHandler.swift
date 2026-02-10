import Foundation
import JavaScriptKit

/// Manages swipe-to-dismiss gestures for sheet presentations.
///
/// This handler implements native-like swipe gestures for dismissing sheets,
/// including:
/// - Touch tracking with velocity calculation
/// - Rubber-band physics for over-scroll
/// - Smooth spring animations for release
/// - Cancel and commit thresholds
///
/// ## Usage
///
/// The handler is automatically attached to sheet dialog elements:
///
/// ```swift
/// let handler = SwipeDismissHandler(
///     dialogElement: dialogElement,
///     onDismiss: { coordinator.dismiss(id) }
/// )
/// handler.attach()
/// ```
///
/// ## Gesture Behavior
///
/// - **Swipe Down**: User can drag the sheet downward to dismiss
/// - **Threshold**: Sheet dismisses if dragged past 30% of height or with sufficient velocity
/// - **Rubber Band**: Sheet resists upward dragging with exponential decay
/// - **Spring Release**: Sheet animates back to position if gesture is cancelled
@MainActor
public final class SwipeDismissHandler: Sendable {
    // MARK: - Constants

    /// Minimum distance (in pixels) to recognize as a swipe
    private static let swipeThreshold: Double = 50

    /// Velocity threshold (pixels/ms) to trigger dismiss
    private static let velocityThreshold: Double = 0.5

    /// Percentage of height to dismiss (0.0-1.0)
    private static let dismissThreshold: Double = 0.3

    /// Rubber band resistance factor for over-scroll
    private static let rubberBandFactor: Double = 0.15

    /// Maximum rubber band distance (pixels)
    private static let maxRubberBandDistance: Double = 50

    /// Spring animation duration (ms)
    private static let springDuration: Int = 300

    // MARK: - Properties

    /// The dialog element being tracked
    private let dialogElement: JSObject

    /// Callback invoked when the sheet should dismiss
    private let onDismiss: @Sendable @MainActor () -> Void

    /// Whether dismiss is allowed (can be disabled via modifier)
    private var dismissDisabled: Bool

    /// Touch tracking state
    private var touchState: TouchState?

    /// Event handler closures (retained to prevent deallocation)
    private var touchStartClosure: JSClosure?
    private var touchMoveClosure: JSClosure?
    private var touchEndClosure: JSClosure?

    // MARK: - Touch State

    /// Tracks the state of an active touch gesture
    private struct TouchState {
        /// Starting Y position of the touch
        let startY: Double

        /// Current Y position of the touch
        var currentY: Double

        /// Timestamp of touch start
        let startTime: Double

        /// Previous Y position for velocity calculation
        var previousY: Double

        /// Previous timestamp for velocity calculation
        var previousTime: Double

        /// Initial height of the sheet
        let sheetHeight: Double

        /// Calculated translation distance
        var translation: Double {
            currentY - startY
        }

        /// Calculated velocity (pixels per millisecond)
        var velocity: Double {
            let timeDelta = previousTime - startTime
            guard timeDelta > 0 else { return 0 }
            return (currentY - previousY) / timeDelta
        }

        /// Whether the gesture should trigger dismiss
        @MainActor
        func shouldDismiss() -> Bool {
            // Dismiss if dragged past threshold
            if translation > sheetHeight * SwipeDismissHandler.dismissThreshold {
                return true
            }

            // Dismiss if velocity exceeds threshold
            if velocity > SwipeDismissHandler.velocityThreshold {
                return true
            }

            return false
        }

        /// Apply rubber band effect for negative (upward) translation
        @MainActor
        func rubberBandTranslation() -> Double {
            if translation < 0 {
                // Apply exponential decay for upward dragging
                let resistance = 1.0 - exp(translation / SwipeDismissHandler.maxRubberBandDistance)
                return translation * SwipeDismissHandler.rubberBandFactor * resistance
            }
            return translation
        }
    }

    // MARK: - Initialization

    /// Creates a new swipe dismiss handler.
    ///
    /// - Parameters:
    ///   - dialogElement: The dialog element to attach gestures to
    ///   - dismissDisabled: Whether dismissal is disabled
    ///   - onDismiss: Callback invoked when the sheet should dismiss
    public init(
        dialogElement: JSObject,
        dismissDisabled: Bool = false,
        onDismiss: @escaping @Sendable @MainActor () -> Void
    ) {
        self.dialogElement = dialogElement
        self.dismissDisabled = dismissDisabled
        self.onDismiss = onDismiss
    }

    // MARK: - Public Methods

    /// Attaches touch event handlers to the dialog element.
    ///
    /// This method sets up all necessary event listeners for tracking
    /// swipe gestures. Call this after the element is added to the DOM.
    public func attach() {
        // Create event handler closures
        touchStartClosure = JSClosure { [weak self] args in
            guard let self = self else { return .undefined }
            Task { @MainActor in
                if let event = args.first?.object {
                    self.handleTouchStart(event)
                }
            }
            return .undefined
        }

        touchMoveClosure = JSClosure { [weak self] args in
            guard let self = self else { return .undefined }
            Task { @MainActor in
                if let event = args.first?.object {
                    self.handleTouchMove(event)
                }
            }
            return .undefined
        }

        touchEndClosure = JSClosure { [weak self] args in
            guard let self = self else { return .undefined }
            Task { @MainActor in
                if let event = args.first?.object {
                    self.handleTouchEnd(event)
                }
            }
            return .undefined
        }

        // Add event listeners
        _ = dialogElement.addEventListener!("touchstart", touchStartClosure!)
        _ = dialogElement.addEventListener!("touchmove", touchMoveClosure!)
        _ = dialogElement.addEventListener!("touchend", touchEndClosure!)
        _ = dialogElement.addEventListener!("touchcancel", touchEndClosure!)

        // Also support mouse events for desktop testing
        _ = dialogElement.addEventListener!("mousedown", touchStartClosure!)
    }

    /// Detaches all touch event handlers.
    ///
    /// Call this when the sheet is being removed to clean up resources.
    public func detach() {
        if let closure = touchStartClosure {
            _ = dialogElement.removeEventListener!("touchstart", closure)
            _ = dialogElement.removeEventListener!("mousedown", closure)
        }
        if let closure = touchMoveClosure {
            _ = dialogElement.removeEventListener!("touchmove", closure)
        }
        if let closure = touchEndClosure {
            _ = dialogElement.removeEventListener!("touchend", closure)
            _ = dialogElement.removeEventListener!("touchcancel", closure)
        }

        touchStartClosure = nil
        touchMoveClosure = nil
        touchEndClosure = nil
    }

    /// Updates whether dismissal is disabled.
    ///
    /// - Parameter disabled: Whether to disable swipe-to-dismiss
    public func setDismissDisabled(_ disabled: Bool) {
        dismissDisabled = disabled
    }

    // MARK: - Event Handlers

    /// Handles the start of a touch gesture.
    private func handleTouchStart(_ event: JSObject) {
        guard !dismissDisabled else { return }

        // Get touch position
        let touches = event.touches
        guard let touch = touches[0].object else { return }

        let clientY = touch.clientY.number ?? 0
        let timestamp = JSObject.global.performance.now().number ?? 0

        // Get sheet height
        let height = dialogElement.offsetHeight.number ?? 0

        // Initialize touch state
        touchState = TouchState(
            startY: clientY,
            currentY: clientY,
            startTime: timestamp,
            previousY: clientY,
            previousTime: timestamp,
            sheetHeight: height
        )

        // Disable transitions during dragging
        dialogElement.style.transition = .string("none")
    }

    /// Handles touch movement during a gesture.
    private func handleTouchMove(_ event: JSObject) {
        guard !dismissDisabled, var state = touchState else { return }

        // Get current touch position
        let touches = event.touches
        guard let touch = touches[0].object else { return }

        let clientY = touch.clientY.number ?? 0
        let timestamp = JSObject.global.performance.now().number ?? 0

        // Update state
        state.previousY = state.currentY
        state.previousTime = timestamp
        state.currentY = clientY
        touchState = state

        // Apply rubber band translation
        let translation = state.rubberBandTranslation()

        // Update sheet position
        dialogElement.style.transform = .string("translateY(\(translation)px)")

        // Prevent default scrolling if dragging down
        if state.translation > 0 {
            _ = event.preventDefault!()
        }
    }

    /// Handles the end of a touch gesture.
    private func handleTouchEnd(_ event: JSObject) {
        guard !dismissDisabled, let state = touchState else { return }

        // Clear touch state
        touchState = nil

        // Re-enable transitions
        dialogElement.style.transition = .string("transform \(Self.springDuration)ms cubic-bezier(0.34, 1.56, 0.64, 1)")

        // Decide whether to dismiss or snap back
        if state.shouldDismiss() {
            // Animate dismiss
            let finalTranslation = state.sheetHeight
            dialogElement.style.transform = .string("translateY(\(finalTranslation)px)")

            // Mark as dismissing for backdrop animation
            _ = dialogElement.setAttribute!("data-dismissing", "true")

            // Trigger dismiss after animation
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(Self.springDuration))
                onDismiss()
            }
        } else {
            // Snap back to original position
            dialogElement.style.transform = .string("translateY(0)")
        }
    }
}
