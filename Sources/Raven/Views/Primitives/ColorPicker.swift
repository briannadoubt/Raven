import Foundation

/// A control for selecting colors.
///
/// `ColorPicker` is a primitive view that renders directly to an HTML `input` element
/// with `type="color"`. It provides two-way data binding through a `Binding<Color>`
/// that updates when the user selects a color and reflects external changes to the bound value.
///
/// ## Overview
///
/// Use `ColorPicker` to let users select colors using a native color picker interface.
/// The HTML5 color input provides a platform-appropriate color selection UI, typically
/// showing a color wheel, palette, or slider interface.
///
/// ## Basic Usage
///
/// Create a color picker with a label:
///
/// ```swift
/// struct ThemeView: View {
///     @State private var accentColor = Color.blue
///
///     var body: some View {
///         VStack {
///             Text("Choose Theme Color")
///             ColorPicker("Accent Color", selection: $accentColor)
///
///             Rectangle()
///                 .fill(accentColor)
///                 .frame(width: 100, height: 100)
///         }
///     }
/// }
/// ```
///
/// ## With Opacity Support
///
/// Enable alpha channel selection:
///
/// ```swift
/// @State private var fillColor = Color.red.opacity(0.5)
///
/// ColorPicker("Fill Color",
///             selection: $fillColor,
///             supportsOpacity: true)
/// ```
///
/// Note: HTML5 color input (`type="color"`) does not natively support opacity.
/// When `supportsOpacity` is true, Raven will render an additional opacity slider
/// alongside the color picker.
///
/// ## Common Patterns
///
/// **Text color selector:**
/// ```swift
/// @State private var textColor = Color.black
///
/// VStack {
///     ColorPicker("Text Color", selection: $textColor)
///     Text("Sample Text")
///         .foregroundColor(textColor)
/// }
/// ```
///
/// **Background color selector:**
/// ```swift
/// @State private var backgroundColor = Color.white
///
/// VStack {
///     ColorPicker("Background", selection: $backgroundColor)
/// }
/// .background(backgroundColor)
/// ```
///
/// **Drawing tool palette:**
/// ```swift
/// struct DrawingToolbar: View {
///     @State private var strokeColor = Color.black
///     @State private var fillColor = Color.clear
///
///     var body: some View {
///         HStack {
///             ColorPicker("Stroke", selection: $strokeColor)
///             ColorPicker("Fill", selection: $fillColor, supportsOpacity: true)
///         }
///     }
/// }
/// ```
///
/// **Theme customization:**
/// ```swift
/// struct ThemeSettings: View {
///     @State private var primaryColor = Color.blue
///     @State private var secondaryColor = Color.gray
///     @State private var accentColor = Color.orange
///
///     var body: some View {
///         Form {
///             Section("Colors") {
///                 ColorPicker("Primary", selection: $primaryColor)
///                 ColorPicker("Secondary", selection: $secondaryColor)
///                 ColorPicker("Accent", selection: $accentColor)
///             }
///         }
///     }
/// }
/// ```
///
/// ## Color Representation
///
/// Colors are represented using the `Color` type, which can be:
/// - Created from RGB values: `Color(.sRGB, red: 1.0, green: 0.5, blue: 0.0)`
/// - Created from hex strings: Custom extension needed
/// - System colors: `Color.red`, `Color.blue`, etc.
///
/// ## Styling
///
/// Apply modifiers to customize appearance:
///
/// ```swift
/// ColorPicker("Theme", selection: $color)
///     .frame(width: 50, height: 50)
///     .cornerRadius(8)
/// ```
///
/// ## Accessibility
///
/// ColorPicker provides built-in accessibility:
/// - Keyboard navigation support
/// - Screen reader announces the color picker and current color
/// - Focus management through native controls
///
/// For better accessibility, always provide descriptive labels:
/// ```swift
/// ColorPicker("Primary theme color for buttons and links", selection: $color)
/// ```
///
/// ## Best Practices
///
/// - Provide meaningful labels that describe what the color is for
/// - Show a preview of the selected color alongside the picker
/// - Consider providing preset color options for common use cases
/// - Remember that not all users can distinguish all colors (color blindness)
/// - Use additional indicators beyond color alone for critical information
/// - Test color contrast for accessibility compliance
///
/// ## Implementation Notes
///
/// This implementation uses the HTML5 `<input type="color">` element, which:
/// - Returns hex color values in the format `#RRGGBB`
/// - Does not support alpha/opacity natively
/// - Provides a native color picker UI appropriate for the platform
/// - Has good cross-browser support
///
/// When `supportsOpacity` is enabled, an additional range input is rendered
/// for the alpha channel.
///
/// ## Limitations
///
/// - HTML5 color input only supports RGB colors (no HSL, CMYK, etc.)
/// - Alpha channel requires separate control
/// - Some older browsers may fall back to text input
///
/// ## See Also
///
/// - ``Color``
/// - ``Slider``
///
/// Because `ColorPicker` is a primitive view with `Body == Never`, it converts directly
/// to a VNode without further composition.
public struct ColorPicker: View, PrimitiveView, Sendable {
    public typealias Body = Never

