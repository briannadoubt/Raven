import Testing
@testable import Raven

/// Tests for text modifiers (.lineLimit, .multilineTextAlignment, .truncationMode)
///
/// This test suite verifies the text formatting modifiers:
/// - `.lineLimit(_:)` - Limit text to a specific number of lines
/// - `.multilineTextAlignment(_:)` - Control horizontal alignment of multiline text
/// - `.truncationMode(_:)` - Control ellipsis behavior for truncated text
///
/// Each modifier is tested for:
/// - VNode structure and CSS property generation
/// - Correct CSS values for different parameters
/// - Integration with Text views
/// - Edge cases and parameter variations
@MainActor
@Suite struct TextModifiersTests {

    // MARK: - Line Limit Tests (4 tests)

    @Test func lineLimitBasicUsage() {
        let text = Text("This is a long text that should be limited")
            .lineLimit(2)

        let node = text.toVNode()

        // Verify wrapper element
        #expect(node.elementTag == "div")

        // Verify -webkit-line-clamp
        if case .style(name: "-webkit-line-clamp", value: let clamp) = node.props["-webkit-line-clamp"] {
            #expect(clamp == "2")
        } else {
            Issue.record("Line limit should have -webkit-line-clamp property")
        }

        // Verify display: -webkit-box
        if case .style(name: "display", value: let display) = node.props["display"] {
            #expect(display == "-webkit-box")
        } else {
            Issue.record("Line limit should have display property")
        }

        // Verify -webkit-box-orient: vertical
        if case .style(name: "-webkit-box-orient", value: let orient) = node.props["-webkit-box-orient"] {
            #expect(orient == "vertical")
        } else {
            Issue.record("Line limit should have -webkit-box-orient property")
        }

        // Verify overflow: hidden
        if case .style(name: "overflow", value: let overflow) = node.props["overflow"] {
            #expect(overflow == "hidden")
        } else {
            Issue.record("Line limit should have overflow property")
        }
    }

    @Test func lineLimitWithDifferentValues() {
        // Test with 1 line
        let oneLineText = Text("Short text").lineLimit(1)
        let oneLineNode = oneLineText.toVNode()

        if case .style(name: "-webkit-line-clamp", value: let clamp) = oneLineNode.props["-webkit-line-clamp"] {
            #expect(clamp == "1")
        } else {
            Issue.record("Single line limit should have -webkit-line-clamp")
        }

        // Test with 5 lines
        let fiveLineText = Text("Longer text").lineLimit(5)
        let fiveLineNode = fiveLineText.toVNode()

        if case .style(name: "-webkit-line-clamp", value: let clamp) = fiveLineNode.props["-webkit-line-clamp"] {
            #expect(clamp == "5")
        } else {
            Issue.record("Five line limit should have -webkit-line-clamp")
        }
    }

    @Test func lineLimitWithNilValue() {
        let text = Text("Unlimited text").lineLimit(nil)
        let node = text.toVNode()

        // With nil, the wrapper should exist but not have the line-clamp properties
        #expect(node.elementTag == "div")

        // Verify no line-clamp properties when nil
        #expect(node.props["-webkit-line-clamp"] == nil)
        #expect(node.props["display"] == nil)
    }

    @Test func lineLimitVNodeStructure() {
        let text = Text("Sample text").lineLimit(3)
        let node = text.toVNode()

        // Verify all required CSS properties are present
        #expect(node.props["display"] != nil)
        #expect(node.props["-webkit-line-clamp"] != nil)
        #expect(node.props["-webkit-box-orient"] != nil)
        #expect(node.props["overflow"] != nil)

        // Count style properties
        let styleCount = node.props.values.filter { prop in
            if case .style = prop { return true }
            return false
        }.count

        #expect(styleCount == 4)
    }

    // MARK: - Multiline Text Alignment Tests (4 tests)

    @Test func multilineTextAlignmentLeading() {
        let text = Text("Left aligned\nMultiple lines")
            .multilineTextAlignment(.leading)

        let node = text.toVNode()

        #expect(node.elementTag == "div")

        if case .style(name: "text-align", value: let align) = node.props["text-align"] {
            #expect(align == "left")
        } else {
            Issue.record("Multiline alignment should have text-align property")
        }
    }

    @Test func multilineTextAlignmentCenter() {
        let text = Text("Centered\nMultiple lines")
            .multilineTextAlignment(.center)

        let node = text.toVNode()

        if case .style(name: "text-align", value: let align) = node.props["text-align"] {
            #expect(align == "center")
        } else {
            Issue.record("Center alignment should have text-align property")
        }
    }

    @Test func multilineTextAlignmentTrailing() {
        let text = Text("Right aligned\nMultiple lines")
            .multilineTextAlignment(.trailing)

        let node = text.toVNode()

        if case .style(name: "text-align", value: let align) = node.props["text-align"] {
            #expect(align == "right")
        } else {
            Issue.record("Trailing alignment should have text-align property")
        }
    }

    @Test func multilineTextAlignmentVNodeStructure() {
        let text = Text("Sample text").multilineTextAlignment(.center)
        let node = text.toVNode()

        // Verify only text-align property is set
        let styleCount = node.props.values.filter { prop in
            if case .style = prop { return true }
            return false
        }.count

        #expect(styleCount == 1)
        #expect(node.props["text-align"] != nil)
    }

    // MARK: - Truncation Mode Tests (4 tests)

