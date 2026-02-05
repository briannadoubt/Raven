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
        currentApp = app

        // Extract root view from app's scene hierarchy
        let rootView = extractRootView(from: app.body)

        // Set up scene phase tracking based on browser events
        setupScenePhaseTracking()

        // Initialize render coordinator
        let coordinator = RenderCoordinator()
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
    }

    /// Extracts the root view from a scene hierarchy.
    ///
    /// This method recursively unwraps scenes until it finds a `WindowGroup` or other
    /// scene containing a view, then returns that view as `AnyView`.
    ///
    /// - Parameter scene: The scene to extract from.
    /// - Returns: The root view wrapped in `AnyView`.
    private func extractRootView<S: Scene>(from scene: S) -> AnyView {
        // Handle WindowGroup (primary case)
        if let windowGroup = scene as? WindowGroup<AnyView> {
            return AnyView(windowGroup.content())
        }

        // Try to extract from any WindowGroup by casting through existential
        // This handles WindowGroup<Content> where Content is not AnyView
        let mirror = Mirror(reflecting: scene)
        for child in mirror.children {
            if child.label == "content", let contentClosure = child.value as? () -> Any {
                // Call the closure to get the view
                let view = contentClosure()
                if let anyView = view as? AnyView {
                    return anyView
                } else if let concreteView = view as? any View {
                    return AnyView(concreteView)
                }
            }
        }

        // Handle Settings scene
        if mirror.displayStyle == .struct {
            for child in mirror.children {
                if child.label == "content", let contentClosure = child.value as? () -> Any {
                    let view = contentClosure()
                    if let anyView = view as? AnyView {
                        return anyView
                    } else if let concreteView = view as? any View {
                        return AnyView(concreteView)
                    }
                }
            }
        }

        // Handle TupleScene (multiple scenes) - use the first one
        if mirror.displayStyle == .struct {
            for child in mirror.children {
                if child.label == "content" {
                    // TupleScene contains a tuple of scenes
                    let tupleMirror = Mirror(reflecting: child.value)
                    if let firstScene = tupleMirror.children.first?.value as? any Scene {
                        return extractRootView(from: firstScene)
                    }
                }
            }
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
        let document = JSObject.global.document

        // Try to find existing root element
        if let existingRoot = document.getElementById("root").object {
            return existingRoot
        }

        // Create a new root element
        guard let body = document.body.object else {
            return nil
        }

        guard let createElementFn = document.createElement.function,
              let root = createElementFn("div").object else {
            return nil
        }
        root.id = .string("root")
        if let appendChild = body.appendChild.function {
            _ = appendChild(root)
        }

        return root
    }

    /// Sets up tracking for scene phase changes based on browser events.
    ///
    /// This method listens to:
    /// - visibilitychange: Detects when the page is hidden/visible
    /// - blur: Detects when the window loses focus
    /// - focus: Detects when the window gains focus
    private func setupScenePhaseTracking() {
        let document = JSObject.global.document
        let window = JSObject.global

        // Listen for visibility changes
        visibilityHandler = JSClosure { [weak self] _ in
            guard let self = self else { return .undefined }
            let hidden = document.hidden.boolean ?? false
            Task { @MainActor [weak self] in
                self?.updateScenePhase(hidden ? .background : .active)
            }
            return .undefined
        }
        if let addEventListener = document.addEventListener.function {
            _ = addEventListener("visibilitychange", visibilityHandler!)
        }

        // Listen for window blur (lost focus)
        blurHandler = JSClosure { [weak self] _ in
            guard let self = self else { return .undefined }
            Task { @MainActor [weak self] in
                self?.updateScenePhase(.inactive)
            }
            return .undefined
        }
        if let addEventListener = window.addEventListener.function {
            _ = addEventListener("blur", blurHandler!)
        }

        // Listen for window focus (gained focus)
        focusHandler = JSClosure { [weak self] _ in
            guard let self = self else { return .undefined }
            Task { @MainActor [weak self] in
                let hidden = document.hidden.boolean ?? false
                self?.updateScenePhase(hidden ? .background : .active)
            }
            return .undefined
        }
        if let addEventListener = window.addEventListener.function {
            _ = addEventListener("focus", focusHandler!)
        }
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