    /// The label to display for the picker
    private let label: String

    /// Two-way binding to the color value
    private let selection: Binding<Color>

    /// Whether the picker supports opacity/alpha selection
    private let supportsOpacity: Bool

    // MARK: - Initializers

    /// Creates a color picker with a label and color binding.
    ///
    /// - Parameters:
    ///   - label: The label to display for the picker.
    ///   - selection: A binding to the selected color.
    ///   - supportsOpacity: Whether to enable opacity/alpha selection. Defaults to `true`.
    ///
    /// Example:
    /// ```swift
    /// @State private var tintColor = Color.blue
    ///
    /// ColorPicker("Tint", selection: $tintColor)
    /// ```
    @MainActor public init(
        _ label: String,
        selection: Binding<Color>,
        supportsOpacity: Bool = true
    ) {
        self.label = label
        self.selection = selection
        self.supportsOpacity = supportsOpacity
    }

    /// Creates a color picker with a localized label and color binding.
    ///
    /// - Parameters:
    ///   - titleKey: The localized string key for the label.
    ///   - selection: A binding to the selected color.
    ///   - supportsOpacity: Whether to enable opacity/alpha selection.
    ///
    /// Example:
    /// ```swift
    /// @State private var tintColor = Color.blue
    ///
    /// ColorPicker("color_picker_label", selection: $tintColor)
    /// ```
    @MainActor public init(
        _ titleKey: LocalizedStringKey,
        selection: Binding<Color>,
        supportsOpacity: Bool = true
    ) {
        self.label = titleKey.stringValue
        self.selection = selection
        self.supportsOpacity = supportsOpacity
    }

    // MARK: - VNode Conversion

