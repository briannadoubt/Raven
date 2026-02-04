# Todo App Example

A complete todo list application built with Raven, demonstrating core SwiftUI patterns and state management.

## What It Demonstrates

This example showcases the following Raven/SwiftUI concepts:

### State Management
- **@StateObject**: The `TodoStore` is owned by the main view and persists across updates
- **@Published**: Properties in `ObservableObject` that automatically trigger view updates
- **@State**: Local component state for the new todo input field
- **@Binding**: Two-way data binding between parent and child views

### View Composition
- Breaking down complex UIs into small, focused components
- Each view has a single responsibility
- Data flows down through props, actions flow up through callbacks

### Lists and Collections
- **List**: Scrollable container that handles layout automatically
- **ForEach**: Iterate over collections to generate views dynamically
- **Identifiable**: Protocol that provides stable identity for list items

### User Input
- **TextField**: Text input with two-way binding via `$` syntax
- **Button**: Clickable actions that trigger state changes
- **Toggle**: Boolean switches for completion status

### Data Filtering
- Filter todos by status (All, Active, Completed)
- Computed properties for derived state
- Dynamic list updates based on filter selection

### CRUD Operations
- **Create**: Add new todos via text input
- **Read**: Display todos in a scrollable list
- **Update**: Toggle completion status
- **Delete**: Remove individual todos or clear all completed

## Project Structure

```
TodoApp/
├── Sources/
│   └── TodoApp/
│       ├── App.swift      # Main app logic, models, and views
│       └── main.swift     # Entry point
├── Package.swift          # Swift Package Manager configuration
└── README.md             # This file
```

## How to Run

### Build for macOS (for testing)

```bash
cd Examples/TodoApp
swift build
```

### Build for WebAssembly

```bash
# Using swift-wasm toolchain
swift build --triple wasm32-unknown-wasi
```

### Run Tests

The Raven test suite validates that all components used in this example work correctly:

```bash
cd ../..
swift test
```

## Key Files

### App.swift

Contains all the app logic:

1. **TodoItem**: Simple struct representing a todo (Identifiable, Sendable)
2. **TodoStore**: ObservableObject managing all todo state and operations
3. **TodoApp**: Main view composing the entire interface
4. **HeaderView**: Displays title and statistics
5. **AddTodoView**: Input form for new todos
6. **FilterView**: Filter selection buttons
7. **TodoListView**: Renders the list of todos
8. **TodoRowView**: Individual todo row with toggle and delete

### main.swift

Entry point that sets up the render coordinator and starts the app.

## Key Learning Points

### ObservableObject Pattern

```swift
@MainActor
final class TodoStore: ObservableObject {
    @Published var todos: [TodoItem] = []

    init() {
        setupPublished()  // Required for @Published to work
    }

    func addTodo(_ text: String) {
        todos.append(TodoItem(text: text))
    }
}
```

### Parent-Child Communication

```swift
// Parent View
struct ParentView: View {
    @State private var text = ""

    var body: some View {
        ChildView(text: $text)  // Pass binding with $
    }
}

// Child View
struct ChildView: View {
    @Binding var text: String  // Two-way binding

    var body: some View {
        TextField("Enter text", text: $text)
    }
}
```

### List with ForEach

```swift
List(items) { item in
    // Each item must be Identifiable
    Text(item.name)
}
```

### Callbacks for Actions

```swift
// Pass actions as closures
TodoRowView(
    todo: todo,
    onToggle: { toggleTodo(todo.id) },
    onDelete: { deleteTodo(todo.id) }
)
```

## Architecture Notes

### Single Source of Truth

All todo data lives in `TodoStore`. Views read from it and call methods to modify it. This ensures:
- Predictable data flow
- Easy to reason about state changes
- Single place to debug issues

### Unidirectional Data Flow

```
User Action → Store Method → @Published Property Changes → View Updates
```

### Computed Properties

Instead of storing filtered todos, we compute them on-demand:

```swift
var filteredTodos: [TodoItem] {
    switch filter {
    case .all: return todos
    case .active: return todos.filter { !$0.isCompleted }
    case .completed: return todos.filter { $0.isCompleted }
    }
}
```

This keeps the state minimal and prevents data duplication.

## Next Steps

To extend this example, try:

1. **Persistence**: Save todos to localStorage/IndexedDB
2. **Editing**: Allow editing todo text after creation
3. **Drag and Drop**: Reorder todos
4. **Due Dates**: Add dates and sort by urgency
5. **Categories**: Group todos by project/tag
6. **Animations**: Add smooth transitions when adding/removing items

## Related Examples

- **StateObjectExample.swift**: Deep dive into @StateObject vs @ObservedObject
- **ListAndTextFieldExample.swift**: More List and TextField patterns
- **Dashboard Example**: More complex layout with grids and navigation
