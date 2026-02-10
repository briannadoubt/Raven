import Foundation

// MARK: - Alert Extensions

extension View {
    // MARK: - Basic Alert Methods

    /// Presents an alert when a binding to a Boolean value is true.
    ///
    /// Use this method to present a simple alert with a title and actions.
    /// The alert is automatically dismissed when the user taps any button.
    ///
    /// ## Example
    ///
    /// ```swift
    /// struct ContentView: View {
    ///     @State private var showAlert = false
    ///
    ///     var body: some View {
    ///         Button("Show Alert") {
    ///             showAlert = true
    ///         }
    ///         .alert("Important", isPresented: $showAlert) {
    ///             Button("OK") { }
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - title: The title of the alert.
    ///   - isPresented: A binding to a Boolean value that determines whether
    ///     the alert is presented.
    ///   - actions: A view builder that creates the alert's actions.
    /// - Returns: A view that presents an alert.
    @MainActor
    public func alert<Actions: View>(
        _ title: String,
        isPresented: Binding<Bool>,
        @ViewBuilder actions: @escaping @MainActor @Sendable () -> Actions
    ) -> some View {
        modifier(BasicAlertModifier(
            title: title,
            isPresented: isPresented,
            actions: actions
        ))
    }

    /// Presents an alert with a title and message when a binding to a Boolean value is true.
    ///
    /// Use this method to present an alert with additional context provided
    /// by a message view.
    ///
    /// ## Example
    ///
    /// ```swift
    /// struct ContentView: View {
    ///     @State private var showAlert = false
    ///
    ///     var body: some View {
    ///         Button("Save") {
    ///             showAlert = true
    ///         }
    ///         .alert("Save Changes?", isPresented: $showAlert) {
    ///             Button("Save") { save() }
    ///             Button("Cancel", role: .cancel) { }
    ///         } message: {
    ///             Text("Your changes will be saved to the cloud.")
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - title: The title of the alert.
    ///   - isPresented: A binding to a Boolean value that determines whether
    ///     the alert is presented.
    ///   - actions: A view builder that creates the alert's actions.
    ///   - message: A view builder that creates the alert's message.
    /// - Returns: A view that presents an alert with a message.
    @MainActor
    public func alert<Actions: View, Message: View>(
        _ title: String,
        isPresented: Binding<Bool>,
        @ViewBuilder actions: @escaping @MainActor @Sendable () -> Actions,
        @ViewBuilder message: @escaping @MainActor @Sendable () -> Message
    ) -> some View {
        modifier(AlertWithMessageModifier(
            title: title,
            isPresented: isPresented,
            actions: actions,
            message: message
        ))
    }

    // MARK: - Data-Driven Alert Methods

    /// Presents an alert when optional data is non-nil.
    ///
    /// Use this method to present an alert based on the presence of data,
    /// allowing you to pass that data to the alert's actions and message.
    ///
    /// ## Example
    ///
    /// ```swift
    /// struct ContentView: View {
    ///     @State private var itemToDelete: Item?
    ///
    ///     var body: some View {
    ///         List(items) { item in
    ///             Button(item.name) {
    ///                 itemToDelete = item
    ///             }
    ///         }
    ///         .alert("Delete Item", isPresented: $itemToDelete) { item in
    ///             Button("Delete", role: .destructive) {
    ///                 delete(item)
    ///             }
    ///             Button("Cancel", role: .cancel) { }
    ///         } message: { item in
    ///             Text("Are you sure you want to delete \(item.name)?")
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - title: The title of the alert.
    ///   - data: A binding to optional data. When the data is non-nil,
    ///     the alert is presented.
    ///   - actions: A view builder that creates the alert's actions using the data.
    ///   - message: A view builder that creates the alert's message using the data.
    /// - Returns: A view that presents a data-driven alert.
    @MainActor
    public func alert<Item: Sendable & Equatable, Actions: View, Message: View>(
        _ title: String,
        isPresented data: Binding<Item?>,
        @ViewBuilder actions: @escaping @MainActor @Sendable (Item) -> Actions,
        @ViewBuilder message: @escaping @MainActor @Sendable (Item) -> Message
    ) -> some View {
        modifier(DataAlertModifier(
            title: title,
            data: data,
            actions: actions,
            message: message
        ))
    }
}

// MARK: - Confirmation Dialog Extensions

extension View {
    // MARK: - Basic Confirmation Dialog Methods

