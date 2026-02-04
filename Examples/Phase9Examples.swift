import Raven

// MARK: - Phase 9 Examples: Integration of All Phase 9 Features

/// This file demonstrates real-world usage of Phase 9 features:
/// - @Observable and @Bindable for state management
/// - ContentUnavailableView for empty states
/// - Interaction modifiers (.disabled, .onTapGesture, .onAppear, .onDisappear, .onChange)
/// - Layout modifiers (.clipped, .aspectRatio, .fixedSize)
/// - Text modifiers (.lineLimit, .multilineTextAlignment, .truncationMode)

// MARK: - Example 1: User Settings Form with @Observable

/// A complete settings form demonstrating @Observable and @Bindable
/// with various modifiers for a polished UI
@MainActor
final class UserSettings: Observable {
    let _$observationRegistrar = ObservationRegistrar()

    private var _username: String
    var username: String {
        get { _username }
        set {
            _$observationRegistrar.willSet()
            _username = newValue
        }
    }

    private var _email: String
    var email: String {
        get { _email }
        set {
            _$observationRegistrar.willSet()
            _email = newValue
        }
    }

    private var _isDarkMode: Bool
    var isDarkMode: Bool {
        get { _isDarkMode }
        set {
            _$observationRegistrar.willSet()
            _isDarkMode = newValue
        }
    }

    private var _fontSize: Double
    var fontSize: Double {
        get { _fontSize }
        set {
            _$observationRegistrar.willSet()
            _fontSize = newValue
        }
    }

    private var _notificationsEnabled: Bool
    var notificationsEnabled: Bool {
        get { _notificationsEnabled }
        set {
            _$observationRegistrar.willSet()
            _notificationsEnabled = newValue
        }
    }

    // Computed property for validation
    var isValid: Bool {
        !username.isEmpty && !email.isEmpty && email.contains("@")
    }

    // Computed property for display
    var displayName: String {
        username.isEmpty ? "Guest User" : username
    }

    init(
        username: String = "",
        email: String = "",
        isDarkMode: Bool = false,
        fontSize: Double = 14.0,
        notificationsEnabled: Bool = true
    ) {
        self._username = username
        self._email = email
        self._isDarkMode = isDarkMode
        self._fontSize = fontSize
        self._notificationsEnabled = notificationsEnabled
        setupObservation()
    }

    func reset() {
        username = ""
        email = ""
        isDarkMode = false
        fontSize = 14.0
        notificationsEnabled = true
    }
}

struct UserSettingsView: View {
    @Bindable var settings: UserSettings
    @State private var showResetConfirmation = false

    var body: some View {
        VStack(spacing: 24) {
            // Header
            Text("User Settings")
                .font(.largeTitle)
                .lineLimit(1)
                .truncationMode(.tail)
                .onAppear {
                    print("Settings view appeared")
                }

            // Account Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Account")
                    .font(.title2)
                    .lineLimit(1)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Username")
                        .font(.headline)
                    TextField("Enter username", text: $settings.username)
                        .onChange(of: settings.username) { newValue in
                            print("Username changed to: \(newValue)")
                        }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Email")
                        .font(.headline)
                    TextField("Enter email", text: $settings.email)
                        .onChange(of: settings.email) { newValue in
                            print("Email changed to: \(newValue)")
                        }
                }
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(12)
            .clipped()

            // Appearance Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Appearance")
                    .font(.title2)
                    .lineLimit(1)

                Toggle("Dark Mode", isOn: $settings.isDarkMode)
                    .onChange(of: settings.isDarkMode) { newValue in
                        print("Dark mode: \(newValue ? "enabled" : "disabled")")
                    }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Font Size: \(Int(settings.fontSize))pt")
                        .font(.headline)

                    Slider(value: $settings.fontSize, in: 10...24, step: 2)
                        .onChange(of: settings.fontSize) { newSize in
                            print("Font size: \(newSize)")
                        }

                    Text("Preview text at current size")
                        .lineLimit(1)
                }
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(12)
            .clipped()

