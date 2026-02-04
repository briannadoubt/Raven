// import Foundation
// import Raven

// NOTE: These are example code snippets for documentation purposes.
// They demonstrate Phase 14 presentation APIs but are not executable as-is.
// To use these examples, copy them into a proper SwiftUI application with Raven imported.

// MARK: - Alert Examples
//
// This file demonstrates real-world alert patterns using Raven's alert API.
// These examples show common use cases for alerts in production applications.

// MARK: - Basic Alerts

/// Simple informational alert
struct BasicAlertExample: View {
    @State private var showAlert = false

    var body: some View {
        VStack(spacing: 20) {
            Button("Show Info Alert") {
                showAlert = true
            }
        }
        .alert("Information", isPresented: $showAlert) {
            Button("OK") {}
        } message: {
            Text("This is an informational message.")
        }
    }
}

/// Error alert with detailed message
struct ErrorAlertExample: View {
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        VStack(spacing: 20) {
            Button("Simulate Error") {
                errorMessage = "Unable to connect to the server. Please check your internet connection and try again."
                showError = true
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
    }
}

// MARK: - Confirmation Alerts

/// Delete confirmation with destructive action
struct DeleteConfirmationExample: View {
    @State private var showDeleteAlert = false
    @State private var itemCount = 5

    var body: some View {
        VStack(spacing: 20) {
            Text("Items: \(itemCount)")
                .font(.headline)

            Button("Delete All") {
                showDeleteAlert = true
            }
            .buttonStyle(.bordered)
        }
        .alert("Delete All Items?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                itemCount = 0
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone. All \(itemCount) items will be permanently deleted.")
        }
    }
}

/// Save changes confirmation
struct SaveChangesAlertExample: View {
    @State private var showSaveAlert = false
    @State private var hasUnsavedChanges = true
    @State private var documentText = "Draft content..."

    var body: some View {
        VStack(spacing: 20) {
            Text("Document Editor")
                .font(.headline)

            Text(hasUnsavedChanges ? "Unsaved Changes" : "Saved")
                .foregroundColor(hasUnsavedChanges ? .orange : .green)
                .font(.caption)

            Button("Close Document") {
                if hasUnsavedChanges {
                    showSaveAlert = true
                }
            }
            .buttonStyle(.bordered)
        }
        .alert("Save Changes?", isPresented: $showSaveAlert) {
            Button("Save") {
                // Save the document
                hasUnsavedChanges = false
            }
            Button("Don't Save", role: .destructive) {
                // Discard changes
                hasUnsavedChanges = false
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Do you want to save the changes you made to this document?")
        }
    }
}

// MARK: - Item-Based Alerts

/// Alert driven by an error item
struct ItemBasedErrorAlertExample: View {
    struct AlertError: Identifiable {
        let id = UUID()
        let title: String
        let message: String
    }

    @State private var currentError: AlertError?

    var body: some View {
        VStack(spacing: 20) {
            Button("Network Error") {
                currentError = AlertError(
                    title: "Network Error",
                    message: "Unable to reach the server."
                )
            }

            Button("Validation Error") {
                currentError = AlertError(
                    title: "Validation Error",
                    message: "Please fill in all required fields."
                )
            }

            Button("Permission Error") {
                currentError = AlertError(
                    title: "Permission Denied",
                    message: "You don't have permission to perform this action."
                )
            }
        }
        .alert(item: $currentError) { error in
            Alert(
                title: Text(error.title),
                message: Text(error.message),
                buttons: [.default(Text("OK"))]
            )
        }
    }
}

/// Alert with dynamic content based on item
struct DynamicItemAlertExample: View {
    struct FileItem: Identifiable {
        let id = UUID()
        let name: String
        let size: Int
        let canDelete: Bool
    }

    @State private var fileToDelete: FileItem?

    let files = [
        FileItem(name: "Document.pdf", size: 1024, canDelete: true),
        FileItem(name: "Photo.jpg", size: 2048, canDelete: true),
        FileItem(name: "System.dat", size: 512, canDelete: false)
    ]

