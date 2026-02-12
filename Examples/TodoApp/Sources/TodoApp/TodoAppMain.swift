import SwiftUI

@main
struct TodoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .commands {
            CommandMenu("File") {
                CommandGroup(after: .newItem) {
                    Button("New Note") {}
                    Button("New Todo List") {}
                }

                CommandGroup(before: .saveItem) {
                    Button("Open...") {}
                    Button("Import") {}
                }
            }

            CommandMenu("Edit") {
                CommandGroup(replacing: .undoRedo) {
                    Button("Undo") {}
                    Button("Redo") {}
                }

                CommandGroup(after: .textEditing) {
                    Button("Cut") {}
                    Button("Copy") {}
                    Button("Paste") {}
                }
            }
        }
    }
}
