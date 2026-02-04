import Foundation
import Raven

/// Example demonstrating containerRelativeFrame() usage in Raven.
///
/// ContainerRelativeFrame is a modern iOS 17+ modifier that provides a cleaner
/// alternative to GeometryReader for responsive layouts. It sizes views relative
/// to their container using CSS container queries.

// MARK: - Basic Usage

/// Simple example showing percentage-based sizing
struct BasicContainerRelativeExample: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("80% Width Example")

            // Modern approach with containerRelativeFrame
            Color.blue
                .containerRelativeFrame(.horizontal) { width, _ in
                    width * 0.8
                }
                .frame(height: 100)
        }
        .padding()
    }
}

// MARK: - Grid-Based Layout

/// Example showing grid-based sizing without explicit calculations
struct GridLayoutExample: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("3-Column Grid")

            HStack(spacing: 10) {
                Color.red
                    .containerRelativeFrame(.horizontal, count: 3, spacing: 10)
                    .frame(height: 100)

                Color.green
                    .containerRelativeFrame(.horizontal, count: 3, spacing: 10)
                    .frame(height: 100)

                Color.blue
                    .containerRelativeFrame(.horizontal, count: 3, spacing: 10)
                    .frame(height: 100)
            }
        }
        .padding()
    }
}

// MARK: - Spanning Multiple Grid Cells

/// Example showing how to span multiple grid cells
struct SpanningGridExample: View {
    var body: some View {
        VStack(spacing: 10) {
            Text("Asymmetric Grid Layout")

            VStack(spacing: 10) {
                // Header spans 2 of 2 columns (full width)
                Color.purple
                    .containerRelativeFrame(.horizontal, count: 2, span: 2, spacing: 10)
                    .frame(height: 60)

                // Two columns side by side
                HStack(spacing: 10) {
                    Color.red
                        .containerRelativeFrame(.horizontal, count: 2, spacing: 10)
                        .frame(height: 100)

                    Color.blue
                        .containerRelativeFrame(.horizontal, count: 2, spacing: 10)
                        .frame(height: 100)
                }

                // Footer spans full width
                Color.green
                    .containerRelativeFrame(.horizontal, count: 2, span: 2, spacing: 10)
                    .frame(height: 60)
            }
        }
        .padding()
    }
}

// MARK: - Photo Grid

/// Example showing a responsive photo grid
struct PhotoGridExample: View {
    let photos = ["Photo 1", "Photo 2", "Photo 3", "Photo 4", "Photo 5", "Photo 6"]

    var body: some View {
        VStack(spacing: 20) {
            Text("Photo Grid (3 columns)")

            VStack(spacing: 8) {
                ForEach(0..<2) { row in
                    HStack(spacing: 8) {
                        ForEach(0..<3) { col in
                            let index = row * 3 + col
                            if index < photos.count {
                                VStack {
                                    Color.gray
                                        .containerRelativeFrame(.horizontal, count: 3, spacing: 8)
                                        .aspectRatio(1, contentMode: .fill)

                                    Text(photos[index])
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding()
    }
}

// MARK: - Both Axes

/// Example using containerRelativeFrame on both axes
struct BothAxesExample: View {
    var body: some View {
        VStack {
            Text("Centered Square (50% of container)")

            Color.orange
                .containerRelativeFrame([.horizontal, .vertical]) { size, axis in
                    size * 0.5
                }
        }
        .frame(width: 400, height: 400)
        .padding()
    }
}

// MARK: - Alignment Control

/// Example demonstrating alignment within the container
struct AlignmentExample: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Alignment Examples")

            // Leading alignment
            Color.red
                .containerRelativeFrame(.horizontal, alignment: .leading) { w, _ in w * 0.6 }
                .frame(height: 60)

            // Center alignment (default)
            Color.green
                .containerRelativeFrame(.horizontal, alignment: .center) { w, _ in w * 0.6 }
                .frame(height: 60)

            // Trailing alignment
            Color.blue
                .containerRelativeFrame(.horizontal, alignment: .trailing) { w, _ in w * 0.6 }
                .frame(height: 60)
        }
        .padding()
    }
}

// MARK: - Migration from GeometryReader

/// Example showing migration from GeometryReader to containerRelativeFrame
struct MigrationExample: View {
    var body: some View {
        VStack(spacing: 30) {
            Text("Before: Using GeometryReader")

            // Old way with GeometryReader
            GeometryReader { geometry in
                Color.blue
                    .frame(width: geometry.size.width * 0.8)
                    .frame(height: 100)
            }
            .frame(height: 100)

            Text("After: Using containerRelativeFrame")

            // New way with containerRelativeFrame
            Color.blue
                .containerRelativeFrame(.horizontal) { width, _ in
                    width * 0.8
                }
                .frame(height: 100)
        }
        .padding()
    }
}

// MARK: - Responsive Card Layout

/// Example showing a responsive card layout
struct ResponsiveCardExample: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Responsive Cards")

            // Card takes 90% width on mobile, 70% on wider screens
            VStack(spacing: 12) {
                Text("Card Title")

                Text("Card content goes here. This card automatically sizes itself relative to the container.")

                HStack {
                    Button("Action 1") { }
                    Button("Action 2") { }
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .containerRelativeFrame(.horizontal) { width, _ in
                // In a real app, you might adjust based on actual width
                width * 0.9
            }
        }
        .padding()
    }
}

// MARK: - Dashboard Layout

/// Example showing a dashboard with different sized widgets
struct DashboardExample: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Dashboard Layout")

            // Top row: 2 equal widgets
            HStack(spacing: 16) {
                WidgetView(title: "Widget 1", color: .blue)
                    .containerRelativeFrame(.horizontal, count: 2, spacing: 16)

                WidgetView(title: "Widget 2", color: .green)
                    .containerRelativeFrame(.horizontal, count: 2, spacing: 16)
            }

            // Middle row: 1 full-width widget
            WidgetView(title: "Widget 3", color: .purple)
                .containerRelativeFrame(.horizontal, count: 1)

            // Bottom row: 3 equal widgets
            HStack(spacing: 16) {
                WidgetView(title: "Widget 4", color: .red)
                    .containerRelativeFrame(.horizontal, count: 3, spacing: 16)

                WidgetView(title: "Widget 5", color: .orange)
                    .containerRelativeFrame(.horizontal, count: 3, spacing: 16)

                WidgetView(title: "Widget 6", color: .cyan)
                    .containerRelativeFrame(.horizontal, count: 3, spacing: 16)
            }
        }
        .padding()
    }
}

