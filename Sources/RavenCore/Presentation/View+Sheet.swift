import Foundation

// MARK: - Sheet Modifiers

extension View {
    /// Presents a sheet when a binding to a Boolean value is true.
    ///
    /// Use this method to present a modal sheet that slides up from the bottom
    /// of the screen. The sheet is presented when `isPresented` is `true` and
    /// dismissed when it becomes `false`.
    ///
    /// ## Basic Usage
    ///
    /// ```swift
    /// struct ContentView: View {
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
    /// ## With Dismiss Callback
    ///
    /// ```swift
    /// .sheet(isPresented: $showSheet) {
    ///     SheetContent()
    /// } onDismiss: {
    ///     print("Sheet was dismissed")
    /// }
    /// ```
    ///
    /// ## Customizing Sheet Height
    ///
    /// Control the sheet's height with presentation detents:
    ///
    /// ```swift
    /// .sheet(isPresented: $showSheet) {
    ///     SheetContent()
    ///         .presentationDetents([.medium, .large])
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - isPresented: A binding to a Boolean that controls the sheet.
    ///   - onDismiss: Optional closure to execute when dismissed.
    ///   - content: A closure returning the content to display.
    /// - Returns: A view that presents a sheet.
    @MainActor
    public func sheet<Content: View>(
        isPresented: Binding<Bool>,
        onDismiss: (@MainActor @Sendable () -> Void)? = nil,
        @ViewBuilder content: @escaping @MainActor @Sendable () -> Content
    ) -> some View {
        modifier(SheetModifier(
            isPresented: isPresented,
            onDismiss: onDismiss,
            content: content
        ))
    }

    /// Presents a sheet using an optional identifiable item as input.
    ///
    /// Use this method when you need to pass data to the sheet content. The
    /// sheet is presented when `item` is non-nil and dismissed when it becomes nil.
    /// The content closure receives the unwrapped item.
    ///
    /// ## Usage with Item
    ///
    /// ```swift
    /// struct ContentView: View {
    ///     struct DetailItem: Identifiable {
    ///         let id = UUID()
    ///         let title: String
    ///         let description: String
    ///     }
    ///
    ///     @State private var selectedItem: DetailItem?
    ///
    ///     var body: some View {
    ///         Button("Show Details") {
    ///             selectedItem = DetailItem(
    ///                 title: "Item",
    ///                 description: "Details here"
    ///             )
    ///         }
    ///         .sheet(item: $selectedItem) { item in
    ///             VStack {
    ///                 Text(item.title).font(.headline)
    ///                 Text(item.description)
    ///             }
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// ## Benefits
    ///
    /// Item-based sheets provide:
    /// - Type-safe data passing to sheet content
    /// - Automatic dismissal when item is set to nil
    /// - Clean separation of presentation state and data
    ///
    /// - Parameters:
    ///   - item: A binding to an optional identifiable item.
    ///   - onDismiss: Optional closure to execute when dismissed.
    ///   - content: A closure that creates the sheet content from the item.
    /// - Returns: A view that presents a sheet based on an item.
    @MainActor
    public func sheet<Item: Identifiable & Sendable & Equatable, Content: View>(
        item: Binding<Item?>,
        onDismiss: (@MainActor @Sendable () -> Void)? = nil,
        @ViewBuilder content: @escaping @MainActor @Sendable (Item) -> Content
    ) -> some View {
        modifier(ItemSheetModifier(
            item: item,
            onDismiss: onDismiss,
            content: content
        ))
    }
}

// MARK: - Full Screen Cover Modifiers

