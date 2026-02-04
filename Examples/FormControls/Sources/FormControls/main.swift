import Foundation
import Raven
import RavenRuntime

/// FormControls Example Application
///
/// This example demonstrates all Phase 8 form controls working together
/// in a realistic user registration/profile form scenario.

// MARK: - Data Model

/// User profile data structure
struct UserProfile: Sendable {
    var email: String = ""
    var password: String = ""
    var confirmPassword: String = ""
    var fullName: String = ""
    var age: Int = 18
    var country: String = "us"
    var experienceLevel: String = "beginner"
    var notificationVolume: Double = 0.7
    var fontSize: Int = 14
    var uploadProgress: Double = 0.0
    var isUploading: Bool = false

    /// Validates the profile data
    var validationErrors: [String] {
        var errors: [String] = []

        if email.isEmpty {
            errors.append("Email is required")
        } else if !email.contains("@") {
            errors.append("Email must be valid")
        }

        if password.isEmpty {
            errors.append("Password is required")
        } else if password.count < 8 {
            errors.append("Password must be at least 8 characters")
        }

        if password != confirmPassword {
            errors.append("Passwords do not match")
        }

        if fullName.isEmpty {
            errors.append("Full name is required")
        }

        return errors
    }

    var isValid: Bool {
        validationErrors.isEmpty
    }

    /// Calculates form completion progress (0.0 to 1.0)
    var completionProgress: Double {
        var completed = 0.0
        let totalFields = 7.0

        if !email.isEmpty { completed += 1 }
        if password.count >= 8 { completed += 1 }
        if !confirmPassword.isEmpty && password == confirmPassword { completed += 1 }
        if !fullName.isEmpty { completed += 1 }
        if age >= 13 { completed += 1 }
        if !country.isEmpty { completed += 1 }
        if !experienceLevel.isEmpty { completed += 1 }

        return completed / totalFields
    }
}

// MARK: - Main Form View

/// The main registration form view
@MainActor
struct RegistrationForm: View {
    @State private var profile = UserProfile()
    @State private var hasSubmitted = false
    @State private var showSuccess = false

    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Text("Create Your Account")
                    .font(.title)

                Text("Join thousands of developers using Raven")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()

            // Form Completion Progress
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Label("Form Completion", systemImage: "chart.bar.fill")
                        .font(.caption)

                    Spacer()

