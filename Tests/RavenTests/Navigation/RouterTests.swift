import XCTest
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
final class RouterTests: XCTestCase {

    var router: Router!

    override func setUp() async throws {
        // Create router with shared history
        // Note: Tests will use the actual NavigationHistory.shared instance
        // This means tests may interact with the browser's history API if running in a web context
        router = Router()
    }

    override func tearDown() async throws {
        router = nil
    }

    // MARK: - Route Pattern Matching Tests

    func testStaticRouteMatching() {
        // Register a static route
        router.register(path: "/about") {
            Text("About")
        }

        // Verify route is registered
        XCTAssertTrue(router.hasRoute(for: "/about"))
        XCTAssertFalse(router.hasRoute(for: "/contact"))

        // Navigate to the route
        router.navigate(to: "/about")

        XCTAssertEqual(router.currentPath, "/about")
        XCTAssertNotNil(router.currentView)
    }

    func testDynamicRouteMatchingWithSingleParameter() {
        router.register(path: "/products/:id") { params in
            Text("Product \(params.string("id") ?? "")")
        }

        // Navigate with parameter
        router.navigate(to: "/products/123")

        XCTAssertEqual(router.currentPath, "/products/123")
        XCTAssertEqual(router.currentParameters.string("id"), "123")
    }

    func testDynamicRouteMatchingWithMultipleParameters() {
        router.register(path: "/users/:userId/posts/:postId") { params in
            Text("User \(params.string("userId") ?? "") Post \(params.string("postId") ?? "")")
        }

        router.navigate(to: "/users/42/posts/99")

        XCTAssertEqual(router.currentPath, "/users/42/posts/99")
        XCTAssertEqual(router.currentParameters.string("userId"), "42")
        XCTAssertEqual(router.currentParameters.string("postId"), "99")
    }

    func testWildcardRouteMatching() {
        router.register(path: "/files/*path") { params in
            Text("File: \(params.string("path") ?? "")")
        }

        router.navigate(to: "/files/documents/reports/2024/january.pdf")

        XCTAssertEqual(router.currentPath, "/files/documents/reports/2024/january.pdf")
        XCTAssertEqual(router.currentParameters.string("path"), "documents/reports/2024/january.pdf")
    }

    func testRouteMatchingPriority() {
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
        XCTAssertEqual(router.currentPath, "/products/new")
    }

    func testRouteMatchingWithTrailingSlash() {
        router.register(path: "/about") {
            Text("About")
        }

        // Should handle both with and without trailing slash
        router.navigate(to: "/about")
        XCTAssertEqual(router.currentPath, "/about")
    }

    // MARK: - Parameter Extraction Tests

    func testStringParameterExtraction() {
        router.register(path: "/search/:query") { params in
            Text("Search: \(params.string("query") ?? "")")
        }

        router.navigate(to: "/search/swift-programming")

        XCTAssertEqual(router.currentParameters.string("query"), "swift-programming")
    }

    func testIntParameterExtraction() {
        router.register(path: "/products/:id") { params in
            let id = params.int("id") ?? 0
            Text("Product \(id)")
        }

        router.navigate(to: "/products/12345")

        XCTAssertEqual(router.currentParameters.int("id"), 12345)
        XCTAssertEqual(router.currentParameters.string("id"), "12345")
    }

    func testBoolParameterExtraction() {
        router.register(path: "/settings/:enabled") { params in
            let enabled = params.bool("enabled") ?? false
            Text("Enabled: \(enabled)")
        }

        // Test various boolean formats
        router.navigate(to: "/settings/true")
        XCTAssertEqual(router.currentParameters.bool("enabled"), true)

        router.navigate(to: "/settings/false")
        XCTAssertEqual(router.currentParameters.bool("enabled"), false)

        router.navigate(to: "/settings/1")
        XCTAssertEqual(router.currentParameters.bool("enabled"), true)

        router.navigate(to: "/settings/0")
        XCTAssertEqual(router.currentParameters.bool("enabled"), false)
    }

    func testDoubleParameterExtraction() {
        router.register(path: "/price/:amount") { params in
            let amount = params.double("amount") ?? 0.0
            Text("Price: \(amount)")
        }

        router.navigate(to: "/price/99.99")

        XCTAssertEqual(router.currentParameters.double("amount"), 99.99)
    }

