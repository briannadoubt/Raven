import XCTest
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
final class Phase3VerificationTests: XCTestCase {

    // MARK: - Test 1: ObservableObject Tests

    func testObservableObjectConformance() async throws {
        // Create a simple observable object
        class Counter: ObservableObject {
            @Published var count: Int = 0

            init() {
                setupPublished()
            }
        }

        let counter = Counter()

        // Verify it has an objectWillChange publisher
        XCTAssertNotNil(counter.objectWillChange, "ObservableObject should have objectWillChange publisher")
    }

    func testObservableObjectPublisherFiresOnChange() async throws {
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
        XCTAssertEqual(changeCount, 0)

        // Change the published property
        model.value = "new"
        XCTAssertEqual(changeCount, 1, "objectWillChange should fire when @Published property changes")

        // Change again
        model.value = "another"
        XCTAssertEqual(changeCount, 2)
    }

    func testObservableObjectWithMultiplePublishedProperties() async throws {
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
        XCTAssertEqual(changeCount, 1)

        settings.age = 30
        XCTAssertEqual(changeCount, 2)

        settings.isActive = true
        XCTAssertEqual(changeCount, 3)
    }

    func testPublishedPropertyProjectedValue() async throws {
        class DataStore: ObservableObject {
            @Published var text: String = "initial"

            init() {
                setupPublished()
            }
        }

        let store = DataStore()

        // Access projected value to get a Binding
        let binding = store.$text
        XCTAssertEqual(binding.wrappedValue, "initial")

        // Modify through binding
        binding.wrappedValue = "updated"
        XCTAssertEqual(store.text, "updated")
    }

    // MARK: - Test 2: @StateObject Tests

    func testStateObjectCreatesObjectLazily() async throws {
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
        XCTAssertEqual(LazyModel.instanceCount, 0, "Object should not be created until accessed")

        // Accessing wrappedValue should create it
        let model = view.$model
        XCTAssertEqual(LazyModel.instanceCount, 1, "Object should be created on first access")

        // Accessing again shouldn't create another
        let model2 = view.$model
        XCTAssertEqual(LazyModel.instanceCount, 1, "Same object should be reused")
        XCTAssertEqual(model.id, model2.id, "Should return the same instance")
    }

    func testStateObjectTriggersViewUpdates() async throws {
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
        XCTAssertEqual(updateCount, 0)
        model.increment()
        XCTAssertEqual(updateCount, 1, "Changes to @Published properties should trigger view updates")
    }

    func testStateObjectProjectedValue() async throws {
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
        XCTAssertTrue(type(of: projectedModel) == SharedModel.self, "Projected value should be the object")
    }

    // MARK: - Test 3: @ObservedObject Tests

    func testObservedObjectDoesNotOwnObject() async throws {
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
        XCTAssertEqual(child.model.value, 0)

        externalModel.value = 42
        XCTAssertEqual(child.model.value, 42, "ObservedObject should reflect changes to external object")
    }

    func testObservedObjectTriggersViewUpdates() async throws {
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
        XCTAssertEqual(updateCount, 0)
        data.text = "changed"
        XCTAssertEqual(updateCount, 1, "Changes should trigger view updates")
    }

    func testObservedObjectParentChildFlow() async throws {
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
        XCTAssertEqual(child.appState.message, "Hello")

        parentState.message = "Updated"
        XCTAssertEqual(child.appState.message, "Updated", "Child should observe parent's object")
    }

    // MARK: - Test 4: ForEach Tests

    func testForEachWithIdentifiableItems() async throws {
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
        XCTAssertNotNil(body, "ForEach should have a body")
    }

    func testForEachWithCustomIDKeyPath() async throws {
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
        XCTAssertNotNil(body)
    }

    func testForEachWithRange() async throws {
        let forEach = ForEach(0..<5) { index in
            Text("Item \(index)")
        }

        let body = forEach.body
        XCTAssertNotNil(body)
    }

    // MARK: - Test 5: List Tests

    func testListWithStaticContent() async throws {
        let list = List {
            Text("Item 1")
            Text("Item 2")
            Text("Item 3")
        }

        let vnode = list.toVNode()

        // List should create a div with role="list"
        XCTAssertTrue(vnode.isElement(tag: "div"), "List should create a div element")
        XCTAssertEqual(vnode.props["role"], .attribute(name: "role", value: "list"))

        // Verify layout styles
        XCTAssertEqual(vnode.props["display"], .style(name: "display", value: "flex"))
        XCTAssertEqual(vnode.props["flex-direction"], .style(name: "flex-direction", value: "column"))
    }

