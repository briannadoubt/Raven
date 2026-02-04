import Foundation
@testable import Raven

// MARK: - Sheet Examples
//
// This file contains example code demonstrating various sheet usage patterns.
// These examples are for documentation and testing purposes.

/// Example 1: Basic sheet with isPresented binding
///
/// The simplest way to present a sheet is with a Boolean binding.
@MainActor
struct BasicSheetExample: View {
    @State private var showSheet = false

    var body: some View {
        VStack {
            Button("Show Sheet") {
                showSheet = true
            }
        }
        .sheet(isPresented: $showSheet) {
            VStack {
                Text("Sheet Content")
                Button("Dismiss") {
                    showSheet = false
                }
            }
            .padding()
        }
    }
}

/// Example 2: Sheet with onDismiss callback
///
/// Use onDismiss to perform actions when the sheet is dismissed.
@MainActor
struct SheetWithDismissCallbackExample: View {
    @State private var showSheet = false
    @State private var dismissCount = 0

    var body: some View {
        VStack {
            Text("Dismissed \(dismissCount) times")
            Button("Show Sheet") {
                showSheet = true
            }
        }
        .sheet(isPresented: $showSheet, onDismiss: {
            dismissCount += 1
        }) {
            Text("Sheet Content")
        }
    }
}

/// Example 3: Item-based sheet
///
/// Use an optional identifiable item to pass data to the sheet.
@MainActor
struct ItemBasedSheetExample: View {
    struct DetailItem: Identifiable, Sendable, Equatable {
        let id = UUID()
        let title: String
        let description: String
    }

    @State private var selectedItem: DetailItem?

    var body: some View {
        VStack {
            Button("Show Item 1") {
                selectedItem = DetailItem(
                    title: "Item 1",
                    description: "Description for item 1"
                )
            }

            Button("Show Item 2") {
                selectedItem = DetailItem(
                    title: "Item 2",
                    description: "Description for item 2"
                )
            }
        }
        .sheet(item: $selectedItem) { item in
            VStack {
                Text(item.title)
                    .font(.title)
                Text(item.description)
                Button("Dismiss") {
                    selectedItem = nil
                }
            }
            .padding()
        }
    }
}

/// Example 4: Sheet with presentation detents
///
/// Control the sheet height with presentation detents.
@MainActor
struct SheetWithDetentsExample: View {
    @State private var showSheet = false

    var body: some View {
        Button("Show Sheet") {
            showSheet = true
        }
        .sheet(isPresented: $showSheet) {
            VStack {
                Text("Resizable Sheet")
                Text("Drag to resize")
            }
            .padding()
            .presentationDetents([.medium, .large])
        }
    }
}

/// Example 5: Sheet with custom detents
///
/// Use custom heights and fractions for precise control.
@MainActor
struct CustomDetentsExample: View {
    @State private var showSheet = false

    var body: some View {
        Button("Show Sheet") {
            showSheet = true
        }
        .sheet(isPresented: $showSheet) {
            VStack {
                Text("Custom Sized Sheet")
            }
            .padding()
            .presentationDetents([
                .height(200),
                .fraction(0.6),
                .large
            ])
        }
    }
}

/// Example 6: Sheet with dynamic custom detent
///
/// Use a custom detent with a resolver function.
@MainActor
struct DynamicDetentExample: View {
    @State private var showSheet = false

    var body: some View {
        Button("Show Sheet") {
            showSheet = true
        }
        .sheet(isPresented: $showSheet) {
            VStack {
                Text("Dynamic Sheet")
            }
            .padding()
            .presentationDetents([
                .custom { context in
                    // Use 70% of available height, capped at 500 points
                    min(context.maxDetentValue * 0.7, 500)
                }
            ])
        }
    }
}

/// Example 7: Sheet with interactiveDismissDisabled
///
/// Prevent accidental dismissal when there are unsaved changes.
@MainActor
struct SheetWithUnsavedChangesExample: View {
    @State private var showSheet = false
    @State private var text = ""

