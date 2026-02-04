import Foundation
import JavaScriptKit

/// A 2D drawing destination for custom graphics rendering.
///
/// `GraphicsContext` wraps the HTML5 Canvas 2D context and provides a Swift-friendly
/// API for drawing paths, shapes, images, and text with fills, strokes, gradients,
/// patterns, and transformations.
///
/// ## Overview
///
/// Graphics contexts are provided by Canvas views and should not be created directly.
/// They maintain drawing state including current transformation matrix, fill/stroke
/// styles, line properties, shadows, and compositing settings.
///
/// ## Drawing Paths
///
/// ```swift
/// Canvas { context, size in
///     var path = Path()
///     path.move(to: CGPoint(x: 50, y: 50))
///     path.addLine(to: CGPoint(x: 150, y: 50))
///     path.addLine(to: CGPoint(x: 100, y: 150))
///     path.closeSubpath()
///
///     context.fill(path, with: .color(.blue))
///     context.stroke(path, with: .color(.white), lineWidth: 2)
/// }
/// ```
///
/// ## Transformations
///
/// ```swift
/// context.translateBy(x: 100, y: 100)
/// context.rotate(by: .degrees(45))
/// context.scaleBy(x: 2, y: 2)
/// ```
@MainActor
public struct GraphicsContext: Sendable {
    /// The underlying HTML5 Canvas 2D context
    internal let jsContext: JSObject

    /// The size of the drawing area
    public let size: CGSize

    // MARK: - Initialization

    internal init(jsContext: JSObject, size: CGSize) {
        self.jsContext = jsContext
        self.size = size
    }

    // MARK: - Drawing Operations

    /// Fills a path with the specified shading.
    ///
    /// - Parameters:
    ///   - path: The path to fill.
    ///   - shading: The shading to use for filling.
    public func fill(_ path: Path, with shading: Shading) {
        beginPath()
        addPath(path)
        applyShading(shading, mode: .fill)
        jsContext.fill!()
    }

    /// Strokes a path with the specified shading and line width.
    ///
    /// - Parameters:
    ///   - path: The path to stroke.
    ///   - shading: The shading to use for stroking.
    ///   - lineWidth: The width of the stroke line.
    public func stroke(_ path: Path, with shading: Shading, lineWidth: Double = 1) {
        beginPath()
        addPath(path)
        jsContext.lineWidth = .number(lineWidth)
        applyShading(shading, mode: .stroke)
        jsContext.stroke!()
    }

    /// Fills a path with the specified style and optional stroke.
    ///
    /// - Parameters:
    ///   - path: The path to fill.
    ///   - shading: The shading to use for filling.
    ///   - style: The fill style configuration.
    public func fill(_ path: Path, with shading: Shading, style: FillStyle) {
        beginPath()
        addPath(path)
        applyShading(shading, mode: .fill)

        if style.isEOFilled {
            jsContext.fill!("evenodd")
        } else {
            jsContext.fill!()
        }
    }

    // MARK: - Path Construction

    private func beginPath() {
        jsContext.beginPath!()
    }

    private func addPath(_ path: Path) {
        // Use Path2D API for efficient path rendering
        let path2D = JSObject.global.Path2D.function!.new(path.svgPathData)
        _ = jsContext.addPath!(path2D)
    }

    // MARK: - Shading Application

    private enum ShadingMode {
        case fill
        case stroke
    }

    private func applyShading(_ shading: Shading, mode: ShadingMode) {
        switch shading {
        case .color(let color):
            let cssValue = color.cssValue
            switch mode {
            case .fill:
                jsContext.fillStyle = .string(cssValue)
            case .stroke:
                jsContext.strokeStyle = .string(cssValue)
            }

        case .gradient(let gradient):
            let jsGradient = createGradient(gradient)
            switch mode {
            case .fill:
                jsContext.fillStyle = jsGradient
            case .stroke:
                jsContext.strokeStyle = jsGradient
            }

        case .pattern(let pattern):
            if let jsPattern = createPattern(pattern) {
                switch mode {
                case .fill:
                    jsContext.fillStyle = jsPattern
                case .stroke:
                    jsContext.strokeStyle = jsPattern
                }
            }
        }
    }

    // MARK: - Gradient Creation

