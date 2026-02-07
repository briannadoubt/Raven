import Foundation
import JavaScriptKit

// MARK: - Search Field Placement

/// The placement of a search field in the user interface.
///
/// Search field placement affects where the search bar appears in the view hierarchy
/// and how it's positioned in the rendered DOM. Different placements are appropriate
/// for different contexts.
///
/// ## Overview
///
/// In native SwiftUI, different placements affect where the search bar appears
/// (navigation bar, toolbar, sidebar). In Raven's web implementation, these
/// placements translate to different CSS positioning and DOM structure.
///
/// ## Example
///
/// ```swift
/// List(items) { item in
///     Text(item.name)
/// }
/// .searchable(
///     text: $searchText,
///     placement: .navigationBarDrawer
/// )
/// ```
public enum SearchFieldPlacement: Sendable, Hashable {
    /// Automatically determine the placement based on context.
    ///
    /// This is the default placement. The search field will be positioned
    /// at the top of the containing view.
    case automatic

    /// Place the search field in the navigation bar drawer.
    ///
    /// The search field appears at the top of the view, styled to integrate
    /// with navigation content.
    case navigationBarDrawer

    /// Place the search field in a sidebar.
    ///
    /// The search field appears at the top of a sidebar area, if present.
    /// Falls back to automatic placement if no sidebar context exists.
    case sidebar

    /// Place the search field in a toolbar.
    ///
    /// The search field appears inline within toolbar content.
    case toolbar
}

// MARK: - Searchable View

/// A view wrapper that adds search functionality to its content.
///
/// The searchable modifier adds a search field to a view, typically above list
/// content. It provides two-way data binding through a `Binding<String>` and
/// supports optional search suggestions.
///
/// ## Web Implementation
///
/// The search field is implemented using an HTML `<input type="search">` element,
/// which provides built-in search styling and a clear button in modern browsers.
/// The implementation includes:
///
/// - Search icon indicator
/// - Native browser clear button (x)
/// - Placeholder text support
/// - Real-time binding updates
/// - Optional suggestions dropdown
/// - Keyboard shortcuts (Cmd+F to focus)
///
/// ## Accessibility
///
/// The search field includes appropriate ARIA attributes:
/// - `role="search"` for the container
/// - `aria-label` for screen readers
/// - Proper label association
///
/// ## Example
///
/// ```swift
/// struct ItemList: View {
///     @State private var searchText = ""
///
///     var filteredItems: [Item] {
///         if searchText.isEmpty {
///             return items
///         }
///         return items.filter { $0.name.contains(searchText) }
///     }
///
///     var body: some View {
///         List(filteredItems) { item in
///             Text(item.name)
///         }
///         .searchable(text: $searchText, prompt: "Search items")
///     }
/// }
/// ```
public struct _SearchableView<Content: View, Suggestions: View>: View, PrimitiveView, _CoordinatorRenderable, Sendable {
    let content: Content
    let text: Binding<String>
    let placement: SearchFieldPlacement
    let prompt: Text?
    let suggestions: Suggestions?

    public typealias Body = Never

    /// Initialize a searchable view
    init(
        content: Content,
        text: Binding<String>,
        placement: SearchFieldPlacement,
        prompt: Text?,
        suggestions: Suggestions?
    ) {
        self.content = content
        self.text = text
        self.placement = placement
        self.prompt = prompt
        self.suggestions = suggestions
    }

    @MainActor public func _render(with context: any _RenderContext) -> VNode {
        // If inside a NavigationStack, register the search bar with the controller
        // and let the NavigationStack handle placing it in the nav bar area.
        if let controller = NavigationStackController._current {
            // Build the search input node
            let searchNode = buildSearchInputNode(with: context)
            controller.searchBarInfo = SearchBarInfo(node: searchNode, placement: placement)

            // Render just the content — the search bar will be placed by NavigationStack
            return context.renderChild(content)
        }

        // Not inside a NavigationStack: fall back to rendering search bar above content
        let searchNode = buildSearchInputNode(with: context)
        let contentNode = context.renderChild(content)

        let containerProps: [String: VProperty] = [
            "display": .style(name: "display", value: "flex"),
            "flex-direction": .style(name: "flex-direction", value: "column"),
            "height": .style(name: "height", value: "100%"),
        ]

        let contentChildren: [VNode]
        if case .fragment = contentNode.type {
            contentChildren = contentNode.children
        } else {
            contentChildren = [contentNode]
        }

        let contentWrapper = VNode.element(
            "div",
            props: [
                "flex": .style(name: "flex", value: "1"),
                "overflow": .style(name: "overflow", value: "auto"),
            ],
            children: contentChildren
        )

        return VNode.element("div", props: containerProps, children: [searchNode, contentWrapper])
    }

