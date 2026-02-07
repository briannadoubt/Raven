import Testing
@testable import Raven

/// Tests for layout modifiers (.clipped, .aspectRatio, .fixedSize)
@MainActor
@Suite struct LayoutModifiersTests {

    // MARK: - Clipped Modifier Tests

    @MainActor
    @Test func clipped() {
        // Create a view with clipped modifier
        let view = Text("Hello")
            .clipped()

        // Verify the type is correct
        #expect(view is _ClippedView<Text>)
    }

    @MainActor
    @Test func clippedWithFrame() {
        // Test clipped with a frame modifier
        let view = Text("Long text that might overflow")
            .frame(width: 100, height: 50)
            .clipped()

        // Should compile and create the correct type
        let _ = view
    }

    @MainActor
    @Test func clippedVNodeGeneration() {
        // Test that clipped generates the correct VNode
        let view = Text("Content").clipped()
        let vnode = view.toVNode()

        // Verify it's an element
        if case .element(let tag) = vnode.type {
            #expect(tag == "div")

            // Check for overflow: hidden style
            if case .style(let name, let value) = vnode.props["overflow"] {
                #expect(name == "overflow")
                #expect(value == "hidden")
            } else {
                Issue.record("Expected overflow style property")
            }
        } else {
            Issue.record("Expected element VNode")
        }
    }

    // MARK: - AspectRatio Modifier Tests

    @MainActor
    @Test func aspectRatioWithFit() {
        // Create a view with aspect ratio fit
        let view = Text("Content")
            .aspectRatio(16/9, contentMode: .fit)

        // Verify the type is correct
        #expect(view is _AspectRatioView<Text>)
    }

    @MainActor
    @Test func aspectRatioWithFill() {
        // Create a view with aspect ratio fill
        let view = Text("Content")
            .aspectRatio(1, contentMode: .fill)

        // Verify the type is correct
        #expect(view is _AspectRatioView<Text>)
    }

    @MainActor
    @Test func aspectRatioWithNilRatio() {
        // Create a view with nil aspect ratio (uses intrinsic)
        let view = Text("Content")
            .aspectRatio(contentMode: .fit)

        // Should compile and create the correct type
        let _ = view
    }

    @MainActor
    @Test func aspectRatioSquare() {
        // Test a square aspect ratio (1:1)
        let view = Text("Square")
            .aspectRatio(1, contentMode: .fit)

        // Should compile correctly
        let _ = view
    }

    @MainActor
    @Test func aspectRatioWidescreen() {
        // Test a widescreen aspect ratio (16:9)
        let view = Text("Widescreen")
            .aspectRatio(16/9, contentMode: .fill)

        // Should compile correctly
        let _ = view
    }

    @MainActor
    @Test func aspectRatioPortrait() {
        // Test a portrait aspect ratio (9:16)
        let view = Text("Portrait")
            .aspectRatio(9/16, contentMode: .fit)

        // Should compile correctly
        let _ = view
    }

    @MainActor
    @Test func aspectRatioFitVNodeGeneration() {
        // Test that aspect ratio fit generates the correct VNode
        let view = Text("Content")
            .aspectRatio(2, contentMode: .fit)
        let vnode = view.toVNode()

        // Verify it's an element
        if case .element(let tag) = vnode.type {
            #expect(tag == "div")

            // Check for aspect-ratio style
            if case .style(let name, let value) = vnode.props["aspect-ratio"] {
                #expect(name == "aspect-ratio")
                #expect(value == "2.0")
            } else {
                Issue.record("Expected aspect-ratio style property")
            }

            // Check for object-fit: contain
            if case .style(let name, let value) = vnode.props["object-fit"] {
                #expect(name == "object-fit")
                #expect(value == "contain")
            } else {
                Issue.record("Expected object-fit style property")
            }
        } else {
            Issue.record("Expected element VNode")
        }
    }

    @MainActor
    @Test func aspectRatioFillVNodeGeneration() {
        // Test that aspect ratio fill generates the correct VNode
        let view = Text("Content")
            .aspectRatio(1, contentMode: .fill)
        let vnode = view.toVNode()

        // Verify it's an element
        if case .element(let tag) = vnode.type {
            #expect(tag == "div")

            // Check for object-fit: cover
            if case .style(let name, let value) = vnode.props["object-fit"] {
                #expect(name == "object-fit")
                #expect(value == "cover")
            } else {
                Issue.record("Expected object-fit style property")
            }
        } else {
            Issue.record("Expected element VNode")
        }
    }

    // MARK: - FixedSize Modifier Tests

    @MainActor
    @Test func fixedSizeBothAxes() {
        // Create a view with fixed size on both axes (default)
        let view = Text("Fixed")
            .fixedSize()

        // Verify the type is correct
        #expect(view is _FixedSizeView<Text>)
    }

    @MainActor
    @Test func fixedSizeHorizontalOnly() {
        // Create a view with fixed horizontal size
        let view = Text("Horizontal")
            .fixedSize(horizontal: true, vertical: false)

        // Should compile correctly
        let _ = view
    }

