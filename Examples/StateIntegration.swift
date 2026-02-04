import Foundation
import Raven

// MARK: - Integration Example: State with Render Coordinator

/// This example demonstrates how @State integrates with the rendering system
/// to provide reactive updates.
///
/// In Phase 2, the integration is manual. In future phases, this will be
/// automatic through the rendering system.

@MainActor
struct IntegratedCounterView: View {
    @State private var count: Int = 0
    @State private var message: String = "Click to increment"

    var body: some View {
        VStack {
            Text(message)
            Text("Count: \(count)")

            Button("Increment") {
                count += 1
                message = "Clicked \(count) time\(count == 1 ? "" : "s")"
            }

            Button("Reset") {
                count = 0
                message = "Counter reset"
            }
        }
    }
}

// MARK: - Phase 2 Integration Pattern

/// Example showing how to manually connect State to RenderCoordinator
/// This pattern will be automated in future phases.
@MainActor
class ViewRenderer {
    private let coordinator: RenderCoordinator

    init(coordinator: RenderCoordinator) {
        self.coordinator = coordinator
    }

    /// Render a view and set up state update callbacks
    func render<V: View>(view: inout V) async {
        // In a full implementation, this would use reflection or
        // property wrappers to automatically find all @State properties
        // and register update callbacks

        // For now, this shows the concept:
        // state.setUpdateCallback {
        //     self.coordinator.scheduleUpdate()
        // }

        await coordinator.render(view: view)
    }
}

// MARK: - Real-World Example: Todo List

@MainActor
struct TodoListApp: View {
    @State private var todos: [Todo] = []
    @State private var newTodoTitle: String = ""
    @State private var filterMode: FilterMode = .all

    var filteredTodos: [Todo] {
        switch filterMode {
        case .all:
            return todos
        case .active:
            return todos.filter { !$0.completed }
        case .completed:
            return todos.filter { $0.completed }
        }
    }

    var body: some View {
        VStack {
            Text("Todo List")

            // Filter buttons
            HStack {
                Button("All (\(todos.count))") {
                    filterMode = .all
                }

                Button("Active (\(todos.filter { !$0.completed }.count))") {
                    filterMode = .active
                }

                Button("Completed (\(todos.filter { $0.completed }.count))") {
                    filterMode = .completed
                }
            }

            // Add todo section
            HStack {
                Button("Add Todo") {
                    if !newTodoTitle.isEmpty {
                        todos.append(Todo(title: newTodoTitle))
                        newTodoTitle = ""
                    }
                }
            }

            // Todo list
            VStack {
                for todo in filteredTodos {
                    TodoRow(
                        todo: binding(for: todo)
                    )
                }
            }

            // Stats
            Text("Total: \(todos.count) | Active: \(todos.filter { !$0.completed }.count)")
        }
    }

    /// Create a binding for a specific todo item
    private func binding(for todo: Todo) -> Binding<Todo> {
        guard let index = todos.firstIndex(where: { $0.id == todo.id }) else {
            return .constant(todo)
        }

        return Binding(
            get: { self.todos[index] },
            set: { self.todos[index] = $0 }
        )
    }
}

// MARK: - Supporting Types

struct Todo: Identifiable, Sendable {
    let id = UUID()
    var title: String
    var completed: Bool = false
}

enum FilterMode: Sendable {
    case all
    case active
    case completed
}

struct TodoRow: View {
    @Binding var todo: Todo

    var body: some View {
        HStack {
            Button(todo.completed ? "✓" : "○") {
                todo.completed.toggle()
            }

            Text(todo.title)

            if todo.completed {
                Text("(Done)")
            }
        }
    }
}

// MARK: - Multi-View State Sharing Example

/// Parent view that manages shared state
@MainActor
struct SharedStateParent: View {
    @State private var sharedValue: Int = 0
    @State private var displayMode: DisplayMode = .decimal

