import Foundation
import Testing
@testable import Raven

/// Comprehensive tests for Form Validation System
/// Tests all ValidationRule types, FormState management, async validation,
/// error display, ARIA attributes, field touch tracking, and edge cases.
@MainActor
@Suite struct FormValidationTests {

    // MARK: - ValidationRule: Required Tests

    @Test func requiredRuleWithEmptyString() {
        let rule = ValidationRule.required(field: "name")
        let result = rule.validate("")

        #expect(result.isInvalid)
        #expect(result.error?.field == "name")
        #expect(result.error?.type == .required)
        #expect(result.error?.message == "This field is required")
    }

    @Test func requiredRuleWithWhitespace() {
        let rule = ValidationRule.required(field: "name")
        let result = rule.validate("   \n\t  ")

        #expect(result.isInvalid)
        #expect(result.error?.type == .required)
    }

    @Test func requiredRuleWithValidValue() {
        let rule = ValidationRule.required(field: "name")
        let result = rule.validate("John Doe")

        #expect(result.isValid)
        #expect(result.error == nil)
    }

    @Test func requiredRuleWithCustomMessage() {
        let rule = ValidationRule.required(field: "email", message: "Email is required")
        let result = rule.validate("")

        #expect(result.isInvalid)
        #expect(result.error?.message == "Email is required")
    }

    // MARK: - ValidationRule: Email Tests

    @Test func emailRuleWithValidEmail() {
        let rule = ValidationRule.email(field: "email")
        let validEmails = [
            "user@example.com",
            "test.user@domain.co.uk",
            "name+tag@test.org",
            "user123@test-domain.com"
        ]

        for email in validEmails {
            let result = rule.validate(email)
            #expect(result.isValid)
        }
    }

    @Test func emailRuleWithInvalidEmail() {
        let rule = ValidationRule.email(field: "email")
        let invalidEmails = [
            "notanemail",
            "@example.com",
            "user@",
            "user @example.com",
            "user@.com",
            "user..name@example.com"
        ]

        for email in invalidEmails {
            let result = rule.validate(email)
            #expect(result.isInvalid)
            #expect(result.error?.type == .invalidFormat)
        }
    }

    @Test func emailRuleWithEmptyString() {
        let rule = ValidationRule.email(field: "email")
        let result = rule.validate("")

        // Email rule allows empty (use required separately)
        #expect(result.isValid)
    }

    @Test func emailRuleWithCustomMessage() {
        let rule = ValidationRule.email(field: "email", message: "Invalid email format")
        let result = rule.validate("notanemail")

        #expect(result.isInvalid)
        #expect(result.error?.message == "Invalid email format")
    }

    // MARK: - ValidationRule: MinLength Tests

    @Test func minLengthRuleValid() {
        let rule = ValidationRule.minLength(field: "password", length: 8)
        let result = rule.validate("password123")

        #expect(result.isValid)
    }

    @Test func minLengthRuleInvalid() {
        let rule = ValidationRule.minLength(field: "password", length: 8)
        let result = rule.validate("short")

        #expect(result.isInvalid)
        #expect(result.error?.type == .tooShort)
        #expect(result.error?.message == "Must be at least 8 characters")
        #expect(result.error?.context["minLength"] == "8")
        #expect(result.error?.context["actualLength"] == "5")
    }

    @Test func minLengthRuleExactLength() {
        let rule = ValidationRule.minLength(field: "password", length: 8)
        let result = rule.validate("12345678")

        #expect(result.isValid)
    }

    @Test func minLengthRuleWithEmptyString() {
        let rule = ValidationRule.minLength(field: "password", length: 8)
        let result = rule.validate("")

        // MinLength allows empty (use required separately)
        #expect(result.isValid)
    }

    // MARK: - ValidationRule: MaxLength Tests

    @Test func maxLengthRuleValid() {
        let rule = ValidationRule.maxLength(field: "bio", length: 100)
        let result = rule.validate("Short bio")

        #expect(result.isValid)
    }

