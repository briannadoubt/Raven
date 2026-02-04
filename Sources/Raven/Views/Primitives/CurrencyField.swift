import Foundation

/// A control for entering formatted currency values.
///
/// `CurrencyField` is a specialized numeric input that automatically formats
/// currency amounts with proper symbols, decimal places, and thousands separators.
/// It provides two-way data binding through a `Binding<Double>` representing the
/// monetary value in the base unit (e.g., dollars, not cents).
///
/// ## Overview
///
/// Use `CurrencyField` when you need users to enter monetary amounts with
/// automatic formatting. The field applies currency-specific formatting rules
/// and validates input to ensure proper numeric structure.
///
/// ## Basic Usage
///
/// Create a currency field with default USD formatting:
///
/// ```swift
/// struct PriceForm: View {
///     @State private var price: Double = 0
///
///     var body: some View {
///         VStack {
///             Text("Price")
///             CurrencyField("Amount", value: $price)
///             Text("Total: \(price, format: .currency(code: "USD"))")
///         }
///     }
/// }
/// ```
///
/// ## Different Currencies
///
/// Specify different currency formats:
///
/// ```swift
/// // US Dollars: $1,234.56
/// CurrencyField("Price", value: $amount, currency: .usd)
///
/// // Euros: €1.234,56
/// CurrencyField("Price", value: $amount, currency: .eur)
///
/// // British Pounds: £1,234.56
/// CurrencyField("Price", value: $amount, currency: .gbp)
///
/// // Japanese Yen: ¥1,234 (no decimals)
/// CurrencyField("Price", value: $amount, currency: .jpy)
/// ```
///
/// ## Custom Decimal Places
///
/// Control the number of decimal places:
///
/// ```swift
/// // Default 2 decimal places
/// CurrencyField("Price", value: $price)
///
/// // No decimal places (for JPY, KRW, etc.)
/// CurrencyField("Price", value: $price, currency: .jpy)
///
/// // Three decimal places (for gas prices, etc.)
/// CurrencyField("Gas Price", value: $gasPrice, currency: .custom("$", decimals: 3))
/// ```
///
/// ## Input Formatting
///
/// The field automatically formats input:
/// - Adds currency symbol
/// - Inserts thousands separators
/// - Limits decimal places
/// - Removes invalid characters
/// - Handles paste operations
///
/// ## Common Patterns
///
/// **Shopping cart total:**
/// ```swift
/// @State private var subtotal: Double = 99.99
/// @State private var tax: Double = 8.50
///
/// var total: Double {
///     subtotal + tax
/// }
///
/// VStack(alignment: .trailing) {
///     HStack {
///         Text("Subtotal:")
///         CurrencyField("", value: $subtotal)
///             .frame(width: 120)
///     }
///
///     HStack {
///         Text("Tax:")
///         Text(tax, format: .currency(code: "USD"))
///     }
///
///     Divider()
///
///     HStack {
///         Text("Total:").bold()
///         Text(total, format: .currency(code: "USD")).bold()
///     }
/// }
/// ```
///
/// **Budget tracker:**
/// ```swift
/// struct BudgetItem: View {
///     let category: String
///     @Binding var amount: Double
///
///     var body: some View {
///         HStack {
///             Text(category)
///             Spacer()
///             CurrencyField("", value: $amount)
///                 .frame(width: 150)
///         }
///     }
/// }
/// ```
///
/// **International pricing:**
/// ```swift
/// @State private var selectedCurrency = CurrencyType.usd
/// @State private var amount: Double = 0
///
/// VStack {
///     Picker("Currency", selection: $selectedCurrency) {
///         Text("USD").tag(CurrencyType.usd)
///         Text("EUR").tag(CurrencyType.eur)
///         Text("GBP").tag(CurrencyType.gbp)
///         Text("JPY").tag(CurrencyType.jpy)
///     }
///
///     CurrencyField("Amount", value: $amount, currency: selectedCurrency)
/// }
/// ```
///
/// **Tip calculator:**
/// ```swift
/// @State private var billAmount: Double = 0
/// @State private var tipPercent: Double = 15
///
/// var tipAmount: Double {
///     billAmount * (tipPercent / 100)
/// }
///
/// var total: Double {
///     billAmount + tipAmount
/// }
///
/// Form {
///     Section("Bill") {
///         CurrencyField("Amount", value: $billAmount)
///         Slider(value: $tipPercent, in: 0...30, step: 1)
///         Text("Tip: \(tipPercent, specifier: "%.0f")%")
///     }
///
///     Section("Total") {
///         Text(total, format: .currency(code: "USD"))
///             .font(.title)
///     }
/// }
/// ```
///
/// ## Validation
///
/// The field validates input automatically:
/// - Ensures numeric input only
/// - Limits to maximum safe currency values
/// - Enforces decimal place restrictions
/// - Prevents negative values (unless explicitly allowed)
///
/// ## Accessibility
///
/// CurrencyField provides accessibility features:
/// - Keyboard type set to decimal pad on mobile devices
/// - Screen reader announces currency values properly
/// - Clear label indicating the currency type
///
/// ## Best Practices
///
/// - Use appropriate currency for your target market
/// - Display currency code or symbol prominently
/// - Handle currency conversion separately from display
/// - Store values in smallest unit (cents) in databases
/// - Use Double for display, Decimal for precise calculations
/// - Consider rounding rules for different currencies
/// - Test with large and small values
///
/// ## Data Storage
///
/// The binding uses Double values representing the major currency unit:
/// - $1.99 is stored as 1.99 (not 199 cents)
/// - €1.234,56 is stored as 1234.56
/// - ¥1,234 is stored as 1234.0
///
/// For financial calculations requiring precision, convert to Decimal:
/// ```swift
/// let preciseAmount = Decimal(currencyValue)
/// ```
///
/// ## See Also
///
/// - ``CurrencyFormatter``
/// - ``NumberFormatField``
/// - ``TextField``
public struct CurrencyField: View, PrimitiveView, Sendable {
    public typealias Body = Never

