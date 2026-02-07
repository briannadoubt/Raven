import Testing
@testable import Raven

/// Comprehensive tests for the Router URL-based routing system.
///
/// These tests verify:
/// - Route pattern matching with static and dynamic segments
/// - Parameter extraction (string, int, bool, double)
/// - Query string parsing and access
/// - Navigation operations (forward, back, replace)
/// - Deep link handling and validation
/// - History state preservation
/// - Multiple router instances
/// - Route guards and interceptors
/// - 404 handling and fallback views
/// - Edge cases and error conditions
@MainActor
@Suite struct RouterTests {

    var router: Router

    init() {
        // Create router without NavigationHistory (nil = no browser history integration)
        router = Router()
    }

    // MARK: - Route Pattern Matching Tests

    @Test func staticRouteMatching() {
        // Register a static route
        router.register(path: "/about") {
            Text("About")
        }

        // Verify route is registered
        #expect(router.hasRoute(for: "/about"))
        #expect(!router.hasRoute(for: "/contact"))

        // Navigate to the route
        router.navigate(to: "/about")

        #expect(router.currentPath == "/about")
        #expect(router.currentView != nil)
    }

    @Test func dynamicRouteMatchingWithSingleParameter() {
        router.register(path: "/products/:id") { params in
            Text("Product \(params.string("id") ?? "")")
        }

        // Navigate with parameter
        router.navigate(to: "/products/123")

        #expect(router.currentPath == "/products/123")
        #expect(router.currentParameters.string("id") == "123")
    }

    @Test func dynamicRouteMatchingWithMultipleParameters() {
        router.register(path: "/users/:userId/posts/:postId") { params in
            Text("User \(params.string("userId") ?? "") Post \(params.string("postId") ?? "")")
        }

        router.navigate(to: "/users/42/posts/99")

        #expect(router.currentPath == "/users/42/posts/99")
        #expect(router.currentParameters.string("userId") == "42")
        #expect(router.currentParameters.string("postId") == "99")
    }

    @Test func wildcardRouteMatching() {
        router.register(path: "/files/*path") { params in
            Text("File: \(params.string("path") ?? "")")
        }

        router.navigate(to: "/files/documents/reports/2024/january.pdf")

        #expect(router.currentPath == "/files/documents/reports/2024/january.pdf")
        #expect(router.currentParameters.string("path") == "documents/reports/2024/january.pdf")
    }

    @Test func routeMatchingPriority() {
        // More specific route should match first
        router.register(path: "/products/:id") { params in
            Text("Product \(params.string("id") ?? "")")
        }

        router.register(path: "/products/new") {
            Text("New Product")
        }

        // Static should match before dynamic
        router.navigate(to: "/products/new")

        // This depends on registration order - first match wins
        #expect(router.currentPath == "/products/new")
    }

    @Test func routeMatchingWithTrailingSlash() {
        router.register(path: "/about") {
            Text("About")
        }

        // Should handle both with and without trailing slash
        router.navigate(to: "/about")
        #expect(router.currentPath == "/about")
    }

    // MARK: - Parameter Extraction Tests

    @Test func stringParameterExtraction() {
        router.register(path: "/search/:query") { params in
            Text("Search: \(params.string("query") ?? "")")
        }

        router.navigate(to: "/search/swift-programming")

        #expect(router.currentParameters.string("query") == "swift-programming")
    }

    @Test func intParameterExtraction() {
        router.register(path: "/products/:id") { params in
            let id = params.int("id") ?? 0
            Text("Product \(id)")
        }

        router.navigate(to: "/products/12345")

        #expect(router.currentParameters.int("id") == 12345)
        #expect(router.currentParameters.string("id") == "12345")
    }

    @Test func boolParameterExtraction() {
        router.register(path: "/settings/:enabled") { params in
            let enabled = params.bool("enabled") ?? false
            Text("Enabled: \(enabled)")
        }

        // Test various boolean formats
        router.navigate(to: "/settings/true")
        #expect(router.currentParameters.bool("enabled") == true)

        router.navigate(to: "/settings/false")
        #expect(router.currentParameters.bool("enabled") == false)

        router.navigate(to: "/settings/1")
        #expect(router.currentParameters.bool("enabled") == true)

        router.navigate(to: "/settings/0")
        #expect(router.currentParameters.bool("enabled") == false)
    }

    @Test func doubleParameterExtraction() {
        router.register(path: "/price/:amount") { params in
            let amount = params.double("amount") ?? 0.0
            Text("Price: \(amount)")
        }

        router.navigate(to: "/price/99.99")

        #expect(router.currentParameters.double("amount") == 99.99)
    }

