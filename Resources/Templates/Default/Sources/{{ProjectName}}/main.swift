import Foundation
import JavaScriptKit
// import Raven
// import RavenRuntime

/// Entry point for the {{ProjectName}} application
/// This sets up the RenderCoordinator and mounts the app to the DOM
@MainActor
func main() async {
    print("Starting {{ProjectName}}...")

    // Once Raven is added as a dependency, uncomment this code:
    //
    // // Create the render coordinator
    // let coordinator = RenderCoordinator()
    //
    // // Get root container from DOM
    // guard let document = JSObject.global.document.object,
    //       let rootElement = document.getElementById("app").object else {
    //     print("Error: Could not find #app element in DOM")
    //     return
    // }
    //
    // // Set the root container
    // coordinator.setRootContainer(rootElement)
    //
    // // Render the app
    // await coordinator.render(view: App())
    //
    // print("{{ProjectName}} is running!")

    // For now, just update the DOM directly as a placeholder
    if let document = JSObject.global.document.object,
       let getElementById = document.getElementById.function,
       let rootElement = getElementById("app").object {
        let app = App()
        rootElement.innerHTML = JSValue.string(app.body)
        print("{{ProjectName}} placeholder is running!")
    } else {
        print("Error: Could not find #app element in DOM")
    }
}

// Run the main function
await main()
