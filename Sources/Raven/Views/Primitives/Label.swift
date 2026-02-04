import Foundation

/// A view that displays an icon and text label in a standard layout.
///
/// `Label` is a composed view that combines an icon and text into a horizontal
/// layout. It's commonly used for buttons, list items, and menu items where you
/// need to display both visual and textual information together.
///
/// ## Overview
///
/// `Label` provides a consistent way to display icon-text combinations across
/// your application. It uses an `HStack` internally to arrange the icon and
/// title horizontally with appropriate spacing.
///
/// ## Basic Usage
///
/// Create a label with custom views for both icon and title:
///
/// ```swift
/// Label {
///     Text("Welcome")
/// } icon: {
///     Image(systemName: "star.fill")
/// }
/// ```
///
/// ## Convenience Initializer
///
/// For simple text and system image combinations, use the string-based initializer:
///
/// ```swift
/// Label("Favorites", systemImage: "star.fill")
/// Label("Settings", systemImage: "gear")
/// Label("Profile", systemImage: "person.circle")
/// ```
///
/// ## Custom Content
///
/// Use ViewBuilder to create complex icon and title content:
///
/// ```swift
/// Label {
///     VStack(alignment: .leading) {
///         Text("John Doe")
///             .font(.headline)
///         Text("Online")
///             .font(.caption)
///             .foregroundColor(.green)
///     }
/// } icon: {
///     Image("avatar")
///         .frame(width: 40, height: 40)
///         .clipShape(Circle())
/// }
/// ```
///
/// ## Common Patterns
///
/// **Button labels:**
/// ```swift
/// Button {
///     save()
/// } label: {
///     Label("Save", systemImage: "square.and.arrow.down")
/// }
/// ```
///
/// **List items:**
/// ```swift
/// List {
///     Label("Documents", systemImage: "folder")
///     Label("Downloads", systemImage: "arrow.down.circle")
///     Label("Trash", systemImage: "trash")
/// }
/// ```
///
/// **Navigation items:**
/// ```swift
/// NavigationLink(destination: SettingsView()) {
///     Label("Settings", systemImage: "gear")
/// }
/// ```
///
/// **Status indicators:**
/// ```swift
/// Label {
///     Text(status.message)
/// } icon: {
///     Image(systemName: status.iconName)
///         .foregroundColor(status.color)
/// }
/// ```
///
/// ## Styling
///
/// Apply modifiers to customize the entire label:
///
/// ```swift
/// Label("Important", systemImage: "exclamationmark.triangle")
///     .font(.title)
///     .foregroundColor(.red)
///     .padding()
/// ```
///
/// Or style individual components:
///
/// ```swift
/// Label {
///     Text("Featured")
///         .font(.headline)
/// } icon: {
///     Image(systemName: "star.fill")
///         .foregroundColor(.yellow)
/// }
/// ```
///
/// ## Layout Behavior
///
/// `Label` uses `HStack` with default spacing to arrange its content:
/// - Icon appears on the left (leading edge)
/// - Title appears on the right (trailing edge)
/// - Content is vertically centered by default
///
/// ## System Images Note
///
/// In the web environment, SF Symbols are not available. The convenience
/// initializer with `systemImage` will render the icon name as text as a
/// placeholder. For production use, consider providing custom icon images
/// or web-compatible icon fonts.
///
/// ## See Also
///
/// - ``HStack``
/// - ``Text``
/// - ``Image``
/// - ``Button``
///
/// Because `Label` is a composed view (Body != Never), it defines its layout
/// through its `body` property rather than converting directly to a VNode.
public struct Label<Title: View, Icon: View>: View, Sendable {
    /// The title content of the label
    private let title: Title

    /// The icon content of the label
    private let icon: Icon

    // MARK: - Initializers

    /// Creates a label with custom title and icon views.
    ///
    /// Use this initializer when you need full control over the label's content,
    /// using ViewBuilder to create complex or styled views.
    ///
    /// - Parameters:
    ///   - title: A view builder that creates the label's title content.
    ///   - icon: A view builder that creates the label's icon content.
    ///
    /// ## Example
    ///
    /// ```swift
    /// Label {
    ///     VStack(alignment: .leading) {
    ///         Text("Main Title")
    ///             .font(.headline)
    ///         Text("Subtitle")
    ///             .font(.caption)
    ///     }
    /// } icon: {
    ///     Image("custom-icon")
    ///         .resizable()
    ///         .frame(width: 24, height: 24)
    /// }
    /// ```
    @MainActor public init(
        @ViewBuilder title: () -> Title,
        @ViewBuilder icon: () -> Icon
    ) {
        self.title = title()
        self.icon = icon()
    }

    // MARK: - Body

    /// The content and behavior of the label.
    ///
    /// The label arranges its icon and title horizontally using an `HStack`
    /// with default spacing for a clean, consistent appearance.
    @ViewBuilder @MainActor public var body: some View {
        HStack(spacing: 8) {
            icon
            title
        }
    }
}

// MARK: - String Convenience

extension Label where Title == Text, Icon == Text {
    /// Creates a label with a string title and system image name.
    ///
    /// This is a convenience initializer for creating simple labels with
    /// text and system image references. Since SF Symbols are not available
    /// in the web environment, the system image name is rendered as text.
    ///
    /// - Parameters:
    ///   - title: The string to display as the label's title.
    ///   - systemImage: The name of the system image (rendered as text placeholder).
    ///
    /// ## Example
    ///
    /// ```swift
    /// Label("Favorites", systemImage: "star.fill")
    /// Label("Settings", systemImage: "gear")
    /// ```
    ///
    /// - Note: In a web environment, SF Symbols are not available. The system
    ///   image name will be displayed as text. For production applications,
    ///   consider using custom images or web icon fonts instead.
    @MainActor public init(_ title: String, systemImage: String) {
        self.title = Text(title)
        // For now, render the system image name as text since we don't have
        // SF Symbols on web. In the future, this could be replaced with an
        // icon font or custom image mapping.
        self.icon = Text(systemImage)
    }

    /// Creates a label with a localized string title and system image name.
    ///
    /// Use this initializer for labels that should be localized.
    ///
    /// - Parameters:
    ///   - titleKey: The localized string key for the label's title.
    ///   - systemImage: The name of the system image (rendered as text placeholder).
    ///
    /// ## Example
    ///
    /// ```swift
    /// Label("settings_label", systemImage: "gear")
    /// ```
    @MainActor public init(_ titleKey: LocalizedStringKey, systemImage: String) {
        self.title = Text(titleKey)
        self.icon = Text(systemImage)
    }
}
