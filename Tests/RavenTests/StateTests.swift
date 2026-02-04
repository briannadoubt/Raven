import XCTest
@testable import Raven

/// Tests for @State property wrapper
@MainActor
final class StateTests: XCTestCase {

    // MARK: - State Basic Tests

    func testStateInitialization() {
        var state = State(wrappedValue: 42)
        XCTAssertEqual(state.wrappedValue, 42)
    }

    func testStateInitialValue() {
        var state = State(initialValue: "Hello")
        XCTAssertEqual(state.wrappedValue, "Hello")
    }

    func testStateModification() {
        var state = State(wrappedValue: 0)
        XCTAssertEqual(state.wrappedValue, 0)

        state.wrappedValue = 10
        XCTAssertEqual(state.wrappedValue, 10)

        state.wrappedValue = 100
        XCTAssertEqual(state.wrappedValue, 100)
    }

    func testStateWithDifferentTypes() {
        var intState = State(wrappedValue: 42)
        var stringState = State(wrappedValue: "test")
        var boolState = State(wrappedValue: true)
        var doubleState = State(wrappedValue: 3.14)

        XCTAssertEqual(intState.wrappedValue, 42)
        XCTAssertEqual(stringState.wrappedValue, "test")
        XCTAssertEqual(boolState.wrappedValue, true)
        XCTAssertEqual(doubleState.wrappedValue, 3.14)
    }

    // MARK: - Binding Tests

    func testBindingFromState() {
        var state = State(wrappedValue: 42)
        let binding = state.projectedValue

        // Reading from binding should return state value
        XCTAssertEqual(binding.wrappedValue, 42)
    }

    func testBindingModifiesState() {
        var state = State(wrappedValue: 42)
        let binding = state.projectedValue

        // Writing to binding should update state
        binding.wrappedValue = 100
        XCTAssertEqual(state.wrappedValue, 100)
        XCTAssertEqual(binding.wrappedValue, 100)
    }

    func testBindingCreation() {
        var value = 42

        let binding = Binding(
            get: { value },
            set: { value = $0 }
        )

        XCTAssertEqual(binding.wrappedValue, 42)

        binding.wrappedValue = 100
        XCTAssertEqual(value, 100)
        XCTAssertEqual(binding.wrappedValue, 100)
    }

    func testConstantBinding() {
        let binding = Binding.constant(42)

        XCTAssertEqual(binding.wrappedValue, 42)

        // Writing to constant binding should be ignored
        binding.wrappedValue = 100
        XCTAssertEqual(binding.wrappedValue, 42)
    }

    func testBindingProjectedValue() {
        var state = State(wrappedValue: 42)
        let binding = state.projectedValue
        let projected = binding.projectedValue

        // Projected value of binding should be itself
        XCTAssertEqual(projected.wrappedValue, 42)

        projected.wrappedValue = 100
        XCTAssertEqual(state.wrappedValue, 100)
    }

    // MARK: - Binding Transformation Tests

    func testBindingTransformation() {
        var state = State(wrappedValue: 20.0)

        // Create a binding that converts Celsius to Fahrenheit
        let fahrenheit = Binding<Double>(
            state.projectedValue,
            get: { (celsius: Double) -> Double in celsius * 9/5 + 32 },
            set: { (celsius: Double, fahrenheit: Double) -> Double in (fahrenheit - 32) * 5/9 }
        )

        // 20°C should be 68°F
        XCTAssertEqual(fahrenheit.wrappedValue, 68.0, accuracy: 0.01)

        // Set to 32°F (0°C)
        fahrenheit.wrappedValue = 32.0
        XCTAssertEqual(state.wrappedValue, 0.0, accuracy: 0.01)
    }

    // MARK: - Dynamic Member Lookup Tests

