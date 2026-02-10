import Foundation

/// A modifier that makes no changes to the view.
///
/// SwiftUI exposes this as a public type, and it is occasionally useful as an identity
/// in generic contexts. In Raven it is also a convenient "do nothing" modifier that
/// preserves SwiftUI source compatibility.
@MainActor
public struct EmptyModifier: ViewModifier, Sendable {
    @MainActor public init() {}

    @MainActor public func body(content: Content) -> some View {
        content
    }
}

