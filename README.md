# Raven

<div align="center">

<img width="256" height="256" alt="Raven logo" src="https://github.com/user-attachments/assets/8d0656c7-de7a-4ff8-8953-67affd5427fa" />

**SwiftUI for the modern web**

Build browser apps with SwiftUI APIs in Swift, compile to WebAssembly, render in the DOM.

[![Swift](https://img.shields.io/badge/Swift-6.2-orange.svg)](https://swift.org)
[![SPM](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)](Package.swift)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

</div>

## What Raven Is

Raven is a Swift framework for building browser applications with SwiftUI APIs.

It compiles Swift to WebAssembly, renders through a virtual DOM pipeline, and is built around modern Swift concurrency patterns.

## Start Here

### 1) Build Raven locally

```bash
git clone https://github.com/briannadoubt/Raven.git
cd Raven
swift build
swift test
```

### 2) Run a real example app

```bash
cd Examples/TodoApp
raven dev
```

Open `http://localhost:3000`.

### 3) Build a WASM binary explicitly (optional)

```bash
cd Examples/TodoApp
swift build --swift-sdk swift-6.2.3-RELEASE_wasm
```

## What Works Today

- SwiftUI view composition and modifiers
- State/data flow: `@State`, `@Binding`, `@StateObject`, `@ObservedObject`, `@Observable`, `@Bindable`
- Virtual DOM diff-and-patch renderer
- Gestures (tap, drag, long press, magnification, rotation, composition)
- Animations (`withAnimation`, value-based animation, transitions, keyframes)
- Dev/build/create CLI workflows

## Known Rough Edges

- `raven create` scaffolding still requires uncommenting Raven dependencies/imports
- Documentation depth varies by subsystem
- Deployment and performance guidance is still being consolidated

## CLI Workflows

CLI commands below assume Raven is installed and available on `PATH` (for example via Homebrew).

### Development server

```bash
raven dev
raven dev --port 3000 --host localhost
```

### Production build

```bash
raven build
raven build --optimize --compress
```

### Scaffold a new project

```bash
raven create MyApp
```

Note: `create` currently generates a template that still expects Raven import/dependency lines to be uncommented.

## Architecture (Short Version)

```text
SwiftUI Views -> Virtual DOM -> DOM Bridge -> Browser DOM
```

1. Views are declared using SwiftUI APIs.
2. The view tree is transformed into virtual nodes.
3. State changes trigger a diff.
4. Minimal patches are applied to real DOM nodes.

## Diffing and Identity

Raven uses a Fiber reconciliation pipeline with a few practical rules:

- Keyed reconciliation first: when children have keys, Raven matches by key so reorders and inserts stay stable.
- Positional fallback second: unkeyed children are matched by index as a fallback.
- Stable identity from tree paths: fiber/node identity is derived from deterministic path strings and hashed (FNV-1a) so matching remains consistent across renders.
- Targeted patch generation: reconciliation emits focused mutations (`insert`, `remove`, `replace`, `updateProps`, `reorder`) instead of rebuilding entire subtrees.
- Dirty-subtree skipping: clean branches are skipped entirely (`isDirty` / `hasDirtyDescendant`), which keeps updates fast as trees grow.

In practice, this means Raven preserves state and DOM continuity better for keyed collections, while still handling simpler unkeyed trees predictably.

## Troubleshooting

### `No SwiftWasm toolchain found`

Install a WASM-capable Swift SDK/toolchain, then retry `raven dev`.

### `No Package.swift found`

Run CLI commands from a Swift package root (for example, `Examples/TodoApp`).

### Dev server starts but page is blank

- Check terminal output for compiler errors.
- Confirm `http://localhost:3000` is reachable.
- Ensure the initial build finished successfully.

## Project Structure

```text
Raven/
├── Sources/
│   ├── Raven/              # Framework
│   ├── RavenRuntime/       # Runtime support
│   └── RavenCLI/           # CLI implementation
├── Tests/
├── Examples/
├── Documentation/
└── Docs/
```

## Documentation

- [Documentation Index](Documentation/)
- [Getting Started](Documentation/GettingStarted.md)
- [API Overview](Documentation/API-Overview.md)
- [Architecture and Performance Notes](Docs/)
- [Examples](Examples/)
- [Changelog](CHANGELOG.md)

## Roadmap

### Now

- tighten SwiftUI API coverage in high-usage primitives/modifiers
- improve `raven dev` reliability and iteration speed
- expand concurrency hardening and test coverage

### Next

- make `raven create` turnkey
- add more production-grade examples
- unify migration/deployment documentation

### Later

- deeper SSR + hydration support
- stronger offline/PWA defaults
- formal benchmark suite and perf-budget guidance

## Contributing

```bash
swift build
swift test
```

When opening a PR, include:

- a clear behavior summary
- tests for new or changed behavior
- docs updates for public API changes

Issue tracker: [GitHub Issues](https://github.com/briannadoubt/Raven/issues)
Pull requests: [GitHub Pull Requests](https://github.com/briannadoubt/Raven/pulls)

## License

MIT. See [LICENSE](LICENSE).

[Documentation](Documentation/) • [Examples](Examples/) • [Contributing](#contributing) • [License](LICENSE)