    @Test func maxLengthRuleInvalid() {
        let rule = ValidationRule.maxLength(field: "bio", length: 10)
        let result = rule.validate("This is a very long biography text")

        #expect(result.isInvalid)
        #expect(result.error?.type == .tooLong)
        #expect(result.error?.message == "Must be at most 10 characters")
        #expect(result.error?.context["maxLength"] == "10")
        #expect(result.error?.context["actualLength"] == "35")
    }

    @Test func maxLengthRuleExactLength() {
        let rule = ValidationRule.maxLength(field: "code", length: 6)
        let result = rule.validate("123456")

        #expect(result.isValid)
    }

    @Test func maxLengthRuleWithEmptyString() {
        let rule = ValidationRule.maxLength(field: "bio", length: 100)
        let result = rule.validate("")

        #expect(result.isValid)
    }

    // MARK: - ValidationRule: Regex Tests

    @Test func regexRuleValid() {
        let rule = ValidationRule.regex(
            field: "zipcode",
            pattern: "^\\d{5}$",
            message: "Must be 5 digits"
        )
        let result = rule.validate("12345")

        #expect(result.isValid)
    }

    @Test func regexRuleInvalid() {
        let rule = ValidationRule.regex(
            field: "zipcode",
            pattern: "^\\d{5}$",
            message: "Must be 5 digits"
        )
        let result = rule.validate("1234")

        #expect(result.isInvalid)
        #expect(result.error?.type == .patternMismatch)
        #expect(result.error?.message == "Must be 5 digits")
    }

    @Test func regexRuleComplexPattern() {
        let rule = ValidationRule.regex(
            field: "password",
            pattern: "^(?=.*[A-Z])(?=.*[0-9]).*$",
            message: "Must contain uppercase and number"
        )

        #expect(rule.validate("Password123").isValid)
        #expect(rule.validate("abc123").isInvalid)
        #expect(rule.validate("ABCDEF").isInvalid)
    }

    @Test func regexRuleWithEmptyString() {
        let rule = ValidationRule.regex(
            field: "code",
            pattern: "^\\d+$",
            message: "Must be numeric"
        )
        let result = rule.validate("")

        // Regex allows empty (use required separately)
        #expect(result.isValid)
    }

    // MARK: - ValidationRule: Range Tests

    @Test func rangeRuleWithIntegerValid() {
        let rule = ValidationRule.range(field: "age", min: 18, max: 100)

        #expect(rule.validate("25").isValid)
        #expect(rule.validate("18").isValid)
        #expect(rule.validate("100").isValid)
    }

    @Test func rangeRuleWithIntegerBelowMin() {
        let rule = ValidationRule.range(field: "age", min: 18, max: 100)
        let result = rule.validate("15")

        #expect(result.isInvalid)
        #expect(result.error?.type == .belowMinimum)
        #expect(result.error?.message == "Must be at least 18")
    }

    @Test func rangeRuleWithIntegerAboveMax() {
        let rule = ValidationRule.range(field: "age", min: 18, max: 100)
        let result = rule.validate("150")

        #expect(result.isInvalid)
        #expect(result.error?.type == .aboveMaximum)
        #expect(result.error?.message == "Must be at most 100")
    }

    @Test func rangeRuleWithDoubleValid() {
        let rule = ValidationRule.range(field: "price", min: 0.0, max: 999.99)

        #expect(rule.validate("49.99").isValid)
        #expect(rule.validate("0.0").isValid)
        #expect(rule.validate("999.99").isValid)
    }

    @Test func rangeRuleWithInvalidNumber() {
        let rule = ValidationRule.range(field: "age", min: 0, max: 100)
        let result = rule.validate("not a number")

        #expect(result.isInvalid)
        #expect(result.error?.type == .invalidFormat)
        #expect(result.error?.message == "Please enter a valid number")
    }

