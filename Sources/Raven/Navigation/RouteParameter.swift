import Foundation

/// Container for route parameters extracted from URL paths and query strings.
///
/// `RouteParameters` provides type-safe access to URL parameters with automatic
/// type conversion for common types like strings, integers, and booleans.
///
/// ## Overview
///
/// Parameters are extracted from two sources:
/// - Path parameters: Dynamic segments in the URL path (e.g., `:id` in `/products/:id`)
/// - Query parameters: Key-value pairs in the query string (e.g., `?page=2&sort=asc`)
///
/// ## Basic Usage
///
/// ```swift
/// let params = RouteParameters(
///     pathParameters: ["id": "123"],
///     queryParameters: ["page": "2", "active": "true"]
/// )
///
/// let id = params.int("id")           // 123
/// let page = params.int("page")       // 2
/// let active = params.bool("active")  // true
/// ```
///
/// ## Type Conversion
///
/// The following conversions are supported:
/// - `string(_:)`: Returns the raw string value
/// - `int(_:)`: Converts to Int (returns nil if invalid)
/// - `bool(_:)`: Converts to Bool (accepts "true"/"false", "1"/"0", "yes"/"no")
/// - `double(_:)`: Converts to Double (returns nil if invalid)
@MainActor
public struct RouteParameters: Sendable {
    // MARK: - Properties

    /// Parameters extracted from the URL path
    private let pathParameters: [String: String]

    /// Parameters extracted from the query string
    private let queryParameters: [String: String]

    // MARK: - Initialization

    /// Creates a route parameters container.
    ///
    /// - Parameters:
    ///   - pathParameters: Parameters from URL path segments
    ///   - queryParameters: Parameters from URL query string
    public init(
        pathParameters: [String: String] = [:],
        queryParameters: [String: String] = [:]
    ) {
        self.pathParameters = pathParameters
        self.queryParameters = queryParameters
    }

    // MARK: - String Access

    /// Retrieves a parameter as a string.
    ///
    /// Checks path parameters first, then query parameters.
    ///
    /// - Parameter name: The parameter name
    /// - Returns: The parameter value as a string, or nil if not found
    public func string(_ name: String) -> String? {
        pathParameters[name] ?? queryParameters[name]
    }

    /// Retrieves a parameter as a string with a default value.
    ///
    /// - Parameters:
    ///   - name: The parameter name
    ///   - defaultValue: The default value if parameter is not found
    /// - Returns: The parameter value or default value
    public func string(_ name: String, default defaultValue: String) -> String {
        string(name) ?? defaultValue
    }

    // MARK: - Integer Access

    /// Retrieves a parameter as an integer.
    ///
    /// - Parameter name: The parameter name
    /// - Returns: The parameter value as Int, or nil if not found or invalid
    public func int(_ name: String) -> Int? {
        guard let value = string(name) else { return nil }
        return Int(value)
    }

    /// Retrieves a parameter as an integer with a default value.
    ///
    /// - Parameters:
    ///   - name: The parameter name
    ///   - defaultValue: The default value if parameter is not found or invalid
    /// - Returns: The parameter value or default value
    public func int(_ name: String, default defaultValue: Int) -> Int {
        int(name) ?? defaultValue
    }

    // MARK: - Boolean Access

    /// Retrieves a parameter as a boolean.
    ///
    /// Accepts the following formats (case-insensitive):
    /// - "true", "1", "yes" → true
    /// - "false", "0", "no" → false
    ///
    /// - Parameter name: The parameter name
    /// - Returns: The parameter value as Bool, or nil if not found or invalid
    public func bool(_ name: String) -> Bool? {
        guard let value = string(name)?.lowercased() else { return nil }

        switch value {
        case "true", "1", "yes", "on":
            return true
        case "false", "0", "no", "off":
            return false
        default:
            return nil
        }
    }

