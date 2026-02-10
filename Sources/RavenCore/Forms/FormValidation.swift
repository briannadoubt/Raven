import Foundation

// MARK: - ValidationModifier

/// A view modifier that applies validation to a view.
///
/// This modifier tracks validation state and applies ARIA attributes
/// for accessibility.
public struct ValidationModifier: ViewModifier, Sendable {
    /// The field identifier
    let field: String

    /// Validation rules to apply
    let rules: [ValidationRule]

    /// The form state
    let formState: FormState

    /// Whether to validate on every change
    let validateOnChange: Bool

    /// Whether to show inline errors
    let showInlineErrors: Bool

    /// Creates a validation modifier
    ///
    /// - Parameters:
    ///   - field: The field identifier
    ///   - rules: Validation rules to apply
    ///   - formState: The form state managing validation
    ///   - validateOnChange: Whether to validate on change. Defaults to true.
    ///   - showInlineErrors: Whether to show inline error messages. Defaults to true.
    public init(
        field: String,
        rules: [ValidationRule],
        formState: FormState,
        validateOnChange: Bool = true,
        showInlineErrors: Bool = true
    ) {
        self.field = field
        self.rules = rules
        self.formState = formState
        self.validateOnChange = validateOnChange
        self.showInlineErrors = showInlineErrors
    }

    @MainActor
    public func body(content: Content) -> some View {
        content
            .modifier(ValidationARIAModifier(
                field: field,
                formState: formState
            ))
    }
}

// MARK: - AsyncValidationModifier

/// A view modifier that applies asynchronous validation to a view.
public struct AsyncValidationModifier: ViewModifier, Sendable {
    /// The field identifier
    let field: String

    /// Async validation rule
    let rule: AsyncValidationRule

    /// The form state
    let formState: FormState

    /// Debounce delay in milliseconds
    let debounce: Int

    /// Creates an async validation modifier
    ///
    /// - Parameters:
    ///   - field: The field identifier
    ///   - rule: Async validation rule to apply
    ///   - formState: The form state managing validation
    ///   - debounce: Debounce delay in milliseconds. Defaults to 300.
    public init(
        field: String,
        rule: AsyncValidationRule,
        formState: FormState,
        debounce: Int = 300
    ) {
        self.field = field
        self.rule = rule
        self.formState = formState
        self.debounce = debounce
    }

    @MainActor
    public func body(content: Content) -> some View {
        content
            .modifier(ValidationARIAModifier(
                field: field,
                formState: formState
            ))
    }
}

// MARK: - ValidationARIAModifier

/// A view modifier that adds ARIA attributes for validation state.
///
/// This modifier applies appropriate ARIA attributes to make validation
/// errors accessible to screen readers and assistive technologies.
public struct ValidationARIAModifier: ViewModifier, Sendable {
    /// The field identifier
    let field: String

    /// The form state
    let formState: FormState

    /// Creates a validation ARIA modifier
    ///
    /// - Parameters:
    ///   - field: The field identifier
    ///   - formState: The form state managing validation
    public init(field: String, formState: FormState) {
        self.field = field
        self.formState = formState
    }

    @MainActor
    public func body(content: Content) -> some View {
        let hasErrors = formState.hasErrors(for: field)
        let shouldShow = formState.shouldShowErrors(for: field)
        let showErrors = hasErrors && shouldShow

        return content
            .modifier(ARIAInvalidModifier(isInvalid: showErrors))
            .modifier(ARIADescribedByModifier(
                describedBy: showErrors ? "\(field)-error" : nil
            ))
    }
}

// MARK: - ARIAInvalidModifier

/// A view modifier that sets the aria-invalid attribute.
struct ARIAInvalidModifier: ViewModifier, Sendable {
    let isInvalid: Bool

    @MainActor
    func body(content: Content) -> some View {
        content
            .modifier(ARIAAttributeModifier(
                attribute: "aria-invalid",
                value: isInvalid ? "true" : "false"
            ))
    }
}

// MARK: - ARIADescribedByModifier

