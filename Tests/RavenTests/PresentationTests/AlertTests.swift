import XCTest
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
final class AlertTests: XCTestCase {

    // MARK: - Button Tests

    func testButtonCreation() {
        let button = Alert.Button(label: "OK")

        XCTAssertEqual(button.label, "OK")
        XCTAssertNil(button.role)
        XCTAssertNil(button.action)
        XCTAssertNotNil(button.id)
    }

    func testButtonWithRole() {
        let button = Alert.Button(label: "Delete", role: .destructive)

        XCTAssertEqual(button.label, "Delete")
        XCTAssertEqual(button.role, .destructive)
        XCTAssertNil(button.action)
    }

    func testButtonWithAction() {
        let button = Alert.Button(label: "Confirm") { }

        XCTAssertEqual(button.label, "Confirm")
        XCTAssertNil(button.role)
        XCTAssertNotNil(button.action)
    }

    func testButtonWithRoleAndAction() {
        let button = Alert.Button(label: "Cancel", role: .cancel) { }

        XCTAssertEqual(button.label, "Cancel")
        XCTAssertEqual(button.role, .cancel)
        XCTAssertNotNil(button.action)
    }

    // MARK: - Button Static Methods

    func testDefaultButton() {
        let button = Alert.Button.default("OK") { }

        XCTAssertEqual(button.label, "OK")
        XCTAssertNil(button.role)
        XCTAssertNotNil(button.action)
    }

    func testDefaultButtonWithoutAction() {
        let button = Alert.Button.default("OK")

        XCTAssertEqual(button.label, "OK")
        XCTAssertNil(button.role)
        XCTAssertNil(button.action)
    }

    func testCancelButton() {
        let button = Alert.Button.cancel { }

        XCTAssertEqual(button.label, "Cancel")
        XCTAssertEqual(button.role, .cancel)
        XCTAssertNotNil(button.action)
    }

    func testCancelButtonWithCustomLabel() {
        let button = Alert.Button.cancel("Dismiss")

        XCTAssertEqual(button.label, "Dismiss")
        XCTAssertEqual(button.role, .cancel)
    }

    func testCancelButtonWithoutAction() {
        let button = Alert.Button.cancel()

        XCTAssertEqual(button.label, "Cancel")
        XCTAssertEqual(button.role, .cancel)
        XCTAssertNil(button.action)
    }

    func testDestructiveButton() {
        let button = Alert.Button.destructive("Delete") { }

        XCTAssertEqual(button.label, "Delete")
        XCTAssertEqual(button.role, .destructive)
        XCTAssertNotNil(button.action)
    }

    func testDestructiveButtonWithoutAction() {
        let button = Alert.Button.destructive("Delete")

        XCTAssertEqual(button.label, "Delete")
        XCTAssertEqual(button.role, .destructive)
        XCTAssertNil(button.action)
    }

    // MARK: - Button Role Tests

    func testButtonRoleEquality() {
        XCTAssertEqual(ButtonRole.cancel, .cancel)
        XCTAssertEqual(ButtonRole.destructive, .destructive)
        XCTAssertNotEqual(ButtonRole.cancel, .destructive)
    }

    func testButtonRoleHashable() {
        let roles: Set<ButtonRole> = [.cancel, .destructive]
        XCTAssertEqual(roles.count, 2)
        XCTAssertTrue(roles.contains(.cancel))
        XCTAssertTrue(roles.contains(.destructive))
    }

    // MARK: - Button Identifiable

    func testButtonIdentifiable() {
        let button1 = Alert.Button(label: "OK")
        let button2 = Alert.Button(label: "OK")

        // Each button should have a unique ID
        XCTAssertNotEqual(button1.id, button2.id)
    }

    // MARK: - Alert Creation Tests

    func testAlertWithDefaults() {
        let alert = Alert(title: "Title")

        XCTAssertEqual(alert.title, "Title")
        XCTAssertNil(alert.message)
        XCTAssertEqual(alert.buttons.count, 1)
        XCTAssertEqual(alert.buttons.first?.label, "OK")
    }

    func testAlertWithMessage() {
        let alert = Alert(title: "Title", message: "Message")

        XCTAssertEqual(alert.title, "Title")
        XCTAssertEqual(alert.message, "Message")
        XCTAssertEqual(alert.buttons.count, 1)
    }

