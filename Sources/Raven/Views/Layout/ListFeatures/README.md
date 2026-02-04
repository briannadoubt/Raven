# List Features

This module provides enhanced list functionality for Raven, including swipe actions, pull-to-refresh, reordering, selection, and edit mode.

## Overview

The List Features module extends the basic `List` view with interactive capabilities commonly found in modern mobile and web applications. These features work seamlessly together and integrate with SwiftUI's environment system.

## Components

### 1. EditMode

Edit mode controls whether users can modify list content. It provides three states:

- `inactive`: Content is read-only
- `active`: Content can be edited (delete, reorder, select)
- `transient`: Transitioning between states (for animations)

**Usage:**

```swift
@State private var editMode = EditMode.inactive

List {
    ForEach(items) { item in
        Text(item.name)
    }
    .onDelete { indices in
        items.remove(atOffsets: indices)
    }
}
.environment(\.editMode, $editMode)
.toolbar {
    EditButton() // Automatically toggles edit mode
}
```

**Key Features:**
- Environment-based propagation through view hierarchy
- `EditButton` for automatic toggle functionality
- Integration with selection, deletion, and reordering

### 2. List Selection

Selection allows users to select one or multiple items in a list. Supports both single and multi-selection modes.

**Single Selection:**

```swift
@State private var selection: UUID?

List(items, selection: $selection) { item in
    Text(item.name)
}
```

**Multiple Selection:**

```swift
@State private var selection = Set<UUID>()

List(items, selection: $selection) { item in
    Text(item.name)
}
```

**Key Features:**
- Single and multi-selection support
- Automatic checkboxes in edit mode
- Works with any `Hashable` identifier type
- Integration with edit mode for visual indicators

### 3. Swipe Actions

Swipe actions reveal action buttons when users swipe on list rows. Supports both leading and trailing edges.

**Basic Usage:**

```swift
List(items) { item in
    Text(item.name)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                deleteItem(item)
            } label: {
                Label("Delete", systemImage: "trash")
            }
            Button {
                shareItem(item)
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
            }
        }
}
```

**Full Swipe:**

```swift
Text(item.name)
    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
        Button(role: .destructive) {
            deleteItem(item)
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }
```

**Key Features:**
- Swipe from leading or trailing edges
- Full-swipe support for primary action
- Smooth CSS transform animations
- Spring-based snap animations
- Configurable thresholds and behavior

**Configuration:**

```swift
List(items) { item in
    // ...
}
.environment(\.swipeActionsConfiguration, .init(
    revealThreshold: 100,
    fullSwipeThreshold: 250,
    actionButtonWidth: 90
))
```

### 4. Pull to Refresh

Pull-to-refresh allows users to refresh content by pulling down on a scrollable view. Fully async/await compatible.

**Usage:**

```swift
List(items) { item in
    Text(item.name)
}
.refreshable {
    await loadData()
}
```

**With Error Handling:**

```swift
ScrollView {
    content
}
.refreshable {
    do {
        items = try await api.fetchItems()
    } catch {
        showError(error)
    }
}
```

**Key Features:**
- Async/await support
- Automatic loading indicator
- Elastic pull resistance
- Configurable trigger distance
- Haptic feedback (configurable)
- Minimum refresh duration to prevent flicker

**Configuration:**

```swift
List(items) { item in
    // ...
}
.refreshable {
    await loadData()
}
.environment(\.refreshConfiguration, .init(
    triggerDistance: 100,
    resistance: 3.0,
    minimumRefreshDuration: 0.5
))
```

### 5. List Reordering

Reordering allows users to drag items to rearrange them. Works with `ForEach` inside Lists.

**Usage:**

```swift
@State private var items = ["Apple", "Banana", "Cherry"]

List {
    ForEach(items, id: \.self) { item in
        Text(item)
    }
    .onMove { from, to in
        items.move(fromOffsets: from, toOffset: to)
    }
}
.toolbar {
    EditButton() // Shows drag handles in edit mode
}
```

**With Deletion:**

```swift
List {
    ForEach(items) { item in
        Text(item.name)
    }
    .onMove(perform: moveItems)
    .onDelete(perform: deleteItems)
}

func moveItems(from: IndexSet, to: Int) {
    items.move(fromOffsets: from, toOffset: to)
}

func deleteItems(at: IndexSet) {
    items.remove(atOffsets: at)
}
```

**Key Features:**
- Drag handles visible in edit mode
- Visual feedback during drag (opacity, scale)
- Drop target indicators
- Smooth animations
- Helper methods for array manipulation
- Haptic feedback (configurable)

**Configuration:**

```swift
List {
    ForEach(items) { item in
        Text(item.name)
    }
    .onMove(perform: moveItems)
}
.environment(\.reorderConfiguration, .init(
    draggedItemScale: 1.1,
    draggedItemOpacity: 0.6,
    enableHaptics: true
))
```

