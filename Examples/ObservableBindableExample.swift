import Raven

// MARK: - Example: Using @Observable and @Bindable in Raven

/// This example demonstrates how to use the modern @Observable and @Bindable
/// pattern in Raven for state management, replacing the legacy ObservableObject pattern.

// MARK: - Observable Model

/// A simple user settings model using the Observable protocol
/// This is the modern approach (iOS 17+) that replaces ObservableObject
@MainActor
final class UserSettings: Observable {
    // Required: The observation registrar
    let _$observationRegistrar = ObservationRegistrar()

    // Observable properties with manual observation
    private var _username: String
    var username: String {
        get { _username }
        set {
            _$observationRegistrar.willSet()
            _username = newValue
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

    // Computed property (automatically observed)
    var displayName: String {
        username.isEmpty ? "Guest" : username
    }

    init(username: String = "", isDarkMode: Bool = false, fontSize: Double = 14.0) {
        self._username = username
        self._isDarkMode = isDarkMode
        self._fontSize = fontSize
        setupObservation()
    }

    func toggleDarkMode() {
        isDarkMode.toggle()
    }

    func increaseFontSize() {
        fontSize = min(fontSize + 2, 32)
    }

    func decreaseFontSize() {
        fontSize = max(fontSize - 2, 8)
    }
}

// MARK: - Settings View with @Bindable

/// A view that uses @Bindable to create bindings to Observable properties
struct SettingsView: View {
    @Bindable var settings: UserSettings

    var body: some View {
        VStack(spacing: 20) {
            // Title
            Text("Settings")
                .font(.title)

            // Username field using $settings.username binding
            VStack(alignment: .leading) {
                Text("Username")
                    .font(.headline)
                TextField("Enter username", text: $settings.username)
            }

            // Dark mode toggle using $settings.isDarkMode binding
            Toggle("Dark Mode", isOn: $settings.isDarkMode)

            // Font size controls
            VStack(alignment: .leading) {
                Text("Font Size: \(Int(settings.fontSize))")
                    .font(.headline)

                HStack {
                    Button("Decrease") {
                        settings.decreaseFontSize()
                    }

                    Slider(value: $settings.fontSize, in: 8...32)

                    Button("Increase") {
                        settings.increaseFontSize()
                    }
                }
            }

            // Display current settings
            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Current Settings:")
                    .font(.headline)
                Text("Display Name: \(settings.displayName)")
                Text("Theme: \(settings.isDarkMode ? "Dark" : "Light")")
                Text("Font Size: \(Int(settings.fontSize))pt")
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(8)
        }
        .padding()
    }
}

// MARK: - App Root with @State

/// The root app view that creates and owns the settings
struct SettingsApp: View {
    @State private var settings = UserSettings()

    var body: some View {
        VStack {
            Text("Raven Settings Demo")
                .font(.largeTitle)

            // Pass the settings to child view using @Bindable
            SettingsView(settings: settings)
        }
    }
}

// MARK: - Alternative: Simplified Pattern

/// For simpler cases, you can use willSet instead of explicit getters/setters
@MainActor
final class SimpleCounter: Observable {
    let _$observationRegistrar = ObservationRegistrar()

    var count: Int = 0 {
        willSet { _$observationRegistrar.willSet() }
    }

    var name: String = "Counter" {
        willSet { _$observationRegistrar.willSet() }
    }

    init() {
        setupObservation()
    }

    func increment() {
        count += 1
    }
}

struct CounterView: View {
    @Bindable var counter: SimpleCounter

    var body: some View {
        VStack {
            Text(counter.name)
                .font(.headline)

            Text("Count: \(counter.count)")
                .font(.title)

            Button("Increment") {
                counter.increment()
            }
        }
    }
}

// MARK: - Migration Guide

/*
 ## Migrating from ObservableObject to @Observable

 ### Before (ObservableObject):

 ```swift
 @MainActor
 class Settings: ObservableObject {
     @Published var username: String = ""
     @Published var isDarkMode: Bool = false

     init() {
         setupPublished()
     }
 }

 struct SettingsView: View {
     @ObservedObject var settings: Settings

     var body: some View {
         TextField("Username", text: $settings.username)
         Toggle("Dark Mode", isOn: $settings.isDarkMode)
     }
 }
 ```

 ### After (@Observable):

 ```swift
 @MainActor
 class Settings: Observable {
     let _$observationRegistrar = ObservationRegistrar()

     var username: String = "" {
         willSet { _$observationRegistrar.willSet() }
     }

     var isDarkMode: Bool = false {
         willSet { _$observationRegistrar.willSet() }
     }

     init() {
         setupObservation()
     }
 }

 struct SettingsView: View {
     @Bindable var settings: Settings

     var body: some View {
         TextField("Username", text: $settings.username)
         Toggle("Dark Mode", isOn: $settings.isDarkMode)
     }
 }
 ```

 ### Benefits:
 - No @Published wrappers needed
 - Cleaner, more concise code
 - Better performance with fine-grained observation
 - Modern SwiftUI API alignment

 ## When Swift Macros Become Available:

 In the future, when Swift macros are fully supported in SwiftWasm, you'll be able to use:

 ```swift
 @Observable
 @MainActor
 class Settings {
     var username: String = ""
     var isDarkMode: Bool = false
 }
 ```

 The macro will automatically generate all the observation infrastructure!
 */
