import Foundation

// MARK: - Basic Confirmation Dialog Modifier

/// A view modifier that presents a confirmation dialog when a binding to a Boolean value is true.
///
/// Confirmation dialogs (also known as action sheets) present a set of choices
/// to the user in a modal interface. They're commonly used for destructive actions
/// or when the user needs to choose between multiple options.
///
/// ## Usage
///
/// ```swift
/// @State private var showDialog = false
///
/// var body: some View {
///     Button("Show Options") {
///         showDialog = true
///     }
///     .confirmationDialog("Choose an action", isPresented: $showDialog) {
///         Button("Save") { save() }
///         Button("Delete", role: .destructive) { delete() }
///         Button("Cancel", role: .cancel) { }
///     }
/// }
/// ```
@MainActor
struct BasicConfirmationDialogModifier<Actions: View>: ViewModifier {
    /// The title of the confirmation dialog
    let title: String

    /// Controls the visibility of the title
    let titleVisibility: Visibility

    /// Binding that controls whether the dialog is presented
    @Binding var isPresented: Bool

    /// The actions to display in the dialog
    let actions: @MainActor @Sendable () -> Actions

    /// The presentation coordinator from the environment
    @Environment(\.presentationCoordinator) private var coordinator

    /// The current presentation ID if active
    @State private var presentationId: UUID?

    /// Creates a basic confirmation dialog modifier.
    ///
    /// - Parameters:
    ///   - title: The title of the dialog.
    ///   - titleVisibility: Controls whether the title is shown.
    ///   - isPresented: A binding to a Boolean value that determines whether
    ///     the dialog is presented.
    ///   - actions: A view builder that creates the dialog's actions.
    init(
        title: String,
        titleVisibility: Visibility = .automatic,
        isPresented: Binding<Bool>,
        @ViewBuilder actions: @escaping @MainActor @Sendable () -> Actions
    ) {
        self.title = title
        self.titleVisibility = titleVisibility
        self._isPresented = isPresented
        self.actions = actions
    }

    func body(content: Content) -> some View {
        content
            .onChange(of: isPresented) { newValue in
                if newValue {
                    presentDialog()
                } else if let id = presentationId {
                    coordinator.dismiss(id)
                    presentationId = nil
                }
            }
    }

    private func presentDialog() {
        let dialogContent = VStack {
            // Only show title if visibility is not hidden
            if titleVisibility != .hidden {
                Text(title)
            }
            actions()
        }

        let id = coordinator.present(
            type: .confirmationDialog,
            content: AnyView(dialogContent),
            onDismiss: {
                isPresented = false
                presentationId = nil
            }
        )
        presentationId = id
    }
}

// MARK: - Confirmation Dialog with Message

/// A view modifier that presents a confirmation dialog with a title and message.
///
/// This variant includes a message view in addition to the title,
/// providing additional context for the user's choice.
///
/// ## Usage
///
/// ```swift
/// @State private var showDialog = false
///
/// var body: some View {
///     Button("Delete All") {
///         showDialog = true
///     }
///     .confirmationDialog("Delete All Items", isPresented: $showDialog) {
///         Button("Delete All", role: .destructive) { deleteAll() }
///         Button("Cancel", role: .cancel) { }
///     } message: {
///         Text("This action cannot be undone.")
///     }
/// }
/// ```
@MainActor
struct ConfirmationDialogWithMessageModifier<Actions: View, Message: View>: ViewModifier {
    /// The title of the confirmation dialog
    let title: String

    /// Controls the visibility of the title
    let titleVisibility: Visibility

    /// Binding that controls whether the dialog is presented
    @Binding var isPresented: Bool

    /// The actions to display in the dialog
    let actions: @MainActor @Sendable () -> Actions

    /// The message to display below the title
    let message: @MainActor @Sendable () -> Message

    /// The presentation coordinator from the environment
    @Environment(\.presentationCoordinator) private var coordinator

    /// The current presentation ID if active
    @State private var presentationId: UUID?

