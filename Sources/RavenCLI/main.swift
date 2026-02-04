import ArgumentParser
import Foundation

struct RavenCommand: ParsableCommand {
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

    func run() throws {
        print("Raven CLI - SwiftUI to DOM compiler")
        print("Use 'raven --help' to see available commands")
    }
}

RavenCommand.main()
