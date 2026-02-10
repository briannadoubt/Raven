// Raven umbrella module.
//
// This target exists to give apps a single import (`import Raven`) while keeping
// build graph cycles out of SwiftPM targets.
//
// - RavenCore: SwiftUI-style API surface (views, modifiers, VDOM, state)
// - RavenRuntime: WASI runtime bootstrap + DOM renderer + default App.main()
@_exported import RavenCore
@_exported import RavenRuntime
