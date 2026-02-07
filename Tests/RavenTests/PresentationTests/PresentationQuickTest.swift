import Testing
@testable import Raven

/// Quick sanity test for presentation infrastructure
@MainActor
@Suite struct PresentationQuickTest {

    @Test func presentationCoordinatorBasics() {
        let coordinator = PresentationCoordinator()

        // Test initial state
        #expect(coordinator.count == 0)
        #expect(coordinator.topPresentation() == nil)

        // Test present
        let id = coordinator.present(type: .sheet, content: AnyView(Text("Test")))
        #expect(coordinator.count == 1)
        #expect(coordinator.topPresentation()?.id == id)

        // Test dismiss
        coordinator.dismiss(id)
        #expect(coordinator.count == 0)
    }

    @Test func presentationTypes() {
        // Verify all presentation types exist
        let _ = PresentationType.sheet
        let _ = PresentationType.alert
        let _ = PresentationType.fullScreenCover
        let _ = PresentationType.confirmationDialog
        let _ = PresentationType.popover
    }

    @Test func environmentKey() {
        // Verify environment key works
        var env = EnvironmentValues()
        let coordinator = PresentationCoordinator()
        env.presentationCoordinator = coordinator

        #expect(env.presentationCoordinator === coordinator)
    }
}
