import Foundation
import JavaScriptKit

/// A repeating pattern for filling or stroking canvas paths.
///
/// `CanvasPattern` represents a tiled pattern created from an image or another canvas.
/// Patterns can repeat horizontally, vertically, or in both directions.
///
/// ## Overview
///
/// Patterns provide an efficient way to fill areas with repeating textures. They're
/// commonly used for backgrounds, textures, and decorative effects.
///
/// ## Creating Patterns
///
/// ```swift
/// Canvas { context, size in
///     // Create a pattern from an image (when image support is added)
///     // let pattern = CanvasPattern(imageURL: "texture.png", repetition: .repeat)
///     // context.fill(Path(CGRect(origin: .zero, size: size)), with: .pattern(pattern))
/// }
/// ```
///
/// ## Repetition Modes
///
/// Patterns can repeat in different ways:
/// - `.repeat`: Repeats horizontally and vertically (default)
/// - `.repeatX`: Repeats only horizontally
/// - `.repeatY`: Repeats only vertically
/// - `.noRepeat`: Does not repeat (shows pattern once)
///
/// ## Topics
///
/// ### Creating Patterns
/// - ``init(imageURL:repetition:)``
/// - ``init(drawing:size:repetition:)``
///
/// ### Repetition Modes
/// - ``Repetition``
public struct CanvasPattern: Sendable {
    /// The pattern source
    let source: Source

    /// How the pattern repeats
    let repetition: Repetition

    // MARK: - Pattern Source

    enum Source: Sendable {
        case image(url: String)
        case drawing(size: CGSize, renderer: @Sendable @MainActor (GraphicsContext) -> Void)
    }

    // MARK: - Repetition Mode

    /// The repetition mode for a pattern.
    public enum Repetition: String, Sendable {
        /// Repeats the pattern horizontally and vertically.
        case `repeat`

        /// Repeats the pattern only horizontally.
        case repeatX = "repeat-x"

        /// Repeats the pattern only vertically.
        case repeatY = "repeat-y"

        /// Does not repeat the pattern.
        case noRepeat = "no-repeat"
    }

    // MARK: - Initialization

    /// Creates a pattern from an image URL.
    ///
    /// - Parameters:
    ///   - imageURL: The URL of the image to use as a pattern.
    ///   - repetition: How the pattern should repeat.
    public init(imageURL: String, repetition: Repetition = .repeat) {
        self.source = .image(url: imageURL)
        self.repetition = repetition
    }

    /// Creates a pattern from a drawing closure.
    ///
    /// This allows creating procedural patterns using Canvas drawing commands.
    ///
    /// - Parameters:
    ///   - size: The size of the pattern tile.
    ///   - repetition: How the pattern should repeat.
    ///   - drawing: A closure that draws the pattern content.
    public init(
        size: CGSize,
        repetition: Repetition = .repeat,
        drawing: @escaping @Sendable @MainActor (GraphicsContext) -> Void
    ) {
        self.source = .drawing(size: size, renderer: drawing)
        self.repetition = repetition
    }

    // MARK: - JavaScript Conversion

    /// Creates a JavaScript CanvasPattern object.
    ///
    /// - Parameter context: The canvas 2D context.
    /// - Returns: A JavaScript pattern object, or nil if creation fails.
    @MainActor
    internal func createJSPattern(context: JSObject) -> JSObject? {
        switch source {
        case .image(let url):
            // Image loading would require async handling
            // For now, this is a placeholder
            return createImagePattern(context: context, url: url)

        case .drawing(let size, let renderer):
            return createDrawingPattern(context: context, size: size, renderer: renderer)
        }
    }

    @MainActor
    private func createImagePattern(context: JSObject, url: String) -> JSObject? {
        // Image pattern creation would require:
        // 1. Loading the image asynchronously
        // 2. Creating a pattern from the loaded image
        // 3. Managing image lifecycle
        //
        // This is a placeholder implementation
        guard let image = JSObject.global.Image.function?.new() else {
            return nil
        }

        image.src = .string(url)

        // Wait for image to load (this is synchronous, but should be async)
        // In a real implementation, this would use a completion handler
        guard let pattern = context.createPattern!(image, repetition.rawValue).object else {
            return nil
        }

        return pattern
    }

    @MainActor
    private func createDrawingPattern(
        context: JSObject,
        size: CGSize,
        renderer: @Sendable @MainActor (GraphicsContext) -> Void
    ) -> JSObject? {
        // Create an offscreen canvas for the pattern
        let bridge = DOMBridge.shared
        let patternCanvas = bridge.createElement(tag: "canvas")
        patternCanvas.width = .number(size.width)
        patternCanvas.height = .number(size.height)

        guard let patternContext = patternCanvas.getContext!("2d").object else {
            return nil
        }

        // Draw the pattern content
        let graphicsContext = GraphicsContext(jsContext: patternContext, size: size)
        renderer(graphicsContext)

        // Create pattern from the canvas
        guard let pattern = context.createPattern!(patternCanvas, repetition.rawValue).object else {
            return nil
        }

        return pattern
    }
}