    func testAlertWithCustomButtons() {
        let buttons = [
            Alert.Button.default("Save"),
            Alert.Button.cancel()
        ]
        let alert = Alert(title: "Save Changes?", message: nil, buttons: buttons)

        XCTAssertEqual(alert.title, "Save Changes?")
        XCTAssertNil(alert.message)
        XCTAssertEqual(alert.buttons.count, 2)
        XCTAssertEqual(alert.buttons[0].label, "Save")
        XCTAssertEqual(alert.buttons[1].label, "Cancel")
    }

    // MARK: - Single Button Alert Tests

    func testSingleButtonAlert() {
        let button = Alert.Button.default("OK")
        let alert = Alert(title: "Success", message: "Operation completed", button: button)

        XCTAssertEqual(alert.title, "Success")
        XCTAssertEqual(alert.message, "Operation completed")
        XCTAssertEqual(alert.buttons.count, 1)
        XCTAssertEqual(alert.buttons.first?.label, "OK")
    }

    func testSingleButtonAlertWithAction() {
        let button = Alert.Button.default("OK") { }
        let alert = Alert(title: "Info", button: button)

        XCTAssertEqual(alert.buttons.count, 1)
        XCTAssertNotNil(alert.buttons.first?.action)
    }

    // MARK: - Two Button Alert Tests

    func testTwoButtonAlert() {
        let primaryButton = Alert.Button.destructive("Delete")
        let secondaryButton = Alert.Button.cancel()
        let alert = Alert(
            title: "Delete Item",
            message: "This cannot be undone",
            primaryButton: primaryButton,
            secondaryButton: secondaryButton
        )

        XCTAssertEqual(alert.title, "Delete Item")
        XCTAssertEqual(alert.message, "This cannot be undone")
        XCTAssertEqual(alert.buttons.count, 2)
        XCTAssertEqual(alert.buttons[0].label, "Delete")
        XCTAssertEqual(alert.buttons[0].role, .destructive)
        XCTAssertEqual(alert.buttons[1].label, "Cancel")
        XCTAssertEqual(alert.buttons[1].role, .cancel)
    }

    func testTwoButtonAlertWithActions() {
        let primaryButton = Alert.Button.default("Confirm") { }
        let secondaryButton = Alert.Button.cancel { }
        let alert = Alert(
            title: "Confirm",
            primaryButton: primaryButton,
            secondaryButton: secondaryButton
        )

        XCTAssertEqual(alert.buttons.count, 2)
        XCTAssertNotNil(alert.buttons[0].action)
        XCTAssertNotNil(alert.buttons[1].action)
    }

    func testTwoButtonAlertWithMixedRoles() {
        let primaryButton = Alert.Button.default("Save")
        let secondaryButton = Alert.Button.destructive("Discard")
        let alert = Alert(
            title: "Save Changes?",
            primaryButton: primaryButton,
            secondaryButton: secondaryButton
        )

        XCTAssertEqual(alert.buttons[0].role, nil)
        XCTAssertEqual(alert.buttons[1].role, .destructive)
    }

    // MARK: - Alert Sendable Tests

    func testAlertSendable() {
        // Alert should conform to Sendable
        XCTAssert(Alert.self is any Sendable.Type)
    }

    func testAlertButtonSendable() {
        // Alert.Button should conform to Sendable
        XCTAssert(Alert.Button.self is any Sendable.Type)
    }

    func testButtonRoleSendable() {
        // ButtonRole should conform to Sendable
        XCTAssert(ButtonRole.self is any Sendable.Type)
    }

    // MARK: - Complex Alert Scenarios

    func testMultipleButtonsWithDifferentRoles() {
        let buttons = [
            Alert.Button.default("Option 1"),
            Alert.Button.default("Option 2"),
            Alert.Button.destructive("Delete"),
            Alert.Button.cancel()
        ]
        let alert = Alert(title: "Choose", buttons: buttons)

        XCTAssertEqual(alert.buttons.count, 4)
        XCTAssertNil(alert.buttons[0].role)
        XCTAssertNil(alert.buttons[1].role)
        XCTAssertEqual(alert.buttons[2].role, .destructive)
        XCTAssertEqual(alert.buttons[3].role, .cancel)
    }

    func testAlertWithLongMessage() {
        let longMessage = String(repeating: "This is a long message. ", count: 10)
        let alert = Alert(title: "Warning", message: longMessage)

        XCTAssertEqual(alert.message, longMessage)
    }

    func testAlertWithEmptyTitle() {
        let alert = Alert(title: "")

        XCTAssertEqual(alert.title, "")
        XCTAssertEqual(alert.buttons.count, 1)
    }

    func testAlertWithEmptyMessage() {
        let alert = Alert(title: "Title", message: "")

        XCTAssertEqual(alert.message, "")
    }
}