            // Notifications Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Notifications")
                    .font(.title2)
                    .lineLimit(1)

                Toggle("Enable Notifications", isOn: $settings.notificationsEnabled)
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(12)

            // Display current settings
            VStack(alignment: .leading, spacing: 8) {
                Text("Current Profile:")
                    .font(.headline)
                Text("Display Name: \(settings.displayName)")
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text("Email: \(settings.email.isEmpty ? "Not set" : settings.email)")
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text("Theme: \(settings.isDarkMode ? "Dark" : "Light")")
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)

            // Action Buttons
            HStack(spacing: 12) {
                Button("Save Settings") {
                    print("Settings saved")
                }
                .disabled(!settings.isValid)

                Button("Reset to Defaults") {
                    settings.reset()
                }
            }
        }
        .padding()
        .aspectRatio(2/3, contentMode: .fit)
        .onDisappear {
            print("Settings view disappeared")
        }
    }
}

// MARK: - Example 2: ContentUnavailableView States

/// Demonstrates different ContentUnavailableView scenarios
struct ContentUnavailableExamples: View {
    var body: some View {
        VStack(spacing: 40) {
            // Empty list state
            ContentUnavailableView(
                "No Messages",
                systemImage: "envelope.open",
                description: Text("You don't have any messages yet. Start a conversation to see your messages here.")
                    .lineLimit(3)
                    .multilineTextAlignment(.center)
            ) {
                Button("New Message") {
                    print("New message tapped")
                }
                .padding()
            }
            .frame(maxHeight: 300)
            .aspectRatio(3/2, contentMode: .fit)
            .clipped()

            Divider()

            // Search empty state
            ContentUnavailableView.search
                .padding()

            Divider()

            // Error state
            ContentUnavailableView(
                "Connection Failed",
                systemImage: "wifi.slash",
                description: Text("Unable to connect to the server. Please check your internet connection and try again.")
                    .lineLimit(4)
                    .multilineTextAlignment(.center)
            ) {
                VStack(spacing: 8) {
                    Button("Retry") {
                        print("Retry tapped")
                    }

                    Button("Cancel") {
                        print("Cancel tapped")
                    }
                }
            }
            .onAppear {
                print("Error state appeared")
            }

            Divider()

            // Permission required state
            ContentUnavailableView(
                "Location Access Required",
                systemImage: "location.slash",
                description: Text("This app needs access to your location to show nearby items.")
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            ) {
                Button("Open Settings") {
                    print("Open settings tapped")
                }
            }
        }
        .padding()
    }
}

// MARK: - Example 3: Interactive Task List

/// A task list demonstrating @Observable with interaction and lifecycle modifiers
@MainActor
final class TaskListState: Observable {
    let _$observationRegistrar = ObservationRegistrar()

    struct Task: Identifiable, Equatable {
        let id: String
        var title: String
        var isCompleted: Bool
    }

    private var _tasks: [Task]
    var tasks: [Task] {
        get { _tasks }
        set {
            _$observationRegistrar.willSet()
            _tasks = newValue
        }
    }

    private var _newTaskTitle: String
    var newTaskTitle: String {
        get { _newTaskTitle }
        set {
            _$observationRegistrar.willSet()
            _newTaskTitle = newValue
        }
    }

    var incompleteTasks: [Task] {
        tasks.filter { !$0.isCompleted }
    }

    var completedTasks: [Task] {
        tasks.filter { $0.isCompleted }
    }

    var isEmpty: Bool {
        tasks.isEmpty
    }

    init(tasks: [Task] = []) {
        self._tasks = tasks
        self._newTaskTitle = ""
        setupObservation()
    }

    func addTask() {
        guard !newTaskTitle.isEmpty else { return }
        let task = Task(id: UUID().uuidString, title: newTaskTitle, isCompleted: false)
        tasks.append(task)
        newTaskTitle = ""
    }

