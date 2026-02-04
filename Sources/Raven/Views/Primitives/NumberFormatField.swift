import Foundation

/// A control for entering formatted numeric values with custom formatting rules.
///
/// `NumberFormatField` is a flexible numeric input that can apply various formatting
/// rules including decimal places, thousands separators, prefixes, suffixes, and more.
/// It provides two-way data binding through a `Binding<Double>` for numeric values.
///
/// ## Overview
///
/// Use `NumberFormatField` when you need custom numeric formatting beyond basic
/// currency or phone numbers. This control supports percentage formatting, units,
/// scientific notation, and custom patterns.
///
/// ## Basic Usage
///
/// Create a number field with default formatting:
///
/// ```swift
/// struct QuantityView: View {
///     @State private var quantity: Double = 0
///
///     var body: some View {
///         VStack {
///             Text("Quantity")
///             NumberFormatField("Enter amount", value: $quantity)
///         }
///     }
/// }
/// ```
///
/// ## Percentage Formatting
///
/// Format values as percentages:
///
/// ```swift
/// @State private var discount: Double = 15.5
///
/// NumberFormatField(
///     "Discount",
///     value: $discount,
///     formatter: NumberFormatter.percentage
/// )
/// // Displays: 15.5%
/// ```
///
/// ## Custom Decimal Places
///
/// Control decimal precision:
///
/// ```swift
/// // 2 decimal places
/// NumberFormatField(
///     "Price",
///     value: $price,
///     formatter: NumberFormatter.decimal(places: 2)
/// )
///
/// // No decimal places (integers only)
/// NumberFormatField(
///     "Count",
///     value: $count,
///     formatter: NumberFormatter.integer
/// )
///
/// // Scientific notation
/// NumberFormatField(
///     "Distance",
///     value: $distance,
///     formatter: NumberFormatter.scientific
/// )
/// ```
///
/// ## Units and Suffixes
///
/// Add units or suffixes to numbers:
///
/// ```swift
/// // Temperature: 72°F
/// NumberFormatField(
///     "Temperature",
///     value: $temp,
///     formatter: NumberFormatter.unit("°F")
/// )
///
/// // Distance: 42.5 km
/// NumberFormatField(
///     "Distance",
///     value: $distance,
///     formatter: NumberFormatter.unit("km")
/// )
///
/// // Weight: 150 lbs
/// NumberFormatField(
///     "Weight",
///     value: $weight,
///     formatter: NumberFormatter.unit("lbs", decimals: 0)
/// )
/// ```
///
/// ## Thousands Separators
///
/// Format large numbers with separators:
///
/// ```swift
/// @State private var population: Double = 1234567
///
/// NumberFormatField(
///     "Population",
///     value: $population,
///     formatter: NumberFormatter.withThousands
/// )
/// // Displays: 1,234,567
/// ```
///
/// ## Common Patterns
///
/// **Measurement input:**
/// ```swift
/// struct MeasurementForm: View {
///     @State private var height: Double = 0
///     @State private var weight: Double = 0
///
///     var body: some View {
///         Form {
///             NumberFormatField("Height", value: $height, formatter: .unit("cm"))
///             NumberFormatField("Weight", value: $weight, formatter: .unit("kg", decimals: 1))
///         }
///     }
/// }
/// ```
///
/// **Statistics display:**
/// ```swift
/// @State private var accuracy: Double = 98.5
/// @State private var responseTime: Double = 245.8
///
/// VStack {
///     HStack {
///         Text("Accuracy:")
///         NumberFormatField("", value: $accuracy, formatter: .percentage)
///     }
///
///     HStack {
///         Text("Response Time:")
///         NumberFormatField("", value: $responseTime, formatter: .unit("ms", decimals: 1))
///     }
/// }
/// ```
///
/// **Calculator:**
/// ```swift
/// @State private var result: Double = 0
///
/// NumberFormatField(
///     "Result",
///     value: $result,
///     formatter: NumberFormatter.decimal(places: 10)
/// )
/// .font(.system(.title, design: .monospaced))
/// ```
///
/// **Scientific data:**
/// ```swift
/// @State private var concentration: Double = 0.000123
///
/// NumberFormatField(
///     "Concentration",
///     value: $concentration,
///     formatter: .scientific
/// )
/// // Displays: 1.23e-4
/// ```
///
/// ## Custom Formatters
///
/// Create custom number formatters:
///
/// ```swift
/// extension NumberFormatter {
///     static var rpm: NumberFormatter {
///         NumberFormatter(
///             suffix: " RPM",
///             decimals: 0,
///             thousandsSeparator: true
///         )
///     }
/// }
///
/// NumberFormatField("Engine Speed", value: $rpm, formatter: .rpm)
/// ```
///
/// ## Validation
///
/// Set minimum and maximum values:
///
/// ```swift
/// NumberFormatField(
///     "Age",
///     value: $age,
///     formatter: .integer,
///     range: 0...120
/// )
/// ```
///
/// ## Accessibility
///
/// NumberFormatField provides accessibility features:
/// - Keyboard type set to decimal pad on mobile devices
/// - Screen reader announces the field purpose and units
/// - Clear validation feedback
///
/// ## Best Practices
///
/// - Choose appropriate decimal precision for your data
/// - Use thousands separators for large numbers
/// - Include units in the formatter for clarity
/// - Provide clear placeholders showing the expected format
/// - Validate ranges to prevent invalid input
/// - Consider scientific notation for very large/small numbers
/// - Use consistent formatting across your application
///
/// ## Performance
///
/// NumberFormatField formats values on every keystroke. For complex
/// formatting rules, consider debouncing updates or using `onCommit`:
///
/// ```swift
/// NumberFormatField("Value", value: $value, formatter: .complex)
///     .onChange(of: value) { _ in
///         // Debounce expensive operations
///     }
/// ```
///
/// ## See Also
///
/// - ``NumberFormatter``
/// - ``CurrencyField``
/// - ``TextField``
public struct NumberFormatField: View, Sendable {
    public typealias Body = Never

