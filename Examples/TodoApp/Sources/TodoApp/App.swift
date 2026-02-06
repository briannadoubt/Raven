import Foundation
import Raven
import JavaScriptKit

// Import Raven's ObservableObject explicitly to avoid ambiguity with Foundation
typealias ObservableObject = Raven.ObservableObject
typealias Published = Raven.Published

// MARK: - Unique ID Generation

/// Counter-based UUID generator for WASM
/// Foundation's UUID() relies on WASI random_get which is broken in our polyfill
/// This generates unique UUIDs using a monotonic counter instead
@MainActor
private var _todoIDCounter: UInt64 = 0

@MainActor
func nextTodoID() -> UUID {
    _todoIDCounter += 1
    let hex = String(_todoIDCounter, radix: 16, uppercase: false)
    let padded = String(repeating: "0", count: max(0, 12 - hex.count)) + hex
    // UUID format: 8-4-4-4-12 hex digits
    let uuidString = "a0000000-0000-4000-8000-\(padded)"
    return UUID(uuidString: uuidString) ?? UUID()
}

// MARK: - Models

/// Represents a single todo item
struct TodoItem: Identifiable, Sendable {
    /// Unique identifier for the todo item
    let id: UUID
    /// The todo text/description
    var text: String
    /// Whether the todo has been completed
    var isCompleted: Bool

    @MainActor
    init(text: String, isCompleted: Bool = false) {
        self.id = nextTodoID()
        self.text = text
        self.isCompleted = isCompleted
    }
}

// MARK: - Store

/// Central store managing all showcase state including todos and form controls
@MainActor
final class ShowcaseStore: ObservableObject {
    // -- Tab state --
    @Published var selectedTab: String = "todos"

    // -- Todo state --
    @Published var todos: [TodoItem] = []

    @Published var filter: Filter = .all

    enum Filter: String, CaseIterable, Sendable {
        case all = "All"
        case active = "Active"
        case completed = "Completed"
    }

    // -- Controls state --
    @Published var toggleValue: Bool = false
    @Published var sliderValue: Double = 50.0
    @Published var stepperValue: Int = 0
    @Published var secureText: String = ""
    @Published var progressValue: Double = 0.65

    init() {
        setupPublished()

        todos = [
            TodoItem(text: "Learn SwiftUI basics", isCompleted: true),
            TodoItem(text: "Build a Raven app", isCompleted: false),
            TodoItem(text: "Deploy to production", isCompleted: false)
        ]
    }

    // MARK: Todo actions

    func addTodo(_ text: String) {
        guard !text.isEmpty else { return }
        let newTodo = TodoItem(text: text)
        todos.append(newTodo)
    }

    func toggleTodo(_ id: UUID) {
        if let index = todos.firstIndex(where: { $0.id == id }) {
            todos[index].isCompleted.toggle()
        }
    }

    func deleteTodo(_ id: UUID) {
        todos.removeAll { $0.id == id }
    }

    func clearCompleted() {
        todos.removeAll { $0.isCompleted }
    }

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

    var activeCount: Int {
        todos.filter { !$0.isCompleted }.count
    }

    var completedCount: Int {
        todos.filter { $0.isCompleted }.count
    }
}

// MARK: - Root View

/// Tabbed component showcase demonstrating Raven framework capabilities
@MainActor
struct TodoApp: View {
    @StateObject var store = ShowcaseStore()

    @State private var newTodoText = ""

    var body: some View {
        VStack(spacing: 0) {
            // Header
            ShowcaseHeader()

            // Tab bar
            TabBar(selectedTab: store.selectedTab) { tab in
                store.selectedTab = tab
            }

            // Tab content
            if store.selectedTab == "todos" {
                TodosTab(
                    store: store,
                    newTodoText: $newTodoText
                )
            }
            if store.selectedTab == "controls" {
                ControlsTab(store: store)
            }
            if store.selectedTab == "display" {
                DisplayTab()
            }
            if store.selectedTab == "layout" {
                LayoutTab()
            }
        }
    }
}

// MARK: - Header

@MainActor
struct ShowcaseHeader: View {
    var body: some View {
        VStack(spacing: 4) {
            Text("Raven Component Showcase")
                .font(.title)
                .foregroundColor(.white)

            Text("Cross-compiled SwiftUI running in the browser")
                .font(.caption)
                .foregroundColor(Color(hex: "#cbd5e1"))
        }
        .padding(20)
        .background(Color(hex: "#1e293b"))
    }
}

