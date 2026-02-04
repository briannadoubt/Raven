import Testing
@testable import Raven

/// Tests for Path drawing functionality
struct PathTests {
    // MARK: - Basic Path Commands

    @Test("Empty path is empty")
    func emptyPath() {
        let path = Path()
        #expect(path.isEmpty)
    }

    @Test("Path with elements is not empty")
    func nonEmptyPath() {
        var path = Path()
        path.move(to: CGPoint(x: 10, y: 10))
        #expect(!path.isEmpty)
    }

    @Test("Move command generates correct SVG")
    func moveCommand() {
        var path = Path()
        path.move(to: CGPoint(x: 50, y: 100))

        let svgData = path.svgPathData
        #expect(svgData == "M 50 100")
    }

    @Test("Line command generates correct SVG")
    func lineCommand() {
        var path = Path()
        path.move(to: CGPoint(x: 10, y: 10))
        path.addLine(to: CGPoint(x: 100, y: 100))

        let svgData = path.svgPathData
        #expect(svgData == "M 10 10 L 100 100")
    }

    @Test("Quad curve command generates correct SVG")
    func quadCurveCommand() {
        var path = Path()
        path.move(to: CGPoint(x: 10, y: 10))
        path.addQuadCurve(
            to: CGPoint(x: 100, y: 100),
            control: CGPoint(x: 50, y: 150)
        )

        let svgData = path.svgPathData
        #expect(svgData == "M 10 10 Q 50 150 100 100")
    }

    @Test("Cubic curve command generates correct SVG")
    func cubicCurveCommand() {
        var path = Path()
        path.move(to: CGPoint(x: 10, y: 10))
        path.addCurve(
            to: CGPoint(x: 100, y: 100),
            control1: CGPoint(x: 30, y: 150),
            control2: CGPoint(x: 70, y: 150)
        )

        let svgData = path.svgPathData
        #expect(svgData == "M 10 10 C 30 150 70 150 100 100")
    }

    @Test("Close subpath generates Z command")
    func closeSubpath() {
        var path = Path()
        path.move(to: CGPoint(x: 10, y: 10))
        path.addLine(to: CGPoint(x: 100, y: 10))
        path.addLine(to: CGPoint(x: 50, y: 100))
        path.closeSubpath()

        let svgData = path.svgPathData
        #expect(svgData == "M 10 10 L 100 10 L 50 100 Z")
    }

    // MARK: - Complex Paths

    @Test("Triangle path")
    func trianglePath() {
        var path = Path()
        path.move(to: CGPoint(x: 50, y: 0))
        path.addLine(to: CGPoint(x: 100, y: 100))
        path.addLine(to: CGPoint(x: 0, y: 100))
        path.closeSubpath()

        let svgData = path.svgPathData
        #expect(svgData == "M 50 0 L 100 100 L 0 100 Z")
    }

    @Test("Multiple subpaths")
    func multipleSubpaths() {
        var path = Path()

        // First subpath - triangle
        path.move(to: CGPoint(x: 10, y: 10))
        path.addLine(to: CGPoint(x: 20, y: 10))
        path.addLine(to: CGPoint(x: 15, y: 20))
        path.closeSubpath()

        // Second subpath - square
        path.move(to: CGPoint(x: 30, y: 30))
        path.addLine(to: CGPoint(x: 40, y: 30))
        path.addLine(to: CGPoint(x: 40, y: 40))
        path.addLine(to: CGPoint(x: 30, y: 40))
        path.closeSubpath()

        #expect(!path.isEmpty)
        let svgData = path.svgPathData
        #expect(svgData.contains("M 10 10"))
        #expect(svgData.contains("M 30 30"))
    }

    // MARK: - Convenience Shape Methods

    @Test("Add rectangle")
    func addRectangle() {
        var path = Path()
        path.addRect(CGRect(x: 10, y: 10, width: 100, height: 50))

        let svgData = path.svgPathData
        #expect(svgData.contains("M 10 10"))
        #expect(svgData.contains("L 110 10"))
        #expect(svgData.contains("L 110 60"))
        #expect(svgData.contains("L 10 60"))
        #expect(svgData.contains("Z"))
    }

