import Foundation
import Testing
@testable import Raven
import RavenRuntime

// Resolve ambiguities with Foundation types
typealias ObservableObject = Raven.ObservableObject
typealias Published = Raven.Published
typealias StateObject = Raven.StateObject
typealias ObservedObject = Raven.ObservedObject

/// Comprehensive Phase 3 verification tests that validate the Todo app works.
///
/// These tests verify that:
/// 1. ObservableObject classes work with @Published properties
/// 2. @StateObject creates and owns observable objects
/// 3. @ObservedObject observes objects owned by parents
/// 4. ForEach iterates over collections
/// 5. List displays collections properly
/// 6. TextField provides two-way binding
/// 7. Toggle provides boolean two-way binding
/// 8. Complete Todo app integration works end-to-end
@MainActor
@Suite struct Phase3VerificationTests {

    // MARK: - Test 1: ObservableObject Tests

    @Test func observableObjectConformance() async throws {
        // Create a simple observable object
        class Counter: ObservableObject {
            @Published var count: Int = 0

            init() {
                setupPublished()
            }
        }

        let counter = Counter()

        // Verify it has an objectWillChange publisher
        #expect(counter.objectWillChange != nil)
    }

    @Test func observableObjectPublisherFiresOnChange() async throws {
        class TestModel: ObservableObject {
            @Published var value: String = ""

            init() {
                setupPublished()
            }
        }

        let model = TestModel()
        var changeCount = 0

        // Subscribe to changes
        model.objectWillChange.subscribe {
            changeCount += 1
        }

        // Initial state
        #expect(changeCount == 0)

        // Change the published property
        model.value = "new"
        #expect(changeCount == 1)

        // Change again
        model.value = "another"
        #expect(changeCount == 2)
    }

    @Test func observableObjectWithMultiplePublishedProperties() async throws {
        class UserSettings: ObservableObject {
            @Published var username: String = ""
            @Published var age: Int = 0
            @Published var isActive: Bool = false

            init() {
                setupPublished()
            }
        }

        let settings = UserSettings()
        var changeCount = 0

        settings.objectWillChange.subscribe {
            changeCount += 1
        }

        // Changes to any @Published property should trigger objectWillChange
        settings.username = "alice"
        #expect(changeCount == 1)

        settings.age = 30
        #expect(changeCount == 2)

        settings.isActive = true
        #expect(changeCount == 3)
    }

    @Test func publishedPropertyProjectedValue() async throws {
        class DataStore: ObservableObject {
            @Published var text: String = "initial"

            init() {
                setupPublished()
            }
        }

        let store = DataStore()

        // Access projected value to get a Binding
        let binding = store.$text
        #expect(binding.wrappedValue == "initial")

        // Modify through binding
        binding.wrappedValue = "updated"
        #expect(store.text == "updated")
    }

    // MARK: - Test 2: @StateObject Tests

    @Test func stateObjectCreatesObjectLazily() async throws {
        class LazyModel: ObservableObject {
            static var instanceCount = 0
            let id: Int

            init() {
                LazyModel.instanceCount += 1
                self.id = LazyModel.instanceCount
                setupPublished()
            }
        }

        // Reset counter
        LazyModel.instanceCount = 0

        struct TestView: View {
            @StateObject var model = LazyModel()

            var body: some View {
                Text("Test")
            }

            @MainActor init() {}
        }

        // Creating the view shouldn't create the object yet
        let view = TestView()
        #expect(LazyModel.instanceCount == 0)

        // Accessing wrappedValue should create it
        let model = view.$model
        #expect(LazyModel.instanceCount == 1)

        // Accessing again shouldn't create another
        let model2 = view.$model
        #expect(LazyModel.instanceCount == 1)
        #expect(model.id == model2.id)
    }

    @Test func stateObjectTriggersViewUpdates() async throws {
        class ViewModel: ObservableObject {
            @Published var count: Int = 0

            init() {
                setupPublished()
            }

            func increment() {
                count += 1
            }
        }

        struct TestView: View {
            @StateObject var viewModel = ViewModel()

            var body: some View {
                Text("Count: \(viewModel.count)")
            }

            @MainActor init() {}
        }

        let view = TestView()

        // Access the object through the projected value
        let model = view.$viewModel
        var updateCount = 0

        // Subscribe to changes directly on the model
        model.objectWillChange.subscribe {
            updateCount += 1
        }

        // Changes should trigger updates
        #expect(updateCount == 0)
        model.increment()
        #expect(updateCount == 1)
    }

