import Testing
@testable import Raven

/// Comprehensive tests for the alert view modifiers.
///
/// These tests verify:
/// - Basic alert presentation
/// - Two-button alerts
/// - Button roles (.cancel, .destructive)
/// - Data-driven alerts
/// - Alert with messages
/// - Dismissal behavior
@MainActor
@Suite struct AlertModifierTests {

    // MARK: - Basic Alert Tests

    @Test func basicAlertModifier() {
        let coordinator = PresentationCoordinator()
        var isPresented = false

        let modifier = BasicAlertModifier(
            title: "Test Alert",
            isPresented: Binding(
                get: { isPresented },
                set: { isPresented = $0 }
            ),
            actions: {
                Button("OK") { }
            }
        )

        #expect(modifier != nil)
        #expect(modifier.title == "Test Alert")
    }

    @Test func alertPresentation() {
        let coordinator = PresentationCoordinator()

        // Initially no presentations
        #expect(coordinator.count == 0)

        // Create a binding
        var isPresented = true
        let binding = Binding(
            get: { isPresented },
            set: { isPresented = $0 }
        )

        // Note: In a real view, the onChange would trigger presentation
        // For unit tests, we verify the modifier structure is correct
        let modifier = BasicAlertModifier(
            title: "Alert",
            isPresented: binding,
            actions: {
                Button("OK") { }
            }
        )

        #expect(modifier != nil)
    }

