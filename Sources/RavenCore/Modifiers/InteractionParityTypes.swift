import Foundation

/// Describes interaction affordances for focus behavior.
public struct FocusInteractions: Sendable, Hashable {
    private let rawValue: String

    private init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// Uses system-default focus interaction behavior.
    public static let automatic = FocusInteractions(rawValue: "automatic")

    /// Enables explicit activation interaction behavior.
    public static let activate = FocusInteractions(rawValue: "activate")
}

/// Describes the severity level for dialogs.
public enum DialogSeverity: Sendable, Hashable {
    /// Uses default dialog severity behavior.
    case automatic

    /// Indicates a critical dialog.
    case critical
}
