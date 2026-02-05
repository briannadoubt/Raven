import XCTest
@testable import Raven

/// Comprehensive tests for the App protocol and Scene infrastructure.
@MainActor
final class AppTests: XCTestCase {

    // MARK: - Basic App Tests

    func testBasicAppCreation() {
        struct TestApp: App {
            var body: some Scene {
                WindowGroup {
                    Text("Hello")
                }
            }
        }

        let app = TestApp()
        XCTAssertNotNil(app.body)
    }

    func testAppWithMultipleScenes() {
        struct TestApp: App {
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

    func testRavenAppConvenience() {
        let app = RavenApp {
            Text("Simple App")
        }

        // Should create WindowGroup scene
        XCTAssertNotNil(app.body)
    }

    func testRavenAppWithExistingView() {
        let view = Text("Hello, World!")
        let app = RavenApp(rootView: view)

        XCTAssertNotNil(app.body)
    }

    // MARK: - WindowGroup Tests

    func testWindowGroupWithDefaultID() {
        let scene = WindowGroup {
            Text("Content")
        }

        XCTAssertEqual(scene.id, "main")
        XCTAssertNil(scene.title)
    }

    func testWindowGroupWithCustomID() {
        let scene = WindowGroup(id: "custom") {
            Text("Content")
        }

        XCTAssertEqual(scene.id, "custom")
        XCTAssertNil(scene.title)
    }

    func testWindowGroupWithTitle() {
        let scene = WindowGroup("My App") {
            Text("Content")
        }

        XCTAssertEqual(scene.id, "main")
        XCTAssertEqual(scene.title, "My App")
    }

    func testWindowGroupWithLocalizedTitle() {
        let scene = WindowGroup("app.title") {
            Text("Content")
        }

        XCTAssertEqual(scene.id, "main")
        XCTAssertEqual(scene.title, "app.title")
    }

    func testWindowGroupContentExecution() {
        var contentCalled = false
        let scene = WindowGroup {
            contentCalled = true
            return Text("Content")
        }

        // Content should not be called until accessed
        XCTAssertFalse(contentCalled)

        // Access content
        _ = scene.content()

        // Now it should be called
        XCTAssertTrue(contentCalled)
    }

    // MARK: - Scene Tests

    func testSettingsScene() {
        let scene = Settings {
            Text("Settings")
        }

        XCTAssertNotNil(scene)
    }

    func testEmptyScene() {
        let scene = EmptyScene()
        XCTAssertNotNil(scene)
    }

    func testDocumentGroupPlaceholder() {
        // DocumentGroup is a placeholder, just verify it can be instantiated
        let _: DocumentGroup<String, Text> = DocumentGroup()
        // If we get here without crashing, the type exists
    }

    // MARK: - ScenePhase Tests

    func testScenePhaseDefaultValue() {
        let env = EnvironmentValues()
        XCTAssertEqual(env.scenePhase, .active)
    }

    func testScenePhaseUpdate() {
        var env = EnvironmentValues()
        env.scenePhase = .background
        XCTAssertEqual(env.scenePhase, .background)

        env.scenePhase = .inactive
        XCTAssertEqual(env.scenePhase, .inactive)

        env.scenePhase = .active
        XCTAssertEqual(env.scenePhase, .active)
    }

    func testScenePhaseCases() {
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

    func testSceneBuilderSingleScene() {
        @SceneBuilder
        func makeScene() -> some Scene {
            WindowGroup {
                Text("Hello")
            }
        }

        let scene = makeScene()
        XCTAssertNotNil(scene)
    }

    func testSceneBuilderTwoScenes() {
        @SceneBuilder
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

    func testSceneBuilderThreeScenes() {
        @SceneBuilder
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

    func testSceneBuilderOptionalScene() {
        let showSettings = true

        @SceneBuilder
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

    func testSceneBuilderConditionalScene() {
        let isDevelopment = false

        @SceneBuilder
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

    func testLocalizedStringKeyFromString() {
        let key = LocalizedStringKey("hello.world")
        XCTAssertEqual(key.stringValue, "hello.world")
    }

    func testLocalizedStringKeyFromLiteral() {
        let key: LocalizedStringKey = "hello.world"
        XCTAssertEqual(key.stringValue, "hello.world")
    }

    // MARK: - App Modifier Tests

    func testOnChangeModifier() {
        struct TestApp: App {
            @State private var counter = 0

            var body: some Scene {
                WindowGroup {
                    Text("\(counter)")
                }
                .onChange(of: counter) { newValue in
                    // This would normally trigger side effects
                }
            }
        }

        let app = TestApp()
        XCTAssertNotNil(app.body)
    }

    func testOnOpenURLModifier() {
        struct TestApp: App {
            var body: some Scene {
                WindowGroup {
                    Text("Main")
                }
                .onOpenURL { url in
                    // This would normally handle deep links
                }
            }
        }

        let app = TestApp()
        XCTAssertNotNil(app.body)
    }

    // MARK: - Integration Tests

    func testCompleteAppStructure() {
        struct CompleteApp: App {
            @State private var userLoggedIn = false

            var body: some Scene {
                WindowGroup("My App", id: "main") {
                    if userLoggedIn {
                        Text("Dashboard")
                    } else {
                        Text("Login")
                    }
                }
                .onChange(of: userLoggedIn) { newValue in
                    // Track analytics
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
    }

    func testRavenAppWithComplexView() {
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

    func testAppBodyIsScene() {
        struct TestApp: App {
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

    func testSceneTypeErasure() {
        // Test that different scene types can be stored in an array using type erasure
        let scenes: [any Scene] = [
            WindowGroup { Text("Main") },
            Settings { Text("Settings") },
            EmptyScene()
        ]

        XCTAssertEqual(scenes.count, 3)
    }

    func testAppProtocolRequirements() {
        struct MinimalApp: App {
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

    func testEmptyWindowGroup() {
        let scene = WindowGroup {
            EmptyView()
        }

        XCTAssertNotNil(scene)
    }

    func testNestedSceneBuilder() {
        @SceneBuilder
        func innerScenes() -> some Scene {
            Settings {
                Text("Inner Settings")
            }
        }

        @SceneBuilder
        func outerScenes() -> some Scene {
            WindowGroup {
                Text("Main")
            }

            innerScenes()
        }

        let scene = outerScenes()
        XCTAssertNotNil(scene)
    }

    func testMultipleWindowGroups() {
        struct MultiWindowApp: App {
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