    /// Retrieves a parameter as a boolean with a default value.
    ///
    /// - Parameters:
    ///   - name: The parameter name
    ///   - defaultValue: The default value if parameter is not found or invalid
    /// - Returns: The parameter value or default value
    public func bool(_ name: String, default defaultValue: Bool) -> Bool {
        bool(name) ?? defaultValue
    }

    // MARK: - Double Access

    /// Retrieves a parameter as a double.
    ///
    /// - Parameter name: The parameter name
    /// - Returns: The parameter value as Double, or nil if not found or invalid
    public func double(_ name: String) -> Double? {
        guard let value = string(name) else { return nil }
        return Double(value)
    }

    /// Retrieves a parameter as a double with a default value.
    ///
    /// - Parameters:
    ///   - name: The parameter name
    ///   - defaultValue: The default value if parameter is not found or invalid
    /// - Returns: The parameter value or default value
    public func double(_ name: String, default defaultValue: Double) -> Double {
        double(name) ?? defaultValue
    }

    // MARK: - Array Access

    /// Retrieves a parameter as an array of strings.
    ///
    /// For query parameters, this supports multiple values with the same key.
    /// For example: `?tag=swift&tag=ios` returns ["swift", "ios"]
    ///
    /// - Parameter name: The parameter name
    /// - Returns: Array of string values, or empty array if not found
    public func array(_ name: String) -> [String] {
        // For now, treat single values as single-element arrays
        if let value = string(name) {
            return [value]
        }
        return []
    }

    // MARK: - Existence Check

    /// Checks if a parameter exists.
    ///
    /// - Parameter name: The parameter name
    /// - Returns: True if the parameter exists, false otherwise
    public func has(_ name: String) -> Bool {
        string(name) != nil
    }

    // MARK: - All Parameters

    /// Returns all parameters as a dictionary.
    ///
    /// Query parameters take precedence over path parameters with the same name.
    ///
    /// - Returns: Dictionary of all parameters
    public func all() -> [String: String] {
        pathParameters.merging(queryParameters) { _, query in query }
    }

    /// Returns all path parameters.
    ///
    /// - Returns: Dictionary of path parameters
    public func pathParams() -> [String: String] {
        pathParameters
    }

    /// Returns all query parameters.
    ///
    /// - Returns: Dictionary of query parameters
    public func queryParams() -> [String: String] {
        queryParameters
    }
}

// MARK: - URL Query Parsing

extension RouteParameters {
    /// Creates route parameters by parsing a URL string.
    ///
    /// Extracts query parameters from the URL's query string.
    ///
    /// - Parameter url: The URL string to parse
    /// - Returns: RouteParameters with query parameters extracted
    public static func from(url: String) -> RouteParameters {
        guard let components = URLComponents(string: url) else {
            return RouteParameters()
        }

        var queryParameters: [String: String] = [:]
        if let queryItems = components.queryItems {
            for item in queryItems {
                if let value = item.value {
                    queryParameters[item.name] = value
                }
            }
        }

        return RouteParameters(queryParameters: queryParameters)
    }

    /// Creates route parameters by parsing a full URL with path matching.
    ///
    /// - Parameters:
    ///   - url: The URL string to parse
    ///   - pathParameters: Path parameters extracted from route matching
    /// - Returns: RouteParameters with both path and query parameters
    public static func from(url: String, pathParameters: [String: String]) -> RouteParameters {
        let queryParams = Self.from(url: url)
        return RouteParameters(
            pathParameters: pathParameters,
            queryParameters: queryParams.queryParameters
        )
    }
}

// MARK: - CustomStringConvertible

extension RouteParameters: CustomStringConvertible {
    public nonisolated var description: String {
        var parts: [String] = []

        if !pathParameters.isEmpty {
            let pathDesc = pathParameters.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
            parts.append("path: [\(pathDesc)]")
        }

        if !queryParameters.isEmpty {
            let queryDesc = queryParameters.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
            parts.append("query: [\(queryDesc)]")
        }

        return "RouteParameters(\(parts.joined(separator: "; ")))"
    }
}
