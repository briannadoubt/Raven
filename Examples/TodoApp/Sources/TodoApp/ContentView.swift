import Foundation
import Raven
import JavaScriptKit

// MARK: - Unique ID Generation

/// Counter-based UUID generator for WASM
/// Foundation's UUID() relies on WASI `random_get` which is broken in our polyfill
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

// MARK: - Tab Enum

/// Represents each tab in the root TabView.
///
/// Used as the selection value for the TabView binding. Each case maps to a
/// `.tabPath()` route so the browser URL updates when switching tabs.
enum Tab: Hashable, Sendable {
    case todos
    case controls
    case display
    case layout
    case forms
    case effects
}

// MARK: - Store

/// Central store managing all showcase state including todos and form controls
@MainActor
final class ShowcaseStore: Raven.ObservableObject {
    // -- Tab state --
    @Raven.Published var selectedTab: Tab = .todos

    // -- Todo state --
    @Raven.Published var todos: [TodoItem] = []

    @Raven.Published var filter: Filter = .all

    enum Filter: String, CaseIterable, Sendable {
        case all = "All"
        case active = "Active"
        case completed = "Completed"
    }

    // -- Controls state --
    @Raven.Published var toggleValue: Bool = false
    @Raven.Published var sliderValue: Double = 50.0
    @Raven.Published var stepperValue: Int = 0
    @Raven.Published var secureText: String = ""
    @Raven.Published var progressValue: Double = 0.65
    @Raven.Published var pickerSelection: String = "option1"
    @Raven.Published var disclosureExpanded: Bool = false
    @Raven.Published var colorPickerValue: Color = .blue
    @Raven.Published var datePickerValue: Date = Date()
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

/// Tabbed component showcase demonstrating Raven's TabView → NavigationStack architecture.
///
/// Each tab owns a URL path segment via `.tabPath()`. NavigationStack inside each tab
/// manages drill-down navigation (push/pop). Together they produce web-idiomatic URLs:
///
///     /todos                  ← Todos tab selected
///     /todos/detail/abc123    ← Todo detail pushed inside Todos tab
///     /controls               ← Controls tab selected
///
/// Browser back/forward crosses both tab boundaries and navigation stack depth.
@MainActor
struct ContentView: View {
    @StateObject var store = ShowcaseStore()

    @State private var newTodoText = ""

