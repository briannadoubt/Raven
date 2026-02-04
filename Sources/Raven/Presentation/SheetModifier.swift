import Foundation

// MARK: - Sheet Modifier (Binding-based)

/// A view modifier that presents a sheet based on a binding.
///
/// This modifier presents a sheet when the binding's value is `true` and
/// dismisses it when the value becomes `false`. It integrates with the
/// `PresentationCoordinator` to manage the presentation lifecycle.
///
/// ## Usage
///
/// ```swift
/// .sheet(isPresented: $showSheet) {
///     SheetContent()
/// }
/// ```
///
/// ## Dismissal
///
/// The sheet can be dismissed by:
/// - Setting the binding to `false`
/// - User interaction (swipe down or tap outside)
/// - Calling the `onDismiss` callback
///
/// - Note: Use the `.sheet(isPresented:content:)` modifier on `View` rather
///   than applying this modifier directly.
@MainActor
public struct SheetModifier<SheetContent: View>: ViewModifier, PresentationModifier {
    /// Binding that controls whether the sheet is presented
    @Binding private var isPresented: Bool

    /// The content to display in the sheet
    private let content: @MainActor @Sendable () -> SheetContent

    /// Optional callback when the sheet is dismissed
    private let onDismiss: (@MainActor @Sendable () -> Void)?

    /// The current presentation ID, if presented
    @State private var presentationId: UUID?

    /// The presentation coordinator from environment
    @Environment(\.presentationCoordinator) private var coordinator

    /// Creates a sheet modifier with a boolean binding.
    ///
    /// - Parameters:
    ///   - isPresented: A binding that controls the presentation.
    ///   - onDismiss: Optional closure to execute when the sheet is dismissed.
    ///   - content: A closure returning the content to display.
    public init(
        isPresented: Binding<Bool>,
        onDismiss: (@MainActor @Sendable () -> Void)? = nil,
        @ViewBuilder content: @escaping @MainActor @Sendable () -> SheetContent
    ) {
        self._isPresented = isPresented
        self.onDismiss = onDismiss
        self.content = content
    }

    // MARK: - PresentationModifier

    public func register(with coordinator: PresentationCoordinator) -> UUID? {
        guard isPresented else { return nil }

        let id = coordinator.present(
            type: .sheet,
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

    // MARK: - VNode Rendering

    /// Converts this sheet modifier to a VNode for DOM rendering.
    ///
    /// This method creates a dialog element using the HTML5 dialog API
    /// with sheet-specific styling and animations.
    ///
    /// - Returns: A VNode representing the sheet presentation
    @MainActor public func toVNode() -> VNode? {
        guard isPresented, let presentationId = presentationId else {
            return nil
        }

        // Create a presentation entry for rendering
        let entry = PresentationEntry(
            id: presentationId,
            type: .sheet,
            content: AnyView(content()),
            zIndex: coordinator.presentations.firstIndex(where: { $0.id == presentationId })
                .map { coordinator.presentations.count - $0 } ?? 1000,
            onDismiss: onDismiss
        )

        // Use SheetRenderer to create the VNode
        return SheetRenderer.render(entry: entry, coordinator: coordinator)
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

// MARK: - Sheet Modifier (Item-based)

/// A view modifier that presents a sheet based on an optional identifiable item.
///
/// This modifier presents a sheet when the item is non-nil and dismisses it
/// when the item becomes nil. The content closure receives the unwrapped item.
///
/// ## Usage
///
/// ```swift
/// struct DetailSheet: Identifiable {
///     let id = UUID()
///     let title: String
/// }
///
/// @State private var selectedItem: DetailSheet?
///
/// .sheet(item: $selectedItem) { item in
///     Text(item.title)
/// }
/// ```
///
/// ## Benefits
///
/// Item-based sheets are useful when you need to:
/// - Pass data to the sheet content
/// - Present different content based on the item
/// - Ensure type-safe data passing
///
/// - Note: Use the `.sheet(item:content:)` modifier on `View` rather
///   than applying this modifier directly.
@MainActor
public struct ItemSheetModifier<Item: Identifiable & Sendable & Equatable, SheetContent: View>: ViewModifier, PresentationModifier {
    /// Binding to an optional identifiable item
    @Binding private var item: Item?

    /// Closure that creates sheet content from the item
    private let content: @MainActor @Sendable (Item) -> SheetContent

    /// Optional callback when the sheet is dismissed
    private let onDismiss: (@MainActor @Sendable () -> Void)?

    /// The current presentation ID, if presented
    @State private var presentationId: UUID?

    /// The presentation coordinator from environment
    @Environment(\.presentationCoordinator) private var coordinator

    /// The last presented item (to detect changes)
    @State private var lastItem: Item?

    /// Creates a sheet modifier with an item binding.
    ///
    /// - Parameters:
    ///   - item: A binding to an optional identifiable item.
    ///   - onDismiss: Optional closure to execute when the sheet is dismissed.
    ///   - content: A closure that creates the sheet content from the item.
    public init(
        item: Binding<Item?>,
        onDismiss: (@MainActor @Sendable () -> Void)? = nil,
        @ViewBuilder content: @escaping @MainActor @Sendable (Item) -> SheetContent
    ) {
        self._item = item
        self.onDismiss = onDismiss
        self.content = content
    }

    // MARK: - PresentationModifier

    public func register(with coordinator: PresentationCoordinator) -> UUID? {
        guard let currentItem = item else { return nil }

        let id = coordinator.present(
            type: .sheet,
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

    // MARK: - VNode Rendering

    /// Converts this sheet modifier to a VNode for DOM rendering.
    ///
    /// This method creates a dialog element using the HTML5 dialog API
    /// with sheet-specific styling and animations.
    ///
    /// - Returns: A VNode representing the sheet presentation
    @MainActor public func toVNode() -> VNode? {
        guard let currentItem = item, let presentationId = presentationId else {
            return nil
        }

        // Create a presentation entry for rendering
        let entry = PresentationEntry(
            id: presentationId,
            type: .sheet,
            content: AnyView(content(currentItem)),
            zIndex: coordinator.presentations.firstIndex(where: { $0.id == presentationId })
                .map { coordinator.presentations.count - $0 } ?? 1000,
            onDismiss: onDismiss
        )

        // Use SheetRenderer to create the VNode
        return SheetRenderer.render(entry: entry, coordinator: coordinator)
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
