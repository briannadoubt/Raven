import Foundation

/// A proxy that can request scrolling to specific content within a scroll view.
///
/// Raven currently treats `scrollTo` as a compatibility API. Calls are accepted so
/// SwiftUI-style code compiles and runs, and richer programmatic scrolling behavior
/// can be layered in without API changes.
public struct ScrollViewProxy: Sendable {
    @MainActor public init() {}

    /// Requests scrolling to the view identified by `id`.
    ///
    /// - Parameters:
    ///   - id: The identifier of the target view.
    ///   - anchor: Optional unit-point anchor for alignment.
    @MainActor public func scrollTo<ID: Hashable>(_: ID, anchor _: UnitPoint? = nil) {
        // Placeholder parity implementation. Rendering is unaffected and content remains interactive.
    }
}

/// A view that provides a `ScrollViewProxy` to its content.
///
/// Use `ScrollViewReader` to keep SwiftUI-compatible structure when building UIs
/// that need programmatic scrolling.
@MainActor
public struct ScrollViewReader<Content: View>: View, Sendable {
    private let content: @MainActor @Sendable (ScrollViewProxy) -> Content

    /// Creates a scroll view reader that passes a `ScrollViewProxy` into `content`.
    ///
    /// - Parameter content: A closure that builds the child view hierarchy.
    @MainActor public init(
        @ViewBuilder content: @escaping @MainActor @Sendable (ScrollViewProxy) -> Content
    ) {
        self.content = content
    }

    @MainActor public var body: some View {
        content(ScrollViewProxy())
    }
}
