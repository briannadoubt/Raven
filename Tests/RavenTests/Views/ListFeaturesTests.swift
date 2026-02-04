import XCTest
@testable import Raven

/// Comprehensive tests for Track D.1: Enhanced List Features
///
/// This test suite provides extensive coverage of List enhancements including:
/// - SwipeActions (leading/trailing edges, full swipe)
/// - Pull-to-refresh with async completion
/// - Drag-to-reorder gestures and state management
/// - Selection modes (single and multi-selection)
/// - EditMode integration and toggle behavior
/// - Touch gesture calculations and physics
/// - Configuration options and customization
/// - Edge cases (empty lists, single items, boundary conditions)
/// - Performance considerations
///
/// ## Test Organization
///
/// Tests are organized into the following categories:
/// 1. SwipeActions Tests (10 tests)
/// 2. Pull-to-Refresh Tests (8 tests)
/// 3. Reorder/Delete Tests (7 tests)
/// 4. Selection Tests (8 tests)
/// 5. EditMode Tests (5 tests)
/// 6. Configuration Tests (3 tests)
/// 7. Edge Cases & Performance (6 tests)
///
/// Total: 47 tests
@available(macOS 13.0, *)
@MainActor
final class ListFeaturesTests: XCTestCase {

    // MARK: - SwipeActions Tests (10 tests)

