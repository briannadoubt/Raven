import Foundation
import Raven

/// Example demonstrating the ForEach view implementation
///
/// This file showcases different ways to use ForEach:
/// 1. With Identifiable collections
/// 2. With custom ID key paths
/// 3. With integer ranges
/// 4. Nested within other layouts

// MARK: - Models

struct TodoItem: Identifiable, Sendable {
    let id: UUID
    let title: String
    let isCompleted: Bool

    init(title: String, isCompleted: Bool = false) {
        self.id = UUID()
        self.title = title
        self.isCompleted = isCompleted
    }
}

struct Category: Sendable {
    let name: String
    let color: String
    let itemCount: Int
}

// MARK: - Example Views

/// Example 1: Simple list with Identifiable items
struct TodoListView: View {
    let items: [TodoItem] = [
        TodoItem(title: "Implement ForEach view", isCompleted: true),
        TodoItem(title: "Add VNode conversion", isCompleted: true),
        TodoItem(title: "Write tests", isCompleted: true),
        TodoItem(title: "Add examples", isCompleted: false)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Todo List")
            ForEach(items) { item in
                HStack(spacing: 8) {
                    Text(item.isCompleted ? "✓" : "◯")
                    Text(item.title)
                }
            }
        }
    }
}

/// Example 2: Using custom ID key path
struct CategoryListView: View {
    let categories: [Category] = [
        Category(name: "Work", color: "blue", itemCount: 5),
        Category(name: "Personal", color: "green", itemCount: 3),
        Category(name: "Shopping", color: "orange", itemCount: 7)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Categories")
            ForEach(categories, id: \.name) { category in
                HStack(spacing: 8) {
                    Text(category.name)
                    Text("(\(category.itemCount))")
                }
            }
        }
    }
}

/// Example 3: Using integer ranges
struct NumberGridView: View {
    var body: some View {
        VStack(spacing: 4) {
            Text("Multiplication Table")
            ForEach(1..<11) { row in
                HStack(spacing: 8) {
                    ForEach(1..<11) { col in
                        Text("\(row * col)")
                    }
                }
            }
        }
    }
}

/// Example 4: Nested ForEach with complex layouts
struct TaskBoardView: View {
    struct TaskColumn: Identifiable, Sendable {
        let id: UUID = UUID()
        let title: String
        let tasks: [TodoItem]
    }

    let columns: [TaskColumn] = [
        TaskColumn(
            title: "To Do",
            tasks: [
                TodoItem(title: "Design UI"),
                TodoItem(title: "Write documentation")
            ]
        ),
        TaskColumn(
            title: "In Progress",
            tasks: [
                TodoItem(title: "Implement ForEach"),
                TodoItem(title: "Add tests")
            ]
        ),
        TaskColumn(
            title: "Done",
            tasks: [
                TodoItem(title: "Setup project"),
                TodoItem(title: "Create base views")
            ]
        )
    ]

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ForEach(columns) { column in
                VStack(alignment: .leading, spacing: 8) {
                    Text(column.title)
                    ForEach(column.tasks) { task in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(task.title)
                        }
                    }
                }
            }
        }
    }
}

/// Example 5: Dynamic filtering with ForEach
struct FilteredListView: View {
    let allItems: [TodoItem] = [
        TodoItem(title: "Buy groceries", isCompleted: true),
        TodoItem(title: "Walk the dog", isCompleted: false),
        TodoItem(title: "Read book", isCompleted: false),
        TodoItem(title: "Clean house", isCompleted: true)
    ]

    var body: some View {
        VStack(spacing: 16) {
            // Show all items
            VStack(alignment: .leading, spacing: 8) {
                Text("All Items")
                ForEach(allItems) { item in
                    Text(item.title)
                }
            }

            // Show only incomplete items
            VStack(alignment: .leading, spacing: 8) {
                Text("Incomplete Items")
                ForEach(allItems.filter { !$0.isCompleted }) { item in
                    Text(item.title)
                }
            }

            // Show only completed items
            VStack(alignment: .leading, spacing: 8) {
                Text("Completed Items")
                ForEach(allItems.filter { $0.isCompleted }) { item in
                    Text(item.title)
                }
            }
        }
    }
}

// MARK: - Usage Notes

/*
 ForEach Key Features:

 1. Identifiable Collections:
    ForEach(items) { item in ... }
    - Requires items to conform to Identifiable
    - Uses item.id for stable identity

 2. Custom ID Key Paths:
    ForEach(items, id: \.propertyName) { item in ... }
    - Use any Hashable property as the identifier
    - Useful for types that don't conform to Identifiable

 3. Integer Ranges:
    ForEach(0..<10) { index in ... }
    - Generate a fixed number of views
    - Useful for grids, repeating patterns, etc.

 4. Stable Identity:
    - ForEach uses IDs for efficient diffing
    - The same ID across renders = same view (just updated)
    - Different ID = new view (will be re-rendered)

 5. Performance:
    - ForEach generates views lazily through its body property
    - The RenderCoordinator handles the actual iteration
    - Efficient DOM updates through stable IDs

 6. Nesting:
    - ForEach can be nested to create complex layouts
    - Each ForEach maintains its own stable identity
    - Great for grids, tables, and hierarchical data

 Best Practices:
 - Always use stable IDs (UUID, database IDs, etc.)
 - Avoid using array indices as IDs unless the array never changes
 - Keep the content closure simple and focused
 - Consider performance with very large collections
 - Use filtering/mapping before ForEach, not inside it
 */
