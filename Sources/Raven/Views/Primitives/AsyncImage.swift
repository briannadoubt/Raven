import Foundation

/// A view that asynchronously loads and displays an image.
///
/// `AsyncImage` loads images from URLs asynchronously and provides different
/// views for loading, success, and failure states. It leverages the browser's
/// native image loading capabilities for optimal performance.
///
/// ## Overview
///
/// Use `AsyncImage` when you need to load images from remote URLs. The view
/// automatically handles loading states, displays placeholders, and provides
/// error handling.
///
/// ## Basic Usage
///
/// Display an image from a URL with default behavior:
///
/// ```swift
/// AsyncImage(url: URL(string: "https://example.com/image.jpg"))
/// ```
///
/// ## Custom Placeholder
///
/// Show a custom placeholder while loading:
///
/// ```swift
/// AsyncImage(url: imageURL) { image in
///     image
///         .resizable()
///         .aspectRatio(contentMode: .fit)
/// } placeholder: {
///     ProgressView()
/// }
/// ```
///
/// ## Phase-Based Content
///
/// Handle all loading phases explicitly:
///
/// ```swift
/// AsyncImage(url: imageURL) { phase in
///     switch phase {
///     case .empty:
///         ProgressView()
///     case .success(let image):
///         image
///             .resizable()
///             .aspectRatio(contentMode: .fit)
///     case .failure(let error):
///         VStack {
///             Image(systemName: "exclamationmark.triangle")
///             Text("Failed to load image")
///         }
///     }
/// }
/// ```
///
/// ## Caching
///
/// AsyncImage leverages the browser's native image caching, which automatically
/// caches images based on HTTP headers and provides optimal performance.
///
/// ## Scale Factor
///
/// Specify a scale factor for high-DPI displays:
///
/// ```swift
/// AsyncImage(url: imageURL, scale: 2.0)
/// ```
///
/// ## Transactions
///
/// Control animations during state transitions:
///
/// ```swift
/// AsyncImage(
///     url: imageURL,
///     transaction: Transaction(animation: .easeInOut)
/// ) { phase in
///     // ...
/// }
/// ```
///
/// ## Implementation Details
///
/// - Uses HTML `<img>` element for actual image loading
/// - Monitors `onload` and `onerror` events
/// - Manages loading state internally
/// - Supports lazy loading via browser's native `loading="lazy"` attribute
///
/// ## See Also
///
/// - ``Image``
/// - ``ProgressView``
public struct AsyncImage<Content: View>: View {
    /// The URL of the image to load
    private let url: URL?

    /// The scale factor for the image (default: 1.0)
    private let scale: CGFloat

    /// The transaction to use for state changes
    private let transaction: Transaction

    /// The content builder that takes the current phase
    private let content: @Sendable @MainActor (AsyncImagePhase) -> Content

    // MARK: - Phase-Based Initializer

    /// Creates an async image with a custom content builder for all loading phases.
    ///
    /// Use this initializer when you need full control over how the image is
    /// displayed in each loading phase.
    ///
    /// - Parameters:
    ///   - url: The URL of the image to load.
    ///   - scale: The scale factor for the image. Default is 1.0.
    ///   - transaction: The transaction to use when the phase changes.
    ///   - content: A closure that builds the view for the current phase.
    ///
    /// ## Example
    ///
    /// ```swift
    /// AsyncImage(url: imageURL) { phase in
    ///     switch phase {
    ///     case .empty:
    ///         Color.gray
    ///     case .success(let image):
    ///         image.resizable()
    ///     case .failure:
    ///         Image(systemName: "exclamationmark.triangle")
    ///     }
    /// }
    /// ```
    @MainActor
    public init(
        url: URL?,
        scale: CGFloat = 1.0,
        transaction: Transaction = Transaction(),
        @ViewBuilder content: @escaping @Sendable @MainActor (AsyncImagePhase) -> Content
    ) {
        self.url = url
        self.scale = scale
        self.transaction = transaction
        self.content = content
    }

    // MARK: - Body

    public var body: some View {
        AsyncImageRenderer(
            url: url,
            scale: scale,
            transaction: transaction,
            content: content
        )
    }
}

// MARK: - Convenience Initializers

extension AsyncImage {
    /// Creates an async image that displays the loaded image without customization.
    ///
    /// This is the simplest way to load and display an image. The image will be
    /// hidden while loading and will appear once loaded.
    ///
    /// - Parameters:
    ///   - url: The URL of the image to load.
    ///   - scale: The scale factor for the image. Default is 1.0.
    ///
    /// ## Example
    ///
    /// ```swift
    /// AsyncImage(url: URL(string: "https://example.com/photo.jpg"))
    /// ```
    @MainActor
    public init(url: URL?, scale: CGFloat = 1.0) where Content == ConditionalContent<Image, EmptyView> {
        self.init(
            url: url,
            scale: scale,
            transaction: Transaction()
        ) { phase in
            if case .success(let image) = phase {
                image
            } else {
                // Return empty view during loading/error
                EmptyView()
            }
        }
    }
}