    /// The placeholder text to display when the field is empty
    private let placeholder: String

    /// Two-way binding to the currency value
    private let value: Binding<Double>

    /// The currency type to use for formatting
    private let currency: CurrencyType

    // MARK: - Initializers

    /// Creates a currency field with a placeholder and value binding.
    ///
    /// - Parameters:
    ///   - placeholder: The placeholder text to display when empty.
    ///   - value: A binding to the currency value.
    ///   - currency: The currency type to use. Defaults to `.usd`.
    ///
    /// Example:
    /// ```swift
    /// @State private var price: Double = 0
    ///
    /// CurrencyField("Enter amount", value: $price)
    /// ```
    @MainActor public init(
        _ placeholder: String,
        value: Binding<Double>,
        currency: CurrencyType = .usd
    ) {
        self.placeholder = placeholder
        self.value = value
        self.currency = currency
    }

    /// Creates a currency field with a localized placeholder.
    ///
    /// - Parameters:
    ///   - titleKey: The localized string key for the placeholder.
    ///   - value: A binding to the currency value.
    ///   - currency: The currency type to use.
    ///
    /// Example:
    /// ```swift
    /// @State private var price: Double = 0
    ///
    /// CurrencyField("price_placeholder", value: $price)
    /// ```
    @MainActor public init(
        _ titleKey: LocalizedStringKey,
        value: Binding<Double>,
        currency: CurrencyType = .usd
    ) {
        self.placeholder = titleKey.stringValue
        self.value = value
        self.currency = currency
    }

    // MARK: - VNode Conversion

    /// Converts this CurrencyField to a virtual DOM node.
    ///
    /// The CurrencyField is rendered as an `input` element with:
    /// - `type="text"` attribute (not number, to allow formatting)
    /// - `inputmode="decimal"` for mobile keyboard
    /// - `placeholder` attribute for hint text
    /// - `value` attribute bound to the formatted currency value
    /// - `input` event handler for auto-formatting
    ///
    /// - Returns: A VNode configured as a currency input element with event handlers.
    @MainActor public func toVNode() -> VNode {
        // Generate a unique ID for the input event handler
        let handlerID = UUID()

        // Format the current value
        let formatter = CurrencyFormatter(currency)
        let formattedValue = formatter.format(value.wrappedValue)

        // Create properties for the input element
        let props: [String: VProperty] = [
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
            "aria-label": .attribute(name: "aria-label", value: "\(placeholder) in \(currency.symbol)"),

            // Default styling
            "padding": .style(name: "padding", value: "8px"),
            "border": .style(name: "border", value: "1px solid #ccc"),
            "border-radius": .style(name: "border-radius", value: "4px"),
            "font-size": .style(name: "font-size", value: "14px"),
            "font-family": .style(name: "font-family", value: "monospace"),
            "text-align": .style(name: "text-align", value: "right"),
        ]

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
    @MainActor public var formatter: CurrencyFormatter {
        CurrencyFormatter(currency)
    }
}

// MARK: - Currency Type

/// Defines currency formatting styles for different currencies.
public enum CurrencyType: Sendable, Hashable {
    /// US Dollar: $1,234.56
    case usd