    var body: some View {
        TabView(selection: Binding(
            get: { store.selectedTab },
            set: { store.selectedTab = $0 }
        )) {
            // -- Todos tab --
            NavigationStack {
                TodosTab(store: store, newTodoText: $newTodoText)
                    .navigationTitle("Todos")
            }
            .tabItem { Text("Todos") }
            .tag(Tab.todos)
            .tabPath("/todos")

            // -- Controls tab --
            NavigationStack {
                ControlsTab(store: store)
                    .navigationTitle("Controls")
            }
            .tabItem { Text("Controls") }
            .tag(Tab.controls)
            .tabPath("/controls")

            // -- Display tab --
            NavigationStack {
                DisplayTab()
                    .navigationTitle("Display")
            }
            .tabItem { Text("Display") }
            .tag(Tab.display)
            .tabPath("/display")

            // -- Layout tab --
            NavigationStack {
                LayoutTab()
                    .navigationTitle("Layout")
            }
            .tabItem { Text("Layout") }
            .tag(Tab.layout)
            .tabPath("/layout")

            // -- Forms tab --
            NavigationStack {
                FormsTab(store: store)
                    .navigationTitle("Forms")
            }
            .tabItem { Text("Forms") }
            .tag(Tab.forms)
            .tabPath("/forms")

            // -- Effects tab --
            NavigationStack {
                EffectsTab()
                    .navigationTitle("Effects")
            }
            .tabItem { Text("Effects") }
            .tag(Tab.effects)
            .tabPath("/effects")
        }
    }
}

// MARK: - Todos Tab

/// Demonstrates NavigationStack drill-down inside a TabView tab.
///
/// Tapping a todo pushes a `TodoDetailView` onto the NavigationStack. Because
/// the Todos tab has `.tabPath("/todos")`, the URL stays at `/todos` for the
/// list and would extend to `/todos/detail/:id` for detail views when using
/// path-based `navigationDestination`.
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
                .background(Color.accent)
                .foregroundColor(.white)
                .cornerRadius(6)
            }

            // Stats
            HStack(spacing: 16) {
                Text("\(store.activeCount) active")
                    .font(.caption)
                    .foregroundColor(Color.secondaryLabel)

                Text("\(store.completedCount) completed")
                    .font(.caption)
                    .foregroundColor(Color.secondaryLabel)
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
                    .background(store.filter == filter ? Color.accent : Color.fill)
                    .foregroundColor(store.filter == filter ? Color.white : Color.label)
                    .cornerRadius(4)
                    .font(.caption)
                }
            }

            // Todo list — each item is a NavigationLink to its detail view
            if store.filteredTodos.isEmpty {
                ContentUnavailableView(
                    "No Todos",
                    systemImage: "checklist",
                    description: Text("Add a todo above to get started")
                )
            } else {
                List(store.filteredTodos) { todo in
                    NavigationLink(destination: TodoDetailView(store: store, todoId: todo.id)) {
                        HStack(spacing: 8) {
                            Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(todo.isCompleted ? Color.green : Color.tertiaryLabel)

                            Text(todo.text)
                                .foregroundColor(todo.isCompleted ? Color.tertiaryLabel : Color.label)
                        }
                    }
                }
            }

            // Clear completed
            if store.completedCount > 0 {
                Button("Clear Completed (\(store.completedCount))") {
                    store.clearCompleted()
                }
                .padding(8)
                .background(Color.red.opacity(0.1))
                .foregroundColor(Color.red)
                .cornerRadius(6)
                .font(.caption)
            }
        }
        .padding(16)
    }
}

// MARK: - Todo Detail View

/// Detail view for a single todo, pushed by NavigationStack within the Todos tab.
///
/// Demonstrates NavigationStack drill-down: the back button pops this view,
/// and pressing browser-back from the Todos list switches to the previous tab.
@MainActor
struct TodoDetailView: View {
    let store: ShowcaseStore
    let todoId: UUID

    var body: some View {
        if let todo = store.todos.first(where: { $0.id == todoId }) {
            VStack(spacing: 16) {
                Text(todo.text)
                    .font(.title)

                HStack(spacing: 8) {
                    Text("Status:")
                        .foregroundColor(Color.secondaryLabel)
                    Text(todo.isCompleted ? "Completed" : "Active")
                        .foregroundColor(todo.isCompleted ? Color.green : Color.accent)
                        .font(.headline)
                }

                Divider()

                Button(todo.isCompleted ? "Mark Active" : "Mark Completed") {
                    store.toggleTodo(todoId)
                }
                .padding(12)
                .background(Color.accent.opacity(0.1))
                .foregroundColor(Color.accent)
                .cornerRadius(8)

                Button("Delete Todo") {
                    store.deleteTodo(todoId)
                }
                .padding(12)
                .background(Color.red.opacity(0.1))
                .foregroundColor(Color.red)
                .cornerRadius(8)

                Spacer()
            }
            .padding(16)
            .navigationTitle(todo.text)
            .navigationBarTitleDisplayMode(.inline)
        } else {
            ContentUnavailableView(
                "Todo Not Found",
                systemImage: "questionmark.circle",
                description: Text("This todo may have been deleted")
            )
        }
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
                        .foregroundColor(Color.secondaryLabel)
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
                        .foregroundColor(Color.secondaryLabel)
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
                        .foregroundColor(Color.label)
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
                        .foregroundColor(Color.secondaryLabel)
                }
            }

            // Progress section
            SectionCard(title: "ProgressView") {
                VStack(spacing: 8) {
                    ProgressView(value: store.progressValue, total: 1.0)

                    Text("\(Int(store.progressValue * 100))% complete")
                        .font(.caption)
                        .foregroundColor(Color.secondaryLabel)
                }
            }

            ColorPickerDemo(store: store)
            DatePickerDemo(store: store)
            LabeledContentDemo()
        }
        .padding(16)
    }
}

