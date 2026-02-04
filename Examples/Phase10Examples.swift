import Raven

// MARK: - Phase 10 Examples: Shapes, Paths, and Visual Effects

/// This file demonstrates real-world usage of Phase 10 features:
/// - Shape protocol and 5 built-in shapes (Circle, Rectangle, RoundedRectangle, Capsule, Ellipse)
/// - Path type for custom shapes
/// - Shape modifiers (.fill, .stroke, .trim)
/// - Visual effects (.blur, .brightness, .contrast, .saturation, .grayscale, .hueRotation)
/// - .clipShape() modifier for clipping content to shapes

// MARK: - Example 1: Shape Gallery

/// A gallery showcasing all 5 built-in shapes with different styles
struct ShapeGalleryView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Shape Gallery")
                .font(.title)

            HStack(spacing: 15) {
                // Circle
                Circle()
                    .fill(Color.blue)
                    .frame(width: 60, height: 60)

                // Rectangle
                Rectangle()
                    .fill(Color.red)
                    .frame(width: 60, height: 60)

                // RoundedRectangle
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.green)
                    .frame(width: 60, height: 60)

                // Capsule
                Capsule()
                    .fill(Color.orange)
                    .frame(width: 60, height: 40)

                // Ellipse
                Ellipse()
                    .fill(Color.purple)
                    .frame(width: 80, height: 50)
            }

            // Shapes with gradients
            HStack(spacing: 15) {
                Circle()
                    .fill(LinearGradient(
                        colors: [.blue, .purple],
                        angle: Angle(degrees: 45)
                    ))
                    .frame(width: 60, height: 60)

                RoundedRectangle(cornerRadius: 12)
                    .fill(RadialGradient(
                        colors: [.white, .orange, .red]
                    ))
                    .frame(width: 60, height: 60)
            }

            // Shapes with strokes
            HStack(spacing: 15) {
                Circle()
                    .stroke(Color.blue, lineWidth: 3)
                    .frame(width: 60, height: 60)

                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.green, lineWidth: 2)
                    .frame(width: 60, height: 60)

                Capsule()
                    .strokeBorder(Color.orange, lineWidth: 4)
                    .frame(width: 80, height: 40)
            }
        }
        .padding()
    }
}

// MARK: - Example 2: Custom Path Shapes

/// Custom star shape using Path
struct StarShape: Shape {
    var points: Int = 5
    var innerRadiusRatio: Double = 0.4

    func path(in rect: Raven.CGRect) -> Path {
        var path = Path()
        let center = Raven.CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let innerRadius = radius * innerRadiusRatio

        for i in 0..<points * 2 {
            let angle = (Double(i) * .pi / Double(points)) - .pi / 2
            let r = i % 2 == 0 ? radius : innerRadius
            let x = center.x + r * cos(angle)
            let y = center.y + r * sin(angle)

            if i == 0 {
                path.move(to: Raven.CGPoint(x: x, y: y))
            } else {
                path.addLine(to: Raven.CGPoint(x: x, y: y))
            }
        }
        path.closeSubpath()
        return path
    }
}

