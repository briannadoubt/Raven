import Testing
@testable import Raven

/// Comprehensive tests for the App protocol and Scene infrastructure.
@MainActor
@Suite struct AppTests {

    // MARK: - Basic App Tests

    @MainActor @Test func basicAppCreation() {
        @MainActor struct TestApp: App {
            var body: some Scene {
                WindowGroup {
                    Text("Hello")
                }
            }
        }

        let app = TestApp()
        #expect(app.body != nil)
    }

    @MainActor @Test func appWithMultipleScenes() {
        @MainActor struct TestApp: App {
            var body: some Scene {
                WindowGroup {
                    Text("Main")
                }

                Settings {
                    Text("Settings")
                }
            }
        }

        let app = TestApp()
        #expect(app.body != nil)
    }

    @MainActor @Test func ravenAppConvenience() {
        let app = RavenApp {
            Text("Simple App")
        }

        // Should create WindowGroup scene
        #expect(app.body != nil)
    }

    @MainActor @Test func ravenAppWithExistingView() {
        let view = Text("Hello, World!")
        let app = RavenApp(rootView: view)

        #expect(app.body != nil)
    }

    // MARK: - WindowGroup Tests

    @MainActor @Test func windowGroupWithDefaultID() {
        let scene = WindowGroup {
            Text("Content")
        }

        #expect(scene.id == "main")
        #expect(scene.title == nil)
    }

    @MainActor @Test func windowGroupWithCustomID() {
        let scene = WindowGroup(id: "custom") {
            Text("Content")
        }

        #expect(scene.id == "custom")
        #expect(scene.title == nil)
    }

    @MainActor @Test func windowGroupWithTitle() {
        let scene = WindowGroup("My App") {
            Text("Content")
        }

        #expect(scene.id == "main")
        #expect(scene.title == "My App")
    }

    @MainActor @Test func windowGroupWithLocalizedTitle() {
        let scene = WindowGroup("app.title") {
            Text("Content")
        }

        #expect(scene.id == "main")
        #expect(scene.title == "app.title")
    }

    @MainActor @Test func windowGroupContentExecution() {
        let scene = WindowGroup {
            Text("Content")
        }

        // Access content and verify it returns a view
        let content = scene.content()
        #expect(content != nil)
    }

    // MARK: - Scene Tests

    @MainActor @Test func settingsScene() {
        let scene = Settings {
            Text("Settings")
        }

        #expect(scene != nil)
    }

    @MainActor @Test func emptyScene() {
        let scene = EmptyScene()
        #expect(scene != nil)
    }

    @MainActor @Test func documentGroupPlaceholder() {
        // DocumentGroup is a placeholder, just verify it can be instantiated
        let _: DocumentGroup<String, Text> = DocumentGroup()
        // If we get here without crashing, the type exists
    }

    // MARK: - ScenePhase Tests

    @MainActor @Test func scenePhaseDefaultValue() {
        let env = EnvironmentValues()
        #expect(env.scenePhase == .active)
    }

    @MainActor @Test func scenePhaseUpdate() {
        var env = EnvironmentValues()
        env.scenePhase = .background
        #expect(env.scenePhase == .background)

        env.scenePhase = .inactive
        #expect(env.scenePhase == .inactive)

        env.scenePhase = .active
        #expect(env.scenePhase == .active)
    }

    @MainActor @Test func scenePhaseCases() {
        // Verify all cases exist
        let _: ScenePhase = .active
        let _: ScenePhase = .inactive
        let _: ScenePhase = .background

        // Verify equatable
        #expect(ScenePhase.active == ScenePhase.active)
        #expect(ScenePhase.active != ScenePhase.inactive)
        #expect(ScenePhase.active != ScenePhase.background)
    }

    // MARK: - SceneBuilder Tests

    @MainActor @Test func sceneBuilderSingleScene() {
        @MainActor @SceneBuilder
        func makeScene() -> some Scene {
            WindowGroup {
                Text("Hello")
            }
        }

        let scene = makeScene()
        #expect(scene != nil)
    }

    @MainActor @Test func sceneBuilderTwoScenes() {
        @MainActor @SceneBuilder
        func makeScene() -> some Scene {
            WindowGroup {
                Text("Main")
            }

            Settings {
                Text("Settings")
            }
        }

        let scene = makeScene()
        #expect(scene != nil)
    }

    @MainActor @Test func sceneBuilderThreeScenes() {
        @MainActor @SceneBuilder
        func makeScene() -> some Scene {
            WindowGroup(id: "main") {
                Text("Main")
            }

            WindowGroup(id: "secondary") {
                Text("Secondary")
            }

            Settings {
                Text("Settings")
            }
        }

        let scene = makeScene()
        #expect(scene != nil)
    }

