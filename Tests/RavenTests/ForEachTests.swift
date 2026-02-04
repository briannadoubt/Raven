import XCTest
@testable import Raven

/// Tests for the ForEach view
@MainActor
final class ForEachTests: XCTestCase {

    // MARK: - Range-based ForEach

    func testForEachWithRange() async throws {
        // Create a ForEach with a range
        let forEach = ForEach(0..<3) { index in
            Text("Item \(index)")
        }

        // Verify that the ForEach has a body (it's a composed view)
        let body = forEach.body

        // The body should be a ForEachView
        XCTAssertTrue(body is ForEachView<Text>, "Body should be a ForEachView")
    }

    // MARK: - Identifiable Collection

    struct Item: Identifiable, Sendable {
        let id: Int
        let name: String
    }

    func testForEachWithIdentifiable() async throws {
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
        XCTAssertTrue(body is ForEachView<Text>, "Body should be a ForEachView")
    }

    // MARK: - Custom ID Key Path

    struct CustomItem: Sendable {
        let name: String
        let value: Int
    }

    func testForEachWithCustomKeyPath() async throws {
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
        XCTAssertTrue(body is ForEachView<Text>, "Body should be a ForEachView")
    }

    // MARK: - Empty Collection

    func testForEachWithEmptyCollection() async throws {
        let items: [Item] = []

        let forEach = ForEach(items) { item in
            Text(item.name)
        }

        // Verify that the ForEach has a body
        let body = forEach.body

        // The body should be a ForEachView with no views
        if let forEachView = body as? ForEachView<Text> {
            XCTAssertTrue(forEachView.views.isEmpty, "ForEachView should have no views for empty collection")
        } else {
            XCTFail("Body should be a ForEachView")
        }
    }

    // MARK: - Nested Views

    func testForEachWithNestedViews() async throws {
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

        // The body should be a ForEachView
        XCTAssertTrue(body is ForEachView<VStack<TupleView<(Text, Text)>>>, "Body should be a ForEachView of VStacks")
    }

    // MARK: - Large Collections

    func testForEachWithLargeCollection() async throws {
        let range = 0..<100

        let forEach = ForEach(range) { index in
            Text("Item \(index)")
        }

        // Verify that the ForEach has a body
        let body = forEach.body

        // The body should be a ForEachView with 100 items
        if let forEachView = body as? ForEachView<Text> {
            XCTAssertEqual(forEachView.views.count, 100, "ForEachView should have 100 views")
        } else {
            XCTFail("Body should be a ForEachView")
        }
    }

    // MARK: - Integration with ViewBuilder

    func testForEachInVStack() async throws {
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

        // Verify the body structure
        XCTAssertTrue(body is VStack<TupleView<(Text, ForEach<[Item], Int, Text>, Text)>>,
                      "Body should be a VStack with Text, ForEach, and Text")
    }
}