    @Test func rangeRuleOnlyMinimum() {
        let rule = ValidationRule.range(field: "quantity", min: 1)

        #expect(rule.validate("5").isValid)
        #expect(rule.validate("1").isValid)
        #expect(rule.validate("0").isInvalid)
    }

    @Test func rangeRuleOnlyMaximum() {
        let rule = ValidationRule.range(field: "discount", max: 100)

        #expect(rule.validate("50").isValid)
        #expect(rule.validate("100").isValid)
        #expect(rule.validate("101").isInvalid)
    }

    @Test func rangeRuleWithEmptyString() {
        let rule = ValidationRule.range(field: "age", min: 0, max: 100)
        let result = rule.validate("")

        // Range allows empty (use required separately)
        #expect(result.isValid)
    }

    // MARK: - ValidationRule: Custom Tests

    @Test func customRuleValid() {
        let rule = ValidationRule.custom(
            field: "username",
            message: "Username must start with a letter"
        ) { value in
            guard let first = value.first else { return false }
            return first.isLetter
        }

        let result = rule.validate("john123")
        #expect(result.isValid)
    }

    @Test func customRuleInvalid() {
        let rule = ValidationRule.custom(
            field: "username",
            message: "Username must start with a letter"
        ) { value in
            guard let first = value.first else { return false }
            return first.isLetter
        }

        let result = rule.validate("123john")
        #expect(result.isInvalid)
        #expect(result.error?.type == .custom("validation"))
        #expect(result.error?.message == "Username must start with a letter")
    }

    // MARK: - ValidationRule: Combine Tests

    @Test func combineRulesAllPass() {
        let combined = ValidationRule.combine([
            .required(field: "password"),
            .minLength(field: "password", length: 8),
            .regex(field: "password", pattern: ".*[A-Z].*", message: "Need uppercase")
        ])

        let result = combined.validate("Password123")
        #expect(result.isValid)
    }

    @Test func combineRulesFirstFails() {
        let combined = ValidationRule.combine([
            .required(field: "password"),
            .minLength(field: "password", length: 8),
            .regex(field: "password", pattern: ".*[A-Z].*", message: "Need uppercase")
        ])

        let result = combined.validate("")
        #expect(result.isInvalid)
        #expect(result.error?.type == .required)
    }

    @Test func combineRulesMiddleFails() {
        let combined = ValidationRule.combine([
            .required(field: "password"),
            .minLength(field: "password", length: 8),
            .regex(field: "password", pattern: ".*[A-Z].*", message: "Need uppercase")
        ])

        let result = combined.validate("short")
        #expect(result.isInvalid)
        #expect(result.error?.type == .tooShort)
    }

    @Test func combineRulesLastFails() {
        let combined = ValidationRule.combine([
            .required(field: "password"),
            .minLength(field: "password", length: 8),
            .regex(field: "password", pattern: ".*[A-Z].*", message: "Need uppercase")
        ])

        let result = combined.validate("lowercase123")
        #expect(result.isInvalid)
        #expect(result.error?.type == .patternMismatch)
    }

    // MARK: - FormState: Basic Tests

    @Test func formStateInitialization() {
        let formState = FormState()

        #expect(formState.isValid)
        #expect(!formState.hasAnyErrors)
        #expect(!formState.isSubmitting)
        #expect(!formState.hasBeenSubmitted)
        #expect(!formState.showErrors)
    }

    @Test func formStateSetErrors() {
        let formState = FormState()
        let error = ValidationError(
            field: "email",
            type: .invalidFormat,
            message: "Invalid email"
        )

        formState.setError(error, for: "email")

        #expect(!formState.isValid)
        #expect(formState.hasAnyErrors)
        #expect(formState.hasErrors(for: "email"))
        #expect(formState.errors(for: "email").count == 1)
        #expect(formState.firstError(for: "email") == "Invalid email")
    }

