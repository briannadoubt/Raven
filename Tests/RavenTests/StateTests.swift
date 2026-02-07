import Testing
@testable import Raven

/// Tests for @State property wrapper
@MainActor
@Suite struct StateTests {

    // MARK: - State Basic Tests

    @Test func stateInitialization() {
        var state = State(wrappedValue: 42)
        #expect(state.wrappedValue == 42)
    }

    @Test func stateInitialValue() {
        var state = State(initialValue: "Hello")
        #expect(state.wrappedValue == "Hello")
    }

    @Test func stateModification() {
        var state = State(wrappedValue: 0)
        #expect(state.wrappedValue == 0)

        state.wrappedValue = 10
        #expect(state.wrappedValue == 10)

        state.wrappedValue = 100
        #expect(state.wrappedValue == 100)
    }

    @Test func stateWithDifferentTypes() {
        var intState = State(wrappedValue: 42)
        var stringState = State(wrappedValue: "test")
        var boolState = State(wrappedValue: true)
        var doubleState = State(wrappedValue: 3.14)

        #expect(intState.wrappedValue == 42)
        #expect(stringState.wrappedValue == "test")
        #expect(boolState.wrappedValue == true)
        #expect(doubleState.wrappedValue == 3.14)
    }

    // MARK: - Binding Tests

    @Test func bindingFromState() {
        var state = State(wrappedValue: 42)
        let binding = state.projectedValue

        // Reading from binding should return state value
        #expect(binding.wrappedValue == 42)
    }

    @Test func bindingModifiesState() {
        var state = State(wrappedValue: 42)
        let binding = state.projectedValue

        // Writing to binding should update state
        binding.wrappedValue = 100
        #expect(state.wrappedValue == 100)
        #expect(binding.wrappedValue == 100)
    }

    @Test func bindingCreation() {
        var value = 42

        let binding = Binding(
            get: { value },
            set: { value = $0 }
        )

        #expect(binding.wrappedValue == 42)

        binding.wrappedValue = 100
        #expect(value == 100)
        #expect(binding.wrappedValue == 100)
    }

    @Test func constantBinding() {
        let binding = Binding.constant(42)

        #expect(binding.wrappedValue == 42)

        // Writing to constant binding should be ignored
        binding.wrappedValue = 100
        #expect(binding.wrappedValue == 42)
    }

    @Test func bindingProjectedValue() {
        var state = State(wrappedValue: 42)
        let binding = state.projectedValue
        let projected = binding.projectedValue

        // Projected value of binding should be itself
        #expect(projected.wrappedValue == 42)

        projected.wrappedValue = 100
        #expect(state.wrappedValue == 100)
    }

    // MARK: - Binding Transformation Tests

    @Test func bindingTransformation() {
        var state = State(wrappedValue: 20.0)

        // Create a binding that converts Celsius to Fahrenheit
        let fahrenheit = Binding<Double>(
            state.projectedValue,
            get: { (celsius: Double) -> Double in celsius * 9/5 + 32 },
            set: { (celsius: Double, fahrenheit: Double) -> Double in (fahrenheit - 32) * 5/9 }
        )

        // 20C should be 68F
        #expect(abs(fahrenheit.wrappedValue - 68.0) < 0.01)

        // Set to 32F (0C)
        fahrenheit.wrappedValue = 32.0
        #expect(abs(state.wrappedValue - 0.0) < 0.01)
    }

    // MARK: - Dynamic Member Lookup Tests

    @Test func bindingDynamicMemberLookup() {
        struct Person: Sendable {
            var name: String
            var age: Int
        }

        var state = State(wrappedValue: Person(name: "Alice", age: 30))

        // Get a binding to the name property using dynamic member lookup
        let nameBinding = state.projectedValue.name
        #expect(nameBinding.wrappedValue == "Alice")

        // Modify through the nested binding
        nameBinding.wrappedValue = "Bob"
        #expect(state.wrappedValue.name == "Bob")
        #expect(nameBinding.wrappedValue == "Bob")

        // Get a binding to the age property
        let ageBinding = state.projectedValue.age
        #expect(ageBinding.wrappedValue == 30)

        ageBinding.wrappedValue = 25
        #expect(state.wrappedValue.age == 25)
        #expect(state.wrappedValue.name == "Bob")
    }

    @Test func bindingDynamicMemberLookupNested() {
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
        #expect(addressBinding.wrappedValue.city == "Springfield")

        let cityBinding = addressBinding.city
        #expect(cityBinding.wrappedValue == "Springfield")

        cityBinding.wrappedValue = "Shelbyville"
        #expect(state.wrappedValue.address.city == "Shelbyville")
    }

    // MARK: - Update Callback Tests

    @Test func stateUpdateCallback() {
        var state = State(wrappedValue: 0)
        var callbackCount = 0

        // Set update callback
        state.setUpdateCallback {
            callbackCount += 1
        }

        // Changing state should trigger callback
        state.wrappedValue = 1
        #expect(callbackCount == 1)

        state.wrappedValue = 2
        #expect(callbackCount == 2)

        state.wrappedValue = 3
        #expect(callbackCount == 3)
    }

    @Test func stateUpdateCallbackNotCalledOnRead() {
        var state = State(wrappedValue: 42)
        var callbackCount = 0

        state.setUpdateCallback {
            callbackCount += 1
        }

        // Reading should not trigger callback
        let _ = state.wrappedValue
        let _ = state.wrappedValue
        let _ = state.wrappedValue

        #expect(callbackCount == 0)
    }

    // MARK: - DynamicProperty Tests

    @Test func stateDynamicProperty() {
        var state = State(wrappedValue: 42)

        // State conforms to DynamicProperty
        #expect(state is any DynamicProperty)

        // Update should be callable (even if it does nothing by default)
        state.update()

        #expect(state.wrappedValue == 42)
    }

    @Test func bindingDynamicProperty() {
        let binding = Binding.constant(42)

        // Binding conforms to DynamicProperty
        #expect(binding is any DynamicProperty)

        // Update should be callable
        var mutableBinding = binding
        mutableBinding.update()

        #expect(binding.wrappedValue == 42)
    }

    // MARK: - Complex State Tests

    @Test func stateWithArrays() {
        var state = State(wrappedValue: [1, 2, 3])

        #expect(state.wrappedValue == [1, 2, 3])

        state.wrappedValue.append(4)
        #expect(state.wrappedValue == [1, 2, 3, 4])

        state.wrappedValue = [10, 20]
        #expect(state.wrappedValue == [10, 20])
    }

    @Test func stateWithOptionals() {
        var state = State<Int?>(wrappedValue: nil)

        #expect(state.wrappedValue == nil)

        state.wrappedValue = 42
        #expect(state.wrappedValue == 42)

        state.wrappedValue = nil
        #expect(state.wrappedValue == nil)
    }

    // MARK: - Sendable Tests

    @Test func stateSendable() {
        // State should be Sendable
        #expect(State<Int>.self is any Sendable.Type)
        #expect(State<String>.self is any Sendable.Type)
    }

    @Test func bindingSendable() {
        // Binding should be Sendable
        #expect(Binding<Int>.self is any Sendable.Type)
        #expect(Binding<String>.self is any Sendable.Type)
    }
}