// MARK: - ColorPicker Demo

@MainActor
struct ColorPickerDemo: View {
    let store: ShowcaseStore
    var body: some View {
        SectionCard(title: "ColorPicker") {
            VStack(spacing: 8) {
                ColorPicker("Theme Color", selection: Binding(
                    get: { store.colorPickerValue },
                    set: { store.colorPickerValue = $0 }
                ), supportsOpacity: false)

                Text("Selected color applied below:")
                    .font(.caption)
                    .foregroundColor(Color.secondaryLabel)

                Text("Sample")
                    .padding(12)
                    .background(store.colorPickerValue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
    }
}

// MARK: - DatePicker Demo

@MainActor
struct DatePickerDemo: View {
    let store: ShowcaseStore
    var body: some View {
        SectionCard(title: "DatePicker") {
            VStack(spacing: 8) {
                DatePicker("Event Date", selection: Binding(
                    get: { store.datePickerValue },
                    set: { store.datePickerValue = $0 }
                ), displayedComponents: .date)

                Text("Date selected")
                    .font(.caption)
                    .foregroundColor(Color.secondaryLabel)
            }
        }
    }
}

// MARK: - LabeledContent Demo

@MainActor
struct LabeledContentDemo: View {
    var body: some View {
        SectionCard(title: "LabeledContent") {
            VStack(spacing: 8) {
                LabeledContent("Name", value: "Raven Framework")
                LabeledContent("Version", value: "0.1.0")
                LabeledContent("Platform", value: "WebAssembly")
                LabeledContent("Language", value: "Swift 6.2")
            }
        }
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
                        .foregroundColor(Color.label)

                    Text("Headline Style")
                        .font(.headline)
                        .foregroundColor(Color.label)

                    Text("Body Style - regular paragraph text for content areas")
                        .font(.body)
                        .foregroundColor(Color.secondaryLabel)

                    Text("Caption Style - small text for labels and metadata")
                        .font(.caption)
                        .foregroundColor(Color.tertiaryLabel)
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
                        .foregroundColor(Color.secondaryLabel)

                    ProgressView(value: 0.65, total: 1.0)
                    Text("65%")
                        .font(.caption)
                        .foregroundColor(Color.secondaryLabel)

                    ProgressView(value: 1.0, total: 1.0)
                    Text("100%")
                        .font(.caption)
                        .foregroundColor(Color.green)
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
                            .foregroundColor(Color.label)
                        Spacer()
                        Text("Right")
                            .foregroundColor(Color.label)
                    }
                    .padding(8)
                    .background(Color.secondarySystemBackground)
                    .cornerRadius(4)

                    HStack(spacing: 0) {
                        Spacer()
                        Text("Centered with Spacers")
                            .foregroundColor(Color.label)
                        Spacer()
                    }
                    .padding(8)
                    .background(Color.secondarySystemBackground)
                    .cornerRadius(4)
                }
            }

            ImageDemo()
            ContentUnavailableDemo()
            ShapesDemo()
        }
        .padding(16)
    }
}

// MARK: - Image Demo

@MainActor
struct ImageDemo: View {
    var body: some View {
        SectionCard(title: "Image") {
            VStack(spacing: 8) {
                HStack(spacing: 16) {
                    Image(systemName: "star.fill")
                    Image(systemName: "heart.fill")
                    Image(systemName: "bell.fill")
                    Image(systemName: "gear")
                }

                Text("System SF Symbol icons")
                    .font(.caption)
                    .foregroundColor(Color.secondaryLabel)
            }
        }
    }
}

// MARK: - ContentUnavailableView Demo

@MainActor
struct ContentUnavailableDemo: View {
    var body: some View {
        SectionCard(title: "ContentUnavailableView") {
            ContentUnavailableView(
                "No Results",
                systemImage: "magnifyingglass",
                description: Text("Try a different search term")
            )
        }
    }
}

// MARK: - Shapes Demo

