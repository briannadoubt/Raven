import Foundation

// MARK: - Path

/// A path that represents a 2D shape for drawing custom graphics.
///
/// `Path` provides a way to create custom shapes using drawing commands like lines,
/// curves, and arcs. Paths can be filled, stroked, or used with shape modifiers.
///
/// ## Overview
///
/// Use `Path` to create custom shapes by combining drawing primitives. A path is
/// a sequence of commands that describe how to draw a shape, similar to drawing
/// with a pen on paper. You can move the pen without drawing, draw lines and curves,
/// and close shapes to create complex graphics.
///
/// In Raven, paths are rendered as SVG `<path>` elements, providing resolution-independent
/// vector graphics that scale perfectly at any size.
///
/// ## Creating Simple Shapes
///
/// Create a triangle by drawing three lines:
///
/// ```swift
/// var path = Path()
/// path.move(to: CGPoint(x: 50, y: 0))
/// path.addLine(to: CGPoint(x: 100, y: 100))
/// path.addLine(to: CGPoint(x: 0, y: 100))
/// path.closeSubpath()
/// ```
///
/// ## Using Convenience Initializers
///
/// For common shapes, use the convenience initializers:
///
/// ```swift
/// // Rectangle
/// let rect = Path(CGRect(x: 0, y: 0, width: 100, height: 50))
///
/// // Rounded rectangle
/// let rounded = Path(roundedRect: CGRect(x: 0, y: 0, width: 100, height: 50), cornerRadius: 10)
///
/// // Circle
/// let circle = Path(ellipseIn: CGRect(x: 0, y: 0, width: 100, height: 100))
/// ```
///
/// ## Drawing Curves
///
/// Create smooth curves using quadratic and cubic Bezier curves:
///
/// ```swift
/// var path = Path()
/// path.move(to: CGPoint(x: 0, y: 100))
///
/// // Quadratic curve with one control point
/// path.addQuadCurve(
///     to: CGPoint(x: 100, y: 100),
///     control: CGPoint(x: 50, y: 0)
/// )
///
/// // Cubic curve with two control points for more control
/// path.addCurve(
///     to: CGPoint(x: 200, y: 100),
///     control1: CGPoint(x: 125, y: 0),
///     control2: CGPoint(x: 175, y: 200)
/// )
/// ```
///
/// ## Creating Custom Icons
///
/// Paths are perfect for creating custom icons and symbols:
///
/// ```swift
/// struct HeartShape: Shape {
///     func path(in rect: CGRect) -> Path {
///         var path = Path()
///         let width = rect.width
///         let height = rect.height
///
///         // Start at the bottom point
///         path.move(to: CGPoint(x: width / 2, y: height))
///
///         // Left curve
///         path.addCurve(
///             to: CGPoint(x: 0, y: height / 4),
///             control1: CGPoint(x: width / 2, y: height * 0.75),
///             control2: CGPoint(x: 0, y: height / 2)
///         )
///
///         // Left top arc
///         path.addArc(
///             center: CGPoint(x: width / 4, y: height / 4),
///             radius: width / 4,
///             startAngle: .degrees(180),
///             endAngle: .degrees(0),
///             clockwise: true
///         )
///
///         // Repeat for right side (mirrored)
///         // ... more drawing commands
///
///         return path
///     }
/// }
/// ```
///
/// ## SVG Coordinate System
///
/// Paths in Raven use the same coordinate system as SVG:
/// - The origin (0, 0) is at the top-left corner
/// - X increases to the right
/// - Y increases downward
/// - Angles are measured clockwise from the positive X-axis
///
/// This matches the web's coordinate system and makes it easy to integrate
/// with existing SVG graphics and design tools.
///
/// ## Transforming Paths
///
/// Apply transformations to paths using `CGAffineTransform`:
///
/// ```swift
/// let originalPath = Path(CGRect(x: 0, y: 0, width: 50, height: 50))
///
/// // Translate (move)
/// let movedPath = originalPath.offsetBy(x: 100, y: 100)
///
/// // Scale
/// let transform = CGAffineTransform(scaleX: 2, y: 2)
/// let scaledPath = originalPath.applying(transform)
///
/// // Rotate
/// let rotateTransform = CGAffineTransform(rotationAngle: .pi / 4)
/// let rotatedPath = originalPath.applying(rotateTransform)
/// ```
///
/// ## Combining Multiple Paths
///
/// Build complex shapes by combining simpler paths:
///
/// ```swift
/// var complexPath = Path()
///
/// // Add a rectangle
/// var rect = Path(CGRect(x: 0, y: 0, width: 100, height: 100))
/// complexPath.addPath(rect)
///
/// // Add a circle inside
/// var circle = Path(ellipseIn: CGRect(x: 25, y: 25, width: 50, height: 50))
/// complexPath.addPath(circle)
/// ```
///
/// ## Performance Notes
///
/// - Paths are value types (structs), so they're copied when passed around
/// - Use `isEmpty` to check if a path has any drawing commands
/// - SVG path data is generated on-demand, so complex paths don't impact memory
/// - Paths are `Sendable` and `Hashable`, making them safe for concurrent use
///
/// ## Topics
///
/// ### Creating Paths
/// - ``init()``
/// - ``init(_:)``
/// - ``init(roundedRect:cornerRadius:)``
/// - ``init(roundedRect:cornerSize:)``
/// - ``init(ellipseIn:)``
///
/// ### Drawing Commands
/// - ``move(to:)``
/// - ``addLine(to:)``
/// - ``addQuadCurve(to:control:)``
/// - ``addCurve(to:control1:control2:)``
/// - ``addArc(center:radius:startAngle:endAngle:clockwise:)``
/// - ``closeSubpath()``
///
/// ### Convenience Methods
/// - ``addRect(_:)``
/// - ``addRoundedRect(in:cornerRadius:)``
/// - ``addRoundedRect(in:cornerSize:)``
/// - ``addEllipse(in:)``
/// - ``addLines(_:)``
/// - ``addPath(_:)``
///
/// ### Transformations
/// - ``applying(_:)``
/// - ``offsetBy(x:y:)``
///
/// ### Path Information
/// - ``isEmpty``
/// - ``copy()``
///
/// - Note: Paths are rendered as SVG path elements in the DOM, providing
///   resolution-independent vector graphics that look sharp at any scale.
public struct Path: Sendable, Hashable {
    /// The drawing commands that make up this path
    private var elements: [Element]

