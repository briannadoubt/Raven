import XCTest
@testable import Raven

/// Simple verification tests for ContentUnavailableView
@MainActor
final class ContentUnavailableViewSimpleTests: XCTestCase {

    func testBasicContentUnavailableView() throws {
        // Test that a basic ContentUnavailableView can be created
        let view = ContentUnavailableView(
            "No Messages",
            systemImage: "envelope.open"
        )

        // Since ContentUnavailableView is a composed view, we just verify it initializes
        XCTAssertNotNil(view, "ContentUnavailableView should initialize successfully")
    }

    func testContentUnavailableViewWithTextDescription() throws {
        let view = ContentUnavailableView(
            "No Messages",
            systemImage: "envelope.open",
            description: Text("You don't have any messages yet.")
        )

        XCTAssertNotNil(view, "ContentUnavailableView with Text description should initialize")
    }

    func testSearchVariantExists() throws {
        let view = ContentUnavailableView<Text, EmptyView>.search

        XCTAssertNotNil(view, "ContentUnavailableView.search should be available")
    }

    func testFullInitializer() throws {
        let view = ContentUnavailableView(
            "No Items",
            systemImage: "tray",
            description: Text("Add your first item."),
            actions: {
                Button("Add Item") { }
            }
        )

        XCTAssertNotNil(view, "ContentUnavailableView with all components should initialize")
    }
}
