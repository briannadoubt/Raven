import Foundation

/// A view that shows the progress of a task or activity.
///
/// `ProgressView` is a primitive view that renders directly to the virtual DOM.
/// It supports two modes: indeterminate (spinner) and determinate (progress bar).
///
/// ## Overview
///
/// Use `ProgressView` to indicate that an operation is in progress. When no value
/// is provided, it displays an indeterminate spinner animation. When a value is
/// provided, it displays a determinate progress bar showing completion percentage.
///
/// ## Basic Usage
///
/// Create an indeterminate progress view (spinner):
///
/// ```swift
/// ProgressView()
/// ```
///
/// ## Determinate Progress
///
/// Show specific progress with a value:
///
/// ```swift
/// @State private var progress = 0.5
///
/// var body: some View {
///     ProgressView(value: progress)
/// }
/// ```
///
/// With a custom total:
///
/// ```swift
/// @State private var completed = 75.0
///
/// var body: some View {
///     ProgressView(value: completed, total: 100.0)
/// }
/// ```
///
/// ## With Labels
///
/// Add a label to provide context:
///
/// ```swift
/// ProgressView("Loading...", value: progress, total: 1.0)
/// ```
///
/// ## Common Patterns
///
/// **Loading data:**
/// ```swift
/// struct DataView: View {
///     @State private var isLoading = true
///
///     var body: some View {
///         VStack {
///             if isLoading {
///                 ProgressView()
///             } else {
///                 ContentView()
///             }
///         }
///     }
/// }
/// ```
///
/// **Download progress:**
/// ```swift
/// struct DownloadView: View {
///     @State private var downloadProgress = 0.0
///
///     var body: some View {
///         VStack {
///             Text("Downloading...")
///             ProgressView(value: downloadProgress, total: 1.0)
///         }
///     }
/// }
/// ```
///
/// **Upload with percentage:**
/// ```swift
/// @State private var uploaded: Double = 45
/// @State private var total: Double = 100
///
/// var body: some View {
///     VStack {
///         Text("\(Int(uploaded))% Complete")
///         ProgressView(value: uploaded, total: total)
///     }
/// }
/// ```
///
/// **Loading indicator with label:**
/// ```swift
/// ProgressView("Processing your request...")
/// ```
///
/// ## Styling
///
/// Style progress views using view modifiers:
///
/// ```swift
/// ProgressView(value: progress)
///     .padding()
///     .background(Color.gray.opacity(0.2))
///     .cornerRadius(8)
/// ```
///
/// ## Implementation Details
///
/// - **Indeterminate mode**: Rendered as a `<div>` with CSS animation creating a rotating spinner
/// - **Determinate mode**: Rendered as an HTML `<progress>` element with `value` and `max` attributes
/// - **Accessibility**: Includes ARIA attributes for screen reader support
///
/// ## Best Practices
///
/// - Use indeterminate progress for operations with unknown duration
/// - Use determinate progress when you can calculate completion percentage
/// - Provide labels to give users context about what's loading
/// - Consider showing completion percentage for long operations
/// - Don't use progress indicators for operations that complete instantly
///
/// ## See Also
///
/// - ``Text``
/// - ``VStack``
///
/// Because `ProgressView` is a primitive view with `Body == Never`, it converts directly
/// to a VNode without further composition.
public struct ProgressView: View, PrimitiveView, Sendable {
    public typealias Body = Never

    /// The current value of the progress (nil for indeterminate)
    private let value: Double?

    /// The total value representing completion
    private let total: Double

    /// Optional label text
    private let label: String?

    // MARK: - Initializers

    /// Creates an indeterminate progress view (spinner).
    ///
    /// Use this initializer when you want to show activity without specific progress.
    ///
    /// Example:
    /// ```swift
    /// ProgressView()
    /// ```
    public init() {
        self.value = nil
        self.total = 1.0
        self.label = nil
    }

    /// Creates a determinate progress view with a current value.
    ///
    /// The progress bar will show the ratio of `value` to `total`.
    ///
    /// - Parameters:
    ///   - value: The current progress value.
    ///   - total: The total value representing 100% completion. Defaults to 1.0.
    ///
    /// Example:
    /// ```swift
    /// ProgressView(value: 0.75, total: 1.0)  // 75% complete
    /// ProgressView(value: 45, total: 100)    // 45% complete
    /// ```
    public init(value: Double, total: Double = 1.0) {
        self.value = value
        self.total = total
        self.label = nil
    }

    /// Creates a determinate progress view with a label.
    ///
    /// Displays a progress bar with accompanying label text.
    ///
    /// - Parameters:
    ///   - label: The text to display alongside the progress indicator.
    ///   - value: The current progress value.
    ///   - total: The total value representing 100% completion. Defaults to 1.0.
    ///
    /// Example:
    /// ```swift
    /// ProgressView("Uploading...", value: uploadedBytes, total: totalBytes)
    /// ```
    public init(_ label: String, value: Double, total: Double = 1.0) {
        self.value = value
        self.total = total
        self.label = label
    }

    // MARK: - VNode Conversion