    @Test("Add rounded rectangle")
    func addRoundedRectangle() {
        var path = Path()
        path.addRoundedRect(
            in: CGRect(x: 0, y: 0, width: 100, height: 60),
            cornerRadius: 10
        )

        let svgData = path.svgPathData
        // Should have quadratic curves for corners
        #expect(svgData.contains("Q"))
        #expect(svgData.contains("Z"))
        #expect(!path.isEmpty)
    }

    @Test("Add ellipse")
    func addEllipse() {
        var path = Path()
        path.addEllipse(in: CGRect(x: 0, y: 0, width: 100, height: 50))

        let svgData = path.svgPathData
        // Ellipse uses cubic curves
        #expect(svgData.contains("C"))
        #expect(svgData.contains("Z"))
        // Should start at top center
        #expect(svgData.contains("M 50 0"))
    }

    @Test("Add circle via ellipse")
    func addCircle() {
        var path = Path()
        let size: Double = 100
        path.addEllipse(in: CGRect(x: 0, y: 0, width: size, height: size))

        #expect(!path.isEmpty)
        let svgData = path.svgPathData
        #expect(svgData.contains("C"))
    }

    // MARK: - Convenience Initializers

    @Test("Init with rectangle")
    func initWithRectangle() {
        let rect = CGRect(x: 20, y: 20, width: 80, height: 60)
        let path = Path(rect)

        #expect(!path.isEmpty)
        let svgData = path.svgPathData
        #expect(svgData.contains("M 20 20"))
        #expect(svgData.contains("Z"))
    }

    @Test("Init with rounded rect")
    func initWithRoundedRect() {
        let rect = CGRect(x: 0, y: 0, width: 100, height: 100)
        let path = Path(roundedRect: rect, cornerRadius: 15)

        #expect(!path.isEmpty)
        let svgData = path.svgPathData
        #expect(svgData.contains("Q"))
    }

    @Test("Init with ellipse")
    func initWithEllipse() {
        let rect = CGRect(x: 10, y: 10, width: 80, height: 60)
        let path = Path(ellipseIn: rect)

        #expect(!path.isEmpty)
        let svgData = path.svgPathData
        #expect(svgData.contains("C"))
    }

    // MARK: - Add Lines

    @Test("Add lines from array of points")
    func addLinesFromArray() {
        var path = Path()
        let points = [
            CGPoint(x: 0, y: 0),
            CGPoint(x: 10, y: 10),
            CGPoint(x: 20, y: 0),
            CGPoint(x: 30, y: 10)
        ]
        path.addLines(points)

        let svgData = path.svgPathData
        #expect(svgData.contains("M 0 0"))
        #expect(svgData.contains("L 10 10"))
        #expect(svgData.contains("L 20 0"))
        #expect(svgData.contains("L 30 10"))
    }

    @Test("Add lines with empty array does nothing")
    func addLinesEmptyArray() {
        var path = Path()
        path.addLines([])

        #expect(path.isEmpty)
    }

    // MARK: - Add Path

    @Test("Add path to path")
    func addPathToPath() {
        var path1 = Path()
        path1.move(to: CGPoint(x: 0, y: 0))
        path1.addLine(to: CGPoint(x: 10, y: 10))

        var path2 = Path()
        path2.move(to: CGPoint(x: 20, y: 20))
        path2.addLine(to: CGPoint(x: 30, y: 30))

        path1.addPath(path2)

        let svgData = path1.svgPathData
        #expect(svgData.contains("M 0 0"))
        #expect(svgData.contains("L 10 10"))
        #expect(svgData.contains("M 20 20"))
        #expect(svgData.contains("L 30 30"))
    }

    // MARK: - Transformations

    @Test("Translation transform")
    func translationTransform() {
        var path = Path()
        path.addRect(CGRect(x: 0, y: 0, width: 10, height: 10))

        let transform = CGAffineTransform(translationX: 50, y: 50)
        let transformedPath = path.applying(transform)

        let svgData = transformedPath.svgPathData
        #expect(svgData.contains("M 50 50"))
        #expect(svgData.contains("L 60 50"))
    }