    func toggleTask(id: String) {
        if let index = tasks.firstIndex(where: { $0.id == id }) {
            tasks[index].isCompleted.toggle()
        }
    }

    func deleteTask(id: String) {
        tasks.removeAll { $0.id == id }
    }
}

struct TaskListView: View {
    @Bindable var state: TaskListState

    var body: some View {
        VStack(spacing: 16) {
            // Header
            Text("My Tasks")
                .font(.largeTitle)
                .lineLimit(1)
                .onAppear {
                    print("Task list appeared")
                }

            // Add task input
            HStack {
                TextField("New task", text: $state.newTaskTitle)
                    .onChange(of: state.newTaskTitle) { newValue in
                        print("Task title: \(newValue)")
                    }

                Button("Add") {
                    state.addTask()
                }
                .disabled(state.newTaskTitle.isEmpty)
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(8)

            // Task list or empty state
            if state.isEmpty {
                ContentUnavailableView(
                    "No Tasks",
                    systemImage: "checkmark.circle",
                    description: Text("Add your first task to get started with your to-do list.")
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                ) {
                    Button("Create Task") {
                        state.newTaskTitle = "My first task"
                    }
                }
                .padding()
                .aspectRatio(1, contentMode: .fit)
                .onAppear {
                    print("Empty state shown")
                }
            } else {
                VStack(spacing: 12) {
                    // Incomplete tasks
                    if !state.incompleteTasks.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("To Do (\(state.incompleteTasks.count))")
                                .font(.headline)

                            ForEach(state.incompleteTasks) { task in
                                TaskRow(
                                    task: task,
                                    onToggle: { state.toggleTask(id: task.id) },
                                    onDelete: { state.deleteTask(id: task.id) }
                                )
                            }
                        }
                    }

                    // Completed tasks
                    if !state.completedTasks.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Completed (\(state.completedTasks.count))")
                                .font(.headline)

                            ForEach(state.completedTasks) { task in
                                TaskRow(
                                    task: task,
                                    onToggle: { state.toggleTask(id: task.id) },
                                    onDelete: { state.deleteTask(id: task.id) }
                                )
                            }
                        }
                    }
                }
                .onChange(of: state.tasks.count) { count in
                    print("Task count changed: \(count)")
                }
            }
        }
        .padding()
        .onDisappear {
            print("Task list disappeared")
        }
    }
}

struct TaskRow: View {
    let task: TaskListState.Task
    let onToggle: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack {
            Button(action: onToggle) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
            }
            .disabled(false)

            Text(task.title)
                .lineLimit(2)
                .truncationMode(.tail)
                .strikethrough(task.isCompleted)

            Spacer()

            Button("Delete") {
                onDelete()
            }
        }
        .padding(8)
        .background(task.isCompleted ? Color.green.opacity(0.1) : Color.secondary.opacity(0.05))
        .cornerRadius(6)
        .onTapGesture {
            onToggle()
        }
    }
}

// MARK: - Example 4: Responsive Image Gallery

/// Demonstrates layout modifiers with aspect ratios and clipping
struct ImageGalleryExample: View {
    let images = [
        "photo.artframe",
        "photo.on.rectangle",
        "photo.stack",
        "photo.fill.on.rectangle.fill"
    ]

    var body: some View {
        VStack(spacing: 16) {
            Text("Photo Gallery")
                .font(.title)
                .lineLimit(1)

            // Grid layout with aspect ratio
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    ForEach(0..<2, id: \.self) { index in
                        Image(systemName: images[index])
                            .frame(width: 150, height: 150)
                            .aspectRatio(1, contentMode: .fill)
                            .clipped()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                            .onTapGesture {
                                print("Image \(index) tapped")
                            }
                    }
                }

                HStack(spacing: 12) {
                    ForEach(2..<4, id: \.self) { index in
                        Image(systemName: images[index])
                            .frame(width: 150, height: 150)
                            .aspectRatio(1, contentMode: .fill)
                            .clipped()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                            .onTapGesture {
                                print("Image \(index) tapped")
                            }
                    }
                }
            }

