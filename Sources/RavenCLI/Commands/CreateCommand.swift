import ArgumentParser
import Foundation

struct CreateCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "create",
        abstract: "Create a new Raven project from a template"
    )

    @Argument(help: "The name of the project to create")
    var projectName: String

    @Option(name: .shortAndLong, help: "The template to use")
    var template: String = "default"

    @Flag(name: .long, help: "Skip git repository initialization")
    var noGit: Bool = false

    @Flag(name: .long, help: "Enable verbose logging")
    var verbose: Bool = false

    func run() throws {
        if verbose {
            print("Creating new Raven project: \(projectName)")
            print("Template: \(template)")
        }

        // Validate project name
        guard isValidProjectName(projectName) else {
            throw ValidationError("Project name must be alphanumeric (can include hyphens and underscores, no spaces)")
        }

        // Get current directory
        let currentDirectory = FileManager.default.currentDirectoryPath
        let projectPath = (currentDirectory as NSString).appendingPathComponent(projectName)

        // Check if project directory already exists
        if FileManager.default.fileExists(atPath: projectPath) {
            throw ValidationError("Directory '\(projectName)' already exists")
        }

        // Create project directory
        if verbose {
            print("Creating project directory at: \(projectPath)")
        }
        try FileManager.default.createDirectory(atPath: projectPath, withIntermediateDirectories: true)

        // Copy template files
        try copyTemplateFiles(to: projectPath)

        // Replace placeholders
        try replacePlaceholders(in: projectPath)

        // Initialize git repository
        if !noGit {
            if verbose {
                print("Initializing git repository...")
            }
            try initializeGitRepo(at: projectPath)
        }

        // Print success message
        printSuccessMessage()
    }

    // MARK: - Validation

    private func isValidProjectName(_ name: String) -> Bool {
        // Allow alphanumeric characters, hyphens, and underscores
        let pattern = "^[a-zA-Z0-9_-]+$"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: name.utf16.count)
        return regex?.firstMatch(in: name, range: range) != nil
    }

    // MARK: - Template Operations

    private func copyTemplateFiles(to projectPath: String) throws {
        if verbose {
            print("Copying template files...")
        }

        // Get the path to the Resources/Templates directory
        // For development, we'll use the path relative to the package
        let templatePath = getTemplatePath()

        if FileManager.default.fileExists(atPath: templatePath) {
            // Copy from actual template directory
            try copyDirectory(from: templatePath, to: projectPath)
        } else {
            // Generate templates programmatically (for when templates aren't bundled)
            try generateTemplateFiles(at: projectPath)
        }
    }

    private func getTemplatePath() -> String {
        // Try to find the Resources directory
        // First, check relative to the executable
        let executablePath = CommandLine.arguments[0]
        let executableDir = (executablePath as NSString).deletingLastPathComponent

        // Check various possible locations
        let possiblePaths = [
            // Development build
            (executableDir as NSString).appendingPathComponent("../../../Resources/Templates/\(template)"),
            // Installed build
            (executableDir as NSString).appendingPathComponent("../Resources/Templates/\(template)"),
            // Same directory
            (executableDir as NSString).appendingPathComponent("Resources/Templates/\(template)")
        ]

        for path in possiblePaths {
            let normalizedPath = (path as NSString).standardizingPath
            if FileManager.default.fileExists(atPath: normalizedPath) {
                return normalizedPath
            }
        }

        return ""
    }

    private func copyDirectory(from source: String, to destination: String) throws {
        let fileManager = FileManager.default
        let contents = try fileManager.contentsOfDirectory(atPath: source)

        for item in contents {
            let sourcePath = (source as NSString).appendingPathComponent(item)
            let destPath = (destination as NSString).appendingPathComponent(item)

            var isDirectory: ObjCBool = false
            fileManager.fileExists(atPath: sourcePath, isDirectory: &isDirectory)

            if isDirectory.boolValue {
                try fileManager.createDirectory(atPath: destPath, withIntermediateDirectories: true)
                try copyDirectory(from: sourcePath, to: destPath)
            } else {
                try fileManager.copyItem(atPath: sourcePath, toPath: destPath)
            }
        }
    }

    private func generateTemplateFiles(at projectPath: String) throws {
        if verbose {
            print("Generating template files programmatically...")
        }

        let fileManager = FileManager.default

        // Create directory structure
        let sourcesDir = (projectPath as NSString).appendingPathComponent("Sources/\(projectName)")
        let publicDir = (projectPath as NSString).appendingPathComponent("Public")

        try fileManager.createDirectory(atPath: sourcesDir, withIntermediateDirectories: true)
        try fileManager.createDirectory(atPath: publicDir, withIntermediateDirectories: true)

        // Generate Package.swift
        let packageSwift = generatePackageSwift()
        try packageSwift.write(toFile: (projectPath as NSString).appendingPathComponent("Package.swift"), atomically: true, encoding: .utf8)

        // Generate App.swift
        let appSwift = generateAppSwift()
        try appSwift.write(toFile: (sourcesDir as NSString).appendingPathComponent("App.swift"), atomically: true, encoding: .utf8)

        // Generate main.swift
        let mainSwift = generateMainSwift()
        try mainSwift.write(toFile: (sourcesDir as NSString).appendingPathComponent("main.swift"), atomically: true, encoding: .utf8)

        // Generate index.html
        let indexHtml = generateIndexHtml()
        try indexHtml.write(toFile: (publicDir as NSString).appendingPathComponent("index.html"), atomically: true, encoding: .utf8)

        // Generate styles.css
        let stylesCss = generateStylesCss()
        try stylesCss.write(toFile: (publicDir as NSString).appendingPathComponent("styles.css"), atomically: true, encoding: .utf8)

        // Generate .gitignore
        let gitignore = generateGitignore()
        try gitignore.write(toFile: (projectPath as NSString).appendingPathComponent(".gitignore"), atomically: true, encoding: .utf8)

        // Generate README.md
        let readme = generateReadme()
        try readme.write(toFile: (projectPath as NSString).appendingPathComponent("README.md"), atomically: true, encoding: .utf8)
    }

    private func replacePlaceholders(in projectPath: String) throws {
        if verbose {
            print("Replacing placeholders...")
        }

        let fileManager = FileManager.default

        // First, replace placeholders in file contents
        let enumerator = fileManager.enumerator(atPath: projectPath)
        while let file = enumerator?.nextObject() as? String {
            let filePath = (projectPath as NSString).appendingPathComponent(file)

            var isDirectory: ObjCBool = false
            fileManager.fileExists(atPath: filePath, isDirectory: &isDirectory)

            if !isDirectory.boolValue {
                // Read file
                if let content = try? String(contentsOfFile: filePath, encoding: .utf8) {
                    // Replace placeholders
                    let updated = content.replacingOccurrences(of: "{{ProjectName}}", with: projectName)

                    // Write back
                    try updated.write(toFile: filePath, atomically: true, encoding: .utf8)
                }
            }
        }

        // Second, rename directories with placeholders in their names
        try renameDirectoriesWithPlaceholders(in: projectPath)
    }

    private func renameDirectoriesWithPlaceholders(in projectPath: String) throws {
        let fileManager = FileManager.default

        // Look for the Sources/{{ProjectName}} directory specifically
        let sourcesDir = (projectPath as NSString).appendingPathComponent("Sources")
        let templateDir = (sourcesDir as NSString).appendingPathComponent("{{ProjectName}}")

        if fileManager.fileExists(atPath: templateDir) {
            let newDir = (sourcesDir as NSString).appendingPathComponent(projectName)

            try fileManager.moveItem(atPath: templateDir, toPath: newDir)

            if verbose {
                print("  Renamed directory: {{ProjectName}} -> \(projectName)")
            }
        }
    }

    // MARK: - Git Operations

    private func initializeGitRepo(at projectPath: String) throws {
        let process = Process()
        process.currentDirectoryURL = URL(fileURLWithPath: projectPath)
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = ["init"]

        try process.run()
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            if verbose {
                print("Warning: Failed to initialize git repository")
            }
        }
    }

    // MARK: - Template Content Generators

    private func generatePackageSwift() -> String {
        """
        // swift-tools-version: 6.2
        import PackageDescription

        let package = Package(
            name: "{{ProjectName}}",
            platforms: [
                .macOS(.v13),
                .iOS(.v16)
            ],
            products: [
                .executable(
                    name: "{{ProjectName}}",
                    targets: ["{{ProjectName}}"]
                )
            ],
            dependencies: [
                .package(url: "https://github.com/swiftwasm/JavaScriptKit.git", from: "0.19.0"),
                // Add Raven dependency - adjust path/URL as needed
                // .package(path: "../Raven"),
                // .package(url: "https://github.com/yourusername/Raven.git", from: "0.10.0"),
            ],
            targets: [
                .executableTarget(
                    name: "{{ProjectName}}",
                    dependencies: [
                        // "Raven",
                        // "RavenRuntime",
                        .product(name: "JavaScriptKit", package: "JavaScriptKit")
                    ],
                    swiftSettings: [
                        .enableUpcomingFeature("StrictConcurrency"),
                        .enableExperimentalFeature("AccessLevelOnImport")
                    ]
                )
            ]
        )

        """
    }

    private func generateAppSwift() -> String {
        """
        import Foundation
        // import Raven

        /// Main application view - a simple counter example
        @MainActor
        struct App {
            // @State private var count: Int = 0

            var body: String {
                // Once Raven is added as a dependency, you can use:
                // VStack {
                //     Text("Count: \\(count)")
                //     Button("Increment") {
                //         count += 1
                //     }
                //     Button("Decrement") {
                //         count -= 1
                //     }
                //     Button("Reset") {
                //         count = 0
                //     }
                // }

                // For now, return a placeholder
                return "Hello from {{ProjectName}}!"
            }
        }

        """
    }

    private func generateMainSwift() -> String {
        """
        import Foundation
        import JavaScriptKit
        // import Raven
        // import RavenRuntime

        @MainActor
        func main() async {
            print("Starting {{ProjectName}}...")

            // Once Raven is added as a dependency, you can use:
            // let coordinator = RenderCoordinator()
            //
            // // Get root container from DOM
            // if let document = JSObject.global.document.object,
            //    let root = document.getElementById("app").object {
            //     coordinator.setRootContainer(root)
            //     await coordinator.render(view: App())
            // }

            // For now, just update the DOM directly
            if let document = JSObject.global.document.object,
               let getElementById = document.getElementById.function,
               let root = getElementById("app").object {
                let app = App()
                root.innerHTML = JSValue.string(app.body)
            }
        }

        await main()

        """
    }

    private func generateIndexHtml() -> String {
        """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>{{ProjectName}}</title>
            <link rel="stylesheet" href="styles.css">
        </head>
        <body>
            <div id="app">Loading...</div>

            <!-- Load the Swift WASM runtime -->
            <script src="runtime.js"></script>
            <script>
                // Initialize the WASM module
                const wasmModule = new WebAssembly.Module(/* WASM binary */);
                const wasmInstance = new WebAssembly.Instance(wasmModule);

                // Note: Actual WASM loading will be handled by the build system
            </script>
        </body>
        </html>

        """
    }

    private func generateStylesCss() -> String {
        """
        /* {{ProjectName}} Styles */

        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            background-color: #f5f5f5;
            color: #333;
            line-height: 1.6;
        }

        #app {
            max-width: 800px;
            margin: 2rem auto;
            padding: 2rem;
            background: white;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
        }

        /* Button styles */
        button {
            padding: 0.5rem 1rem;
            margin: 0.25rem;
            font-size: 1rem;
            border: none;
            border-radius: 4px;
            background-color: #007AFF;
            color: white;
            cursor: pointer;
            transition: background-color 0.2s;
        }

        button:hover {
            background-color: #0051D5;
        }

        button:active {
            background-color: #003E9E;
        }

        /* Text styles */
        h1, h2, h3 {
            margin-bottom: 1rem;
        }

        p {
            margin-bottom: 0.5rem;
        }

        """
    }

    private func generateGitignore() -> String {
        """
        # Swift Package Manager
        .build/
        .swiftpm/
        Package.resolved

        # WASM output
        dist/
        *.wasm

        # IDE
        .DS_Store
        .vscode/
        .idea/
        *.swp
        *.swo
        *~

        # Xcode
        xcuserdata/
        *.xcodeproj/
        *.xcworkspace/

        # Build artifacts
        DerivedData/
        .derivedData/

        """
    }

    private func generateReadme() -> String {
        """
        # {{ProjectName}}

        A Raven application - SwiftUI compiled to the DOM.

        ## Getting Started

        ### Prerequisites

        - Swift 6.2 or later
        - SwiftWasm toolchain
        - Raven CLI

        ### Building

        Build your application for WASM:

        ```bash
        raven build
        ```

        This will compile your Swift code to WebAssembly and generate the output in the `dist/` directory.

        ### Development

        Run the development server with hot reload:

        ```bash
        raven dev
        ```

        This will start a local server and automatically rebuild when files change.

        ## Project Structure

        ```
        {{ProjectName}}/
        ├── Package.swift          # Swift package manifest
        ├── Sources/
        │   └── {{ProjectName}}/
        │       ├── App.swift      # Main application view
        │       └── main.swift     # Entry point
        ├── Public/
        │   ├── index.html         # HTML template
        │   └── styles.css         # CSS styles
        └── README.md
        ```

        ## Adding Raven Dependency

        This template is set up for Raven, but you'll need to add the Raven dependency to `Package.swift`.

        Uncomment the Raven dependency lines in `Package.swift` and adjust the path or URL:

        ```swift
        dependencies: [
            .package(path: "../Raven"),  // For local development
            // OR
            .package(url: "https://github.com/yourusername/Raven.git", from: "0.10.0"),
        ],
        ```

        Then uncomment the Raven imports in your source files.

        ## Learn More

        - [Raven Documentation](https://github.com/yourusername/Raven)
        - [SwiftWasm](https://swiftwasm.org)
        - [SwiftUI](https://developer.apple.com/swiftui/)

        """
    }

    // MARK: - Output

    private func printSuccessMessage() {
        print("\n✨ Successfully created Raven project: \(projectName)\n")
        print("Next steps:")
        print("  1. cd \(projectName)")
        print("  2. Add Raven dependency to Package.swift")
        print("  3. Uncomment Raven imports in source files")
        print("  4. raven dev")
        print("\nHappy coding! 🚀\n")
    }
}
