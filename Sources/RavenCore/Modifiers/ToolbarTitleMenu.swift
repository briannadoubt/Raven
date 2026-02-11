import Foundation

/// A menu presented from a navigation title context.
///
/// This component maps SwiftUI's `ToolbarTitleMenu` API into Raven's menu
/// infrastructure so it renders in web builds.
@MainActor
public struct ToolbarTitleMenu<Content: View>: View, Sendable {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        Menu {
            content
        } label: {
            Text("Title")
        }
    }
}

extension View {
    /// Adds a title menu to the current view's toolbar context.
    @MainActor public func toolbarTitleMenu<Items: View>(
        @ViewBuilder _ items: () -> Items
    ) -> some View {
        // Raven does not yet project title-menu items into NavigationStack chrome.
        // Keep API compatibility and preserve layout until toolbar title wiring lands.
        _ = items()
        return self
    }
}
