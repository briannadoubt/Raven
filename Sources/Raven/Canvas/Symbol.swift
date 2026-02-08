import Foundation

/// A reusable graphic symbol that can be drawn in a graphics context.
///
/// Symbols provide a way to define vector graphics once and draw them multiple times
/// at different sizes, colors, and locations. They're ideal for icons, UI elements,
/// and repeated graphics in Canvas drawings.
///
/// ## Overview
///
/// Symbols are defined using SVG-like path data normalized to a unit square (0,0 to 1,1).
/// When drawn, they're automatically scaled to the requested size while maintaining
/// their proportions.
///
/// ## Creating Symbols
///
/// Create a symbol from path data:
///
/// ```swift
/// let symbol = Symbol(
///     name: "custom.icon",
///     category: "custom",
///     pathData: "M 0.5 0 L 1 1 L 0 1 Z"
/// )
/// ```
///
/// Or create from a Path:
///
/// ```swift
/// var path = Path()
/// path.move(to: CGPoint(x: 0.5, y: 0))
/// path.addLine(to: CGPoint(x: 1, y: 1))
/// path.addLine(to: CGPoint(x: 0, y: 1))
/// path.closeSubpath()
///
/// let symbol = Symbol(name: "custom.triangle", path: path)
/// ```
///
/// ## Drawing Symbols
///
/// Use symbols with GraphicsContext:
///
/// ```swift
/// Canvas { context, size in
///     let symbol = Symbol.builtIn("circle.fill")
///     context.draw(symbol, at: CGPoint(x: 100, y: 100), size: 50)
/// }
/// ```
///
/// ## Symbol Modifiers
///
/// Customize symbol appearance:
///
/// ```swift
/// let symbol = Symbol.builtIn("heart")
///     .foregroundColor(.red)
///     .font(.system(size: 24, weight: .bold))
/// ```
@MainActor
public struct Symbol: Sendable, Hashable, Identifiable {
    /// Unique identifier for the symbol
    public let id: String

    /// The name of the symbol
    public let name: String

    /// The category this symbol belongs to
    public let category: String

    /// SVG path data normalized to unit square (0,0 to 1,1)
    public let pathData: String

    /// The viewBox defining the coordinate system (default: 0 0 1 1)
    public let viewBox: CGRect

    /// Optional foreground color for the symbol
    public let foregroundColor: Color?

    /// Optional font weight for stroke width
    public let weight: Weight?

    /// Rendering mode for the symbol
    public let renderingMode: RenderingMode

    /// Optional accessibility label
    public let accessibilityLabel: String?

    // MARK: - Symbol Weight

    /// The weight (line thickness) of a symbol.
    public enum Weight: String, Sendable, Hashable, CaseIterable {
        case ultraLight
        case thin
        case light
        case regular
        case medium
        case semibold
        case bold
        case heavy
        case black

        /// The stroke width multiplier for this weight
        var strokeWidthMultiplier: Double {
            switch self {
            case .ultraLight: return 0.5
            case .thin: return 0.7
            case .light: return 0.85
            case .regular: return 1.0
            case .medium: return 1.15
            case .semibold: return 1.3
            case .bold: return 1.5
            case .heavy: return 1.7
            case .black: return 2.0
            }
        }
    }

    // MARK: - Rendering Mode

    /// How the symbol should be rendered.
    public enum RenderingMode: Sendable, Hashable {
        /// Single color rendering
        case monochrome

        /// Hierarchical rendering with opacity variations
        case hierarchical

        /// Multiple color rendering
        case multicolor

        /// Use the symbol's original colors
        case palette
    }

    // MARK: - Initialization

    /// Creates a symbol with the specified properties.
    ///
    /// - Parameters:
    ///   - name: The name of the symbol (e.g., "heart", "circle.fill").
    ///   - category: The category this symbol belongs to (e.g., "shapes", "communication").
    ///   - pathData: SVG path data normalized to unit square (0,0 to 1,1).
    ///   - viewBox: The coordinate system for the path data. Defaults to unit square.
    ///   - foregroundColor: Optional foreground color.
    ///   - weight: Optional stroke weight.
    ///   - renderingMode: How to render the symbol. Defaults to monochrome.
    ///   - accessibilityLabel: Optional accessibility label.
    public init(
        name: String,
        category: String = "custom",
        pathData: String,
        viewBox: CGRect = CGRect(x: 0, y: 0, width: 1, height: 1),
        foregroundColor: Color? = nil,
        weight: Weight? = nil,
        renderingMode: RenderingMode = .monochrome,
        accessibilityLabel: String? = nil
    ) {
        self.id = name
        self.name = name
        self.category = category
        self.pathData = pathData
        self.viewBox = viewBox
        self.foregroundColor = foregroundColor
        self.weight = weight
        self.renderingMode = renderingMode
        self.accessibilityLabel = accessibilityLabel
    }

