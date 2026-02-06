import Foundation

// MARK: - Gradient Types

/// A linear gradient that transitions between colors along a straight line.
///
/// Linear gradients are defined by a list of color stops and an angle.
///
/// Example:
/// ```swift
/// LinearGradient(
///     colors: [.red, .blue],
///     angle: Angle(degrees: 45)
/// )
/// ```
public struct LinearGradient: Sendable, Hashable {
    /// The colors in the gradient
    public let colors: [Color]

    /// The angle of the gradient line
    public let angle: Angle

    /// Creates a linear gradient with the specified colors and angle.
    ///
    /// - Parameters:
    ///   - colors: The colors to transition between.
    ///   - angle: The angle of the gradient line. Defaults to vertical (180 degrees).
    public init(colors: [Color], angle: Angle = Angle(degrees: 180)) {
        self.colors = colors
        self.angle = angle
    }

    /// Converts this gradient to a CSS linear-gradient string.
    internal var cssValue: String {
        let colorStops = colors.map { $0.cssValue }.joined(separator: ", ")
        return "linear-gradient(\(angle.degrees)deg, \(colorStops))"
    }
}

/// A radial gradient that transitions between colors radiating from a center point.
///
/// Radial gradients are defined by a list of color stops.
///
/// Example:
/// ```swift
/// RadialGradient(
///     colors: [.white, .blue]
/// )
/// ```
public struct RadialGradient: Sendable, Hashable {
    /// The colors in the gradient
    public let colors: [Color]

    /// Creates a radial gradient with the specified colors.
    ///
    /// - Parameter colors: The colors to transition between.
    public init(colors: [Color]) {
        self.colors = colors
    }

    /// Converts this gradient to a CSS radial-gradient string.
    internal var cssValue: String {
        let colorStops = colors.map { $0.cssValue }.joined(separator: ", ")
        return "radial-gradient(circle, \(colorStops))"
    }
}

// Note: Angle type is defined in Modifiers/AdvancedModifiers.swift

/// A representation of a color that can be used in views.
///
/// `Color` provides a way to specify colors using various formats including
/// named colors, RGB values, hex strings, and system colors.
///
/// Example:
/// ```swift
/// Color.red
/// Color.rgb(255, 0, 0)
/// Color.hex("#FF0000")
/// ```
public struct Color: View, PrimitiveView, Sendable, Hashable {
    public typealias Body = Never

    /// The underlying color representation
    private let storage: Storage

    private enum Storage: Sendable, Hashable {
        case rgb(red: Double, green: Double, blue: Double, opacity: Double)
        case hex(String)
        case named(String)
        case cssVariable(String)
        case systemColor(String)
    }

    // MARK: - Initializers

    /// Creates a color from RGB values.
    ///
    /// - Parameters:
    ///   - red: The red component (0.0 to 1.0).
    ///   - green: The green component (0.0 to 1.0).
    ///   - blue: The blue component (0.0 to 1.0).
    ///   - opacity: The opacity (0.0 to 1.0). Defaults to 1.0.
    public init(red: Double, green: Double, blue: Double, opacity: Double = 1.0) {
        self.storage = .rgb(
            red: min(max(red, 0.0), 1.0),
            green: min(max(green, 0.0), 1.0),
            blue: min(max(blue, 0.0), 1.0),
            opacity: min(max(opacity, 0.0), 1.0)
        )
    }

    /// Creates a color from a hex string.
    ///
    /// - Parameter hex: A hex color string (e.g., "#FF0000" or "FF0000").
    public init(hex: String) {
        self.storage = .hex(hex.hasPrefix("#") ? hex : "#\(hex)")
    }

    /// Creates a color from a named CSS color.
    ///
    /// - Parameter name: The CSS color name (e.g., "red", "blue", "transparent").
    private init(named: String) {
        self.storage = .named(named)
    }

    /// Creates a color from a storage value.
    ///
    /// - Parameter storage: The storage representation of the color.
    private init(storage: Storage) {
        self.storage = storage
    }

    /// Creates a color from a CSS custom property (CSS variable).
    ///
    /// Use this to reference CSS variables defined in your stylesheets for theming.
    ///
    /// - Parameter name: The CSS variable name (e.g., "theme-primary").
    /// - Returns: A color that references the CSS variable.
    ///
    /// Example:
    /// ```swift
    /// Color.custom("theme-primary")  // References var(--theme-primary)
    /// ```
    public static func custom(_ name: String) -> Color {
        Color(storage: .cssVariable(name))
    }

