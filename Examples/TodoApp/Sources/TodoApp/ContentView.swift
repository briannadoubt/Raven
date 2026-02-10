import Foundation
import Raven
import TipKit

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
enum Tab: String, Codable, Hashable, Sendable {
    case todos
    case controls
    case display
    case layout
    case forms
    case effects
    case preferences
}

// MARK: - Store

/// Central store managing all showcase state including todos and form controls
@MainActor
final class ShowcaseStore: Raven.ObservableObject {
    // -- Tab state --
    @AppStorage("TodoApp.selectedTab") var selectedTab: Tab = .todos

    // -- Todo state --
    @Raven.Published var todos: [TodoItem] = []

    @Raven.Published var filter: Filter = .all
    @Raven.Published var searchText: String = ""
    @Raven.Published var isSearchFocused: Bool = false
    @Raven.Published var isDropTargeted: Bool = false
    @Raven.Published var isImportPresented: Bool = false
    @Raven.Published var lastImportedFilesSummary: String = ""
    @Raven.Published var selectedTodoId: UUID? = nil
    @Raven.Published var todosSplitVisibility: NavigationSplitViewVisibility = .all
    @Raven.Published var todoSidebarPath: NavigationPath = NavigationPath()
    @Raven.Published var todoListPath: NavigationPath = NavigationPath()
    @Raven.Published var todoDetailPath: NavigationPath = NavigationPath()

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
        let scopedTodos: [TodoItem]
        switch filter {
        case .all:
            scopedTodos = todos
        case .active:
            scopedTodos = todos.filter { !$0.isCompleted }
        case .completed:
            scopedTodos = todos.filter { $0.isCompleted }
        }

        let query = searchText._raven_trimmingWhitespace()
        guard !query.isEmpty else { return scopedTodos }
        let q = query.lowercased()
        return scopedTodos.filter { $0.text.lowercased().contains(q) }
    }

    var activeCount: Int {
        todos.filter { !$0.isCompleted }.count
    }

    var completedCount: Int {
        todos.filter { $0.isCompleted }.count
    }
}

private extension String {
    func _raven_trimmingWhitespace() -> String {
        var start = startIndex
        while start < endIndex, self[start].isWhitespace {
            start = index(after: start)
        }

        var end = endIndex
        while end > start, self[index(before: end)].isWhitespace {
            end = index(before: end)
        }

        return String(self[start..<end])
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
            TodosTab(store: store, newTodoText: $newTodoText)
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

            // -- Preferences tab --
            NavigationStack {
                PreferencesTab()
                    .navigationTitle("Preferences")
            }
            .tabItem { Text("Prefs") }
            .tag(Tab.preferences)
            .tabPath("/preferences")
        }
    }
}

// MARK: - Preferences Tab (Demo)

private struct _TodoRowCountKey: PreferenceKey {
    static var defaultValue: Int { 0 }
    static func reduce(value: inout Int, nextValue: () -> Int) {
        value += nextValue()
    }
}

private struct _TodoBoundsAnchorKey: PreferenceKey {
    typealias Value = Anchor<RavenCore.CGRect>?

    static var defaultValue: Value { nil }
    static func reduce(value: inout Value, nextValue: () -> Value) {
        // Prefer the most recent anchor if multiple descendants emit.
        value = nextValue() ?? value
    }
}

// MARK: - TipKit (Demo)

private struct _WelcomeTip: Tip {
    // Keep this demo deterministic across reloads (TipKit Parameters persist by default).
    @Parameter(.transient) static var hasSeen: Bool = false

    var title: Text { Text("Welcome to Raven") }

    var message: Text? {
        Text("This is a TipKit-style tip rendered via Raven. It is gated by a @Parameter and a #Rule macro.")
    }

    var actions: [Tips.Action] {
        Tips.Action(title: "Got it") {
            Self.hasSeen = true
        }
    }

    var rules: [Tips.Rule] {
        #Rule(Self.$hasSeen) { hasSeen in
            hasSeen == false
        }
    }
}

