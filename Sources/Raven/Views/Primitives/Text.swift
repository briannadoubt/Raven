import Foundation

/// A view that displays one or more lines of read-only text.
///
/// `Text` is a primitive view that renders directly to a text node in the virtual DOM.
/// It supports both static strings and localized string keys for internationalization.
///
/// ## Overview
///
/// Use `Text` to display strings and formatted text in your views. Text views
/// are immutable and can be styled using view modifiers like `.font()`,
/// `.foregroundColor()`, and `.padding()`.
///
/// ## Basic Usage
///
/// Create a text view with a string literal:
///
/// ```swift
/// Text("Hello, World!")
/// ```
///
/// ## String Interpolation
///
/// Use string interpolation to display dynamic content:
///
/// ```swift
/// let name = "Alice"
/// let count = 5
/// Text("Hello, \(name)! You have \(count) messages.")
/// ```
///
/// ## Localization
///
/// Use localized string keys for internationalization:
///
/// ```swift
/// Text("welcome_message")
/// Text("items_count")
/// ```
///
/// ## Styling Text
///
/// Apply modifiers to customize text appearance:
///
/// ```swift
/// Text("Important")
///     .font(.title)
///     .foregroundColor(.red)
///     .bold()
///
/// Text("Subtle message")
///     .font(.caption)
///     .foregroundColor(.gray)
/// ```
///
/// ## Combining Text Views
///
/// While `Text` views can't be concatenated in Raven (unlike SwiftUI),
/// you can combine them in layout containers:
///
/// ```swift
/// HStack {
///     Text("Hello,")
///     Text(name).bold()
/// }
/// ```
///
/// ## Common Patterns
///
/// **Display user data:**
/// ```swift
/// struct ProfileView: View {
///     let user: User
///
///     var body: some View {
///         VStack {
///             Text(user.name)
///                 .font(.title)
///             Text(user.email)
///                 .font(.subheadline)
///                 .foregroundColor(.secondary)
///         }
///     }
/// }
/// ```
///
/// **Conditional text:**
/// ```swift
/// @State private var count = 0
///
/// var body: some View {
///     Text(count == 0 ? "No items" : "\(count) items")
/// }
/// ```
///
/// ## See Also
///
/// - ``Font``
/// - ``Color``
/// - ``LocalizedStringKey``
///
/// Because `Text` is a primitive view with `Body == Never`, it converts directly
/// to a VNode without further composition.
public struct Text: View, Sendable {
    public typealias Body = Never

    /// The string content to display
    private let content: String

    /// Storage for whether this text uses a localized string key
    private let isLocalized: Bool

    // MARK: - Initializers

    /// Creates a text view that displays a string literal.
    ///
    /// - Parameter content: The string to display.
    public init(_ content: String) {
        self.content = content
        self.isLocalized = false
    }

    /// Creates a text view that displays localized content.
    ///
    /// - Parameter key: The localized string key to look up in the string table.
    public init(_ key: LocalizedStringKey) {
        // For now, extract the string from the key
        // In a full implementation, this would perform localization lookup
        self.content = key.stringValue
        self.isLocalized = true
    }

    /// Creates a text view from a string interpolation.
    ///
    /// This enables Text to work naturally with Swift's string interpolation:
    /// ```swift
    /// let name = "Alice"
    /// Text("Hello, \(name)!")
    /// ```
    public init(verbatim content: String) {
        self.content = content
        self.isLocalized = false
    }

    // MARK: - Internal Access

    /// Provides access to the text content for internal use.
    ///
    /// This is used by other components like Picker to extract the text
    /// content for rendering purposes.
    internal var textContent: String {
        content
    }

    // MARK: - VNode Conversion

    /// Converts this Text view to a virtual DOM node.
    ///
    /// This method is used internally by the rendering system to convert
    /// the Text primitive into its VNode representation.
    ///
    /// - Returns: A text-type VNode containing the string content.
    @MainActor public func toVNode() -> VNode {
        VNode.text(content)
    }
}

// MARK: - ExpressibleByStringLiteral

extension Text: ExpressibleByStringLiteral {
    /// Creates a text view from a string literal.
    ///
    /// This enables Text to be created directly from string literals:
    /// ```swift
    /// let text: Text = "Hello, World!"
    /// ```
    public init(stringLiteral value: String) {
        self.init(value)
    }
}

// MARK: - ExpressibleByStringInterpolation

extension Text: ExpressibleByStringInterpolation {
    /// String interpolation type for Text
    public struct StringInterpolation: StringInterpolationProtocol, Sendable {
        var output: String = ""

        public init(literalCapacity: Int, interpolationCount: Int) {
            output.reserveCapacity(literalCapacity)
        }

        public mutating func appendLiteral(_ literal: String) {
            output.append(literal)
        }

        public mutating func appendInterpolation<T>(_ value: T) where T: CustomStringConvertible {
            output.append(value.description)
        }

        public mutating func appendInterpolation<T>(_ value: T) {
            output.append(String(describing: value))
        }
    }

    /// Creates a text view from a string interpolation.
    ///
    /// This enables natural string interpolation with Text:
    /// ```swift
    /// let count = 5
    /// Text("You have \(count) items")
    /// ```
    public init(stringInterpolation: StringInterpolation) {
        self.init(verbatim: stringInterpolation.output)
    }
}

// MARK: - LocalizedStringKey

/// A key for looking up localized strings.
///
/// This is a simplified version that stores the key string.
/// In a full implementation, this would integrate with the localization system.
public struct LocalizedStringKey: Sendable, ExpressibleByStringLiteral {
    internal let stringValue: String

    public init(_ value: String) {
        self.stringValue = value
    }

    public init(stringLiteral value: String) {
        self.stringValue = value
    }
}
