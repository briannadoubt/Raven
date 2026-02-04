import Foundation

// MARK: - PresentationType

/// The type of presentation being displayed.
///
/// This enum defines the different presentation styles available in Raven,
/// matching SwiftUI's presentation APIs.
public enum PresentationType: Sendable, Equatable {
    /// A sheet presentation that slides up from the bottom
    case sheet

    /// A full-screen cover that takes over the entire screen
    case fullScreenCover

    /// An alert dialog for user notifications
    case alert

    /// A confirmation dialog with multiple action choices
    case confirmationDialog

    /// A popover that appears anchored to a view
    ///
    /// - Parameters:
    ///   - anchor: The attachment point for the popover
    ///   - edge: The preferred edge for the popover arrow
    case popover(anchor: PopoverAttachmentAnchor, edge: Edge)
}

// MARK: - PresentationEntry

/// A single entry in the presentation stack.
///
/// This structure holds all the information needed to manage a presentation,
/// including its type, content, z-index for layering, and optional dismiss callback.
public struct PresentationEntry: Sendable, Identifiable {
    /// Unique identifier for this presentation
    public let id: UUID

    /// The type of presentation (sheet, alert, etc.)
    public let type: PresentationType

    /// The view content being presented (type-erased)
    public let content: AnyView

    /// The z-index for CSS layering
    public let zIndex: Int

    /// Optional callback when the presentation is dismissed
    public let onDismiss: (@MainActor @Sendable () -> Void)?

    /// Metadata for presentation configuration
    public let metadata: [String: any Sendable]

    /// Creates a new presentation entry.
    ///
    /// - Parameters:
    ///   - id: Unique identifier (defaults to a new UUID)
    ///   - type: The presentation type
    ///   - content: The view to present
    ///   - zIndex: The z-index for layering
    ///   - onDismiss: Optional callback when dismissed
    ///   - metadata: Additional metadata for presentation configuration
    public init(
        id: UUID = UUID(),
        type: PresentationType,
        content: AnyView,
        zIndex: Int,
        onDismiss: (@MainActor @Sendable () -> Void)? = nil,
        metadata: [String: any Sendable] = [:]
    ) {
        self.id = id
        self.type = type
        self.content = content
        self.zIndex = zIndex
        self.onDismiss = onDismiss
        self.metadata = metadata
    }
}

// MARK: - PresentationCoordinator

/// Manages the presentation stack for the application.
///
/// The `PresentationCoordinator` is the central authority for managing all presentations
/// (sheets, alerts, popovers, etc.) in a Raven application. It maintains a stack of
/// active presentations and handles their z-index layering.
///
/// ## Usage
///
/// The coordinator is typically accessed through the environment:
///
/// ```swift
/// struct MyView: View {
///     @Environment(\.presentationCoordinator) var coordinator
///     @State private var showSheet = false
///
///     var body: some View {
///         Button("Show Sheet") {
///             showSheet = true
///         }
///         .sheet(isPresented: $showSheet) {
///             Text("Sheet Content")
///         }
///     }
/// }
/// ```
///
/// ## Z-Index Management
///
/// The coordinator automatically manages z-index values for presentations:
/// - Base z-index starts at 1000
/// - Each presentation increments by 10
/// - This ensures proper layering when multiple presentations are active
///
/// ## Thread Safety
///
/// All methods must be called from the main actor.
@MainActor
public final class PresentationCoordinator: ObservableObject, Sendable {
    /// The stack of active presentations, ordered from bottom to top
    @Published public private(set) var presentations: [PresentationEntry] = []

    /// The base z-index for the first presentation
    private let baseZIndex: Int = 1000

    /// The increment between each presentation's z-index
    private let zIndexIncrement: Int = 10

    /// Creates a new presentation coordinator.
    public init() {}

    // MARK: - Public Methods

    /// Presents a new view with the specified presentation type.
    ///
    /// This method adds a new presentation to the stack and returns its unique identifier.
    /// The z-index is automatically calculated based on the current stack depth.
    ///
    /// - Parameters:
    ///   - type: The presentation type (sheet, alert, etc.)
    ///   - content: The view to present
    ///   - onDismiss: Optional callback when the presentation is dismissed
    ///   - metadata: Additional metadata for presentation configuration
    /// - Returns: The unique identifier for this presentation
    ///
    /// Example:
    /// ```swift
    /// let id = coordinator.present(
    ///     type: .sheet,
    ///     content: AnyView(MySheetView()),
    ///     onDismiss: { print("Sheet dismissed") },
    ///     metadata: ["detents": detents, "dismissDisabled": true]
    /// )
    /// ```
    @discardableResult
    public func present(
        type: PresentationType,
        content: AnyView,
        onDismiss: (@MainActor @Sendable () -> Void)? = nil,
        metadata: [String: any Sendable] = [:]
    ) -> UUID {
        let zIndex = calculateZIndex()
        let entry = PresentationEntry(
            type: type,
            content: content,
            zIndex: zIndex,
            onDismiss: onDismiss,
            metadata: metadata
        )
        presentations.append(entry)
        return entry.id
    }

    /// Dismisses the presentation with the specified identifier.
    ///
    /// If the presentation has an `onDismiss` callback, it will be invoked before removal.
    ///
    /// - Parameter id: The unique identifier of the presentation to dismiss
    /// - Returns: `true` if a presentation was dismissed, `false` if not found
    ///
    /// Example:
    /// ```swift
    /// coordinator.dismiss(presentationId)
    /// ```
    @discardableResult
    public func dismiss(_ id: UUID) -> Bool {
        guard let index = presentations.firstIndex(where: { $0.id == id }) else {
            return false
        }

        let entry = presentations.remove(at: index)
        entry.onDismiss?()
        return true
    }

    /// Dismisses all presentations in the stack.
    ///
    /// Presentations are dismissed in reverse order (top to bottom), and each
    /// presentation's `onDismiss` callback is invoked if present.
    ///
    /// Example:
    /// ```swift
    /// coordinator.dismissAll()
    /// ```
    public func dismissAll() {
        // Dismiss in reverse order (top to bottom)
        for entry in presentations.reversed() {
            entry.onDismiss?()
        }
        presentations.removeAll()
    }

    /// Returns the topmost presentation, if any.
    ///
    /// - Returns: The most recently presented entry, or `nil` if the stack is empty
    public func topPresentation() -> PresentationEntry? {
        presentations.last
    }

    /// Returns the number of active presentations.
    ///
    /// - Returns: The count of presentations in the stack
    public var count: Int {
        presentations.count
    }

    // MARK: - Private Methods

    /// Calculates the z-index for the next presentation.
    ///
    /// - Returns: The z-index value based on the current stack depth
    private func calculateZIndex() -> Int {
        baseZIndex + (presentations.count * zIndexIncrement)
    }
}
