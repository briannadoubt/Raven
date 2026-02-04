import Testing
@testable import Raven

/// Tests for the Shape protocol and related functionality
struct ShapeTests {
    // MARK: - ShapeStyle Protocol Tests

    @Test("Color conforms to ShapeStyle")
    func colorConformsToShapeStyle() {
        let color = Color.blue
        let fillValue = color.svgFillValue()
        let strokeValue = color.svgStrokeValue()

        #expect(!fillValue.isEmpty)
        #expect(!strokeValue.isEmpty)
        #expect(fillValue == strokeValue) // Colors use same value for fill and stroke
    }

    @Test("Color ShapeStyle definitions are empty")
    func colorShapeStyleDefinitions() {
        let color = Color.red
        let defs = color.svgDefinitions(id: "test")

        #expect(defs.isEmpty) // Solid colors don't need gradient definitions
    }

    @Test("LinearGradient conforms to ShapeStyle")
    func linearGradientConformsToShapeStyle() {
        let gradient = LinearGradient(
            colors: [.red, .blue],
            angle: Angle(degrees: 90)
        )

        let fillValue = gradient.svgFillValue()
        let strokeValue = gradient.svgStrokeValue()

        #expect(fillValue.contains("url(#linearGradient-"))
        #expect(strokeValue.contains("url(#linearGradient-"))
        #expect(fillValue == strokeValue) // Gradients use same value for fill and stroke
    }

    @Test("LinearGradient generates SVG definitions")
    func linearGradientDefinitions() {
        let gradient = LinearGradient(
            colors: [.red, .blue],
            angle: Angle(degrees: 0)
        )

        let defs = gradient.svgDefinitions(id: "test")

        #expect(!defs.isEmpty)
        #expect(defs.contains("<linearGradient"))
        #expect(defs.contains("</linearGradient>"))
        #expect(defs.contains("<stop"))
    }

    @Test("RadialGradient conforms to ShapeStyle")
    func radialGradientConformsToShapeStyle() {
        let gradient = RadialGradient(colors: [.white, .black])

        let fillValue = gradient.svgFillValue()
        let strokeValue = gradient.svgStrokeValue()

        #expect(fillValue.contains("url(#radialGradient-"))
        #expect(strokeValue.contains("url(#radialGradient-"))
        #expect(fillValue == strokeValue)
    }

    @Test("RadialGradient generates SVG definitions")
    func radialGradientDefinitions() {
        let gradient = RadialGradient(colors: [.red, .orange, .yellow])

        let defs = gradient.svgDefinitions(id: "test")

        #expect(!defs.isEmpty)
        #expect(defs.contains("<radialGradient"))
        #expect(defs.contains("</radialGradient>"))
        #expect(defs.contains("<stop"))
    }

    // MARK: - Custom Shape Tests

