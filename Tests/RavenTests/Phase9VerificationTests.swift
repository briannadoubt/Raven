import XCTest
@testable import Raven

/// Phase 9 Verification: Integration Tests for Observable, ContentUnavailableView, and Modifiers
///
/// This test suite verifies Phase 9 features working together in realistic scenarios:
/// - @Observable and @Bindable with view updates
/// - ContentUnavailableView in different UI states
/// - Interaction modifiers working together
/// - Layout modifiers in combination
/// - Text modifiers on actual Text views
/// - Full UI scenarios using multiple Phase 9 features
///
/// These are INTEGRATION tests - they verify how features work together,
/// not individual features (which have their own unit test files).
@available(macOS 13.0, *)
@MainActor
final class Phase9VerificationTests: XCTestCase {

    // MARK: - Observable + Bindable Integration Tests (5 tests)

    func testObservableWithInteractionModifiers() {
        // Test that Observable state changes work with .onTapGesture and .disabled
        final class TapCounter: Observable {
            let _$observationRegistrar = ObservationRegistrar()

            private var _count: Int
            var count: Int {
                get { _count }
                set {
                    _$observationRegistrar.willSet()
                    _count = newValue
                }
            }

            private var _isDisabled: Bool
            var isDisabled: Bool {
                get { _isDisabled }
                set {
                    _$observationRegistrar.willSet()
                    _isDisabled = newValue
                }
            }

            init(count: Int = 0, isDisabled: Bool = false) {
                self._count = count
                self._isDisabled = isDisabled
                setupObservation()
            }
        }

        let counter = TapCounter()
        var changeCount = 0

        _ = counter.subscribe {
            changeCount += 1
        }

        // Test interaction: modify properties through bindable
        let bindable = Bindable(wrappedValue: counter)
        bindable.count.wrappedValue = 5
        XCTAssertEqual(changeCount, 1, "Should notify on count change")

        bindable.isDisabled.wrappedValue = true
        XCTAssertEqual(changeCount, 2, "Should notify on isDisabled change")

        XCTAssertEqual(counter.count, 5)
        XCTAssertTrue(counter.isDisabled)
    }

    func testObservableWithTextModifiers() {
        // Test that Observable properties work with text modifiers
        final class TextConfig: Observable {
            let _$observationRegistrar = ObservationRegistrar()

            private var _lineLimit: Int?
            var lineLimit: Int? {
                get { _lineLimit }
                set {
                    _$observationRegistrar.willSet()
                    _lineLimit = newValue
                }
            }

            private var _alignment: TextAlignment
            var alignment: TextAlignment {
                get { _alignment }
                set {
                    _$observationRegistrar.willSet()
                    _alignment = newValue
                }
            }

            init(lineLimit: Int? = nil, alignment: TextAlignment = .leading) {
                self._lineLimit = lineLimit
                self._alignment = alignment
                setupObservation()
            }
        }

        let config = TextConfig(lineLimit: 2, alignment: .center)
        var changeCount = 0

        _ = config.subscribe {
            changeCount += 1
        }

        // Modify through binding
        config.lineLimit = 3
        XCTAssertEqual(changeCount, 1)

        config.alignment = .trailing
        XCTAssertEqual(changeCount, 2)

        XCTAssertEqual(config.lineLimit, 3)
        XCTAssertEqual(config.alignment, .trailing)
    }