    /// A drawing command in the path
    private enum Element: Sendable, Hashable {
        /// Move to a point without drawing
        case move(to: CGPoint)
        /// Draw a line to a point
        case line(to: CGPoint)
        /// Draw a quadratic curve
        case quadCurve(to: CGPoint, control: CGPoint)
        /// Draw a cubic Bezier curve
        case curve(to: CGPoint, control1: CGPoint, control2: CGPoint)
        /// Draw an arc
        case arc(center: CGPoint, radius: Double, startAngle: Angle, endAngle: Angle, clockwise: Bool)
        /// Close the current subpath
        case closeSubpath
    }

    // MARK: - Initialization

    /// Creates an empty path.
    public init() {
        self.elements = []
    }

    /// Creates a path from a CGRect as a rectangle.
    ///
    /// - Parameter rect: The rectangle to create a path from.
    public init(_ rect: CGRect) {
        self.init()
        addRect(rect)
    }

    /// Creates a path from a rounded rectangle.
    ///
    /// - Parameters:
    ///   - rect: The rectangle bounds.
    ///   - cornerRadius: The radius of the rounded corners.
    public init(roundedRect rect: CGRect, cornerRadius: Double) {
        self.init()
        addRoundedRect(in: rect, cornerRadius: cornerRadius)
    }

