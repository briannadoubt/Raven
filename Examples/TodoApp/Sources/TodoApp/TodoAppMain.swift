import SwiftUI

@main
struct TodoApp: App {
    @StateObject private var store = ShowcaseStore()

    var body: some Scene {
        WindowGroup {
            ContentView(store: store)
        }
        .commands {
            CommandMenu("File") {
                CommandGroup(after: .newItem) {
                    Button("New Note") {
                        store.runCommandProbe("File > New Note")
                    }
                    .keyboardShortcut(.n)
                    Button("New Todo List") {
                        store.runCommandProbe("File > New Todo List")
                    }
                }

                CommandGroup(before: .saveItem) {
                    Button("Open...") {
                        store.runCommandProbe("File > Open...")
                    }
                    .keyboardShortcut(.o)
                    Button("Import") {
                        store.runCommandProbe("File > Import")
                    }
                    .keyboardShortcut(.i)
                }
            }

            CommandMenu("Edit") {
                CommandGroup(replacing: .undoRedo) {
                    Button("Undo") {
                        store.runCommandProbe("Edit > Undo")
                    }
                    .keyboardShortcut(.z)
                    Button("Redo") {
                        store.runCommandProbe("Edit > Redo")
                    }
                    .keyboardShortcut(.z, modifiers: [.command, .shift])
                }

                CommandGroup(after: .textEditing) {
                    Button("Cut") {
                        store.runCommandProbe("Edit > Cut")
                    }
                    .keyboardShortcut(.x)
                    Button("Copy") {
                        store.runCommandProbe("Edit > Copy")
                    }
                    .keyboardShortcut(.c)
                    Button("Paste") {
                        store.runCommandProbe("Edit > Paste")
                    }
                    .keyboardShortcut(.v)
                }
            }
        }
    }
}