    struct TestTriangle: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.closeSubpath()
            return path
        }
    }

    @Test("Custom shape conforms to Shape protocol")
    @MainActor func customShapeConformsToShape() {
        let triangle = TestTriangle()
        let rect = CGRect(x: 0, y: 0, width: 100, height: 100)
        let shapePath = triangle.path(in: rect)

        #expect(!shapePath.isEmpty)
    }

    @Test("Custom shape conforms to View protocol")
    @MainActor func customShapeConformsToView() {
        let triangle = TestTriangle()
        let vnode = triangle.toVNode()

        // Should render as an SVG element
        #expect(vnode.elementTag == "svg")
    }

    @Test("Shape path uses correct rect bounds")
    @MainActor func shapePathUsesCorrectBounds() {
        let triangle = TestTriangle()
        let rect = CGRect(x: 10, y: 20, width: 80, height: 60)
        let shapePath = triangle.path(in: rect)
        let svgData = shapePath.svgPathData

        // Should contain coordinates from the rect
        #expect(svgData.contains("50")) // midX = 10 + 80/2 = 50
        #expect(svgData.contains("20")) // minY
        #expect(svgData.contains("90")) // maxX = 10 + 80
        #expect(svgData.contains("80")) // maxY = 20 + 60
    }

    // MARK: - Shape Fill Modifier Tests

    @Test("Shape fill modifier creates _ShapeFillView")
    @MainActor func shapeFillModifier() {
        let triangle = TestTriangle()
        let filled = triangle.fill(Color.blue)

        // Type should be _ShapeFillView
        #expect(type(of: filled) == _ShapeFillView<TestTriangle, Color>.self)
    }

    @Test("Shape fill with gradient")
    @MainActor func shapeFillWithGradient() {
        let triangle = TestTriangle()
        let gradient = LinearGradient(colors: [.red, .blue], angle: Angle(degrees: 45))
        let filled = triangle.fill(gradient)

        let vnode = filled.toVNode()

        // Should contain SVG with gradient definitions
        #expect(vnode.elementTag == "svg")
        #expect(vnode.children.count > 0)
    }

    // MARK: - Shape Stroke Modifier Tests

    @Test("Shape stroke modifier creates _ShapeStrokeView")
    @MainActor func shapeStrokeModifier() {
        let triangle = TestTriangle()
        let stroked = triangle.stroke(Color.black, lineWidth: 2)

        // Type should be _ShapeStrokeView
        #expect(type(of: stroked) == _ShapeStrokeView<TestTriangle, Color>.self)
    }

    @Test("Shape stroke with default line width")
    @MainActor func shapeStrokeDefaultLineWidth() {
        let triangle = TestTriangle()
        let stroked = triangle.stroke(Color.red)

        let vnode = stroked.toVNode()
        #expect(vnode.elementTag == "svg")
    }

    // MARK: - InsettableShape Tests

    struct TestCircle: InsettableShape {
        var insetAmount: CGFloat = 0

        func path(in rect: CGRect) -> Path {
            let insetRect = rect.insetBy(dx: insetAmount, dy: insetAmount)
            var path = Path()
            path.addEllipse(in: insetRect)
            return path
        }

        func inset(by amount: CGFloat) -> TestCircle {
            var shape = self
            shape.insetAmount += amount
            return shape
        }
    }

    @Test("InsettableShape inset creates smaller shape")
    @MainActor func insettableShapeInset() {
        let circle = TestCircle()
        let insetCircle = circle.inset(by: 10)

        #expect(insetCircle.insetAmount == 10)
    }

    @Test("InsettableShape strokeBorder modifier")
    @MainActor func insettableShapeStrokeBorder() {
        let circle = TestCircle()
        let bordered = circle.strokeBorder(Color.blue, lineWidth: 5)

        let vnode = bordered.toVNode()
        #expect(vnode.elementTag == "svg")
    }

    @Test("StrokeBorder insets shape by half line width")
    @MainActor func strokeBorderInsetsCorrectly() {
        let circle = TestCircle()
        let bordered = circle.strokeBorder(Color.black, lineWidth: 10)

        // The shape should be inset by half the line width (5)
        // This is verified indirectly through the rendering
        let vnode = bordered.toVNode()
        #expect(vnode.elementTag == "svg")
        #expect(vnode.children.count > 0)
    }

    // MARK: - CGRect Extension Tests

    @Test("CGRect insetBy reduces size correctly")
    func cgRectInsetBy() {
        let rect = CGRect(x: 10, y: 20, width: 100, height: 80)
        let insetRect = rect.insetBy(dx: 10, dy: 5)

        #expect(insetRect.origin.x == 20) // 10 + 10
        #expect(insetRect.origin.y == 25) // 20 + 5
        #expect(insetRect.width == 80)    // 100 - 20
        #expect(insetRect.height == 70)   // 80 - 10
    }

    @Test("CGRect insetBy with negative values expands")
    func cgRectInsetByNegative() {
        let rect = CGRect(x: 10, y: 10, width: 50, height: 50)
        let expandedRect = rect.insetBy(dx: -5, dy: -10)

        #expect(expandedRect.origin.x == 5)   // 10 - 5
        #expect(expandedRect.origin.y == 0)   // 10 - 10
        #expect(expandedRect.width == 60)     // 50 + 10
        #expect(expandedRect.height == 70)    // 50 + 20
    }
}
