import Foundation

/// Handles deep link processing and validation.
///
/// `DeepLinkHandler` processes incoming URLs and validates them against registered routes,
/// enabling support for deep linking and URL-based app entry points.
///
/// ## Overview
///
/// Deep linking allows users to navigate directly to specific content within your app
/// by opening a URL. This is essential for:
/// - Sharing links to specific content
/// - Email and notification links
/// - Browser bookmarks
/// - SEO and search engine indexing
///
/// ## Basic Usage
///
/// ```swift
/// let handler = DeepLinkHandler()
///
/// // Register a deep link pattern
/// handler.register(pattern: "/products/:id") { params in
///     guard let id = params.int("id") else { return false }
///     // Validate the product ID exists
///     return productExists(id)
/// }
///
/// // Process a deep link
/// if handler.canHandle(url: "/products/123") {
///     let result = handler.process(url: "/products/123")
///     // Handle the result
/// }
/// ```
///
/// ## Validation
///
/// Deep link handlers can validate URLs before processing:
/// - Check parameter formats
/// - Verify resource existence
/// - Enforce authentication requirements
/// - Apply business logic rules
@MainActor
public final class DeepLinkHandler {
    // MARK: - Types

    /// Result of processing a deep link
    public enum ProcessingResult: Sendable {
        /// The deep link was successfully processed
        case success(path: String, parameters: RouteParameters)

        /// The deep link was invalid or couldn't be processed
        case failure(reason: String)

        /// The deep link requires authentication
        case requiresAuthentication(path: String)

        /// The deep link should redirect to a different URL
        case redirect(to: String)
    }

    /// Deep link validator closure
    public typealias Validator = @Sendable @MainActor (RouteParameters) -> Bool

    // MARK: - Properties

    /// Registered deep link patterns and their validators
    private var validators: [String: Validator] = [:]

    /// URL schemes that are allowed for deep linking
    private var allowedSchemes: Set<String> = ["http", "https"]

    /// Base URL for the application (used for relative URL resolution)
    private var baseURL: String = ""

    /// Whether to automatically handle initial URL on app launch
    private var shouldHandleInitialURL: Bool = true

    // MARK: - Initialization

    /// Creates a new deep link handler.
    ///
    /// - Parameters:
    ///   - baseURL: Base URL for the application (e.g., "https://example.com")
    ///   - handleInitialURL: Whether to process the initial URL on app launch
    public init(baseURL: String = "", handleInitialURL: Bool = true) {
        self.baseURL = baseURL
        self.shouldHandleInitialURL = handleInitialURL
    }

    // MARK: - Registration

    /// Registers a deep link pattern with an optional validator.
    ///
    /// - Parameters:
    ///   - pattern: The URL pattern to match (e.g., "/products/:id")
    ///   - validator: Optional closure to validate the parameters
    public func register(
        pattern: String,
        validator: @escaping Validator = { _ in true }
    ) {
        validators[pattern] = validator
    }

    /// Unregisters a deep link pattern.
    ///
    /// - Parameter pattern: The URL pattern to unregister
    public func unregister(pattern: String) {
        validators.removeValue(forKey: pattern)
    }

    /// Registers an allowed URL scheme.
    ///
    /// By default, only "http" and "https" are allowed.
    ///
    /// - Parameter scheme: The URL scheme to allow (e.g., "myapp")
    public func allowScheme(_ scheme: String) {
        allowedSchemes.insert(scheme.lowercased())
    }

    // MARK: - URL Handling

    /// Checks if a URL can be handled by this deep link handler.
    ///
    /// - Parameter url: The URL string to check
    /// - Returns: True if the URL can be handled, false otherwise
    public func canHandle(url: String) -> Bool {
        guard let normalized = normalizeURL(url) else { return false }

        // Extract path
        let path = extractPath(from: normalized)

        // Check if any registered pattern matches
        for pattern in validators.keys {
            let route = Route(path: pattern, view: EmptyView())
            if route.match(path) != nil {
                return true
            }
        }

        return false
    }

    /// Processes a deep link URL.
    ///
    /// - Parameter url: The URL string to process
    /// - Returns: The result of processing the deep link
    public func process(url: String) -> ProcessingResult {
        guard let normalized = normalizeURL(url) else {
            return .failure(reason: "Invalid URL format")
        }

        // Check scheme
        if let scheme = extractScheme(from: normalized) {
            guard allowedSchemes.contains(scheme) else {
                return .failure(reason: "URL scheme '\(scheme)' is not allowed")
            }
        }

        // Extract path
        let path = extractPath(from: normalized)

        // Find matching validator
        for (pattern, validator) in validators {
            let route = Route(path: pattern, view: EmptyView())
            if let parameters = route.match(path) {
                // Validate the parameters
                if validator(parameters) {
                    return .success(path: path, parameters: parameters)
                } else {
                    return .failure(reason: "Validation failed for pattern: \(pattern)")
                }
            }
        }

        return .failure(reason: "No matching route found for path: \(path)")
    }

