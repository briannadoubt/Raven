import Foundation

// MARK: - ToolbarItemPlacement

/// The placement of a toolbar item on the screen.
///
/// Use toolbar item placements to control where items appear in the interface.
/// Different placements are used for different parts of the toolbar or app chrome.
public enum ToolbarItemPlacement: Sendable, Hashable {
    /// The default placement, typically in the trailing (right) side of the toolbar.
    case automatic

    /// The leading (left) navigation area, typically for back/navigation buttons.
    case navigationBarLeading

    /// The trailing (right) navigation area, typically for action buttons.
    case navigationBarTrailing

    /// The principal (center) area of the toolbar, typically for titles.
    case principal

    /// The bottom bar, typically for persistent actions.
    case bottomBar

    /// Confirmation action placement, typically for OK/Save buttons in dialogs.
    case confirmationAction

    /// Cancellation action placement, typically for Cancel buttons in dialogs.
    case cancellationAction
}

// MARK: - ToolbarItem

/// A single item that can be placed in a toolbar.
///
/// `ToolbarItem` represents a view that should appear in a toolbar at a specific placement.
/// It's typically used with the `.toolbar()` modifier to define toolbar contents.
public struct ToolbarItem<Content: View>: Sendable {
    /// The placement of this toolbar item
    public let placement: ToolbarItemPlacement

    /// The content to display in the toolbar
    public let content: Content

    /// Creates a toolbar item with the specified placement and content.
    ///
    /// - Parameters:
    ///   - placement: The placement of the toolbar item. Defaults to `.automatic`.
    ///   - content: A view builder that creates the toolbar item's content.
    ///
    /// Example:
    /// ```swift
    /// ToolbarItem(placement: .navigationBarTrailing) {
    ///     Button("Add") { addItem() }
    /// }
    /// ```
    @MainActor public init(
        placement: ToolbarItemPlacement = .automatic,
        @ViewBuilder content: () -> Content
    ) {
        self.placement = placement
        self.content = content()
    }
}

// MARK: - ToolbarItemGroup

/// A group of items that can be placed in a toolbar together.
///
/// Use `ToolbarItemGroup` to place multiple items at the same toolbar placement,
/// automatically handling spacing and layout between them.
public struct ToolbarItemGroup<Content: View>: Sendable {
    /// The placement of these toolbar items
    public let placement: ToolbarItemPlacement

    /// The content containing the grouped toolbar items
    public let content: Content

    /// Creates a toolbar item group with the specified placement and content.
    ///
    /// - Parameters:
    ///   - placement: The placement for all items in the group.
    ///   - content: A view builder that creates the toolbar items.
    ///
    /// Example:
    /// ```swift
    /// ToolbarItemGroup(placement: .bottomBar) {
    ///     Button("Delete") { deleteItem() }
    ///     Spacer()
    ///     Button("Share") { shareItem() }
    /// }
    /// ```
    @MainActor public init(
        placement: ToolbarItemPlacement,
        @ViewBuilder content: () -> Content
    ) {
        self.placement = placement
        self.content = content()
    }
}

// MARK: - Toolbar View

/// Internal view that wraps content and toolbar items.
public struct _ToolbarView<Content: View>: View, PrimitiveView, _CoordinatorRenderable, Sendable {
    let content: Content

    public typealias Body = Never

    @MainActor public func toVNode() -> VNode {
        // Create a toolbar container
        let toolbarProps: [String: VProperty] = [
            "class": .attribute(name: "class", value: "raven-toolbar"),
            "style": .style(
                name: "style",
                value: "display: flex; flex-direction: row; align-items: center; background-color: #f8f8f8; border-bottom: 1px solid #e0e0e0; padding: 8px 16px; gap: 8px;"
            )
        ]

        let toolbarNode = VNode.element(
            "div",
            props: toolbarProps,
            children: []
        )

        // Wrap both toolbar and content
        let containerProps: [String: VProperty] = [
            "class": .attribute(name: "class", value: "raven-toolbar-container"),
            "style": .style(name: "style", value: "display: flex; flex-direction: column; width: 100%;")
        ]

        return VNode.element(
            "div",
            props: containerProps,
            children: [toolbarNode]
        )
    }

    /// Explicit toolbar items passed via the type-erased builder.
    internal var _explicitItems: [_AnyToolbarItem] = []

    @MainActor public func _render(with context: any _RenderContext) -> VNode {
        // Register explicit toolbar items with the NavigationStackController
        if let controller = NavigationStackController._current {
            for item in _explicitItems {
                let renderedNode = context.renderChild(item.content)
                controller.toolbarItems.append(ToolbarItemInfo(placement: item.placement, node: renderedNode))
            }
        }

        // Render the wrapped content (the actual page content, not toolbar items)
        return context.renderChild(content)
    }
}

// MARK: - View Extension

