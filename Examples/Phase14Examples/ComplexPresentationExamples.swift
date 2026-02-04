// import Foundation
// import Raven

// NOTE: These are example code snippets for documentation purposes.
// They demonstrate Phase 14 presentation APIs but are not executable as-is.
// To use these examples, copy them into a proper SwiftUI application with Raven imported.

// MARK: - Complex Presentation Examples
//
// This file demonstrates advanced presentation patterns including nested
// presentations, multiple simultaneous presentations, and complex workflows
// that combine different presentation types.

// MARK: - Nested Presentations

/// Sheet that can present another sheet
struct NestedSheetsExample: View {
    @State private var showFirstSheet = false
    @State private var showSecondSheet = false
    @State private var showThirdSheet = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Nested Sheets Demo")
                .font(.headline)

            Button("Open First Sheet") {
                showFirstSheet = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .sheet(isPresented: $showFirstSheet) {
            FirstSheetView(showSecondSheet: $showSecondSheet)
                .sheet(isPresented: $showSecondSheet) {
                    SecondSheetView(showThirdSheet: $showThirdSheet)
                        .sheet(isPresented: $showThirdSheet) {
                            ThirdSheetView()
                        }
                }
        }
    }

    struct FirstSheetView: View {
        @Binding var showSecondSheet: Bool