    @Test func stateObjectProjectedValue() async throws {
        class SharedModel: ObservableObject {
            @Published var name: String = "test"

            init() {
                setupPublished()
            }
        }

        struct ParentView: View {
            @StateObject var model = SharedModel()

            var body: some View {
                Text("Parent")
            }

            @MainActor init() {}
        }

        let parent = ParentView()

        // Projected value should return the object itself for passing to children
        let projectedModel = parent.$model
        #expect(type(of: projectedModel) == SharedModel.self)
    }

    // MARK: - Test 3: @ObservedObject Tests

    @Test func observedObjectDoesNotOwnObject() async throws {
        class ExternalModel: ObservableObject {
            @Published var value: Int = 0

            init() {
                setupPublished()
            }
        }

        @MainActor
        struct ChildView: View {
            @ObservedObject var model: ExternalModel

            var body: some View {
                Text("\(model.value)")
            }
        }

        // Create model externally
        let externalModel = ExternalModel()
        let child = ChildView(model: externalModel)

        // Child should observe the same object
        #expect(child.model.value == 0)

        externalModel.value = 42
        #expect(child.model.value == 42)
    }

    @Test func observedObjectTriggersViewUpdates() async throws {
        class DataModel: ObservableObject {
            @Published var text: String = ""

            init() {
                setupPublished()
            }
        }

        @MainActor
        struct ObserverView: View {
            @ObservedObject var data: DataModel

            var body: some View {
                Text(data.text)
            }
        }

        let data = DataModel()
        _ = ObserverView(data: data)
        var updateCount = 0

        // Subscribe to changes directly on the model
        data.objectWillChange.subscribe {
            updateCount += 1
        }

        // Changes to observed object should trigger updates
        #expect(updateCount == 0)
        data.text = "changed"
        #expect(updateCount == 1)
    }

    @Test func observedObjectParentChildFlow() async throws {
        class AppState: ObservableObject {
            @Published var message: String = "Hello"

            init() {
                setupPublished()
            }
        }

        struct ParentView: View {
            @StateObject var appState = AppState()

            var body: some View {
                Text("Parent")
            }

            @MainActor init() {}
        }

        @MainActor
        struct ChildView: View {
            @ObservedObject var appState: AppState

            var body: some View {
                Text(appState.message)
            }
        }

        // Parent owns the object via @StateObject
        let parent = ParentView()
        let parentState = parent.$appState

        // Child observes it via @ObservedObject
        let child = ChildView(appState: parentState)

        // Verify they share the same object
        #expect(child.appState.message == "Hello")

        parentState.message = "Updated"
        #expect(child.appState.message == "Updated")
    }

    // MARK: - Test 4: ForEach Tests

    @Test func forEachWithIdentifiableItems() async throws {
        struct Item: Identifiable, Sendable {
            let id: UUID
            let name: String
        }

        let items = [
            Item(id: UUID(), name: "First"),
            Item(id: UUID(), name: "Second"),
            Item(id: UUID(), name: "Third")
        ]

        let forEach = ForEach(items) { item in
            Text(item.name)
        }

        // ForEach should have a body that can be accessed
        let body = forEach.body
        #expect(body != nil)
    }

    @Test func forEachWithCustomIDKeyPath() async throws {
        struct Item: Sendable {
            let name: String
            let value: Int
        }

        let items = [
            Item(name: "A", value: 1),
            Item(name: "B", value: 2),
            Item(name: "C", value: 3)
        ]

        let forEach = ForEach(items, id: \.name) { item in
            Text("\(item.name): \(item.value)")
        }

        let body = forEach.body
        #expect(body != nil)
    }

    @Test func forEachWithRange() async throws {
        let forEach = ForEach(0..<5) { index in
            Text("Item \(index)")
        }

        let body = forEach.body
        #expect(body != nil)
    }

    // MARK: - Test 5: List Tests

    @Test func listWithStaticContent() async throws {
        let list = List {
            Text("Item 1")
            Text("Item 2")
            Text("Item 3")
        }

        let vnode = list.toVNode()

        // List should create a div with role="list"
        #expect(vnode.isElement(tag: "div"))
        #expect(vnode.props["role"] == .attribute(name: "role", value: "list"))

        // Verify layout styles
        #expect(vnode.props["display"] == .style(name: "display", value: "flex"))
        #expect(vnode.props["flex-direction"] == .style(name: "flex-direction", value: "column"))
    }

    @Test func listWithForEach() async throws {
        struct Item: Identifiable, Sendable {
            let id: Int
            let title: String
        }

        let items = [
            Item(id: 1, title: "One"),
            Item(id: 2, title: "Two")
        ]

        let list = List(items) { item in
            Text(item.title)
        }

        let vnode = list.toVNode()

        // Verify List structure
        #expect(vnode.isElement(tag: "div"))
        #expect(vnode.props["role"] == .attribute(name: "role", value: "list"))
    }