@MainActor
struct ShapesDemo: View {
    var body: some View {
        SectionCard(title: "Shapes") {
            HStack(spacing: 12) {
                Circle()
                    .fill(Color.accent)
                    .frame(width: 50, height: 50)

                Rectangle()
                    .fill(Color.red)
                    .frame(width: 50, height: 50)

                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.green)
                    .frame(width: 50, height: 50)

                Capsule()
                    .fill(Color.orange)
                    .frame(width: 80, height: 40)
            }
        }
    }
}

// MARK: - Layout Tab

// Split into sub-views to avoid deeply nested generic types that crash WASM's
// swift_getTypeByMangledName (memory access out of bounds on huge type metadata).

@MainActor
struct LayoutTab: View {
    var body: some View {
        VStack(spacing: 16) {
            LayoutBasicDemos()
            LayoutAdvancedDemos()
        }
        .padding(16)
    }
}

@MainActor
struct LayoutBasicDemos: View {
    var body: some View {
        VStack(spacing: 16) {
            VStackDemo()
            HStackDemo()
            ZStackDemo()
            GroupAndClosedRangeDemo()
            NestedLayoutDemo()
            ModifierShowcase()
        }
    }
}

@MainActor
struct LayoutAdvancedDemos: View {
    var body: some View {
        VStack(spacing: 16) {
            GridDemo()
            LazyVGridDemo()
            LazyVStackDemo()
            LazyHGridDemo()
            GeometryReaderDemo()
            ViewThatFitsDemo()
            NavigationViewDemo()
            TableDemo()
        }
    }
}

@MainActor
struct VStackDemo: View {
    var body: some View {
        SectionCard(title: "VStack") {
            VStack(spacing: 8) {
                Text("Item 1")
                    .padding(12)
                    .background(Color.blue.opacity(0.15))
                    .foregroundColor(Color.blue)
                    .cornerRadius(6)

                Text("Item 2")
                    .padding(12)
                    .background(Color.green.opacity(0.15))
                    .foregroundColor(Color.green)
                    .cornerRadius(6)

                Text("Item 3")
                    .padding(12)
                    .background(Color.yellow.opacity(0.2))
                    .foregroundColor(Color.orange)
                    .cornerRadius(6)
            }
        }
    }
}

@MainActor
struct GroupAndClosedRangeDemo: View {
    var body: some View {
        SectionCard(title: "Group + ClosedRange") {
            VStack(alignment: .leading, spacing: 8) {
                Group {
                    Text("Group does not add extra layout.")
                        .font(.caption)
                        .foregroundColor(Color.secondaryLabel)
                    Text("Rows below are rendered by List(1...3).")
                        .font(.caption)
                        .foregroundColor(Color.secondaryLabel)
                }

                List(1...3) { index in
                    Text("Range row \(index)")
                        .padding(6)
                }
                .frame(height: 120)
                .background(Color.secondarySystemBackground)
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
                    .background(Color.indigo.opacity(0.15))
                    .foregroundColor(Color.indigo)
                    .cornerRadius(6)

                Text("B")
                    .padding(16)
                    .background(Color.pink.opacity(0.15))
                    .foregroundColor(Color.pink)
                    .cornerRadius(6)

                Text("C")
                    .padding(16)
                    .background(Color.teal.opacity(0.15))
                    .foregroundColor(Color.teal)
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
                    .background(Color.blue.opacity(0.25))
                    .foregroundColor(Color.blue)
                    .cornerRadius(8)

                Text("Front Layer")
                    .padding(12)
                    .background(Color.red.opacity(0.2))
                    .foregroundColor(Color.red)
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
                            .foregroundColor(Color.secondaryLabel)
                    }
                    .padding(12)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(6)

                    VStack(spacing: 4) {
                        Text("Top Right")
                            .font(.caption)
                        Text("Detail")
                            .font(.caption)
                            .foregroundColor(Color.secondaryLabel)
                    }
                    .padding(12)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(6)
                }

                HStack(spacing: 8) {
                    Text("Full Width Bottom")
                        .font(.caption)
                        .foregroundColor(Color.label)

                    Spacer()

                    Text("Right-aligned")
                        .font(.caption)
                        .foregroundColor(Color.secondaryLabel)
                }
                .padding(12)
                .background(Color.secondarySystemBackground)
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
                    .background(Color.accent)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .opacity(0.5)

                Text("Large Corner Radius")
                    .padding(12)
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(20)
            }
        }
    }
}

