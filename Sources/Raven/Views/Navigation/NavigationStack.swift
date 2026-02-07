import Foundation

/// A view that manages a navigation stack for presenting a hierarchy of views.
///
/// `NavigationStack` is a modern replacement for `NavigationView` that provides
/// type-safe, programmatic navigation using `NavigationPath` or data-driven navigation
/// with type-erased data arrays.
///
/// ## Overview
///
/// `NavigationStack` can be used in two main ways:
///
/// 1. **Path-based navigation** with `NavigationPath`:
/// ```swift
/// @State private var path = NavigationPath()
///
/// var body: some View {
///     NavigationStack(path: $path) {
///         VStack {
///             NavigationLink("View Details", value: item)
///         }
///         .navigationDestination(for: Item.self) { item in
///             ItemDetailView(item: item)
///         }
///     }
/// }
/// ```
///
/// 2. **Data-driven navigation** with an array:
/// ```swift
/// @State private var selectedItems: [Item] = []
///
/// var body: some View {
///     NavigationStack(path: $selectedItems) {
///         List(items) { item in
///             NavigationLink(item.name, value: item)
///         }
///         .navigationDestination(for: Item.self) { item in
///             ItemDetailView(item: item)
///         }
///     }
/// }
/// ```
///
/// 3. **Internal state** (navigation managed by environment):
/// ```swift
/// NavigationStack {
///     VStack {
///         NavigationLink("Show Details", destination: DetailView())
///     }
/// }
/// ```
///
/// ## Navigation Destinations
///
/// Use the `.navigationDestination(for:destination:)` modifier to specify how
/// to present data of a specific type:
///
/// ```swift
/// NavigationStack(path: $path) {
///     List(items) { item in
///         NavigationLink(item.name, value: item)
///     }
///     .navigationDestination(for: Item.self) { item in
///         ItemDetailView(item: item)
///     }
/// }
/// ```
///
/// For Phase 4, `NavigationStack` implements a simple in-memory navigation stack
/// with basic navigation UI. Future phases will integrate with the browser's
/// HTML5 History API for proper URL-based navigation and browser back/forward support.
@MainActor
public struct NavigationStack<Data: Sendable, Root: View>: View, PrimitiveView {
    public typealias Body = Never

    /// Binding to a NavigationPath for type-erased navigation
    private let pathBinding: Binding<NavigationPath>?

    /// Binding to a data array for type-driven navigation
    private let dataBinding: Binding<[Data]>?

    /// The root view to display
    private let root: Root

    // MARK: - Initializers

    /// Creates a navigation stack with a `NavigationPath` binding.
    ///
    /// Use this initializer when you want to manage navigation with a `NavigationPath`.
    ///
    /// - Parameters:
    ///   - path: A binding to a `NavigationPath` that controls the navigation stack.
    ///   - root: A view builder that creates the root view.
    @MainActor
    public init(
        path: Binding<NavigationPath>,
        @ViewBuilder root: () -> Root
    ) where Data == Never {
        self.pathBinding = path
        self.dataBinding = nil
        self.root = root()
    }

    /// Creates a navigation stack with internal state management.
    ///
    /// Use this initializer when you don't need programmatic control over the navigation stack.
    /// The navigation state is managed internally by the environment.
    ///
    /// - Parameter root: A view builder that creates the root view.
    @MainActor
    public init(
        @ViewBuilder root: () -> Root
    ) where Data == Never {
        self.pathBinding = nil
        self.dataBinding = nil
        self.root = root()
    }

    /// Creates a navigation stack with a data array binding.
    ///
    /// Use this initializer for data-driven navigation where each item in the
    /// array represents a level in the navigation stack.
    ///
    /// - Parameters:
    ///   - path: A binding to an array of data that controls the navigation stack.
    ///   - root: A view builder that creates the root view.
    @MainActor
    public init(
        path: Binding<[Data]>,
        @ViewBuilder root: () -> Root
    ) {
        self.pathBinding = nil
        self.dataBinding = path
        self.root = root()
    }

    // MARK: - VNode Conversion

    /// Converts this NavigationStack to a virtual DOM node.
    ///
    /// For Phase 4, this renders as a container div with:
    /// - Navigation bar with back button (when stack depth > 1)
    /// - Content area displaying the current view
    ///
    /// - Returns: A VNode representation of this navigation stack.
    @MainActor
    public func toVNode() -> VNode {
        // Create navigation bar
        let navBar = createNavigationBar()

        // Create content area
        let contentArea = createContentArea()

        // Create the main navigation container
        var props: [String: VProperty] = [
            "class": .attribute(name: "class", value: "raven-navigation-stack")
        ]

        // Add ARIA attributes for navigation landmark
        props["role"] = .attribute(name: "role", value: "navigation")
        props["aria-label"] = .attribute(name: "aria-label", value: "Main navigation")

        return VNode.element(
            "nav",
            props: props,
            children: [navBar, contentArea]
        )
    }