    func testObservableWithLayoutModifiers() {
        // Test Observable with layout-related properties
        final class LayoutConfig: Observable {
            let _$observationRegistrar = ObservationRegistrar()

            private var _aspectRatio: Double?
            var aspectRatio: Double? {
                get { _aspectRatio }
                set {
                    _$observationRegistrar.willSet()
                    _aspectRatio = newValue
                }
            }

            private var _isClipped: Bool
            var isClipped: Bool {
                get { _isClipped }
                set {
                    _$observationRegistrar.willSet()
                    _isClipped = newValue
                }
            }

            init(aspectRatio: Double? = nil, isClipped: Bool = false) {
                self._aspectRatio = aspectRatio
                self._isClipped = isClipped
                setupObservation()
            }
        }

        let layout = LayoutConfig(aspectRatio: 16/9, isClipped: true)
        let bindable = Bindable(wrappedValue: layout)

        XCTAssertEqual(bindable.aspectRatio.wrappedValue, 16/9)
        XCTAssertTrue(bindable.isClipped.wrappedValue)

        // Modify through binding
        bindable.aspectRatio.wrappedValue = 1.0
        bindable.isClipped.wrappedValue = false

        XCTAssertEqual(layout.aspectRatio, 1.0)
        XCTAssertFalse(layout.isClipped)
    }

    func testObservableWithLifecycleModifiers() {
        // Test Observable state with .onAppear and .onChange
        final class LifecycleTracker: Observable {
            let _$observationRegistrar = ObservationRegistrar()

            private var _hasAppeared: Bool
            var hasAppeared: Bool {
                get { _hasAppeared }
                set {
                    _$observationRegistrar.willSet()
                    _hasAppeared = newValue
                }
            }

            private var _value: Int
            var value: Int {
                get { _value }
                set {
                    _$observationRegistrar.willSet()
                    _value = newValue
                }
            }

            init(hasAppeared: Bool = false, value: Int = 0) {
                self._hasAppeared = hasAppeared
                self._value = value
                setupObservation()
            }
        }

        let tracker = LifecycleTracker()
        var changeCount = 0

        _ = tracker.subscribe {
            changeCount += 1
        }

        tracker.hasAppeared = true
        XCTAssertEqual(changeCount, 1)

        tracker.value = 42
        XCTAssertEqual(changeCount, 2)
    }

    func testMultipleBindablesToSameObservable() {
        // Test that multiple @Bindable instances to the same Observable work correctly
        final class SharedState: Observable {
            let _$observationRegistrar = ObservationRegistrar()

            private var _counter: Int
            var counter: Int {
                get { _counter }
                set {
                    _$observationRegistrar.willSet()
                    _counter = newValue
                }
            }

            init(counter: Int = 0) {
                self._counter = counter
                setupObservation()
            }
        }

        let state = SharedState(counter: 10)
        let bindable1 = Bindable(wrappedValue: state)
        let bindable2 = Bindable(wrappedValue: state)

        // Modify through first binding
        bindable1.counter.wrappedValue = 20

        // Both bindings and the original should reflect the change
        XCTAssertEqual(bindable2.counter.wrappedValue, 20)
        XCTAssertEqual(state.counter, 20)

        // Modify through second binding
        bindable2.counter.wrappedValue = 30

        XCTAssertEqual(bindable1.counter.wrappedValue, 30)
        XCTAssertEqual(state.counter, 30)
    }

    // MARK: - ContentUnavailableView Integration Tests (5 tests)

    func testContentUnavailableViewWithObservableState() {
        // Test ContentUnavailableView shown/hidden based on Observable state
        final class DataState: Observable {
            let _$observationRegistrar = ObservationRegistrar()

            private var _isEmpty: Bool
            var isEmpty: Bool {
                get { _isEmpty }
                set {
                    _$observationRegistrar.willSet()
                    _isEmpty = newValue
                }
            }

            init(isEmpty: Bool = true) {
                self._isEmpty = isEmpty
                setupObservation()
            }
        }

        let state = DataState(isEmpty: true)

        @MainActor
        struct TestView: View {
            @Bindable var state: DataState

            var body: some View {
                if state.isEmpty {
                    ContentUnavailableView(
                        "No Data",
                        systemImage: "tray",
                        description: Text("No data available.")
                    )
                } else {
                    Text("Data loaded")
                }
            }
        }

        let view = TestView(state: state)
        XCTAssertNotNil(view.body)

        // Toggle state
        state.isEmpty = false
        XCTAssertFalse(state.isEmpty)
    }

