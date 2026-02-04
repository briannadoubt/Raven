import XCTest
@testable import Raven

// MARK: - Presentation Integration Tests
//
// These tests verify the integration of the entire presentation system,
// including nested presentations, environment propagation, state updates,
// and memory management.

@MainActor
final class PresentationIntegrationTests: XCTestCase {

    // MARK: - Nested Presentations

    func testNestedSheetOnSheet() async throws {
        let coordinator = PresentationCoordinator()

        // Present first sheet
        let firstId = coordinator.present(
            type: .sheet,
            content: AnyView(Text("First Sheet"))
        )

        XCTAssertEqual(coordinator.count, 1)
        XCTAssertEqual(coordinator.topPresentation()?.id, firstId)

        // Present second sheet on top of first
        let secondId = coordinator.present(
            type: .sheet,
            content: AnyView(Text("Second Sheet"))
        )

        XCTAssertEqual(coordinator.count, 2)
        XCTAssertEqual(coordinator.topPresentation()?.id, secondId)

        // Verify z-index ordering
        let presentations = coordinator.presentations
        XCTAssertTrue(presentations[0].zIndex < presentations[1].zIndex)

        // Dismiss second sheet
        coordinator.dismiss(secondId)
        XCTAssertEqual(coordinator.count, 1)
        XCTAssertEqual(coordinator.topPresentation()?.id, firstId)

        // Dismiss first sheet
        coordinator.dismiss(firstId)
        XCTAssertEqual(coordinator.count, 0)
    }

    func testAlertOnSheet() async throws {
        let coordinator = PresentationCoordinator()

        // Present sheet
        let sheetId = coordinator.present(
            type: .sheet,
            content: AnyView(Text("Sheet"))
        )

        XCTAssertEqual(coordinator.count, 1)

        // Present alert on top of sheet
        let alertId = coordinator.present(
            type: .alert,
            content: AnyView(Text("Alert"))
        )

        XCTAssertEqual(coordinator.count, 2)

        // Alert should be on top
        XCTAssertEqual(coordinator.topPresentation()?.id, alertId)

        // Verify alert has higher z-index than sheet
        let presentations = coordinator.presentations
        let sheet = presentations.first { $0.id == sheetId }!
        let alert = presentations.first { $0.id == alertId }!
        XCTAssertTrue(alert.zIndex > sheet.zIndex)

        // Dismiss alert
        coordinator.dismiss(alertId)
        XCTAssertEqual(coordinator.count, 1)
        XCTAssertEqual(coordinator.topPresentation()?.id, sheetId)
    }

    func testOnDismissCallback() async throws {
        let coordinator = PresentationCoordinator()
        var dismissed = false

        let id = coordinator.present(
            type: .sheet,
            content: AnyView(Text("Sheet")),
            onDismiss: {
                dismissed = true
            }
        )

        XCTAssertEqual(coordinator.count, 1)
        XCTAssertFalse(dismissed)

        coordinator.dismiss(id)
        XCTAssertTrue(dismissed)
        XCTAssertEqual(coordinator.count, 0)
    }
}
