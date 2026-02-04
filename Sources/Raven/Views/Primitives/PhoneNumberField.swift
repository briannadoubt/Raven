import Foundation

/// A control for entering formatted phone numbers.
///
/// `PhoneNumberField` is a specialized text input that automatically formats
/// phone numbers according to various regional standards. It provides two-way
/// data binding through a `Binding<String>` and handles formatting as the user types.
///
/// ## Overview
///
/// Use `PhoneNumberField` when you need users to enter phone numbers with
/// automatic formatting. The field applies regional formatting rules and
/// validates input to ensure proper phone number structure.
///
/// ## Basic Usage
///
/// Create a phone number field with default US formatting:
///
/// ```swift
/// struct ContactForm: View {
///     @State private var phoneNumber = ""
///
///     var body: some View {
///         VStack {
///             Text("Phone Number")
///             PhoneNumberField("(555) 555-5555", text: $phoneNumber)
///         }
///     }
/// }
/// ```
///
/// ## Regional Formats
///
/// Specify different phone number formats for various regions:
///
/// ```swift
/// // US format: (555) 555-5555
/// PhoneNumberField("Phone", text: $phone, format: .us)
///
/// // International format: +1 555 555 5555
/// PhoneNumberField("Phone", text: $phone, format: .international)
///
/// // UK format: +44 20 1234 5678
/// PhoneNumberField("Phone", text: $phone, format: .uk)
///
/// // Custom format
/// PhoneNumberField("Phone", text: $phone, format: .custom("+## ### ### ####"))
/// ```
///
/// ## Input Validation
///
/// The field automatically validates phone numbers:
///
/// ```swift
/// @State private var phone = ""
/// @State private var isValid = false
///
/// PhoneNumberField("Phone", text: $phone, format: .us)
///     .onChange(of: phone) { newValue in
///         isValid = PhoneNumberFormatter(.us).validate(newValue)
///     }
/// ```
///
/// ## Auto-formatting
///
/// The field formats input as the user types:
/// - Removes invalid characters (letters, special symbols)
/// - Adds formatting characters (parentheses, dashes, spaces)
/// - Limits input length to valid phone number ranges
/// - Supports paste operations with auto-formatting
///
/// ## Common Patterns
///
/// **Contact form:**
/// ```swift
/// struct ContactView: View {
///     @State private var phone = ""
///
///     var body: some View {
///         Form {
///             PhoneNumberField("Mobile", text: $phone, format: .us)
///             PhoneNumberField("Work", text: $workPhone, format: .us)
///         }
///     }
/// }
/// ```
///
/// **International phone input:**
/// ```swift
/// @State private var countryCode = "+1"
/// @State private var phoneNumber = ""
///
/// HStack {
///     Picker("Code", selection: $countryCode) {
///         Text("+1").tag("+1")
///         Text("+44").tag("+44")
///         Text("+81").tag("+81")
///     }
///     .frame(width: 80)
///
///     PhoneNumberField("Number", text: $phoneNumber, format: .international)
/// }
/// ```
///
/// **With validation indicator:**
/// ```swift
/// @State private var phone = ""
///
/// var isValid: Bool {
///     PhoneNumberFormatter(.us).validate(phone)
/// }
///
/// VStack(alignment: .leading) {
///     PhoneNumberField("Phone", text: $phone)
///
///     if !phone.isEmpty {
///         Label(
///             isValid ? "Valid" : "Invalid phone number",
///             systemImage: isValid ? "checkmark.circle" : "xmark.circle"
///         )
///         .foregroundColor(isValid ? .green : .red)
///     }
/// }
/// ```
///
/// ## Accessibility
///
/// PhoneNumberField provides accessibility features:
/// - Keyboard type set to telephone pad on mobile devices
/// - Screen reader announces the field purpose and current value
/// - Clear error messages for invalid input
///
/// ## Best Practices
///
/// - Use appropriate format for your target region
/// - Provide clear placeholder text showing the expected format
/// - Display validation feedback only after user interaction
/// - Consider international users - support multiple formats
/// - Store the raw digits separately from the formatted display
/// - Handle country codes for international numbers
///
/// ## Data Storage
///
/// The binding receives the formatted string. For storage, you may want
/// to extract just the digits:
///
/// ```swift
/// let digitsOnly = phone.filter { $0.isNumber }
/// ```
///
/// ## See Also
///
/// - ``PhoneNumberFormatter``
/// - ``TextField``
/// - ``NumberFormatField``
public struct PhoneNumberField: View, PrimitiveView, Sendable {
    public typealias Body = Never

