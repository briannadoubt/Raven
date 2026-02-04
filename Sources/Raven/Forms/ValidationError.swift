import Foundation

// MARK: - ValidationError

/// Represents a validation error for a form field.
///
/// Validation errors contain information about what failed validation
/// and can provide localized error messages to display to users.
///
/// ## Overview
///
/// Use `ValidationError` to represent validation failures in form fields.
/// Each error contains a field identifier, error type, and message.
///
/// ## Basic Usage
///
/// ```swift
/// let error = ValidationError(
///     field: "email",
///     type: .invalidFormat,
///     message: "Please enter a valid email address"
/// )
/// ```
///
/// ## Error Context
///
/// Errors can include additional context for debugging:
///
/// ```swift
/// let error = ValidationError(
///     field: "password",
///     type: .tooShort,
///     message: "Password must be at least 8 characters",
///     context: ["minLength": "8", "actualLength": "5"]
/// )
/// ```
public struct ValidationError: Error, Sendable, Hashable, Identifiable {
    /// Unique identifier for the error
    public let id: UUID

    /// The field identifier this error is associated with
    public let field: String

    /// The type of validation error
    public let type: ValidationErrorType

    /// Human-readable error message
    public let message: String

    /// Optional context information for debugging
    public let context: [String: String]

    /// Creates a validation error.
    ///
    /// - Parameters:
    ///   - field: The field identifier this error is associated with.
    ///   - type: The type of validation error.
    ///   - message: Human-readable error message.
    ///   - context: Optional context information for debugging.
    public init(
        field: String,
        type: ValidationErrorType,
        message: String,
        context: [String: String] = [:]
    ) {
        self.id = UUID()
        self.field = field
        self.type = type
        self.message = message
        self.context = context
    }
}

// MARK: - ValidationErrorType

/// Types of validation errors that can occur.
///
/// This enum categorizes common validation failures to allow
/// for consistent error handling and styling.
public enum ValidationErrorType: Sendable, Hashable {
    /// Field is required but empty
    case required

    /// Field value doesn't match expected format
    case invalidFormat

    /// Field value is too short
    case tooShort

    /// Field value is too long
    case tooLong

    /// Field value is below minimum range
    case belowMinimum

    /// Field value is above maximum range
    case aboveMaximum

    /// Field value doesn't match regex pattern
    case patternMismatch

    /// Custom validation failed
    case custom(String)

    /// Async validation failed
    case asyncValidation
}

// MARK: - ValidationResult

/// Result of a validation operation.
///
/// Validation rules return this type to indicate success or failure.
///
/// ## Basic Usage
///
/// ```swift
/// let result: ValidationResult = .success
///
/// let result: ValidationResult = .failure(
///     ValidationError(
///         field: "email",
///         type: .invalidFormat,
///         message: "Invalid email"
///     )
/// )
/// ```
public enum ValidationResult: Sendable, Hashable {
    /// Validation succeeded
    case success

    /// Validation failed with one or more errors
    case failure(ValidationError)

    /// Whether validation succeeded
    public var isValid: Bool {
        if case .success = self {
            return true
        }
        return false
    }

    /// Whether validation failed
    public var isInvalid: Bool {
        !isValid
    }

    /// Get the error if validation failed
    public var error: ValidationError? {
        if case .failure(let error) = self {
            return error
        }
        return nil
    }
}

// MARK: - AsyncValidationResult

/// Result of an asynchronous validation operation.
///
/// Async validation rules return this type wrapped in a Task or async function.
public typealias AsyncValidationResult = ValidationResult

// MARK: - ValidationError Extensions

extension ValidationError: CustomStringConvertible {
    /// A textual representation of the validation error
    public var description: String {
        "ValidationError(field: \(field), type: \(type), message: \"\(message)\")"
    }
}

extension ValidationError {
    /// Creates a required field error
    ///
    /// - Parameters:
    ///   - field: The field identifier
    ///   - message: Optional custom message. Defaults to standard message.
    /// - Returns: A validation error for a required field
    public static func required(
        field: String,
        message: String? = nil
    ) -> ValidationError {
        ValidationError(
            field: field,
            type: .required,
            message: message ?? "This field is required"
        )
    }

    /// Creates an invalid format error
    ///
    /// - Parameters:
    ///   - field: The field identifier
    ///   - message: Optional custom message. Defaults to standard message.
    /// - Returns: A validation error for invalid format
    public static func invalidFormat(
        field: String,
        message: String? = nil
    ) -> ValidationError {
        ValidationError(
            field: field,
            type: .invalidFormat,
            message: message ?? "Invalid format"
        )
    }

    /// Creates a minimum length error
    ///
    /// - Parameters:
    ///   - field: The field identifier
    ///   - minLength: The minimum required length
    ///   - actualLength: The actual length of the value
    /// - Returns: A validation error for minimum length violation
    public static func tooShort(
        field: String,
        minLength: Int,
        actualLength: Int
    ) -> ValidationError {
        ValidationError(
            field: field,
            type: .tooShort,
            message: "Must be at least \(minLength) characters",
            context: [
                "minLength": String(minLength),
                "actualLength": String(actualLength)
            ]
        )
    }

    /// Creates a maximum length error
    ///
    /// - Parameters:
    ///   - field: The field identifier
    ///   - maxLength: The maximum allowed length
    ///   - actualLength: The actual length of the value
    /// - Returns: A validation error for maximum length violation
    public static func tooLong(
        field: String,
        maxLength: Int,
        actualLength: Int
    ) -> ValidationError {
        ValidationError(
            field: field,
            type: .tooLong,
            message: "Must be at most \(maxLength) characters",
            context: [
                "maxLength": String(maxLength),
                "actualLength": String(actualLength)
            ]
        )
    }

    /// Creates a range error for values below minimum
    ///
    /// - Parameters:
    ///   - field: The field identifier
    ///   - minimum: The minimum allowed value
    /// - Returns: A validation error for below minimum
    public static func belowMinimum<T: Comparable & CustomStringConvertible>(
        field: String,
        minimum: T
    ) -> ValidationError {
        ValidationError(
            field: field,
            type: .belowMinimum,
            message: "Must be at least \(minimum)",
            context: ["minimum": String(describing: minimum)]
        )
    }

    /// Creates a range error for values above maximum
    ///
    /// - Parameters:
    ///   - field: The field identifier
    ///   - maximum: The maximum allowed value
    /// - Returns: A validation error for above maximum
    public static func aboveMaximum<T: Comparable & CustomStringConvertible>(
        field: String,
        maximum: T
    ) -> ValidationError {
        ValidationError(
            field: field,
            type: .aboveMaximum,
            message: "Must be at most \(maximum)",
            context: ["maximum": String(describing: maximum)]
        )
    }
}