// MARK: - Common Pattern Presets

extension CanvasPattern {
    /// Creates a checkerboard pattern.
    ///
    /// - Parameters:
    ///   - size: The size of each checker square.
    ///   - color1: The first checker color.
    ///   - color2: The second checker color.
    /// - Returns: A checkerboard pattern.
    public static func checkerboard(
        size: Double,
        color1: Color,
        color2: Color
    ) -> CanvasPattern {
        CanvasPattern(size: CGSize(width: size * 2, height: size * 2)) { context in
            // Draw first checker
            context.fill(
                Path(CGRect(x: 0, y: 0, width: size, height: size)),
                with: .color(color1)
            )

            // Draw second checker
            context.fill(
                Path(CGRect(x: size, y: 0, width: size, height: size)),
                with: .color(color2)
            )

            // Draw third checker
            context.fill(
                Path(CGRect(x: 0, y: size, width: size, height: size)),
                with: .color(color2)
            )

            // Draw fourth checker
            context.fill(
                Path(CGRect(x: size, y: size, width: size, height: size)),
                with: .color(color1)
            )
        }
    }

    /// Creates a diagonal stripe pattern.
    ///
    /// - Parameters:
    ///   - width: The width of each stripe.
    ///   - color1: The first stripe color.
    ///   - color2: The second stripe color.
    ///   - angle: The angle of the stripes.
    /// - Returns: A striped pattern.
    public static func stripes(
        width: Double,
        color1: Color,
        color2: Color,
        angle: Angle = Angle(degrees: 45)
    ) -> CanvasPattern {
        let size = width * 2
        return CanvasPattern(size: CGSize(width: size, height: size)) { context in
            context.saveState()

            // Fill background
            context.fill(
                Path(CGRect(x: 0, y: 0, width: size, height: size)),
                with: .color(color1)
            )

            // Rotate and draw stripes
            context.translateBy(x: size / 2, y: size / 2)
            context.rotate(by: angle)
            context.translateBy(x: -size / 2, y: -size / 2)

            context.fill(
                Path(CGRect(x: 0, y: 0, width: width, height: size)),
                with: .color(color2)
            )

            context.restoreState()
        }
    }

    /// Creates a dot pattern.
    ///
    /// - Parameters:
    ///   - spacing: The spacing between dots.
    ///   - dotSize: The size of each dot.
    ///   - dotColor: The dot color.
    ///   - backgroundColor: The background color.
    /// - Returns: A dot pattern.
    public static func dots(
        spacing: Double,
        dotSize: Double,
        dotColor: Color,
        backgroundColor: Color = .clear
    ) -> CanvasPattern {
        CanvasPattern(size: CGSize(width: spacing, height: spacing)) { context in
            // Fill background
            if backgroundColor != .clear {
                context.fill(
                    Path(CGRect(x: 0, y: 0, width: spacing, height: spacing)),
                    with: .color(backgroundColor)
                )
            }

            // Draw dot
            let dotRect = CGRect(
                x: (spacing - dotSize) / 2,
                y: (spacing - dotSize) / 2,
                width: dotSize,
                height: dotSize
            )
            context.fill(
                Path(ellipseIn: dotRect),
                with: .color(dotColor)
            )
        }
    }

    /// Creates a grid pattern.
    ///
    /// - Parameters:
    ///   - spacing: The spacing between grid lines.
    ///   - lineWidth: The width of grid lines.
    ///   - lineColor: The grid line color.
    ///   - backgroundColor: The background color.
    /// - Returns: A grid pattern.
    public static func grid(
        spacing: Double,
        lineWidth: Double,
        lineColor: Color,
        backgroundColor: Color = .clear
    ) -> CanvasPattern {
        CanvasPattern(size: CGSize(width: spacing, height: spacing)) { context in
            // Fill background
            if backgroundColor != .clear {
                context.fill(
                    Path(CGRect(x: 0, y: 0, width: spacing, height: spacing)),
                    with: .color(backgroundColor)
                )
            }

            // Draw vertical line
            var vPath = Path()
            vPath.move(to: CGPoint(x: 0, y: 0))
            vPath.addLine(to: CGPoint(x: 0, y: spacing))

            context.stroke(vPath, with: .color(lineColor), lineWidth: lineWidth)

            // Draw horizontal line
            var hPath = Path()
            hPath.move(to: CGPoint(x: 0, y: 0))
            hPath.addLine(to: CGPoint(x: spacing, y: 0))

            context.stroke(hPath, with: .color(lineColor), lineWidth: lineWidth)
        }
    }
}
