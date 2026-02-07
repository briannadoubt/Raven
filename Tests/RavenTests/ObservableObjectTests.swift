import Testing
@testable import Raven

@MainActor
@Suite struct ObservableObjectTests {

    // MARK: - Basic ObservableObject Tests

    @Test func observableObjectPublisher() async {
        let counter = Counter()
        var changeCount = 0

        // Subscribe to changes
        _ = counter.objectWillChange.subscribe {
            changeCount += 1
        }

        // Modify published properties
        counter.count = 1
        #expect(changeCount == 1)

        counter.name = "Test"
        #expect(changeCount == 2)

        counter.increment()
        #expect(changeCount == 3)
    }

    @Test func publishedPropertyValue() async {
        let counter = Counter()
        #expect(counter.count == 0)

        counter.count = 5
        #expect(counter.count == 5)

        counter.increment()
        #expect(counter.count == 6)

        counter.reset()
        #expect(counter.count == 0)
    }

    @Test func multiplePublishedProperties() async {
        let settings = UserSettings()
        var changeCount = 0

        _ = settings.objectWillChange.subscribe {
            changeCount += 1
        }

        settings.username = "Alice"
        #expect(changeCount == 1)

        settings.isDarkMode = true
        #expect(changeCount == 2)

        settings.fontSize = 16.0
        #expect(changeCount == 3)

        settings.notificationsEnabled = false
        #expect(changeCount == 4)
    }

    // MARK: - Manual Notification Tests

    @Test func manualObjectWillChange() async {
        let store = DataStore()
        var changeCount = 0

        _ = store.objectWillChange.subscribe {
            changeCount += 1
        }

        // Test manual notification
        store.addItem("Item 1")
        #expect(changeCount == 1)
        #expect(store.items.count == 1)

        // Test @Published property (selectedIndex)
        store.selectedIndex = 0
        #expect(changeCount == 2)

        // Test another manual notification
        store.addItem("Item 2")
        #expect(changeCount == 3)
        #expect(store.items.count == 2)
    }

    // MARK: - Publisher Subscription Tests

    @Test func multipleSubscribers() async {
        let counter = Counter()
        var subscriber1Count = 0
        var subscriber2Count = 0

        _ = counter.objectWillChange.subscribe {
            subscriber1Count += 1
        }

        _ = counter.objectWillChange.subscribe {
            subscriber2Count += 1
        }

        counter.count = 1
        #expect(subscriber1Count == 1)
        #expect(subscriber2Count == 1)

        counter.count = 2
        #expect(subscriber1Count == 2)
        #expect(subscriber2Count == 2)
    }

    @Test func unsubscribe() async {
        let counter = Counter()
        var changeCount = 0

        let subscriptionId = counter.objectWillChange.subscribe {
            changeCount += 1
        }

        counter.count = 1
        #expect(changeCount == 1)

        // Unsubscribe
        counter.objectWillChange.unsubscribe(subscriptionId)

        counter.count = 2
        #expect(changeCount == 1)
    }

    // MARK: - Integration Tests

    @Test func counterMethods() async {
        let counter = Counter(count: 10, name: "Test Counter")
        #expect(counter.count == 10)
        #expect(counter.name == "Test Counter")

        counter.increment()
        #expect(counter.count == 11)

        counter.decrement()
        #expect(counter.count == 10)

        counter.reset()
        #expect(counter.count == 0)
    }

    @Test func userSettingsMethods() async {
        let settings = UserSettings()

        settings.fontSize = 14.0
        settings.increaseFontSize()
        #expect(settings.fontSize == 16.0)

        settings.decreaseFontSize()
        #expect(settings.fontSize == 14.0)

        settings.isDarkMode = false
        settings.toggleDarkMode()
        #expect(settings.isDarkMode)
    }

    @Test func dataStoreMethods() async {
        let store = DataStore()

        store.addItem("First")
        store.addItem("Second")
        store.addItem("Third")
        #expect(store.items.count == 3)

        store.selectedIndex = 1
        #expect(store.selectedIndex == 1)

        store.removeItem(at: 1)
        #expect(store.items.count == 2)
        #expect(store.selectedIndex == nil)
    }

    // MARK: - Nested ObservableObjects Tests

    @Test func todoItem() async {
        let todo = TodoItem(title: "Test Task")
        #expect(!todo.isCompleted)

        var changeCount = 0
        _ = todo.objectWillChange.subscribe {
            changeCount += 1
        }

        todo.toggle()
        #expect(todo.isCompleted)
        #expect(changeCount == 1)

        todo.title = "Updated Task"
        #expect(changeCount == 2)
    }

    @Test func todoList() async {
        let list = TodoList()

        list.addTodo(title: "First Task")
        list.addTodo(title: "Second Task")
        #expect(list.items.count == 2)

        // Test filtering
        #expect(list.filteredItems.count == 2)

        list.filter = .completed
        #expect(list.filteredItems.count == 0)

        // Toggle first item
        if let firstId = list.items.first?.id {
            list.toggleTodo(id: firstId)
            list.filter = .completed
            #expect(list.filteredItems.count == 1)

            list.filter = .active
            #expect(list.filteredItems.count == 1)
        }
    }

    // MARK: - Thread Safety Tests

    @Test func mainActorIsolation() async {
        // All operations should work on MainActor
        await MainActor.run {
            let counter = Counter()
            counter.count = 10
            #expect(counter.count == 10)
        }
    }
}