// MARK: - Grid Demo

@MainActor
struct GridDemo: View {
    var body: some View {
        SectionCard(title: "Grid") {
            Grid(horizontalSpacing: 8, verticalSpacing: 8) {
                GridRow {
                    Text("R1C1")
                        .padding(8)
                        .background(Color.blue.opacity(0.15))
                        .cornerRadius(4)
                    Text("R1C2")
                        .padding(8)
                        .background(Color.blue.opacity(0.15))
                        .cornerRadius(4)
                    Text("R1C3")
                        .padding(8)
                        .background(Color.blue.opacity(0.15))
                        .cornerRadius(4)
                }
                GridRow {
                    Text("R2C1")
                        .padding(8)
                        .background(Color.green.opacity(0.15))
                        .cornerRadius(4)
                    Text("R2C2")
                        .padding(8)
                        .background(Color.green.opacity(0.15))
                        .cornerRadius(4)
                    Text("R2C3")
                        .padding(8)
                        .background(Color.green.opacity(0.15))
                        .cornerRadius(4)
                }
            }
        }
    }
}

// MARK: - LazyVGrid Demo

@MainActor
struct LazyVGridDemo: View {
    var body: some View {
        SectionCard(title: "LazyVGrid") {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                Text("1")
                    .padding(12)
                    .background(Color.indigo.opacity(0.15))
                    .cornerRadius(4)
                Text("2")
                    .padding(12)
                    .background(Color.pink.opacity(0.15))
                    .cornerRadius(4)
                Text("3")
                    .padding(12)
                    .background(Color.teal.opacity(0.15))
                    .cornerRadius(4)
                Text("4")
                    .padding(12)
                    .background(Color.yellow.opacity(0.2))
                    .cornerRadius(4)
                Text("5")
                    .padding(12)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(4)
                Text("6")
                    .padding(12)
                    .background(Color.blue.opacity(0.15))
                    .cornerRadius(4)
            }
        }
    }
}

// MARK: - LazyVStack Demo

@MainActor
struct LazyVStackDemo: View {
    var body: some View {
        SectionCard(title: "LazyVStack") {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    Text("Lazy Item 1")
                        .padding(8)
                        .background(Color.blue.opacity(0.15))
                        .cornerRadius(4)
                    Text("Lazy Item 2")
                        .padding(8)
                        .background(Color.green.opacity(0.15))
                        .cornerRadius(4)
                    Text("Lazy Item 3")
                        .padding(8)
                        .background(Color.yellow.opacity(0.2))
                        .cornerRadius(4)
                }
            }
            .frame(height: 120)
        }
    }
}

// MARK: - GeometryReader Demo

@MainActor
struct GeometryReaderDemo: View {
    var body: some View {
        SectionCard(title: "GeometryReader") {
            GeometryReader { proxy in
                Text("Size: \(Int(proxy.size.width))x\(Int(proxy.size.height))")
                    .font(.caption)
                    .foregroundColor(Color.secondaryLabel)
            }
            .frame(height: 40)
        }
    }
}

// MARK: - Forms Tab

@MainActor
struct FormsTab: View {
    let store: ShowcaseStore

    var body: some View {
        VStack(spacing: 16) {
            FormsCoreDemos(store: store)
            FormsExtraDemos()
        }
        .padding(16)
    }
}

@MainActor
struct FormsCoreDemos: View {
    let store: ShowcaseStore

    var body: some View {
        VStack(spacing: 16) {
            FormDemo(store: store)
            PickerDemo(store: store)
            GroupBoxDemo()
            ScrollViewDemo()
            DisclosureGroupDemo(store: store)
            LinkDemo()
            MenuDemo()
            ControlGroupDemo()
        }
    }
}

@MainActor
struct FormsExtraDemos: View {
    var body: some View {
        VStack(spacing: 16) {
            EditButtonDemo()
            LabelDemo()
            AsyncImageDemo()
            TextEditorDemo()
            FormattedInputDemo()
        }
    }
}

