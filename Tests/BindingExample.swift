import Foundation
import Raven

// MARK: - Comprehensive Binding Example
//
// This file demonstrates all the features of the @Binding implementation
// and how it integrates with @State for two-way data flow.

// MARK: - Basic Child View with Binding

/// A simple toggle button that uses a binding to modify its parent's state
@MainActor
struct ToggleView: View {
    @Binding var isOn: Bool

    var body: some View {
        Button(isOn ? "Turn Off" : "Turn On") {
            isOn.toggle()
        }
    }
}

// MARK: - Parent View with State

/// Parent view that owns the state and passes a binding to the child
@MainActor
struct ParentView: View {
    @State private var isToggled = false

    var body: some View {
        VStack {
            Text(isToggled ? "ON" : "OFF")
            // Pass binding using $state syntax
            ToggleView(isOn: $isToggled)
        }
    }
}

// MARK: - Nested Property Binding Example

/// Demonstrates dynamic member lookup for nested properties
@MainActor
struct UserProfileEditor: View {
    struct UserProfile: Sendable {
        var name: String
        var email: String
        var age: Int
    }

    @State private var profile = UserProfile(
        name: "Alice",
        email: "alice@example.com",
        age: 30
    )

    var body: some View {
        VStack {
            // Use dynamic member lookup to bind to nested properties
            TextField(text: $profile.name)
            TextField(text: $profile.email)
            Text("Age: \(profile.age)")
        }
    }
}

// MARK: - TextField Placeholder (for demo purposes)

@MainActor
struct TextField: View {
    @Binding var text: String

    init(text: Binding<String>) {
        self._text = text
    }

    var body: some View {
        Text("TextField: \(text)")
    }
}

// MARK: - Binding Transformation Example

/// Demonstrates how to create derived bindings with transformations
@MainActor
struct TemperatureConverter: View {
    @State private var celsius: Double = 20.0

    // Create a computed binding that transforms the value
    var fahrenheitBinding: Binding<Double> {
        Binding(
            get: { celsius * 9/5 + 32 },
            set: { newFahrenheit in
                celsius = (newFahrenheit - 32) * 5/9
            }
        )
    }

    var body: some View {
        VStack {
            Text("Celsius: \(celsius)")
            Text("Fahrenheit: \(fahrenheitBinding.wrappedValue)")
        }
    }
}

// MARK: - Constant Binding Example

/// Shows how to use constant bindings for preview or read-only scenarios
@MainActor
struct PreviewToggle: View {
    var body: some View {
        // Use constant binding when you don't need state changes
        ToggleView(isOn: .constant(true))
    }
}

// MARK: - Deep Nested Binding Example

/// Demonstrates multi-level dynamic member lookup
@MainActor
struct AddressForm: View {
    struct Address: Sendable {
        var street: String
        var city: String
        var zipCode: String
    }

    struct Person: Sendable {
        var name: String
        var address: Address
    }

    @State private var person = Person(
        name: "Bob",
        address: Address(street: "123 Main St", city: "Springfield", zipCode: "12345")
    )

    var body: some View {
        VStack {
            TextField(text: $person.name)
            // Access deeply nested properties using chained dynamic member lookup
            TextField(text: $person.address.street)
            TextField(text: $person.address.city)
            TextField(text: $person.address.zipCode)
        }
    }
}

// MARK: - Custom Binding Creation

/// Shows how to create custom bindings programmatically
@MainActor
struct CustomBindingExample: View {
    @State private var items: [String] = ["Apple", "Banana", "Cherry"]

    func bindingForItem(at index: Int) -> Binding<String> {
        Binding(
            get: { items[index] },
            set: { newValue in
                items[index] = newValue
            }
        )
    }

    var body: some View {
        VStack {
            // Use custom bindings for collection items
            TextField(text: bindingForItem(at: 0))
            TextField(text: bindingForItem(at: 1))
            TextField(text: bindingForItem(at: 2))
        }
    }
}

// MARK: - Demonstration Function

/// Function that demonstrates all binding features work correctly
@MainActor
func demonstrateBindingFeatures() {
    print("=== Binding Feature Demonstration ===\n")

    // 1. Basic State and Binding
    print("1. Basic State and Binding:")
    var state = State(wrappedValue: 42)
    let binding = state.projectedValue
    print("   Initial value: \(binding.wrappedValue)")
    binding.wrappedValue = 100
    print("   After binding update: \(state.wrappedValue)")
    print("   ✓ Two-way binding works!\n")

    // 2. Constant Binding
    print("2. Constant Binding:")
    let constant = Binding.constant("unchangeable")
    print("   Value: \(constant.wrappedValue)")
    constant.wrappedValue = "attempt change"
    print("   After set attempt: \(constant.wrappedValue)")
    print("   ✓ Constant binding ignores writes!\n")

    // 3. Dynamic Member Lookup
    print("3. Dynamic Member Lookup:")
    struct TestPerson: Sendable {
        var name: String
        var age: Int
    }
    var personState = State(wrappedValue: TestPerson(name: "Alice", age: 30))
    let nameBinding = personState.projectedValue.name
    print("   Initial name: \(nameBinding.wrappedValue)")
    nameBinding.wrappedValue = "Bob"
    print("   After update: \(personState.wrappedValue.name)")
    print("   ✓ Dynamic member lookup works!\n")

    // 4. Binding Transformation
    print("4. Binding Transformation:")
    var tempState = State(wrappedValue: 20.0)
    let fahrenheit = Binding<Double>(
        tempState.projectedValue,
        get: { (celsius: Double) -> Double in celsius * 9/5 + 32 },
        set: { (celsius: Double, fahrenheit: Double) -> Double in (fahrenheit - 32) * 5/9 }
    )
    print("   20°C = \(fahrenheit.wrappedValue)°F")
    fahrenheit.wrappedValue = 32.0
    print("   Set to 32°F = \(tempState.wrappedValue)°C")
    print("   ✓ Binding transformation works!\n")

    print("=== All Binding Features Working! ===")
}
