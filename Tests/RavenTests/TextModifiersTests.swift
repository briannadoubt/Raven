import XCTest
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
@available(macOS 13.0, *)
@MainActor
final class TextModifiersTests: XCTestCase {

    // MARK: - Line Limit Tests (4 tests)

    func testLineLimitBasicUsage() {
        let text = Text("This is a long text that should be limited")
            .lineLimit(2)

        let node = text.toVNode()

        // Verify wrapper element
        XCTAssertEqual(node.elementTag, "div", "Line limit should wrap content in div")

        // Verify -webkit-line-clamp
        if case .style(name: "-webkit-line-clamp", value: let clamp) = node.props["-webkit-line-clamp"] {
            XCTAssertEqual(clamp, "2", "Line limit should set -webkit-line-clamp to 2")
        } else {
            XCTFail("Line limit should have -webkit-line-clamp property")
        }

        // Verify display: -webkit-box
        if case .style(name: "display", value: let display) = node.props["display"] {
            XCTAssertEqual(display, "-webkit-box", "Line limit should set display to -webkit-box")
        } else {
            XCTFail("Line limit should have display property")
        }

        // Verify -webkit-box-orient: vertical
        if case .style(name: "-webkit-box-orient", value: let orient) = node.props["-webkit-box-orient"] {
            XCTAssertEqual(orient, "vertical", "Line limit should set -webkit-box-orient to vertical")
        } else {
            XCTFail("Line limit should have -webkit-box-orient property")
        }

        // Verify overflow: hidden
        if case .style(name: "overflow", value: let overflow) = node.props["overflow"] {
            XCTAssertEqual(overflow, "hidden", "Line limit should set overflow to hidden")
        } else {
            XCTFail("Line limit should have overflow property")
        }
    }

    func testLineLimitWithDifferentValues() {
        // Test with 1 line
        let oneLineText = Text("Short text").lineLimit(1)
        let oneLineNode = oneLineText.toVNode()

        if case .style(name: "-webkit-line-clamp", value: let clamp) = oneLineNode.props["-webkit-line-clamp"] {
            XCTAssertEqual(clamp, "1", "Line limit should handle single line")
        } else {
            XCTFail("Single line limit should have -webkit-line-clamp")
        }

        // Test with 5 lines
        let fiveLineText = Text("Longer text").lineLimit(5)
        let fiveLineNode = fiveLineText.toVNode()

        if case .style(name: "-webkit-line-clamp", value: let clamp) = fiveLineNode.props["-webkit-line-clamp"] {
            XCTAssertEqual(clamp, "5", "Line limit should handle 5 lines")
        } else {
            XCTFail("Five line limit should have -webkit-line-clamp")
        }
    }

    func testLineLimitWithNilValue() {
        let text = Text("Unlimited text").lineLimit(nil)
        let node = text.toVNode()

        // With nil, the wrapper should exist but not have the line-clamp properties
        XCTAssertEqual(node.elementTag, "div", "Line limit with nil should still wrap in div")

        // Verify no line-clamp properties when nil
        XCTAssertNil(node.props["-webkit-line-clamp"], "Nil line limit should not set -webkit-line-clamp")
        XCTAssertNil(node.props["display"], "Nil line limit should not set display")
    }

    func testLineLimitVNodeStructure() {
        let text = Text("Sample text").lineLimit(3)
        let node = text.toVNode()

        // Verify all required CSS properties are present
        XCTAssertNotNil(node.props["display"], "Should have display property")
        XCTAssertNotNil(node.props["-webkit-line-clamp"], "Should have -webkit-line-clamp property")
        XCTAssertNotNil(node.props["-webkit-box-orient"], "Should have -webkit-box-orient property")
        XCTAssertNotNil(node.props["overflow"], "Should have overflow property")

        // Count style properties
        let styleCount = node.props.values.filter { prop in
            if case .style = prop { return true }
            return false
        }.count

        XCTAssertEqual(styleCount, 4, "Line limit should set exactly 4 style properties")
    }

    // MARK: - Multiline Text Alignment Tests (4 tests)

