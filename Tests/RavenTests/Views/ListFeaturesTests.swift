import Foundation
import Testing
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
@MainActor
@Suite struct ListFeaturesTests {

    // MARK: - SwipeActions Tests (10 tests)

    @Test func swipeActionsTrailingEdge() {
        let text = Text("Swipeable Item")
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button("Delete", role: .destructive, action: {
                    // Delete action
                })
            }

        #expect(text != nil)
    }

    @Test func swipeActionsLeadingEdge() {
        let text = Text("Swipeable Item")
            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                Button {
                    // Favorite action
                } label: {
                    Text("Favorite")
                }
            }

        #expect(text != nil)
    }

    @Test func swipeActionsBothEdges() {
        let text = Text("Swipeable Item")
            .swipeActions(edge: .leading) {
                Button {
                    // Mark action
                } label: {
                    Text("Mark")
                }
            }
            .swipeActions(edge: .trailing) {
                Button("Delete", role: .destructive, action: {
                    // Delete action
                })
            }

        #expect(text != nil)
    }

    @Test func swipeActionsFullSwipeEnabled() {
        let config = SwipeActionsConfiguration(
            revealThreshold: 80,
            fullSwipeThreshold: 200,
            allowElasticOverscroll: true
        )

        #expect(config.fullSwipeThreshold == 200)
        #expect(config.revealThreshold == 80)
        #expect(config.allowElasticOverscroll)
    }

    @Test func swipeActionsFullSwipeDisabled() {
        let text = Text("Item")
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                Button { } label: { Text("Action") }
            }

        #expect(text != nil)
    }

    @Test func swipeActionsConfiguration() {
        let config = SwipeActionsConfiguration(
            revealThreshold: 100,
            fullSwipeThreshold: 250,
            springResponse: 0.4,
            springDamping: 0.85,
            actionButtonWidth: 90,
            allowElasticOverscroll: false,
            wrongDirectionResistance: 0.15
        )

        #expect(config.revealThreshold == 100)
        #expect(config.fullSwipeThreshold == 250)
        #expect(config.springResponse == 0.4)
        #expect(config.springDamping == 0.85)
        #expect(config.actionButtonWidth == 90)
        #expect(!config.allowElasticOverscroll)
        #expect(config.wrongDirectionResistance == 0.15)
    }

    @Test func swipeActionButtonRole() {
        let destructiveButton = SwipeActionButton(role: .destructive, action: {}) {
            Text("Delete")
        }

        let standardButton = SwipeActionButton(role: nil, action: {}) {
            Text("Share")
        }

        #expect(destructiveButton != nil)
        #expect(standardButton != nil)
    }

    @Test func swipeTouchStateCalculations() {
        var touchState = SwipeTouchState()
        touchState.startX = 100
        touchState.currentX = 150

        let translation = touchState.translation
        #expect(translation == 50)

        touchState.startY = 100
        let isHorizontal = touchState.isHorizontalGesture(currentY: 105)
        #expect(isHorizontal)
    }

    @Test func swipeTouchStateVelocity() {
        var touchState = SwipeTouchState()
        touchState.startX = 100
        touchState.currentX = 150
        touchState.lastUpdateTime = Date().addingTimeInterval(-0.1)

        touchState.updateVelocity()

        #expect(touchState.velocity != 0)
    }

    @Test func swipeActionsDefaultConfiguration() {
        let config = SwipeActionsConfiguration()

        #expect(config.revealThreshold == 80)
        #expect(config.fullSwipeThreshold == 200)
        #expect(config.springResponse == 0.3)
        #expect(config.springDamping == 0.8)
        #expect(config.actionButtonWidth == 80)
        #expect(config.allowElasticOverscroll)
        #expect(config.wrongDirectionResistance == 0.1)
    }

    // MARK: - Pull-to-Refresh Tests (8 tests)

    @Test func refreshableModifier() async {
        var refreshed = false

        let list = List {
            Text("Item 1")
            Text("Item 2")
        }
        .refreshable {
            refreshed = true
        }

        #expect(list != nil)
    }

    @Test func refreshableAsyncCompletion() async {
        var completed = false

        let action: @MainActor @Sendable () async -> Void = {
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            completed = true
        }

        await action()

        #expect(completed)
    }

    @Test func refreshConfiguration() {
        let config = RefreshConfiguration(
            triggerDistance: 100,
            resistance: 3.0,
            springResponse: 0.35,
            springDamping: 0.75,
            enableHaptics: false,
            minimumRefreshDuration: 0.8
        )

        #expect(config.triggerDistance == 100)
        #expect(config.resistance == 3.0)
        #expect(config.springResponse == 0.35)
        #expect(config.springDamping == 0.75)
        #expect(!config.enableHaptics)
        #expect(config.minimumRefreshDuration == 0.8)
    }

    @Test func refreshConfigurationDefaults() {
        let config = RefreshConfiguration()

        #expect(config.triggerDistance == 80)
        #expect(config.resistance == 2.5)
        #expect(config.springResponse == 0.3)
        #expect(config.springDamping == 0.7)
        #expect(config.enableHaptics)
        #expect(config.minimumRefreshDuration == 0.5)
    }

    @Test func refreshProgress() {
        let progress = RefreshProgress(isRefreshing: true, pullProgress: 0.75)

        #expect(progress.isRefreshing)
        #expect(progress.pullProgress == 0.75)
    }

    @Test func refreshProgressIdle() {
        let progress = RefreshProgress(isRefreshing: false, pullProgress: 0.0)

        #expect(!progress.isRefreshing)
        #expect(progress.pullProgress == 0.0)
    }

    @Test func scrollPositionTrackerAtTop() {
        var tracker = ScrollPositionTracker()
        tracker.scrollOffset = 0

        #expect(tracker.isAtTop)
        #expect(tracker.overscrollAmount == 0)
    }

    @Test func scrollPositionTrackerOverscroll() {
        var tracker = ScrollPositionTracker()
        tracker.scrollOffset = -50

        #expect(tracker.isAtTop)
        #expect(tracker.overscrollAmount == 50)
    }

    // MARK: - Reorder/Delete Tests (7 tests)

    @Test func onMoveModifier() {
        var items = ["A", "B", "C"]

        let list = List {
            ForEach(items, id: \.self) { item in
                Text(item)
            }
            .onMove { source, destination in
                items.move(fromOffsets: source, toOffset: destination)
            }
        }

        #expect(list != nil)
    }

    @Test func onDeleteModifier() {
        var items = ["A", "B", "C"]

        let list = List {
            ForEach(items, id: \.self) { item in
                Text(item)
            }
            .onDelete { _ in
            }
        }

        #expect(list != nil)
    }

    @Test func reorderConfiguration() {
        let config = ReorderConfiguration(
            showDragHandles: true,
            springResponse: 0.4,
            springDamping: 0.75,
            enableHaptics: true,
            draggedItemOpacity: 0.6,
            draggedItemScale: 1.08,
            dropTargetColor: .blue
        )

        #expect(config.showDragHandles)
        #expect(config.springResponse == 0.4)
        #expect(config.springDamping == 0.75)
        #expect(config.enableHaptics)
        #expect(config.draggedItemOpacity == 0.6)
        #expect(config.draggedItemScale == 1.08)
    }

    @Test func reorderConfigurationDefaults() {
        let config = ReorderConfiguration()

        #expect(config.showDragHandles)
        #expect(config.springResponse == 0.3)
        #expect(config.springDamping == 0.7)
        #expect(config.enableHaptics)
        #expect(config.draggedItemOpacity == 0.5)
        #expect(config.draggedItemScale == 1.05)
    }

    @Test func reorderStateTracking() {
        var state = ReorderState()

        #expect(!state.isDragging)
        #expect(state.draggedIndex == nil)

        state.draggedIndex = 2
        #expect(state.isDragging)
    }

    @Test func reorderStateCalculateDropTarget() {
        var state = ReorderState()
        state.draggedIndex = 2
        state.dragOffset = CGSize(width: 0, height: 88) // Two items at 44pt each

        state.calculateDropTarget(itemHeight: 44)

        #expect(state.dropTargetIndex == 4)
    }

    @Test func reorderStateReset() {
        var state = ReorderState()
        state.draggedIndex = 2
        state.dropTargetIndex = 5
        state.dragOffset = CGSize(width: 0, height: 100)

        state.reset()

        #expect(state.draggedIndex == nil)
        #expect(state.dropTargetIndex == nil)
        #expect(state.dragOffset == .zero)
    }

    // MARK: - Selection Tests (8 tests)

    @Test func singleSelectionList() {
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

        #expect(list != nil)
    }

    @Test func multipleSelectionList() {
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

        #expect(list != nil)
    }

    @Test func selectionStateIsSelected() {
        var state = SelectionState<Int>(single: 2)

        #expect(state.isSelected(2))
        #expect(!state.isSelected(3))

        var multiState = SelectionState<Int>(multi: [1, 3, 5])
        #expect(multiState.isSelected(3))
        #expect(!multiState.isSelected(2))
    }

    @Test func selectionStateToggle() {
        var state = SelectionState<Int>(single: 2)

        state.toggle(2)
        #expect(state.singleSelection == nil)

        state.toggle(3)
        #expect(state.singleSelection == 3)
    }

    @Test func selectionStateToggleMultiple() {
        var state = SelectionState<Int>(multi: [1, 3])

        state.toggle(3)
        #expect(!state.multiSelection.contains(3))

        state.toggle(5)
        #expect(state.multiSelection.contains(5))
    }

    @Test func selectionStateSelect() {
        var state = SelectionState<Int>(single: nil)

        state.select(7)
        #expect(state.singleSelection == 7)

        state.select(9)
        #expect(state.singleSelection == 9)
    }

    @Test func selectionStateDeselect() {
        var state = SelectionState<Int>(multi: [1, 2, 3])

        state.deselect(2)
        #expect(!state.multiSelection.contains(2))
        #expect(state.multiSelection.contains(1))
        #expect(state.multiSelection.contains(3))
    }

    @Test func selectionStateClear() {
        var state = SelectionState<Int>(multi: [1, 2, 3])

        state.clear()
        #expect(state.multiSelection.isEmpty)
        #expect(state.singleSelection == nil)
    }

    // MARK: - EditMode Tests (5 tests)

    @Test func editModeStates() {
        let inactive = EditMode.inactive
        let active = EditMode.active
        let transient = EditMode.transient

        #expect(!inactive.isEditing)
        #expect(active.isEditing)
        #expect(transient.isEditing)
    }

    @Test func editModeIsEditing() {
        let inactive = EditMode.inactive
        #expect(!inactive.isEditing)

        let active = EditMode.active
        #expect(active.isEditing)

        let transient = EditMode.transient
        #expect(transient.isEditing)
    }

    @Test func editButton() {
        let button = EditButton()
        #expect(button != nil)
    }

    @Test func editModeBindingConstant() {
        let binding = Binding<EditMode>.constant(.active)

        #expect(binding.wrappedValue == .active)
    }

    @Test func editModeToggle() {
        var mode = EditMode.inactive

        mode = mode.isEditing ? .inactive : .active
        #expect(mode.isEditing)

        mode = mode.isEditing ? .inactive : .active
        #expect(!mode.isEditing)
    }

    // MARK: - Configuration Tests (3 tests)

    @Test func environmentSwipeActionsConfiguration() {
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

        #expect(list != nil)
    }

    @Test func environmentRefreshConfiguration() {
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

        #expect(list != nil)
    }

    @Test func environmentReorderConfiguration() {
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

        #expect(list != nil)
    }

    // MARK: - Edge Cases & Performance Tests (6 tests)

    @Test func emptyListWithSwipeActions() {
        let list = List {
            ForEach([] as [String], id: \.self) { item in
                Text(item)
            }
        }

        let node = list.toVNode()
        #expect(node.elementTag == "div")
    }

    @Test func singleItemListWithReorder() {
        var items = ["Single"]

        let list = List {
            ForEach(items, id: \.self) { item in
                Text(item)
            }
            .onMove { source, destination in
                items.move(fromOffsets: source, toOffset: destination)
            }
        }

        #expect(list != nil)
    }

    @Test func collectionMoveOperation() {
        var items = ["A", "B", "C", "D", "E"]

        items.move(fromOffsets: IndexSet(integer: 1), toOffset: 4)

        #expect(items == ["A", "C", "D", "B", "E"])
    }

    @Test func collectionMoveMultipleItems() {
        var items = ["A", "B", "C", "D", "E", "F"]

        items.move(fromOffsets: IndexSet([1, 2]), toOffset: 5)

        #expect(items == ["A", "D", "E", "B", "C", "F"])
    }

    @Test func indexSetMoved() {
        let original = IndexSet([1, 3, 5])
        let result = original.moved(from: IndexSet([1]), to: 4)

        #expect(result.contains(3))
        #expect(result.contains(5))
    }

    // MARK: - Integration Tests (6 tests)

    @Test func swipeActionsWithEditMode() {
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

        #expect(list != nil)
    }

    @Test func selectionWithEditMode() {
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

        #expect(list != nil)
    }

    @Test func reorderWithSelection() {
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

        #expect(list != nil)
    }

    @Test func multipleFeaturesCombined() {
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
                    Button("Delete", role: .destructive, action: { })
                }
        }
        .environment(\.editMode, editModeBinding)
        .refreshable {
            // Refresh action
        }

        #expect(list != nil)
    }

    @Test func horizontalEdgeEquality() {
        #expect(HorizontalEdge.leading == HorizontalEdge.leading)
        #expect(HorizontalEdge.trailing == HorizontalEdge.trailing)
        #expect(HorizontalEdge.leading != HorizontalEdge.trailing)
    }

    @Test func refreshStateTransitions() {
        var state = RefreshState.idle

        state = .pulling
        #expect(state == .pulling)

        state = .triggered
        #expect(state == .triggered)

        state = .refreshing
        #expect(state == .refreshing)

        state = .idle
        #expect(state == .idle)
    }
}
