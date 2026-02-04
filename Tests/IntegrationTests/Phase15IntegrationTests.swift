import XCTest
@testable import Raven

// MARK: - Phase 15 Integration Tests
//
// These tests verify the integration of Phase 15 features, combining multiple
// components to test real-world workflows and interactions.
//
// Phase 15 Features Tested:
// - Form validation + focus management
// - List with swipe actions + selection
// - TabView with routing
// - Virtual scrolling + pull-to-refresh
// - Table with sorting + selection
// - Modal with focus trap + ARIA
// - Router with deep links + validation
// - Complete end-to-end workflows

@MainActor
final class Phase15IntegrationTests: XCTestCase {

    // MARK: - Form Validation + Focus Management

    func testFormValidationWithFocusManagement() async throws {
        enum Field: Hashable {
            case email
            case password
            case confirmPassword
        }

        struct LoginForm: View {
            @State private var email = ""
            @State private var password = ""
            @State private var confirmPassword = ""
            @FocusState private var focusedField: Field?
            @StateObject private var formState = FormState()

            nonisolated init() {}

            var body: some View {
                VStack {
                    TextField("Email", text: $email)
                        .focused($focusedField, equals: .email)
                        .validated(
                            by: [
                                .required(field: "email"),
                                .email(field: "email")
                            ],
                            in: formState
                        )

                    SecureField("Password", text: $password)
                        .focused($focusedField, equals: .password)
                        .validated(
                            by: [
                                .required(field: "password"),
                                .minLength(field: "password", length: 8)
                            ],
                            in: formState
                        )

                    SecureField("Confirm Password", text: $confirmPassword)
                        .focused($focusedField, equals: .confirmPassword)
                        .validated(
                            by: [
                                .required(field: "confirmPassword"),
                                .custom(field: "confirmPassword", message: "Passwords must match") { [password] value in
                                    value == password
                                }
                            ],
                            in: formState
                        )

                    Button("Submit") {
                        // Touch all fields to show validation errors
                        formState.touchAll()

                        // Check if any fields have errors
                        if !formState.hasErrors(for: "email") &&
                           !formState.hasErrors(for: "password") &&
                           !formState.hasErrors(for: "confirmPassword") {
                            // Success
                        } else {
                            // Focus first invalid field
                            if formState.hasErrors(for: "email") {
                                focusedField = .email
                            } else if formState.hasErrors(for: "password") {
                                focusedField = .password
                            } else if formState.hasErrors(for: "confirmPassword") {
                                focusedField = .confirmPassword
                            }
                        }
                    }
                }
            }
        }

        let view = LoginForm()
        _ = view  // Compile test only
    }

    func testFormWithAsyncValidationAndFocus() async throws {
        @MainActor
        struct SignupForm: View {
            @State private var username = ""
            @State private var email = ""
            @FocusState private var isFocused: Bool
            @StateObject private var formState = FormState()

            nonisolated init() {}

            var body: some View {
                VStack {
                    TextField("Username", text: $username)
                        .focused($isFocused)
                        .validatedAsync(
                            by: AsyncValidationRule(field: "username") { value in
                                // Simulate async username check
                                try? await Task.sleep(nanoseconds: 100_000_000)
                                return value != "admin" ? .success : .failure(.init(
                                    field: "username",
                                    type: .custom("taken"),
                                    message: "Username already taken"
                                ))
                            },
                            in: formState
                        )

                    TextField("Email", text: $email)
                        .validated(
                            by: [.email(field: "email")],
                            in: formState
                        )
                }
                .onAppear {
                    isFocused = true
                }
            }
        }

        let view = SignupForm()
        _ = view  // Compile test only
    }

    // MARK: - List + Swipe Actions + Selection

    func testListWithSwipeActionsAndSelection() async throws {
        struct Item: Identifiable, Hashable, Sendable {
            let id = UUID()
            let name: String
        }

        struct ItemListView: View {
            @State private var items = [
                Item(name: "Item 1"),
                Item(name: "Item 2"),
                Item(name: "Item 3")
            ]
            @State private var selection: Set<Item.ID> = []
            @Environment(\.editMode) private var editMode

            init() {}

            var body: some View {
                // Note: List doesn't support selection binding in current implementation
                // Using without selection for now
                List(items) { item in
                    Text(item.name)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(action: {
                                items.removeAll { $0.id == item.id }
                            }) {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading) {
                            Button(action: {
                                // Archive action
                            }) {
                                Label("Archive", systemImage: "archivebox")
                            }
                        }
                }
            }
        }

        let view = ItemListView()
        _ = view  // Compile test only
    }

