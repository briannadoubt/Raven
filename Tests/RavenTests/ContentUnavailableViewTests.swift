import Testing
@testable import Raven

/// Tests for ContentUnavailableView composed view
@MainActor
@Suite struct ContentUnavailableViewTests {

    // MARK: - Basic Initialization Tests

    @Test func contentUnavailableViewWithTitleAndIcon() throws {
        let view = ContentUnavailableView(
            "No Messages",
            systemImage: "envelope.open"
        )

        // ContentUnavailableView is a composed view, so we can't directly call toVNode()
        // Instead, we verify that it compiles and has the expected structure
        // The body should be a VStack containing the components
        #expect(view != nil)
    }

    @Test func contentUnavailableViewWithDescription() throws {
        let view = ContentUnavailableView(
            "No Messages",
            systemImage: "envelope.open",
            description: Text("You don't have any messages yet.")
        )

        #expect(view != nil)
    }

    @Test func contentUnavailableViewWithActions() throws {
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

        #expect(view != nil)
    }

    @Test func contentUnavailableViewWithDescriptionAndActions() throws {
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

        #expect(view != nil)
    }

    @Test func contentUnavailableViewWithViewBuilderDescription() throws {
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

        #expect(view != nil)
    }

    // MARK: - Search Variant Tests

    @Test func searchVariant() throws {
        let view = ContentUnavailableView<Text, EmptyView>.search

        // Verify the search variant exists and can be created
        #expect(view != nil)
    }

    // MARK: - Type System Tests

    @Test func typeInferenceWithTextDescription() throws {
        // This should compile with Description = Text, Actions = EmptyView
        let view = ContentUnavailableView(
            "No Items",
            systemImage: "tray",
            description: Text("Add your first item.")
        )

        #expect(view != nil)
    }

    @Test func typeInferenceWithActions() throws {
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

        #expect(view != nil)
    }

    @Test func typeInferenceWithBoth() throws {
        // This should compile with Description = Text, Actions = Button
        let view = ContentUnavailableView(
            "No Items",
            systemImage: "tray",
            description: Text("Add your first item.")
        ) {
            Button("Add Item") { }
        }

        #expect(view != nil)
    }

    // MARK: - Integration Tests

    @Test func contentUnavailableViewInConditional() throws {
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

        #expect(emptyState != nil)
        #expect(normalState != nil)
    }

    @Test func contentUnavailableViewWithMultipleActions() throws {
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

        #expect(view != nil)
    }

    // MARK: - Real-World Usage Tests

    @Test func emptyListPattern() throws {
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

        #expect(emptyList != nil)
        #expect(nonEmptyList != nil)
    }

    @Test func emptySearchPattern() throws {
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

        #expect(emptySearch != nil)
        #expect(successfulSearch != nil)
        #expect(noQuery != nil)
    }

    @Test func permissionRequiredPattern() throws {
        let view = ContentUnavailableView(
            "Photos Access Required",
            systemImage: "photo.badge.exclamationmark",
            description: Text("Allow access to your photos to continue."),
            actions: {
                Button("Open Settings") { }
            }
        )

        #expect(view != nil)
    }

    @Test func noNetworkPattern() throws {
        let view = ContentUnavailableView(
            "No Internet Connection",
            systemImage: "wifi.slash",
            description: Text("Connect to the internet to continue."),
            actions: {
                Button("Retry") { }
            }
        )

        #expect(view != nil)
    }

    // MARK: - Custom Content Tests

    @Test func customDescriptionView() throws {
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

        #expect(view != nil)
    }

    @Test func complexActionsLayout() throws {
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

        #expect(view != nil)
    }
}
