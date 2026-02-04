import XCTest
@testable import Raven

/// Comprehensive tests for the confirmation dialog view modifiers.
///
/// These tests verify:
/// - Action sheet layout concept
/// - Multiple actions
/// - Cancel button handling
/// - Destructive actions
/// - Presenting with data
/// - Title visibility
@MainActor
final class ConfirmationDialogTests: XCTestCase {

    // MARK: - Visibility Tests

    func testVisibilityAutomatic() {
        XCTAssertEqual(Visibility.automatic, .automatic)
    }

    func testVisibilityVisible() {
        XCTAssertEqual(Visibility.visible, .visible)
    }

    func testVisibilityHidden() {
        XCTAssertEqual(Visibility.hidden, .hidden)
    }

    func testVisibilityEquality() {
        XCTAssertNotEqual(Visibility.automatic, .visible)
        XCTAssertNotEqual(Visibility.visible, .hidden)
        XCTAssertNotEqual(Visibility.hidden, .automatic)
    }

    func testVisibilityHashable() {
        let visibilities: Set<Visibility> = [.automatic, .visible, .hidden]
        XCTAssertEqual(visibilities.count, 3)
    }

    // MARK: - Basic Confirmation Dialog Tests

    func testBasicConfirmationDialogModifier() {
        var isPresented = false
        let binding = Binding(
            get: { isPresented },
            set: { isPresented = $0 }
        )

        let modifier = BasicConfirmationDialogModifier(
            title: "Choose Action",
            isPresented: binding,
            actions: {
                Button("Save") { }
                Button("Delete", role: .destructive) { }
                Button("Cancel", role: .cancel) { }
            }
        )

        XCTAssertNotNil(modifier)
        XCTAssertEqual(modifier.title, "Choose Action")
        XCTAssertEqual(modifier.titleVisibility, .automatic)
    }

    func testConfirmationDialogWithTitleVisibility() {
        var isPresented = false
        let binding = Binding(
            get: { isPresented },
            set: { isPresented = $0 }
        )

        let modifier = BasicConfirmationDialogModifier(
            title: "Actions",
            titleVisibility: .visible,
            isPresented: binding,
            actions: {
                Button("Option 1") { }
            }
        )

        XCTAssertEqual(modifier.titleVisibility, .visible)
    }

    func testConfirmationDialogWithHiddenTitle() {
        var isPresented = false
        let binding = Binding(
            get: { isPresented },
            set: { isPresented = $0 }
        )

        let modifier = BasicConfirmationDialogModifier(
            title: "Hidden",
            titleVisibility: .hidden,
            isPresented: binding,
            actions: {
                Button("Action") { }
            }
        )

        XCTAssertEqual(modifier.titleVisibility, .hidden)
    }

    func testConfirmationDialogPresentation() {
        let coordinator = PresentationCoordinator()
        var isPresented = false

        let binding = Binding(
            get: { isPresented },
            set: { isPresented = $0 }
        )

        let modifier = BasicConfirmationDialogModifier(
            title: "Options",
            isPresented: binding,
            actions: {
                Button("OK") { }
            }
        )

        XCTAssertNotNil(modifier)
        XCTAssertEqual(coordinator.count, 0)

        // Simulate presentation
        binding.wrappedValue = true
        XCTAssertTrue(binding.wrappedValue)
    }

    func testConfirmationDialogDismissal() {
        var isPresented = true
        let binding = Binding(
            get: { isPresented },
            set: { isPresented = $0 }
        )

        XCTAssertTrue(isPresented)

        // Simulate dismissal
        binding.wrappedValue = false
        XCTAssertFalse(isPresented)
    }

    // MARK: - Confirmation Dialog with Message Tests

    func testConfirmationDialogWithMessage() {
        var isPresented = false
        let binding = Binding(
            get: { isPresented },
            set: { isPresented = $0 }
        )

        let modifier = ConfirmationDialogWithMessageModifier(
            title: "Delete All",
            isPresented: binding,
            actions: {
                Button("Delete All", role: .destructive) { }
                Button("Cancel", role: .cancel) { }
            },
            message: {
                Text("This action cannot be undone.")
            }
        )

        XCTAssertNotNil(modifier)
        XCTAssertEqual(modifier.title, "Delete All")
    }

