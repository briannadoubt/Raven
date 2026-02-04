import Foundation
import Raven

/// Example demonstrating GeometryReader usage in Raven.
///
/// GeometryReader provides access to size and coordinate space information,
/// allowing views to adapt their appearance based on the container's geometry.

// MARK: - Basic Usage

/// Simple example showing how to access size information
struct BasicGeometryExample: View {
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 10) {
                Text("Container Size")
                    .padding()

                Text("Width: \(geometry.size.width)")
                Text("Height: \(geometry.size.height)")
            }
            .padding()
        }
        .frame(width: 300, height: 200)
    }
}

// MARK: - Adaptive Layout

/// Example showing adaptive layout based on available space
struct AdaptiveLayoutExample: View {
    var body: some View {
        GeometryReader { geometry in
            let isWide = geometry.size.width > geometry.size.height

            if isWide {
                // Horizontal layout for wide containers
                HStack(spacing: 20) {
                    ColorBox(color: .blue)
                    ColorBox(color: .green)
                    ColorBox(color: .red)
                }
            } else {
                // Vertical layout for narrow containers
                VStack(spacing: 20) {
                    ColorBox(color: .blue)
                    ColorBox(color: .green)
                    ColorBox(color: .red)
                }
            }
        }
    }
}

/// Helper view for the adaptive layout example
struct ColorBox: View {
    let color: Color

    var body: some View {
        color
            .frame(width: 100, height: 100)
    }
}

// MARK: - Coordinate Spaces

/// Example demonstrating coordinate space queries
struct CoordinateSpaceExample: View {
    var body: some View {
        GeometryReader { geometry in
            let localFrame = geometry.frame(in: .local)
            let globalFrame = geometry.frame(in: .global)

            VStack(alignment: .leading, spacing: 8) {
                Text("Local Coordinates")
                    .padding(.bottom, 4)

                Text("Origin: (\(localFrame.minX), \(localFrame.minY))")
                Text("Size: \(localFrame.width) x \(localFrame.height)")

                Text("Global Coordinates")
                    .padding(.top, 12)
                    .padding(.bottom, 4)

                Text("Position: (\(globalFrame.minX), \(globalFrame.minY))")
                Text("Size: \(globalFrame.width) x \(globalFrame.height)")
            }
            .padding()
        }
        .frame(width: 400, height: 300)
    }
}

// MARK: - Percentage-based Sizing

/// Example showing how to size child views as a percentage of the container
struct PercentageBasedSizingExample: View {
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Header - 20% of height
                Color.blue
                    .frame(
                        width: geometry.size.width,
                        height: geometry.size.height * 0.2
                    )

                // Content - 60% of height
                Color.green
                    .frame(
                        width: geometry.size.width,
                        height: geometry.size.height * 0.6
                    )

                // Footer - 20% of height
                Color.red
                    .frame(
                        width: geometry.size.width,
                        height: geometry.size.height * 0.2
                    )
            }
        }
        .frame(width: 300, height: 400)
    }
}

// MARK: - Centered Content

/// Example showing how to center content at specific coordinates
struct CenteredContentExample: View {
    var body: some View {
        GeometryReader { geometry in
            VStack {
                Text("Centered in Container")
                    .padding()
                    .foregroundColor(.white)
            }
            .background(Color.blue)
            .frame(
                width: geometry.size.width * 0.6,
                height: geometry.size.height * 0.4
            )
        }
        .frame(width: 500, height: 300)
    }
}

// MARK: - Aspect Ratio Preservation

/// Example showing how to maintain aspect ratio while filling available space
struct AspectRatioExample: View {
    var body: some View {
        GeometryReader { geometry in
            let aspectRatio = 16.0 / 9.0
            let width = geometry.size.width
            let height = geometry.size.height

            // Calculate dimensions that fit and maintain aspect ratio
            let fitWidth = min(width, height * aspectRatio)
            let fitHeight = fitWidth / aspectRatio

            Color.purple
                .frame(width: fitWidth, height: fitHeight)
        }
        .frame(width: 600, height: 400)
    }
}

// MARK: - Safe Area Example

/// Example demonstrating safe area insets (placeholder for now)
struct SafeAreaExample: View {
    var body: some View {
        GeometryReader { geometry in
            let safeArea = geometry.safeAreaInsets

            VStack(alignment: .leading, spacing: 8) {
                Text("Safe Area Insets")
                    .padding(.bottom, 4)

                Text("Top: \(safeArea.top)")
                Text("Leading: \(safeArea.leading)")
                Text("Bottom: \(safeArea.bottom)")
                Text("Trailing: \(safeArea.trailing)")

                Text("Note: Safe area integration is a future enhancement")
                    .padding(.top, 12)
            }
            .padding()
        }
    }
}

// MARK: - Usage Notes

/*
 GeometryReader Usage Notes:

 1. GeometryReader expands to fill all available space in its parent container.
    Use .frame() to constrain it if needed.

 2. The geometry proxy provides:
    - size: The container's width and height
    - frame(in:): Position and bounds in different coordinate spaces
    - safeAreaInsets: Safe area insets (placeholder implementation)

 3. Coordinate spaces:
    - .local: Relative to the GeometryReader itself (origin at 0, 0)
    - .global: Relative to the window/viewport
    - .named: Named coordinate spaces (future enhancement)

 4. Performance considerations:
    - GeometryReader re-renders when the geometry changes
    - Use sparingly and only when layout needs geometric information
    - Prefer static layouts when possible

 5. Future enhancements:
    - Dynamic measurement updates when the DOM element is resized
    - Integration with ResizeObserver API for responsive updates
    - Named coordinate space tracking
    - Actual safe area insets from browser viewport
 */