@MainActor
private struct PreferencesTab: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("PreferenceKey + overlayPreferenceValue demo")
                .font(.headline)

            VStack(spacing: 8) {
                ForEach(0..<5, id: \.self) { _ in
                    Text("Row")
                        .padding(8)
                        .background(Color.gray.opacity(0.08))
                        .preference(key: _TodoRowCountKey.self, value: 1)
                }
            }
            .padding(12)
            .background(Color.gray.opacity(0.04))
            .overlayPreferenceValue(_TodoRowCountKey.self, alignment: .topTrailing) { count in
                Text("count: \(count)")
                    .font(.caption)
                    .padding(6)
                    .background(Color.accent.opacity(0.15))
            }

            Text("Expected: overlay shows count: 5")
                .font(.caption)
                .foregroundColor(.gray)

            Divider()

            Text("AnchorPreference + GeometryReader demo")
                .font(.headline)

            VStack(spacing: 10) {
                Text("The red outline should snap to the target after the first layout pass.")
                    .font(.caption)
                    .foregroundColor(.gray)

                ZStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.04))

                    GeometryReader { geo in
                        VStack(spacing: 12) {
                            Text("Target below emits an Anchor<CGRect> preference (from inside a GeometryReader)")
                                .font(.caption)
                                .foregroundColor(.gray)

                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.accent.opacity(0.18))
                                .frame(width: 180, height: 80)
                                .overlay(
                                    Text("Target")
                                        .font(.caption)
                                )
                                .anchorPreference(key: _TodoBoundsAnchorKey.self, value: .bounds) { anchor in
                                    anchor
                                }
                        }
                        // Raven doesn't currently support `frame(maxWidth:maxHeight:)`,
                        // so explicitly expand to the geometry reader's container size.
                        .frame(width: geo.size.width, height: geo.size.height)
                        .padding(16)
                    }
                }
                .frame(height: 200)
                .overlayPreferenceValue(_TodoBoundsAnchorKey.self, alignment: .topLeading) { anchor in
                    GeometryReader { geo in
                        let rect = anchor.map { geo[$0] } ?? .zero

                        ZStack(alignment: .topLeading) {
                            Rectangle()
                                .stroke(Color.red, lineWidth: 2)
                                .frame(width: rect.width, height: rect.height)
                                .offset(x: rect.minX, y: rect.minY)

                            Text("x: \(Int(rect.minX)) y: \(Int(rect.minY))  w: \(Int(rect.width)) h: \(Int(rect.height))")
                                .font(.caption2)
                                .padding(6)
                                .background(Color.white.opacity(0.75))
                                .cornerRadius(8)
                                .padding(8)
                        }
                    }
                }
            }

            Divider()

            Text("TipKit demo")
                .font(.headline)

            VStack(spacing: 10) {
                Text("Expected: a popover tip appears on the target until you press \"Got it\".")
                    .font(.caption)
                    .foregroundColor(.gray)

                HStack(spacing: 12) {
                    Text("Tip target")
                        .padding(12)
                        .background(Color.accent.opacity(0.15))
                        .cornerRadius(10)
                        .popoverTip(_WelcomeTip(), arrowEdge: .bottom)

                    Button("Reset tip") {
                        _WelcomeTip.hasSeen = false
                        _WelcomeTip().resetEligibility()
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding(16)
    }
}

// MARK: - Todos Tab

/// Demonstrates a NavigationSplitView-driven master/detail experience inside a TabView tab.
///
/// The sidebar hosts the filter controls, the middle column shows the list, and
/// the detail column renders the selected todo.
@MainActor
struct TodosTab: View {
    let store: ShowcaseStore
    @Binding var newTodoText: String

    var body: some View {
        NavigationSplitView(columnVisibility: Binding(
            get: { store.todosSplitVisibility },
            set: { store.todosSplitVisibility = $0 }
        )) {
            NavigationStack(path: Binding(
                get: { store.todoSidebarPath },
                set: { store.todoSidebarPath = $0 }
            )) {
                TodosSidebar(store: store)
                    .navigationTitle("Todos")
                    .navigationBarTitleDisplayMode(.inline)
            }
        } content: {
            NavigationStack(path: Binding(
                get: { store.todoListPath },
                set: { store.todoListPath = $0 }
            )) {
                TodosListColumn(
                    store: store,
                    newTodoText: $newTodoText,
                    selectedTodoId: Binding(
                        get: { store.selectedTodoId },
                        set: { store.selectedTodoId = $0 }
                    )
                )
                .navigationTitle("List")
                .navigationBarTitleDisplayMode(.inline)
            }
        } detail: {
            TodosDetailColumn(store: store, selectedTodoId: Binding(
                get: { store.selectedTodoId },
                set: { store.selectedTodoId = $0 }
            ))
        }
        .navigationSplitViewStyle(.automatic)
        .onAppear {
            ensureSelectionIsValid()
        }
        .onChange(of: store.selectedTodoId) { _ in
            // Selection changes should reset nested detail navigation.
            store.todoDetailPath = NavigationPath()
        }
        .onChange(of: store.filter) { _ in
            ensureSelectionIsValid()
        }
        .onChange(of: store.searchText) { _ in
            ensureSelectionIsValid()
        }
        .onChange(of: store.todos.count) { _ in
            ensureSelectionIsValid()
        }
    }

    private func ensureSelectionIsValid() {
        if let selectedTodoId = store.selectedTodoId,
           store.filteredTodos.contains(where: { $0.id == selectedTodoId }) {
            return
        }
        store.selectedTodoId = store.filteredTodos.first?.id
    }
}

@MainActor
private struct TodosSidebar: View {
    let store: ShowcaseStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            NavigationLink("Sidebar Help", destination: TodosSidebarHelpView())
                .buttonStyle(.bordered)

            Text("Filter")
                .font(.caption)
                .foregroundColor(Color.secondaryLabel)

            VStack(spacing: 8) {
                ForEach(ShowcaseStore.Filter.allCases, id: \.self) { filter in
                    Button {
                        store.filter = filter
                    } label: {
                        HStack {
                            Text(filter.rawValue)
                            Spacer()
                            Text(filterCountLabel(for: filter))
                                .foregroundColor(Color.secondaryLabel)
                        }
                    }
                    .padding(10)
                    .background(store.filter == filter ? Color.accent.opacity(0.12) : Color.fill)
                    .cornerRadius(8)
                }
            }

            Divider()

            Text("Drag a row to re-add its text, or drop text into the list.")
                .font(.caption)
                .foregroundColor(Color.secondaryLabel)

            Spacer()
        }
        .padding(16)
    }

    private func filterCountLabel(for filter: ShowcaseStore.Filter) -> String {
        switch filter {
        case .all:
            return "\(store.todos.count)"
        case .active:
            return "\(store.activeCount)"
        case .completed:
            return "\(store.completedCount)"
        }
    }
}

