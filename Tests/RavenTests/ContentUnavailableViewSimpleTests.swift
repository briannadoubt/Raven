import Testing
@testable import Raven

/// Simple verification tests for ContentUnavailableView
@MainActor
@Suite struct ContentUnavailableViewSimpleTests {

    @Test func basicContentUnavailableView() throws {
        // Test that a basic ContentUnavailableView can be created
        let view = ContentUnavailableView(
            "No Messages",
            systemImage: "envelope.open"
        )

        // Since ContentUnavailableView is a composed view, we just verify it initializes
        #expect(view != nil)
    }

    @Test func contentUnavailableViewWithTextDescription() throws {
        let view = ContentUnavailableView(
            "No Messages",
            systemImage: "envelope.open",
            description: Text("You don't have any messages yet.")
        )

        #expect(view != nil)
    }

    @Test func searchVariantExists() throws {
        let view = ContentUnavailableView<Text, EmptyView>.search

        #expect(view != nil)
    }

    @Test func fullInitializer() throws {
        let view = ContentUnavailableView(
            "No Items",
            systemImage: "tray",
            description: Text("Add your first item."),
            actions: {
                Button("Add Item") { }
            }
        )

        #expect(view != nil)
    }
}
