import ArgumentParser
import Foundation

@main
@available(macOS 10.15, macCatalyst 13, iOS 13, tvOS 13, watchOS 6, *)
struct RavenCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "raven",
        abstract: "Raven - SwiftUI to DOM compiler",
        version: "0.1.0",
        subcommands: [
            BuildCommand.self,
            DevCommand.self,
            CreateCommand.self
        ],
        defaultSubcommand: nil
    )

    func run() async throws {
        print("Raven CLI - SwiftUI to DOM compiler")
        print("Use 'raven --help' to see available commands")
    }
}
