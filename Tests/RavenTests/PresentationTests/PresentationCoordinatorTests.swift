import XCTest
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
final class PresentationCoordinatorTests: XCTestCase {

    // MARK: - Basic Initialization

    func testCoordinatorInitialization() {
        let coordinator = PresentationCoordinator()
        XCTAssertEqual(coordinator.presentations.count, 0)
        XCTAssertEqual(coordinator.count, 0)
        XCTAssertNil(coordinator.topPresentation())
    }

    // MARK: - Single Presentation Tests

    func testPresentSingleSheet() {
        let coordinator = PresentationCoordinator()
        let content = AnyView(Text("Sheet Content"))

        let id = coordinator.present(type: .sheet, content: content)

        XCTAssertEqual(coordinator.count, 1)
        XCTAssertEqual(coordinator.presentations.count, 1)

        let entry = coordinator.presentations.first
        XCTAssertNotNil(entry)
        XCTAssertEqual(entry?.id, id)
        XCTAssertEqual(entry?.type, .sheet)
        XCTAssertEqual(entry?.zIndex, 1000) // Base z-index
    }

    func testPresentSingleAlert() {
        let coordinator = PresentationCoordinator()
        let content = AnyView(Text("Alert Content"))

        let id = coordinator.present(type: .alert, content: content)

        XCTAssertEqual(coordinator.count, 1)

        let entry = coordinator.presentations.first
        XCTAssertEqual(entry?.type, .alert)
        XCTAssertEqual(entry?.id, id)
    }

    func testPresentFullScreenCover() {
        let coordinator = PresentationCoordinator()
        let content = AnyView(Text("Full Screen Content"))

        coordinator.present(type: .fullScreenCover, content: content)

        XCTAssertEqual(coordinator.count, 1)
        XCTAssertEqual(coordinator.presentations.first?.type, .fullScreenCover)
    }

    func testPresentConfirmationDialog() {
        let coordinator = PresentationCoordinator()
        let content = AnyView(Text("Dialog Content"))

        coordinator.present(type: .confirmationDialog, content: content)

        XCTAssertEqual(coordinator.count, 1)
        XCTAssertEqual(coordinator.presentations.first?.type, .confirmationDialog)
    }

    func testPresentPopover() {
        let coordinator = PresentationCoordinator()
        let content = AnyView(Text("Popover Content"))

        coordinator.present(type: .popover(anchor: .rect(.bounds), edge: .top), content: content)

        XCTAssertEqual(coordinator.count, 1)
        if case .popover = coordinator.presentations.first?.type {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected popover presentation type")
        }
    }

    // MARK: - Stack Management Tests

    func testMultiplePresentations() {
        let coordinator = PresentationCoordinator()

        let id1 = coordinator.present(type: .sheet, content: AnyView(Text("First")))
        let id2 = coordinator.present(type: .alert, content: AnyView(Text("Second")))
        let id3 = coordinator.present(type: .popover(anchor: .rect(.bounds), edge: .top), content: AnyView(Text("Third")))

        XCTAssertEqual(coordinator.count, 3)
        XCTAssertEqual(coordinator.presentations[0].id, id1)
        XCTAssertEqual(coordinator.presentations[1].id, id2)
        XCTAssertEqual(coordinator.presentations[2].id, id3)
    }

    func testTopPresentation() {
        let coordinator = PresentationCoordinator()

        XCTAssertNil(coordinator.topPresentation())

        let id1 = coordinator.present(type: .sheet, content: AnyView(Text("First")))
        XCTAssertEqual(coordinator.topPresentation()?.id, id1)

        let id2 = coordinator.present(type: .alert, content: AnyView(Text("Second")))
        XCTAssertEqual(coordinator.topPresentation()?.id, id2)

        let id3 = coordinator.present(type: .popover(anchor: .rect(.bounds), edge: .top), content: AnyView(Text("Third")))
        XCTAssertEqual(coordinator.topPresentation()?.id, id3)
    }

    func testPresentationOrder() {
        let coordinator = PresentationCoordinator()

        let id1 = coordinator.present(type: .sheet, content: AnyView(Text("First")))
        let id2 = coordinator.present(type: .alert, content: AnyView(Text("Second")))
        let id3 = coordinator.present(type: .fullScreenCover, content: AnyView(Text("Third")))

        // Verify order: first presentation is at index 0, last is at the end
        XCTAssertEqual(coordinator.presentations[0].id, id1)
        XCTAssertEqual(coordinator.presentations[1].id, id2)
        XCTAssertEqual(coordinator.presentations[2].id, id3)
    }

    // MARK: - Z-Index Tests

    func testZIndexAllocation() {
        let coordinator = PresentationCoordinator()

        let id1 = coordinator.present(type: .sheet, content: AnyView(Text("First")))
        let id2 = coordinator.present(type: .alert, content: AnyView(Text("Second")))
        let id3 = coordinator.present(type: .popover(anchor: .rect(.bounds), edge: .top), content: AnyView(Text("Third")))

        // First presentation: base z-index (1000)
        XCTAssertEqual(coordinator.presentations[0].zIndex, 1000)

        // Second presentation: base + 1 * increment (1010)
        XCTAssertEqual(coordinator.presentations[1].zIndex, 1010)

        // Third presentation: base + 2 * increment (1020)
        XCTAssertEqual(coordinator.presentations[2].zIndex, 1020)
    }