// MARK: - Tab Bar

@MainActor
struct TabBar: View {
    let selectedTab: String
    let onSelect: @MainActor (String) -> Void

    var body: some View {
        HStack(spacing: 0) {
            TabButton(label: "Todos", tab: "todos", isSelected: selectedTab == "todos", onSelect: onSelect)
            TabButton(label: "Controls", tab: "controls", isSelected: selectedTab == "controls", onSelect: onSelect)
            TabButton(label: "Display", tab: "display", isSelected: selectedTab == "display", onSelect: onSelect)
            TabButton(label: "Layout", tab: "layout", isSelected: selectedTab == "layout", onSelect: onSelect)
        }
        .background(Color(hex: "#f1f5f9"))
    }
}

@MainActor
struct TabButton: View {
    let label: String
    let tab: String
    let isSelected: Bool
    let onSelect: @MainActor (String) -> Void

    var body: some View {
        Button(label) {
            onSelect(tab)
        }
        .padding(12)
        .background(isSelected ? Color.white : Color.clear)
        .foregroundColor(isSelected ? Color(hex: "#1e293b") : Color(hex: "#64748b"))
        .font(.body)
    }
}

// MARK: - Todos Tab

@MainActor
struct TodosTab: View {
    let store: ShowcaseStore
    @Binding var newTodoText: String

    var body: some View {
        VStack(spacing: 16) {
            // Add todo input
            HStack(spacing: 8) {
                TextField("What needs to be done?", text: $newTodoText)

                Button("Add") {
                    store.addTodo(newTodoText)
                    newTodoText = ""
                }
                .padding(8)
                .background(Color(hex: "#3b82f6"))
                .foregroundColor(.white)
                .cornerRadius(6)
            }

            // Stats
            HStack(spacing: 16) {
                Text("\(store.activeCount) active")
                    .font(.caption)
                    .foregroundColor(Color(hex: "#64748b"))

                Text("\(store.completedCount) completed")
                    .font(.caption)
                    .foregroundColor(Color(hex: "#64748b"))
            }

            // Filter buttons
            HStack(spacing: 8) {
                Text("Show:")
                    .font(.caption)

                ForEach(ShowcaseStore.Filter.allCases, id: \.self) { filter in
                    Button(filter.rawValue) {
                        store.filter = filter
                    }
                    .padding(6)
                    .background(store.filter == filter ? Color(hex: "#3b82f6") : Color(hex: "#e2e8f0"))
                    .foregroundColor(store.filter == filter ? Color.white : Color(hex: "#334155"))
                    .cornerRadius(4)
                    .font(.caption)
                }
            }

            // Todo list
            if store.filteredTodos.isEmpty {
                Text("No todos to display")
                    .foregroundColor(Color(hex: "#94a3b8"))
                    .padding(20)
            } else {
                List(store.filteredTodos) { todo in
                    HStack(spacing: 12) {
                        Button(todo.isCompleted ? "[x]" : "[ ]") {
                            store.toggleTodo(todo.id)
                        }
                        .foregroundColor(todo.isCompleted ? Color(hex: "#22c55e") : Color(hex: "#94a3b8"))

                        Text(todo.text)
                            .foregroundColor(todo.isCompleted ? Color(hex: "#94a3b8") : Color(hex: "#1e293b"))

                        Spacer()

                        Button("Delete") {
                            store.deleteTodo(todo.id)
                        }
                        .foregroundColor(Color(hex: "#ef4444"))
                        .font(.caption)
                    }
                }
            }

            // Clear completed
            if store.completedCount > 0 {
                Button("Clear Completed (\(store.completedCount))") {
                    store.clearCompleted()
                }
                .padding(8)
                .background(Color(hex: "#fee2e2"))
                .foregroundColor(Color(hex: "#dc2626"))
                .cornerRadius(6)
                .font(.caption)
            }
        }
        .padding(16)
    }
}

// MARK: - Controls Tab

@MainActor
struct ControlsTab: View {
    let store: ShowcaseStore

