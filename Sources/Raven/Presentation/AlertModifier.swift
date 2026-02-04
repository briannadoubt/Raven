import Foundation

// MARK: - Basic Alert Modifier

/// A view modifier that presents an alert when a binding to a Boolean value is true.
///
/// This modifier displays a simple alert with a title and optional actions.
/// The alert is automatically dismissed when the user taps any button.
///
/// ## Usage
///
/// ```swift
/// @State private var showAlert = false
///
/// var body: some View {
///     Button("Show Alert") {
///         showAlert = true
///     }
///     .alert("Important", isPresented: $showAlert) {
///         Button("OK") { }
///     }
/// }
/// ```
@MainActor
struct BasicAlertModifier<Actions: View>: ViewModifier {
    /// The title of the alert
    let title: String

    /// Binding that controls whether the alert is presented
    @Binding var isPresented: Bool

    /// The actions to display in the alert
    let actions: @MainActor @Sendable () -> Actions

    /// The presentation coordinator from the environment
    @Environment(\.presentationCoordinator) private var coordinator

    /// The current presentation ID if active
    @State private var presentationId: UUID?

    /// Creates a basic alert modifier.
    ///
    /// - Parameters:
    ///   - title: The title of the alert.
    ///   - isPresented: A binding to a Boolean value that determines whether
    ///     the alert is presented.
    ///   - actions: A view builder that creates the alert's actions.
    init(
        title: String,
        isPresented: Binding<Bool>,
        @ViewBuilder actions: @escaping @MainActor @Sendable () -> Actions
    ) {
        self.title = title
        self._isPresented = isPresented
        self.actions = actions
    }

    func body(content: Content) -> some View {
        content
            .onChange(of: isPresented) { newValue in
                if newValue {
                    presentAlert()
                } else if let id = presentationId {
                    coordinator.dismiss(id)
                    presentationId = nil
                }
            }
    }

    private func presentAlert() {
        let alertContent = VStack {
            Text(title)
            actions()
        }

        let id = coordinator.present(
            type: .alert,
            content: AnyView(alertContent),
            onDismiss: { @MainActor in
                isPresented = false
                presentationId = nil
            }
        )
        presentationId = id
    }
}

// MARK: - Alert with Message

/// A view modifier that presents an alert with a title and message.
///
/// This variant includes a message view in addition to the title,
/// allowing for more detailed alert content.
///
/// ## Usage
///
/// ```swift
/// @State private var showAlert = false
///
/// var body: some View {
///     Button("Show Alert") {
///         showAlert = true
///     }
///     .alert("Save Changes?", isPresented: $showAlert) {
///         Button("Save") { save() }
///         Button("Cancel", role: .cancel) { }
///     } message: {
///         Text("Your changes will be saved to the cloud.")
///     }
/// }
/// ```
@MainActor
public struct AlertWithMessageModifier<Actions: View, Message: View>: ViewModifier {
    /// The title of the alert
    let title: String

    /// Binding that controls whether the alert is presented
    @Binding var isPresented: Bool

    /// The actions to display in the alert
    let actions: @MainActor @Sendable () -> Actions

    /// The message to display below the title
    let message: @MainActor @Sendable () -> Message

    /// Creates an alert modifier with a message.
    ///
    /// - Parameters:
    ///   - title: The title of the alert.
    ///   - isPresented: A binding to a Boolean value that determines whether
    ///     the alert is presented.
    ///   - actions: A view builder that creates the alert's actions.
    ///   - message: A view builder that creates the alert's message.
    public init(
        title: String,
        isPresented: Binding<Bool>,
        @ViewBuilder actions: @escaping @MainActor @Sendable () -> Actions,
        @ViewBuilder message: @escaping @MainActor @Sendable () -> Message
    ) {
        self.title = title
        self._isPresented = isPresented
        self.actions = actions
        self.message = message
    }

    public func body(content: Content) -> some View {
        content
            .modifier(
                AlertPresentationWithMessageModifier(
                    title: title,
                    isPresented: $isPresented,
                    actions: actions,
                    message: message
                )
            )
    }
}

// MARK: - Alert with Data

