import Foundation

/// A view that displays a standardized empty state interface.
///
/// `ContentUnavailableView` is a composed view that shows a centered message when
/// content is unavailable, such as empty search results or missing data. It displays
/// an icon, title, optional description, and optional actions in a consistent layout.
///
/// ## Overview
///
/// Use `ContentUnavailableView` to provide a polished empty state experience. It
/// combines an icon, title, description, and actions into a centered vertical layout
/// that follows platform conventions for empty state UI.
///
/// This view is available in iOS 17+ and provides a consistent way to handle various
/// empty states across your application.
///
/// ## Basic Usage
///
/// Create a simple empty state with icon and message:
///
/// ```swift
/// ContentUnavailableView(
///     "No Messages",
///     systemImage: "envelope.open",
///     description: Text("You don't have any messages yet.")
/// )
/// ```
///
/// ## Search Variant
///
/// Use the search variant for empty search results:
///
/// ```swift
/// if searchResults.isEmpty {
///     ContentUnavailableView.search
/// }
/// ```
///
/// ## With Actions
///
/// Add action buttons to help users resolve the empty state:
///
/// ```swift
/// ContentUnavailableView(
///     "No Messages",
///     systemImage: "envelope.open",
///     description: Text("Get started by sending a message.")
/// ) {
///     Button("Compose Message") {
///         showComposer = true
///     }
/// }
/// ```
///
/// ## Common Patterns
///
/// **Empty list:**
/// ```swift
/// struct ItemListView: View {
///     let items: [Item]
///
///     var body: some View {
///         if items.isEmpty {
///             ContentUnavailableView(
///                 "No Items",
///                 systemImage: "tray",
///                 description: Text("Add your first item to get started.")
///             ) {
///                 Button("Add Item") {
///                     addNewItem()
///                 }
///             }
///         } else {
///             List(items) { item in
///                 ItemRow(item: item)
///             }
///         }
///     }
/// }
/// ```
///
/// **Empty search:**
/// ```swift
/// struct SearchView: View {
///     @State private var query = ""
///     var results: [Result]
///
///     var body: some View {
///         if results.isEmpty && !query.isEmpty {
///             ContentUnavailableView.search
///         } else {
///             List(results) { result in
///                 ResultRow(result: result)
///             }
///         }
///     }
/// }
/// ```
///
/// **No data loaded:**
/// ```swift
/// ContentUnavailableView(
///     "Connection Lost",
///     systemImage: "wifi.slash",
///     description: Text("Unable to connect to the server.")
/// ) {
///     Button("Retry") {
///         retryConnection()
///     }
/// }
/// ```
///
/// **Permission required:**
/// ```swift
/// ContentUnavailableView(
///     "Photos Access Required",
///     systemImage: "photo.badge.exclamationmark",
///     description: Text("Allow access to your photos to continue.")
/// ) {
///     Button("Open Settings") {
///         openSettings()
///     }
/// }
/// ```
///
/// ## Layout Behavior
///
/// `ContentUnavailableView` centers its content both horizontally and vertically:
/// - Icon is displayed at the top with generous spacing
/// - Title appears below the icon in a prominent font
/// - Description provides additional context in a secondary font
/// - Actions are displayed at the bottom with appropriate spacing
///
/// ## Styling
///
/// The view uses system styling for consistent appearance:
/// - Icon: System image with large size
/// - Title: Large title font with primary color
/// - Description: Body font with secondary color
/// - Actions: Standard button styling
///
/// ## Web Rendering
///
/// In the web environment, `ContentUnavailableView` renders as a centered div
/// container with semantic HTML structure and appropriate CSS classes for styling.
///
/// ## See Also
///
/// - ``VStack``
/// - ``Text``
/// - ``Image``
/// - ``Button``
///
/// Because `ContentUnavailableView` is a composed view (Body != Never), it defines
/// its layout through its `body` property rather than converting directly to a VNode.
public struct ContentUnavailableView<Description: View, Actions: View>: View, Sendable {
    /// The title text to display
    private let title: String

    /// The system image name to display as an icon
    private let systemImage: String

    /// Optional description content
    private let description: Description?

    /// Optional actions content
    private let actions: Actions?

    // MARK: - Initializers

    /// Creates a content unavailable view with all components.
    ///
    /// Use this initializer when you need full control over all components of the
    /// empty state, including custom actions.
    ///
    /// - Parameters:
    ///   - title: The title text to display.
    ///   - systemImage: The name of the system image to display as an icon.
    ///   - description: A view builder that creates the description content.
    ///   - actions: A view builder that creates the action buttons.
    ///
    /// ## Example
    ///
    /// ```swift
    /// ContentUnavailableView(
    ///     "No Messages",
    ///     systemImage: "envelope.open",
    ///     description: {
    ///         Text("You don't have any messages yet.")
    ///     },
    ///     actions: {
    ///         Button("Compose Message") {
    ///             showComposer = true
    ///         }
    ///     }
    /// )
    /// ```
    @MainActor public init(
        _ title: String,
        systemImage: String,
        @ViewBuilder description: () -> Description,
        @ViewBuilder actions: () -> Actions
    ) {
        self.title = title
        self.systemImage = systemImage
        self.description = description()
        self.actions = actions()
    }

