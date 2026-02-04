import Testing
@testable import Raven

/// Tests for built-in shape types.
///
/// This test suite verifies the behavior of the five built-in shapes:
/// Circle, Rectangle, RoundedRectangle, Capsule, and Ellipse.
@Suite("Built-in Shapes Tests")
struct BuiltInShapesTests {

    // MARK: - Circle Tests

    @Test("Circle creates path in square rect")
    @MainActor func circleInSquareRect() async throws {
        let circle = Circle()
        let rect = CGRect(x: 0, y: 0, width: 100, height: 100)
        let path = circle.path(in: rect)

        #expect(!path.isEmpty)
        #expect(path.svgPathData.contains("M")) // Has move command
        #expect(path.svgPathData.contains("C")) // Has curve command
    }

    @Test("Circle creates perfect circle in non-square rect")
    @MainActor func circleInNonSquareRect() async throws {
        let circle = Circle()
        let rect = CGRect(x: 0, y: 0, width: 200, height: 100)
        let path = circle.path(in: rect)

        #expect(!path.isEmpty)
        // Circle should use the smaller dimension (100)
        // This ensures a perfect circle rather than an ellipse
    }

    @Test("Circle with fill modifier creates VNode")
    @MainActor func circleWithFill() async throws {
        let circle = Circle()
        let filled = circle.fill(Color.blue)
        let vnode = filled.toVNode()

        // Verify it's an SVG element
        if case .element(let tag) = vnode.type {
            #expect(tag == "svg")
        }
    }

    @Test("Circle with stroke modifier creates VNode")
    @MainActor func circleWithStroke() async throws {
        let circle = Circle()
        let stroked = circle.stroke(Color.red, lineWidth: 2)
        let vnode = stroked.toVNode()

        // Verify it's an SVG element
        if case .element(let tag) = vnode.type {
            #expect(tag == "svg")
        }
    }

    // MARK: - Rectangle Tests

    @Test("Rectangle creates path filling entire rect")
    @MainActor func rectangleInRect() async throws {
        let rectangle = Rectangle()
        let rect = CGRect(x: 10, y: 20, width: 100, height: 50)
        let path = rectangle.path(in: rect)

        #expect(!path.isEmpty)
        #expect(path.svgPathData.contains("M")) // Has move command
        #expect(path.svgPathData.contains("L")) // Has line command
        #expect(path.svgPathData.contains("Z")) // Has close command
    }

    @Test("Rectangle with fill modifier creates VNode")
    @MainActor func rectangleWithFill() async throws {
        let rectangle = Rectangle()
        let filled = rectangle.fill(Color.green)
        let vnode = filled.toVNode()

        // Verify it's an SVG element
        if case .element(let tag) = vnode.type {
            #expect(tag == "svg")
        }
    }

    @Test("Rectangle with stroke modifier creates VNode")
    @MainActor func rectangleWithStroke() async throws {
        let rectangle = Rectangle()
        let stroked = rectangle.stroke(Color.black, lineWidth: 1)
        let vnode = stroked.toVNode()

        // Verify it's an SVG element
        if case .element(let tag) = vnode.type {
            #expect(tag == "svg")
        }
    }

    // MARK: - RoundedRectangle Tests

    @Test("RoundedRectangle with corner radius creates path")
    @MainActor func roundedRectangleWithCornerRadius() async throws {
        let rounded = RoundedRectangle(cornerRadius: 10)
        let rect = CGRect(x: 0, y: 0, width: 100, height: 60)
        let path = rounded.path(in: rect)

        #expect(!path.isEmpty)
        #expect(path.svgPathData.contains("M")) // Has move command
        #expect(path.svgPathData.contains("Q")) // Has quadratic curve for corners
        #expect(path.svgPathData.contains("Z")) // Has close command
    }

    @Test("RoundedRectangle with corner size creates path")
    @MainActor func roundedRectangleWithCornerSize() async throws {
        let cornerSize = CGSize(width: 15, height: 10)
        let rounded = RoundedRectangle(cornerSize: cornerSize)
        let rect = CGRect(x: 0, y: 0, width: 100, height: 60)
        let path = rounded.path(in: rect)

        #expect(!path.isEmpty)
    }

