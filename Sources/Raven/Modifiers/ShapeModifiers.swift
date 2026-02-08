import Foundation

// MARK: - StrokeStyle

/// A style for stroking shapes with customizable line properties.
///
/// `StrokeStyle` defines how the outline of a shape is drawn, including
/// line width, caps, joins, and dash patterns. It provides comprehensive
/// control over stroke appearance, mapping directly to SVG stroke attributes.
///
/// ## Overview
///
/// Use `StrokeStyle` when you need more control over how a shape's outline
/// is rendered than the basic `stroke(_:lineWidth:)` modifier provides.
/// You can customize line endings, corner joins, and create dashed patterns.
///
/// ## Line Caps
///
/// Line caps determine how the ends of open paths are rendered:
/// - `.butt`: Square-ended lines (default)
/// - `.round`: Rounded line endings
/// - `.square`: Square-ended with extra length equal to half the line width
///
/// ## Line Joins
///
/// Line joins determine how corners are rendered:
/// - `.miter`: Sharp, pointed corners (default)
/// - `.round`: Rounded corners
/// - `.bevel`: Flat, beveled corners
///
/// ## Dash Patterns
///
/// Create dashed or dotted lines by specifying an array of dash lengths.
/// The pattern alternates between drawn and empty segments.
///
/// ## Example
///
/// ```swift
/// // Solid stroke with rounded caps
/// Circle()
///     .stroke(.blue, style: StrokeStyle(
///         lineWidth: 4,
///         lineCap: .round
///     ))
///
/// // Dashed line
/// Path { path in
///     path.move(to: CGPoint(x: 0, y: 50))
///     path.addLine(to: CGPoint(x: 200, y: 50))
/// }
/// .stroke(.red, style: StrokeStyle(
///     lineWidth: 2,
///     lineCap: .round,
///     dash: [10, 5]
/// ))
///
/// // Complex pattern with rounded joins
/// RoundedRectangle(cornerRadius: 10)
///     .stroke(.green, style: StrokeStyle(
///         lineWidth: 3,
///         lineJoin: .round,
///         dash: [15, 5, 5, 5],
///         dashPhase: 10
/// ))
/// ```
///
/// ## SVG Rendering
///
/// StrokeStyle properties map directly to SVG stroke attributes:
/// - `lineWidth` → `stroke-width`
/// - `lineCap` → `stroke-linecap`
/// - `lineJoin` → `stroke-linejoin`
/// - `miterLimit` → `stroke-miterlimit`
/// - `dash` → `stroke-dasharray`
/// - `dashPhase` → `stroke-dashoffset`
///
/// ## Topics
///
/// ### Creating Stroke Styles
/// - ``init(lineWidth:lineCap:lineJoin:miterLimit:dash:dashPhase:)``
///
/// ### Line Properties
/// - ``lineWidth``
/// - ``lineCap``
/// - ``lineJoin``
/// - ``miterLimit``
///
/// ### Dash Properties
/// - ``dash``
/// - ``dashPhase``
///
/// ### Enumerations
/// - ``LineCap``
/// - ``LineJoin``
public struct StrokeStyle: Sendable, Hashable {
    /// The width of the stroked line.
    public var lineWidth: CGFloat

    /// The style for rendering the ends of open paths.
    public var lineCap: LineCap

    /// The style for rendering the joins between line segments.
    public var lineJoin: LineJoin

    /// The limit for the ratio of the miter length to the line width.
    ///
    /// When the miter join extends beyond this limit, it's replaced with a bevel join.
    /// This prevents excessively long points at sharp angles.
    public var miterLimit: CGFloat

    /// An array of values defining the dash pattern.
    ///
    /// The array alternates between the length of dashes and gaps.
    /// For example, `[10, 5]` creates a pattern of 10pt dashes with 5pt gaps.
    /// An empty array means a solid line.
    public var dash: [CGFloat]

    /// The offset for the dash pattern.
    ///
    /// Use this to animate dashed lines or offset where the pattern starts.
    public var dashPhase: CGFloat