/// Custom triangle shape
struct TriangleShape: Shape {
    func path(in rect: Raven.CGRect) -> Path {
        var path = Path()
        path.move(to: Raven.CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: Raven.CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: Raven.CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// Custom heart shape
struct HeartShape: Shape {
    func path(in rect: Raven.CGRect) -> Path {
        var path = Path()

        let width = rect.width
        let height = rect.height

        // Top curves
        path.move(to: Raven.CGPoint(x: width / 2, y: height * 0.3))

        // Right curve
        path.addCurve(
            to: Raven.CGPoint(x: width, y: height * 0.25),
            control1: Raven.CGPoint(x: width / 2, y: height * 0.1),
            control2: Raven.CGPoint(x: width * 0.75, y: height * 0.05)
        )

        path.addCurve(
            to: Raven.CGPoint(x: width / 2, y: height),
            control1: Raven.CGPoint(x: width, y: height * 0.5),
            control2: Raven.CGPoint(x: width / 2, y: height * 0.75)
        )

        // Left curve
        path.addCurve(
            to: Raven.CGPoint(x: 0, y: height * 0.25),
            control1: Raven.CGPoint(x: width / 2, y: height * 0.75),
            control2: Raven.CGPoint(x: 0, y: height * 0.5)
        )

        path.addCurve(
            to: Raven.CGPoint(x: width / 2, y: height * 0.3),
            control1: Raven.CGPoint(x: width * 0.25, y: height * 0.05),
            control2: Raven.CGPoint(x: width / 2, y: height * 0.1)
        )

        return path
    }
}

/// Showcase of custom path shapes
struct CustomShapesView: View {
    var body: some View {
        VStack(spacing: 30) {
            Text("Custom Path Shapes")
                .font(.title)

            HStack(spacing: 20) {
                // Star with gradient fill
                StarShape()
                    .fill(LinearGradient(
                        colors: [.yellow, .orange],
                        angle: Angle(degrees: 135)
                    ))
                    .frame(width: 80, height: 80)

                // Triangle with solid fill
                TriangleShape()
                    .fill(Color.green)
                    .frame(width: 70, height: 70)

                // Heart with stroke
                HeartShape()
                    .stroke(Color.red, lineWidth: 3)
                    .frame(width: 70, height: 70)
            }

            HStack(spacing: 20) {
                // Star with stroke
                StarShape(points: 6)
                    .stroke(Color.purple, lineWidth: 2)
                    .frame(width: 80, height: 80)

                // Triangle with gradient stroke
                TriangleShape()
                    .stroke(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            angle: Angle(degrees: 90)
                        ),
                        lineWidth: 4
                    )
                    .frame(width: 70, height: 70)

                // Heart filled
                HeartShape()
                    .fill(Color.red)
                    .frame(width: 70, height: 70)
            }
        }
        .padding()
    }
}

// MARK: - Example 3: Visual Effects Showcase

/// Demonstrates all visual effects with before/after comparisons
struct VisualEffectsShowcaseView: View {
    var body: some View {
        VStack(spacing: 25) {
            Text("Visual Effects Showcase")
                .font(.title)

            // Blur effect
            HStack(spacing: 20) {
                VStack {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 60, height: 60)
                    Text("Normal")
                        .font(.caption)
                }

                VStack {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 60, height: 60)
                        .blur(radius: 5)
                    Text("Blur")
                        .font(.caption)
                }
            }

            // Brightness effect
            HStack(spacing: 20) {
                VStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.orange)
                        .frame(width: 60, height: 60)
                    Text("Normal")
                        .font(.caption)
                }

                VStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.orange)
                        .frame(width: 60, height: 60)
                        .brightness(1.5)
                    Text("Bright")
                        .font(.caption)
                }

                VStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.orange)
                        .frame(width: 60, height: 60)
                        .brightness(0.5)
                    Text("Dark")
                        .font(.caption)
                }
            }

            // Saturation effect
            HStack(spacing: 20) {
                VStack {
                    Capsule()
                        .fill(Color.red)
                        .frame(width: 80, height: 40)
                    Text("Normal")
                        .font(.caption)
                }

                VStack {
                    Capsule()
                        .fill(Color.red)
                        .frame(width: 80, height: 40)
                        .saturation(2.0)
                    Text("Vibrant")
                        .font(.caption)
                }

                VStack {
                    Capsule()
                        .fill(Color.red)
                        .frame(width: 80, height: 40)
                        .saturation(0.0)
                    Text("Grayscale")
                        .font(.caption)
                }
            }

            // Grayscale effect
            HStack(spacing: 20) {
                VStack {
                    Circle()
                        .fill(Color.purple)
                        .frame(width: 60, height: 60)
                    Text("Color")
                        .font(.caption)
                }

                VStack {
                    Circle()
                        .fill(Color.purple)
                        .frame(width: 60, height: 60)
                        .grayscale(0.5)
                    Text("50% Gray")
                        .font(.caption)
                }

                VStack {
                    Circle()
                        .fill(Color.purple)
                        .frame(width: 60, height: 60)
                        .grayscale(1.0)
                    Text("Full Gray")
                        .font(.caption)
                }
            }

            // Hue rotation effect
            HStack(spacing: 20) {
                VStack {
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: 60, height: 60)
                    Text("0°")
                        .font(.caption)
                }

                VStack {
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: 60, height: 60)
                        .hueRotation(Angle(degrees: 90))
                    Text("90°")
                        .font(.caption)
                }

                VStack {
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: 60, height: 60)
                        .hueRotation(Angle(degrees: 180))
                    Text("180°")
                        .font(.caption)
                }
            }
        }
        .padding()
    }
}

// MARK: - Example 4: Clipping Demonstrations