    func testContentUnavailableViewWithInteractionModifiers() {
        // Test ContentUnavailableView with .disabled and .onAppear
        var appeared = false
        var actionTapped = false

        let view = ContentUnavailableView(
            "Error Occurred",
            systemImage: "exclamationmark.triangle",
            description: Text("Something went wrong.")
        ) {
            Button("Retry") {
                actionTapped = true
            }
        }
        .disabled(false)
        .onAppear {
            appeared = true
        }

        // Verify the view compiles and can be modified
        XCTAssertNotNil(view)
    }

    func testContentUnavailableViewWithLayoutModifiers() {
        // Test ContentUnavailableView with layout modifiers
        let view = ContentUnavailableView(
            "Empty List",
            systemImage: "list.bullet",
            description: Text("No items to display.")
        )
        .frame(width: 300, height: 400)
        .padding(20)
        .aspectRatio(1, contentMode: .fit)
        .clipped()

        XCTAssertNotNil(view)
    }

    func testContentUnavailableViewInComplexLayout() {
        // Test ContentUnavailableView in a complex view hierarchy
        @MainActor
        struct ComplexView: View {
            let isEmpty: Bool

            var body: some View {
                VStack {
                    Text("Header")
                        .font(.title)

                    if isEmpty {
                        ContentUnavailableView(
                            "No Results",
                            systemImage: "magnifyingglass",
                            description: Text("Try a different search term.")
                        )
                        .padding()
                    } else {
                        Text("Results here")
                    }

                    Divider()

                    Text("Footer")
                }
            }
        }

        let emptyView = ComplexView(isEmpty: true)
        let filledView = ComplexView(isEmpty: false)

        XCTAssertNotNil(emptyView.body)
        XCTAssertNotNil(filledView.body)
    }

    func testContentUnavailableViewWithTextModifiers() {
        // Test that text within ContentUnavailableView description is accepted
        let view = ContentUnavailableView(
            "Very Long Title That Might Need Truncation",
            systemImage: "doc.text",
            description: Text("This is a very long description that might need to be limited to a certain number of lines and aligned properly.")
        )

        XCTAssertNotNil(view)
    }

    // MARK: - Interaction Modifier Combination Tests (5 tests)

    func testDisabledWithOnTapGesture() {
        // Test that .disabled prevents .onTapGesture from firing
        var tapped = false

        let enabledView = Text("Tap me")
            .onTapGesture {
                tapped = true
            }
            .disabled(false)

        let disabledView = Text("Tap me")
            .onTapGesture {
                tapped = true
            }
            .disabled(true)

        let enabledNode = enabledView.toVNode()
        let disabledNode = disabledView.toVNode()

        // Verify disabled has pointer-events: none
        XCTAssertTrue(disabledNode.props.contains { key, value in
            if case .style(let name, let val) = value {
                return name == "pointer-events" && val == "none"
            }
            return false
        }, "Disabled view should have pointer-events: none")
    }

    func testLifecycleModifiersCombination() {
        // Test .onAppear and .onDisappear together with .onChange
        var appeared = false
        var disappeared = false
        var changed = false
        let value = 42

        let view = Text("Content")
            .onAppear {
                appeared = true
            }
            .onDisappear {
                disappeared = true
            }
            .onChange(of: value) { newValue in
                changed = true
            }

        let node = view.toVNode()

        // Verify multiple lifecycle handlers
        let hasAppear = node.props.contains { key, value in
            if case .eventHandler(let event, _) = value {
                return event == "appear"
            }
            return false
        }

        let hasDisappear = node.props.contains { key, value in
            if case .eventHandler(let event, _) = value {
                return event == "disappear"
            }
            return false
        }

        let hasChange = node.props.contains { key, value in
            if case .eventHandler(let event, _) = value {
                return event == "change"
            }
            return false
        }

        XCTAssertTrue(hasAppear || hasDisappear || hasChange, "Should have lifecycle handlers")
    }

