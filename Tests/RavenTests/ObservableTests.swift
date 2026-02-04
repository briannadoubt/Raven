import XCTest
@testable import Raven

// MARK: - Test Models

@MainActor
final class ObservableCounter: Observable {
    let _$observationRegistrar = ObservationRegistrar()

    private var _count: Int
    var count: Int {
        get { _count }
        set {
            _$observationRegistrar.willSet()
            _count = newValue
        }
    }

    private var _name: String
    var name: String {
        get { _name }
        set {
            _$observationRegistrar.willSet()
            _name = newValue
        }
    }

    init(count: Int = 0, name: String = "Counter") {
        self._count = count
        self._name = name
        setupObservation()
    }

    func increment() {
        count += 1
    }

    func decrement() {
        count -= 1
    }

    func reset() {
        count = 0
    }
}

@MainActor
final class ObservableUserSettings: Observable {
    let _$observationRegistrar = ObservationRegistrar()

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

    init(username: String = "", isDarkMode: Bool = false, fontSize: Double = 14.0) {
        self._username = username
        self._isDarkMode = isDarkMode
        self._fontSize = fontSize
        setupObservation()
    }

    func increaseFontSize() {
        fontSize += 2
    }

    func decreaseFontSize() {
        fontSize -= 2
    }
}

@MainActor
final class ObservableShoppingCart: Observable {
    let _$observationRegistrar = ObservationRegistrar()

    struct Item: Sendable, Equatable {
        let id: String
        let name: String
        let price: Double
    }

    private var _items: [Item]
    var items: [Item] {
        get { _items }
        set {
            _$observationRegistrar.willSet()
            _items = newValue
        }
    }

    var total: Double {
        items.reduce(0) { $0 + $1.price }
    }

    var itemCount: Int {
        items.count
    }

    init(items: [Item] = []) {
        self._items = items
        setupObservation()
    }

    func addItem(_ item: Item) {
        items.append(item)
    }

    func removeItem(at index: Int) {
        items.remove(at: index)
    }

    func clear() {
        items.removeAll()
    }
}

@MainActor
final class ObservableProfile: Observable {
    let _$observationRegistrar = ObservationRegistrar()

    private var _name: String
    var name: String {
        get { _name }
        set {
            _$observationRegistrar.willSet()
            _name = newValue
        }
    }

    private var _email: String
    var email: String {
        get { _email }
        set {
            _$observationRegistrar.willSet()
            _email = newValue
        }
    }

    init(name: String = "", email: String = "") {
        self._name = name
        self._email = email
        setupObservation()
    }
}

@MainActor
final class ObservableUser: Observable {
    let _$observationRegistrar = ObservationRegistrar()

    private var _profile: ObservableProfile
    var profile: ObservableProfile {
        get { _profile }
        set {
            _$observationRegistrar.willSet()
            _profile = newValue
        }
    }

    init(profile: ObservableProfile = ObservableProfile()) {
        self._profile = profile
        setupObservation()
    }
}

// MARK: - Observable Tests

@MainActor
final class ObservableTests: XCTestCase {

    // MARK: - Basic Observable Tests

    func testObservableProtocolConformance() {
        let counter = ObservableCounter()
        XCTAssert(counter is Observable)
        XCTAssertNotNil(counter._$observationRegistrar)
    }

    func testObservationRegistrarInitialization() {
        let counter = ObservableCounter()
        var changeCount = 0

        _ = counter.subscribe {
            changeCount += 1
        }

        counter.count = 1
        XCTAssertEqual(changeCount, 1)
    }

    func testPropertyChangesNotifyObservers() {
        let counter = ObservableCounter()
        var changeCount = 0

        _ = counter.subscribe {
            changeCount += 1
        }

        counter.count = 1
        XCTAssertEqual(changeCount, 1)

        counter.count = 2
        XCTAssertEqual(changeCount, 2)

        counter.name = "Test"
        XCTAssertEqual(changeCount, 3)
    }

    func testPropertyValuesUpdate() {
        let counter = ObservableCounter()
        XCTAssertEqual(counter.count, 0)
        XCTAssertEqual(counter.name, "Counter")

        counter.count = 5
        XCTAssertEqual(counter.count, 5)

        counter.name = "New Counter"
        XCTAssertEqual(counter.name, "New Counter")
    }