    /// The placeholder text to display when the field is empty
    private let placeholder: String

    /// Two-way binding to the phone number text
    private let text: Binding<String>

    /// The phone number format to use
    private let format: PhoneNumberFormat

    // MARK: - Initializers

    /// Creates a phone number field with a placeholder and text binding.
    ///
    /// - Parameters:
    ///   - placeholder: The placeholder text to display when empty.
    ///   - text: A binding to the phone number text.
    ///   - format: The phone number format to apply. Defaults to `.us`.
    ///
    /// Example:
    /// ```swift
    /// @State private var phone = ""
    ///
    /// PhoneNumberField("(555) 555-5555", text: $phone)
    /// ```
    @MainActor public init(
        _ placeholder: String,
        text: Binding<String>,
        format: PhoneNumberFormat = .us
    ) {
        self.placeholder = placeholder
        self.text = text
        self.format = format
    }

    /// Creates a phone number field with a localized placeholder.
    ///
    /// - Parameters:
    ///   - titleKey: The localized string key for the placeholder.
    ///   - text: A binding to the phone number text.
    ///   - format: The phone number format to apply.
    ///
    /// Example:
    /// ```swift
    /// @State private var phone = ""
    ///
    /// PhoneNumberField("phone_placeholder", text: $phone)
    /// ```
    @MainActor public init(
        _ titleKey: LocalizedStringKey,
        text: Binding<String>,
        format: PhoneNumberFormat = .us
    ) {
        self.placeholder = titleKey.stringValue
        self.text = text
        self.format = format
    }

    // MARK: - VNode Conversion

    /// Converts this PhoneNumberField to a virtual DOM node.
    ///
    /// The PhoneNumberField is rendered as an `input` element with:
    /// - `type="tel"` attribute for mobile keyboard optimization
    /// - `placeholder` attribute for hint text
    /// - `value` attribute bound to the formatted phone number
    /// - `input` event handler for auto-formatting
    ///
    /// - Returns: A VNode configured as a tel input element with event handlers.
    @MainActor public func toVNode() -> VNode {
        // Generate a unique ID for the input event handler
        let handlerID = UUID()

        // Create properties for the input element
        let props: [String: VProperty] = [
            // Input type - tel for phone number keyboard
            "type": .attribute(name: "type", value: "tel"),

            // Placeholder text
            "placeholder": .attribute(name: "placeholder", value: placeholder),

            // Current value (reflects the binding)
            "value": .attribute(name: "value", value: text.wrappedValue),

            // Input event handler for auto-formatting
            "onInput": .eventHandler(event: "input", handlerID: handlerID),

            // Autocomplete for better UX
            "autocomplete": .attribute(name: "autocomplete", value: "tel"),

            // ARIA attributes for accessibility
            "aria-label": .attribute(name: "aria-label", value: placeholder),

            // Pattern for basic HTML5 validation (optional)
            "pattern": .attribute(name: "pattern", value: format.htmlPattern),

            // Default styling
            "padding": .style(name: "padding", value: "8px"),
            "border": .style(name: "border", value: "1px solid #ccc"),
            "border-radius": .style(name: "border-radius", value: "4px"),
            "font-size": .style(name: "font-size", value: "14px"),
            "font-family": .style(name: "font-family", value: "monospace"),
        ]

        return VNode.element(
            "input",
            props: props,
            children: []
        )
    }

    // MARK: - Internal Access

    /// Provides access to the text binding for the render coordinator.
    @MainActor public var textBinding: Binding<String> {
        text
    }

    /// Provides access to the formatter for the render coordinator.
    @MainActor public var formatter: PhoneNumberFormatter {
        PhoneNumberFormatter(format)
    }
}

// MARK: - Phone Number Format

/// Defines phone number formatting styles for different regions.
public enum PhoneNumberFormat: Sendable, Hashable {
    /// US format: (555) 555-5555
    case us

    /// International format with country code: +1 555 555 5555
    case international

    /// UK format: +44 20 1234 5678
    case uk

    /// Custom format with pattern (use # for digits)
    case custom(String)

