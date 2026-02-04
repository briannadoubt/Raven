# FormControls Example

A comprehensive example application demonstrating all Phase 8 form controls in Raven working together in a realistic user registration form.

## What This Example Demonstrates

This example showcases a complete user registration form that uses all of the Phase 8 form controls:

### Controls Demonstrated

1. **SecureField** - Password input with visual obscuring
   - Main password field
   - Password confirmation field
   - Real-time password strength indicator

2. **Slider** - Continuous value selection
   - Notification volume control (0-100%)
   - Smooth sliding interaction with percentage display

3. **Stepper** - Discrete value increment/decrement
   - Age selector (13-120 years)
   - Font size adjustment (10-24pt)
   - Visual feedback with current value display

4. **ProgressView** - Loading and progress indication
   - Form completion progress bar (determinate)
   - Password strength indicator (determinate)
   - Upload progress simulation (determinate)
   - Loading spinner during form submission (indeterminate)

5. **Picker** - Selection from multiple options
   - Country selection dropdown
   - Experience level selection
   - Multiple options with readable labels

6. **Link** - Navigation and hyperlinks
   - Terms of Service link (external)
   - Privacy Policy link (external)
   - Sign in link (internal navigation)

7. **Label** - Icon + text combinations
   - Section headers with icons
   - Form field labels with descriptive icons
   - Consistent visual hierarchy

## Features Showcased

### Real-World Form Validation

- Email validation (required, format check)
- Password validation (minimum length, matching confirmation)
- Required field checking
- Real-time validation feedback
- Error message display

### Dynamic Progress Tracking

- Automatic form completion calculation
- Visual progress indicator
- Percentage display
- Color-coded feedback (blue → green when complete)

### Password Security Features

- Password strength calculation
- Visual strength indicator
- Color-coded strength levels (Weak → Strong)
- Password matching validation
- Real-time feedback

### User Experience Patterns

- Grouped form sections (Personal Info, Security, Preferences)
- Visual hierarchy with backgrounds and spacing
- Clear labels with icons for context
- Disabled state handling (submit button)
- Success state with confirmation message
- Simulated upload progress

### Data Binding Examples

- `@State` for local component state
- Two-way data binding with `$` syntax
- Computed properties for derived values
- Reactive UI updates

## Project Structure

```
FormControls/
├── Package.swift           # Swift Package Manager configuration
├── README.md              # This file
└── Sources/
    └── FormControls/
        └── main.swift     # Main application code
```

## Building the Example

### Prerequisites

- Swift 6.2 or later
- Swift toolchain with WASM support (for web deployment)

### Build for WASM

From the `FormControls` directory:

```bash
swift build --triple wasm32-unknown-wasi
```

### Build for Native (Development)

For local testing and development:

```bash
swift build
```

## Code Highlights

### Form Completion Progress

The example includes a sophisticated form completion tracker:

```swift
var completionProgress: Double {
    var completed = 0.0
    let totalFields = 7.0

    if !email.isEmpty { completed += 1 }
    if password.count >= 8 { completed += 1 }
    if !confirmPassword.isEmpty && password == confirmPassword { completed += 1 }
    // ... more fields

    return completed / totalFields
}
```

### Password Strength Indicator

Real-time password strength calculation with visual feedback:

```swift
private func passwordStrength(_ password: String) -> Double {
    var strength = 0.0

    if password.count >= 8 { strength += 0.25 }
    if password.count >= 12 { strength += 0.25 }
    if password.contains(where: { $0.isUppercase }) { strength += 0.15 }
    if password.contains(where: { $0.isLowercase }) { strength += 0.15 }
    if password.contains(where: { $0.isNumber }) { strength += 0.10 }
    // ... special characters check

    return min(strength, 1.0)
}
```

### Validation Logic

Comprehensive validation with helpful error messages:

```swift
var validationErrors: [String] {
    var errors: [String] = []

    if email.isEmpty {
        errors.append("Email is required")
    } else if !email.contains("@") {
        errors.append("Email must be valid")
    }

    if password.count < 8 {
        errors.append("Password must be at least 8 characters")
    }

    if password != confirmPassword {
        errors.append("Passwords do not match")
    }

    return errors
}
```

### Grouped Form Sections

Clean organization with visual grouping:

```swift
VStack(alignment: .leading, spacing: 16) {
    Label("Personal Information", systemImage: "person.circle")
        .font(.headline)

    // Form fields...
}
.padding()
.background(Color.gray.opacity(0.05))
.cornerRadius(8)
```

## Learning Objectives

By studying this example, you'll learn:

1. **Form Control Usage** - How to use each Phase 8 control effectively
2. **Data Validation** - Best practices for form validation
3. **State Management** - Using `@State` and bindings for reactive UIs
4. **User Experience** - Creating intuitive, feedback-rich forms
5. **Code Organization** - Structuring a complex view with helpers
6. **Real-World Patterns** - Common form patterns used in production apps

## Best Practices Demonstrated

- Clear visual hierarchy with sections
- Icon usage for better scannability
- Real-time validation feedback
- Progress indication for long operations
- Accessible form labels
- Responsive layout with max width constraint
- Color-coded feedback (errors, success, warnings)
- Disabled states for async operations

## Extending This Example

Consider adding:

- Profile photo upload with image picker
- Multi-step form wizard with navigation
- Form auto-save to local storage
- Accessibility improvements (ARIA labels)
- Custom error styling
- Animation for state transitions
- Form field focus management

## See Also

- [SecureField Documentation](../../Sources/Raven/Views/Primitives/SecureField.swift)
- [Slider Documentation](../../Sources/Raven/Views/Primitives/Slider.swift)
- [Stepper Documentation](../../Sources/Raven/Views/Primitives/Stepper.swift)
- [ProgressView Documentation](../../Sources/Raven/Views/Primitives/ProgressView.swift)
- [Picker Documentation](../../Sources/Raven/Views/Primitives/Picker.swift)
- [Link Documentation](../../Sources/Raven/Views/Primitives/Link.swift)
- [Label Documentation](../../Sources/Raven/Views/Primitives/Label.swift)

## License

This example is part of the Raven project.
