import Testing
@testable import SwiftUI
@testable import RavenCore

@MainActor
@Suite struct DefaultLabelComponentsTests {
    @Test func defaultLabelComponentsCompileAsViews() async throws {
        func acceptsView<V: View>(_ value: V) -> Bool {
            _ = value
            return true
        }

        #expect(acceptsView(DefaultButtonLabel()))
        #expect(acceptsView(DefaultDateProgressLabel()))
        #expect(acceptsView(DefaultShareLinkLabel()))
        #expect(acceptsView(CurrentValueLabel()))
        #expect(acceptsView(MinimumValueLabel()))
        #expect(acceptsView(MaximumValueLabel()))
        #expect(acceptsView(MarkedValueLabel()))
    }
}