    func testBindingDynamicMemberLookup() {
        struct Person: Sendable {
            var name: String
            var age: Int
        }

        var state = State(wrappedValue: Person(name: "Alice", age: 30))

        // Get a binding to the name property using dynamic member lookup
        let nameBinding = state.projectedValue.name
        XCTAssertEqual(nameBinding.wrappedValue, "Alice")

        // Modify through the nested binding
        nameBinding.wrappedValue = "Bob"
        XCTAssertEqual(state.wrappedValue.name, "Bob")
        XCTAssertEqual(nameBinding.wrappedValue, "Bob")

        // Get a binding to the age property
        let ageBinding = state.projectedValue.age
        XCTAssertEqual(ageBinding.wrappedValue, 30)

        ageBinding.wrappedValue = 25
        XCTAssertEqual(state.wrappedValue.age, 25)
        XCTAssertEqual(state.wrappedValue.name, "Bob")
    }

    func testBindingDynamicMemberLookupNested() {
        struct Address: Sendable {
            var street: String
            var city: String
        }

        struct Person: Sendable {
            var name: String
            var address: Address
        }

        var state = State(wrappedValue: Person(
            name: "Alice",
            address: Address(street: "123 Main St", city: "Springfield")
        ))

        // Access nested properties using dynamic member lookup
        let addressBinding = state.projectedValue.address
        XCTAssertEqual(addressBinding.wrappedValue.city, "Springfield")

        let cityBinding = addressBinding.city
        XCTAssertEqual(cityBinding.wrappedValue, "Springfield")

        cityBinding.wrappedValue = "Shelbyville"
        XCTAssertEqual(state.wrappedValue.address.city, "Shelbyville")
    }

    // MARK: - Update Callback Tests

    func testStateUpdateCallback() {
        var state = State(wrappedValue: 0)
        var callbackCount = 0

        // Set update callback
        state.setUpdateCallback {
            callbackCount += 1
        }

        // Changing state should trigger callback
        state.wrappedValue = 1
        XCTAssertEqual(callbackCount, 1)

        state.wrappedValue = 2
        XCTAssertEqual(callbackCount, 2)

        state.wrappedValue = 3
        XCTAssertEqual(callbackCount, 3)
    }

    func testStateUpdateCallbackNotCalledOnRead() {
        var state = State(wrappedValue: 42)
        var callbackCount = 0

        state.setUpdateCallback {
            callbackCount += 1
        }

        // Reading should not trigger callback
        let _ = state.wrappedValue
        let _ = state.wrappedValue
        let _ = state.wrappedValue

        XCTAssertEqual(callbackCount, 0)
    }

    // MARK: - DynamicProperty Tests

    func testStateDynamicProperty() {
        var state = State(wrappedValue: 42)

        // State conforms to DynamicProperty
        XCTAssert(state is any DynamicProperty)

        // Update should be callable (even if it does nothing by default)
        state.update()

        XCTAssertEqual(state.wrappedValue, 42)
    }

    func testBindingDynamicProperty() {
        let binding = Binding.constant(42)

        // Binding conforms to DynamicProperty
        XCTAssert(binding is any DynamicProperty)

        // Update should be callable
        var mutableBinding = binding
        mutableBinding.update()

        XCTAssertEqual(binding.wrappedValue, 42)
    }

    // MARK: - Complex State Tests

    func testStateWithArrays() {
        var state = State(wrappedValue: [1, 2, 3])

        XCTAssertEqual(state.wrappedValue, [1, 2, 3])

        state.wrappedValue.append(4)
        XCTAssertEqual(state.wrappedValue, [1, 2, 3, 4])

        state.wrappedValue = [10, 20]
        XCTAssertEqual(state.wrappedValue, [10, 20])
    }

    func testStateWithOptionals() {
        var state = State<Int?>(wrappedValue: nil)

        XCTAssertNil(state.wrappedValue)

        state.wrappedValue = 42
        XCTAssertEqual(state.wrappedValue, 42)

        state.wrappedValue = nil
        XCTAssertNil(state.wrappedValue)
    }

    // MARK: - Sendable Tests

    func testStateSendable() {
        // State should be Sendable
        XCTAssert(State<Int>.self is any Sendable.Type)
        XCTAssert(State<String>.self is any Sendable.Type)
    }

    func testBindingSendable() {
        // Binding should be Sendable
        XCTAssert(Binding<Int>.self is any Sendable.Type)
        XCTAssert(Binding<String>.self is any Sendable.Type)
    }
}