// MARK: - Form Demo

@MainActor
struct FormDemo: View {
    let store: ShowcaseStore

    var body: some View {
        SectionCard(title: "Form & Section") {
            Form {
                Section(header: "User Info") {
                    Text("Forms render as semantic HTML form elements")
                        .font(.caption)
                        .foregroundColor(Color.secondaryLabel)

                    Toggle("Dark Mode", isOn: Binding(
                        get: { store.toggleValue },
                        set: { store.toggleValue = $0 }
                    ))
                }

                Section(header: "Preferences") {
                    Text("Sections render as fieldset elements with legend headers")
                        .font(.caption)
                        .foregroundColor(Color.secondaryLabel)
                }
            }
        }
    }
}

// MARK: - Picker Demo

@MainActor
struct PickerDemo: View {
    let store: ShowcaseStore

    var body: some View {
        SectionCard(title: "Picker") {
            VStack(spacing: 8) {
                Picker("Theme", selection: Binding(
                    get: { store.pickerSelection },
                    set: { store.pickerSelection = $0 }
                )) {
                    Text("Light").tag("option1")
                    Text("Dark").tag("option2")
                    Text("System").tag("option3")
                }

                Text("Selected: \(store.pickerSelection)")
                    .font(.caption)
                    .foregroundColor(Color.secondaryLabel)
            }
        }
    }
}

// MARK: - GroupBox Demo

@MainActor
struct GroupBoxDemo: View {
    var body: some View {
        SectionCard(title: "GroupBox") {
            GroupBox("Appearance Settings") {
                VStack(spacing: 8) {
                    Text("GroupBox renders as a fieldset with a legend label")
                        .font(.caption)
                        .foregroundColor(Color.secondaryLabel)

                    Text("It provides visual grouping of related content")
                        .font(.caption)
                        .foregroundColor(Color.secondaryLabel)
                }
            }
        }
    }
}

// MARK: - ScrollView Demo

@MainActor
struct ScrollViewDemo: View {
    var body: some View {
        SectionCard(title: "ScrollView") {
            ScrollView {
                VStack(spacing: 4) {
                    Text("Item 1")
                        .padding(8)
                        .background(Color.blue.opacity(0.15))
                        .cornerRadius(4)
                    Text("Item 2")
                        .padding(8)
                        .background(Color.green.opacity(0.15))
                        .cornerRadius(4)
                    Text("Item 3")
                        .padding(8)
                        .background(Color.yellow.opacity(0.2))
                        .cornerRadius(4)
                    Text("Item 4")
                        .padding(8)
                        .background(Color.pink.opacity(0.15))
                        .cornerRadius(4)
                    Text("Item 5")
                        .padding(8)
                        .background(Color.indigo.opacity(0.15))
                        .cornerRadius(4)
                    Text("Item 6")
                        .padding(8)
                        .background(Color.teal.opacity(0.15))
                        .cornerRadius(4)
                }
            }
            .frame(height: 150)
        }
    }
}

// MARK: - DisclosureGroup Demo

@MainActor
struct DisclosureGroupDemo: View {
    let store: ShowcaseStore

    var body: some View {
        SectionCard(title: "DisclosureGroup") {
            VStack(spacing: 4) {
                DisclosureGroup("Settings", isExpanded: Binding(
                    get: { store.disclosureExpanded },
                    set: { store.disclosureExpanded = $0 }
                )) {
                    VStack(spacing: 8) {
                        Text("Hidden content revealed!")
                            .font(.body)
                            .foregroundColor(Color.label)
                        Text("Click the header to collapse")
                            .font(.caption)
                            .foregroundColor(Color.secondaryLabel)
                    }
                }

                Text(store.disclosureExpanded ? "State: Expanded" : "State: Collapsed")
                    .font(.caption)
                    .foregroundColor(Color.secondaryLabel)
            }
        }
    }
}

// MARK: - Link Demo

