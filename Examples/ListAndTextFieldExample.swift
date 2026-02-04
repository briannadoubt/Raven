import Foundation
import Raven

/// Example demonstrating List and TextField views
///
/// This example shows how to use the List view with ForEach for dynamic content
/// and TextField for text input with two-way data binding.

// Example 1: Simple List with static content
struct SimpleListExample: View {
    var body: some View {
        List {
            Text("Item 1")
            Text("Item 2")
            Text("Item 3")
        }
    }
}

// Example 2: List with ForEach and dynamic content
struct DynamicListExample: View {
    struct Item: Identifiable, Sendable {
        let id: UUID
        let name: String
    }

    let items = [
        Item(id: UUID(), name: "Apple"),
        Item(id: UUID(), name: "Banana"),
        Item(id: UUID(), name: "Cherry")
    ]

    var body: some View {
        List(items) { item in
            Text(item.name)
        }
    }
}

// Example 3: TextField with State binding
struct TextFieldExample: View {
    @State private var username = ""
    @State private var email = ""

    var body: some View {
        VStack(spacing: 12) {
            TextField("Username", text: $username)
            TextField("Email", text: $email)
            Text("Username: \(username)")
            Text("Email: \(email)")
        }
    }
}

// Example 4: Todo List combining List and TextField
struct TodoListExample: View {
    struct Todo: Identifiable, Sendable {
        let id: UUID
        var text: String
        var isCompleted: Bool
    }

    @State private var todos: [Todo] = [
        Todo(id: UUID(), text: "Buy groceries", isCompleted: false),
        Todo(id: UUID(), text: "Walk the dog", isCompleted: true),
        Todo(id: UUID(), text: "Write code", isCompleted: false)
    ]

    @State private var newTodoText = ""

    var body: some View {
        VStack(spacing: 16) {
            // Input section
            HStack(spacing: 8) {
                TextField("New todo", text: $newTodoText)
                Button("Add") {
                    addTodo()
                }
            }

            // Todo list
            List(todos) { todo in
                HStack {
                    Text(todo.text)
                    if todo.isCompleted {
                        Text("✓")
                    }
                }
            }
        }
    }

    private func addTodo() {
        guard !newTodoText.isEmpty else { return }
        todos.append(Todo(id: UUID(), text: newTodoText, isCompleted: false))
        newTodoText = ""
    }
}

// Example 5: TextEditor for multi-line input
struct TextEditorExample: View {
    @State private var notes = ""

    var body: some View {
        VStack(spacing: 12) {
            Text("Notes:")
            TextEditor(text: $notes)
            Text("Character count: \(notes.count)")
        }
    }
}

// Example 6: List with range
struct RangeListExample: View {
    var body: some View {
        List(0..<10) { index in
            Text("Row \(index)")
        }
    }
}

// Example 7: List with custom ID key path
struct CustomIDListExample: View {
    struct Person: Sendable {
        let email: String
        let name: String
    }

    let people = [
        Person(email: "alice@example.com", name: "Alice"),
        Person(email: "bob@example.com", name: "Bob"),
        Person(email: "charlie@example.com", name: "Charlie")
    ]

    var body: some View {
        List(people, id: \.email) { person in
            VStack(alignment: .leading, spacing: 4) {
                Text(person.name)
                Text(person.email)
            }
        }
    }
}