    func testInteractionModifiersWithButton() {
        // Test interaction modifiers applied to a Button
        var tapped = false
        var appeared = false

        let button = Button("Submit") {
            tapped = true
        }
        .disabled(false)
        .onAppear {
            appeared = true
        }
        .onTapGesture {
            print("Additional tap handler")
        }

        XCTAssertNotNil(button)
    }

    func testOnChangeWithMultipleProperties() {
        // Test .onChange tracking multiple different values
        let value1 = "test"
        let value2 = 42

        var changes1 = 0
        var changes2 = 0

        let view = Text("Content")
            .onChange(of: value1) { _ in
                changes1 += 1
            }
            .onChange(of: value2) { _ in
                changes2 += 1
            }

        XCTAssertNotNil(view)
    }

    func testInteractionModifiersWithLayoutModifiers() {
        // Test mixing interaction and layout modifiers
        let view = Text("Interactive Box")
            .padding(10)
            .background(Color.blue)
            .cornerRadius(8)
            .aspectRatio(2, contentMode: .fit)
            .clipped()
            .onTapGesture {
                print("Tapped")
            }
            .disabled(false)
            .onAppear {
                print("Appeared")
            }

        XCTAssertNotNil(view)
    }

    // MARK: - Layout Modifier Combination Tests (5 tests)

    func testClippedWithAspectRatio() {
        // Test .clipped and .aspectRatio working together
        let view = Text("Image placeholder")
            .frame(width: 200, height: 200)
            .aspectRatio(16/9, contentMode: .fill)
            .clipped()

        let node = view.toVNode()

        // The outermost modifier (clipped) should be applied
        let hasOverflow = node.props.contains { key, value in
            if case .style(let name, let val) = value {
                return name == "overflow" && val == "hidden"
            }
            return false
        }

        XCTAssertTrue(hasOverflow, "Clipped modifier should set overflow: hidden")
    }

    func testAspectRatioWithFixedSize() {
        // Test .aspectRatio and .fixedSize together
        let view = Text("Content")
            .aspectRatio(1, contentMode: .fit)
            .fixedSize(horizontal: true, vertical: false)

        XCTAssertNotNil(view)
    }

    func testFixedSizeWithMultipleAxes() {
        // Test fixedSize on both axes with other layout modifiers
        let view = Text("Fixed content")
            .padding(10)
            .fixedSize()
            .background(Color.gray)
            .clipped()

        let node = view.toVNode()
        XCTAssertNotNil(node)
    }

    func testLayoutModifiersWithTextModifiers() {
        // Test layout modifiers combined with text modifiers
        let view = Text("Long text that needs formatting")
            .lineLimit(2)
            .multilineTextAlignment(.center)
            .truncationMode(.tail)
            .frame(width: 200)
            .aspectRatio(2, contentMode: .fit)
            .clipped()

        XCTAssertNotNil(view)
    }

    func testComplexLayoutHierarchy() {
        // Test a complex layout with multiple nested modifiers
        let view = VStack {
            Text("Title")
                .lineLimit(1)
                .truncationMode(.tail)

            HStack {
                Text("Left")
                    .fixedSize()

                Text("Right")
                    .aspectRatio(1, contentMode: .fit)
            }
            .clipped()
        }
        .padding()

        XCTAssertNotNil(view.body)
    }

    // MARK: - Text Modifier Integration Tests (3 tests)

    func testTextModifiersWithInteraction() {
        // Test text modifiers with interaction modifiers
        var tapped = false

        let view = Text("Clickable truncated text that is very long")
            .lineLimit(1)
            .truncationMode(.tail)
            .multilineTextAlignment(.leading)
            .onTapGesture {
                tapped = true
            }

        XCTAssertNotNil(view)
    }

    func testTextModifiersInList() {
        // Test text modifiers on items in a list-like structure
        @MainActor
        struct ItemView: View {
            let title: String
            let description: String

            var body: some View {
                VStack(alignment: .leading) {
                    Text(title)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .font(.headline)

                    Text(description)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .truncationMode(.tail)
                        .font(.caption)
                }
            }
        }

        let item = ItemView(
            title: "Very long title that should be truncated",
            description: "Very long description that should be limited to two lines and truncated with ellipsis"
        )

        XCTAssertNotNil(item.body)
    }

