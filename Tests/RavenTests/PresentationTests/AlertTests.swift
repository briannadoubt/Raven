import Testing
@testable import Raven

/// Comprehensive tests for the Alert struct and related types.
///
/// These tests verify:
/// - Alert struct creation
/// - Button roles
/// - Single button alerts
/// - Two-button alerts
/// - Button static methods
@MainActor
@Suite struct AlertTests {

    // MARK: - Button Tests

    @Test func buttonCreation() {
        let button = Alert.Button(label: "OK")

        #expect(button.label == "OK")
        #expect(button.role == nil)
        #expect(button.action == nil)
        #expect(button.id != nil)
    }

    @Test func buttonWithRole() {
        let button = Alert.Button(label: "Delete", role: .destructive)

        #expect(button.label == "Delete")
        #expect(button.role == .destructive)
        #expect(button.action == nil)
    }

    @Test func buttonWithAction() {
        let button = Alert.Button(label: "Confirm") { }

        #expect(button.label == "Confirm")
        #expect(button.role == nil)
        #expect(button.action != nil)
    }

    @Test func buttonWithRoleAndAction() {
        let button = Alert.Button(label: "Cancel", role: .cancel) { }

        #expect(button.label == "Cancel")
        #expect(button.role == .cancel)
        #expect(button.action != nil)
    }

    // MARK: - Button Static Methods

    @Test func defaultButton() {
        let button = Alert.Button.default("OK") { }

        #expect(button.label == "OK")
        #expect(button.role == nil)
        #expect(button.action != nil)
    }

    @Test func defaultButtonWithoutAction() {
        let button = Alert.Button.default("OK")

        #expect(button.label == "OK")
        #expect(button.role == nil)
        #expect(button.action == nil)
    }

    @Test func cancelButton() {
        let button = Alert.Button.cancel { }

        #expect(button.label == "Cancel")
        #expect(button.role == .cancel)
        #expect(button.action != nil)
    }

    @Test func cancelButtonWithCustomLabel() {
        let button = Alert.Button.cancel("Dismiss")

        #expect(button.label == "Dismiss")
        #expect(button.role == .cancel)
    }

    @Test func cancelButtonWithoutAction() {
        let button = Alert.Button.cancel()

        #expect(button.label == "Cancel")
        #expect(button.role == .cancel)
        #expect(button.action == nil)
    }

    @Test func destructiveButton() {
        let button = Alert.Button.destructive("Delete") { }

        #expect(button.label == "Delete")
        #expect(button.role == .destructive)
        #expect(button.action != nil)
    }

    @Test func destructiveButtonWithoutAction() {
        let button = Alert.Button.destructive("Delete")

        #expect(button.label == "Delete")
        #expect(button.role == .destructive)
        #expect(button.action == nil)
    }

    // MARK: - Button Role Tests

    @Test func buttonRoleEquality() {
        #expect(ButtonRole.cancel == .cancel)
        #expect(ButtonRole.destructive == .destructive)
        #expect(ButtonRole.cancel != .destructive)
    }

    @Test func buttonRoleHashable() {
        let roles: Set<ButtonRole> = [.cancel, .destructive]
        #expect(roles.count == 2)
        #expect(roles.contains(.cancel))
        #expect(roles.contains(.destructive))
    }

    // MARK: - Button Identifiable

    @Test func buttonIdentifiable() {
        let button1 = Alert.Button(label: "OK")
        let button2 = Alert.Button(label: "OK")

        // Each button should have a unique ID
        #expect(button1.id != button2.id)
    }

    // MARK: - Alert Creation Tests

    @Test func alertWithDefaults() {
        let alert = Alert(title: "Title")

        #expect(alert.title == "Title")
        #expect(alert.message == nil)
        #expect(alert.buttons.count == 1)
        #expect(alert.buttons.first?.label == "OK")
    }

    @Test func alertWithMessage() {
        let alert = Alert(title: "Title", message: "Message")

        #expect(alert.title == "Title")
        #expect(alert.message == "Message")
        #expect(alert.buttons.count == 1)
    }

    @Test func alertWithCustomButtons() {
        let buttons = [
            Alert.Button.default("Save"),
            Alert.Button.cancel()
        ]
        let alert = Alert(title: "Save Changes?", message: nil, buttons: buttons)

        #expect(alert.title == "Save Changes?")
        #expect(alert.message == nil)
        #expect(alert.buttons.count == 2)
        #expect(alert.buttons[0].label == "Save")
        #expect(alert.buttons[1].label == "Cancel")
    }

    // MARK: - Single Button Alert Tests

    @Test func singleButtonAlert() {
        let button = Alert.Button.default("OK")
        let alert = Alert(title: "Success", message: "Operation completed", button: button)

        #expect(alert.title == "Success")
        #expect(alert.message == "Operation completed")
        #expect(alert.buttons.count == 1)
        #expect(alert.buttons.first?.label == "OK")
    }

    @Test func singleButtonAlertWithAction() {
        let button = Alert.Button.default("OK") { }
        let alert = Alert(title: "Info", button: button)

        #expect(alert.buttons.count == 1)
        #expect(alert.buttons.first?.action != nil)
    }

    // MARK: - Two Button Alert Tests