            // Wide image with 16:9 aspect ratio
            Image(systemName: "photo.artframe")
                .frame(width: 320, height: 180)
                .aspectRatio(16/9, contentMode: .fit)
                .clipped()
                .background(Color.blue.opacity(0.2))
                .cornerRadius(12)
                .onAppear {
                    print("Wide image appeared")
                }

            // Portrait image
            Image(systemName: "rectangle.portrait")
                .frame(width: 150, height: 200)
                .aspectRatio(3/4, contentMode: .fill)
                .clipped()
                .background(Color.purple.opacity(0.2))
                .cornerRadius(8)
        }
        .padding()
    }
}

// MARK: - Example 5: Text Formatting Showcase

/// Demonstrates all text modifiers in various contexts
struct TextFormattingShowcase: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Text Formatting Examples")
                .font(.largeTitle)
                .lineLimit(1)
                .truncationMode(.tail)

            // Line limit examples
            VStack(alignment: .leading, spacing: 12) {
                Text("Line Limit")
                    .font(.title2)

                Text("This is a very long text that demonstrates line limiting. It will be truncated after the specified number of lines. This helps maintain clean layouts and prevents text from overflowing.")
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)

                Text("Single line text with ellipsis at the end of a very long sentence")
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
            }

            // Alignment examples
            VStack(alignment: .leading, spacing: 12) {
                Text("Text Alignment")
                    .font(.title2)

                VStack(spacing: 8) {
                    Text("Left aligned\nMultiple lines\nOf text content")
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.1))

                    Text("Center aligned\nMultiple lines\nOf text content")
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green.opacity(0.1))

                    Text("Right aligned\nMultiple lines\nOf text content")
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange.opacity(0.1))
                }
            }

            // Truncation mode examples
            VStack(alignment: .leading, spacing: 12) {
                Text("Truncation Modes")
                    .font(.title2)

                Text("This text is truncated at the tail with an ellipsis at the end")
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .padding()
                    .background(Color.red.opacity(0.1))

                Text("This text is truncated at the head with ellipsis at start")
                    .lineLimit(1)
                    .truncationMode(.head)
                    .padding()
                    .background(Color.purple.opacity(0.1))

                Text("This text is truncated in the middle with ellipsis")
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .padding()
                    .background(Color.yellow.opacity(0.1))
            }

            // Combined modifiers
            VStack(alignment: .leading, spacing: 12) {
                Text("Combined Modifiers")
                    .font(.title2)

                Text("This text uses line limiting, center alignment, and tail truncation together for a polished presentation. It demonstrates how multiple text modifiers can work together.")
                    .lineLimit(3)
                    .multilineTextAlignment(.center)
                    .truncationMode(.tail)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.teal.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding()
    }
}

// MARK: - Example 6: Complete App with All Phase 9 Features

/// A complete mini-app demonstrating all Phase 9 features together
@MainActor
final class AppState: Observable {
    let _$observationRegistrar = ObservationRegistrar()

    enum ViewMode {
        case list
        case empty
        case error
    }

    private var _viewMode: ViewMode
    var viewMode: ViewMode {
        get { _viewMode }
        set {
            _$observationRegistrar.willSet()
            _viewMode = newValue
        }
    }

    private var _searchQuery: String
    var searchQuery: String {
        get { _searchQuery }
        set {
            _$observationRegistrar.willSet()
            _searchQuery = newValue
        }
    }

    private var _items: [String]
    var items: [String] {
        get { _items }
        set {
            _$observationRegistrar.willSet()
            _items = newValue
        }
    }

    private var _isLoading: Bool
    var isLoading: Bool {
        get { _isLoading }
        set {
            _$observationRegistrar.willSet()
            _isLoading = newValue
        }
    }

