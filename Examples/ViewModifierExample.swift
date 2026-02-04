import Foundation
import Raven

// This example demonstrates the ViewModifier protocol system in Raven
// It shows how to create custom modifiers and use them with views

// Note: This file is for documentation purposes and demonstrates the API.
// It requires the full Raven library to be buildable.

/*

// MARK: - Creating Custom Modifiers

/// Example 1: A simple border modifier
struct BorderModifier: ViewModifier {
    let color: Color
    let width: Double

    func body(content: Content) -> some View {
        content
            .padding(width)
            .foregroundColor(color)
    }
}

// Usage:
Text("Hello")
    .modifier(BorderModifier(color: .blue, width: 2))

// Or with the convenience extension:
Text("Hello")
    .border(.blue, width: 2)


// MARK: - Composing Modifiers

/// Example 2: A card modifier that combines multiple effects
struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .frame(width: 300)
    }
}

// Usage:
VStack {
    Text("Card Title")
    Text("Card content")
}
.modifier(CardModifier())

// Or:
VStack {
    Text("Card Title")
    Text("Card content")
}
.card()


// MARK: - Parameterized Modifiers

/// Example 3: A modifier with configurable parameters
struct ShadowModifier: ViewModifier {
    let color: Color
    let radius: Double
    let x: Double
    let y: Double

    func body(content: Content) -> some View {
        content
            .padding(radius)
            // In a full implementation, this would apply shadow styles
    }
}

// Usage:
Text("Shadowed")
    .modifier(ShadowModifier(color: .gray, radius: 5, x: 2, y: 2))


// MARK: - Conditional Modifiers

/// Example 4: A modifier that applies different styles based on state
struct ConditionalStyleModifier: ViewModifier {
    let isHighlighted: Bool

    func body(content: Content) -> some View {
        if isHighlighted {
            content
                .padding(12)
                .foregroundColor(.blue)
        } else {
            content
                .padding(8)
                .foregroundColor(.gray)
        }
    }
}

// Usage:
Text("Conditional")
    .modifier(ConditionalStyleModifier(isHighlighted: true))


// MARK: - Nested Modifiers

/// Example 5: A modifier that uses other modifiers
struct ComplexModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .modifier(BorderModifier(color: .red, width: 1))
            .modifier(CardModifier())
            .padding(4)
    }
}

// Usage:
Text("Complex styling")
    .modifier(ComplexModifier())


// MARK: - Environment-Aware Modifiers (Future)

/// Example 6: A modifier that accesses environment values
/// (This would require the Environment system to be fully implemented)
struct ThemedModifier: ViewModifier {
    // @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        content
            // .foregroundColor(colorScheme == .dark ? .white : .black)
            .padding(10)
    }
}


// MARK: - Modifier Extensions

extension View {
    /// Create reusable modifier methods for better ergonomics

    func shadow(color: Color = .gray, radius: Double = 5, x: Double = 0, y: Double = 0) -> some View {
        self.modifier(ShadowModifier(color: color, radius: radius, x: x, y: y))
    }

    func conditionalStyle(isHighlighted: Bool) -> some View {
        self.modifier(ConditionalStyleModifier(isHighlighted: isHighlighted))
    }

    func complex() -> some View {
        self.modifier(ComplexModifier())
    }
}

// Usage with extensions:
Text("With shadow")
    .shadow(color: .black, radius: 3)

Text("Highlighted")
    .conditionalStyle(isHighlighted: true)


// MARK: - Complete Example

struct ExampleView: View {
    var body: some View {
        VStack {
            // Basic usage
            Text("Title")
                .title()

            // Custom modifier
            Text("Bordered text")
                .border(.blue, width: 2)

            // Card layout
            VStack {
                Text("Card Title")
                Text("Card description")
            }
            .card()

            // Chained modifiers
            Text("Complex")
                .padding(8)
                .border(.green, width: 1)
                .frame(width: 200)
                .modifier(TitleModifier())

            // Conditional styling
            Text("Maybe highlighted")
                .conditionalStyle(isHighlighted: true)
        }
    }
}

*/
