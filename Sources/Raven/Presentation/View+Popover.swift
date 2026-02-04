import Foundation

// MARK: - View Extension for Popover

extension View {
    /// Presents a popover when a binding to a boolean value is true.
    ///
    /// Use this method to display a popover that appears when the `isPresented`
    /// binding becomes `true`. The popover is automatically dismissed when the
    /// binding becomes `false`, either through user interaction or programmatic
    /// changes.
    ///
    /// ## Basic Usage
    ///
    /// ```swift
    /// struct ContentView: View {
    ///     @State private var showInfo = false
    ///
    ///     var body: some View {
    ///         Button("Show Info") {
    ///             showInfo = true
    ///         }
    ///         .popover(isPresented: $showInfo) {
    ///             Text("This is important information")
    ///                 .padding()
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// ## Custom Anchoring
    ///
    /// Control where the popover attaches to the source view:
    ///
    /// ```swift
    /// .popover(
    ///     isPresented: $showPopover,
    ///     attachmentAnchor: .point(.topLeading),
    ///     arrowEdge: .bottom
    /// ) {
    ///     PopoverContent()
    /// }
    /// ```
    ///
    /// ## Arrow Edge
    ///
    /// Specify which edge should display the popover arrow:
    ///
    /// ```swift
    /// .popover(isPresented: $show, arrowEdge: .leading) {
    ///     Text("Arrow points from the leading edge")
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - isPresented: A binding to whether the popover is presented
    ///   - attachmentAnchor: The attachment point for the popover (default: `.rect(.bounds)`)
    ///   - arrowEdge: The preferred edge for the popover arrow (default: `.top`)
    ///   - onDismiss: Optional closure executed when the popover is dismissed
    ///   - content: A closure that returns the content of the popover
    ///
    /// - Returns: A view that presents a popover when the condition is true
    @MainActor
    public func popover<Content: View>(
        isPresented: Binding<Bool>,
        attachmentAnchor: PopoverAttachmentAnchor = .default,
        arrowEdge: Edge = .top,
        onDismiss: (@MainActor @Sendable () -> Void)? = nil,
        @ViewBuilder content: @escaping @MainActor @Sendable () -> Content
    ) -> some View {
        modifier(
            PopoverModifier(
                isPresented: isPresented,
                attachmentAnchor: attachmentAnchor,
                arrowEdge: arrowEdge,
                onDismiss: onDismiss,
                content: content
            )
        )
    }

    /// Presents a popover using an optional identifiable item as the data source.
    ///
    /// Use this method when you want to present a popover based on an optional
    /// identifiable value. The popover is presented when the item is non-nil and
    /// dismissed when it becomes nil. The item is passed to the content closure,
    /// allowing you to build popover content based on the data.
    ///
    /// ## Basic Usage
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
    ///             UserDetailPopover(user: user)
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// ## Custom Positioning
    ///
    /// ```swift
    /// .popover(
    ///     item: $selectedItem,
    ///     attachmentAnchor: .point(.center),
    ///     arrowEdge: .bottom
    /// ) { item in
    ///     ItemDetailView(item: item)
    /// }
    /// ```
    ///
    /// ## Item Changes
    ///
    /// If the item changes while the popover is already presented (the ID changes
    /// but the item remains non-nil), the popover content will be updated with
    /// the new item:
    ///
    /// ```swift
    /// // Tapping different items updates the popover content
    /// .popover(item: $currentItem) { item in
    ///     DetailView(for: item)
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - item: A binding to an optional identifiable item that controls presentation
    ///   - attachmentAnchor: The attachment point for the popover (default: `.rect(.bounds)`)
    ///   - arrowEdge: The preferred edge for the popover arrow (default: `.top`)
    ///   - onDismiss: Optional closure executed when the popover is dismissed
    ///   - content: A closure that takes the item and returns the popover content
    ///
    /// - Returns: A view that presents a popover when the item is non-nil
    @MainActor
    public func popover<Item: Identifiable & Sendable, Content: View>(
        item: Binding<Item?>,
        attachmentAnchor: PopoverAttachmentAnchor = .default,
        arrowEdge: Edge = .top,
        onDismiss: (@MainActor @Sendable () -> Void)? = nil,
        @ViewBuilder content: @escaping @MainActor @Sendable (Item) -> Content
    ) -> some View where Item.ID: Sendable {
        modifier(
            PopoverItemModifier(
                item: item,
                attachmentAnchor: attachmentAnchor,
                arrowEdge: arrowEdge,
                onDismiss: onDismiss,
                content: content
            )
        )
    }
}

// MARK: - Documentation Examples

/// Example: Basic popover with dismiss action
///
/// ```swift
/// struct InfoButton: View {
///     @State private var showInfo = false
///
///     var body: some View {
///         Button("i", systemImage: "info.circle") {
///             showInfo = true
///         }
///         .popover(isPresented: $showInfo) {
///             VStack(alignment: .leading, spacing: 12) {
///                 Text("Information")
///                     .font(.headline)
///
///                 Text("This feature helps you understand the content.")
///                     .font(.body)
///
///                 Button("Got it") {
///                     showInfo = false
///                 }
///                 .buttonStyle(.bordered)
///             }
///             .padding()
///         }
///     }
/// }
/// ```

/// Example: Popover with custom anchor point
///
/// ```swift
/// struct ColorPicker: View {
///     @State private var showPicker = false
///     @State private var selectedColor = Color.blue
///
///     var body: some View {
///         Circle()
///             .fill(selectedColor)
///             .frame(width: 50, height: 50)
///             .onTapGesture {
///                 showPicker = true
///             }
///             .popover(
///                 isPresented: $showPicker,
///                 attachmentAnchor: .point(.center),
///                 arrowEdge: .bottom
///             ) {
///                 ColorPickerView(selectedColor: $selectedColor)
///             }
///     }
/// }
/// ```

/// Example: Item-based popover with data
///
/// ```swift
/// struct DocumentList: View {
///     @State private var documents: [Document] = []
///     @State private var selectedDocument: Document?
///
///     var body: some View {
///         List(documents) { document in
///             Button(document.name) {
///                 selectedDocument = document
///             }
///         }
///         .popover(item: $selectedDocument) { document in
///             VStack(alignment: .leading, spacing: 16) {
///                 Text(document.name)
///                     .font(.headline)
///
///                 Text("Created: \(document.createdDate)")
///                     .font(.caption)
///
///                 Text(document.description)
///
///                 HStack {
///                     Button("Edit") {
///                         // Edit document
///                         selectedDocument = nil
///                     }
///
///                     Button("Close") {
///                         selectedDocument = nil
///                     }
///                 }
///             }
///             .padding()
///         }
///     }
/// }
/// ```

/// Example: Popover with different arrow edges
///
/// ```swift
/// struct EdgeDemo: View {
///     @State private var edge: Edge = .top
///     @State private var showPopover = false
///
///     var body: some View {
///         VStack(spacing: 20) {
///             Picker("Arrow Edge", selection: $edge) {
///                 Text("Top").tag(Edge.top)
///                 Text("Bottom").tag(Edge.bottom)
///                 Text("Leading").tag(Edge.leading)
///                 Text("Trailing").tag(Edge.trailing)
///             }
///
///             Button("Show Popover") {
///                 showPopover = true
///             }
///             .popover(
///                 isPresented: $showPopover,
///                 arrowEdge: edge
///             ) {
///                 Text("Arrow points from \(edge.rawValue)")
///                     .padding()
///             }
///         }
///     }
/// }
/// ```
