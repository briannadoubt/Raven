import XCTest
@testable import Raven

/// Tests for full-screen cover presentation modifiers.
///
/// These tests verify the behavior of `.fullScreenCover(isPresented:)` and
/// `.fullScreenCover(item:)` modifiers, ensuring they properly manage presentation
/// state and integrate with the PresentationCoordinator.
@MainActor
final class FullScreenCoverTests: XCTestCase {

    // MARK: - isPresented Tests

    /// Tests that a full-screen cover is registered when isPresented becomes true.
    func testFullScreenCoverRegistersWhenPresented() {
        let coordinator = PresentationCoordinator()

        let modifier = FullScreenCoverModifier(
            isPresented: .constant(true),
            onDismiss: nil
        ) {
            Text("Cover Content")
        }

        let presentationId = modifier.register(with: coordinator)

        XCTAssertNotNil(presentationId)
        XCTAssertEqual(coordinator.count, 1)
        XCTAssertEqual(coordinator.topPresentation()?.type, .fullScreenCover)
    }

    /// Tests that a full-screen cover is not registered when isPresented is false.
    func testFullScreenCoverDoesNotRegisterWhenNotPresented() {
        let coordinator = PresentationCoordinator()

        let modifier = FullScreenCoverModifier(
            isPresented: .constant(false),
            onDismiss: nil
        ) {
            Text("Cover Content")
        }

        let presentationId = modifier.register(with: coordinator)

        XCTAssertNil(presentationId)
        XCTAssertEqual(coordinator.count, 0)
    }

    /// Tests that dismissing a full-screen cover removes it from the coordinator.
    func testFullScreenCoverDismissal() {
        let coordinator = PresentationCoordinator()

        let modifier = FullScreenCoverModifier(
            isPresented: .constant(true),
            onDismiss: nil
        ) {
            Text("Cover Content")
        }

        guard let presentationId = modifier.register(with: coordinator) else {
            XCTFail("Failed to register presentation")
            return
        }

        XCTAssertEqual(coordinator.count, 1)

        // Dismiss the cover
        modifier.unregister(id: presentationId, from: coordinator)

        XCTAssertEqual(coordinator.count, 0)
    }

    /// Tests that the onDismiss callback is invoked when the cover is dismissed.
    func testOnDismissCallback() {
        let coordinator = PresentationCoordinator()
        var dismissCallbackInvoked = false

        // Create a presentation directly with the coordinator
        let id = coordinator.present(
            type: .fullScreenCover,
            content: AnyView(Text("Cover")),
            onDismiss: { @MainActor in
                dismissCallbackInvoked = true
            }
        )

        XCTAssertFalse(dismissCallbackInvoked)

        // Dismiss the presentation
        coordinator.dismiss(id)

        XCTAssertTrue(dismissCallbackInvoked)
    }

    // MARK: - Item-based Tests

    /// Tests that a full-screen cover is registered when an item is set.
    func testItemFullScreenCoverRegistersWithItem() {
        struct TestItem: Identifiable, Sendable, Equatable {
            let id = UUID()
            let title: String
            let content: String
        }

        let coordinator = PresentationCoordinator()
        let item = TestItem(title: "Document", content: "Content here")

        let modifier = ItemFullScreenCoverModifier(
            item: .constant(item),
            onDismiss: nil
        ) { item in
            VStack {
                Text(item.title)
                Text(item.content)
            }
        }

        let presentationId = modifier.register(with: coordinator)

        XCTAssertNotNil(presentationId)
        XCTAssertEqual(coordinator.count, 1)
        XCTAssertEqual(coordinator.topPresentation()?.type, .fullScreenCover)
    }

    /// Tests that a full-screen cover is not registered when the item is nil.
    func testItemFullScreenCoverDoesNotRegisterWithNilItem() {
        struct TestItem: Identifiable, Sendable, Equatable {
            let id = UUID()
            let title: String
        }

        let coordinator = PresentationCoordinator()

        let modifier = ItemFullScreenCoverModifier(
            item: .constant(nil as TestItem?),
            onDismiss: nil
        ) { item in
            Text(item.title)
        }

        let presentationId = modifier.register(with: coordinator)

        XCTAssertNil(presentationId)
        XCTAssertEqual(coordinator.count, 0)
    }

