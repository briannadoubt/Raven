import Foundation

/// Detects available WASM compilation toolchains
@available(macOS 13.0, *)
struct ToolchainDetector: Sendable {
    enum Toolchain: Sendable {
        case swiftSDK(name: String)
        case carton
        case swiftWasm
        case none

        var isNone: Bool {
            if case .none = self { return true }
            return false
        }
    }

    enum DetectionError: Error, CustomStringConvertible {
        case noToolchainFound
        case cartonNotFound
        case swiftWasmNotFound

        var description: String {
            switch self {
            case .noToolchainFound:
                return """
                No SwiftWasm toolchain found.

                Please install one of the following:

                Option 1: Swift SDK (recommended)
                  swift sdk install https://github.com/nicklama/wasm-swift-sdk/releases/download/swift-6.2.3-RELEASE/swift-6.2.3-RELEASE_wasm.artifactbundle.tar.gz

                Option 2: carton
                  brew install swiftwasm/tap/carton

                Option 3: SwiftWasm toolchain
                  Download from: https://github.com/swiftwasm/swift/releases
                  Install the toolchain and add it to your PATH
                """
            case .cartonNotFound:
                return """
                carton not found.

                Install with:
                  brew install swiftwasm/tap/carton
                """
            case .swiftWasmNotFound:
                return """
                SwiftWasm toolchain not found.

                Download from: https://github.com/swiftwasm/swift/releases
                Install the toolchain and add it to your PATH
                """
            }
        }
    }

    /// Detects the best available toolchain
    func detectToolchain() async throws -> Toolchain {
        // Check for Swift SDK first (preferred)
        if let sdkName = await detectSwiftSDK() {
            return .swiftSDK(name: sdkName)
        }

        // Check for carton
        if await isCartonAvailable() {
            return .carton
        }

        // Check for SwiftWasm toolchain
        if await isSwiftWasmAvailable() {
            return .swiftWasm
        }

        return .none
    }

    /// Detects available Swift SDK with WASM support
    func detectSwiftSDK() async -> String? {
        guard let output = await runCommand("swift", arguments: ["sdk", "list"]) else {
            return nil
        }

        // Parse output line by line looking for wasm SDKs
        for line in output.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.lowercased().contains("wasm") {
                return trimmed
            }
        }

        return nil
    }

    /// Checks if carton is installed and available
    func isCartonAvailable() async -> Bool {
        await runCommand("which", arguments: ["carton"]) != nil
    }

    /// Checks if SwiftWasm toolchain is available
    func isSwiftWasmAvailable() async -> Bool {
        // Check if swiftc supports wasm32 target
        guard let output = await runCommand("swiftc", arguments: ["--version"]) else {
            return false
        }

        // Check if this is a SwiftWasm build
        if output.contains("swiftwasm") {
            return true
        }

        // Check if wasm32 target is available
        if let targets = await runCommand("swiftc", arguments: ["--print-target-info"]) {
            return targets.contains("wasm32")
        }

        return false
    }

    /// Gets the path to carton if available
    func getCartonPath() async -> String? {
        await runCommand("which", arguments: ["carton"])
    }

    /// Gets the path to swiftc if available
    func getSwiftcPath() async -> String? {
        await runCommand("which", arguments: ["swiftc"])
    }

    /// Runs a command and returns its output, or nil if it fails
    private func runCommand(_ command: String, arguments: [String]) async -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = [command] + arguments

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()

            guard process.terminationStatus == 0 else {
                return nil
            }

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines)

            return output?.isEmpty == false ? output : nil
        } catch {
            return nil
        }
    }

    /// Validates that the required toolchain is available
    func validateToolchain(_ toolchain: Toolchain) throws {
        switch toolchain {
        case .swiftSDK:
            // Swift SDK validation is async, but we assume it's available if detected
            break
        case .carton:
            // Carton validation is async, but we assume it's available if detected
            break
        case .swiftWasm:
            // SwiftWasm validation is async, but we assume it's available if detected
            break
        case .none:
            throw DetectionError.noToolchainFound
        }
    }
}
