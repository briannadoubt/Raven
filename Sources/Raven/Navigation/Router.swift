import Foundation
import JavaScriptKit

/// Core routing engine for URL-based navigation.
///
/// `Router` is the central component for managing application navigation through URLs.
/// It coordinates route registration, matching, navigation, and browser history integration.
///
/// ## Overview
///
/// The Router provides:
/// - Route registration and pattern matching
/// - Browser history integration (back/forward buttons)
/// - Deep link support
/// - Programmatic navigation
/// - URL parameter extraction
///
/// ## Basic Usage
///
/// ```swift
/// @MainActor
/// class AppRouter: ObservableObject {
///     let router = Router()
///
///     init() {
///         // Register routes
///         router.register(path: "/") {
///             HomeView()
///         }
///
///         router.register(path: "/products/:id") { params in
///             ProductDetailView(id: params.int("id") ?? 0)
///         }
///
///         // Handle initial URL
///         router.handleInitialURL()
///     }
/// }
/// ```
///
/// ## Navigation
///
/// Navigate programmatically:
/// ```swift
/// router.navigate(to: "/products/123")
/// router.back()
/// router.forward()
/// ```
///
/// ## Environment Integration
///
/// Access the router from views:
/// ```swift
/// @Environment(\.router) var router
///
/// Button("Go to Products") {
///     router.navigate(to: "/products")
/// }
/// ```
@MainActor
public final class Router: ObservableObject {
    // MARK: - Types

    /// Navigation mode for controlling history behavior
    public enum NavigationMode: Sendable {
        /// Push a new entry onto the history stack
        case push

        /// Replace the current history entry
        case replace
    }

    // MARK: - Published Properties

    /// The current URL path
    @Published public private(set) var currentPath: String = "/"

    /// The current route parameters
    @Published public private(set) var currentParameters: RouteParameters = RouteParameters()

    /// The current view to display
    @Published public private(set) var currentView: AnyView?

    /// Whether the router is navigating
    @Published public private(set) var isNavigating: Bool = false

    // MARK: - Private Properties

    /// Registered routes
    private var routes: [Route] = []

    /// Navigation history manager
    private let history: NavigationHistory

    /// Deep link handler
    private let deepLinkHandler: DeepLinkHandler

    /// Default/fallback view for unmatched routes
    private var notFoundView: AnyView?

    /// Navigation interceptor for custom handling
    private var navigationInterceptor: (@Sendable @MainActor (String) -> Bool)?

    // MARK: - Initialization

    /// Creates a new router instance.
    ///
    /// - Parameters:
    ///   - history: Navigation history manager (defaults to shared instance)
    ///   - deepLinkHandler: Deep link handler (creates new instance if not provided)
    public init(
        history: NavigationHistory = .shared,
        deepLinkHandler: DeepLinkHandler? = nil
    ) {
        self.history = history
        self.deepLinkHandler = deepLinkHandler ?? DeepLinkHandler()

        setupPublished()
        setupHistoryListener()
    }

    // MARK: - Route Registration

    /// Registers a route with a path pattern and view handler.
    ///
    /// - Parameters:
    ///   - path: The URL pattern to match (e.g., "/products/:id")
    ///   - handler: Closure that receives route parameters and returns a view
    public func register<Content: View>(
        path: String,
        @ViewBuilder handler: @escaping @Sendable @MainActor (RouteParameters) -> Content
    ) {
        let route = Route(path: path, handler: handler)
        routes.append(route)

        // Also register with deep link handler
        deepLinkHandler.register(pattern: path)
    }

    /// Registers a route with a constant view.
    ///
    /// - Parameters:
    ///   - path: The URL pattern to match
    ///   - view: The view to display for this route
    public func register<Content: View>(path: String, view: Content) {
        let route = Route(path: path, view: view)
        routes.append(route)

        // Also register with deep link handler
        deepLinkHandler.register(pattern: path)
    }