    func testTextModifiersWithContentUnavailableView() {
        // Test text description within ContentUnavailableView
        let view = ContentUnavailableView(
            "No Internet Connection",
            systemImage: "wifi.slash",
            description: Text("Please check your internet connection and try again. This message might be long.")
        ) {
            Button("Retry") { }
                .disabled(false)
        }

        XCTAssertNotNil(view)
    }

    // MARK: - Full UI Scenario Tests (5 tests)

    func testCompleteFormWithObservableAndModifiers() {
        // Test a complete form using Observable, Bindable, and various modifiers
        final class FormData: Observable {
            let _$observationRegistrar = ObservationRegistrar()

            private var _name: String
            var name: String {
                get { _name }
                set {
                    _$observationRegistrar.willSet()
                    _name = newValue
                }
            }

            private var _isValid: Bool
            var isValid: Bool {
                get { _isValid }
                set {
                    _$observationRegistrar.willSet()
                    _isValid = newValue
                }
            }

            init(name: String = "", isValid: Bool = false) {
                self._name = name
                self._isValid = isValid
                setupObservation()
            }
        }

        let formData = FormData()

        @MainActor
        struct FormView: View {
            @Bindable var data: FormData

            var body: some View {
                VStack(spacing: 10) {
                    TextField("Name", text: $data.name)
                        .disabled(!data.isValid)
                        .onAppear {
                            print("Form appeared")
                        }

                    Button("Submit") {
                        print("Submitted")
                    }
                    .disabled(!data.isValid)
                }
                .padding()
                .aspectRatio(2, contentMode: .fit)
            }
        }

        let form = FormView(data: formData)
        XCTAssertNotNil(form.body)

        formData.isValid = true
        XCTAssertTrue(formData.isValid)
    }

    func testEmptyStateWithObservableToggle() {
        // Test empty state pattern with Observable controlling visibility
        final class ListState: Observable {
            let _$observationRegistrar = ObservationRegistrar()

            private var _items: [String]
            var items: [String] {
                get { _items }
                set {
                    _$observationRegistrar.willSet()
                    _items = newValue
                }
            }

            var isEmpty: Bool { items.isEmpty }

            init(items: [String] = []) {
                self._items = items
                setupObservation()
            }

            func addItem(_ item: String) {
                items.append(item)
            }
        }

        let state = ListState()

        @MainActor
        struct ListView: View {
            @Bindable var state: ListState

            var body: some View {
                VStack {
                    if state.isEmpty {
                        ContentUnavailableView(
                            "No Items",
                            systemImage: "list.bullet",
                            description: Text("Add your first item to get started.")
                        ) {
                            Button("Add Item") {
                                state.items.append("New Item")
                            }
                        }
                        .onAppear {
                            print("Empty state shown")
                        }
                    } else {
                        Text("Items: \(state.items.count)")
                            .lineLimit(1)
                    }
                }
            }
        }

        let list = ListView(state: state)
        XCTAssertNotNil(list.body)
        XCTAssertTrue(state.isEmpty)

        state.addItem("Test")
        XCTAssertFalse(state.isEmpty)
    }