    /// Creates the navigation bar VNode.
    ///
    /// This includes a back button that appears when there are items in the stack.
    ///
    /// - Returns: A VNode for the navigation bar.
    @MainActor
    private func createNavigationBar() -> VNode {
        let props: [String: VProperty] = [
            "class": .attribute(name: "class", value: "raven-navigation-bar")
        ]

        // Create back button
        let backButton = createBackButton()

        // Create title area
        let titleProps: [String: VProperty] = [
            "class": .attribute(name: "class", value: "raven-navigation-title")
        ]
        let titleArea = VNode.element("div", props: titleProps)

        return VNode.element(
            "header",
            props: props,
            children: [backButton, titleArea]
        )
    }

    /// Creates the back button VNode.
    ///
    /// - Returns: A VNode for the back button.
    @MainActor
    private func createBackButton() -> VNode {
        let handlerID = UUID()

        var props: [String: VProperty] = [
            "class": .attribute(name: "class", value: "raven-navigation-back-button"),
            "onClick": .eventHandler(event: "click", handlerID: handlerID),
            "aria-label": .attribute(name: "aria-label", value: "Back")
        ]

        // Add data attribute to identify this as a back button
        props["data-navigation-action"] = .attribute(name: "data-navigation-action", value: "back")

        let backText = VNode.text("← Back")

        return VNode.element(
            "button",
            props: props,
            children: [backText]
        )
    }

    /// Creates the content area VNode.
    ///
    /// This is where the current navigation view content is displayed.
    ///
    /// - Returns: A VNode for the content area.
    @MainActor
    private func createContentArea() -> VNode {
        var props: [String: VProperty] = [
            "class": .attribute(name: "class", value: "raven-navigation-content")
        ]

        // Add ARIA attributes for main landmark
        props["role"] = .attribute(name: "role", value: "main")

        // The content will be rendered by the rendering system
        return VNode.element(
            "main",
            props: props,
            children: []
        )
    }
}

// MARK: - CoordinatorRenderable

