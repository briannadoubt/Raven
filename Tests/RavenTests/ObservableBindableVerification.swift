import XCTest
@testable import Raven

/// Simplified verification tests for @Observable and @Bindable
/// These tests verify the basic functionality works correctly
@MainActor
final class ObservableBindableVerificationTests: XCTestCase {

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

    func testObservableBasicFunctionality() {
        let model = SimpleModel(value: 10)
        XCTAssertEqual(model.value, 10)

        model.value = 20
        XCTAssertEqual(model.value, 20)
    }

    func testObservableNotifications() {
        let model = SimpleModel()
        var notificationCount = 0

        _ = model.subscribe {
            notificationCount += 1
        }

        model.value = 1
        XCTAssertEqual(notificationCount, 1)

        model.value = 2
        XCTAssertEqual(notificationCount, 2)
    }

    func testObservableUnsubscribe() {
        let model = SimpleModel()
        var notificationCount = 0

        let id = model.subscribe {
            notificationCount += 1
        }

        model.value = 1
        XCTAssertEqual(notificationCount, 1)

        model.unsubscribe(id)

        model.value = 2
        XCTAssertEqual(notificationCount, 1, "Should not notify after unsubscribe")
    }

    // MARK: - Bindable Tests

    func testBindableBasicFunctionality() {
        let model = SimpleModel(value: 42)
        let bindable = Bindable(wrappedValue: model)

        XCTAssertIdentical(bindable.wrappedValue, model)
        XCTAssertEqual(model.value, 42)
    }

    func testBindableCreatesBindings() {
        let model = SimpleModel(value: 10)
        let bindable = Bindable(wrappedValue: model)

        let binding = bindable.value
        XCTAssertEqual(binding.wrappedValue, 10)

        binding.wrappedValue = 20
        XCTAssertEqual(model.value, 20)
        XCTAssertEqual(binding.wrappedValue, 20)
    }

    func testBindableTriggersNotifications() {
        let model = SimpleModel()
        let bindable = Bindable(wrappedValue: model)
        var notificationCount = 0

        _ = model.subscribe {
            notificationCount += 1
        }

        let binding = bindable.value
        binding.wrappedValue = 100

        XCTAssertEqual(notificationCount, 1)
        XCTAssertEqual(model.value, 100)
    }

    func testBindableProjectedValue() {
        let model = SimpleModel()
        let bindable = Bindable(wrappedValue: model)
        let projected = bindable.projectedValue

        XCTAssertIdentical(projected.wrappedValue, model)
    }

    // MARK: - Integration Tests

    func testObservableWithBindable() {
        let model = SimpleModel(value: 5)
        let bindable = Bindable(wrappedValue: model)
        var changeCount = 0

        _ = model.subscribe {
            changeCount += 1
        }

        // Modify through bindable binding
        let binding = bindable.value
        binding.wrappedValue = 10
        XCTAssertEqual(changeCount, 1)
        XCTAssertEqual(model.value, 10)

        // Modify through model directly
        model.value = 15
        XCTAssertEqual(changeCount, 2)
        XCTAssertEqual(binding.wrappedValue, 15)
    }

    func testObservationIgnored() {
        var ignored = ObservationIgnored(wrappedValue: "test")
        XCTAssertEqual(ignored.wrappedValue, "test")

        ignored.wrappedValue = "modified"
        XCTAssertEqual(ignored.wrappedValue, "modified")
    }

    func testBindableMethod() {
        let model = SimpleModel(value: 99)
        let bindable = model.bindable()

        XCTAssertIdentical(bindable.wrappedValue, model)

        let binding = bindable.value
        XCTAssertEqual(binding.wrappedValue, 99)
    }
}
