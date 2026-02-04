import Testing
@testable import Raven

/// Tests for shape modifiers including StrokeStyle and trim functionality
struct ShapeModifierTests {
    // MARK: - Test Shape

    struct TestCircle: Shape {
        func path(in rect: CGRect) -> Path {
            Path(ellipseIn: rect)
        }
    }

    struct TestRectangle: Shape {
        func path(in rect: CGRect) -> Path {
            Path(rect)
        }
    }

    // MARK: - StrokeStyle Tests

    @Test("StrokeStyle default initialization")
    func strokeStyleDefaults() {
        let style = StrokeStyle()

        #expect(style.lineWidth == 1)
        #expect(style.lineCap == .butt)
        #expect(style.lineJoin == .miter)
        #expect(style.miterLimit == 10)
        #expect(style.dash.isEmpty)
        #expect(style.dashPhase == 0)
    }

    @Test("StrokeStyle custom initialization")
    func strokeStyleCustom() {
        let style = StrokeStyle(
            lineWidth: 5,
            lineCap: .round,
            lineJoin: .bevel,
            miterLimit: 15,
            dash: [10, 5],
            dashPhase: 2.5
        )

        #expect(style.lineWidth == 5)
        #expect(style.lineCap == .round)
        #expect(style.lineJoin == .bevel)
        #expect(style.miterLimit == 15)
        #expect(style.dash == [10, 5])
        #expect(style.dashPhase == 2.5)
    }

    @Test("StrokeStyle SVG attributes for solid line")
    func strokeStyleSolidLineSVG() {
        let style = StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
        let attrs = style.svgAttributes()

        #expect(attrs["stroke-width"] == "3.0")
        #expect(attrs["stroke-linecap"] == "round")
        #expect(attrs["stroke-linejoin"] == "round")
        #expect(attrs["stroke-miterlimit"] == nil) // Not added for non-miter joins
        #expect(attrs["stroke-dasharray"] == nil)
    }

    @Test("StrokeStyle SVG attributes for dashed line")
    func strokeStyleDashedLineSVG() {
        let style = StrokeStyle(
            lineWidth: 2,
            dash: [10, 5, 2, 5]
        )
        let attrs = style.svgAttributes()

        #expect(attrs["stroke-width"] == "2.0")
        #expect(attrs["stroke-dasharray"] == "10.0 5.0 2.0 5.0")
        #expect(attrs["stroke-dashoffset"] == nil) // Not added when phase is 0
    }

    @Test("StrokeStyle SVG attributes with dash phase")
    func strokeStyleDashPhaseSVG() {
        let style = StrokeStyle(
            lineWidth: 2,
            dash: [5, 5],
            dashPhase: 2.5
        )
        let attrs = style.svgAttributes()

        #expect(attrs["stroke-dasharray"] == "5.0 5.0")
        #expect(attrs["stroke-dashoffset"] == "2.5")
    }

    @Test("StrokeStyle SVG attributes with miter limit")
    func strokeStyleMiterLimitSVG() {
        let style = StrokeStyle(
            lineWidth: 2,
            lineJoin: .miter,
            miterLimit: 20
        )
        let attrs = style.svgAttributes()

        #expect(attrs["stroke-linejoin"] == "miter")
        #expect(attrs["stroke-miterlimit"] == "20.0")
    }

    @Test("StrokeStyle LineCap cases")
    func strokeStyleLineCaps() {
        #expect(StrokeStyle.LineCap.butt.rawValue == "butt")
        #expect(StrokeStyle.LineCap.round.rawValue == "round")
        #expect(StrokeStyle.LineCap.square.rawValue == "square")
    }

    @Test("StrokeStyle LineJoin cases")
    func strokeStyleLineJoins() {
        #expect(StrokeStyle.LineJoin.miter.rawValue == "miter")
        #expect(StrokeStyle.LineJoin.round.rawValue == "round")
        #expect(StrokeStyle.LineJoin.bevel.rawValue == "bevel")
    }

    @Test("StrokeStyle is Sendable")
    func strokeStyleSendable() {
        let style = StrokeStyle(lineWidth: 2)
        let _: any Sendable = style
    }

    @Test("StrokeStyle is Hashable")
    func strokeStyleHashable() {
        let style1 = StrokeStyle(lineWidth: 2, dash: [5, 5])
        let style2 = StrokeStyle(lineWidth: 2, dash: [5, 5])
        let style3 = StrokeStyle(lineWidth: 3, dash: [5, 5])

        #expect(style1 == style2)
        #expect(style1 != style3)
    }

    // MARK: - Enhanced Stroke Modifier Tests