    /// Creates a stroke style with the specified properties.
    ///
    /// - Parameters:
    ///   - lineWidth: The width of the stroked line. Default is 1.
    ///   - lineCap: The style for line endings. Default is `.butt`.
    ///   - lineJoin: The style for line joins. Default is `.miter`.
    ///   - miterLimit: The miter limit. Default is 10.
    ///   - dash: The dash pattern. Default is `[]` (solid line).
    ///   - dashPhase: The dash pattern offset. Default is 0.
    public init(
        lineWidth: CGFloat = 1,
        lineCap: LineCap = .butt,
        lineJoin: LineJoin = .miter,
        miterLimit: CGFloat = 10,
        dash: [CGFloat] = [],
        dashPhase: CGFloat = 0
    ) {
        self.lineWidth = lineWidth
        self.lineCap = lineCap
        self.lineJoin = lineJoin
        self.miterLimit = miterLimit
        self.dash = dash
        self.dashPhase = dashPhase
    }

    /// The style for rendering line caps (endpoints).
    public enum LineCap: String, Sendable, Hashable {
        /// Square-ended lines at the exact endpoint.
        case butt

        /// Rounded line endings.
        case round

        /// Square-ended lines extending beyond the endpoint.
        case square
    }

    /// The style for rendering line joins (corners).
    public enum LineJoin: String, Sendable, Hashable {
        /// Sharp, pointed corners.
        case miter

        /// Rounded corners.
        case round

        /// Flat, beveled corners.
        case bevel
    }

    /// Generates SVG stroke attributes for this style.
    ///
    /// - Returns: A dictionary of SVG attribute name-value pairs.
    internal func svgAttributes() -> [String: String] {
        var attrs: [String: String] = [
            "stroke-width": String(lineWidth),
            "stroke-linecap": lineCap.rawValue,
            "stroke-linejoin": lineJoin.rawValue
        ]

        // Only add miter limit if using miter joins
        if lineJoin == .miter {
            attrs["stroke-miterlimit"] = String(miterLimit)
        }

        // Add dash pattern if specified
        if !dash.isEmpty {
            let dashArray = dash.map { String($0) }.joined(separator: " ")
            attrs["stroke-dasharray"] = dashArray

            // Only add dash phase if non-zero
            if dashPhase != 0 {
                attrs["stroke-dashoffset"] = String(dashPhase)
            }
        }

        return attrs
    }
}

// MARK: - Enhanced Stroke Modifier

extension Shape {
    /// Strokes the outline of this shape with a style and full stroke configuration.
    ///
    /// Use this modifier when you need more control over the stroke appearance
    /// than the basic `stroke(_:lineWidth:)` provides. You can specify line caps,
    /// joins, dash patterns, and more.
    ///
    /// - Parameters:
    ///   - style: The style to stroke the shape with.
    ///   - strokeStyle: The stroke style configuration.
    /// - Returns: A view that strokes this shape with the specified style.
    ///
    /// ## Example
    ///
    /// ```swift
    /// Circle()
    ///     .stroke(.blue, style: StrokeStyle(
    ///         lineWidth: 4,
    ///         lineCap: .round,
    ///         dash: [10, 5]
    ///     ))
    ///
    /// RoundedRectangle(cornerRadius: 10)
    ///     .stroke(.red, style: StrokeStyle(
    ///         lineWidth: 3,
    ///         lineJoin: .round
    ///     ))
    /// ```
    @MainActor public func stroke<S: ShapeStyle>(
        _ style: S,
        style strokeStyle: StrokeStyle
    ) -> _ShapeStyledStrokeView<Self, S> {
        _ShapeStyledStrokeView(shape: self, style: style, strokeStyle: strokeStyle)
    }
}

// MARK: - Shape Styled Stroke View

/// A view that strokes a shape with a style and full stroke configuration.
///
/// This view is created by the `stroke(_:style:)` modifier on shapes.
public struct _ShapeStyledStrokeView<S: Shape, Style: ShapeStyle>: View, PrimitiveView, Sendable {
    let shape: S
    let style: Style
    let strokeStyle: StrokeStyle

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
        let props: [String: VProperty] = [
            "xmlns": .attribute(name: "xmlns", value: "http://www.w3.org/2000/svg"),
            "width": .attribute(name: "width", value: "100%"),
            "height": .attribute(name: "height", value: "100%"),
            "viewBox": .attribute(name: "viewBox", value: "0 0 100 100"),
            "preserveAspectRatio": .attribute(name: "preserveAspectRatio", value: "none")
        ]