        var body: some View {
            VStack(spacing: 20) {
                Text("First Sheet")
                    .font(.title)

                Text("This is the first level")
                    .foregroundColor(.secondary)

                Button("Open Second Sheet") {
                    showSecondSheet = true
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .presentationDetents([.medium])
        }
    }

    struct SecondSheetView: View {
        @Binding var showThirdSheet: Bool

        var body: some View {
            VStack(spacing: 20) {
                Text("Second Sheet")
                    .font(.title)

                Text("This is the second level")
                    .foregroundColor(.secondary)

                Button("Open Third Sheet") {
                    showThirdSheet = true
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .presentationDetents([.medium])
        }
    }

    struct ThirdSheetView: View {
        var body: some View {
            VStack(spacing: 20) {
                Text("Third Sheet")
                    .font(.title)

                Text("This is the deepest level")
                    .foregroundColor(.secondary)

                Text("✓ Three sheets deep!")
                    .font(.caption)
                    .foregroundColor(.green)
            }
            .padding()
            .presentationDetents([.medium])
        }
    }
}

/// Alert on top of sheet
struct AlertOnSheetExample: View {
    @State private var showSheet = false
    @State private var showAlert = false
    @State private var text = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("Alert on Sheet Demo")
                .font(.headline)

            Button("Open Editor Sheet") {
                showSheet = true
            }
            .buttonStyle(.borderedProminent)
        }
        .sheet(isPresented: $showSheet) {
            VStack(spacing: 20) {
                Text("Editor")
                    .font(.title)

                TextField("Enter text", text: $text)
                    .textFieldStyle(.roundedBorder)

                Button("Save") {
                    if text.isEmpty {
                        showAlert = true
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .alert("Validation Error", isPresented: $showAlert) {
                Button("OK") {}
            } message: {
                Text("Text cannot be empty")
            }
        }
    }
}

/// Popover on sheet
struct PopoverOnSheetExample: View {
    @State private var showSheet = false
    @State private var showPopover = false

    var body: some View {
        Button("Open Settings") {
            showSheet = true
        }
        .sheet(isPresented: $showSheet) {
            VStack(spacing: 20) {
                Text("Settings")
                    .font(.title)

                Button("Show Help") {
                    showPopover = true
                }
                .popover(isPresented: $showPopover) {
                    VStack {
                        Text("Help")
                            .font(.headline)
                        Text("This is contextual help")
                            .font(.caption)
                    }
                    .padding()
                }
            }
            .padding()
            .presentationDetents([.large])
        }
    }
}

/// Confirmation dialog on sheet
struct ConfirmationDialogOnSheetExample: View {
    @State private var showSheet = false
    @State private var showDialog = false
    @State private var items = ["Item 1", "Item 2", "Item 3"]

    var body: some View {
        Button("Manage Items") {
            showSheet = true
        }
        .sheet(isPresented: $showSheet) {
            VStack(spacing: 20) {
                Text("Item Manager")
                    .font(.title)

                List(items, id: \.self) { item in
                    Text(item)
                }

                Button("Clear All") {
                    showDialog = true
                }
                .buttonStyle(.bordered)
            }
            .confirmationDialog("Clear All Items?", isPresented: $showDialog) {
                Button("Clear", role: .destructive) {
                    items.removeAll()
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }
}

// MARK: - Multiple Simultaneous Presentations

/// Multiple sheets controlled by enum
struct MultipleSheetsExample: View {
    enum ActiveSheet: Identifiable {
        case settings
        case profile
        case help

        var id: Self { self }
    }

    @State private var activeSheet: ActiveSheet?

    var body: some View {
        VStack(spacing: 20) {
            Text("Multiple Sheets")
                .font(.headline)

            Button("Settings") {
                activeSheet = .settings
            }
            .buttonStyle(.bordered)

            Button("Profile") {
                activeSheet = .profile
            }
            .buttonStyle(.bordered)

            Button("Help") {
                activeSheet = .help
            }
            .buttonStyle(.bordered)
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .settings:
                SettingsSheetView()
            case .profile:
                ProfileSheetView()
            case .help:
                HelpSheetView()
            }
        }
    }

    struct SettingsSheetView: View {
        var body: some View {
            VStack {
                Text("Settings")
                    .font(.title)
                Text("Configure your preferences")
            }
            .padding()
        }
    }

    struct ProfileSheetView: View {
        var body: some View {
            VStack {
                Text("Profile")
                    .font(.title)
                Text("View and edit your profile")
            }
            .padding()
        }
    }

    struct HelpSheetView: View {
        var body: some View {
            VStack {
                Text("Help")
                    .font(.title)
                Text("Get help and support")
            }
            .padding()
        }
    }
}

/// Multiple alerts for different scenarios
struct MultipleAlertsExample: View {
    @State private var showErrorAlert = false
    @State private var showSuccessAlert = false
    @State private var showWarningAlert = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Multiple Alerts")
                .font(.headline)

            Button("Trigger Error") {
                showErrorAlert = true
            }

            Button("Trigger Success") {
                showSuccessAlert = true
            }

            Button("Trigger Warning") {
                showWarningAlert = true
            }
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK") {}
        } message: {
            Text("An error occurred")
        }
        .alert("Success", isPresented: $showSuccessAlert) {
            Button("OK") {}
        } message: {
            Text("Operation completed successfully")
        }
        .alert("Warning", isPresented: $showWarningAlert) {
            Button("Continue") {}
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action requires caution")
        }
    }
}

// MARK: - Complex Workflows

/// Multi-step form with sheets and alerts
struct FormWorkflowExample: View {
    @State private var showPersonalInfo = false
    @State private var showAddressInfo = false
    @State private var showReview = false
    @State private var showSuccessAlert = false

    @State private var name = ""
    @State private var email = ""
    @State private var address = ""
    @State private var city = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("Registration Form")
                .font(.title)

            Button("Start Registration") {
                showPersonalInfo = true
            }
            .buttonStyle(.borderedProminent)

            if showSuccessAlert {
                Text("Registration Complete!")
                    .foregroundColor(.green)
            }
        }
        .sheet(isPresented: $showPersonalInfo) {
            PersonalInfoSheet(
                name: $name,
                email: $email,
                onNext: {
                    showPersonalInfo = false
                    showAddressInfo = true
                }
            )
        }
        .sheet(isPresented: $showAddressInfo) {
            AddressInfoSheet(
                address: $address,
                city: $city,
                onNext: {
                    showAddressInfo = false
                    showReview = true
                }
            )
        }
        .sheet(isPresented: $showReview) {
            ReviewSheet(
                name: name,
                email: email,
                address: address,
                city: city,
                onSubmit: {
                    showReview = false
                    showSuccessAlert = true
                }
            )
        }
        .alert("Success", isPresented: $showSuccessAlert) {
            Button("OK") {
                // Reset form
                name = ""
                email = ""
                address = ""
                city = ""
            }
        } message: {
            Text("Your registration has been submitted")
        }
    }

    struct PersonalInfoSheet: View {
        @Binding var name: String
        @Binding var email: String
        let onNext: () -> Void

        var body: some View {
            VStack(spacing: 20) {
                Text("Personal Information")
                    .font(.title)

                TextField("Name", text: $name)
                    .textFieldStyle(.roundedBorder)

                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)

                Button("Next") {
                    onNext()
                }
                .buttonStyle(.borderedProminent)
                .disabled(name.isEmpty || email.isEmpty)
            }
            .padding()
        }
    }

    struct AddressInfoSheet: View {
        @Binding var address: String
        @Binding var city: String
        let onNext: () -> Void

        var body: some View {
            VStack(spacing: 20) {
                Text("Address Information")
                    .font(.title)

                TextField("Address", text: $address)
                    .textFieldStyle(.roundedBorder)

                TextField("City", text: $city)
                    .textFieldStyle(.roundedBorder)

                Button("Next") {
                    onNext()
                }
                .buttonStyle(.borderedProminent)
                .disabled(address.isEmpty || city.isEmpty)
            }
            .padding()
        }
    }

    struct ReviewSheet: View {
        let name: String
        let email: String
        let address: String
        let city: String
        let onSubmit: () -> Void

        var body: some View {
            VStack(spacing: 20) {
                Text("Review")
                    .font(.title)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Name: \(name)")
                    Text("Email: \(email)")
                    Text("Address: \(address)")
                    Text("City: \(city)")
                }

                Button("Submit") {
                    onSubmit()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }
}

/// Document editor with multiple presentation types
struct DocumentEditorExample: View {
    @State private var documentText = ""
    @State private var hasUnsavedChanges = false

    @State private var showSaveDialog = false
    @State private var showExportSheet = false
    @State private var showSettingsPopover = false
    @State private var showFindSheet = false

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Button("Save") {
                    if hasUnsavedChanges {
                        showSaveDialog = true
                    }
                }

                Button("Export") {
                    showExportSheet = true
                }

                Button("Find") {
                    showFindSheet = true
                }

                Spacer()

                Button("⚙️") {
                    showSettingsPopover = true
                }
                .popover(isPresented: $showSettingsPopover) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Settings")
                            .font(.headline)

                        Toggle("Auto Save", isOn: .constant(true))
                        Toggle("Spell Check", isOn: .constant(false))
                    }
                    .padding()
                    .frame(width: 200)
                }
            }
            .padding()
            .background(Color.secondary.opacity(0.1))

