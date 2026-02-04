import Foundation

/// A shape that can be inset to produce another shape.
///
/// Insettable shapes can create smaller or larger versions of themselves by
/// moving their edges inward or outward. This is particularly useful for
/// creating stroke effects that don't extend beyond a shape's bounds.
///
/// ## Understanding Insets
///
/// An inset shape is one where all edges are moved toward or away from the
/// center by a specified amount. Positive inset values move edges inward,
/// making the shape smaller. Negative inset values move edges outward, making
/// the shape larger.
///
/// ## Stroke Borders
///
/// The primary use case for insettable shapes is the `strokeBorder` modifier,
/// which strokes the shape while keeping the stroke entirely inside the shape's
/// bounds. This is achieved by insetting the shape by half the stroke width
/// and then stroking it.
///
/// ```swift
/// Circle()
///     .strokeBorder(Color.blue, lineWidth: 10)
/// ```
///
/// Without insets, a regular stroke would extend half its width beyond the
/// shape's bounds. With `strokeBorder`, the stroke stays entirely within the
/// original bounds.
///
/// ## Creating Custom Insettable Shapes
///
/// To create a custom insettable shape, conform to `InsettableShape` and
/// implement both `path(in:)` and `inset(by:)` methods:
///
/// ```swift
/// struct CustomShape: InsettableShape {
///     var insetAmount: CGFloat = 0
///
///     func path(in rect: CGRect) -> Path {
///         let insetRect = rect.insetBy(dx: insetAmount, dy: insetAmount)
///         var path = Path()
///         // Draw shape in insetRect
///         return path
///     }
///
///     func inset(by amount: CGFloat) -> CustomShape {
///         var shape = self
///         shape.insetAmount += amount
///         return shape
///     }
/// }
/// ```
///
/// ## Topics
///
/// ### Creating Inset Shapes
/// - ``inset(by:)``
///
/// ### Stroke Modifiers
/// - ``strokeBorder(_:lineWidth:)``
///
/// - Note: Many built-in shapes like `Circle`, `RoundedRectangle`, and `Capsule`
///   conform to `InsettableShape`, making them suitable for stroke border effects.
public protocol InsettableShape: Shape {
    /// Returns a new shape that is inset by the specified amount.
    ///
    /// Insetting moves all edges of the shape toward or away from the center.
    /// Positive amounts make the shape smaller, negative amounts make it larger.
    ///
    /// - Parameter amount: The amount to inset the shape. Positive values move
    ///   edges inward, negative values move edges outward.
    /// - Returns: A new shape with edges inset by the specified amount.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let circle = Circle()
    /// let smallerCircle = circle.inset(by: 10)  // 10 points smaller
    /// let largerCircle = circle.inset(by: -10)  // 10 points larger
    /// ```
    @MainActor func inset(by amount: CGFloat) -> Self
}

// MARK: - InsettableShape Modifiers

extension InsettableShape {
    /// Strokes the outline of this shape with a style, fitting the stroke
    /// entirely inside the shape's bounds.
    ///
    /// Unlike the regular `stroke` modifier, `strokeBorder` ensures the stroke
    /// doesn't extend beyond the shape's bounds. This is achieved by insetting
    /// the shape by half the stroke width before stroking it.
    ///
    /// - Parameters:
    ///   - style: The style to stroke the shape with.
    ///   - lineWidth: The width of the stroke line.
    /// - Returns: A view that strokes this shape with a border.
    ///
    /// ## Example
    ///
    /// ```swift
    /// Circle()
    ///     .strokeBorder(Color.blue, lineWidth: 10)
    ///     .frame(width: 100, height: 100)
    /// ```
    ///
    /// This creates a circle with a 10-point blue border that stays entirely
    /// within the 100x100 frame. With a regular `stroke`, the border would
    /// extend 5 points beyond the frame on all sides.
    @MainActor public func strokeBorder<S: ShapeStyle>(
        _ style: S,
        lineWidth: CGFloat = 1
    ) -> _StrokeBorderView<Self, S> {
        _StrokeBorderView(shape: self, style: style, lineWidth: lineWidth)
    }
}

// MARK: - Stroke Border View

/// A view that strokes the border of an insettable shape.
///
/// This view is created by the `strokeBorder(_:lineWidth:)` modifier on
/// insettable shapes.
public struct _StrokeBorderView<S: InsettableShape, Style: ShapeStyle>: View, PrimitiveView, Sendable {
    let shape: S
    let style: Style
    let lineWidth: CGFloat

    public typealias Body = Never

    @MainActor public func toVNode() -> VNode {
        // Inset the shape by half the line width to keep stroke inside bounds
        let insetShape = shape.inset(by: lineWidth / 2)

        // Use a default size that will be overridden by frame modifiers
        let defaultRect = CGRect(x: 0, y: 0, width: 100, height: 100)
        let shapePath = insetShape.path(in: defaultRect)

        // Generate gradient definitions if needed
        let gradientDefs = style.svgDefinitions(id: "gradient")
        let defsNode: [VNode] = gradientDefs.isEmpty ? [] : [
            VNode.element("defs", props: [:], children: [
                VNode(type: .text(gradientDefs))
            ])
        ]

        // Create SVG element
        var props: [String: VProperty] = [
            "xmlns": .attribute(name: "xmlns", value: "http://www.w3.org/2000/svg"),
            "width": .attribute(name: "width", value: "100%"),
            "height": .attribute(name: "height", value: "100%"),
            "viewBox": .attribute(name: "viewBox", value: "0 0 100 100"),
            "preserveAspectRatio": .attribute(name: "preserveAspectRatio", value: "none")
        ]

        // Create path element with stroke
        let pathProps: [String: VProperty] = [
            "d": .attribute(name: "d", value: shapePath.svgPathData),
            "stroke": .attribute(name: "stroke", value: style.svgStrokeValue()),
            "stroke-width": .attribute(name: "stroke-width", value: String(lineWidth)),
            "fill": .attribute(name: "fill", value: "none")
        ]

        let pathNode = VNode.element("path", props: pathProps)

        return VNode.element(
            "svg",
            props: props,
            children: defsNode + [pathNode]
        )
    }
}

// MARK: - CGRect Extension

extension CGRect {
    /// Returns a rectangle that is inset by the specified amounts.
    ///
    /// - Parameters:
    ///   - dx: The amount to inset the rectangle horizontally.
    ///   - dy: The amount to inset the rectangle vertically.
    /// - Returns: A new rectangle inset by the specified amounts.
    public func insetBy(dx: CGFloat, dy: CGFloat) -> CGRect {
        CGRect(
            x: origin.x + dx,
            y: origin.y + dy,
            width: size.width - (dx * 2),
            height: size.height - (dy * 2)
        )
    }
}