    func testMethodsModifyProperties() {
        let counter = ObservableCounter(count: 10)

        counter.increment()
        XCTAssertEqual(counter.count, 11)

        counter.decrement()
        XCTAssertEqual(counter.count, 10)

        counter.reset()
        XCTAssertEqual(counter.count, 0)
    }

    // MARK: - Multiple Property Tests

    func testMultiplePropertiesNotify() {
        let settings = ObservableUserSettings()
        var changeCount = 0

        _ = settings.subscribe {
            changeCount += 1
        }

        settings.username = "Alice"
        XCTAssertEqual(changeCount, 1)

        settings.isDarkMode = true
        XCTAssertEqual(changeCount, 2)

        settings.fontSize = 16.0
        XCTAssertEqual(changeCount, 3)
    }

    func testMultiplePropertiesValues() {
        let settings = ObservableUserSettings()

        settings.username = "Bob"
        settings.isDarkMode = true
        settings.fontSize = 18.0

        XCTAssertEqual(settings.username, "Bob")
        XCTAssertTrue(settings.isDarkMode)
        XCTAssertEqual(settings.fontSize, 18.0)
    }

    func testUserSettingsMethods() {
        let settings = ObservableUserSettings(fontSize: 14.0)

        settings.increaseFontSize()
        XCTAssertEqual(settings.fontSize, 16.0)

        settings.decreaseFontSize()
        XCTAssertEqual(settings.fontSize, 14.0)
    }

    // MARK: - Subscription Tests

    func testMultipleSubscribers() {
        let counter = ObservableCounter()
        var subscriber1Count = 0
        var subscriber2Count = 0

        _ = counter.subscribe {
            subscriber1Count += 1
        }

        _ = counter.subscribe {
            subscriber2Count += 1
        }

        counter.count = 1
        XCTAssertEqual(subscriber1Count, 1)
        XCTAssertEqual(subscriber2Count, 1)

        counter.count = 2
        XCTAssertEqual(subscriber1Count, 2)
        XCTAssertEqual(subscriber2Count, 2)
    }

    func testUnsubscribe() {
        let counter = ObservableCounter()
        var changeCount = 0

        let id = counter.subscribe {
            changeCount += 1
        }

        counter.count = 1
        XCTAssertEqual(changeCount, 1)

        counter.unsubscribe(id)

        counter.count = 2
        XCTAssertEqual(changeCount, 1, "Should not receive notifications after unsubscribe")
    }

    func testMultipleUnsubscribes() {
        let counter = ObservableCounter()
        var count1 = 0
        var count2 = 0

        let id1 = counter.subscribe { count1 += 1 }
        let id2 = counter.subscribe { count2 += 1 }

        counter.count = 1
        XCTAssertEqual(count1, 1)
        XCTAssertEqual(count2, 1)

        counter.unsubscribe(id1)
        counter.count = 2
        XCTAssertEqual(count1, 1)
        XCTAssertEqual(count2, 2)

        counter.unsubscribe(id2)
        counter.count = 3
        XCTAssertEqual(count1, 1)
        XCTAssertEqual(count2, 2)
    }

    // MARK: - Computed Property Tests

    func testComputedProperties() {
        let cart = ObservableShoppingCart()

        XCTAssertEqual(cart.total, 0.0)
        XCTAssertEqual(cart.itemCount, 0)

        cart.addItem(ObservableShoppingCart.Item(id: "1", name: "Widget", price: 9.99))
        XCTAssertEqual(cart.total, 9.99, accuracy: 0.01)
        XCTAssertEqual(cart.itemCount, 1)

        cart.addItem(ObservableShoppingCart.Item(id: "2", name: "Gadget", price: 14.99))
        XCTAssertEqual(cart.total, 24.98, accuracy: 0.01)
        XCTAssertEqual(cart.itemCount, 2)
    }

    func testComputedPropertiesUpdate() {
        let cart = ObservableShoppingCart()

        cart.addItem(ObservableShoppingCart.Item(id: "1", name: "Item 1", price: 10.0))
        cart.addItem(ObservableShoppingCart.Item(id: "2", name: "Item 2", price: 20.0))
        cart.addItem(ObservableShoppingCart.Item(id: "3", name: "Item 3", price: 30.0))

        XCTAssertEqual(cart.total, 60.0)
        XCTAssertEqual(cart.itemCount, 3)

        cart.removeItem(at: 1)
        XCTAssertEqual(cart.total, 40.0)
        XCTAssertEqual(cart.itemCount, 2)

        cart.clear()
        XCTAssertEqual(cart.total, 0.0)
        XCTAssertEqual(cart.itemCount, 0)
    }

