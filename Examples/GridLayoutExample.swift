import Foundation
import Raven

/// Example demonstrating the use of LazyVGrid with various column configurations
///
/// This example shows:
/// 1. Fixed-size columns
/// 2. Flexible columns
/// 3. Adaptive columns
/// 4. Mixed column types
/// 5. Custom spacing and alignment
@MainActor
struct BasicGridExample: View {
    var body: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ],
            spacing: 16
        ) {
            ForEach(0..<12) { index in
                Text("Item \(index)")
            }
        }
    }
}

/// Example demonstrating LazyVGrid with fixed column sizes
@MainActor
struct FixedColumnsExample: View {
    var body: some View {
        LazyVGrid(
            columns: [
                GridItem(.fixed(100)),
                GridItem(.fixed(150)),
                GridItem(.fixed(100))
            ],
            spacing: 12
        ) {
            ForEach(0..<9) { index in
                Text("Cell \(index)")
            }
        }
    }
}

/// Example demonstrating adaptive columns that fit as many as possible
@MainActor
struct AdaptiveGridExample: View {
    var body: some View {
        LazyVGrid(
            columns: [
                GridItem(.adaptive(minimum: 80))
            ],
            spacing: 16
        ) {
            ForEach(0..<20) { index in
                Text("Item \(index)")
            }
        }
    }
}

/// Example demonstrating mixed column types
@MainActor
struct MixedColumnsExample: View {
    var body: some View {
        LazyVGrid(
            columns: [
                GridItem(.fixed(60)),           // Fixed sidebar
                GridItem(.flexible()),          // Main content area
                GridItem(.flexible()),          // Secondary content area
                GridItem(.fixed(80))            // Fixed right panel
            ],
            spacing: 12
        ) {
            ForEach(0..<16) { index in
                Text("Item \(index)")
            }
        }
    }
}

/// Example demonstrating flexible columns with min/max constraints
@MainActor
struct FlexibleConstraintsExample: View {
    var body: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(minimum: 100, maximum: 200)),
                GridItem(.flexible(minimum: 150, maximum: 300)),
                GridItem(.flexible(minimum: 100, maximum: 200))
            ],
            spacing: 16
        ) {
            ForEach(0..<12) { index in
                Text("Item \(index)")
            }
        }
    }
}

/// Example demonstrating LazyHGrid with horizontal scrolling rows
@MainActor
struct HorizontalGridExample: View {
    var body: some View {
        LazyHGrid(
            rows: [
                GridItem(.fixed(100)),
                GridItem(.fixed(100)),
                GridItem(.fixed(100))
            ],
            spacing: 16
        ) {
            ForEach(0..<15) { index in
                Text("Item \(index)")
            }
        }
    }
}

/// Example demonstrating a photo gallery with adaptive grid
@MainActor
struct PhotoGalleryExample: View {
    var body: some View {
        VStack(spacing: 0) {
            // Header
            Text("Photo Gallery")

            // Grid of photos (simulated with text for example)
            LazyVGrid(
                columns: [
                    GridItem(.adaptive(minimum: 120, maximum: 200))
                ],
                spacing: 16
            ) {
                ForEach(0..<24) { index in
                    VStack {
                        Text("Photo \(index)")
                        Text("Caption")
                    }
                }
            }
        }
    }
}

/// Example demonstrating a dashboard layout with mixed column sizes
@MainActor
struct DashboardExample: View {
    var body: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(minimum: 200)),
                GridItem(.flexible(minimum: 200)),
                GridItem(.flexible(minimum: 200))
            ],
            alignment: .topLeading,
            spacing: 20
        ) {
            // Dashboard widgets
            VStack {
                Text("Widget 1")
                Text("Stats and metrics")
            }

            VStack {
                Text("Widget 2")
                Text("Recent activity")
            }

            VStack {
                Text("Widget 3")
                Text("User information")
            }

            VStack {
                Text("Widget 4")
                Text("Graph or chart")
            }

            VStack {
                Text("Widget 5")
                Text("Notifications")
            }

            VStack {
                Text("Widget 6")
                Text("Quick actions")
            }
        }
    }
}

/// Example demonstrating alignment in grid cells
@MainActor
struct GridAlignmentExample: View {
    var body: some View {
        VStack(spacing: 24) {
            // Center aligned (default)
            LazyVGrid(
                columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ],
                alignment: .center,
                spacing: 12
            ) {
                ForEach(0..<6) { index in
                    Text("Center \(index)")
                }
            }

            // Top-leading aligned
            LazyVGrid(
                columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ],
                alignment: .topLeading,
                spacing: 12
            ) {
                ForEach(0..<6) { index in
                    Text("Top-Leading \(index)")
                }
            }

            // Bottom-trailing aligned
            LazyVGrid(
                columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ],
                alignment: .bottomTrailing,
                spacing: 12
            ) {
                ForEach(0..<6) { index in
                    Text("Bottom-Trailing \(index)")
                }
            }
        }
    }
}

/// Example demonstrating a calendar-like grid
@MainActor
struct CalendarGridExample: View {
    var body: some View {
        VStack(spacing: 8) {
            // Days of week header
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible()), count: 7),
                spacing: 4
            ) {
                ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                    Text(day)
                }
            }

            // Calendar days (simplified)
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible()), count: 7),
                spacing: 4
            ) {
                ForEach(1...35) { day in
                    Text("\(day)")
                }
            }
        }
    }
}

