import Foundation

/// Generates HTML index files for Raven builds
struct HTMLGenerator: Sendable {
    /// Generates an HTML index file from the given HTML configuration
    /// - Parameter config: The HTML configuration containing project settings
    /// - Returns: A complete HTML document as a string
    func generate(config: HTMLConfig) -> String {
        var html = """
        <!DOCTYPE html>
        <html lang="\(escapeHTML(config.language))">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
        """

        // Add optional meta tags
        for (name, content) in config.metaTags.sorted(by: { $0.key < $1.key }) {
            html += "\n    <meta name=\"\(escapeHTML(name))\" content=\"\(escapeHTML(content))\">"
        }

        // Add title
        html += "\n    <title>\(escapeHTML(config.title))</title>"

        // Add CSS links
        for cssFile in config.cssFiles {
            html += "\n    <link rel=\"stylesheet\" href=\"\(escapeHTML(cssFile))\">"
        }

        html += """

        </head>
        <body>
            <div id="\(escapeHTML(config.mountElementID))"></div>
            <script src="\(escapeHTML(config.runtimeJSFile))" defer></script>
            <script type="module">
                // Load WASM and initialize Raven
                import init from './\(escapeHTML(config.wasmFile))';

                async function startApp() {
                    try {
                        await init();
                        console.log('Raven app initialized successfully');
                    } catch (error) {
                        console.error('Failed to initialize Raven app:', error);
                    }
                }

                startApp();
            </script>
        """

        // Inject error overlay and hot reload client in development mode
        if config.isDevelopment {
            let errorOverlay = ErrorOverlay()
            html += errorOverlay.generateWithHotReload(hotReloadPort: config.hotReloadPort)
        }

        html += """
        </body>
        </html>
        """

        return html
    }

    /// Writes the generated HTML to a file at the specified path
    /// - Parameters:
    ///   - config: The HTML configuration
    ///   - path: The file path where the HTML should be written
    /// - Throws: File system errors if writing fails
    func writeToFile(config: HTMLConfig, path: String) throws {
        let html = generate(config: config)
        let url = URL(fileURLWithPath: path)

        // Create parent directory if it doesn't exist
        let parentDirectory = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(
            at: parentDirectory,
            withIntermediateDirectories: true
        )

        try html.write(to: url, atomically: true, encoding: .utf8)
    }

    /// Escapes HTML special characters to prevent injection
    /// - Parameter text: The text to escape
    /// - Returns: The escaped text safe for HTML output
    private func escapeHTML(_ text: String) -> String {
        var escaped = text
        escaped = escaped.replacingOccurrences(of: "&", with: "&amp;")
        escaped = escaped.replacingOccurrences(of: "<", with: "&lt;")
        escaped = escaped.replacingOccurrences(of: ">", with: "&gt;")
        escaped = escaped.replacingOccurrences(of: "\"", with: "&quot;")
        escaped = escaped.replacingOccurrences(of: "'", with: "&#x27;")
        return escaped
    }
}

// MARK: - Convenience Extensions

extension HTMLGenerator {
    /// Generates HTML with default configuration for a project
    /// - Parameter projectName: The name of the project
    /// - Returns: A complete HTML document as a string
    func generate(projectName: String) -> String {
        let config = HTMLConfig(projectName: projectName)
        return generate(config: config)
    }

    /// Generates and writes HTML with custom configuration options
    /// - Parameters:
    ///   - projectName: The name of the project
    ///   - title: Optional custom title (defaults to project name)
    ///   - outputPath: The file path where HTML should be written
    ///   - wasmFile: Path to WASM file (relative to output directory)
    ///   - runtimeJSFile: Path to runtime JS file (relative to output directory)
    ///   - cssFiles: Array of CSS file paths (relative to output directory)
    ///   - metaTags: Dictionary of meta tag name-content pairs
    /// - Throws: File system errors if writing fails
    func writeToFile(
        projectName: String,
        title: String? = nil,
        outputPath: String,
        wasmFile: String = "app.wasm",
        runtimeJSFile: String = "runtime.js",
        cssFiles: [String] = ["styles.css"],
        metaTags: [String: String] = [:]
    ) throws {
        let config = HTMLConfig(
            projectName: projectName,
            title: title,
            wasmFile: wasmFile,
            runtimeJSFile: runtimeJSFile,
            cssFiles: cssFiles,
            metaTags: metaTags
        )
        try writeToFile(config: config, path: outputPath)
    }
}