        // Create path element with stroke and stroke style attributes
        var pathProps: [String: VProperty] = [
            "d": .attribute(name: "d", value: shapePath.svgPathData),
            "stroke": .attribute(name: "stroke", value: style.svgStrokeValue()),
            "fill": .attribute(name: "fill", value: "none")
        ]

        // Add stroke style attributes
        for (key, value) in strokeStyle.svgAttributes() {
            pathProps[key] = .attribute(name: key, value: value)
        }

        let pathNode = VNode.element("path", props: pathProps)

        return VNode.element(
            "svg",
            props: props,
            children: defsNode + [pathNode]
        )
    }
}

// MARK: - Trim Modifier

extension Shape {
    /// Trims this shape along its path.
    ///
    /// Use this modifier to show only a portion of the shape's path, which is
    /// particularly useful for creating progress indicators, loading animations,
    /// and reveal effects.
    ///
    /// The trim values range from 0.0 (start of the path) to 1.0 (end of the path).
    /// By animating these values, you can create smooth drawing animations.
    ///
    /// - Parameters:
    ///   - from: The fraction of the path where trimming starts (0.0 to 1.0).
    ///   - to: The fraction of the path where trimming ends (0.0 to 1.0).
    /// - Returns: A view that displays a trimmed portion of this shape.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Show first half of circle
    /// Circle()
    ///     .trim(from: 0.0, to: 0.5)
    ///     .stroke(.blue, lineWidth: 2)
    ///
    /// // Create a progress indicator
    /// Circle()
    ///     .trim(from: 0.0, to: progress)
    ///     .stroke(.green, lineWidth: 4)
    ///     .rotationEffect(.degrees(-90)) // Start at top
    ///
    /// // Animated loading spinner
    /// Circle()
    ///     .trim(from: 0.0, to: 0.7)
    ///     .stroke(.blue, style: StrokeStyle(
    ///         lineWidth: 3,
    ///         lineCap: .round
    ///     ))
    ///     .rotationEffect(.degrees(rotation))
    /// ```
    ///
    /// ## SVG Implementation
    ///
    /// The trim effect is implemented using SVG's `pathLength`, `stroke-dasharray`,
    /// and `stroke-dashoffset` attributes. This provides smooth, GPU-accelerated
    /// rendering with excellent performance.
    ///
    /// ## Animation
    ///
    /// Trim is ideal for animations. Animate the `from` and `to` parameters
    /// to create effects like:
    /// - Progress bars
    /// - Loading spinners
    /// - Drawing/writing animations
    /// - Reveal effects
    ///
    /// - Note: Trim works by manipulating stroke properties, so it's typically
    ///   combined with `stroke()` modifiers. Using trim with `fill()` won't
    ///   have the expected effect.
    @MainActor public func trim(from: CGFloat = 0, to: CGFloat = 1) -> _ShapeTrimView<Self> {
        _ShapeTrimView(shape: self, from: from, to: to)
    }
}

// MARK: - Shape Trim View

/// A view that displays a trimmed portion of a shape.
///
/// This view is created by the `trim(from:to:)` modifier on shapes.
public struct _ShapeTrimView<S: Shape>: View, PrimitiveView, Sendable {
    let shape: S
    let from: CGFloat
    let to: CGFloat

    public typealias Body = Never

    @MainActor public func toVNode() -> VNode {
        // Use a default size that will be overridden by frame modifiers
        let defaultRect = CGRect(x: 0, y: 0, width: 100, height: 100)
        let shapePath = shape.path(in: defaultRect)

        // Calculate trim parameters
        // We use pathLength of 1 for simplicity (0.0 to 1.0 mapping)
        let pathLength = "1"
        let trimStart = from
        let trimEnd = to
        let trimLength = trimEnd - trimStart

        // stroke-dasharray: the visible portion length, then a large gap
        // stroke-dashoffset: offset to position the visible portion correctly
        let dashArray = "\(trimLength) \(1 - trimLength)"
        let dashOffset = String(-trimStart)

        // Create SVG element
        let props: [String: VProperty] = [
            "xmlns": .attribute(name: "xmlns", value: "http://www.w3.org/2000/svg"),
            "width": .attribute(name: "width", value: "100%"),
            "height": .attribute(name: "height", value: "100%"),
            "viewBox": .attribute(name: "viewBox", value: "0 0 100 100"),
            "preserveAspectRatio": .attribute(name: "preserveAspectRatio", value: "none")
        ]

        // Create path element with trim applied via dash pattern
        let pathProps: [String: VProperty] = [
            "d": .attribute(name: "d", value: shapePath.svgPathData),
            "pathLength": .attribute(name: "pathLength", value: pathLength),
            "stroke-dasharray": .attribute(name: "stroke-dasharray", value: dashArray),
            "stroke-dashoffset": .attribute(name: "stroke-dashoffset", value: dashOffset),
            "stroke": .attribute(name: "stroke", value: "currentColor"),
            "stroke-width": .attribute(name: "stroke-width", value: "1"),
            "fill": .attribute(name: "fill", value: "none")
        ]

        let pathNode = VNode.element("path", props: pathProps)

        return VNode.element(
            "svg",
            props: props,
            children: [pathNode]
        )
    }
}