    @Test("Shape stroke with StrokeStyle creates correct view type")
    @MainActor func shapeStrokeWithStyle() {
        let circle = TestCircle()
        let strokeStyle = StrokeStyle(lineWidth: 4, lineCap: .round)
        let stroked = circle.stroke(Color.blue, style: strokeStyle)

        #expect(type(of: stroked) == _ShapeStyledStrokeView<TestCircle, Color>.self)
    }

    @Test("Shape stroke with StrokeStyle renders SVG")
    @MainActor func shapeStrokeStyleRendersSVG() {
        let circle = TestCircle()
        let strokeStyle = StrokeStyle(
            lineWidth: 3,
            lineCap: .round,
            lineJoin: .round
        )
        let stroked = circle.stroke(Color.red, style: strokeStyle)
        let vnode = stroked.toVNode()

        #expect(vnode.elementTag == "svg")
        #expect(vnode.children.count > 0)
    }

    @Test("Shape stroke with dashed style")
    @MainActor func shapeStrokeWithDash() {
        let rect = TestRectangle()
        let strokeStyle = StrokeStyle(
            lineWidth: 2,
            dash: [10, 5]
        )
        let stroked = rect.stroke(Color.black, style: strokeStyle)
        let vnode = stroked.toVNode()

        #expect(vnode.elementTag == "svg")
    }

    // MARK: - Trim Modifier Tests

    @Test("Shape trim modifier creates correct view type")
    @MainActor func shapeTrimModifier() {
        let circle = TestCircle()
        let trimmed = circle.trim(from: 0.0, to: 0.5)

        #expect(type(of: trimmed) == _ShapeTrimView<TestCircle>.self)
    }

    @Test("Shape trim with default values")
    @MainActor func shapeTrimDefaults() {
        let circle = TestCircle()
        let trimmed = circle.trim()
        let vnode = trimmed.toVNode()

        #expect(vnode.elementTag == "svg")
        #expect(vnode.children.count > 0)
    }

    @Test("Shape trim renders SVG with path attributes")
    @MainActor func shapeTrimRendersSVG() {
        let circle = TestCircle()
        let trimmed = circle.trim(from: 0.25, to: 0.75)
        let vnode = trimmed.toVNode()

        #expect(vnode.elementTag == "svg")
        #expect(vnode.children.count > 0)
    }

    @Test("Shape trim with zero to one (full path)")
    @MainActor func shapeTrimFullPath() {
        let rect = TestRectangle()
        let trimmed = rect.trim(from: 0.0, to: 1.0)
        let vnode = trimmed.toVNode()

        #expect(vnode.elementTag == "svg")
    }

    @Test("Shape trim with partial path")
    @MainActor func shapeTrimPartialPath() {
        let circle = TestCircle()
        let trimmed = circle.trim(from: 0.0, to: 0.5)
        let vnode = trimmed.toVNode()

        #expect(vnode.elementTag == "svg")
    }

    @Test("Shape trim with offset start")
    @MainActor func shapeTrimOffsetStart() {
        let circle = TestCircle()
        let trimmed = circle.trim(from: 0.25, to: 0.75)
        let vnode = trimmed.toVNode()

        #expect(vnode.elementTag == "svg")
    }

    // MARK: - Trim with Fill Tests

    @Test("Filled shape can be trimmed")
    @MainActor func filledShapeTrim() {
        let circle = TestCircle()
        let filled = circle.fill(Color.blue)
        let trimmed = filled.trim(from: 0.0, to: 0.5)

        #expect(type(of: trimmed) == _ShapeTrimmedFillView<TestCircle, Color>.self)
    }

    @Test("Filled trimmed shape renders SVG")
    @MainActor func filledTrimmedShapeRendersSVG() {
        let circle = TestCircle()
        let trimmed = circle.fill(Color.red).trim(from: 0.25, to: 0.75)
        let vnode = trimmed.toVNode()

        #expect(vnode.elementTag == "svg")
        #expect(vnode.children.count > 0)
    }

    // MARK: - Trim with Stroke Tests

    @Test("Stroked shape can be trimmed")
    @MainActor func strokedShapeTrim() {
        let circle = TestCircle()
        let stroked = circle.stroke(Color.blue, lineWidth: 2)
        let trimmed = stroked.trim(from: 0.0, to: 0.5)

        #expect(type(of: trimmed) == _ShapeTrimmedStrokeView<TestCircle, Color>.self)
    }

    @Test("Stroked trimmed shape renders SVG")
    @MainActor func strokedTrimmedShapeRendersSVG() {
        let circle = TestCircle()
        let trimmed = circle.stroke(Color.green, lineWidth: 3).trim(from: 0.0, to: 0.7)
        let vnode = trimmed.toVNode()

        #expect(vnode.elementTag == "svg")
        #expect(vnode.children.count > 0)
    }