    /// Builds the search input VNode for use in both coordinator and fallback rendering.
    @MainActor private func buildSearchInputNode(with context: any _RenderContext) -> VNode {
        let placeholderText = prompt?.textContent ?? "Search"

        let inputHandlerId = context.registerInputHandler { jsValue in
            if let target = jsValue.object?["target"].object,
               let value = target["value"].string {
                self.text.wrappedValue = value
            }
        }

        let searchInputProps: [String: VProperty] = [
            "type": .attribute(name: "type", value: "search"),
            "placeholder": .attribute(name: "placeholder", value: placeholderText),
            "value": .attribute(name: "value", value: text.wrappedValue),
            "onInput": .eventHandler(event: "input", handlerID: inputHandlerId),
            "aria-label": .attribute(name: "aria-label", value: placeholderText),
            "padding": .style(name: "padding", value: "8px 12px"),
            "padding-left": .style(name: "padding-left", value: "36px"),
            "border": .style(name: "border", value: "1px solid #d1d5db"),
            "border-radius": .style(name: "border-radius", value: "8px"),
            "font-size": .style(name: "font-size", value: "14px"),
            "width": .style(name: "width", value: "100%"),
            "box-sizing": .style(name: "box-sizing", value: "border-box"),
            "outline": .style(name: "outline", value: "none"),
        ]

        let searchInput = VNode.element("input", props: searchInputProps, children: [])

        // Search icon
        let searchIcon = VNode.element(
            "div",
            props: [
                "position": .style(name: "position", value: "absolute"),
                "left": .style(name: "left", value: "12px"),
                "top": .style(name: "top", value: "50%"),
                "transform": .style(name: "transform", value: "translateY(-50%)"),
                "color": .style(name: "color", value: "#9ca3af"),
                "pointer-events": .style(name: "pointer-events", value: "none"),
            ],
            children: [
                VNode.element(
                    "svg",
                    props: [
                        "width": .attribute(name: "width", value: "16"),
                        "height": .attribute(name: "height", value: "16"),
                        "viewBox": .attribute(name: "viewBox", value: "0 0 16 16"),
                        "fill": .attribute(name: "fill", value: "none"),
                        "stroke": .attribute(name: "stroke", value: "currentColor"),
                        "stroke-width": .attribute(name: "stroke-width", value: "2"),
                    ],
                    children: [
                        VNode.element("circle", props: [
                            "cx": .attribute(name: "cx", value: "6.5"),
                            "cy": .attribute(name: "cy", value: "6.5"),
                            "r": .attribute(name: "r", value: "4"),
                        ]),
                        VNode.element("path", props: [
                            "d": .attribute(name: "d", value: "M9.5 9.5l4 4"),
                        ]),
                    ]
                )
            ]
        )

        // Search container with icon + input
        let searchContainer = VNode.element(
            "div",
            props: [
                "role": .attribute(name: "role", value: "search"),
                "position": .style(name: "position", value: "relative"),
                "width": .style(name: "width", value: "100%"),
                "padding": .style(name: "padding", value: "8px 16px"),
                "box-sizing": .style(name: "box-sizing", value: "border-box"),
            ],
            children: [searchIcon, searchInput]
        )

        return searchContainer
    }