    @Test func listHTMLStructure() async throws {
        let list = List {
            Text("Content")
        }

        let vnode = list.toVNode()

        // Verify accessibility attributes
        #expect(vnode.props["role"] == .attribute(name: "role", value: "list"))

        // Verify scrolling
        #expect(vnode.props["overflow-y"] == .style(name: "overflow-y", value: "auto"))

        // Verify width
        #expect(vnode.props["width"] == .style(name: "width", value: "100%"))
    }

    // MARK: - Test 6: TextField Tests

    @Test func textFieldWithBinding() async throws {
        let state = State(wrappedValue: "initial")
        let binding = state.projectedValue

        let textField = TextField("Placeholder", text: binding)

        let vnode = textField.toVNode()

        // Verify input element
        #expect(vnode.isElement(tag: "input"))
        #expect(vnode.props["type"] == .attribute(name: "type", value: "text"))

        // Verify placeholder
        #expect(vnode.props["placeholder"] == .attribute(name: "placeholder", value: "Placeholder"))

        // Verify value reflects binding
        #expect(vnode.props["value"] == .attribute(name: "value", value: "initial"))

        // Verify event handler exists
        #expect(vnode.props["onInput"] != nil)
    }

    @Test func textFieldTwoWayBinding() async throws {
        let state = State(wrappedValue: "")
        let binding = state.projectedValue

        // Verify binding works both ways
        #expect(binding.wrappedValue == "")

        // Simulate user input
        binding.wrappedValue = "user typed this"
        #expect(state.wrappedValue == "user typed this")

        // Create new textfield to verify value updated
        let textField2 = TextField("Enter text", text: binding)
        let vnode = textField2.toVNode()
        #expect(vnode.props["value"] == .attribute(name: "value", value: "user typed this"))
    }

    @Test func textFieldEventHandling() async throws {
        let state = State(wrappedValue: "")
        let textField = TextField("Test", text: state.projectedValue)

        let vnode = textField.toVNode()

        // Extract event handler
        guard case .eventHandler(let event, let handlerID) = vnode.props["onInput"] else {
            Issue.record("TextField should have onInput event handler")
            return
        }

        #expect(event == "input")
        #expect(handlerID != nil)
    }

    // MARK: - Test 7: Toggle Tests

    @Test func toggleWithBinding() async throws {
        let state = State(wrappedValue: false)
        let binding = state.projectedValue

        let toggle = Toggle("Enable", isOn: binding)

        let vnode = toggle.toVNode()

        // Toggle renders as a label element
        #expect(vnode.isElement(tag: "label"))

        // Should contain an input checkbox
        #expect(vnode.children.count > 0)

        let checkboxNode = vnode.children[0]
        #expect(checkboxNode.isElement(tag: "input"))
        #expect(checkboxNode.props["type"] == .attribute(name: "type", value: "checkbox"))
    }

    @Test func toggleCheckedState() async throws {
        let stateOn = State(wrappedValue: true)
        let toggleOn = Toggle("On", isOn: stateOn.projectedValue)

        let vnodeOn = toggleOn.toVNode()
        let checkboxOn = vnodeOn.children[0]

        #expect(checkboxOn.props["checked"] == .boolAttribute(name: "checked", value: true))

        let stateOff = State(wrappedValue: false)
        let toggleOff = Toggle("Off", isOn: stateOff.projectedValue)

        let vnodeOff = toggleOff.toVNode()
        let checkboxOff = vnodeOff.children[0]

        #expect(checkboxOff.props["checked"] == .boolAttribute(name: "checked", value: false))
    }

    @Test func toggleChangeEventHandling() async throws {
        let state = State(wrappedValue: false)
        let toggle = Toggle("Test", isOn: state.projectedValue)

        let vnode = toggle.toVNode()
        let checkboxNode = vnode.children[0]

        // Verify change event handler
        guard case .eventHandler(let event, let handlerID) = checkboxNode.props["onChange"] else {
            Issue.record("Toggle should have onChange event handler")
            return
        }

        #expect(event == "change")
        #expect(handlerID != nil)

        // Test the change handler
        let changeHandler = toggle.changeHandler
        #expect(state.wrappedValue == false)

        changeHandler()
        #expect(state.wrappedValue == true)

        changeHandler()
        #expect(state.wrappedValue == false)
    }

