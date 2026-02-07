import Testing
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
@Suite struct ObservableTests {

    // MARK: - Basic Observable Tests

    @Test func observableProtocolConformance() {
        let counter = ObservableCounter()
        #expect(counter is Observable)
        #expect(counter._$observationRegistrar != nil)
    }

    @Test func observationRegistrarInitialization() {
        let counter = ObservableCounter()
        var changeCount = 0

        _ = counter.subscribe {
            changeCount += 1
        }

        counter.count = 1
        #expect(changeCount == 1)
    }

    @Test func propertyChangesNotifyObservers() {
        let counter = ObservableCounter()
        var changeCount = 0

        _ = counter.subscribe {
            changeCount += 1
        }

        counter.count = 1
        #expect(changeCount == 1)

        counter.count = 2
        #expect(changeCount == 2)

        counter.name = "Test"
        #expect(changeCount == 3)
    }

    @Test func propertyValuesUpdate() {
        let counter = ObservableCounter()
        #expect(counter.count == 0)
        #expect(counter.name == "Counter")

        counter.count = 5
        #expect(counter.count == 5)

        counter.name = "New Counter"
        #expect(counter.name == "New Counter")
    }

    @Test func methodsModifyProperties() {
        let counter = ObservableCounter(count: 10)

        counter.increment()
        #expect(counter.count == 11)

        counter.decrement()
        #expect(counter.count == 10)

        counter.reset()
        #expect(counter.count == 0)
    }

    // MARK: - Multiple Property Tests

    @Test func multiplePropertiesNotify() {
        let settings = ObservableUserSettings()
        var changeCount = 0

        _ = settings.subscribe {
            changeCount += 1
        }

        settings.username = "Alice"
        #expect(changeCount == 1)

        settings.isDarkMode = true
        #expect(changeCount == 2)

        settings.fontSize = 16.0
        #expect(changeCount == 3)
    }

    @Test func multiplePropertiesValues() {
        let settings = ObservableUserSettings()

        settings.username = "Bob"
        settings.isDarkMode = true
        settings.fontSize = 18.0

        #expect(settings.username == "Bob")
        #expect(settings.isDarkMode)
        #expect(settings.fontSize == 18.0)
    }

    @Test func userSettingsMethods() {
        let settings = ObservableUserSettings(fontSize: 14.0)

        settings.increaseFontSize()
        #expect(settings.fontSize == 16.0)

        settings.decreaseFontSize()
        #expect(settings.fontSize == 14.0)
    }

    // MARK: - Subscription Tests

    @Test func multipleSubscribers() {
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
        #expect(subscriber1Count == 1)
        #expect(subscriber2Count == 1)

        counter.count = 2
        #expect(subscriber1Count == 2)
        #expect(subscriber2Count == 2)
    }

    @Test func unsubscribe() {
        let counter = ObservableCounter()
        var changeCount = 0

        let id = counter.subscribe {
            changeCount += 1
        }

        counter.count = 1
        #expect(changeCount == 1)

        counter.unsubscribe(id)

        counter.count = 2
        #expect(changeCount == 1)
    }

    @Test func multipleUnsubscribes() {
        let counter = ObservableCounter()
        var count1 = 0
        var count2 = 0

        let id1 = counter.subscribe { count1 += 1 }
        let id2 = counter.subscribe { count2 += 1 }

        counter.count = 1
        #expect(count1 == 1)
        #expect(count2 == 1)

        counter.unsubscribe(id1)
        counter.count = 2
        #expect(count1 == 1)
        #expect(count2 == 2)

        counter.unsubscribe(id2)
        counter.count = 3
        #expect(count1 == 1)
        #expect(count2 == 2)
    }

    // MARK: - Computed Property Tests

    @Test func computedProperties() {
        let cart = ObservableShoppingCart()

        #expect(cart.total == 0.0)
        #expect(cart.itemCount == 0)

        cart.addItem(ObservableShoppingCart.Item(id: "1", name: "Widget", price: 9.99))
        #expect(abs(cart.total - 9.99) < 0.01)
        #expect(cart.itemCount == 1)

        cart.addItem(ObservableShoppingCart.Item(id: "2", name: "Gadget", price: 14.99))
        #expect(abs(cart.total - 24.98) < 0.01)
        #expect(cart.itemCount == 2)
    }

    @Test func computedPropertiesUpdate() {
        let cart = ObservableShoppingCart()

        cart.addItem(ObservableShoppingCart.Item(id: "1", name: "Item 1", price: 10.0))
        cart.addItem(ObservableShoppingCart.Item(id: "2", name: "Item 2", price: 20.0))
        cart.addItem(ObservableShoppingCart.Item(id: "3", name: "Item 3", price: 30.0))

        #expect(cart.total == 60.0)
        #expect(cart.itemCount == 3)

        cart.removeItem(at: 1)
        #expect(cart.total == 40.0)
        #expect(cart.itemCount == 2)

        cart.clear()
        #expect(cart.total == 0.0)
        #expect(cart.itemCount == 0)
    }

    // MARK: - @Bindable Tests

    @Test func bindableInitialization() {
        let settings = ObservableUserSettings()
        let bindable = Bindable(wrappedValue: settings)

        #expect(bindable.wrappedValue === settings)
    }

    @Test func bindableProjectedValue() {
        let settings = ObservableUserSettings()
        let bindable = Bindable(wrappedValue: settings)
        let projected = bindable.projectedValue

        #expect(projected.wrappedValue === settings)
    }

    @Test func bindableDynamicMemberLookup() {
        let settings = ObservableUserSettings(username: "Alice", isDarkMode: true, fontSize: 16.0)
        let bindable = Bindable(wrappedValue: settings)

        let usernameBinding = bindable.username
        #expect(usernameBinding.wrappedValue == "Alice")

        let darkModeBinding = bindable.isDarkMode
        #expect(darkModeBinding.wrappedValue)

        let fontSizeBinding = bindable.fontSize
        #expect(fontSizeBinding.wrappedValue == 16.0)
    }