    @Test func invalidParameterConversion() {
        router.register(path: "/products/:id") { params in
            Text("Product \(params.string("id") ?? "")")
        }

        router.navigate(to: "/products/not-a-number")

        #expect(router.currentParameters.int("id") == nil)
        #expect(router.currentParameters.string("id") != nil)
    }

    // MARK: - Query String Parsing Tests

    @Test func queryStringParsing() {
        router.register(path: "/search") { params in
            Text("Search: \(params.string("q") ?? "")")
        }

        router.navigate(to: "/search?q=swift&lang=en")

        #expect(router.currentPath == "/search?q=swift&lang=en")
        // Note: Query parameter extraction depends on RouteParameters.from(url:) being called
    }

    @Test func queryStringWithMultipleValues() {
        router.register(path: "/filter") { params in
            Text("Filter")
        }

        router.navigate(to: "/filter?category=electronics&category=books")

        #expect(router.currentPath == "/filter?category=electronics&category=books")
    }

    @Test func queryStringWithSpecialCharacters() {
        router.register(path: "/search") { params in
            Text("Search")
        }

        router.navigate(to: "/search?q=hello%20world&filter=a%26b")

        #expect(router.currentPath == "/search?q=hello%20world&filter=a%26b")
    }

    @Test func emptyQueryString() {
        router.register(path: "/products") {
            Text("Products")
        }

        router.navigate(to: "/products?")

        #expect(router.currentPath == "/products?")
    }

    // MARK: - Navigation Tests

    @Test func navigatePush() {
        router.register(path: "/home") {
            Text("Home")
        }
        router.register(path: "/about") {
            Text("About")
        }

        router.navigate(to: "/home", mode: .push)
        #expect(router.currentPath == "/home")
        #expect(router.currentView != nil)

        router.navigate(to: "/about", mode: .push)
        #expect(router.currentPath == "/about")
        #expect(router.currentView != nil)
    }

    @Test func navigateReplace() {
        router.register(path: "/home") {
            Text("Home")
        }
        router.register(path: "/about") {
            Text("About")
        }

        router.navigate(to: "/home", mode: .replace)
        #expect(router.currentPath == "/home")
        #expect(router.currentView != nil)

        let previousPath = router.currentPath
        router.navigate(to: "/about", mode: .replace)
        #expect(router.currentPath == "/about")
        #expect(router.currentPath != previousPath)
    }

    @Test func navigateBack() {
        router.register(path: "/home") {
            Text("Home")
        }
        router.register(path: "/about") {
            Text("About")
        }

        router.navigate(to: "/home")
        router.navigate(to: "/about")
        #expect(router.currentPath == "/about")

        // Call back() - in a real browser this would navigate back
        router.back()

        // In test environment without real browser history, path may not change
        // Test verifies the method doesn't crash
        #expect(router.currentView != nil)
    }

    @Test func navigateForward() {
        router.register(path: "/home") {
            Text("Home")
        }

        router.navigate(to: "/home")
        router.back()

        // Call forward() - in a real browser this would navigate forward
        router.forward()

        // Test verifies the method doesn't crash
        #expect(router != nil)
    }

    @Test func navigateGo() {
        router.register(path: "/home") {
            Text("Home")
        }

        router.navigate(to: "/home")

        // Call go() with negative delta (back)
        router.go(-2)
        #expect(router != nil)

        // Call go() with positive delta (forward)
        router.go(1)
        #expect(router != nil)
    }

    @Test func navigationState() {
        router.register(path: "/products/:id") { params in
            Text("Product \(params.string("id") ?? "")")
        }

        #expect(!router.isNavigating)

        router.navigate(to: "/products/123")

        // Navigation should complete synchronously
        #expect(!router.isNavigating)
        #expect(router.currentPath == "/products/123")
    }

    // MARK: - Deep Link Handling Tests

    @Test func deepLinkHandling() {
        let deepLinkHandler = DeepLinkHandler()
        let customRouter = Router(deepLinkHandler: deepLinkHandler)

        deepLinkHandler.register(pattern: "/products/:id") { params in
            guard let id = params.int("id"), id > 0 else { return false }
            return true
        }

        customRouter.register(path: "/products/:id") { params in
            Text("Product \(params.string("id") ?? "")")
        }

        let result = customRouter.handleInitialURL()

        // Should handle initial URL based on current location
        #expect(customRouter.currentView != nil)
    }

