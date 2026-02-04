import XCTest
@testable import Raven

/// Quick sanity test for presentation infrastructure
@MainActor
final class PresentationQuickTest: XCTestCase {

    func testPresentationCoordinatorBasics() {
        let coordinator = PresentationCoordinator()

        // Test initial state
        XCTAssertEqual(coordinator.count, 0)
        XCTAssertNil(coordinator.topPresentation())

        // Test present
        let id = coordinator.present(type: .sheet, content: AnyView(Text("Test")))
        XCTAssertEqual(coordinator.count, 1)
        XCTAssertEqual(coordinator.topPresentation()?.id, id)

        // Test dismiss
        coordinator.dismiss(id)
        XCTAssertEqual(coordinator.count, 0)
    }

    func testPresentationTypes() {
        // Verify all presentation types exist
        let _ = PresentationType.sheet
        let _ = PresentationType.alert
        let _ = PresentationType.fullScreenCover
        let _ = PresentationType.confirmationDialog
        let _ = PresentationType.popover
    }

    func testEnvironmentKey() {
        // Verify environment key works
        var env = EnvironmentValues()
        let coordinator = PresentationCoordinator()
        env.presentationCoordinator = coordinator

        XCTAssertIdentical(env.presentationCoordinator, coordinator)
    }
}
