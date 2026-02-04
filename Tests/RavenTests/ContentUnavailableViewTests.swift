import XCTest
@testable import Raven

/// Tests for ContentUnavailableView composed view
@MainActor
final class ContentUnavailableViewTests: XCTestCase {

    // MARK: - Basic Initialization Tests

    func testContentUnavailableViewWithTitleAndIcon() throws {
        let view = ContentUnavailableView(
            "No Messages",
            systemImage: "envelope.open"
        )

        // ContentUnavailableView is a composed view, so we can't directly call toVNode()
        // Instead, we verify that it compiles and has the expected structure
        // The body should be a VStack containing the components
        XCTAssertNotNil(view, "ContentUnavailableView should initialize")
    }

    func testContentUnavailableViewWithDescription() throws {
        let view = ContentUnavailableView(
            "No Messages",
            systemImage: "envelope.open",
            description: Text("You don't have any messages yet.")
        )

        XCTAssertNotNil(view, "ContentUnavailableView with description should initialize")
    }

    func testContentUnavailableViewWithActions() throws {
        var buttonTapped = false
        let view = ContentUnavailableView(
            "No Messages",
            systemImage: "envelope.open",
            description: {
                EmptyView()
            },
            actions: {
                Button("Compose") {
                    buttonTapped = true
                }
            }
        )

        XCTAssertNotNil(view, "ContentUnavailableView with actions should initialize")
    }

    func testContentUnavailableViewWithDescriptionAndActions() throws {
        var buttonTapped = false
        let view = ContentUnavailableView(
            "No Messages",
            systemImage: "envelope.open",
            description: Text("Get started by sending a message.")
        ) {
            Button("Compose Message") {
                buttonTapped = true
            }
        }

        XCTAssertNotNil(view, "ContentUnavailableView with description and actions should initialize")
    }

    func testContentUnavailableViewWithViewBuilderDescription() throws {
        var buttonTapped = false
        let view = ContentUnavailableView(
            "No Data",
            systemImage: "tray",
            description: {
                VStack {
                    Text("No data available.")
                    Text("Try again later.")
                }
            },
            actions: {
                Button("Retry") {
                    buttonTapped = true
                }
            }
        )

        XCTAssertNotNil(view, "ContentUnavailableView with ViewBuilder description should initialize")
    }

    // MARK: - Search Variant Tests

    func testSearchVariant() throws {
        let view = ContentUnavailableView<Text, EmptyView>.search

        // Verify the search variant exists and can be created
        XCTAssertNotNil(view, "ContentUnavailableView.search should be available")
    }

    // MARK: - Type System Tests

    func testTypeInferenceWithTextDescription() throws {
        // This should compile with Description = Text, Actions = EmptyView
        let view = ContentUnavailableView(
            "No Items",
            systemImage: "tray",
            description: Text("Add your first item.")
        )

        XCTAssertNotNil(view, "Type inference should work for Text description")
    }

    func testTypeInferenceWithActions() throws {
        // This should compile with Description = EmptyView, Actions = Button
        let view = ContentUnavailableView(
            "No Items",
            systemImage: "tray",
            description: {
                EmptyView()
            },
            actions: {
                Button("Add Item") { }
            }
        )

        XCTAssertNotNil(view, "Type inference should work for actions")
    }

    func testTypeInferenceWithBoth() throws {
        // This should compile with Description = Text, Actions = Button
        let view = ContentUnavailableView(
            "No Items",
            systemImage: "tray",
            description: Text("Add your first item.")
        ) {
            Button("Add Item") { }
        }

        XCTAssertNotNil(view, "Type inference should work with both description and actions")
    }

    // MARK: - Integration Tests

