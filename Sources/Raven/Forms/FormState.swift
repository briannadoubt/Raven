import Foundation

// MARK: - FormState

/// Observable state manager for form validation and submission.
///
/// `FormState` manages the validation state, errors, and submission lifecycle
/// for form fields. It provides a centralized way to track validation status
/// and coordinate form submission.
///
/// ## Overview
///
/// Use `FormState` to manage complex forms with multiple validated fields.
/// It tracks field values, validation errors, submission state, and provides
/// methods for validating and submitting forms.
///
/// ## Basic Usage
///
/// ```swift
/// @StateObject private var formState = FormState()
///
/// var body: some View {
///     Form {
///         TextField("Email", text: $email)
///             .validated(by: .email(field: "email"), in: formState)
///
///         Button("Submit") {
///             formState.submit {
///                 await submitForm()
///             }
///         }
///         .disabled(!formState.isValid || formState.isSubmitting)
///     }
/// }
/// ```
///
/// ## Validation Tracking
///
/// FormState automatically tracks validation results for all fields:
///
/// ```swift
/// formState.hasErrors(for: "email") // Check if field has errors
/// formState.errors(for: "email")    // Get field errors
/// formState.isValid                 // Check if all fields valid
/// ```
@MainActor
public final class FormState: ObservableObject {
    /// Dictionary of field validation errors
    @Published public private(set) var fieldErrors: [String: [ValidationError]] = [:]

    /// Whether the form is currently being submitted
    @Published public private(set) var isSubmitting: Bool = false

    /// Whether the form has been submitted at least once
    @Published public private(set) var hasBeenSubmitted: Bool = false

    /// Whether validation errors should be shown
    @Published public private(set) var showErrors: Bool = false

    /// Dictionary of field touched state
    @Published public private(set) var touchedFields: Set<String> = []

    /// Dictionary of pending async validations
    private var pendingValidations: [String: Task<Void, Never>] = [:]

    /// Creates a new form state
    public init() {
        setupPublished()
    }

    // MARK: - Validation State

    /// Whether all fields are valid
    public var isValid: Bool {
        fieldErrors.values.allSatisfy { $0.isEmpty }
    }

    /// Whether any field has errors
    public var hasAnyErrors: Bool {
        !isValid
    }

    /// Checks if a specific field has errors
    ///
    /// - Parameter field: The field identifier
    /// - Returns: Whether the field has validation errors
    public func hasErrors(for field: String) -> Bool {
        if let errors = fieldErrors[field] {
            return !errors.isEmpty
        }
        return false
    }

    /// Gets validation errors for a specific field
    ///
    /// - Parameter field: The field identifier
    /// - Returns: Array of validation errors for the field
    public func errors(for field: String) -> [ValidationError] {
        fieldErrors[field] ?? []
    }

    /// Gets the first error message for a field
    ///
    /// - Parameter field: The field identifier
    /// - Returns: The first error message, or nil if no errors
    public func firstError(for field: String) -> String? {
        errors(for: field).first?.message
    }

    /// Checks if a field has been touched by the user
    ///
    /// - Parameter field: The field identifier
    /// - Returns: Whether the field has been touched
    public func isTouched(_ field: String) -> Bool {
        touchedFields.contains(field)
    }

    /// Whether errors should be shown for a specific field
    ///
    /// Errors are shown if the form has been submitted or the field has been touched
    ///
    /// - Parameter field: The field identifier
    /// - Returns: Whether to show errors for this field
    public func shouldShowErrors(for field: String) -> Bool {
        showErrors || hasBeenSubmitted || isTouched(field)
    }

    // MARK: - Field Management

    /// Marks a field as touched
    ///
    /// - Parameter field: The field identifier
    public func touch(_ field: String) {
        touchedFields.insert(field)
    }

    /// Marks a field as untouched
    ///
    /// - Parameter field: The field identifier
    public func untouch(_ field: String) {
        touchedFields.remove(field)
    }

    /// Marks all fields as touched
    public func touchAll() {
        touchedFields = Set(fieldErrors.keys)
    }

    /// Clears all touched fields
    public func clearTouched() {
        touchedFields.removeAll()
    }

    // MARK: - Validation

    /// Sets validation errors for a field
    ///
    /// - Parameters:
    ///   - errors: Array of validation errors
    ///   - field: The field identifier
    public func setErrors(_ errors: [ValidationError], for field: String) {
        fieldErrors[field] = errors
    }

    /// Sets a single validation error for a field
    ///
    /// - Parameters:
    ///   - error: The validation error
    ///   - field: The field identifier
    public func setError(_ error: ValidationError, for field: String) {
        fieldErrors[field] = [error]
    }

    /// Clears validation errors for a field
    ///
    /// - Parameter field: The field identifier
    public func clearErrors(for field: String) {
        fieldErrors[field] = []
    }

