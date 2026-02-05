import Foundation
import Raven
import JavaScriptKit

// Import Raven's ObservableObject explicitly to avoid ambiguity with Foundation
typealias ObservableObject = Raven.ObservableObject
typealias Published = Raven.Published

// MARK: - Models

/// Represents a single todo item
struct TodoItem: Identifiable, Sendable {
    /// Unique identifier for the todo item
    let id: UUID
    /// The todo text/description
    var text: String
    /// Whether the todo has been completed
    var isCompleted: Bool

    init(id: UUID = UUID(), text: String, isCompleted: Bool = false) {
        self.id = id
        self.text = text
        self.isCompleted = isCompleted
    }
}

// MARK: - View Models

/// Central store managing the todo list state
/// This demonstrates @StateObject usage with ObservableObject
@MainActor
final class TodoStore: ObservableObject {
    /// The list of all todos
    /// @Published automatically notifies views when this changes
    @Published var todos: [TodoItem] = []

    /// Current filter selection
    @Published var filter: Filter = .all

    /// Available filter options
    enum Filter: String, CaseIterable, Sendable {
        case all = "All"
        case active = "Active"
        case completed = "Completed"
    }

    init() {
        // Required setup for @Published properties
        setupPublished()

        // Add some sample todos to start
        todos = [
            TodoItem(text: "Learn SwiftUI basics", isCompleted: true),
            TodoItem(text: "Build a Raven app", isCompleted: false),
            TodoItem(text: "Deploy to production", isCompleted: false)
        ]
    }

    /// Add a new todo to the list
    func addTodo(_ text: String) {
        guard !text.isEmpty else { return }
        let newTodo = TodoItem(text: text)
        todos.append(newTodo)
    }

    /// Toggle the completion status of a todo
    func toggleTodo(_ id: UUID) {
        let console = JSObject.global.console
        _ = console.log("[Swift TodoStore] 🎯 toggleTodo called for id: \(id)")
        if let index = todos.firstIndex(where: { $0.id == id }) {
            _ = console.log("[Swift TodoStore] Found todo at index \(index), calling objectWillChange.send()")
            // Manually trigger objectWillChange since we're mutating array contents
            objectWillChange.send()
            _ = console.log("[Swift TodoStore] objectWillChange.send() completed, toggling isCompleted")
            todos[index].isCompleted.toggle()
            _ = console.log("[Swift TodoStore] Toggled! New value: \(todos[index].isCompleted)")
        } else {
            _ = console.log("[Swift TodoStore] ⚠️ Todo not found for id: \(id)")
        }
    }

    /// Delete a todo from the list
    func deleteTodo(_ id: UUID) {
        // Manually trigger objectWillChange since we're mutating array contents
        objectWillChange.send()
        todos.removeAll { $0.id == id }
    }

    /// Delete all completed todos
    func clearCompleted() {
        // Manually trigger objectWillChange since we're mutating array contents
        objectWillChange.send()
        todos.removeAll { $0.isCompleted }
    }

    /// Get filtered todos based on current filter
    var filteredTodos: [TodoItem] {
        switch filter {
        case .all:
            return todos
        case .active:
            return todos.filter { !$0.isCompleted }
        case .completed:
            return todos.filter { $0.isCompleted }
        }
    }

    /// Count of active (incomplete) todos
    var activeCount: Int {
        todos.filter { !$0.isCompleted }.count
    }

    /// Count of completed todos
    var completedCount: Int {
        todos.filter { $0.isCompleted }.count
    }
}

// MARK: - Views

/// Main todo app view
@MainActor
struct TodoApp: View {
    /// The store manages all todo state and is owned by this view
    /// Using @StateObject ensures the store persists across view updates
    @StateObject var store = TodoStore()

    /// Local state for the new todo input field
    @State private var newTodoText = ""

    var body: some View {
        VStack(spacing: 16) {
            // Header with title and stats
            HeaderView(
                activeCount: store.activeCount,
                completedCount: store.completedCount
            )

            // Input section for adding new todos
            AddTodoView(newTodoText: $newTodoText) {
                store.addTodo(newTodoText)
                newTodoText = ""
            }

            // Filter buttons
            FilterView(currentFilter: store.filter) { filter in
                store.filter = filter
            }

            // The todo list
            TodoListView(
                todos: store.filteredTodos,
                onToggle: { id in store.toggleTodo(id) },
                onDelete: { id in store.deleteTodo(id) }
            )

            // Footer with clear completed button
            if store.completedCount > 0 {
                Button("Clear Completed (\(store.completedCount))") {
                    store.clearCompleted()
                }
            }
        }
    }
}