    var body: some View {
        VStack(spacing: 12) {
            Text("Files")
                .font(.headline)

            ForEach(files) { file in
                HStack {
                    VStack(alignment: .leading) {
                        Text(file.name)
                            .font(.body)
                        Text("\(file.size) KB")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Button("Delete") {
                        fileToDelete = file
                    }
                    .buttonStyle(.bordered)
                    .disabled(!file.canDelete)
                }
                .padding(.horizontal)
            }
        }
        .alert(item: $fileToDelete) { file in
            if file.canDelete {
                return Alert(
                    title: Text("Delete \(file.name)?"),
                    message: Text("This file (\(file.size) KB) will be permanently deleted."),
                    buttons: [
                        .destructive(Text("Delete")) {
                            // Perform deletion
                        },
                        .cancel()
                    ]
                )
            } else {
                return Alert(
                    title: Text("Cannot Delete"),
                    message: Text("\(file.name) is a system file and cannot be deleted."),
                    buttons: [.default(Text("OK"))]
                )
            }
        }
    }
}

// MARK: - Multi-Option Alerts

/// Alert with multiple action options
struct MultiOptionAlertExample: View {
    @State private var showOptions = false
    @State private var selectedOption = "None"

    var body: some View {
        VStack(spacing: 20) {
            Text("Selected: \(selectedOption)")
                .font(.headline)

            Button("Choose Option") {
                showOptions = true
            }
            .buttonStyle(.bordered)
        }
        .alert("Select an Action", isPresented: $showOptions) {
            Button("Option A") {
                selectedOption = "Option A"
            }
            Button("Option B") {
                selectedOption = "Option B"
            }
            Button("Option C") {
                selectedOption = "Option C"
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Choose one of the following options:")
        }
    }
}

// MARK: - Form Validation Alerts

/// Input validation alert
struct ValidationAlertExample: View {
    @State private var email = ""
    @State private var password = ""
    @State private var showValidationAlert = false
    @State private var validationMessage = ""

