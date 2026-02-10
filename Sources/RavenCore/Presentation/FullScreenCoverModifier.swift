import Foundation

// MARK: - Full Screen Cover Modifier (Binding-based)

/// A view modifier that presents a full-screen cover based on a binding.
///
/// This modifier presents a full-screen modal view when the binding's value
/// is `true` and dismisses it when the value becomes `false`. Unlike sheets,
/// full-screen covers take up the entire screen and don't allow the underlying
/// content to be visible.
///
/// ## Usage
///
/// ```swift
/// .fullScreenCover(isPresented: $showCover) {
///     FullScreenContent()
/// }
/// ```
///
/// ## Characteristics
///
/// - Takes up the entire screen
/// - No underlying content is visible
/// - Cannot be dismissed by swiping down (unless explicitly enabled)
/// - Typically used for immersive experiences or modal workflows
///
/// ## Dismissal
///
/// The cover can be dismissed by:
/// - Setting the binding to `false`
/// - Programmatic dismissal via environment dismiss action
/// - Calling the `onDismiss` callback
///
/// - Note: Use the `.fullScreenCover(isPresented:content:)` modifier on `View`
///   rather than applying this modifier directly.
@MainActor
public struct FullScreenCoverModifier<CoverContent: View>: ViewModifier, PresentationModifier {
    /// Binding that controls whether the cover is presented
    @Binding private var isPresented: Bool

    /// The content to display in the full-screen cover
    private let content: @MainActor @Sendable () -> CoverContent

    /// Optional callback when the cover is dismissed
    private let onDismiss: (@MainActor @Sendable () -> Void)?

    /// The current presentation ID, if presented
    @State private var presentationId: UUID?

    /// The presentation coordinator from environment
    @Environment(\.presentationCoordinator) private var coordinator

    /// Creates a full-screen cover modifier with a boolean binding.
    ///
    /// - Parameters:
    ///   - isPresented: A binding that controls the presentation.
    ///   - onDismiss: Optional closure to execute when the cover is dismissed.
    ///   - content: A closure returning the content to display.
    public init(
        isPresented: Binding<Bool>,
        onDismiss: (@MainActor @Sendable () -> Void)? = nil,
        @ViewBuilder content: @escaping @MainActor @Sendable () -> CoverContent
    ) {
        self._isPresented = isPresented
        self.onDismiss = onDismiss
        self.content = content
    }

    // MARK: - PresentationModifier

    public func register(with coordinator: PresentationCoordinator) -> UUID? {
        guard isPresented else { return nil }

        let id = coordinator.present(
            type: .fullScreenCover,
            content: AnyView(content()),
            onDismiss: { @MainActor [onDismiss] in
                isPresented = false
                onDismiss?()
            }
        )
        return id
    }

    public func unregister(id: UUID, from coordinator: PresentationCoordinator) {
        coordinator.dismiss(id)
    }

    public func shouldUpdate(currentId: UUID?, coordinator: PresentationCoordinator) -> Bool {
        // Register if we should present but aren't
        if isPresented && currentId == nil {
            return true
        }
        // Unregister if we shouldn't present but are
        if !isPresented && currentId != nil {
            return true
        }
        return false
    }

    // MARK: - ViewModifier

    public func body(content: Content) -> some View {
        content
            .onAppear {
                // Register on appear if needed
                if shouldUpdate(currentId: presentationId, coordinator: coordinator) {
                    if isPresented {
                        presentationId = register(with: coordinator)
                    }
                }
            }
            .onChange(of: isPresented) { newValue in
                // Handle presentation state changes
                if newValue && presentationId == nil {
                    presentationId = register(with: coordinator)
                } else if !newValue, let id = presentationId {
                    unregister(id: id, from: coordinator)
                    presentationId = nil
                }
            }
    }
}

// MARK: - Full Screen Cover Modifier (Item-based)