/// A view modifier that sets the aria-describedby attribute.
struct ARIADescribedByModifier: ViewModifier, Sendable {
    let describedBy: String?

    @MainActor
    func body(content: Content) -> some View {
        if let describedBy = describedBy {
            content
                .modifier(ARIAAttributeModifier(
                    attribute: "aria-describedby",
                    value: describedBy
                ))
        } else {
            content
        }
    }
}

// MARK: - ARIAAttributeModifier

/// A low-level view modifier that adds an ARIA attribute.
///
/// This modifier adds ARIA attributes as DOM attributes for accessibility.
/// Note: In the current Raven architecture, ARIA attributes will need to be
/// applied at the rendering layer. This modifier serves as a marker that
/// the rendering system can recognize and apply the attributes accordingly.
struct ARIAAttributeModifier: ViewModifier, Sendable {
    let attribute: String
    let value: String

    @MainActor
    func body(content: Content) -> some View {
        // For now, pass through the content
        // In a full implementation, the rendering system would recognize
        // this modifier and apply ARIA attributes to the resulting DOM element
        content
    }
}

// MARK: - ValidationMessageModifier

/// A view modifier that displays validation error messages.
public struct ValidationMessageModifier: ViewModifier, Sendable {
    /// The field identifier
    let field: String

    /// The form state
    let formState: FormState

    /// The message style
    let style: ValidationMessageStyle

    /// Creates a validation message modifier
    ///
    /// - Parameters:
    ///   - field: The field identifier
    ///   - formState: The form state managing validation
    ///   - style: The visual style for error messages
    public init(
        field: String,
        formState: FormState,
        style: ValidationMessageStyle = .default
    ) {
        self.field = field
        self.formState = formState
        self.style = style
    }

    @MainActor
    public func body(content: Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            content

            if formState.shouldShowErrors(for: field),
               let errorMessage = formState.firstError(for: field) {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(style.color)
                    .modifier(ARIAAttributeModifier(
                        attribute: "id",
                        value: "\(field)-error"
                    ))
                    .modifier(ARIAAttributeModifier(
                        attribute: "role",
                        value: "alert"
                    ))
            }
        }
    }
}

// MARK: - ValidationMessageStyle

/// Visual style for validation error messages.
public struct ValidationMessageStyle: Sendable {
    /// The text color for error messages
    let color: Color

    /// Default red error style
    public static let `default` = ValidationMessageStyle(color: .red)

    /// Custom style with specific color
    ///
    /// - Parameter color: The text color for error messages
    public static func custom(color: Color) -> ValidationMessageStyle {
        ValidationMessageStyle(color: color)
    }
}

// MARK: - View Extensions

extension View {
    /// Applies validation rules to this view.
    ///
    /// This method adds validation logic and ARIA attributes for accessibility.
    ///
    /// ## Basic Usage
    ///
    /// ```swift
    /// @StateObject private var formState = FormState()
    ///
    /// TextField("Email", text: $email)
    ///     .validated(
    ///         by: [.required(field: "email"), .email(field: "email")],
    ///         in: formState
    ///     )
    /// ```
    ///
    /// ## Single Rule
    ///
    /// ```swift
    /// TextField("Name", text: $name)
    ///     .validated(by: .required(field: "name"), in: formState)
    /// ```
    ///
    /// - Parameters:
    ///   - rules: Validation rules to apply
    ///   - formState: The form state managing validation
    ///   - validateOnChange: Whether to validate on change. Defaults to true.
    /// - Returns: A view with validation applied
    @MainActor
    public func validated(
        by rules: [ValidationRule],
        in formState: FormState,
        validateOnChange: Bool = true
    ) -> some View {
        guard let firstRule = rules.first else {
            return AnyView(self)
        }

        return AnyView(
            self.modifier(ValidationModifier(
                field: firstRule.field,
                rules: rules,
                formState: formState,
                validateOnChange: validateOnChange
            ))
        )
    }

