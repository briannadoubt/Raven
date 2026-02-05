import Foundation
import Raven
import RavenRuntime
import JavaScriptKit
import JavaScriptEventLoop

/// Entry point for the Todo App
/// Uses command ABI and synchronous initialization like Tokamak

/// Simple test view for debugging
@MainActor
struct SimpleTestView: View {
    var body: some View {
        Text("Hello from Raven!")
    }
}

@main
struct TodoAppMain {
    static func main() {
        // Guard against multiple _start calls (WASM resets static vars, JS globals persist)
        let alreadyLaunched = JSObject.global.__ravenAppLaunched
        guard alreadyLaunched.isUndefined || alreadyLaunched.boolean != true else { return }
        JSObject.global.__ravenAppLaunched = .boolean(true)

        let console = JSObject.global.console
        _ = console.log("[Swift] Main entry point")

        // Install event loop for any async operations
        JavaScriptEventLoop.installGlobalExecutor()

        // Launch the app synchronously (no async/await in main)
        launchApp()
    }

    // Store coordinator globally so we can trigger re-renders
    @MainActor
    static var coordinator: RenderCoordinator?
    @MainActor
    static var rootView: TodoApp?
    @MainActor
    static var renderPending: Bool = false
    /// Reusable JSClosure for setTimeout render callback (prevents JSClosure leak)
    @MainActor
    static var renderCallback: JSClosure?
    /// Synchronous app launch like Tokamak
    @MainActor
    static func launchApp() {
        let console = JSObject.global.console
        _ = console.log("[Swift] Launching app...")

        // Create the root view directly (skip App/Scene extraction)
        // Test full TodoApp with 5-element tuple using parameter packs
        let view = TodoApp()
        rootView = view
        _ = console.log("[Swift] Root view created")

        // Get the root container from the DOM
        guard let rootContainer = getRootContainer() else {
            _ = console.log("[Swift Error] Could not find root container")
            return
        }
        _ = console.log("[Swift] Root container found")

        // Create render coordinator
        let coord = RenderCoordinator()
        coordinator = coord
        coord.setRootContainer(rootContainer)
        _ = console.log("[Swift] Render coordinator created")

        // Subscribe to state changes to trigger re-renders
        setupStateSubscriptions(view: view, coordinator: coord)

        // Render synchronously (no async/await needed!)
        _ = console.log("[Swift] Starting render...")
        coord.render(view: view)
        _ = console.log("[Swift] Render complete!")

        _ = console.log("[Swift] App launched!")
    }

    /// Subscribe to observable object changes to trigger re-renders
    @MainActor
    static func setupStateSubscriptions(view: TodoApp, coordinator: RenderCoordinator) {
        let console = JSObject.global.console
        _ = console.log("[Swift] Setting up state subscriptions...")

        // Access the store directly (now that it's internal, not private)
        let store = view.store
        _ = console.log("[Swift] Found TodoStore, subscribing to changes")

        // Create ONE reusable JSClosure for setTimeout (prevents JSClosure leak)
        let callback = JSClosure { _ in
            _ = console.log("[Swift] 🎨 Deferred re-render executing...")
            if let rootView = Self.rootView, let coord = Self.coordinator {
                coord.render(view: rootView)
            }
            // Clear AFTER render so any objectWillChange during render is blocked
            Self.renderPending = false
            return .undefined
        }
        Self.renderCallback = callback  // Keep alive

        // Subscribe to store changes
        // CRITICAL: Defer re-render to next event loop tick using setTimeout
        // Synchronous re-render during event handler causes WASM reentrancy crash
        // Use renderPending flag to coalesce multiple objectWillChange notifications
        store.objectWillChange.subscribe {
            guard !Self.renderPending else { return }
            Self.renderPending = true
            _ = console.log("[Swift] 🔄 Store changed, scheduling deferred re-render...")
            _ = JSObject.global.setTimeout!(callback, 0)
        }
    }

    /// Get or create root DOM container (from AppRuntime)
    @MainActor
    static func getRootContainer() -> JSObject? {
        let document = JSObject.global.document

        // Try to find existing root element
        if let existingRoot = document.getElementById("root").object {
            return existingRoot
        }

        // Create a new root element
        guard let body = document.body.object else {
            return nil
        }

        var root = document.createElement("div")
        root.id = "root"
        if let appendChild = body.appendChild.function {
            _ = appendChild(root)
        }

        return root.object
    }
}
// Test comment
