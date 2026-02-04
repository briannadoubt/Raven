import Foundation

/// A protocol that defines how to format, parse, and validate input values.
///
/// `InputFormatter` provides a standardized interface for text input formatting,
/// allowing specialized input fields to transform raw text input into structured
/// values and vice versa. This enables fields like phone numbers, currency, and
/// custom number formats to provide user-friendly input experiences.
///
/// ## Overview
///
/// Formatters handle three key operations:
/// - **Formatting**: Convert a value into a display string for the user
/// - **Parsing**: Convert user input text back into the underlying value type
/// - **Validation**: Check if input text is valid for the expected format
///
/// ## Implementing a Custom Formatter
///
/// ```swift
/// struct SSNFormatter: InputFormatter {
///     func format(_ value: String) -> String {
///         let digits = value.filter { $0.isNumber }
///         guard !digits.isEmpty else { return "" }
///
///         var result = ""
///         for (index, char) in digits.prefix(9).enumerated() {
///             if index == 3 || index == 5 {
///                 result.append("-")
///             }
///             result.append(char)
///         }
///         return result
///     }
///
///     func parse(_ formattedText: String) -> String? {
///         let digits = formattedText.filter { $0.isNumber }
///         return digits.isEmpty ? nil : String(digits)
///     }
///
///     func validate(_ text: String) -> Bool {
///         let digits = text.filter { $0.isNumber }
///         return digits.count <= 9
///     }
/// }
/// ```
///
/// ## Built-in Formatters
///
/// Raven provides several built-in formatters:
/// - ``PhoneNumberFormatter`` - Format phone numbers in various international formats
/// - ``CurrencyFormatter`` - Format currency values with locale-specific symbols
/// - ``NumberFormatter`` - Format numbers with custom decimal places and grouping
///
/// ## See Also
///
/// - ``NumberFormatField``
/// - ``CurrencyField``
/// - ``PhoneNumberField``
public protocol InputFormatter: Sendable {
    /// The type of value this formatter works with
    associatedtype Value: Sendable

    /// Formats a value into a display string.
    ///
    /// This method converts the underlying value into a string that will be
    /// displayed to the user. The formatted string should be human-readable
    /// and follow the conventions of the formatter's domain.
    ///
    /// - Parameter value: The value to format
    /// - Returns: A formatted string representation of the value
    @MainActor func format(_ value: Value) -> String

    /// Parses formatted text back into a value.
    ///
    /// This method attempts to convert user input text into the underlying
    /// value type. If the text cannot be parsed into a valid value, this
    /// method returns `nil`.
    ///
    /// - Parameter formattedText: The text to parse
    /// - Returns: The parsed value, or `nil` if parsing fails
    @MainActor func parse(_ formattedText: String) -> Value?

    /// Validates whether text conforms to this formatter's rules.
    ///
    /// This method checks if the input text is valid according to the
    /// formatter's constraints. Unlike `parse()`, this method doesn't
    /// require the text to be complete or convertible to a value - it
    /// only checks if the current text is valid as-is or could become
    /// valid with additional input.
    ///
    /// - Parameter text: The text to validate
    /// - Returns: `true` if the text is valid, `false` otherwise
    @MainActor func validate(_ text: String) -> Bool

    /// Returns a placeholder string for empty fields.
    ///
    /// Override this to provide a helpful placeholder that shows the
    /// expected format to users.
    ///
    /// - Returns: A placeholder string, or an empty string by default
    @MainActor func placeholder() -> String
}

// MARK: - Default Implementations

extension InputFormatter {
    /// Default placeholder is an empty string.
    @MainActor public func placeholder() -> String {
        return ""
    }
}

// Note: InputFormatter provides a simple boolean validation interface.
// For detailed validation with error messages, consider using the ValidationResult
// type from the Forms module, which provides richer error information.