    var body: some View {
        VStack(spacing: 16) {
            // Toggle section
            SectionCard(title: "Toggle") {
                VStack(spacing: 8) {
                    Toggle("Dark Mode", isOn: Binding(
                        get: { store.toggleValue },
                        set: { store.toggleValue = $0 }
                    ))

                    Text(store.toggleValue ? "Enabled" : "Disabled")
                        .font(.caption)
                        .foregroundColor(Color(hex: "#64748b"))
                }
            }

            // Slider section
            SectionCard(title: "Slider") {
                VStack(spacing: 8) {
                    Slider(value: Binding(
                        get: { store.sliderValue },
                        set: { store.sliderValue = $0 }
                    ), in: 0...100, step: 1)

                    Text("Value: \(Int(store.sliderValue))")
                        .font(.caption)
                        .foregroundColor(Color(hex: "#64748b"))
                }
            }

            // Stepper section
            SectionCard(title: "Stepper") {
                HStack(spacing: 12) {
                    Stepper("Quantity", value: Binding(
                        get: { store.stepperValue },
                        set: { store.stepperValue = $0 }
                    ), in: -10...10)

                    Text("\(store.stepperValue)")
                        .font(.headline)
                        .foregroundColor(Color(hex: "#1e293b"))
                }
            }

            // Text input section
            SectionCard(title: "SecureField") {
                VStack(spacing: 8) {
                    SecureField("Enter password", text: Binding(
                        get: { store.secureText },
                        set: { store.secureText = $0 }
                    ))

                    Text("Length: \(store.secureText.count) characters")
                        .font(.caption)
                        .foregroundColor(Color(hex: "#64748b"))
                }
            }

            // Progress section
            SectionCard(title: "ProgressView") {
                VStack(spacing: 8) {
                    ProgressView(value: store.progressValue, total: 1.0)

                    Text("\(Int(store.progressValue * 100))% complete")
                        .font(.caption)
                        .foregroundColor(Color(hex: "#64748b"))
                }
            }
        }
        .padding(16)
    }
}

// MARK: - Display Tab

@MainActor
struct DisplayTab: View {
    var body: some View {
        VStack(spacing: 16) {
            // Typography section
            SectionCard(title: "Typography") {
                VStack(spacing: 8) {
                    Text("Title Style")
                        .font(.title)
                        .foregroundColor(Color(hex: "#1e293b"))

                    Text("Headline Style")
                        .font(.headline)
                        .foregroundColor(Color(hex: "#334155"))

                    Text("Body Style - regular paragraph text for content areas")
                        .font(.body)
                        .foregroundColor(Color(hex: "#475569"))

                    Text("Caption Style - small text for labels and metadata")
                        .font(.caption)
                        .foregroundColor(Color(hex: "#94a3b8"))
                }
            }

            // Divider section
            SectionCard(title: "Divider") {
                VStack(spacing: 8) {
                    Text("Content above")
                        .font(.body)
                    Divider()
                    Text("Content below")
                        .font(.body)
                }
            }

            // Progress indicators section
            SectionCard(title: "Progress Indicators") {
                VStack(spacing: 12) {
                    ProgressView(value: 0.25, total: 1.0)
                    Text("25%")
                        .font(.caption)
                        .foregroundColor(Color(hex: "#64748b"))

                    ProgressView(value: 0.65, total: 1.0)
                    Text("65%")
                        .font(.caption)
                        .foregroundColor(Color(hex: "#64748b"))

                    ProgressView(value: 1.0, total: 1.0)
                    Text("100%")
                        .font(.caption)
                        .foregroundColor(Color(hex: "#22c55e"))
                }
            }

            // Link section
            SectionCard(title: "Link") {
                VStack(spacing: 8) {
                    Link("Raven on GitHub", destination: URL(string: "https://github.com/nicktowe/raven")!)

                    Link("Swift.org", destination: URL(string: "https://swift.org")!)
                }
            }

            // Spacer demonstration
            SectionCard(title: "Spacer") {
                VStack(spacing: 8) {
                    HStack(spacing: 0) {
                        Text("Left")
                            .foregroundColor(Color(hex: "#1e293b"))
                        Spacer()
                        Text("Right")
                            .foregroundColor(Color(hex: "#1e293b"))
                    }
                    .padding(8)
                    .background(Color(hex: "#f1f5f9"))
                    .cornerRadius(4)

                    HStack(spacing: 0) {
                        Spacer()
                        Text("Centered with Spacers")
                            .foregroundColor(Color(hex: "#1e293b"))
                        Spacer()
                    }
                    .padding(8)
                    .background(Color(hex: "#f1f5f9"))
                    .cornerRadius(4)
                }
            }
        }
        .padding(16)
    }
}

// MARK: - Layout Tab

// Split into sub-views to avoid deeply nested generic types that crash WASM's
// swift_getTypeByMangledName (memory access out of bounds on huge type metadata).