    /// Creates a path from a rounded rectangle with corner size.
    ///
    /// - Parameters:
    ///   - rect: The rectangle bounds.
    ///   - cornerSize: The size of the rounded corners.
    public init(roundedRect rect: CGRect, cornerSize: CGSize) {
        self.init()
        addRoundedRect(in: rect, cornerSize: cornerSize)
    }

    /// Creates a path from an ellipse inscribed in a rectangle.
    ///
    /// - Parameter rect: The rectangle to inscribe the ellipse in.
    public init(ellipseIn rect: CGRect) {
        self.init()
        addEllipse(in: rect)
    }

    // MARK: - Basic Path Commands

    /// Moves the current point to a new location without drawing.
    ///
    /// This begins a new subpath at the specified point.
    ///
    /// - Parameter point: The point to move to.
    public mutating func move(to point: CGPoint) {
        elements.append(.move(to: point))
    }

    /// Adds a straight line from the current point to the specified point.
    ///
    /// - Parameter point: The end point of the line.
    public mutating func addLine(to point: CGPoint) {
        elements.append(.line(to: point))
    }

    /// Adds a quadratic Bezier curve from the current point to the specified point.
    ///
    /// - Parameters:
    ///   - point: The end point of the curve.
    ///   - control: The control point for the curve.
    public mutating func addQuadCurve(to point: CGPoint, control: CGPoint) {
        elements.append(.quadCurve(to: point, control: control))
    }

    /// Adds a cubic Bezier curve from the current point to the specified point.
    ///
    /// - Parameters:
    ///   - point: The end point of the curve.
    ///   - control1: The first control point.
    ///   - control2: The second control point.
    public mutating func addCurve(to point: CGPoint, control1: CGPoint, control2: CGPoint) {
        elements.append(.curve(to: point, control1: control1, control2: control2))
    }