/// Header view displaying app title and statistics
@MainActor
struct HeaderView: View {
    let activeCount: Int
    let completedCount: Int

    var body: some View {
        VStack(spacing: 8) {
            Text("Todo App")
                .font(.title)

            HStack(spacing: 16) {
                Text("\(activeCount) active")
                Text("\(completedCount) completed")
            }
            .font(.caption)
        }
    }
}

/// View for adding new todos
/// Demonstrates TextField usage and action callbacks
@MainActor
struct AddTodoView: View {
    /// Two-way binding to the parent's newTodoText state
    @Binding var newTodoText: String

    /// Callback when the add button is pressed
    let onAdd: @MainActor () -> Void

    var body: some View {
        HStack(spacing: 8) {
            // TextField with placeholder and two-way binding
            TextField("What needs to be done?", text: $newTodoText)

            // Add button
            Button("Add") {
                onAdd()
            }
        }
    }
}

/// Filter selection view
/// Demonstrates how to create a segmented control-style interface
@MainActor
struct FilterView: View {
    let currentFilter: TodoStore.Filter
    let onFilterChange: @MainActor (TodoStore.Filter) -> Void

    var body: some View {
        HStack(spacing: 8) {
            Text("Show:")

            // Create a button for each filter option
            ForEach(TodoStore.Filter.allCases, id: \.self) { filter in
                Button(filter.rawValue) {
                    onFilterChange(filter)
                }
                // You could add styling here to highlight the selected filter
            }
        }
    }
}

/// The main todo list view
/// Demonstrates List and ForEach usage with dynamic content
@MainActor
struct TodoListView: View {
    let todos: [TodoItem]
    let onToggle: @MainActor (UUID) -> Void
    let onDelete: @MainActor (UUID) -> Void

    var body: some View {
        if todos.isEmpty {
            // Empty state
            Text("No todos to display")
        } else {
            // List of todos
            // List automatically provides scrolling and layout
            List(todos) { todo in
                TodoRowView(
                    todo: todo,
                    onToggle: { onToggle(todo.id) },
                    onDelete: { onDelete(todo.id) }
                )
            }
        }
    }
}

/// Individual todo row view
/// Demonstrates Toggle and Button usage
@MainActor
struct TodoRowView: View {
    let todo: TodoItem
    let onToggle: @MainActor () -> Void
    let onDelete: @MainActor () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Toggle for completion status
            // Note: In a real app, you'd want to make this truly interactive
            // For now, we'll use a button to toggle
            Button(todo.isCompleted ? "☑" : "☐") {
                onToggle()
            }

            // Todo text
            Text(todo.text)

            Spacer()

            // Delete button
            Button("Delete") {
                onDelete()
            }
        }
    }
}

// MARK: - Usage Notes

/*
 This Todo App demonstrates several key Raven/SwiftUI concepts:

 1. State Management:
    - @StateObject: Store owns and manages the todo list state
    - @Published: Properties that trigger view updates when changed
    - @State: Local component state for the input field
    - @Binding: Two-way data binding between parent and child views

 2. View Composition:
    - Breaking down the UI into small, reusable components
    - Passing data down through props
    - Passing actions up through callbacks

 3. Lists and Dynamic Content:
    - List: Scrollable container for multiple items
    - ForEach: Iterate over collections to create views
    - Identifiable: Protocol for stable list item identity

 4. User Input:
    - TextField: Text input with two-way binding
    - Button: Clickable actions
    - Toggle: Boolean switches

 5. Conditional Rendering:
    - if/else to show different content based on state
    - Empty states for better UX

 Key Learning Points:
 - ObservableObject must call setupPublished() in init
 - Use @StateObject for objects the view owns
 - Use @Binding when a child needs to modify parent state
 - Keep view logic simple, move business logic to models
 - Identifiable types work seamlessly with List and ForEach
*/