    @MainActor
    @Test func fixedSizeVerticalOnly() {
        // Create a view with fixed vertical size
        let view = Text("Vertical")
            .fixedSize(horizontal: false, vertical: true)

        // Should compile correctly
        let _ = view
    }

    @MainActor
    @Test func fixedSizeNeitherAxis() {
        // Create a view with no fixed size (edge case)
        let view = Text("Neither")
            .fixedSize(horizontal: false, vertical: false)

        // Should compile correctly
        let _ = view
    }

    @MainActor
    @Test func fixedSizeWithLongText() {
        // Test fixed size with long text that might wrap
        let view = Text("This is a very long piece of text that might need to wrap")
            .fixedSize(horizontal: false, vertical: true)

        // Should compile correctly
        let _ = view
    }

    @MainActor
    @Test func fixedSizeVNodeGenerationBothAxes() {
        // Test that fixed size generates the correct VNode
        let view = Text("Content")
            .fixedSize()
        let vnode = view.toVNode()

        // Verify it's an element
        if case .element(let tag) = vnode.type {
            #expect(tag == "div")

            // Check for width: fit-content
            if case .style(let name, let value) = vnode.props["width"] {
                #expect(name == "width")
                #expect(value == "fit-content")
            } else {
                Issue.record("Expected width style property")
            }

            // Check for height: fit-content
            if case .style(let name, let value) = vnode.props["height"] {
                #expect(name == "height")
                #expect(value == "fit-content")
            } else {
                Issue.record("Expected height style property")
            }

            // Check for flex-shrink: 0
            if case .style(let name, let value) = vnode.props["flex-shrink"] {
                #expect(name == "flex-shrink")
                #expect(value == "0")
            } else {
                Issue.record("Expected flex-shrink style property")
            }
        } else {
            Issue.record("Expected element VNode")
        }
    }

    @MainActor
    @Test func fixedSizeVNodeGenerationHorizontalOnly() {
        // Test that fixed size horizontal generates the correct VNode
        let view = Text("Content")
            .fixedSize(horizontal: true, vertical: false)
        let vnode = view.toVNode()

        // Verify it's an element
        if case .element(let tag) = vnode.type {
            #expect(tag == "div")

            // Check for width: fit-content
            if case .style(let name, let value) = vnode.props["width"] {
                #expect(name == "width")
                #expect(value == "fit-content")
            } else {
                Issue.record("Expected width style property")
            }

            // Height should not be set
            #expect(vnode.props["height"] == nil)
        } else {
            Issue.record("Expected element VNode")
        }
    }

    // MARK: - Modifier Composition Tests

    @MainActor
    @Test func clippedWithAspectRatio() {
        // Combine clipped and aspect ratio modifiers
        let view = Text("Content")
            .aspectRatio(16/9, contentMode: .fill)
            .clipped()

        // Should compile correctly
        let _ = view
    }

    @MainActor
    @Test func aspectRatioWithFixedSize() {
        // Combine aspect ratio and fixed size modifiers
        let view = Text("Content")
            .fixedSize()
            .aspectRatio(1, contentMode: .fit)

        // Should compile correctly
        let _ = view
    }

    @MainActor
    @Test func allLayoutModifiersTogether() {
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
    @Test func layoutModifiersWithOtherModifiers() {
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
    @Test func contentModeFit() {
        // Test ContentMode.fit
        let mode: ContentMode = .fit
        #expect(mode == .fit)
    }

    @MainActor
    @Test func contentModeFill() {
        // Test ContentMode.fill
        let mode: ContentMode = .fill
        #expect(mode == .fill)
    }

    @MainActor
    @Test func contentModeHashable() {
        // Test that ContentMode is Hashable
        let modes: Set<ContentMode> = [.fit, .fill]
        #expect(modes.count == 2)
    }

    @MainActor
    @Test func contentModeSendable() {
        // Test that ContentMode is Sendable (ContentMode already conforms to Sendable)
        let mode: ContentMode = .fit
        let _: any Sendable = mode
    }

    // MARK: - Sendable and Concurrency Tests

    @MainActor
    @Test func layoutModifiersAreSendable() {
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
    @Test func aspectRatioWithZero() {
        // Test aspect ratio with zero (edge case)
        let view = Text("Zero")
            .aspectRatio(0, contentMode: .fit)

        // Should compile (though may not render meaningfully)
        let _ = view
    }

    @MainActor
    @Test func aspectRatioWithLargeValue() {
        // Test aspect ratio with large value
        let view = Text("Large")
            .aspectRatio(1000, contentMode: .fill)

        // Should compile correctly
        let _ = view
    }

    @MainActor
    @Test func aspectRatioWithVerySmallValue() {
        // Test aspect ratio with very small value
        let view = Text("Small")
            .aspectRatio(0.001, contentMode: .fit)

        // Should compile correctly
        let _ = view
    }
}