    var filteredItems: [String] {
        if searchQuery.isEmpty {
            return items
        }
        return items.filter { $0.lowercased().contains(searchQuery.lowercased()) }
    }

    init(viewMode: ViewMode = .list, items: [String] = []) {
        self._viewMode = viewMode
        self._searchQuery = ""
        self._items = items
        self._isLoading = false
        setupObservation()
    }

    func loadData() {
        isLoading = true
        // Simulate loading
        items = ["Item 1", "Item 2", "Item 3", "Sample Item", "Test Data"]
        isLoading = false
        viewMode = .list
    }

    func simulateError() {
        viewMode = .error
    }

    func clear() {
        items = []
        searchQuery = ""
        viewMode = .empty
    }
}

struct CompletePhase9App: View {
    @Bindable var state: AppState

    var body: some View {
        VStack(spacing: 16) {
            // Header
            Text("Phase 9 Demo App")
                .font(.largeTitle)
                .lineLimit(1)
                .truncationMode(.tail)
                .multilineTextAlignment(.center)
                .onAppear {
                    print("App appeared")
                }

            // Search bar
            TextField("Search items...", text: $state.searchQuery)
                .disabled(state.isLoading)
                .onChange(of: state.searchQuery) { query in
                    print("Search query: \(query)")
                }
                .padding(8)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)

            // Content area
            VStack {
                switch state.viewMode {
                case .list:
                    if state.filteredItems.isEmpty && !state.searchQuery.isEmpty {
                        ContentUnavailableView.search
                            .padding()
                            .onAppear {
                                print("No search results")
                            }
                    } else {
                        VStack(spacing: 8) {
                            ForEach(state.filteredItems, id: \.self) { item in
                                HStack {
                                    Text(item)
                                        .lineLimit(1)
                                        .truncationMode(.tail)

                                    Spacer()
                                }
                                .padding(12)
                                .background(Color.secondary.opacity(0.05))
                                .cornerRadius(6)
                                .onTapGesture {
                                    print("Tapped: \(item)")
                                }
                            }
                        }
                        .onChange(of: state.filteredItems.count) { count in
                            print("Filtered items count: \(count)")
                        }
                    }

                case .empty:
                    ContentUnavailableView(
                        "No Items",
                        systemImage: "tray",
                        description: Text("Get started by loading some data.")
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                    ) {
                        Button("Load Data") {
                            state.loadData()
                        }
                    }
                    .padding()
                    .aspectRatio(1, contentMode: .fit)

                case .error:
                    ContentUnavailableView(
                        "Error Loading Data",
                        systemImage: "exclamationmark.triangle",
                        description: Text("Unable to load data. Please try again.")
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                    ) {
                        VStack(spacing: 8) {
                            Button("Retry") {
                                state.loadData()
                            }

                            Button("Clear") {
                                state.clear()
                            }
                        }
                    }
                    .padding()
                }
            }
            .clipped()

            // Action buttons
            HStack(spacing: 12) {
                Button("Load") {
                    state.loadData()
                }
                .disabled(state.isLoading)

                Button("Error") {
                    state.simulateError()
                }

                Button("Clear") {
                    state.clear()
                }
            }
            .padding()
        }
        .padding()
        .fixedSize(horizontal: false, vertical: true)
        .onDisappear {
            print("App disappeared")
        }
    }
}

// MARK: - Usage Examples

/*
 To use these examples:

 1. User Settings Form:
    let settings = UserSettings()
    let view = UserSettingsView(settings: settings)

 2. ContentUnavailableView States:
    let examples = ContentUnavailableExamples()

 3. Interactive Task List:
    let taskState = TaskListState()
    let taskList = TaskListView(state: taskState)

 4. Image Gallery:
    let gallery = ImageGalleryExample()

 5. Text Formatting:
    let textShowcase = TextFormattingShowcase()

 6. Complete App:
    let appState = AppState(viewMode: .empty)
    let app = CompletePhase9App(state: appState)
 */