@MainActor
private struct TodosSidebarHelpView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sidebar Help")
                .font(.title3)

            Text("This screen is pushed inside the sidebar column's NavigationStack.")
                .font(.caption)
                .foregroundColor(Color.secondaryLabel)

            Text("In SwiftUI it is common to keep independent stacks per column so toolbars, titles, and searchable state stay scoped.")
                .font(.body)

            Spacer()
        }
        .padding(16)
        .navigationTitle("Sidebar Help")
        .navigationBarTitleDisplayMode(.inline)
    }
}

@MainActor
private struct TodosDetailColumn: View {
    let store: ShowcaseStore
    @Binding var selectedTodoId: UUID?

    var body: some View {
        if let selectedTodoId {
            // Common SwiftUI pattern: embed a NavigationStack inside the split view column.
            NavigationStack(path: Binding(
                get: { store.todoDetailPath },
                set: { store.todoDetailPath = $0 }
            )) {
                TodoDetailView(store: store, todoId: selectedTodoId)
            }
        } else {
            ContentUnavailableView(
                "Select a Todo",
                systemImage: "sidebar.left",
                description: Text("Choose an item from the list to see details here.")
            )
        }
    }
}

@MainActor
private struct TodosListColumn: View {
    let store: ShowcaseStore
    @Binding var newTodoText: String
    @Binding var selectedTodoId: UUID?

