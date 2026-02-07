import Foundation
import Raven
import JavaScriptKit

// Import Raven's ObservableObject explicitly to avoid ambiguity with Foundation
typealias ObservableObject = Foundation.ObservableObject
typealias Published = Raven.Published

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
    @Published var pickerSelection: String = "option1"
    @Published var disclosureExpanded: Bool = false
    @Published var colorPickerValue: Color = .blue
    @Published var datePickerValue: Date = Date()
    @Published var demoTabSelection: Int = 0

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
struct ContentView: View {
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
                LayoutTab(store: store)
            }
            if store.selectedTab == "forms" {
                FormsTab(store: store)
            }
            if store.selectedTab == "effects" {
                EffectsTab()
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

            Text("Cross-compiled SwiftUI running in the browser yaaaay")
                .font(.caption)
                .foregroundColor(Color.tertiaryLabel)
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
            TabButton(label: "Forms", tab: "forms", isSelected: selectedTab == "forms", onSelect: onSelect)
            TabButton(label: "Effects", tab: "effects", isSelected: selectedTab == "effects", onSelect: onSelect)
        }
        .background(Color.secondarySystemBackground)
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
        .background(isSelected ? Color.systemBackground : Color.clear)
        .foregroundColor(isSelected ? Color.accent : Color.secondaryLabel)
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

            // Todo list
            if store.filteredTodos.isEmpty {
                Text("No todos to display")
                    .foregroundColor(Color.tertiaryLabel)
                    .padding(20)
            } else {
                List(store.filteredTodos) { todo in
                    HStack(spacing: 12) {
                        Button(todo.isCompleted ? "[x]" : "[ ]") {
                            store.toggleTodo(todo.id)
                        }
                        .foregroundColor(todo.isCompleted ? Color.green : Color.tertiaryLabel)

                        Text(todo.text)
                            .foregroundColor(todo.isCompleted ? Color.tertiaryLabel : Color.label)

                        Spacer()

                        Button("Delete") {
                            store.deleteTodo(todo.id)
                        }
                        .foregroundColor(Color.red)
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
                .background(Color.red.opacity(0.1))
                .foregroundColor(Color.red)
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
    let store: ShowcaseStore

    var body: some View {
        VStack(spacing: 16) {
            LayoutBasicDemos()
            LayoutAdvancedDemos(store: store)
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
            NestedLayoutDemo()
            ModifierShowcase()
        }
    }
}

@MainActor
struct LayoutAdvancedDemos: View {
    let store: ShowcaseStore

    var body: some View {
        VStack(spacing: 16) {
            GridDemo()
            LazyVGridDemo()
            LazyVStackDemo()
            GeometryReaderDemo()
            TabViewDemo(store: store)
            NavigationDemo()
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

// MARK: - TabView Demo

@MainActor
struct TabViewDemo: View {
    let store: ShowcaseStore

    var body: some View {
        SectionCard(title: "TabView") {
            VStack(spacing: 8) {
                TabView(selection: Binding(
                    get: { store.demoTabSelection },
                    set: { store.demoTabSelection = $0 }
                )) {
                    VStack(spacing: 8) {
                        Text("Home Content")
                            .font(.headline)
                        Text("Welcome to the home tab")
                            .font(.caption)
                            .foregroundColor(Color.secondaryLabel)
                    }
                    .padding(16)
                    .tabItem { Text("Home") }
                    .tag(0)

                    VStack(spacing: 8) {
                        Text("Search Content")
                            .font(.headline)
                        Text("Find what you need")
                            .font(.caption)
                            .foregroundColor(Color.secondaryLabel)
                    }
                    .padding(16)
                    .tabItem { Text("Search") }
                    .tag(1)

                    VStack(spacing: 8) {
                        Text("Profile Content")
                            .font(.headline)
                        Text("Your account details")
                            .font(.caption)
                            .foregroundColor(Color.secondaryLabel)
                    }
                    .padding(16)
                    .tabItem { Text("Profile") }
                    .tag(2)
                }

                Text("Selected tab: \(store.demoTabSelection)")
                    .font(.caption)
                    .foregroundColor(Color.secondaryLabel)
            }
        }
    }
}

// MARK: - Navigation Demo

@MainActor
struct NavigationDemo: View {
    var body: some View {
        SectionCard(title: "NavigationStack") {
            NavigationStack {
                VStack(spacing: 0) {
                    NavigationLink(destination: Text("Detail View")) {
                        HStack(spacing: 8) {
                            Text("Settings")
                                .foregroundColor(Color.label)
                        }
                    }

                    Divider()

                    NavigationLink(destination: Text("About View")) {
                        HStack(spacing: 8) {
                            Text("About")
                                .foregroundColor(Color.label)
                        }
                    }

                    Divider()

                    NavigationLink(destination: Text("Help View")) {
                        HStack(spacing: 8) {
                            Text("Help")
                                .foregroundColor(Color.label)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Forms Tab

@MainActor
struct FormsTab: View {
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
        .padding(16)
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
