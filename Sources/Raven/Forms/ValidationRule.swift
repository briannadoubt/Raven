import Foundation

// MARK: - ValidationRule

/// A rule that validates field values.
///
/// Validation rules define the constraints and requirements for form fields.
/// They can be synchronous or asynchronous and can be combined for complex validation.
///
/// ## Overview
///
/// Use validation rules to enforce data quality and format requirements in forms.
/// Rules can be chained together and applied to fields individually or as part
/// of a form-wide validation strategy.
///
/// ## Basic Usage
///
/// ```swift
/// let emailRule = ValidationRule.email(field: "email")
/// let result = emailRule.validate("user@example.com")
/// ```
///
/// ## Combining Rules
///
/// ```swift
/// let passwordRules = ValidationRule.combine([
///     .required(field: "password"),
///     .minLength(field: "password", length: 8),
///     .regex(field: "password", pattern: ".*[A-Z].*", message: "Must contain uppercase")
/// ])
/// ```
public struct ValidationRule: Sendable {
    /// The field identifier this rule applies to
    public let field: String

    /// The validation function
    private let validator: @Sendable (String) -> ValidationResult

    /// Creates a custom validation rule
    ///
    /// - Parameters:
    ///   - field: The field identifier this rule applies to
    ///   - validator: The validation function
    public init(
        field: String,
        validator: @escaping @Sendable (String) -> ValidationResult
    ) {
        self.field = field
        self.validator = validator
    }

    /// Validates a value against this rule
    ///
    /// - Parameter value: The value to validate
    /// - Returns: The validation result
    public func validate(_ value: String) -> ValidationResult {
        validator(value)
    }
}

// MARK: - AsyncValidationRule

/// A validation rule that performs asynchronous validation.
///
/// Use async rules for validations that require network calls,
/// database queries, or other asynchronous operations.
///
/// ## Basic Usage
///
/// ```swift
/// let uniqueEmailRule = AsyncValidationRule(field: "email") { value in
///     let isUnique = await checkEmailUniqueness(value)
///     if isUnique {
///         return .success
///     } else {
///         return .failure(.init(
///             field: "email",
///             type: .custom("duplicate"),
///             message: "Email already in use"
///         ))
///     }
/// }
/// ```
public struct AsyncValidationRule: Sendable {
    /// The field identifier this rule applies to
    public let field: String

    /// The async validation function
    private let validator: @Sendable (String) async -> ValidationResult

    /// Creates an async validation rule
    ///
    /// - Parameters:
    ///   - field: The field identifier this rule applies to
    ///   - validator: The async validation function
    public init(
        field: String,
        validator: @escaping @Sendable (String) async -> ValidationResult
    ) {
        self.field = field
        self.validator = validator
    }

    /// Validates a value against this rule asynchronously
    ///
    /// - Parameter value: The value to validate
    /// - Returns: The validation result
    public func validate(_ value: String) async -> ValidationResult {
        await validator(value)
    }
}

// MARK: - Built-in Validation Rules

