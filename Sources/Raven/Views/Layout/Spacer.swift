import Foundation

/// A flexible space that expands to fill available space in a stack layout.
///
/// `Spacer` is a primitive view that creates flexible space along the major axis
/// of a containing stack layout. In a `VStack`, it expands vertically; in an `HStack`,
/// it expands horizontally. It's rendered as a `div` element with `flex-grow: 1`.
///
/// Example:
/// ```swift
/// VStack {
///     Text("Top")
///     Spacer()
///     Text("Bottom")
/// }
/// ```
///
/// You can specify a minimum length to ensure the spacer doesn't shrink below
/// a certain size:
/// ```swift
/// HStack {
///     Text("Left")
///     Spacer(minLength: 20)
///     Text("Right")
/// }
/// ```
///
/// - Parameters:
///   - minLength: The minimum length this spacer can be shrunk to. Defaults to `nil` (no minimum).
public struct Spacer: View, Sendable {
    public typealias Body = Never

    /// The minimum length this spacer can be shrunk to, in pixels
    private let minLength: Double?

    // MARK: - Initializers

    /// Creates a spacer with an optional minimum length.
    ///
    /// - Parameter minLength: The minimum length this spacer can be shrunk to, in pixels.
    ///                        Defaults to `nil` (no minimum).
    public init(minLength: Double? = nil) {
        self.minLength = minLength
    }

    // MARK: - VNode Conversion

    /// Converts this Spacer to a virtual DOM node.
    ///
    /// The Spacer is rendered as a `div` element with flexbox styling:
    /// - `flex-grow: 1` to expand and fill available space
    /// - `flex-shrink: 1` to allow shrinking when needed
    /// - `flex-basis: 0` to start from zero size
    /// - `min-width` or `min-height` if minLength is specified
    ///
    /// Note: The parent stack container determines whether the spacer expands
    /// horizontally (in HStack) or vertically (in VStack) through its flex-direction.
    ///
    /// - Returns: A VNode configured as a flexible spacer.
    @MainActor public func toVNode() -> VNode {
        var props: [String: VProperty] = [
            "flex-grow": .style(name: "flex-grow", value: "1"),
            "flex-shrink": .style(name: "flex-shrink", value: "1"),
            "flex-basis": .style(name: "flex-basis", value: "0")
        ]

        // Add minimum length if specified
        // Note: In a full implementation, we would detect the parent stack direction
        // to determine whether to use min-width or min-height. For now, we apply both
        // to support both horizontal and vertical layouts.
        if let minLength = minLength {
            props["min-width"] = .style(name: "min-width", value: "\(minLength)px")
            props["min-height"] = .style(name: "min-height", value: "\(minLength)px")
        }

        // Return empty div that will expand to fill space
        return VNode.element(
            "div",
            props: props,
            children: []
        )
    }
}
