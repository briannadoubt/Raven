import JavaScriptKit
@_exported import Raven
import Foundation

/// The main runtime coordinator for Raven apps.
///
/// `AppRuntime` is responsible for:
/// - Launching apps and extracting their root views
/// - Tracking scene lifecycle (active/inactive/background)
/// - Managing the connection between App → Scene → View → DOM
/// - Coordinating with `RenderCoordinator` for actual rendering
///
/// The runtime tracks browser visibility and focus events to update scene phase appropriately.
@MainActor
public final class AppRuntime: Sendable {
    /// Shared singleton instance.
    public static let shared = AppRuntime()

    /// The currently running app (type-erased).
    private var currentApp: (any App)?

    /// The render coordinator handling view rendering.
    private var renderCoordinator: RenderCoordinator?

    /// Current scene phase.
    private var scenePhase: ScenePhase = .active

    /// Environment values to propagate to views.
    private var environmentValues: EnvironmentValues = EnvironmentValues()

    /// Closures for event listeners (stored to prevent deallocation).
    private var visibilityHandler: JSClosure?
    private var blurHandler: JSClosure?
    private var focusHandler: JSClosure?
    private var colorSchemeHandler: JSClosure?

    /// Whether framework CSS has already been injected.
    private static var cssInjected = false

    /// Whether the app has already been launched (prevents duplicate launches).
    private var hasLaunched = false

    private init() {}

    /// Runs an app by extracting its scenes and mounting the root view to the DOM.
    ///
    /// This is the main entry point for launching a Raven app:
    /// ```swift
    /// AppRuntime.shared.run(app: myApp)
    /// ```
    ///
    /// - Parameter app: The app to run.
    public func run<A: App>(app: A) {
        guard !hasLaunched else { return }
        hasLaunched = true

        Self.injectFrameworkCSSIfNeeded()
        currentApp = app

        // Extract root view from app's scene hierarchy
        let rootView = extractRootView(from: app.body)

        // Set up scene phase tracking based on browser events
        setupScenePhaseTracking()

        // Initialize render coordinator with DOMRenderer
        let domRenderer = DOMRenderer()
        let coordinator = RenderCoordinator(renderer: domRenderer)
        renderCoordinator = coordinator

        // Get or create root container element
        guard let rootContainer = getRootContainer() else {
            print("Error: Could not find or create root container element")
            return
        }

        // Set the root container in the coordinator
        coordinator.setRootContainer(rootContainer)

        // Render the root view (now synchronous!)
        coordinator.render(view: rootView)

        // Set up color scheme tracking after coordinator is ready
        setupColorSchemeTracking()
    }