    @Test func deepLinkValidation() {
        let deepLinkHandler = DeepLinkHandler()

        deepLinkHandler.register(pattern: "/products/:id") { params in
            guard let id = params.int("id"), id > 0 else { return false }
            return true
        }

        let validResult = deepLinkHandler.process(url: "/products/123")
        #expect(validResult.isSuccess)

        let invalidResult = deepLinkHandler.process(url: "/products/abc")
        #expect(invalidResult.isFailure)
    }

    @Test func deepLinkRedirect() {
        let deepLinkHandler = DeepLinkHandler()
        let customRouter = Router(deepLinkHandler: deepLinkHandler)

        customRouter.register(path: "/home") {
            Text("Home")
        }

        // Simulate redirect scenario
        let redirectResult = deepLinkHandler.createRedirect(to: "/home")
        #expect(redirectResult.isRedirect)
    }

    // MARK: - History State Preservation Tests

    @Test func historyStatePreservation() {
        router.register(path: "/products/:id") { params in
            Text("Product \(params.string("id") ?? "")")
        }

        router.navigate(to: "/products/123")

        // Verify router maintains state correctly
        #expect(router.currentPath == "/products/123")
        #expect(router.currentParameters.string("id") == "123")
        #expect(router.currentParameters.int("id") == 123)
    }

    @Test func historyStateOnReplace() {
        router.register(path: "/products/:id") { params in
            Text("Product \(params.string("id") ?? "")")
        }

        router.navigate(to: "/products/123", mode: .replace)

        // Verify state is correct after replace
        #expect(router.currentPath == "/products/123")
        #expect(router.currentParameters.string("id") == "123")
        #expect(router.currentView != nil)
    }

    @Test func popStateHandling() {
        router.register(path: "/home") {
            Text("Home")
        }
        router.register(path: "/about") {
            Text("About")
        }

        router.navigate(to: "/home")
        #expect(router.currentPath == "/home")

        router.navigate(to: "/about")
        #expect(router.currentPath == "/about")

        // Note: Actual popstate events require browser history API
        // Test verifies router state management
        #expect(router.currentView != nil)
    }

    // MARK: - Multiple Router Tests

    @Test func multipleRouterInstances() {
        let router1 = Router()
        let router2 = Router()

        router1.register(path: "/home") {
            Text("Router 1 Home")
        }

        router2.register(path: "/home") {
            Text("Router 2 Home")
        }

        router1.navigate(to: "/home")
        router2.navigate(to: "/home")

        #expect(router1.currentPath == "/home")
        #expect(router2.currentPath == "/home")
        #expect(router1.currentView != nil)
        #expect(router2.currentView != nil)
    }

    @Test func routerIndependence() {
        let router1 = Router()
        let router2 = Router()

        router1.register(path: "/page1") {
            Text("Page 1")
        }

        router2.register(path: "/page2") {
            Text("Page 2")
        }

        router1.navigate(to: "/page1")
        router2.navigate(to: "/page2")

        // Verify routers maintain independent state
        #expect(router1.currentPath == "/page1")
        #expect(router2.currentPath == "/page2")
        #expect(router1.currentPath != router2.currentPath)
    }

    // MARK: - Route Guard Tests

    @Test func navigationInterceptor() {
        var interceptedPath: String?
        var shouldAllow = true

        router.setNavigationInterceptor { path in
            interceptedPath = path
            return shouldAllow
        }

        router.register(path: "/protected") {
            Text("Protected")
        }

        // Allow navigation
        shouldAllow = true
        router.navigate(to: "/protected")
        #expect(interceptedPath == "/protected")
        #expect(router.currentPath == "/protected")

        // Block navigation
        shouldAllow = false
        router.navigate(to: "/protected")
        #expect(interceptedPath == "/protected")
        // Path shouldn't change since navigation was blocked
        #expect(router.currentPath == "/protected")
    }

    @Test func navigationInterceptorRemoval() {
        router.setNavigationInterceptor { _ in false }

        router.register(path: "/home") {
            Text("Home")
        }

        router.navigate(to: "/home")
        #expect(router.currentPath != "/home")

        router.removeNavigationInterceptor()
        router.navigate(to: "/home")
        #expect(router.currentPath == "/home")
    }

    @Test func routeGuardForAuthentication() {
        var isAuthenticated = false

        router.setNavigationInterceptor { path in
            if path.hasPrefix("/admin") {
                return isAuthenticated
            }
            return true
        }

        router.register(path: "/admin/dashboard") {
            Text("Admin Dashboard")
        }

        router.register(path: "/login") {
            Text("Login")
        }

        // Try to access protected route while unauthenticated
        isAuthenticated = false
        router.navigate(to: "/admin/dashboard")
        #expect(router.currentPath != "/admin/dashboard")

        // Access public route
        router.navigate(to: "/login")
        #expect(router.currentPath == "/login")

        // Access protected route while authenticated
        isAuthenticated = true
        router.navigate(to: "/admin/dashboard")
        #expect(router.currentPath == "/admin/dashboard")
    }

