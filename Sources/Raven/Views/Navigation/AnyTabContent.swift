import Foundation

/// A type-erased tab content container.
///
/// SwiftUI exposes `AnyTabContent` as part of its TabView-related surface area.
/// Raven does not currently require this for rendering, but providing the symbol
/// improves SwiftUI API parity and allows apps to compile without `#if canImport(SwiftUI)`.
@MainActor
public struct AnyTabContent: View, Sendable {
    private let content: AnyView

    @MainActor public init<Content: View>(_ content: Content) {
        self.content = AnyView(content)
    }

    @MainActor public var body: some View {
        content
    }
}

