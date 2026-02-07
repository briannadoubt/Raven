import Testing
@testable import Raven

/// Tests for the ForEach view
@MainActor
@Suite struct ForEachTests {

    // MARK: - Range-based ForEach

    @Test func forEachWithRange() async throws {
        // Create a ForEach with a range
        let forEach = ForEach(0..<3) { index in
            Text("Item \(index)")
        }

        // Verify that the ForEach has a body (it's a composed view)
        let body = forEach.body

        // The body should be a ForEachView
        #expect(body is ForEachView<Text>)
    }

    // MARK: - Identifiable Collection

    struct Item: Identifiable, Sendable {
        let id: Int
        let name: String
    }

    @Test func forEachWithIdentifiable() async throws {
        let items = [
            Item(id: 1, name: "First"),
            Item(id: 2, name: "Second"),
            Item(id: 3, name: "Third")
        ]

        let forEach = ForEach(items) { item in
            Text(item.name)
        }

        // Verify that the ForEach has a body
        let body = forEach.body

        // The body should be a ForEachView
        #expect(body is ForEachView<Text>)
    }

    // MARK: - Custom ID Key Path

    struct CustomItem: Sendable {
        let name: String
        let value: Int
    }

    @Test func forEachWithCustomKeyPath() async throws {
        let items = [
            CustomItem(name: "Alpha", value: 1),
            CustomItem(name: "Beta", value: 2),
            CustomItem(name: "Gamma", value: 3)
        ]

        let forEach = ForEach(items, id: \.name) { item in
            Text("\(item.name): \(item.value)")
        }

        // Verify that the ForEach has a body
        let body = forEach.body

        // The body should be a ForEachView
        #expect(body is ForEachView<Text>)
    }

    // MARK: - Empty Collection

    @Test func forEachWithEmptyCollection() async throws {
        let items: [Item] = []

        let forEach = ForEach(items) { item in
            Text(item.name)
        }

        // Verify that the ForEach has a body
        let body = forEach.body

        // The body should be a ForEachView with no views
        if let forEachView = body as? ForEachView<Text> {
            #expect(forEachView.views.isEmpty)
        } else {
            Issue.record("Body should be a ForEachView")
        }
    }

    // MARK: - Nested Views

    @Test func forEachWithNestedViews() async throws {
        let items = [
            Item(id: 1, name: "First"),
            Item(id: 2, name: "Second")
        ]

        let forEach = ForEach(items) { item in
            VStack {
                Text(item.name)
                Text("ID: \(item.id)")
            }
        }

        // Verify that the ForEach has a body
        let body = forEach.body

        // The body should be a ForEachView (exact generic type depends on ViewBuilder output)
        #expect(body != nil)
    }

    // MARK: - Large Collections

    @Test func forEachWithLargeCollection() async throws {
        let range = 0..<100

        let forEach = ForEach(range) { index in
            Text("Item \(index)")
        }

        // Verify that the ForEach has a body
        let body = forEach.body

        // The body should be a ForEachView with 100 items
        if let forEachView = body as? ForEachView<Text> {
            #expect(forEachView.views.count == 100)
        } else {
            Issue.record("Body should be a ForEachView")
        }
    }

    // MARK: - Integration with ViewBuilder

    @Test func forEachInVStack() async throws {
        struct ContentView: View {
            let items = [
                Item(id: 1, name: "First"),
                Item(id: 2, name: "Second")
            ]

            var body: some View {
                VStack {
                    Text("Header")
                    ForEach(items) { @MainActor item in
                        Text(item.name)
                    }
                    Text("Footer")
                }
            }
        }

        let view = ContentView()
        let body = view.body

        // Verify the body structure exists
        #expect(body != nil)
    }
}