    /// Processes the initial URL when the app launches.
    ///
    /// Call this method from your app's entry point to handle deep links
    /// that open the app.
    ///
    /// - Parameter currentPath: The current URL path to process (defaults to `NavigationHistory.shared.getCurrentPath()`)
    /// - Returns: The result of processing the initial URL, or nil if none
    public func processInitialURL(currentPath: String? = nil) -> ProcessingResult? {
        guard shouldHandleInitialURL else { return nil }

        let currentPath = currentPath ?? NavigationHistory.shared.getCurrentPath()
        guard !currentPath.isEmpty && currentPath != "/" else {
            return nil
        }

        return process(url: currentPath)
    }

    // MARK: - URL Parsing

    /// Normalizes a URL string.
    ///
    /// - Parameter url: The URL string to normalize
    /// - Returns: Normalized URL string, or nil if invalid
    private func normalizeURL(_ url: String) -> String? {
        // If it's already a full URL, return as-is
        if url.hasPrefix("http://") || url.hasPrefix("https://") {
            return url
        }

        // If it starts with a custom scheme
        if url.contains("://") {
            return url
        }

        // If it's a path, prepend base URL if available
        if url.hasPrefix("/") {
            if !baseURL.isEmpty {
                return baseURL + url
            }
            return url
        }

        // Try to parse as relative path
        if !baseURL.isEmpty {
            return baseURL + "/" + url
        }

        return "/" + url
    }

    /// Extracts the scheme from a URL.
    ///
    /// - Parameter url: The URL string
    /// - Returns: The URL scheme (lowercased), or nil if none
    private func extractScheme(from url: String) -> String? {
        guard let schemeEnd = url.firstIndex(of: ":") else { return nil }
        return String(url[..<schemeEnd]).lowercased()
    }

    /// Extracts the path from a URL.
    ///
    /// - Parameter url: The URL string
    /// - Returns: The URL path component
    private func extractPath(from url: String) -> String {
        // If it's just a path, return as-is
        if url.hasPrefix("/") {
            // Remove query string if present
            if let queryIndex = url.firstIndex(of: "?") {
                return String(url[..<queryIndex])
            }
            return url
        }

        // Parse as full URL
        guard let components = URLComponents(string: url) else {
            return "/"
        }

        return components.path
    }

    // MARK: - Redirection

    /// Creates a redirect result.
    ///
    /// Use this when a deep link should redirect to a different URL.
    ///
    /// - Parameter url: The URL to redirect to
    /// - Returns: A redirect processing result
    public func createRedirect(to url: String) -> ProcessingResult {
        .redirect(to: url)
    }

    /// Creates an authentication required result.
    ///
    /// Use this when a deep link requires the user to be authenticated.
    ///
    /// - Parameter path: The original path that requires authentication
    /// - Returns: An authentication required processing result
    public func requireAuthentication(for path: String) -> ProcessingResult {
        .requiresAuthentication(path: path)
    }
}

// MARK: - Processing Result Extensions

extension DeepLinkHandler.ProcessingResult {
    /// Whether the processing was successful
    public var isSuccess: Bool {
        if case .success = self {
            return true
        }
        return false
    }

    /// Whether the processing failed
    public var isFailure: Bool {
        if case .failure = self {
            return true
        }
        return false
    }

    /// Whether the result requires authentication
    public var requiresAuth: Bool {
        if case .requiresAuthentication = self {
            return true
        }
        return false
    }

    /// Whether the result is a redirect
    public var isRedirect: Bool {
        if case .redirect = self {
            return true
        }
        return false
    }
}

// MARK: - CustomStringConvertible

extension DeepLinkHandler.ProcessingResult: CustomStringConvertible {
    public var description: String {
        switch self {
        case .success(let path, let parameters):
            return "Success(path: \(path), parameters: \(parameters))"
        case .failure(let reason):
            return "Failure(reason: \(reason))"
        case .requiresAuthentication(let path):
            return "RequiresAuthentication(path: \(path))"
        case .redirect(let url):
            return "Redirect(to: \(url))"
        }
    }
}