    var body: some View {
        let base = TodosListColumnBase(
            store: store,
            newTodoText: $newTodoText,
            selectedTodoId: $selectedTodoId
        )

        let padded = base
            .padding(16)
            .contentMargins(.horizontal, 12, for: .scrollContent)
            .containerBackground(Color.secondarySystemBackground.opacity(0.35), for: .automatic)

        let searchable = padded.searchable(
            text: Binding(
                get: { store.searchText },
                set: { store.searchText = $0 }
            ),
            prompt: "Search todos"
        ) {
            ForEach(Array(store.filteredTodos.prefix(5))) { todo in
                Text(todo.text)
                    .searchCompletion(todo.text)
            }
        }

        let suggestions = searchable
            .searchSuggestions {
                if store.searchText.isEmpty {
                    Text("Try searching: build, deploy, learn")
                }
            }
            .searchScopes(
                Binding(
                    get: { Optional(store.filter) },
                    set: { store.filter = $0 ?? .all }
                ),
                scopes: [ShowcaseStore.Filter.all, ShowcaseStore.Filter.active, ShowcaseStore.Filter.completed]
            )
            .searchFocused(
                Binding(
                    get: { store.isSearchFocused },
                    set: { store.isSearchFocused = $0 }
                )
            )

        let tasked = suggestions.task(id: store.searchText, priority: TaskPriority.utility) {
            // Phase 1 demo: task(id:) API re-runs as search query changes.
            await Task.yield()
        }

        return tasked.fileImporter(
            isPresented: Binding(
                get: { store.isImportPresented },
                set: { store.isImportPresented = $0 }
            ),
            allowedContentTypes: [.plainText, .text, .data],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let files):
                store.lastImportedFilesSummary = "Imported \(files.count) file(s)"
            case .failure:
                store.lastImportedFilesSummary = ""
            }
        }
    }
}

@MainActor
private struct TodosListColumnBase: View {
    let store: ShowcaseStore
    @Binding var newTodoText: String
    @Binding var selectedTodoId: UUID?

    var body: some View {
        VStack(spacing: 16) {
            NavigationLink("List Info", destination: TodosListInfoView(store: store))
                .buttonStyle(.bordered)

            // Phase 2 demo: fileImporter API
            HStack(spacing: 10) {
                Button("Import Todos...") {
                    store.isImportPresented = true
                }
                .buttonStyle(.bordered)

                if !store.lastImportedFilesSummary.isEmpty {
                    Text(store.lastImportedFilesSummary)
                        .font(.caption)
                        .foregroundColor(Color.secondaryLabel)
                }
            }

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

            TodosList(
                store: store,
                selectedTodoId: $selectedTodoId
            )

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
    }
}

@MainActor
private struct TodosListInfoView: View {
    let store: ShowcaseStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("List Info")
                .font(.title3)

            LabeledContent("Filter", value: store.filter.rawValue)
            LabeledContent("Count", value: "\(store.filteredTodos.count)")

            Text("This screen is pushed inside the list column's NavigationStack. The detail column remains a separate stack.")
                .font(.caption)
                .foregroundColor(Color.secondaryLabel)

            Spacer()
        }
        .padding(16)
        .navigationTitle("List Info")
        .navigationBarTitleDisplayMode(.inline)
    }
}

@MainActor
private struct TodosList: View {
    let store: ShowcaseStore
    @Binding var selectedTodoId: UUID?