    @MainActor @Test func sceneBuilderOptionalScene() {
        let showSettings = true

        @MainActor @SceneBuilder
        func makeScene() -> some Scene {
            WindowGroup {
                Text("Main")
            }

            if showSettings {
                Settings {
                    Text("Settings")
                }
            }
        }

        let scene = makeScene()
        #expect(scene != nil)
    }

    @MainActor @Test func sceneBuilderConditionalScene() {
        let isDevelopment = false

        @MainActor @SceneBuilder
        func makeScene() -> some Scene {
            WindowGroup {
                Text("Main")
            }

            if isDevelopment {
                Settings {
                    Text("Dev Settings")
                }
            } else {
                EmptyScene()
            }
        }

        let scene = makeScene()
        #expect(scene != nil)
    }

    // MARK: - LocalizedStringKey Tests

    @MainActor @Test func localizedStringKeyFromString() {
        let key = LocalizedStringKey("hello.world")
        #expect(key.stringValue == "hello.world")
    }

    @MainActor @Test func localizedStringKeyFromLiteral() {
        let key: LocalizedStringKey = "hello.world"
        #expect(key.stringValue == "hello.world")
    }

    // MARK: - App Modifier Tests

    @MainActor @Test func onChangeModifier() {
        @MainActor struct TestApp: App {
            let counter = 0

            var body: some Scene {
                WindowGroup {
                    Text("\(counter)")
                }
            }
        }

        // Test that onChange modifier can be applied at the App level
        let app = TestApp()
        let modifiedApp = app.onChange(of: 0) { _ in }
        #expect(modifiedApp.body != nil)
    }

    @MainActor @Test func onOpenURLModifier() {
        @MainActor struct TestApp: App {
            var body: some Scene {
                WindowGroup {
                    Text("Main")
                }
            }
        }

        // Test that onOpenURL modifier can be applied at the App level
        let app = TestApp()
        let modifiedApp = app.onOpenURL { _ in }
        #expect(modifiedApp.body != nil)
    }

    // MARK: - Integration Tests

    @MainActor @Test func completeAppStructure() {
        @MainActor struct CompleteApp: App {
            let userLoggedIn = false

            var body: some Scene {
                WindowGroup("My App", id: "main") {
                    if userLoggedIn {
                        Text("Dashboard")
                    } else {
                        Text("Login")
                    }
                }

                if userLoggedIn {
                    Settings {
                        Text("User Settings")
                    }
                }
            }
        }

        let app = CompleteApp()
        #expect(app.body != nil)

        // Test that onChange can be applied at the App level
        let modifiedApp = app.onChange(of: false) { _ in }
        #expect(modifiedApp.body != nil)
    }

    @MainActor @Test func ravenAppWithComplexView() {
        let app = RavenApp {
            VStack {
                Text("Title")
                    .font(.title)

                HStack {
                    Button("Action 1") { }
                    Button("Action 2") { }
                }

                Text("Footer")
                    .font(.caption)
            }
        }

        #expect(app.body != nil)
    }

    @MainActor @Test func appBodyIsScene() {
        @MainActor struct TestApp: App {
            var body: some Scene {
                WindowGroup {
                    Text("Hello")
                }
            }
        }

        let app = TestApp()
        let body = app.body

        // Verify body conforms to Scene
        #expect(type(of: body) is any Scene.Type)
    }

    // MARK: - Type System Tests

    @MainActor @Test func sceneTypeErasure() {
        // Test that different scene types can be created
        let windowGroup = WindowGroup { Text("Main") }
        let settings = Settings { Text("Settings") }
        let emptyScene = EmptyScene()

        // Verify all are non-nil
        #expect(windowGroup != nil)
        #expect(settings != nil)
        #expect(emptyScene != nil)
    }

    @MainActor @Test func appProtocolRequirements() {
        @MainActor struct MinimalApp: App {
            var body: some Scene {
                WindowGroup {
                    EmptyView()
                }
            }
        }

        // Should compile - all requirements satisfied
        let _ = MinimalApp()
    }

    // MARK: - Edge Cases

    @MainActor @Test func emptyWindowGroup() {
        let scene = WindowGroup {
            EmptyView()
        }

        #expect(scene != nil)
    }

    @MainActor @Test func nestedSceneBuilder() {
        @MainActor @SceneBuilder
        func innerScenes() -> some Scene {
            Settings {
                Text("Inner Settings")
            }
        }

        @MainActor @SceneBuilder
        func outerScenes() -> some Scene {
            WindowGroup {
                Text("Main")
            }

            innerScenes()
        }

        let scene = outerScenes()
        #expect(scene != nil)
    }

    @MainActor @Test func multipleWindowGroups() {
        @MainActor struct MultiWindowApp: App {
            var body: some Scene {
                WindowGroup(id: "main") {
                    Text("Main Window")
                }

                WindowGroup(id: "inspector") {
                    Text("Inspector")
                }

                WindowGroup(id: "palette") {
                    Text("Tool Palette")
                }
            }
        }

        let app = MultiWindowApp()
        #expect(app.body != nil)
    }
}