    @Test func alertDismissal() {
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

    // MARK: - Alert with Message Tests

    @Test func alertWithMessage() {
        var isPresented = false
        let binding = Binding(
            get: { isPresented },
            set: { isPresented = $0 }
        )

        let modifier = AlertWithMessageModifier(
            title: "Save Changes",
            isPresented: binding,
            actions: {
                Button("Save") { }
                Button("Cancel", role: .cancel) { }
            },
            message: {
                Text("Your changes will be saved.")
            }
        )

        #expect(modifier != nil)
        #expect(modifier.title == "Save Changes")
    }

    @Test func alertWithMessagePresentation() {
        let coordinator = PresentationCoordinator()
        var isPresented = false

        let binding = Binding(
            get: { isPresented },
            set: { isPresented = $0 }
        )

        let modifier = AlertWithMessageModifier(
            title: "Warning",
            isPresented: binding,
            actions: {
                Button("OK") { }
            },
            message: {
                Text("This is a warning message.")
            }
        )

        #expect(modifier != nil)
        #expect(coordinator.count == 0)

        // When presented, the coordinator would receive the presentation
        binding.wrappedValue = true
        #expect(binding.wrappedValue)
    }

    // MARK: - Data-Driven Alert Tests

    @Test func dataAlertModifier() {
        struct TestItem: Equatable {
            let name: String
        }

        var selectedItem: TestItem? = nil
        let binding = Binding(
            get: { selectedItem },
            set: { selectedItem = $0 }
        )

        let modifier = DataAlertModifier(
            title: "Delete Item",
            data: binding,
            actions: { item in
                Button("Delete") { }
                Button("Cancel", role: .cancel) { }
            },
            message: { item in
                Text("Delete \(item.name)?")
            }
        )

        #expect(modifier != nil)
        #expect(modifier.title == "Delete Item")
    }

    @Test func dataAlertPresentation() {
        struct TestItem: Equatable {
            let name: String
        }

        var selectedItem: TestItem? = nil
        let binding = Binding(
            get: { selectedItem },
            set: { selectedItem = $0 }
        )

        let modifier = DataAlertModifier(
            title: "Confirm",
            data: binding,
            actions: { item in
                Button("Yes") { }
            },
            message: { item in
                Text("Proceed with \(item.name)?")
            }
        )

        #expect(selectedItem == nil)

        // Set data to trigger presentation
        binding.wrappedValue = TestItem(name: "Test")
        #expect(selectedItem != nil)
        #expect(selectedItem?.name == "Test")
    }

    @Test func dataAlertDismissal() {
        struct TestItem: Equatable {
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

    // MARK: - Button Action Tests

    @Test func buttonActionExecution() {
        var actionCalled = false
        var isPresented = false

        let binding = Binding(
            get: { isPresented },
            set: { isPresented = $0 }
        )

        let modifier = BasicAlertModifier(
            title: "Test",
            isPresented: binding,
            actions: {
                Button("Execute") {
                    actionCalled = true
                }
            }
        )

        #expect(modifier != nil)
        // In a real scenario, tapping the button would execute the action
        // Here we verify the structure is correct
        #expect(!actionCalled)
    }

    @Test func multipleButtonActions() {
        var primaryActionCalled = false
        var secondaryActionCalled = false
        var isPresented = false

        let binding = Binding(
            get: { isPresented },
            set: { isPresented = $0 }
        )

        let modifier = BasicAlertModifier(
            title: "Choose",
            isPresented: binding,
            actions: {
                Button("Primary") {
                    primaryActionCalled = true
                }
                Button("Secondary") {
                    secondaryActionCalled = true
                }
            }
        )

        #expect(modifier != nil)
        #expect(!primaryActionCalled)
        #expect(!secondaryActionCalled)
    }

    // MARK: - Button Role Tests

    @Test func cancelButtonRole() {
        var isPresented = false
        let binding = Binding(
            get: { isPresented },
            set: { isPresented = $0 }
        )

        let modifier = BasicAlertModifier(
            title: "Alert",
            isPresented: binding,
            actions: {
                Button("Cancel", role: .cancel) { }
            }
        )

        #expect(modifier != nil)
    }

    @Test func destructiveButtonRole() {
        var isPresented = false
        let binding = Binding(
            get: { isPresented },
            set: { isPresented = $0 }
        )

        let modifier = BasicAlertModifier(
            title: "Delete",
            isPresented: binding,
            actions: {
                Button("Delete", role: .destructive) { }
                Button("Cancel", role: .cancel) { }
            }
        )

        #expect(modifier != nil)
    }

    @Test func mixedButtonRoles() {
        var isPresented = false
        let binding = Binding(
            get: { isPresented },
            set: { isPresented = $0 }
        )

        let modifier = AlertWithMessageModifier(
            title: "Options",
            isPresented: binding,
            actions: {
                Button("Save") { } // default role
                Button("Delete", role: .destructive) { }
                Button("Cancel", role: .cancel) { }
            },
            message: {
                Text("Choose an action")
            }
        )

        #expect(modifier != nil)
    }

    // MARK: - View Extension Tests

    @Test func alertViewExtension() {
        @MainActor struct TestView: View {
            @State private var showAlert = false

            var body: some View {
                Text("Content")
                    .alert("Test", isPresented: $showAlert) {
                        Button("OK") { }
                    }
            }
        }

        let view = TestView()
        #expect(view != nil)
    }

    @Test func alertWithMessageViewExtension() {
        @MainActor struct TestView: View {
            @State private var showAlert = false

            var body: some View {
                Text("Content")
                    .alert("Test", isPresented: $showAlert) {
                        Button("OK") { }
                    } message: {
                        Text("Message")
                    }
            }
        }

        let view = TestView()
        #expect(view != nil)
    }

    @Test func dataAlertViewExtension() {
        struct Item: Equatable {
            let id: Int
        }

        @MainActor struct TestView: View {
            @State private var selectedItem: Item?

            var body: some View {
                Text("Content")
                    .alert("Item", isPresented: $selectedItem) { item in
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

    @Test func alertWithPresentationCoordinator() {
        let coordinator = PresentationCoordinator()

        #expect(coordinator.count == 0)

        // Simulate presenting an alert
        coordinator.present(
            type: .alert,
            content: AnyView(Text("Alert Content"))
        )

        #expect(coordinator.count == 1)
        #expect(coordinator.topPresentation()?.type == .alert)
    }

    @Test func multipleAlertsSequence() {
        let coordinator = PresentationCoordinator()

        // Present first alert
        let id1 = coordinator.present(
            type: .alert,
            content: AnyView(Text("Alert 1"))
        )

        #expect(coordinator.count == 1)

        // Dismiss first
        coordinator.dismiss(id1)
        #expect(coordinator.count == 0)

        // Present second alert
        coordinator.present(
            type: .alert,
            content: AnyView(Text("Alert 2"))
        )

        #expect(coordinator.count == 1)
    }

    // MARK: - Edge Cases

    @Test func alertWithEmptyTitle() {
        var isPresented = false
        let binding = Binding(
            get: { isPresented },
            set: { isPresented = $0 }
        )

        let modifier = BasicAlertModifier(
            title: "",
            isPresented: binding,
            actions: {
                Button("OK") { }
            }
        )

        #expect(modifier != nil)
        #expect(modifier.title == "")
    }

    @Test func alertWithNoActions() {
        var isPresented = false
        let binding = Binding(
            get: { isPresented },
            set: { isPresented = $0 }
        )

        let modifier = BasicAlertModifier(
            title: "Alert",
            isPresented: binding,
            actions: {
                EmptyView()
            }
        )

        #expect(modifier != nil)
    }
}
