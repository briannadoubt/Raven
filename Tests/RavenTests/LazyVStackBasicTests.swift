import XCTest
@testable import Raven

/// Basic tests for LazyVStack to verify it compiles and creates VNodes correctly.
@MainActor
final class LazyVStackBasicTests: XCTestCase {

    func testLazyVStackCompiles() async throws {
        // Just verify it compiles and creates a VNode
        let lazyVStack = LazyVStack {
            Text("Hello")
        }

        let vnode = lazyVStack.toVNode()
        XCTAssertTrue(vnode.isElement(tag: "div"))
    }

    func testLazyVStackWithAllParameters() async throws {
        // Verify all parameters work
        let lazyVStack = LazyVStack(
            alignment: .leading,
            spacing: 10,
            pinnedViews: .sectionHeaders
        ) {
            Text("Content")
        }

        let vnode = lazyVStack.toVNode()
        XCTAssertTrue(vnode.isElement(tag: "div"))
    }
}