/// Demonstrates .clipShape() for creating masked content
struct ClippingDemonstrationView: View {
    var body: some View {
        VStack(spacing: 30) {
            Text("ClipShape Examples")
                .font(.title)

            // Circular profile image placeholder
            VStack {
                Text("Profile Photo")
                    .frame(width: 100, height: 100)
                    .background(Color.gray)
                    .clipShape(Circle())

                Text("Circular Avatar")
                    .font(.caption)
            }

            // Rounded rectangle content card
            VStack(alignment: .leading, spacing: 10) {
                Text("Card Title")
                    .font(.headline)
                Text("This is a content card with rounded corners achieved using clipShape.")
                    .font(.body)
            }
            .padding()
            .background(Color.blue.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 15))

            // Capsule button
            Text("Capsule Button")
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.green)
                .foregroundColor(.white)
                .clipShape(Capsule())

            // Complex clipping with gradient background
            HStack(spacing: 10) {
                Text("Tag 1")
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        LinearGradient(
                            colors: [.blue, .purple],
                            angle: Angle(degrees: 45)
                        )
                    )
                    .foregroundColor(.white)
                    .clipShape(Capsule())

                Text("Tag 2")
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        LinearGradient(
                            colors: [.orange, .red],
                            angle: Angle(degrees: 45)
                        )
                    )
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
        }
        .padding()
    }
}

// MARK: - Example 5: Progress Indicators

/// Progress bars and loading indicators using .trim()
struct ProgressIndicatorsView: View {
    var body: some View {
        VStack(spacing: 30) {
            Text("Progress Indicators")
                .font(.title)

            // Linear progress bar
            VStack(alignment: .leading, spacing: 8) {
                Text("Download Progress: 65%")
                    .font(.caption)

                ZStack(alignment: .leading) {
                    // Background track
                    Capsule()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 8)

                    // Progress fill
                    Capsule()
                        .fill(Color.blue)
                        .frame(width: 200 * 0.65, height: 8)
                }
                .frame(width: 200)
            }

            // Circular progress indicator
            VStack(spacing: 8) {
                Text("Loading: 75%")
                    .font(.caption)

                ZStack {
                    // Background circle
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                        .frame(width: 80, height: 80)

                    // Progress arc
                    Circle()
                        .stroke(
                            Color.green,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .trim(from: 0.0, to: 0.75)
                        .frame(width: 80, height: 80)
                }
            }

            // Multiple progress rings
            HStack(spacing: 20) {
                ForEach([0.3, 0.5, 0.8], id: \.self) { progress in
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 6)

                        Circle()
                            .stroke(
                                Color.purple,
                                style: StrokeStyle(lineWidth: 6, lineCap: .round)
                            )
                            .trim(from: 0.0, to: progress)
                    }
                    .frame(width: 60, height: 60)
                }
            }

            // Gradient progress
            VStack(spacing: 8) {
                Text("Gradient Progress: 50%")
                    .font(.caption)

                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [.blue, .purple],
                            angle: Angle(degrees: 90)
                        ),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .trim(from: 0.0, to: 0.5)
                    .frame(width: 80, height: 80)
            }
        }
        .padding()
    }
}

// MARK: - Example 6: Loading Spinners