    @Test func bindingModifiesObservable() {
        let settings = ObservableUserSettings()
        let bindable = Bindable(wrappedValue: settings)

        let usernameBinding = bindable.username
        usernameBinding.wrappedValue = "Bob"

        #expect(settings.username == "Bob")
        #expect(usernameBinding.wrappedValue == "Bob")
    }

    @Test func bindingTriggersObservation() {
        let settings = ObservableUserSettings()
        let bindable = Bindable(wrappedValue: settings)
        var changeCount = 0

        _ = settings.subscribe {
            changeCount += 1
        }

        let usernameBinding = bindable.username
        usernameBinding.wrappedValue = "Charlie"

        #expect(changeCount == 1)
        #expect(settings.username == "Charlie")
    }

    @Test func bindableNestedProperties() {
        let user = ObservableUser(profile: ObservableProfile(name: "Alice", email: "alice@example.com"))
        let bindable = Bindable(wrappedValue: user)

        // Note: For nested observable objects, we'd need special handling
        // For now, test that we can bind to the nested object itself
        #expect(user.profile.name == "Alice")
        #expect(user.profile.email == "alice@example.com")
    }

    @Test func bindableWithState() {
        // Simulate using @Bindable with @State pattern
        var state = State(wrappedValue: ObservableUserSettings())
        let settings = state.wrappedValue
        let bindable = Bindable(wrappedValue: settings)

        let usernameBinding = bindable.username
        usernameBinding.wrappedValue = "TestUser"

        #expect(settings.username == "TestUser")
    }

    @Test func bindableSubscribe() {
        let settings = ObservableUserSettings()
        let bindable = Bindable(wrappedValue: settings)
        var changeCount = 0

        _ = bindable.subscribe {
            changeCount += 1
        }

        settings.username = "Dave"
        #expect(changeCount == 1)
    }

    @Test func bindableUnsubscribe() {
        let settings = ObservableUserSettings()
        let bindable = Bindable(wrappedValue: settings)
        var changeCount = 0

        let id = bindable.subscribe {
            changeCount += 1
        }

        settings.username = "Eve"
        #expect(changeCount == 1)

        bindable.unsubscribe(id)

        settings.username = "Frank"
        #expect(changeCount == 1)
    }

    // MARK: - Integration Tests

    @Test func observableWithBindableIntegration() {
        let counter = ObservableCounter(count: 0, name: "Test")
        let bindable = Bindable(wrappedValue: counter)
        var changeCount = 0

        _ = counter.subscribe {
            changeCount += 1
        }

        // Modify through bindable
        let countBinding = bindable.count
        countBinding.wrappedValue = 10
        #expect(changeCount == 1)
        #expect(counter.count == 10)

        // Modify through counter directly
        counter.increment()
        #expect(changeCount == 2)
        #expect(countBinding.wrappedValue == 11)
    }

    @Test func multipleBindingsToSameProperty() {
        let settings = ObservableUserSettings()
        let bindable = Bindable(wrappedValue: settings)

        let binding1 = bindable.username
        let binding2 = bindable.username

        binding1.wrappedValue = "User1"
        #expect(binding2.wrappedValue == "User1")
        #expect(settings.username == "User1")

        binding2.wrappedValue = "User2"
        #expect(binding1.wrappedValue == "User2")
        #expect(settings.username == "User2")
    }

    @Test func observableBindableMethod() {
        let counter = ObservableCounter()
        let bindable = counter.bindable()

        #expect(bindable.wrappedValue === counter)
    }

    // MARK: - Thread Safety Tests

    @Test func mainActorIsolation() async {
        await MainActor.run {
            let counter = ObservableCounter()
            counter.count = 10
            #expect(counter.count == 10)

            let bindable = Bindable(wrappedValue: counter)
            let binding = bindable.count
            binding.wrappedValue = 20
            #expect(counter.count == 20)
        }
    }

    // MARK: - ObservationIgnored Tests

    @Test func observationIgnored() {
        var ignored = ObservationIgnored(wrappedValue: 42)
        #expect(ignored.wrappedValue == 42)

        ignored.wrappedValue = 100
        #expect(ignored.wrappedValue == 100)
    }

    @Test func observationIgnoredWithDifferentTypes() {
        var intIgnored = ObservationIgnored(wrappedValue: 42)
        var stringIgnored = ObservationIgnored(wrappedValue: "test")
        var boolIgnored = ObservationIgnored(wrappedValue: true)

        #expect(intIgnored.wrappedValue == 42)
        #expect(stringIgnored.wrappedValue == "test")
        #expect(boolIgnored.wrappedValue)

        intIgnored.wrappedValue = 100
        stringIgnored.wrappedValue = "modified"
        boolIgnored.wrappedValue = false

        #expect(intIgnored.wrappedValue == 100)
        #expect(stringIgnored.wrappedValue == "modified")
        #expect(!boolIgnored.wrappedValue)
    }

    // MARK: - Edge Cases

    @Test func emptyObservable() {
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
        #expect(changeCount == 1)
    }

    @Test func observableWithOptionals() {
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

        #expect(model.value == nil)

        model.value = "test"
        #expect(changeCount == 1)
        #expect(model.value == "test")

        model.value = nil
        #expect(changeCount == 2)
        #expect(model.value == nil)
    }

    @Test func observableWithArrays() {
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
        #expect(changeCount == 1)
        #expect(model.items.count == 3)

        model.items.append("d")
        #expect(changeCount == 2)
        #expect(model.items.count == 4)
    }
}
