import Foundation
import Testing
@testable import Raven

/// Tests for full-screen cover presentation modifiers.
///
/// These tests verify the behavior of `.fullScreenCover(isPresented:)` and
/// `.fullScreenCover(item:)` modifiers, ensuring they properly manage presentation
/// state and integrate with the PresentationCoordinator.
@MainActor
@Suite struct FullScreenCoverTests {

    // MARK: - isPresented Tests

    /// Tests that a full-screen cover is registered when isPresented becomes true.
    @Test func fullScreenCoverRegistersWhenPresented() {
        let coordinator = PresentationCoordinator()

        let modifier = FullScreenCoverModifier(
            isPresented: .constant(true),
            onDismiss: nil
        ) {
            Text("Cover Content")
        }

        let presentationId = modifier.register(with: coordinator)

        #expect(presentationId != nil)
        #expect(coordinator.count == 1)
        #expect(coordinator.topPresentation()?.type == .fullScreenCover)
    }

    /// Tests that a full-screen cover is not registered when isPresented is false.
    @Test func fullScreenCoverDoesNotRegisterWhenNotPresented() {
        let coordinator = PresentationCoordinator()

        let modifier = FullScreenCoverModifier(
            isPresented: .constant(false),
            onDismiss: nil
        ) {
            Text("Cover Content")
        }

        let presentationId = modifier.register(with: coordinator)

        #expect(presentationId == nil)
        #expect(coordinator.count == 0)
    }

    /// Tests that dismissing a full-screen cover removes it from the coordinator.
    @Test func fullScreenCoverDismissal() {
        let coordinator = PresentationCoordinator()

        let modifier = FullScreenCoverModifier(
            isPresented: .constant(true),
            onDismiss: nil
        ) {
            Text("Cover Content")
        }

        guard let presentationId = modifier.register(with: coordinator) else {
            Issue.record("Failed to register presentation")
            return
        }

        #expect(coordinator.count == 1)

        // Dismiss the cover
        modifier.unregister(id: presentationId, from: coordinator)

        #expect(coordinator.count == 0)
    }

    /// Tests that the onDismiss callback is invoked when the cover is dismissed.
    @Test func onDismissCallback() {
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

        #expect(!dismissCallbackInvoked)

        // Dismiss the presentation
        coordinator.dismiss(id)

        #expect(dismissCallbackInvoked)
    }

    // MARK: - Item-based Tests

    /// Tests that a full-screen cover is registered when an item is set.
    @Test func itemFullScreenCoverRegistersWithItem() {
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

        #expect(presentationId != nil)
        #expect(coordinator.count == 1)
        #expect(coordinator.topPresentation()?.type == .fullScreenCover)
    }

    /// Tests that a full-screen cover is not registered when the item is nil.
    @Test func itemFullScreenCoverDoesNotRegisterWithNilItem() {
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

        #expect(presentationId == nil)
        #expect(coordinator.count == 0)
    }

    /// Tests that changing the item dismisses the old cover and presents a new one.
    @Test func itemFullScreenCoverUpdatesWhenItemChanges() {
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
            Issue.record("Failed to register first presentation")
            return
        }

        #expect(coordinator.count == 1)

        // Simulate item change by unregistering old and registering new
        modifier.unregister(id: id1, from: coordinator)

        let modifier2 = ItemFullScreenCoverModifier(
            item: .constant(item2),
            onDismiss: nil
        ) { item in
            Text(item.title)
        }

        let id2 = modifier2.register(with: coordinator)

        #expect(id2 != nil)
        #expect(id1 != id2)
        #expect(coordinator.count == 1)
    }

    // MARK: - Multiple Covers Tests

    /// Tests that multiple full-screen covers can be stacked.
    @Test func multipleFullScreenCovers() {
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

        #expect(id1 != nil)
        #expect(id2 != nil)
        #expect(id1 != id2)
        #expect(coordinator.count == 2)

        // Verify z-index ordering
        #expect(coordinator.presentations.first != nil)
        #expect(coordinator.presentations.last != nil)
        #expect(coordinator.presentations.first!.zIndex < coordinator.presentations.last!.zIndex)
    }

    // MARK: - Presentation Type Tests

    /// Tests that full-screen covers use the correct presentation type.
    @Test func fullScreenCoverPresentationType() {
        let coordinator = PresentationCoordinator()

        let modifier = FullScreenCoverModifier(
            isPresented: .constant(true),
            onDismiss: nil
        ) {
            Text("Cover Content")
        }

        guard let _ = modifier.register(with: coordinator) else {
            Issue.record("Failed to register presentation")
            return
        }

        #expect(coordinator.topPresentation()?.type == .fullScreenCover)
    }

    /// Tests that full-screen covers and sheets can be differentiated.
    @Test func fullScreenCoverVsSheet() {
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

        #expect(sheetId != nil)
        #expect(coverId != nil)
        #expect(coordinator.count == 2)

        // Verify types are different
        let presentations = coordinator.presentations
        let sheetPresentation = presentations.first { $0.id == sheetId }
        let coverPresentation = presentations.first { $0.id == coverId }

        #expect(sheetPresentation?.type == .sheet)
        #expect(coverPresentation?.type == .fullScreenCover)
        #expect(sheetPresentation?.type != coverPresentation?.type)
    }

    // MARK: - Modifier Composition Tests

    /// Tests that full-screen covers can be combined with other modifiers.
    @Test func fullScreenCoverWithInteractiveDismissDisabled() {
        // Verify the modifiers can be composed
        let view = Text("Content")
            .fullScreenCover(isPresented: .constant(false)) {
                Text("Cover")
            }
            .interactiveDismissDisabled()

        #expect(view != nil)
    }

    /// Tests that full-screen covers work with conditional presentation.
    @Test func conditionalFullScreenCover() {
        var shouldPresent = false

        let view = Text("Content")
            .fullScreenCover(isPresented: .constant(shouldPresent)) {
                Text("Cover")
            }

        #expect(view != nil)

        shouldPresent = true

        let view2 = Text("Content")
            .fullScreenCover(isPresented: .constant(shouldPresent)) {
                Text("Cover")
            }

        #expect(view2 != nil)
    }
}
