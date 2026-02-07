import Foundation
import Testing
@testable import Raven

/// Comprehensive tests for the PresentationCoordinator and related types.
///
/// These tests verify the core presentation infrastructure including:
/// - Stack management (push/pop)
/// - Z-index allocation
/// - Multiple presentations
/// - Dismiss callbacks
/// - Memory leak prevention
@MainActor
@Suite struct PresentationCoordinatorTests {

    // MARK: - Basic Initialization

    @Test func coordinatorInitialization() {
        let coordinator = PresentationCoordinator()
        #expect(coordinator.presentations.count == 0)
        #expect(coordinator.count == 0)
        #expect(coordinator.topPresentation() == nil)
    }

    // MARK: - Single Presentation Tests

    @Test func presentSingleSheet() {
        let coordinator = PresentationCoordinator()
        let content = AnyView(Text("Sheet Content"))

        let id = coordinator.present(type: .sheet, content: content)

        #expect(coordinator.count == 1)
        #expect(coordinator.presentations.count == 1)

        let entry = coordinator.presentations.first
        #expect(entry != nil)
        #expect(entry?.id == id)
        #expect(entry?.type == .sheet)
        #expect(entry?.zIndex == 1000) // Base z-index
    }

    @Test func presentSingleAlert() {
        let coordinator = PresentationCoordinator()
        let content = AnyView(Text("Alert Content"))

        let id = coordinator.present(type: .alert, content: content)

        #expect(coordinator.count == 1)

        let entry = coordinator.presentations.first
        #expect(entry?.type == .alert)
        #expect(entry?.id == id)
    }

    @Test func presentFullScreenCover() {
        let coordinator = PresentationCoordinator()
        let content = AnyView(Text("Full Screen Content"))

        coordinator.present(type: .fullScreenCover, content: content)

        #expect(coordinator.count == 1)
        #expect(coordinator.presentations.first?.type == .fullScreenCover)
    }

    @Test func presentConfirmationDialog() {
        let coordinator = PresentationCoordinator()
        let content = AnyView(Text("Dialog Content"))

        coordinator.present(type: .confirmationDialog, content: content)

        #expect(coordinator.count == 1)
        #expect(coordinator.presentations.first?.type == .confirmationDialog)
    }

    @Test func presentPopover() {
        let coordinator = PresentationCoordinator()
        let content = AnyView(Text("Popover Content"))

        coordinator.present(type: .popover(anchor: .rect(.bounds), edge: .top), content: content)

        #expect(coordinator.count == 1)
        if case .popover = coordinator.presentations.first?.type {
            #expect(true)
        } else {
            Issue.record("Expected popover presentation type")
        }
    }

    // MARK: - Stack Management Tests

    @Test func multiplePresentations() {
        let coordinator = PresentationCoordinator()

        let id1 = coordinator.present(type: .sheet, content: AnyView(Text("First")))
        let id2 = coordinator.present(type: .alert, content: AnyView(Text("Second")))
        let id3 = coordinator.present(type: .popover(anchor: .rect(.bounds), edge: .top), content: AnyView(Text("Third")))

        #expect(coordinator.count == 3)
        #expect(coordinator.presentations[0].id == id1)
        #expect(coordinator.presentations[1].id == id2)
        #expect(coordinator.presentations[2].id == id3)
    }

    @Test func topPresentation() {
        let coordinator = PresentationCoordinator()

        #expect(coordinator.topPresentation() == nil)

        let id1 = coordinator.present(type: .sheet, content: AnyView(Text("First")))
        #expect(coordinator.topPresentation()?.id == id1)

        let id2 = coordinator.present(type: .alert, content: AnyView(Text("Second")))
        #expect(coordinator.topPresentation()?.id == id2)

        let id3 = coordinator.present(type: .popover(anchor: .rect(.bounds), edge: .top), content: AnyView(Text("Third")))
        #expect(coordinator.topPresentation()?.id == id3)
    }

