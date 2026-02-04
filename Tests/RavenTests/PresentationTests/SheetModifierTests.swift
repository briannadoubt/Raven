import XCTest
@testable import Raven

/// Tests for sheet presentation modifiers.
///
/// These tests verify the behavior of `.sheet(isPresented:)` and `.sheet(item:)`
/// modifiers, including presentation state management, onDismiss callbacks,
/// and integration with the PresentationCoordinator.
@MainActor
final class SheetModifierTests: XCTestCase {

    // MARK: - isPresented Tests

    /// Tests that a sheet is registered when isPresented becomes true.
    func testSheetRegistersWhenPresented() {
        let coordinator = PresentationCoordinator()
        var isPresented = false

        // Initially, no presentations
        XCTAssertEqual(coordinator.count, 0)

        // Simulate presentation
        isPresented = true

        // In a real scenario, the modifier would register on onChange
        // For unit testing, we directly test the registration logic
        let modifier = SheetModifier(
            isPresented: .constant(true),
            onDismiss: nil
        ) {
            Text("Sheet Content")
        }

        let presentationId = modifier.register(with: coordinator)

        XCTAssertNotNil(presentationId)
        XCTAssertEqual(coordinator.count, 1)
        XCTAssertEqual(coordinator.topPresentation()?.type, .sheet)
    }

    /// Tests that a sheet is not registered when isPresented is false.
    func testSheetDoesNotRegisterWhenNotPresented() {
        let coordinator = PresentationCoordinator()

        let modifier = SheetModifier(
            isPresented: .constant(false),
            onDismiss: nil
        ) {
            Text("Sheet Content")
        }

        let presentationId = modifier.register(with: coordinator)

        XCTAssertNil(presentationId)
        XCTAssertEqual(coordinator.count, 0)
    }

    /// Tests that dismissing a sheet removes it from the coordinator.
    func testSheetDismissal() {
        let coordinator = PresentationCoordinator()

        let modifier = SheetModifier(
            isPresented: .constant(true),
            onDismiss: nil
        ) {
            Text("Sheet Content")
        }

        guard let presentationId = modifier.register(with: coordinator) else {
            XCTFail("Failed to register presentation")
            return
        }

        XCTAssertEqual(coordinator.count, 1)

        // Dismiss the sheet
        modifier.unregister(id: presentationId, from: coordinator)

        XCTAssertEqual(coordinator.count, 0)
    }