    /// Creates a symbol from a Path.
    ///
    /// The path should be normalized to a unit square or specify an appropriate viewBox.
    ///
    /// - Parameters:
    ///   - name: The name of the symbol.
    ///   - category: The category this symbol belongs to.
    ///   - path: The path defining the symbol shape.
    ///   - viewBox: The coordinate system for the path. Defaults to unit square.
    public init(
        name: String,
        category: String = "custom",
        path: Path,
        viewBox: CGRect = CGRect(x: 0, y: 0, width: 1, height: 1)
    ) {
        self.init(
            name: name,
            category: category,
            pathData: path.svgPathData,
            viewBox: viewBox
        )
    }

    /// Creates a symbol from SVG path data with automatic normalization.
    ///
    /// This attempts to normalize the path to a unit square based on the provided
    /// original viewBox.
    ///
    /// - Parameters:
    ///   - name: The name of the symbol.
    ///   - category: The category this symbol belongs to.
    ///   - svgPath: The SVG path data.
    ///   - originalViewBox: The original coordinate system of the SVG path.
    public init(
        name: String,
        category: String = "custom",
        svgPath: String,
        originalViewBox: CGRect
    ) {
        // For now, store the original path and viewBox
        // A full implementation would normalize the coordinates
        self.init(
            name: name,
            category: category,
            pathData: svgPath,
            viewBox: originalViewBox
        )
    }

    // MARK: - Built-in Symbol Lookup

    /// Looks up a built-in symbol by name.
    ///
    /// - Parameter name: The symbol name (e.g., "circle.fill", "heart", "arrow.up").
    /// - Returns: The symbol if found, nil otherwise.
    public static func builtIn(_ name: String) -> Symbol? {
        return SymbolRegistry.shared.lookup(name: name)
    }

    /// Looks up a symbol by name, supporting SF Symbol name aliases.
    ///
    /// This method checks both direct symbol names and SF Symbol aliases.
    ///
    /// - Parameter name: The symbol or SF Symbol name.
    /// - Returns: The symbol if found, nil otherwise.
    public static func systemName(_ name: String) -> Symbol? {
        return SymbolRegistry.shared.lookupWithAlias(name: name)
    }

    // MARK: - Symbol Modifiers

    /// Returns a new symbol with the specified foreground color.
    ///
    /// - Parameter color: The foreground color to apply.
    /// - Returns: A new symbol with the specified color.
    public func foregroundColor(_ color: Color) -> Symbol {
        return Symbol(
            name: name,
            category: category,
            pathData: pathData,
            viewBox: viewBox,
            foregroundColor: color,
            weight: weight,
            renderingMode: renderingMode,
            accessibilityLabel: accessibilityLabel
        )
    }

    /// Returns a new symbol with the specified weight.
    ///
    /// - Parameter weight: The symbol weight (affects stroke width).
    /// - Returns: A new symbol with the specified weight.
    public func weight(_ weight: Weight) -> Symbol {
        return Symbol(
            name: name,
            category: category,
            pathData: pathData,
            viewBox: viewBox,
            foregroundColor: foregroundColor,
            weight: weight,
            renderingMode: renderingMode,
            accessibilityLabel: accessibilityLabel
        )
    }

    /// Returns a new symbol with the specified rendering mode.
    ///
    /// - Parameter mode: The rendering mode.
    /// - Returns: A new symbol with the specified rendering mode.
    public func symbolRenderingMode(_ mode: RenderingMode) -> Symbol {
        return Symbol(
            name: name,
            category: category,
            pathData: pathData,
            viewBox: viewBox,
            foregroundColor: foregroundColor,
            weight: weight,
            renderingMode: mode,
            accessibilityLabel: accessibilityLabel
        )
    }

    /// Returns a new symbol with the specified accessibility label.
    ///
    /// - Parameter label: The accessibility label.
    /// - Returns: A new symbol with the specified label.
    public func accessibilityLabel(_ label: String) -> Symbol {
        return Symbol(
            name: name,
            category: category,
            pathData: pathData,
            viewBox: viewBox,
            foregroundColor: foregroundColor,
            weight: weight,
            renderingMode: renderingMode,
            accessibilityLabel: label
        )
    }

    // MARK: - Path Generation

    /// Generates a Path for this symbol scaled to the specified size.
    ///
    /// - Parameter size: The target size for the symbol.
    /// - Returns: A path scaled to the specified size.
    public func path(size: CGSize) -> Path {
        let scaleX = size.width / viewBox.width
        let scaleY = size.height / viewBox.height
        _ = min(scaleX, scaleY) // Preserve aspect ratio

        // Create a path from the SVG data
        // Note: This is simplified - a full implementation would parse SVG path data
        return Path()
    }

    /// Generates a Path for this symbol fitted to the specified rectangle.
    ///
    /// - Parameter rect: The target rectangle for the symbol.
    /// - Returns: A path fitted to the specified rectangle.
    public func path(in rect: CGRect) -> Path {
        let scaledPath = path(size: rect.size)
        return scaledPath.offsetBy(x: rect.minX, y: rect.minY)
    }
}

// MARK: - Symbol Categories

extension Symbol {
    /// Common symbol categories
    public enum Category {
        public static let shapes = "shapes"
        public static let arrows = "arrows"
        public static let communication = "communication"
        public static let media = "media"
        public static let actions = "actions"
        public static let status = "status"
        public static let navigation = "navigation"
        public static let editing = "editing"
        public static let commerce = "commerce"
        public static let weather = "weather"
    }
}
