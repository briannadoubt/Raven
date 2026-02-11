import Foundation

/// An action that performs a rename request in the current environment.
public struct RenameAction: Sendable {
    private let action: (@Sendable @MainActor () -> Void)?

    public init(_ action: (@Sendable @MainActor () -> Void)? = nil) {
        self.action = action
    }

    @MainActor public func callAsFunction() {
        action?()
    }

    public var isAvailable: Bool {
        action != nil
    }
}

private struct RenameActionKey: EnvironmentKey {
    typealias Value = RenameAction
    static let defaultValue: RenameAction = RenameAction()
}

extension EnvironmentValues {
    /// The rename action for the current view hierarchy.
    public var renameAction: RenameAction {
        get { self[RenameActionKey.self] }
        set { self[RenameActionKey.self] = newValue }
    }
}

extension View {
    /// Installs a rename handler for `RenameButton`.
    @MainActor public func onRename(perform action: @escaping @Sendable @MainActor () -> Void) -> some View {
        environment(\.renameAction, RenameAction(action))
    }
}

/// A button that triggers the current environment's rename action.
public struct RenameButton: View, Sendable {
    @Environment(\.renameAction) private var renameAction
    private let title: String
    private let action: (@Sendable @MainActor () -> Void)?

    @MainActor public init() {
        self.title = "Rename"
        self.action = nil
    }

    @MainActor public init(_ title: String) {
        self.title = title
        self.action = nil
    }

    @MainActor public init(_ titleKey: LocalizedStringKey) {
        self.title = titleKey.stringValue
        self.action = nil
    }

    @MainActor public init(
        _ title: String = "Rename",
        action: @escaping @Sendable @MainActor () -> Void
    ) {
        self.title = title
        self.action = action
    }

    @MainActor public init(
        _ titleKey: LocalizedStringKey,
        action: @escaping @Sendable @MainActor () -> Void
    ) {
        self.title = titleKey.stringValue
        self.action = action
    }

    @MainActor public var body: some View {
        Button(title) {
            if let action {
                action()
            } else {
                renameAction()
            }
        }
        .disabled(action == nil && !renameAction.isAvailable)
    }
}