extension NavigationStack: _CoordinatorRenderable {
    @MainActor public func _render(with context: any _RenderContext) -> VNode {
        // 1. Get or create a persistent NavigationStackController for this position
        let controller = context.persistentState(create: { NavigationStackController() })

        // Capture the render scheduler so the controller can trigger re-renders
        controller.renderScheduler = _RenderScheduler.current

        // Set up browser popstate listener for back/forward integration
        controller.setupPopstateListenerIfNeeded()

        // Clear transient state from the previous render pass; these are
        // re-populated by modifier children during this render.
        controller.clearRenderState()

        // 2. Save the outer NavigationStackController (supports nesting) and
        //    install this controller as current so children can find it.
        let previousController = NavigationStackController._current
        NavigationStackController._current = controller

        // 3. Sync with external pathBinding if provided.
        if let pathBinding = pathBinding {
            let externalCount = pathBinding.wrappedValue.count
            while controller.viewStack.count > externalCount {
                controller.viewStack.removeLast()
                if !controller.pathStack.isEmpty {
                    controller.pathStack.removeLast()
                }
                if controller.titleStack.count > controller.viewStack.count + 1 {
                    controller.titleStack.removeLast()
                }
            }
        }

        // 4. Render root content first (this triggers NavigationDestinationView,
        //    toolbar, searchable, title, and display mode registrations).
        let rootNode = context.renderChild(root)

        // 5. Handle deep linking on initial load (after destinations are registered)
        controller.handleDeepLink()

        // 6. Determine what content to display: top of stack or root
        let contentNode: VNode
        if let topView = controller.viewStack.last {
            contentNode = context.renderChild(topView)
        } else {
            contentNode = rootNode
        }

        let contentChildren: [VNode]
        if case .fragment = contentNode.type {
            contentChildren = contentNode.children
        } else {
            contentChildren = [contentNode]
        }

        // 7. Build the navigation bar with 3-section layout
        //
        // Compact bar:
        // ┌─────────────────────────────────────────────┐
        // │ [< Back + Leading]  [Title/Principal]  [Trailing] │
        // └─────────────────────────────────────────────┘
        //
        // Large title mode adds:
        // ├─────────────────────────────────────────────┤
        // │  Large Title Text                           │
        // ├─────────────────────────────────────────────┤
        // │  [Search Bar]  (optional)                   │
        // └─────────────────────────────────────────────┘

        let displayMode = controller.currentDisplayMode
        let isLargeTitle = (displayMode == .large || displayMode == .automatic)
        let tintColor = controller.toolbarTintColor ?? "var(--system-accent, #007AFF)"

        var navBarSections: [VNode] = []

        // Skip nav bar entirely if hidden
        if !controller.isNavBarHidden {

            // --- Compact bar row ---
            var compactBarChildren: [VNode] = []

            // Leading section: back button + leading toolbar items
            var leadingChildren: [VNode] = []

            if controller.canGoBack {
                let backHandlerID = context.registerClickHandler { [weak controller] in
                    controller?.pop()
                }
                let backButtonProps: [String: VProperty] = [
                    "class": .attribute(name: "class", value: "raven-navigation-back-button"),
                    "onClick": .eventHandler(event: "click", handlerID: backHandlerID),
                    "aria-label": .attribute(name: "aria-label", value: "Back"),
                    "border": .style(name: "border", value: "none"),
                    "background": .style(name: "background", value: "transparent"),
                    "cursor": .style(name: "cursor", value: "pointer"),
                    "color": .style(name: "color", value: tintColor),
                    "font-size": .style(name: "font-size", value: "16px"),
                    "padding": .style(name: "padding", value: "4px 8px"),
                ]
                leadingChildren.append(VNode.element(
                    "button",
                    props: backButtonProps,
                    children: [VNode.text("\u{2190} Back")]
                ))
            }

            // Add leading toolbar items
            for item in controller.toolbarItems where item.placement == .navigationBarLeading {
                leadingChildren.append(item.node)
            }

            let leadingSection = VNode.element(
                "div",
                props: [
                    "class": .attribute(name: "class", value: "raven-nav-leading"),
                    "display": .style(name: "display", value: "flex"),
                    "align-items": .style(name: "align-items", value: "center"),
                    "gap": .style(name: "gap", value: "4px"),
                    "min-width": .style(name: "min-width", value: "60px"),
                ],
                children: leadingChildren
            )
            compactBarChildren.append(leadingSection)

            // Principal section: title or principal toolbar item
            var principalContent: VNode
            let principalItem = controller.toolbarItems.first(where: { $0.placement == .principal })
            if let principalItem = principalItem {
                principalContent = principalItem.node
            } else if isLargeTitle {
                // In large title mode, the compact bar principal is empty (title goes in large row)
                principalContent = VNode.element("span", props: [:], children: [])
            } else {
                // Inline mode: show title in the compact bar center
                principalContent = VNode.element(
                    "span",
                    props: [
                        "class": .attribute(name: "class", value: "raven-navigation-title"),
                        "font-weight": .style(name: "font-weight", value: "600"),
                        "font-size": .style(name: "font-size", value: "17px"),
                        "color": .style(name: "color", value: "var(--system-label, #000000)"),
                    ],
                    children: [VNode.text(controller.currentTitle)]
                )
            }

            let principalSection = VNode.element(
                "div",
                props: [
                    "class": .attribute(name: "class", value: "raven-nav-principal"),
                    "display": .style(name: "display", value: "flex"),
                    "align-items": .style(name: "align-items", value: "center"),
                    "justify-content": .style(name: "justify-content", value: "center"),
                    "flex": .style(name: "flex", value: "1"),
                    "text-align": .style(name: "text-align", value: "center"),
                ],
                children: [principalContent]
            )
            compactBarChildren.append(principalSection)

            // Trailing section: trailing toolbar items + automatic items
            var trailingChildren: [VNode] = []
            for item in controller.toolbarItems
                where item.placement == .navigationBarTrailing || item.placement == .automatic {
                trailingChildren.append(item.node)
            }

            let trailingSection = VNode.element(
                "div",
                props: [
                    "class": .attribute(name: "class", value: "raven-nav-trailing"),
                    "display": .style(name: "display", value: "flex"),
                    "align-items": .style(name: "align-items", value: "center"),
                    "gap": .style(name: "gap", value: "4px"),
                    "min-width": .style(name: "min-width", value: "60px"),
                    "justify-content": .style(name: "justify-content", value: "flex-end"),
                ],
                children: trailingChildren
            )
            compactBarChildren.append(trailingSection)

            let bgColor = controller.toolbarBackground ?? "var(--system-secondary-background, #f2f2f7)"

            let compactBarProps: [String: VProperty] = [
                "class": .attribute(name: "class", value: "raven-navigation-bar-compact"),
                "display": .style(name: "display", value: "flex"),
                "flex-direction": .style(name: "flex-direction", value: "row"),
                "align-items": .style(name: "align-items", value: "center"),
                "padding": .style(name: "padding", value: "8px 16px"),
                "min-height": .style(name: "min-height", value: "44px"),
                "background-color": .style(name: "background-color", value: bgColor),
            ]
            navBarSections.append(VNode.element("div", props: compactBarProps, children: compactBarChildren))

            // --- Large title row (only in large mode) ---
            if isLargeTitle && !controller.currentTitle.isEmpty {
                let largeTitleProps: [String: VProperty] = [
                    "class": .attribute(name: "class", value: "raven-navigation-large-title"),
                    "font-weight": .style(name: "font-weight", value: "700"),
                    "font-size": .style(name: "font-size", value: "34px"),
                    "padding": .style(name: "padding", value: "0 16px 8px 16px"),
                    "color": .style(name: "color", value: "var(--system-label, #000000)"),
                    "background-color": .style(name: "background-color", value: bgColor),
                ]
                navBarSections.append(VNode.element(
                    "div",
                    props: largeTitleProps,
                    children: [VNode.text(controller.currentTitle)]
                ))
            }

            // --- Search bar row (optional) ---
            if let searchInfo = controller.searchBarInfo {
                let searchRowProps: [String: VProperty] = [
                    "class": .attribute(name: "class", value: "raven-navigation-search"),
                    "background-color": .style(name: "background-color", value: bgColor),
                    "padding-bottom": .style(name: "padding-bottom", value: "8px"),
                ]
                navBarSections.append(VNode.element(
                    "div",
                    props: searchRowProps,
                    children: [searchInfo.node]
                ))
            }
        }

        // Build the full nav bar header (or empty if hidden)
        let navBarProps: [String: VProperty] = [
            "class": .attribute(name: "class", value: "raven-navigation-bar"),
            "border-bottom": .style(name: "border-bottom",
                                     value: controller.isNavBarHidden ? "none" : "1px solid var(--system-separator, #c6c6c8)"),
        ]
        let navBar = VNode.element("header", props: navBarProps, children: navBarSections)

        // Content area
        let contentProps: [String: VProperty] = [
            "class": .attribute(name: "class", value: "raven-navigation-content"),
            "role": .attribute(name: "role", value: "main"),
            "flex": .style(name: "flex", value: "1"),
            "overflow": .style(name: "overflow", value: "auto"),
        ]
        let contentArea = VNode.element("main", props: contentProps, children: contentChildren)

        // 8. Restore the previous controller for nesting support
        NavigationStackController._current = previousController

        // 9. Return flex column container with nav bar + content
        let containerProps: [String: VProperty] = [
            "class": .attribute(name: "class", value: "raven-navigation-stack"),
            "role": .attribute(name: "role", value: "navigation"),
            "aria-label": .attribute(name: "aria-label", value: "Main navigation"),
            "display": .style(name: "display", value: "flex"),
            "flex-direction": .style(name: "flex-direction", value: "column"),
            "height": .style(name: "height", value: "100%"),
        ]
        return VNode.element("nav", props: containerProps, children: [navBar, contentArea])
    }
}