    /// Injects framework-level CSS (variables, resets, pseudo-element styles).
    /// Called automatically by RenderCoordinator.setRootContainer().
    /// Safe to call multiple times — only injects once.
    public static func injectFrameworkCSSIfNeeded() {
        guard !cssInjected else { return }
        cssInjected = true

        let dom = DOMBridge.shared

        guard let styleElement = dom.createElement(tag: "style") else { return }

        let css = """
        :root {
            --system-primary: #000000;
            --system-secondary: #3c3c43;
            --system-tertiary: #48484a;
            --system-accent: #007AFF;
            --system-background: #ffffff;
            --system-secondary-background: #f2f2f7;
            --system-tertiary-background: #ffffff;
            --system-grouped-background: #f2f2f7;
            --system-label: #000000;
            --system-secondary-label: #3c3c43;
            --system-tertiary-label: #48484a;
            --system-separator: #c6c6c8;
            --system-fill: rgba(120, 120, 128, 0.2);
            --system-secondary-fill: rgba(120, 120, 128, 0.16);
            --system-control-background: #ffffff;
            --system-control-border: #c6c6c8;
        }
        @media (prefers-color-scheme: dark) {
            :root {
                --system-primary: #ffffff;
                --system-secondary: #ebebf5;
                --system-tertiary: #ebebf5;
                --system-accent: #0A84FF;
                --system-background: #000000;
                --system-secondary-background: #1c1c1e;
                --system-tertiary-background: #2c2c2e;
                --system-grouped-background: #1c1c1e;
                --system-label: #ffffff;
                --system-secondary-label: rgba(235, 235, 245, 0.6);
                --system-tertiary-label: rgba(235, 235, 245, 0.3);
                --system-separator: #38383a;
                --system-fill: rgba(120, 120, 128, 0.36);
                --system-secondary-fill: rgba(120, 120, 128, 0.32);
                --system-control-background: #1c1c1e;
                --system-control-border: #38383a;
            }
        }
        * { box-sizing: border-box; }
        body { margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; color: var(--system-label); background-color: var(--system-background); }
        button { cursor: pointer; transition: all 0.15s; border: none; background: transparent; padding: 0; font: inherit; color: inherit; text-align: inherit; }
        button:hover { filter: brightness(0.95); }
        button:active { transform: translateY(1px); }
        .raven-progress-bar { width: 100%; height: 8px; border-radius: 4px; appearance: none; -webkit-appearance: none; -moz-appearance: none; }
        .raven-progress-bar::-webkit-progress-bar { background-color: var(--system-fill); border-radius: 4px; }
        .raven-progress-bar::-webkit-progress-value { background-color: var(--system-accent); border-radius: 4px; transition: width 0.3s ease; }
        .raven-progress-bar::-moz-progress-bar { background-color: var(--system-accent); border-radius: 4px; transition: width 0.3s ease; }
        .raven-progress-container { display: flex; flex-direction: column; gap: 8px; align-items: flex-start; }
        @keyframes raven-spinner-rotate { from { transform: rotate(0deg); } to { transform: rotate(360deg); } }
        input[type="range"] { -webkit-appearance: none; appearance: none; width: 100%; height: 6px; background: var(--system-fill); border-radius: 3px; outline: none; }
        input[type="range"]::-webkit-slider-thumb { -webkit-appearance: none; appearance: none; width: 20px; height: 20px; border-radius: 50%; background: var(--system-accent); cursor: pointer; border: 2px solid var(--system-control-background); box-shadow: 0 2px 6px rgba(0,0,0,0.2); }
        input[type="range"]::-moz-range-thumb { width: 20px; height: 20px; border-radius: 50%; background: var(--system-accent); cursor: pointer; border: 2px solid var(--system-control-background); box-shadow: 0 2px 6px rgba(0,0,0,0.2); }
        """

        dom.setTextContent(element: styleElement, text: css)

        if let doc = JSObject.global.document.object,
           let head = doc.head.object {
            dom.appendChild(parent: head, child: styleElement)
        }
    }

    /// Extracts the root view from a scene hierarchy.
    ///
    /// Uses protocol-based dispatch instead of Mirror reflection, which crashes
    /// in Swift WASM on complex generic types.
    ///
    /// - Parameter scene: The scene to extract from.
    /// - Returns: The root view wrapped in `AnyView`.
    private func extractRootView<S: Scene>(from scene: S) -> AnyView {
        // Primary path: scenes that conform to _SceneContentExtractable (e.g. WindowGroup)
        if let extractable = scene as? _SceneContentExtractable {
            return extractable._extractRootView()
        }

        // Handle nested scenes (scene with body)
        if S.Body.self != Never.self {
            return extractRootView(from: scene.body)
        }

        // Fallback: empty view
        return AnyView(EmptyView())
    }

    /// Gets or creates the root DOM container element.
    ///
    /// Looks for an element with id "root" or creates one if it doesn't exist.
    ///
    /// - Returns: The root container JSObject, or nil if creation fails.
    private func getRootContainer() -> JSObject? {
        guard let doc = JSObject.global.document.object else { return nil }

        // Try to find existing root element
        if let existingRoot = doc.getElementById!("root").object {
            return existingRoot
        }

        // Create a new root element
        guard let body = doc.body.object else {
            return nil
        }

        let dom = DOMBridge.shared
        guard let root = dom.createElement(tag: "div") else {
            return nil
        }
        root.id = .string("root")
        dom.appendChild(parent: body, child: root)

        return root
    }