extension AsyncImage {
    /// Creates an async image with separate content and placeholder closures.
    ///
    /// This initializer provides a convenient way to specify different views for
    /// the loaded image and the loading state. Errors are handled by showing the
    /// placeholder.
    ///
    /// - Parameters:
    ///   - url: The URL of the image to load.
    ///   - scale: The scale factor for the image. Default is 1.0.
    ///   - content: A closure that takes the loaded image and returns a view.
    ///   - placeholder: A closure that returns the view to show while loading.
    ///
    /// ## Example
    ///
    /// ```swift
    /// AsyncImage(url: imageURL) { image in
    ///     image
    ///         .resizable()
    ///         .frame(width: 200, height: 200)
    /// } placeholder: {
    ///     ProgressView()
    /// }
    /// ```
    @MainActor
    public init<I: View, P: View>(
        url: URL?,
        scale: CGFloat = 1.0,
        @ViewBuilder content: @escaping @Sendable @MainActor (Image) -> I,
        @ViewBuilder placeholder: @escaping @Sendable @MainActor () -> P
    ) where Content == _ConditionalContent<I, P> {
        self.init(
            url: url,
            scale: scale,
            transaction: Transaction()
        ) { phase in
            if case .success(let image) = phase {
                content(image)
            } else {
                placeholder()
            }
        }
    }
}

// MARK: - AsyncImagePhase

/// The current phase of the async image loading process.
///
/// Use this enum in the content closure to determine what to display based on
/// the current loading state.
public enum AsyncImagePhase: Sendable {
    /// No image has been loaded yet (initial state).
    case empty

    /// An image was successfully loaded.
    case success(Image)

    /// Image loading failed with an error.
    case failure(Error)

    /// Returns the loaded image, if available.
    public var image: Image? {
        if case .success(let image) = self {
            return image
        }
        return nil
    }

    /// Returns the error, if loading failed.
    public var error: Error? {
        if case .failure(let error) = self {
            return error
        }
        return nil
    }
}

// MARK: - Internal Renderer

/// Internal view that handles the actual image loading and state management.
private struct AsyncImageRenderer<Content: View>: View, PrimitiveView {
    typealias Body = Never

    let url: URL?
    let scale: CGFloat
    let transaction: Transaction
    let content: @Sendable @MainActor (AsyncImagePhase) -> Content

    @MainActor public func toVNode() -> VNode {
        guard let url = url else {
            // No URL provided, render empty phase
            return renderView(content(.empty))
        }

        // Create an img element with event handlers
        // The browser will handle the actual loading
        let urlString = url.absoluteString

        // We'll use a wrapper div to manage the loading state
        // The image will be hidden until loaded via CSS
        var imgProps: [String: VProperty] = [
            "src": .attribute(name: "src", value: urlString),
            "loading": .attribute(name: "loading", value: "lazy"),
            "class": .attribute(name: "class", value: "raven-async-image"),
            "style": .attribute(name: "style", value: "display: none;"),
            "data-scale": .attribute(name: "data-scale", value: String(scale))
        ]

        // Add alt text for accessibility
        imgProps["alt"] = .attribute(name: "alt", value: "")

        let imgElement = VNode.element(
            "img",
            props: imgProps,
            children: []
        )

        // Create a placeholder element
        let placeholderElement = renderView(content(.empty))

        // Wrap in a container that manages visibility
        let containerProps: [String: VProperty] = [
            "class": .attribute(name: "class", value: "raven-async-image-container"),
            "data-url": .attribute(name: "data-url", value: urlString)
        ]

        return VNode.element(
            "div",
            props: containerProps,
            children: [placeholderElement, imgElement]
        )
    }
}

// MARK: - Type Alias for Conditional Content

/// Type alias for conditional content used in AsyncImage.
///
/// This allows the two-closure initializer to return different view types
/// for success and placeholder states.
public typealias _ConditionalContent<TrueContent: View, FalseContent: View> = ConditionalContent<TrueContent, FalseContent>

// MARK: - AsyncImageError

/// Errors that can occur during async image loading.
public enum AsyncImageError: Error, Sendable {
    /// The image failed to load from the given URL.
    case loadFailed

    /// The image data was invalid or couldn't be decoded.
    case invalidData

    /// The network request failed.
    case networkError
}

// MARK: - CSS Styles

extension AsyncImageRenderer {
    /// Returns the CSS styles needed for AsyncImage functionality.
    ///
    /// These styles handle the loading state transitions and image display.
    ///
    /// ## Example CSS
    ///
    /// ```css
    /// .raven-async-image-container {
    ///     position: relative;
    ///     display: inline-block;
    /// }
    ///
    /// .raven-async-image {
    ///     display: none;
    ///     width: 100%;
    ///     height: 100%;
    ///     object-fit: contain;
    /// }
    ///
    /// .raven-async-image.loaded {
    ///     display: block;
    /// }
    /// ```
    public static var defaultStyles: String {
        """
        .raven-async-image-container {
            position: relative;
            display: inline-block;
        }

        .raven-async-image {
            display: none;
            max-width: 100%;
            height: auto;
            object-fit: contain;
        }

        .raven-async-image.loaded {
            display: block;
        }

        .raven-async-image.error {
            display: none;
        }
        """
    }
}
