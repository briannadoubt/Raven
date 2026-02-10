// Raven Accessibility shim
//
// Raven cross-compiles SwiftUI-style apps to WebAssembly. When targeting WASM,
// Apple system frameworks like `Accessibility` are not available. This module
// exists to satisfy `import Accessibility` in shared codebases.
//
// Note: This is intentionally minimal. Add specific API surface area here as
// Raven apps require it.

/// Marker type for Raven's `Accessibility` shim module.
///
/// On Apple platforms, prefer the system `Accessibility` framework and avoid
/// depending on Raven's `Accessibility` product unless you explicitly want the
/// shim.
public enum _RavenAccessibilityShim: Sendable {}