    func testMultilineTextAlignmentLeading() {
        let text = Text("Left aligned\nMultiple lines")
            .multilineTextAlignment(.leading)

        let node = text.toVNode()

        XCTAssertEqual(node.elementTag, "div", "Multiline alignment should wrap content in div")

        if case .style(name: "text-align", value: let align) = node.props["text-align"] {
            XCTAssertEqual(align, "left", "Leading alignment should map to left")
        } else {
            XCTFail("Multiline alignment should have text-align property")
        }
    }

    func testMultilineTextAlignmentCenter() {
        let text = Text("Centered\nMultiple lines")
            .multilineTextAlignment(.center)

        let node = text.toVNode()

        if case .style(name: "text-align", value: let align) = node.props["text-align"] {
            XCTAssertEqual(align, "center", "Center alignment should map to center")
        } else {
            XCTFail("Center alignment should have text-align property")
        }
    }

    func testMultilineTextAlignmentTrailing() {
        let text = Text("Right aligned\nMultiple lines")
            .multilineTextAlignment(.trailing)

        let node = text.toVNode()

        if case .style(name: "text-align", value: let align) = node.props["text-align"] {
            XCTAssertEqual(align, "right", "Trailing alignment should map to right")
        } else {
            XCTFail("Trailing alignment should have text-align property")
        }
    }

    func testMultilineTextAlignmentVNodeStructure() {
        let text = Text("Sample text").multilineTextAlignment(.center)
        let node = text.toVNode()

        // Verify only text-align property is set
        let styleCount = node.props.values.filter { prop in
            if case .style = prop { return true }
            return false
        }.count

        XCTAssertEqual(styleCount, 1, "Multiline alignment should set exactly 1 style property")
        XCTAssertNotNil(node.props["text-align"], "Should have text-align property")
    }

    // MARK: - Truncation Mode Tests (4 tests)

    func testTruncationModeTail() {
        let text = Text("This is a very long text that will be truncated at the end")
            .truncationMode(.tail)

        let node = text.toVNode()

        XCTAssertEqual(node.elementTag, "div", "Truncation mode should wrap content in div")

        // Verify text-overflow: ellipsis
        if case .style(name: "text-overflow", value: let overflow) = node.props["text-overflow"] {
            XCTAssertEqual(overflow, "ellipsis", "Tail truncation should use text-overflow ellipsis")
        } else {
            XCTFail("Tail truncation should have text-overflow property")
        }

        // Verify overflow: hidden
        if case .style(name: "overflow", value: let overflow) = node.props["overflow"] {
            XCTAssertEqual(overflow, "hidden", "Truncation should set overflow hidden")
        } else {
            XCTFail("Truncation should have overflow property")
        }

        // Verify white-space: nowrap
        if case .style(name: "white-space", value: let whitespace) = node.props["white-space"] {
            XCTAssertEqual(whitespace, "nowrap", "Truncation should set white-space nowrap")
        } else {
            XCTFail("Truncation should have white-space property")
        }

        // Tail should not have direction property
        XCTAssertNil(node.props["direction"], "Tail truncation should not set direction")
    }

    func testTruncationModeHead() {
        let text = Text("This is a very long text that will be truncated at the beginning")
            .truncationMode(.head)

        let node = text.toVNode()

        // Verify direction: rtl for head truncation
        if case .style(name: "direction", value: let direction) = node.props["direction"] {
            XCTAssertEqual(direction, "rtl", "Head truncation should use RTL direction")
        } else {
            XCTFail("Head truncation should have direction property")
        }

        // Verify text-align: right for head truncation
        if case .style(name: "text-align", value: let align) = node.props["text-align"] {
            XCTAssertEqual(align, "right", "Head truncation should align right")
        } else {
            XCTFail("Head truncation should have text-align property")
        }

        // Should still have text-overflow
        XCTAssertNotNil(node.props["text-overflow"], "Head truncation should have text-overflow")
    }

    func testTruncationModeMiddle() {
        let text = Text("This is a very long text that will be truncated in the middle")
            .truncationMode(.middle)

        let node = text.toVNode()

        // Middle truncation should have data attribute for enhancement
        if case .attribute(name: "data-truncation", value: let mode) = node.props["data-truncation"] {
            XCTAssertEqual(mode, "middle", "Middle truncation should have data-truncation attribute")
        } else {
            XCTFail("Middle truncation should have data-truncation attribute")
        }

        // Should still have basic truncation styles
        XCTAssertNotNil(node.props["overflow"], "Middle truncation should have overflow")
        XCTAssertNotNil(node.props["white-space"], "Middle truncation should have white-space")
        XCTAssertNotNil(node.props["text-overflow"], "Middle truncation should have text-overflow")
    }

