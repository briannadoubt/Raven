import Raven

/// Example demonstrating the Picker view functionality
struct PickerExample: View {
    @State private var selectedFlavor = Flavor.vanilla
    @State private var selectedColor = "red"
    @State private var quantity = 1
    @State private var priority = Priority.medium

    var body: some View {
        VStack {
            Text("Picker Examples")
                .padding()

            // Example 1: Enum-based picker
            VStack {
                Text("Flavor Selection")
                Picker("Select Flavor", selection: $selectedFlavor) {
                    Text("Vanilla").tag(Flavor.vanilla)
                    Text("Chocolate").tag(Flavor.chocolate)
                    Text("Strawberry").tag(Flavor.strawberry)
                }
                Text("Selected: \(selectedFlavor.rawValue)")
            }
            .padding()

            // Example 2: String-based picker
            VStack {
                Text("Color Selection")
                Picker("Color", selection: $selectedColor) {
                    Text("Red").tag("red")
                    Text("Green").tag("green")
                    Text("Blue").tag("blue")
                }
                Text("Selected color: \(selectedColor)")
            }
            .padding()

            // Example 3: Integer-based picker
            VStack {
                Text("Quantity Selection")
                Picker("Quantity", selection: $quantity) {
                    Text("1").tag(1)
                    Text("2").tag(2)
                    Text("3").tag(3)
                    Text("4").tag(4)
                    Text("5").tag(5)
                }
                Text("Quantity: \(quantity)")
            }
            .padding()

            // Example 4: Priority picker with custom enum
            VStack {
                Text("Priority Selection")
                Picker("Priority", selection: $priority) {
                    Text("Low").tag(Priority.low)
                    Text("Medium").tag(Priority.medium)
                    Text("High").tag(Priority.high)
                    Text("Critical").tag(Priority.critical)
                }
                .pickerStyle(.menu)
                Text("Priority: \(priority.rawValue)")
            }
            .padding()
        }
    }
}

// Supporting types for the example

enum Flavor: String, Hashable, Sendable {
    case vanilla = "Vanilla"
    case chocolate = "Chocolate"
    case strawberry = "Strawberry"
}

enum Priority: String, Hashable, Sendable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"
}