    /// Creates a color from a system color name.
    ///
    /// System colors adapt to the current color scheme and theme.
    ///
    /// - Parameter name: The system color name (e.g., "primary", "secondary").
    /// - Returns: A color that references the system color.
    private init(systemColor: String) {
        self.storage = .systemColor(systemColor)
    }

    // MARK: - Common Colors

    /// A pure black color
    public static let black = Color(named: "black")

    /// A pure white color
    public static let white = Color(named: "white")

    /// A red color
    public static let red = Color(named: "red")

    /// A green color
    public static let green = Color(named: "green")

    /// A blue color
    public static let blue = Color(named: "blue")

    /// A yellow color
    public static let yellow = Color(named: "yellow")

    /// An orange color
    public static let orange = Color(named: "orange")

    /// A purple color
    public static let purple = Color(named: "purple")

    /// A pink color
    public static let pink = Color(named: "pink")

    /// A gray color
    public static let gray = Color(named: "gray")

    /// An indigo color
    public static let indigo = Color(named: "indigo")

    /// A teal color
    public static let teal = Color(named: "teal")

    /// A cyan color
    public static let cyan = Color(named: "cyan")

    /// A mint color
    public static let mint = Color(red: 0.0, green: 0.78, blue: 0.75)

    /// A brown color
    public static let brown = Color(named: "brown")

    /// A clear (transparent) color
    public static let clear = Color(named: "transparent")

    // MARK: - Semantic Colors

    /// Primary color for the current theme
    public static let primary = Color(systemColor: "primary")

    /// Secondary color for the current theme
    public static let secondary = Color(systemColor: "secondary")

    /// Accent color for the current theme
    public static let accent = Color(systemColor: "accent")

    /// Label color for primary text content
    public static let label = Color(systemColor: "label")

    /// Label color for secondary text content
    public static let secondaryLabel = Color(systemColor: "secondary-label")

    /// Label color for tertiary text content
    public static let tertiaryLabel = Color(systemColor: "tertiary-label")

    /// Primary background color
    public static let systemBackground = Color(systemColor: "background")

    /// Secondary background color for grouped content
    public static let secondarySystemBackground = Color(systemColor: "secondary-background")

    /// Tertiary background color
    public static let tertiarySystemBackground = Color(systemColor: "tertiary-background")

    /// Background color for grouped content areas
    public static let groupedBackground = Color(systemColor: "grouped-background")

    /// Color for thin separator lines
    public static let separator = Color(systemColor: "separator")

    /// Color for fill areas
    public static let fill = Color(systemColor: "fill")

    /// Color for secondary fill areas
    public static let secondaryFill = Color(systemColor: "secondary-fill")

    // MARK: - CSS Conversion

    /// Converts this color to a CSS color string.
    ///
    /// - Returns: A CSS-compatible color string.
    public var cssValue: String {
        switch storage {
        case .rgb(let red, let green, let blue, let opacity):
            let r = Int(red * 255)
            let g = Int(green * 255)
            let b = Int(blue * 255)
            if opacity < 1.0 {
                return "rgba(\(r), \(g), \(b), \(opacity))"
            } else {
                return "rgb(\(r), \(g), \(b))"
            }
        case .hex(let hex):
            return hex
        case .named(let name):
            return name
        case .cssVariable(let name):
            return "var(--\(name))"
        case .systemColor(let name):
            // System colors map to CSS variables with a standard prefix
            return "var(--system-\(name))"
        }
    }

    // MARK: - VNode Conversion

    /// Converts this Color to a virtual DOM node.
    ///
    /// When used as a standalone view, Color renders as a `div` with a background color.
    ///
    /// - Returns: A VNode configured as a colored div.
    @MainActor public func toVNode() -> VNode {
        VNode.element(
            "div",
            props: [
                "background-color": .style(name: "background-color", value: cssValue),
                "width": .style(name: "width", value: "100%"),
                "height": .style(name: "height", value: "100%")
            ],
            children: []
        )
    }

    // MARK: - Opacity