    func testZIndexAfterDismiss() {
        let coordinator = PresentationCoordinator()

        let id1 = coordinator.present(type: .sheet, content: AnyView(Text("First")))
        let id2 = coordinator.present(type: .alert, content: AnyView(Text("Second")))

        XCTAssertEqual(coordinator.presentations[0].zIndex, 1000)
        XCTAssertEqual(coordinator.presentations[1].zIndex, 1010)

        // Dismiss the first one
        coordinator.dismiss(id1)

        // Add a new presentation - should get z-index based on current count (1)
        let id3 = coordinator.present(type: .popover(anchor: .rect(.bounds), edge: .top), content: AnyView(Text("Third")))

        XCTAssertEqual(coordinator.presentations[0].zIndex, 1010) // id2
        XCTAssertEqual(coordinator.presentations[1].zIndex, 1010) // id3 (count was 1 when created)
    }

    func testZIndexUniqueness() {
        let coordinator = PresentationCoordinator()

        // Present 5 items
        for i in 0..<5 {
            coordinator.present(type: .sheet, content: AnyView(Text("Item \(i)")))
        }

        // Verify each has a unique z-index
        let zIndices = coordinator.presentations.map { $0.zIndex }
        let uniqueZIndices = Set(zIndices)

        XCTAssertEqual(zIndices.count, uniqueZIndices.count)
    }

    // MARK: - Dismiss Tests

    func testDismissSinglePresentation() {
        let coordinator = PresentationCoordinator()
        let id = coordinator.present(type: .sheet, content: AnyView(Text("Content")))

        XCTAssertEqual(coordinator.count, 1)

        let dismissed = coordinator.dismiss(id)

        XCTAssertTrue(dismissed)
        XCTAssertEqual(coordinator.count, 0)
        XCTAssertNil(coordinator.topPresentation())
    }

    func testDismissMiddlePresentation() {
        let coordinator = PresentationCoordinator()

        let id1 = coordinator.present(type: .sheet, content: AnyView(Text("First")))
        let id2 = coordinator.present(type: .alert, content: AnyView(Text("Second")))
        let id3 = coordinator.present(type: .popover(anchor: .rect(.bounds), edge: .top), content: AnyView(Text("Third")))

        XCTAssertEqual(coordinator.count, 3)

        // Dismiss the middle one
        let dismissed = coordinator.dismiss(id2)

        XCTAssertTrue(dismissed)
        XCTAssertEqual(coordinator.count, 2)
        XCTAssertEqual(coordinator.presentations[0].id, id1)
        XCTAssertEqual(coordinator.presentations[1].id, id3)
    }

    func testDismissNonExistentPresentation() {
        let coordinator = PresentationCoordinator()

        coordinator.present(type: .sheet, content: AnyView(Text("Content")))

        let randomId = UUID()
        let dismissed = coordinator.dismiss(randomId)

        XCTAssertFalse(dismissed)
        XCTAssertEqual(coordinator.count, 1)
    }

    func testDismissAll() {
        let coordinator = PresentationCoordinator()

        coordinator.present(type: .sheet, content: AnyView(Text("First")))
        coordinator.present(type: .alert, content: AnyView(Text("Second")))
        coordinator.present(type: .popover(anchor: .default, edge: .top), content: AnyView(Text("Third")))

        XCTAssertEqual(coordinator.count, 3)

        coordinator.dismissAll()

        XCTAssertEqual(coordinator.count, 0)
        XCTAssertEqual(coordinator.presentations.count, 0)
        XCTAssertNil(coordinator.topPresentation())
    }

    func testDismissAllWhenEmpty() {
        let coordinator = PresentationCoordinator()

        XCTAssertEqual(coordinator.count, 0)

        // Should not crash
        coordinator.dismissAll()

        XCTAssertEqual(coordinator.count, 0)
    }

    // MARK: - Callback Tests

    func testOnDismissCallback() {
        let coordinator = PresentationCoordinator()
        var callbackCount = 0

        let id = coordinator.present(
            type: .sheet,
            content: AnyView(Text("Content")),
            onDismiss: { callbackCount += 1 }
        )

        XCTAssertEqual(callbackCount, 0)

        coordinator.dismiss(id)

        XCTAssertEqual(callbackCount, 1)
    }

    func testOnDismissCallbackWithDismissAll() {
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

        XCTAssertEqual(callback1Count, 0)
        XCTAssertEqual(callback2Count, 0)
        XCTAssertEqual(callback3Count, 0)

        coordinator.dismissAll()

        // All callbacks should be called once
        XCTAssertEqual(callback1Count, 1)
        XCTAssertEqual(callback2Count, 1)
        XCTAssertEqual(callback3Count, 1)
    }