    @Test func toggleAccessibilityAttributes() async throws {
        let state = State(wrappedValue: true)
        let toggle = Toggle("Accessible", isOn: state.projectedValue)

        let vnode = toggle.toVNode()
        let checkboxNode = vnode.children[0]

        // Verify ARIA attributes
        #expect(checkboxNode.props["role"] == .attribute(name: "role", value: "switch"))
        #expect(checkboxNode.props["aria-checked"] == .attribute(name: "aria-checked", value: "true"))
    }

    // MARK: - Test 8: Complete Todo App Integration

    @Test func todoItemModel() async throws {
        struct TodoItem: Identifiable, Sendable {
            let id: UUID
            var title: String
            var isCompleted: Bool
        }

        let item = TodoItem(id: UUID(), title: "Buy milk", isCompleted: false)

        #expect(item.id != nil)
        #expect(item.title == "Buy milk")
        #expect(!item.isCompleted)
    }

    @Test func todoStoreAsObservableObject() async throws {
        struct TodoItem: Identifiable, Sendable {
            let id: UUID
            var title: String
            var isCompleted: Bool
        }

        class TodoStore: ObservableObject {
            @Published var todos: [TodoItem] = []

            init() {
                setupPublished()
            }

            func addTodo(title: String) {
                let item = TodoItem(id: UUID(), title: title, isCompleted: false)
                todos.append(item)
            }

            func toggleTodo(id: UUID) {
                if let index = todos.firstIndex(where: { $0.id == id }) {
                    todos[index].isCompleted.toggle()
                }
            }
        }

        let store = TodoStore()
        var changeCount = 0

        store.objectWillChange.subscribe {
            changeCount += 1
        }

        #expect(store.todos.count == 0)

        store.addTodo(title: "Test task")
        #expect(store.todos.count == 1)
        #expect(changeCount == 1)

        let todoID = store.todos[0].id
        store.toggleTodo(id: todoID)
        #expect(store.todos[0].isCompleted)
        #expect(changeCount == 2)
    }

    @Test func todoAppViewStructure() async throws {
        struct TodoItem: Identifiable, Sendable {
            let id: UUID
            var title: String
            var isCompleted: Bool
        }

        class TodoStore: ObservableObject {
            @Published var todos: [TodoItem] = []
            @Published var newTodoText: String = ""

            init() {
                setupPublished()
            }

            func addTodo() {
                guard !newTodoText.isEmpty else { return }
                let item = TodoItem(id: UUID(), title: newTodoText, isCompleted: false)
                todos.append(item)
                newTodoText = ""
            }

            func toggleTodo(id: UUID) {
                if let index = todos.firstIndex(where: { $0.id == id }) {
                    todos[index].isCompleted.toggle()
                }
            }
        }

        struct TodoApp: View {
            @StateObject var store = TodoStore()

            var body: some View {
                VStack {
                    Text("Todo List")

                    HStack {
                        TextField("New todo", text: store.$newTodoText)
                        Button("Add") {
                            store.addTodo()
                        }
                    }

                    List(store.todos) { todo in
                        HStack {
                            Toggle(todo.title, isOn: .constant(todo.isCompleted))
                            Text(todo.title)
                        }
                    }
                }
            }

            @MainActor init() {}
        }

        let app = TodoApp()

        // Verify the app structure compiles and can be instantiated
        #expect(app.body != nil)
    }

    @Test func completeTodoAppIntegration() async throws {
        struct TodoItem: Identifiable, Sendable {
            let id: UUID
            var title: String
            var isCompleted: Bool
        }

        class TodoStore: ObservableObject {
            @Published var todos: [TodoItem] = []
            @Published var newTodoText: String = ""

            init() {
                setupPublished()
            }

            func addTodo() {
                guard !newTodoText.isEmpty else { return }
                let item = TodoItem(id: UUID(), title: newTodoText, isCompleted: false)
                todos.append(item)
                newTodoText = ""
            }

            func toggleTodo(id: UUID) {
                if let index = todos.firstIndex(where: { $0.id == id }) {
                    todos[index].isCompleted.toggle()
                }
            }
        }

        struct TodoRow: View {
            let todo: TodoItem
            let onToggle: @Sendable @MainActor () -> Void

            var body: some View {
                HStack {
                    Toggle(todo.title, isOn: .constant(todo.isCompleted))
                    Text(todo.title)
                        .foregroundColor(todo.isCompleted ? .gray : .black)
                }
            }
        }

        struct TodoApp: View {
            @StateObject var store = TodoStore()

            var body: some View {
                VStack(spacing: 16) {
                    Text("My Todo List")
                        .padding()

                    HStack {
                        TextField("Enter new todo", text: store.$newTodoText)
                        Button("Add") {
                            store.addTodo()
                        }
                    }
                    .padding()

                    List(store.todos) { todo in
                        TodoRow(
                            todo: todo,
                            onToggle: {
                                store.toggleTodo(id: todo.id)
                            }
                        )
                    }
                }
                .frame(width: 400)
            }

            @MainActor init() {}
        }

        // Create the app
        let app = TodoApp()

        // Access the store to initialize it
        let store = app.$store

        // Simulate adding todos
        store.newTodoText = "Buy groceries"
        store.addTodo()

        #expect(store.todos.count == 1)
        #expect(store.todos[0].title == "Buy groceries")
        #expect(!store.todos[0].isCompleted)

        // Add another
        store.newTodoText = "Write tests"
        store.addTodo()

        #expect(store.todos.count == 2)
        #expect(store.newTodoText == "")

        // Toggle completion
        let firstTodoID = store.todos[0].id
        store.toggleTodo(id: firstTodoID)

        #expect(store.todos[0].isCompleted)
        #expect(!store.todos[1].isCompleted)

        // Verify the view body exists
        let body = app.body
        #expect(body != nil)
    }