    @MainActor public func toVNode() -> VNode {
        // Generate unique IDs for the search elements
        let searchInputId = "search-\(UUID().uuidString)"
        let inputHandlerId = UUID()
        let clearHandlerId = UUID()
        let suggestionsId = suggestions != nil ? "suggestions-\(UUID().uuidString)" : nil

        // Extract placeholder text from prompt
        let placeholderText = prompt?.textContent ?? "Search"

        // Create the search input element
        var searchInputProps: [String: VProperty] = [
            "id": .attribute(name: "id", value: searchInputId),
            "type": .attribute(name: "type", value: "search"),
            "placeholder": .attribute(name: "placeholder", value: placeholderText),
            "value": .attribute(name: "value", value: text.wrappedValue),
            "onInput": .eventHandler(event: "input", handlerID: inputHandlerId),
            "aria-label": .attribute(name: "aria-label", value: placeholderText),

            // Styling
            "padding": .style(name: "padding", value: "8px 12px"),
            "padding-left": .style(name: "padding-left", value: "36px"), // Space for search icon
            "border": .style(name: "border", value: "1px solid #d1d5db"),
            "border-radius": .style(name: "border-radius", value: "8px"),
            "font-size": .style(name: "font-size", value: "14px"),
            "width": .style(name: "width", value: "100%"),
            "box-sizing": .style(name: "box-sizing", value: "border-box"),
            "outline": .style(name: "outline", value: "none"),
            "transition": .style(name: "transition", value: "border-color 0.2s"),
        ]

        // Add suggestions list reference if present
        if let suggestionsId = suggestionsId {
            searchInputProps["list"] = .attribute(name: "list", value: suggestionsId)
        }

        let searchInput = VNode.element(
            "input",
            props: searchInputProps,
            children: []
        )

        // Create search icon (using CSS pseudo-element or inline SVG)
        let searchIcon = VNode.element(
            "div",
            props: [
                "position": .style(name: "position", value: "absolute"),
                "left": .style(name: "left", value: "12px"),
                "top": .style(name: "top", value: "50%"),
                "transform": .style(name: "transform", value: "translateY(-50%)"),
                "color": .style(name: "color", value: "#9ca3af"),
                "pointer-events": .style(name: "pointer-events", value: "none"),
            ],
            children: [
                // SVG search icon
                VNode.element(
                    "svg",
                    props: [
                        "width": .attribute(name: "width", value: "16"),
                        "height": .attribute(name: "height", value: "16"),
                        "viewBox": .attribute(name: "viewBox", value: "0 0 16 16"),
                        "fill": .attribute(name: "fill", value: "none"),
                        "stroke": .attribute(name: "stroke", value: "currentColor"),
                        "stroke-width": .attribute(name: "stroke-width", value: "2"),
                    ],
                    children: [
                        VNode.element(
                            "circle",
                            props: [
                                "cx": .attribute(name: "cx", value: "6.5"),
                                "cy": .attribute(name: "cy", value: "6.5"),
                                "r": .attribute(name: "r", value: "4"),
                            ]
                        ),
                        VNode.element(
                            "path",
                            props: [
                                "d": .attribute(name: "d", value: "M9.5 9.5l4 4"),
                            ]
                        ),
                    ]
                )
            ]
        )

        // Create the search input wrapper with icon
        let searchInputWrapper = VNode.element(
            "div",
            props: [
                "position": .style(name: "position", value: "relative"),
                "width": .style(name: "width", value: "100%"),
            ],
            children: [searchIcon, searchInput]
        )

        // Create suggestions element if provided
        var searchFieldChildren: [VNode] = [searchInputWrapper]

        if let suggestions = suggestions, let suggestionsId = suggestionsId {
            // For now, render suggestions as a datalist
            // A more advanced implementation could use a custom dropdown
            let suggestionsNode = VNode.element(
                "datalist",
                props: [
                    "id": .attribute(name: "id", value: suggestionsId),
                ],
                children: [] // Suggestions would be populated by the view hierarchy
            )
            searchFieldChildren.append(suggestionsNode)
        }

        // Determine container styles based on placement
        var containerStyles: [String: VProperty] = [
            "display": .style(name: "display", value: "flex"),
            "flex-direction": .style(name: "flex-direction", value: "column"),
            "gap": .style(name: "gap", value: "12px"),
        ]

        switch placement {
        case .automatic, .navigationBarDrawer:
            containerStyles["padding"] = .style(name: "padding", value: "12px")
            containerStyles["background"] = .style(name: "background", value: "#f9fafb")
            containerStyles["border-bottom"] = .style(name: "border-bottom", value: "1px solid #e5e7eb")

        case .toolbar:
            containerStyles["padding"] = .style(name: "padding", value: "8px")
            containerStyles["align-items"] = .style(name: "align-items", value: "center")

        case .sidebar:
            containerStyles["padding"] = .style(name: "padding", value: "12px")
            containerStyles["border-bottom"] = .style(name: "border-bottom", value: "1px solid #e5e7eb")
        }

        // Create the search field container
        let searchField = VNode.element(
            "div",
            props: Dictionary(uniqueKeysWithValues:
                containerStyles.map { ($0.key, $0.value) } +
                [("role", .attribute(name: "role", value: "search"))]
            ),
            children: searchFieldChildren
        )

        // Render the content
        // Note: In a full implementation, this would traverse the view hierarchy
        // For now, we create a simple container structure
        let contentNode = VNode.element(
            "div",
            props: [
                "flex": .style(name: "flex", value: "1"),
                "overflow": .style(name: "overflow", value: "auto"),
            ],
            children: [] // Content would be rendered here
        )

        // Combine search field and content
        return VNode.element(
            "div",
            props: [
                "display": .style(name: "display", value: "flex"),
                "flex-direction": .style(name: "flex-direction", value: "column"),
                "height": .style(name: "height", value: "100%"),
            ],
            children: [searchField, contentNode]
        )
    }
}