@MainActor
struct LinkDemo: View {
    var body: some View {
        SectionCard(title: "Link") {
            VStack(spacing: 8) {
                Link("Swift.org", destination: URL(string: "https://swift.org")!)
                Link("WebAssembly", destination: URL(string: "https://webassembly.org")!)
                Link(destination: URL(string: "https://github.com")!) {
                    Text("GitHub (custom label)")
                        .font(.headline)
                }
            }
        }
    }
}

// MARK: - Menu Demo

@MainActor
struct MenuDemo: View {
    var body: some View {
        SectionCard(title: "Menu") {
            Menu("Actions") {
                Button("Copy") { }
                Button("Paste") { }
                Button("Delete") { }
            }
        }
    }
}

// MARK: - ControlGroup Demo

@MainActor
struct ControlGroupDemo: View {
    var body: some View {
        SectionCard(title: "ControlGroup") {
            ControlGroup {
                Button("Bold") { }
                Button("Italic") { }
                Button("Underline") { }
            }
        }
    }
}

// MARK: - Label Demo

@MainActor
struct LabelDemo: View {
    var body: some View {
        SectionCard(title: "Label") {
            VStack(alignment: .leading, spacing: 8) {
                Label("Favorites", systemImage: "star.fill")
                Label("Downloads", systemImage: "arrow.down.circle")
                Label {
                    Text("Custom Label")
                        .font(.caption)
                } icon: {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.accent)
                        .frame(width: 12, height: 12)
                }
            }
        }
    }
}

// MARK: - AsyncImage Demo

@MainActor
struct AsyncImageDemo: View {
    var body: some View {
        SectionCard(title: "AsyncImage") {
            if let url = URL(string: "https://picsum.photos/220/120") {
                AsyncImage(url: url) { phase in
                    if case .success(let image) = phase {
                        image
                            .frame(width: 220, height: 120)
                            .cornerRadius(6)
                    } else if case .failure = phase {
                        Text("Image load failed")
                            .font(.caption)
                            .foregroundColor(Color.secondaryLabel)
                    } else {
                        ProgressView(value: 0.4, total: 1.0)
                    }
                }
            }
        }
    }
}

// MARK: - TextEditor Demo

@MainActor
struct TextEditorDemo: View {
    @State private var notesText = "Draft notes for the next release..."

    var body: some View {
        SectionCard(title: "TextEditor") {
            VStack(spacing: 8) {
                TextEditor(text: Binding(
                    get: { notesText },
                    set: { notesText = $0 }
                ))
                .frame(height: 110)

                Text("Characters: \(notesText.count)")
                    .font(.caption)
                    .foregroundColor(Color.secondaryLabel)
            }
        }
    }
}

// MARK: - Formatted Input Demo

@MainActor
struct FormattedInputDemo: View {
    @State private var currencyAmount = 249.99
    @State private var percentageValue = 73.5
    @State private var phoneNumberValue = "(415) 555-0135"

    var body: some View {
        SectionCard(title: "Formatted Inputs") {
            VStack(spacing: 8) {
                CurrencyField("Amount", value: Binding(
                    get: { currencyAmount },
                    set: { currencyAmount = $0 }
                ))

                NumberFormatField("Completion %", value: Binding(
                    get: { percentageValue },
                    set: { percentageValue = $0 }
                ), formatter: Raven.NumberFormatter.percentage, range: 0...100)

                PhoneNumberField("Phone", text: Binding(
                    get: { phoneNumberValue },
                    set: { phoneNumberValue = $0 }
                ))
            }
        }
    }
}

// MARK: - EditButton Demo

@MainActor
struct EditButtonDemo: View {
    @State private var editMode: EditMode = .inactive

    var body: some View {
        SectionCard(title: "EditButton") {
            VStack(spacing: 8) {
                EditButton()

                Text(editMode.isEditing ? "Editing Enabled" : "Editing Disabled")
                    .font(.caption)
                    .foregroundColor(Color.secondaryLabel)
            }
            .environment(\.editMode, Optional($editMode))
        }
    }
}

// MARK: - LazyHGrid Demo