    // MARK: - Trim with Styled Stroke Tests

    @Test("Styled stroke shape can be trimmed")
    @MainActor func styledStrokeShapeTrim() {
        let circle = TestCircle()
        let strokeStyle = StrokeStyle(lineWidth: 4, lineCap: .round)
        let stroked = circle.stroke(Color.blue, style: strokeStyle)
        let trimmed = stroked.trim(from: 0.0, to: 0.5)

        #expect(type(of: trimmed) == _ShapeTrimmedStyledStrokeView<TestCircle, Color>.self)
    }

    @Test("Styled stroke trimmed shape renders SVG")
    @MainActor func styledStrokeTrimmedShapeRendersSVG() {
        let circle = TestCircle()
        let strokeStyle = StrokeStyle(
            lineWidth: 3,
            lineCap: .round,
            lineJoin: .round
        )
        let trimmed = circle.stroke(Color.red, style: strokeStyle).trim(from: 0.25, to: 0.75)
        let vnode = trimmed.toVNode()

        #expect(vnode.elementTag == "svg")
        #expect(vnode.children.count > 0)
    }

    // MARK: - Integration Tests

    @Test("Trim with gradient stroke")
    @MainActor func trimWithGradientStroke() {
        let circle = TestCircle()
        let gradient = LinearGradient(colors: [.red, .blue], angle: Angle(degrees: 90))
        let trimmed = circle.stroke(gradient, lineWidth: 2).trim(from: 0.0, to: 0.5)
        let vnode = trimmed.toVNode()

        #expect(vnode.elementTag == "svg")
    }

    @Test("StrokeStyle with gradient")
    @MainActor func strokeStyleWithGradient() {
        let rect = TestRectangle()
        let gradient = RadialGradient(colors: [.white, .black])
        let strokeStyle = StrokeStyle(
            lineWidth: 3,
            lineCap: .round,
            dash: [5, 5]
        )
        let stroked = rect.stroke(gradient, style: strokeStyle)
        let vnode = stroked.toVNode()

        #expect(vnode.elementTag == "svg")
    }

    @Test("Complex stroke style with all properties")
    @MainActor func complexStrokeStyle() {
        let circle = TestCircle()
        let strokeStyle = StrokeStyle(
            lineWidth: 4,
            lineCap: .round,
            lineJoin: .bevel,
            miterLimit: 15,
            dash: [10, 5, 2, 5],
            dashPhase: 3
        )
        let stroked = circle.stroke(Color.purple, style: strokeStyle)
        let vnode = stroked.toVNode()

        #expect(vnode.elementTag == "svg")
        #expect(vnode.children.count > 0)
    }

    @Test("Multiple trim values for animation")
    @MainActor func multipleTrimValues() {
        let circle = TestCircle()

        // Test different trim values (simulating animation frames)
        let values: [(CGFloat, CGFloat)] = [
            (0.0, 0.0),
            (0.0, 0.25),
            (0.0, 0.5),
            (0.0, 0.75),
            (0.0, 1.0)
        ]

        for (from, to) in values {
            let trimmed = circle.trim(from: from, to: to)
            let vnode = trimmed.toVNode()
            #expect(vnode.elementTag == "svg")
        }
    }

    @Test("Trim creates progress indicator pattern")
    @MainActor func trimProgressIndicator() {
        let circle = TestCircle()
        let progress: CGFloat = 0.65

        let trimmed = circle
            .stroke(Color.blue, lineWidth: 4)
            .trim(from: 0.0, to: progress)

        let vnode = trimmed.toVNode()
        #expect(vnode.elementTag == "svg")
    }

    @Test("Trim with rounded line caps for smooth appearance")
    @MainActor func trimWithRoundedCaps() {
        let circle = TestCircle()
        let strokeStyle = StrokeStyle(
            lineWidth: 5,
            lineCap: .round
        )

        let trimmed = circle
            .stroke(Color.green, style: strokeStyle)
            .trim(from: 0.0, to: 0.7)

        let vnode = trimmed.toVNode()
        #expect(vnode.elementTag == "svg")
    }

    @Test("_ShapeTrimView is Sendable")
    @MainActor func shapeTrimViewSendable() {
        let circle = TestCircle()
        let trimmed = circle.trim(from: 0.0, to: 0.5)
        let _: any Sendable = trimmed
    }

    @Test("_ShapeStyledStrokeView is Sendable")
    @MainActor func shapeStyledStrokeViewSendable() {
        let circle = TestCircle()
        let strokeStyle = StrokeStyle(lineWidth: 2)
        let stroked = circle.stroke(Color.blue, style: strokeStyle)
        let _: any Sendable = stroked
    }
}
