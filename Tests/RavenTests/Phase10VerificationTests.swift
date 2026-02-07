import Testing
import Foundation
@testable import Raven

/// Phase 10 Verification Tests
///
/// These integration tests verify that all Phase 10 features work together correctly:
/// - Shape protocol and 5 built-in shapes (Circle, Rectangle, RoundedRectangle, Capsule, Ellipse)
/// - Path type for custom shapes
/// - Shape modifiers (.fill, .stroke, .trim)
/// - Visual effects (.blur, .brightness, .contrast, .saturation, .grayscale, .hueRotation)
/// - .clipShape() modifier
///
/// Focus: Integration testing across features, real-world scenarios, edge cases
@MainActor
@Suite("Phase 10 Integration Tests")
struct Phase10VerificationTests {

    // MARK: - Shapes with Visual Effects

    @Test("Circle with gradient fill and blur effect")
    @MainActor func circleWithGradientAndBlur() {
        let gradient = LinearGradient(
            colors: [.blue, .purple],
            angle: Angle(degrees: 45)
        )

        let view = Circle()
            .fill(gradient)
            .blur(radius: 5)

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div") // Wrapped in div for blur
    }

    @Test("Rectangle with stroke and brightness adjustment")
    @MainActor func rectangleWithStrokeAndBrightness() {
        let view = Rectangle()
            .stroke(Color.red, lineWidth: 3)
            .brightness(1.2)

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div") // Wrapped for brightness
    }