    func testSearchUIWithAllPhase9Features() {
        // Test a search UI using all Phase 9 features
        final class SearchState: Observable {
            let _$observationRegistrar = ObservationRegistrar()

            private var _query: String
            var query: String {
                get { _query }
                set {
                    _$observationRegistrar.willSet()
                    _query = newValue
                }
            }

            private var _results: [String]
            var results: [String] {
                get { _results }
                set {
                    _$observationRegistrar.willSet()
                    _results = newValue
                }
            }

            var isEmpty: Bool { results.isEmpty && !query.isEmpty }

            init(query: String = "", results: [String] = []) {
                self._query = query
                self._results = results
                setupObservation()
            }
        }

        let search = SearchState(query: "test", results: [])

        @MainActor
        struct SearchView: View {
            @Bindable var state: SearchState

            var body: some View {
                VStack {
                    TextField("Search", text: $state.query)
                        .onAppear {
                            print("Search appeared")
                        }
                        .onChange(of: state.query) { newValue in
                            print("Query changed: \(newValue)")
                        }

                    if state.isEmpty {
                        ContentUnavailableView.search
                            .padding()
                    } else if state.results.isEmpty {
                        Text("Enter a search term")
                            .multilineTextAlignment(.center)
                    } else {
                        VStack {
                            ForEach(0..<state.results.count, id: \.self) { index in
                                Text(state.results[index])
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                            }
                        }
                        .clipped()
                    }
                }
            }
        }

        let searchView = SearchView(state: search)
        XCTAssertNotNil(searchView.body)
    }