/// Animated loading spinners (static frames)
struct LoadingSpinnersView: View {
    var body: some View {
        VStack(spacing: 30) {
            Text("Loading Spinner Frames")
                .font(.title)
            Text("(Each shows a different animation frame)")
                .font(.caption)
                .foregroundColor(.gray)

            // Simple spinner frames
            HStack(spacing: 20) {
                // Frame 1: 0-25%
                Circle()
                    .stroke(
                        Color.blue,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .trim(from: 0.0, to: 0.25)
                    .frame(width: 40, height: 40)

                // Frame 2: 25-50%
                Circle()
                    .stroke(
                        Color.blue,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .trim(from: 0.25, to: 0.5)
                    .frame(width: 40, height: 40)

                // Frame 3: 50-75%
                Circle()
                    .stroke(
                        Color.blue,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .trim(from: 0.5, to: 0.75)
                    .frame(width: 40, height: 40)

                // Frame 4: 75-100%
                Circle()
                    .stroke(
                        Color.blue,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .trim(from: 0.75, to: 1.0)
                    .frame(width: 40, height: 40)
            }

            // Gradient spinner frames
            HStack(spacing: 20) {
                ForEach([0.0, 0.2, 0.4, 0.6, 0.8], id: \.self) { offset in
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [.purple, .pink],
                                angle: Angle(degrees: 90)
                            ),
                            style: StrokeStyle(lineWidth: 5, lineCap: .round)
                        )
                        .trim(from: offset, to: offset + 0.3)
                        .frame(width: 35, height: 35)
                }
            }

            // Dashed spinner
            Circle()
                .stroke(
                    Color.orange,
                    style: StrokeStyle(
                        lineWidth: 6,
                        lineCap: .round,
                        dash: [2, 4]
                    )
                )
                .trim(from: 0.0, to: 0.7)
                .frame(width: 60, height: 60)
        }
        .padding()
    }
}

// MARK: - Example 7: Shape Composition

/// Complex shapes built from multiple shapes
struct ShapeCompositionView: View {
    var body: some View {
        VStack(spacing: 30) {
            Text("Shape Composition")
                .font(.title)

            // Concentric circles
            ZStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 100, height: 100)

                Circle()
                    .fill(Color.white)
                    .frame(width: 70, height: 70)

                Circle()
                    .fill(Color.blue)
                    .frame(width: 40, height: 40)
            }

            // Target/bullseye
            ZStack {
                Circle()
                    .fill(Color.red)
                    .frame(width: 100, height: 100)

                Circle()
                    .fill(Color.white)
                    .frame(width: 80, height: 80)

                Circle()
                    .fill(Color.red)
                    .frame(width: 60, height: 60)

                Circle()
                    .fill(Color.white)
                    .frame(width: 40, height: 40)

                Circle()
                    .fill(Color.red)
                    .frame(width: 20, height: 20)
            }

            // Overlapping shapes with opacity
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.5))
                    .frame(width: 60, height: 60)
                    .offset(x: -15, y: 0)

                Circle()
                    .fill(Color.green.opacity(0.5))
                    .frame(width: 60, height: 60)
                    .offset(x: 15, y: 0)

                Circle()
                    .fill(Color.blue.opacity(0.5))
                    .frame(width: 60, height: 60)
                    .offset(x: 0, y: -15)
            }

            // Shape with border using stroke
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .frame(width: 100, height: 80)

                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue, lineWidth: 3)
                    .frame(width: 100, height: 80)
            }
        }
        .padding()
    }
}

// MARK: - Example 8: Real-World UI Components

/// Practical UI components using Phase 10 features
struct UIComponentsView: View {
    var body: some View {
        VStack(spacing: 25) {
            Text("Real-World UI Components")
                .font(.title)

            // Profile avatar with status indicator
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(Color.gray)
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())

                Circle()
                    .fill(Color.green)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
                    .offset(x: -5, y: -5)
            }

            // Icon badge
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.blue)
                    .frame(width: 60, height: 60)

                Circle()
                    .fill(Color.red)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Text("3")
                            .font(.caption2)
                            .foregroundColor(.white)
                    )
                    .offset(x: 5, y: -5)
            }

            // Chip/Tag component
            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text("Active")
                        .font(.caption)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.green.opacity(0.2))
                .clipShape(Capsule())

                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 8, height: 8)
                    Text("Pending")
                        .font(.caption)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.orange.opacity(0.2))
                .clipShape(Capsule())
            }

            // Segmented control style
            HStack(spacing: 0) {
                Text("Day")
                    .frame(width: 60, height: 30)
                    .background(Color.blue)
                    .foregroundColor(.white)

                Text("Week")
                    .frame(width: 60, height: 30)
                    .background(Color.gray.opacity(0.2))

                Text("Month")
                    .frame(width: 60, height: 30)
                    .background(Color.gray.opacity(0.2))
            }
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.gray, lineWidth: 1)
            )

            // Rating stars
            HStack(spacing: 4) {
                ForEach(0..<5) { _ in
                    StarShape()
                        .fill(Color.yellow)
                        .frame(width: 20, height: 20)
                }
            }
        }
        .padding()
    }
}

// MARK: - Main Demo View

/// Combined demo of all Phase 10 examples
struct Phase10DemoView: View {
    var body: some View {
        VStack(spacing: 40) {
            Text("Phase 10: Shapes & Visual Effects")
                .font(.title)
                .fontWeight(.bold)

            ScrollView {
                VStack(spacing: 50) {
                    ShapeGalleryView()
                    Divider()

                    CustomShapesView()
                    Divider()

                    VisualEffectsShowcaseView()
                    Divider()

                    ClippingDemonstrationView()
                    Divider()

                    ProgressIndicatorsView()
                    Divider()

                    LoadingSpinnersView()
                    Divider()

                    ShapeCompositionView()
                    Divider()

                    UIComponentsView()
                }
            }
        }
        .padding()
    }
}