    @Test("RoundedRectangle with fill, saturation, and contrast")
    @MainActor func roundedRectWithMultipleEffects() {
        let view = RoundedRectangle(cornerRadius: 15)
            .fill(Color.green)
            .saturation(1.5)
            .contrast(1.2)

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("Capsule with styled stroke and grayscale")
    @MainActor func capsuleWithStyledStrokeAndGrayscale() {
        let strokeStyle = StrokeStyle(
            lineWidth: 4,
            lineCap: .round,
            dash: [10, 5]
        )

        let view = Capsule()
            .stroke(Color.blue, style: strokeStyle)
            .grayscale(0.7)

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("Ellipse with radial gradient and hue rotation")
    @MainActor func ellipseWithRadialGradientAndHueRotation() {
        let gradient = RadialGradient(
            colors: [.white, .orange, .red]
        )

        let view = Ellipse()
            .fill(gradient)
            .hueRotation(Angle(degrees: 90))

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    // MARK: - ClipShape Integration

    @Test("Text clipped to circular shape")
    @MainActor func textClippedToCircle() {
        let view = Text("Clipped Content")
            .padding(20)
            .background(Color.blue)
            .clipShape(Circle())

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("Image view clipped to rounded rectangle")
    @MainActor func imageClippedToRoundedRect() {
        let view = VStack {
            Text("Profile")
        }
        .frame(width: 100, height: 100)
        .background(Color.gray)
        .clipShape(RoundedRectangle(cornerRadius: 20))

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("Multiple views clipped to capsule shape")
    @MainActor func stackClippedToCapsule() {
        let view = HStack {
            Text("Left")
            Text("Right")
        }
        .padding()
        .background(Color.green)
        .clipShape(Capsule())

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("ClipShape with custom fill style")
    @MainActor func clipShapeWithFillStyle() {
        let view = Rectangle()
            .fill(Color.red)
            .frame(width: 100, height: 100)
            .clipShape(Circle(), style: FillStyle(rule: .evenOdd))

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    // MARK: - Custom Path Shapes

    struct StarShape: Shape {
        func path(in rect: Raven.CGRect) -> Path {
            var path = Path()
            let center = Raven.CGPoint(x: rect.midX, y: rect.midY)
            let radius = min(rect.width, rect.height) / 2
            let innerRadius = radius * 0.4
            let points = 5

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

    @Test("Custom star shape with gradient fill")
    @MainActor func customStarWithGradient() {
        let gradient = LinearGradient(
            colors: [.yellow, .orange],
            angle: Angle(degrees: 135)
        )

        let view = StarShape()
            .fill(gradient)

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "svg")
    }

    @Test("Custom star shape with stroke and trim")
    @MainActor func customStarWithStrokeAndTrim() {
        let view = StarShape()
            .stroke(Color.blue, lineWidth: 3)
            .trim(from: 0.0, to: 0.7)

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "svg")
    }

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

    @Test("Custom triangle with multiple visual effects")
    @MainActor func customTriangleWithEffects() {
        let view = TriangleShape()
            .fill(Color.purple)
            .blur(radius: 2)
            .brightness(1.1)
            .saturation(1.3)

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    // MARK: - Shape Composition

    @Test("Shapes inside shapes using ZStack")
    @MainActor func shapesInsideShapes() {
        let view = ZStack {
            Circle()
                .fill(Color.blue)

            Circle()
                .fill(Color.white)
                .padding(20)

            Circle()
                .fill(Color.red)
                .padding(40)
        }
        .frame(width: 100, height: 100)

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("Overlaid shapes with different opacities")
    @MainActor func overlaidShapesWithOpacity() {
        let view = ZStack {
            Rectangle()
                .fill(Color.blue)
                .opacity(0.3)

            Circle()
                .fill(Color.red)
                .opacity(0.5)
                .padding(20)
        }

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    // MARK: - Gradients with Shapes

    @Test("Shape with linear gradient at different angles")
    @MainActor func shapeWithAngledGradients() {
        let angles: [Double] = [0, 45, 90, 135, 180, 270]

        for angleDegrees in angles {
            let gradient = LinearGradient(
                colors: [.red, .blue],
                angle: Angle(degrees: angleDegrees)
            )

            let view = Rectangle()
                .fill(gradient)

            let vnode = view.toVNode()
            #expect(vnode.elementTag == "svg")
        }
    }

    @Test("Circle with multi-stop radial gradient")
    @MainActor func circleWithMultiStopGradient() {
        let gradient = RadialGradient(
            colors: [.white, .yellow, .orange, .red, .black]
        )

        let view = Circle()
            .fill(gradient)

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "svg")
    }

    @Test("Gradient stroke on capsule")
    @MainActor func gradientStrokeOnCapsule() {
        let gradient = LinearGradient(
            colors: [.purple, .pink],
            angle: Angle(degrees: 90)
        )

        let view = Capsule()
            .stroke(gradient, lineWidth: 5)

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "svg")
    }

    // MARK: - Multiple Visual Effects

    @Test("Shape with all visual effects combined")
    @MainActor func shapeWithAllEffects() {
        let view = RoundedRectangle(cornerRadius: 10)
            .fill(Color.blue)
            .blur(radius: 1)
            .brightness(1.1)
            .contrast(1.05)
            .saturation(1.2)
            .grayscale(0.3)
            .hueRotation(Angle(degrees: 15))

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("Visual effects applied in different orders")
    @MainActor func visualEffectsInDifferentOrders() {
        // Order 1: Blur first
        let view1 = Circle()
            .fill(Color.red)
            .blur(radius: 5)
            .brightness(1.2)

        // Order 2: Brightness first
        let view2 = Circle()
            .fill(Color.red)
            .brightness(1.2)
            .blur(radius: 5)

        let vnode1 = view1.toVNode()
        let vnode2 = view2.toVNode()

        #expect(vnode1.elementTag == "div")
        #expect(vnode2.elementTag == "div")
    }

    // MARK: - Trim for Progress Indicators

    @Test("Circle trim as progress indicator")
    @MainActor func circleTrimProgress() {
        let progressValues: [Double] = [0.0, 0.25, 0.5, 0.75, 1.0]

        for progress in progressValues {
            let strokeStyle = StrokeStyle(lineWidth: 8, lineCap: .round)

            let view = Circle()
                .stroke(Color.blue, style: strokeStyle)
                .trim(from: 0.0, to: progress)

            let vnode = view.toVNode()
            #expect(vnode.elementTag == "svg")
        }
    }

    @Test("Capsule trim with gradient stroke")
    @MainActor func capsuleTrimWithGradient() {
        let gradient = LinearGradient(
            colors: [.green, .blue],
            angle: Angle(degrees: 0)
        )

        let view = Capsule()
            .stroke(gradient, lineWidth: 6)
            .trim(from: 0.1, to: 0.9)

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "svg")
    }

    // MARK: - Loading Spinner Frames

    @Test("Loading spinner animation frames using trim")
    @MainActor func loadingSpinnerFrames() {
        // Simulate different animation frames
        let frames = [
            (from: 0.0, to: 0.25),
            (from: 0.25, to: 0.5),
            (from: 0.5, to: 0.75),
            (from: 0.75, to: 1.0),
            (from: 0.0, to: 0.5)
        ]

        for (from, to) in frames {
            let strokeStyle = StrokeStyle(lineWidth: 4, lineCap: .round)

            let view = Circle()
                .stroke(Color.purple, style: strokeStyle)
                .trim(from: from, to: to)

            let vnode = view.toVNode()
            #expect(vnode.elementTag == "svg")
        }
    }

    // MARK: - Full UI Scenarios

    @Test("Profile card with clipped image and effects")
    @MainActor func profileCard() {
        let view = VStack {
            // Profile image placeholder
            Circle()
                .fill(Color.gray)
                .frame(width: 80, height: 80)
                .clipShape(Circle())
                .blur(radius: 0.5)

            Text("User Name")
                .font(.headline)

            Text("Bio goes here")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("Progress bar using trimmed capsule")
    @MainActor func progressBar() {
        let progress: Double = 0.65

        let view = ZStack(alignment: .leading) {
            // Background track
            Capsule()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 8)

            // Progress fill (simplified - trim works on shapes, not frames)
            Capsule()
                .fill(Color.blue)
                .frame(width: 200 * progress, height: 8)
        }
        .frame(width: 200, height: 8)

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("Icon button with hover-like effects")
    @MainActor func iconButton() {
        let view = Circle()
            .fill(Color.blue)
            .frame(width: 44, height: 44)
            .brightness(1.1)
            .saturation(1.2)

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("Badge with shape and effects")
    @MainActor func badge() {
        let view = Text("5")
            .foregroundColor(.white)
            .padding(8)
            .background(
                Circle()
                    .fill(Color.red)
            )
            .brightness(1.05)

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    // MARK: - Edge Cases

    @Test("Shape with zero-sized frame")
    @MainActor func shapeWithZeroFrame() {
        let view = Circle()
            .fill(Color.blue)
            .frame(width: 0, height: 0)

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("Trim with inverted from/to values")
    @MainActor func trimWithInvertedValues() {
        // to < from should still render (though might be empty)
        let view = Circle()
            .stroke(Color.blue, lineWidth: 2)
            .trim(from: 0.7, to: 0.3)

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "svg")
    }

    @Test("Visual effects with extreme values")
    @MainActor func extremeVisualEffects() {
        let view = Rectangle()
            .fill(Color.red)
            .blur(radius: 100)
            .brightness(5.0)
            .contrast(10.0)
            .saturation(0.0)

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("Nested clip shapes")
    @MainActor func nestedClipShapes() {
        let view = Rectangle()
            .fill(Color.blue)
            .frame(width: 100, height: 100)
            .clipShape(Circle())
            .clipShape(RoundedRectangle(cornerRadius: 10))

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("Shape with InsettableShape strokeBorder")
    @MainActor func insettableShapeStrokeBorder() {
        let view = RoundedRectangle(cornerRadius: 10)
            .strokeBorder(Color.blue, lineWidth: 4)
            .frame(width: 100, height: 100)

        let vnode = view.toVNode()
        // Frame wraps the SVG in a div
        #expect(vnode.elementTag == "div")
    }

    @Test("Complex path with transformations")
    @MainActor func complexPathWithTransformations() {
        var path = Path()
        path.addRect(CGRect(x: 0, y: 0, width: 50, height: 50))

        let transform = Raven.CGAffineTransform(scaleX: 2, y: 2)

        let transformedPath = path.applying(transform)

        #expect(!transformedPath.isEmpty)
    }

    // MARK: - Phase 9 + Phase 10 Integration

    @Test("Shapes with Phase 9 interaction modifiers")
    @MainActor func shapesWithInteractionModifiers() {
        let view = Circle()
            .fill(Color.blue)
            .frame(width: 50, height: 50)
            .onTapGesture {
                // Tap handler
            }
            .disabled(false)

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("ClipShape with text layout modifiers")
    @MainActor func clipShapeWithTextModifiers() {
        let view = Text("This is a long text that might be truncated")
            .lineLimit(1)
            .truncationMode(.tail)
            .padding()
            .background(Color.yellow)
            .clipShape(RoundedRectangle(cornerRadius: 8))

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }

    @Test("Shape with fixed size and aspect ratio")
    @MainActor func shapeWithLayoutModifiers() {
        let view = Circle()
            .fill(Color.green)
            .aspectRatio(1.0, contentMode: .fit)
            .fixedSize()

        let vnode = view.toVNode()
        #expect(vnode.elementTag == "div")
    }
}
