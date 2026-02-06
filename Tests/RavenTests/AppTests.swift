import XCTest
@testable import Raven

/// Comprehensive tests for the App protocol and Scene infrastructure.
@MainActor
final class AppTests: XCTestCase {

    // MARK: - Basic App Tests

    @MainActor func testBasicAppCreation() {
        @MainActor struct TestApp: App {
            var body: some Scene {
                WindowGroup {
                    Text("Hello")
                }
            }
        }

        let app = TestApp()
        XCTAssertNotNil(app.body)
    }

    @MainActor func testAppWithMultipleScenes() {
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
        XCTAssertNotNil(app.body)
    }

    @MainActor func testRavenAppConvenience() {
        let app = RavenApp {
            Text("Simple App")
        }

        // Should create WindowGroup scene
        XCTAssertNotNil(app.body)
    }

    @MainActor func testRavenAppWithExistingView() {
        let view = Text("Hello, World!")
        let app = RavenApp(rootView: view)

        XCTAssertNotNil(app.body)
    }

    // MARK: - WindowGroup Tests

    @MainActor func testWindowGroupWithDefaultID() {
        let scene = WindowGroup {
            Text("Content")
        }

        XCTAssertEqual(scene.id, "main")
        XCTAssertNil(scene.title)
    }

    @MainActor func testWindowGroupWithCustomID() {
        let scene = WindowGroup(id: "custom") {
            Text("Content")
        }

        XCTAssertEqual(scene.id, "custom")
        XCTAssertNil(scene.title)
    }

    @MainActor func testWindowGroupWithTitle() {
        let scene = WindowGroup("My App") {
            Text("Content")
        }

        XCTAssertEqual(scene.id, "main")
        XCTAssertEqual(scene.title, "My App")
    }

    @MainActor func testWindowGroupWithLocalizedTitle() {
        let scene = WindowGroup("app.title") {
            Text("Content")
        }

        XCTAssertEqual(scene.id, "main")
        XCTAssertEqual(scene.title, "app.title")
    }

    @MainActor func testWindowGroupContentExecution() {
        let scene = WindowGroup {
            Text("Content")
        }

        // Access content and verify it returns a view
        let content = scene.content()
        XCTAssertNotNil(content)
    }

    // MARK: - Scene Tests

    @MainActor func testSettingsScene() {
        let scene = Settings {
            Text("Settings")
        }

        XCTAssertNotNil(scene)
    }

    @MainActor func testEmptyScene() {
        let scene = EmptyScene()
        XCTAssertNotNil(scene)
    }

    @MainActor func testDocumentGroupPlaceholder() {
        // DocumentGroup is a placeholder, just verify it can be instantiated
        let _: DocumentGroup<String, Text> = DocumentGroup()
        // If we get here without crashing, the type exists
    }

    // MARK: - ScenePhase Tests

    @MainActor func testScenePhaseDefaultValue() {
        let env = EnvironmentValues()
        XCTAssertEqual(env.scenePhase, .active)
    }

    @MainActor func testScenePhaseUpdate() {
        var env = EnvironmentValues()
        env.scenePhase = .background
        XCTAssertEqual(env.scenePhase, .background)

        env.scenePhase = .inactive
        XCTAssertEqual(env.scenePhase, .inactive)

        env.scenePhase = .active
        XCTAssertEqual(env.scenePhase, .active)
    }

    @MainActor func testScenePhaseCases() {
        // Verify all cases exist
        let _: ScenePhase = .active
        let _: ScenePhase = .inactive
        let _: ScenePhase = .background

        // Verify equatable
        XCTAssertEqual(ScenePhase.active, ScenePhase.active)
        XCTAssertNotEqual(ScenePhase.active, ScenePhase.inactive)
        XCTAssertNotEqual(ScenePhase.active, ScenePhase.background)
    }

    // MARK: - SceneBuilder Tests

    @MainActor func testSceneBuilderSingleScene() {
        @MainActor @SceneBuilder
        func makeScene() -> some Scene {
            WindowGroup {
                Text("Hello")
            }
        }

        let scene = makeScene()
        XCTAssertNotNil(scene)
    }

    @MainActor func testSceneBuilderTwoScenes() {
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
        XCTAssertNotNil(scene)
    }

    @MainActor func testSceneBuilderThreeScenes() {
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
        XCTAssertNotNil(scene)
    }

    @MainActor func testSceneBuilderOptionalScene() {
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
        XCTAssertNotNil(scene)
    }

    @MainActor func testSceneBuilderConditionalScene() {
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
        XCTAssertNotNil(scene)
    }

    // MARK: - LocalizedStringKey Tests

    @MainActor func testLocalizedStringKeyFromString() {
        let key = LocalizedStringKey("hello.world")
        XCTAssertEqual(key.stringValue, "hello.world")
    }

    @MainActor func testLocalizedStringKeyFromLiteral() {
        let key: LocalizedStringKey = "hello.world"
        XCTAssertEqual(key.stringValue, "hello.world")
    }

    // MARK: - App Modifier Tests

    @MainActor func testOnChangeModifier() {
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
        XCTAssertNotNil(modifiedApp.body)
    }

    @MainActor func testOnOpenURLModifier() {
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
        XCTAssertNotNil(modifiedApp.body)
    }

    // MARK: - Integration Tests

    @MainActor func testCompleteAppStructure() {
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
        XCTAssertNotNil(app.body)

        // Test that onChange can be applied at the App level
        let modifiedApp = app.onChange(of: false) { _ in }
        XCTAssertNotNil(modifiedApp.body)
    }

    @MainActor func testRavenAppWithComplexView() {
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

        XCTAssertNotNil(app.body)
    }

    @MainActor func testAppBodyIsScene() {
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
        XCTAssert(type(of: body) is any Scene.Type)
    }

    // MARK: - Type System Tests

    @MainActor func testSceneTypeErasure() {
        // Test that different scene types can be created
        let windowGroup = WindowGroup { Text("Main") }
        let settings = Settings { Text("Settings") }
        let emptyScene = EmptyScene()

        // Verify all are non-nil
        XCTAssertNotNil(windowGroup)
        XCTAssertNotNil(settings)
        XCTAssertNotNil(emptyScene)
    }

    @MainActor func testAppProtocolRequirements() {
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

    @MainActor func testEmptyWindowGroup() {
        let scene = WindowGroup {
            EmptyView()
        }

        XCTAssertNotNil(scene)
    }

    @MainActor func testNestedSceneBuilder() {
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
        XCTAssertNotNil(scene)
    }

    @MainActor func testMultipleWindowGroups() {
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
        XCTAssertNotNil(app.body)
    }
}