@MainActor
struct LazyHGridDemo: View {
    var body: some View {
        SectionCard(title: "LazyHGrid") {
            ScrollView(.horizontal) {
                LazyHGrid(rows: [GridItem(.fixed(40)), GridItem(.fixed(40))], spacing: 8) {
                    ForEach(1...12, id: \.self) { index in
                        Text("Cell \(index)")
                            .padding(8)
                            .background(Color.blue.opacity(0.15))
                            .cornerRadius(4)
                    }
                }
            }
            .frame(height: 100)
        }
    }
}

// MARK: - ViewThatFits Demo

@MainActor
struct ViewThatFitsDemo: View {
    var body: some View {
        SectionCard(title: "ViewThatFits") {
            VStack(spacing: 8) {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 6) {
                        Text("Desktop Option")
                        Text("With Extra Details")
                            .foregroundColor(Color.secondaryLabel)
                    }
                    HStack(spacing: 6) {
                        Text("Compact")
                    }
                }
                .padding(8)
                .background(Color.secondarySystemBackground)
                .cornerRadius(6)
                .frame(width: 220)

                Text("Chooses the first layout that fits.")
                    .font(.caption)
                    .foregroundColor(Color.secondaryLabel)
            }
        }
    }
}

// MARK: - NavigationView Demo

@MainActor
struct NavigationViewDemo: View {
    var body: some View {
        SectionCard(title: "NavigationView") {
            NavigationView {
                VStack(spacing: 8) {
                    Text("Legacy navigation container")
                        .font(.caption)
                        .foregroundColor(Color.secondaryLabel)

                    NavigationLink(destination: Text("Legacy detail screen")) {
                        Text("Open detail")
                    }
                }
            }
            .frame(height: 120)
            .background(Color.secondarySystemBackground)
            .cornerRadius(6)
        }
    }
}

// MARK: - Table Demo

struct TableRowData: Identifiable, Sendable {
    let id: Int
    let task: String
    let owner: String
    let status: String
}

@MainActor
struct TableDemo: View {
    private let rows = [
        TableRowData(id: 1, task: "Ship release", owner: "Alex", status: "In Progress"),
        TableRowData(id: 2, task: "Write docs", owner: "Sam", status: "Done"),
        TableRowData(id: 3, task: "Polish UI", owner: "Jordan", status: "Todo")
    ]

    var body: some View {
        SectionCard(title: "Table") {
            Table(rows) {
                TableColumn("Task", value: \TableRowData.task)
                TableColumn("Owner", value: \TableRowData.owner)
                TableColumn("Status", value: \TableRowData.status)
            }
            .frame(height: 160)
        }
    }
}

// MARK: - Effects Tab

@MainActor
struct EffectsTab: View {
    var body: some View {
        VStack(spacing: 16) {
            VisualEffectsDemo()
            TransformDemo()
        }
        .padding(16)
    }
}

// MARK: - Visual Effects Demo

@MainActor
struct VisualEffectsDemo: View {
    var body: some View {
        SectionCard(title: "Visual Effects") {
            VStack(spacing: 12) {
                Text("Blur Effect")
                    .padding(12)
                    .background(Color.accent)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .blur(radius: 2)

                Text("Grayscale")
                    .padding(12)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .grayscale(0.8)

                Text("Brightness 1.3")
                    .padding(12)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .brightness(0.3)

                Text("Contrast 1.5")
                    .padding(12)
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .contrast(1.5)

                Text("Saturation 2.0")
                    .padding(12)
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .saturation(2.0)
            }
        }
    }
}

// MARK: - Transform Effects Demo

@MainActor
struct TransformDemo: View {
    var body: some View {
        SectionCard(title: "Transform Effects") {
            HStack(spacing: 24) {
                Text("Rotated")
                    .padding(12)
                    .background(Color.accent)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .rotationEffect(Angle(degrees: 15))

                Text("Scaled")
                    .padding(12)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .scaleEffect(1.2)

                Text("Offset")
                    .padding(12)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .offset(x: 0, y: -8)
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
                .foregroundColor(Color.label)

            content
        }
        .padding(16)
        .background(Color.secondarySystemBackground)
        .cornerRadius(8)
    }
}
