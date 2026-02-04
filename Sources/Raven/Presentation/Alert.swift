import Foundation

/// A presentation that displays an alert to the user.
///
/// An alert is a modal dialog that interrupts the user to display important
/// information or request a decision. Alerts consist of a title, an optional
/// message, and one or more buttons.
///
/// ## Overview
///
/// Alerts are used to:
/// - Notify users of important information
/// - Request confirmation before a significant action
/// - Present simple choices to the user
/// - Display error messages
///
/// ## Creating Alerts
///
/// Create an alert with a title and message:
///
/// ```swift
/// struct ContentView: View {
///     @State private var showAlert = false
///
///     var body: some View {
///         Button("Show Alert") {
///             showAlert = true
///         }
///         .alert("Important Message", isPresented: $showAlert) {
///             Button("OK") { }
///         } message: {
///             Text("This is an important notification.")
///         }
///     }
/// }
/// ```
///
/// ## Button Configuration
///
/// Alerts can have one or two buttons:
///
/// **Single Button (Acknowledgment):**
/// ```swift
/// .alert("Success", isPresented: $showAlert) {
///     Button("OK") { }
/// }
/// ```
///
/// **Two Buttons (Choice):**
/// ```swift
/// .alert("Delete Item", isPresented: $showAlert) {
///     Button("Delete", role: .destructive) {
///         deleteItem()
///     }
///     Button("Cancel", role: .cancel) { }
/// }
/// ```
///
/// ## Button Roles
///
/// Use button roles to indicate the semantic meaning of each action:
/// - `.cancel`: Dismisses the alert without taking action
/// - `.destructive`: Performs a potentially harmful action (styled in red)
///
/// ## Error Presentation
///
/// Present errors using the error variant:
///
/// ```swift
/// .alert(isPresented: $hasError, error: currentError) {
///     Button("OK") { }
/// }
/// ```
///
/// - Note: This is a data structure representing alert configuration.
///   Use the `.alert()` view modifier to present alerts in your views.
///
/// ## See Also
///
/// - ``ButtonRole``
/// - ``View/alert(_:isPresented:actions:)``
/// - ``View/confirmationDialog(_:isPresented:titleVisibility:actions:)``
public struct Alert: Sendable {
    /// A button in an alert.
    ///
    /// Alert buttons define the actions available to the user. Each button
    /// has a label, an optional action to perform when tapped, and an optional
    /// role that affects its appearance and position.
    ///
    /// ## Creating Buttons
    ///
    /// Create buttons using the initializer:
    ///
    /// ```swift
    /// Alert.Button(label: "OK", action: { print("OK tapped") })
    /// Alert.Button(label: "Cancel", role: .cancel)
    /// Alert.Button(label: "Delete", role: .destructive) { deleteItem() }
    /// ```
    ///
    /// ## Convenience Methods
    ///
    /// Use static methods for common button types:
    ///
    /// ```swift
    /// Alert.Button.default("OK") { }
    /// Alert.Button.cancel("Cancel")
    /// Alert.Button.destructive("Delete") { deleteItem() }
    /// ```
    public struct Button: Sendable, Identifiable {
        /// Unique identifier for this button
        public let id: UUID

        /// The text label for the button
        public let label: String

        /// The action to perform when the button is tapped
        public let action: (@Sendable () -> Void)?

        /// The semantic role of the button
        public let role: ButtonRole?

        /// Creates an alert button.
        ///
        /// - Parameters:
        ///   - label: The text to display on the button.
        ///   - role: The semantic role of the button (optional).
        ///   - action: The action to perform when tapped (optional).
        public init(
            label: String,
            role: ButtonRole? = nil,
            action: (@Sendable () -> Void)? = nil
        ) {
            self.id = UUID()
            self.label = label
            self.role = role
            self.action = action
        }

        /// Creates a default button with no special role.
        ///
        /// Default buttons appear with standard styling and are typically
        /// used for affirmative actions.
        ///
        /// Example:
        /// ```swift
        /// Alert.Button.default("OK") {
        ///     print("OK tapped")
        /// }
        /// ```
        ///
        /// - Parameters:
        ///   - label: The text to display on the button.
        ///   - action: The action to perform when tapped.
        /// - Returns: A button with default styling.
        public static func `default`(
            _ label: String,
            action: (@Sendable () -> Void)? = nil
        ) -> Button {
            Button(label: label, role: nil, action: action)
        }

        /// Creates a cancel button.
        ///
        /// Cancel buttons dismiss the alert without taking action and are
        /// typically styled neutrally.
        ///
        /// Example:
        /// ```swift
        /// Alert.Button.cancel("Cancel")
        /// ```
        ///
        /// - Parameters:
        ///   - label: The text to display on the button. Defaults to "Cancel".
        ///   - action: The action to perform when tapped (optional).
        /// - Returns: A button with the cancel role.
        public static func cancel(
            _ label: String = "Cancel",
            action: (@Sendable () -> Void)? = nil
        ) -> Button {
            Button(label: label, role: .cancel, action: action)
        }

        /// Creates a destructive button.
        ///
        /// Destructive buttons perform potentially harmful actions and are
        /// typically styled in red to indicate danger.
        ///
        /// Example:
        /// ```swift
        /// Alert.Button.destructive("Delete") {
        ///     deleteItem()
        /// }
        /// ```
        ///
        /// - Parameters:
        ///   - label: The text to display on the button.
        ///   - action: The action to perform when tapped.
        /// - Returns: A button with the destructive role.
        public static func destructive(
            _ label: String,
            action: (@Sendable () -> Void)? = nil
        ) -> Button {
            Button(label: label, role: .destructive, action: action)
        }
    }

    /// The title of the alert
    public let title: String

    /// The optional message providing additional context
    public let message: String?

    /// The buttons available in the alert
    public let buttons: [Button]

    /// Creates an alert with a title and optional message.
    ///
    /// - Parameters:
    ///   - title: The title of the alert.
    ///   - message: An optional message providing additional context.
    ///   - buttons: The buttons to display. Defaults to a single "OK" button.
    public init(
        title: String,
        message: String? = nil,
        buttons: [Button] = [.default("OK")]
    ) {
        self.title = title
        self.message = message
        self.buttons = buttons
    }

    /// Creates an alert with a title, message, and a single button.
    ///
    /// - Parameters:
    ///   - title: The title of the alert.
    ///   - message: An optional message providing additional context.
    ///   - button: The single button to display.
    public init(
        title: String,
        message: String? = nil,
        button: Button
    ) {
        self.title = title
        self.message = message
        self.buttons = [button]
    }

    /// Creates an alert with a title, message, and two buttons.
    ///
    /// This is commonly used for confirmation dialogs where the user must
    /// choose between two options (e.g., "Delete" vs "Cancel").
    ///
    /// - Parameters:
    ///   - title: The title of the alert.
    ///   - message: An optional message providing additional context.
    ///   - primaryButton: The primary action button.
    ///   - secondaryButton: The secondary action button (often a cancel button).
    public init(
        title: String,
        message: String? = nil,
        primaryButton: Button,
        secondaryButton: Button
    ) {
        self.title = title
        self.message = message
        self.buttons = [primaryButton, secondaryButton]
    }
}
