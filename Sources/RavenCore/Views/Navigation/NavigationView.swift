import Foundation

/// A view that manages navigation presentation and the navigation stack.
///
/// `NavigationView` provides a container for navigable content and manages
/// a stack of views. It displays the root content and allows NavigationLinks
/// within that content to push new views onto the stack.
///
/// Example:
/// ```swift
/// NavigationView {
///     VStack {
///         Text("Home")
///         NavigationLink("Go to Detail", destination: DetailView())
///     }
/// }
/// ```
///
/// For Phase 4, NavigationView implements a simple in-memory navigation stack
/// with basic navigation UI (back button when stack depth > 1). Future phases
/// will integrate with the browser's HTML5 History API for proper URL-based
/// navigation and browser back/forward button support.
public struct NavigationView<Content: View>: View, Sendable {
    /// The root content of the navigation view
    private let content: Content

    // MARK: - Initializers

    /// Creates a navigation view with the given content.
    ///
    /// - Parameter content: A view builder that creates the root content.
    ///
    /// Example:
    /// ```swift
    /// NavigationView {
    ///     List {
    ///         NavigationLink("Item 1", destination: DetailView(id: 1))
    ///         NavigationLink("Item 2", destination: DetailView(id: 2))
    ///     }
    /// }
    /// ```
    @MainActor
    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    // MARK: - Body

    /// The content and behavior of this view.
    @MainActor
    public var body: some View {
        // For Phase 4, we create a simple container structure
        // The actual navigation logic will be handled by the environment
        // and rendering system
        NavigationContainer(content: content)
    }
}

// MARK: - Navigation Container

/// Internal view that renders the navigation container structure.
///
/// This view is responsible for creating the DOM structure for navigation,
/// including the navigation bar and content area.
@MainActor
private struct NavigationContainer<Content: View>: View, PrimitiveView, Sendable {
    typealias Body = Never

    /// The content to display in the navigation view
    let content: Content

    /// Converts this container to a virtual DOM node.
    ///
    /// Creates a nav element with proper structure:
    /// - Navigation bar (header) with back button (when stack depth > 1)
    /// - Content area for the current view
    ///
    /// - Returns: A VNode representation of the navigation container.
    @MainActor public func toVNode() -> VNode {
        // Create navigation bar
        let navBar = createNavigationBar()

        // Create content area
        let contentArea = createContentArea()

        // Create the main navigation container with proper ARIA landmark
        var props: [String: VProperty] = [
            "class": .attribute(name: "class", value: "raven-navigation-view")
        ]

        // Add ARIA attributes for navigation landmark (WCAG 2.1 requirement)
        // The <nav> element already has implicit role="navigation", but we can add
        // aria-label for clarity
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
    /// For Phase 4, this is a simple header with a back button placeholder.
    /// The back button will be shown/hidden based on navigation stack depth.
    ///
    /// - Returns: A VNode for the navigation bar.
    @MainActor
    private func createNavigationBar() -> VNode {
        let props: [String: VProperty] = [
            "class": .attribute(name: "class", value: "raven-navigation-bar")
        ]

        // Create back button (will be controlled by navigation state)
        let backButton = createBackButton()

        // Create title area (placeholder for now)
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
    /// For Phase 4, this creates a button that will pop the navigation stack.
    /// The rendering system will handle showing/hiding this based on stack depth.
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

        // Add data attribute to identify this as a back button for the navigation system
        props["data-navigation-action"] = .attribute(name: "data-navigation-action", value: "back")

        // Create back button text/icon
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

        // Add ARIA attributes for main landmark (WCAG 2.1 requirement)
        // The <main> element has implicit role="main" which marks primary content
        props["role"] = .attribute(name: "role", value: "main")

        // The content will be rendered by the rendering system
        // For now, create a placeholder that will be populated during rendering
        return VNode.element(
            "main",
            props: props,
            children: []
        )
    }
}

// MARK: - Navigation Environment

/// Environment key for navigation stack state.
///
/// This will be used in future phases to manage navigation state through the environment.
private struct NavigationStackKey: EnvironmentKey {
    static let defaultValue: NavigationPath = NavigationPath()
}

extension EnvironmentValues {
    /// The current navigation path.
    ///
    /// This property will be used by NavigationLink to push views onto the stack
    /// and by NavigationView to display the current view.
    internal var navigationPath: NavigationPath {
        get { self[NavigationStackKey.self] }
        set { self[NavigationStackKey.self] = newValue }
    }
}

// MARK: - Navigation Title Modifier

/// A modifier view that sets the navigation title on the current
/// `NavigationStackController` during render and passes through its content.
@MainActor
struct _NavigationTitleModifier<Content: View>: View, PrimitiveView, _CoordinatorRenderable, Sendable {
    typealias Body = Never