    /// Clears all validation errors
    public func clearAllErrors() {
        fieldErrors.removeAll()
    }

    /// Validates a field with a synchronous rule
    ///
    /// - Parameters:
    ///   - value: The value to validate
    ///   - rule: The validation rule
    /// - Returns: The validation result
    @discardableResult
    public func validate(
        _ value: String,
        with rule: ValidationRule
    ) -> ValidationResult {
        let result = rule.validate(value)

        if case .failure(let error) = result {
            setError(error, for: rule.field)
        } else {
            clearErrors(for: rule.field)
        }

        return result
    }

    /// Validates a field with multiple synchronous rules
    ///
    /// - Parameters:
    ///   - value: The value to validate
    ///   - rules: Array of validation rules
    /// - Returns: Whether all rules passed
    @discardableResult
    public func validate(
        _ value: String,
        with rules: [ValidationRule]
    ) -> Bool {
        guard let firstRule = rules.first else {
            return true
        }

        var allErrors: [ValidationError] = []

        for rule in rules {
            let result = rule.validate(value)
            if case .failure(let error) = result {
                allErrors.append(error)
            }
        }

        if allErrors.isEmpty {
            clearErrors(for: firstRule.field)
            return true
        } else {
            setErrors(allErrors, for: firstRule.field)
            return false
        }
    }

    /// Validates a field with an asynchronous rule
    ///
    /// Cancels any pending validation for the same field before starting.
    ///
    /// - Parameters:
    ///   - value: The value to validate
    ///   - rule: The async validation rule
    public func validateAsync(
        _ value: String,
        with rule: AsyncValidationRule
    ) {
        // Cancel pending validation for this field
        pendingValidations[rule.field]?.cancel()

        // Start new validation
        let task = Task { @MainActor in
            let result = await rule.validate(value)

            // Only update if this task wasn't cancelled
            if !Task.isCancelled {
                if case .failure(let error) = result {
                    setError(error, for: rule.field)
                } else {
                    clearErrors(for: rule.field)
                }
            }

            // Clean up
            pendingValidations[rule.field] = nil
        }

        pendingValidations[rule.field] = task
    }

    // MARK: - Form Submission

    /// Submits the form with validation
    ///
    /// This method validates all fields and calls the submission handler
    /// if validation passes.
    ///
    /// - Parameter handler: Async closure to execute on successful validation
    public func submit(_ handler: @escaping @Sendable @MainActor () async throws -> Void) {
        Task { @MainActor in
            hasBeenSubmitted = true
            showErrors = true
            touchAll()

            // Check if form is valid
            guard isValid else {
                return
            }

            // Start submission
            isSubmitting = true

            do {
                try await handler()
                // Success - could add success state tracking here
            } catch {
                // Error - could add error handling here
                print("Form submission error: \(error)")
            }

            isSubmitting = false
        }
    }

    /// Resets the form to initial state
    ///
    /// Clears all errors, touched fields, and submission state.
    public func reset() {
        fieldErrors.removeAll()
        touchedFields.removeAll()
        isSubmitting = false
        hasBeenSubmitted = false
        showErrors = false

        // Cancel all pending validations
        for task in pendingValidations.values {
            task.cancel()
        }
        pendingValidations.removeAll()
    }

    // MARK: - Error Display Control

    /// Shows validation errors for all fields
    public func showAllErrors() {
        showErrors = true
        touchAll()
    }

    /// Hides validation errors
    public func hideErrors() {
        showErrors = false
    }

    // MARK: - Batch Operations

    /// Validates multiple fields at once
    ///
    /// - Parameter validations: Dictionary mapping field names to validation functions
    /// - Returns: Whether all validations passed
    @discardableResult
    public func validateAll(_ validations: [String: () -> ValidationResult]) -> Bool {
        var isValid = true

        for (field, validation) in validations {
            let result = validation()
            if case .failure(let error) = result {
                setError(error, for: field)
                isValid = false
            } else {
                clearErrors(for: field)
            }
        }

        return isValid
    }
}

// MARK: - Convenience Methods

extension FormState {
    /// Creates a validation binding for a field
    ///
    /// - Parameters:
    ///   - field: The field identifier
    ///   - rules: Validation rules to apply
    /// - Returns: A closure that validates the field
    public func validator(
        for field: String,
        rules: [ValidationRule]
    ) -> (String) -> Void {
        return { [weak self] value in
            self?.validate(value, with: rules)
        }
    }

    /// Creates an async validation binding for a field
    ///
    /// - Parameters:
    ///   - field: The field identifier
    ///   - rule: Async validation rule to apply
    /// - Returns: A closure that validates the field asynchronously
    public func asyncValidator(
        for field: String,
        rule: AsyncValidationRule
    ) -> (String) -> Void {
        return { [weak self] value in
            self?.validateAsync(value, with: rule)
        }
    }
}
