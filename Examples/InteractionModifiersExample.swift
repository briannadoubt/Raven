import Raven

/// Example demonstrating interaction modifiers in Raven.
///
/// This example shows how to use the five interaction modifiers:
/// - .disabled(_:)
/// - .onTapGesture(count:perform:)
/// - .onAppear(perform:)
/// - .onDisappear(perform:)
/// - .onChange(of:perform:)
struct InteractionModifiersExample: View {
    @State private var count = 0
    @State private var isEnabled = true
    @State private var searchText = ""
    @State private var showAlert = false

    var body: some View {
        VStack {
            // Example 1: Disabled modifier
            Text("Disabled Modifier Example")
                .font(.title)
                .padding()

            Button("Submit Form") {
                print("Form submitted")
            }
            .padding()
            .background(.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            .disabled(!isEnabled)

            Toggle("Enable Button", isOn: $isEnabled)
                .padding()

            // Example 2: OnTapGesture modifier
            Text("Tap Gesture Example")
                .font(.title)
                .padding()

            Text("Single Tap Counter: \(count)")
                .padding()
                .background(.gray)
                .cornerRadius(5)
                .onTapGesture {
                    count += 1
                }

            Text("Double Tap to Reset")
                .padding()
                .background(.red)
                .foregroundColor(.white)
                .cornerRadius(5)
                .onTapGesture(count: 2) {
                    count = 0
                }

            // Example 3: OnAppear and OnDisappear
            Text("Lifecycle Example")
                .font(.title)
                .padding()

            if showAlert {
                Text("This view tracks lifecycle")
                    .padding()
                    .background(.green)
                    .cornerRadius(5)
                    .onAppear {
                        print("Alert appeared")
                    }
                    .onDisappear {
                        print("Alert disappeared")
                    }
            }

            Button(showAlert ? "Hide Alert" : "Show Alert") {
                showAlert.toggle()
            }
            .padding()

            // Example 4: OnChange modifier
            Text("OnChange Example")
                .font(.title)
                .padding()

            TextField("Search", text: $searchText)
                .padding()
                .background(.gray.opacity(0.2))
                .cornerRadius(5)
                .onChange(of: searchText) { newValue in
                    print("Search text changed to: \(newValue)")
                    // In a real app, this would trigger a search
                }

            Text("Current search: \(searchText)")
                .padding()

            // Example 5: Combined modifiers
            Text("Combined Modifiers Example")
                .font(.title)
                .padding()

            Button("Complex Button") {
                print("Button action triggered")
            }
            .padding()
            .background(.purple)
            .foregroundColor(.white)
            .cornerRadius(8)
            .disabled(count > 10)
            .onTapGesture {
                print("Gesture handler triggered")
            }
            .onAppear {
                print("Button appeared in view")
            }
            .onChange(of: count) { newCount in
                if newCount > 10 {
                    print("Count exceeded 10, button disabled")
                }
            }

            Text("Status: Count is \(count), button is \(count > 10 ? "disabled" : "enabled")")
                .padding()
        }
        .padding()
        .onAppear {
            print("Main view appeared")
        }
        .onDisappear {
            print("Main view disappeared")
        }
    }
}

// MARK: - Usage Examples

/// Example showing disabled modifier usage patterns
struct DisabledExamples: View {
    @State private var isLoading = false
    @State private var username = ""
    @State private var password = ""

    var body: some View {
        VStack {
            TextField("Username", text: $username)
            SecureField("Password", text: $password)

            Button("Login") {
                isLoading = true
                // Perform login...
            }
            .disabled(username.isEmpty || password.isEmpty || isLoading)

            if isLoading {
                Text("Loading...")
            }
        }
    }
}

/// Example showing tap gesture patterns
struct TapGestureExamples: View {
    @State private var isFavorite = false
    @State private var tapCount = 0