    /// Converts this ColorPicker to a virtual DOM node.
    ///
    /// The ColorPicker is rendered as:
    /// - A `div` container
    /// - An `input` element with `type="color"` for RGB selection
    /// - Optionally, an additional `input` with `type="range"` for opacity
    ///
    /// - Returns: A VNode configured as a color picker with event handlers.
    @MainActor public func toVNode() -> VNode {
        let colorHandlerID = UUID()

        // Extract RGB hex value from color
        let hexColor = colorToHex(selection.wrappedValue)

        // Create the color input element
        var colorProps: [String: VProperty] = [
            "type": .attribute(name: "type", value: "color"),
            "value": .attribute(name: "value", value: hexColor),
            "onChange": .eventHandler(event: "change", handlerID: colorHandlerID),
            "aria-label": .attribute(name: "aria-label", value: label),
            "width": .style(name: "width", value: "60px"),
            "height": .style(name: "height", value: "40px"),
            "border": .style(name: "border", value: "1px solid var(--system-control-border)"),
            "border-radius": .style(name: "border-radius", value: "4px"),
            "cursor": .style(name: "cursor", value: "pointer"),
        ]

        let colorInput = VNode.element("input", props: colorProps, children: [])

        // If opacity is not supported, return just the color input
        if !supportsOpacity {
            return colorInput
        }

        // Create opacity slider
        let opacityHandlerID = UUID()
        let opacity = extractOpacity(selection.wrappedValue)

        let opacityProps: [String: VProperty] = [
            "type": .attribute(name: "type", value: "range"),
            "min": .attribute(name: "min", value: "0"),
            "max": .attribute(name: "max", value: "1"),
            "step": .attribute(name: "step", value: "0.01"),
            "value": .attribute(name: "value", value: String(opacity)),
            "onInput": .eventHandler(event: "input", handlerID: opacityHandlerID),
            "aria-label": .attribute(name: "aria-label", value: "\(label) opacity"),
            "width": .style(name: "width", value: "120px"),
            "margin-left": .style(name: "margin-left", value: "8px"),
        ]

        let opacityInput = VNode.element("input", props: opacityProps, children: [])

        // Create label text
        let labelText = VNode.text(label)
        let labelProps: [String: VProperty] = [
            "display": .style(name: "display", value: "block"),
            "margin-bottom": .style(name: "margin-bottom", value: "4px"),
            "font-size": .style(name: "font-size", value: "14px"),
            "font-weight": .style(name: "font-weight", value: "500"),
        ]
        let labelNode = VNode.element("label", props: labelProps, children: [labelText])

        // Container for color input and opacity slider
        let controlsProps: [String: VProperty] = [
            "display": .style(name: "display", value: "flex"),
            "align-items": .style(name: "align-items", value: "center"),
            "gap": .style(name: "gap", value: "8px"),
        ]
        let controlsContainer = VNode.element(
            "div",
            props: controlsProps,
            children: [colorInput, opacityInput]
        )

        // Main container
        let containerProps: [String: VProperty] = [
            "display": .style(name: "display", value: "flex"),
            "flex-direction": .style(name: "flex-direction", value: "column"),
        ]

        return VNode.element(
            "div",
            props: containerProps,
            children: [labelNode, controlsContainer]
        )
    }

    // MARK: - Internal Access

    /// Provides access to the color binding for the render coordinator.
    @MainActor public var colorBinding: Binding<Color> {
        selection
    }

    /// Provides access to the supports opacity flag.
    @MainActor public var hasOpacity: Bool {
        supportsOpacity
    }

    // MARK: - Private Helpers

    /// Converts a Color to a hex string for HTML color input.
    @MainActor private func colorToHex(_ color: Color) -> String {
        // Get the CSS value and convert to hex if needed
        let css = color.cssValue

        // If it's already a hex color, return it
        if css.hasPrefix("#") {
            // Ensure it's 6-digit format
            let cleaned = css.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
            if cleaned.count >= 6 {
                return "#" + String(cleaned.prefix(6))
            }
        }

        // If it's rgb() or rgba(), parse and convert
        if css.hasPrefix("rgb") {
            if let components = parseRGBString(css) {
                return String(format: "#%02X%02X%02X", components.red, components.green, components.blue)
            }
        }

        // For named colors, return a default
        // HTML color input only accepts hex format
        return "#000000"
    }

    /// Parses an RGB/RGBA CSS string into components.
    @MainActor private func parseRGBString(_ rgb: String) -> (red: Int, green: Int, blue: Int)? {
        let cleaned = rgb
            .replacingOccurrences(of: "rgba(", with: "")
            .replacingOccurrences(of: "rgb(", with: "")
            .replacingOccurrences(of: ")", with: "")
            .replacingOccurrences(of: " ", with: "")

        let components = cleaned.split(separator: ",")
        guard components.count >= 3,
              let red = Int(components[0]),
              let green = Int(components[1]),
              let blue = Int(components[2]) else {
            return nil
        }

        return (red, green, blue)
    }

    /// Extracts the opacity from a color.
    @MainActor private func extractOpacity(_ color: Color) -> Double {
        let css = color.cssValue

        // Check if it's rgba with an alpha value
        if css.hasPrefix("rgba(") {
            let cleaned = css
                .replacingOccurrences(of: "rgba(", with: "")
                .replacingOccurrences(of: ")", with: "")
                .replacingOccurrences(of: " ", with: "")

            let components = cleaned.split(separator: ",")
            if components.count >= 4, let alpha = Double(components[3]) {
                return alpha
            }
        }

        // Default to fully opaque
        return 1.0
    }
}

