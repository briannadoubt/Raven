import Foundation

// MARK: - ValidatedField

/// A property wrapper that wraps a field value with validation.
///
/// `ValidatedField` provides a convenient way to bind field values
/// to validation rules and form state.
///
/// ## Overview
///
/// Use `@ValidatedField` to create form fields that automatically
/// validate their values and update form state.
///
/// ## Basic Usage
///
/// ```swift
/// @StateObject private var formState = FormState()
/// @ValidatedField(
///     formState: formState,
///     field: "email",
///     rules: [.required(field: "email"), .email(field: "email")]
/// )
/// private var email: String = ""
///
/// var body: some View {
///     TextField("Email", text: $email)
/// }
/// ```
///
/// ## Validation Behavior
///
/// Validation occurs automatically when the value changes.
/// Use `validateOnChange` to control validation timing.
@MainActor
@propertyWrapper
public struct ValidatedField: DynamicProperty {
    /// The form state managing validation
    private let formState: FormState

    /// The field identifier
    private let field: String

    /// Validation rules to apply
    private let rules: [ValidationRule]

    /// Whether to validate on every change
    private let validateOnChange: Bool

    /// The underlying value storage
    @State private var value: String

    /// Creates a validated field
    ///
    /// - Parameters:
    ///   - formState: The form state to track validation
    ///   - field: The field identifier
    ///   - rules: Validation rules to apply
    ///   - validateOnChange: Whether to validate on every change. Defaults to true.
    ///   - wrappedValue: Initial value for the field
    public init(
        formState: FormState,
        field: String,
        rules: [ValidationRule],
        validateOnChange: Bool = true,
        wrappedValue: String = ""
    ) {
        self.formState = formState
        self.field = field
        self.rules = rules
        self.validateOnChange = validateOnChange
        self._value = State(initialValue: wrappedValue)
    }

    /// The current value of the field
    public var wrappedValue: String {
        get { value }
        nonmutating set {
            value = newValue

            if validateOnChange {
                formState.validate(newValue, with: rules)
            }
        }
    }

    /// A binding to the field value
    public var projectedValue: Binding<String> {
        Binding(
            get: { value },
            set: { newValue in
                wrappedValue = newValue
            }
        )
    }

    /// Manually triggers validation
    ///
    /// - Returns: Whether validation passed
    @discardableResult
    public func validate() -> Bool {
        formState.validate(value, with: rules)
    }

    /// Gets validation errors for this field
    public var errors: [ValidationError] {
        formState.errors(for: field)
    }

    /// Whether this field has errors
    public var hasErrors: Bool {
        formState.hasErrors(for: field)
    }

    /// The first error message for this field
    public var errorMessage: String? {
        formState.firstError(for: field)
    }
}

// MARK: - AsyncValidatedField

/// A property wrapper for fields with asynchronous validation.
///
/// Use `@AsyncValidatedField` when validation requires async operations
/// like network calls or database queries.
///
/// ## Basic Usage
///
/// ```swift
/// @StateObject private var formState = FormState()
/// @AsyncValidatedField(
///     formState: formState,
///     field: "username",
///     rule: .custom(field: "username", message: "Username taken") { username in
///         await checkUsernameAvailability(username)
///     }
/// )
/// private var username: String = ""
/// ```
@MainActor
@propertyWrapper
public struct AsyncValidatedField: DynamicProperty {
    /// The form state managing validation
    private let formState: FormState

    /// The field identifier
    private let field: String

    /// Async validation rule
    private let rule: AsyncValidationRule

    /// Debounce delay in milliseconds
    private let debounce: Int

    /// The underlying value storage
    @State private var value: String

    /// Debounce timer
    @State private var debounceTask: Task<Void, Never>?

    /// Creates an async validated field
    ///
    /// - Parameters:
    ///   - formState: The form state to track validation
    ///   - field: The field identifier
    ///   - rule: Async validation rule to apply
    ///   - debounce: Debounce delay in milliseconds. Defaults to 300.
    ///   - wrappedValue: Initial value for the field
    public init(
        formState: FormState,
        field: String,
        rule: AsyncValidationRule,
        debounce: Int = 300,
        wrappedValue: String = ""
    ) {
        self.formState = formState
        self.field = field
        self.rule = rule
        self.debounce = debounce
        self._value = State(initialValue: wrappedValue)
    }

    /// The current value of the field
    public var wrappedValue: String {
        get { value }
        nonmutating set {
            value = newValue

            // Cancel previous debounce task
            debounceTask?.cancel()

            // Start new debounced validation
            debounceTask = Task { @MainActor in
                try? await Task.sleep(nanoseconds: UInt64(debounce) * 1_000_000)

                if !Task.isCancelled {
                    formState.validateAsync(newValue, with: rule)
                }
            }
        }
    }

    /// A binding to the field value
    public var projectedValue: Binding<String> {
        Binding(
            get: { value },
            set: { newValue in
                wrappedValue = newValue
            }
        )
    }

    /// Gets validation errors for this field
    public var errors: [ValidationError] {
        formState.errors(for: field)
    }

    /// Whether this field has errors
    public var hasErrors: Bool {
        formState.hasErrors(for: field)
    }

    /// The first error message for this field
    public var errorMessage: String? {
        formState.firstError(for: field)
    }
}