    func testCallbackNotCalledOnPresent() {
        let coordinator = PresentationCoordinator()
        var callbackCount = 0

        coordinator.present(
            type: .sheet,
            content: AnyView(Text("Content")),
            onDismiss: { callbackCount += 1 }
        )

        // Callback should not be called on present
        XCTAssertEqual(callbackCount, 0)
    }

    func testNilCallback() {
        let coordinator = PresentationCoordinator()

        // Should not crash with nil callback
        let id = coordinator.present(type: .sheet, content: AnyView(Text("Content")))

        coordinator.dismiss(id)

        // If we get here without crashing, test passes
        XCTAssertEqual(coordinator.count, 0)
    }

    func testMultipleDismissCallbacks() {
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

        XCTAssertEqual(dismissOrder, [2, 1, 3])
    }

    // MARK: - PresentationType Tests

    func testPresentationTypeEquality() {
        XCTAssertEqual(PresentationType.sheet, .sheet)
        XCTAssertEqual(PresentationType.alert, .alert)
        XCTAssertEqual(PresentationType.fullScreenCover, .fullScreenCover)
        XCTAssertEqual(PresentationType.confirmationDialog, .confirmationDialog)
        XCTAssertEqual(PresentationType.popover(anchor: .default, edge: .top), .popover(anchor: .default, edge: .top))

        XCTAssertNotEqual(PresentationType.sheet, .alert)
        XCTAssertNotEqual(PresentationType.alert, .popover(anchor: .default, edge: .top))
    }

    // MARK: - PresentationEntry Tests

    func testPresentationEntryIdentifiable() {
        let entry = PresentationEntry(
            type: .sheet,
            content: AnyView(Text("Content")),
            zIndex: 1000
        )

        // Should have a unique ID
        XCTAssertNotNil(entry.id)
    }

    func testPresentationEntryCustomId() {
        let customId = UUID()
        let entry = PresentationEntry(
            id: customId,
            type: .sheet,
            content: AnyView(Text("Content")),
            zIndex: 1000
        )

        XCTAssertEqual(entry.id, customId)
    }

    func testPresentationEntryProperties() {
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

        XCTAssertEqual(entry.id, id)
        XCTAssertEqual(entry.type, .alert)
        XCTAssertEqual(entry.zIndex, 1020)

        // Call the callback
        entry.onDismiss?()
        XCTAssertTrue(callbackCalled)
    }

    // MARK: - Memory and Performance Tests

    func testLargeNumberOfPresentations() {
        let coordinator = PresentationCoordinator()

        // Present 100 items
        for i in 0..<100 {
            coordinator.present(type: .sheet, content: AnyView(Text("Item \(i)")))
        }

        XCTAssertEqual(coordinator.count, 100)

        coordinator.dismissAll()

        XCTAssertEqual(coordinator.count, 0)
    }

    func testRapidPresentAndDismiss() {
        let coordinator = PresentationCoordinator()
        var ids: [UUID] = []

        // Rapid present
        for i in 0..<50 {
            let id = coordinator.present(type: .sheet, content: AnyView(Text("Item \(i)")))
            ids.append(id)
        }

        XCTAssertEqual(coordinator.count, 50)

        // Rapid dismiss
        for id in ids {
            coordinator.dismiss(id)
        }

        XCTAssertEqual(coordinator.count, 0)
    }

    func testCallbackMemoryManagement() {
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
        XCTAssertEqual(callbackCount, 1)
    }

    // MARK: - Sendable Conformance Tests

    func testCoordinatorSendable() {
        // PresentationCoordinator should be Sendable
        XCTAssert(PresentationCoordinator.self is any Sendable.Type)
    }

    func testPresentationEntrySendable() {
        // PresentationEntry should be Sendable
        XCTAssert(PresentationEntry.self is any Sendable.Type)
    }

    func testPresentationTypeSendable() {
        // PresentationType should be Sendable
        XCTAssert(PresentationType.self is any Sendable.Type)
    }

    // MARK: - Edge Cases

    func testEmptyStack() {
        let coordinator = PresentationCoordinator()

        XCTAssertNil(coordinator.topPresentation())
        XCTAssertEqual(coordinator.count, 0)
        XCTAssertTrue(coordinator.presentations.isEmpty)
    }

    func testDismissFromEmptyStack() {
        let coordinator = PresentationCoordinator()

        let dismissed = coordinator.dismiss(UUID())

        XCTAssertFalse(dismissed)
    }

    func testPresentAfterDismissAll() {
        let coordinator = PresentationCoordinator()

        // Present some items
        coordinator.present(type: .sheet, content: AnyView(Text("First")))
        coordinator.present(type: .alert, content: AnyView(Text("Second")))

        // Dismiss all
        coordinator.dismissAll()

        XCTAssertEqual(coordinator.count, 0)

        // Present new item - should work fine
        let id = coordinator.present(type: .popover(anchor: .default, edge: .top), content: AnyView(Text("New")))

        XCTAssertEqual(coordinator.count, 1)
        XCTAssertEqual(coordinator.topPresentation()?.id, id)
        XCTAssertEqual(coordinator.topPresentation()?.zIndex, 1000) // Back to base z-index
    }
}
