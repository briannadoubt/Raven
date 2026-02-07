import Testing
@testable import Raven

/// Tests for the ViewModifier protocol and custom modifiers
@MainActor
@Suite struct ViewModifierTests {

    // MARK: - Basic ViewModifier Tests

    @MainActor
    @Test func borderModifier() {
        // Create a view with a custom border modifier
        let view = Text("Hello")
            .modifier(BorderModifier(color: .blue, width: 2))

        // Verify the type is correct
        #expect(view is ModifiedContent<Text, BorderModifier>)
    }

    @MainActor
    @Test func cardModifier() {
        // Create a view with a custom card modifier
        let view = Text("Card Content")
            .modifier(CardModifier())

        // Verify the type is correct
        #expect(view is ModifiedContent<Text, CardModifier>)
    }

    @MainActor
    @Test func titleModifier() {
        // Create a view with a custom title modifier
        let view = Text("Title")
            .modifier(TitleModifier())

        // Verify the type is correct
        #expect(view is ModifiedContent<Text, TitleModifier>)
    }

    // MARK: - Convenience Extension Tests

    @MainActor
    @Test func borderConvenienceMethod() {
        // Use the convenience method
        let view = Text("Bordered")
            .border(.red, width: 3)

        // The type should be some View, but we can verify it compiles
        let _ = view
    }

    @MainActor
    @Test func cardConvenienceMethod() {
        // Use the convenience method
        let view = Text("Card")
            .card()

        // The type should be some View
        let _ = view
    }

    @MainActor
    @Test func titleConvenienceMethod() {
        // Use the convenience method
        let view = Text("Title")
            .title()

        // The type should be some View
        let _ = view
    }

    // MARK: - Modifier Composition Tests

    @MainActor
    @Test func modifierComposition() {
        // Chain multiple custom modifiers
        let view = Text("Complex")
            .modifier(TitleModifier())
            .modifier(BorderModifier(color: .blue, width: 1))
            .modifier(CardModifier())

        // Verify it compiles and creates a complex type
        let _ = view
    }

    @MainActor
    @Test func mixedModifiers() {
        // Mix custom modifiers with basic modifiers
        let view = Text("Mixed")
            .padding(10)
            .modifier(BorderModifier(color: .green, width: 2))
            .frame(width: 200, height: 100)
            .modifier(TitleModifier())

        // Verify it compiles
        let _ = view
    }

    // MARK: - Custom Modifier Tests

    /// A test custom modifier
    struct TestModifier: ViewModifier, Sendable {
        let value: Double

        @MainActor
        func body(content: Content) -> some View {
            content
                .padding(value)
                .foregroundColor(.blue)
        }
    }

    @MainActor
    @Test func customModifier() {
        // Create a custom modifier
        let modifier = TestModifier(value: 20)

        // Apply it to a view
        let view = Text("Custom")
            .modifier(modifier)

        // Verify the type
        #expect(view is ModifiedContent<Text, TestModifier>)
    }

    @MainActor
    @Test func customModifierWithParameters() {
        // Test a custom modifier with different parameters
        let view1 = Text("Small").modifier(TestModifier(value: 5))
        let view2 = Text("Large").modifier(TestModifier(value: 20))

        // Both should compile correctly
        let _ = view1
        let _ = view2
    }

    // MARK: - SendableAndConcurrency Tests

    @MainActor
    @Test func modifierIsSendable() {
        // Verify that our modifiers conform to Sendable
        let border: any ViewModifier & Sendable = BorderModifier(color: .red, width: 1)
        let card: any ViewModifier & Sendable = CardModifier()
        let title: any ViewModifier & Sendable = TitleModifier()

        // These should all compile without issues
        let _ = border
        let _ = card
        let _ = title
    }

    @MainActor
    @Test func modifiedContentIsSendable() {
        // Verify that ModifiedContent conforms to Sendable
        let view = Text("Test")
            .modifier(BorderModifier(color: .blue, width: 2))

        // This should be Sendable
        let sendableView: any View & Sendable = view
        let _ = sendableView
    }

    // MARK: - Type Erasure Tests

    @MainActor
    @Test func modifierWithTypeErasure() {
        // Use AnyView with modifiers
        let view = AnyView(
            Text("Erased")
                .modifier(BorderModifier(color: .purple, width: 1))
        )

        // Should compile and work correctly
        let _ = view
    }

    // MARK: - Edge Cases

    @MainActor
    @Test func emptyModifierBody() {
        /// A modifier that does nothing
        struct EmptyModifier: ViewModifier, Sendable {
            @MainActor
            func body(content: Content) -> some View {
                content
            }
        }

        let view = Text("Unchanged")
            .modifier(EmptyModifier())

        // Should compile fine
        let _ = view
    }

    @MainActor
    @Test func nestedModifierComposition() {
        /// A modifier that applies another modifier
        struct WrapperModifier: ViewModifier, Sendable {
            @MainActor
            func body(content: Content) -> some View {
                content
                    .modifier(BorderModifier(color: .red, width: 1))
                    .padding(8)
            }
        }

        let view = Text("Nested")
            .modifier(WrapperModifier())

        // Should compile and allow nested composition
        let _ = view
    }
}
