import Foundation

/// A wrapper view that provides SwiftUI source-compatibility for `.equatable()`.
///
/// In SwiftUI, `EquatableView` can help the framework skip updates when its `Content`
/// hasn't changed. Raven's renderer already performs structural diffing, so for now this
/// is primarily an API-compatibility wrapper that forwards through to `content`.
@MainActor
public struct EquatableView<Content: View>: View, Sendable where Content: Sendable {
    public let content: Content

    @MainActor public init(_ content: Content) {
        self.content = content
    }

    @MainActor public var body: some View {
        content
    }
}

extension View {
    /// Wraps this view in an `EquatableView`.
    ///
    /// Note: SwiftUI constrains this API to `Self: Equatable`. Raven's `View` types are
    /// `@MainActor`-isolated, which makes `Equatable` conformance difficult in Swift 6's
    /// strict isolation model. We intentionally provide a more permissive API so that
    /// common `.equatable()` call sites compile unchanged.
    @MainActor public func equatable() -> EquatableView<Self> where Self: Sendable {
        EquatableView(self)
    }
}