    /// Converts this ProgressView to a virtual DOM node.
    ///
    /// This method is used internally by the rendering system to convert
    /// the ProgressView primitive into its VNode representation.
    ///
    /// - Returns: A div or progress element VNode depending on the mode.
    @MainActor public func toVNode() -> VNode {
        if let value = value {
            // Determinate mode: use progress element
            return createDeterminateProgressView(value: value, total: total, label: label)
        } else {
            // Indeterminate mode: use spinner
            return createIndeterminateProgressView(label: label)
        }
    }

    // MARK: - Private Helpers

    /// Creates a determinate progress bar using the HTML progress element.
    private func createDeterminateProgressView(value: Double, total: Double, label: String?) -> VNode {
        var props: [String: VProperty] = [
            "value": .attribute(name: "value", value: String(value)),
            "max": .attribute(name: "max", value: String(total)),
            "class": .attribute(name: "class", value: "raven-progress-bar"),
            "role": .attribute(name: "role", value: "progressbar"),
            "aria-valuenow": .attribute(name: "aria-valuenow", value: String(value)),
            "aria-valuemin": .attribute(name: "aria-valuemin", value: "0"),
            "aria-valuemax": .attribute(name: "aria-valuemax", value: String(total))
        ]

        // Add label as aria-label if provided
        if let label = label {
            props["aria-label"] = .attribute(name: "aria-label", value: label)
        }

        let progressElement = VNode.element(
            "progress",
            props: props,
            children: []
        )

        // If there's a label, wrap in a container with label text
        if let label = label {
            let labelNode = VNode.text(label)

            let containerProps: [String: VProperty] = [
                "class": .attribute(name: "class", value: "raven-progress-container")
            ]

            return VNode.element(
                "div",
                props: containerProps,
                children: [labelNode, progressElement]
            )
        }

        return progressElement
    }

    /// Creates an indeterminate spinner using CSS animation.
    private func createIndeterminateProgressView(label: String?) -> VNode {
        // Create inline styles for the spinner animation
        let spinnerStyles = """
            display: inline-block;
            width: 24px;
            height: 24px;
            border: 3px solid rgba(0, 0, 0, 0.1);
            border-top-color: var(--system-accent);
            border-radius: 50%;
            animation: raven-spinner-rotate 0.8s linear infinite;
            """

        var props: [String: VProperty] = [
            "class": .attribute(name: "class", value: "raven-progress-spinner"),
            "role": .attribute(name: "role", value: "progressbar"),
            "aria-busy": .attribute(name: "aria-busy", value: "true"),
            "aria-valuetext": .attribute(name: "aria-valuetext", value: "Loading"),
            "style": .attribute(name: "style", value: spinnerStyles)
        ]

        // Add label as aria-label if provided
        if let label = label {
            props["aria-label"] = .attribute(name: "aria-label", value: label)
        }

        let spinnerElement = VNode.element(
            "div",
            props: props,
            children: []
        )

        // If there's a label, wrap in a container with label text
        if let label = label {
            let labelNode = VNode.text(label)

            let containerProps: [String: VProperty] = [
                "class": .attribute(name: "class", value: "raven-progress-container"),
                "style": .attribute(name: "style", value: "display: inline-flex; align-items: center; gap: 8px;")
            ]

            return VNode.element(
                "div",
                props: containerProps,
                children: [spinnerElement, labelNode]
            )
        }

        return spinnerElement
    }
}

// MARK: - CSS Animation Support

extension ProgressView {
    /// Returns the CSS keyframes animation for the spinner.
    ///
    /// This should be injected into the page's stylesheet when ProgressView is used.
    /// The animation creates a smooth rotating effect for the indeterminate spinner.
    ///
    /// Example CSS injection:
    /// ```css
    /// @keyframes raven-spinner-rotate {
    ///     from { transform: rotate(0deg); }
    ///     to { transform: rotate(360deg); }
    /// }
    /// ```
    public static var spinnerKeyframes: String {
        """
        @keyframes raven-spinner-rotate {
            from {
                transform: rotate(0deg);
            }
            to {
                transform: rotate(360deg);
            }
        }
        """
    }

    /// Returns the default CSS styles for ProgressView elements.
    ///
    /// These styles provide sensible defaults for both determinate and
    /// indeterminate progress indicators.
    ///
    /// Example CSS:
    /// ```css
    /// .raven-progress-bar {
    ///     width: 100%;
    ///     height: 8px;
    /// }
    ///
    /// .raven-progress-spinner {
    ///     /* Inline styles are used for the spinner */
    /// }
    ///
    /// .raven-progress-container {
    ///     display: flex;
    ///     flex-direction: column;
    ///     gap: 8px;
    /// }
    /// ```
    public static var defaultStyles: String {
        """
        .raven-progress-bar {
            width: 100%;
            height: 8px;
            border-radius: 4px;
            appearance: none;
            -webkit-appearance: none;
            -moz-appearance: none;
        }

        .raven-progress-bar::-webkit-progress-bar {
            background-color: var(--system-fill);
            border-radius: 4px;
        }

        .raven-progress-bar::-webkit-progress-value {
            background-color: var(--system-accent);
            border-radius: 4px;
            transition: width 0.3s ease;
        }

        .raven-progress-bar::-moz-progress-bar {
            background-color: var(--system-accent);
            border-radius: 4px;
            transition: width 0.3s ease;
        }

        .raven-progress-container {
            display: flex;
            flex-direction: column;
            gap: 8px;
            align-items: flex-start;
        }

        \(spinnerKeyframes)
        """
    }
}
