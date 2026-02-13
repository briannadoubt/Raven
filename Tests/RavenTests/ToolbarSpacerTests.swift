import Testing
@testable import SwiftUI
@testable import RavenCore

@MainActor
@Suite struct ToolbarSpacerTests {
    @Test func toolbarBuilderAcceptsToolbarSpacerAndItems() async throws {
        let view = Text("Toolbar")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("Leading")
                }
                ToolbarSpacer()
                ToolbarItem(placement: .navigationBarTrailing) {
                    Text("Trailing")
                }
            }

        #expect(view != nil)
    }

    @Test func toolbarSpacerSupportsSizingAndPlacement() async throws {
        let spacer = ToolbarSpacer(.fixed, placement: .bottomBar)
        let erased = _AnyToolbarItem(spacer)

        #expect(spacer.sizing == .fixed)
        #expect(spacer.placement == .bottomBar)
        #expect(erased.placement == .bottomBar)
    }
}
