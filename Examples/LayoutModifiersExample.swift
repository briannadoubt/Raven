import Raven

// Example usage of layout modifiers: .clipped(), .aspectRatio(), .fixedSize()

struct LayoutModifiersExample: View {
    @MainActor var body: some View {
        VStack(spacing: 20) {
            // Example 1: Clipped modifier
            Text("This text is clipped to prevent overflow")
                .frame(width: 100, height: 50)
                .background(.blue)
                .clipped()

            // Example 2: Aspect ratio with fit
            Text("16:9 Fit")
                .aspectRatio(16/9, contentMode: .fit)
                .background(.green)

            // Example 3: Aspect ratio with fill
            Text("Square Fill")
                .aspectRatio(1, contentMode: .fill)
                .frame(width: 200, height: 200)
                .clipped()

            // Example 4: Fixed size on both axes
            Text("Fixed size text")
                .fixedSize()
                .background(.red)

            // Example 5: Fixed size horizontal only
            Text("This is a very long text that won't wrap because horizontal is fixed")
                .fixedSize(horizontal: true, vertical: false)
                .background(.purple)

            // Example 6: Fixed size vertical only
            Text("Vertical fixed\nMultiple lines")
                .fixedSize(horizontal: false, vertical: true)
                .background(.orange)

            // Example 7: Combine multiple layout modifiers
            Text("Combined")
                .frame(width: 150, height: 100)
                .aspectRatio(3/2, contentMode: .fill)
                .clipped()
                .fixedSize(horizontal: false, vertical: true)

            // Example 8: Aspect ratio with nil (intrinsic)
            Text("Intrinsic ratio")
                .aspectRatio(contentMode: .fit)

            // Example 9: Complex composition
            VStack {
                Text("Card Content")
                    .padding()
            }
            .aspectRatio(1, contentMode: .fit)
            .background(.blue)
            .cornerRadius(10)
            .clipped()
            .shadow(radius: 5)
        }
        .padding()
    }
}
