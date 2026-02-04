import Foundation

/// A 2D shape that can be drawn on the screen.
///
/// The `Shape` protocol defines the fundamental interface for all shapes in Raven.
/// Shapes are resolution-independent vector graphics that can be filled, stroked,
/// and transformed. They render as SVG elements in the DOM, providing smooth
/// scaling at any size.
///
/// ## Creating Custom Shapes
///
/// To create a custom shape, conform to the `Shape` protocol and implement the
/// `path(in:)` method. This method receives a rectangle defining the shape's
/// bounds and returns a `Path` describing the shape's outline.
///
/// ```swift
/// struct Triangle: Shape {
///     func path(in rect: CGRect) -> Path {
///         var path = Path()
///         path.move(to: CGPoint(x: rect.midX, y: rect.minY))
///         path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
///         path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
///         path.closeSubpath()
///         return path
///     }
/// }
/// ```
///
/// ## Using Shapes as Views
///
/// Shapes automatically conform to the `View` protocol, so they can be used
/// anywhere a view is expected. By default, shapes are filled with the foreground
/// color, but you can customize their appearance with modifiers.
///
/// ```swift
/// Triangle()
///     .fill(Color.blue)
///     .frame(width: 100, height: 100)
///
/// Circle()
///     .stroke(Color.red, lineWidth: 3)
///     .frame(width: 50, height: 50)
/// ```
///
/// ## SVG Rendering
///
/// In Raven, shapes are rendered as SVG `<path>` elements (or specialized SVG
/// shapes like `<circle>` and `<rect>` for optimized rendering). SVG provides
/// resolution-independent graphics that look sharp on all displays, from mobile
/// phones to 4K monitors.
///
/// ## Built-in Shapes
///
/// Raven includes several common shapes:
/// - ``Circle`` - A circular shape
/// - ``Rectangle`` - A rectangular shape
/// - ``RoundedRectangle`` - A rectangle with rounded corners
/// - ``Capsule`` - A rounded rectangle with fully rounded ends
/// - ``Ellipse`` - An elliptical shape
///
/// ## Topics
///
/// ### Creating Shapes
/// - ``path(in:)``
///
/// ### Styling Shapes
/// - ``fill(_:)``
/// - ``stroke(_:lineWidth:)``
///
/// ### Shape Protocol
/// - ``InsettableShape``
///
/// - Note: Shapes in Raven are rendered using SVG, which provides excellent
///   performance and quality for vector graphics in modern web browsers.
public protocol Shape: View {
    /// Describes the shape's path within the specified rectangle.
    ///
    /// Implement this method to define your shape's outline. The path is
    /// defined relative to the provided rectangle, which represents the
    /// shape's frame.
    ///
    /// - Parameter rect: The rectangle in which to draw the shape.
    /// - Returns: A path representing the shape's outline.
    ///
    /// ## Example
    ///
    /// ```swift
    /// func path(in rect: CGRect) -> Path {
    ///     var path = Path()
    ///     path.addEllipse(in: rect)
    ///     return path
    /// }
    /// ```
    @MainActor func path(in rect: CGRect) -> Path
}

// MARK: - Shape View Conformance

extension Shape {
    /// Shapes have `Never` as their body type because they render directly.
    public typealias Body = Never

    /// Converts this shape to a virtual DOM node.
    ///
    /// This method renders the shape as an SVG element in the DOM.
    /// By default, shapes are rendered with the foreground color fill.
    ///
    /// - Returns: A VNode configured as an SVG shape element.
    @MainActor public func toVNode() -> VNode {
        // Default rendering: create an SVG with the shape's path
        // The actual path is determined by the frame size, which will be
        // provided by the layout system. For now, we use a default size.
        let defaultRect = CGRect(x: 0, y: 0, width: 100, height: 100)
        let shapePath = path(in: defaultRect)

        // Create SVG element
        var props: [String: VProperty] = [
            "xmlns": .attribute(name: "xmlns", value: "http://www.w3.org/2000/svg"),
            "width": .attribute(name: "width", value: "100%"),
            "height": .attribute(name: "height", value: "100%"),
            "viewBox": .attribute(name: "viewBox", value: "0 0 100 100"),
            "preserveAspectRatio": .attribute(name: "preserveAspectRatio", value: "none")
        ]

        // Create path element
        let pathProps: [String: VProperty] = [
            "d": .attribute(name: "d", value: shapePath.svgPathData),
            "fill": .attribute(name: "fill", value: "currentColor")
        ]

        let pathNode = VNode.element("path", props: pathProps)

        return VNode.element(
            "svg",
            props: props,
            children: [pathNode]
        )
    }
}

