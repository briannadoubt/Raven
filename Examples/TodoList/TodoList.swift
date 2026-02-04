import Raven

/// A todo list app demonstrating forms, lists, and state management
@main
struct TodoApp {
    static func main() async {
        await RavenApp(rootView: TodoListView()).run()
    }
}

struct TodoListView: View {
    @State private var todos: [TodoItem] = [
        TodoItem(title: "Learn Raven basics"),
        TodoItem(title: "Build an awesome app"),
        TodoItem(title: "Deploy to production")
    ]
    @State private var newTodoText = ""
    @State private var showCompleted = true

    var filteredTodos: [TodoItem] {
        showCompleted ? todos : todos.filter { !$0.isCompleted }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                Text("My Tasks")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.primary)

                Text("\(todos.filter { !$0.isCompleted }.count) remaining")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(.systemBackground))

            Divider()

            // Add new todo form
            HStack(spacing: 12) {
                TextField("Add a new task...", text: $newTodoText)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        addTodo()
                    }

                Button(action: addTodo) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
                .disabled(newTodoText.isEmpty)
            }
            .padding()
            .background(Color(.secondarySystemBackground))

            Divider()

            // Filter toggle
            Toggle("Show completed", isOn: $showCompleted)
                .padding(.horizontal)
                .padding(.vertical, 8)

            Divider()

            // Todo list
            List {
                ForEach(filteredTodos) { todo in
                    TodoRow(
                        todo: todo,
                        onToggle: { toggleTodo(todo) },
                        onDelete: { deleteTodo(todo) }
                    )
                }
            }
            .listStyle(.plain)
        }
        .frame(maxWidth: 600)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }

    private func addTodo() {
        guard !newTodoText.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        let newTodo = TodoItem(title: newTodoText)
        todos.insert(newTodo, at: 0)
        newTodoText = ""
    }

    private func toggleTodo(_ todo: TodoItem) {
        if let index = todos.firstIndex(where: { $0.id == todo.id }) {
            todos[index].isCompleted.toggle()
        }
    }

    private func deleteTodo(_ todo: TodoItem) {
        todos.removeAll { $0.id == todo.id }
    }
}

struct TodoRow: View {
    let todo: TodoItem
    let onToggle: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(todo.isCompleted ? .green : .gray)
            }

            Text(todo.title)
                .strikethrough(todo.isCompleted)
                .foregroundColor(todo.isCompleted ? .secondary : .primary)

            Spacer()

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
        .padding(.vertical, 8)
    }
}

struct TodoItem: Identifiable {
    let id = UUID()
    var title: String
    var isCompleted = false
}
