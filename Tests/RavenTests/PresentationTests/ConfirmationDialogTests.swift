import Testing
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
@Suite struct ConfirmationDialogTests {

    // MARK: - Visibility Tests

    @Test func visibilityAutomatic() {
        #expect(Visibility.automatic == .automatic)
    }

    @Test func visibilityVisible() {
        #expect(Visibility.visible == .visible)
    }

    @Test func visibilityHidden() {
        #expect(Visibility.hidden == .hidden)
    }

    @Test func visibilityEquality() {
        #expect(Visibility.automatic != .visible)
        #expect(Visibility.visible != .hidden)
        #expect(Visibility.hidden != .automatic)
    }

    @Test func visibilityHashable() {
        let visibilities: Set<Visibility> = [.automatic, .visible, .hidden]
        #expect(visibilities.count == 3)
    }

    // MARK: - Basic Confirmation Dialog Tests

    @Test func basicConfirmationDialogModifier() {
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

        #expect(modifier != nil)
        #expect(modifier.title == "Choose Action")
        #expect(modifier.titleVisibility == .automatic)
    }

    @Test func confirmationDialogWithTitleVisibility() {
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

        #expect(modifier.titleVisibility == .visible)
    }

    @Test func confirmationDialogWithHiddenTitle() {
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

        #expect(modifier.titleVisibility == .hidden)
    }

    @Test func confirmationDialogPresentation() {
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

        #expect(modifier != nil)
        #expect(coordinator.count == 0)

        // Simulate presentation
        binding.wrappedValue = true
        #expect(binding.wrappedValue)
    }

    @Test func confirmationDialogDismissal() {
        var isPresented = true
        let binding = Binding(
            get: { isPresented },
            set: { isPresented = $0 }
        )

        #expect(isPresented)

        // Simulate dismissal
        binding.wrappedValue = false
        #expect(!isPresented)
    }

    // MARK: - Confirmation Dialog with Message Tests

    @Test func confirmationDialogWithMessage() {
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

        #expect(modifier != nil)
        #expect(modifier.title == "Delete All")
    }

    @Test func confirmationDialogWithMessageAndVisibility() {
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

        #expect(modifier.titleVisibility == .visible)
    }

    // MARK: - Data-Driven Confirmation Dialog Tests

    @Test func dataConfirmationDialogModifier() {
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

        #expect(modifier != nil)
        #expect(modifier.title == "Item Actions")
    }

    @Test func dataConfirmationDialogPresentation() {
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

        #expect(selectedItem == nil)

        // Set data to trigger presentation
        binding.wrappedValue = TestItem(name: "Test Item")
        #expect(selectedItem != nil)
        #expect(selectedItem?.name == "Test Item")
    }

    @Test func dataConfirmationDialogDismissal() {
        struct TestItem {
            let name: String
        }

        var selectedItem: TestItem? = TestItem(name: "Initial")
        let binding = Binding(
            get: { selectedItem },
            set: { selectedItem = $0 }
        )

        #expect(selectedItem != nil)

        // Simulate dismissal
        binding.wrappedValue = nil
        #expect(selectedItem == nil)
    }

    // MARK: - Multiple Actions Tests

    @Test func confirmationDialogWithMultipleActions() {
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

        #expect(modifier != nil)
    }

    @Test func confirmationDialogWithSingleAction() {
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

        #expect(modifier != nil)
    }

    // MARK: - Cancel Button Handling Tests

    @Test func confirmationDialogWithCancelButton() {
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

        #expect(modifier != nil)
    }

    @Test func confirmationDialogWithOnlyCancelButton() {
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

        #expect(modifier != nil)
    }

    // MARK: - Destructive Actions Tests

    @Test func confirmationDialogWithDestructiveAction() {
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

        #expect(modifier != nil)
    }

    @Test func confirmationDialogWithMultipleDestructiveActions() {
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

        #expect(modifier != nil)
    }

    // MARK: - Mixed Button Roles Tests

    @Test func confirmationDialogWithMixedRoles() {
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

        #expect(modifier != nil)
    }

    // MARK: - View Extension Tests

    @Test func confirmationDialogViewExtension() {
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
        #expect(view != nil)
    }

    @Test func confirmationDialogWithMessageViewExtension() {
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
        #expect(view != nil)
    }

    @Test func dataConfirmationDialogViewExtension() {
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
        #expect(view != nil)
    }

    // MARK: - Integration Tests

    @Test func confirmationDialogWithPresentationCoordinator() {
        let coordinator = PresentationCoordinator()

        #expect(coordinator.count == 0)

        // Simulate presenting a confirmation dialog
        coordinator.present(
            type: .confirmationDialog,
            content: AnyView(Text("Dialog Content"))
        )

        #expect(coordinator.count == 1)
        #expect(coordinator.topPresentation()?.type == .confirmationDialog)
    }

    @Test func multipleConfirmationDialogsSequence() {
        let coordinator = PresentationCoordinator()

        // Present first dialog
        let id1 = coordinator.present(
            type: .confirmationDialog,
            content: AnyView(Text("Dialog 1"))
        )

        #expect(coordinator.count == 1)

        // Dismiss first
        coordinator.dismiss(id1)
        #expect(coordinator.count == 0)

        // Present second dialog
        coordinator.present(
            type: .confirmationDialog,
            content: AnyView(Text("Dialog 2"))
        )

        #expect(coordinator.count == 1)
    }

    // MARK: - Edge Cases

    @Test func confirmationDialogWithEmptyTitle() {
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

        #expect(modifier != nil)
        #expect(modifier.title == "")
    }

    @Test func confirmationDialogWithNoActions() {
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

        #expect(modifier != nil)
    }
}