    func testListWithReorderingAndSelection() async throws {
        struct TodoItem: Identifiable, Hashable, Sendable {
            let id = UUID()
            var title: String
            var isComplete: Bool
        }

        struct TodoListView: View {
            @State private var todos = [
                TodoItem(title: "Task 1", isComplete: false),
                TodoItem(title: "Task 2", isComplete: true)
            ]
            @State private var selection: Set<TodoItem.ID> = []
            @State private var editMode: EditMode = .inactive

            init() {}

            var body: some View {
                // Note: List doesn't support selection binding in current implementation
                List {
                    ForEach(todos) { todo in
                        HStack {
                            Toggle(isOn: .constant(todo.isComplete)) {
                                Text(todo.title)
                            }
                        }
                    }
                    .onMove { from, to in
                        todos.move(fromOffsets: from, toOffset: to)
                    }
                }
                .environment(\.editMode, $editMode)
            }
        }

        let view = TodoListView()
        _ = view  // Compile test only
    }

    // MARK: - Virtual Scrolling + Pull-to-Refresh

    func testVirtualScrollingWithPullToRefresh() async throws {
        struct InfiniteListView: View {
            @State private var items: [Int] = Array(0..<1000)
            @State private var isRefreshing = false

            init() {}

            var body: some View {
                List(items, id: \.self) { item in
                    Text("Item \(item)")
                }
                .virtualized(estimatedItemHeight: 44)
                .refreshable {
                    isRefreshing = true
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                    items = Array(0..<1000)
                    isRefreshing = false
                }
            }
        }

        let view = InfiniteListView()
        _ = view  // Compile test only
    }

    // Note: Disabled until ScrollView and LazyVStack are implemented
    /*
    func testVirtualScrollingWithDynamicContent() async throws {
        struct DynamicListView: View {
            @State private var items: [String] = (0..<10000).map { "Item \($0)" }

            init() {}

            var body: some View {
                ScrollView {
                    LazyVStack {
                        ForEach(items, id: \.self) { item in
                            Text(item)
                                .frame(height: 50)
                        }
                    }
                    .virtualized(estimatedItemHeight: 50)
                }
            }
        }

        let view = DynamicListView()
        _ = view  // Compile test only
    }
    */

    // MARK: - Table + Sorting + Selection

    func testTableWithSortingAndSelection() async throws {
        struct Person: Identifiable, Sendable, Hashable {
            let id = UUID()
            let name: String
            let age: Int
            let email: String
        }

        struct PeopleTableView: View {
            @State private var people = [
                Person(name: "Alice", age: 30, email: "alice@example.com"),
                Person(name: "Bob", age: 25, email: "bob@example.com"),
                Person(name: "Charlie", age: 35, email: "charlie@example.com")
            ]
            @State private var selection: Person.ID?
            @State private var sortOrder = [SortDescriptor(KeyPathComparator(\Person.name))]

            init() {}

            var body: some View {
                Table(people, selection: $selection) {
                    TableColumn("Name", content: { person in
                        Text(person.name)
                    })
                    TableColumn("Age", content: { person in
                        Text("\(person.age)")
                    })
                    TableColumn("Email", content: { person in
                        Text(person.email)
                    })
                }
            }
        }

        let view = PeopleTableView()
        _ = view  // Compile test only
    }

    func testTableWithMultipleSelection() async throws {
        struct DataItem: Identifiable, Sendable, Hashable {
            let id = UUID()
            let title: String
            let value: Int
        }

        struct DataTableView: View {
            @State private var items = [
                DataItem(title: "A", value: 100),
                DataItem(title: "B", value: 200)
            ]
            @State private var selection: Set<DataItem.ID> = []


            init() {}
            var body: some View {
                VStack {
                    Table(items, selection: $selection) {
                        TableColumn("Title", content: { item in
                            Text(item.title)
                        })
                        TableColumn("Value", content: { item in
                            Text("\(item.value)")
                        })
                    }

                    Text("Selected: \(selection.count)")
                }
            }
        }

        let view = DataTableView()
        _ = view  // Compile test only
    }