    var body: some View {
        VStack {
            // Single tap to toggle
            Image(systemName: isFavorite ? "heart.fill" : "heart")
                .font(.largeTitle)
                .foregroundColor(isFavorite ? .red : .gray)
                .onTapGesture {
                    isFavorite.toggle()
                }

            // Double tap for special action
            Text("Tap Count: \(tapCount)")
                .padding()
                .background(.blue)
                .foregroundColor(.white)
                .onTapGesture {
                    tapCount += 1
                }
                .onTapGesture(count: 2) {
                    tapCount = 0
                }
        }
    }
}

/// Example showing lifecycle modifier patterns
struct LifecycleExamples: View {
    @State private var data: [String] = []

    var body: some View {
        List {
            ForEach(data, id: \.self) { item in
                Text(item)
            }
        }
        .onAppear {
            loadData()
        }
        .onDisappear {
            saveState()
        }
    }

    func loadData() {
        // Load data from API or local storage
        data = ["Item 1", "Item 2", "Item 3"]
    }

    func saveState() {
        // Save current state before view disappears
        print("Saving state with \(data.count) items")
    }
}

/// Example showing onChange patterns
struct OnChangeExamples: View {
    @State private var sliderValue: Double = 0.5
    @State private var selectedOption = 0
    @State private var filterText = ""

    var body: some View {
        VStack {
            Slider(value: $sliderValue, in: 0...1)
                .onChange(of: sliderValue) { newValue in
                    print("Slider changed to: \(newValue)")
                    // Update dependent calculations
                }

            Picker("Options", selection: $selectedOption) {
                Text("Option 1").tag(0)
                Text("Option 2").tag(1)
                Text("Option 3").tag(2)
            }
            .onChange(of: selectedOption) { newSelection in
                print("Picker changed to: \(newSelection)")
                // Update UI based on selection
            }

            TextField("Filter", text: $filterText)
                .onChange(of: filterText) { newText in
                    // Debounce and perform filtering
                    performFilter(newText)
                }
        }
    }

    func performFilter(_ text: String) {
        print("Filtering with: \(text)")
    }
}

// MARK: - Real-World Example

/// A complete real-world example combining all interaction modifiers
struct TaskListView: View {
    @State private var tasks: [Task] = []
    @State private var newTaskTitle = ""
    @State private var isAddingTask = false
    @State private var selectedTask: Task?

    var body: some View {
        VStack {
            // Header
            Text("Task Manager")
                .font(.title)
                .padding()
                .onAppear {
                    loadTasks()
                }

            // Add task section
            HStack {
                TextField("New task", text: $newTaskTitle)
                    .padding()
                    .background(.gray.opacity(0.2))
                    .cornerRadius(5)
                    .disabled(isAddingTask)
                    .onChange(of: newTaskTitle) { newValue in
                        // Could add validation here
                        print("Task title: \(newValue)")
                    }

                Button("Add") {
                    addTask()
                }
                .padding()
                .background(.blue)
                .foregroundColor(.white)
                .cornerRadius(5)
                .disabled(newTaskTitle.isEmpty || isAddingTask)
            }
            .padding()

            // Task list
            List {
                ForEach(tasks) { task in
                    TaskRow(task: task)
                        .onTapGesture {
                            selectedTask = task
                        }
                        .onTapGesture(count: 2) {
                            toggleTaskComplete(task)
                        }
                }
            }
            .onDisappear {
                saveTasks()
            }

            // Status bar
            Text("\(tasks.count) tasks, \(tasks.filter(\.isCompleted).count) completed")
                .padding()
                .onChange(of: tasks.count) { newCount in
                    print("Task count changed to: \(newCount)")
                }
        }
    }

    func loadTasks() {
        print("Loading tasks from storage")
        // Load tasks from local storage or API
    }

    func saveTasks() {
        print("Saving tasks to storage")
        // Save tasks to local storage
    }

    func addTask() {
        isAddingTask = true
        // Add task to list
        tasks.append(Task(title: newTaskTitle))
        newTaskTitle = ""
        isAddingTask = false
    }

    func toggleTaskComplete(_ task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isCompleted.toggle()
        }
    }
}

struct TaskRow: View {
    let task: Task

    var body: some View {
        HStack {
            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(task.isCompleted ? .green : .gray)
            Text(task.title)
                .foregroundColor(task.isCompleted ? .gray : .black)
        }
        .padding()
    }
}

struct Task: Identifiable {
    let id = UUID()
    let title: String
    var isCompleted = false
}