    /// Tests that changing the item dismisses the old cover and presents a new one.
    func testItemFullScreenCoverUpdatesWhenItemChanges() {
        struct TestItem: Identifiable, Sendable, Equatable {
            let id: UUID
            let title: String
        }

        let coordinator = PresentationCoordinator()
        let item1 = TestItem(id: UUID(), title: "Document 1")
        let item2 = TestItem(id: UUID(), title: "Document 2")

        let modifier = ItemFullScreenCoverModifier(
            item: .constant(item1),
            onDismiss: nil
        ) { item in
            Text(item.title)
        }

        // Register first item
        guard let id1 = modifier.register(with: coordinator) else {
            XCTFail("Failed to register first presentation")
            return
        }

        XCTAssertEqual(coordinator.count, 1)

        // Simulate item change by unregistering old and registering new
        modifier.unregister(id: id1, from: coordinator)

        let modifier2 = ItemFullScreenCoverModifier(
            item: .constant(item2),
            onDismiss: nil
        ) { item in
            Text(item.title)
        }

        let id2 = modifier2.register(with: coordinator)

        XCTAssertNotNil(id2)
        XCTAssertNotEqual(id1, id2)
        XCTAssertEqual(coordinator.count, 1)
    }

    // MARK: - Multiple Covers Tests

    /// Tests that multiple full-screen covers can be stacked.
    func testMultipleFullScreenCovers() {
        let coordinator = PresentationCoordinator()

        let modifier1 = FullScreenCoverModifier(
            isPresented: .constant(true),
            onDismiss: nil
        ) {
            Text("Cover 1")
        }

        let modifier2 = FullScreenCoverModifier(
            isPresented: .constant(true),
            onDismiss: nil
        ) {
            Text("Cover 2")
        }

        let id1 = modifier1.register(with: coordinator)
        let id2 = modifier2.register(with: coordinator)

        XCTAssertNotNil(id1)
        XCTAssertNotNil(id2)
        XCTAssertNotEqual(id1, id2)
        XCTAssertEqual(coordinator.count, 2)

        // Verify z-index ordering
        XCTAssertNotNil(coordinator.presentations.first)
        XCTAssertNotNil(coordinator.presentations.last)
        XCTAssertLessThan(coordinator.presentations.first!.zIndex,
                          coordinator.presentations.last!.zIndex)
    }

    // MARK: - Presentation Type Tests

    /// Tests that full-screen covers use the correct presentation type.
    func testFullScreenCoverPresentationType() {
        let coordinator = PresentationCoordinator()

        let modifier = FullScreenCoverModifier(
            isPresented: .constant(true),
            onDismiss: nil
        ) {
            Text("Cover Content")
        }

        guard let _ = modifier.register(with: coordinator) else {
            XCTFail("Failed to register presentation")
            return
        }

        XCTAssertEqual(coordinator.topPresentation()?.type, .fullScreenCover)
    }

    /// Tests that full-screen covers and sheets can be differentiated.
    func testFullScreenCoverVsSheet() {
        let coordinator = PresentationCoordinator()

        // Register a sheet
        let sheetModifier = SheetModifier(
            isPresented: .constant(true),
            onDismiss: nil
        ) {
            Text("Sheet")
        }
        let sheetId = sheetModifier.register(with: coordinator)

        // Register a full-screen cover
        let coverModifier = FullScreenCoverModifier(
            isPresented: .constant(true),
            onDismiss: nil
        ) {
            Text("Cover")
        }
        let coverId = coverModifier.register(with: coordinator)

        XCTAssertNotNil(sheetId)
        XCTAssertNotNil(coverId)
        XCTAssertEqual(coordinator.count, 2)

        // Verify types are different
        let presentations = coordinator.presentations
        let sheetPresentation = presentations.first { $0.id == sheetId }
        let coverPresentation = presentations.first { $0.id == coverId }

        XCTAssertEqual(sheetPresentation?.type, .sheet)
        XCTAssertEqual(coverPresentation?.type, .fullScreenCover)
        XCTAssertNotEqual(sheetPresentation?.type, coverPresentation?.type)
    }

    // MARK: - Modifier Composition Tests

    /// Tests that full-screen covers can be combined with other modifiers.
    func testFullScreenCoverWithInteractiveDismissDisabled() {
        // Verify the modifiers can be composed
        let view = Text("Content")
            .fullScreenCover(isPresented: .constant(false)) {
                Text("Cover")
            }
            .interactiveDismissDisabled()

        XCTAssertNotNil(view)
    }

    /// Tests that full-screen covers work with conditional presentation.
    func testConditionalFullScreenCover() {
        var shouldPresent = false

        let view = Text("Content")
            .fullScreenCover(isPresented: .constant(shouldPresent)) {
                Text("Cover")
            }

        XCTAssertNotNil(view)

        shouldPresent = true

        let view2 = Text("Content")
            .fullScreenCover(isPresented: .constant(shouldPresent)) {
                Text("Cover")
            }

        XCTAssertNotNil(view2)
    }
}