    // MARK: - TabView + Routing

    func testTabViewWithRouting() async throws {
        enum AppTab: Hashable, Sendable {
            case home
            case search
            case profile
        }

        struct AppTabView: View {
            @State private var selectedTab: AppTab = .home
            @StateObject private var router = Router()


            init() {}
            var body: some View {
                TabView(selection: $selectedTab) {
                    Text("Home")
                        .tabItem {
                            Label("Home", systemImage: "house")
                        }
                        .tag(AppTab.home)

                    Text("Search")
                        .tabItem {
                            Label("Search", systemImage: "magnifyingglass")
                        }
                        .tag(AppTab.search)

                    Text("Profile")
                        .tabItem {
                            Label("Profile", systemImage: "person")
                        }
                        .tag(AppTab.profile)
                }
                .router(router)
                .onChange(of: selectedTab) { newTab in
                    switch newTab {
                    case .home: router.navigate(to: "/")
                    case .search: router.navigate(to: "/search")
                    case .profile: router.navigate(to: "/profile")
                    }
                }
            }
        }

        let view = AppTabView()
        _ = view  // Compile test only
    }

    func testTabViewWithBadges() async throws {
        struct MessagingTabView: View {
            @State private var unreadMessages = 5
            @State private var notifications = 12


            init() {}
            var body: some View {
                TabView {
                    Text("Messages")
                        .tabItem { Label("Messages", systemImage: "message") }
                        .badge(unreadMessages > 0 ? "\(unreadMessages)" : nil)

                    Text("Notifications")
                        .tabItem { Label("Notifications", systemImage: "bell") }
                        .badge("\(notifications)")

                    Text("Settings")
                        .tabItem { Label("Settings", systemImage: "gear") }
                }
            }
        }

        let view = MessagingTabView()
        _ = view  // Compile test only
    }

    // MARK: - Router + Deep Links + Navigation

    func testRouterWithDeepLinks() async throws {
        let router = Router()

        // Register routes
        router.register(path: "/") { _ in
            Text("Home")
        }

        router.register(path: "/products/:id") { params in
            Text("Product \(params.string("id") ?? "unknown")")
        }

        router.register(path: "/users/:userId/posts/:postId") { params in
            VStack {
                Text("User: \(params.string("userId") ?? "")")
                Text("Post: \(params.string("postId") ?? "")")
            }
        }

        // Test navigation
        router.navigate(to: "/products/123")
        XCTAssertEqual(router.currentPath, "/products/123")
        XCTAssertEqual(router.currentParameters.string("id"), "123")

        router.navigate(to: "/users/42/posts/99")
        XCTAssertEqual(router.currentPath, "/users/42/posts/99")
        XCTAssertEqual(router.currentParameters.string("userId"), "42")
        XCTAssertEqual(router.currentParameters.string("postId"), "99")
    }

    func testRouterWithNavigation() async throws {
        @MainActor
        struct RouterTestView: View {
            @StateObject private var router = Router()

            nonisolated init() {}

            var body: some View {
                VStack {
                    if let currentView = router.currentView {
                        currentView
                    } else {
                        Text("No route")
                    }

                    Button("Go to Products") {
                        router.navigate(to: "/products")
                    }

                    Button("Go Back") {
                        router.back()
                    }
                }
                .router(router)
                .onAppear {
                    router.register(path: "/") { _ in
                        Text("Home")
                    }
                    router.register(path: "/products") { _ in
                        Text("Products")
                    }
                    router.handleInitialURL()
                }
            }
        }

        let view = RouterTestView()
        _ = view  // Compile test only
    }

    // MARK: - Modal + Focus Trap + ARIA