    @Test func presentationOrder() {
        let coordinator = PresentationCoordinator()

        let id1 = coordinator.present(type: .sheet, content: AnyView(Text("First")))
        let id2 = coordinator.present(type: .alert, content: AnyView(Text("Second")))
        let id3 = coordinator.present(type: .fullScreenCover, content: AnyView(Text("Third")))

        // Verify order: first presentation is at index 0, last is at the end
        #expect(coordinator.presentations[0].id == id1)
        #expect(coordinator.presentations[1].id == id2)
        #expect(coordinator.presentations[2].id == id3)
    }

    // MARK: - Z-Index Tests

    @Test func zIndexAllocation() {
        let coordinator = PresentationCoordinator()

        let id1 = coordinator.present(type: .sheet, content: AnyView(Text("First")))
        let id2 = coordinator.present(type: .alert, content: AnyView(Text("Second")))
        let id3 = coordinator.present(type: .popover(anchor: .rect(.bounds), edge: .top), content: AnyView(Text("Third")))

        // First presentation: base z-index (1000)
        #expect(coordinator.presentations[0].zIndex == 1000)

        // Second presentation: base + 1 * increment (1010)
        #expect(coordinator.presentations[1].zIndex == 1010)

        // Third presentation: base + 2 * increment (1020)
        #expect(coordinator.presentations[2].zIndex == 1020)
    }

    @Test func zIndexAfterDismiss() {
        let coordinator = PresentationCoordinator()

        let id1 = coordinator.present(type: .sheet, content: AnyView(Text("First")))
        let id2 = coordinator.present(type: .alert, content: AnyView(Text("Second")))

        #expect(coordinator.presentations[0].zIndex == 1000)
        #expect(coordinator.presentations[1].zIndex == 1010)

        // Dismiss the first one
        coordinator.dismiss(id1)

        // Add a new presentation - should get z-index based on current count (1)
        let id3 = coordinator.present(type: .popover(anchor: .rect(.bounds), edge: .top), content: AnyView(Text("Third")))

        #expect(coordinator.presentations[0].zIndex == 1010) // id2
        #expect(coordinator.presentations[1].zIndex == 1010) // id3 (count was 1 when created)
    }

    @Test func zIndexUniqueness() {
        let coordinator = PresentationCoordinator()

        // Present 5 items
        for i in 0..<5 {
            coordinator.present(type: .sheet, content: AnyView(Text("Item \(i)")))
        }

        // Verify each has a unique z-index
        let zIndices = coordinator.presentations.map { $0.zIndex }
        let uniqueZIndices = Set(zIndices)

        #expect(zIndices.count == uniqueZIndices.count)
    }

    // MARK: - Dismiss Tests

    @Test func dismissSinglePresentation() {
        let coordinator = PresentationCoordinator()
        let id = coordinator.present(type: .sheet, content: AnyView(Text("Content")))

        #expect(coordinator.count == 1)

        let dismissed = coordinator.dismiss(id)

        #expect(dismissed)
        #expect(coordinator.count == 0)
        #expect(coordinator.topPresentation() == nil)
    }

    @Test func dismissMiddlePresentation() {
        let coordinator = PresentationCoordinator()

        let id1 = coordinator.present(type: .sheet, content: AnyView(Text("First")))
        let id2 = coordinator.present(type: .alert, content: AnyView(Text("Second")))
        let id3 = coordinator.present(type: .popover(anchor: .rect(.bounds), edge: .top), content: AnyView(Text("Third")))

        #expect(coordinator.count == 3)

        // Dismiss the middle one
        let dismissed = coordinator.dismiss(id2)

        #expect(dismissed)
        #expect(coordinator.count == 2)
        #expect(coordinator.presentations[0].id == id1)
        #expect(coordinator.presentations[1].id == id3)
    }

    @Test func dismissNonExistentPresentation() {
        let coordinator = PresentationCoordinator()

        coordinator.present(type: .sheet, content: AnyView(Text("Content")))

        let randomId = UUID()
        let dismissed = coordinator.dismiss(randomId)

        #expect(!dismissed)
        #expect(coordinator.count == 1)
    }

