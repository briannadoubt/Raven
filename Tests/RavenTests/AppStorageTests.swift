import Foundation
import Raven
import Testing

@MainActor
@Suite("AppStorage")
struct AppStorageTests {
    @MainActor
    struct Probe {
        static let defaults = UserDefaults(suiteName: "codex.appstorage")!

        @AppStorage("codex.appstorage.test", store: Probe.defaults)
        var value: Int = 0
    }

    @Test func persistsToUserDefaultsSuite() {
        let defaults = Probe.defaults
        defaults.removeObject(forKey: "codex.appstorage.test")

        var p1 = Probe()
        #expect(p1.value == 0)

        p1.value = 42

        // New instance should read persisted value.
        let p2 = Probe()
        #expect(p2.value == 42)
    }
}
