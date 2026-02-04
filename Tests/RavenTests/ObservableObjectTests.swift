import XCTest
@testable import Raven

@MainActor
final class ObservableObjectTests: XCTestCase {

    // MARK: - Basic ObservableObject Tests

    func testObservableObjectPublisher() async {
        let counter = Counter()
        var changeCount = 0

        // Subscribe to changes
        _ = counter.objectWillChange.subscribe {
            changeCount += 1
        }

        // Modify published properties
        counter.count = 1
        XCTAssertEqual(changeCount, 1, "Publisher should emit when @Published property changes")

        counter.name = "Test"
        XCTAssertEqual(changeCount, 2, "Publisher should emit for each property change")

        counter.increment()
        XCTAssertEqual(changeCount, 3, "Publisher should emit when method changes @Published property")
    }

    func testPublishedPropertyValue() async {
        let counter = Counter()
        XCTAssertEqual(counter.count, 0, "Initial count should be 0")

        counter.count = 5
        XCTAssertEqual(counter.count, 5, "Count should update to 5")

        counter.increment()
        XCTAssertEqual(counter.count, 6, "Count should increment to 6")

        counter.reset()
        XCTAssertEqual(counter.count, 0, "Count should reset to 0")
    }

    func testMultiplePublishedProperties() async {
        let settings = UserSettings()
        var changeCount = 0

        _ = settings.objectWillChange.subscribe {
            changeCount += 1
        }

        settings.username = "Alice"
        XCTAssertEqual(changeCount, 1)

        settings.isDarkMode = true
        XCTAssertEqual(changeCount, 2)

        settings.fontSize = 16.0
        XCTAssertEqual(changeCount, 3)

        settings.notificationsEnabled = false
        XCTAssertEqual(changeCount, 4)
    }

    // MARK: - Manual Notification Tests

    func testManualObjectWillChange() async {
        let store = DataStore()
        var changeCount = 0

        _ = store.objectWillChange.subscribe {
            changeCount += 1
        }

        // Test manual notification
        store.addItem("Item 1")
        XCTAssertEqual(changeCount, 1, "Manual send() should trigger publisher")
        XCTAssertEqual(store.items.count, 1)

        // Test @Published property (selectedIndex)
        store.selectedIndex = 0
        XCTAssertEqual(changeCount, 2, "@Published property should trigger publisher")

        // Test another manual notification
        store.addItem("Item 2")
        XCTAssertEqual(changeCount, 3)
        XCTAssertEqual(store.items.count, 2)
    }

    // MARK: - Publisher Subscription Tests

    func testMultipleSubscribers() async {
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
        XCTAssertEqual(subscriber1Count, 1, "First subscriber should receive notification")
        XCTAssertEqual(subscriber2Count, 1, "Second subscriber should receive notification")

        counter.count = 2
        XCTAssertEqual(subscriber1Count, 2)
        XCTAssertEqual(subscriber2Count, 2)
    }

    func testUnsubscribe() async {
        let counter = Counter()
        var changeCount = 0

        let subscriptionId = counter.objectWillChange.subscribe {
            changeCount += 1
        }

        counter.count = 1
        XCTAssertEqual(changeCount, 1)

        // Unsubscribe
        counter.objectWillChange.unsubscribe(subscriptionId)

        counter.count = 2
        XCTAssertEqual(changeCount, 1, "Should not receive notifications after unsubscribe")
    }

    // MARK: - Integration Tests

    func testCounterMethods() async {
        let counter = Counter(count: 10, name: "Test Counter")
        XCTAssertEqual(counter.count, 10)
        XCTAssertEqual(counter.name, "Test Counter")

        counter.increment()
        XCTAssertEqual(counter.count, 11)

        counter.decrement()
        XCTAssertEqual(counter.count, 10)

        counter.reset()
        XCTAssertEqual(counter.count, 0)
    }

    func testUserSettingsMethods() async {
        let settings = UserSettings()

        settings.fontSize = 14.0
        settings.increaseFontSize()
        XCTAssertEqual(settings.fontSize, 16.0)

        settings.decreaseFontSize()
        XCTAssertEqual(settings.fontSize, 14.0)

        settings.isDarkMode = false
        settings.toggleDarkMode()
        XCTAssertTrue(settings.isDarkMode)
    }

    func testDataStoreMethods() async {
        let store = DataStore()

        store.addItem("First")
        store.addItem("Second")
        store.addItem("Third")
        XCTAssertEqual(store.items.count, 3)

        store.selectedIndex = 1
        XCTAssertEqual(store.selectedIndex, 1)

        store.removeItem(at: 1)
        XCTAssertEqual(store.items.count, 2)
        XCTAssertNil(store.selectedIndex, "Selected index should be nil after removing selected item")

        store.clear()
        XCTAssertEqual(store.items.count, 0)
    }

    // MARK: - Nested ObservableObjects Tests

    func testTodoItem() async {
        let todo = TodoItem(title: "Test Task")
        XCTAssertFalse(todo.isCompleted)

        var changeCount = 0
        _ = todo.objectWillChange.subscribe {
            changeCount += 1
        }

        todo.toggle()
        XCTAssertTrue(todo.isCompleted)
        XCTAssertEqual(changeCount, 1)

        todo.title = "Updated Task"
        XCTAssertEqual(changeCount, 2)
    }

    func testTodoList() async {
        let list = TodoList()

        list.addTodo(title: "First Task")
        list.addTodo(title: "Second Task")
        XCTAssertEqual(list.items.count, 2)

        // Test filtering
        XCTAssertEqual(list.filteredItems.count, 2)

        list.filter = .completed
        XCTAssertEqual(list.filteredItems.count, 0)

        // Toggle first item
        if let firstId = list.items.first?.id {
            list.toggleTodo(id: firstId)
            list.filter = .completed
            XCTAssertEqual(list.filteredItems.count, 1)

            list.filter = .active
            XCTAssertEqual(list.filteredItems.count, 1)
        }
    }

    // MARK: - Thread Safety Tests

    func testMainActorIsolation() async {
        // All operations should work on MainActor
        await MainActor.run {
            let counter = Counter()
            counter.count = 10
            XCTAssertEqual(counter.count, 10)
        }
    }
}
