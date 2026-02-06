import XCTest
@testable import Raven

/// Comprehensive tests for Form Validation System
/// Tests all ValidationRule types, FormState management, async validation,
/// error display, ARIA attributes, field touch tracking, and edge cases.
@MainActor
final class FormValidationTests: XCTestCase {

    // MARK: - Test Setup

    var formState: FormState!

    override func setUp() async throws {
        formState = FormState()
    }

    override func tearDown() async throws {
        formState = nil
    }

    // MARK: - ValidationRule: Required Tests

    func testRequiredRuleWithEmptyString() {
        let rule = ValidationRule.required(field: "name")
        let result = rule.validate("")

        XCTAssertTrue(result.isInvalid)
        XCTAssertEqual(result.error?.field, "name")
        XCTAssertEqual(result.error?.type, .required)
        XCTAssertEqual(result.error?.message, "This field is required")
    }

    func testRequiredRuleWithWhitespace() {
        let rule = ValidationRule.required(field: "name")
        let result = rule.validate("   \n\t  ")

        XCTAssertTrue(result.isInvalid)
        XCTAssertEqual(result.error?.type, .required)
    }

    func testRequiredRuleWithValidValue() {
        let rule = ValidationRule.required(field: "name")
        let result = rule.validate("John Doe")

        XCTAssertTrue(result.isValid)
        XCTAssertNil(result.error)
    }

    func testRequiredRuleWithCustomMessage() {
        let rule = ValidationRule.required(field: "email", message: "Email is required")
        let result = rule.validate("")

        XCTAssertTrue(result.isInvalid)
        XCTAssertEqual(result.error?.message, "Email is required")
    }

    // MARK: - ValidationRule: Email Tests

    func testEmailRuleWithValidEmail() {
        let rule = ValidationRule.email(field: "email")
        let validEmails = [
            "user@example.com",
            "test.user@domain.co.uk",
            "name+tag@test.org",
            "user123@test-domain.com"
        ]

        for email in validEmails {
            let result = rule.validate(email)
            XCTAssertTrue(result.isValid, "Should accept valid email: \(email)")
        }
    }

