import Foundation

/// A semantic role for a button in an alert or confirmation dialog.
///
/// Button roles provide semantic meaning to buttons, which can affect their
/// appearance and position in alerts and confirmation dialogs. The role helps
/// the system present buttons in a way that's familiar to users.
///
/// ## Overview
///
/// In SwiftUI (and Raven), button roles help differentiate between different
/// types of actions:
/// - **Cancel**: Dismisses the alert without taking action
/// - **Destructive**: Performs a potentially harmful or irreversible action
///
/// ## Usage in Alerts
///
/// ```swift
/// .alert("Delete Item", isPresented: $showAlert) {
///     Button("Delete", role: .destructive) {
///         deleteItem()
///     }
///     Button("Cancel", role: .cancel) { }
/// }
/// ```
///
/// ## Usage in Confirmation Dialogs
///
/// ```swift
/// .confirmationDialog("Choose an action", isPresented: $showDialog) {
///     Button("Save") { save() }
///     Button("Delete", role: .destructive) { delete() }
///     Button("Cancel", role: .cancel) { }
/// }
/// ```
///
/// ## Rendering Behavior
///
/// - Cancel buttons typically appear with a neutral style and may be positioned
///   separately from other buttons
/// - Destructive buttons are often styled in red to indicate danger
/// - Buttons without a role use the default appearance
@frozen
public enum ButtonRole: Sendable, Hashable {
    /// A cancel button that dismisses the alert or dialog without taking action.
    ///
    /// Cancel buttons are typically styled neutrally and may appear in a
    /// separate position from other buttons (e.g., at the bottom of an action
    /// sheet on iOS).
    ///
    /// Example:
    /// ```swift
    /// Button("Cancel", role: .cancel) { }
    /// ```
    case cancel

    /// A destructive button that performs a potentially harmful action.
    ///
    /// Destructive buttons are often styled in red to indicate that the action
    /// is dangerous or irreversible, such as deleting data.
    ///
    /// Example:
    /// ```swift
    /// Button("Delete", role: .destructive) {
    ///     deleteItem()
    /// }
    /// ```
    case destructive
}
