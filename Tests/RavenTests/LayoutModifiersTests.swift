import XCTest
@testable import Raven

/// Tests for layout modifiers (.clipped, .aspectRatio, .fixedSize)
final class LayoutModifiersTests: XCTestCase {

    // MARK: - Clipped Modifier Tests

    @MainActor
    func testClipped() {
        // Create a view with clipped modifier
        let view = Text("Hello")
            .clipped()

        // Verify the type is correct
        XCTAssertTrue(view is _ClippedView<Text>)
    }

    @MainActor
    func testClippedWithFrame() {
        // Test clipped with a frame modifier
        let view = Text("Long text that might overflow")
            .frame(width: 100, height: 50)
            .clipped()

        // Should compile and create the correct type
        let _ = view
    }

    @MainActor
    func testClippedVNodeGeneration() {
        // Test that clipped generates the correct VNode
        let view = Text("Content").clipped()
        let vnode = view.toVNode()

        // Verify it's an element
        if case .element(let tag, let props, _) = vnode {
            XCTAssertEqual(tag, "div")

            // Check for overflow: hidden style
            if case .style(let name, let value) = props["overflow"] {
                XCTAssertEqual(name, "overflow")
                XCTAssertEqual(value, "hidden")
            } else {
                XCTFail("Expected overflow style property")
            }
        } else {
            XCTFail("Expected element VNode")
        }
    }

    // MARK: - AspectRatio Modifier Tests

    @MainActor
    func testAspectRatioWithFit() {
        // Create a view with aspect ratio fit
        let view = Text("Content")
            .aspectRatio(16/9, contentMode: .fit)

        // Verify the type is correct
        XCTAssertTrue(view is _AspectRatioView<Text>)
    }

    @MainActor
    func testAspectRatioWithFill() {
        // Create a view with aspect ratio fill
        let view = Text("Content")
            .aspectRatio(1, contentMode: .fill)

        // Verify the type is correct
        XCTAssertTrue(view is _AspectRatioView<Text>)
    }

    @MainActor
    func testAspectRatioWithNilRatio() {
        // Create a view with nil aspect ratio (uses intrinsic)
        let view = Text("Content")
            .aspectRatio(contentMode: .fit)

        // Should compile and create the correct type
        let _ = view
    }

    @MainActor
    func testAspectRatioSquare() {
        // Test a square aspect ratio (1:1)
        let view = Text("Square")
            .aspectRatio(1, contentMode: .fit)

        // Should compile correctly
        let _ = view
    }

    @MainActor
    func testAspectRatioWidescreen() {
        // Test a widescreen aspect ratio (16:9)
        let view = Text("Widescreen")
            .aspectRatio(16/9, contentMode: .fill)

        // Should compile correctly
        let _ = view
    }

    @MainActor
    func testAspectRatioPortrait() {
        // Test a portrait aspect ratio (9:16)
        let view = Text("Portrait")
            .aspectRatio(9/16, contentMode: .fit)

        // Should compile correctly
        let _ = view
    }

    @MainActor
    func testAspectRatioFitVNodeGeneration() {
        // Test that aspect ratio fit generates the correct VNode
        let view = Text("Content")
            .aspectRatio(2, contentMode: .fit)
        let vnode = view.toVNode()

        // Verify it's an element
        if case .element(let tag, let props, _) = vnode {
            XCTAssertEqual(tag, "div")

            // Check for aspect-ratio style
            if case .style(let name, let value) = props["aspect-ratio"] {
                XCTAssertEqual(name, "aspect-ratio")
                XCTAssertEqual(value, "2.0")
            } else {
                XCTFail("Expected aspect-ratio style property")
            }

            // Check for object-fit: contain
            if case .style(let name, let value) = props["object-fit"] {
                XCTAssertEqual(name, "object-fit")
                XCTAssertEqual(value, "contain")
            } else {
                XCTFail("Expected object-fit style property")
            }
        } else {
            XCTFail("Expected element VNode")
        }
    }

    @MainActor
    func testAspectRatioFillVNodeGeneration() {
        // Test that aspect ratio fill generates the correct VNode
        let view = Text("Content")
            .aspectRatio(1, contentMode: .fill)
        let vnode = view.toVNode()

        // Verify it's an element
        if case .element(let tag, let props, _) = vnode {
            XCTAssertEqual(tag, "div")

            // Check for object-fit: cover
            if case .style(let name, let value) = props["object-fit"] {
                XCTAssertEqual(name, "object-fit")
                XCTAssertEqual(value, "cover")
            } else {
                XCTFail("Expected object-fit style property")
            }
        } else {
            XCTFail("Expected element VNode")
        }
    }

    // MARK: - FixedSize Modifier Tests

    @MainActor
    func testFixedSizeBothAxes() {
        // Create a view with fixed size on both axes (default)
        let view = Text("Fixed")
            .fixedSize()

        // Verify the type is correct
        XCTAssertTrue(view is _FixedSizeView<Text>)
    }

    @MainActor
    func testFixedSizeHorizontalOnly() {
        // Create a view with fixed horizontal size
        let view = Text("Horizontal")
            .fixedSize(horizontal: true, vertical: false)

        // Should compile correctly
        let _ = view
    }

    @MainActor
    func testFixedSizeVerticalOnly() {
        // Create a view with fixed vertical size
        let view = Text("Vertical")
            .fixedSize(horizontal: false, vertical: true)

        // Should compile correctly
        let _ = view
    }

    @MainActor
    func testFixedSizeNeitherAxis() {
        // Create a view with no fixed size (edge case)
        let view = Text("Neither")
            .fixedSize(horizontal: false, vertical: false)

        // Should compile correctly
        let _ = view
    }