// MARK: - Shape Modifiers

extension Shape {
    /// Fills this shape with a style.
    ///
    /// Use this modifier to apply a fill style to the shape. The style can be
    /// a solid color, gradient, or other `ShapeStyle` conforming type.
    ///
    /// - Parameter style: The style to fill the shape with.
    /// - Returns: A view that fills this shape.
    ///
    /// ## Example
    ///
    /// ```swift
    /// Circle()
    ///     .fill(Color.blue)
    ///
    /// Rectangle()
    ///     .fill(LinearGradient(
    ///         colors: [.red, .orange],
    ///         angle: .degrees(90)
    ///     ))
    /// ```
    @MainActor public func fill<S: ShapeStyle>(_ style: S) -> _ShapeFillView<Self, S> {
        _ShapeFillView(shape: self, style: style)
    }

    /// Strokes the outline of this shape with a style and line width.
    ///
    /// Use this modifier to draw the shape's outline rather than filling it.
    /// You can specify the stroke color (or gradient) and line width.
    ///
    /// - Parameters:
    ///   - style: The style to stroke the shape with.
    ///   - lineWidth: The width of the stroke line.
    /// - Returns: A view that strokes this shape.
    ///
    /// ## Example
    ///
    /// ```swift
    /// Circle()
    ///     .stroke(Color.red, lineWidth: 2)
    ///
    /// RoundedRectangle(cornerRadius: 10)
    ///     .stroke(Color.black, lineWidth: 3)
    /// ```
    @MainActor public func stroke<S: ShapeStyle>(
        _ style: S,
        lineWidth: CGFloat = 1
    ) -> _ShapeStrokeView<Self, S> {
        _ShapeStrokeView(shape: self, style: style, lineWidth: lineWidth)
    }
}

// MARK: - Shape Fill View

/// A view that fills a shape with a style.
///
/// This view is created by the `fill(_:)` modifier on shapes.
public struct _ShapeFillView<S: Shape, Style: ShapeStyle>: View, Sendable {
    let shape: S
    let style: Style

    public typealias Body = Never

    @MainActor public func toVNode() -> VNode {
        // Use a default size that will be overridden by frame modifiers
        let defaultRect = CGRect(x: 0, y: 0, width: 100, height: 100)
        let shapePath = shape.path(in: defaultRect)

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

        // Create path element with fill
        let pathProps: [String: VProperty] = [
            "d": .attribute(name: "d", value: shapePath.svgPathData),
            "fill": .attribute(name: "fill", value: style.svgFillValue())
        ]

        let pathNode = VNode.element("path", props: pathProps)

        return VNode.element(
            "svg",
            props: props,
            children: defsNode + [pathNode]
        )
    }
}

// MARK: - Shape Stroke View

/// A view that strokes a shape with a style.
///
/// This view is created by the `stroke(_:lineWidth:)` modifier on shapes.
public struct _ShapeStrokeView<S: Shape, Style: ShapeStyle>: View, Sendable {
    let shape: S
    let style: Style
    let lineWidth: CGFloat

    public typealias Body = Never

    @MainActor public func toVNode() -> VNode {
        // Use a default size that will be overridden by frame modifiers
        let defaultRect = CGRect(x: 0, y: 0, width: 100, height: 100)
        let shapePath = shape.path(in: defaultRect)

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

// Note: CGRect, CGPoint, CGSize, and Path are defined in:
// - GeometryReader.swift (CGRect, CGPoint, CGSize for layout)
// - Path.swift (comprehensive Path implementation for drawing)
