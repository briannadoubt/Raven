import Testing
@testable import Raven

/// Basic tests for LazyVStack to verify it compiles and creates VNodes correctly.
@MainActor
@Suite struct LazyVStackBasicTests {

    @Test func lazyVStackCompiles() async throws {
        // Just verify it compiles and creates a VNode
        let lazyVStack = LazyVStack {
            Text("Hello")
        }

        let vnode = lazyVStack.toVNode()
        #expect(vnode.isElement(tag: "div"))
    }

    @Test func lazyVStackWithAllParameters() async throws {
        // Verify all parameters work
        let lazyVStack = LazyVStack(
            alignment: .leading,
            spacing: 10,
            pinnedViews: .sectionHeaders
        ) {
            Text("Content")
        }

        let vnode = lazyVStack.toVNode()
        #expect(vnode.isElement(tag: "div"))
    }
}