    var body: some View {
        VStack {
            Text("Shared Value: \(formatValue(sharedValue))")

            // Multiple children share the same state
            IncrementView(value: $sharedValue)
            DecrementView(value: $sharedValue)
            DisplayModeSelector(mode: $displayMode)

            // Different representations of the same value
            Text("Decimal: \(sharedValue)")
            Text("Hex: 0x\(String(sharedValue, radix: 16).uppercased())")
            Text("Binary: 0b\(String(sharedValue, radix: 2))")
        }
    }

    private func formatValue(_ value: Int) -> String {
        switch displayMode {
        case .decimal:
            return String(value)
        case .hexadecimal:
            return "0x\(String(value, radix: 16).uppercased())"
        case .binary:
            return "0b\(String(value, radix: 2))"
        }
    }
}

enum DisplayMode: Sendable {
    case decimal
    case hexadecimal
    case binary
}

struct IncrementView: View {
    @Binding var value: Int

    var body: some View {
        Button("Increment") {
            value += 1
        }
    }
}

struct DecrementView: View {
    @Binding var value: Int

    var body: some View {
        Button("Decrement") {
            value -= 1
        }
    }
}

struct DisplayModeSelector: View {
    @Binding var mode: DisplayMode

    var body: some View {
        HStack {
            Button("Dec") { mode = .decimal }
            Button("Hex") { mode = .hexadecimal }
            Button("Bin") { mode = .binary }
        }
    }
}

// MARK: - Computed State Example

@MainActor
struct ComputedStateExample: View {
    @State private var width: Double = 100
    @State private var height: Double = 50

    var area: Double {
        width * height
    }

    var perimeter: Double {
        2 * (width + height)
    }

    var aspectRatio: Double {
        width / height
    }

    var body: some View {
        VStack {
            Text("Rectangle Calculator")

            Text("Width: \(width)")
            Text("Height: \(height)")

            HStack {
                Button("Width +") { width += 10 }
                Button("Width -") { width = max(0, width - 10) }
            }

            HStack {
                Button("Height +") { height += 10 }
                Button("Height -") { height = max(0, height - 10) }
            }

            Text("Area: \(area)")
            Text("Perimeter: \(perimeter)")
            Text("Aspect Ratio: \(aspectRatio)")
        }
    }
}

// MARK: - State Composition Example

/// Example showing how to compose multiple state properties
@MainActor
struct CompositeStateExample: View {
    @State private var user: User = User()
    @State private var settings: Settings = Settings()
    @State private var sessionInfo: SessionInfo = SessionInfo()

    var body: some View {
        VStack {
            UserProfile(user: $user)
            SettingsPanel(settings: $settings)
            SessionStats(session: $sessionInfo)
        }
    }
}

struct User: Sendable {
    var name: String = ""
    var email: String = ""
    var avatar: String = ""
}

struct Settings: Sendable {
    var notifications: Bool = true
    var darkMode: Bool = false
    var fontSize: Int = 14
}

struct SessionInfo: Sendable {
    var loginTime: Date = Date()
    var pageViews: Int = 0
    var lastActivity: Date = Date()
}

struct UserProfile: View {
    @Binding var user: User

    var body: some View {
        VStack {
            Text("User Profile")
            Text("Name: \(user.name)")
            Text("Email: \(user.email)")
        }
    }
}

struct SettingsPanel: View {
    @Binding var settings: Settings

    var body: some View {
        VStack {
            Text("Settings")

            Button("Notifications: \(settings.notifications ? "On" : "Off")") {
                settings.notifications.toggle()
            }

            Button("Dark Mode: \(settings.darkMode ? "On" : "Off")") {
                settings.darkMode.toggle()
            }
        }
    }
}

struct SessionStats: View {
    @Binding var session: SessionInfo

    var body: some View {
        VStack {
            Text("Session Info")
            Text("Page Views: \(session.pageViews)")

            Button("Track Page View") {
                session.pageViews += 1
                session.lastActivity = Date()
            }
        }
    }
}