    /// Registers a route with a parameterless view builder closure.
    ///
    /// This is a convenience overload that wraps a parameterless closure
    /// into the standard `(RouteParameters) -> Content` handler form.
    ///
    /// - Parameters:
    ///   - path: The URL pattern to match
    ///   - content: Closure that returns a view for this route
    public func register<Content: View>(
        path: String,
        @ViewBuilder content: @escaping @Sendable @MainActor () -> Content
    ) {
        register(path: path) { (_: RouteParameters) in content() }
    }

    /// Unregisters a route by path pattern.
    ///
    /// - Parameter path: The path pattern to unregister
    public func unregister(path: String) {
        routes.removeAll { $0.path == path }
        deepLinkHandler.unregister(pattern: path)
    }

    /// Sets the fallback view for unmatched routes.
    ///
    /// - Parameter view: The view to display when no route matches
    public func setNotFoundView<Content: View>(_ view: Content) {
        self.notFoundView = AnyView(view)
    }

    // MARK: - Navigation

    /// Navigates to a URL path.
    ///
    /// - Parameters:
    ///   - path: The URL path to navigate to
    ///   - mode: Navigation mode (push or replace, defaults to push)
    ///   - animated: Whether to animate the transition (currently unused)
    public func navigate(
        to path: String,
        mode: NavigationMode = .push,
        animated: Bool = true
    ) {
        // Check navigation interceptor
        if let interceptor = navigationInterceptor {
            guard interceptor(path) else { return }
        }

        isNavigating = true

        // Find matching route
        guard let (route, parameters) = routes.findMatch(for: path) else {
            handleUnmatchedRoute(path, mode: mode)
            return
        }

        // Update state
        currentPath = path
        currentParameters = parameters
        currentView = route.invoke(with: parameters)

        // Update browser history
        switch mode {
        case .push:
            history.pushState(path: path, state: parameters.pathParams())
        case .replace:
            history.replaceState(path: path, state: parameters.pathParams())
        }

        isNavigating = false
    }

    /// Navigates back in history.
    public func back() {
        history.back()
        // The popstate listener will handle updating the current view
    }

    /// Navigates forward in history.
    public func forward() {
        history.forward()
        // The popstate listener will handle updating the current view
    }

    /// Navigates to a specific position in history.
    ///
    /// - Parameter delta: Number of steps (negative for back, positive for forward)
    public func go(_ delta: Int) {
        history.go(delta)
    }

    // MARK: - Initial URL Handling

    /// Handles the initial URL when the app launches.
    ///
    /// Call this method after registering all routes to process any deep link
    /// or initial URL.
    ///
    /// - Returns: True if an initial URL was handled, false otherwise
    @discardableResult
    public func handleInitialURL() -> Bool {
        let initialPath = history.getCurrentPath()

        // If we're at root and no routes registered, nothing to do
        if initialPath == "/" && routes.isEmpty {
            return false
        }

        // Try to process as deep link
        let result = deepLinkHandler.process(url: initialPath)

        switch result {
        case .success(let path, let parameters):
            // Navigate without pushing to history (we're already there)
            handleSuccessfulDeepLink(path: path, parameters: parameters)
            return true

        case .requiresAuthentication(let path):
            // Handle authentication requirement
            handleAuthenticationRequired(for: path)
            return true

        case .redirect(let redirectPath):
            // Handle redirect
            navigate(to: redirectPath, mode: .replace)
            return true

        case .failure:
            // Try normal route matching
            if let (route, parameters) = routes.findMatch(for: initialPath) {
                currentPath = initialPath
                currentParameters = parameters
                currentView = route.invoke(with: parameters)
                return true
            }

            // Show not found view
            if let notFoundView = notFoundView {
                currentPath = initialPath
                currentView = notFoundView
                return true
            }

            return false
        }
    }

    // MARK: - History Listener

