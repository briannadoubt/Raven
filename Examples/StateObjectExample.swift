import Foundation
import Raven

// MARK: - Example: Simple Counter with @StateObject

/// Example ObservableObject that demonstrates @StateObject usage
@MainActor
final class CounterViewModel: ObservableObject {
    /// The current count value
    @Published var count: Int = 0

    /// The step size for incrementing/decrementing
    @Published var step: Int = 1

    init(initialCount: Int = 0, step: Int = 1) {
        self.count = initialCount
        self.step = step
        setupPublished()
    }

    func increment() {
        count += step
    }

    func decrement() {
        count -= step
    }

    func reset() {
        count = 0
    }
}

/// View that owns and creates a CounterViewModel using @StateObject
struct CounterView: View {
    /// The view owns this object - it will persist across view updates
    @StateObject private var viewModel = CounterViewModel()

    var body: some View {
        VStack {
            Text("Count: \(viewModel.count)")
            Text("Step: \(viewModel.step)")

            HStack {
                Button("-") {
                    viewModel.decrement()
                }
                Button("+") {
                    viewModel.increment()
                }
                Button("Reset") {
                    viewModel.reset()
                }
            }
        }
    }
}

// MARK: - Example: Parent-Child with @StateObject and @ObservedObject

/// Settings model for demonstration
@MainActor
final class AppSettings: ObservableObject {
    @Published var theme: Theme = .light
    @Published var fontSize: Double = 14.0
    @Published var notifications: Bool = true

    enum Theme: String, Sendable {
        case light = "Light"
        case dark = "Dark"
    }

    init() {
        setupPublished()
    }

    func toggleTheme() {
        theme = (theme == .light) ? .dark : .light
    }

    func increaseFontSize() {
        fontSize = min(fontSize + 2.0, 32.0)
    }

    func decreaseFontSize() {
        fontSize = max(fontSize - 2.0, 8.0)
    }

    func toggleNotifications() {
        notifications.toggle()
    }
}

/// Parent view that owns the AppSettings
struct SettingsParentView: View {
    /// This view creates and owns the settings object
    @StateObject private var settings = AppSettings()

    var body: some View {
        VStack {
            Text("App Settings")

            // Pass the settings to child views
            ThemeSettingsView(settings: settings)
            FontSettingsView(settings: settings)
            NotificationSettingsView(settings: settings)
        }
    }
}

/// Child view that observes settings owned by parent
struct ThemeSettingsView: View {
    /// This view observes an object owned by the parent
    @ObservedObject var settings: AppSettings

    var body: some View {
        VStack {
            Text("Theme: \(settings.theme.rawValue)")
            Button("Toggle Theme") {
                settings.toggleTheme()
            }
        }
    }
}

/// Another child view observing the same settings
struct FontSettingsView: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        VStack {
            Text("Font Size: \(Int(settings.fontSize))pt")
            HStack {
                Button("Smaller") {
                    settings.decreaseFontSize()
                }
                Button("Larger") {
                    settings.increaseFontSize()
                }
            }
        }
    }
}

/// Yet another child view
struct NotificationSettingsView: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        VStack {
            Text("Notifications: \(settings.notifications ? "Enabled" : "Disabled")")
            Button("Toggle") {
                settings.toggleNotifications()
            }
        }
    }
}

// MARK: - Example: Complex State Management

/// User profile model
@MainActor
final class UserProfile: ObservableObject {
    @Published var username: String = ""
    @Published var email: String = ""
    @Published var bio: String = ""
    @Published var isVerified: Bool = false

    init() {
        setupPublished()
    }

    func updateProfile(username: String, email: String, bio: String) {
        self.username = username
        self.email = email
        self.bio = bio
    }

    func verify() {
        isVerified = true
    }
}

/// View demonstrating multiple StateObjects
struct UserDashboardView: View {
    /// Each StateObject maintains its own lifecycle
    @StateObject private var userProfile = UserProfile()
    @StateObject private var appSettings = AppSettings()
    @StateObject private var counter = CounterViewModel(initialCount: 10, step: 5)

    var body: some View {
        VStack {
            Text("User Dashboard")

            // Profile section
            VStack {
                Text("Username: \(userProfile.username)")
                Text("Verified: \(userProfile.isVerified ? "Yes" : "No")")
                Button("Verify Profile") {
                    userProfile.verify()
                }
            }

            // Settings section (pass to child)
            SettingsSummaryView(settings: appSettings)

            // Counter section
            VStack {
                Text("Counter: \(counter.count)")
                Button("Increment by \(counter.step)") {
                    counter.increment()
                }
            }
        }
    }
}

/// Child view that uses @ObservedObject to observe parent's settings
struct SettingsSummaryView: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        VStack {
            Text("Theme: \(settings.theme.rawValue)")
            Text("Font: \(Int(settings.fontSize))pt")
            Text("Notifications: \(settings.notifications ? "On" : "Off")")
        }
    }
}

// MARK: - Example: Shared Observable Objects

/// Data model shared across multiple views
@MainActor
final class SharedDataStore: ObservableObject {
    @Published var items: [String] = []
    @Published var selectedIndex: Int? = nil

    init() {
        setupPublished()
    }

    func addItem(_ item: String) {
        items.append(item)
    }

    func removeItem(at index: Int) {
        guard items.indices.contains(index) else { return }
        items.remove(at: index)
        if selectedIndex == index {
            selectedIndex = nil
        }
    }

    func selectItem(at index: Int) {
        selectedIndex = index
    }
}

/// View that creates the shared data store
struct DataListView: View {
    @StateObject private var dataStore = SharedDataStore()

    var body: some View {
        VStack {
            Text("Items: \(dataStore.items.count)")

            // Pass the store to child views
            ItemListView(dataStore: dataStore)
            SelectedItemView(dataStore: dataStore)
        }
    }
}

/// Child view that displays the list
struct ItemListView: View {
    @ObservedObject var dataStore: SharedDataStore

    var body: some View {
        VStack {
            Text("Item List")
            // ForEach would go here to display items
        }
    }
}

/// Child view that displays the selected item
struct SelectedItemView: View {
    @ObservedObject var dataStore: SharedDataStore

    var body: some View {
        if let index = dataStore.selectedIndex {
            Text("Selected: \(dataStore.items[index])")
        } else {
            Text("No selection")
        }
    }
}

// MARK: - Usage Notes

/*
 Key Differences Between @StateObject and @ObservedObject:

 1. Ownership:
    - @StateObject: Creates and owns the observable object
    - @ObservedObject: Observes an object owned elsewhere

 2. Lifecycle:
    - @StateObject: Object persists for the lifetime of the view
    - @ObservedObject: Object lifecycle is managed by whoever owns it

 3. Initialization:
    - @StateObject: Lazy initialization on first access
    - @ObservedObject: Object must be provided during initialization

 4. When to use:
    - @StateObject: When the view should create and own the object
    - @ObservedObject: When receiving an object from a parent view

 Example hierarchy:

 ```
 struct ParentView: View {
     @StateObject private var model = MyModel()  // Parent owns it

     var body: some View {
         ChildView(model: model)  // Pass to child
     }
 }

 struct ChildView: View {
     @ObservedObject var model: MyModel  // Child observes it

     var body: some View {
         Text("\(model.value)")
     }
 }
 ```

 Best Practices:
 - Use @StateObject for the view that creates the object
 - Use @ObservedObject for views that receive the object from parent
 - Never use @StateObject if the object is passed from parent
 - Always call setupPublished() in ObservableObject init()
 - Use @Published for properties that should trigger view updates
 */
