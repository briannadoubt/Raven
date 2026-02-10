import Foundation

// MARK: - PresentationModifier Protocol

/// A protocol for view modifiers that manage presentations.
///
/// Types conforming to `PresentationModifier` can register and unregister
/// presentations with the `PresentationCoordinator` based on their state.
/// This protocol provides a common interface for modifiers like `.sheet()`,
/// `.alert()`, `.fullScreenCover()`, and others.
///
/// ## Implementing a Presentation Modifier
///
/// To create a custom presentation modifier, conform to this protocol and
/// implement the required methods:
///
/// ```swift
/// struct MyPresentationModifier: PresentationModifier {
///     @Binding var isPresented: Bool
///     let content: () -> AnyView
///
///     func register(with coordinator: PresentationCoordinator) -> UUID? {
///         guard isPresented else { return nil }
///
///         return coordinator.present(
///             type: .sheet,
///             content: content(),
///             onDismiss: { isPresented = false }
///         )
///     }
///
///     func unregister(id: UUID, from coordinator: PresentationCoordinator) {
///         coordinator.dismiss(id)
///     }
///
///     func shouldUpdate(currentId: UUID?, coordinator: PresentationCoordinator) -> Bool {
///         // Re-register if isPresented changed to true and we don't have an ID
///         (isPresented && currentId == nil) ||
///         // Unregister if isPresented changed to false and we have an ID
///         (!isPresented && currentId != nil)
///     }
/// }
/// ```
///
/// ## Integration with ViewModifier
///
/// Presentation modifiers typically also conform to `ViewModifier` to integrate
/// with the view hierarchy:
///
/// ```swift
/// extension MyPresentationModifier: ViewModifier {
///     func body(content: Content) -> some View {
///         content
///             .onAppear {
///                 // Register if needed
///             }
///             .onChange(of: isPresented) {
///                 // Update presentation state
///             }
///     }
/// }
/// ```
///
/// ## State Management
///
/// Presentation modifiers are responsible for:
/// - Registering presentations when they should appear
/// - Unregistering presentations when they should disappear
/// - Updating the presentation state when bindings change
/// - Calling dismiss callbacks when presentations are removed
///
/// - Note: All methods must be called from the main actor.
@MainActor
public protocol PresentationModifier: Sendable {
    /// Registers a presentation with the coordinator if appropriate.
    ///
    /// This method should check the modifier's state and register a presentation
    /// if needed. For example, a sheet modifier would check if `isPresented` is true.
    ///
    /// - Parameter coordinator: The presentation coordinator to register with
    /// - Returns: The UUID of the registered presentation, or `nil` if not registered
    ///
    /// Example implementation:
    /// ```swift
    /// func register(with coordinator: PresentationCoordinator) -> UUID? {
    ///     guard isPresented else { return nil }
    ///
    ///     return coordinator.present(
    ///         type: .sheet,
    ///         content: makeContent(),
    ///         onDismiss: handleDismiss
    ///     )
    /// }
    /// ```
    func register(with coordinator: PresentationCoordinator) -> UUID?

    /// Unregisters a presentation from the coordinator.
    ///
    /// This method should remove the presentation with the given ID from the
    /// coordinator. It's called when the presentation should be dismissed.
    ///
    /// - Parameters:
    ///   - id: The UUID of the presentation to unregister
    ///   - coordinator: The presentation coordinator to unregister from
    ///
    /// Example implementation:
    /// ```swift
    /// func unregister(id: UUID, from coordinator: PresentationCoordinator) {
    ///     coordinator.dismiss(id)
    ///     isPresented = false
    /// }
    /// ```
    func unregister(id: UUID, from coordinator: PresentationCoordinator)

    /// Determines if the presentation state should be updated.
    ///
    /// This method is called when the modifier's state might have changed.
    /// It should return `true` if the presentation needs to be registered or
    /// unregistered.
    ///
    /// - Parameters:
    ///   - currentId: The current presentation ID, or `nil` if not presented
    ///   - coordinator: The presentation coordinator
    /// - Returns: `true` if the presentation state should be updated
    ///
    /// Example implementation:
    /// ```swift
    /// func shouldUpdate(currentId: UUID?, coordinator: PresentationCoordinator) -> Bool {
    ///     // Should register if we want to present but aren't
    ///     if isPresented && currentId == nil {
    ///         return true
    ///     }
    ///     // Should unregister if we don't want to present but are
    ///     if !isPresented && currentId != nil {
    ///         return true
    ///     }
    ///     return false
    /// }
    /// ```
    func shouldUpdate(currentId: UUID?, coordinator: PresentationCoordinator) -> Bool
}

// MARK: - Default Implementations

extension PresentationModifier {
    /// Default implementation for determining if an update is needed.
    ///
    /// This implementation is a simple helper that's sufficient for most use cases.
    /// Override this method if you need custom update logic.
    ///
    /// - Parameters:
    ///   - currentId: The current presentation ID
    ///   - coordinator: The presentation coordinator
    /// - Returns: Always returns `true` to allow subclasses to handle updates
    public func shouldUpdate(currentId: UUID?, coordinator: PresentationCoordinator) -> Bool {
        true
    }
}

// MARK: - Documentation Examples

// The following examples demonstrate various presentation modifier patterns.
// These are for documentation purposes and show best practices.

/// Example: Sheet presentation modifier
///
/// ```swift
/// struct SheetModifier<SheetContent: View>: PresentationModifier, ViewModifier {
///     @Binding var isPresented: Bool
///     let content: () -> SheetContent
///     let onDismiss: (() -> Void)?
///
///     @State private var presentationId: UUID?
///
///     func register(with coordinator: PresentationCoordinator) -> UUID? {
///         guard isPresented else { return nil }
///
///         return coordinator.present(
///             type: .sheet,
///             content: AnyView(content()),
///             onDismiss: {
///                 isPresented = false
///                 onDismiss?()
///             }
///         )
///     }
///
///     func unregister(id: UUID, from coordinator: PresentationCoordinator) {
///         coordinator.dismiss(id)
///     }
///
///     func body(content: Content) -> some View {
///         content
///             // Implementation details...
///     }
/// }
/// ```

/// Example: Alert presentation modifier
///
/// ```swift
/// struct AlertModifier: PresentationModifier, ViewModifier {
///     @Binding var isPresented: Bool
///     let title: String
///     let message: String?
///     let actions: [AlertAction]
///
///     @State private var presentationId: UUID?
///
///     func register(with coordinator: PresentationCoordinator) -> UUID? {
///         guard isPresented else { return nil }
///
///         return coordinator.present(
///             type: .alert,
///             content: AnyView(makeAlertView()),
///             onDismiss: { isPresented = false }
///         )
///     }
///
///     func unregister(id: UUID, from coordinator: PresentationCoordinator) {
///         coordinator.dismiss(id)
///     }
///
///     func body(content: Content) -> some View {
///         content
///             // Implementation details...
///     }
///
///     private func makeAlertView() -> some View {
///         // Build alert UI...
///     }
/// }
/// ```