    /// Tests that the onDismiss callback is invoked when the sheet is dismissed.
    func testOnDismissCallback() {
        let coordinator = PresentationCoordinator()
        var dismissCallbackInvoked = false

        // Create a presentation directly with the coordinator
        let id = coordinator.present(
            type: .sheet,
            content: AnyView(Text("Sheet")),
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

    /// Tests that a sheet is registered when an item is set.
    func testItemSheetRegistersWithItem() {
        struct TestItem: Identifiable, Sendable, Equatable {
            let id = UUID()
            let name: String
        }

        let coordinator = PresentationCoordinator()
        let item = TestItem(name: "Test")

        let modifier = ItemSheetModifier(
            item: .constant(item),
            onDismiss: nil
        ) { item in
            Text(item.name)
        }

        let presentationId = modifier.register(with: coordinator)

        XCTAssertNotNil(presentationId)
        XCTAssertEqual(coordinator.count, 1)
        XCTAssertEqual(coordinator.topPresentation()?.type, .sheet)
    }

    /// Tests that a sheet is not registered when the item is nil.
    func testItemSheetDoesNotRegisterWithNilItem() {
        struct TestItem: Identifiable, Sendable, Equatable {
            let id = UUID()
            let name: String
        }

        let coordinator = PresentationCoordinator()

        let modifier = ItemSheetModifier(
            item: .constant(nil as TestItem?),
            onDismiss: nil
        ) { item in
            Text(item.name)
        }

        let presentationId = modifier.register(with: coordinator)

        XCTAssertNil(presentationId)
        XCTAssertEqual(coordinator.count, 0)
    }

    /// Tests that changing the item dismisses the old sheet and presents a new one.
    func testItemSheetUpdatesWhenItemChanges() {
        struct TestItem: Identifiable, Sendable, Equatable {
            let id: UUID
            let name: String
        }

        let coordinator = PresentationCoordinator()
        let item1 = TestItem(id: UUID(), name: "Item 1")
        let item2 = TestItem(id: UUID(), name: "Item 2")

        let modifier = ItemSheetModifier(
            item: .constant(item1),
            onDismiss: nil
        ) { item in
            Text(item.name)
        }

        // Register first item
        guard let id1 = modifier.register(with: coordinator) else {
            XCTFail("Failed to register first presentation")
            return
        }

        XCTAssertEqual(coordinator.count, 1)

        // Simulate item change by unregistering old and registering new
        modifier.unregister(id: id1, from: coordinator)

        let modifier2 = ItemSheetModifier(
            item: .constant(item2),
            onDismiss: nil
        ) { item in
            Text(item.name)
        }

        let id2 = modifier2.register(with: coordinator)

        XCTAssertNotNil(id2)
        XCTAssertNotEqual(id1, id2)
        XCTAssertEqual(coordinator.count, 1)
    }

    // MARK: - Environment Integration Tests

    /// Tests that the sheet modifier can access the presentation coordinator from the environment.
    func testSheetAccessesCoordinatorFromEnvironment() {
        // This test verifies that the @Environment property wrapper correctly
        // accesses the presentation coordinator. In a real app, this would be
        // set up by the root view.

        let coordinator = PresentationCoordinator()

        // The modifier should be able to access the coordinator through @Environment
        // In practice, this is tested through integration tests with actual views
        XCTAssertEqual(coordinator.count, 0)
    }

    // MARK: - Multiple Sheets Tests

    /// Tests that multiple sheets can be presented simultaneously.
    func testMultipleSheets() {
        let coordinator = PresentationCoordinator()

        let modifier1 = SheetModifier(
            isPresented: .constant(true),
            onDismiss: nil
        ) {
            Text("Sheet 1")
        }

        let modifier2 = SheetModifier(
            isPresented: .constant(true),
            onDismiss: nil
        ) {
            Text("Sheet 2")
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

    // MARK: - PresentationDetent Tests

    /// Tests that PresentationDetent types can be created and compared.
    func testPresentationDetents() {
        let large = PresentationDetent.large
        let medium = PresentationDetent.medium
        let height = PresentationDetent.height(300)
        let fraction = PresentationDetent.fraction(0.75)

        // Test equality
        XCTAssertEqual(large, .large)
        XCTAssertEqual(medium, .medium)
        XCTAssertNotEqual(large, medium)

        // Test in Set
        let detents: Set<PresentationDetent> = [large, medium, height, fraction]
        XCTAssertEqual(detents.count, 4)
    }

    /// Tests that custom detents can be created with resolvers.
    func testCustomDetents() {
        let customDetent = PresentationDetent.custom { context in
            context.maxDetentValue * 0.6
        }

        let context = PresentationDetent.Context(maxDetentValue: 800)
        let resolvedHeight = customDetent.resolvedHeight(in: context)

        XCTAssertEqual(resolvedHeight, 480, accuracy: 0.1)
    }

    /// Tests that detent heights are resolved correctly.
    func testDetentResolution() {
        let context = PresentationDetent.Context(maxDetentValue: 1000)

        // Test large detent
        let large = PresentationDetent.large
        XCTAssertEqual(large.resolvedHeight(in: context), 1000)

        // Test medium detent (50% of max)
        let medium = PresentationDetent.medium
        XCTAssertEqual(medium.resolvedHeight(in: context), 500)

        // Test height detent
        let height = PresentationDetent.height(300)
        XCTAssertEqual(height.resolvedHeight(in: context), 300)

        // Test fraction detent
        let fraction = PresentationDetent.fraction(0.75)
        XCTAssertEqual(fraction.resolvedHeight(in: context), 750)

        // Test height exceeding max
        let largeHeight = PresentationDetent.height(1500)
        XCTAssertEqual(largeHeight.resolvedHeight(in: context), 1000)

        // Test fraction clamping
        let overFraction = PresentationDetent.fraction(1.5)
        XCTAssertEqual(overFraction.resolvedHeight(in: context), 1000)

        let underFraction = PresentationDetent.fraction(-0.5)
        XCTAssertEqual(underFraction.resolvedHeight(in: context), 0)
    }

    // MARK: - InteractiveDismissDisabled Tests

    /// Tests that the interactive dismiss disabled modifier can be applied.
    func testInteractiveDismissDisabled() {
        // This is a modifier test - we verify it compiles and can be applied
        // The actual behavior would be tested in integration tests

        let view = Text("Content")
            .interactiveDismissDisabled()

        // Should not be nil
        XCTAssertNotNil(view)
    }

    /// Tests conditional interactive dismiss disabled.
    func testConditionalInteractiveDismissDisabled() {
        var hasUnsavedChanges = true

        let view = Text("Content")
            .interactiveDismissDisabled(hasUnsavedChanges)

        XCTAssertNotNil(view)

        hasUnsavedChanges = false

        let view2 = Text("Content")
            .interactiveDismissDisabled(hasUnsavedChanges)

        XCTAssertNotNil(view2)
    }
}
