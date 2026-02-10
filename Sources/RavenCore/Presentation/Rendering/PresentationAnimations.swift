import Foundation

/// CSS animation definitions for presentation transitions.
///
/// This module provides CSS keyframe animations and transition utilities
/// for sheet, alert, popover, and other presentation types. All animations
/// use hardware-accelerated transforms and opacity for optimal performance.
///
/// ## Animation Types
///
/// - **Slide Animations**: For sheets and popovers sliding in from edges
/// - **Fade Animations**: For alerts and backdrop overlays
/// - **Scale Animations**: For popover and confirmation dialog entrances
/// - **Dismiss Animations**: Reverse versions of entrance animations
///
/// ## Usage
///
/// Animations are applied via CSS classes and data attributes on dialog elements:
///
/// ```swift
/// let node = VNode.element("dialog", props: [
///     "class": .attribute(name: "class", value: "raven-dialog raven-sheet"),
///     "data-animation": .attribute(name: "data-animation", value: "slide-up")
/// ])
/// ```
@MainActor
public struct PresentationAnimations: Sendable {
    // MARK: - Animation Duration Constants

    /// Standard animation duration in milliseconds
    public static let standardDuration: Int = 300

    /// Fast animation duration for dismissals
    public static let fastDuration: Int = 200

    /// Slow animation duration for complex presentations
    public static let slowDuration: Int = 400

    /// Backdrop fade duration
    public static let backdropDuration: Int = 250

    // MARK: - Easing Functions

    /// Cubic bezier easing for natural motion
    public static let easeOut = "cubic-bezier(0.25, 0.46, 0.45, 0.94)"

    /// Spring-like easing for sheet presentations
    public static let springEasing = "cubic-bezier(0.34, 1.56, 0.64, 1)"

    /// Smooth easing for fade transitions
    public static let smoothEasing = "cubic-bezier(0.4, 0.0, 0.2, 1)"

    // MARK: - CSS Generation