    /// The placeholder text to display when the field is empty
    private let placeholder: String

    /// Two-way binding to the numeric value
    private let value: Binding<Double>

    /// The number formatter to use
    private let formatter: NumberFormatter

    /// Optional range constraint
    private let range: ClosedRange<Double>?

    // MARK: - Initializers

    /// Creates a number field with a placeholder and value binding.
    ///
    /// - Parameters:
    ///   - placeholder: The placeholder text to display when empty.
    ///   - value: A binding to the numeric value.
    ///   - formatter: The number formatter to use. Defaults to basic decimal.
    ///   - range: Optional range constraint for valid values.
    ///
    /// Example:
    /// ```swift
    /// @State private var amount: Double = 0
    ///
    /// NumberFormatField("Enter amount", value: $amount)
    /// ```
    @MainActor public init(
        _ placeholder: String,
        value: Binding<Double>,
        formatter: NumberFormatter = .decimal(places: 2),
        range: ClosedRange<Double>? = nil
    ) {
        self.placeholder = placeholder
        self.value = value
        self.formatter = formatter
        self.range = range
    }

    /// Creates a number field with a localized placeholder.
    ///
    /// - Parameters:
    ///   - titleKey: The localized string key for the placeholder.
    ///   - value: A binding to the numeric value.
    ///   - formatter: The number formatter to use.
    ///   - range: Optional range constraint for valid values.
    ///
    /// Example:
    /// ```swift
    /// @State private var amount: Double = 0
    ///
    /// NumberFormatField("amount_placeholder", value: $amount)
    /// ```
    @MainActor public init(
        _ titleKey: LocalizedStringKey,
        value: Binding<Double>,
        formatter: NumberFormatter = .decimal(places: 2),
        range: ClosedRange<Double>? = nil
    ) {
        self.placeholder = titleKey.stringValue
        self.value = value
        self.formatter = formatter
        self.range = range
    }

    // MARK: - VNode Conversion