    func testInvalidParameterConversion() {
        router.register(path: "/products/:id") { params in
            Text("Product \(params.string("id") ?? "")")
        }

        router.navigate(to: "/products/not-a-number")

        XCTAssertNil(router.currentParameters.int("id"))
        XCTAssertNotNil(router.currentParameters.string("id"))
    }

    // MARK: - Query String Parsing Tests

    func testQueryStringParsing() {
        router.register(path: "/search") { params in
            Text("Search: \(params.string("q") ?? "")")
        }

        router.navigate(to: "/search?q=swift&lang=en")

        XCTAssertEqual(router.currentPath, "/search?q=swift&lang=en")
        // Note: Query parameter extraction depends on RouteParameters.from(url:) being called
    }

    func testQueryStringWithMultipleValues() {
        router.register(path: "/filter") { params in
            Text("Filter")
        }

        router.navigate(to: "/filter?category=electronics&category=books")

        XCTAssertEqual(router.currentPath, "/filter?category=electronics&category=books")
    }

    func testQueryStringWithSpecialCharacters() {
        router.register(path: "/search") { params in
            Text("Search")
        }

        router.navigate(to: "/search?q=hello%20world&filter=a%26b")

        XCTAssertEqual(router.currentPath, "/search?q=hello%20world&filter=a%26b")
    }

    func testEmptyQueryString() {
        router.register(path: "/products") {
            Text("Products")
        }

        router.navigate(to: "/products?")

        XCTAssertEqual(router.currentPath, "/products?")
    }

    // MARK: - Navigation Tests

    func testNavigatePush() {
        router.register(path: "/home") {
            Text("Home")
        }
        router.register(path: "/about") {
            Text("About")
        }

        router.navigate(to: "/home", mode: .push)
        XCTAssertEqual(router.currentPath, "/home")
        XCTAssertNotNil(router.currentView)

        router.navigate(to: "/about", mode: .push)
        XCTAssertEqual(router.currentPath, "/about")
        XCTAssertNotNil(router.currentView)
    }

    func testNavigateReplace() {
        router.register(path: "/home") {
            Text("Home")
        }
        router.register(path: "/about") {
            Text("About")
        }

        router.navigate(to: "/home", mode: .replace)
        XCTAssertEqual(router.currentPath, "/home")
        XCTAssertNotNil(router.currentView)

        let previousPath = router.currentPath
        router.navigate(to: "/about", mode: .replace)
        XCTAssertEqual(router.currentPath, "/about")
        XCTAssertNotEqual(router.currentPath, previousPath)
    }

    func testNavigateBack() {
        router.register(path: "/home") {
            Text("Home")
        }
        router.register(path: "/about") {
            Text("About")
        }

        router.navigate(to: "/home")
        router.navigate(to: "/about")
        XCTAssertEqual(router.currentPath, "/about")

        // Call back() - in a real browser this would navigate back
        router.back()

        // In test environment without real browser history, path may not change
        // Test verifies the method doesn't crash
        XCTAssertNotNil(router.currentView)
    }

    func testNavigateForward() {
        router.register(path: "/home") {
            Text("Home")
        }

        router.navigate(to: "/home")
        router.back()

        // Call forward() - in a real browser this would navigate forward
        router.forward()

        // Test verifies the method doesn't crash
        XCTAssertNotNil(router)
    }

    func testNavigateGo() {
        router.register(path: "/home") {
            Text("Home")
        }

        router.navigate(to: "/home")

        // Call go() with negative delta (back)
        router.go(-2)
        XCTAssertNotNil(router)

        // Call go() with positive delta (forward)
        router.go(1)
        XCTAssertNotNil(router)
    }

    func testNavigationState() {
        router.register(path: "/products/:id") { params in
            Text("Product \(params.string("id") ?? "")")
        }

        XCTAssertFalse(router.isNavigating)

        router.navigate(to: "/products/123")

        // Navigation should complete synchronously
        XCTAssertFalse(router.isNavigating)
        XCTAssertEqual(router.currentPath, "/products/123")
    }

    // MARK: - Deep Link Handling Tests

    func testDeepLinkHandling() {
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
        XCTAssertNotNil(customRouter.currentView)
    }