    @Test func formStateSetMultipleErrors() {
        let formState = FormState()
        let errors = [
            ValidationError(field: "password", type: .required, message: "Required"),
            ValidationError(field: "password", type: .tooShort, message: "Too short")
        ]

        formState.setErrors(errors, for: "password")

        #expect(!formState.isValid)
        #expect(formState.errors(for: "password").count == 2)
        #expect(formState.firstError(for: "password") == "Required")
    }

    @Test func formStateClearErrors() {
        let formState = FormState()
        let error = ValidationError(field: "email", type: .required, message: "Required")
        formState.setError(error, for: "email")

        #expect(formState.hasErrors(for: "email"))

        formState.clearErrors(for: "email")

        #expect(!formState.hasErrors(for: "email"))
        #expect(formState.isValid)
    }

    @Test func formStateClearAllErrors() {
        let formState = FormState()
        formState.setError(ValidationError(field: "email", type: .required, message: "Required"), for: "email")
        formState.setError(ValidationError(field: "password", type: .required, message: "Required"), for: "password")

        #expect(!formState.isValid)

        formState.clearAllErrors()

        #expect(formState.isValid)
        #expect(!formState.hasErrors(for: "email"))
        #expect(!formState.hasErrors(for: "password"))
    }

    // MARK: - FormState: Validation Tests

    @Test func formStateValidateSuccess() {
        let formState = FormState()
        let rule = ValidationRule.required(field: "name")
        let result = formState.validate("John", with: rule)

        #expect(result.isValid)
        #expect(formState.isValid)
        #expect(!formState.hasErrors(for: "name"))
    }

    @Test func formStateValidateFailure() {
        let formState = FormState()
        let rule = ValidationRule.required(field: "name")
        let result = formState.validate("", with: rule)

        #expect(result.isInvalid)
        #expect(!formState.isValid)
        #expect(formState.hasErrors(for: "name"))
    }

    @Test func formStateValidateMultipleRulesAllPass() {
        let formState = FormState()
        let rules = [
            ValidationRule.required(field: "email"),
            ValidationRule.email(field: "email")
        ]

        let success = formState.validate("user@example.com", with: rules)

        #expect(success)
        #expect(formState.isValid)
        #expect(!formState.hasErrors(for: "email"))
    }

    @Test func formStateValidateMultipleRulesOneFails() {
        let formState = FormState()
        let rules = [
            ValidationRule.required(field: "email"),
            ValidationRule.email(field: "email")
        ]

        let success = formState.validate("notanemail", with: rules)

        #expect(!success)
        #expect(!formState.isValid)
        #expect(formState.hasErrors(for: "email"))
    }

    @Test func formStateValidateMultipleRulesMultipleFail() {
        let formState = FormState()
        let rules = [
            ValidationRule.required(field: "password"),
            ValidationRule.minLength(field: "password", length: 8),
            ValidationRule.regex(field: "password", pattern: ".*[A-Z].*", message: "Need uppercase")
        ]

        let success = formState.validate("abc", with: rules)

        #expect(!success)
        #expect(formState.hasErrors(for: "password"))
        // Should collect all errors
        #expect(formState.errors(for: "password").count > 0)
    }

    // MARK: - FormState: Field Touch Tracking Tests

    @Test func fieldTouchTracking() {
        let formState = FormState()
        #expect(!formState.isTouched("email"))

        formState.touch("email")

        #expect(formState.isTouched("email"))
    }

    @Test func fieldUntouchTracking() {
        let formState = FormState()
        formState.touch("email")
        #expect(formState.isTouched("email"))

        formState.untouch("email")

        #expect(!formState.isTouched("email"))
    }

    @Test func touchAllFields() {
        let formState = FormState()
        formState.setError(ValidationError(field: "email", type: .required, message: "Required"), for: "email")
        formState.setError(ValidationError(field: "password", type: .required, message: "Required"), for: "password")

        formState.touchAll()

        #expect(formState.isTouched("email"))
        #expect(formState.isTouched("password"))
    }