                    Text("\(Int(profile.completionProgress * 100))%")
                        .font(.caption)
                        .foregroundColor(profile.completionProgress == 1.0 ? .green : .blue)
                }

                ProgressView(value: profile.completionProgress, total: 1.0)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)

            // Personal Information Section
            VStack(alignment: .leading, spacing: 16) {
                Label("Personal Information", systemImage: "person.circle")
                    .font(.headline)

                // Full Name
                VStack(alignment: .leading, spacing: 4) {
                    Label("Full Name", systemImage: "person")
                        .font(.caption)
                    TextField("John Doe", text: $profile.fullName)
                }

                // Email
                VStack(alignment: .leading, spacing: 4) {
                    Label("Email Address", systemImage: "envelope")
                        .font(.caption)
                    TextField("you@example.com", text: $profile.email)
                }

                // Age with Stepper
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Label("Age", systemImage: "calendar")
                            .font(.caption)
                        Spacer()
                        Text("\(profile.age) years old")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Stepper(value: $profile.age, in: 13...120)
                }

                // Country Picker
                VStack(alignment: .leading, spacing: 4) {
                    Label("Country", systemImage: "globe")
                        .font(.caption)
                    Picker("Country", selection: $profile.country) {
                        Text("United States").tag("us")
                        Text("United Kingdom").tag("uk")
                        Text("Canada").tag("ca")
                        Text("Germany").tag("de")
                        Text("France").tag("fr")
                        Text("Japan").tag("jp")
                        Text("Australia").tag("au")
                    }
                }
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(8)

            // Security Section
            VStack(alignment: .leading, spacing: 16) {
                Label("Security", systemImage: "lock.shield")
                    .font(.headline)

                // Password
                VStack(alignment: .leading, spacing: 4) {
                    Label("Password", systemImage: "lock")
                        .font(.caption)
                    SecureField("At least 8 characters", text: $profile.password)

                    if !profile.password.isEmpty {
                        HStack(spacing: 4) {
                            Text("Strength:")
                                .font(.caption2)

                            let strength = passwordStrength(profile.password)
                            ProgressView(value: strength, total: 1.0)

                            Text(passwordStrengthLabel(strength))
                                .font(.caption2)
                                .foregroundColor(passwordStrengthColor(strength))
                        }
                    }
                }

                // Confirm Password
                VStack(alignment: .leading, spacing: 4) {
                    Label("Confirm Password", systemImage: "lock.rotation")
                        .font(.caption)
                    SecureField("Re-enter your password", text: $profile.confirmPassword)

                    if !profile.confirmPassword.isEmpty {
                        if profile.password == profile.confirmPassword {
                            Text("Passwords match")
                                .font(.caption2)
                                .foregroundColor(.green)
                        } else {
                            Text("Passwords do not match")
                                .font(.caption2)
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(8)

            // Preferences Section
            VStack(alignment: .leading, spacing: 16) {
                Label("Preferences", systemImage: "slider.horizontal.3")
                    .font(.headline)

                // Experience Level
                VStack(alignment: .leading, spacing: 4) {
                    Label("Experience Level", systemImage: "star")
                        .font(.caption)
                    Picker("Experience", selection: $profile.experienceLevel) {
                        Text("Beginner").tag("beginner")
                        Text("Intermediate").tag("intermediate")
                        Text("Advanced").tag("advanced")
                        Text("Expert").tag("expert")
                    }
                }

                // Notification Volume
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Label("Notification Volume", systemImage: "speaker.wave.2")
                            .font(.caption)
                        Spacer()
                        Text("\(Int(profile.notificationVolume * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $profile.notificationVolume, in: 0...1, step: 0.01)
                }

                // Font Size
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Label("UI Font Size", systemImage: "textformat.size")
                            .font(.caption)
                        Spacer()
                        Text("\(profile.fontSize)pt")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Stepper(value: $profile.fontSize, in: 10...24)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(8)

            // Validation Errors
            if hasSubmitted && !profile.isValid {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Please fix the following errors:", systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundColor(.red)

                    ForEach(profile.validationErrors, id: \.self) { error in
                        HStack {
                            Text("•")
                            Text(error)
                        }
                        .font(.caption2)
                        .foregroundColor(.red)
                    }
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }

            // Success Message
            if showSuccess {
                VStack(spacing: 8) {
                    Label("Account Created Successfully!", systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)

                    Text("Welcome to Raven, \(profile.fullName)!")

                    if profile.isUploading {
                        VStack(spacing: 4) {
                            Text("Uploading profile data...")
                                .font(.caption)
                            ProgressView(value: profile.uploadProgress, total: 1.0)
                        }
                    }
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            }

            // Terms and Submit
            VStack(spacing: 12) {
                HStack {
                    Text("By signing up, you agree to our")
                        .font(.caption2)
                    Link("Terms of Service", destination: URL(string: "https://example.com/terms")!)
                        .font(.caption2)
                    Text("and")
                        .font(.caption2)
                    Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
                        .font(.caption2)
                }
                .foregroundColor(.secondary)

                Button {
                    submitForm()
                } label: {
                    HStack {
                        if profile.isUploading {
                            ProgressView()
                        } else {
                            Label("Create Account", systemImage: "checkmark.circle.fill")
                        }
                    }
                    .padding()
                    .background(profile.isValid ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }

                HStack {
                    Text("Already have an account?")
                        .font(.caption)
                    Link("Sign in", destination: URL(string: "/login")!)
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
        }
        .padding()
    }

    // MARK: - Helper Methods

    @MainActor private func submitForm() {
        hasSubmitted = true

        guard profile.isValid else {
            return
        }

        // Simulate upload progress
        showSuccess = true
        profile.isUploading = true
        profile.uploadProgress = 0.0

        // In a real app, this would be an actual async upload
        // For now, we'll just show the completed state
        profile.uploadProgress = 1.0

        // Simulate completion after a delay would happen here
        // For demonstration purposes, we show immediate completion
    }

    @MainActor private func passwordStrength(_ password: String) -> Double {
        var strength = 0.0

        if password.count >= 8 { strength += 0.25 }
        if password.count >= 12 { strength += 0.25 }
        if password.contains(where: { $0.isUppercase }) { strength += 0.15 }
        if password.contains(where: { $0.isLowercase }) { strength += 0.15 }
        if password.contains(where: { $0.isNumber }) { strength += 0.10 }
        if password.contains(where: { "!@#$%^&*()_+-=[]{}|;:,.<>?".contains($0) }) { strength += 0.10 }

        return min(strength, 1.0)
    }

    @MainActor private func passwordStrengthLabel(_ strength: Double) -> String {
        switch strength {
        case 0..<0.3: return "Weak"
        case 0.3..<0.6: return "Fair"
        case 0.6..<0.8: return "Good"
        case 0.8...1.0: return "Strong"
        default: return "Unknown"
        }
    }

    @MainActor private func passwordStrengthColor(_ strength: Double) -> Color {
        switch strength {
        case 0..<0.3: return .red
        case 0.3..<0.6: return .orange
        case 0.6..<0.8: return .blue
        case 0.8...1.0: return .green
        default: return .gray
        }
    }
}

// MARK: - Entry Point

/// Entry point for the FormControls example
/// In a real WASM environment, this would be called from JavaScript after the DOM is ready

// Example usage (would be called from JavaScript):
// let coordinator = RenderCoordinator()
// await coordinator.render(view: RegistrationForm())