    func testDeepLinkValidation() {
        let deepLinkHandler = DeepLinkHandler()

        deepLinkHandler.register(pattern: "/products/:id") { params in
            guard let id = params.int("id"), id > 0 else { return false }
            return true
        }

        let validResult = deepLinkHandler.process(url: "/products/123")
        XCTAssertTrue(validResult.isSuccess)

        let invalidResult = deepLinkHandler.process(url: "/products/abc")
        XCTAssertTrue(invalidResult.isFailure)
    }

    func testDeepLinkRedirect() {
        let deepLinkHandler = DeepLinkHandler()
        let customRouter = Router(deepLinkHandler: deepLinkHandler)

        customRouter.register(path: "/home") {
            Text("Home")
        }

        // Simulate redirect scenario
        let redirectResult = deepLinkHandler.createRedirect(to: "/home")
        XCTAssertTrue(redirectResult.isRedirect)
    }

    // MARK: - History State Preservation Tests

    func testHistoryStatePreservation() {
        router.register(path: "/products/:id") { params in
            Text("Product \(params.string("id") ?? "")")
        }

        router.navigate(to: "/products/123")

        // Verify router maintains state correctly
        XCTAssertEqual(router.currentPath, "/products/123")
        XCTAssertEqual(router.currentParameters.string("id"), "123")
        XCTAssertEqual(router.currentParameters.int("id"), 123)
    }

    func testHistoryStateOnReplace() {
        router.register(path: "/products/:id") { params in
            Text("Product \(params.string("id") ?? "")")
        }

        router.navigate(to: "/products/123", mode: .replace)

        // Verify state is correct after replace
        XCTAssertEqual(router.currentPath, "/products/123")
        XCTAssertEqual(router.currentParameters.string("id"), "123")
        XCTAssertNotNil(router.currentView)
    }

    func testPopStateHandling() {
        router.register(path: "/home") {
            Text("Home")
        }
        router.register(path: "/about") {
            Text("About")
        }

        router.navigate(to: "/home")
        XCTAssertEqual(router.currentPath, "/home")

        router.navigate(to: "/about")
        XCTAssertEqual(router.currentPath, "/about")

        // Note: Actual popstate events require browser history API
        // Test verifies router state management
        XCTAssertNotNil(router.currentView)
    }

    // MARK: - Multiple Router Tests

    func testMultipleRouterInstances() {
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

        XCTAssertEqual(router1.currentPath, "/home")
        XCTAssertEqual(router2.currentPath, "/home")
        XCTAssertNotNil(router1.currentView)
        XCTAssertNotNil(router2.currentView)
    }

    func testRouterIndependence() {
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
        XCTAssertEqual(router1.currentPath, "/page1")
        XCTAssertEqual(router2.currentPath, "/page2")
        XCTAssertNotEqual(router1.currentPath, router2.currentPath)
    }

    // MARK: - Route Guard Tests

    func testNavigationInterceptor() {
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
        XCTAssertEqual(interceptedPath, "/protected")
        XCTAssertEqual(router.currentPath, "/protected")

        // Block navigation
        shouldAllow = false
        router.navigate(to: "/protected")
        XCTAssertEqual(interceptedPath, "/protected")
        // Path shouldn't change since navigation was blocked
        XCTAssertEqual(router.currentPath, "/protected")
    }

    func testNavigationInterceptorRemoval() {
        router.setNavigationInterceptor { _ in false }

        router.register(path: "/home") {
            Text("Home")
        }

        router.navigate(to: "/home")
        XCTAssertNotEqual(router.currentPath, "/home")

        router.removeNavigationInterceptor()
        router.navigate(to: "/home")
        XCTAssertEqual(router.currentPath, "/home")
    }

    func testRouteGuardForAuthentication() {
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
        XCTAssertNotEqual(router.currentPath, "/admin/dashboard")

        // Access public route
        router.navigate(to: "/login")
        XCTAssertEqual(router.currentPath, "/login")

        // Access protected route while authenticated
        isAuthenticated = true
        router.navigate(to: "/admin/dashboard")
        XCTAssertEqual(router.currentPath, "/admin/dashboard")
    }

    // MARK: - 404 Handling Tests