    /// Sets up the browser history popstate listener.
    private func setupHistoryListener() {
        history.onPopState { [weak self] state in
            guard let self = self else { return }

            let path = state.path

            // Find matching route
            if let (route, parameters) = self.routes.findMatch(for: path) {
                self.currentPath = path
                self.currentParameters = parameters
                self.currentView = route.invoke(with: parameters)
            } else {
                // Show not found view
                if let notFoundView = self.notFoundView {
                    self.currentPath = path
                    self.currentView = notFoundView
                }
            }
        }
    }

    // MARK: - Unmatched Route Handling

    /// Handles navigation to an unmatched route.
    private func handleUnmatchedRoute(_ path: String, mode: NavigationMode) {
        currentPath = path
        currentParameters = RouteParameters()

        if let notFoundView = notFoundView {
            currentView = notFoundView
        } else {
            // Create a default not found view
            currentView = AnyView(
                Text("404 - Not Found")
                    .font(.title)
            )
        }

        // Still update history for consistency
        switch mode {
        case .push:
            history.pushState(path: path)
        case .replace:
            history.replaceState(path: path)
        }

        isNavigating = false
    }

    // MARK: - Deep Link Handling

    /// Handles a successful deep link.
    private func handleSuccessfulDeepLink(path: String, parameters: RouteParameters) {
        if let (route, _) = routes.findMatch(for: path) {
            currentPath = path
            currentParameters = parameters
            currentView = route.invoke(with: parameters)
        }
    }

    /// Handles authentication required scenario.
    private func handleAuthenticationRequired(for path: String) {
        // Store the intended destination
        // Navigate to login/auth view
        // This is a placeholder - actual implementation depends on auth system
        currentPath = "/auth/login"
        currentParameters = RouteParameters(queryParameters: ["redirect": path])
    }

    // MARK: - Navigation Interception

    /// Sets a navigation interceptor.
    ///
    /// The interceptor can block navigation by returning false.
    /// Useful for implementing guards, confirmations, or auth checks.
    ///
    /// - Parameter interceptor: Closure that receives the destination path and returns whether to proceed
    public func setNavigationInterceptor(
        _ interceptor: @escaping @Sendable @MainActor (String) -> Bool
    ) {
        self.navigationInterceptor = interceptor
    }

    /// Removes the navigation interceptor.
    public func removeNavigationInterceptor() {
        self.navigationInterceptor = nil
    }

    // MARK: - Route Information

    /// Gets all registered routes.
    ///
    /// - Returns: Array of registered route paths
    public func getRegisteredRoutes() -> [String] {
        routes.map { $0.path }
    }

    /// Checks if a route is registered for the given path.
    ///
    /// - Parameter path: The path to check
    /// - Returns: True if a matching route exists
    public func hasRoute(for path: String) -> Bool {
        routes.findMatch(for: path) != nil
    }

    /// Checks if we can navigate back.
    ///
    /// - Returns: True if there's history to go back to
    public func canGoBack() -> Bool {
        // This is a simplified check
        // In a real implementation, we'd query the history state
        return currentPath != "/"
    }

    /// Checks if we can navigate forward.
    ///
    /// - Returns: True if there's history to go forward to
    public func canGoForward() -> Bool {
        // This is a simplified check
        // In a real implementation, we'd query the history state
        false
    }
}

// MARK: - Environment Integration

/// Environment key for accessing the router.
private struct RouterKey: EnvironmentKey {
    static let defaultValue: Router? = nil
}

extension EnvironmentValues {
    /// The current router instance.
    ///
    /// Use this to access the router from within views:
    /// ```swift
    /// @Environment(\.router) var router
    ///
    /// Button("Navigate") {
    ///     router?.navigate(to: "/products")
    /// }
    /// ```
    public var router: Router? {
        get { self[RouterKey.self] }
        set { self[RouterKey.self] = newValue }
    }
}

// MARK: - View Extension

extension View {
    /// Injects a router into the environment.
    ///
    /// - Parameter router: The router to inject
    /// - Returns: A view with the router in its environment
    @MainActor
    public func router(_ router: Router) -> some View {
        environment(\.router, router)
    }
}
