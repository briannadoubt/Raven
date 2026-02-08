import Foundation

extension View {
    /// Configures whether this view hierarchy should disable text autocorrection.
    ///
    /// - Parameter disabled: Pass `true` to disable autocorrection.
    /// - Returns: A view with updated autocorrection behavior.
    @MainActor public func autocorrectionDisabled(_ disabled: Bool = true) -> some View {
        environment(\.autocorrectionDisabled, disabled)
    }

    /// Legacy alias for `autocorrectionDisabled(_:)`.
    @MainActor public func disableAutocorrection(_ disable: Bool = true) -> some View {
        environment(\.disableAutocorrection, disable)
    }
}
