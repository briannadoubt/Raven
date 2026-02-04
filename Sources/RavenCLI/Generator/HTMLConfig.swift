import Foundation

/// Configuration for generating HTML index files
public struct HTMLConfig: Sendable {
    /// The name of the project
    let projectName: String

    /// The display title for the HTML page
    let title: String

    /// Path to the WASM binary file (relative to output directory)
    let wasmFile: String

    /// Path to the runtime JavaScript file (relative to output directory)
    let runtimeJSFile: String

    /// Optional CSS file paths (relative to output directory)
    let cssFiles: [String]

    /// Optional meta tags for the HTML head
    let metaTags: [String: String]

    /// Language attribute for the html tag
    let language: String

    /// The div ID where the Raven app will mount
    let mountElementID: String

    /// Whether this is a development build (enables error overlay and hot reload)
    let isDevelopment: Bool

    /// Port for hot reload server (only used in development mode)
    let hotReloadPort: Int

    public init(
        projectName: String,
        title: String? = nil,
        wasmFile: String = "app.wasm",
        runtimeJSFile: String = "runtime.js",
        cssFiles: [String] = ["styles.css"],
        metaTags: [String: String] = [:],
        language: String = "en",
        mountElementID: String = "app",
        isDevelopment: Bool = false,
        hotReloadPort: Int = 35729
    ) {
        self.projectName = projectName
        self.title = title ?? projectName
        self.wasmFile = wasmFile
        self.runtimeJSFile = runtimeJSFile
        self.cssFiles = cssFiles
        self.metaTags = metaTags
        self.language = language
        self.mountElementID = mountElementID
        self.isDevelopment = isDevelopment
        self.hotReloadPort = hotReloadPort
    }
}
