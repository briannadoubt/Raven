import Testing
@testable import Raven

/// Tests for ScrollView rendering and configuration
@Suite("ScrollView Tests")
struct ScrollViewTests {

    // MARK: - Basic Rendering Tests

    @Test("ScrollView creates a div element")
    func testBasicScrollView() async throws {
        let scrollView = ScrollView {
            Text("Hello, World!")
        }

        let vnode = await scrollView.toVNode()

        #expect(vnode.elementTag == "div")
    }

    @Test("ScrollView has role attribute for accessibility")
    func testScrollViewRoleAttribute() async throws {
        let scrollView = ScrollView {
            Text("Content")
        }

        let vnode = await scrollView.toVNode()

        // Check for role attribute
        let hasRole = vnode.props.contains { key, value in
            if case .attribute(let name, let val) = value {
                return name == "role" && val == "region"
            }
            return false
        }
        #expect(hasRole)
    }

    @Test("ScrollView has CSS class")
    func testScrollViewCSSClass() async throws {
        let scrollView = ScrollView {
            Text("Content")
        }

        let vnode = await scrollView.toVNode()

        // Check for class attribute
        let hasClass = vnode.props.contains { key, value in
            if case .attribute(let name, let val) = value {
                return name == "class" && val.contains("raven-scroll-view")
            }
            return false
        }
        #expect(hasClass)
    }

    // MARK: - Axis Configuration Tests

    @Test("ScrollView with vertical axis has correct overflow properties")
    func testVerticalScrollView() async throws {
        let scrollView = ScrollView(.vertical) {
            Text("Content")
        }

        let vnode = await scrollView.toVNode()

        // Check overflow-y is auto
        let hasOverflowY = vnode.props.contains { key, value in
            if case .style(let name, let val) = value {
                return name == "overflow-y" && val == "auto"
            }
            return false
        }
        #expect(hasOverflowY)

        // Check overflow-x is visible
        let hasOverflowX = vnode.props.contains { key, value in
            if case .style(let name, let val) = value {
                return name == "overflow-x" && val == "visible"
            }
            return false
        }
        #expect(hasOverflowX)
    }

    @Test("ScrollView with horizontal axis has correct overflow properties")
    func testHorizontalScrollView() async throws {
        let scrollView = ScrollView(.horizontal) {
            Text("Content")
        }

        let vnode = await scrollView.toVNode()

        // Check overflow-x is auto
        let hasOverflowX = vnode.props.contains { key, value in
            if case .style(let name, let val) = value {
                return name == "overflow-x" && val == "auto"
            }
            return false
        }
        #expect(hasOverflowX)

        // Check overflow-y is visible
        let hasOverflowY = vnode.props.contains { key, value in
            if case .style(let name, let val) = value {
                return name == "overflow-y" && val == "visible"
            }
            return false
        }
        #expect(hasOverflowY)
    }

    @Test("ScrollView with both axes has correct overflow properties")
    func testBothAxesScrollView() async throws {
        let scrollView = ScrollView([.horizontal, .vertical]) {
            Text("Content")
        }

        let vnode = await scrollView.toVNode()

        // Check overflow-y is auto
        let hasOverflowY = vnode.props.contains { key, value in
            if case .style(let name, let val) = value {
                return name == "overflow-y" && val == "auto"
            }
            return false
        }
        #expect(hasOverflowY)

        // Check overflow-x is auto
        let hasOverflowX = vnode.props.contains { key, value in
            if case .style(let name, let val) = value {
                return name == "overflow-x" && val == "auto"
            }
            return false
        }
        #expect(hasOverflowX)
    }

    // MARK: - Scroll Indicator Tests

    @Test("ScrollView with indicators shown (default)")
    func testScrollViewWithIndicators() async throws {
        let scrollView = ScrollView(showsIndicators: true) {
            Text("Content")
        }

        let vnode = await scrollView.toVNode()

        // Should NOT have scrollbar-width: none
        let hasScrollbarWidth = vnode.props.contains { key, value in
            if case .style(let name, let val) = value {
                return name == "scrollbar-width" && val == "none"
            }
            return false
        }
        #expect(!hasScrollbarWidth)
    }

