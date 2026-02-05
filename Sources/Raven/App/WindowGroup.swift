import Foundation

/// A scene that presents a group of identically structured windows.
///
/// In a web context, a `WindowGroup` maps to the root DOM element. For Raven apps,
/// the first `WindowGroup` in the scene hierarchy becomes the main application view.
///
/// Example:
/// ```swift
/// @main
/// struct MyApp: App {
///     var body: some Scene {
///         WindowGroup {
///             ContentView()
///         }
///     }
/// }
/// ```
public struct WindowGroup<Content: View>: Scene {
    public typealias Body = _EmptyScene

    /// The unique identifier for this window group.
    let id: String

    /// Optional title for the window group.
    let title: String?

    /// The content closure that creates the root view.
    public let content: @Sendable () -> Content

    /// Creates a window group with an identifier and content.
    ///
    /// - Parameters:
    ///   - id: A unique identifier for this window group.
    ///   - content: A closure that creates the root view for windows in this group.
    public init(id: String = "main", @ViewBuilder content: @escaping @Sendable () -> Content) {
        self.id = id
        self.title = nil
        self.content = content
    }

    /// Creates a window group with a title, identifier, and content.
    ///
    /// - Parameters:
    ///   - title: The title for windows in this group.
    ///   - id: A unique identifier for this window group.
    ///   - content: A closure that creates the root view for windows in this group.
    public init(_ title: String, id: String = "main", @ViewBuilder content: @escaping @Sendable () -> Content) {
        self.id = id
        self.title = title
        self.content = content
    }

    /// Creates a window group with a localized title, identifier, and content.
    ///
    /// - Parameters:
    ///   - title: A localized string key for the window title.
    ///   - id: A unique identifier for this window group.
    ///   - content: A closure that creates the root view for windows in this group.
    public init(_ title: LocalizedStringKey, id: String = "main", @ViewBuilder content: @escaping @Sendable () -> Content) {
        self.id = id
        self.title = title.stringValue // Store the key as the title
        self.content = content
    }
}