    @Test func clearTouchedFields() {
        let formState = FormState()
        formState.touch("email")
        formState.touch("password")

        formState.clearTouched()

        #expect(!formState.isTouched("email"))
        #expect(!formState.isTouched("password"))
    }

    @Test func shouldShowErrorsForUntouchedField() {
        let formState = FormState()
        formState.setError(ValidationError(field: "email", type: .required, message: "Required"), for: "email")

        #expect(!formState.shouldShowErrors(for: "email"))
    }

    @Test func shouldShowErrorsForTouchedField() {
        let formState = FormState()
        formState.setError(ValidationError(field: "email", type: .required, message: "Required"), for: "email")
        formState.touch("email")

        #expect(formState.shouldShowErrors(for: "email"))
    }

    @Test func shouldShowErrorsAfterSubmission() {
        let formState = FormState()
        formState.setError(ValidationError(field: "email", type: .required, message: "Required"), for: "email")

        // Simulate submission
        formState.showAllErrors()

        #expect(formState.shouldShowErrors(for: "email"))
    }

    // MARK: - FormState: Submission Tests

    @Test func formSubmissionWithValidForm() async {
        let formState = FormState()
        var submitted = false

        formState.submit {
            submitted = true
        }

        // Wait briefly for async task
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms

        #expect(submitted)
        #expect(formState.hasBeenSubmitted)
        #expect(!formState.isSubmitting) // Should be false after completion
    }

    @Test func formSubmissionWithInvalidForm() async {
        let formState = FormState()
        var submitted = false

        formState.setError(ValidationError(field: "email", type: .required, message: "Required"), for: "email")

        formState.submit {
            submitted = true
        }

        // Wait briefly for async task
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms

        #expect(!submitted)
        #expect(formState.hasBeenSubmitted)
        #expect(formState.showErrors)
    }

    @Test func formSubmissionMarksAllFieldsTouched() async {
        let formState = FormState()
        formState.setError(ValidationError(field: "email", type: .required, message: "Required"), for: "email")
        formState.setError(ValidationError(field: "password", type: .required, message: "Required"), for: "password")

        formState.submit {
            // Should not execute
        }

        // Wait briefly for async task
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms

        #expect(formState.isTouched("email"))
        #expect(formState.isTouched("password"))
    }

    // MARK: - FormState: Reset Tests

    @Test func formReset() {
        let formState = FormState()
        // Set up some state
        formState.setError(ValidationError(field: "email", type: .required, message: "Required"), for: "email")
        formState.touch("email")
        formState.showAllErrors()

        formState.reset()

        #expect(formState.isValid)
        #expect(!formState.hasAnyErrors)
        #expect(!formState.isTouched("email"))
        #expect(!formState.hasBeenSubmitted)
        #expect(!formState.showErrors)
        #expect(!formState.isSubmitting)
    }

    // MARK: - Async Validation Tests

    @Test func asyncValidationSuccess() async {
        let formState = FormState()
        let rule = AsyncValidationRule.custom(
            field: "username",
            message: "Username is taken"
        ) { value in
            // Simulate async check
            try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
            return value != "admin"
        }

        formState.validateAsync("john", with: rule)

        // Wait for validation to complete
        try? await Task.sleep(nanoseconds: 50_000_000) // 50ms

        #expect(formState.isValid)
        #expect(!formState.hasErrors(for: "username"))
    }

    @Test func asyncValidationFailure() async {
        let formState = FormState()
        let rule = AsyncValidationRule.custom(
            field: "username",
            message: "Username is taken"
        ) { value in
            // Simulate async check
            try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
            return value != "admin"
        }

        formState.validateAsync("admin", with: rule)

        // Wait for validation to complete
        try? await Task.sleep(nanoseconds: 50_000_000) // 50ms

        #expect(!formState.isValid)
        #expect(formState.hasErrors(for: "username"))
        #expect(formState.firstError(for: "username") == "Username is taken")
    }

