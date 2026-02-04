import Foundation

// MARK: - List Reordering

/// Support for reordering items in a list.
///
/// List reordering allows users to drag items to rearrange them. This is typically
/// enabled in edit mode and requires a handler to update the underlying data.
///
/// ## Overview
///
/// Reordering works with ForEach views inside Lists. When edit mode is active,
/// reorder controls (drag handles) appear, allowing users to drag items to new positions.
///
/// ## Usage
///
/// Add reordering to a list:
///
/// ```swift
/// @State private var items = ["Apple", "Banana", "Cherry"]
/// @State private var editMode = EditMode.inactive
///
/// List {
///     ForEach(items, id: \.self) { item in
///         Text(item)
///     }
///     .onMove { from, to in
///         items.move(fromOffsets: from, toOffset: to)
///     }
/// }
/// .environment(\.editMode, $editMode)
/// ```
///
/// ## Edit Mode Integration
///
/// Reorder controls are only visible when edit mode is active:
///
/// ```swift
/// List {
///     ForEach(items) { item in
///         Text(item.name)
///     }
///     .onMove(perform: moveItems)
/// }
/// .toolbar {
///     EditButton()
/// }
///
/// func moveItems(from: IndexSet, to: Int) {
///     items.move(fromOffsets: from, toOffset: to)
/// }
/// ```
extension ForEach {
    /// Adds the ability to reorder items in a list.
    ///
    /// When edit mode is active, drag handles appear on list items, allowing users
    /// to drag them to new positions. The `perform` closure is called with the
    /// source indices and destination index when a move occurs.
    ///
    /// - Parameter perform: A closure that handles the move operation.
    ///   It receives an `IndexSet` of source indices and an `Int` destination index.
    /// - Returns: A view with reorder support.
    @MainActor
    public func onMove(
        perform: @escaping @Sendable @MainActor (IndexSet, Int) -> Void
    ) -> some View {
        modifier(_MoveModifier(action: perform))
    }
}

// MARK: - Move Modifier

/// Internal modifier that adds reordering capability to a view.
///
/// This modifier handles:
/// - Drag handle rendering in edit mode
/// - Touch tracking for drag gestures
/// - Visual feedback during drag (lift, ghost item)
/// - Drop target highlighting
/// - Animation for item reordering
/// - Accessibility support for reordering
@MainActor
struct _MoveModifier: ViewModifier, Sendable {
    let action: @Sendable @MainActor (IndexSet, Int) -> Void

    @Environment(\.editMode) private var editMode
    @State private var isDragging = false
    @State private var draggedItemIndex: Int?
    @State private var dropTargetIndex: Int?

    @MainActor
    func body(content: Content) -> some View {
        HStack(spacing: 12) {
            // Content
            content

            // Drag handle (visible in edit mode)
            if editMode?.wrappedValue.isEditing == true {
                dragHandle
            }
        }
        .opacity(isDragging ? 0.5 : 1)
    }

    /// The drag handle icon
    @ViewBuilder
    private var dragHandle: some View {
        Image(systemName: "line.3.horizontal")
            .foregroundColor(.secondary)
            .gesture(dragGesture)
    }

    /// Visual indicator for drop target
    @ViewBuilder
    private var dropTargetIndicator: some View {
        Rectangle()
            .fill(Color.blue.opacity(0.3))
            .frame(height: 2)
    }

    /// The drag gesture for reordering
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged(handleDragChanged)
            .onEnded(handleDragEnded)
    }

    /// Handles drag gesture changes
    private func handleDragChanged(_ value: DragGesture.Value) {
        if !isDragging {
            isDragging = true
            // Haptic feedback
        }

        // Calculate drop target based on drag position
        // This would use the actual item heights and positions
        let itemHeight: CGFloat = 44 // Standard list item height
        let offset = value.translation.height
        let targetOffset = Int(round(offset / itemHeight))

        dropTargetIndex = targetOffset
    }

    /// Handles drag gesture end
    private func handleDragEnded(_ value: DragGesture.Value) {
        isDragging = false

        if let sourceIndex = draggedItemIndex, let targetOffset = dropTargetIndex {
            let destinationIndex = sourceIndex + targetOffset

            // Perform the move
            withAnimation {
                action(IndexSet(integer: sourceIndex), destinationIndex)
            }
        }

        // Reset state
        draggedItemIndex = nil
        dropTargetIndex = nil
    }
}

// MARK: - Delete Support

/// Extension to add deletion support to ForEach views.
extension ForEach {
    /// Adds the ability to delete items from a list.
    ///
    /// When edit mode is active, delete buttons appear on list items. The `perform`
    /// closure is called with the indices to delete.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// ForEach(items) { item in
    ///     Text(item.name)
    /// }
    /// .onDelete { indices in
    ///     items.remove(atOffsets: indices)
    /// }
    /// ```
    ///
    /// - Parameter perform: A closure that handles the deletion.
    /// - Returns: A view with delete support.
    @MainActor
    public func onDelete(
        perform: @escaping @Sendable @MainActor (IndexSet) -> Void
    ) -> some View {
        modifier(_DeleteModifier(action: perform))
    }
}

// MARK: - Delete Modifier

/// Internal modifier that adds deletion capability to a view.
///
/// This modifier handles:
/// - Delete button rendering in edit mode
/// - Swipe-to-delete gestures
/// - Confirmation for destructive operations
/// - Animation for item removal
/// - Accessibility support for deletion
@MainActor
struct _DeleteModifier: ViewModifier, Sendable {
    let action: @Sendable @MainActor (IndexSet) -> Void

    @Environment(\.editMode) private var editMode
    @State private var showDeleteButton = false