    var body: some View {
        if store.filteredTodos.isEmpty {
            ContentUnavailableView(
                "No Todos",
                systemImage: "checklist",
                description: Text("Add a todo above to get started")
            )
        } else {
            List(store.filteredTodos) { todo in
                Button {
                    selectedTodoId = todo.id
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(todo.isCompleted ? Color.green : Color.tertiaryLabel)

                        Text(todo.text)
                            .foregroundColor(todo.isCompleted ? Color.tertiaryLabel : Color.label)

                        Spacer()
                    }
                    .padding(EdgeInsets(top: 6, leading: 4, bottom: 6, trailing: 4))
                    .background(selectedTodoId == todo.id ? Color.accent.opacity(0.08) : Color.clear)
                    .cornerRadius(6)
                }
                // Phase 2 demo: draggable() API
                .draggable(todo.text)
            }
            // Phase 2 demo: onDrop() API (drop text to create a new todo)
            .onDrop(of: [.plainText, .text], isTargeted: Binding(
                get: { store.isDropTargeted },
                set: { store.isDropTargeted = $0 }
            )) { items in
                handleDrop(items)
            }
        }
    }

    private func handleDrop(_ items: [DropItem]) -> Bool {
        guard let text = items.compactMap({ item -> String? in
            if case .text(let t) = item { return t }
            return nil
        }).first else {
            return false
        }

        let trimmed = text._raven_trimmingWhitespace()
        guard !trimmed.isEmpty else { return false }

        store.addTodo(trimmed)
        return true
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
    @State private var showActionSheet = false

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

                NavigationLink("More Details", destination: TodoMoreDetailsView(todo: todo))
                    .buttonStyle(.bordered)

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

                Button("More Actions") {
                    showActionSheet = true
                }
                .padding(12)
                .background(Color.secondarySystemBackground)
                .cornerRadius(8)

                Spacer()
            }
            .padding(16)
            .navigationTitle(todo.text)
            .navigationBarTitleDisplayMode(.inline)
            .actionSheet(isPresented: $showActionSheet) {
                ActionSheet(
                    title: Text("Todo Actions"),
                    message: Text("Choose what to do with this item."),
                    buttons: [
                        .default(Text(todo.isCompleted ? "Mark Active" : "Mark Completed")) {
                            store.toggleTodo(todoId)
                        },
                        .destructive(Text("Delete Todo")) {
                            store.deleteTodo(todoId)
                        },
                        .cancel()
                    ]
                )
            }
        } else {
            ContentUnavailableView(
                "Todo Not Found",
                systemImage: "questionmark.circle",
                description: Text("This todo may have been deleted")
            )
        }
    }
}

@MainActor
private struct TodoMoreDetailsView: View {
    let todo: TodoItem

    var body: some View {
        VStack(spacing: 12) {
            Text("Details")
                .font(.title3)

            LabeledContent("ID", value: todo.id.uuidString)
            LabeledContent("Status", value: todo.isCompleted ? "Completed" : "Active")

            Text("This screen is pushed inside the detail column's NavigationStack.")
                .font(.caption)
                .foregroundColor(Color.secondaryLabel)

            Spacer()
        }
        .padding(16)
        .navigationTitle("More Details")
        .navigationBarTitleDisplayMode(.inline)
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

            GaugeDemo()

            // Link section
            SectionCard(title: "Link") {
                VStack(spacing: 8) {
                    Link("Raven on GitHub", destination: URL(string: "https://github.com/nicktowe/raven")!)

                    Link("Swift.org", destination: URL(string: "https://swift.org")!)
                }
            }

            ShareLinkDemo()

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
        VStack(spacing: 16) {
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

            SectionCard(title: "Asset Catalog (.xcassets)") {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 12) {
                        Image("RavenMark")
                            .frame(width: 44, height: 44)

                        Text("Image(\"RavenMark\") from Assets.xcassets")
                            .font(.caption)
                            .foregroundColor(Color.secondaryLabel)
                    }

                    HStack(spacing: 12) {
                        Image("RavenCustom")
                            .foregroundColor(Color("BrandPrimary"))

                        Text("Image(\"RavenCustom\") from .symbolset (tintable)")
                            .font(.caption)
                            .foregroundColor(Color.secondaryLabel)
                    }

                    HStack(spacing: 12) {
                        Image("git.commit")
                            .foregroundColor(Color("BrandPrimary"))

                        Text("Image(\"git.commit\") from MoreSFSymbols (.symbolset)")
                            .font(.caption)
                            .foregroundColor(Color.secondaryLabel)
                    }

                    HStack(spacing: 12) {
                        Image("git.branch")
                            .foregroundColor(Color.blue)

                        Text("Image(\"git.branch\") from MoreSFSymbols (.symbolset)")
                            .font(.caption)
                            .foregroundColor(Color.secondaryLabel)
                    }

                    HStack(spacing: 12) {
                        Image("git.merge")
                            .foregroundColor(Color.purple)

                        Text("Image(\"git.merge\") from MoreSFSymbols (.symbolset)")
                            .font(.caption)
                            .foregroundColor(Color.secondaryLabel)
                    }

                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color("BrandPrimary"))
                            .frame(width: 56, height: 22)

                        Text("Color(\"BrandPrimary\") (light/dark)")
                            .font(.caption)
                            .foregroundColor(Color.secondaryLabel)
                    }

