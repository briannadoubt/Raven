import XCTest
@testable import Raven

/// Tests for AlertRenderer content extraction functionality.
///
/// These tests verify that the extractAlertData method can properly
/// parse view hierarchies and extract structured alert data.
@MainActor
final class AlertRendererExtractionTests: XCTestCase {

    // MARK: - Basic Extraction Tests

    func testExtractTitleOnly() {
        // Create a simple alert content with just a title and button
        let content = AnyView(VStack {
            Text("Alert Title")
            Button("OK") { }
        })

        let result = AlertRenderer.extractAlertData(from: content)

        XCTAssertNotNil(result, "Extraction should succeed for valid alert content")
        XCTAssertEqual(result?.title, "Alert Title")
        XCTAssertNil(result?.message)
        XCTAssertEqual(result?.buttons.count, 1)
        XCTAssertEqual(result?.buttons.first?.label, "OK")
    }

    func testExtractTitleAndMessage() {
        // Create alert content with title and message
        let content = AnyView(VStack {
            Text("Alert Title")
            Text("This is a descriptive message")
            Button("OK") { }
        })

        let result = AlertRenderer.extractAlertData(from: content)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.title, "Alert Title")
        XCTAssertEqual(result?.message, "This is a descriptive message")
        XCTAssertEqual(result?.buttons.count, 1)
    }

    func testExtractMultipleButtons() {
        // Create alert content with multiple buttons
        let content = AnyView(VStack {
            Text("Confirm Action")
            Text("Are you sure you want to proceed?")
            Button("Delete") { }
            Button("Cancel") { }
        })

        let result = AlertRenderer.extractAlertData(from: content)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.title, "Confirm Action")
        XCTAssertEqual(result?.message, "Are you sure you want to proceed?")
        XCTAssertEqual(result?.buttons.count, 2)
        XCTAssertEqual(result?.buttons[0].label, "Delete")
        XCTAssertEqual(result?.buttons[1].label, "Cancel")
    }

    func testExtractThreeButtons() {
        // Create alert content with three buttons
        let content = AnyView(VStack {
            Text("Choose Option")
            Button("Option A") { }
            Button("Option B") { }
            Button("Cancel") { }
        })

        let result = AlertRenderer.extractAlertData(from: content)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.title, "Choose Option")
        XCTAssertNil(result?.message)
        XCTAssertEqual(result?.buttons.count, 3)
    }

    // MARK: - Edge Cases

    func testExtractWithNoButtons() {
        // Alert content with no buttons (unusual but should handle gracefully)
        let content = AnyView(VStack {
            Text("Information")
            Text("Just displaying info")
        })

        let result = AlertRenderer.extractAlertData(from: content)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.title, "Information")
        XCTAssertEqual(result?.message, "Just displaying info")
        XCTAssertEqual(result?.buttons.count, 0)
    }

    func testExtractEmptyContent() {
        // Empty content should return nil
        let content = AnyView(VStack { })

        let result = AlertRenderer.extractAlertData(from: content)

        XCTAssertNil(result, "Empty content should return nil")
    }

    func testExtractWithWhitespaceText() {
        // Text with only whitespace should be ignored
        let content = AnyView(VStack {
            Text("Title")
            Text("   ")
            Button("OK") { }
        })

        let result = AlertRenderer.extractAlertData(from: content)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.title, "Title")
        // Whitespace-only text should be ignored, so no message
        XCTAssertNil(result?.message)
    }

    // MARK: - Complex Structure Tests

    func testExtractWithNestedViews() {
        // Alert content with nested structure (VStack in VStack)
        let content = AnyView(VStack {
            VStack {
                Text("Nested Title")
            }
            Text("Message")
            Button("OK") { }
        })

        let result = AlertRenderer.extractAlertData(from: content)

        XCTAssertNotNil(result)
        // Should still extract the title from nested structure
        XCTAssertEqual(result?.title, "Nested Title")
        XCTAssertEqual(result?.message, "Message")
    }

    // MARK: - Real-World Patterns

    func testExtractSimpleAlert() {
        // Pattern: .alert("Title", isPresented: $show) { Button("OK") { } }
        let content = AnyView(VStack {
            Text("Success")
            Button("OK") { }
        })

        let result = AlertRenderer.extractAlertData(from: content)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.title, "Success")
        XCTAssertNil(result?.message)
        XCTAssertEqual(result?.buttons.count, 1)
    }

    func testExtractAlertWithMessage() {
        // Pattern: .alert("Title", ...) { ... } message: { Text("...") }
        let content = AnyView(VStack {
            Text("Save Changes?")
            Text("Your document will be saved to the cloud.")
            Button("Save") { }
            Button("Cancel") { }
        })

        let result = AlertRenderer.extractAlertData(from: content)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.title, "Save Changes?")
        XCTAssertEqual(result?.message, "Your document will be saved to the cloud.")
        XCTAssertEqual(result?.buttons.count, 2)
    }

    func testExtractDestructiveAlert() {
        // Pattern: Destructive action confirmation
        let content = AnyView(VStack {
            Text("Delete Item")
            Text("This action cannot be undone.")
            Button("Delete") { }
            Button("Cancel") { }
        })

        let result = AlertRenderer.extractAlertData(from: content)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.title, "Delete Item")
        XCTAssertEqual(result?.message, "This action cannot be undone.")
        XCTAssertEqual(result?.buttons.count, 2)
        XCTAssertEqual(result?.buttons[0].label, "Delete")
        XCTAssertEqual(result?.buttons[1].label, "Cancel")
    }
}