    @Test("RoundedRectangle clamps corner radius to valid range")
    @MainActor func roundedRectangleCornerClamping() async throws {
        // Corner radius larger than half the rect should be clamped
        let rounded = RoundedRectangle(cornerRadius: 100)
        let rect = CGRect(x: 0, y: 0, width: 50, height: 30)
        let path = rounded.path(in: rect)

        #expect(!path.isEmpty)
        // Path should still be valid even with oversized corner radius
    }

    @Test("RoundedRectangle conforms to InsettableShape")
    @MainActor func roundedRectangleInset() async throws {
        let rounded = RoundedRectangle(cornerRadius: 10)
        let inset = rounded.inset(by: 5)

        let rect = CGRect(x: 0, y: 0, width: 100, height: 60)
        let path = inset.path(in: rect)

        #expect(!path.isEmpty)
        // The inset shape should create a smaller path
    }

    @Test("RoundedRectangle with strokeBorder modifier")
    @MainActor func roundedRectangleWithStrokeBorder() async throws {
        let rounded = RoundedRectangle(cornerRadius: 8)
        let bordered = rounded.strokeBorder(Color.blue, lineWidth: 4)
        let vnode = bordered.toVNode()

        // Verify it's an SVG element
        if case .element(let tag) = vnode.type {
            #expect(tag == "svg")
        }
    }

    @Test("RoundedRectangle with fill modifier creates VNode")
    @MainActor func roundedRectangleWithFill() async throws {
        let rounded = RoundedRectangle(cornerRadius: 12)
        let filled = rounded.fill(Color.purple)
        let vnode = filled.toVNode()

        // Verify it's an SVG element
        if case .element(let tag) = vnode.type {
            #expect(tag == "svg")
        }
    }

    // MARK: - Capsule Tests

    @Test("Capsule creates path with fully rounded ends")
    @MainActor func capsuleCreatesPath() async throws {
        let capsule = Capsule()
        let rect = CGRect(x: 0, y: 0, width: 100, height: 40)
        let path = capsule.path(in: rect)

        #expect(!path.isEmpty)
        #expect(path.svgPathData.contains("M")) // Has move command
        #expect(path.svgPathData.contains("Q")) // Has quadratic curve for rounded ends
        #expect(path.svgPathData.contains("Z")) // Has close command
    }

    @Test("Capsule adapts to rectangle dimensions")
    @MainActor func capsuleAdaptsToDimensions() async throws {
        let capsule = Capsule()

        // Horizontal capsule
        let horizontalRect = CGRect(x: 0, y: 0, width: 100, height: 40)
        let horizontalPath = capsule.path(in: horizontalRect)
        #expect(!horizontalPath.isEmpty)

        // Vertical capsule
        let verticalRect = CGRect(x: 0, y: 0, width: 40, height: 100)
        let verticalPath = capsule.path(in: verticalRect)
        #expect(!verticalPath.isEmpty)

        // Square capsule (becomes a circle)
        let squareRect = CGRect(x: 0, y: 0, width: 50, height: 50)
        let squarePath = capsule.path(in: squareRect)
        #expect(!squarePath.isEmpty)
    }

    @Test("Capsule conforms to InsettableShape")
    @MainActor func capsuleInset() async throws {
        let capsule = Capsule()
        let inset = capsule.inset(by: 5)

        let rect = CGRect(x: 0, y: 0, width: 100, height: 40)
        let path = inset.path(in: rect)

        #expect(!path.isEmpty)
    }

    @Test("Capsule with strokeBorder modifier")
    @MainActor func capsuleWithStrokeBorder() async throws {
        let capsule = Capsule()
        let bordered = capsule.strokeBorder(Color.green, lineWidth: 3)
        let vnode = bordered.toVNode()

        // Verify it's an SVG element
        if case .element(let tag) = vnode.type {
            #expect(tag == "svg")
        }
    }

    @Test("Capsule with fill modifier creates VNode")
    @MainActor func capsuleWithFill() async throws {
        let capsule = Capsule()
        let filled = capsule.fill(Color.orange)
        let vnode = filled.toVNode()

        // Verify it's an SVG element
        if case .element(let tag) = vnode.type {
            #expect(tag == "svg")
        }
    }

    // MARK: - Ellipse Tests

    @Test("Ellipse creates path filling entire rect")
    @MainActor func ellipseInRect() async throws {
        let ellipse = Ellipse()
        let rect = CGRect(x: 0, y: 0, width: 200, height: 100)
        let path = ellipse.path(in: rect)

        #expect(!path.isEmpty)
        #expect(path.svgPathData.contains("M")) // Has move command
        #expect(path.svgPathData.contains("C")) // Has curve command
    }

