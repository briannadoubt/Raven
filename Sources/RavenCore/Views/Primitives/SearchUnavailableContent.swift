import Foundation

/// A preconfigured empty state for unsuccessful search results.
///
/// `SearchUnavailableContent` mirrors SwiftUI's dedicated search-empty-state
/// component and composes into `ContentUnavailableView` for rendering.
@MainActor
public struct SearchUnavailableContent: View, Sendable {
    private let searchText: String?
    private let descriptionText: String?
    private let actions: AnyView?

    /// Creates a search-unavailable view with the default title/description.
    ///
    /// - Parameter text: The user's search query, used to tailor messaging.
    public init(text: String? = nil) {
        self.searchText = text?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.descriptionText = nil
        self.actions = nil
    }

    /// Creates a search-unavailable view with custom description and actions.
    ///
    /// - Parameters:
    ///   - text: The user's search query, used to tailor messaging.
    ///   - description: Additional context shown below the title.
    ///   - actions: Suggested actions to recover from the empty state.
    public init<Actions: View>(
        text: String? = nil,
        description: Description? = nil,
        @ViewBuilder actions: () -> Actions
    ) {
        self.searchText = text?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.descriptionText = description?.value
        self.actions = AnyView(actions())
    }

    public var body: some View {
        ContentUnavailableView(
            titleText,
            systemImage: "magnifyingglass",
            description: Text(fullDescription)
        ) {
            if let actions {
                actions
            }
        }
    }

    private var titleText: String {
        if let searchText, !searchText.isEmpty {
            return "No Results for \"\(searchText)\""
        }
        return "No Results"
    }

    private var fullDescription: String {
        if let descriptionText, !descriptionText.isEmpty {
            return descriptionText
        }
        return "Try a different search term."
    }
}

extension SearchUnavailableContent {
    /// Description content for `SearchUnavailableContent`.
    public struct Description: Sendable {
        fileprivate let value: String

        public init(_ text: String) {
            self.value = text
        }

        public init(_ key: LocalizedStringKey) {
            self.value = key.stringValue
        }
    }

    /// Action content for `SearchUnavailableContent`.
    public struct Actions<Content: View>: View, Sendable {
        private let content: Content

        public init(@ViewBuilder _ content: () -> Content) {
            self.content = content()
        }

        public var body: some View {
            content
        }
    }
}
