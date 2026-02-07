import Testing
@testable import Raven

/// Simplified verification tests for @Observable and @Bindable
/// These tests verify the basic functionality works correctly
@MainActor
@Suite struct ObservableBindableVerificationTests {

    // MARK: - Simple Test Model

    final class SimpleModel: Observable {
        let _$observationRegistrar = ObservationRegistrar()

        private var _value: Int
        var value: Int {
            get { _value }
            set {
                _$observationRegistrar.willSet()
                _value = newValue
            }
        }

        init(value: Int = 0) {
            self._value = value
            setupObservation()
        }
    }

    // MARK: - Observable Tests

    @Test func observableBasicFunctionality() {
        let model = SimpleModel(value: 10)
        #expect(model.value == 10)

        model.value = 20
        #expect(model.value == 20)
    }

    @Test func observableNotifications() {
        let model = SimpleModel()
        var notificationCount = 0

        _ = model.subscribe {
            notificationCount += 1
        }

        model.value = 1
        #expect(notificationCount == 1)

        model.value = 2
        #expect(notificationCount == 2)
    }

    @Test func observableUnsubscribe() {
        let model = SimpleModel()
        var notificationCount = 0

        let id = model.subscribe {
            notificationCount += 1
        }

        model.value = 1
        #expect(notificationCount == 1)

        model.unsubscribe(id)

        model.value = 2
        #expect(notificationCount == 1)
    }

    // MARK: - Bindable Tests

    @Test func bindableBasicFunctionality() {
        let model = SimpleModel(value: 42)
        let bindable = Bindable(wrappedValue: model)

        #expect(bindable.wrappedValue === model)
        #expect(model.value == 42)
    }

    @Test func bindableCreatesBindings() {
        let model = SimpleModel(value: 10)
        let bindable = Bindable(wrappedValue: model)

        let binding = bindable.value
        #expect(binding.wrappedValue == 10)

        binding.wrappedValue = 20
        #expect(model.value == 20)
        #expect(binding.wrappedValue == 20)
    }

    @Test func bindableTriggersNotifications() {
        let model = SimpleModel()
        let bindable = Bindable(wrappedValue: model)
        var notificationCount = 0

        _ = model.subscribe {
            notificationCount += 1
        }

        let binding = bindable.value
        binding.wrappedValue = 100

        #expect(notificationCount == 1)
        #expect(model.value == 100)
    }

    @Test func bindableProjectedValue() {
        let model = SimpleModel()
        let bindable = Bindable(wrappedValue: model)
        let projected = bindable.projectedValue

        #expect(projected.wrappedValue === model)
    }

    // MARK: - Integration Tests

    @Test func observableWithBindable() {
        let model = SimpleModel(value: 5)
        let bindable = Bindable(wrappedValue: model)
        var changeCount = 0

        _ = model.subscribe {
            changeCount += 1
        }

        // Modify through bindable binding
        let binding = bindable.value
        binding.wrappedValue = 10
        #expect(changeCount == 1)
        #expect(model.value == 10)

        // Modify through model directly
        model.value = 15
        #expect(changeCount == 2)
        #expect(binding.wrappedValue == 15)
    }

    @Test func observationIgnored() {
        var ignored = ObservationIgnored(wrappedValue: "test")
        #expect(ignored.wrappedValue == "test")

        ignored.wrappedValue = "modified"
        #expect(ignored.wrappedValue == "modified")
    }

    @Test func bindableMethod() {
        let model = SimpleModel(value: 99)
        let bindable = model.bindable()

        #expect(bindable.wrappedValue === model)

        let binding = bindable.value
        #expect(binding.wrappedValue == 99)
    }
}
