import Testing
@testable import SwiftUI
@testable import RavenCore

@MainActor
@Suite struct ContentTransitionModifiersTests {
    @Test func contentTransitionModifierRendersMetadata() {
        let node = Text("42")
            .contentTransition(.numericText())
            .toVNode()

        #expect(node.elementTag == "div")
        if case .attribute(name: "data-content-transition", value: let value) = node.props["data-content-transition"] {
            #expect(value == "numericText")
        } else {
            Issue.record("Expected data-content-transition attribute")
        }
    }

    @Test func dynamicTypeSizeEnvironmentRoundTrip() {
        var env = EnvironmentValues()
        env.dynamicTypeSize = .xxLarge
        #expect(env.dynamicTypeSize == .xxLarge)
    }

    @Test func colorSchemeContrastEnvironmentRoundTrip() {
        var env = EnvironmentValues()
        env.colorSchemeContrast = .increased
        #expect(env.colorSchemeContrast == .increased)
    }

    @Test func dynamicTypeSizeModifierCompiles() {
        let view = Text("Hello").dynamicTypeSize(.accessibility3)
        #expect(view != nil)
    }

    @Test func colorSchemeContrastModifierCompiles() {
        let view = Text("Hello").colorSchemeContrast(.increased)
        #expect(view != nil)
    }
}