    // MARK: - @Bindable Tests

    func testBindableInitialization() {
        let settings = ObservableUserSettings()
        let bindable = Bindable(wrappedValue: settings)

        XCTAssertIdentical(bindable.wrappedValue, settings)
    }

    func testBindableProjectedValue() {
        let settings = ObservableUserSettings()
        let bindable = Bindable(wrappedValue: settings)
        let projected = bindable.projectedValue

        XCTAssertIdentical(projected.wrappedValue, settings)
    }

    func testBindableDynamicMemberLookup() {
        let settings = ObservableUserSettings(username: "Alice", isDarkMode: true, fontSize: 16.0)
        let bindable = Bindable(wrappedValue: settings)

        let usernameBinding = bindable.username
        XCTAssertEqual(usernameBinding.wrappedValue, "Alice")

        let darkModeBinding = bindable.isDarkMode
        XCTAssertTrue(darkModeBinding.wrappedValue)

        let fontSizeBinding = bindable.fontSize
        XCTAssertEqual(fontSizeBinding.wrappedValue, 16.0)
    }

    func testBindingModifiesObservable() {
        let settings = ObservableUserSettings()
        let bindable = Bindable(wrappedValue: settings)

        let usernameBinding = bindable.username
        usernameBinding.wrappedValue = "Bob"

        XCTAssertEqual(settings.username, "Bob")
        XCTAssertEqual(usernameBinding.wrappedValue, "Bob")
    }

    func testBindingTriggersObservation() {
        let settings = ObservableUserSettings()
        let bindable = Bindable(wrappedValue: settings)
        var changeCount = 0

        _ = settings.subscribe {
            changeCount += 1
        }

        let usernameBinding = bindable.username
        usernameBinding.wrappedValue = "Charlie"

        XCTAssertEqual(changeCount, 1)
        XCTAssertEqual(settings.username, "Charlie")
    }

    func testBindableNestedProperties() {
        let user = ObservableUser(profile: ObservableProfile(name: "Alice", email: "alice@example.com"))
        let bindable = Bindable(wrappedValue: user)

        // Note: For nested observable objects, we'd need special handling
        // For now, test that we can bind to the nested object itself
        XCTAssertEqual(user.profile.name, "Alice")
        XCTAssertEqual(user.profile.email, "alice@example.com")
    }

    func testBindableWithState() {
        // Simulate using @Bindable with @State pattern
        var state = State(wrappedValue: ObservableUserSettings())
        let settings = state.wrappedValue
        let bindable = Bindable(wrappedValue: settings)

        let usernameBinding = bindable.username
        usernameBinding.wrappedValue = "TestUser"

        XCTAssertEqual(settings.username, "TestUser")
    }

    func testBindableSubscribe() {
        let settings = ObservableUserSettings()
        let bindable = Bindable(wrappedValue: settings)
        var changeCount = 0

        _ = bindable.subscribe {
            changeCount += 1
        }

        settings.username = "Dave"
        XCTAssertEqual(changeCount, 1)
    }

    func testBindableUnsubscribe() {
        let settings = ObservableUserSettings()
        let bindable = Bindable(wrappedValue: settings)
        var changeCount = 0

        let id = bindable.subscribe {
            changeCount += 1
        }

        settings.username = "Eve"
        XCTAssertEqual(changeCount, 1)

        bindable.unsubscribe(id)

        settings.username = "Frank"
        XCTAssertEqual(changeCount, 1)
    }

    // MARK: - Integration Tests

    func testObservableWithBindableIntegration() {
        let counter = ObservableCounter(count: 0, name: "Test")
        let bindable = Bindable(wrappedValue: counter)
        var changeCount = 0

        _ = counter.subscribe {
            changeCount += 1
        }

        // Modify through bindable
        let countBinding = bindable.count
        countBinding.wrappedValue = 10
        XCTAssertEqual(changeCount, 1)
        XCTAssertEqual(counter.count, 10)

        // Modify through counter directly
        counter.increment()
        XCTAssertEqual(changeCount, 2)
        XCTAssertEqual(countBinding.wrappedValue, 11)
    }