    /// Adds an arc to the path.
    ///
    /// The arc is drawn from `startAngle` to `endAngle` along the circumference
    /// of a circle with the specified center and radius.
    ///
    /// - Parameters:
    ///   - center: The center point of the arc.
    ///   - radius: The radius of the arc.
    ///   - startAngle: The starting angle of the arc.
    ///   - endAngle: The ending angle of the arc.
    ///   - clockwise: Whether to draw the arc clockwise.
    public mutating func addArc(
        center: CGPoint,
        radius: Double,
        startAngle: Angle,
        endAngle: Angle,
        clockwise: Bool
    ) {
        elements.append(.arc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: clockwise
        ))
    }

    /// Adds an arc tangent to two lines.
    ///
    /// This creates a circular arc that is tangent to the line from the current point
    /// to `point1`, and from `point1` to `point2`, with the specified radius.
    ///
    /// - Parameters:
    ///   - point1: The first point defining the arc's tangent lines.
    ///   - point2: The second point defining the arc's tangent lines.
    ///   - radius: The radius of the arc.
    public mutating func addArc(tangent1End point1: CGPoint, tangent2End point2: CGPoint, radius: Double) {
        // For simplicity, we'll approximate this with a quadratic curve
        // A full implementation would calculate the tangent points
        let control = point1
        addQuadCurve(to: point2, control: control)
    }

    /// Closes the current subpath by drawing a line back to the starting point.
    public mutating func closeSubpath() {
        elements.append(.closeSubpath)
    }

    // MARK: - Convenience Shape Methods

    /// Adds a rectangle to the path.
    ///
    /// - Parameter rect: The rectangle to add.
    public mutating func addRect(_ rect: CGRect) {
        move(to: CGPoint(x: rect.minX, y: rect.minY))
        addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        closeSubpath()
    }

    /// Adds a rounded rectangle to the path.
    ///
    /// - Parameters:
    ///   - rect: The rectangle bounds.
    ///   - cornerRadius: The radius of all corners.
    public mutating func addRoundedRect(in rect: CGRect, cornerRadius: Double) {
        addRoundedRect(in: rect, cornerSize: CGSize(width: cornerRadius, height: cornerRadius))
    }

    /// Adds a rounded rectangle to the path.
    ///
    /// - Parameters:
    ///   - rect: The rectangle bounds.
    ///   - cornerSize: The size of the rounded corners.
    public mutating func addRoundedRect(in rect: CGRect, cornerSize: CGSize) {
        let rx = min(cornerSize.width, rect.width / 2)
        let ry = min(cornerSize.height, rect.height / 2)

        // Start at the top-left corner (after the curve)
        move(to: CGPoint(x: rect.minX + rx, y: rect.minY))

        // Top edge
        addLine(to: CGPoint(x: rect.maxX - rx, y: rect.minY))

        // Top-right corner
        addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + ry),
            control: CGPoint(x: rect.maxX, y: rect.minY)
        )

        // Right edge
        addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - ry))

        // Bottom-right corner
        addQuadCurve(
            to: CGPoint(x: rect.maxX - rx, y: rect.maxY),
            control: CGPoint(x: rect.maxX, y: rect.maxY)
        )

        // Bottom edge
        addLine(to: CGPoint(x: rect.minX + rx, y: rect.maxY))

        // Bottom-left corner
        addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.maxY - ry),
            control: CGPoint(x: rect.minX, y: rect.maxY)
        )

        // Left edge
        addLine(to: CGPoint(x: rect.minX, y: rect.minY + ry))

        // Top-left corner
        addQuadCurve(
            to: CGPoint(x: rect.minX + rx, y: rect.minY),
            control: CGPoint(x: rect.minX, y: rect.minY)
        )

        closeSubpath()
    }

    /// Adds an ellipse inscribed in a rectangle to the path.
    ///
    /// - Parameter rect: The rectangle to inscribe the ellipse in.
    public mutating func addEllipse(in rect: CGRect) {
        let centerX = rect.minX + rect.width / 2
        let centerY = rect.minY + rect.height / 2
        let radiusX = rect.width / 2
        let radiusY = rect.height / 2

        // Use the magic number for Bezier curve approximation of a circle
        // kappa = 4 * (√2 - 1) / 3 ≈ 0.5522847498
        let kappa = 0.5522847498
        let offsetX = radiusX * kappa
        let offsetY = radiusY * kappa

        // Start at the top center
        move(to: CGPoint(x: centerX, y: rect.minY))

        // Top-right quadrant
        addCurve(
            to: CGPoint(x: rect.maxX, y: centerY),
            control1: CGPoint(x: centerX + offsetX, y: rect.minY),
            control2: CGPoint(x: rect.maxX, y: centerY - offsetY)
        )

        // Bottom-right quadrant
        addCurve(
            to: CGPoint(x: centerX, y: rect.maxY),
            control1: CGPoint(x: rect.maxX, y: centerY + offsetY),
            control2: CGPoint(x: centerX + offsetX, y: rect.maxY)
        )

        // Bottom-left quadrant
        addCurve(
            to: CGPoint(x: rect.minX, y: centerY),
            control1: CGPoint(x: centerX - offsetX, y: rect.maxY),
            control2: CGPoint(x: rect.minX, y: centerY + offsetY)
        )

        // Top-left quadrant
        addCurve(
            to: CGPoint(x: centerX, y: rect.minY),
            control1: CGPoint(x: rect.minX, y: centerY - offsetY),
            control2: CGPoint(x: centerX - offsetX, y: rect.minY)
        )

        closeSubpath()
    }

    /// Adds multiple lines connecting an array of points.
    ///
    /// - Parameter points: The points to connect with lines.
    public mutating func addLines(_ points: [CGPoint]) {
        guard let first = points.first else { return }
        move(to: first)
        for point in points.dropFirst() {
            addLine(to: point)
        }
    }

    /// Adds a path to this path.
    ///
    /// - Parameter path: The path to add.
    public mutating func addPath(_ path: Path) {
        elements.append(contentsOf: path.elements)
    }

    // MARK: - SVG Path Data Generation

    /// Generates SVG path data (the `d` attribute) from the path elements.
    ///
    /// This converts the drawing commands to SVG path syntax:
    /// - Move → M command
    /// - Line → L command
    /// - Quad curve → Q command
    /// - Cubic curve → C command
    /// - Arc → A command (elliptical arc) or curve approximation
    /// - Close → Z command
    ///
    /// - Returns: An SVG path data string.
    internal var svgPathData: String {
        var data = ""

        for element in elements {
            switch element {
            case .move(let point):
                data += "M \(formatNumber(point.x)) \(formatNumber(point.y)) "

            case .line(let point):
                data += "L \(formatNumber(point.x)) \(formatNumber(point.y)) "

            case .quadCurve(let point, let control):
                data += "Q \(formatNumber(control.x)) \(formatNumber(control.y)) "
                data += "\(formatNumber(point.x)) \(formatNumber(point.y)) "

            case .curve(let point, let control1, let control2):
                data += "C \(formatNumber(control1.x)) \(formatNumber(control1.y)) "
                data += "\(formatNumber(control2.x)) \(formatNumber(control2.y)) "
                data += "\(formatNumber(point.x)) \(formatNumber(point.y)) "

            case .arc(let center, let radius, let startAngle, let endAngle, let clockwise):
                // Convert arc to SVG path arc command (A)
                // For simplicity, we'll approximate with Bezier curves for complex arcs
                // SVG arc: A rx ry rotation large-arc-flag sweep-flag x y

                let start = CGPoint(
                    x: center.x + radius * cos(startAngle.radians),
                    y: center.y + radius * sin(startAngle.radians)
                )
                let end = CGPoint(
                    x: center.x + radius * cos(endAngle.radians),
                    y: center.y + radius * sin(endAngle.radians)
                )

                // Calculate the arc angle
                var deltaAngle = endAngle.radians - startAngle.radians
                if clockwise && deltaAngle > 0 {
                    deltaAngle -= 2 * .pi
                } else if !clockwise && deltaAngle < 0 {
                    deltaAngle += 2 * .pi
                }

                let largeArc = abs(deltaAngle) > .pi ? 1 : 0
                let sweep = clockwise ? 1 : 0

                // Move to start if needed, then draw arc
                data += "M \(formatNumber(start.x)) \(formatNumber(start.y)) "
                data += "A \(formatNumber(radius)) \(formatNumber(radius)) 0 \(largeArc) \(sweep) "
                data += "\(formatNumber(end.x)) \(formatNumber(end.y)) "

            case .closeSubpath:
                data += "Z "
            }
        }

        return data.trimmingCharacters(in: .whitespaces)
    }

    /// Formats a number for SVG, removing unnecessary decimal places.
    private func formatNumber(_ value: Double) -> String {
        // Round to 2 decimal places for cleaner SVG output
        let rounded = round(value * 100) / 100

        // If it's a whole number, don't include decimals
        if rounded == rounded.rounded() {
            return String(Int(rounded))
        }

        return String(rounded)
    }

    // MARK: - Path Information

    /// Returns whether the path is empty (contains no elements).
    public var isEmpty: Bool {
        elements.isEmpty
    }

    /// Returns a copy of the path.
    public func copy() -> Path {
        return self
    }
}