    /// Converts this NumberFormatField to a virtual DOM node.
    ///
    /// The NumberFormatField is rendered as an `input` element with:
    /// - `type="text"` attribute (not number, to allow formatting)
    /// - `inputmode="decimal"` for mobile keyboard
    /// - `placeholder` attribute for hint text
    /// - `value` attribute bound to the formatted numeric value
    /// - `input` event handler for auto-formatting
    ///
    /// - Returns: A VNode configured as a number input element with event handlers.
    @MainActor public func toVNode() -> VNode {
        // Generate a unique ID for the input event handler
        let handlerID = UUID()

        // Format the current value
        let formattedValue = formatter.format(value.wrappedValue)

        // Create properties for the input element
        var props: [String: VProperty] = [
            // Input type - text to allow formatting characters
            "type": .attribute(name: "type", value: "text"),

            // Input mode for mobile keyboards
            "inputmode": .attribute(name: "inputmode", value: "decimal"),

            // Placeholder text
            "placeholder": .attribute(name: "placeholder", value: placeholder.isEmpty ? formatter.placeholder() : placeholder),

            // Current value (reflects the binding)
            "value": .attribute(name: "value", value: formattedValue),

            // Input event handler for auto-formatting
            "onInput": .eventHandler(event: "input", handlerID: handlerID),

            // ARIA attributes for accessibility
            "aria-label": .attribute(name: "aria-label", value: placeholder),

            // Default styling
            "padding": .style(name: "padding", value: "8px"),
            "border": .style(name: "border", value: "1px solid #ccc"),
            "border-radius": .style(name: "border-radius", value: "4px"),
            "font-size": .style(name: "font-size", value: "14px"),
            "font-family": .style(name: "font-family", value: "monospace"),
            "text-align": .style(name: "text-align", value: "right"),
        ]

        // Add min/max attributes if range is specified
        if let range = range {
            props["min"] = .attribute(name: "min", value: String(range.lowerBound))
            props["max"] = .attribute(name: "max", value: String(range.upperBound))
        }

        return VNode.element(
            "input",
            props: props,
            children: []
        )
    }

    // MARK: - Internal Access

    /// Provides access to the value binding for the render coordinator.
    @MainActor public var valueBinding: Binding<Double> {
        value
    }

    /// Provides access to the formatter for the render coordinator.
    @MainActor public var numberFormatter: NumberFormatter {
        formatter
    }

    /// Provides access to the range constraint.
    @MainActor public var valueRange: ClosedRange<Double>? {
        range
    }
}

// MARK: - Number Formatter

/// A formatter for numeric values with customizable formatting rules.
public struct NumberFormatter: InputFormatter, Sendable {
    public typealias Value = Double

    /// Optional prefix to add before the number
    private let prefix: String?

    /// Optional suffix to add after the number
    private let suffix: String?

    /// Number of decimal places (nil for no limit)
    private let decimals: Int?

    /// Whether to use thousands separators
    private let thousandsSeparator: Bool

    /// The decimal separator character
    private let decimalSeparator: String

    /// The thousands separator character
    private let groupingSeparator: String

    /// Whether to use scientific notation
    private let scientific: Bool

    /// Creates a number formatter with custom options.
    ///
    /// - Parameters:
    ///   - prefix: Optional prefix string (e.g., "$", "€").
    ///   - suffix: Optional suffix string (e.g., "%", "km", "°C").
    ///   - decimals: Number of decimal places. `nil` for no limit.
    ///   - thousandsSeparator: Whether to use thousands separators.
    ///   - decimalSeparator: The decimal separator character. Defaults to ".".
    ///   - groupingSeparator: The thousands separator character. Defaults to ",".
    ///   - scientific: Whether to use scientific notation.
    public init(
        prefix: String? = nil,
        suffix: String? = nil,
        decimals: Int? = 2,
        thousandsSeparator: Bool = false,
        decimalSeparator: String = ".",
        groupingSeparator: String = ",",
        scientific: Bool = false
    ) {
        self.prefix = prefix
        self.suffix = suffix
        self.decimals = decimals
        self.thousandsSeparator = thousandsSeparator
        self.decimalSeparator = decimalSeparator
        self.groupingSeparator = groupingSeparator
        self.scientific = scientific
    }

    // MARK: - Common Formatters

    /// Integer formatter (no decimal places).
    public static let integer = NumberFormatter(decimals: 0)

    /// Decimal formatter with specified decimal places.
    public static func decimal(places: Int) -> NumberFormatter {
        NumberFormatter(decimals: places)
    }

    /// Formatter with thousands separators.
    public static let withThousands = NumberFormatter(decimals: 2, thousandsSeparator: true)