    @MainActor
    func testFixedSizeWithLongText() {
        // Test fixed size with long text that might wrap
        let view = Text("This is a very long piece of text that might need to wrap")
            .fixedSize(horizontal: false, vertical: true)

        // Should compile correctly
        let _ = view
    }

    @MainActor
    func testFixedSizeVNodeGenerationBothAxes() {
        // Test that fixed size generates the correct VNode
        let view = Text("Content")
            .fixedSize()
        let vnode = view.toVNode()

        // Verify it's an element
        if case .element(let tag, let props, _) = vnode {
            XCTAssertEqual(tag, "div")

            // Check for width: fit-content
            if case .style(let name, let value) = props["width"] {
                XCTAssertEqual(name, "width")
                XCTAssertEqual(value, "fit-content")
            } else {
                XCTFail("Expected width style property")
            }

            // Check for height: fit-content
            if case .style(let name, let value) = props["height"] {
                XCTAssertEqual(name, "height")
                XCTAssertEqual(value, "fit-content")
            } else {
                XCTFail("Expected height style property")
            }

            // Check for flex-shrink: 0
            if case .style(let name, let value) = props["flex-shrink"] {
                XCTAssertEqual(name, "flex-shrink")
                XCTAssertEqual(value, "0")
            } else {
                XCTFail("Expected flex-shrink style property")
            }
        } else {
            XCTFail("Expected element VNode")
        }
    }

    @MainActor
    func testFixedSizeVNodeGenerationHorizontalOnly() {
        // Test that fixed size horizontal generates the correct VNode
        let view = Text("Content")
            .fixedSize(horizontal: true, vertical: false)
        let vnode = view.toVNode()

        // Verify it's an element
        if case .element(let tag, let props, _) = vnode {
            XCTAssertEqual(tag, "div")

            // Check for width: fit-content
            if case .style(let name, let value) = props["width"] {
                XCTAssertEqual(name, "width")
                XCTAssertEqual(value, "fit-content")
            } else {
                XCTFail("Expected width style property")
            }

            // Height should not be set
            XCTAssertNil(props["height"])
        } else {
            XCTFail("Expected element VNode")
        }
    }

    // MARK: - Modifier Composition Tests

    @MainActor
    func testClippedWithAspectRatio() {
        // Combine clipped and aspect ratio modifiers
        let view = Text("Content")
            .aspectRatio(16/9, contentMode: .fill)
            .clipped()

        // Should compile correctly
        let _ = view
    }

    @MainActor
    func testAspectRatioWithFixedSize() {
        // Combine aspect ratio and fixed size modifiers
        let view = Text("Content")
            .fixedSize()
            .aspectRatio(1, contentMode: .fit)

        // Should compile correctly
        let _ = view
    }

    @MainActor
    func testAllLayoutModifiersTogether() {
        // Combine all layout modifiers
        let view = Text("Content")
            .frame(width: 200, height: 200)
            .aspectRatio(1, contentMode: .fill)
            .clipped()
            .fixedSize(horizontal: false, vertical: true)

        // Should compile correctly
        let _ = view
    }

    @MainActor
    func testLayoutModifiersWithOtherModifiers() {
        // Mix layout modifiers with other modifiers
        let view = Text("Complex")
            .padding(10)
            .aspectRatio(16/9, contentMode: .fit)
            .background(.blue)
            .clipped()
            .cornerRadius(8)
            .fixedSize(horizontal: true, vertical: false)

        // Should compile correctly
        let _ = view
    }

    // MARK: - ContentMode Tests

    @MainActor
    func testContentModeFit() {
        // Test ContentMode.fit
        let mode: ContentMode = .fit
        XCTAssertEqual(mode, .fit)
    }

    @MainActor
    func testContentModeFill() {
        // Test ContentMode.fill
        let mode: ContentMode = .fill
        XCTAssertEqual(mode, .fill)
    }

    @MainActor
    func testContentModeHashable() {
        // Test that ContentMode is Hashable
        let modes: Set<ContentMode> = [.fit, .fill]
        XCTAssertEqual(modes.count, 2)
    }

    @MainActor
    func testContentModeSendable() {
        // Test that ContentMode is Sendable
        let mode: ContentMode & Sendable = .fit
        let _ = mode
    }

    // MARK: - Sendable and Concurrency Tests

    @MainActor
    func testLayoutModifiersAreSendable() {
        // Verify that layout modifier views conform to Sendable
        let clipped = Text("Test").clipped()
        let aspectRatio = Text("Test").aspectRatio(1, contentMode: .fit)
        let fixedSize = Text("Test").fixedSize()

        let _: any View & Sendable = clipped
        let _: any View & Sendable = aspectRatio
        let _: any View & Sendable = fixedSize
    }

    // MARK: - Edge Cases

    @MainActor
    func testAspectRatioWithZero() {
        // Test aspect ratio with zero (edge case)
        let view = Text("Zero")
            .aspectRatio(0, contentMode: .fit)

        // Should compile (though may not render meaningfully)
        let _ = view
    }

    @MainActor
    func testAspectRatioWithLargeValue() {
        // Test aspect ratio with large value
        let view = Text("Large")
            .aspectRatio(1000, contentMode: .fill)

        // Should compile correctly
        let _ = view
    }

    @MainActor
    func testAspectRatioWithVerySmallValue() {
        // Test aspect ratio with very small value
        let view = Text("Small")
            .aspectRatio(0.001, contentMode: .fit)

        // Should compile correctly
        let _ = view
    }
}