    /// Generates the complete CSS stylesheet for presentation animations.
    ///
    /// This method returns a comprehensive CSS string that includes:
    /// - Keyframe animations for all presentation types
    /// - Dialog element base styles
    /// - Animation utility classes
    /// - Backdrop styling
    ///
    /// The CSS should be injected into the document head on application startup.
    ///
    /// - Returns: Complete CSS stylesheet as a string
    public static func generateStylesheet() -> String {
        return """
        /* Raven Presentation System Animations */

        /* Base Dialog Styles */
        dialog.raven-dialog {
            border: none;
            padding: 0;
            margin: 0;
            background: transparent;
            max-width: none;
            max-height: none;
            overflow: visible;
        }

        dialog.raven-dialog::backdrop {
            background-color: rgba(0, 0, 0, 0.5);
            animation: raven-backdrop-fade-in \(backdropDuration)ms \(smoothEasing) forwards;
        }

        dialog.raven-dialog[data-dismissing]::backdrop {
            animation: raven-backdrop-fade-out \(backdropDuration)ms \(smoothEasing) forwards;
        }

        /* Sheet Presentation */
        dialog.raven-sheet {
            position: fixed;
            bottom: 0;
            left: 0;
            right: 0;
            background: white;
            border-radius: 16px 16px 0 0;
            box-shadow: 0 -2px 20px rgba(0, 0, 0, 0.15);
            transform-origin: bottom center;
            animation: raven-slide-up \(standardDuration)ms \(springEasing) forwards;
        }

        dialog.raven-sheet[data-dismissing] {
            animation: raven-slide-down \(fastDuration)ms \(easeOut) forwards;
        }

        /* Alert Presentation */
        dialog.raven-alert {
            position: fixed;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            background: white;
            border-radius: 12px;
            box-shadow: 0 4px 30px rgba(0, 0, 0, 0.2);
            min-width: 280px;
            max-width: 90vw;
            animation: raven-alert-appear \(standardDuration)ms \(smoothEasing) forwards;
        }

        dialog.raven-alert[data-dismissing] {
            animation: raven-alert-disappear \(fastDuration)ms \(smoothEasing) forwards;
        }

        /* Popover Presentation */
        dialog.raven-popover {
            position: fixed;
            background: white;
            border-radius: 8px;
            box-shadow: 0 2px 16px rgba(0, 0, 0, 0.15);
            border: 1px solid rgba(0, 0, 0, 0.1);
            animation: raven-popover-appear \(fastDuration)ms \(smoothEasing) forwards;
        }

        dialog.raven-popover[data-dismissing] {
            animation: raven-popover-disappear \(fastDuration)ms \(smoothEasing) forwards;
        }

        /* Full Screen Cover */
        dialog.raven-fullscreen {
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: white;
            animation: raven-fade-in \(standardDuration)ms \(smoothEasing) forwards;
        }

        dialog.raven-fullscreen[data-dismissing] {
            animation: raven-fade-out \(fastDuration)ms \(smoothEasing) forwards;
        }

        /* Confirmation Dialog */
        dialog.raven-confirmation {
            position: fixed;
            bottom: 20px;
            left: 50%;
            transform: translateX(-50%);
            background: white;
            border-radius: 12px;
            box-shadow: 0 4px 24px rgba(0, 0, 0, 0.15);
            min-width: 320px;
            max-width: 90vw;
            animation: raven-slide-up-confirmation \(standardDuration)ms \(springEasing) forwards;
        }

        dialog.raven-confirmation[data-dismissing] {
            animation: raven-slide-down \(fastDuration)ms \(easeOut) forwards;
        }

        /* Keyframe Animations */

        /* Backdrop Animations */
        @keyframes raven-backdrop-fade-in {
            from {
                opacity: 0;
            }
            to {
                opacity: 1;
            }
        }

        @keyframes raven-backdrop-fade-out {
            from {
                opacity: 1;
            }
            to {
                opacity: 0;
            }
        }

        /* Sheet Slide Animations */
        @keyframes raven-slide-up {
            from {
                transform: translateY(100%);
                opacity: 0;
            }
            to {
                transform: translateY(0);
                opacity: 1;
            }
        }

        @keyframes raven-slide-down {
            from {
                transform: translateY(0);
                opacity: 1;
            }
            to {
                transform: translateY(100%);
                opacity: 0;
            }
        }

        /* Alert Animations */
        @keyframes raven-alert-appear {
            from {
                transform: translate(-50%, -50%) scale(0.9);
                opacity: 0;
            }
            to {
                transform: translate(-50%, -50%) scale(1);
                opacity: 1;
            }
        }

        @keyframes raven-alert-disappear {
            from {
                transform: translate(-50%, -50%) scale(1);
                opacity: 1;
            }
            to {
                transform: translate(-50%, -50%) scale(0.95);
                opacity: 0;
            }
        }

        /* Popover Animations */
        @keyframes raven-popover-appear {
            from {
                transform: scale(0.95);
                opacity: 0;
            }
            to {
                transform: scale(1);
                opacity: 1;
            }
        }

        @keyframes raven-popover-disappear {
            from {
                transform: scale(1);
                opacity: 1;
            }
            to {
                transform: scale(0.95);
                opacity: 0;
            }
        }

        /* Fade Animations */
        @keyframes raven-fade-in {
            from {
                opacity: 0;
            }
            to {
                opacity: 1;
            }
        }

        @keyframes raven-fade-out {
            from {
                opacity: 1;
            }
            to {
                opacity: 0;
            }
        }

        /* Confirmation Dialog Slide */
        @keyframes raven-slide-up-confirmation {
            from {
                transform: translateX(-50%) translateY(20px);
                opacity: 0;
            }
            to {
                transform: translateX(-50%) translateY(0);
                opacity: 1;
            }
        }

        /* Sheet Drag Indicator */
        .raven-sheet-drag-indicator {
            width: 36px;
            height: 4px;
            background: rgba(0, 0, 0, 0.3);
            border-radius: 2px;
            margin: 8px auto;
        }

        /* Sheet Container */
        .raven-sheet-container {
            max-height: 90vh;
            overflow-y: auto;
            -webkit-overflow-scrolling: touch;
        }

        /* Alert Content */
        .raven-alert-content {
            padding: 20px;
            text-align: center;
        }

        .raven-alert-title {
            font-size: 17px;
            font-weight: 600;
            margin-bottom: 8px;
            color: #000;
        }

        .raven-alert-message {
            font-size: 13px;
            color: #666;
            line-height: 1.4;
        }

        .raven-alert-actions {
            display: flex;
            border-top: 1px solid rgba(0, 0, 0, 0.1);
        }

        .raven-alert-button {
            flex: 1;
            padding: 12px;
            background: none;
            border: none;
            color: #007AFF;
            font-size: 17px;
            cursor: pointer;
            transition: background-color 0.2s;
        }

        .raven-alert-button:hover {
            background-color: rgba(0, 0, 0, 0.05);
        }

        .raven-alert-button:active {
            background-color: rgba(0, 0, 0, 0.1);
        }

        .raven-alert-button + .raven-alert-button {
            border-left: 1px solid rgba(0, 0, 0, 0.1);
        }

        .raven-alert-button-cancel {
            font-weight: 600;
        }

        .raven-alert-button-destructive {
            color: #FF3B30;
        }

        /* Popover Arrow */
        .raven-popover-arrow {
            position: absolute;
            width: 16px;
            height: 16px;
            background: white;
            border: 1px solid rgba(0, 0, 0, 0.1);
            transform: rotate(45deg);
        }

        .raven-popover-arrow-top {
            top: -8px;
            border-bottom: none;
            border-right: none;
        }

        .raven-popover-arrow-bottom {
            bottom: -8px;
            border-top: none;
            border-left: none;
        }

        .raven-popover-arrow-leading {
            left: -8px;
            border-right: none;
            border-bottom: none;
        }

        .raven-popover-arrow-trailing {
            right: -8px;
            border-left: none;
            border-top: none;
        }

        /* Popover Content */
        .raven-popover-content {
            position: relative;
            z-index: 1;
            background: white;
            border-radius: 8px;
            overflow: hidden;
        }

        /* Dark mode support */
        @media (prefers-color-scheme: dark) {
            dialog.raven-sheet {
                background: #1c1c1e;
            }

            dialog.raven-alert {
                background: #1c1c1e;
            }

            dialog.raven-popover {
                background: #1c1c1e;
                border-color: rgba(255, 255, 255, 0.1);
            }

            .raven-popover-arrow {
                background: #1c1c1e;
                border-color: rgba(255, 255, 255, 0.1);
            }

            .raven-popover-content {
                background: #1c1c1e;
            }

            .raven-alert-title {
                color: #fff;
            }

            .raven-alert-message {
                color: #999;
            }
        }

        /* Reduced motion support */
        @media (prefers-reduced-motion: reduce) {
            dialog.raven-dialog,
            dialog.raven-dialog::backdrop {
                animation-duration: 1ms !important;
            }
        }
        """
    }

    /// Injects the presentation animations stylesheet into the document.
    ///
    /// This method should be called once during application initialization
    /// to ensure all presentation animations are available.
    ///
    /// The stylesheet is injected as a `<style>` element with the ID
    /// `raven-presentation-animations` to prevent duplicate injection.
    public static func injectStylesheet() {
        let bridge = DOMBridge.shared

        // Check if stylesheet already exists
        if bridge.getElementById("raven-presentation-animations") != nil {
            return
        }

        // Create style element
        guard let styleElement = bridge.createElement(tag: "style") else {
            print("Warning: Failed to create style element for presentation animations")
            return
        }
        bridge.setAttribute(element: styleElement, name: "id", value: "raven-presentation-animations")
        bridge.setTextContent(element: styleElement, text: generateStylesheet())

        // Append to head
        if let head = bridge.getHead() {
            bridge.appendChild(parent: head, child: styleElement)
        }
    }
}