extension View {
    /// Adds a toolbar to this view.
    ///
    /// Use this modifier to add toolbar items that appear in the app's navigation bar or toolbar.
    /// The toolbar items are positioned based on their `ToolbarItemPlacement`.
    ///
    /// ## Basic Usage
    ///
    /// Add a simple toolbar with a button:
    ///
    /// ```swift
    /// VStack {
    ///     Text("Content")
    /// }
    /// .toolbar {
    ///     ToolbarItem(placement: .navigationBarTrailing) {
    ///         Button("Add") { addItem() }
    ///     }
    /// }
    /// ```
    ///
    /// ## Multiple Items
    ///
    /// Use `ToolbarItemGroup` to add multiple items at the same placement:
    ///
    /// ```swift
    /// .toolbar {
    ///     ToolbarItemGroup(placement: .navigationBarTrailing) {
    ///         Button("Edit") { edit() }
    ///         Button("Share") { share() }
    ///     }
    /// }
    /// ```
    ///
    /// ## Different Placements
    ///
    /// Organize items across different toolbar areas:
    ///
    /// ```swift
    /// .toolbar {
    ///     ToolbarItem(placement: .navigationBarLeading) {
    ///         Button("Back") { goBack() }
    ///     }
    ///     ToolbarItem(placement: .principal) {
    ///         Text("Title")
    ///     }
    ///     ToolbarItem(placement: .navigationBarTrailing) {
    ///         Button("Menu") { showMenu() }
    ///     }
    /// }
    /// ```
    ///
    /// - Parameter content: A view builder that creates the toolbar items.
    /// - Returns: A view with a toolbar applied.
    @MainActor public func toolbar<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> _ToolbarView<Content> {
        _ToolbarView(content: content())
    }
}

// MARK: - Type-Erased Toolbar Item

/// A type-erased toolbar item for use with the toolbar modifier.
public struct _AnyToolbarItem: Sendable {
    /// The placement of this toolbar item.
    public let placement: ToolbarItemPlacement

    /// The content view for this toolbar item (type-erased).
    public let content: AnyView

    /// Creates a type-erased toolbar item from a `ToolbarItem`.
    @MainActor
    public init<C: View>(_ item: ToolbarItem<C>) {
        self.placement = item.placement
        self.content = AnyView(item.content)
    }
}

// MARK: - Toolbar Content Builder

/// Result builder for creating arrays of type-erased toolbar items.
@resultBuilder
public struct _ToolbarContentBuilder {
    public static func buildBlock(_ components: _AnyToolbarItem...) -> [_AnyToolbarItem] {
        components
    }

    public static func buildBlock(_ components: [_AnyToolbarItem]...) -> [_AnyToolbarItem] {
        components.flatMap { $0 }
    }

    public static func buildOptional(_ component: [_AnyToolbarItem]?) -> [_AnyToolbarItem] {
        component ?? []
    }

    public static func buildEither(first component: [_AnyToolbarItem]) -> [_AnyToolbarItem] {
        component
    }

    public static func buildEither(second component: [_AnyToolbarItem]) -> [_AnyToolbarItem] {
        component
    }
}

// MARK: - Toolbar Background Modifier

/// A modifier that sets the toolbar background color.
@MainActor
struct _ToolbarBackgroundModifier<Content: View>: View, PrimitiveView, _CoordinatorRenderable, Sendable {
    typealias Body = Never

    let content: Content
    let cssColor: String

    @MainActor func toVNode() -> VNode {
        return VNode.text("")
    }

    @MainActor public func _render(with context: any _RenderContext) -> VNode {
        NavigationStackController._current?.toolbarBackground = cssColor
        return context.renderChild(content)
    }
}

/// A modifier that sets the toolbar tint/color scheme.
@MainActor
struct _ToolbarColorSchemeModifier<Content: View>: View, PrimitiveView, _CoordinatorRenderable, Sendable {
    typealias Body = Never

    let content: Content
    let colorScheme: ColorScheme?

    @MainActor func toVNode() -> VNode {
        return VNode.text("")
    }

    @MainActor public func _render(with context: any _RenderContext) -> VNode {
        if let scheme = colorScheme {
            let tint = scheme == .dark ? "#ffffff" : "#000000"
            NavigationStackController._current?.toolbarTintColor = tint
        }
        return context.renderChild(content)
    }
}

// MARK: - Toolbar Modifier Extensions

extension View {
    /// Adds toolbar items using the type-erased toolbar content builder.
    ///
    /// This overload accepts explicit `_AnyToolbarItem` instances that get
    /// registered with the NavigationStackController during render.
    @MainActor
    public func toolbar(@_ToolbarContentBuilder items: () -> [_AnyToolbarItem]) -> some View {
        var view = _ToolbarView(content: self)
        view._explicitItems = items()
        return view
    }

    /// Sets the background color of the toolbar/navigation bar.
    @MainActor
    public func toolbarBackground(_ color: Color) -> some View {
        _ToolbarBackgroundModifier(content: self, cssColor: color.cssValue)
    }

    /// Sets the color scheme for the toolbar items.
    @MainActor
    public func toolbarColorScheme(_ colorScheme: ColorScheme?) -> some View {
        _ToolbarColorSchemeModifier(content: self, colorScheme: colorScheme)
    }
}
