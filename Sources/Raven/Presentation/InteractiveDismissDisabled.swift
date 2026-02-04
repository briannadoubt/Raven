import Foundation

// MARK: - InteractiveDismissDisabledKey

/// Environment key for controlling interactive dismiss behavior.
///
/// This key determines whether presentations can be dismissed by user interaction
/// (such as swiping down on a sheet or tapping outside a popover).
private struct InteractiveDismissDisabledKey: EnvironmentKey {
    /// By default, interactive dismissal is enabled (the value is `false`).
    static let defaultValue: Bool = false
}

// MARK: - EnvironmentValues Extension

extension EnvironmentValues {
    /// Whether interactive dismissal is disabled for presentations.
    ///
    /// When set to `true`, presentations cannot be dismissed through user
    /// interaction. They must be dismissed programmatically by changing the
    /// binding or state that controls the presentation.
    ///
    /// ## Usage
    ///
    /// Access this value from the environment:
    ///
    /// ```swift
    /// @Environment(\.isInteractiveDismissDisabled) var isDisabled
    /// ```
    ///
    /// Or set it using the `.interactiveDismissDisabled()` modifier:
    ///
    /// ```swift
    /// .sheet(isPresented: $showSheet) {
    ///     SheetContent()
    ///         .interactiveDismissDisabled(true)
    /// }
    /// ```
    ///
    /// - Note: This is an internal property used by the presentation system.
    ///   Use the `.interactiveDismissDisabled()` modifier instead of setting
    ///   this value directly.
    internal var isInteractiveDismissDisabled: Bool {
        get { self[InteractiveDismissDisabledKey.self] }
        set { self[InteractiveDismissDisabledKey.self] = newValue }
    }
}

// MARK: - View Extension

extension View {
    /// Controls whether the user can dismiss presentations.
    ///
    /// Apply this modifier to the content of a presentation to prevent users
    /// from dismissing it through gestures or other interactive means. The
    /// presentation can only be dismissed programmatically.
    ///
    /// ## Basic Usage
    ///
    /// Disable interactive dismissal for a sheet:
    ///
    /// ```swift
    /// .sheet(isPresented: $showSheet) {
    ///     EditView(item: item)
    ///         .interactiveDismissDisabled()
    /// }
    /// ```
    ///
    /// ## Conditional Disabling
    ///
    /// Prevent dismissal based on state (e.g., unsaved changes):
    ///
    /// ```swift
    /// .sheet(isPresented: $showEditor) {
    ///     EditorView()
    ///         .interactiveDismissDisabled(hasUnsavedChanges)
    /// }
    /// ```
    ///
    /// ## Use Cases
    ///
    /// - Prevent accidental dismissal during data entry
    /// - Block dismissal when there are unsaved changes
    /// - Force user to make a choice before closing
    /// - Ensure critical workflows are completed
    ///
    /// ## Behavior
    ///
    /// When interactive dismissal is disabled:
    /// - Swipe-to-dismiss gestures are blocked (for sheets)
    /// - Tap-to-dismiss outside the presentation is blocked (for popovers)
    /// - Close buttons or other interactive elements still work
    /// - Programmatic dismissal (via binding changes) still works
    ///
    /// Example with validation:
    /// ```swift
    /// struct FormSheet: View {
    ///     @Environment(\.dismiss) var dismiss
    ///     @State private var name = ""
    ///
    ///     var isValid: Bool {
    ///         !name.isEmpty
    ///     }
    ///
    ///     var body: some View {
    ///         NavigationView {
    ///             Form {
    ///                 TextField("Name", text: $name)
    ///             }
    ///             .navigationBarItems(
    ///                 trailing: Button("Done") {
    ///                     dismiss()
    ///                 }
    ///                 .disabled(!isValid)
    ///             )
    ///             .interactiveDismissDisabled(!isValid)
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// - Parameter isDisabled: A Boolean value that determines whether
    ///   interactive dismissal is disabled. Defaults to `true`.
    /// - Returns: A view that controls interactive dismissal behavior.
    ///
    /// - Note: This modifier only affects user-initiated dismissals. You can
    ///   always dismiss presentations programmatically by modifying the binding
    ///   or state that controls the presentation.
    @MainActor
    public func interactiveDismissDisabled(_ isDisabled: Bool = true) -> some View {
        environment(\.isInteractiveDismissDisabled, isDisabled)
    }
}