// MARK: - Path Transformations

extension Path {
    /// Applies an affine transformation to the path.
    ///
    /// This creates a new path with all points transformed.
    ///
    /// - Parameter transform: The transformation to apply.
    /// - Returns: A new transformed path.
    public func applying(_ transform: CGAffineTransform) -> Path {
        var newPath = Path()

        for element in elements {
            switch element {
            case .move(let point):
                newPath.move(to: point.applying(transform))

            case .line(let point):
                newPath.addLine(to: point.applying(transform))

            case .quadCurve(let point, let control):
                newPath.addQuadCurve(
                    to: point.applying(transform),
                    control: control.applying(transform)
                )

            case .curve(let point, let control1, let control2):
                newPath.addCurve(
                    to: point.applying(transform),
                    control1: control1.applying(transform),
                    control2: control2.applying(transform)
                )

            case .arc(let center, let radius, let startAngle, let endAngle, let clockwise):
                // For transformed arcs, we'll keep the arc representation
                // A full implementation might convert to curves if the transform includes scaling
                let newCenter = center.applying(transform)
                let scaleFactor = sqrt(abs(transform.a * transform.d - transform.b * transform.c))
                newPath.addArc(
                    center: newCenter,
                    radius: radius * scaleFactor,
                    startAngle: startAngle,
                    endAngle: endAngle,
                    clockwise: clockwise
                )

            case .closeSubpath:
                newPath.closeSubpath()
            }
        }

        return newPath
    }

