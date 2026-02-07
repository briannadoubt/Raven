import Testing
import Foundation
@testable import Raven

/// Tests for container-relative frame modifier functionality.
///
/// These tests verify that the `containerRelativeFrame()` modifier correctly
/// generates VNodes with appropriate CSS for container-relative sizing.
@MainActor
@Suite("Container Relative Frame Tests")
struct ContainerRelativeFrameTests {

    // MARK: - Axis Tests

    @Test("Axis.Set contains horizontal")
    func axisSetHorizontal() {
        let axes: Axis.Set = .horizontal
        #expect(axes.contains(.horizontal))
        #expect(!axes.contains(.vertical))
    }

    @Test("Axis.Set contains vertical")
    func axisSetVertical() {
        let axes: Axis.Set = .vertical
        #expect(!axes.contains(.horizontal))
        #expect(axes.contains(.vertical))
    }

    @Test("Axis.Set contains all axes")
    func axisSetAll() {
        let axes: Axis.Set = .all
        #expect(axes.contains(.horizontal))
        #expect(axes.contains(.vertical))
    }

    @Test("Axis.Set can be combined")
    func axisSetCombined() {
        let axes: Axis.Set = [.horizontal, .vertical]
        #expect(axes.contains(.horizontal))
        #expect(axes.contains(.vertical))
        #expect(axes == .all)
    }

    // MARK: - Basic Closure-Based Frame Tests

    @Test("Container relative frame with horizontal axis generates container query")
    @MainActor
    func containerRelativeFrameHorizontal() {
        let view = Text("Hello")
            .containerRelativeFrame(.horizontal) { width, _ in width * 0.8 }

        let vnode = view.toVNode()

        // Should create a container wrapper
        #expect(vnode.elementTag == "div")

        // Should have container-type set to size
        let containerType = vnode.props["container-type"]
        #expect(containerType != nil)
        if case .style(_, let value) = containerType {
            #expect(value == "size")
        }

        // Should have display flex for alignment
        let display = vnode.props["display"]
        #expect(display != nil)
        if case .style(_, let value) = display {
            #expect(value == "flex")
        }
    }

    @Test("Container relative frame with vertical axis generates correct styles")
    @MainActor
    func containerRelativeFrameVertical() {
        let view = Text("Hello")
            .containerRelativeFrame(.vertical) { height, _ in height * 0.5 }

        let vnode = view.toVNode()

        #expect(vnode.elementTag == "div")

        // Should have container-type set to size
        let containerType = vnode.props["container-type"]
        #expect(containerType != nil)
        if case .style(_, let value) = containerType {
            #expect(value == "size")
        }
    }

    @Test("Container relative frame with both axes")
    @MainActor
    func containerRelativeFrameBothAxes() {
        let view = Text("Hello")
            .containerRelativeFrame([.horizontal, .vertical]) { size, _ in size * 0.5 }

        let vnode = view.toVNode()

        #expect(vnode.elementTag == "div")

        // Should have both justify-content and align-items
        #expect(vnode.props["justify-content"] != nil)
        #expect(vnode.props["align-items"] != nil)
    }

    // MARK: - Grid-Based Frame Tests

    @Test("Container relative frame with count creates grid sizing")
    @MainActor
    func containerRelativeFrameWithCount() {
        let view = Text("Hello")
            .containerRelativeFrame(.horizontal, count: 3)

        let vnode = view.toVNode()

        #expect(vnode.elementTag == "div")
        #expect(vnode.children.count == 1)

        // Inner wrapper should have width calculation
        let innerNode = vnode.children[0]
        let widthProp = innerNode.props["width"]
        #expect(widthProp != nil)

        if case .style(_, let value) = widthProp {
            // Should contain calc expression
            #expect(value.contains("calc"))
            // Should divide by count (3)
            #expect(value.contains("3"))
        }
    }

    @Test("Container relative frame with span creates proper calculation")
    @MainActor
    func containerRelativeFrameWithSpan() {
        let view = Text("Hello")
            .containerRelativeFrame(.horizontal, count: 4, span: 2)

        let vnode = view.toVNode()

        let innerNode = vnode.children[0]
        let widthProp = innerNode.props["width"]
        #expect(widthProp != nil)

        if case .style(_, let value) = widthProp {
            // Should contain calc expression with span
            #expect(value.contains("calc"))
            #expect(value.contains("2")) // span
            #expect(value.contains("4")) // count
        }
    }

    @Test("Container relative frame with spacing includes spacing in calculation")
    @MainActor
    func containerRelativeFrameWithSpacing() {
        let view = Text("Hello")
            .containerRelativeFrame(.horizontal, count: 3, spacing: 10)

        let vnode = view.toVNode()

        let innerNode = vnode.children[0]
        let widthProp = innerNode.props["width"]
        #expect(widthProp != nil)

        if case .style(_, let value) = widthProp {
            // Should include spacing calculation: spacing * (count - 1)
            // For count=3, that's 10 * 2 = 20px
            #expect(value.contains("20"))
            #expect(value.contains("px"))
        }
    }

    @Test("Container relative frame grid on vertical axis")
    @MainActor
    func containerRelativeFrameGridVertical() {
        let view = Text("Hello")
            .containerRelativeFrame(.vertical, count: 4, spacing: 8)

        let vnode = view.toVNode()

        let innerNode = vnode.children[0]
        let heightProp = innerNode.props["height"]
        #expect(heightProp != nil)

        if case .style(_, let value) = heightProp {
            // Should use container query height units (cqh)
            #expect(value.contains("cqh"))
            #expect(value.contains("calc"))
        }
    }