    /// Returns a new color with the specified opacity.
    ///
    /// - Parameter opacity: The opacity value (0.0 to 1.0).
    /// - Returns: A new color with the specified opacity.
    public func opacity(_ opacity: Double) -> Color {
        let clampedOpacity = min(max(opacity, 0.0), 1.0)

        switch storage {
        case .rgb(let red, let green, let blue, _):
            return Color(red: red, green: green, blue: blue, opacity: clampedOpacity)
        case .hex(let hexString):
            // Parse hex color and convert to RGBA
            if let (r, g, b) = parseHex(hexString) {
                return Color(red: r, green: g, blue: b, opacity: clampedOpacity)
            }
            // Fallback if parsing fails
            return self
        case .named(let name):
            // For named colors, use CSS color-mix or rgba() with color name
            // Since CSS doesn't support rgba(named-color, opacity) directly,
            // we'll convert common colors to RGB
            if let (r, g, b) = namedColorToRGB(name) {
                return Color(red: r, green: g, blue: b, opacity: clampedOpacity)
            }
            // For unknown colors, keep as is
            return self
        case .cssVariable, .systemColor:
            // CSS variables and system colors can't have opacity applied directly
            // They would need to be wrapped in a container with opacity
            return self
        }
    }

    // MARK: - Gradient Creation

    /// Creates a simple linear gradient from this color.
    ///
    /// This creates a gradient that transitions from this color to a lighter/darker variant,
    /// useful for creating quick visual effects without defining multiple colors.
    ///
    /// - Parameter angle: The angle of the gradient. Defaults to vertical (180 degrees).
    /// - Returns: A linear gradient based on this color.
    ///
    /// Example:
    /// ```swift
    /// Color.blue.gradient  // Creates a blue gradient
    /// ```
    public var gradient: LinearGradient {
        // Create a gradient from this color to a slightly lighter version
        switch storage {
        case .rgb(let red, let green, let blue, let opacity):
            let lighterColor = Color(
                red: min(red + 0.2, 1.0),
                green: min(green + 0.2, 1.0),
                blue: min(blue + 0.2, 1.0),
                opacity: opacity
            )
            return LinearGradient(colors: [lighterColor, self], angle: Angle(degrees: 180))
        default:
            // For other color types, create a simple gradient with the same color
            // This won't be as visually interesting but maintains consistency
            return LinearGradient(colors: [self, self], angle: Angle(degrees: 180))
        }
    }

    // MARK: - Private Helpers

    /// Parses a hex color string into RGB components.
    ///
    /// - Parameter hex: The hex color string (e.g., "#FF0000" or "FF0000").
    /// - Returns: A tuple of RGB values (0.0 to 1.0), or nil if parsing fails.
    private func parseHex(_ hex: String) -> (Double, Double, Double)? {
        let cleaned = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))

        guard cleaned.count == 6 || cleaned.count == 8 else {
            return nil
        }

        var rgb: UInt64 = 0
        Scanner(string: String(cleaned.prefix(6))).scanHexInt64(&rgb)

        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0

        return (r, g, b)
    }

    /// Converts common named colors to RGB values.
    ///
    /// - Parameter name: The CSS color name.
    /// - Returns: A tuple of RGB values (0.0 to 1.0), or nil if not a known color.
    private func namedColorToRGB(_ name: String) -> (Double, Double, Double)? {
        switch name.lowercased() {
        case "black": return (0.0, 0.0, 0.0)
        case "white": return (1.0, 1.0, 1.0)
        case "red": return (1.0, 0.0, 0.0)
        case "green": return (0.0, 0.5, 0.0)
        case "blue": return (0.0, 0.0, 1.0)
        case "yellow": return (1.0, 1.0, 0.0)
        case "orange": return (1.0, 0.647, 0.0)
        case "purple": return (0.5, 0.0, 0.5)
        case "pink": return (1.0, 0.753, 0.796)
        case "gray", "grey": return (0.5, 0.5, 0.5)
        case "indigo": return (0.294, 0.0, 0.510)
        case "teal": return (0.0, 0.5, 0.5)
        case "cyan": return (0.0, 1.0, 1.0)
        case "brown": return (0.647, 0.165, 0.165)
        case "transparent": return (0.0, 0.0, 0.0) // Will have 0 opacity anyway
        default: return nil
        }
    }
}