/// A view modifier that presents an alert when optional data is non-nil.
///
/// This modifier allows you to present an alert based on the presence of data,
/// and pass that data to the alert's actions. When the data becomes non-nil,
/// the alert is presented. When dismissed, the data is set to nil.
///
/// ## Usage
///
/// ```swift
/// @State private var selectedItem: Item?
///
/// var body: some View {
///     List(items) { item in
///         Button(item.name) {
///             selectedItem = item
///         }
///     }
///     .alert("Delete Item", isPresented: $selectedItem) { item in
///         Button("Delete", role: .destructive) {
///             delete(item)
///         }
///         Button("Cancel", role: .cancel) { }
///     } message: { item in
///         Text("Are you sure you want to delete \(item.name)?")
///     }
/// }
/// ```
@MainActor
public struct DataAlertModifier<Item: Sendable & Equatable, Actions: View, Message: View>: ViewModifier {
    /// The title of the alert
    let title: String

    /// Binding to optional data that controls presentation
    @Binding var data: Item?

    /// A closure that creates the alert's actions using the data
    let actions: @MainActor @Sendable (Item) -> Actions

    /// A closure that creates the alert's message using the data
    let message: @MainActor @Sendable (Item) -> Message

    /// Creates a data-driven alert modifier.
    ///
    /// - Parameters:
    ///   - title: The title of the alert.
    ///   - data: A binding to optional data. When the data is non-nil,
    ///     the alert is presented.
    ///   - actions: A view builder that creates the alert's actions using the data.
    ///   - message: A view builder that creates the alert's message using the data.
    public init(
        title: String,
        data: Binding<Item?>,
        @ViewBuilder actions: @escaping @MainActor @Sendable (Item) -> Actions,
        @ViewBuilder message: @escaping @MainActor @Sendable (Item) -> Message
    ) {
        self.title = title
        self._data = data
        self.actions = actions
        self.message = message
    }

    public func body(content: Content) -> some View {
        let isPresented = Binding<Bool>(
            get: { data != nil },
            set: { if !$0 { data = nil } }
        )

        return content.modifier(
            DataAlertPresentationModifier(
                title: title,
                isPresented: isPresented,
                data: data,
                actions: actions,
                message: message
            )
        )
    }
}

// MARK: - Internal Presentation Modifiers

/// Internal modifier that handles the actual alert presentation.
@MainActor
struct AlertPresentationModifier<Actions: View>: ViewModifier {
    @Environment(\.presentationCoordinator) var coordinator
    let title: String
    let message: String?
    @Binding var isPresented: Bool
    let actions: @MainActor @Sendable () -> Actions

    func body(content: Content) -> some View {
        content
            .onChange(of: isPresented) { newValue in
                if newValue {
                    presentAlert()
                }
            }
    }

    private func presentAlert() {
        let alertContent = VStack {
            Text(title)
            if let message = message {
                Text(message)
            }
            actions()
        }

        coordinator.present(
            type: .alert,
            content: AnyView(alertContent),
            onDismiss: { @MainActor in
                isPresented = false
            }
        )
    }
}

/// Internal modifier that handles alert presentation with a message view.
@MainActor
struct AlertPresentationWithMessageModifier<Actions: View, Message: View>: ViewModifier {
    @Environment(\.presentationCoordinator) var coordinator
    let title: String
    @Binding var isPresented: Bool
    let actions: @MainActor @Sendable () -> Actions
    let message: @MainActor @Sendable () -> Message

    func body(content: Content) -> some View {
        content
            .onChange(of: isPresented) { newValue in
                if newValue {
                    presentAlert()
                }
            }
    }

    private func presentAlert() {
        let alertContent = VStack {
            Text(title)
            message()
            actions()
        }

        coordinator.present(
            type: .alert,
            content: AnyView(alertContent),
            onDismiss: { @MainActor in
                isPresented = false
            }
        )
    }
}

/// Internal modifier that handles data-driven alert presentation.
@MainActor
struct DataAlertPresentationModifier<Item: Sendable, Actions: View, Message: View>: ViewModifier {
    @Environment(\.presentationCoordinator) var coordinator
    let title: String
    let isPresented: Binding<Bool>
    let data: Item?
    let actions: @MainActor @Sendable (Item) -> Actions
    let message: @MainActor @Sendable (Item) -> Message

    func body(content: Content) -> some View {
        content
            .onChange(of: isPresented.wrappedValue) { newValue in
                if newValue, let item = data {
                    presentAlert(with: item)
                }
            }
    }

    private func presentAlert(with item: Item) {
        let alertContent = VStack {
            Text(title)
            message(item)
            actions(item)
        }

        coordinator.present(
            type: .alert,
            content: AnyView(alertContent),
            onDismiss: { @MainActor in
                isPresented.wrappedValue = false
            }
        )
    }
}
