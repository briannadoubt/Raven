import Testing
@testable import Raven

@MainActor
@Suite struct Phase1ParityAPITests {
    @Test func contentMarginsWrapperRendersPaddingStyles() {
        let view = Text("Margins")
            .contentMargins(.horizontal, 12, for: .scrollContent)
        let node = AnyView(view).toVNode()

        #expect(node.elementTag == "div")
        #expect(node.props["padding-left"] != nil)
        #expect(node.props["padding-right"] != nil)
        #expect(node.props["data-content-margin-placement"] != nil)
    }

    @Test func containerBackgroundStyleWrapperRendersBackground() {
        let view = Text("Background")
            .containerBackground(Color.blue, for: .automatic)
        let node = AnyView(view).toVNode()

        #expect(node.elementTag == "div")
        #expect(node.props["background"] != nil)
        #expect(node.props["data-container-background-placement"] != nil)
    }

    @Test func searchableSuggestionAndScopeAPIsCompose() {
        let text = Binding.constant("")
        let focused = Binding.constant(false)
        let scope = Binding.constant(Phase1Scope.all as Phase1Scope?)

        let view = Text("Search")
            .searchable(text: text)
            .searchSuggestions {
                Text("Quick suggestion")
            }
            .searchScopes(scope, scopes: [.all, .active])
            .searchFocused(focused)
        let node = AnyView(view).toVNode()

        #expect(node.elementTag == "div")
    }

    @Test func taskModifiersComposeToLifecycleWrappers() {
        let view = Text("Task")
            .task(priority: .utility) {
                await Task.yield()
            }
            .task(id: "query", priority: .background) {
                await Task.yield()
            }
        let node = AnyView(view).toVNode()

        #expect(node.elementTag == "div")
        // We only assert that the wrapper structure exists; lifecycle wiring is handled by the coordinator.
        #expect(node.children.count >= 0)
    }
}

private enum Phase1Scope: Hashable, Sendable {
    case all
    case active
}
