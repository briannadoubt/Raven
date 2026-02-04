# Todo List Example

A complete todo list app demonstrating forms, lists, state management, and user interactions.

## What This Example Shows

- ✅ Complex state management with arrays
- ✅ Form input with TextField
- ✅ List rendering with ForEach
- ✅ Filtering and computed properties
- ✅ CRUD operations (Create, Read, Update, Delete)
- ✅ Toggle switches
- ✅ Conditional styling (strikethrough)
- ✅ Component composition (TodoRow)

## Features

- **Add tasks**: Type and press Enter or click the + button
- **Complete tasks**: Click the circle icon to toggle completion
- **Delete tasks**: Click the trash icon to remove
- **Filter**: Toggle "Show completed" to hide finished tasks
- **Task counter**: Shows remaining incomplete tasks

## Key Concepts

### 1. Array State Management
```swift
@State private var todos: [TodoItem] = [...]
```

Manage collections of data that automatically trigger UI updates.

### 2. Computed Properties
```swift
var filteredTodos: [TodoItem] {
    showCompleted ? todos : todos.filter { !$0.isCompleted }
}
```

Derive new data from state without duplication.

### 3. List with ForEach
```swift
List {
    ForEach(filteredTodos) { todo in
        TodoRow(todo: todo, ...)
    }
}
```

Render dynamic lists efficiently.

### 4. Data Models
```swift
struct TodoItem: Identifiable {
    let id = UUID()
    var title: String
    var isCompleted = false
}
```

Create identifiable models for list items.

### 5. Callbacks
```swift
TodoRow(
    todo: todo,
    onToggle: { toggleTodo(todo) },
    onDelete: { deleteTodo(todo) }
)
```

Pass actions down to child components.

## Building on This Example

- Add persistence with localStorage
- Add categories or tags
- Add due dates and sorting
- Add drag-and-drop reordering
- Add animations for adding/removing items