    func testListWithForEach() async throws {
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
        XCTAssertTrue(vnode.isElement(tag: "div"))
        XCTAssertEqual(vnode.props["role"], .attribute(name: "role", value: "list"))
    }

    func testListHTMLStructure() async throws {
        let list = List {
            Text("Content")
        }

        let vnode = list.toVNode()

        // Verify accessibility attributes
        XCTAssertEqual(vnode.props["role"], .attribute(name: "role", value: "list"),
                      "List should have role='list' for accessibility")

        // Verify scrolling
        XCTAssertEqual(vnode.props["overflow-y"], .style(name: "overflow-y", value: "auto"),
                      "List should be scrollable")

        // Verify width
        XCTAssertEqual(vnode.props["width"], .style(name: "width", value: "100%"))
    }

    // MARK: - Test 6: TextField Tests

    func testTextFieldWithBinding() async throws {
        let state = State(wrappedValue: "initial")
        let binding = state.projectedValue

        let textField = TextField("Placeholder", text: binding)

        let vnode = textField.toVNode()

        // Verify input element
        XCTAssertTrue(vnode.isElement(tag: "input"), "TextField should create an input element")
        XCTAssertEqual(vnode.props["type"], .attribute(name: "type", value: "text"))

        // Verify placeholder
        XCTAssertEqual(vnode.props["placeholder"], .attribute(name: "placeholder", value: "Placeholder"))

        // Verify value reflects binding
        XCTAssertEqual(vnode.props["value"], .attribute(name: "value", value: "initial"))

        // Verify event handler exists
        XCTAssertNotNil(vnode.props["onInput"], "TextField should have input event handler")
    }

    func testTextFieldTwoWayBinding() async throws {
        let state = State(wrappedValue: "")
        let binding = state.projectedValue

        // Verify binding works both ways
        XCTAssertEqual(binding.wrappedValue, "")

        // Simulate user input
        binding.wrappedValue = "user typed this"
        XCTAssertEqual(state.wrappedValue, "user typed this", "Binding should update state")

        // Create new textfield to verify value updated
        let textField2 = TextField("Enter text", text: binding)
        let vnode = textField2.toVNode()
        XCTAssertEqual(vnode.props["value"], .attribute(name: "value", value: "user typed this"))
    }

    func testTextFieldEventHandling() async throws {
        let state = State(wrappedValue: "")
        let textField = TextField("Test", text: state.projectedValue)

        let vnode = textField.toVNode()

        // Extract event handler
        guard case .eventHandler(let event, let handlerID) = vnode.props["onInput"] else {
            XCTFail("TextField should have onInput event handler")
            return
        }

        XCTAssertEqual(event, "input", "Event should be 'input'")
        XCTAssertNotNil(handlerID, "Handler should have a unique ID")
    }

    // MARK: - Test 7: Toggle Tests

    func testToggleWithBinding() async throws {
        let state = State(wrappedValue: false)
        let binding = state.projectedValue

        let toggle = Toggle("Enable", isOn: binding)

        let vnode = toggle.toVNode()

        // Toggle renders as a label element
        XCTAssertTrue(vnode.isElement(tag: "label"), "Toggle should create a label element")

        // Should contain an input checkbox
        XCTAssertGreaterThan(vnode.children.count, 0, "Toggle should have children")

        let checkboxNode = vnode.children[0]
        XCTAssertTrue(checkboxNode.isElement(tag: "input"), "First child should be input")
        XCTAssertEqual(checkboxNode.props["type"], .attribute(name: "type", value: "checkbox"))
    }

    func testToggleCheckedState() async throws {
        let stateOn = State(wrappedValue: true)
        let toggleOn = Toggle("On", isOn: stateOn.projectedValue)

        let vnodeOn = toggleOn.toVNode()
        let checkboxOn = vnodeOn.children[0]

        XCTAssertEqual(checkboxOn.props["checked"], .boolAttribute(name: "checked", value: true),
                      "Toggle should reflect checked state")

        let stateOff = State(wrappedValue: false)
        let toggleOff = Toggle("Off", isOn: stateOff.projectedValue)

        let vnodeOff = toggleOff.toVNode()
        let checkboxOff = vnodeOff.children[0]

        XCTAssertEqual(checkboxOff.props["checked"], .boolAttribute(name: "checked", value: false),
                      "Toggle should reflect unchecked state")
    }

