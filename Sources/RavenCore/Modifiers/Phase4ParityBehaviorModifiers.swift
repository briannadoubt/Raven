import Foundation

private struct FindDisabledEnvironmentKey: EnvironmentKey {
    static let defaultValue = false
}

private struct DeleteDisabledEnvironmentKey: EnvironmentKey {
    static let defaultValue = false
}

private struct FocusEffectDisabledEnvironmentKey: EnvironmentKey {
    static let defaultValue = false
}

private struct AllowsWindowActivationEventsEnvironmentKey: EnvironmentKey {
    static let defaultValue = true
}

private struct BackgroundExtensionEffectEnabledEnvironmentKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var findDisabled: Bool {
        get { self[FindDisabledEnvironmentKey.self] }
        set { self[FindDisabledEnvironmentKey.self] = newValue }
    }

    var deleteDisabled: Bool {
        get { self[DeleteDisabledEnvironmentKey.self] }
        set { self[DeleteDisabledEnvironmentKey.self] = newValue }
    }

    var focusEffectDisabled: Bool {
        get { self[FocusEffectDisabledEnvironmentKey.self] }
        set { self[FocusEffectDisabledEnvironmentKey.self] = newValue }
    }

    var allowsWindowActivationEvents: Bool {
        get { self[AllowsWindowActivationEventsEnvironmentKey.self] }
        set { self[AllowsWindowActivationEventsEnvironmentKey.self] = newValue }
    }

    var backgroundExtensionEffectEnabled: Bool {
        get { self[BackgroundExtensionEffectEnabledEnvironmentKey.self] }
        set { self[BackgroundExtensionEffectEnabledEnvironmentKey.self] = newValue }
    }
}

/// Wrapper that stores behavior flags as data attributes on the DOM.
public struct _BehaviorFlagsView<Content: View>: View, PrimitiveView, Sendable {
    let content: Content
    let flags: [String: String]

    public typealias Body = Never

    @MainActor public func toVNode() -> VNode {
        let props = flags.reduce(into: [String: VProperty]()) { acc, pair in
            let (name, value) = pair
            acc[name] = .attribute(name: name, value: value)
        }
        return VNode.element("div", props: props, children: [])
    }
}

extension _BehaviorFlagsView: _ModifierRenderable {
    public var _modifiedContent: Content { content }
}

extension View {
    /// Disables find interactions for this view hierarchy.
    @MainActor public func findDisabled(_ isDisabled: Bool = true) -> some View {
        environment(\.findDisabled, isDisabled)
    }

    /// Disables delete actions for this view hierarchy.
    @MainActor public func deleteDisabled(_ isDisabled: Bool = true) -> some View {
        environment(\.deleteDisabled, isDisabled)
    }

    /// Disables hover/focus effects for this view hierarchy.
    @MainActor public func focusEffectDisabled(_ disabled: Bool = true) -> some View {
        environment(\.focusEffectDisabled, disabled)
    }

    /// Enables window activation events.
    @MainActor public func allowsWindowActivationEvents() -> some View {
        allowsWindowActivationEvents(true)
    }

    /// Controls whether window activation events are enabled.
    @MainActor public func allowsWindowActivationEvents(_ enabled: Bool) -> some View {
        environment(\.allowsWindowActivationEvents, enabled)
    }

    /// Enables background extension effects.
    @MainActor public func backgroundExtensionEffect() -> some View {
        backgroundExtensionEffect(isEnabled: true)
    }

    /// Controls whether background extension effects are enabled.
    @MainActor public func backgroundExtensionEffect(isEnabled: Bool) -> some View {
        environment(\.backgroundExtensionEffectEnabled, isEnabled)
    }

    /// Adds a dialog suppression toggle with a text label.
    @MainActor public func dialogSuppressionToggle(
        _ title: String,
        isSuppressed: Binding<Bool>
    ) -> some View {
        _ = isSuppressed
        return _BehaviorFlagsView(
            content: self,
            flags: [
                "data-dialog-suppression-toggle": "true",
                "data-dialog-suppression-title": title,
            ]
        )
    }

    /// Adds a dialog suppression toggle with a `Text` label.
    @MainActor public func dialogSuppressionToggle(
        _ title: Text,
        isSuppressed: Binding<Bool>
    ) -> some View {
        dialogSuppressionToggle(title.textContent, isSuppressed: isSuppressed)
    }

    /// Adds a dialog suppression toggle without a custom title.
    @MainActor public func dialogSuppressionToggle(
        isSuppressed: Binding<Bool>
    ) -> some View {
        _ = isSuppressed
        return _BehaviorFlagsView(
            content: self,
            flags: [
                "data-dialog-suppression-toggle": "true",
            ]
        )
    }
}