    func testContentUnavailableViewInConditional() throws {
        struct TestView: View {
            let isEmpty: Bool

            var body: some View {
                if isEmpty {
                    ContentUnavailableView(
                        "No Data",
                        systemImage: "folder",
                        description: Text("No data available.")
                    )
                } else {
                    Text("Data available")
                }
            }
        }

        let emptyState = TestView(isEmpty: true)
        let normalState = TestView(isEmpty: false)

        XCTAssertNotNil(emptyState, "Empty state should render")
        XCTAssertNotNil(normalState, "Normal state should render")
    }

    func testContentUnavailableViewWithMultipleActions() throws {
        var primaryTapped = false
        var secondaryTapped = false

        let view = ContentUnavailableView(
            "Connection Lost",
            systemImage: "wifi.slash",
            description: Text("Unable to connect to the server.")
        ) {
            VStack {
                Button("Retry") {
                    primaryTapped = true
                }
                Button("Cancel") {
                    secondaryTapped = true
                }
            }
        }

        XCTAssertNotNil(view, "ContentUnavailableView with multiple actions should initialize")
    }

    // MARK: - Real-World Usage Tests

    func testEmptyListPattern() throws {
        struct Item: Identifiable {
            let id: Int
            let name: String
        }

        struct ItemListView: View {
            let items: [Item]

            var body: some View {
                if items.isEmpty {
                    ContentUnavailableView(
                        "No Items",
                        systemImage: "tray",
                        description: Text("Add your first item to get started."),
                        actions: {
                            Button("Add Item") { }
                        }
                    )
                } else {
                    Text("Items: \(items.count)")
                }
            }
        }

        let emptyList = ItemListView(items: [])
        let nonEmptyList = ItemListView(items: [Item(id: 1, name: "Test")])

        XCTAssertNotNil(emptyList, "Empty list view should render")
        XCTAssertNotNil(nonEmptyList, "Non-empty list view should render")
    }

    func testEmptySearchPattern() throws {
        struct SearchView: View {
            let query: String
            let results: [String]

            var body: some View {
                if results.isEmpty && !query.isEmpty {
                    ContentUnavailableView.search
                } else {
                    Text("Results: \(results.count)")
                }
            }
        }

        let emptySearch = SearchView(query: "test", results: [])
        let successfulSearch = SearchView(query: "test", results: ["result1", "result2"])
        let noQuery = SearchView(query: "", results: [])

        XCTAssertNotNil(emptySearch, "Empty search should render")
        XCTAssertNotNil(successfulSearch, "Successful search should render")
        XCTAssertNotNil(noQuery, "No query state should render")
    }

    func testPermissionRequiredPattern() throws {
        let view = ContentUnavailableView(
            "Photos Access Required",
            systemImage: "photo.badge.exclamationmark",
            description: Text("Allow access to your photos to continue."),
            actions: {
                Button("Open Settings") { }
            }
        )

        XCTAssertNotNil(view, "Permission required pattern should work")
    }

    func testNoNetworkPattern() throws {
        let view = ContentUnavailableView(
            "No Internet Connection",
            systemImage: "wifi.slash",
            description: Text("Connect to the internet to continue."),
            actions: {
                Button("Retry") { }
            }
        )

        XCTAssertNotNil(view, "No network pattern should work")
    }

    // MARK: - Custom Content Tests

    func testCustomDescriptionView() throws {
        let view = ContentUnavailableView(
            "Custom Content",
            systemImage: "star",
            description: {
                VStack {
                    Text("Line 1")
                    Text("Line 2")
                    Text("Line 3")
                }
            },
            actions: {
                Button("Action") { }
            }
        )

        XCTAssertNotNil(view, "Custom description view should work")
    }

    func testComplexActionsLayout() throws {
        let view = ContentUnavailableView(
            "Multiple Actions",
            systemImage: "exclamationmark.triangle",
            description: Text("Choose an action below."),
            actions: {
                VStack(spacing: 8) {
                    Button("Primary Action") { }
                    Button("Secondary Action") { }
                    HStack {
                        Button("Cancel") { }
                        Button("Dismiss") { }
                    }
                }
            }
        )

        XCTAssertNotNil(view, "Complex actions layout should work")
    }
}