    /// Returns an HTML pattern for basic validation.
    fileprivate var htmlPattern: String {
        switch self {
        case .us:
            return "[0-9]{3}-[0-9]{3}-[0-9]{4}"
        case .international:
            return "\\+[0-9]{1,3}[0-9\\s]{9,15}"
        case .uk:
            return "\\+44[0-9\\s]{10,13}"
        case .custom:
            return "[0-9+\\s\\-\\(\\)]+"
        }
    }
}

// MARK: - Phone Number Formatter

/// A formatter for phone numbers that handles formatting, parsing, and validation.
public struct PhoneNumberFormatter: InputFormatter, Sendable {
    public typealias Value = String

    /// The phone number format to use
    private let format: PhoneNumberFormat

    /// Creates a phone number formatter with the specified format.
    ///
    /// - Parameter format: The phone number format to apply.
    public init(_ format: PhoneNumberFormat) {
        self.format = format
    }

    // MARK: - InputFormatter Protocol

    /// Formats a phone number string according to the format rules.
    @MainActor public func format(_ value: String) -> String {
        // Extract digits only
        let digits = value.filter { $0.isNumber }

        switch format {
        case .us:
            return formatUS(digits)
        case .international:
            return formatInternational(digits)
        case .uk:
            return formatUK(digits)
        case .custom(let pattern):
            return formatCustom(digits, pattern: pattern)
        }
    }

    /// Parses formatted phone number text back to digits.
    @MainActor public func parse(_ formattedText: String) -> String? {
        let digits = formattedText.filter { $0.isNumber || $0 == "+" }
        return digits.isEmpty ? nil : digits
    }

    /// Validates whether the phone number text is valid.
    @MainActor public func validate(_ text: String) -> Bool {
        let digits = text.filter { $0.isNumber }

        switch format {
        case .us:
            return digits.count == 10
        case .international:
            return digits.count >= 10 && digits.count <= 15
        case .uk:
            return digits.count >= 10 && digits.count <= 11
        case .custom:
            return digits.count >= 7 && digits.count <= 15
        }
    }

    /// Returns a placeholder string for the format.
    @MainActor public func placeholder() -> String {
        switch format {
        case .us:
            return "(555) 555-5555"
        case .international:
            return "+1 555 555 5555"
        case .uk:
            return "+44 20 1234 5678"
        case .custom:
            return "Enter phone number"
        }
    }

    // MARK: - Private Formatting Helpers

    /// Formats digits in US format: (555) 555-5555
    @MainActor private func formatUS(_ digits: String) -> String {
        guard !digits.isEmpty else { return "" }

        var result = ""
        let limited = String(digits.prefix(10))

        for (index, char) in limited.enumerated() {
            if index == 0 {
                result.append("(")
            } else if index == 3 {
                result.append(") ")
            } else if index == 6 {
                result.append("-")
            }
            result.append(char)
        }

        return result
    }

    /// Formats digits in international format: +1 555 555 5555
    @MainActor private func formatInternational(_ digits: String) -> String {
        guard !digits.isEmpty else { return "" }

        var result = "+"
        let limited = String(digits.prefix(15))

        for (index, char) in limited.enumerated() {
            if index == 1 || index == 4 || index == 7 {
                result.append(" ")
            }
            result.append(char)
        }

        return result
    }

    /// Formats digits in UK format: +44 20 1234 5678
    @MainActor private func formatUK(_ digits: String) -> String {
        guard !digits.isEmpty else { return "" }

        var result = "+44 "
        let limited = String(digits.prefix(11))

        for (index, char) in limited.enumerated() {
            if index == 2 || index == 6 {
                result.append(" ")
            }
            result.append(char)
        }

        return result
    }

    /// Formats digits according to a custom pattern.
    /// Pattern uses # for digit positions.
    @MainActor private func formatCustom(_ digits: String, pattern: String) -> String {
        var result = ""
        var digitIndex = 0

        for char in pattern {
            if char == "#" {
                if digitIndex < digits.count {
                    let index = digits.index(digits.startIndex, offsetBy: digitIndex)
                    result.append(digits[index])
                    digitIndex += 1
                }
            } else {
                if digitIndex > 0 && digitIndex <= digits.count {
                    result.append(char)
                }
            }
        }

        return result
    }
}