    /// Presents a confirmation dialog when a binding to a Boolean value is true.
    ///
    /// Confirmation dialogs (also known as action sheets) present a set of choices
    /// to the user in a modal interface.
    ///
    /// ## Example
    ///
    /// ```swift
    /// struct ContentView: View {
    ///     @State private var showDialog = false
    ///
    ///     var body: some View {
    ///         Button("Show Options") {
    ///             showDialog = true
    ///         }
    ///         .confirmationDialog("Choose an action", isPresented: $showDialog) {
    ///             Button("Save") { save() }
    ///             Button("Delete", role: .destructive) { delete() }
    ///             Button("Cancel", role: .cancel) { }
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - title: The title of the dialog.
    ///   - isPresented: A binding to a Boolean value that determines whether
    ///     the dialog is presented.
    ///   - titleVisibility: Controls whether the title is shown.
    ///   - actions: A view builder that creates the dialog's actions.
    /// - Returns: A view that presents a confirmation dialog.
    @MainActor
    public func confirmationDialog<Actions: View>(
        _ title: String,
        isPresented: Binding<Bool>,
        titleVisibility: Visibility = .automatic,
        @ViewBuilder actions: @escaping @MainActor @Sendable () -> Actions
    ) -> some View {
        modifier(BasicConfirmationDialogModifier(
            title: title,
            titleVisibility: titleVisibility,
            isPresented: isPresented,
            actions: actions
        ))
    }

    /// Presents a confirmation dialog with a title and message when a binding to a Boolean value is true.
    ///
    /// Use this method to present a confirmation dialog with additional context
    /// provided by a message view.
    ///
    /// ## Example
    ///
    /// ```swift
    /// struct ContentView: View {
    ///     @State private var showDialog = false
    ///
    ///     var body: some View {
    ///         Button("Delete All") {
    ///             showDialog = true
    ///         }
    ///         .confirmationDialog("Delete All Items", isPresented: $showDialog) {
    ///             Button("Delete All", role: .destructive) { deleteAll() }
    ///             Button("Cancel", role: .cancel) { }
    ///         } message: {
    ///             Text("This action cannot be undone.")
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - title: The title of the dialog.
    ///   - isPresented: A binding to a Boolean value that determines whether
    ///     the dialog is presented.
    ///   - titleVisibility: Controls whether the title is shown.
    ///   - actions: A view builder that creates the dialog's actions.
    ///   - message: A view builder that creates the dialog's message.
    /// - Returns: A view that presents a confirmation dialog with a message.
    @MainActor
    public func confirmationDialog<Actions: View, Message: View>(
        _ title: String,
        isPresented: Binding<Bool>,
        titleVisibility: Visibility = .automatic,
        @ViewBuilder actions: @escaping @MainActor @Sendable () -> Actions,
        @ViewBuilder message: @escaping @MainActor @Sendable () -> Message
    ) -> some View {
        modifier(ConfirmationDialogWithMessageModifier(
            title: title,
            titleVisibility: titleVisibility,
            isPresented: isPresented,
            actions: actions,
            message: message
        ))
    }

    // MARK: - Data-Driven Confirmation Dialog Methods

    /// Presents a confirmation dialog when optional data is non-nil.
    ///
    /// Use this method to present a confirmation dialog based on the presence
    /// of data, allowing you to pass that data to the dialog's actions and message.
    ///
    /// ## Example
    ///
    /// ```swift
    /// struct ContentView: View {
    ///     @State private var itemToDelete: Item?
    ///
    ///     var body: some View {
    ///         List(items) { item in
    ///             Button(item.name) {
    ///                 itemToDelete = item
    ///             }
    ///         }
    ///         .confirmationDialog(
    ///             "Delete Item",
    ///             isPresented: $itemToDelete
    ///         ) { item in
    ///             Button("Delete \(item.name)", role: .destructive) {
    ///                 delete(item)
    ///             }
    ///             Button("Cancel", role: .cancel) { }
    ///         } message: { item in
    ///             Text("This will permanently delete \(item.name)")
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - title: The title of the dialog.
    ///   - data: A binding to optional data. When the data is non-nil,
    ///     the dialog is presented.
    ///   - titleVisibility: Controls whether the title is shown.
    ///   - actions: A view builder that creates the dialog's actions using the data.
    ///   - message: A view builder that creates the dialog's message using the data.
    /// - Returns: A view that presents a data-driven confirmation dialog.
    @MainActor
    public func confirmationDialog<Item: Sendable & Equatable, Actions: View, Message: View>(
        _ title: String,
        isPresented data: Binding<Item?>,
        titleVisibility: Visibility = .automatic,
        @ViewBuilder actions: @escaping @MainActor @Sendable (Item) -> Actions,
        @ViewBuilder message: @escaping @MainActor @Sendable (Item) -> Message
    ) -> some View {
        modifier(DataConfirmationDialogModifier(
            title: title,
            titleVisibility: titleVisibility,
            data: data,
            actions: actions,
            message: message
        ))
    }
}