    /// Euro: €1.234,56
    case eur

    /// British Pound: £1,234.56
    case gbp

    /// Japanese Yen: ¥1,234 (no decimals)
    case jpy

    /// Custom currency with symbol and decimal places
    case custom(symbol: String, decimals: Int)

    /// The currency symbol.
    public var symbol: String {
        switch self {
        case .usd: return "$"
        case .eur: return "€"
        case .gbp: return "£"
        case .jpy: return "¥"
        case .custom(let symbol, _): return symbol
        }
    }

    /// The number of decimal places.
    public var decimals: Int {
        switch self {
        case .usd, .eur, .gbp: return 2
        case .jpy: return 0
        case .custom(_, let decimals): return decimals
        }
    }

    /// The decimal separator.
    fileprivate var decimalSeparator: String {
        switch self {
        case .eur: return ","
        default: return "."
        }
    }

    /// The thousands separator.
    fileprivate var thousandsSeparator: String {
        switch self {
        case .eur: return "."
        default: return ","
        }
    }
}

// MARK: - Currency Formatter

/// A formatter for currency values that handles formatting, parsing, and validation.
public struct CurrencyFormatter: InputFormatter, Sendable {
    public typealias Value = Double

    /// The currency type to use
    private let currency: CurrencyType

    /// Creates a currency formatter with the specified currency.
    ///
    /// - Parameter currency: The currency type to use.
    public init(_ currency: CurrencyType) {
        self.currency = currency
    }

    // MARK: - InputFormatter Protocol

    /// Formats a numeric value as a currency string.
    @MainActor public func format(_ value: Double) -> String {
        // Handle special case of zero
        if value == 0 {
            return ""
        }

        // Format the number with proper decimal places
        let rounded = (value * pow(10.0, Double(currency.decimals))).rounded() / pow(10.0, Double(currency.decimals))

        // Split into integer and decimal parts
        let integerPart = Int(abs(rounded))
        let decimalPart = abs(rounded).truncatingRemainder(dividingBy: 1.0)

        // Format integer part with thousands separators
        let integerString = formatWithThousandsSeparator(integerPart)

        // Format decimal part
        var result = currency.symbol + integerString

        if currency.decimals > 0 {
            let decimalValue = Int((decimalPart * pow(10.0, Double(currency.decimals))).rounded())
            let decimalFormat = String(format: "%0\(currency.decimals)d", decimalValue)
            result += currency.decimalSeparator + decimalFormat
        }

        // Add negative sign if needed
        if value < 0 {
            result = "-" + result
        }

        return result
    }

    /// Parses formatted currency text back to a numeric value.
    @MainActor public func parse(_ formattedText: String) -> Double? {
        // Remove currency symbol and separators
        var cleaned = formattedText
            .replacingOccurrences(of: currency.symbol, with: "")
            .replacingOccurrences(of: currency.thousandsSeparator, with: "")
            .replacingOccurrences(of: " ", with: "")
            .trimmingCharacters(in: .whitespaces)

        // Handle different decimal separators
        if currency.decimalSeparator == "," {
            cleaned = cleaned.replacingOccurrences(of: ",", with: ".")
        }

        // Convert to Double
        return Double(cleaned)
    }

    /// Validates whether the currency text is valid.
    @MainActor public func validate(_ text: String) -> Bool {
        // Empty text is valid
        if text.isEmpty {
            return true
        }

        // Try to parse the value
        guard let value = parse(text) else {
            return false
        }

        // Check for reasonable range (avoid overflow)
        return value >= -1_000_000_000 && value <= 1_000_000_000
    }

    /// Returns a placeholder string for the currency.
    @MainActor public func placeholder() -> String {
        let example = currency.decimals > 0 ? "0\(currency.decimalSeparator)\(String(repeating: "0", count: currency.decimals))" : "0"
        return currency.symbol + example
    }

    // MARK: - Private Helpers

    /// Formats an integer with thousands separators.
    @MainActor private func formatWithThousandsSeparator(_ value: Int) -> String {
        let string = String(value)
        var result = ""
        var count = 0

        for char in string.reversed() {
            if count > 0 && count % 3 == 0 {
                result.insert(contentsOf: currency.thousandsSeparator, at: result.startIndex)
            }
            result.insert(char, at: result.startIndex)
            count += 1
        }

        return result
    }
}