    var body: some View {
        VStack(spacing: 16) {
            Text("Sign Up")
                .font(.title)

            TextField("Email", text: $email)
                .textFieldStyle(.roundedBorder)

            TextField("Password", text: $password)
                .textFieldStyle(.roundedBorder)

            Button("Create Account") {
                if let error = validate() {
                    validationMessage = error
                    showValidationAlert = true
                } else {
                    // Proceed with account creation
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .alert("Validation Error", isPresented: $showValidationAlert) {
            Button("OK") {}
        } message: {
            Text(validationMessage)
        }
    }

    private func validate() -> String? {
        if email.isEmpty {
            return "Email address is required."
        }
        if !email.contains("@") {
            return "Please enter a valid email address."
        }
        if password.isEmpty {
            return "Password is required."
        }
        if password.count < 8 {
            return "Password must be at least 8 characters long."
        }
        return nil
    }
}

// MARK: - Permission Alerts

/// Permission request alert
struct PermissionAlertExample: View {
    @State private var showPermissionAlert = false
    @State private var hasPermission = false

    var body: some View {
        VStack(spacing: 20) {
            Text(hasPermission ? "Permission Granted" : "Permission Not Granted")
                .font(.headline)
                .foregroundColor(hasPermission ? .green : .orange)

            Button("Request Camera Access") {
                showPermissionAlert = true
            }
            .buttonStyle(.bordered)
        }
        .alert("Camera Access Required", isPresented: $showPermissionAlert) {
            Button("Allow") {
                hasPermission = true
            }
            Button("Don't Allow", role: .cancel) {
                hasPermission = false
            }
        } message: {
            Text("This app needs access to your camera to take photos. You can change this in Settings later.")
        }
    }
}

// MARK: - Success/Completion Alerts

/// Success confirmation alert
struct SuccessAlertExample: View {
    @State private var showSuccess = false
    @State private var isProcessing = false

    var body: some View {
        VStack(spacing: 20) {
            if isProcessing {
                Text("Processing...")
                    .foregroundColor(.secondary)
            }

            Button("Submit Form") {
                isProcessing = true
                // Simulate async operation
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    isProcessing = false
                    showSuccess = true
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isProcessing)
        }
        .alert("Success!", isPresented: $showSuccess) {
            Button("OK") {}
        } message: {
            Text("Your form has been submitted successfully.")
        }
    }
}

// MARK: - Network Operation Alerts

/// Network operation with retry
struct NetworkRetryAlertExample: View {
    @State private var showRetryAlert = false
    @State private var attemptCount = 0

    var body: some View {
        VStack(spacing: 20) {
            Text("Attempts: \(attemptCount)")
                .font(.caption)

            Button("Load Data") {
                attemptData()
            }
            .buttonStyle(.bordered)
        }
        .alert("Connection Failed", isPresented: $showRetryAlert) {
            Button("Retry") {
                attemptData()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Unable to connect to the server. Please check your connection and try again.")
        }
    }

    private func attemptData() {
        attemptCount += 1
        // Simulate network failure
        let success = attemptCount > 2
        if !success {
            showRetryAlert = true
        }
    }
}

// MARK: - Destructive Action with Confirmation

/// Permanent deletion with text confirmation
struct PermanentDeleteExample: View {
    @State private var showWarning = false
    @State private var accountExists = true

    var body: some View {
        VStack(spacing: 20) {
            if accountExists {
                Text("Account Active")
                    .font(.headline)

                Button("Delete Account") {
                    showWarning = true
                }
                .buttonStyle(.bordered)
                .foregroundColor(.red)
            } else {
                Text("Account Deleted")
                    .foregroundColor(.secondary)
            }
        }
        .alert("Delete Account Permanently?", isPresented: $showWarning) {
            Button("Delete Account", role: .destructive) {
                accountExists = false
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone. Your account and all associated data will be permanently deleted.")
        }
    }
}

// MARK: - Contextual Alerts

/// Context-aware alert based on state
struct ContextualAlertExample: View {
    enum OperationResult: Identifiable {
        case success(String)
        case failure(String)
        case warning(String)

        var id: String {
            switch self {
            case .success(let msg): return "success-\(msg)"
            case .failure(let msg): return "failure-\(msg)"
            case .warning(let msg): return "warning-\(msg)"
            }
        }
    }

    @State private var result: OperationResult?

    var body: some View {
        VStack(spacing: 20) {
            Button("Successful Operation") {
                result = .success("File saved successfully")
            }

            Button("Failed Operation") {
                result = .failure("Unable to save file")
            }

            Button("Warning Operation") {
                result = .warning("File is read-only")
            }
        }
        .alert(item: $result) { result in
            switch result {
            case .success(let message):
                return Alert(
                    title: Text("Success"),
                    message: Text(message),
                    buttons: [.default(Text("OK"))]
                )
            case .failure(let message):
                return Alert(
                    title: Text("Error"),
                    message: Text(message),
                    buttons: [
                        .default(Text("Retry")),
                        .cancel()
                    ]
                )
            case .warning(let message):
                return Alert(
                    title: Text("Warning"),
                    message: Text(message),
                    buttons: [
                        .default(Text("Continue Anyway")),
                        .cancel()
                    ]
                )
            }
        }
    }
}

// MARK: - Timed Auto-Dismiss Alert

/// Alert that auto-dismisses after a delay
struct TimedAlertExample: View {
    @State private var showTimedAlert = false

    var body: some View {
        Button("Show Timed Alert") {
            showTimedAlert = true
            // Auto-dismiss after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                showTimedAlert = false
            }
        }
        .alert("Auto-Dismiss", isPresented: $showTimedAlert) {
            Button("OK") {}
        } message: {
            Text("This alert will automatically dismiss in 3 seconds.")
        }
    }
}