    @Test func dismissAll() {
        let coordinator = PresentationCoordinator()

        coordinator.present(type: .sheet, content: AnyView(Text("First")))
        coordinator.present(type: .alert, content: AnyView(Text("Second")))
        coordinator.present(type: .popover(anchor: .default, edge: .top), content: AnyView(Text("Third")))

        #expect(coordinator.count == 3)

        coordinator.dismissAll()

        #expect(coordinator.count == 0)
        #expect(coordinator.presentations.count == 0)
        #expect(coordinator.topPresentation() == nil)
    }

    @Test func dismissAllWhenEmpty() {
        let coordinator = PresentationCoordinator()

        #expect(coordinator.count == 0)

        // Should not crash
        coordinator.dismissAll()

        #expect(coordinator.count == 0)
    }

    // MARK: - Callback Tests

    @Test func onDismissCallback() {
        let coordinator = PresentationCoordinator()
        var callbackCount = 0

        let id = coordinator.present(
            type: .sheet,
            content: AnyView(Text("Content")),
            onDismiss: { callbackCount += 1 }
        )

        #expect(callbackCount == 0)

        coordinator.dismiss(id)

        #expect(callbackCount == 1)
    }

    @Test func onDismissCallbackWithDismissAll() {
        let coordinator = PresentationCoordinator()
        var callback1Count = 0
        var callback2Count = 0
        var callback3Count = 0

        coordinator.present(
            type: .sheet,
            content: AnyView(Text("First")),
            onDismiss: { callback1Count += 1 }
        )
        coordinator.present(
            type: .alert,
            content: AnyView(Text("Second")),
            onDismiss: { callback2Count += 1 }
        )
        coordinator.present(
            type: .popover(anchor: .default, edge: .top),
            content: AnyView(Text("Third")),
            onDismiss: { callback3Count += 1 }
        )

        #expect(callback1Count == 0)
        #expect(callback2Count == 0)
        #expect(callback3Count == 0)

        coordinator.dismissAll()

        // All callbacks should be called once
        #expect(callback1Count == 1)
        #expect(callback2Count == 1)
        #expect(callback3Count == 1)
    }

    @Test func callbackNotCalledOnPresent() {
        let coordinator = PresentationCoordinator()
        var callbackCount = 0

        coordinator.present(
            type: .sheet,
            content: AnyView(Text("Content")),
            onDismiss: { callbackCount += 1 }
        )

        // Callback should not be called on present
        #expect(callbackCount == 0)
    }

    @Test func nilCallback() {
        let coordinator = PresentationCoordinator()

        // Should not crash with nil callback
        let id = coordinator.present(type: .sheet, content: AnyView(Text("Content")))

        coordinator.dismiss(id)

        // If we get here without crashing, test passes
        #expect(coordinator.count == 0)
    }

    @Test func multipleDismissCallbacks() {
        let coordinator = PresentationCoordinator()
        var dismissOrder: [Int] = []

        let id1 = coordinator.present(
            type: .sheet,
            content: AnyView(Text("First")),
            onDismiss: { dismissOrder.append(1) }
        )
        let id2 = coordinator.present(
            type: .alert,
            content: AnyView(Text("Second")),
            onDismiss: { dismissOrder.append(2) }
        )
        let id3 = coordinator.present(
            type: .popover(anchor: .default, edge: .top),
            content: AnyView(Text("Third")),
            onDismiss: { dismissOrder.append(3) }
        )

        // Dismiss in specific order
        coordinator.dismiss(id2)
        coordinator.dismiss(id1)
        coordinator.dismiss(id3)

        #expect(dismissOrder == [2, 1, 3])
    }

    // MARK: - PresentationType Tests

    @Test func presentationTypeEquality() {
        #expect(PresentationType.sheet == .sheet)
        #expect(PresentationType.alert == .alert)
        #expect(PresentationType.fullScreenCover == .fullScreenCover)
        #expect(PresentationType.confirmationDialog == .confirmationDialog)
        #expect(PresentationType.popover(anchor: .default, edge: .top) == .popover(anchor: .default, edge: .top))

        #expect(PresentationType.sheet != .alert)
        #expect(PresentationType.alert != .popover(anchor: .default, edge: .top))
    }

    // MARK: - PresentationEntry Tests

