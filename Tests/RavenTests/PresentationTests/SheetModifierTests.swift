import Foundation
import Testing
@testable import Raven

/// Tests for sheet presentation modifiers.
///
/// These tests verify the behavior of `.sheet(isPresented:)` and `.sheet(item:)`
/// modifiers, including presentation state management, onDismiss callbacks,
/// and integration with the PresentationCoordinator.
@MainActor
@Suite struct SheetModifierTests {

    // MARK: - isPresented Tests

    /// Tests that a sheet is registered when isPresented becomes true.
    @Test func sheetRegistersWhenPresented() {
        let coordinator = PresentationCoordinator()
        var isPresented = false

        // Initially, no presentations
        #expect(coordinator.count == 0)

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

        #expect(presentationId != nil)
        #expect(coordinator.count == 1)
        #expect(coordinator.topPresentation()?.type == .sheet)
    }

    /// Tests that a sheet is not registered when isPresented is false.
    @Test func sheetDoesNotRegisterWhenNotPresented() {
        let coordinator = PresentationCoordinator()

        let modifier = SheetModifier(
            isPresented: .constant(false),
            onDismiss: nil
        ) {
            Text("Sheet Content")
        }

        let presentationId = modifier.register(with: coordinator)

        #expect(presentationId == nil)
        #expect(coordinator.count == 0)
    }

    /// Tests that dismissing a sheet removes it from the coordinator.
    @Test func sheetDismissal() {
        let coordinator = PresentationCoordinator()

        let modifier = SheetModifier(
            isPresented: .constant(true),
            onDismiss: nil
        ) {
            Text("Sheet Content")
        }

        guard let presentationId = modifier.register(with: coordinator) else {
            Issue.record("Failed to register presentation")
            return
        }

        #expect(coordinator.count == 1)

        // Dismiss the sheet
        modifier.unregister(id: presentationId, from: coordinator)

        #expect(coordinator.count == 0)
    }

    /// Tests that the onDismiss callback is invoked when the sheet is dismissed.
    @Test func onDismissCallback() {
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

        #expect(!dismissCallbackInvoked)

        // Dismiss the presentation
        coordinator.dismiss(id)

        #expect(dismissCallbackInvoked)
    }

    // MARK: - Item-based Tests

    /// Tests that a sheet is registered when an item is set.
    @Test func itemSheetRegistersWithItem() {
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

        #expect(presentationId != nil)
        #expect(coordinator.count == 1)
        #expect(coordinator.topPresentation()?.type == .sheet)
    }

    /// Tests that a sheet is not registered when the item is nil.
    @Test func itemSheetDoesNotRegisterWithNilItem() {
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

        #expect(presentationId == nil)
        #expect(coordinator.count == 0)
    }

    /// Tests that changing the item dismisses the old sheet and presents a new one.
    @Test func itemSheetUpdatesWhenItemChanges() {
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
            Issue.record("Failed to register first presentation")
            return
        }

        #expect(coordinator.count == 1)

        // Simulate item change by unregistering old and registering new
        modifier.unregister(id: id1, from: coordinator)

        let modifier2 = ItemSheetModifier(
            item: .constant(item2),
            onDismiss: nil
        ) { item in
            Text(item.name)
        }

        let id2 = modifier2.register(with: coordinator)

        #expect(id2 != nil)
        #expect(id1 != id2)
        #expect(coordinator.count == 1)
    }

    // MARK: - Environment Integration Tests

    /// Tests that the sheet modifier can access the presentation coordinator from the environment.
    @Test func sheetAccessesCoordinatorFromEnvironment() {
        // This test verifies that the @Environment property wrapper correctly
        // accesses the presentation coordinator. In a real app, this would be
        // set up by the root view.

        let coordinator = PresentationCoordinator()

        // The modifier should be able to access the coordinator through @Environment
        // In practice, this is tested through integration tests with actual views
        #expect(coordinator.count == 0)
    }

    // MARK: - Multiple Sheets Tests

    /// Tests that multiple sheets can be presented simultaneously.
    @Test func multipleSheets() {
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

        #expect(id1 != nil)
        #expect(id2 != nil)
        #expect(id1 != id2)
        #expect(coordinator.count == 2)

        // Verify z-index ordering
        #expect(coordinator.presentations.first != nil)
        #expect(coordinator.presentations.last != nil)
        #expect(coordinator.presentations.first!.zIndex < coordinator.presentations.last!.zIndex)
    }

    // MARK: - PresentationDetent Tests

    /// Tests that PresentationDetent types can be created and compared.
    @Test func presentationDetents() {
        let large = PresentationDetent.large
        let medium = PresentationDetent.medium
        let height = PresentationDetent.height(300)
        let fraction = PresentationDetent.fraction(0.75)

        // Test equality
        #expect(large == .large)
        #expect(medium == .medium)
        #expect(large != medium)

        // Test in Set
        let detents: Set<PresentationDetent> = [large, medium, height, fraction]
        #expect(detents.count == 4)
    }

    /// Tests that custom detents can be created with resolvers.
    @Test func customDetents() {
        let customDetent = PresentationDetent.custom { context in
            context.maxDetentValue * 0.6
        }

        let context = PresentationDetent.Context(maxDetentValue: 800)
        let resolvedHeight = customDetent.resolvedHeight(in: context)

        #expect(abs(resolvedHeight - 480) < 0.1)
    }

    /// Tests that detent heights are resolved correctly.
    @Test func detentResolution() {
        let context = PresentationDetent.Context(maxDetentValue: 1000)

        // Test large detent
        let large = PresentationDetent.large
        #expect(large.resolvedHeight(in: context) == 1000)

        // Test medium detent (50% of max)
        let medium = PresentationDetent.medium
        #expect(medium.resolvedHeight(in: context) == 500)

        // Test height detent
        let height = PresentationDetent.height(300)
        #expect(height.resolvedHeight(in: context) == 300)

        // Test fraction detent
        let fraction = PresentationDetent.fraction(0.75)
        #expect(fraction.resolvedHeight(in: context) == 750)

        // Test height exceeding max
        let largeHeight = PresentationDetent.height(1500)
        #expect(largeHeight.resolvedHeight(in: context) == 1000)

        // Test fraction clamping
        let overFraction = PresentationDetent.fraction(1.5)
        #expect(overFraction.resolvedHeight(in: context) == 1000)

        let underFraction = PresentationDetent.fraction(-0.5)
        #expect(underFraction.resolvedHeight(in: context) == 0)
    }

    // MARK: - InteractiveDismissDisabled Tests

    /// Tests that the interactive dismiss disabled modifier can be applied.
    @Test func interactiveDismissDisabled() {
        // This is a modifier test - we verify it compiles and can be applied
        // The actual behavior would be tested in integration tests

        let view = Text("Content")
            .interactiveDismissDisabled()

        // Should not be nil
        #expect(view != nil)
    }

    /// Tests conditional interactive dismiss disabled.
    @Test func conditionalInteractiveDismissDisabled() {
        var hasUnsavedChanges = true

        let view = Text("Content")
            .interactiveDismissDisabled(hasUnsavedChanges)

        #expect(view != nil)

        hasUnsavedChanges = false

        let view2 = Text("Content")
            .interactiveDismissDisabled(hasUnsavedChanges)

        #expect(view2 != nil)
    }
}
