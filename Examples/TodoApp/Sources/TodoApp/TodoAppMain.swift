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
        let console = JSObject.global.console
        _ = console.log("[Swift] Main entry point - synchronous launch")

        // Install event loop for any async operations
        JavaScriptEventLoop.installGlobalExecutor()
        _ = console.log("[Swift] Event loop installed")

        // Launch the app synchronously (no async/await in main)
        launchApp()

        _ = console.log("[Swift] Main returning")
    }

    /// Synchronous app launch like Tokamak
    @MainActor
    static func launchApp() {
        let console = JSObject.global.console
        _ = console.log("[Swift] Launching app synchronously...")

        // Create the root view directly (skip App/Scene extraction)
        // Test full TodoApp with 5-element tuple using parameter packs
        let rootView = TodoApp()
        _ = console.log("[Swift] Root view created")

        // Get the root container from the DOM
        guard let rootContainer = getRootContainer() else {
            _ = console.log("[Swift Error] Could not find root container")
            return
        }
        _ = console.log("[Swift] Root container found")

        // Create render coordinator
        let coordinator = RenderCoordinator()
        coordinator.setRootContainer(rootContainer)
        _ = console.log("[Swift] Render coordinator created")

        // Render synchronously (no async/await needed!)
        _ = console.log("[Swift] Starting render...")
        coordinator.render(view: rootView)
        _ = console.log("[Swift] Render complete!")

        _ = console.log("[Swift] App launched!")
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