extension View {
    /// Presents a full-screen modal cover when a binding to a Boolean is true.
    ///
    /// Use this method to present a modal view that covers the entire screen.
    /// Unlike sheets, full-screen covers completely obscure the underlying content
    /// and are ideal for immersive experiences.
    ///
    /// ## Basic Usage
    ///
    /// ```swift
    /// struct ContentView: View {
    ///     @State private var showCover = false
    ///
    ///     var body: some View {
    ///         Button("Show Cover") {
    ///             showCover = true
    ///         }
    ///         .fullScreenCover(isPresented: $showCover) {
    ///             FullScreenView()
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// ## Use Cases
    ///
    /// Full-screen covers are ideal for:
    /// - Onboarding flows
    /// - Media viewers (photos, videos)
    /// - Document editors
    /// - Immersive detail views
    /// - Modal workflows that require full attention
    ///
    /// ## Dismissal
    ///
    /// Add a dismiss button in the cover content:
    ///
    /// ```swift
    /// struct FullScreenView: View {
    ///     @Environment(\.dismiss) var dismiss
    ///
    ///     var body: some View {
    ///         VStack {
    ///             Button("Close") {
    ///                 dismiss()
    ///             }
    ///             // Cover content...
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - isPresented: A binding to a Boolean that controls the cover.
    ///   - onDismiss: Optional closure to execute when dismissed.
    ///   - content: A closure returning the content to display.
    /// - Returns: A view that presents a full-screen cover.
    @MainActor
    public func fullScreenCover<Content: View>(
        isPresented: Binding<Bool>,
        onDismiss: (@MainActor @Sendable () -> Void)? = nil,
        @ViewBuilder content: @escaping @MainActor @Sendable () -> Content
    ) -> some View {
        modifier(FullScreenCoverModifier(
            isPresented: isPresented,
            onDismiss: onDismiss,
            content: content
        ))
    }

    /// Presents a full-screen cover using an optional identifiable item.
    ///
    /// Use this method when you need to pass data to the full-screen cover.
    /// The cover is presented when `item` is non-nil and dismissed when it
    /// becomes nil.
    ///
    /// ## Usage with Item
    ///
    /// ```swift
    /// struct ContentView: View {
    ///     struct Document: Identifiable {
    ///         let id = UUID()
    ///         let title: String
    ///         let content: String
    ///     }
    ///
    ///     @State private var openDocument: Document?
    ///
    ///     var body: some View {
    ///         Button("Open Document") {
    ///             openDocument = Document(
    ///                 title: "Report",
    ///                 content: "Document content..."
    ///             )
    ///         }
    ///         .fullScreenCover(item: $openDocument) { doc in
    ///             DocumentEditor(document: doc)
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - item: A binding to an optional identifiable item.
    ///   - onDismiss: Optional closure to execute when dismissed.
    ///   - content: A closure that creates the cover content from the item.
    /// - Returns: A view that presents a full-screen cover based on an item.
    @MainActor
    public func fullScreenCover<Item: Identifiable & Sendable & Equatable, Content: View>(
        item: Binding<Item?>,
        onDismiss: (@MainActor @Sendable () -> Void)? = nil,
        @ViewBuilder content: @escaping @MainActor @Sendable (Item) -> Content
    ) -> some View {
        modifier(ItemFullScreenCoverModifier(
            item: item,
            onDismiss: onDismiss,
            content: content
        ))
    }
}

// MARK: - Presentation Detents

extension View {
    /// Sets the available detents for a sheet presentation.
    ///
    /// Use this modifier to control the height of sheet presentations. Detents
    /// allow users to resize sheets by dragging. The first detent in the array
    /// is the initial size.
    ///
    /// ## Built-in Detents
    ///
    /// ```swift
    /// .sheet(isPresented: $showSheet) {
    ///     SheetContent()
    ///         .presentationDetents([.medium, .large])
    /// }
    /// ```
    ///
    /// ## Custom Heights
    ///
    /// ```swift
    /// .presentationDetents([
    ///     .height(200),      // 200 points
    ///     .fraction(0.6),    // 60% of available height
    ///     .large             // Full height
    /// ])
    /// ```
    ///
    /// ## Dynamic Heights
    ///
    /// ```swift
    /// .presentationDetents([
    ///     .custom { context in
    ///         min(context.maxDetentValue * 0.7, 500)
    ///     }
    /// ])
    /// ```
    ///
    /// ## Selection Binding
    ///
    /// Track the current detent with a binding:
    ///
    /// ```swift
    /// @State private var currentDetent: PresentationDetent = .medium
    ///
    /// .presentationDetents(
    ///     [.medium, .large],
    ///     selection: $currentDetent
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - detents: The set of available detents.
    ///   - selection: Optional binding to track the current detent.
    /// - Returns: A view with configured presentation detents.
    ///
    /// - Note: This modifier only affects sheet presentations. It has no effect
    ///   on full-screen covers or other presentation types.
    @MainActor
    public func presentationDetents(
        _ detents: Set<PresentationDetent>
    ) -> some View {
        // Store detents in environment for rendering system to use
        environment(\.presentationDetents, detents)
    }
}