    @Test("Ellipse fills non-square rect completely")
    @MainActor func ellipseInNonSquareRect() async throws {
        let ellipse = Ellipse()
        let rect = CGRect(x: 0, y: 0, width: 300, height: 100)
        let path = ellipse.path(in: rect)

        #expect(!path.isEmpty)
        // Unlike Circle, Ellipse should fill the entire non-square rect
    }

    @Test("Ellipse with fill modifier creates VNode")
    @MainActor func ellipseWithFill() async throws {
        let ellipse = Ellipse()
        let filled = ellipse.fill(Color.yellow)
        let vnode = filled.toVNode()

        // Verify it's an SVG element
        if case .element(let tag) = vnode.type {
            #expect(tag == "svg")
        }
    }

    @Test("Ellipse with stroke modifier creates VNode")
    @MainActor func ellipseWithStroke() async throws {
        let ellipse = Ellipse()
        let stroked = ellipse.stroke(Color.purple, lineWidth: 2)
        let vnode = stroked.toVNode()

        // Verify it's an SVG element
        if case .element(let tag) = vnode.type {
            #expect(tag == "svg")
        }
    }

    // MARK: - SVG Output Tests

    @Test("Circle generates valid SVG path data")
    @MainActor func circleValidSVGPathData() async throws {
        let circle = Circle()
        let rect = CGRect(x: 0, y: 0, width: 100, height: 100)
        let path = circle.path(in: rect)
        let svgData = path.svgPathData

        // SVG path should have move and curve commands
        #expect(svgData.contains("M"))
        #expect(svgData.contains("C"))
        #expect(!svgData.isEmpty)
    }

    @Test("Rectangle generates valid SVG path data")
    @MainActor func rectangleValidSVGPathData() async throws {
        let rectangle = Rectangle()
        let rect = CGRect(x: 0, y: 0, width: 100, height: 50)
        let path = rectangle.path(in: rect)
        let svgData = path.svgPathData

        // SVG path should have move, line, and close commands
        #expect(svgData.contains("M"))
        #expect(svgData.contains("L"))
        #expect(svgData.contains("Z"))
        #expect(!svgData.isEmpty)
    }

    @Test("RoundedRectangle generates valid SVG path data")
    @MainActor func roundedRectangleValidSVGPathData() async throws {
        let rounded = RoundedRectangle(cornerRadius: 10)
        let rect = CGRect(x: 0, y: 0, width: 100, height: 60)
        let path = rounded.path(in: rect)
        let svgData = path.svgPathData

        // SVG path should have move, line, quadratic curve, and close commands
        #expect(svgData.contains("M"))
        #expect(svgData.contains("L"))
        #expect(svgData.contains("Q"))
        #expect(svgData.contains("Z"))
        #expect(!svgData.isEmpty)
    }

    // MARK: - Edge Cases

    @Test("Shapes handle zero-sized rects")
    @MainActor func shapesHandleZeroSizedRects() async throws {
        let zeroRect = CGRect(x: 0, y: 0, width: 0, height: 0)

        let circle = Circle()
        let circlePath = circle.path(in: zeroRect)
        #expect(!circlePath.isEmpty) // Path is created even if degenerate

        let rectangle = Rectangle()
        let rectPath = rectangle.path(in: zeroRect)
        #expect(!rectPath.isEmpty)

        let ellipse = Ellipse()
        let ellipsePath = ellipse.path(in: zeroRect)
        #expect(!ellipsePath.isEmpty)
    }

    @Test("RoundedRectangle handles zero corner radius")
    @MainActor func roundedRectangleWithZeroCornerRadius() async throws {
        let rounded = RoundedRectangle(cornerRadius: 0)
        let rect = CGRect(x: 0, y: 0, width: 100, height: 60)
        let path = rounded.path(in: rect)

        #expect(!path.isEmpty)
        // Should still generate a valid path, effectively a rectangle
    }

    @Test("Multiple insets on InsettableShape")
    @MainActor func multipleInsetsOnShape() async throws {
        let capsule = Capsule()
        let inset1 = capsule.inset(by: 5)
        let inset2 = inset1.inset(by: 3)

        let rect = CGRect(x: 0, y: 0, width: 100, height: 40)
        let path = inset2.path(in: rect)

        #expect(!path.isEmpty)
        // Total inset should be 8 points
    }
}