    /// Creates a confirmation dialog modifier with a message.
    ///
    /// - Parameters:
    ///   - title: The title of the dialog.
    ///   - titleVisibility: Controls whether the title is shown.
    ///   - isPresented: A binding to a Boolean value that determines whether
    ///     the dialog is presented.
    ///   - actions: A view builder that creates the dialog's actions.
    ///   - message: A view builder that creates the dialog's message.
    init(
        title: String,
        titleVisibility: Visibility = .automatic,
        isPresented: Binding<Bool>,
        @ViewBuilder actions: @escaping @MainActor @Sendable () -> Actions,
        @ViewBuilder message: @escaping @MainActor @Sendable () -> Message
    ) {
        self.title = title
        self.titleVisibility = titleVisibility
        self._isPresented = isPresented
        self.actions = actions
        self.message = message
    }

    func body(content: Content) -> some View {
        content
            .onChange(of: isPresented) { newValue in
                if newValue {
                    presentDialog()
                } else if let id = presentationId {
                    coordinator.dismiss(id)
                    presentationId = nil
                }
            }
    }

    private func presentDialog() {
        let dialogContent = VStack {
            // Only show title if visibility is not hidden
            if titleVisibility != .hidden {
                Text(title)
            }
            message()
            actions()
        }

        let id = coordinator.present(
            type: .confirmationDialog,
            content: AnyView(dialogContent),
            onDismiss: {
                isPresented = false
                presentationId = nil
            }
        )
        presentationId = id
    }
}

// MARK: - Confirmation Dialog with Data

/// A view modifier that presents a confirmation dialog when optional data is non-nil.
///
/// This modifier allows you to present a confirmation dialog based on the presence
/// of data, and pass that data to the dialog's actions. When the data becomes non-nil,
/// the dialog is presented. When dismissed, the data is set to nil.
///
/// ## Usage
///
/// ```swift
/// @State private var itemToDelete: Item?
///
/// var body: some View {
///     List(items) { item in
///         Button(item.name) {
///             itemToDelete = item
///         }
///     }
///     .confirmationDialog(
///         "Delete Item",
///         isPresented: $itemToDelete
///     ) { item in
///         Button("Delete \(item.name)", role: .destructive) {
///             delete(item)
///         }
///         Button("Cancel", role: .cancel) { }
///     } message: { item in
///         Text("This will permanently delete \(item.name)")
///     }
/// }
/// ```
@MainActor
struct DataConfirmationDialogModifier<Item: Sendable & Equatable, Actions: View, Message: View>: ViewModifier {
    /// The title of the confirmation dialog
    let title: String

    /// Controls the visibility of the title
    let titleVisibility: Visibility

    /// Binding to optional data that controls presentation
    @Binding var data: Item?

    /// A closure that creates the dialog's actions using the data
    let actions: @MainActor @Sendable (Item) -> Actions

    /// A closure that creates the dialog's message using the data
    let message: @MainActor @Sendable (Item) -> Message

    /// The presentation coordinator from the environment
    @Environment(\.presentationCoordinator) private var coordinator

    /// The current presentation ID if active
    @State private var presentationId: UUID?

    /// Creates a data-driven confirmation dialog modifier.
    ///
    /// - Parameters:
    ///   - title: The title of the dialog.
    ///   - titleVisibility: Controls whether the title is shown.
    ///   - data: A binding to optional data. When the data is non-nil,
    ///     the dialog is presented.
    ///   - actions: A view builder that creates the dialog's actions using the data.
    ///   - message: A view builder that creates the dialog's message using the data.
    init(
        title: String,
        titleVisibility: Visibility = .automatic,
        data: Binding<Item?>,
        @ViewBuilder actions: @escaping @MainActor @Sendable (Item) -> Actions,
        @ViewBuilder message: @escaping @MainActor @Sendable (Item) -> Message
    ) {
        self.title = title
        self.titleVisibility = titleVisibility
        self._data = data
        self.actions = actions
        self.message = message
    }

    func body(content: Content) -> some View {
        content
            .onChange(of: data) { newValue in
                if let item = newValue {
                    presentDialog(with: item)
                } else if let id = presentationId {
                    coordinator.dismiss(id)
                    presentationId = nil
                }
            }
    }

    private func presentDialog(with item: Item) {
        let dialogContent = VStack {
            // Only show title if visibility is not hidden
            if titleVisibility != .hidden {
                Text(title)
            }
            message(item)
            actions(item)
        }

        let id = coordinator.present(
            type: .confirmationDialog,
            content: AnyView(dialogContent),
            onDismiss: {
                data = nil
                presentationId = nil
            }
        )
        presentationId = id
    }
}