            // Editor
            TextField("Enter text...", text: $documentText)
                .textFieldStyle(.roundedBorder)
                .padding()
                .onChange(of: documentText) { _, _ in
                    hasUnsavedChanges = true
                }

            if hasUnsavedChanges {
                Text("Unsaved changes")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
        .confirmationDialog("Save Changes?", isPresented: $showSaveDialog) {
            Button("Save") {
                hasUnsavedChanges = false
            }
            Button("Don't Save", role: .destructive) {
                hasUnsavedChanges = false
            }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showExportSheet) {
            ExportSheetView()
        }
        .sheet(isPresented: $showFindSheet) {
            FindSheetView()
        }
    }

    struct ExportSheetView: View {
        @State private var selectedFormat = "PDF"

        var body: some View {
            VStack(spacing: 20) {
                Text("Export Document")
                    .font(.title)

                Picker("Format", selection: $selectedFormat) {
                    Text("PDF").tag("PDF")
                    Text("Word").tag("Word")
                    Text("Text").tag("Text")
                }

                Button("Export") {
                    // Export logic
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }

    struct FindSheetView: View {
        @State private var searchText = ""

        var body: some View {
            VStack(spacing: 20) {
                Text("Find")
                    .font(.title)

                TextField("Search", text: $searchText)
                    .textFieldStyle(.roundedBorder)

                Button("Find Next") {
                    // Search logic
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .presentationDetents([.height(200)])
        }
    }
}

// MARK: - State Management Across Presentations

/// Shared state across nested presentations
struct SharedStateExample: View {
    @StateObject private var sharedData = SharedData()

    var body: some View {
        VStack(spacing: 20) {
            Text("Shared State Demo")
                .font(.headline)

            Text("Counter: \(sharedData.counter)")
                .font(.title)

            Button("Open First Sheet") {
                sharedData.showFirstSheet = true
            }
        }
        .sheet(isPresented: $sharedData.showFirstSheet) {
            FirstSheetView()
                .environmentObject(sharedData)
        }
    }

    @MainActor
    class SharedData: ObservableObject {
        @Published var counter = 0
        @Published var showFirstSheet = false
        @Published var showSecondSheet = false
    }

    struct FirstSheetView: View {
        @EnvironmentObject var sharedData: SharedData

        var body: some View {
            VStack(spacing: 20) {
                Text("First Sheet")
                    .font(.title)

                Text("Counter: \(sharedData.counter)")

                Button("Increment") {
                    sharedData.counter += 1
                }

                Button("Open Second Sheet") {
                    sharedData.showSecondSheet = true
                }
            }
            .sheet(isPresented: $sharedData.showSecondSheet) {
                SecondSheetView()
                    .environmentObject(sharedData)
            }
        }
    }

    struct SecondSheetView: View {
        @EnvironmentObject var sharedData: SharedData

        var body: some View {
            VStack(spacing: 20) {
                Text("Second Sheet")
                    .font(.title)

                Text("Counter: \(sharedData.counter)")

                Button("Increment") {
                    sharedData.counter += 1
                }

                Text("Changes are visible in all sheets")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Presentation with Interactive Dismiss

/// Sheet with conditional dismiss
struct ConditionalDismissExample: View {
    @State private var showSheet = false
    @State private var hasChanges = false
    @State private var text = ""

    var body: some View {
        Button("Edit") {
            showSheet = true
        }
        .sheet(isPresented: $showSheet) {
            VStack(spacing: 20) {
                Text("Editor")
                    .font(.title)

                TextField("Enter text", text: $text)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: text) { _, _ in
                        hasChanges = !text.isEmpty
                    }

                if hasChanges {
                    Text("You have unsaved changes")
                        .font(.caption)
                        .foregroundColor(.orange)

                    Text("Swipe down to dismiss is disabled")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Button("Save & Close") {
                    hasChanges = false
                    showSheet = false
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .interactiveDismissDisabled(hasChanges)
        }
    }
}

// MARK: - Complex Real-World Example

/// Shopping cart checkout flow
struct CheckoutFlowExample: View {
    @State private var cartItems = ["Item 1", "Item 2", "Item 3"]
    @State private var showCheckout = false
    @State private var showPayment = false
    @State private var showConfirmation = false
    @State private var orderComplete = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Shopping Cart")
                .font(.title)

            List(cartItems, id: \.self) { item in
                Text(item)
            }

            Button("Checkout (\(cartItems.count) items)") {
                showCheckout = true
            }
            .buttonStyle(.borderedProminent)
            .disabled(cartItems.isEmpty)
        }
        .sheet(isPresented: $showCheckout) {
            VStack(spacing: 20) {
                Text("Shipping Information")
                    .font(.title)

                // Shipping form would go here

                Button("Continue to Payment") {
                    showCheckout = false
                    showPayment = true
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .sheet(isPresented: $showPayment) {
            VStack(spacing: 20) {
                Text("Payment")
                    .font(.title)

                // Payment form would go here

                Button("Place Order") {
                    showPayment = false
                    showConfirmation = true
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .alert("Confirm Order", isPresented: $showConfirmation) {
                Button("Confirm") {
                    orderComplete = true
                    cartItems.removeAll()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Place order for \(cartItems.count) items?")
            }
        }
        .alert("Order Complete", isPresented: $orderComplete) {
            Button("OK") {}
        } message: {
            Text("Your order has been placed successfully!")
        }
    }
}
