import Foundation
import Raven

// MARK: - Simple Counter Example

/// A simple counter view demonstrating @State usage
@MainActor
struct CounterView: View {
    // State automatically triggers view updates when changed
    @State private var count: Int = 0

    var body: some View {
        VStack {
            Text("Count: \(count)")
            Button("Increment") {
                count += 1
            }
            Button("Decrement") {
                count -= 1
            }
            Button("Reset") {
                count = 0
            }
        }
    }
}

// MARK: - Toggle Example

/// Example showing boolean state with toggle
@MainActor
struct ToggleExample: View {
    @State private var isOn: Bool = false
    @State private var showDetails: Bool = false

    var body: some View {
        VStack {
            Button(isOn ? "Turn Off" : "Turn On") {
                isOn.toggle()
            }

            Text("Status: \(isOn ? "On" : "Off")")

            Button("Toggle Details") {
                showDetails.toggle()
            }

            // Conditional rendering based on state
            if showDetails {
                Text("Details are visible")
            }
        }
    }
}

// MARK: - Binding Example

/// Child view that receives a binding
@MainActor
struct ChildView: View {
    @Binding var text: String

    var body: some View {
        VStack {
            Text("Current text: \(text)")
            Button("Change Text") {
                text = "Changed by child!"
            }
        }
    }
}

/// Parent view that passes binding to child
@MainActor
struct ParentView: View {
    @State private var sharedText: String = "Hello from parent"

    var body: some View {
        VStack {
            Text("Parent text: \(sharedText)")
            // Pass binding to child using $
            ChildView(text: $sharedText)
        }
    }
}

// MARK: - Multiple State Example

/// Example with multiple state variables
@MainActor
struct FormView: View {
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var rememberMe: Bool = false
    @State private var loginCount: Int = 0

    var body: some View {
        VStack {
            Text("Username: \(username)")
            Text("Password: \(password.isEmpty ? "Not set" : "***")")
            Text("Remember me: \(rememberMe ? "Yes" : "No")")
            Text("Login attempts: \(loginCount)")

            Button("Login") {
                loginCount += 1
            }

            Button("Toggle Remember Me") {
                rememberMe.toggle()
            }
        }
    }
}

// MARK: - Computed Binding Example

/// Example showing how to create computed bindings
@MainActor
struct TemperatureView: View {
    @State private var celsius: Double = 20.0

    var fahrenheit: Binding<Double> {
        Binding(
            get: { celsius * 9/5 + 32 },
            set: { celsius = ($0 - 32) * 5/9 }
        )
    }

    var body: some View {
        VStack {
            Text("Temperature: \(celsius)°C")
            Text("Temperature: \(fahrenheit.wrappedValue)°F")

            Button("Increase Celsius") {
                celsius += 1
            }

            Button("Increase Fahrenheit") {
                fahrenheit.wrappedValue += 1
            }
        }
    }
}

// MARK: - Constant Binding Example

/// Example using constant bindings
@MainActor
struct ReadOnlyView: View {
    var body: some View {
        VStack {
            // Use constant binding when you don't need two-way binding
            ChildView(text: .constant("Read-only text"))
        }
    }
}

// MARK: - Complex State Example

/// Example with nested state and complex interactions
@MainActor
struct TodoListView: View {
    @State private var todos: [String] = []
    @State private var newTodoText: String = ""
    @State private var completedCount: Int = 0

    var body: some View {
        VStack {
            Text("Todo List (\(todos.count) items)")
            Text("Completed: \(completedCount)")

            Button("Add Todo") {
                if !newTodoText.isEmpty {
                    todos.append(newTodoText)
                    newTodoText = ""
                }
            }

            Button("Mark One Complete") {
                if !todos.isEmpty {
                    todos.removeFirst()
                    completedCount += 1
                }
            }

            Button("Clear All") {
                todos.removeAll()
                completedCount = 0
            }
        }
    }
}
