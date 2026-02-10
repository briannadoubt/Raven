import Foundation

/// A visual separator line that can be used to divide content.
///
/// `Divider` is a primitive view that creates a thin line to visually separate
/// content in layouts. It's rendered as a `div` element with border styling.
/// By default, it creates a horizontal line that spans the full width with a
/// 1px solid border in a system gray color.
///
/// Example:
/// ```swift
/// VStack {
///     Text("Section 1")
///     Divider()
///     Text("Section 2")
/// }
/// ```
///
/// In a vertical stack (VStack), Divider creates a horizontal line.
/// In a horizontal stack (HStack), it can also be used to create a visual break.
///
/// The divider automatically adapts to the available space and styling of its container.
public struct Divider: View, PrimitiveView, Sendable {
    public typealias Body = Never

    // MARK: - Initializers

    /// Creates a divider.
    public init() {
        // No configuration needed for basic divider
    }

    // MARK: - VNode Conversion

    /// Converts this Divider to a virtual DOM node.
    ///
    /// The Divider is rendered as a `div` element with border styling:
    /// - Default horizontal divider (1px height, full width)
    /// - Border style: 1px solid with a gray color (#d1d5db - gray-300)
    /// - Uses border-top for horizontal dividers
    /// - Height of 1px to create the visual line
    ///
    /// Note: In a full implementation, we could detect the parent stack direction
    /// to automatically switch between horizontal and vertical dividers. For now,
    /// we default to horizontal dividers which work well in VStacks.
    ///
    /// - Returns: A VNode configured as a divider line.
    @MainActor public func toVNode() -> VNode {
        let props: [String: VProperty] = [
            // Use border-top for the divider line
            "border-top": .style(name: "border-top", value: "1px solid var(--system-separator)"),
            // Set height to 0 and rely on border for the visual line
            "height": .style(name: "height", value: "0"),
            // Full width
            "width": .style(name: "width", value: "100%"),
            // Add small vertical margins for spacing
            "margin-top": .style(name: "margin-top", value: "0"),
            "margin-bottom": .style(name: "margin-bottom", value: "0"),
            // Ensure it doesn't grow or shrink in flex layouts
            "flex-shrink": .style(name: "flex-shrink", value: "0")
        ]

        // Return div with border styling
        return VNode.element(
            "div",
            props: props,
            children: []
        )
    }
}
