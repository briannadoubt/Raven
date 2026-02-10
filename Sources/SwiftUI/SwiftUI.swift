// SwiftUI umbrella module for Raven.
//
// This target exists to give apps a single import (`import SwiftUI`) while keeping
// build graph cycles out of SwiftPM targets.
//
// - RavenCore: SwiftUI-style API surface (views, modifiers, VDOM, state)
// - RavenRuntime: WASI runtime bootstrap + DOM renderer + default App.main()
@_exported import RavenCore
@_exported import RavenRuntime