    func testMultipleBindingsToSameProperty() {
        let settings = ObservableUserSettings()
        let bindable = Bindable(wrappedValue: settings)

        let binding1 = bindable.username
        let binding2 = bindable.username

        binding1.wrappedValue = "User1"
        XCTAssertEqual(binding2.wrappedValue, "User1")
        XCTAssertEqual(settings.username, "User1")

        binding2.wrappedValue = "User2"
        XCTAssertEqual(binding1.wrappedValue, "User2")
        XCTAssertEqual(settings.username, "User2")
    }

    func testObservableBindableMethod() {
        let counter = ObservableCounter()
        let bindable = counter.bindable()

        XCTAssertIdentical(bindable.wrappedValue, counter)
    }

    // MARK: - Thread Safety Tests

    func testMainActorIsolation() async {
        await MainActor.run {
            let counter = ObservableCounter()
            counter.count = 10
            XCTAssertEqual(counter.count, 10)

            let bindable = Bindable(wrappedValue: counter)
            let binding = bindable.count
            binding.wrappedValue = 20
            XCTAssertEqual(counter.count, 20)
        }
    }

    // MARK: - ObservationIgnored Tests

    func testObservationIgnored() {
        var ignored = ObservationIgnored(wrappedValue: 42)
        XCTAssertEqual(ignored.wrappedValue, 42)

        ignored.wrappedValue = 100
        XCTAssertEqual(ignored.wrappedValue, 100)
    }

    func testObservationIgnoredWithDifferentTypes() {
        var intIgnored = ObservationIgnored(wrappedValue: 42)
        var stringIgnored = ObservationIgnored(wrappedValue: "test")
        var boolIgnored = ObservationIgnored(wrappedValue: true)

        XCTAssertEqual(intIgnored.wrappedValue, 42)
        XCTAssertEqual(stringIgnored.wrappedValue, "test")
        XCTAssertTrue(boolIgnored.wrappedValue)

        intIgnored.wrappedValue = 100
        stringIgnored.wrappedValue = "modified"
        boolIgnored.wrappedValue = false

        XCTAssertEqual(intIgnored.wrappedValue, 100)
        XCTAssertEqual(stringIgnored.wrappedValue, "modified")
        XCTAssertFalse(boolIgnored.wrappedValue)
    }

    // MARK: - Edge Cases

    func testEmptyObservable() {
        @MainActor
        final class EmptyModel: Observable {
            let _$observationRegistrar = ObservationRegistrar()

            init() {
                setupObservation()
            }
        }

        let model = EmptyModel()
        var changeCount = 0

        _ = model.subscribe {
            changeCount += 1
        }

        // Manually trigger
        model._$observationRegistrar.willSet()
        XCTAssertEqual(changeCount, 1)
    }

    func testObservableWithOptionals() {
        @MainActor
        final class OptionalModel: Observable {
            let _$observationRegistrar = ObservationRegistrar()

            private var _value: String?
            var value: String? {
                get { _value }
                set {
                    _$observationRegistrar.willSet()
                    _value = newValue
                }
            }

            init(value: String? = nil) {
                self._value = value
                setupObservation()
            }
        }

        let model = OptionalModel()
        var changeCount = 0

        _ = model.subscribe {
            changeCount += 1
        }

        XCTAssertNil(model.value)

        model.value = "test"
        XCTAssertEqual(changeCount, 1)
        XCTAssertEqual(model.value, "test")

        model.value = nil
        XCTAssertEqual(changeCount, 2)
        XCTAssertNil(model.value)
    }

    func testObservableWithArrays() {
        @MainActor
        final class ArrayModel: Observable {
            let _$observationRegistrar = ObservationRegistrar()

            private var _items: [String]
            var items: [String] {
                get { _items }
                set {
                    _$observationRegistrar.willSet()
                    _items = newValue
                }
            }

            init(items: [String] = []) {
                self._items = items
                setupObservation()
            }
        }

        let model = ArrayModel()
        var changeCount = 0

        _ = model.subscribe {
            changeCount += 1
        }

        model.items = ["a", "b", "c"]
        XCTAssertEqual(changeCount, 1)
        XCTAssertEqual(model.items.count, 3)

        model.items.append("d")
        XCTAssertEqual(changeCount, 2)
        XCTAssertEqual(model.items.count, 4)
    }
}
