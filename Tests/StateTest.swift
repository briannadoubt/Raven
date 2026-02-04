import Foundation
import Raven

// Simple test to verify State compiles
@MainActor
struct TestView: View {
    @State private var count: Int = 0
    @State private var text: String = "Hello"
    @State private var isEnabled: Bool = true

    var body: some View {
        Text("Count: \(count)")
    }
}

// Test that bindings work
@MainActor
func testBinding() {
    var state = State(wrappedValue: 42)
    let binding = state.projectedValue

    // Test reading
    let value = binding.wrappedValue
    print("Value: \(value)")

    // Test writing
    binding.wrappedValue = 100
    print("New value: \(state.wrappedValue)")
}

// Test constant binding
@MainActor
func testConstantBinding() {
    let binding = Binding.constant("test")
    print("Constant: \(binding.wrappedValue)")
}
