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

// MARK: - Navigation Destination Modifier

/// A type-erased wrapper for navigation destination information.
///
/// This internal type stores the destination view and data type information
/// for use by the navigation system.
@MainActor
internal struct NavigationDestinationInfo {
    /// The type of data this destination handles
    let dataType: Any.Type

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
/// This internal view applies the navigation destination registration by wrapping
/// the content and setting the environment appropriately.
@MainActor
private struct NavigationDestinationView<Content: View>: View {
    let content: Content
    let info: NavigationDestinationInfo

    @MainActor
    var body: some View {
        content.environment(\.navigationDestinations, [info])
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
        // For Phase 4, register the destination in the environment
        // The rendering system will use this to resolve navigation destinations
        let info = NavigationDestinationInfo(
            dataType: D.self,
            makeDestination: { anyData in
                if let typedData = anyData as? D {
                    return AnyView(destination(typedData))
                }
                return AnyView(EmptyView())
            }
        )

        // Wrap the view and apply the destination registration
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
