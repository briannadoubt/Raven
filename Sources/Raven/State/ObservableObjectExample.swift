import Foundation

// MARK: - Example ObservableObject Implementation

/// Example: Simple counter that conforms to ObservableObject
///
/// This demonstrates the basic usage of ObservableObject with @Published properties.
@MainActor
public final class Counter: ObservableObject {
    /// The current count value
    @Published public var count: Int = 0

    /// The counter name
    @Published public var name: String = "Counter"

    /// Initialize the counter
    public init(count: Int = 0, name: String = "Counter") {
        self.count = count
        self.name = name
        // Setup @Published properties to connect with objectWillChange
        setupPublished()
    }

    /// Increment the counter
    public func increment() {
        count += 1
    }

    /// Decrement the counter
    public func decrement() {
        count -= 1
    }

    /// Reset the counter to zero
    public func reset() {
        count = 0
    }
}

// MARK: - Example: User Settings

/// Example: User settings that demonstrates multiple @Published properties
@MainActor
public final class UserSettings: ObservableObject {
    /// The username
    @Published public var username: String = ""

    /// Whether dark mode is enabled
    @Published public var isDarkMode: Bool = false

    /// Font size preference
    @Published public var fontSize: Double = 14.0

    /// Notification preferences
    @Published public var notificationsEnabled: Bool = true

    public init() {
        setupPublished()
    }

    /// Toggle dark mode
    public func toggleDarkMode() {
        isDarkMode.toggle()
    }

    /// Increase font size
    public func increaseFontSize() {
        fontSize = min(fontSize + 2.0, 32.0)
    }

    /// Decrease font size
    public func decreaseFontSize() {
        fontSize = max(fontSize - 2.0, 8.0)
    }
}

// MARK: - Example: Data Store with Manual Notification

/// Example: Data store that manually triggers objectWillChange
///
/// This demonstrates how to manually send change notifications
/// for properties that are not @Published.
@MainActor
public final class DataStore: ObservableObject {
    /// Items array (manually notifying)
    private var _items: [String] = []

    public var items: [String] {
        get { _items }
        set {
            objectWillChange.send()
            _items = newValue
        }
    }

    /// Selected item index
    @Published public var selectedIndex: Int? = nil

    public init() {
        setupPublished()
    }

    /// Add an item
    public func addItem(_ item: String) {
        objectWillChange.send()
        _items.append(item)
    }

    /// Remove an item at index
    public func removeItem(at index: Int) {
        objectWillChange.send()
        _items.remove(at: index)
        if selectedIndex == index {
            selectedIndex = nil
        }
    }

    /// Clear all items
    public func clear() {
        objectWillChange.send()
        _items.removeAll()
        selectedIndex = nil
    }
}

// MARK: - Example: Nested ObservableObjects

/// Example: Todo item
@MainActor
public final class TodoItem: ObservableObject, Identifiable {
    public let id: UUID

    @Published public var title: String
    @Published public var isCompleted: Bool

    public init(id: UUID = UUID(), title: String, isCompleted: Bool = false) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        setupPublished()
    }

    public func toggle() {
        isCompleted.toggle()
    }
}

/// Example: Todo list containing multiple TodoItems
@MainActor
public final class TodoList: ObservableObject {
    @Published public var items: [TodoItem] = []
    @Published public var filter: TodoFilter = .all

    public init() {
        setupPublished()
    }

    public enum TodoFilter: Sendable {
        case all
        case active
        case completed
    }

    public func addTodo(title: String) {
        let item = TodoItem(title: title)
        items.append(item)
    }

    public func removeTodo(id: UUID) {
        items.removeAll { $0.id == id }
    }

    public func toggleTodo(id: UUID) {
        if let item = items.first(where: { $0.id == id }) {
            item.toggle()
            // Manually notify because nested object changes don't auto-propagate
            objectWillChange.send()
        }
    }

    public var filteredItems: [TodoItem] {
        switch filter {
        case .all:
            return items
        case .active:
            return items.filter { !$0.isCompleted }
        case .completed:
            return items.filter { $0.isCompleted }
        }
    }
}