// MARK: - Trim with Fill Support

extension _ShapeFillView {
    /// Trims a filled shape along its path.
    ///
    /// This allows you to apply trim to shapes that have already been filled.
    ///
    /// - Parameters:
    ///   - from: The fraction of the path where trimming starts (0.0 to 1.0).
    ///   - to: The fraction of the path where trimming ends (0.0 to 1.0).
    /// - Returns: A view that displays a trimmed, filled portion of the shape.
    @MainActor public func trim(from: CGFloat = 0, to: CGFloat = 1) -> _ShapeTrimmedFillView<S, Style> {
        _ShapeTrimmedFillView(shape: shape, style: style, from: from, to: to)
    }
}

/// A view that displays a trimmed portion of a filled shape.
public struct _ShapeTrimmedFillView<S: Shape, Style: ShapeStyle>: View, PrimitiveView, Sendable {
    let shape: S
    let style: Style
    let from: CGFloat
    let to: CGFloat

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

        // Calculate trim parameters
        let pathLength = "1"
        let trimLength = to - from
        let dashArray = "\(trimLength) \(1 - trimLength)"
        let dashOffset = String(-from)

        // Create SVG element
        let props: [String: VProperty] = [
            "xmlns": .attribute(name: "xmlns", value: "http://www.w3.org/2000/svg"),
            "width": .attribute(name: "width", value: "100%"),
            "height": .attribute(name: "height", value: "100%"),
            "viewBox": .attribute(name: "viewBox", value: "0 0 100 100"),
            "preserveAspectRatio": .attribute(name: "preserveAspectRatio", value: "none")
        ]