    @Test func asyncValidationDebouncing() async {
        let formState = FormState()
        nonisolated(unsafe) var callCount = 0

        let rule = AsyncValidationRule.custom(
            field: "search",
            message: "Invalid search"
        ) { value in
            callCount += 1
            try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
            return true
        }

        // Trigger multiple validations rapidly
        formState.validateAsync("a", with: rule)
        formState.validateAsync("ab", with: rule)
        formState.validateAsync("abc", with: rule)

        // Wait for validations to complete
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms

        // Should have cancelled previous validations
        // Only the last one should complete
        #expect(callCount < 3)
    }

    // MARK: - Multiple Fields Tests

    @Test func multipleFieldValidation() {
        let formState = FormState()
        let emailRule = ValidationRule.email(field: "email")
        let passwordRule = ValidationRule.minLength(field: "password", length: 8)

        formState.validate("user@example.com", with: emailRule)
        formState.validate("password123", with: passwordRule)

        #expect(formState.isValid)
        #expect(!formState.hasErrors(for: "email"))
        #expect(!formState.hasErrors(for: "password"))
    }

    @Test func multipleFieldsWithMixedValidation() {
        let formState = FormState()
        let emailRule = ValidationRule.email(field: "email")
        let passwordRule = ValidationRule.minLength(field: "password", length: 8)

        formState.validate("user@example.com", with: emailRule)
        formState.validate("short", with: passwordRule)

        #expect(!formState.isValid)
        #expect(!formState.hasErrors(for: "email"))
        #expect(formState.hasErrors(for: "password"))
    }

    @Test func batchValidation() {
        let formState = FormState()
        let validations: [String: () -> ValidationResult] = [
            "email": {
                ValidationRule.email(field: "email").validate("user@example.com")
            },
            "password": {
                ValidationRule.minLength(field: "password", length: 8).validate("password123")
            }
        ]

        let isValid = formState.validateAll(validations)

        #expect(isValid)
        #expect(formState.isValid)
    }

    // MARK: - Edge Cases Tests

    @Test func validationWithUnicodeCharacters() {
        let rule = ValidationRule.minLength(field: "name", length: 3)

        #expect(rule.validate("你好世界").isValid)
        #expect(rule.validate("cafe\u{0301}").isValid)
        #expect(rule.validate("\u{1F389}\u{1F38A}\u{1F388}").isValid)
    }

    @Test func validationWithVeryLongString() {
        let longString = String(repeating: "a", count: 10000)
        let rule = ValidationRule.maxLength(field: "text", length: 5000)

        let result = rule.validate(longString)

        #expect(result.isInvalid)
        #expect(result.error?.type == .tooLong)
    }

    @Test func validationWithSpecialCharacters() {
        let rule = ValidationRule.email(field: "email")

        #expect(rule.validate("user+tag@example.com").isValid)
        #expect(rule.validate("user.name@example.com").isValid)
        #expect(rule.validate("user_name@example.com").isValid)
    }

    @Test func rangeValidationWithNegativeNumbers() {
        let rule = ValidationRule.range(field: "temperature", min: -100, max: 100)

        #expect(rule.validate("-50").isValid)
        #expect(rule.validate("0").isValid)
        #expect(rule.validate("50").isValid)
        #expect(rule.validate("-101").isInvalid)
    }

    @Test func rangeValidationWithDecimalNumbers() {
        let rule = ValidationRule.range(field: "price", min: 0.01, max: 999.99)

        #expect(rule.validate("0.01").isValid)
        #expect(rule.validate("99.99").isValid)
        #expect(rule.validate("999.99").isValid)
        #expect(rule.validate("0.001").isInvalid)
        #expect(rule.validate("1000.00").isInvalid)
    }

