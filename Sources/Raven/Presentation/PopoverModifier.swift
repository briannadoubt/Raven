import Foundation

// MARK: - Popover Modifier (isPresented)

/// A view modifier that presents a popover based on a boolean binding.
///
/// This modifier displays a popover when the `isPresented` binding is `true`.
/// The popover is positioned relative to the source view using the specified
/// attachment anchor and arrow edge.
///
/// ## Usage
///
/// ```swift
/// struct ContentView: View {
///     @State private var showPopover = false
///
///     var body: some View {
///         Button("Show Info") {
///             showPopover = true
///         }
///         .popover(isPresented: $showPopover) {
///             Text("Additional information")
///                 .padding()
///         }
///     }
/// }
/// ```
///
/// ## Thread Safety
///
/// All methods must be called from the main actor.
@MainActor
struct PopoverModifier<PopoverContent: View>: ViewModifier, PresentationModifier {
    /// Binding that controls whether the popover is presented
    @Binding var isPresented: Bool

    /// The attachment point for the popover
    let attachmentAnchor: PopoverAttachmentAnchor

    /// The preferred edge for the popover arrow
    let arrowEdge: Edge

    /// Closure that builds the popover content
    let content: () -> PopoverContent

    /// Optional callback invoked when the popover is dismissed
    let onDismiss: (@MainActor @Sendable () -> Void)?

    /// The presentation coordinator from the environment
    @Environment(\.presentationCoordinator) private var coordinator

    /// The current presentation ID if active
    @State private var presentationId: UUID?

    // MARK: - Initialization

    /// Creates a new popover modifier.
    ///
    /// - Parameters:
    ///   - isPresented: A binding that controls the popover's visibility
    ///   - attachmentAnchor: The attachment point for the popover
    ///   - arrowEdge: The preferred edge for the popover arrow
    ///   - onDismiss: Optional callback when dismissed
    ///   - content: A closure that builds the popover content
    init(
        isPresented: Binding<Bool>,
        attachmentAnchor: PopoverAttachmentAnchor,
        arrowEdge: Edge,
        onDismiss: (@MainActor @Sendable () -> Void)?,
        @ViewBuilder content: @escaping () -> PopoverContent
    ) {
        self._isPresented = isPresented
        self.attachmentAnchor = attachmentAnchor
        self.arrowEdge = arrowEdge
        self.onDismiss = onDismiss
        self.content = content
    }

    // MARK: - PresentationModifier Implementation

    func register(with coordinator: PresentationCoordinator) -> UUID? {
        guard isPresented else { return nil }

        let handleDismiss: @MainActor @Sendable () -> Void = { [onDismiss, _isPresented] in
            _isPresented.wrappedValue = false
            onDismiss?()
        }

        return coordinator.present(
            type: .popover(anchor: attachmentAnchor, edge: arrowEdge),
            content: AnyView(content()),
            onDismiss: handleDismiss
        )
    }

    func unregister(id: UUID, from coordinator: PresentationCoordinator) {
        coordinator.dismiss(id)
    }

    func shouldUpdate(currentId: UUID?, coordinator: PresentationCoordinator) -> Bool {
        // Need to register if we should be presented but aren't
        if isPresented && currentId == nil {
            return true
        }

        // Need to unregister if we shouldn't be presented but are
        if !isPresented && currentId != nil {
            return true
        }

        return false
    }

    // MARK: - ViewModifier Implementation

    func body(content: Content) -> some View {
        content
            .onAppear {
                updatePresentation()
            }
            .onChange(of: isPresented) { _ in
                updatePresentation()
            }
    }

    // MARK: - Private Methods

    /// Updates the presentation state based on the current binding value.
    private func updatePresentation() {
        guard shouldUpdate(currentId: presentationId, coordinator: coordinator) else {
            return
        }

        if isPresented {
            // Register new presentation
            if presentationId == nil {
                presentationId = register(with: coordinator)
            }
        } else {
            // Unregister existing presentation
            if let id = presentationId {
                unregister(id: id, from: coordinator)
                presentationId = nil
            }
        }
    }
}

// MARK: - Popover Modifier (item)