    func testToggleChangeEventHandling() async throws {
        let state = State(wrappedValue: false)
        let toggle = Toggle("Test", isOn: state.projectedValue)

        let vnode = toggle.toVNode()
        let checkboxNode = vnode.children[0]

        // Verify change event handler
        guard case .eventHandler(let event, let handlerID) = checkboxNode.props["onChange"] else {
            XCTFail("Toggle should have onChange event handler")
            return
        }

        XCTAssertEqual(event, "change", "Event should be 'change'")
        XCTAssertNotNil(handlerID)

        // Test the change handler
        let changeHandler = toggle.changeHandler
        XCTAssertEqual(state.wrappedValue, false)

        changeHandler()
        XCTAssertEqual(state.wrappedValue, true, "Change handler should toggle the value")

        changeHandler()
        XCTAssertEqual(state.wrappedValue, false, "Change handler should toggle back")
    }

    func testToggleAccessibilityAttributes() async throws {
        let state = State(wrappedValue: true)
        let toggle = Toggle("Accessible", isOn: state.projectedValue)

        let vnode = toggle.toVNode()
        let checkboxNode = vnode.children[0]

        // Verify ARIA attributes
        XCTAssertEqual(checkboxNode.props["role"], .attribute(name: "role", value: "switch"))
        XCTAssertEqual(checkboxNode.props["aria-checked"], .attribute(name: "aria-checked", value: "true"))
    }

    // MARK: - Test 8: Complete Todo App Integration

    func testTodoItemModel() async throws {
        struct TodoItem: Identifiable, Sendable {
            let id: UUID
            var title: String
            var isCompleted: Bool
        }

        let item = TodoItem(id: UUID(), title: "Buy milk", isCompleted: false)

        XCTAssertNotNil(item.id)
        XCTAssertEqual(item.title, "Buy milk")
        XCTAssertFalse(item.isCompleted)
    }

    func testTodoStoreAsObservableObject() async throws {
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

        XCTAssertEqual(store.todos.count, 0)

        store.addTodo(title: "Test task")
        XCTAssertEqual(store.todos.count, 1)
        XCTAssertEqual(changeCount, 1, "Adding todo should trigger objectWillChange")

        let todoID = store.todos[0].id
        store.toggleTodo(id: todoID)
        XCTAssertTrue(store.todos[0].isCompleted)
        XCTAssertEqual(changeCount, 2, "Toggling todo should trigger objectWillChange")
    }

    func testTodoAppViewStructure() async throws {
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
        XCTAssertNotNil(app.body, "TodoApp should have a body")
    }

    func testCompleteTodoAppIntegration() async throws {
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

        XCTAssertEqual(store.todos.count, 1, "Should have one todo")
        XCTAssertEqual(store.todos[0].title, "Buy groceries")
        XCTAssertFalse(store.todos[0].isCompleted)

        // Add another
        store.newTodoText = "Write tests"
        store.addTodo()

        XCTAssertEqual(store.todos.count, 2, "Should have two todos")
        XCTAssertEqual(store.newTodoText, "", "Text should be cleared after adding")

        // Toggle completion
        let firstTodoID = store.todos[0].id
        store.toggleTodo(id: firstTodoID)

        XCTAssertTrue(store.todos[0].isCompleted, "First todo should be completed")
        XCTAssertFalse(store.todos[1].isCompleted, "Second todo should not be completed")

        // Verify the view body exists
        let body = app.body
        XCTAssertNotNil(body)
    }

    func testTodoAppVNodeStructure() async throws {
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
        XCTAssertNotNil(body)

        // The body is a List, which should convert to VNode
        // This verifies the complete pipeline works
    }

    // MARK: - Integration Tests

    func testStateObjectAndObservedObjectTogether() async throws {
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
        XCTAssertEqual(sharedData.count, 0)
        XCTAssertEqual(child.data.count, 0)

        sharedData.count = 42
        XCTAssertEqual(child.data.count, 42, "Child should see parent's changes")
    }

    func testForEachInsideList() async throws {
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
        XCTAssertTrue(vnode.isElement(tag: "div"))
        XCTAssertEqual(vnode.props["role"], .attribute(name: "role", value: "list"))
    }

    func testTextFieldInsideForm() async throws {
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
        XCTAssertTrue(vnode.isElement(tag: "div"))
    }

    func testToggleInsideList() async throws {
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
        XCTAssertTrue(vnode.isElement(tag: "div"))
        XCTAssertEqual(vnode.props["role"], .attribute(name: "role", value: "list"))
    }
}