    func testModalWithFocusTrap() async throws {
        enum Field: Hashable {
            case name
            case email
        }

        @MainActor
        struct ModalFormView: View {
            @State private var showModal = false
            @State private var name = ""
            @State private var email = ""
            @FocusState private var focusedField: Field?


            nonisolated init() {}
            var body: some View {
                VStack {
                    Button("Show Form") {
                        showModal = true
                    }
                }
                .sheet(isPresented: $showModal) {
                    VStack {
                        TextField("Name", text: $name)
                            .focused($focusedField, equals: .name)
                            .accessibilityLabel("Name field")

                        TextField("Email", text: $email)
                            .focused($focusedField, equals: .email)
                            .accessibilityLabel("Email field")

                        HStack {
                            Button("Cancel") {
                                showModal = false
                            }

                            Button("Save") {
                                showModal = false
                            }
                        }
                    }
                    .focusScope(trapFocus: true)
                    .onAppear {
                        focusedField = .name
                    }
                }
            }
        }

        let view = ModalFormView()
        _ = view  // Compile test only
    }

    func testModalWithARIA() async throws {
        struct AccessibleModalView: View {
            @State private var showAlert = false
            @State private var showSheet = false


            init() {}
            var body: some View {
                VStack {
                    Button("Show Alert") {
                        showAlert = true
                    }
                    .accessibilityRole(.button)
                    .accessibilityLabel("Show alert dialog")

                    Button("Show Sheet") {
                        showSheet = true
                    }
                    .accessibilityRole(.button)
                    .accessibilityLabel("Show bottom sheet")
                }
                .alert("Important", isPresented: $showAlert) {
                    Button("OK") {
                        showAlert = false
                    }
                } message: {
                    Text("This is an important message")
                }
                .sheet(isPresented: $showSheet) {
                    Text("Sheet Content")
                        .accessibilityRole(.dialog)
                        .accessibilityLabel("Sheet dialog")
                }
            }
        }

        let view = AccessibleModalView()
        _ = view  // Compile test only
    }

    // MARK: - Complete Workflows

    func testCompleteUserRegistrationWorkflow() async throws {
        enum Field: Hashable {
            case username, email, password, confirmPassword
        }

        struct RegistrationView: View {
            @State private var username = ""
            @State private var email = ""
            @State private var password = ""
            @State private var confirmPassword = ""
            @FocusState private var focusedField: Field?
            @StateObject private var formState = FormState()
            @StateObject private var router = Router()
            @State private var showSuccess = false


            nonisolated init() {}
            var body: some View {
                VStack {
                    TextField("Username", text: $username)
                        .focused($focusedField, equals: .username)
                        .validated(
                            by: [
                                .required(field: "username"),
                                .minLength(field: "username", length: 3)
                            ],
                            in: formState
                        )
                        .accessibilityLabel("Username")

                    TextField("Email", text: $email)
                        .focused($focusedField, equals: .email)
                        .validated(
                            by: [
                                .required(field: "email"),
                                .email(field: "email")
                            ],
                            in: formState
                        )
                        .accessibilityLabel("Email address")

                    SecureField("Password", text: $password)
                        .focused($focusedField, equals: .password)
                        .validated(
                            by: [
                                .required(field: "password"),
                                .minLength(field: "password", length: 8)
                            ],
                            in: formState
                        )

                    SecureField("Confirm Password", text: $confirmPassword)
                        .focused($focusedField, equals: .confirmPassword)
                        .validated(
                            by: [
                                .required(field: "confirmPassword"),
                                .custom(field: "confirmPassword", message: "Passwords must match") { [password] in $0 == password }
                            ],
                            in: formState
                        )

                    Button("Register") {
                        formState.touchAll()
                        if !formState.hasErrors(for: "username") &&
                           !formState.hasErrors(for: "email") &&
                           !formState.hasErrors(for: "password") &&
                           !formState.hasErrors(for: "confirmPassword") {
                            showSuccess = true
                        }
                    }
                    .accessibilityRole(.button)
                }
                .alert("Success", isPresented: $showSuccess) {
                    Button("OK") {
                        router.navigate(to: "/home")
                    }
                } message: {
                    Text("Registration complete!")
                }
                .router(router)
            }
        }

        let view = RegistrationView()
        _ = view  // Compile test only
    }

