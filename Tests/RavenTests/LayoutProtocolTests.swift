import Testing
@testable import SwiftUI
@testable import RavenCore

@MainActor
@Suite("Layout Protocol Tests")
struct LayoutProtocolTests {
    private struct ImportanceKey: LayoutValueKey {
        static let defaultValue: Int = 0
    }

    private struct AlignmentEchoLayout: Layout {
        func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
            CGSize(width: 10, height: 10)
        }

        func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {}

        func explicitAlignment(
            of guide: HorizontalAlignment,
            in bounds: CGRect,
            proposal: ProposedViewSize,
            subviews: Subviews,
            cache: inout Void
        ) -> Double? {
            guide == .center ? 5 : nil
        }
    }

    private struct ValueReadingLayout: Layout {
        func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
            guard let first = subviews.first else { return .zero }
            return CGSize(width: Double(first[ImportanceKey.self]), height: 1)
        }

        func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {}
    }

    @Test("AnyLayout wraps custom Layout and computes placements")
    func anyLayoutComputesFrames() {
        let layout = AnyLayout(HStackLayout(alignment: .center, spacing: 10))
        var cache = AnyLayoutCache()

        let result = layout._computeLayout(
            proposal: ProposedViewSize(width: nil, height: nil),
            measuredSubviews: [
                _MeasuredLayoutSubview(size: CGSize(width: 20, height: 10)),
                _MeasuredLayoutSubview(size: CGSize(width: 30, height: 20)),
            ],
            cache: &cache
        )

        #expect(result.size.width == 60)
        #expect(result.size.height == 20)
        #expect(result.frames.count == 2)
        #expect(result.frames[0].origin.x == 0)
        #expect(result.frames[1].origin.x == 30)
    }

    @Test("FlowLayout wraps into rows against proposed width")
    func flowLayoutWrapsRows() {
        let layout = AnyLayout(FlowLayout(itemSpacing: 8, lineSpacing: 6))
        var cache = AnyLayoutCache()

        let result = layout._computeLayout(
            proposal: ProposedViewSize(width: 100, height: nil),
            measuredSubviews: [
                _MeasuredLayoutSubview(size: CGSize(width: 40, height: 20)),
                _MeasuredLayoutSubview(size: CGSize(width: 50, height: 18)),
                _MeasuredLayoutSubview(size: CGSize(width: 45, height: 16)),
            ],
            cache: &cache
        )

        #expect(result.frames.count == 3)
        #expect(result.frames[0].origin.y == 0)
        #expect(result.frames[1].origin.y == 0)
        #expect(result.frames[2].origin.y > 0)
    }

    @Test("HStackLayout distributes extra width by layout priority")
    func hstackLayoutPriorityDistribution() {
        let layout = AnyLayout(HStackLayout(alignment: .center, spacing: 0))
        var cache = AnyLayoutCache()

        let result = layout._computeLayout(
            proposal: ProposedViewSize(width: 200, height: nil),
            measuredSubviews: [
                _MeasuredLayoutSubview(size: CGSize(width: 50, height: 20), priority: 1),
                _MeasuredLayoutSubview(size: CGSize(width: 50, height: 20), priority: 0),
            ],
            cache: &cache
        )

        #expect(result.size.width == 200)
        #expect(result.frames[0].width == 150)
        #expect(result.frames[1].origin.x == 150)
        #expect(result.frames[1].width == 50)
    }

    @Test("VStackLayout uses horizontal alignment guides")
    func vstackAlignmentGuides() {
        let layout = AnyLayout(VStackLayout(alignment: .center, spacing: 0))
        var cache = AnyLayoutCache()

        let result = layout._computeLayout(
            proposal: ProposedViewSize(width: nil, height: nil),
            measuredSubviews: [
                _MeasuredLayoutSubview(
                    size: CGSize(width: 20, height: 10),
                    horizontalGuides: [.center: 5]
                ),
                _MeasuredLayoutSubview(size: CGSize(width: 50, height: 10)),
            ],
            cache: &cache
        )

        #expect(result.frames[0].origin.x == 20)
        #expect(result.frames[1].origin.x == 0)
    }

    @Test("HStackLayout supports first baseline alignment")
    func hstackFirstBaselineAlignment() {
        let layout = AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: 0))
        var cache = AnyLayoutCache()

        let result = layout._computeLayout(
            proposal: ProposedViewSize(width: nil, height: nil),
            measuredSubviews: [
                _MeasuredLayoutSubview(
                    size: CGSize(width: 30, height: 20),
                    verticalGuides: [.firstTextBaseline: 10]
                ),
                _MeasuredLayoutSubview(
                    size: CGSize(width: 30, height: 30),
                    verticalGuides: [.firstTextBaseline: 20]
                ),
            ],
            cache: &cache
        )

        #expect(result.frames[0].origin.y == 10)
        #expect(result.frames[1].origin.y == 0)
    }

    @Test("FlowLayout callAsFunction returns layout container")
    func flowLayoutCallAsFunction() {
        let view = FlowLayout(itemSpacing: 6, lineSpacing: 4) {
            Text("One")
            Text("Two")
        }

        let erased = AnyView(view)
        let vnode = erased.toVNode()
        #expect(vnode.elementTag == "div")
        #expect(vnode.props["data-raven-layout"] == .attribute(name: "data-raven-layout", value: "true"))
    }

    @Test("LayoutSubview exposes layout value defaults and overrides")
    func layoutValueSubscript() {
        let layout = AnyLayout(ValueReadingLayout())
        var cache = AnyLayoutCache()

        let result = layout._computeLayout(
            proposal: ProposedViewSize(width: nil, height: nil),
            measuredSubviews: [
                _MeasuredLayoutSubview(
                    size: CGSize(width: 10, height: 10),
                    values: [ObjectIdentifier(ImportanceKey.self): _AnyLayoutValueBox(7)]
                ),
            ],
            cache: &cache
        )

        #expect(result.size.width == 7)
    }

    @Test("AnyLayout forwards explicit horizontal alignment")
    func anyLayoutExplicitAlignmentForwarding() {
        let layout = AnyLayout(AlignmentEchoLayout())
        var cache = AnyLayoutCache()
        let subviews = LayoutSubviews._fromMeasured([_MeasuredLayoutSubview(size: CGSize(width: 10, height: 10))])
        let value = layout.explicitAlignment(
            of: .center,
            in: CGRect(x: 0, y: 0, width: 10, height: 10),
            proposal: .unspecified,
            subviews: subviews,
            cache: &cache
        )
        #expect(value == 5)
    }

    @Test("Stack toVNode output remains compatible after bridging")
    func stacksRemainCompatible() {
        let vstack = VStack(spacing: 16) {
            Text("A")
            Text("B")
        }
        let hstack = HStack(alignment: .bottom, spacing: 8) {
            Text("A")
            Text("B")
        }
        let zstack = ZStack(alignment: .topLeading) {
            Text("A")
            Text("B")
        }

        let vv = vstack.toVNode()
        let hv = hstack.toVNode()
        let zv = zstack.toVNode()

        #expect(vv.props["flex-direction"] == .style(name: "flex-direction", value: "column"))
        #expect(vv.props["gap"] == .style(name: "gap", value: "16.0px"))
        #expect(hv.props["align-items"] == .style(name: "align-items", value: "flex-end"))
        #expect(zv.props["place-items"] == .style(name: "place-items", value: "flex-start flex-start"))
    }
}