    /// Sets up tracking for scene phase changes based on browser events.
    ///
    /// This method listens to:
    /// - visibilitychange: Detects when the page is hidden/visible
    /// - blur: Detects when the window loses focus
    /// - focus: Detects when the window gains focus
    private func setupScenePhaseTracking() {
        guard let doc = JSObject.global.document.object else { return }
        let window = JSObject.global

        // Listen for visibility changes
        visibilityHandler = JSClosure { [weak self] _ in
            guard let self = self else { return .undefined }
            let hidden = doc.hidden.boolean ?? false
            Task { @MainActor [weak self] in
                self?.updateScenePhase(hidden ? .background : .active)
            }
            return .undefined
        }
        _ = doc.addEventListener!("visibilitychange", visibilityHandler!)

        // Listen for window blur (lost focus)
        blurHandler = JSClosure { [weak self] _ in
            guard let self = self else { return .undefined }
            Task { @MainActor [weak self] in
                self?.updateScenePhase(.inactive)
            }
            return .undefined
        }
        _ = window.addEventListener!("blur", blurHandler!)

        // Listen for window focus (gained focus)
        focusHandler = JSClosure { [weak self] _ in
            guard let self = self else { return .undefined }
            Task { @MainActor [weak self] in
                let hidden = doc.hidden.boolean ?? false
                self?.updateScenePhase(hidden ? .background : .active)
            }
            return .undefined
        }
        _ = window.addEventListener!("focus", focusHandler!)
    }

    /// Sets up tracking for system color scheme changes using matchMedia.
    ///
    /// Queries `prefers-color-scheme: dark` and listens for changes.
    /// Updates `environmentValues.colorScheme` and triggers a re-render
    /// when the user toggles OS dark mode.
    private func setupColorSchemeTracking() {
        let window = JSObject.global

        // Query the current color scheme
        guard let mediaQuery = window.matchMedia!("(prefers-color-scheme: dark)").object else {
            return
        }

        // Set initial value from current state
        let isDark = mediaQuery.matches.boolean ?? false
        environmentValues.colorScheme = isDark ? .dark : .light

        // Listen for changes (use "change" event, not deprecated addListener)
        // WASM constraint: call handler synchronously, no Task{}
        colorSchemeHandler = JSClosure { [weak self] _ in
            guard let self = self else { return .undefined }
            let nowDark = mediaQuery.matches.boolean ?? false
            let newScheme: ColorScheme = nowDark ? .dark : .light
            self.environmentValues.colorScheme = newScheme
            self.renderCoordinator?.triggerRerender()
            return .undefined
        }
        _ = mediaQuery.addEventListener!("change", colorSchemeHandler!)
    }

    /// Updates the scene phase and triggers a re-render if needed.
    ///
    /// - Parameter newPhase: The new scene phase to set.
    private func updateScenePhase(_ newPhase: ScenePhase) {
        guard scenePhase != newPhase else { return }

        scenePhase = newPhase

        // Update environment values
        environmentValues.scenePhase = newPhase

        // Trigger re-render with updated environment
        // Note: This would require updating the RenderCoordinator to support
        // environment updates. For now, this is a placeholder.
        // TODO: Implement environment propagation in RenderCoordinator
    }

    /// Updates an environment value and triggers a re-render.
    ///
    /// This method is a placeholder for future environment update support.
    ///
    /// - Parameters:
    ///   - keyPath: The key path to the environment value to update.
    ///   - value: The new value to set.
    public func updateEnvironment<Value>(_ keyPath: WritableKeyPath<EnvironmentValues, Value>, _ value: Value) {
        environmentValues[keyPath: keyPath] = value

        // TODO: Trigger re-render with updated environment
        // This requires integrating environment values into the render pipeline
    }
}

// MARK: - RavenApp Extension

extension RavenApp {
    /// Runs the app by mounting it to the DOM and starting the render loop.
    ///
    /// Call this method to launch your app:
    ///
    /// ```swift
    /// @main
    /// struct MyApp {
    ///     static func main() async {
    ///         await RavenApp {
    ///             Text("Hello, World!")
    ///         }.run()
    ///     }
    /// }
    /// ```
    public func run() async {
        await AppRuntime.shared.run(app: self)
    }
}
