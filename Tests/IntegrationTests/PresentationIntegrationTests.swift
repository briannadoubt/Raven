import Testing
@testable import Raven

// MARK: - Presentation Integration Tests
//
// These tests verify the integration of the entire presentation system,
// including nested presentations, environment propagation, state updates,
// and memory management.

@MainActor
@Suite struct PresentationIntegrationTests {

    // MARK: - Nested Presentations

    @Test func nestedSheetOnSheet() async throws {
        let coordinator = PresentationCoordinator()

        // Present first sheet
        let firstId = coordinator.present(
            type: .sheet,
            content: AnyView(Text("First Sheet"))
        )

        #expect(coordinator.count == 1)
        #expect(coordinator.topPresentation()?.id == firstId)

        // Present second sheet on top of first
        let secondId = coordinator.present(
            type: .sheet,
            content: AnyView(Text("Second Sheet"))
        )

        #expect(coordinator.count == 2)
        #expect(coordinator.topPresentation()?.id == secondId)

        // Verify z-index ordering
        let presentations = coordinator.presentations
        #expect(presentations[0].zIndex < presentations[1].zIndex)

        // Dismiss second sheet
        coordinator.dismiss(secondId)
        #expect(coordinator.count == 1)
        #expect(coordinator.topPresentation()?.id == firstId)

        // Dismiss first sheet
        coordinator.dismiss(firstId)
        #expect(coordinator.count == 0)
    }

    @Test func alertOnSheet() async throws {
        let coordinator = PresentationCoordinator()

        // Present sheet
        let sheetId = coordinator.present(
            type: .sheet,
            content: AnyView(Text("Sheet"))
        )

        #expect(coordinator.count == 1)

        // Present alert on top of sheet
        let alertId = coordinator.present(
            type: .alert,
            content: AnyView(Text("Alert"))
        )

        #expect(coordinator.count == 2)

        // Alert should be on top
        #expect(coordinator.topPresentation()?.id == alertId)

        // Verify alert has higher z-index than sheet
        let presentations = coordinator.presentations
        let sheet = presentations.first { $0.id == sheetId }!
        let alert = presentations.first { $0.id == alertId }!
        #expect(alert.zIndex > sheet.zIndex)

        // Dismiss alert
        coordinator.dismiss(alertId)
        #expect(coordinator.count == 1)
        #expect(coordinator.topPresentation()?.id == sheetId)
    }

    @Test func onDismissCallback() async throws {
        let coordinator = PresentationCoordinator()
        var dismissed = false

        let id = coordinator.present(
            type: .sheet,
            content: AnyView(Text("Sheet")),
            onDismiss: {
                dismissed = true
            }
        )

        #expect(coordinator.count == 1)
        #expect(!dismissed)

        coordinator.dismiss(id)
        #expect(dismissed)
        #expect(coordinator.count == 0)
    }
}