## Integration Examples

### Complete List with All Features

```swift
struct ItemListView: View {
    @State private var items: [Item] = []
    @State private var selection = Set<UUID>()
    @State private var editMode = EditMode.inactive
    @State private var isLoading = false

    var body: some View {
        List(items, selection: $selection) { item in
            ItemRow(item: item)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        deleteItem(item)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
                .swipeActions(edge: .leading) {
                    Button {
                        favoriteItem(item)
                    } label: {
                        Label("Favorite", systemImage: "star")
                    }
                }
        }
        .refreshable {
            await loadItems()
        }
        .environment(\.editMode, $editMode)
        .toolbar {
            EditButton()
        }
        .navigationTitle("Items")
    }

    func deleteItem(_ item: Item) {
        items.removeAll { $0.id == item.id }
    }

    func favoriteItem(_ item: Item) {
        // Toggle favorite
    }

    func loadItems() async {
        do {
            items = try await api.fetchItems()
        } catch {
            // Handle error
        }
    }
}
```

### Reorderable Todo List

```swift
struct TodoListView: View {
    @State private var todos: [Todo] = []
    @State private var editMode = EditMode.inactive

    var body: some View {
        List {
            ForEach(todos) { todo in
                TodoRow(todo: todo)
            }
            .onMove(perform: moveTodos)
            .onDelete(perform: deleteTodos)
        }
        .environment(\.editMode, $editMode)
        .toolbar {
            EditButton()
        }
        .refreshable {
            await syncTodos()
        }
    }

    func moveTodos(from: IndexSet, to: Int) {
        todos.move(fromOffsets: from, toOffset: to)
        Task {
            await saveTodoOrder()
        }
    }

    func deleteTodos(at: IndexSet) {
        todos.remove(atOffsets: at)
    }

    func syncTodos() async {
        // Sync with server
    }

    func saveTodoOrder() async {
        // Save order to server
    }
}
```

## Implementation Details

### Web Platform Integration

All list features are designed to work seamlessly in the browser environment:

1. **Touch Events**: Uses pointer events (pointerdown, pointermove, pointerup) for cross-device compatibility
2. **CSS Transforms**: Smooth animations using CSS transforms for optimal performance
3. **Gesture Detection**: Sophisticated touch tracking to disambiguate swipes, scrolls, and taps
4. **DOM Manipulation**: Efficient VNode updates for list item changes
5. **Accessibility**: ARIA attributes for screen readers and keyboard navigation

### Performance Considerations

- **Virtualization**: Works with the `.virtualized()` modifier for large lists
- **Event Delegation**: Efficient event handling through bubbling
- **Animation**: Hardware-accelerated CSS transforms
- **State Management**: Minimal re-renders through targeted updates

### Thread Safety

All components are `@MainActor` isolated and fully compatible with Swift 6.2 strict concurrency:

- All gesture handlers run on the main actor
- Async operations properly isolated
- State updates are thread-safe
- Environment values are `Sendable`

## Environment Values

### Edit Mode

```swift
@Environment(\.editMode) var editMode
```

### Selection Configuration

```swift
@Environment(\.swipeActionsConfiguration) var swipeConfig
@Environment(\.refreshConfiguration) var refreshConfig
@Environment(\.reorderConfiguration) var reorderConfig
```

### Refresh Action

```swift
@Environment(\.refresh) var refresh
```

Check if refresh is available and trigger manually:

```swift
if let refresh = refresh {
    Task {
        await refresh()
    }
}
```

## Customization

Each feature provides configuration types for customizing behavior:

- `SwipeActionsConfiguration`: Thresholds, animations, button width
- `RefreshConfiguration`: Trigger distance, resistance, haptics
- `ReorderConfiguration`: Visual feedback, animations, drag handles

All configurations can be set via the environment for hierarchical propagation.

## Future Enhancements

Planned improvements include:

- [ ] Custom refresh indicators
- [ ] Programmatic swipe reveal/hide
- [ ] Multi-column swipe actions
- [ ] Context menu integration
- [ ] Batch operations in edit mode
- [ ] Undo/redo support for reordering
- [ ] Accessibility improvements (VoiceOver hints)
- [ ] Keyboard shortcuts for edit operations

## Testing

When testing list features:

1. Test with various data sizes (empty, single, large)
2. Verify edit mode transitions
3. Test gesture conflicts (scroll vs swipe)
4. Verify selection state updates
5. Test async refresh operations
6. Verify reorder with complex data structures
7. Test accessibility with screen readers
8. Verify performance with virtualization

## See Also

- `List.swift` - Base list implementation
- `ForEach.swift` - Dynamic content iteration
- `ScrollView.swift` - Scrolling container
- `GestureModifier.swift` - Gesture handling
- `VirtualizedModifier.swift` - Performance optimization