/// A view modifier that presents a popover based on an optional identifiable item.
///
/// This modifier displays a popover when the `item` binding contains a non-nil value.
/// The popover is automatically dismissed when the item becomes nil. The item is
/// passed to the content closure, allowing you to customize the popover based on
/// the presented data.
///
/// ## Usage
///
/// ```swift
/// struct ContentView: View {
///     @State private var selectedUser: User?
///
///     var body: some View {
///         List(users) { user in
///             Button(user.name) {
///                 selectedUser = user
///             }
///         }
///         .popover(item: $selectedUser) { user in
///             UserDetailView(user: user)
///         }
///     }
/// }
/// ```
///
/// ## Thread Safety
///
/// All methods must be called from the main actor.
@MainActor
struct PopoverItemModifier<Item: Identifiable & Sendable, PopoverContent: View>: ViewModifier, PresentationModifier where Item.ID: Sendable {
    /// Binding to an optional identifiable item
    @Binding var item: Item?

    /// The attachment point for the popover
    let attachmentAnchor: PopoverAttachmentAnchor

    /// The preferred edge for the popover arrow
    let arrowEdge: Edge

    /// Closure that builds the popover content from the item
    let content: (Item) -> PopoverContent

    /// Optional callback invoked when the popover is dismissed
    let onDismiss: (@MainActor @Sendable () -> Void)?

    /// The presentation coordinator from the environment
    @Environment(\.presentationCoordinator) private var coordinator

    /// The current presentation ID if active
    @State private var presentationId: UUID?

    /// The item ID that's currently being presented
    @State private var currentItemId: Item.ID?

    // MARK: - Initialization

    /// Creates a new item-based popover modifier.
    ///
    /// - Parameters:
    ///   - item: A binding to an optional identifiable item
    ///   - attachmentAnchor: The attachment point for the popover
    ///   - arrowEdge: The preferred edge for the popover arrow
    ///   - onDismiss: Optional callback when dismissed
    ///   - content: A closure that builds the popover content from the item
    init(
        item: Binding<Item?>,
        attachmentAnchor: PopoverAttachmentAnchor,
        arrowEdge: Edge,
        onDismiss: (@MainActor @Sendable () -> Void)?,
        @ViewBuilder content: @escaping (Item) -> PopoverContent
    ) {
        self._item = item
        self.attachmentAnchor = attachmentAnchor
        self.arrowEdge = arrowEdge
        self.onDismiss = onDismiss
        self.content = content
    }

    // MARK: - PresentationModifier Implementation

    func register(with coordinator: PresentationCoordinator) -> UUID? {
        guard let item = item else { return nil }

        currentItemId = item.id

        let handleDismiss: @MainActor @Sendable () -> Void = { [onDismiss, _item] in
            _item.wrappedValue = nil
            onDismiss?()
        }

        return coordinator.present(
            type: .popover(anchor: attachmentAnchor, edge: arrowEdge),
            content: AnyView(content(item)),
            onDismiss: handleDismiss
        )
    }

    func unregister(id: UUID, from coordinator: PresentationCoordinator) {
        coordinator.dismiss(id)
        currentItemId = nil
    }

    func shouldUpdate(currentId: UUID?, coordinator: PresentationCoordinator) -> Bool {
        // Need to register if we have an item but no presentation
        if item != nil && currentId == nil {
            return true
        }

        // Need to unregister if we have no item but have a presentation
        if item == nil && currentId != nil {
            return true
        }

        // Need to update if the item changed while already presenting
        if let item = item, let currentItemId = currentItemId, item.id != currentItemId {
            return true
        }

        return false
    }

    // MARK: - ViewModifier Implementation

    func body(content: Content) -> some View {
        content
            .onAppear {
                updatePresentation()
            }
            .onChange(of: item?.id) { _ in
                updatePresentation()
            }
    }

    // MARK: - Private Methods

    /// Updates the presentation state based on the current item.
    private func updatePresentation() {
        guard shouldUpdate(currentId: presentationId, coordinator: coordinator) else {
            return
        }

        // If we need to update and have a presentation, unregister it first
        if let id = presentationId {
            unregister(id: id, from: coordinator)
            presentationId = nil
        }

        // If we have an item, register a new presentation
        if item != nil {
            presentationId = register(with: coordinator)
        }
    }
}

// MARK: - Sendable Conformance

extension PopoverModifier: Sendable where PopoverContent: Sendable {}
extension PopoverItemModifier: Sendable where Item: Sendable, Item.ID: Sendable, PopoverContent: Sendable {}