    let content: Content
    let title: String

    @MainActor func toVNode() -> VNode {
        return VNode.text("")
    }

    @MainActor public func _render(with context: any _RenderContext) -> VNode {
        NavigationStackController._current?.setCurrentTitle(title)
        return context.renderChild(content)
    }
}

/// A modifier view that sets the navigation bar title display mode on the current
/// `NavigationStackController` during render and passes through its content.
@MainActor
struct _NavigationBarTitleDisplayModeModifier<Content: View>: View, PrimitiveView, _CoordinatorRenderable, Sendable {
    typealias Body = Never

    let content: Content
    let displayMode: NavigationBarTitleDisplayMode

    @MainActor func toVNode() -> VNode {
        return VNode.text("")
    }

    @MainActor public func _render(with context: any _RenderContext) -> VNode {
        NavigationStackController._current?.setCurrentDisplayMode(displayMode)
        return context.renderChild(content)
    }
}

/// A modifier view that hides/shows the navigation bar on the current
/// `NavigationStackController` during render and passes through its content.
@MainActor
struct _NavigationBarHiddenModifier<Content: View>: View, PrimitiveView, _CoordinatorRenderable, Sendable {
    typealias Body = Never

    let content: Content
    let hidden: Bool

    @MainActor func toVNode() -> VNode {
        return VNode.text("")
    }

    @MainActor public func _render(with context: any _RenderContext) -> VNode {
        NavigationStackController._current?.setCurrentNavBarHidden(hidden)
        return context.renderChild(content)
    }
}

// MARK: - Navigation Bar Modifiers

extension View {
    /// Sets the title for the navigation bar.
    ///
    /// Use this modifier to set the title displayed in the navigation bar
    /// when this view is shown in a NavigationView.
    ///
    /// Example:
    /// ```swift
    /// NavigationView {
    ///     Text("Content")
    ///         .navigationTitle("My Screen")
    /// }
    /// ```
    ///
    /// - Parameter title: The title to display in the navigation bar.
    /// - Returns: A view with a navigation title.
    @MainActor
    public func navigationTitle(_ title: String) -> some View {
        _NavigationTitleModifier(content: self, title: title)
    }

    /// Sets the navigation bar title display mode.
    ///
    /// - Parameter displayMode: The display mode for the navigation bar title.
    /// - Returns: A view with the specified navigation bar title display mode.
    @MainActor
    public func navigationBarTitleDisplayMode(_ displayMode: NavigationBarTitleDisplayMode) -> some View {
        _NavigationBarTitleDisplayModeModifier(content: self, displayMode: displayMode)
    }

    /// Hides the navigation bar for this view.
    ///
    /// - Parameter hidden: Whether to hide the navigation bar.
    /// - Returns: A view with the navigation bar visibility set.
    @MainActor
    public func navigationBarHidden(_ hidden: Bool) -> some View {
        _NavigationBarHiddenModifier(content: self, hidden: hidden)
    }
}

// MARK: - Navigation Bar Title Display Mode

/// The display mode for navigation bar titles.
public enum NavigationBarTitleDisplayMode: Sendable {
    /// Large title display (default)
    case large
    /// Inline title display
    case inline
    /// Automatic title display based on context
    case automatic
}

// MARK: - Navigation State Management

/// A class that manages navigation state for a NavigationView.
///
/// For Phase 4, this provides basic stack management. Future phases will
/// integrate with the browser's History API and handle URL-based routing.
@MainActor
private final class NavigationState: ObservableObject {
    /// The navigation stack
    @Published var path: NavigationPath = NavigationPath()

    /// Push a view onto the navigation stack
    func push<V: View>(_ view: V) {
        path.append(view)
    }

    /// Pop the top view from the navigation stack
    func pop() {
        path.removeLast()
    }

    /// Clear the navigation stack
    func popToRoot() {
        path.removeAll()
    }

    /// Check if we can navigate back
    var canGoBack: Bool {
        !path.isEmpty
    }
}