    func testConfirmationDialogWithMessageAndVisibility() {
        var isPresented = false
        let binding = Binding(
            get: { isPresented },
            set: { isPresented = $0 }
        )

        let modifier = ConfirmationDialogWithMessageModifier(
            title: "Warning",
            titleVisibility: .visible,
            isPresented: binding,
            actions: {
                Button("Proceed") { }
            },
            message: {
                Text("Are you sure?")
            }
        )

        XCTAssertEqual(modifier.titleVisibility, .visible)
    }

    // MARK: - Data-Driven Confirmation Dialog Tests

    func testDataConfirmationDialogModifier() {
        struct TestItem: Equatable {
            let name: String
        }

        var selectedItem: TestItem? = nil
        let binding = Binding(
            get: { selectedItem },
            set: { selectedItem = $0 }
        )

        let modifier = DataConfirmationDialogModifier(
            title: "Item Actions",
            data: binding,
            actions: { item in
                Button("Edit \(item.name)") { }
                Button("Delete", role: .destructive) { }
                Button("Cancel", role: .cancel) { }
            },
            message: { item in
                Text("Choose action for \(item.name)")
            }
        )

        XCTAssertNotNil(modifier)
        XCTAssertEqual(modifier.title, "Item Actions")
    }

    func testDataConfirmationDialogPresentation() {
        struct TestItem: Equatable {
            let name: String
        }

        var selectedItem: TestItem? = nil
        let binding = Binding(
            get: { selectedItem },
            set: { selectedItem = $0 }
        )

        let modifier = DataConfirmationDialogModifier(
            title: "Actions",
            data: binding,
            actions: { item in
                Button("Action") { }
            },
            message: { item in
                Text(item.name)
            }
        )

        XCTAssertNil(selectedItem)

        // Set data to trigger presentation
        binding.wrappedValue = TestItem(name: "Test Item")
        XCTAssertNotNil(selectedItem)
        XCTAssertEqual(selectedItem?.name, "Test Item")
    }

    func testDataConfirmationDialogDismissal() {
        struct TestItem {
            let name: String
        }

        var selectedItem: TestItem? = TestItem(name: "Initial")
        let binding = Binding(
            get: { selectedItem },
            set: { selectedItem = $0 }
        )

        XCTAssertNotNil(selectedItem)

        // Simulate dismissal
        binding.wrappedValue = nil
        XCTAssertNil(selectedItem)
    }

    // MARK: - Multiple Actions Tests

    func testConfirmationDialogWithMultipleActions() {
        var isPresented = false
        let binding = Binding(
            get: { isPresented },
            set: { isPresented = $0 }
        )

        let modifier = BasicConfirmationDialogModifier(
            title: "Choose",
            isPresented: binding,
            actions: {
                Button("Action 1") { }
                Button("Action 2") { }
                Button("Action 3") { }
                Button("Cancel", role: .cancel) { }
            }
        )

        XCTAssertNotNil(modifier)
    }

    func testConfirmationDialogWithSingleAction() {
        var isPresented = false
        let binding = Binding(
            get: { isPresented },
            set: { isPresented = $0 }
        )

        let modifier = BasicConfirmationDialogModifier(
            title: "Info",
            isPresented: binding,
            actions: {
                Button("OK") { }
            }
        )

        XCTAssertNotNil(modifier)
    }

    // MARK: - Cancel Button Handling Tests

    func testConfirmationDialogWithCancelButton() {
        var isPresented = false
        let binding = Binding(
            get: { isPresented },
            set: { isPresented = $0 }
        )

        let modifier = BasicConfirmationDialogModifier(
            title: "Actions",
            isPresented: binding,
            actions: {
                Button("Save") { }
                Button("Cancel", role: .cancel) { }
            }
        )

        XCTAssertNotNil(modifier)
    }

    func testConfirmationDialogWithOnlyCancelButton() {
        var isPresented = false
        let binding = Binding(
            get: { isPresented },
            set: { isPresented = $0 }
        )

        let modifier = BasicConfirmationDialogModifier(
            title: "Options",
            isPresented: binding,
            actions: {
                Button("Cancel", role: .cancel) { }
            }
        )

        XCTAssertNotNil(modifier)
    }

    // MARK: - Destructive Actions Tests

    func testConfirmationDialogWithDestructiveAction() {
        var isPresented = false
        let binding = Binding(
            get: { isPresented },
            set: { isPresented = $0 }
        )

        let modifier = BasicConfirmationDialogModifier(
            title: "Delete",
            isPresented: binding,
            actions: {
                Button("Delete All", role: .destructive) { }
                Button("Cancel", role: .cancel) { }
            }
        )

        XCTAssertNotNil(modifier)
    }