extension ValidationRule {
    /// Creates a required field rule
    ///
    /// - Parameters:
    ///   - field: The field identifier
    ///   - message: Optional custom error message
    /// - Returns: A validation rule that checks for non-empty values
    public static func required(
        field: String,
        message: String? = nil
    ) -> ValidationRule {
        ValidationRule(field: field) { value in
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                return .failure(.required(field: field, message: message))
            }
            return ValidationResult.success
        }
    }

    /// Creates an email validation rule
    ///
    /// - Parameters:
    ///   - field: The field identifier
    ///   - message: Optional custom error message
    /// - Returns: A validation rule that checks for valid email format
    public static func email(
        field: String,
        message: String? = nil
    ) -> ValidationRule {
        return ValidationRule(field: field) { value in
            if value.isEmpty {
                return ValidationResult.success // Empty is valid, use required() separately
            }

            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)

            // Reject obvious invalid forms first
            guard !trimmed.isEmpty, !trimmed.contains(" ") else {
                return .failure(.invalidFormat(
                    field: field,
                    message: message ?? "Please enter a valid email address"
                ))
            }

            let parts = trimmed.split(separator: "@", omittingEmptySubsequences: false)
            guard parts.count == 2 else {
                return .failure(.invalidFormat(field: field, message: message))
            }

            let localPart = String(parts[0])
            let domainPart = String(parts[1])

            // Reject empty local/domain, consecutive dots, and edge dots.
            guard !localPart.isEmpty,
                  !domainPart.isEmpty,
                  !localPart.hasPrefix("."),
                  !localPart.hasSuffix("."),
                  !domainPart.hasPrefix("."),
                  !domainPart.hasSuffix("."),
                  !localPart.contains(".."),
                  !domainPart.contains("..")
            else {
                return .failure(.invalidFormat(
                    field: field,
                    message: message ?? "Please enter a valid email address"
                ))
            }

            // Domain must contain a dot and labels must be valid host labels.
            let labels = domainPart.split(separator: ".", omittingEmptySubsequences: false)
            guard labels.count >= 2 else {
                return .failure(.invalidFormat(
                    field: field,
                    message: message ?? "Please enter a valid email address"
                ))
            }

            let hostLabelPattern = "^[A-Za-z0-9-]+$"
            guard let labelRegex = try? NSRegularExpression(pattern: hostLabelPattern, options: []) else {
                return .failure(.invalidFormat(field: field, message: message))
            }

            for label in labels {
                let labelString = String(label)
                guard !labelString.isEmpty,
                      !labelString.hasPrefix("-"),
                      !labelString.hasSuffix("-")
                else {
                    return .failure(.invalidFormat(
                        field: field,
                        message: message ?? "Please enter a valid email address"
                    ))
                }

                let range = NSRange(labelString.startIndex..., in: labelString)
                if labelRegex.firstMatch(in: labelString, options: [], range: range) == nil {
                    return .failure(.invalidFormat(
                        field: field,
                        message: message ?? "Please enter a valid email address"
                    ))
                }
            }

            // Require alphabetic TLD with at least 2 chars.
            if let tld = labels.last, tld.count < 2 || !tld.allSatisfy({ $0.isLetter }) {
                return .failure(.invalidFormat(
                    field: field,
                    message: message ?? "Please enter a valid email address"
                ))
            }

            return ValidationResult.success
        }
    }

    /// Creates a minimum length rule
    ///
    /// - Parameters:
    ///   - field: The field identifier
    ///   - length: The minimum required length
    /// - Returns: A validation rule that checks minimum length
    public static func minLength(
        field: String,
        length: Int
    ) -> ValidationRule {
        ValidationRule(field: field) { value in
            if value.isEmpty {
                return ValidationResult.success // Empty is valid, use required() separately
            }

            if value.count < length {
                return .failure(.tooShort(
                    field: field,
                    minLength: length,
                    actualLength: value.count
                ))
            }

            return ValidationResult.success
        }
    }

    /// Creates a maximum length rule
    ///
    /// - Parameters:
    ///   - field: The field identifier
    ///   - length: The maximum allowed length
    /// - Returns: A validation rule that checks maximum length
    public static func maxLength(
        field: String,
        length: Int
    ) -> ValidationRule {
        ValidationRule(field: field) { value in
            if value.count > length {
                return .failure(.tooLong(
                    field: field,
                    maxLength: length,
                    actualLength: value.count
                ))
            }

            return ValidationResult.success
        }
    }

    /// Creates a regular expression validation rule
    ///
    /// - Parameters:
    ///   - field: The field identifier
    ///   - pattern: The regex pattern to match
    ///   - message: Error message for pattern mismatch
    /// - Returns: A validation rule that checks pattern matching
    public static func regex(
        field: String,
        pattern: String,
        message: String
    ) -> ValidationRule {
        ValidationRule(field: field) { value in
            if value.isEmpty {
                return ValidationResult.success // Empty is valid, use required() separately
            }

            guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
                return .failure(ValidationError(
                    field: field,
                    type: .patternMismatch,
                    message: "Invalid pattern configuration"
                ))
            }

            let range = NSRange(value.startIndex..., in: value)
            let matches = regex.matches(in: value, options: [], range: range)

            if matches.isEmpty {
                return .failure(ValidationError(
                    field: field,
                    type: .patternMismatch,
                    message: message
                ))
            }

            return ValidationResult.success
        }
    }

    /// Creates a numeric range validation rule
    ///
    /// - Parameters:
    ///   - field: The field identifier
    ///   - min: Optional minimum value
    ///   - max: Optional maximum value
    /// - Returns: A validation rule that checks numeric range
    public static func range<T: Comparable & LosslessStringConvertible & CustomStringConvertible & Sendable>(
        field: String,
        min: T? = nil,
        max: T? = nil
    ) -> ValidationRule where T: Sendable {
        ValidationRule(field: field) { value in
            if value.isEmpty {
                return ValidationResult.success // Empty is valid, use required() separately
            }

            guard let numericValue = T(value) else {
                return .failure(.invalidFormat(
                    field: field,
                    message: "Please enter a valid number"
                ))
            }

            if let min = min, numericValue < min {
                return .failure(.belowMinimum(field: field, minimum: min))
            }

            if let max = max, numericValue > max {
                return .failure(.aboveMaximum(field: field, maximum: max))
            }

            return ValidationResult.success
        }
    }

    /// Creates a custom validation rule
    ///
    /// - Parameters:
    ///   - field: The field identifier
    ///   - message: Error message for validation failure
    ///   - validator: Custom validation function
    /// - Returns: A validation rule with custom logic
    public static func custom(
        field: String,
        message: String,
        validator: @escaping @Sendable (String) -> Bool
    ) -> ValidationRule {
        ValidationRule(field: field) { value in
            if validator(value) {
                return ValidationResult.success
            } else {
                return .failure(ValidationError(
                    field: field,
                    type: .custom("validation"),
                    message: message
                ))
            }
        }
    }

    /// Combines multiple validation rules into one
    ///
    /// - Parameter rules: Array of rules to combine
    /// - Returns: A single rule that applies all rules in sequence
    public static func combine(_ rules: [ValidationRule]) -> ValidationRule {
        guard let firstField = rules.first?.field else {
            fatalError("Cannot combine empty rules array")
        }

        // Verify all rules apply to the same field
        let allSameField = rules.allSatisfy { $0.field == firstField }
        if !allSameField {
            fatalError("Cannot combine rules for different fields")
        }

        return ValidationRule(field: firstField) { value in
            for rule in rules {
                let result = rule.validate(value)
                if case .failure = result {
                    return result
                }
            }
            return ValidationResult.success
        }
    }
}

// MARK: - Async Validation Rules

extension AsyncValidationRule {
    /// Creates an async custom validation rule
    ///
    /// - Parameters:
    ///   - field: The field identifier
    ///   - message: Error message for validation failure
    ///   - validator: Async validation function
    /// - Returns: An async validation rule with custom logic
    public static func custom(
        field: String,
        message: String,
        validator: @escaping @Sendable (String) async -> Bool
    ) -> AsyncValidationRule {
        AsyncValidationRule(field: field) { value in
            let isValid = await validator(value)
            if isValid {
                return ValidationResult.success
            } else {
                return .failure(ValidationError(
                    field: field,
                    type: .asyncValidation,
                    message: message
                ))
            }
        }
    }
}
