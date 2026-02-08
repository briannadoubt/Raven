import Foundation

/// A presentation that displays an action sheet to the user.
///
/// Action sheets present a set of choices in a modal interface. In Raven,
/// action sheets are rendered using the confirmation dialog presentation.
public struct ActionSheet: Sendable {
    /// A button in an action sheet.
    public struct Button: Sendable, Identifiable {
        /// Unique identifier for this button.
        public let id: UUID

        /// The text label for the button.
        public let label: Text

        /// The semantic role of the button.
        public let role: ButtonRole?

        /// The action to perform when the button is tapped.
        public let action: (@Sendable () -> Void)?

        /// Creates a button with a label, optional role, and optional action.
        public init(
            label: Text,
            role: ButtonRole? = nil,
            action: (@Sendable () -> Void)? = nil
        ) {
            self.id = UUID()
            self.label = label
            self.role = role
            self.action = action
        }

        /// Creates a default button.
        public static func `default`(
            _ label: Text,
            action: (@Sendable () -> Void)? = nil
        ) -> Button {
            Button(label: label, role: nil, action: action)
        }

        /// Creates a destructive button.
        public static func destructive(
            _ label: Text,
            action: (@Sendable () -> Void)? = nil
        ) -> Button {
            Button(label: label, role: .destructive, action: action)
        }

        /// Creates a cancel button.
        public static func cancel(
            _ label: Text = Text("Cancel"),
            action: (@Sendable () -> Void)? = nil
        ) -> Button {
            Button(label: label, role: .cancel, action: action)
        }
    }

    /// The title of the action sheet.
    public let title: Text

    /// An optional message shown under the title.
    public let message: Text?

    /// The buttons to display in the action sheet.
    public let buttons: [Button]

    /// Creates an action sheet.
    public init(
        title: Text,
        message: Text? = nil,
        buttons: [Button]
    ) {
        self.title = title
        self.message = message
        self.buttons = buttons
    }
}