// MARK: - Coordinator Renderable

extension ColorPicker: _CoordinatorRenderable {
    @MainActor public func _render(with context: any _RenderContext) -> VNode {
        let hexColor = colorToHex(selection.wrappedValue)

        // Register color input handler
        let colorHandlerID = context.registerInputHandler { jsValue in
            let value = jsValue.target.value.string ?? ""
            // Parse hex color string like "#ff0000"
            let cleaned = value.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
            guard cleaned.count == 6 else { return }
            let scanner = cleaned
            let rStr = String(scanner.prefix(2))
            let gStr = String(scanner.dropFirst(2).prefix(2))
            let bStr = String(scanner.dropFirst(4).prefix(2))
            guard let r = UInt8(rStr, radix: 16),
                  let g = UInt8(gStr, radix: 16),
                  let b = UInt8(bStr, radix: 16) else { return }
            let newColor = Color(red: Double(r) / 255.0, green: Double(g) / 255.0, blue: Double(b) / 255.0)
            self.selection.wrappedValue = newColor
        }

        let colorProps: [String: VProperty] = [
            "type": .attribute(name: "type", value: "color"),
            "value": .attribute(name: "value", value: hexColor),
            "onChange": .eventHandler(event: "change", handlerID: colorHandlerID),
            "aria-label": .attribute(name: "aria-label", value: label),
            "width": .style(name: "width", value: "60px"),
            "height": .style(name: "height", value: "40px"),
            "border": .style(name: "border", value: "1px solid var(--system-control-border)"),
            "border-radius": .style(name: "border-radius", value: "4px"),
            "cursor": .style(name: "cursor", value: "pointer"),
        ]
        let colorInput = VNode.element("input", props: colorProps, children: [])

        if !supportsOpacity {
            return colorInput
        }

        // Register opacity handler
        let currentOpacity = extractOpacity(selection.wrappedValue)
        let opacityHandlerID = context.registerInputHandler { jsValue in
            let value = jsValue.target.value.string ?? "1"
            guard let newOpacity = Double(value) else { return }
            self.selection.wrappedValue = self.selection.wrappedValue.opacity(newOpacity)
        }

        let opacityProps: [String: VProperty] = [
            "type": .attribute(name: "type", value: "range"),
            "min": .attribute(name: "min", value: "0"),
            "max": .attribute(name: "max", value: "1"),
            "step": .attribute(name: "step", value: "0.01"),
            "value": .attribute(name: "value", value: String(currentOpacity)),
            "onInput": .eventHandler(event: "input", handlerID: opacityHandlerID),
            "aria-label": .attribute(name: "aria-label", value: "\(label) opacity"),
            "width": .style(name: "width", value: "120px"),
            "margin-left": .style(name: "margin-left", value: "8px"),
        ]
        let opacityInput = VNode.element("input", props: opacityProps, children: [])

        // Label
        let labelText = VNode.text(label)
        let labelProps: [String: VProperty] = [
            "display": .style(name: "display", value: "block"),
            "margin-bottom": .style(name: "margin-bottom", value: "4px"),
            "font-size": .style(name: "font-size", value: "14px"),
            "font-weight": .style(name: "font-weight", value: "500"),
        ]
        let labelNode = VNode.element("label", props: labelProps, children: [labelText])

        // Controls container
        let controlsProps: [String: VProperty] = [
            "display": .style(name: "display", value: "flex"),
            "align-items": .style(name: "align-items", value: "center"),
            "gap": .style(name: "gap", value: "8px"),
        ]
        let controlsContainer = VNode.element("div", props: controlsProps, children: [colorInput, opacityInput])

        // Main container
        let containerProps: [String: VProperty] = [
            "display": .style(name: "display", value: "flex"),
            "flex-direction": .style(name: "flex-direction", value: "column"),
        ]
        return VNode.element("div", props: containerProps, children: [labelNode, controlsContainer])
    }
}