    func testTruncationModeVNodeStructure() {
        let tailText = Text("Sample").truncationMode(.tail)
        let headText = Text("Sample").truncationMode(.head)
        let middleText = Text("Sample").truncationMode(.middle)

        let tailNode = tailText.toVNode()
        let headNode = headText.toVNode()
        let middleNode = middleText.toVNode()

        // All should wrap in div
        XCTAssertEqual(tailNode.elementTag, "div", "Tail truncation should use div")
        XCTAssertEqual(headNode.elementTag, "div", "Head truncation should use div")
        XCTAssertEqual(middleNode.elementTag, "div", "Middle truncation should use div")

        // All should have basic truncation properties
        for node in [tailNode, headNode, middleNode] {
            XCTAssertNotNil(node.props["overflow"], "Should have overflow property")
            XCTAssertNotNil(node.props["white-space"], "Should have white-space property")
            XCTAssertNotNil(node.props["text-overflow"], "Should have text-overflow property")
        }
    }

    // MARK: - Combined Modifiers Tests (2 tests)

    func testCombinedLineLimitAndAlignment() {
        let text = Text("Multiple\nLines\nOf\nText")
            .lineLimit(3)
            .multilineTextAlignment(.center)

        // When combined, both modifiers should be present in the hierarchy
        // The outermost modifier (alignment) is applied last
        let node = text.toVNode()

        // The outer node should be the alignment wrapper
        XCTAssertNotNil(node.props["text-align"], "Combined modifiers should include alignment")
    }

    func testCombinedLineLimitAndTruncation() {
        let text = Text("Very long text that needs both line limiting and truncation")
            .lineLimit(2)
            .truncationMode(.tail)

        // When combined, both modifiers should be present
        let node = text.toVNode()

        // The outer node should be the truncation wrapper
        XCTAssertNotNil(node.props["text-overflow"], "Combined modifiers should include truncation")
    }

    // MARK: - Dynamic Type Scaling Tests (4 tests)

    func testFontScalingWithDefaultSize() {
        // Test that default size category (1.0) produces correct font size
        let font = Font.body
        let (_, size, _) = font.cssProperties(scale: 1.0)
        XCTAssertEqual(size, "17.0px", "Body font at default scale should be 17px")
    }

    func testFontScalingWithLargerSize() {
        // Test that larger size category scales the font
        let font = Font.body
        let scale = ContentSizeCategory.extraLarge.scaleFactor
        let (_, size, _) = font.cssProperties(scale: scale)

        // extraLarge has scale factor 1.12, so 17 * 1.12 = 19.04 (approximately)
        // Due to floating point precision, check that it starts with "19.04"
        XCTAssertTrue(size.hasPrefix("19.04"), "Body font at extraLarge scale should be approximately 19.04px, got \(size)")
    }

    func testFontScalingWithAccessibilitySize() {
        // Test that accessibility sizes produce significantly larger fonts
        let font = Font.caption
        let scale = ContentSizeCategory.accessibilityLarge.scaleFactor
        let (_, size, _) = font.cssProperties(scale: scale)

        // Caption is 12px, accessibilityLarge has scale factor 1.90, so 12 * 1.90 = 22.8
        XCTAssertTrue(size.hasPrefix("22.8"), "Caption font at accessibilityLarge should be approximately 22.8px, got \(size)")
    }

    func testFixedSizeFontDoesNotScale() {
        // Test that fixed size fonts don't scale with ContentSizeCategory
        let font = Font.custom("Helvetica", fixedSize: 20)
        let scale = ContentSizeCategory.extraExtraLarge.scaleFactor
        let (_, size, _) = font.cssProperties(scale: scale)

        // Fixed size fonts should not scale
        XCTAssertEqual(size, "20.0px", "Fixed size fonts should not scale with ContentSizeCategory")
    }
}