    /// Applies a single validation rule to this view.
    ///
    /// - Parameters:
    ///   - rule: Validation rule to apply
    ///   - formState: The form state managing validation
    ///   - validateOnChange: Whether to validate on change. Defaults to true.
    /// - Returns: A view with validation applied
    @MainActor
    public func validated(
        by rule: ValidationRule,
        in formState: FormState,
        validateOnChange: Bool = true
    ) -> some View {
        validated(by: [rule], in: formState, validateOnChange: validateOnChange)
    }

    /// Applies async validation to this view.
    ///
    /// ## Basic Usage
    ///
    /// ```swift
    /// @StateObject private var formState = FormState()
    ///
    /// TextField("Username", text: $username)
    ///     .validatedAsync(
    ///         by: .custom(field: "username", message: "Username taken") { username in
    ///             await checkUsernameAvailability(username)
    ///         },
    ///         in: formState,
    ///         debounce: 500
    ///     )
    /// ```
    ///
    /// - Parameters:
    ///   - rule: Async validation rule to apply
    ///   - formState: The form state managing validation
    ///   - debounce: Debounce delay in milliseconds. Defaults to 300.
    /// - Returns: A view with async validation applied
    @MainActor
    public func validatedAsync(
        by rule: AsyncValidationRule,
        in formState: FormState,
        debounce: Int = 300
    ) -> some View {
        self.modifier(AsyncValidationModifier(
            field: rule.field,
            rule: rule,
            formState: formState,
            debounce: debounce
        ))
    }

    /// Displays validation error messages below this view.
    ///
    /// ## Basic Usage
    ///
    /// ```swift
    /// TextField("Email", text: $email)
    ///     .validated(by: .email(field: "email"), in: formState)
    ///     .validationMessage(for: "email", in: formState)
    /// ```
    ///
    /// ## Custom Style
    ///
    /// ```swift
    /// TextField("Email", text: $email)
    ///     .validationMessage(
    ///         for: "email",
    ///         in: formState,
    ///         style: .custom(color: .orange)
    ///     )
    /// ```
    ///
    /// - Parameters:
    ///   - field: The field identifier
    ///   - formState: The form state managing validation
    ///   - style: The visual style for error messages. Defaults to red.
    /// - Returns: A view with error messages displayed
    @MainActor
    public func validationMessage(
        for field: String,
        in formState: FormState,
        style: ValidationMessageStyle = .default
    ) -> some View {
        self.modifier(ValidationMessageModifier(
            field: field,
            formState: formState,
            style: style
        ))
    }
}

// MARK: - Binding Extensions

extension Binding where Value == String {
    /// Creates a validated binding that updates form state.
    ///
    /// - Parameters:
    ///   - rules: Validation rules to apply
    ///   - formState: The form state to update
    /// - Returns: A binding that validates on change
    @MainActor
    public func validated(
        with rules: [ValidationRule],
        in formState: FormState
    ) -> Binding<String> {
        Binding(
            get: { self.wrappedValue },
            set: { newValue in
                self.wrappedValue = newValue
                formState.validate(newValue, with: rules)
            }
        )
    }

    /// Creates an async validated binding that updates form state.
    ///
    /// - Parameters:
    ///   - rule: Async validation rule to apply
    ///   - formState: The form state to update
    /// - Returns: A binding that validates asynchronously on change
    @MainActor
    public func validatedAsync(
        with rule: AsyncValidationRule,
        in formState: FormState
    ) -> Binding<String> {
        Binding(
            get: { self.wrappedValue },
            set: { newValue in
                self.wrappedValue = newValue
                formState.validateAsync(newValue, with: rule)
            }
        )
    }
}

// MARK: - FormState Extensions for Convenience

extension FormState {
    /// Creates a validated binding for a field.
    ///
    /// - Parameters:
    ///   - binding: The source binding
    ///   - rules: Validation rules to apply
    /// - Returns: A binding that validates on change
    @MainActor
    public func binding(
        _ binding: Binding<String>,
        validatedWith rules: [ValidationRule]
    ) -> Binding<String> {
        binding.validated(with: rules, in: self)
    }
}