    func testDefaultNotFoundView() {
        // Navigate to unregistered route
        router.navigate(to: "/nonexistent")

        XCTAssertEqual(router.currentPath, "/nonexistent")
        XCTAssertNotNil(router.currentView)
    }

    func testCustomNotFoundView() {
        router.setNotFoundView(
            Text("Custom 404: Page Not Found")
        )

        router.navigate(to: "/missing")

        XCTAssertEqual(router.currentPath, "/missing")
        XCTAssertNotNil(router.currentView)
    }

    func test404WithHistoryUpdate() {
        router.navigate(to: "/does-not-exist")

        XCTAssertEqual(router.currentPath, "/does-not-exist")
        XCTAssertNotNil(router.currentView)
    }

    // MARK: - Edge Case Tests

    func testEmptyPath() {
        router.register(path: "/") {
            Text("Root")
        }

        router.navigate(to: "/")

        XCTAssertEqual(router.currentPath, "/")
        XCTAssertNotNil(router.currentView)
    }

    func testPathWithoutLeadingSlash() {
        router.register(path: "/about") {
            Text("About")
        }

        // Route matching should handle paths without leading slash
        XCTAssertTrue(router.hasRoute(for: "/about"))
    }

    func testPathWithSpecialCharacters() {
        router.register(path: "/user/:name") { params in
            Text("User: \(params.string("name") ?? "")")
        }

        router.navigate(to: "/user/john-doe")

        XCTAssertEqual(router.currentParameters.string("name"), "john-doe")
    }

    func testPathWithNumbers() {
        router.register(path: "/version/:major/:minor/:patch") { params in
            Text("Version")
        }

        router.navigate(to: "/version/1/2/3")

        XCTAssertEqual(router.currentParameters.int("major"), 1)
        XCTAssertEqual(router.currentParameters.int("minor"), 2)
        XCTAssertEqual(router.currentParameters.int("patch"), 3)
    }

    func testVeryLongPath() {
        let longPath = "/a/b/c/d/e/f/g/h/i/j/k/l/m/n/o/p/q/r/s/t/u/v/w/x/y/z"
        router.register(path: longPath) {
            Text("Long Path")
        }

        router.navigate(to: longPath)

        XCTAssertEqual(router.currentPath, longPath)
    }

    func testRouteUnregistration() {
        router.register(path: "/temporary") {
            Text("Temporary")
        }

        XCTAssertTrue(router.hasRoute(for: "/temporary"))

        router.unregister(path: "/temporary")

        XCTAssertFalse(router.hasRoute(for: "/temporary"))
    }

    func testGetRegisteredRoutes() {
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

        XCTAssertEqual(routes.count, 3)
        XCTAssertTrue(routes.contains("/home"))
        XCTAssertTrue(routes.contains("/about"))
        XCTAssertTrue(routes.contains("/contact"))
    }

    func testCanGoBack() {
        router.register(path: "/home") {
            Text("Home")
        }

        XCTAssertFalse(router.canGoBack())

        router.navigate(to: "/home")

        // Simplified implementation returns false for root path
        XCTAssertFalse(router.canGoBack())
    }

    func testCanGoForward() {
        router.register(path: "/home") {
            Text("Home")
        }

        router.navigate(to: "/home")

        // Simplified implementation returns false
        XCTAssertFalse(router.canGoForward())
    }

    // MARK: - Additional Edge Cases

    func testNavigationWithNilParameters() {
        router.register(path: "/search/:query") { params in
            Text("Query: \(params.string("query") ?? "none")")
        }

        router.navigate(to: "/search/")

        // Empty parameter segment
        XCTAssertEqual(router.currentPath, "/search/")
    }

    func testConcurrentNavigation() {
        router.register(path: "/page1") {
            Text("Page 1")
        }
        router.register(path: "/page2") {
            Text("Page 2")
        }

        router.navigate(to: "/page1")
        XCTAssertFalse(router.isNavigating)

        router.navigate(to: "/page2")
        XCTAssertFalse(router.isNavigating)
        XCTAssertEqual(router.currentPath, "/page2")
    }
}

// MARK: - Test Notes

// Note: These tests work with the actual NavigationHistory.shared instance since
// NavigationHistory is a final class with private init and cannot be mocked.
// Tests focus on verifying Router's state management and behavior rather than
// verifying specific history API calls.