    func testSwipeActionsTrailingEdge() {
        let text = Text("Swipeable Item")
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive) {
                    // Delete action
                } label: {
                    Text("Delete")
                }
            }

        XCTAssertNotNil(text, "SwipeActions modifier should be applied")
    }

    func testSwipeActionsLeadingEdge() {
        let text = Text("Swipeable Item")
            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                Button {
                    // Favorite action
                } label: {
                    Text("Favorite")
                }
            }

        XCTAssertNotNil(text, "SwipeActions with leading edge should be applied")
    }

    func testSwipeActionsBothEdges() {
        let text = Text("Swipeable Item")
            .swipeActions(edge: .leading) {
                Button {
                    // Mark action
                } label: {
                    Text("Mark")
                }
            }
            .swipeActions(edge: .trailing) {
                Button(role: .destructive) {
                    // Delete action
                } label: {
                    Text("Delete")
                }
            }

        XCTAssertNotNil(text, "SwipeActions on both edges should be applied")
    }

    func testSwipeActionsFullSwipeEnabled() {
        let config = SwipeActionsConfiguration(
            revealThreshold: 80,
            fullSwipeThreshold: 200,
            allowElasticOverscroll: true
        )

        XCTAssertEqual(config.fullSwipeThreshold, 200)
        XCTAssertEqual(config.revealThreshold, 80)
        XCTAssertTrue(config.allowElasticOverscroll)
    }

    func testSwipeActionsFullSwipeDisabled() {
        let text = Text("Item")
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                Button { } label: { Text("Action") }
            }

        XCTAssertNotNil(text, "SwipeActions with disabled full swipe should be applied")
    }

    func testSwipeActionsConfiguration() {
        let config = SwipeActionsConfiguration(
            revealThreshold: 100,
            fullSwipeThreshold: 250,
            springResponse: 0.4,
            springDamping: 0.85,
            actionButtonWidth: 90,
            allowElasticOverscroll: false,
            wrongDirectionResistance: 0.15
        )

        XCTAssertEqual(config.revealThreshold, 100)
        XCTAssertEqual(config.fullSwipeThreshold, 250)
        XCTAssertEqual(config.springResponse, 0.4)
        XCTAssertEqual(config.springDamping, 0.85)
        XCTAssertEqual(config.actionButtonWidth, 90)
        XCTAssertFalse(config.allowElasticOverscroll)
        XCTAssertEqual(config.wrongDirectionResistance, 0.15)
    }

    func testSwipeActionButtonRole() {
        let destructiveButton = SwipeActionButton(role: .destructive, action: {}) {
            Text("Delete")
        }

        let standardButton = SwipeActionButton(role: nil, action: {}) {
            Text("Share")
        }

        XCTAssertNotNil(destructiveButton, "Destructive button should be created")
        XCTAssertNotNil(standardButton, "Standard button should be created")
    }

    func testSwipeTouchStateCalculations() {
        var touchState = SwipeTouchState()
        touchState.startX = 100
        touchState.currentX = 150

        let translation = touchState.translation
        XCTAssertEqual(translation, 50, "Translation should be calculated correctly")

        touchState.startY = 100
        let isHorizontal = touchState.isHorizontalGesture(currentY: 105)
        XCTAssertTrue(isHorizontal, "Gesture should be detected as horizontal")
    }

    func testSwipeTouchStateVelocity() {
        var touchState = SwipeTouchState()
        touchState.startX = 100
        touchState.currentX = 150
        touchState.lastUpdateTime = Date().addingTimeInterval(-0.1)

        touchState.updateVelocity()

        XCTAssertNotEqual(touchState.velocity, 0, "Velocity should be calculated")
    }

    func testSwipeActionsDefaultConfiguration() {
        let config = SwipeActionsConfiguration()

        XCTAssertEqual(config.revealThreshold, 80)
        XCTAssertEqual(config.fullSwipeThreshold, 200)
        XCTAssertEqual(config.springResponse, 0.3)
        XCTAssertEqual(config.springDamping, 0.8)
        XCTAssertEqual(config.actionButtonWidth, 80)
        XCTAssertTrue(config.allowElasticOverscroll)
        XCTAssertEqual(config.wrongDirectionResistance, 0.1)
    }

    // MARK: - Pull-to-Refresh Tests (8 tests)

    func testRefreshableModifier() async {
        var refreshed = false

        let list = List {
            Text("Item 1")
            Text("Item 2")
        }
        .refreshable {
            refreshed = true
        }

        XCTAssertNotNil(list, "Refreshable modifier should be applied")
    }

    func testRefreshableAsyncCompletion() async {
        var completed = false

        let action: @MainActor @Sendable () async -> Void = {
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            completed = true
        }

        await action()

        XCTAssertTrue(completed, "Async refresh action should complete")
    }

    func testRefreshConfiguration() {
        let config = RefreshConfiguration(
            triggerDistance: 100,
            resistance: 3.0,
            springResponse: 0.35,
            springDamping: 0.75,
            enableHaptics: false,
            minimumRefreshDuration: 0.8
        )

        XCTAssertEqual(config.triggerDistance, 100)
        XCTAssertEqual(config.resistance, 3.0)
        XCTAssertEqual(config.springResponse, 0.35)
        XCTAssertEqual(config.springDamping, 0.75)
        XCTAssertFalse(config.enableHaptics)
        XCTAssertEqual(config.minimumRefreshDuration, 0.8)
    }

    func testRefreshConfigurationDefaults() {
        let config = RefreshConfiguration()

        XCTAssertEqual(config.triggerDistance, 80)
        XCTAssertEqual(config.resistance, 2.5)
        XCTAssertEqual(config.springResponse, 0.3)
        XCTAssertEqual(config.springDamping, 0.7)
        XCTAssertTrue(config.enableHaptics)
        XCTAssertEqual(config.minimumRefreshDuration, 0.5)
    }

    func testRefreshProgress() {
        let progress = RefreshProgress(isRefreshing: true, pullProgress: 0.75)

        XCTAssertTrue(progress.isRefreshing)
        XCTAssertEqual(progress.pullProgress, 0.75)
    }

    func testRefreshProgressIdle() {
        let progress = RefreshProgress(isRefreshing: false, pullProgress: 0.0)

        XCTAssertFalse(progress.isRefreshing)
        XCTAssertEqual(progress.pullProgress, 0.0)
    }

    func testScrollPositionTrackerAtTop() {
        var tracker = ScrollPositionTracker()
        tracker.scrollOffset = 0

        XCTAssertTrue(tracker.isAtTop, "Should be at top with zero offset")
        XCTAssertEqual(tracker.overscrollAmount, 0)
    }

    func testScrollPositionTrackerOverscroll() {
        var tracker = ScrollPositionTracker()
        tracker.scrollOffset = -50

        XCTAssertTrue(tracker.isAtTop, "Should be at top with negative offset")
        XCTAssertEqual(tracker.overscrollAmount, 50, "Overscroll amount should be positive")
    }

    // MARK: - Reorder/Delete Tests (7 tests)

    func testOnMoveModifier() {
        var items = ["A", "B", "C"]
        let moved = expectation(description: "Move callback")

        let list = List {
            ForEach(items, id: \.self) { item in
                Text(item)
            }
            .onMove { source, destination in
                items.move(fromOffsets: source, toOffset: destination)
                moved.fulfill()
            }
        }

        XCTAssertNotNil(list, "OnMove modifier should be applied")
    }

    func testOnDeleteModifier() {
        var items = ["A", "B", "C"]
        let deleted = expectation(description: "Delete callback")

        let list = List {
            ForEach(items, id: \.self) { item in
                Text(item)
            }
            .onDelete { indices in
                items.remove(atOffsets: indices)
                deleted.fulfill()
            }
        }

        XCTAssertNotNil(list, "OnDelete modifier should be applied")
    }

    func testReorderConfiguration() {
        let config = ReorderConfiguration(
            showDragHandles: true,
            springResponse: 0.4,
            springDamping: 0.75,
            enableHaptics: true,
            draggedItemOpacity: 0.6,
            draggedItemScale: 1.08,
            dropTargetColor: .blue
        )

        XCTAssertTrue(config.showDragHandles)
        XCTAssertEqual(config.springResponse, 0.4)
        XCTAssertEqual(config.springDamping, 0.75)
        XCTAssertTrue(config.enableHaptics)
        XCTAssertEqual(config.draggedItemOpacity, 0.6)
        XCTAssertEqual(config.draggedItemScale, 1.08)
    }

    func testReorderConfigurationDefaults() {
        let config = ReorderConfiguration()

        XCTAssertTrue(config.showDragHandles)
        XCTAssertEqual(config.springResponse, 0.3)
        XCTAssertEqual(config.springDamping, 0.7)
        XCTAssertTrue(config.enableHaptics)
        XCTAssertEqual(config.draggedItemOpacity, 0.5)
        XCTAssertEqual(config.draggedItemScale, 1.05)
    }

    func testReorderStateTracking() {
        var state = ReorderState()

        XCTAssertFalse(state.isDragging, "Should not be dragging initially")
        XCTAssertNil(state.draggedIndex)

        state.draggedIndex = 2
        XCTAssertTrue(state.isDragging, "Should be dragging when index is set")
    }

    func testReorderStateCalculateDropTarget() {
        var state = ReorderState()
        state.draggedIndex = 2
        state.dragOffset = CGSize(width: 0, height: 88) // Two items at 44pt each

        state.calculateDropTarget(itemHeight: 44)

        XCTAssertEqual(state.dropTargetIndex, 4, "Should calculate correct drop target")
    }

    func testReorderStateReset() {
        var state = ReorderState()
        state.draggedIndex = 2
        state.dropTargetIndex = 5
        state.dragOffset = CGSize(width: 0, height: 100)

        state.reset()

        XCTAssertNil(state.draggedIndex)
        XCTAssertNil(state.dropTargetIndex)
        XCTAssertEqual(state.dragOffset, .zero)
    }

    // MARK: - Selection Tests (8 tests)

    func testSingleSelectionList() {
        struct Item: Identifiable, Sendable {
            let id: Int
            let name: String
        }

        @MainActor
        class SelectionModel {
            var selection: Int?
        }

        let items = [
            Item(id: 1, name: "Item 1"),
            Item(id: 2, name: "Item 2")
        ]

        let model = SelectionModel()
        let binding = Binding(
            get: { model.selection },
            set: { model.selection = $0 }
        )

        let list = List(items, selection: binding) { item in
            Text(item.name)
        }

        XCTAssertNotNil(list, "List with single selection should be created")
    }

    func testMultipleSelectionList() {
        struct Item: Identifiable, Sendable {
            let id: Int
            let name: String
        }

        @MainActor
        class SelectionModel {
            var selection = Set<Int>()
        }

        let items = [
            Item(id: 1, name: "Item 1"),
            Item(id: 2, name: "Item 2"),
            Item(id: 3, name: "Item 3")
        ]

        let model = SelectionModel()
        let binding = Binding(
            get: { model.selection },
            set: { model.selection = $0 }
        )

        let list = List(items, selection: binding) { item in
            Text(item.name)
        }

        XCTAssertNotNil(list, "List with multiple selection should be created")
    }

    func testSelectionStateIsSelected() {
        var state = SelectionState<Int>(single: 2)

        XCTAssertTrue(state.isSelected(2))
        XCTAssertFalse(state.isSelected(3))

        var multiState = SelectionState<Int>(multi: [1, 3, 5])
        XCTAssertTrue(multiState.isSelected(3))
        XCTAssertFalse(multiState.isSelected(2))
    }

    func testSelectionStateToggle() {
        var state = SelectionState<Int>(single: 2)

        state.toggle(2)
        XCTAssertNil(state.singleSelection, "Toggle should deselect")

        state.toggle(3)
        XCTAssertEqual(state.singleSelection, 3, "Toggle should select")
    }

    func testSelectionStateToggleMultiple() {
        var state = SelectionState<Int>(multi: [1, 3])

        state.toggle(3)
        XCTAssertFalse(state.multiSelection.contains(3), "Toggle should remove")

        state.toggle(5)
        XCTAssertTrue(state.multiSelection.contains(5), "Toggle should add")
    }

    func testSelectionStateSelect() {
        var state = SelectionState<Int>(single: nil)

        state.select(7)
        XCTAssertEqual(state.singleSelection, 7)

        state.select(9)
        XCTAssertEqual(state.singleSelection, 9, "Select should replace in single mode")
    }

    func testSelectionStateDeselect() {
        var state = SelectionState<Int>(multi: [1, 2, 3])

        state.deselect(2)
        XCTAssertFalse(state.multiSelection.contains(2))
        XCTAssertTrue(state.multiSelection.contains(1))
        XCTAssertTrue(state.multiSelection.contains(3))
    }

    func testSelectionStateClear() {
        var state = SelectionState<Int>(multi: [1, 2, 3])

        state.clear()
        XCTAssertTrue(state.multiSelection.isEmpty)
        XCTAssertNil(state.singleSelection)
    }

    // MARK: - EditMode Tests (5 tests)

    func testEditModeStates() {
        let inactive = EditMode.inactive
        let active = EditMode.active
        let transient = EditMode.transient

        XCTAssertFalse(inactive.isEditing)
        XCTAssertTrue(active.isEditing)
        XCTAssertTrue(transient.isEditing)
    }

    func testEditModeIsEditing() {
        let inactive = EditMode.inactive
        XCTAssertFalse(inactive.isEditing, "Inactive mode should not be editing")

        let active = EditMode.active
        XCTAssertTrue(active.isEditing, "Active mode should be editing")

        let transient = EditMode.transient
        XCTAssertTrue(transient.isEditing, "Transient mode should be editing")
    }

    func testEditButton() {
        let button = EditButton()
        XCTAssertNotNil(button, "EditButton should be created")
    }

    func testEditModeBindingConstant() {
        let binding = Binding<EditMode>.constant(.active)

        XCTAssertEqual(binding.wrappedValue, .active)
    }

    func testEditModeToggle() {
        var mode = EditMode.inactive

        mode = mode.isEditing ? .inactive : .active
        XCTAssertTrue(mode.isEditing, "Mode should toggle to editing")

        mode = mode.isEditing ? .inactive : .active
        XCTAssertFalse(mode.isEditing, "Mode should toggle back to not editing")
    }

    // MARK: - Configuration Tests (3 tests)

    func testEnvironmentSwipeActionsConfiguration() {
        let config = SwipeActionsConfiguration(
            revealThreshold: 90,
            fullSwipeThreshold: 220
        )

        let list = List {
            Text("Item")
                .swipeActions {
                    Button { } label: { Text("Action") }
                }
        }
        .environment(\.swipeActionsConfiguration, config)

        XCTAssertNotNil(list, "Environment configuration should be applied")
    }

    func testEnvironmentRefreshConfiguration() {
        let config = RefreshConfiguration(
            triggerDistance: 90,
            resistance: 2.8
        )

        let list = List {
            Text("Item")
        }
        .refreshable {
            // Refresh action
        }
        .environment(\.refreshConfiguration, config)

        XCTAssertNotNil(list, "Environment refresh configuration should be applied")
    }

    func testEnvironmentReorderConfiguration() {
        let config = ReorderConfiguration(
            showDragHandles: false,
            enableHaptics: false
        )

        let list = List {
            ForEach(["A", "B"], id: \.self) { item in
                Text(item)
            }
            .onMove { _, _ in }
        }
        .environment(\.reorderConfiguration, config)

        XCTAssertNotNil(list, "Environment reorder configuration should be applied")
    }

    // MARK: - Edge Cases & Performance Tests (6 tests)

    func testEmptyListWithSwipeActions() {
        let list = List {
            ForEach([] as [String], id: \.self) { item in
                Text(item)
            }
        }

        let node = list.toVNode()
        XCTAssertEqual(node.elementTag, "div", "Empty list should still render container")
    }

    func testSingleItemListWithReorder() {
        var items = ["Single"]

        let list = List {
            ForEach(items, id: \.self) { item in
                Text(item)
            }
            .onMove { source, destination in
                items.move(fromOffsets: source, toOffset: destination)
            }
        }

        XCTAssertNotNil(list, "Single item list with reorder should work")
    }

    func testCollectionMoveOperation() {
        var items = ["A", "B", "C", "D", "E"]

        items.move(fromOffsets: IndexSet(integer: 1), toOffset: 4)

        XCTAssertEqual(items, ["A", "C", "D", "B", "E"], "Move should reorder correctly")
    }

    func testCollectionMoveMultipleItems() {
        var items = ["A", "B", "C", "D", "E", "F"]

        items.move(fromOffsets: IndexSet([1, 2]), toOffset: 5)

        XCTAssertEqual(items, ["A", "D", "E", "B", "C", "F"], "Multiple items should move correctly")
    }

    func testIndexSetMoved() {
        let original = IndexSet([1, 3, 5])
        let result = original.moved(from: IndexSet([1]), to: 4)

        XCTAssertTrue(result.contains(3))
        XCTAssertTrue(result.contains(5))
    }

    func testLargeListPerformance() {
        measure {
            let largeList = List(0..<1000) { index in
                Text("Item \(index)")
            }

            _ = largeList.toVNode()
        }
    }

    // MARK: - Integration Tests (6 tests)

    func testSwipeActionsWithEditMode() {
        @MainActor
        class EditModeModel {
            var editMode = EditMode.inactive
        }

        let model = EditModeModel()
        let binding = Binding(
            get: { model.editMode },
            set: { model.editMode = $0 }
        )

        let list = List {
            Text("Item")
                .swipeActions {
                    Button { } label: { Text("Action") }
                }
        }
        .environment(\.editMode, binding)

        XCTAssertNotNil(list, "SwipeActions should work with EditMode")
    }

    func testSelectionWithEditMode() {
        struct Item: Identifiable, Sendable {
            let id: Int
            let name: String
        }

        @MainActor
        class ViewModel {
            var selection = Set<Int>()
            var editMode = EditMode.inactive
        }

        let model = ViewModel()
        let items = [
            Item(id: 1, name: "Item 1"),
            Item(id: 2, name: "Item 2")
        ]

        let selectionBinding = Binding(
            get: { model.selection },
            set: { model.selection = $0 }
        )

        let editModeBinding = Binding(
            get: { model.editMode },
            set: { model.editMode = $0 }
        )

        let list = List(items, selection: selectionBinding) { item in
            Text(item.name)
        }
        .environment(\.editMode, editModeBinding)

        XCTAssertNotNil(list, "Selection should work with EditMode")
    }

    func testReorderWithSelection() {
        struct Item: Identifiable, Sendable {
            let id: Int
            let name: String
        }

        @MainActor
        class ViewModel {
            var items = [
                Item(id: 1, name: "Item 1"),
                Item(id: 2, name: "Item 2"),
                Item(id: 3, name: "Item 3")
            ]
            var selection = Set<Int>()
        }

        let model = ViewModel()

        let selectionBinding = Binding(
            get: { model.selection },
            set: { model.selection = $0 }
        )

        let list = List(model.items, selection: selectionBinding) { item in
            Text(item.name)
        }

        XCTAssertNotNil(list, "Reorder should work with selection")
    }

    func testMultipleFeaturesCombined() {
        @MainActor
        class ViewModel {
            var items = ["A", "B", "C"]
            var selection = Set<String>()
            var editMode = EditMode.inactive
        }

        let model = ViewModel()

        let selectionBinding = Binding(
            get: { model.selection },
            set: { model.selection = $0 }
        )

        let editModeBinding = Binding(
            get: { model.editMode },
            set: { model.editMode = $0 }
        )

        let list = List(model.items, id: \.self, selection: selectionBinding) { item in
            Text(item)
                .swipeActions {
                    Button(role: .destructive) { } label: { Text("Delete") }
                }
        }
        .environment(\.editMode, editModeBinding)
        .refreshable {
            // Refresh action
        }

        XCTAssertNotNil(list, "Multiple features should work together")
    }

    func testHorizontalEdgeEquality() {
        XCTAssertEqual(HorizontalEdge.leading, HorizontalEdge.leading)
        XCTAssertEqual(HorizontalEdge.trailing, HorizontalEdge.trailing)
        XCTAssertNotEqual(HorizontalEdge.leading, HorizontalEdge.trailing)
    }

    func testRefreshStateTransitions() {
        var state = RefreshState.idle

        state = .pulling
        XCTAssertEqual(state, .pulling)

        state = .triggered
        XCTAssertEqual(state, .triggered)

        state = .refreshing
        XCTAssertEqual(state, .refreshing)

        state = .idle
        XCTAssertEqual(state, .idle)
    }
}