    @Test("ScrollView with indicators hidden")
    func testScrollViewWithoutIndicators() async throws {
        let scrollView = ScrollView(showsIndicators: false) {
            Text("Content")
        }

        let vnode = await scrollView.toVNode()

        // Check for scrollbar-width: none
        let hasScrollbarWidth = vnode.props.contains { key, value in
            if case .style(let name, let val) = value {
                return name == "scrollbar-width" && val == "none"
            }
            return false
        }
        #expect(hasScrollbarWidth)

        // Check for -ms-overflow-style: none
        let hasMsOverflowStyle = vnode.props.contains { key, value in
            if case .style(let name, let val) = value {
                return name == "-ms-overflow-style" && val == "none"
            }
            return false
        }
        #expect(hasMsOverflowStyle)

        // Check for hide-scrollbars class
        let hasHideScrollbarsClass = vnode.props.contains { key, value in
            if case .attribute(let name, let val) = value {
                return name == "class" && val.contains("hide-scrollbars")
            }
            return false
        }
        #expect(hasHideScrollbarsClass)
    }

    // MARK: - Layout Style Tests

    @Test("ScrollView has display: block")
    func testScrollViewDisplayBlock() async throws {
        let scrollView = ScrollView {
            Text("Content")
        }

        let vnode = await scrollView.toVNode()

        let hasDisplayBlock = vnode.props.contains { key, value in
            if case .style(let name, let val) = value {
                return name == "display" && val == "block"
            }
            return false
        }
        #expect(hasDisplayBlock)
    }

    @Test("ScrollView has default width and height")
    func testScrollViewDefaultSize() async throws {
        let scrollView = ScrollView {
            Text("Content")
        }

        let vnode = await scrollView.toVNode()

        // Check for width: 100%
        let hasWidth = vnode.props.contains { key, value in
            if case .style(let name, let val) = value {
                return name == "width" && val == "100%"
            }
            return false
        }
        #expect(hasWidth)

        // Check for height: 100%
        let hasHeight = vnode.props.contains { key, value in
            if case .style(let name, let val) = value {
                return name == "height" && val == "100%"
            }
            return false
        }
        #expect(hasHeight)
    }

    // MARK: - Content Tests

    @Test("ScrollView is Sendable")
    func testScrollViewSendable() async throws {
        // This test verifies that ScrollView conforms to Sendable
        // by attempting to use it in an async context
        let scrollView = ScrollView {
            Text("Content")
        }

        Task {
            let _ = await scrollView.toVNode()
        }

        // If this compiles, the test passes
        #expect(true)
    }

    @Test("ScrollView with complex content")
    func testScrollViewWithComplexContent() async throws {
        let scrollView = ScrollView {
            VStack {
                Text("Title")
                Text("Subtitle")
                HStack {
                    Text("Left")
                    Text("Right")
                }
            }
        }

        let vnode = await scrollView.toVNode()

        // Verify it's still a div element
        #expect(vnode.elementTag == "div")

        // Verify it has the scroll view properties
        let hasOverflowY = vnode.props.contains { key, value in
            if case .style(let name, let val) = value {
                return name == "overflow-y" && val == "auto"
            }
            return false
        }
        #expect(hasOverflowY)
    }

    // MARK: - Integration Tests

    @Test("ScrollView works with default parameters")
    func testScrollViewDefaultParameters() async throws {
        // Test the most common use case: default vertical scrolling with indicators
        let scrollView = ScrollView {
            Text("Content")
        }

        let vnode = await scrollView.toVNode()

        // Should be vertical scrolling
        let hasOverflowY = vnode.props.contains { key, value in
            if case .style(let name, let val) = value {
                return name == "overflow-y" && val == "auto"
            }
            return false
        }
        #expect(hasOverflowY)

        // Should show indicators (no scrollbar-width: none)
        let hasScrollbarWidth = vnode.props.contains { key, value in
            if case .style(let name, let val) = value {
                return name == "scrollbar-width" && val == "none"
            }
            return false
        }
        #expect(!hasScrollbarWidth)
    }

    @Test("ScrollView conforms to View protocol")
    func testScrollViewConformsToView() async throws {
        let scrollView = ScrollView {
            Text("Content")
        }

        // This should compile because ScrollView conforms to View
        let _: any View = scrollView
        #expect(true)
    }

    @Test("ScrollView conforms to PrimitiveView protocol")
    func testScrollViewConformsToPrimitiveView() async throws {
        let scrollView = ScrollView {
            Text("Content")
        }

        // This should compile because ScrollView conforms to PrimitiveView
        let _: any PrimitiveView = scrollView
        #expect(true)
    }
}