    @Test func truncationModeTail() {
        let text = Text("This is a very long text that will be truncated at the end")
            .truncationMode(.tail)

        let node = text.toVNode()

        #expect(node.elementTag == "div")

        // Verify text-overflow: ellipsis
        if case .style(name: "text-overflow", value: let overflow) = node.props["text-overflow"] {
            #expect(overflow == "ellipsis")
        } else {
            Issue.record("Tail truncation should have text-overflow property")
        }

        // Verify overflow: hidden
        if case .style(name: "overflow", value: let overflow) = node.props["overflow"] {
            #expect(overflow == "hidden")
        } else {
            Issue.record("Truncation should have overflow property")
        }

        // Verify white-space: nowrap
        if case .style(name: "white-space", value: let whitespace) = node.props["white-space"] {
            #expect(whitespace == "nowrap")
        } else {
            Issue.record("Truncation should have white-space property")
        }

        // Tail should not have direction property
        #expect(node.props["direction"] == nil)
    }

    @Test func truncationModeHead() {
        let text = Text("This is a very long text that will be truncated at the beginning")
            .truncationMode(.head)

        let node = text.toVNode()

        // Verify direction: rtl for head truncation
        if case .style(name: "direction", value: let direction) = node.props["direction"] {
            #expect(direction == "rtl")
        } else {
            Issue.record("Head truncation should have direction property")
        }

        // Verify text-align: right for head truncation
        if case .style(name: "text-align", value: let align) = node.props["text-align"] {
            #expect(align == "right")
        } else {
            Issue.record("Head truncation should have text-align property")
        }

        // Should still have text-overflow
        #expect(node.props["text-overflow"] != nil)
    }

    @Test func truncationModeMiddle() {
        let text = Text("This is a very long text that will be truncated in the middle")
            .truncationMode(.middle)

        let node = text.toVNode()

        // Middle truncation should have data attribute for enhancement
        if case .attribute(name: "data-truncation", value: let mode) = node.props["data-truncation"] {
            #expect(mode == "middle")
        } else {
            Issue.record("Middle truncation should have data-truncation attribute")
        }

        // Should still have basic truncation styles
        #expect(node.props["overflow"] != nil)
        #expect(node.props["white-space"] != nil)
        #expect(node.props["text-overflow"] != nil)
    }

    @Test func truncationModeVNodeStructure() {
        let tailText = Text("Sample").truncationMode(.tail)
        let headText = Text("Sample").truncationMode(.head)
        let middleText = Text("Sample").truncationMode(.middle)

        let tailNode = tailText.toVNode()
        let headNode = headText.toVNode()
        let middleNode = middleText.toVNode()

        // All should wrap in div
        #expect(tailNode.elementTag == "div")
        #expect(headNode.elementTag == "div")
        #expect(middleNode.elementTag == "div")

        // All should have basic truncation properties
        for node in [tailNode, headNode, middleNode] {
            #expect(node.props["overflow"] != nil)
            #expect(node.props["white-space"] != nil)
            #expect(node.props["text-overflow"] != nil)
        }
    }

    // MARK: - Combined Modifiers Tests (2 tests)

    @Test func combinedLineLimitAndAlignment() {
        let text = Text("Multiple\nLines\nOf\nText")
            .lineLimit(3)
            .multilineTextAlignment(.center)

        // When combined, both modifiers should be present in the hierarchy
        // The outermost modifier (alignment) is applied last
        let node = text.toVNode()

        // The outer node should be the alignment wrapper
        #expect(node.props["text-align"] != nil)
    }

    @Test func combinedLineLimitAndTruncation() {
        let text = Text("Very long text that needs both line limiting and truncation")
            .lineLimit(2)
            .truncationMode(.tail)

        // When combined, both modifiers should be present
        let node = text.toVNode()

        // The outer node should be the truncation wrapper
        #expect(node.props["text-overflow"] != nil)
    }

    // MARK: - Dynamic Type Scaling Tests (4 tests)

    @Test func fontScalingWithDefaultSize() {
        // Test that default size category (1.0) produces correct font size
        let font = Font.body
        let (_, size, _) = font.cssProperties(scale: 1.0)
        #expect(size == "17.0px")
    }

    @Test func fontScalingWithLargerSize() {
        // Test that larger size category scales the font
        let font = Font.body
        let scale = ContentSizeCategory.extraLarge.scaleFactor
        let (_, size, _) = font.cssProperties(scale: scale)

        // extraLarge has scale factor 1.12, so 17 * 1.12 = 19.04 (approximately)
        // Due to floating point precision, check that it starts with "19.04"
        #expect(size.hasPrefix("19.04"))
    }

    @Test func fontScalingWithAccessibilitySize() {
        // Test that accessibility sizes produce significantly larger fonts
        let font = Font.caption
        let scale = ContentSizeCategory.accessibilityLarge.scaleFactor
        let (_, size, _) = font.cssProperties(scale: scale)

        // Caption is 12px, accessibilityLarge has scale factor 1.90, so 12 * 1.90 = 22.8
        #expect(size.hasPrefix("22.8"))
    }

    @Test func fixedSizeFontDoesNotScale() {
        // Test that fixed size fonts don't scale with ContentSizeCategory
        let font = Font.custom("Helvetica", fixedSize: 20)
        let scale = ContentSizeCategory.extraExtraLarge.scaleFactor
        let (_, size, _) = font.cssProperties(scale: scale)

        // Fixed size fonts should not scale
        #expect(size == "20.0px")
    }
}