    @Test func emptyFieldValidationAcrossAllRules() {
        // All non-required rules should allow empty strings
        #expect(ValidationRule.email(field: "email").validate("").isValid)
        #expect(ValidationRule.minLength(field: "text", length: 5).validate("").isValid)
        #expect(ValidationRule.maxLength(field: "text", length: 5).validate("").isValid)
        #expect(ValidationRule.regex(field: "code", pattern: "\\d+", message: "").validate("").isValid)
        #expect(ValidationRule.range(field: "age", min: 0, max: 100).validate("").isValid)
    }

    @Test func validationErrorEquality() {
        let error1 = ValidationError(field: "email", type: .required, message: "Required")
        let error2 = ValidationError(field: "email", type: .required, message: "Required")

        // Errors should not be equal due to unique UUID
        #expect(error1.id != error2.id)

        // But field and type should match
        #expect(error1.field == error2.field)
        #expect(error1.type == error2.type)
        #expect(error1.message == error2.message)
    }

    @Test func validationResultIsValid() {
        let success = ValidationResult.success
        let failure = ValidationResult.failure(ValidationError(field: "test", type: .required, message: "Required"))

        #expect(success.isValid)
        #expect(!success.isInvalid)
        #expect(success.error == nil)

        #expect(!failure.isValid)
        #expect(failure.isInvalid)
        #expect(failure.error != nil)
    }

    @Test func formStateShowAndHideErrors() {
        let formState = FormState()
        formState.setError(ValidationError(field: "email", type: .required, message: "Required"), for: "email")

        #expect(!formState.showErrors)

        formState.showAllErrors()

        #expect(formState.showErrors)
        #expect(formState.isTouched("email"))

        formState.hideErrors()

        #expect(!formState.showErrors)
    }

    @Test func formStateValidatorConvenience() {
        let formState = FormState()
        let rules = [ValidationRule.required(field: "name")]
        let validator = formState.validator(for: "name", rules: rules)

        validator("")

        #expect(formState.hasErrors(for: "name"))
    }

    @Test func formStateAsyncValidatorConvenience() async {
        let formState = FormState()
        let rule = AsyncValidationRule.custom(field: "username", message: "Taken") { _ in true }
        let validator = formState.asyncValidator(for: "username", rule: rule)

        validator("test")

        // Wait for validation
        try? await Task.sleep(nanoseconds: 50_000_000) // 50ms

        #expect(!formState.hasErrors(for: "username"))
    }

    // MARK: - ARIA Attributes Tests (Structural)

    @Test func validationModifierStructure() {
        let formState = FormState()
        let modifier = ValidationModifier(
            field: "email",
            rules: [.email(field: "email")],
            formState: formState,
            validateOnChange: true,
            showInlineErrors: true
        )

        #expect(modifier.field == "email")
        #expect(modifier.validateOnChange)
        #expect(modifier.showInlineErrors)
    }

    @Test func asyncValidationModifierStructure() {
        let formState = FormState()
        let rule = AsyncValidationRule.custom(field: "username", message: "Taken") { _ in true }
        let modifier = AsyncValidationModifier(
            field: "username",
            rule: rule,
            formState: formState,
            debounce: 500
        )

        #expect(modifier.field == "username")
        #expect(modifier.debounce == 500)
    }

    @Test func validationARIAModifierStructure() {
        let formState = FormState()
        let modifier = ValidationARIAModifier(
            field: "email",
            formState: formState
        )

        #expect(modifier.field == "email")
    }

    @Test func validationMessageModifierStructure() {
        let formState = FormState()
        let modifier = ValidationMessageModifier(
            field: "email",
            formState: formState,
            style: .default
        )

        #expect(modifier.field == "email")
    }

    @Test func validationMessageStyleDefault() {
        let style = ValidationMessageStyle.default
        #expect(style.color == .red)
    }

    @Test func validationMessageStyleCustom() {
        let style = ValidationMessageStyle.custom(color: .blue)
        #expect(style.color == .blue)
    }
}