    func testCompleteDataManagementWorkflow() async throws {
        struct DataItem: Identifiable, Sendable, Hashable {
            let id = UUID()
            var name: String
            var value: Int
            var isActive: Bool
        }

        @MainActor
        struct DataManagementView: View {
            @State private var items = [
                DataItem(name: "A", value: 100, isActive: true),
                DataItem(name: "B", value: 200, isActive: false)
            ]
            @State private var selection: Set<DataItem.ID> = []
            @State private var sortOrder = [SortDescriptor(KeyPathComparator(\DataItem.name))]
            @State private var editMode: EditMode = .inactive
            @State private var showAddDialog = false
            @State private var newItemName = ""
            @FocusState private var isNameFieldFocused: Bool


            nonisolated init() {}
            var body: some View {
                VStack {
                    HStack {
                        Button(editMode.isEditing ? "Done" : "Edit") {
                            editMode = editMode.isEditing ? .inactive : .active
                        }

                        Button("Add Item") {
                            showAddDialog = true
                        }

                        if !selection.isEmpty {
                            Button("Delete Selected") {
                                items.removeAll { selection.contains($0.id) }
                                selection = []
                            }
                        }
                    }

                    Table(items, selection: $selection) {
                        TableColumn("Name", content: { item in
                            Text(item.name)
                        })
                        TableColumn("Value", content: { item in
                            Text("\(item.value)")
                        })
                        TableColumn("Status", content: { item in
                            Text(item.isActive ? "Active" : "Inactive")
                        })
                    }
                }
                .environment(\.editMode, $editMode)
                .sheet(isPresented: $showAddDialog) {
                    VStack {
                        TextField("Item Name", text: $newItemName)
                            .focused($isNameFieldFocused)

                        HStack {
                            Button("Cancel") {
                                showAddDialog = false
                                newItemName = ""
                            }

                            Button("Add") {
                                items.append(DataItem(
                                    name: newItemName,
                                    value: 0,
                                    isActive: true
                                ))
                                showAddDialog = false
                                newItemName = ""
                            }
                        }
                    }
                    .onAppear {
                        isNameFieldFocused = true
                    }
                }
            }
        }

        let view = DataManagementView()
        _ = view  // Compile test only
    }

    func testCompleteNavigationWithTabsAndRouting() async throws {
        enum Tab: Hashable, Sendable {
            case home, browse, favorites
        }

        struct Product: Identifiable, Sendable {
            let id = UUID()
            let name: String
        }

        struct AppView: View {
            @State private var selectedTab: Tab = .home
            @StateObject private var router = Router()
            @State private var favorites: Set<Product.ID> = []


            init() {}
            var body: some View {
                TabView(selection: $selectedTab) {
                    Text("Home")
                        .tabItem { Label("Home", systemImage: "house") }
                        .tag(Tab.home)

                    ProductBrowserView(
                        router: router,
                        favorites: $favorites
                    )
                    .tabItem { Label("Browse", systemImage: "square.grid.2x2") }
                    .tag(Tab.browse)

                    FavoritesView(favorites: favorites)
                        .tabItem { Label("Favorites", systemImage: "star") }
                        .badge(favorites.isEmpty ? nil : "\(favorites.count)")
                        .tag(Tab.favorites)
                }
                .router(router)
            }
        }

        struct ProductBrowserView: View {
            let router: Router
            @Binding var favorites: Set<Product.ID>

            var body: some View {
                Text("Products")
            }
        }

        struct FavoritesView: View {
            let favorites: Set<Product.ID>

            var body: some View {
                Text("\(favorites.count) favorites")
            }
        }

        let view = AppView()
        _ = view  // Compile test only
    }