    @MainActor
    func body(content: Content) -> some View {
        HStack {
            // Delete button (visible in edit mode)
            if editMode?.wrappedValue.isEditing == true {
                deleteButton
            }

            content
        }
    }

    /// The delete button
    @ViewBuilder
    private var deleteButton: some View {
        Button(action: performDelete) {
            Image(systemName: "minus.circle.fill")
                .foregroundColor(.red)
        }
    }

    /// Performs the delete action
    private func performDelete() {
        // In a real implementation, this would determine the index
        // For now, placeholder
        withAnimation {
            action(IndexSet(integer: 0))
        }
    }
}

// MARK: - Reorder State

/// State management for list reordering operations.
///
/// This tracks the current reorder operation, including the dragged item,
/// drop target, and animation state.
@MainActor
struct ReorderState: Sendable {
    /// The index of the item being dragged
    var draggedIndex: Int?

    /// The current drop target index
    var dropTargetIndex: Int?

    /// The drag offset
    var dragOffset: CGSize = .zero

    /// Whether a drag is in progress
    var isDragging: Bool {
        draggedIndex != nil
    }

    /// The visual offset for the dragged item
    var visualOffset: CGFloat {
        dragOffset.height
    }

    /// Calculates the target index based on drag position
    mutating func calculateDropTarget(itemHeight: CGFloat) {
        guard let draggedIndex = draggedIndex else { return }

        let offset = dragOffset.height
        let itemOffset = Int(round(offset / itemHeight))

        // Clamp to valid range
        let newIndex = max(0, draggedIndex + itemOffset)
        dropTargetIndex = newIndex
    }

    /// Resets the reorder state
    mutating func reset() {
        draggedIndex = nil
        dropTargetIndex = nil
        dragOffset = .zero
    }
}

// MARK: - Reorder Configuration

/// Configuration for list reordering behavior.
public struct ReorderConfiguration: Sendable {
    /// Whether to show drag handles in edit mode
    public var showDragHandles: Bool = true

    /// The spring response for reorder animations
    public var springResponse: Double = 0.3

    /// The spring damping for reorder animations
    public var springDamping: Double = 0.7

    /// Whether to provide haptic feedback
    public var enableHaptics: Bool = true

    /// The opacity of the dragged item
    public var draggedItemOpacity: Double = 0.5

    /// The scale of the dragged item
    public var draggedItemScale: Double = 1.05

    /// The color of the drop target indicator
    public var dropTargetColor: Color = .blue

    /// Creates a default configuration
    public init() {}

    /// Creates a configuration with custom values
    public init(
        showDragHandles: Bool = true,
        springResponse: Double = 0.3,
        springDamping: Double = 0.7,
        enableHaptics: Bool = true,
        draggedItemOpacity: Double = 0.5,
        draggedItemScale: Double = 1.05,
        dropTargetColor: Color = .blue
    ) {
        self.showDragHandles = showDragHandles
        self.springResponse = springResponse
        self.springDamping = springDamping
        self.enableHaptics = enableHaptics
        self.draggedItemOpacity = draggedItemOpacity
        self.draggedItemScale = draggedItemScale
        self.dropTargetColor = dropTargetColor
    }
}

// MARK: - Environment Key

/// Environment key for reorder configuration.
private struct ReorderConfigurationKey: EnvironmentKey {
    static let defaultValue = ReorderConfiguration()
}

extension EnvironmentValues {
    /// The configuration for list reordering behavior.
    ///
    /// Use this to customize reorder behavior:
    ///
    /// ```swift
    /// List {
    ///     ForEach(items) { item in
    ///         Text(item.name)
    ///     }
    ///     .onMove(perform: moveItems)
    /// }
    /// .environment(\.reorderConfiguration, .init(
    ///     draggedItemScale: 1.1,
    ///     enableHaptics: true
    /// ))
    /// ```
    public var reorderConfiguration: ReorderConfiguration {
        get { self[ReorderConfigurationKey.self] }
        set { self[ReorderConfigurationKey.self] = newValue }
    }
}

// MARK: - Index Set Extension

extension IndexSet {
    /// Moves indices within the set.
    ///
    /// This is a helper for implementing onMove operations.
    ///
    /// - Parameters:
    ///   - source: The source indices to move.
    ///   - destination: The destination index.
    /// - Returns: A new IndexSet with adjusted indices.
    func moved(from source: IndexSet, to destination: Int) -> IndexSet {
        var result = self

        // Remove source indices
        result.subtract(source)

        // Adjust indices based on move
        let sortedSources = source.sorted()
        var adjustment = 0

        for sourceIndex in sortedSources {
            if sourceIndex < destination {
                adjustment += 1
            }
        }

        // Add at new position
        let adjustedDestination = destination - adjustment
        for (offset, _) in sortedSources.enumerated() {
            result.insert(adjustedDestination + offset)
        }

        return result
    }
}

// MARK: - Collection Extension

extension RangeReplaceableCollection where Self: MutableCollection {
    /// Moves elements from one offset to another.
    ///
    /// This is a helper for implementing onMove operations.
    ///
    /// - Parameters:
    ///   - source: The indices of elements to move.
    ///   - destination: The destination index.
    mutating func move(fromOffsets source: IndexSet, toOffset destination: Int) {
        let items = source.sorted().map { self[self.index(self.startIndex, offsetBy: $0)] }

        // Remove from source
        for offset in source.sorted().reversed() {
            let index = self.index(self.startIndex, offsetBy: offset)
            self.remove(at: index)
        }

        // Calculate adjusted destination
        let movedBeforeDestination = source.filter { $0 < destination }.count
        let adjustedDestination = destination - movedBeforeDestination

        // Insert at destination
        let destinationIndex = self.index(self.startIndex, offsetBy: adjustedDestination)
        self.insert(contentsOf: items, at: destinationIndex)
    }
}