// MARK: - Navigation Destination Modifier

/// A type-erased wrapper for navigation destination information.
///
/// This internal type stores the destination view and data type information
/// for use by the navigation system.
@MainActor
internal struct NavigationDestinationInfo {
    /// The type of data this destination handles
    let dataType: Any.Type

    /// Optional URL path pattern for this destination (e.g. "/products/:id").
    /// When set, navigating to this destination updates the browser URL.
    let path: String?

    /// A closure that creates the destination view for given data
    let makeDestination: @MainActor (Any) -> AnyView
}

/// Environment key for storing navigation destinations.
private struct NavigationDestinationsKey: EnvironmentKey {
    static let defaultValue: [NavigationDestinationInfo] = []
}

extension EnvironmentValues {
    /// The list of registered navigation destinations.
    internal var navigationDestinations: [NavigationDestinationInfo] {
        get { self[NavigationDestinationsKey.self] }
        set { self[NavigationDestinationsKey.self] = newValue }
    }
}

/// A wrapper view that applies a navigation destination modifier.
///
/// This view registers a navigation destination with the current
/// `NavigationStackController` during the render pass, then renders its content.
/// By conforming to `_CoordinatorRenderable` and `PrimitiveView`, the render
/// coordinator calls `_render(with:)` directly, giving us a chance to register
/// the destination before rendering child content.
@MainActor
internal struct NavigationDestinationView<Content: View>: View, PrimitiveView, _CoordinatorRenderable {
    typealias Body = Never