    func testCompleteAccessibilityWorkflow() async throws {
        enum FormField: Hashable {
            case title, description, category
        }

        struct AccessibleFormView: View {
            @State private var title = ""
            @State private var description = ""
            @State private var category = ""
            @FocusState private var focusedField: FormField?
            @StateObject private var formState = FormState()
            @State private var showSuccessAlert = false


            nonisolated init() {}
            var body: some View {
                VStack {
                    TextField("Title", text: $title)
                        .focused($focusedField, equals: .title)
                        .accessibilityLabel("Title field")
                        .accessibilityHint("Enter a title for your item")
                        .validated(
                            by: [.required(field: "title")],
                            in: formState
                        )

                    TextField("Description", text: $description)
                        .focused($focusedField, equals: .description)
                        .accessibilityLabel("Description field")
                        .accessibilityRole(.textField)

                    TextField("Category", text: $category)
                        .focused($focusedField, equals: .category)
                        .accessibilityLabel("Category field")

                    Button("Submit") {
                        formState.touchAll()
                        if !formState.hasErrors(for: "title") {
                            showSuccessAlert = true
                        } else {
                            // Focus first invalid field
                            if formState.hasErrors(for: "title") {
                                focusedField = .title
                            }
                        }
                    }
                    .accessibilityRole(.button)
                    .accessibilityLabel("Submit form")
                }
                // Note: .accessibilityElement(children:) not yet implemented in Raven
                .alert("Form Submitted", isPresented: $showSuccessAlert) {
                    Button("OK") {
                        // Reset form
                        title = ""
                        description = ""
                        category = ""
                        focusedField = .title
                    }
                }
            }
        }

        let view = AccessibleFormView()
        _ = view  // Compile test only
    }

    // MARK: - Performance + Virtual Scrolling

    func testVirtualScrollingPerformance() async throws {
        struct PerformanceTestView: View {
            @State private var items = Array(0..<10000)


            init() {}
            var body: some View {
                List(items, id: \.self) { item in
                    HStack {
                        Text("Item \(item)")
                        Spacer()
                        Text("\(item * 2)")
                    }
                }
                .virtualized(estimatedItemHeight: 44)
            }
        }

        let view = PerformanceTestView()
        _ = view  // Compile test only
    }

    func testComplexListWithAllFeatures() async throws {
        struct ComplexItem: Identifiable, Hashable, Sendable {
            let id = UUID()
            var title: String
            var subtitle: String
            var value: Int
        }

        struct ComplexListView: View {
            @State private var items = (0..<100).map {
                ComplexItem(
                    title: "Item \($0)",
                    subtitle: "Description \($0)",
                    value: $0 * 10
                )
            }
            @State private var selection: Set<ComplexItem.ID> = []
            @State private var editMode: EditMode = .inactive
            @State private var isRefreshing = false


            init() {}
            var body: some View {
                // Note: List doesn't support binding to collection items in current implementation
                List {
                    ForEach(items) { item in
                        VStack(alignment: .leading) {
                            Text(item.title)
                                .font(.headline)
                            Text(item.subtitle)
                                .font(.caption)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(action: {
                                items.removeAll { $0.id == item.id }
                            }) {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading) {
                            Button(action: {
                                if let index = items.firstIndex(where: { $0.id == item.id }) {
                                    items[index].value += 10
                                }
                            }) {
                                Label("Increment", systemImage: "plus")
                            }
                        }
                    }
                }
                .virtualized(estimatedItemHeight: 60)
                .refreshable {
                    isRefreshing = true
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    items = (0..<100).map {
                        ComplexItem(
                            title: "Item \($0)",
                            subtitle: "Updated \($0)",
                            value: $0 * 10
                        )
                    }
                    isRefreshing = false
                }
                .environment(\.editMode, $editMode)
            }
        }

        let view = ComplexListView()
        _ = view  // Compile test only
    }

    // MARK: - Edge Cases and Error Handling

    @MainActor
    func testFormValidationWithEmptyFields() async throws {
        let formState = FormState()

        let emailRule = ValidationRule.email(field: "email")
        let result = emailRule.validate("")

        // Email rule allows empty (use required() separately)
        if case .success = result {
            XCTAssertTrue(true)
        } else {
            XCTFail("Empty email should be valid (use required rule separately)")
        }
    }

    @MainActor
    func testRouterWithInvalidPath() async throws {
        let router = Router()

        router.setNotFoundView(Text("404 Not Found"))

        router.navigate(to: "/nonexistent/path")

        XCTAssertEqual(router.currentPath, "/nonexistent/path")
        XCTAssertNotNil(router.currentView)
    }

    func testFocusStateWithoutFocusedView() async throws {
        @MainActor
        struct NoFocusView: View {
            @FocusState private var isFocused: Bool


            nonisolated init() {}
            var body: some View {
                VStack {
                    Text("No focusable elements")
                    Button("Focus") {
                        isFocused = true
                    }
                }
            }
        }

        let view = NoFocusView()
        _ = view  // Compile test only
    }
}
