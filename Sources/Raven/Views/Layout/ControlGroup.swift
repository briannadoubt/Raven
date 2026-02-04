import Foundation

/// A container that groups related controls with a segmented appearance.
///
/// `ControlGroup` is a primitive view that arranges related controls (buttons, toggles, etc.)
/// in a horizontal layout with automatic styling to indicate they are grouped together.
/// The grouped controls appear as a single cohesive unit.
///
/// ## Overview
///
/// Use `ControlGroup` to create button groups, toggle groups, or other related controls
/// that should be visually presented as a unified set. The view automatically applies
/// appropriate styling to indicate the grouping.
///
/// ## Basic Usage
///
/// Create a group of buttons with a segmented appearance:
///
/// ```swift
/// ControlGroup {
///     Button("Bold") { isBold.toggle() }
///     Button("Italic") { isItalic.toggle() }
///     Button("Underline") { isUnderlined.toggle() }
/// }
/// ```
///
/// ## With Toggles
///
/// Group toggle controls together:
///
/// ```swift
/// ControlGroup {
///     Toggle("Wi-Fi", isOn: $wifiEnabled)
///     Toggle("Bluetooth", isOn: $bluetoothEnabled)
///     Toggle("Cellular", isOn: $cellularEnabled)
/// }
/// ```
///
/// ## Mixed Controls
///
/// Combine different control types:
///
/// ```swift
/// ControlGroup {
///     Button("Clear") { clear() }
///     Button("Reset") { reset() }
///     Divider()
///     Button("Settings") { openSettings() }
/// }
/// ```
///
/// ## In Toolbars
///
/// Create a toolbar segment:
///
/// ```swift
/// HStack {
///     ControlGroup {
///         Button(action: zoomOut) {
///             Image(systemName: "minus.magnifyingglass")
///         }
///         Button(action: zoomIn) {
///             Image(systemName: "plus.magnifyingglass")
///         }
///     }
///     Spacer()
///     ControlGroup {
///         Button(action: undo) {
///             Image(systemName: "arrow.uturn.left")
///         }
///         Button(action: redo) {
///             Image(systemName: "arrow.uturn.right")
///         }
///     }
/// }
/// .padding()
/// ```
///
/// ## Best Practices
///
/// - Group logically related controls (e.g., formatting buttons, navigation controls)
/// - Keep the number of controls reasonable (3-5 is ideal)
/// - Use consistent control types within a group when possible
/// - Consider using Dividers to separate groups of related actions within the control group
/// - Provide clear visual indication of the current state for toggle controls
///
/// ## See Also
///
/// - ``Button``
/// - ``Toggle``
/// - ``HStack``
public struct ControlGroup<Content: View>: View, PrimitiveView, Sendable {
    public typealias Body = Never

    /// The grouped control content
    private let content: Content

    // MARK: - Initializers

    /// Creates a control group with the specified content.
    ///
    /// - Parameter content: A view builder that creates the grouped controls.
    ///
    /// Example:
    /// ```swift
    /// ControlGroup {
    ///     Button("Left") { moveLeft() }
    ///     Button("Center") { moveCenter() }
    ///     Button("Right") { moveRight() }
    /// }
    /// ```
    @MainActor public init(
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
    }

    // MARK: - VNode Conversion

    /// Converts this ControlGroup to a virtual DOM node.
    ///
    /// The ControlGroup is rendered as a `<div>` with horizontal flexbox layout and:
    /// - CSS classes indicating segmented styling
    /// - Border and background for visual grouping
    /// - Proper spacing and alignment
    /// - ARIA attributes for accessibility
    ///
    /// - Returns: A VNode configured as a horizontal grouped control container.
    @MainActor public func toVNode() -> VNode {
        // Create the control group container with segmented styling
        let containerProps: [String: VProperty] = [
            "class": .attribute(name: "class", value: "raven-control-group"),
            "role": .attribute(name: "role", value: "group"),
            "style": .style(
                name: "style",
                value: "display: flex; flex-direction: row; border: 1px solid #d0d0d0; border-radius: 4px; overflow: hidden; background-color: #f5f5f5;"
            )
        ]

        return VNode.element(
            "div",
            props: containerProps,
            children: []
        )
    }
}