    @Test func presentationEntryIdentifiable() {
        let entry = PresentationEntry(
            type: .sheet,
            content: AnyView(Text("Content")),
            zIndex: 1000
        )

        // Should have a unique ID
        #expect(entry.id != nil)
    }

    @Test func presentationEntryCustomId() {
        let customId = UUID()
        let entry = PresentationEntry(
            id: customId,
            type: .sheet,
            content: AnyView(Text("Content")),
            zIndex: 1000
        )

        #expect(entry.id == customId)
    }

    @Test func presentationEntryProperties() {
        let id = UUID()
        let content = AnyView(Text("Test"))
        var callbackCalled = false
        let callback: @MainActor @Sendable () -> Void = { @MainActor in callbackCalled = true }

        let entry = PresentationEntry(
            id: id,
            type: .alert,
            content: content,
            zIndex: 1020,
            onDismiss: callback
        )

        #expect(entry.id == id)
        #expect(entry.type == .alert)
        #expect(entry.zIndex == 1020)

        // Call the callback
        entry.onDismiss?()
        #expect(callbackCalled)
    }

    // MARK: - Memory and Performance Tests

    @Test func largeNumberOfPresentations() {
        let coordinator = PresentationCoordinator()

        // Present 100 items
        for i in 0..<100 {
            coordinator.present(type: .sheet, content: AnyView(Text("Item \(i)")))
        }

        #expect(coordinator.count == 100)

        coordinator.dismissAll()

        #expect(coordinator.count == 0)
    }

    @Test func rapidPresentAndDismiss() {
        let coordinator = PresentationCoordinator()
        var ids: [UUID] = []

        // Rapid present
        for i in 0..<50 {
            let id = coordinator.present(type: .sheet, content: AnyView(Text("Item \(i)")))
            ids.append(id)
        }

        #expect(coordinator.count == 50)

        // Rapid dismiss
        for id in ids {
            coordinator.dismiss(id)
        }

        #expect(coordinator.count == 0)
    }

    @Test func callbackMemoryManagement() {
        let coordinator = PresentationCoordinator()
        var callbackCount = 0

        // Create a presentation with a callback that captures a local variable
        do {
            var localValue = 42
            let id = coordinator.present(
                type: .sheet,
                content: AnyView(Text("Content")),
                onDismiss: {
                    callbackCount += 1
                    _ = localValue // Capture localValue
                }
            )

            coordinator.dismiss(id)
        }

        // Callback should have been called even though localValue is out of scope
        #expect(callbackCount == 1)
    }

    // MARK: - Sendable Conformance Tests

    @Test func coordinatorSendable() {
        // PresentationCoordinator should be Sendable
        #expect(PresentationCoordinator.self is any Sendable.Type)
    }

    @Test func presentationEntrySendable() {
        // PresentationEntry should be Sendable
        #expect(PresentationEntry.self is any Sendable.Type)
    }

    @Test func presentationTypeSendable() {
        // PresentationType should be Sendable
        #expect(PresentationType.self is any Sendable.Type)
    }

    // MARK: - Edge Cases

    @Test func emptyStack() {
        let coordinator = PresentationCoordinator()

        #expect(coordinator.topPresentation() == nil)
        #expect(coordinator.count == 0)
        #expect(coordinator.presentations.isEmpty)
    }

    @Test func dismissFromEmptyStack() {
        let coordinator = PresentationCoordinator()

        let dismissed = coordinator.dismiss(UUID())

        #expect(!dismissed)
    }

    @Test func presentAfterDismissAll() {
        let coordinator = PresentationCoordinator()

        // Present some items
        coordinator.present(type: .sheet, content: AnyView(Text("First")))
        coordinator.present(type: .alert, content: AnyView(Text("Second")))

        // Dismiss all
        coordinator.dismissAll()

        #expect(coordinator.count == 0)

        // Present new item - should work fine
        let id = coordinator.present(type: .popover(anchor: .default, edge: .top), content: AnyView(Text("New")))

        #expect(coordinator.count == 1)
        #expect(coordinator.topPresentation()?.id == id)
        #expect(coordinator.topPresentation()?.zIndex == 1000) // Back to base z-index
    }
}