                    if let url = Asset.url("SampleText") {
                        Text("Asset.url(\"SampleText\") → \(url)")
                            .font(.caption2)
                            .foregroundColor(Color.tertiaryLabel)
                    } else {
                        Text("Asset.url(\"SampleText\") → (not found)")
                            .font(.caption2)
                            .foregroundColor(Color.tertiaryLabel)
                    }
                }
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

// MARK: - Gauge Demo

@MainActor
struct GaugeDemo: View {
    var body: some View {
        SectionCard(title: "Gauge") {
            VStack(spacing: 12) {
                Gauge(value: 0.6, in: 0...1) {
                    Text("Task Progress")
                } currentValueLabel: {
                    Text("60%")
                } minimumValueLabel: {
                    Text("0%")
                } maximumValueLabel: {
                    Text("100%")
                }

                Gauge("Storage", value: 32, in: 0...64)
            }
        }
    }
}

// MARK: - ShareLink Demo

@MainActor
struct ShareLinkDemo: View {
    private let shareURL = URL(string: "https://github.com/nicktowe/raven")!

    var body: some View {
        SectionCard(title: "ShareLink") {
            VStack(spacing: 8) {
                ShareLink("Share Raven", item: shareURL, subject: "Raven", message: "Check out Raven on GitHub!")

                ShareLink(item: shareURL, subject: "Raven", message: "SwiftUI for the web") {
                    Label("Share with Label", systemImage: "square.and.arrow.up")
                }
            }
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
            NavigationSplitViewDemo()
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

                    Spacer()

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

@MainActor
struct NavigationSplitViewDemo: View {
    @State private var visibility: NavigationSplitViewVisibility = .all

    var body: some View {
        SectionCard(title: "NavigationSplitView") {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Text("Visibility")
                        .font(.caption)
                        .foregroundColor(Color.secondaryLabel)

                    Picker("Visibility", selection: $visibility) {
                        ForEach(NavigationSplitViewVisibility.allCases, id: \.self) { option in
                            Text(option.displayName)
                                .tag(option)
                        }
                    }
                }

                NavigationSplitView(columnVisibility: $visibility) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Sidebar")
                            .font(.headline)
                        Text("Favorites")
                        Text("Projects")
                        Text("Shared")
                    }
                } content: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Content")
                            .font(.headline)
                        Text("Select a project to see details.")
                        ProgressView(value: 0.62)
                    }
                } detail: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Detail")
                            .font(.headline)
                        Text("Project status")
                        LabeledContent("Owner", value: "Jordan")
                        LabeledContent("Due", value: "Mar 12")
                    }
                }
                .navigationSplitViewStyle(.balanced)
                .frame(height: 220)
            }
        }
    }
}

extension NavigationSplitViewVisibility {
    var displayName: String {
        switch self {
        case .automatic:
            return "Automatic"
        case .all:
            return "All"
        case .doubleColumn:
            return "Double Column"
        case .detailOnly:
            return "Detail Only"
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
            EquatableAndModifierDemo()
        }
        .padding(16)
    }
}

// MARK: - EquatableView + EmptyModifier Demo

@MainActor
private struct EquatableAndModifierDemo: View {
    @State private var taps: Int = 0

    var body: some View {
        SectionCard(title: "EquatableView + EmptyModifier") {
	            VStack(spacing: 12) {
	                Button("Tap count: \(taps)") { taps += 1 }

	                // This demonstrates the new SwiftUI-parity API compiling and rendering.
	                // (Raven currently forwards through; future renderer optimizations can
	                // use this as a hint to skip work when the view's Equatable input is unchanged.)
	                Text("Badge value: \(taps % 2) (toggles every 2 taps)")
	                    .padding(10)
	                    .background(Color.accent.opacity(0.12))
	                    .foregroundColor(Color.label)
	                    .cornerRadius(8)
	                    .equatable()
	                    .modifier(EmptyModifier())
	            }
	        }
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
