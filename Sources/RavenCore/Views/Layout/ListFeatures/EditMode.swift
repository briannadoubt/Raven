import Foundation

// MARK: - Edit Mode

/// A mode that indicates whether the user can edit the content of a view.
///
/// Use edit mode to control whether users can edit content like lists or forms.
/// Edit mode is typically toggled with an "Edit" button in the navigation bar.
///
/// ## Overview
///
/// Edit mode supports three states:
/// - `inactive`: Content is read-only and cannot be edited
/// - `active`: Content is in edit mode, allowing modifications like deletion or reordering
/// - `transient`: Temporary edit mode, typically used during animations
///
/// ## Usage
///
/// Access edit mode using the `@Environment` property wrapper:
///
/// ```swift
/// struct ContentView: View {
///     @Environment(\.editMode) var editMode
///
///     var body: some View {
///         List {
///             ForEach(items) { item in
///                 Text(item.name)
///             }
///             .onDelete { indices in
///                 items.remove(atOffsets: indices)
///             }
///         }
///         .navigationTitle("Items")
///         .toolbar {
///             EditButton()
///         }
///     }
/// }
/// ```
///
/// ## Manual Control
///
/// You can manually control edit mode by using a `@State` binding:
///
/// ```swift
/// struct ManualEditView: View {
///     @State private var editMode = EditMode.inactive
///
///     var body: some View {
///         List {
///             // List content
///         }
///         .environment(\.editMode, $editMode)
///         .toolbar {
///             Button(editMode.isEditing ? "Done" : "Edit") {
///                 editMode = editMode.isEditing ? .inactive : .active
///             }
///         }
///     }
/// }
/// ```
@frozen
public enum EditMode: Sendable, Hashable {
    /// The view content is not editable.
    ///
    /// This is the default state. Interactive elements like delete buttons
    /// and reorder controls are hidden.
    case inactive

    /// The view content is editable.
    ///
    /// Interactive elements like delete buttons and reorder controls are visible.
    /// Users can modify the content.
    case active

    /// The view content is transitioning between edit modes.
    ///
    /// This state is used internally during animations between active and inactive.
    /// It's typically not set manually by application code.
    case transient

    /// Returns true if edit mode is active or transient.
    ///
    /// Use this property to check if editing is currently enabled:
    /// ```swift
    /// if editMode.isEditing {
    ///     // Show edit controls
    /// }
    /// ```
    public var isEditing: Bool {
        switch self {
        case .inactive:
            return false
        case .active, .transient:
            return true
        }
    }
}

// MARK: - Environment Key

/// Environment key for edit mode.
private struct EditModeKey: EnvironmentKey {
    static let defaultValue: Binding<EditMode>? = nil
}

extension EnvironmentValues {
    /// The current edit mode.
    ///
    /// Access this value to determine if the user interface is in edit mode:
    ///
    /// ```swift
    /// @Environment(\.editMode) var editMode
    ///
    /// var body: some View {
    ///     if editMode?.wrappedValue.isEditing == true {
    ///         Text("Editing")
    ///     } else {
    ///         Text("Not editing")
    ///     }
    /// }
    /// ```
    ///
    /// Set this value to control edit mode programmatically:
    ///
    /// ```swift
    /// @State private var editMode = EditMode.inactive
    ///
    /// List {
    ///     // content
    /// }
    /// .environment(\.editMode, $editMode)
    /// ```
    public var editMode: Binding<EditMode>? {
        get { self[EditModeKey.self] }
        set { self[EditModeKey.self] = newValue }
    }
}

// MARK: - Edit Button

/// A button that toggles the edit mode environment value.
///
/// An edit button toggles the environment's `editMode` value between `active` and `inactive`.
/// It automatically displays "Edit" or "Done" based on the current state.
///
/// ## Usage
///
/// Place an `EditButton` in a toolbar to enable editing for lists or other editable content:
///
/// ```swift
/// List {
///     ForEach(items) { item in
///         Text(item.name)
///     }
///     .onDelete { indices in
///         items.remove(atOffsets: indices)
///     }
/// }
/// .toolbar {
///     EditButton()
/// }
/// ```
///
/// The button automatically:
/// - Shows "Edit" when edit mode is inactive
/// - Shows "Done" when edit mode is active
/// - Toggles edit mode when tapped
/// - Disables itself if no edit mode is available in the environment
///
/// ## Requirements
///
/// `EditButton` requires an edit mode binding in the environment. If none is available,
/// the button will be disabled. This typically happens automatically when used with
/// navigation views and lists.
public struct EditButton: View {
    @Environment(\.editMode) private var editMode

    /// Creates an edit button.
    public init() {}

    public var body: some View {
        Button(action: toggleEditMode) {
            Text(editMode?.wrappedValue.isEditing == true ? "Done" : "Edit")
        }
        .disabled(editMode == nil)
    }

    @MainActor
    private func toggleEditMode() {
        guard let editMode = editMode else { return }

        withAnimation {
            if editMode.wrappedValue.isEditing {
                editMode.wrappedValue = .inactive
            } else {
                editMode.wrappedValue = .active
            }
        }
    }
}

// MARK: - Binding Extension

extension Binding where Value == EditMode {
    /// Creates a binding to edit mode that starts in the specified state.
    ///
    /// This is useful when you want to provide a default edit mode state.
    ///
    /// - Parameter initialValue: The initial edit mode state.
    /// - Returns: A binding that can be used with the environment.
    public static func constant(_ value: EditMode) -> Binding<EditMode> {
        Binding(
            get: { value },
            set: { _ in }
        )
    }
}