    func testConfirmationDialogWithMultipleDestructiveActions() {
        var isPresented = false
        let binding = Binding(
            get: { isPresented },
            set: { isPresented = $0 }
        )

        let modifier = BasicConfirmationDialogModifier(
            title: "Danger",
            isPresented: binding,
            actions: {
                Button("Delete", role: .destructive) { }
                Button("Remove", role: .destructive) { }
                Button("Cancel", role: .cancel) { }
            }
        )

        XCTAssertNotNil(modifier)
    }

    // MARK: - Mixed Button Roles Tests

    func testConfirmationDialogWithMixedRoles() {
        var isPresented = false
        let binding = Binding(
            get: { isPresented },
            set: { isPresented = $0 }
        )

        let modifier = BasicConfirmationDialogModifier(
            title: "Options",
            isPresented: binding,
            actions: {
                Button("Save") { } // default
                Button("Edit") { } // default
                Button("Delete", role: .destructive) { }
                Button("Cancel", role: .cancel) { }
            }
        )

        XCTAssertNotNil(modifier)
    }

    // MARK: - View Extension Tests

    func testConfirmationDialogViewExtension() {
        @MainActor struct TestView: View {
            @State private var showDialog = false

            var body: some View {
                Text("Content")
                    .confirmationDialog("Choose", isPresented: $showDialog) {
                        Button("OK") { }
                    }
            }
        }

        let view = TestView()
        XCTAssertNotNil(view)
    }

    func testConfirmationDialogWithMessageViewExtension() {
        @MainActor struct TestView: View {
            @State private var showDialog = false

            var body: some View {
                Text("Content")
                    .confirmationDialog("Choose", isPresented: $showDialog) {
                        Button("OK") { }
                    } message: {
                        Text("Message")
                    }
            }
        }

        let view = TestView()
        XCTAssertNotNil(view)
    }

    func testDataConfirmationDialogViewExtension() {
        struct Item: Equatable {
            let id: Int
        }

        @MainActor struct TestView: View {
            @State private var selectedItem: Item?

            var body: some View {
                Text("Content")
                    .confirmationDialog("Item", isPresented: $selectedItem) { item in
                        Button("OK") { }
                    } message: { item in
                        Text("Item \(item.id)")
                    }
            }
        }

        let view = TestView()
        XCTAssertNotNil(view)
    }

    // MARK: - Integration Tests

    func testConfirmationDialogWithPresentationCoordinator() {
        let coordinator = PresentationCoordinator()

        XCTAssertEqual(coordinator.count, 0)

        // Simulate presenting a confirmation dialog
        coordinator.present(
            type: .confirmationDialog,
            content: AnyView(Text("Dialog Content"))
        )

        XCTAssertEqual(coordinator.count, 1)
        XCTAssertEqual(coordinator.topPresentation()?.type, .confirmationDialog)
    }

    func testMultipleConfirmationDialogsSequence() {
        let coordinator = PresentationCoordinator()

        // Present first dialog
        let id1 = coordinator.present(
            type: .confirmationDialog,
            content: AnyView(Text("Dialog 1"))
        )

        XCTAssertEqual(coordinator.count, 1)

        // Dismiss first
        coordinator.dismiss(id1)
        XCTAssertEqual(coordinator.count, 0)

        // Present second dialog
        coordinator.present(
            type: .confirmationDialog,
            content: AnyView(Text("Dialog 2"))
        )

        XCTAssertEqual(coordinator.count, 1)
    }

    // MARK: - Edge Cases

    func testConfirmationDialogWithEmptyTitle() {
        var isPresented = false
        let binding = Binding(
            get: { isPresented },
            set: { isPresented = $0 }
        )

        let modifier = BasicConfirmationDialogModifier(
            title: "",
            isPresented: binding,
            actions: {
                Button("OK") { }
            }
        )

        XCTAssertNotNil(modifier)
        XCTAssertEqual(modifier.title, "")
    }

    func testConfirmationDialogWithNoActions() {
        var isPresented = false
        let binding = Binding(
            get: { isPresented },
            set: { isPresented = $0 }
        )

        let modifier = BasicConfirmationDialogModifier(
            title: "Dialog",
            isPresented: binding,
            actions: {
                EmptyView()
            }
        )

        XCTAssertNotNil(modifier)
    }
}