    var hasUnsavedChanges: Bool {
        !text.isEmpty
    }

    var body: some View {
        Button("Edit") {
            showSheet = true
        }
        .sheet(isPresented: $showSheet) {
            VStack {
                TextField("Enter text", text: $text)
                Text("Swipe down disabled when text is entered")
            }
            .padding()
            .interactiveDismissDisabled(hasUnsavedChanges)
        }
    }
}

/// Example 8: Nested sheets
///
/// Sheets can be nested within other sheets.
@MainActor
struct NestedSheetsExample: View {
    @State private var showFirstSheet = false
    @State private var showSecondSheet = false

    var body: some View {
        Button("Show First Sheet") {
            showFirstSheet = true
        }
        .sheet(isPresented: $showFirstSheet) {
            VStack {
                Text("First Sheet")
                Button("Show Second Sheet") {
                    showSecondSheet = true
                }
            }
            .padding()
            .sheet(isPresented: $showSecondSheet) {
                VStack {
                    Text("Second Sheet")
                    Button("Dismiss") {
                        showSecondSheet = false
                    }
                }
                .padding()
            }
        }
    }
}

/// Example 9: Full-screen cover
///
/// Use a full-screen cover for immersive experiences.
@MainActor
struct FullScreenCoverExample: View {
    @State private var showCover = false

    var body: some View {
        Button("Show Full-Screen Cover") {
            showCover = true
        }
        .fullScreenCover(isPresented: $showCover) {
            VStack {
                Text("Full-Screen Content")
                Button("Dismiss") {
                    showCover = false
                }
            }
            .padding()
        }
    }
}

/// Example 10: Item-based full-screen cover
///
/// Present a full-screen cover with data from an identifiable item.
@MainActor
struct ItemBasedFullScreenCoverExample: View {
    struct Document: Identifiable, Sendable, Equatable {
        let id = UUID()
        let title: String
        let content: String
    }

    @State private var openDocument: Document?

    var body: some View {
        VStack {
            Button("Open Document 1") {
                openDocument = Document(
                    title: "Document 1",
                    content: "Content of document 1"
                )
            }

            Button("Open Document 2") {
                openDocument = Document(
                    title: "Document 2",
                    content: "Content of document 2"
                )
            }
        }
        .fullScreenCover(item: $openDocument) { doc in
            VStack {
                Text(doc.title)
                    .font(.largeTitle)
                Text(doc.content)
                    .padding()
                Button("Close") {
                    openDocument = nil
                }
            }
            .padding()
        }
    }
}

/// Example 11: Sheet with presentation styling
///
/// Customize the sheet appearance with presentation modifiers.
@MainActor
struct StyledSheetExample: View {
    @State private var showSheet = false

    var body: some View {
        Button("Show Styled Sheet") {
            showSheet = true
        }
        .sheet(isPresented: $showSheet) {
            VStack {
                Text("Styled Sheet")
            }
            .padding()
            .presentationDetents([.medium, .large])
            .presentationCornerRadius(20)
            .presentationDragIndicator(.visible)
        }
    }
}

/// Example 12: Conditional sheet presentation
///
/// Present different sheets based on state.
@MainActor
struct ConditionalSheetExample: View {
    enum SheetType: Identifiable {
        case settings
        case help

        var id: Self { self }
    }

    @State private var activeSheet: SheetType?

    var body: some View {
        VStack {
            Button("Show Settings") {
                activeSheet = .settings
            }

            Button("Show Help") {
                activeSheet = .help
            }
        }
        .sheet(item: Binding(
            get: { activeSheet },
            set: { activeSheet = $0 }
        )) { type in
            switch type {
            case .settings:
                Text("Settings Sheet")
                    .padding()
            case .help:
                Text("Help Sheet")
                    .padding()
            }
        }
    }
}

// Note: These examples demonstrate the API usage but are not executable tests.
// They serve as documentation and can be used as reference implementations.
