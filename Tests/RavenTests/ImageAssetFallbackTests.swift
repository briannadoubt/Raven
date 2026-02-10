import Testing
@testable import SwiftUI
@testable import RavenCore

@Suite("Image Asset Fallback Tests")
@MainActor
struct ImageAssetFallbackTests {
    @Test("Image(name) falls back to /assets/name when no manifest is present")
    func fallbackPath() {
        let vnode = Image("Foo").toVNode()
        if case .element(let tag) = vnode.type {
            #expect(tag == "img")
        } else {
            #expect(Bool(false))
        }

        let prop = vnode.props["src"]
        #expect(prop == .attribute(name: "src", value: "/assets/Foo"))
    }
}