        // For filled shapes, we stroke with the fill color to create the trim effect
        let pathProps: [String: VProperty] = [
            "d": .attribute(name: "d", value: shapePath.svgPathData),
            "pathLength": .attribute(name: "pathLength", value: pathLength),
            "stroke-dasharray": .attribute(name: "stroke-dasharray", value: dashArray),
            "stroke-dashoffset": .attribute(name: "stroke-dashoffset", value: dashOffset),
            "stroke": .attribute(name: "stroke", value: style.svgFillValue()),
            "stroke-width": .attribute(name: "stroke-width", value: "1"),
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

// MARK: - Trim with Stroke Support

extension _ShapeStrokeView {
    /// Trims a stroked shape along its path.
    ///
    /// This allows you to apply trim to shapes that have already been stroked.
    ///
    /// - Parameters:
    ///   - from: The fraction of the path where trimming starts (0.0 to 1.0).
    ///   - to: The fraction of the path where trimming ends (0.0 to 1.0).
    /// - Returns: A view that displays a trimmed, stroked portion of the shape.
    @MainActor public func trim(from: CGFloat = 0, to: CGFloat = 1) -> _ShapeTrimmedStrokeView<S, Style> {
        _ShapeTrimmedStrokeView(shape: shape, style: style, lineWidth: lineWidth, from: from, to: to)
    }
}

/// A view that displays a trimmed portion of a stroked shape.
public struct _ShapeTrimmedStrokeView<S: Shape, Style: ShapeStyle>: View, PrimitiveView, Sendable {
    let shape: S
    let style: Style
    let lineWidth: CGFloat
    let from: CGFloat
    let to: CGFloat

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

        // Calculate trim parameters
        let pathLength = "1"
        let trimLength = to - from
        let dashArray = "\(trimLength) \(1 - trimLength)"
        let dashOffset = String(-from)

        // Create SVG element
        let props: [String: VProperty] = [
            "xmlns": .attribute(name: "xmlns", value: "http://www.w3.org/2000/svg"),
            "width": .attribute(name: "width", value: "100%"),
            "height": .attribute(name: "height", value: "100%"),
            "viewBox": .attribute(name: "viewBox", value: "0 0 100 100"),
            "preserveAspectRatio": .attribute(name: "preserveAspectRatio", value: "none")
        ]

        // Create path element with stroke and trim
        let pathProps: [String: VProperty] = [
            "d": .attribute(name: "d", value: shapePath.svgPathData),
            "pathLength": .attribute(name: "pathLength", value: pathLength),
            "stroke-dasharray": .attribute(name: "stroke-dasharray", value: dashArray),
            "stroke-dashoffset": .attribute(name: "stroke-dashoffset", value: dashOffset),
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

// MARK: - Trim with Styled Stroke Support

extension _ShapeStyledStrokeView {
    /// Trims a stroked shape with full stroke styling along its path.
    ///
    /// This allows you to apply trim to shapes that have been stroked with
    /// a StrokeStyle configuration.
    ///
    /// - Parameters:
    ///   - from: The fraction of the path where trimming starts (0.0 to 1.0).
    ///   - to: The fraction of the path where trimming ends (0.0 to 1.0).
    /// - Returns: A view that displays a trimmed, styled-stroked portion of the shape.
    @MainActor public func trim(from: CGFloat = 0, to: CGFloat = 1) -> _ShapeTrimmedStyledStrokeView<S, Style> {
        _ShapeTrimmedStyledStrokeView(shape: shape, style: style, strokeStyle: strokeStyle, from: from, to: to)
    }
}

/// A view that displays a trimmed portion of a styled-stroked shape.
public struct _ShapeTrimmedStyledStrokeView<S: Shape, Style: ShapeStyle>: View, PrimitiveView, Sendable {
    let shape: S
    let style: Style
    let strokeStyle: StrokeStyle
    let from: CGFloat
    let to: CGFloat

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

        // Calculate trim parameters
        let pathLength = "1"
        let trimLength = to - from

        // Combine trim dash with stroke style dash if present
        var finalDashArray: String
        var finalDashOffset: String

        if strokeStyle.dash.isEmpty {
            // No existing dash pattern, just use trim
            finalDashArray = "\(trimLength) \(1 - trimLength)"
            finalDashOffset = String(-from)
        } else {
            // Existing dash pattern - trim overrides it
            // This matches SwiftUI behavior where trim takes precedence
            finalDashArray = "\(trimLength) \(1 - trimLength)"
            finalDashOffset = String(-from)
        }

        // Create SVG element
        let props: [String: VProperty] = [
            "xmlns": .attribute(name: "xmlns", value: "http://www.w3.org/2000/svg"),
            "width": .attribute(name: "width", value: "100%"),
            "height": .attribute(name: "height", value: "100%"),
            "viewBox": .attribute(name: "viewBox", value: "0 0 100 100"),
            "preserveAspectRatio": .attribute(name: "preserveAspectRatio", value: "none")
        ]

        // Create path element with stroke, stroke style, and trim
        var pathProps: [String: VProperty] = [
            "d": .attribute(name: "d", value: shapePath.svgPathData),
            "pathLength": .attribute(name: "pathLength", value: pathLength),
            "stroke-dasharray": .attribute(name: "stroke-dasharray", value: finalDashArray),
            "stroke-dashoffset": .attribute(name: "stroke-dashoffset", value: finalDashOffset),
            "stroke": .attribute(name: "stroke", value: style.svgStrokeValue()),
            "fill": .attribute(name: "fill", value: "none")
        ]

        // Add stroke style attributes (except dash which is overridden by trim)
        for (key, value) in strokeStyle.svgAttributes() {
            // Skip dash-related attributes as they're handled by trim
            if key != "stroke-dasharray" && key != "stroke-dashoffset" {
                pathProps[key] = .attribute(name: key, value: value)
            }
        }

        let pathNode = VNode.element("path", props: pathProps)

        return VNode.element(
            "svg",
            props: props,
            children: defsNode + [pathNode]
        )
    }
}