    @Test("Offset by")
    func offsetBy() {
        var path = Path()
        path.move(to: CGPoint(x: 10, y: 10))
        path.addLine(to: CGPoint(x: 20, y: 20))

        let offsetPath = path.offsetBy(x: 100, y: 200)

        let svgData = offsetPath.svgPathData
        #expect(svgData.contains("M 110 210"))
        #expect(svgData.contains("L 120 220"))
    }

    @Test("Scale transform")
    func scaleTransform() {
        var path = Path()
        path.move(to: CGPoint(x: 10, y: 10))
        path.addLine(to: CGPoint(x: 20, y: 20))

        let transform = CGAffineTransform(scaleX: 2, y: 2)
        let scaledPath = path.applying(transform)

        let svgData = scaledPath.svgPathData
        #expect(svgData.contains("M 20 20"))
        #expect(svgData.contains("L 40 40"))
    }

    // MARK: - Arc Commands

    @Test("Add arc")
    func addArc() {
        var path = Path()
        path.addArc(
            center: CGPoint(x: 50, y: 50),
            radius: 30,
            startAngle: Angle(degrees: 0),
            endAngle: Angle(degrees: 90),
            clockwise: false
        )

        let svgData = path.svgPathData
        #expect(svgData.contains("A"))
        #expect(!path.isEmpty)
    }

    // MARK: - Rounded Rect with Corner Size

    @Test("Rounded rect with corner size")
    func roundedRectCornerSize() {
        var path = Path()
        path.addRoundedRect(
            in: CGRect(x: 0, y: 0, width: 100, height: 60),
            cornerSize: CGSize(width: 15, height: 10)
        )

        #expect(!path.isEmpty)
        let svgData = path.svgPathData
        #expect(svgData.contains("Q"))
    }

    @Test("Init with rounded rect using corner size")
    func initRoundedRectCornerSize() {
        let path = Path(
            roundedRect: CGRect(x: 0, y: 0, width: 80, height: 50),
            cornerSize: CGSize(width: 10, height: 5)
        )

        #expect(!path.isEmpty)
    }

    // MARK: - Copy

    @Test("Copy creates equal path")
    func copyPath() {
        var original = Path()
        original.move(to: CGPoint(x: 10, y: 10))
        original.addLine(to: CGPoint(x: 20, y: 20))

        let copied = original.copy()

        #expect(original == copied)
        #expect(original.svgPathData == copied.svgPathData)
    }

    // MARK: - CGAffineTransform

    @Test("Identity transform")
    func identityTransform() {
        let identity = CGAffineTransform.identity
        #expect(identity.a == 1.0)
        #expect(identity.b == 0.0)
        #expect(identity.c == 0.0)
        #expect(identity.d == 1.0)
        #expect(identity.tx == 0.0)
        #expect(identity.ty == 0.0)
    }

    @Test("Point applying transform")
    func pointApplyingTransform() {
        let point = CGPoint(x: 10, y: 20)
        let transform = CGAffineTransform(translationX: 5, y: 10)
        let transformed = point.applying(transform)

        #expect(transformed.x == 15.0)
        #expect(transformed.y == 30.0)
    }

    // MARK: - Number Formatting

    @Test("SVG formats whole numbers without decimals")
    func svgFormatsWholeNumbers() {
        var path = Path()
        path.move(to: CGPoint(x: 10.0, y: 20.0))
        path.addLine(to: CGPoint(x: 100.0, y: 200.0))

        let svgData = path.svgPathData
        #expect(svgData == "M 10 20 L 100 200")
    }

    @Test("SVG formats decimal numbers")
    func svgFormatsDecimalNumbers() {
        var path = Path()
        path.move(to: CGPoint(x: 10.5, y: 20.75))

        let svgData = path.svgPathData
        #expect(svgData.contains("10.5"))
        #expect(svgData.contains("20.75"))
    }
}