    // MARK: - Body

    /// The content and behavior of the content unavailable view.
    ///
    /// The view arranges its components in a centered vertical stack with
    /// appropriate spacing and styling for each component.
    @ViewBuilder @MainActor public var body: some View {
        VStack(spacing: 16) {
            // Icon at the top
            Image(systemName: systemImage)

            // Title
            Text(title)

            // Optional description
            if let description = description {
                description
            }

            // Optional actions
            if let actions = actions {
                actions
            }
        }
    }
}

// MARK: - No Actions Variant

extension ContentUnavailableView where Actions == EmptyView {
    /// Creates a content unavailable view with a description but no actions.
    ///
    /// Use this initializer for empty states that don't require user action.
    ///
    /// - Parameters:
    ///   - title: The title text to display.
    ///   - systemImage: The name of the system image to display as an icon.
    ///   - description: A view builder that creates the description content.
    ///
    /// ## Example
    ///
    /// ```swift
    /// ContentUnavailableView(
    ///     "No Messages",
    ///     systemImage: "envelope.open",
    ///     description: {
    ///         Text("You don't have any messages yet.")
    ///     }
    /// )
    /// ```
    @MainActor public init(
        _ title: String,
        systemImage: String,
        @ViewBuilder description: () -> Description
    ) {
        self.title = title
        self.systemImage = systemImage
        self.description = description()
        self.actions = nil
    }
}

// MARK: - Text Description Variants

extension ContentUnavailableView where Description == Text {
    /// Creates a content unavailable view with a text description and actions.
    ///
    /// This is a convenience initializer for the common case of a simple text
    /// description with action buttons.
    ///
    /// - Parameters:
    ///   - title: The title text to display.
    ///   - systemImage: The name of the system image to display as an icon.
    ///   - description: The description text to display.
    ///   - actions: A view builder that creates the action buttons.
    ///
    /// ## Example
    ///
    /// ```swift
    /// ContentUnavailableView(
    ///     "No Messages",
    ///     systemImage: "envelope.open",
    ///     description: Text("Get started by sending a message.")
    /// ) {
    ///     Button("Compose Message") {
    ///         showComposer = true
    ///     }
    /// }
    /// ```
    @MainActor public init(
        _ title: String,
        systemImage: String,
        description: Description,
        @ViewBuilder actions: () -> Actions
    ) {
        self.title = title
        self.systemImage = systemImage
        self.description = description
        self.actions = actions()
    }
}

extension ContentUnavailableView where Description == Text, Actions == EmptyView {
    /// Creates a content unavailable view with a text description and no actions.
    ///
    /// This is a convenience initializer for simple empty states with just a
    /// title, icon, and description.
    ///
    /// - Parameters:
    ///   - title: The title text to display.
    ///   - systemImage: The name of the system image to display as an icon.
    ///   - description: The description text to display.
    ///
    /// ## Example
    ///
    /// ```swift
    /// ContentUnavailableView(
    ///     "No Messages",
    ///     systemImage: "envelope.open",
    ///     description: Text("You don't have any messages yet.")
    /// )
    /// ```
    @MainActor public init(
        _ title: String,
        systemImage: String,
        description: Description
    ) {
        self.title = title
        self.systemImage = systemImage
        self.description = description
        self.actions = nil
    }
}


extension ContentUnavailableView where Description == EmptyView, Actions == EmptyView {
    /// Creates a minimal content unavailable view with just a title and icon.
    ///
    /// Use this initializer for the simplest empty states where the title and
    /// icon are sufficient.
    ///
    /// - Parameters:
    ///   - title: The title text to display.
    ///   - systemImage: The name of the system image to display as an icon.
    ///
    /// ## Example
    ///
    /// ```swift
    /// ContentUnavailableView(
    ///     "No Messages",
    ///     systemImage: "envelope.open"
    /// )
    /// ```
    @MainActor public init(
        _ title: String,
        systemImage: String
    ) {
        self.title = title
        self.systemImage = systemImage
        self.description = nil
        self.actions = nil
    }
}

// MARK: - Search Variant

extension ContentUnavailableView where Description == Text, Actions == EmptyView {
    /// A standard empty state for search results.
    ///
    /// Use this static property to show a consistent empty state when search
    /// results are empty. It displays a search icon with a standard message.
    ///
    /// ## Example
    ///
    /// ```swift
    /// struct SearchView: View {
    ///     @State private var query = ""
    ///     var results: [Result]
    ///
    ///     var body: some View {
    ///         if results.isEmpty && !query.isEmpty {
    ///             ContentUnavailableView.search
    ///         } else {
    ///             List(results) { result in
    ///                 ResultRow(result: result)
    ///             }
    ///         }
    ///     }
    /// }
    /// ```
    @MainActor public static var search: ContentUnavailableView<Text, EmptyView> {
        ContentUnavailableView(
            "No Results",
            systemImage: "magnifyingglass",
            description: Text("Try a different search term.")
        )
    }
}