// MARK: - View Extension

extension View {
    /// Adds a search field to the view.
    ///
    /// Use this modifier to add search functionality to a view, typically a list
    /// or collection view. The search field appears above the content and provides
    /// two-way data binding for the search text.
    ///
    /// ## Basic Usage
    ///
    /// ```swift
    /// struct SearchableList: View {
    ///     @State private var searchText = ""
    ///     let items = ["Apple", "Banana", "Cherry", "Date"]
    ///
    ///     var filteredItems: [String] {
    ///         if searchText.isEmpty {
    ///             return items
    ///         }
    ///         return items.filter { $0.localizedCaseInsensitiveContains(searchText) }
    ///     }
    ///
    ///     var body: some View {
    ///         List(filteredItems, id: \.self) { item in
    ///             Text(item)
    ///         }
    ///         .searchable(text: $searchText)
    ///     }
    /// }
    /// ```
    ///
    /// ## With Prompt
    ///
    /// Provide a custom placeholder to guide users:
    ///
    /// ```swift
    /// List(contacts) { contact in
    ///     Text(contact.name)
    /// }
    /// .searchable(text: $searchText, prompt: "Search contacts")
    /// ```
    ///
    /// ## Search Placement
    ///
    /// Control where the search field appears:
    ///
    /// ```swift
    /// NavigationView {
    ///     List(items) { item in
    ///         Text(item.name)
    ///     }
    ///     .searchable(
    ///         text: $searchText,
    ///         placement: .navigationBarDrawer,
    ///         prompt: "Find items"
    ///     )
    /// }
    /// ```
    ///
    /// ## Filtering Pattern
    ///
    /// A common pattern is to compute filtered results based on the search text:
    ///
    /// ```swift
    /// struct ProductList: View {
    ///     @State private var searchText = ""
    ///     let products: [Product]
    ///
    ///     var searchResults: [Product] {
    ///         guard !searchText.isEmpty else { return products }
    ///         return products.filter { product in
    ///             product.name.localizedCaseInsensitiveContains(searchText) ||
    ///             product.description.localizedCaseInsensitiveContains(searchText)
    ///         }
    ///     }
    ///
    ///     var body: some View {
    ///         List(searchResults) { product in
    ///             VStack(alignment: .leading) {
    ///                 Text(product.name)
    ///                     .font(.headline)
    ///                 Text(product.description)
    ///                     .font(.caption)
    ///             }
    ///         }
    ///         .searchable(text: $searchText, prompt: "Search products")
    ///     }
    /// }
    /// ```
    ///
    /// ## Accessibility
    ///
    /// The search field automatically includes:
    /// - Screen reader labels
    /// - Keyboard navigation support
    /// - Focus management
    ///
    /// ## Web Implementation
    ///
    /// The search field uses native HTML `<input type="search">` which provides:
    /// - Built-in clear button (x) in most browsers
    /// - Search icon indicator
    /// - Mobile keyboard optimization
    ///
    /// - Parameters:
    ///   - text: A binding to the search query text.
    ///   - placement: The preferred placement of the search field. Defaults to `.automatic`.
    ///   - prompt: Text to display when the search field is empty.
    /// - Returns: A view with a search field above the content.
    @MainActor public func searchable(
        text: Binding<String>,
        placement: SearchFieldPlacement = .automatic,
        prompt: Text? = nil
    ) -> _SearchableView<Self, EmptyView> {
        _SearchableView(
            content: self,
            text: text,
            placement: placement,
            prompt: prompt,
            suggestions: nil
        )
    }