    private func createGradient(_ gradient: Gradient) -> JSValue {
        switch gradient.type {
        case .linear:
            let jsGradient = jsContext.createLinearGradient!(
                gradient.startPoint.x,
                gradient.startPoint.y,
                gradient.endPoint.x,
                gradient.endPoint.y
            ).object!

            addColorStops(to: jsGradient, colors: gradient.colors)
            return .object(jsGradient)

        case .radial:
            let radius = gradient.radius ?? 100
            let jsGradient = jsContext.createRadialGradient!(
                gradient.startPoint.x,
                gradient.startPoint.y,
                0,
                gradient.endPoint.x,
                gradient.endPoint.y,
                radius
            ).object!

            addColorStops(to: jsGradient, colors: gradient.colors)
            return .object(jsGradient)
        }
    }

    private func addColorStops(to gradient: JSObject, colors: [Color]) {
        guard !colors.isEmpty else { return }

        for (index, color) in colors.enumerated() {
            let offset = colors.count > 1 ? Double(index) / Double(colors.count - 1) : 0.0
            _ = gradient.addColorStop!(offset, color.cssValue)
        }
    }

    // MARK: - Pattern Creation

    private func createPattern(_ pattern: CanvasPattern) -> JSValue? {
        // Pattern creation would require image loading support
        // For now, return nil and fall back to solid color
        return nil
    }

    // MARK: - Transformations

    /// Translates the coordinate system by the specified offset.
    ///
    /// - Parameters:
    ///   - x: The horizontal translation.
    ///   - y: The vertical translation.
    public func translateBy(x: Double, y: Double) {
        jsContext.translate!(x, y)
    }

    /// Rotates the coordinate system by the specified angle.
    ///
    /// - Parameter angle: The rotation angle.
    public func rotate(by angle: Angle) {
        jsContext.rotate!(angle.radians)
    }

    /// Scales the coordinate system by the specified factors.
    ///
    /// - Parameters:
    ///   - x: The horizontal scale factor.
    ///   - y: The vertical scale factor.
    public func scaleBy(x: Double, y: Double = 1.0) {
        jsContext.scale!(x, y)
    }

    /// Applies an affine transformation to the coordinate system.
    ///
    /// - Parameter transform: The transformation to apply.
    public func concatenate(_ transform: CGAffineTransform) {
        jsContext.transform!(
            transform.a,
            transform.b,
            transform.c,
            transform.d,
            transform.tx,
            transform.ty
        )
    }

    // MARK: - State Management

    /// Saves the current graphics state.
    ///
    /// Call this before making temporary state changes that you want to revert later.
    public func saveState() {
        jsContext.save!()
    }

    /// Restores the most recently saved graphics state.
    ///
    /// This reverts transformations, clip regions, and drawing attributes to their
    /// saved values.
    public func restoreState() {
        jsContext.restore!()
    }

    // MARK: - Clipping

    /// Clips subsequent drawing to the specified path.
    ///
    /// - Parameter path: The clipping path.
    public func clip(to path: Path) {
        beginPath()
        addPath(path)
        jsContext.clip!()
    }

    /// Clips subsequent drawing to the specified rectangle.
    ///
    /// - Parameter rect: The clipping rectangle.
    public func clip(to rect: CGRect) {
        clip(to: Path(rect))
    }

    // MARK: - Line Attributes

    /// Sets the line cap style for stroked paths.
    ///
    /// - Parameter style: The line cap style.
    public func setLineCap(_ style: LineCap) {
        jsContext.lineCap = .string(style.cssValue)
    }

    /// Sets the line join style for stroked paths.
    ///
    /// - Parameter style: The line join style.
    public func setLineJoin(_ style: LineJoin) {
        jsContext.lineJoin = .string(style.cssValue)
    }

    /// Sets the miter limit for line joins.
    ///
    /// - Parameter limit: The miter limit.
    public func setMiterLimit(_ limit: Double) {
        jsContext.miterLimit = .number(limit)
    }

    /// Sets the line dash pattern.
    ///
    /// - Parameters:
    ///   - pattern: An array of dash lengths alternating between dashes and gaps.
    ///   - offset: The offset to start the dash pattern.
    public func setLineDash(_ pattern: [Double], offset: Double = 0) {
        let jsArray = JSObject.global.Array.function!.new()
        for (index, value) in pattern.enumerated() {
            jsArray[index] = .number(value)
        }
        jsContext.setLineDash!(jsArray)
        jsContext.lineDashOffset = .number(offset)
    }

