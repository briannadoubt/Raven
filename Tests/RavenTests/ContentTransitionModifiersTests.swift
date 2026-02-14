import Testing
@testable import SwiftUI
@testable import RavenCore

@MainActor
@Suite struct ContentTransitionModifiersTests {
    @Test func contentTransitionModifierCompiles() {
        let view = Text("42").contentTransition(.numericText())
        #expect(view != nil)
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
