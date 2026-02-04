// import Foundation
// import Raven

// NOTE: These are example code snippets for documentation purposes.
// They demonstrate Phase 14 presentation APIs but are not executable as-is.
// To use these examples, copy them into a proper SwiftUI application with Raven imported.

// MARK: - Confirmation Dialog Examples
//
// This file demonstrates real-world confirmation dialog (action sheet) patterns
// using Raven's confirmationDialog API. These examples show common use cases
// for presenting multiple action choices to users.

// MARK: - Basic Confirmation Dialogs

/// Simple confirmation dialog with two options
struct BasicConfirmationDialogExample: View {
    @State private var showDialog = false
    @State private var selectedAction = "None"

    var body: some View {
        VStack(spacing: 20) {
            Text("Last Action: \(selectedAction)")
                .font(.caption)

            Button("Show Options") {
                showDialog = true
            }
            .buttonStyle(.bordered)
        }
        .confirmationDialog("Choose an Action", isPresented: $showDialog) {
            Button("Action 1") {
                selectedAction = "Action 1"
            }
            Button("Action 2") {
                selectedAction = "Action 2"
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

/// Confirmation dialog with message
struct ConfirmationDialogWithMessageExample: View {
    @State private var showDialog = false

    var body: some View {
        Button("Export Data") {
            showDialog = true
        }
        .confirmationDialog("Export Format", isPresented: $showDialog) {
            Button("PDF") {}
            Button("CSV") {}
            Button("JSON") {}
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Choose the format for your exported data. The export may take a few moments.")
        }
    }
}

// MARK: - File Operations

/// File action confirmation dialog
struct FileActionsExample: View {
    struct File: Identifiable {
        let id = UUID()
        let name: String
        let size: Int
    }

    @State private var selectedFile: File?
    @State private var actionResult = ""

    let files = [
        File(name: "Document.pdf", size: 1024),
        File(name: "Photo.jpg", size: 2048),
        File(name: "Video.mp4", size: 4096)
    ]

    var body: some View {
        VStack(spacing: 16) {
            Text("File Manager")
                .font(.headline)

            if !actionResult.isEmpty {
                Text(actionResult)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            ForEach(files) { file in
                HStack {
                    VStack(alignment: .leading) {
                        Text(file.name)
                        Text("\(file.size) KB")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Button("Actions") {
                        selectedFile = file
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal)
            }
        }
        .confirmationDialog("File Actions", item: $selectedFile) { file in
            Button("Open") {
                actionResult = "Opened \(file.name)"
            }
            Button("Share") {
                actionResult = "Shared \(file.name)"
            }
            Button("Rename") {
                actionResult = "Renamed \(file.name)"
            }
            Button("Delete", role: .destructive) {
                actionResult = "Deleted \(file.name)"
            }
            Button("Cancel", role: .cancel) {}
        } message: { file in
            Text("Choose an action for \(file.name)")
        }
    }
}

/// Delete confirmation with destructive action
struct DeleteConfirmationDialogExample: View {
    @State private var showDeleteDialog = false
    @State private var items = ["Item 1", "Item 2", "Item 3", "Item 4"]

    var body: some View {
        VStack(spacing: 16) {
            Text("Items: \(items.count)")
                .font(.headline)

            List(items, id: \.self) { item in
                Text(item)
            }

            Button("Delete All Items") {
                showDeleteDialog = true
            }
            .buttonStyle(.bordered)
        }
        .confirmationDialog("Delete All?", isPresented: $showDeleteDialog) {
            Button("Delete All", role: .destructive) {
                items.removeAll()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all \(items.count) items. This action cannot be undone.")
        }
    }
}

// MARK: - Sharing and Export

/// Share options dialog
struct ShareOptionsExample: View {
    @State private var showShareDialog = false
    @State private var shareMethod = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("Document Viewer")
                .font(.headline)

            if !shareMethod.isEmpty {
                Text("Shared via: \(shareMethod)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Button("Share Document") {
                showShareDialog = true
            }
            .buttonStyle(.borderedProminent)
        }
        .confirmationDialog("Share", isPresented: $showShareDialog) {
            Button("Email") {
                shareMethod = "Email"
            }
            Button("Message") {
                shareMethod = "Message"
            }
            Button("Copy Link") {
                shareMethod = "Link"
            }
            Button("More...") {
                shareMethod = "System Share Sheet"
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Choose how you'd like to share this document")
        }
    }
}

/// Export with format selection
struct ExportFormatExample: View {
    @State private var showExportDialog = false
    @State private var exportFormat = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("Spreadsheet Editor")
                .font(.headline)

            if !exportFormat.isEmpty {
                Text("Exported as: \(exportFormat)")
                    .font(.caption)
                    .foregroundColor(.green)
            }

            Button("Export") {
                showExportDialog = true
            }
            .buttonStyle(.bordered)
        }
        .confirmationDialog("Export Format", isPresented: $showExportDialog) {
            Button("Excel (.xlsx)") {
                exportFormat = "Excel"
            }
            Button("CSV (.csv)") {
                exportFormat = "CSV"
            }
            Button("PDF (.pdf)") {
                exportFormat = "PDF"
            }
            Button("Numbers") {
                exportFormat = "Numbers"
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Select the format for your export")
        }
    }
}

// MARK: - Sorting and Filtering

/// Sort options dialog
struct SortOptionsExample: View {
    enum SortOrder: String {
        case nameAsc = "Name (A-Z)"
        case nameDesc = "Name (Z-A)"
        case dateNew = "Newest First"
        case dateOld = "Oldest First"
        case size = "Size"
    }

    @State private var showSortDialog = false
    @State private var currentSort: SortOrder = .nameAsc

    var body: some View {
        VStack(spacing: 20) {
            Text("Current Sort: \(currentSort.rawValue)")
                .font(.caption)

            Button("Sort By") {
                showSortDialog = true
            }
            .buttonStyle(.bordered)
        }
        .confirmationDialog("Sort By", isPresented: $showSortDialog) {
            Button("Name (A-Z)") {
                currentSort = .nameAsc
            }
            Button("Name (Z-A)") {
                currentSort = .nameDesc
            }
            Button("Newest First") {
                currentSort = .dateNew
            }
            Button("Oldest First") {
                currentSort = .dateOld
            }
            Button("Size") {
                currentSort = .size
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Choose how to sort items")
        }
    }
}

/// Filter options dialog
struct FilterOptionsExample: View {
    struct FilterOption: Identifiable {
        let id = UUID()
        let name: String
        let count: Int
    }

    @State private var showFilterDialog = false
    @State private var activeFilter = "All"

    let filters = [
        FilterOption(name: "All", count: 42),
        FilterOption(name: "Active", count: 28),
        FilterOption(name: "Completed", count: 14),
        FilterOption(name: "Archived", count: 8)
    ]

    var body: some View {
        VStack(spacing: 20) {
            Text("Showing: \(activeFilter)")
                .font(.headline)

            Button("Filter") {
                showFilterDialog = true
            }
            .buttonStyle(.bordered)
        }
        .confirmationDialog("Filter Items", isPresented: $showFilterDialog) {
            ForEach(filters) { filter in
                Button("\(filter.name) (\(filter.count))") {
                    activeFilter = filter.name
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Show items by status")
        }
    }
}

// MARK: - Context Menu Style

/// Context menu actions
struct ContextMenuStyleExample: View {
    struct ListItem: Identifiable {
        let id = UUID()
        var text: String
        var isFavorite: Bool = false
    }

    @State private var items = [
        ListItem(text: "Item 1"),
        ListItem(text: "Item 2", isFavorite: true),
        ListItem(text: "Item 3")
    ]
    @State private var selectedItem: ListItem?

    var body: some View {
        VStack(spacing: 16) {
            Text("Long Press Items")
                .font(.headline)

            ForEach(items) { item in
                HStack {
                    Text(item.text)
                    if item.isFavorite {
                        Text("★").foregroundColor(.yellow)
                    }
                    Spacer()
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
                .onLongPressGesture {
                    selectedItem = item
                }
            }
        }
        .padding()
        .confirmationDialog("Actions", item: $selectedItem) { item in
            Button(item.isFavorite ? "Remove Favorite" : "Add to Favorites") {
                if let index = items.firstIndex(where: { $0.id == item.id }) {
                    items[index].isFavorite.toggle()
                }
            }
            Button("Edit") {
                // Edit action
            }
            Button("Duplicate") {
                items.append(ListItem(text: item.text + " (Copy)"))
            }
            Button("Delete", role: .destructive) {
                items.removeAll { $0.id == item.id }
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

// MARK: - Account and Settings

/// Account actions dialog
struct AccountActionsExample: View {
    @State private var showAccountDialog = false
    @State private var isLoggedIn = true

    var body: some View {
        VStack(spacing: 20) {
            Text(isLoggedIn ? "Logged In" : "Logged Out")
                .font(.headline)

            Button("Account") {
                showAccountDialog = true
            }
            .buttonStyle(.bordered)
        }
        .confirmationDialog("Account", isPresented: $showAccountDialog) {
            if isLoggedIn {
                Button("View Profile") {}
                Button("Settings") {}
                Button("Log Out") {
                    isLoggedIn = false
                }
            } else {
                Button("Log In") {
                    isLoggedIn = true
                }
                Button("Create Account") {}
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

/// Settings category picker
struct SettingsCategoryExample: View {
    @State private var showCategoryDialog = false
    @State private var currentCategory = "General"

    let categories = ["General", "Privacy", "Notifications", "Appearance", "About"]

    var body: some View {
        VStack(spacing: 20) {
            Text("Settings: \(currentCategory)")
                .font(.headline)

            Button("Change Category") {
                showCategoryDialog = true
            }
            .buttonStyle(.bordered)
        }
        .confirmationDialog("Settings Category", isPresented: $showCategoryDialog) {
            ForEach(categories, id: \.self) { category in
                Button(category) {
                    currentCategory = category
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

// MARK: - Media and Content

/// Photo library actions
struct PhotoActionsExample: View {
    @State private var showPhotoDialog = false
    @State private var actionTaken = ""

    var body: some View {
        VStack(spacing: 20) {
            Rectangle()
                .fill(Color.blue)
                .frame(width: 200, height: 200)
                .cornerRadius(12)
                .overlay(
                    Text("Photo")
                        .foregroundColor(.white)
                )

            if !actionTaken.isEmpty {
                Text(actionTaken)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Button("Photo Actions") {
                showPhotoDialog = true
            }
            .buttonStyle(.bordered)
        }
        .confirmationDialog("Photo", isPresented: $showPhotoDialog) {
            Button("Save to Library") {
                actionTaken = "Saved to library"
            }
            Button("Share") {
                actionTaken = "Opened share sheet"
            }
            Button("Edit") {
                actionTaken = "Opened editor"
            }
            Button("Set as Wallpaper") {
                actionTaken = "Set as wallpaper"
            }
            Button("Delete", role: .destructive) {
                actionTaken = "Deleted photo"
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

/// Video playback options
struct VideoPlaybackExample: View {
    @State private var showPlaybackDialog = false
    @State private var playbackSpeed = "1x"

    var body: some View {
        VStack(spacing: 20) {
            Text("Video Player")
                .font(.headline)

            Text("Speed: \(playbackSpeed)")
                .font(.caption)

            Button("Playback Speed") {
                showPlaybackDialog = true
            }
            .buttonStyle(.bordered)
        }
        .confirmationDialog("Playback Speed", isPresented: $showPlaybackDialog) {
            Button("0.5x") { playbackSpeed = "0.5x" }
            Button("0.75x") { playbackSpeed = "0.75x" }
            Button("1x (Normal)") { playbackSpeed = "1x" }
            Button("1.25x") { playbackSpeed = "1.25x" }
            Button("1.5x") { playbackSpeed = "1.5x" }
            Button("2x") { playbackSpeed = "2x" }
            Button("Cancel", role: .cancel) {}
        }
    }
}

// MARK: - Title Visibility

/// Hidden title confirmation dialog
struct HiddenTitleExample: View {
    @State private var showDialog = false

    var body: some View {
        Button("Quick Actions") {
            showDialog = true
        }
        .confirmationDialog(
            "Actions",
            isPresented: $showDialog,
            titleVisibility: .hidden
        ) {
            Button("Copy") {}
            Button("Paste") {}
            Button("Select All") {}
            Button("Cancel", role: .cancel) {}
        }
    }
}

/// Visible title with Text
struct TextTitleExample: View {
    @State private var showDialog = false

    var body: some View {
        Button("Options") {
            showDialog = true
        }
        .confirmationDialog(
            Text("Choose an Option"),
            isPresented: $showDialog
        ) {
            Button("Option A") {}
            Button("Option B") {}
            Button("Option C") {}
            Button("Cancel", role: .cancel) {}
        }
    }
}

// MARK: - Complex Real-World Example

/// Multi-step workflow with confirmation dialogs
struct WorkflowExample: View {
    enum WorkflowStep {
        case selectSource
        case selectDestination
        case confirm
    }

    @State private var currentStep: WorkflowStep?
    @State private var source = ""
    @State private var destination = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("File Transfer Wizard")
                .font(.headline)

            if !source.isEmpty {
                Text("Source: \(source)")
                    .font(.caption)
            }

            if !destination.isEmpty {
                Text("Destination: \(destination)")
                    .font(.caption)
            }

            Button("Start Transfer") {
                currentStep = .selectSource
            }
            .buttonStyle(.borderedProminent)
        }
        .confirmationDialog("Select Source", isPresented: Binding(
            get: { currentStep == .selectSource },
            set: { if !$0 { currentStep = nil } }
        )) {
            Button("Local Files") {
                source = "Local Files"
                currentStep = .selectDestination
            }
            Button("Cloud Storage") {
                source = "Cloud Storage"
                currentStep = .selectDestination
            }
            Button("Network Drive") {
                source = "Network Drive"
                currentStep = .selectDestination
            }
            Button("Cancel", role: .cancel) {
                currentStep = nil
            }
        }
        .confirmationDialog("Select Destination", isPresented: Binding(
            get: { currentStep == .selectDestination },
            set: { if !$0 { currentStep = nil } }
        )) {
            Button("Desktop") {
                destination = "Desktop"
                currentStep = .confirm
            }
            Button("Documents") {
                destination = "Documents"
                currentStep = .confirm
            }
            Button("Downloads") {
                destination = "Downloads"
                currentStep = .confirm
            }
            Button("Cancel", role: .cancel) {
                currentStep = nil
            }
        }
        .confirmationDialog("Confirm Transfer", isPresented: Binding(
            get: { currentStep == .confirm },
            set: { if !$0 { currentStep = nil } }
        )) {
            Button("Start Transfer") {
                // Perform transfer
                currentStep = nil
            }
            Button("Cancel", role: .cancel) {
                source = ""
                destination = ""
                currentStep = nil
            }
        } message: {
            Text("Transfer from \(source) to \(destination)?")
        }
    }
}