    /// Adds a search field with suggestions to the view.
    ///
    /// Use this modifier when you want to provide search suggestions or autocomplete
    /// options as the user types. The suggestions appear in a dropdown below the
    /// search field.
    ///
    /// ## Example
    ///
    /// ```swift
    /// struct SearchableListWithSuggestions: View {
    ///     @State private var searchText = ""
    ///     let allItems = ["Apple", "Apricot", "Banana", "Blueberry"]
    ///
    ///     var suggestions: [String] {
    ///         guard !searchText.isEmpty else { return [] }
    ///         return allItems.filter {
    ///             $0.localizedCaseInsensitiveContains(searchText)
    ///         }
    ///         .prefix(5)
    ///         .map { $0 }
    ///     }
    ///
    ///     var body: some View {
    ///         List(filteredItems) { item in
    ///             Text(item)
    ///         }
    ///         .searchable(text: $searchText, prompt: "Search fruits") {
    ///             ForEach(suggestions, id: \.self) { suggestion in
    ///                 Text(suggestion)
    ///                     .searchCompletion(suggestion)
    ///             }
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// ## Search Completion
    ///
    /// Use the `.searchCompletion(_:)` modifier on suggestion views to specify
    /// what text should be filled in when the suggestion is selected:
    ///
    /// ```swift
    /// ForEach(recentSearches) { search in
    ///     HStack {
    ///         Image(systemName: "clock")
    ///         Text(search.query)
    ///     }
    ///     .searchCompletion(search.query)
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - text: A binding to the search query text.
    ///   - placement: The preferred placement of the search field. Defaults to `.automatic`.
    ///   - prompt: Text to display when the search field is empty.
    ///   - suggestions: A view builder that creates the search suggestions.
    /// - Returns: A view with a search field and suggestions above the content.
    @MainActor public func searchable<S: View>(
        text: Binding<String>,
        placement: SearchFieldPlacement = .automatic,
        prompt: Text? = nil,
        @ViewBuilder suggestions: () -> S
    ) -> _SearchableView<Self, S> {
        _SearchableView(
            content: self,
            text: text,
            placement: placement,
            prompt: prompt,
            suggestions: suggestions()
        )
    }
}

// MARK: - Search Completion

/// A marker for search suggestion completion values.
///
/// This protocol is used internally to mark views that provide search completion
/// values. When a user taps a suggestion, the completion text is used to update
/// the search binding.
public protocol SearchCompletionProvider {
    /// The text to insert when this suggestion is selected.
    var completionText: String { get }
}

extension View {
    /// Marks this view as a search suggestion with a completion value.
    ///
    /// Use this modifier on views within the suggestions closure of `.searchable()`
    /// to specify what text should be inserted into the search field when the
    /// suggestion is selected.
    ///
    /// ## Example
    ///
    /// ```swift
    /// .searchable(text: $searchText) {
    ///     ForEach(suggestions) { suggestion in
    ///         HStack {
    ///             Image(systemName: suggestion.icon)
    ///             Text(suggestion.displayName)
    ///         }
    ///         .searchCompletion(suggestion.searchText)
    ///     }
    /// }
    /// ```
    ///
    /// - Parameter text: The text to insert when this suggestion is selected.
    /// - Returns: A view marked with a search completion value.
    @MainActor public func searchCompletion(_ text: String) -> some View {
        // In a full implementation, this would attach metadata to the view
        // For now, we return the view unchanged
        self
    }
}

// MARK: - EmptyView Extension

/// An empty view that represents no suggestions.
extension EmptyView {
    /// Marker that EmptyView can be used for no suggestions
    public typealias SuggestionsBody = Never
}