    @Test("Container relative frame grid on both axes")
    @MainActor
    func containerRelativeFrameGridBothAxes() {
        let view = Text("Hello")
            .containerRelativeFrame([.horizontal, .vertical], count: 2, spacing: 5)

        let vnode = view.toVNode()

        let innerNode = vnode.children[0]

        // Should have both width and height
        #expect(innerNode.props["width"] != nil)
        #expect(innerNode.props["height"] != nil)
    }

    // MARK: - Alignment Tests

    @Test("Container relative frame with leading alignment")
    @MainActor
    func containerRelativeFrameLeadingAlignment() {
        let view = Text("Hello")
            .containerRelativeFrame(.horizontal, alignment: .leading) { w, _ in w }

        let vnode = view.toVNode()

        let justifyContent = vnode.props["justify-content"]
        if case .style(_, let value) = justifyContent {
            #expect(value == "flex-start")
        }
    }

    @Test("Container relative frame with center alignment")
    @MainActor
    func containerRelativeFrameCenterAlignment() {
        let view = Text("Hello")
            .containerRelativeFrame(.horizontal, alignment: .center) { w, _ in w }

        let vnode = view.toVNode()

        let justifyContent = vnode.props["justify-content"]
        if case .style(_, let value) = justifyContent {
            #expect(value == "center")
        }
    }

    @Test("Container relative frame with trailing alignment")
    @MainActor
    func containerRelativeFrameTrailingAlignment() {
        let view = Text("Hello")
            .containerRelativeFrame(.horizontal, alignment: .trailing) { w, _ in w }

        let vnode = view.toVNode()

        let justifyContent = vnode.props["justify-content"]
        if case .style(_, let value) = justifyContent {
            #expect(value == "flex-end")
        }
    }

    @Test("Container relative frame with top alignment")
    @MainActor
    func containerRelativeFrameTopAlignment() {
        let view = Text("Hello")
            .containerRelativeFrame(.vertical, alignment: .top) { h, _ in h }

        let vnode = view.toVNode()

        let alignItems = vnode.props["align-items"]
        if case .style(_, let value) = alignItems {
            #expect(value == "flex-start")
        }
    }

    @Test("Container relative frame with bottom alignment")
    @MainActor
    func containerRelativeFrameBottomAlignment() {
        let view = Text("Hello")
            .containerRelativeFrame(.vertical, alignment: .bottom) { h, _ in h }

        let vnode = view.toVNode()

        let alignItems = vnode.props["align-items"]
        if case .style(_, let value) = alignItems {
            #expect(value == "flex-end")
        }
    }

    // MARK: - Container Query Unit Tests

    @Test("Container relative frame uses container query width units")
    @MainActor
    func containerRelativeFrameUsesContainerQueryWidthUnits() {
        let view = Text("Hello")
            .containerRelativeFrame(.horizontal) { w, _ in w }

        let vnode = view.toVNode()
        let innerNode = vnode.children[0]
        let widthProp = innerNode.props["width"]

        if case .style(_, let value) = widthProp {
            // Should use cqw (container query width) units
            #expect(value.contains("cqw"))
        }
    }

    @Test("Container relative frame uses container query height units")
    @MainActor
    func containerRelativeFrameUsesContainerQueryHeightUnits() {
        let view = Text("Hello")
            .containerRelativeFrame(.vertical) { h, _ in h }

        let vnode = view.toVNode()
        let innerNode = vnode.children[0]
        let heightProp = innerNode.props["height"]

        if case .style(_, let value) = heightProp {
            // Should use cqh (container query height) units
            #expect(value.contains("cqh"))
        }
    }

    // MARK: - Nested Content Tests

    @Test("Container relative frame preserves content structure")
    @MainActor
    func containerRelativeFramePreservesContent() {
        let view = VStack {
            Text("Line 1")
            Text("Line 2")
        }
        .containerRelativeFrame(.horizontal) { w, _ in w * 0.8 }

        let vnode = view.toVNode()

        // Should have outer container wrapper
        #expect(vnode.elementTag == "div")
        #expect(vnode.children.count == 1)

        // Inner wrapper exists (content rendering is handled by RenderCoordinator)
        let innerNode = vnode.children[0]
        #expect(innerNode.elementTag == "div")

        // Children are left empty for the RenderCoordinator to populate
        // This is consistent with how other container views like VStack work
    }

    // MARK: - Complex Layout Tests

    @Test("Container relative frame in complex layout")
    @MainActor
    func containerRelativeFrameInComplexLayout() {
        let view = VStack {
            Text("Header")
            HStack {
                Text("Left")
                    .containerRelativeFrame(.horizontal, count: 2, spacing: 10)
                Text("Right")
                    .containerRelativeFrame(.horizontal, count: 2, spacing: 10)
            }
            Text("Footer")
        }

        let vnode = view.toVNode()

        // Should render without errors
        #expect(vnode.elementTag == "div")
    }

    // MARK: - Edge Cases

    @Test("Container relative frame with single count")
    @MainActor
    func containerRelativeFrameSingleCount() {
        let view = Text("Hello")
            .containerRelativeFrame(.horizontal, count: 1)

        let vnode = view.toVNode()

        // Should handle count of 1 (full width)
        #expect(vnode.elementTag == "div")
        #expect(vnode.children.count == 1)
    }

    @Test("Container relative frame with zero spacing")
    @MainActor
    func containerRelativeFrameZeroSpacing() {
        let view = Text("Hello")
            .containerRelativeFrame(.horizontal, count: 3, spacing: 0)

        let vnode = view.toVNode()
        let innerNode = vnode.children[0]
        let widthProp = innerNode.props["width"]

        if case .style(_, let value) = widthProp {
            // With zero spacing and count 3: spacing * (3-1) = 0
            #expect(value.contains("0px") || value.contains("calc"))
        }
    }
}