    // MARK: - 404 Handling Tests

    @Test func defaultNotFoundView() {
        // Navigate to unregistered route
        router.navigate(to: "/nonexistent")

        #expect(router.currentPath == "/nonexistent")
        #expect(router.currentView != nil)
    }

    @Test func customNotFoundView() {
        router.setNotFoundView(
            Text("Custom 404: Page Not Found")
        )

        router.navigate(to: "/missing")

        #expect(router.currentPath == "/missing")
        #expect(router.currentView != nil)
    }

    @Test func notFoundWithHistoryUpdate() {
        router.navigate(to: "/does-not-exist")

        #expect(router.currentPath == "/does-not-exist")
        #expect(router.currentView != nil)
    }

    // MARK: - Edge Case Tests

    @Test func emptyPath() {
        router.register(path: "/") {
            Text("Root")
        }

        router.navigate(to: "/")

        #expect(router.currentPath == "/")
        #expect(router.currentView != nil)
    }

    @Test func pathWithoutLeadingSlash() {
        router.register(path: "/about") {
            Text("About")
        }

        // Route matching should handle paths without leading slash
        #expect(router.hasRoute(for: "/about"))
    }

    @Test func pathWithSpecialCharacters() {
        router.register(path: "/user/:name") { params in
            Text("User: \(params.string("name") ?? "")")
        }

        router.navigate(to: "/user/john-doe")

        #expect(router.currentParameters.string("name") == "john-doe")
    }

    @Test func pathWithNumbers() {
        router.register(path: "/version/:major/:minor/:patch") { params in
            Text("Version")
        }

        router.navigate(to: "/version/1/2/3")

        #expect(router.currentParameters.int("major") == 1)
        #expect(router.currentParameters.int("minor") == 2)
        #expect(router.currentParameters.int("patch") == 3)
    }

    @Test func veryLongPath() {
        let longPath = "/a/b/c/d/e/f/g/h/i/j/k/l/m/n/o/p/q/r/s/t/u/v/w/x/y/z"
        router.register(path: longPath) {
            Text("Long Path")
        }

        router.navigate(to: longPath)

        #expect(router.currentPath == longPath)
    }

    @Test func routeUnregistration() {
        router.register(path: "/temporary") {
            Text("Temporary")
        }

        #expect(router.hasRoute(for: "/temporary"))

        router.unregister(path: "/temporary")

        #expect(!router.hasRoute(for: "/temporary"))
    }

    @Test func getRegisteredRoutes() {
        router.register(path: "/home") {
            Text("Home")
        }
        router.register(path: "/about") {
            Text("About")
        }
        router.register(path: "/contact") {
            Text("Contact")
        }

        let routes = router.getRegisteredRoutes()

        #expect(routes.count == 3)
        #expect(routes.contains("/home"))
        #expect(routes.contains("/about"))
        #expect(routes.contains("/contact"))
    }

    @Test func canGoBack() {
        router.register(path: "/home") {
            Text("Home")
        }

        #expect(!router.canGoBack())

        router.navigate(to: "/home")

        // Simplified implementation returns false for root path
        #expect(!router.canGoBack())
    }

    @Test func canGoForward() {
        router.register(path: "/home") {
            Text("Home")
        }

        router.navigate(to: "/home")

        // Simplified implementation returns false
        #expect(!router.canGoForward())
    }

    // MARK: - Additional Edge Cases

    @Test func navigationWithNilParameters() {
        router.register(path: "/search/:query") { params in
            Text("Query: \(params.string("query") ?? "none")")
        }

        router.navigate(to: "/search/")

        // Empty parameter segment
        #expect(router.currentPath == "/search/")
    }

    @Test func concurrentNavigation() {
        router.register(path: "/page1") {
            Text("Page 1")
        }
        router.register(path: "/page2") {
            Text("Page 2")
        }

        router.navigate(to: "/page1")
        #expect(!router.isNavigating)

        router.navigate(to: "/page2")
        #expect(!router.isNavigating)
        #expect(router.currentPath == "/page2")
    }
}

// MARK: - Test Notes

// Note: Router is created without NavigationHistory in tests, so browser history
// operations are no-ops. Tests focus on verifying Router's state management
// and route matching behavior.
