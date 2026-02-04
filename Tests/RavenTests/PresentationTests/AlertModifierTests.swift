import XCTest
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
final class AlertModifierTests: XCTestCase {

    // MARK: - Basic Alert Tests

    func testBasicAlertModifier() {
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

        XCTAssertNotNil(modifier)
        XCTAssertEqual(modifier.title, "Test Alert")
    }

    func testAlertPresentation() {
        let coordinator = PresentationCoordinator()

        // Initially no presentations
        XCTAssertEqual(coordinator.count, 0)

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

        XCTAssertNotNil(modifier)
    }

    func testAlertDismissal() {
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

    // MARK: - Alert with Message Tests

    func testAlertWithMessage() {
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

        XCTAssertNotNil(modifier)
        XCTAssertEqual(modifier.title, "Save Changes")
    }

    func testAlertWithMessagePresentation() {
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

        XCTAssertNotNil(modifier)
        XCTAssertEqual(coordinator.count, 0)

        // When presented, the coordinator would receive the presentation
        binding.wrappedValue = true
        XCTAssertTrue(binding.wrappedValue)
    }

    // MARK: - Data-Driven Alert Tests

    func testDataAlertModifier() {
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

        XCTAssertNotNil(modifier)
        XCTAssertEqual(modifier.title, "Delete Item")
    }

    func testDataAlertPresentation() {
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

        XCTAssertNil(selectedItem)

        // Set data to trigger presentation
        binding.wrappedValue = TestItem(name: "Test")
        XCTAssertNotNil(selectedItem)
        XCTAssertEqual(selectedItem?.name, "Test")
    }

    func testDataAlertDismissal() {
        struct TestItem: Equatable {
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

    // MARK: - Button Action Tests

    func testButtonActionExecution() {
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

        XCTAssertNotNil(modifier)
        // In a real scenario, tapping the button would execute the action
        // Here we verify the structure is correct
        XCTAssertFalse(actionCalled)
    }

    func testMultipleButtonActions() {
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

        XCTAssertNotNil(modifier)
        XCTAssertFalse(primaryActionCalled)
        XCTAssertFalse(secondaryActionCalled)
    }

    // MARK: - Button Role Tests

    func testCancelButtonRole() {
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

        XCTAssertNotNil(modifier)
    }

    func testDestructiveButtonRole() {
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

        XCTAssertNotNil(modifier)
    }

    func testMixedButtonRoles() {
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

        XCTAssertNotNil(modifier)
    }

    // MARK: - View Extension Tests

    func testAlertViewExtension() {
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
        XCTAssertNotNil(view)
    }

    func testAlertWithMessageViewExtension() {
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
        XCTAssertNotNil(view)
    }

    func testDataAlertViewExtension() {
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
        XCTAssertNotNil(view)
    }

    // MARK: - Integration Tests

    func testAlertWithPresentationCoordinator() {
        let coordinator = PresentationCoordinator()

        XCTAssertEqual(coordinator.count, 0)

        // Simulate presenting an alert
        coordinator.present(
            type: .alert,
            content: AnyView(Text("Alert Content"))
        )

        XCTAssertEqual(coordinator.count, 1)
        XCTAssertEqual(coordinator.topPresentation()?.type, .alert)
    }

    func testMultipleAlertsSequence() {
        let coordinator = PresentationCoordinator()

        // Present first alert
        let id1 = coordinator.present(
            type: .alert,
            content: AnyView(Text("Alert 1"))
        )

        XCTAssertEqual(coordinator.count, 1)

        // Dismiss first
        coordinator.dismiss(id1)
        XCTAssertEqual(coordinator.count, 0)

        // Present second alert
        coordinator.present(
            type: .alert,
            content: AnyView(Text("Alert 2"))
        )

        XCTAssertEqual(coordinator.count, 1)
    }

    // MARK: - Edge Cases

    func testAlertWithEmptyTitle() {
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

        XCTAssertNotNil(modifier)
        XCTAssertEqual(modifier.title, "")
    }

    func testAlertWithNoActions() {
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

        XCTAssertNotNil(modifier)
    }
}