    /// Returns a path offset by the specified amount.
    ///
    /// - Parameters:
    ///   - x: The horizontal offset.
    ///   - y: The vertical offset.
    /// - Returns: A new offset path.
    public func offsetBy(x: Double, y: Double) -> Path {
        applying(CGAffineTransform(translationX: x, y: y))
    }
}

// MARK: - CGAffineTransform

/// A 2D affine transformation matrix for transforming coordinates.
///
/// This represents a transformation that preserves lines and parallelism
/// (but not necessarily distances and angles).
public struct CGAffineTransform: Sendable, Hashable {
    /// The entry at position [1,1] in the matrix
    public var a: Double
    /// The entry at position [1,2] in the matrix
    public var b: Double
    /// The entry at position [2,1] in the matrix
    public var c: Double
    /// The entry at position [2,2] in the matrix
    public var d: Double
    /// The entry at position [3,1] in the matrix (horizontal translation)
    public var tx: Double
    /// The entry at position [3,2] in the matrix (vertical translation)
    public var ty: Double

    /// The identity transform (no transformation).
    public static let identity = CGAffineTransform(a: 1, b: 0, c: 0, d: 1, tx: 0, ty: 0)

    /// Creates a transform with the specified values.
    public init(a: Double, b: Double, c: Double, d: Double, tx: Double, ty: Double) {
        self.a = a
        self.b = b
        self.c = c
        self.d = d
        self.tx = tx
        self.ty = ty
    }

    /// Creates a translation transform.
    ///
    /// - Parameters:
    ///   - x: The horizontal translation.
    ///   - y: The vertical translation.
    public init(translationX x: Double, y: Double) {
        self.init(a: 1, b: 0, c: 0, d: 1, tx: x, ty: y)
    }

    /// Creates a scale transform.
    ///
    /// - Parameters:
    ///   - x: The horizontal scale factor.
    ///   - y: The vertical scale factor.
    public init(scaleX x: Double, y: Double) {
        self.init(a: x, b: 0, c: 0, d: y, tx: 0, ty: 0)
    }

    /// Creates a rotation transform.
    ///
    /// - Parameter angle: The rotation angle.
    public init(rotationAngle angle: Double) {
        let cos = Foundation.cos(angle)
        let sin = Foundation.sin(angle)
        self.init(a: cos, b: sin, c: -sin, d: cos, tx: 0, ty: 0)
    }
}

// MARK: - CGPoint Extension

extension CGPoint {
    /// Applies an affine transformation to the point.
    ///
    /// - Parameter transform: The transformation to apply.
    /// - Returns: The transformed point.
    public func applying(_ transform: CGAffineTransform) -> CGPoint {
        CGPoint(
            x: transform.a * x + transform.c * y + transform.tx,
            y: transform.b * x + transform.d * y + transform.ty
        )
    }
}