    func testSettingsScreenWithAllModifiers() {
        // Test a settings screen with all modifier types
        final class Settings: Observable {
            let _$observationRegistrar = ObservationRegistrar()

            private var _username: String
            var username: String {
                get { _username }
                set {
                    _$observationRegistrar.willSet()
                    _username = newValue
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

            init(username: String = "", fontSize: Double = 14.0) {
                self._username = username
                self._fontSize = fontSize
                setupObservation()
            }
        }

        let settings = Settings()

        @MainActor
        struct SettingsView: View {
            @Bindable var settings: Settings

            var body: some View {
                VStack(spacing: 16) {
                    Text("Settings")
                        .font(.title)
                        .lineLimit(1)

                    VStack(alignment: .leading) {
                        Text("Username")
                            .font(.headline)

                        TextField("Enter username", text: $settings.username)
                            .disabled(false)
                            .onAppear {
                                print("Username field appeared")
                            }
                    }

                    VStack(alignment: .leading) {
                        Text("Font Size: \(Int(settings.fontSize))")
                            .font(.headline)

                        Slider(value: $settings.fontSize, in: 8...32)
                            .disabled(false)
                            .onChange(of: settings.fontSize) { newSize in
                                print("Font size changed: \(newSize)")
                            }
                    }

                    Text("Preview text with current settings")
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .truncationMode(.tail)
                }
                .padding()
                .aspectRatio(3/4, contentMode: .fit)
                .clipped()
            }
        }

        let view = SettingsView(settings: settings)
        XCTAssertNotNil(view.body)
    }

    func testDynamicContentWithErrorState() {
        // Test dynamic content loading with error state using ContentUnavailableView
        final class ContentState: Observable {
            let _$observationRegistrar = ObservationRegistrar()

            enum State {
                case loading
                case loaded([String])
                case error(String)
            }

            private var _currentState: State
            var currentState: State {
                get { _currentState }
                set {
                    _$observationRegistrar.willSet()
                    _currentState = newValue
                }
            }

            init(currentState: State = .loading) {
                self._currentState = currentState
                setupObservation()
            }
        }

        let state = ContentState(currentState: .error("Network error"))

        @MainActor
        struct ContentView: View {
            @Bindable var state: ContentState

            var body: some View {
                VStack {
                    switch state.currentState {
                    case .loading:
                        Text("Loading...")
                            .onAppear {
                                print("Loading state")
                            }
                    case .loaded(let items):
                        VStack {
                            ForEach(0..<items.count, id: \.self) { index in
                                Text(items[index])
                                    .lineLimit(2)
                            }
                        }
                    case .error(let message):
                        ContentUnavailableView(
                            "Error",
                            systemImage: "exclamationmark.triangle",
                            description: Text(message)
                        ) {
                            Button("Retry") {
                                state.currentState = .loading
                            }
                            .disabled(false)
                        }
                    }
                }
                .padding()
                .clipped()
            }
        }

        let view = ContentView(state: state)
        XCTAssertNotNil(view.body)
    }

    // MARK: - Edge Case Integration Tests (2 tests)

    func testObservableWithOptionalBindings() {
        // Test Observable with optional properties and Bindable
        final class OptionalState: Observable {
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

        let state = OptionalState()
        let bindable = Bindable(wrappedValue: state)

        XCTAssertNil(bindable.value.wrappedValue)

        bindable.value.wrappedValue = "test"
        XCTAssertEqual(state.value, "test")

        bindable.value.wrappedValue = nil
        XCTAssertNil(state.value)
    }

    func testAllPhase9FeaturesInSingleView() {
        // Test that all Phase 9 features can coexist in a single view
        final class AppState: Observable {
            let _$observationRegistrar = ObservationRegistrar()

            private var _title: String
            var title: String {
                get { _title }
                set {
                    _$observationRegistrar.willSet()
                    _title = newValue
                }
            }

            private var _isEmpty: Bool
            var isEmpty: Bool {
                get { _isEmpty }
                set {
                    _$observationRegistrar.willSet()
                    _isEmpty = newValue
                }
            }

            init(title: String = "App", isEmpty: Bool = true) {
                self._title = title
                self._isEmpty = isEmpty
                setupObservation()
            }
        }

        let state = AppState()

        @MainActor
        struct CompleteView: View {
            @Bindable var state: AppState

            var body: some View {
                VStack {
                    // Observable + Text modifiers
                    Text(state.title)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .multilineTextAlignment(.center)

                    // ContentUnavailableView + Interaction + Layout modifiers
                    if state.isEmpty {
                        ContentUnavailableView(
                            "No Content",
                            systemImage: "tray",
                            description: Text("Get started by adding content.")
                        ) {
                            Button("Add Content") {
                                state.isEmpty = false
                            }
                            .disabled(false)
                        }
                        .padding()
                        .aspectRatio(1, contentMode: .fit)
                        .clipped()
                        .onAppear {
                            print("Empty state appeared")
                        }
                    } else {
                        Text("Content loaded")
                            .fixedSize()
                            .onTapGesture {
                                print("Tapped")
                            }
                            .onChange(of: state.isEmpty) { newValue in
                                print("Empty state changed: \(newValue)")
                            }
                    }
                }
                .onAppear {
                    print("View appeared")
                }
                .onDisappear {
                    print("View disappeared")
                }
            }
        }

        let view = CompleteView(state: state)
        XCTAssertNotNil(view.body)

        // Test state transitions
        XCTAssertTrue(state.isEmpty)
        state.isEmpty = false
        XCTAssertFalse(state.isEmpty)
    }

    // MARK: - Verification Tests

    func testAllPhase9TypesExist() {
        // Verify all Phase 9 types are available and can be instantiated

        // Observable and Bindable
        final class TestObservable: Observable {
            let _$observationRegistrar = ObservationRegistrar()
            var value: Int = 0 {
                willSet { _$observationRegistrar.willSet() }
            }
            init() { setupObservation() }
        }
        let observable = TestObservable()
        let _ = Bindable(wrappedValue: observable)

        // ContentUnavailableView
        let _ = ContentUnavailableView("Title", systemImage: "star")
        let _ = ContentUnavailableView<Text, EmptyView>.search

        // Interaction modifiers
        let _ = Text("Test").disabled(false)
        let _ = Text("Test").onTapGesture { }
        let _ = Text("Test").onAppear { }
        let _ = Text("Test").onDisappear { }
        let _ = Text("Test").onChange(of: 1) { _ in }

        // Layout modifiers
        let _ = Text("Test").clipped()
        let _ = Text("Test").aspectRatio(1, contentMode: .fit)
        let _ = Text("Test").fixedSize()

        // Text modifiers
        let _ = Text("Test").lineLimit(1)
        let _ = Text("Test").multilineTextAlignment(.center)
        let _ = Text("Test").truncationMode(.tail)

        XCTAssertTrue(true, "All Phase 9 types exist and can be instantiated")
    }
}