/// Helper view for dashboard widgets
struct WidgetView: View {
    let title: String
    let color: Color

    var body: some View {
        VStack {
            Text(title)
                .padding()
        }
        .frame(height: 100)
        .background(color.opacity(0.3))
    }
}

// MARK: - Usage Notes

/*
 ContainerRelativeFrame Usage Notes:

 1. Modern Alternative to GeometryReader:
    - Cleaner syntax for common responsive layout patterns
    - Better performance using CSS container queries
    - Available in iOS 17+ (Raven supports it via CSS)

 2. Two Main Approaches:

    a) Closure-based sizing:
       .containerRelativeFrame(.horizontal) { width, _ in
           width * 0.8
       }

    b) Grid-based sizing:
       .containerRelativeFrame(.horizontal, count: 3, spacing: 10)

 3. Axes:
    - .horizontal: Size relative to container width
    - .vertical: Size relative to container height
    - [.horizontal, .vertical]: Size relative to both

 4. Alignment:
    - .leading, .center (default), .trailing for horizontal
    - .top, .center (default), .bottom for vertical
    - Combine: .topLeading, .bottomTrailing, etc.

 5. Grid Sizing:
    - count: Number of grid cells
    - span: Number of cells this view occupies (default 1)
    - spacing: Gap between cells in pixels

 6. Web Implementation:
    - Uses CSS container queries (container-type: size)
    - Container query units: cqw (width), cqh (height)
    - calc() expressions for grid calculations
    - Formula: (100cqw - spacing*(count-1)) / count * span

 7. Performance:
    - More efficient than GeometryReader for simple cases
    - Layout calculated by browser's CSS engine
    - No Swift-side geometry calculations needed

 8. Browser Support:
    - Container queries: Chrome 105+, Safari 16+, Firefox 110+
    - Gracefully degrades in older browsers

 9. When to Use:
    - Percentage-based sizing
    - Grid layouts with equal-sized items
    - Responsive cards and widgets
    - Dashboard layouts

 10. When to Use GeometryReader Instead:
     - Need actual size values in Swift code
     - Complex calculations based on geometry
     - Dynamic behavior based on size
     - Coordinate space transformations

 11. Migration Tips:
     - Simple percentage sizing: switch to containerRelativeFrame
     - Equal-sized grids: use count/span parameters
     - Complex logic: stick with GeometryReader for now

 Example Comparison:

 // GeometryReader approach (before)
 GeometryReader { geometry in
     Color.blue
         .frame(width: geometry.size.width * 0.8)
 }

 // containerRelativeFrame approach (after)
 Color.blue
     .containerRelativeFrame(.horizontal) { w, _ in w * 0.8 }
 */