// MARK: - Environment Keys for Presentation Detents

/// Environment key for presentation detents.
private struct PresentationDetentsKey: EnvironmentKey {
    static let defaultValue: Set<PresentationDetent> = [.large]
}

extension EnvironmentValues {
    /// The available detents for sheet presentations.
    ///
    /// - Note: This is an internal property used by the presentation system.
    var presentationDetents: Set<PresentationDetent> {
        get { self[PresentationDetentsKey.self] }
        set { self[PresentationDetentsKey.self] = newValue }
    }
}

// MARK: - Additional Presentation Modifiers

extension View {
    /// Sets the background for a presentation.
    ///
    /// Use this modifier to customize the background of sheet presentations.
    ///
    /// ```swift
    /// .sheet(isPresented: $showSheet) {
    ///     SheetContent()
    ///         .presentationBackground(.blue.opacity(0.2))
    /// }
    /// ```
    ///
    /// - Parameter style: The shape style to use as the background.
    /// - Returns: A view with a custom presentation background.
    @MainActor
    public func presentationBackground<S: ShapeStyle>(_ style: S) -> some View {
        // Store in environment for rendering system
        environment(\.presentationBackground, AnyShapeStyle(style))
    }

    /// Sets the corner radius for a presentation.
    ///
    /// Use this modifier to customize the corner radius of sheet presentations.
    ///
    /// ```swift
    /// .sheet(isPresented: $showSheet) {
    ///     SheetContent()
    ///         .presentationCornerRadius(20)
    /// }
    /// ```
    ///
    /// - Parameter radius: The corner radius in points. Pass nil for default.
    /// - Returns: A view with a custom presentation corner radius.
    @MainActor
    public func presentationCornerRadius(_ radius: Double?) -> some View {
        environment(\.presentationCornerRadius, radius)
    }

    /// Controls whether a presentation can be dragged to resize.
    ///
    /// Use this modifier to disable the drag-to-resize gesture on sheets.
    ///
    /// ```swift
    /// .sheet(isPresented: $showSheet) {
    ///     SheetContent()
    ///         .presentationDragIndicator(.hidden)
    /// }
    /// ```
    ///
    /// - Parameter visibility: Whether the drag indicator is visible.
    /// - Returns: A view with configured drag indicator visibility.
    @MainActor
    public func presentationDragIndicator(_ visibility: Visibility) -> some View {
        environment(\.presentationDragIndicator, visibility)
    }
}

/// Visibility options for presentation elements.
public enum Visibility: String, Sendable, Equatable, Hashable {
    /// The element is visible.
    case visible

    /// The element is hidden.
    case hidden

    /// The element visibility is determined automatically.
    case automatic
}

/// Type-erased shape style for presentation backgrounds.
struct AnyShapeStyle: Sendable {
    // Placeholder for shape style type erasure
    init<S: ShapeStyle>(_ style: S) {
        // Store style information
    }
}

// MARK: - Additional Environment Keys

private struct PresentationBackgroundKey: EnvironmentKey {
    static let defaultValue: AnyShapeStyle? = nil
}

private struct PresentationCornerRadiusKey: EnvironmentKey {
    static let defaultValue: Double? = nil
}

private struct PresentationDragIndicatorKey: EnvironmentKey {
    static let defaultValue: Visibility = .automatic
}

extension EnvironmentValues {
    var presentationBackground: AnyShapeStyle? {
        get { self[PresentationBackgroundKey.self] }
        set { self[PresentationBackgroundKey.self] = newValue }
    }

    var presentationCornerRadius: Double? {
        get { self[PresentationCornerRadiusKey.self] }
        set { self[PresentationCornerRadiusKey.self] = newValue }
    }

    var presentationDragIndicator: Visibility {
        get { self[PresentationDragIndicatorKey.self] }
        set { self[PresentationDragIndicatorKey.self] = newValue }
    }
}
