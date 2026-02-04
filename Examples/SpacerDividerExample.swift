import Foundation
import Raven

/// Example demonstrating the use of Spacer and Divider in layouts
///
/// This example shows:
/// 1. Using Spacer to push content apart in vertical and horizontal stacks
/// 2. Using Divider to create visual separators between content sections
/// 3. Combining Spacer and Divider with other layout primitives
@MainActor
struct SpacerDividerExample: View {
    var body: some View {
        VStack(spacing: 16) {
            // Header pushed to top with spacer below
            VStack(spacing: 8) {
                Text("Header Section")
                Text("This is at the top")
            }

            // Spacer pushes content down
            Spacer(minLength: 20)

            // Middle section with divider
            Text("Middle Section")
            Divider()

            // Another section
            Text("Another Section")
            Divider()

            // Footer section
            VStack(spacing: 8) {
                Text("Footer Section")
                Text("This is at the bottom")
            }
        }
    }
}

/// Example demonstrating horizontal spacing with Spacer
@MainActor
struct HorizontalSpacerExample: View {
    var body: some View {
        HStack {
            // Left-aligned content
            Text("Left")

            // Spacer pushes content to edges
            Spacer()

            // Right-aligned content
            Text("Right")
        }
    }
}

/// Example demonstrating multiple spacers creating equal distribution
@MainActor
struct EqualDistributionExample: View {
    var body: some View {
        HStack {
            Text("Item 1")
            Spacer()
            Text("Item 2")
            Spacer()
            Text("Item 3")
        }
    }
}

/// Example demonstrating dividers in a list-like layout
@MainActor
struct ListWithDividersExample: View {
    var body: some View {
        VStack(spacing: 0) {
            // List items with dividers
            Text("Item 1")
            Divider()

            Text("Item 2")
            Divider()

            Text("Item 3")
            Divider()

            Text("Item 4")
        }
    }
}

/// Example demonstrating spacer with minimum length
@MainActor
struct SpacerMinLengthExample: View {
    var body: some View {
        HStack {
            Text("Left Content")

            // Spacer with minimum width of 50px
            Spacer(minLength: 50)

            Text("Right Content")
        }
    }
}

/// Complex example combining multiple layout techniques
@MainActor
struct ComplexLayoutExample: View {
    var body: some View {
        VStack(spacing: 0) {
            // Header with horizontal layout
            HStack {
                Text("App Title")
                Spacer()
                Text("Settings")
            }

            Divider()

            // Main content area
            VStack(spacing: 12) {
                Text("Main Content Area")

                // Nested horizontal layout
                HStack {
                    Text("Left Panel")
                    Spacer(minLength: 20)
                    Text("Right Panel")
                }

                Divider()

                Text("More content here")
            }

            // Push footer to bottom
            Spacer()

            Divider()

            // Footer
            HStack {
                Text("© 2026")
                Spacer()
                Text("Version 1.0")
            }
        }
    }
}

// MARK: - Usage Notes

/*
 Usage Notes:

 ## Spacer

 Spacer is a flexible space that expands to fill available space along the major axis
 of the containing stack:
 - In VStack: Expands vertically
 - In HStack: Expands horizontally

 Properties:
 - `minLength`: Optional minimum size (in pixels) that the spacer cannot shrink below

 Common Patterns:
 1. Push content to edges: Place Spacer between elements
 2. Center content: Use Spacer on both sides
 3. Equal distribution: Multiple spacers divide space equally
 4. Minimum spacing: Use minLength to ensure adequate spacing

 ## Divider

 Divider creates a visual separator line:
 - Default: 1px solid line with gray color
 - Full width in its container
 - Does not expand in flex layouts (flex-shrink: 0)

 Common Patterns:
 1. Section separators in VStack
 2. Visual breaks between content areas
 3. List item separators
 4. Header/footer boundaries

 ## CSS Implementation Details

 ### Spacer
 - `flex-grow: 1` - Allows expansion to fill space
 - `flex-shrink: 1` - Allows shrinking when needed
 - `flex-basis: 0` - Starts from zero size
 - `min-width` / `min-height` - Applied when minLength is specified

 ### Divider
 - `border-top: 1px solid #d1d5db` - Creates the visual line
 - `height: 0` - No content height (border provides the visual)
 - `width: 100%` - Full width of container
 - `flex-shrink: 0` - Does not shrink in flex layouts
 */