/// A view modifier that presents a full-screen cover based on an optional identifiable item.
///
/// This modifier presents a full-screen cover when the item is non-nil and
/// dismisses it when the item becomes nil. The content closure receives the
/// unwrapped item.
///
/// ## Usage
///
/// ```swift
/// struct DetailCover: Identifiable {
///     let id = UUID()
///     let title: String
///     let content: String
/// }
///
/// @State private var selectedItem: DetailCover?
///
/// .fullScreenCover(item: $selectedItem) { item in
///     VStack {
///         Text(item.title).font(.largeTitle)
///         Text(item.content)
///     }
/// }
/// ```
///
/// ## Use Cases
///
/// Full-screen covers are ideal for:
/// - Immersive detail views
/// - Modal editing workflows
/// - Onboarding flows
/// - Full-screen media viewers
/// - Document editors
///
/// - Note: Use the `.fullScreenCover(item:content:)` modifier on `View`
///   rather than applying this modifier directly.
@MainActor
public struct ItemFullScreenCoverModifier<Item: Identifiable & Sendable & Equatable, CoverContent: View>: ViewModifier, PresentationModifier {
    /// Binding to an optional identifiable item
    @Binding private var item: Item?

    /// Closure that creates cover content from the item
    private let content: @MainActor @Sendable (Item) -> CoverContent

    /// Optional callback when the cover is dismissed
    private let onDismiss: (@MainActor @Sendable () -> Void)?

    /// The current presentation ID, if presented
    @State private var presentationId: UUID?

    /// The presentation coordinator from environment
    @Environment(\.presentationCoordinator) private var coordinator

    /// The last presented item (to detect changes)
    @State private var lastItem: Item?

    /// Creates a full-screen cover modifier with an item binding.
    ///
    /// - Parameters:
    ///   - item: A binding to an optional identifiable item.
    ///   - onDismiss: Optional closure to execute when the cover is dismissed.
    ///   - content: A closure that creates the cover content from the item.
    public init(
        item: Binding<Item?>,
        onDismiss: (@MainActor @Sendable () -> Void)? = nil,
        @ViewBuilder content: @escaping @MainActor @Sendable (Item) -> CoverContent
    ) {
        self._item = item
        self.onDismiss = onDismiss
        self.content = content
    }

    // MARK: - PresentationModifier

    public func register(with coordinator: PresentationCoordinator) -> UUID? {
        guard let currentItem = item else { return nil }

        let id = coordinator.present(
            type: .fullScreenCover,
            content: AnyView(content(currentItem)),
            onDismiss: { @MainActor [onDismiss] in
                item = nil
                onDismiss?()
            }
        )
        return id
    }

    public func unregister(id: UUID, from coordinator: PresentationCoordinator) {
        coordinator.dismiss(id)
    }

    public func shouldUpdate(currentId: UUID?, coordinator: PresentationCoordinator) -> Bool {
        let hasItem = item != nil
        let hasPresentation = currentId != nil

        // Register if we have an item but no presentation
        if hasItem && !hasPresentation {
            return true
        }
        // Unregister if we have no item but have a presentation
        if !hasItem && hasPresentation {
            return true
        }
        // Re-register if the item changed
        if hasItem && hasPresentation, let current = item, let last = lastItem, current.id != last.id {
            return true
        }

        return false
    }

    // MARK: - ViewModifier

    public func body(content: Content) -> some View {
        content
            .onAppear {
                // Register on appear if needed
                if item != nil && presentationId == nil {
                    presentationId = register(with: coordinator)
                    lastItem = item
                }
            }
            .onChange(of: item) { newValue in
                // Handle item changes
                if let newItem = newValue {
                    // Item is non-nil: present or update
                    if let id = presentationId, lastItem != newItem {
                        // Item changed: dismiss old and present new
                        unregister(id: id, from: coordinator)
                        presentationId = register(with: coordinator)
                    } else if presentationId == nil {
                        // No current presentation: register new
                        presentationId = register(with: coordinator)
                    }
                    lastItem = newItem
                } else if let id = presentationId {
                    // Item became nil: dismiss
                    unregister(id: id, from: coordinator)
                    presentationId = nil
                    lastItem = nil
                }
            }
    }
}