    // MARK: - Shadow

    /// Sets shadow parameters for subsequent drawing operations.
    ///
    /// - Parameters:
    ///   - color: The shadow color.
    ///   - blur: The shadow blur radius.
    ///   - offset: The shadow offset.
    public func setShadow(color: Color, blur: Double = 0, offset: CGSize = CGSize.zero) {
        jsContext.shadowColor = .string(color.cssValue)
        jsContext.shadowBlur = .number(blur)
        jsContext.shadowOffsetX = .number(offset.width)
        jsContext.shadowOffsetY = .number(offset.height)
    }

    /// Clears any active shadow.
    public func clearShadow() {
        jsContext.shadowColor = .string("transparent")
        jsContext.shadowBlur = .number(0)
        jsContext.shadowOffsetX = .number(0)
        jsContext.shadowOffsetY = .number(0)
    }

    // MARK: - Compositing

    /// Sets the global alpha (opacity) for subsequent drawing operations.
    ///
    /// - Parameter alpha: The opacity value from 0.0 (transparent) to 1.0 (opaque).
    public func setOpacity(_ alpha: Double) {
        jsContext.globalAlpha = .number(alpha)
    }

    /// Sets the compositing operation for blending.
    ///
    /// - Parameter operation: The blend mode.
    public func setBlendMode(_ operation: BlendMode) {
        jsContext.globalCompositeOperation = .string(operation.cssValue)
    }

    // MARK: - Clearing

    /// Clears a rectangular region of the canvas.
    ///
    /// - Parameter rect: The rectangle to clear.
    public func clear(_ rect: CGRect) {
        jsContext.clearRect!(rect.minX, rect.minY, rect.width, rect.height)
    }

    /// Clears the entire canvas.
    public func clear() {
        clear(CGRect(origin: CGPoint.zero, size: size))
    }

    // MARK: - Shading Type

    /// A fill or stroke shading.
    public enum Shading: Sendable {
        case color(Color)
        case gradient(Gradient)
        case pattern(CanvasPattern)
    }

    // MARK: - Gradient Type

    /// A gradient for filling or stroking.
    public struct Gradient: Sendable {
        let type: GradientType
        let colors: [Color]
        let startPoint: CGPoint
        let endPoint: CGPoint
        let radius: Double?

        enum GradientType {
            case linear
            case radial
        }

        public init(colors: [Color], startPoint: CGPoint, endPoint: CGPoint) {
            self.type = .linear
            self.colors = colors
            self.startPoint = startPoint
            self.endPoint = endPoint
            self.radius = nil
        }

        public init(colors: [Color], center: CGPoint, startRadius: Double = 0, endRadius: Double) {
            self.type = .radial
            self.colors = colors
            self.startPoint = center
            self.endPoint = center
            self.radius = endRadius
        }
    }

    // MARK: - Line Cap

    public enum LineCap: Sendable {
        case butt
        case round
        case square

        var cssValue: String {
            switch self {
            case .butt: return "butt"
            case .round: return "round"
            case .square: return "square"
            }
        }
    }

    // MARK: - Line Join

    public enum LineJoin: Sendable {
        case miter
        case round
        case bevel

        var cssValue: String {
            switch self {
            case .miter: return "miter"
            case .round: return "round"
            case .bevel: return "bevel"
            }
        }
    }

    // MARK: - Blend Mode

    public enum BlendMode: Sendable {
        case normal
        case multiply
        case screen
        case overlay
        case darken
        case lighten
        case colorDodge
        case colorBurn
        case hardLight
        case softLight
        case difference
        case exclusion
        case hue
        case saturation
        case color
        case luminosity

        var cssValue: String {
            switch self {
            case .normal: return "source-over"
            case .multiply: return "multiply"
            case .screen: return "screen"
            case .overlay: return "overlay"
            case .darken: return "darken"
            case .lighten: return "lighten"
            case .colorDodge: return "color-dodge"
            case .colorBurn: return "color-burn"
            case .hardLight: return "hard-light"
            case .softLight: return "soft-light"
            case .difference: return "difference"
            case .exclusion: return "exclusion"
            case .hue: return "hue"
            case .saturation: return "saturation"
            case .color: return "color"
            case .luminosity: return "luminosity"
            }
        }
    }
}
