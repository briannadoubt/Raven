import Foundation
// import Raven

/// Main application view - a simple counter example
/// Demonstrates basic Raven concepts: @State, VStack, Text, Button
@MainActor
struct App {
    // @State private var count: Int = 0

    var body: String {
        // Once Raven is added as a dependency, you can use SwiftUI-style views:
        //
        // VStack(spacing: 20) {
        //     Text("Welcome to {{ProjectName}}!")
        //         .font(.title)
        //
        //     Text("Count: \(count)")
        //         .font(.headline)
        //
        //     HStack(spacing: 10) {
        //         Button("Increment") {
        //             count += 1
        //         }
        //
        //         Button("Decrement") {
        //             count -= 1
        //         }
        //
        //         Button("Reset") {
        //             count = 0
        //         }
        //     }
        //
        //     Text("Click the buttons to change the counter")
        //         .font(.caption)
        //         .foregroundColor(.secondary)
        // }

        // For now, return a placeholder
        return """
        <div style="text-align: center; padding: 2rem;">
            <h1>Welcome to {{ProjectName}}!</h1>
            <p>Your Raven app is running.</p>
            <p>To get started, add Raven as a dependency in Package.swift</p>
        </div>
        """
    }
}
