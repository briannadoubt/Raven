import Testing
@testable import Raven

/// Tests for AlertRenderer content extraction functionality.
///
/// These tests verify that the extractAlertData method can properly
/// parse view hierarchies and extract structured alert data.
@MainActor
@Suite struct AlertRendererExtractionTests {

    // MARK: - Basic Extraction Tests

    @Test func extractTitleOnly() {
        // Create a simple alert content with just a title and button
        let content = AnyView(VStack {
            Text("Alert Title")
            Button("OK") { }
        })

        let result = AlertRenderer.extractAlertData(from: content)

        #expect(result != nil)
        #expect(result?.title == "Alert Title")
        #expect(result?.message == nil)
        #expect(result?.buttons.count == 1)
        #expect(result?.buttons.first?.label == "OK")
    }

    @Test func extractTitleAndMessage() {
        // Create alert content with title and message
        let content = AnyView(VStack {
            Text("Alert Title")
            Text("This is a descriptive message")
            Button("OK") { }
        })

        let result = AlertRenderer.extractAlertData(from: content)

        #expect(result != nil)
        #expect(result?.title == "Alert Title")
        #expect(result?.message == "This is a descriptive message")
        #expect(result?.buttons.count == 1)
    }

    @Test func extractMultipleButtons() {
        // Create alert content with multiple buttons
        let content = AnyView(VStack {
            Text("Confirm Action")
            Text("Are you sure you want to proceed?")
            Button("Delete") { }
            Button("Cancel") { }
        })

        let result = AlertRenderer.extractAlertData(from: content)

        #expect(result != nil)
        #expect(result?.title == "Confirm Action")
        #expect(result?.message == "Are you sure you want to proceed?")
        #expect(result?.buttons.count == 2)
        #expect(result?.buttons[0].label == "Delete")
        #expect(result?.buttons[1].label == "Cancel")
    }

    @Test func extractThreeButtons() {
        // Create alert content with three buttons
        let content = AnyView(VStack {
            Text("Choose Option")
            Button("Option A") { }
            Button("Option B") { }
            Button("Cancel") { }
        })

        let result = AlertRenderer.extractAlertData(from: content)

        #expect(result != nil)
        #expect(result?.title == "Choose Option")
        #expect(result?.message == nil)
        #expect(result?.buttons.count == 3)
    }

    // MARK: - Edge Cases

    @Test func extractWithNoButtons() {
        // Alert content with no buttons (unusual but should handle gracefully)
        let content = AnyView(VStack {
            Text("Information")
            Text("Just displaying info")
        })

        let result = AlertRenderer.extractAlertData(from: content)

        #expect(result != nil)
        #expect(result?.title == "Information")
        #expect(result?.message == "Just displaying info")
        #expect(result?.buttons.count == 0)
    }

    @Test func extractEmptyContent() {
        // Empty content should return nil
        let content = AnyView(VStack { })

        let result = AlertRenderer.extractAlertData(from: content)

        #expect(result == nil)
    }

    @Test func extractWithWhitespaceText() {
        // Text with only whitespace should be ignored
        let content = AnyView(VStack {
            Text("Title")
            Text("   ")
            Button("OK") { }
        })

        let result = AlertRenderer.extractAlertData(from: content)

        #expect(result != nil)
        #expect(result?.title == "Title")
        // Whitespace-only text should be ignored, so no message
        #expect(result?.message == nil)
    }

    // MARK: - Complex Structure Tests

    @Test func extractWithNestedViews() {
        // Alert content with nested structure (VStack in VStack)
        let content = AnyView(VStack {
            VStack {
                Text("Nested Title")
            }
            Text("Message")
            Button("OK") { }
        })

        let result = AlertRenderer.extractAlertData(from: content)

        #expect(result != nil)
        // Should still extract the title from nested structure
        #expect(result?.title == "Nested Title")
        #expect(result?.message == "Message")
    }

    // MARK: - Real-World Patterns

    @Test func extractSimpleAlert() {
        // Pattern: .alert("Title", isPresented: $show) { Button("OK") { } }
        let content = AnyView(VStack {
            Text("Success")
            Button("OK") { }
        })

        let result = AlertRenderer.extractAlertData(from: content)

        #expect(result != nil)
        #expect(result?.title == "Success")
        #expect(result?.message == nil)
        #expect(result?.buttons.count == 1)
    }

    @Test func extractAlertWithMessage() {
        // Pattern: .alert("Title", ...) { ... } message: { Text("...") }
        let content = AnyView(VStack {
            Text("Save Changes?")
            Text("Your document will be saved to the cloud.")
            Button("Save") { }
            Button("Cancel") { }
        })

        let result = AlertRenderer.extractAlertData(from: content)

        #expect(result != nil)
        #expect(result?.title == "Save Changes?")
        #expect(result?.message == "Your document will be saved to the cloud.")
        #expect(result?.buttons.count == 2)
    }

    @Test func extractDestructiveAlert() {
        // Pattern: Destructive action confirmation
        let content = AnyView(VStack {
            Text("Delete Item")
            Text("This action cannot be undone.")
            Button("Delete") { }
            Button("Cancel") { }
        })

        let result = AlertRenderer.extractAlertData(from: content)

        #expect(result != nil)
        #expect(result?.title == "Delete Item")
        #expect(result?.message == "This action cannot be undone.")
        #expect(result?.buttons.count == 2)
        #expect(result?.buttons[0].label == "Delete")
        #expect(result?.buttons[1].label == "Cancel")
    }
}