    func testEmailRuleWithInvalidEmail() {
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
            XCTAssertTrue(result.isInvalid, "Should reject invalid email: \(email)")
            XCTAssertEqual(result.error?.type, .invalidFormat)
        }
    }

    func testEmailRuleWithEmptyString() {
        let rule = ValidationRule.email(field: "email")
        let result = rule.validate("")

        // Email rule allows empty (use required separately)
        XCTAssertTrue(result.isValid)
    }

    func testEmailRuleWithCustomMessage() {
        let rule = ValidationRule.email(field: "email", message: "Invalid email format")
        let result = rule.validate("notanemail")

        XCTAssertTrue(result.isInvalid)
        XCTAssertEqual(result.error?.message, "Invalid email format")
    }

    // MARK: - ValidationRule: MinLength Tests

    func testMinLengthRuleValid() {
        let rule = ValidationRule.minLength(field: "password", length: 8)
        let result = rule.validate("password123")

        XCTAssertTrue(result.isValid)
    }

    func testMinLengthRuleInvalid() {
        let rule = ValidationRule.minLength(field: "password", length: 8)
        let result = rule.validate("short")

        XCTAssertTrue(result.isInvalid)
        XCTAssertEqual(result.error?.type, .tooShort)
        XCTAssertEqual(result.error?.message, "Must be at least 8 characters")
        XCTAssertEqual(result.error?.context["minLength"], "8")
        XCTAssertEqual(result.error?.context["actualLength"], "5")
    }

    func testMinLengthRuleExactLength() {
        let rule = ValidationRule.minLength(field: "password", length: 8)
        let result = rule.validate("12345678")

        XCTAssertTrue(result.isValid)
    }

    func testMinLengthRuleWithEmptyString() {
        let rule = ValidationRule.minLength(field: "password", length: 8)
        let result = rule.validate("")

        // MinLength allows empty (use required separately)
        XCTAssertTrue(result.isValid)
    }

    // MARK: - ValidationRule: MaxLength Tests

    func testMaxLengthRuleValid() {
        let rule = ValidationRule.maxLength(field: "bio", length: 100)
        let result = rule.validate("Short bio")

        XCTAssertTrue(result.isValid)
    }

    func testMaxLengthRuleInvalid() {
        let rule = ValidationRule.maxLength(field: "bio", length: 10)
        let result = rule.validate("This is a very long biography text")

        XCTAssertTrue(result.isInvalid)
        XCTAssertEqual(result.error?.type, .tooLong)
        XCTAssertEqual(result.error?.message, "Must be at most 10 characters")
        XCTAssertEqual(result.error?.context["maxLength"], "10")
        XCTAssertEqual(result.error?.context["actualLength"], "35")
    }

    func testMaxLengthRuleExactLength() {
        let rule = ValidationRule.maxLength(field: "code", length: 6)
        let result = rule.validate("123456")

        XCTAssertTrue(result.isValid)
    }

    func testMaxLengthRuleWithEmptyString() {
        let rule = ValidationRule.maxLength(field: "bio", length: 100)
        let result = rule.validate("")

        XCTAssertTrue(result.isValid)
    }

    // MARK: - ValidationRule: Regex Tests

    func testRegexRuleValid() {
        let rule = ValidationRule.regex(
            field: "zipcode",
            pattern: "^\\d{5}$",
            message: "Must be 5 digits"
        )
        let result = rule.validate("12345")

        XCTAssertTrue(result.isValid)
    }

    func testRegexRuleInvalid() {
        let rule = ValidationRule.regex(
            field: "zipcode",
            pattern: "^\\d{5}$",
            message: "Must be 5 digits"
        )
        let result = rule.validate("1234")

        XCTAssertTrue(result.isInvalid)
        XCTAssertEqual(result.error?.type, .patternMismatch)
        XCTAssertEqual(result.error?.message, "Must be 5 digits")
    }

    func testRegexRuleComplexPattern() {
        let rule = ValidationRule.regex(
            field: "password",
            pattern: "^(?=.*[A-Z])(?=.*[0-9]).*$",
            message: "Must contain uppercase and number"
        )

        XCTAssertTrue(rule.validate("Password123").isValid)
        XCTAssertTrue(rule.validate("abc123").isInvalid)
        XCTAssertTrue(rule.validate("ABCDEF").isInvalid)
    }

    func testRegexRuleWithEmptyString() {
        let rule = ValidationRule.regex(
            field: "code",
            pattern: "^\\d+$",
            message: "Must be numeric"
        )
        let result = rule.validate("")

        // Regex allows empty (use required separately)
        XCTAssertTrue(result.isValid)
    }

    // MARK: - ValidationRule: Range Tests

    func testRangeRuleWithIntegerValid() {
        let rule = ValidationRule.range(field: "age", min: 18, max: 100)

        XCTAssertTrue(rule.validate("25").isValid)
        XCTAssertTrue(rule.validate("18").isValid)
        XCTAssertTrue(rule.validate("100").isValid)
    }

    func testRangeRuleWithIntegerBelowMin() {
        let rule = ValidationRule.range(field: "age", min: 18, max: 100)
        let result = rule.validate("15")

        XCTAssertTrue(result.isInvalid)
        XCTAssertEqual(result.error?.type, .belowMinimum)
        XCTAssertEqual(result.error?.message, "Must be at least 18")
    }

    func testRangeRuleWithIntegerAboveMax() {
        let rule = ValidationRule.range(field: "age", min: 18, max: 100)
        let result = rule.validate("150")

        XCTAssertTrue(result.isInvalid)
        XCTAssertEqual(result.error?.type, .aboveMaximum)
        XCTAssertEqual(result.error?.message, "Must be at most 100")
    }

    func testRangeRuleWithDoubleValid() {
        let rule = ValidationRule.range(field: "price", min: 0.0, max: 999.99)

        XCTAssertTrue(rule.validate("49.99").isValid)
        XCTAssertTrue(rule.validate("0.0").isValid)
        XCTAssertTrue(rule.validate("999.99").isValid)
    }

    func testRangeRuleWithInvalidNumber() {
        let rule = ValidationRule.range(field: "age", min: 0, max: 100)
        let result = rule.validate("not a number")

        XCTAssertTrue(result.isInvalid)
        XCTAssertEqual(result.error?.type, .invalidFormat)
        XCTAssertEqual(result.error?.message, "Please enter a valid number")
    }

    func testRangeRuleOnlyMinimum() {
        let rule = ValidationRule.range(field: "quantity", min: 1)

        XCTAssertTrue(rule.validate("5").isValid)
        XCTAssertTrue(rule.validate("1").isValid)
        XCTAssertTrue(rule.validate("0").isInvalid)
    }

    func testRangeRuleOnlyMaximum() {
        let rule = ValidationRule.range(field: "discount", max: 100)

        XCTAssertTrue(rule.validate("50").isValid)
        XCTAssertTrue(rule.validate("100").isValid)
        XCTAssertTrue(rule.validate("101").isInvalid)
    }

    func testRangeRuleWithEmptyString() {
        let rule = ValidationRule.range(field: "age", min: 0, max: 100)
        let result = rule.validate("")

        // Range allows empty (use required separately)
        XCTAssertTrue(result.isValid)
    }

    // MARK: - ValidationRule: Custom Tests

    func testCustomRuleValid() {
        let rule = ValidationRule.custom(
            field: "username",
            message: "Username must start with a letter"
        ) { value in
            guard let first = value.first else { return false }
            return first.isLetter
        }

        let result = rule.validate("john123")
        XCTAssertTrue(result.isValid)
    }

    func testCustomRuleInvalid() {
        let rule = ValidationRule.custom(
            field: "username",
            message: "Username must start with a letter"
        ) { value in
            guard let first = value.first else { return false }
            return first.isLetter
        }

        let result = rule.validate("123john")
        XCTAssertTrue(result.isInvalid)
        XCTAssertEqual(result.error?.type, .custom("validation"))
        XCTAssertEqual(result.error?.message, "Username must start with a letter")
    }

    // MARK: - ValidationRule: Combine Tests

    func testCombineRulesAllPass() {
        let combined = ValidationRule.combine([
            .required(field: "password"),
            .minLength(field: "password", length: 8),
            .regex(field: "password", pattern: ".*[A-Z].*", message: "Need uppercase")
        ])

        let result = combined.validate("Password123")
        XCTAssertTrue(result.isValid)
    }

    func testCombineRulesFirstFails() {
        let combined = ValidationRule.combine([
            .required(field: "password"),
            .minLength(field: "password", length: 8),
            .regex(field: "password", pattern: ".*[A-Z].*", message: "Need uppercase")
        ])

        let result = combined.validate("")
        XCTAssertTrue(result.isInvalid)
        XCTAssertEqual(result.error?.type, .required)
    }

    func testCombineRulesMiddleFails() {
        let combined = ValidationRule.combine([
            .required(field: "password"),
            .minLength(field: "password", length: 8),
            .regex(field: "password", pattern: ".*[A-Z].*", message: "Need uppercase")
        ])

        let result = combined.validate("short")
        XCTAssertTrue(result.isInvalid)
        XCTAssertEqual(result.error?.type, .tooShort)
    }

    func testCombineRulesLastFails() {
        let combined = ValidationRule.combine([
            .required(field: "password"),
            .minLength(field: "password", length: 8),
            .regex(field: "password", pattern: ".*[A-Z].*", message: "Need uppercase")
        ])

        let result = combined.validate("lowercase123")
        XCTAssertTrue(result.isInvalid)
        XCTAssertEqual(result.error?.type, .patternMismatch)
    }

    // MARK: - FormState: Basic Tests

    func testFormStateInitialization() {
        XCTAssertTrue(formState.isValid)
        XCTAssertFalse(formState.hasAnyErrors)
        XCTAssertFalse(formState.isSubmitting)
        XCTAssertFalse(formState.hasBeenSubmitted)
        XCTAssertFalse(formState.showErrors)
    }

    func testFormStateSetErrors() {
        let error = ValidationError(
            field: "email",
            type: .invalidFormat,
            message: "Invalid email"
        )

        formState.setError(error, for: "email")

        XCTAssertFalse(formState.isValid)
        XCTAssertTrue(formState.hasAnyErrors)
        XCTAssertTrue(formState.hasErrors(for: "email"))
        XCTAssertEqual(formState.errors(for: "email").count, 1)
        XCTAssertEqual(formState.firstError(for: "email"), "Invalid email")
    }

    func testFormStateSetMultipleErrors() {
        let errors = [
            ValidationError(field: "password", type: .required, message: "Required"),
            ValidationError(field: "password", type: .tooShort, message: "Too short")
        ]

        formState.setErrors(errors, for: "password")

        XCTAssertFalse(formState.isValid)
        XCTAssertEqual(formState.errors(for: "password").count, 2)
        XCTAssertEqual(formState.firstError(for: "password"), "Required")
    }

    func testFormStateClearErrors() {
        let error = ValidationError(field: "email", type: .required, message: "Required")
        formState.setError(error, for: "email")

        XCTAssertTrue(formState.hasErrors(for: "email"))

        formState.clearErrors(for: "email")

        XCTAssertFalse(formState.hasErrors(for: "email"))
        XCTAssertTrue(formState.isValid)
    }

    func testFormStateClearAllErrors() {
        formState.setError(ValidationError(field: "email", type: .required, message: "Required"), for: "email")
        formState.setError(ValidationError(field: "password", type: .required, message: "Required"), for: "password")

        XCTAssertFalse(formState.isValid)

        formState.clearAllErrors()

        XCTAssertTrue(formState.isValid)
        XCTAssertFalse(formState.hasErrors(for: "email"))
        XCTAssertFalse(formState.hasErrors(for: "password"))
    }

    // MARK: - FormState: Validation Tests

    func testFormStateValidateSuccess() {
        let rule = ValidationRule.required(field: "name")
        let result = formState.validate("John", with: rule)

        XCTAssertTrue(result.isValid)
        XCTAssertTrue(formState.isValid)
        XCTAssertFalse(formState.hasErrors(for: "name"))
    }

    func testFormStateValidateFailure() {
        let rule = ValidationRule.required(field: "name")
        let result = formState.validate("", with: rule)

        XCTAssertTrue(result.isInvalid)
        XCTAssertFalse(formState.isValid)
        XCTAssertTrue(formState.hasErrors(for: "name"))
    }

    func testFormStateValidateMultipleRulesAllPass() {
        let rules = [
            ValidationRule.required(field: "email"),
            ValidationRule.email(field: "email")
        ]

        let success = formState.validate("user@example.com", with: rules)

        XCTAssertTrue(success)
        XCTAssertTrue(formState.isValid)
        XCTAssertFalse(formState.hasErrors(for: "email"))
    }

    func testFormStateValidateMultipleRulesOneFails() {
        let rules = [
            ValidationRule.required(field: "email"),
            ValidationRule.email(field: "email")
        ]

        let success = formState.validate("notanemail", with: rules)

        XCTAssertFalse(success)
        XCTAssertFalse(formState.isValid)
        XCTAssertTrue(formState.hasErrors(for: "email"))
    }

    func testFormStateValidateMultipleRulesMultipleFail() {
        let rules = [
            ValidationRule.required(field: "password"),
            ValidationRule.minLength(field: "password", length: 8),
            ValidationRule.regex(field: "password", pattern: ".*[A-Z].*", message: "Need uppercase")
        ]

        let success = formState.validate("abc", with: rules)

        XCTAssertFalse(success)
        XCTAssertTrue(formState.hasErrors(for: "password"))
        // Should collect all errors
        XCTAssertGreaterThan(formState.errors(for: "password").count, 0)
    }

    // MARK: - FormState: Field Touch Tracking Tests

    func testFieldTouchTracking() {
        XCTAssertFalse(formState.isTouched("email"))

        formState.touch("email")

        XCTAssertTrue(formState.isTouched("email"))
    }

    func testFieldUntouchTracking() {
        formState.touch("email")
        XCTAssertTrue(formState.isTouched("email"))

        formState.untouch("email")

        XCTAssertFalse(formState.isTouched("email"))
    }

    func testTouchAllFields() {
        formState.setError(ValidationError(field: "email", type: .required, message: "Required"), for: "email")
        formState.setError(ValidationError(field: "password", type: .required, message: "Required"), for: "password")

        formState.touchAll()

        XCTAssertTrue(formState.isTouched("email"))
        XCTAssertTrue(formState.isTouched("password"))
    }

    func testClearTouchedFields() {
        formState.touch("email")
        formState.touch("password")

        formState.clearTouched()

        XCTAssertFalse(formState.isTouched("email"))
        XCTAssertFalse(formState.isTouched("password"))
    }

    func testShouldShowErrorsForUntouchedField() {
        formState.setError(ValidationError(field: "email", type: .required, message: "Required"), for: "email")

        XCTAssertFalse(formState.shouldShowErrors(for: "email"))
    }

    func testShouldShowErrorsForTouchedField() {
        formState.setError(ValidationError(field: "email", type: .required, message: "Required"), for: "email")
        formState.touch("email")

        XCTAssertTrue(formState.shouldShowErrors(for: "email"))
    }

    func testShouldShowErrorsAfterSubmission() {
        formState.setError(ValidationError(field: "email", type: .required, message: "Required"), for: "email")

        // Simulate submission
        formState.showAllErrors()

        XCTAssertTrue(formState.shouldShowErrors(for: "email"))
    }

    // MARK: - FormState: Submission Tests

    func testFormSubmissionWithValidForm() async {
        var submitted = false

        formState.submit {
            submitted = true
        }

        // Wait briefly for async task
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms

        XCTAssertTrue(submitted)
        XCTAssertTrue(formState.hasBeenSubmitted)
        XCTAssertFalse(formState.isSubmitting) // Should be false after completion
    }

    func testFormSubmissionWithInvalidForm() async {
        var submitted = false

        formState.setError(ValidationError(field: "email", type: .required, message: "Required"), for: "email")

        formState.submit {
            submitted = true
        }

        // Wait briefly for async task
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms

        XCTAssertFalse(submitted)
        XCTAssertTrue(formState.hasBeenSubmitted)
        XCTAssertTrue(formState.showErrors)
    }

    func testFormSubmissionMarksAllFieldsTouched() async {
        formState.setError(ValidationError(field: "email", type: .required, message: "Required"), for: "email")
        formState.setError(ValidationError(field: "password", type: .required, message: "Required"), for: "password")

        formState.submit {
            // Should not execute
        }

        // Wait briefly for async task
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms

        XCTAssertTrue(formState.isTouched("email"))
        XCTAssertTrue(formState.isTouched("password"))
    }

    // MARK: - FormState: Reset Tests

    func testFormReset() {
        // Set up some state
        formState.setError(ValidationError(field: "email", type: .required, message: "Required"), for: "email")
        formState.touch("email")
        formState.showAllErrors()

        formState.reset()

        XCTAssertTrue(formState.isValid)
        XCTAssertFalse(formState.hasAnyErrors)
        XCTAssertFalse(formState.isTouched("email"))
        XCTAssertFalse(formState.hasBeenSubmitted)
        XCTAssertFalse(formState.showErrors)
        XCTAssertFalse(formState.isSubmitting)
    }

    // MARK: - Async Validation Tests

    func testAsyncValidationSuccess() async {
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

        XCTAssertTrue(formState.isValid)
        XCTAssertFalse(formState.hasErrors(for: "username"))
    }

    func testAsyncValidationFailure() async {
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

        XCTAssertFalse(formState.isValid)
        XCTAssertTrue(formState.hasErrors(for: "username"))
        XCTAssertEqual(formState.firstError(for: "username"), "Username is taken")
    }

    func testAsyncValidationDebouncing() async {
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
        XCTAssertLessThan(callCount, 3)
    }

    // MARK: - Multiple Fields Tests

    func testMultipleFieldValidation() {
        let emailRule = ValidationRule.email(field: "email")
        let passwordRule = ValidationRule.minLength(field: "password", length: 8)

        formState.validate("user@example.com", with: emailRule)
        formState.validate("password123", with: passwordRule)

        XCTAssertTrue(formState.isValid)
        XCTAssertFalse(formState.hasErrors(for: "email"))
        XCTAssertFalse(formState.hasErrors(for: "password"))
    }

    func testMultipleFieldsWithMixedValidation() {
        let emailRule = ValidationRule.email(field: "email")
        let passwordRule = ValidationRule.minLength(field: "password", length: 8)

        formState.validate("user@example.com", with: emailRule)
        formState.validate("short", with: passwordRule)

        XCTAssertFalse(formState.isValid)
        XCTAssertFalse(formState.hasErrors(for: "email"))
        XCTAssertTrue(formState.hasErrors(for: "password"))
    }

    func testBatchValidation() {
        let validations: [String: () -> ValidationResult] = [
            "email": {
                ValidationRule.email(field: "email").validate("user@example.com")
            },
            "password": {
                ValidationRule.minLength(field: "password", length: 8).validate("password123")
            }
        ]

        let isValid = formState.validateAll(validations)

        XCTAssertTrue(isValid)
        XCTAssertTrue(formState.isValid)
    }

    // MARK: - Edge Cases Tests

    func testValidationWithUnicodeCharacters() {
        let rule = ValidationRule.minLength(field: "name", length: 3)

        XCTAssertTrue(rule.validate("你好世界").isValid)
        XCTAssertTrue(rule.validate("café").isValid)
        XCTAssertTrue(rule.validate("🎉🎊🎈").isValid)
    }

    func testValidationWithVeryLongString() {
        let longString = String(repeating: "a", count: 10000)
        let rule = ValidationRule.maxLength(field: "text", length: 5000)

        let result = rule.validate(longString)

        XCTAssertTrue(result.isInvalid)
        XCTAssertEqual(result.error?.type, .tooLong)
    }

    func testValidationWithSpecialCharacters() {
        let rule = ValidationRule.email(field: "email")

        XCTAssertTrue(rule.validate("user+tag@example.com").isValid)
        XCTAssertTrue(rule.validate("user.name@example.com").isValid)
        XCTAssertTrue(rule.validate("user_name@example.com").isValid)
    }

    func testRangeValidationWithNegativeNumbers() {
        let rule = ValidationRule.range(field: "temperature", min: -100, max: 100)

        XCTAssertTrue(rule.validate("-50").isValid)
        XCTAssertTrue(rule.validate("0").isValid)
        XCTAssertTrue(rule.validate("50").isValid)
        XCTAssertTrue(rule.validate("-101").isInvalid)
    }

    func testRangeValidationWithDecimalNumbers() {
        let rule = ValidationRule.range(field: "price", min: 0.01, max: 999.99)

        XCTAssertTrue(rule.validate("0.01").isValid)
        XCTAssertTrue(rule.validate("99.99").isValid)
        XCTAssertTrue(rule.validate("999.99").isValid)
        XCTAssertTrue(rule.validate("0.001").isInvalid)
        XCTAssertTrue(rule.validate("1000.00").isInvalid)
    }

    func testEmptyFieldValidationAcrossAllRules() {
        // All non-required rules should allow empty strings
        XCTAssertTrue(ValidationRule.email(field: "email").validate("").isValid)
        XCTAssertTrue(ValidationRule.minLength(field: "text", length: 5).validate("").isValid)
        XCTAssertTrue(ValidationRule.maxLength(field: "text", length: 5).validate("").isValid)
        XCTAssertTrue(ValidationRule.regex(field: "code", pattern: "\\d+", message: "").validate("").isValid)
        XCTAssertTrue(ValidationRule.range(field: "age", min: 0, max: 100).validate("").isValid)
    }

    func testValidationErrorEquality() {
        let error1 = ValidationError(field: "email", type: .required, message: "Required")
        let error2 = ValidationError(field: "email", type: .required, message: "Required")

        // Errors should not be equal due to unique UUID
        XCTAssertNotEqual(error1.id, error2.id)

        // But field and type should match
        XCTAssertEqual(error1.field, error2.field)
        XCTAssertEqual(error1.type, error2.type)
        XCTAssertEqual(error1.message, error2.message)
    }

    func testValidationResultIsValid() {
        let success = ValidationResult.success
        let failure = ValidationResult.failure(ValidationError(field: "test", type: .required, message: "Required"))

        XCTAssertTrue(success.isValid)
        XCTAssertFalse(success.isInvalid)
        XCTAssertNil(success.error)

        XCTAssertFalse(failure.isValid)
        XCTAssertTrue(failure.isInvalid)
        XCTAssertNotNil(failure.error)
    }

    func testFormStateShowAndHideErrors() {
        formState.setError(ValidationError(field: "email", type: .required, message: "Required"), for: "email")

        XCTAssertFalse(formState.showErrors)

        formState.showAllErrors()

        XCTAssertTrue(formState.showErrors)
        XCTAssertTrue(formState.isTouched("email"))

        formState.hideErrors()

        XCTAssertFalse(formState.showErrors)
    }

    func testFormStateValidatorConvenience() {
        let rules = [ValidationRule.required(field: "name")]
        let validator = formState.validator(for: "name", rules: rules)

        validator("")

        XCTAssertTrue(formState.hasErrors(for: "name"))
    }

    func testFormStateAsyncValidatorConvenience() async {
        let rule = AsyncValidationRule.custom(field: "username", message: "Taken") { _ in true }
        let validator = formState.asyncValidator(for: "username", rule: rule)

        validator("test")

        // Wait for validation
        try? await Task.sleep(nanoseconds: 50_000_000) // 50ms

        XCTAssertFalse(formState.hasErrors(for: "username"))
    }

    // MARK: - ARIA Attributes Tests (Structural)

    func testValidationModifierStructure() {
        let modifier = ValidationModifier(
            field: "email",
            rules: [.email(field: "email")],
            formState: formState,
            validateOnChange: true,
            showInlineErrors: true
        )

        XCTAssertEqual(modifier.field, "email")
        XCTAssertTrue(modifier.validateOnChange)
        XCTAssertTrue(modifier.showInlineErrors)
    }

    func testAsyncValidationModifierStructure() {
        let rule = AsyncValidationRule.custom(field: "username", message: "Taken") { _ in true }
        let modifier = AsyncValidationModifier(
            field: "username",
            rule: rule,
            formState: formState,
            debounce: 500
        )

        XCTAssertEqual(modifier.field, "username")
        XCTAssertEqual(modifier.debounce, 500)
    }

    func testValidationARIAModifierStructure() {
        let modifier = ValidationARIAModifier(
            field: "email",
            formState: formState
        )

        XCTAssertEqual(modifier.field, "email")
    }

    func testValidationMessageModifierStructure() {
        let modifier = ValidationMessageModifier(
            field: "email",
            formState: formState,
            style: .default
        )

        XCTAssertEqual(modifier.field, "email")
    }

    func testValidationMessageStyleDefault() {
        let style = ValidationMessageStyle.default
        XCTAssertEqual(style.color, .red)
    }

    func testValidationMessageStyleCustom() {
        let style = ValidationMessageStyle.custom(color: .blue)
        XCTAssertEqual(style.color, .blue)
    }
}