/// Example demonstrating nested grids for complex layouts
@MainActor
struct NestedGridExample: View {
    var body: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ],
            spacing: 16
        ) {
            // Each grid cell contains another grid
            VStack {
                Text("Section 1")
                LazyVGrid(
                    columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ],
                    spacing: 8
                ) {
                    ForEach(0..<4) { index in
                        Text("1.\(index)")
                    }
                }
            }

            VStack {
                Text("Section 2")
                LazyVGrid(
                    columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ],
                    spacing: 8
                ) {
                    ForEach(0..<4) { index in
                        Text("2.\(index)")
                    }
                }
            }
        }
    }
}

// MARK: - Usage Notes

/*
 Usage Notes:

 ## LazyVGrid (Vertical Grid)

 LazyVGrid creates a vertically scrolling grid with a fixed number of columns.
 Items flow into rows automatically as needed.

 ### Column Configuration

 Each column is defined by a `GridItem` with one of three sizing modes:

 1. **Fixed**: A column with a fixed width in pixels
    ```swift
    GridItem(.fixed(100))  // Always 100px wide
    ```

 2. **Flexible**: A column that grows to fill available space
    ```swift
    GridItem(.flexible())                      // Default: min 10px, max infinite
    GridItem(.flexible(minimum: 50))           // At least 50px wide
    GridItem(.flexible(minimum: 50, maximum: 200))  // Between 50px and 200px
    ```

 3. **Adaptive**: Multiple columns that adapt to available space
    ```swift
    GridItem(.adaptive(minimum: 80))  // As many 80px+ columns as fit
    GridItem(.adaptive(minimum: 80, maximum: 150))  // Columns between 80-150px
    ```

 ### Parameters

 - `columns`: Array of `GridItem` defining column behavior
 - `alignment`: How content aligns within cells (default: `.center`)
 - `spacing`: Gap between rows and columns in pixels (default: `nil`)
 - `pinnedViews`: Currently unused, for API compatibility

 ### Common Patterns

 1. **Equal columns**: `Array(repeating: GridItem(.flexible()), count: 3)`
 2. **Photo grid**: `[GridItem(.adaptive(minimum: 120))]`
 3. **Fixed sidebar**: `[GridItem(.fixed(200)), GridItem(.flexible())]`
 4. **Dashboard**: Mix of flexible items with minimum sizes

 ## LazyHGrid (Horizontal Grid)

 LazyHGrid creates a horizontally scrolling grid with a fixed number of rows.
 Items flow into columns automatically as needed.

 ### Row Configuration

 Same as LazyVGrid but defines rows instead of columns:
 - `.fixed(height)`: Fixed row height
 - `.flexible(minimum:maximum:)`: Flexible row height
 - `.adaptive(minimum:maximum:)`: Auto-fitting rows

 ### Parameters

 - `rows`: Array of `GridItem` defining row behavior
 - `alignment`: How content aligns within cells (default: `.center`)
 - `spacing`: Gap between rows and columns in pixels (default: `nil`)
 - `pinnedViews`: Currently unused, for API compatibility

 ## Alignment

 Grid alignment controls how content is positioned within each cell:
 - `.center` - Center both horizontally and vertically (default)
 - `.topLeading` - Align to top-left corner
 - `.top` - Align to top edge, centered horizontally
 - `.topTrailing` - Align to top-right corner
 - `.leading` - Align to left edge, centered vertically
 - `.trailing` - Align to right edge, centered vertically
 - `.bottomLeading` - Align to bottom-left corner
 - `.bottom` - Align to bottom edge, centered horizontally
 - `.bottomTrailing` - Align to bottom-right corner

 ## CSS Implementation Details

 ### LazyVGrid
 - `display: grid` - Uses CSS Grid layout
 - `grid-auto-flow: row` - Items flow into rows
 - `grid-template-columns` - Defines column structure
   - Fixed: `100px`
   - Flexible: `minmax(50px, 1fr)`
   - Adaptive: `repeat(auto-fit, minmax(80px, 1fr))`
 - `gap: 16px` - Spacing between rows and columns
 - `place-items: center center` - Aligns content within cells

 ### LazyHGrid
 - `display: grid` - Uses CSS Grid layout
 - `grid-auto-flow: column` - Items flow into columns
 - `grid-template-rows` - Defines row structure (same sizing as columns)
 - `gap: 16px` - Spacing between rows and columns
 - `place-items: center center` - Aligns content within cells

 ## Performance Considerations

 Both LazyVGrid and LazyHGrid are "lazy" in SwiftUI, meaning they create
 views on demand. In Raven's DOM implementation, all child views are
 rendered immediately, but the CSS Grid layout provides efficient
 rendering and positioning.

 ## Best Practices

 1. **Use adaptive for responsive layouts**: Let the grid adapt to screen size
 2. **Set minimum sizes**: Prevent columns/rows from becoming too small
 3. **Consider alignment**: Choose alignment based on content type
 4. **Use spacing**: Add visual breathing room between items
 5. **Combine with other layouts**: Nest grids or mix with VStack/HStack

 ## Examples of Common Use Cases

 1. **Photo Gallery**: Adaptive grid that fits photos of varying sizes
 2. **Dashboard**: Mixed column sizes for different widget types
 3. **Calendar**: Fixed 7-column grid for days of the week
 4. **Product Catalog**: Flexible columns that scale with screen size
 5. **Settings Panel**: Fixed sidebar with flexible content area
 */