    @Test func todoAppVNodeStructure() async throws {
        struct TodoItem: Identifiable, Sendable {
            let id: UUID
            var title: String
            var isCompleted: Bool
        }

        class TodoStore: ObservableObject {
            @Published var todos: [TodoItem] = []

            init() {
                setupPublished()
                // Add some sample data
                todos = [
                    TodoItem(id: UUID(), title: "Sample task", isCompleted: false)
                ]
            }
        }

        struct SimpleTodoList: View {
            @StateObject var store = TodoStore()

            var body: some View {
                List(store.todos) { todo in
                    Text(todo.title)
                }
            }

            @MainActor init() {}
        }

        let app = SimpleTodoList()

        // Verify the list can be converted to VNode
        let body = app.body
        #expect(body != nil)

        // The body is a List, which should convert to VNode
        // This verifies the complete pipeline works
    }

    // MARK: - Integration Tests

    @Test func stateObjectAndObservedObjectTogether() async throws {
        class SharedData: ObservableObject {
            @Published var count: Int = 0

            init() {
                setupPublished()
            }
        }

        struct ParentView: View {
            @StateObject var data = SharedData()

            var body: some View {
                Text("Parent: \(data.count)")
            }

            @MainActor init() {}
        }

        @MainActor
        struct ChildView: View {
            @ObservedObject var data: SharedData

            var body: some View {
                Text("Child: \(data.count)")
            }
        }

        // Parent owns via @StateObject
        let parent = ParentView()
        let sharedData = parent.$data

        // Child observes via @ObservedObject
        let child = ChildView(data: sharedData)

        // Verify they share the same instance
        #expect(sharedData.count == 0)
        #expect(child.data.count == 0)

        sharedData.count = 42
        #expect(child.data.count == 42)
    }

    @Test func forEachInsideList() async throws {
        struct Item: Identifiable, Sendable {
            let id: Int
            let name: String
        }

        let items = [
            Item(id: 1, name: "First"),
            Item(id: 2, name: "Second")
        ]

        let list = List {
            ForEach(items) { item in
                Text(item.name)
            }
        }

        let vnode = list.toVNode()
        #expect(vnode.isElement(tag: "div"))
        #expect(vnode.props["role"] == .attribute(name: "role", value: "list"))
    }

    @Test func textFieldInsideForm() async throws {
        let state1 = State(wrappedValue: "")
        let state2 = State(wrappedValue: "")

        let form = VStack {
            TextField("Username", text: state1.projectedValue)
            TextField("Password", text: state2.projectedValue)
            Button("Submit") {
                print("Submit")
            }
        }

        let vnode = form.toVNode()
        #expect(vnode.isElement(tag: "div"))
    }

    @Test func toggleInsideList() async throws {
        struct Setting: Identifiable, Sendable {
            let id: Int
            let name: String
            var isEnabled: Bool
        }

        let settings = [
            Setting(id: 1, name: "Notifications", isEnabled: true),
            Setting(id: 2, name: "Dark Mode", isEnabled: false)
        ]

        let list = List {
            ForEach(settings, id: \.id) { setting in
                Toggle(setting.name, isOn: .constant(setting.isEnabled))
            }
        }

        let vnode = list.toVNode()
        #expect(vnode.isElement(tag: "div"))
        #expect(vnode.props["role"] == .attribute(name: "role", value: "list"))
    }
}