@MainActor
struct LayoutTab: View {
    var body: some View {
        VStack(spacing: 16) {
            VStackDemo()
            HStackDemo()
            ZStackDemo()
            NestedLayoutDemo()
            ModifierShowcase()
        }
        .padding(16)
    }
}

@MainActor
struct VStackDemo: View {
    var body: some View {
        SectionCard(title: "VStack") {
            VStack(spacing: 8) {
                Text("Item 1")
                    .padding(12)
                    .background(Color(hex: "#dbeafe"))
                    .foregroundColor(Color(hex: "#1e40af"))
                    .cornerRadius(6)

                Text("Item 2")
                    .padding(12)
                    .background(Color(hex: "#dcfce7"))
                    .foregroundColor(Color(hex: "#166534"))
                    .cornerRadius(6)

                Text("Item 3")
                    .padding(12)
                    .background(Color(hex: "#fef9c3"))
                    .foregroundColor(Color(hex: "#854d0e"))
                    .cornerRadius(6)
            }
        }
    }
}

@MainActor
struct HStackDemo: View {
    var body: some View {
        SectionCard(title: "HStack") {
            HStack(spacing: 8) {
                Text("A")
                    .padding(16)
                    .background(Color(hex: "#e0e7ff"))
                    .foregroundColor(Color(hex: "#3730a3"))
                    .cornerRadius(6)

                Text("B")
                    .padding(16)
                    .background(Color(hex: "#fce7f3"))
                    .foregroundColor(Color(hex: "#9d174d"))
                    .cornerRadius(6)

                Text("C")
                    .padding(16)
                    .background(Color(hex: "#ccfbf1"))
                    .foregroundColor(Color(hex: "#115e59"))
                    .cornerRadius(6)
            }
        }
    }
}

@MainActor
struct ZStackDemo: View {
    var body: some View {
        SectionCard(title: "ZStack") {
            ZStack {
                Text("Back Layer")
                    .padding(24)
                    .background(Color(hex: "#bfdbfe"))
                    .foregroundColor(Color(hex: "#1e40af"))
                    .cornerRadius(8)

                Text("Front Layer")
                    .padding(12)
                    .background(Color(hex: "#fecaca"))
                    .foregroundColor(Color(hex: "#991b1b"))
                    .cornerRadius(8)
                    .opacity(0.9)
            }
            .frame(height: 100)
        }
    }
}

@MainActor
struct NestedLayoutDemo: View {
    var body: some View {
        SectionCard(title: "Nested Layout") {
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    VStack(spacing: 4) {
                        Text("Top Left")
                            .font(.caption)
                        Text("Detail")
                            .font(.caption)
                            .foregroundColor(Color(hex: "#64748b"))
                    }
                    .padding(12)
                    .background(Color(hex: "#f0fdf4"))
                    .cornerRadius(6)

                    VStack(spacing: 4) {
                        Text("Top Right")
                            .font(.caption)
                        Text("Detail")
                            .font(.caption)
                            .foregroundColor(Color(hex: "#64748b"))
                    }
                    .padding(12)
                    .background(Color(hex: "#fef2f2"))
                    .cornerRadius(6)
                }

                HStack(spacing: 8) {
                    Text("Full Width Bottom")
                        .font(.caption)
                        .foregroundColor(Color(hex: "#1e293b"))

                    Spacer()

                    Text("Right-aligned")
                        .font(.caption)
                        .foregroundColor(Color(hex: "#64748b"))
                }
                .padding(12)
                .background(Color(hex: "#f8fafc"))
                .cornerRadius(6)
            }
        }
    }
}

@MainActor
struct ModifierShowcase: View {
    var body: some View {
        SectionCard(title: "View Modifiers") {
            VStack(spacing: 8) {
                Text("Shadow")
                    .padding(12)
                    .background(Color.white)
                    .cornerRadius(8)
                    .shadow(color: Color.gray.opacity(0.4), radius: 4, x: 0, y: 2)

                Text("Opacity 50%")
                    .padding(12)
                    .background(Color(hex: "#3b82f6"))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .opacity(0.5)

                Text("Large Corner Radius")
                    .padding(12)
                    .background(Color(hex: "#8b5cf6"))
                    .foregroundColor(.white)
                    .cornerRadius(20)
            }
        }
    }
}

// MARK: - Reusable Section Card

@MainActor
struct SectionCard<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(Color(hex: "#1e293b"))

            content
        }
        .padding(16)
        .background(Color(hex: "#f9fafb"))
        .cornerRadius(8)
    }
}