    @Test func twoButtonAlert() {
        let primaryButton = Alert.Button.destructive("Delete")
        let secondaryButton = Alert.Button.cancel()
        let alert = Alert(
            title: "Delete Item",
            message: "This cannot be undone",
            primaryButton: primaryButton,
            secondaryButton: secondaryButton
        )

        #expect(alert.title == "Delete Item")
        #expect(alert.message == "This cannot be undone")
        #expect(alert.buttons.count == 2)
        #expect(alert.buttons[0].label == "Delete")
        #expect(alert.buttons[0].role == .destructive)
        #expect(alert.buttons[1].label == "Cancel")
        #expect(alert.buttons[1].role == .cancel)
    }

    @Test func twoButtonAlertWithActions() {
        let primaryButton = Alert.Button.default("Confirm") { }
        let secondaryButton = Alert.Button.cancel { }
        let alert = Alert(
            title: "Confirm",
            primaryButton: primaryButton,
            secondaryButton: secondaryButton
        )

        #expect(alert.buttons.count == 2)
        #expect(alert.buttons[0].action != nil)
        #expect(alert.buttons[1].action != nil)
    }

    @Test func twoButtonAlertWithMixedRoles() {
        let primaryButton = Alert.Button.default("Save")
        let secondaryButton = Alert.Button.destructive("Discard")
        let alert = Alert(
            title: "Save Changes?",
            primaryButton: primaryButton,
            secondaryButton: secondaryButton
        )

        #expect(alert.buttons[0].role == nil)
        #expect(alert.buttons[1].role == .destructive)
    }

    // MARK: - Alert Sendable Tests

    @Test func alertSendable() {
        // Alert should conform to Sendable
        #expect(Alert.self is any Sendable.Type)
    }

    @Test func alertButtonSendable() {
        // Alert.Button should conform to Sendable
        #expect(Alert.Button.self is any Sendable.Type)
    }

    @Test func buttonRoleSendable() {
        // ButtonRole should conform to Sendable
        #expect(ButtonRole.self is any Sendable.Type)
    }

    // MARK: - Complex Alert Scenarios

    @Test func multipleButtonsWithDifferentRoles() {
        let buttons = [
            Alert.Button.default("Option 1"),
            Alert.Button.default("Option 2"),
            Alert.Button.destructive("Delete"),
            Alert.Button.cancel()
        ]
        let alert = Alert(title: "Choose", buttons: buttons)

        #expect(alert.buttons.count == 4)
        #expect(alert.buttons[0].role == nil)
        #expect(alert.buttons[1].role == nil)
        #expect(alert.buttons[2].role == .destructive)
        #expect(alert.buttons[3].role == .cancel)
    }

    @Test func alertWithLongMessage() {
        let longMessage = String(repeating: "This is a long message. ", count: 10)
        let alert = Alert(title: "Warning", message: longMessage)

        #expect(alert.message == longMessage)
    }

    @Test func alertWithEmptyTitle() {
        let alert = Alert(title: "")

        #expect(alert.title == "")
        #expect(alert.buttons.count == 1)
    }

    @Test func alertWithEmptyMessage() {
        let alert = Alert(title: "Title", message: "")

        #expect(alert.message == "")
    }

    // MARK: - Alert Renderer Extraction Tests

    @Test func extractAlertDataWithTitleOnly() {
        // Create an alert content view with just a title
        let content = AnyView(VStack {
            Text("Alert Title")
            Button("OK") { }
        })

        let extracted = AlertRenderer.extractAlertData(from: content)

        #expect(extracted != nil)
        #expect(extracted?.title == "Alert Title")
        #expect(extracted?.message == nil)
        #expect(extracted?.buttons.count == 1)
        #expect(extracted?.buttons.first?.label == "OK")
    }

    @Test func extractAlertDataWithTitleAndMessage() {
        // Create an alert content view with title and message
        let content = AnyView(VStack {
            Text("Alert Title")
            Text("This is a message")
            Button("OK") { }
        })

        let extracted = AlertRenderer.extractAlertData(from: content)

        #expect(extracted != nil)
        #expect(extracted?.title == "Alert Title")
        #expect(extracted?.message == "This is a message")
        #expect(extracted?.buttons.count == 1)
    }

    @Test func extractAlertDataWithMultipleButtons() {
        // Create an alert content view with multiple buttons
        let content = AnyView(VStack {
            Text("Confirm Action")
            Text("Are you sure?")
            Button("Delete") { }
            Button("Cancel") { }
        })

        let extracted = AlertRenderer.extractAlertData(from: content)

        #expect(extracted != nil)
        #expect(extracted?.title == "Confirm Action")
        #expect(extracted?.message == "Are you sure?")
        #expect(extracted?.buttons.count == 2)
        #expect(extracted?.buttons[0].label == "Delete")
        #expect(extracted?.buttons[1].label == "Cancel")
    }

    @Test func extractAlertDataWithNoButtons() {
        // Create an alert content view with no buttons
        let content = AnyView(VStack {
            Text("Alert Title")
            Text("This is a message")
        })

        let extracted = AlertRenderer.extractAlertData(from: content)

        #expect(extracted != nil)
        #expect(extracted?.title == "Alert Title")
        #expect(extracted?.message == "This is a message")
        #expect(extracted?.buttons.count == 0)
    }

    @Test func extractAlertDataWithEmptyContent() {
        // Create an empty content view
        let content = AnyView(VStack { })

        let extracted = AlertRenderer.extractAlertData(from: content)

        // Should return nil for empty content
        #expect(extracted == nil)
    }
}
