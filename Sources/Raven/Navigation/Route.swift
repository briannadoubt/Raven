import Foundation

/// A route definition that matches URL patterns and extracts parameters.
///
/// Routes support pattern matching with dynamic parameters using the `:param` syntax.
/// For example, `/products/:id` matches `/products/123` and extracts `id` as "123".
///
/// ## Overview
///
/// `Route` provides a type-safe way to define URL patterns and their associated handlers.
/// Routes can match static paths, dynamic parameters, and query strings.
///
/// ## Basic Usage
///
/// ```swift
/// let route = Route(path: "/products/:id") { params in
///     ProductDetailView(id: params.int("id") ?? 0)
/// }
/// ```
///
/// ## Pattern Syntax
///
/// - Static segments: `/products`, `/about/team`
/// - Dynamic parameters: `/products/:id`, `/users/:userId/posts/:postId`
/// - Wildcard: `/files/*path` (captures remaining path segments)
///
/// ## Parameter Extraction
///
/// Access parameters through the `RouteParameters` object:
/// ```swift
/// params.string("id")       // String value
/// params.int("id")          // Integer value
/// params.bool("active")     // Boolean value
/// ```
@MainActor
public struct Route: Sendable {
    // MARK: - Properties

    /// The URL path pattern (e.g., "/products/:id")
    public let path: String

    /// Parsed pattern segments for efficient matching
    internal let segments: [PathSegment]

    /// Handler closure that creates a view when the route matches
    private let handler: @Sendable @MainActor (RouteParameters) -> AnyView

    // MARK: - Initialization

    /// Creates a route with a path pattern and view handler.
    ///
    /// - Parameters:
    ///   - path: The URL pattern to match (e.g., "/products/:id")
    ///   - handler: Closure that receives route parameters and returns a view
    public init<Content: View>(
        path: String,
        @ViewBuilder handler: @escaping @Sendable @MainActor (RouteParameters) -> Content
    ) {
        self.path = path
        self.segments = Self.parsePattern(path)
        self.handler = { params in
            AnyView(handler(params))
        }
    }

    /// Creates a route with a path pattern and constant view.
    ///
    /// Use this initializer when the view doesn't need route parameters.
    ///
    /// - Parameters:
    ///   - path: The URL pattern to match
    ///   - view: The view to display for this route
    public init<Content: View>(path: String, view: Content) {
        self.path = path
        self.segments = Self.parsePattern(path)
        self.handler = { _ in AnyView(view) }
    }

    // MARK: - Pattern Matching

    /// Attempts to match a URL path against this route's pattern.
    ///
    /// - Parameter urlPath: The URL path to match (e.g., "/products/123")
    /// - Returns: RouteParameters if the path matches, nil otherwise
    public func match(_ urlPath: String) -> RouteParameters? {
        let pathSegments = Self.parsePathSegments(urlPath)

        // Quick length check (unless we have a wildcard)
        let hasWildcard = segments.contains { $0.isWildcard }
        if !hasWildcard && pathSegments.count != segments.count {
            return nil
        }

        var parameters: [String: String] = [:]
        var wildcardPath: [String] = []
        var segmentIndex = 0

        for (index, segment) in segments.enumerated() {
            switch segment {
            case .static(let value):
                guard segmentIndex < pathSegments.count else { return nil }
                guard pathSegments[segmentIndex] == value else { return nil }
                segmentIndex += 1

            case .parameter(let name):
                guard segmentIndex < pathSegments.count else { return nil }
                parameters[name] = pathSegments[segmentIndex]
                segmentIndex += 1

            case .wildcard(let name):
                // Capture all remaining segments
                wildcardPath = Array(pathSegments[segmentIndex...])
                parameters[name] = wildcardPath.joined(separator: "/")
                segmentIndex = pathSegments.count
                break
            }
        }

        // Ensure we consumed all path segments
        guard segmentIndex == pathSegments.count else { return nil }

        return RouteParameters(pathParameters: parameters, queryParameters: [:])
    }

    /// Invokes the route's handler with the given parameters.
    ///
    /// - Parameter parameters: The extracted route parameters
    /// - Returns: The view created by the route's handler
    public func invoke(with parameters: RouteParameters) -> AnyView {
        handler(parameters)
    }

    // MARK: - Pattern Parsing

    /// Parses a path pattern into segments.
    ///
    /// - Parameter pattern: The path pattern (e.g., "/products/:id")
    /// - Returns: Array of path segments
    internal static func parsePattern(_ pattern: String) -> [PathSegment] {
        let normalized = pattern.hasPrefix("/") ? String(pattern.dropFirst()) : pattern
        guard !normalized.isEmpty else { return [] }

        return normalized.split(separator: "/").map { component in
            let segment = String(component)
            if segment.hasPrefix(":") {
                return .parameter(String(segment.dropFirst()))
            } else if segment.hasPrefix("*") {
                return .wildcard(String(segment.dropFirst()))
            } else {
                return .static(segment)
            }
        }
    }

    /// Parses a URL path into segments.
    ///
    /// - Parameter path: The URL path (e.g., "/products/123")
    /// - Returns: Array of path segments
    internal static func parsePathSegments(_ path: String) -> [String] {
        let normalized = path.hasPrefix("/") ? String(path.dropFirst()) : path
        guard !normalized.isEmpty else { return [] }

        // Remove query string if present
        let pathOnly = normalized.split(separator: "?").first.map(String.init) ?? normalized

        return pathOnly.split(separator: "/").map(String.init)
    }
}

// MARK: - Path Segment

/// Represents a segment of a route pattern.
internal enum PathSegment: Sendable, Equatable {
    /// Static segment that must match exactly (e.g., "products")
    case `static`(String)

    /// Dynamic parameter segment (e.g., ":id")
    case parameter(String)

    /// Wildcard segment that captures remaining path (e.g., "*path")
    case wildcard(String)

    /// Whether this segment is a wildcard
    var isWildcard: Bool {
        if case .wildcard = self {
            return true
        }
        return false
    }
}

// MARK: - Hashable Conformance

extension Route: Hashable {
    public nonisolated static func == (lhs: Route, rhs: Route) -> Bool {
        lhs.path == rhs.path
    }

    public nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(path)
    }
}

// MARK: - Route Collection Extension

extension Array where Element == Route {
    /// Finds the first route that matches the given URL path.
    ///
    /// - Parameter urlPath: The URL path to match
    /// - Returns: Tuple of matching route and extracted parameters, or nil
    @MainActor
    public func findMatch(for urlPath: String) -> (route: Route, parameters: RouteParameters)? {
        for route in self {
            if let parameters = route.match(urlPath) {
                return (route, parameters)
            }
        }
        return nil
    }
}