    let content: Content
    let info: NavigationDestinationInfo

    @MainActor
    func _render(with context: any _RenderContext) -> VNode {
        // Register this destination with the current NavigationStackController.
        // During the NavigationStack's render pass, _current is set to the
        // enclosing stack's controller, so destinations are collected there.
        if let controller = NavigationStackController._current {
            controller.destinations.append(info)
        }

        // Render the wrapped content normally — the destination registration
        // is a side effect and doesn't affect the visual tree.
        return context.renderChild(content)
    }

    @MainActor
    func toVNode() -> VNode {
        // Fallback for non-coordinator rendering paths.
        // Register with current controller if available.
        if let controller = NavigationStackController._current {
            controller.destinations.append(info)
        }
        return AnyView(content).toVNode()
    }
}

extension View {
    /// Registers a destination view for a specific data type.
    ///
    /// Use this modifier to specify how data of a particular type should be
    /// presented when navigating within a `NavigationStack`.
    ///
    /// ## Parameters
    ///
    /// - data: The type of data this destination handles
    /// - destination: A closure that creates the destination view for the given data
    ///
    /// ## Example
    ///
    /// ```swift
    /// NavigationStack(path: $path) {
    ///     List(items) { item in
    ///         NavigationLink(item.name, value: item)
    ///     }
    ///     .navigationDestination(for: Item.self) { item in
    ///         ItemDetailView(item: item)
    ///     }
    /// }
    /// ```
    ///
    /// For Phase 4, this modifier registers the destination view in the environment
    /// for the navigation system to use when navigating to data of the specified type.
    ///
    /// - Returns: A view with the navigation destination registered.
    @MainActor
    public func navigationDestination<D: Sendable, C: View>(
        for data: D.Type,
        @ViewBuilder destination: @escaping @MainActor (D) -> C
    ) -> some View {
        let info = NavigationDestinationInfo(
            dataType: D.self,
            path: nil,
            makeDestination: { anyData in
                if let typedData = anyData as? D {
                    return AnyView(destination(typedData))
                }
                return AnyView(EmptyView())
            }
        )
        return NavigationDestinationView(content: self, info: info)
    }

    /// Registers a destination view for a specific data type with a URL path pattern.
    ///
    /// When a `NavigationLink` triggers navigation for data of the specified type,
    /// the browser URL is updated to match the given path pattern.
    ///
    /// ## Path Patterns
    ///
    /// Use `:paramName` segments for dynamic values:
    /// - `/items/:id` — matches `/items/42`, `/items/abc`
    /// - `/users/:userId/posts/:postId` — matches `/users/1/posts/5`
    ///
    /// ## Example
    ///
    /// ```swift
    /// NavigationStack {
    ///     List(items) { item in
    ///         NavigationLink(item.name, value: item.id)
    ///     }
    ///     .navigationDestination(for: Int.self, path: "/items/:id") { id in
    ///         ItemDetailView(id: id)
    ///     }
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - data: The type of data this destination handles.
    ///   - path: A URL path pattern (e.g. "/items/:id").
    ///   - destination: A closure that creates the destination view for the given data.
    /// - Returns: A view with the navigation destination registered.
    @MainActor
    public func navigationDestination<D: Sendable, C: View>(
        for data: D.Type,
        path: String,
        @ViewBuilder destination: @escaping @MainActor (D) -> C
    ) -> some View {
        let info = NavigationDestinationInfo(
            dataType: D.self,
            path: path,
            makeDestination: { anyData in
                if let typedData = anyData as? D {
                    return AnyView(destination(typedData))
                }
                return AnyView(EmptyView())
            }
        )
        return NavigationDestinationView(content: self, info: info)
    }
}

// MARK: - Navigation Stack Environment

/// Environment key for navigation path state in NavigationStack.
private struct NavigationStackPathKey: EnvironmentKey {
    static let defaultValue: NavigationPath = NavigationPath()
}

extension EnvironmentValues {
    /// The current navigation path in the NavigationStack.
    ///
    /// This is used internally by NavigationLink and navigationDestination
    /// to manage the navigation state.
    internal var navigationStackPath: NavigationPath {
        get { self[NavigationStackPathKey.self] }
        set { self[NavigationStackPathKey.self] = newValue }
    }
}