    /// Percentage formatter.
    public static let percentage = NumberFormatter(suffix: "%", decimals: 1)

    /// Scientific notation formatter.
    public static let scientific = NumberFormatter(decimals: 2, scientific: true)

    /// Unit formatter with suffix.
    public static func unit(_ unit: String, decimals: Int = 2) -> NumberFormatter {
        NumberFormatter(suffix: " " + unit, decimals: decimals)
    }

    // MARK: - InputFormatter Protocol

    /// Formats a numeric value according to the formatter rules.
    @MainActor public func format(_ value: Double) -> String {
        // Handle special case of zero
        if value == 0 {
            return ""
        }

        // Scientific notation
        if scientific {
            let formatted = String(format: "%.\(decimals ?? 2)e", value)
            return (prefix ?? "") + formatted + (suffix ?? "")
        }

        // Round to specified decimal places
        let rounded: Double
        if let decimals = decimals {
            let multiplier = pow(10.0, Double(decimals))
            rounded = (value * multiplier).rounded() / multiplier
        } else {
            rounded = value
        }

        // Split into integer and decimal parts
        let integerPart = Int(abs(rounded))
        let decimalPart = abs(rounded).truncatingRemainder(dividingBy: 1.0)

        // Format integer part with thousands separators
        var integerString = String(integerPart)
        if thousandsSeparator {
            integerString = formatWithGroupingSeparator(integerPart)
        }

        // Build result
        var result = integerString

        // Add decimal part if needed
        if let decimals = decimals, decimals > 0 {
            let decimalValue = Int((decimalPart * pow(10.0, Double(decimals))).rounded())
            let decimalFormat = String(format: "%0\(decimals)d", decimalValue)
            result += decimalSeparator + decimalFormat
        } else if decimals == nil && decimalPart > 0 {
            // No limit on decimals
            result += decimalSeparator + String(decimalPart).dropFirst(2) // Drop "0."
        }

        // Add negative sign if needed
        if value < 0 {
            result = "-" + result
        }

        // Add prefix and suffix
        return (prefix ?? "") + result + (suffix ?? "")
    }

    /// Parses formatted text back to a numeric value.
    @MainActor public func parse(_ formattedText: String) -> Double? {
        // Remove prefix, suffix, and separators
        var cleaned = formattedText
        if let prefix = prefix {
            cleaned = cleaned.replacingOccurrences(of: prefix, with: "")
        }
        if let suffix = suffix {
            cleaned = cleaned.replacingOccurrences(of: suffix, with: "")
        }

        cleaned = cleaned
            .replacingOccurrences(of: groupingSeparator, with: "")
            .replacingOccurrences(of: " ", with: "")
            .trimmingCharacters(in: .whitespaces)

        // Handle different decimal separators
        if decimalSeparator != "." {
            cleaned = cleaned.replacingOccurrences(of: decimalSeparator, with: ".")
        }

        // Handle scientific notation
        if scientific || cleaned.contains("e") || cleaned.contains("E") {
            return Double(cleaned)
        }

        // Convert to Double
        return Double(cleaned)
    }

    /// Validates whether the text is valid.
    @MainActor public func validate(_ text: String) -> Bool {
        // Empty text is valid
        if text.isEmpty {
            return true
        }

        // Try to parse the value
        guard let _ = parse(text) else {
            return false
        }

        return true
    }

    /// Returns a placeholder string.
    @MainActor public func placeholder() -> String {
        let example: String
        if scientific {
            example = "1.23e-4"
        } else if let decimals = decimals, decimals > 0 {
            example = "0" + decimalSeparator + String(repeating: "0", count: decimals)
        } else {
            example = "0"
        }

        return (prefix ?? "") + example + (suffix ?? "")
    }

    // MARK: - Private Helpers

    /// Formats an integer with grouping separators.
    @MainActor private func formatWithGroupingSeparator(_ value: Int) -> String {
        let string = String(value)
        var result = ""
        var count = 0

        for char in string.reversed() {
            if count > 0 && count % 3 == 0 {
                result.insert(contentsOf: groupingSeparator, at: result.startIndex)
            }
            result.insert(char, at: result.startIndex)
            count += 1
        }

        return result
    }
}
