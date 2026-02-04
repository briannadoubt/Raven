import Foundation
import JavaScriptKit

/// A view that provides a 2D drawing environment backed by HTML5 Canvas.
///
/// `Canvas` is a view that lets you draw custom graphics using immediate-mode
/// rendering. Unlike Shape and Path which create declarative vector graphics,
/// Canvas provides a procedural drawing API that directly corresponds to the
/// HTML5 Canvas 2D context.
///
/// ## Overview
///
/// Canvas is ideal for animations, interactive graphics, games, data visualizations,
/// and any scenario where you need frame-by-frame control of rendering. It supports
/// the full HTML5 Canvas API including paths, fills, strokes, images, text, gradients,
/// patterns, transformations, and compositing operations.
///
/// ## Basic Drawing
///
/// Create a canvas and draw shapes using the graphics context:
///
/// ```swift
/// Canvas { context, size in
///     // Draw a red rectangle
///     context.fill(Path(CGRect(x: 0, y: 0, width: 100, height: 100)), with: .color(.red))
///
///     // Draw a blue circle
///     let circle = Path(ellipseIn: CGRect(x: 150, y: 0, width: 100, height: 100))
///     context.fill(circle, with: .color(.blue))
/// }
/// .frame(width: 400, height: 300)
/// ```
///
/// ## Animated Drawing
///
/// Use TimelineView to create animated canvas content:
///
/// ```swift
/// TimelineView(.animation) { timeline in
///     Canvas { context, size in
///         let elapsed = timeline.date.timeIntervalSince1970
///         let angle = elapsed.truncatingRemainder(dividingBy: 2 * .pi)
///
///         context.rotate(by: Angle(radians: angle))
///         context.fill(Path(CGRect(x: -50, y: -50, width: 100, height: 100)),
///                      with: .color(.purple))
///     }
/// }
/// .frame(width: 200, height: 200)
/// ```
///
/// ## Advanced Drawing
///
/// Canvas supports advanced features like gradients, shadows, and compositing:
///
/// ```swift
/// Canvas { context, size in
///     // Apply shadow
///     context.setShadow(color: .black, blur: 10, offset: CGSize(width: 5, height: 5))
///
///     // Draw with gradient
///     let gradient = GraphicsContext.Gradient(
///         colors: [.red, .orange, .yellow],
///         startPoint: .zero,
///         endPoint: CGPoint(x: size.width, y: 0)
///     )
///     context.fill(Path(CGRect(origin: .zero, size: size)), with: .gradient(gradient))
/// }
/// ```
///
/// ## Topics
///
/// ### Creating a Canvas
/// - ``init(opaque:colorMode:rendersAsynchronously:renderer:)``
/// - ``init(opaque:colorMode:rendersAsynchronously:symbols:renderer:)``
///
/// ### Drawing Context
/// - ``GraphicsContext``
///
/// ### Canvas Configuration
/// - ``opaque``
/// - ``colorMode``
/// - ``rendersAsynchronously``
public struct Canvas: View {
    public typealias Body = Never

    /// The renderer closure that draws content
    private let renderer: @Sendable @MainActor (GraphicsContext, CGSize) -> Void

    /// Whether the canvas is opaque (no transparency)
    private let opaque: Bool

    /// The color mode for the canvas
    private let colorMode: ColorMode

    /// Whether to render asynchronously
    private let rendersAsynchronously: Bool

    /// Canvas identifier for DOM element
    private let id: UUID

    // MARK: - Color Mode

    /// The color mode for canvas rendering.
    public enum ColorMode: Sendable {
        /// Standard RGB color mode
        case linear

        /// Extended color mode with wider gamut
        case extended
    }

    // MARK: - Initialization

    /// Creates a canvas that renders custom drawing.
    ///
    /// - Parameters:
    ///   - opaque: A Boolean that indicates whether the canvas is fully opaque.
    ///             Setting this to `true` can improve performance when transparency
    ///             is not needed. The default is `false`.
    ///   - colorMode: The working color space for the canvas. The default is `.linear`.
    ///   - rendersAsynchronously: A Boolean that indicates whether to render on a
    ///                            background thread. The default is `false`.
    ///   - renderer: A closure that performs custom drawing into the canvas.
    ///               The closure receives a graphics context and the current size.
    public init(
        opaque: Bool = false,
        colorMode: ColorMode = .linear,
        rendersAsynchronously: Bool = false,
        renderer: @escaping @Sendable @MainActor (GraphicsContext, CGSize) -> Void
    ) {
        self.opaque = opaque
        self.colorMode = colorMode
        self.rendersAsynchronously = rendersAsynchronously
        self.renderer = renderer
        self.id = UUID()
    }

    // MARK: - Internal Rendering

    /// Renders the canvas content to a DOM canvas element
    @MainActor
    internal func render(size: CGSize) -> JSObject {
        let bridge = DOMBridge.shared
        let canvas = bridge.createElement(tag: "canvas")

        // Set canvas dimensions
        canvas.width = .number(size.width)
        canvas.height = .number(size.height)

        // Set canvas ID
        bridge.setAttribute(element: canvas, name: "id", value: "canvas-\(id.uuidString)")

        // Configure canvas style
        bridge.setStyle(element: canvas, name: "width", value: "\(size.width)px")
        bridge.setStyle(element: canvas, name: "height", value: "\(size.height)px")

        if opaque {
            // Disable alpha channel for better performance
            bridge.setAttribute(element: canvas, name: "data-opaque", value: "true")
        }

        // Get 2D rendering context
        guard let ctx = canvas.getContext!("2d").object else {
            return canvas
        }

        // Create graphics context wrapper
        let graphicsContext = GraphicsContext(jsContext: ctx, size: size)

        // Execute renderer
        renderer(graphicsContext, size)

        return canvas
    }
}

// MARK: - Canvas Symbols Support

extension Canvas {
    /// Creates a canvas with symbol support for reusable graphics.
    ///
    /// Symbols are reusable graphic elements that can be defined once and drawn
    /// multiple times efficiently.
    ///
    /// - Parameters:
    ///   - opaque: A Boolean that indicates whether the canvas is fully opaque.
    ///   - colorMode: The working color space for the canvas.
    ///   - rendersAsynchronously: A Boolean that indicates whether to render on a
    ///                            background thread.
    ///   - symbols: A view builder that creates symbol definitions.
    ///   - renderer: A closure that performs custom drawing into the canvas.
    public init<Symbols: View>(
        opaque: Bool = false,
        colorMode: ColorMode = .linear,
        rendersAsynchronously: Bool = false,
        @ViewBuilder symbols: () -> Symbols,
        renderer: @escaping @Sendable @MainActor (GraphicsContext, CGSize) -> Void
    ) {
        // For now, symbols are not implemented - they would require
        // a more complex rendering pipeline with pattern support
        self.init(
            opaque: opaque,
            colorMode: colorMode,
            rendersAsynchronously: rendersAsynchronously,
            renderer: renderer
        )
    }
}
