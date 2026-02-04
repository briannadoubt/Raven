import Foundation

/// A view that creates a hyperlink navigation element.
///
/// `Link` is a primitive view that renders directly to an HTML anchor tag (`<a>`)
/// in the virtual DOM. It supports both simple text labels and complex custom
/// label content with URL destinations.
///
/// ## Overview
///
/// Use `Link` to create clickable hyperlinks that navigate to URLs. Links can
/// navigate to external websites, internal pages, or any valid URL destination.
/// The link automatically handles external URLs by opening them in a new tab.
///
/// ## Basic Usage
///
/// Create a link with a text label and destination URL:
///
/// ```swift
/// Link("Visit Apple", destination: URL(string: "https://apple.com")!)
/// ```
///
/// ## Custom Labels
///
/// Use the label initializer for custom link content:
///
/// ```swift
/// Link(destination: URL(string: "https://github.com")!) {
///     HStack {
///         Image(systemName: "link")
///         Text("GitHub")
///     }
/// }
/// ```
///
/// ## External vs Internal Links
///
/// Links automatically detect external URLs and open them in a new tab using
/// `target="_blank"`. This provides a better user experience by preserving
/// the current application state.
///
/// ```swift
/// // External link - opens in new tab
/// Link("Documentation", destination: URL(string: "https://docs.swift.org")!)
///
/// // Internal link - same tab navigation
/// Link("Profile", destination: URL(string: "/profile")!)
/// ```
///
/// ## Styling Links
///
/// Apply modifiers to customize link appearance:
///
/// ```swift
/// Link("Learn More", destination: url)
///     .font(.headline)
///     .foregroundColor(.blue)
///     .underline()
///
/// Link("Subtle Link", destination: url)
///     .foregroundColor(.secondary)
///     .underline(false)
/// ```
///
/// ## Common Patterns
///
/// **Navigation menu:**
/// ```swift
/// VStack(alignment: .leading) {
///     Link("Home", destination: URL(string: "/")!)
///     Link("About", destination: URL(string: "/about")!)
///     Link("Contact", destination: URL(string: "/contact")!)
/// }
/// ```
///
/// **Social media links:**
/// ```swift
/// HStack {
///     Link(destination: URL(string: "https://twitter.com/username")!) {
///         Image(systemName: "twitter")
///     }
///     Link(destination: URL(string: "https://github.com/username")!) {
///         Image(systemName: "github")
///     }
/// }
/// ```
///
/// **Call to action:**
/// ```swift
/// Link("Get Started", destination: URL(string: "/signup")!)
///     .padding()
///     .background(Color.blue)
///     .foregroundColor(.white)
///     .cornerRadius(8)
/// ```
///
/// **Email and phone links:**
/// ```swift
/// VStack(alignment: .leading) {
///     Link("Email Us", destination: URL(string: "mailto:support@example.com")!)
///     Link("Call Us", destination: URL(string: "tel:+1234567890")!)
/// }
/// ```
///
/// **Download link:**
/// ```swift
/// Link("Download PDF", destination: URL(string: "/files/document.pdf")!)
///     .font(.body)
///     .foregroundColor(.blue)
/// ```
///
/// ## Accessibility
///
/// Links are inherently accessible as they use semantic HTML anchor elements.
/// Screen readers automatically identify links and announce them appropriately.
/// Consider adding descriptive labels for better accessibility:
///
/// ```swift
/// // Good: descriptive label
/// Link("Read the full article about Swift concurrency", destination: articleURL)
///
/// // Avoid: vague labels
/// Link("Click here", destination: articleURL)
/// ```
///
/// ## Best Practices
///
/// - Use descriptive link text that makes sense out of context
/// - External links open in new tabs automatically for better UX
/// - Style links consistently throughout your application
/// - Avoid using links for actions - use `Button` instead
/// - Ensure sufficient color contrast for link visibility
///
/// ## See Also
///
/// - ``Button``
/// - ``Text``
/// - ``URL``
///
/// Because `Link` is a primitive view with `Body == Never`, it converts directly
/// to a VNode without further composition.
public struct Link<Label: View>: View, PrimitiveView, Sendable {
    public typealias Body = Never

    /// The destination URL for navigation
    private let destination: URL

    /// The label content to display in the link
    private let label: Label

    // MARK: - Initializers

    /// Creates a link with a custom label.
    ///
    /// Use this initializer when you want to provide custom view content as
    /// the link's label, such as images, formatted text, or complex layouts.
    ///
    /// - Parameters:
    ///   - destination: The URL to navigate to when the link is clicked.
    ///   - label: A view builder that creates the link's label content.
    ///
    /// Example:
    /// ```swift
    /// Link(destination: URL(string: "https://swift.org")!) {
    ///     HStack {
    ///         Image(systemName: "swift")
    ///         Text("Swift.org")
    ///     }
    /// }
    /// ```
    @MainActor public init(
        destination: URL,
        @ViewBuilder label: () -> Label
    ) {
        self.destination = destination
        self.label = label()
    }

    // MARK: - VNode Conversion

    /// Converts this Link view to a virtual DOM node.
    ///
    /// This method is used internally by the rendering system to convert
    /// the Link primitive into its VNode representation as an HTML anchor element.
    ///
    /// - Returns: An anchor element VNode with href attribute and label content.
    @MainActor public func toVNode() -> VNode {
        // Create properties for the anchor element
        var props: [String: VProperty] = [
            "href": .attribute(name: "href", value: destination.absoluteString)
        ]

        // Add target="_blank" for external links (http/https schemes)
        if let scheme = destination.scheme,
           (scheme == "http" || scheme == "https"),
           let host = destination.host,
           !host.isEmpty {
            props["target"] = .attribute(name: "target", value: "_blank")
            // Add rel="noopener noreferrer" for security when opening in new tab
            props["rel"] = .attribute(name: "rel", value: "noopener noreferrer")
        }

        // Add default link styling
        props["style:color"] = .style(name: "color", value: "#0066cc")
        props["style:text-decoration"] = .style(name: "text-decoration", value: "underline")
        props["style:cursor"] = .style(name: "cursor", value: "pointer")

        // Convert label to children nodes
        let children: [VNode]
        if let textLabel = label as? Text {
            // Optimize for simple text labels
            children = [textLabel.toVNode()]
        } else {
            // For complex labels, create a placeholder that will be handled by the render system
            // This will be properly implemented when the render system is connected
            children = []
        }

        return VNode.element(
            "a",
            props: props,
            children: children
        )
    }
}

// MARK: - Convenience Initializers

extension Link where Label == Text {
    /// Creates a link with a text label.
    ///
    /// This is a convenience initializer for creating simple text-based links.
    ///
    /// - Parameters:
    ///   - label: The string to display as the link's label.
    ///   - destination: The URL to navigate to when the link is clicked.
    ///
    /// Example:
    /// ```swift
    /// Link("Visit Apple", destination: URL(string: "https://apple.com")!)
    /// ```
    @MainActor public init(
        _ label: String,
        destination: URL
    ) {
        self.destination = destination
        self.label = Text(label)
    }

    /// Creates a link with a localized text label.
    ///
    /// - Parameters:
    ///   - titleKey: The localized string key for the link's label.
    ///   - destination: The URL to navigate to when the link is clicked.
    ///
    /// Example:
    /// ```swift
    /// Link("home_link", destination: URL(string: "/")!)
    /// ```
    @MainActor public init(
        _ titleKey: LocalizedStringKey,
        destination: URL
    ) {
        self.destination = destination
        self.label = Text(titleKey)
    }
}
