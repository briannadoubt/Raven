# Raven

<div align="center">

<img width="256" height="256" alt="Raven logo" src="https://github.com/user-attachments/assets/8d0656c7-de7a-4ff8-8953-67affd5427fa" />

**Swift-native UI for the modern web**

Build browser apps with SwiftUI APIs in Swift, compiled to WebAssembly and rendered in the DOM.

[![Swift](https://img.shields.io/badge/Swift-6.2-orange.svg)](https://swift.org)
[![SPM](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)](Package.swift)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

</div>

## Overview

Raven is a Swift framework for building browser applications with SwiftUI APIs.

It compiles Swift to WebAssembly, renders through a virtual DOM pipeline, and prioritizes type safety and modern concurrency practices.

## Project Status

Raven is actively developed and production-oriented, with some areas still maturing.

### Stable Today

- SwiftUI view composition and modifiers
- State and data flow: `@State`, `@Binding`, `@StateObject`, `@ObservedObject`, `@Observable`, `@Bindable`
- Virtual DOM diff-and-patch renderer
- Gesture system (tap, drag, long press, magnification, rotation, gesture composition)
- Animation APIs (`withAnimation`, value-based animation, transitions, keyframes)
- CLI workflows for create/build/dev
- Swift 6.2 concurrency-focused patterns across core modules

### Still Maturing

- `raven create` scaffolding still requires uncommenting Raven dependencies/imports
- Documentation quality is uneven across modules; active cleanup is ongoing
- Deployment/performance guidance is improving but not fully consolidated yet

## Features

- SwiftUI API surface for web-first apps
- WebAssembly runtime with JavaScriptKit interop
- Virtual DOM architecture with minimal DOM updates
- Navigation, forms, lists, grid layouts, and modern view modifiers
- Gesture foundation with composition and gesture state handling
- Animation/transition support with browser-optimized rendering paths
- Accessibility, PWA, and SSR modules in active development
- CLI development loop with hot reload and error overlay support

## Quick Start

### Prerequisites

- Swift 6.2+
- Swift WASM SDK/toolchain (for WASM builds)
- Modern browser with WebAssembly support

### Build the Package

```bash
git clone https://github.com/briannadoubt/Raven.git
cd Raven
swift build
swift test
```

### Build a Real Example App (WASM)

```bash
cd Examples/TodoApp
swift build --swift-sdk swift-6.2.3-RELEASE_wasm
```

### Run the Dev Server

From a Raven app package directory (for example, `Examples/TodoApp`):

```bash
swift run raven dev
```

Default URL: `http://localhost:3000`

## CLI Notes

This repository currently includes two CLI paths:

- Swift CLI target (`swift run raven ...`) from `Sources/RavenCLI`
- Legacy helper script (`./raven`) used by older local workflows

For active Raven development, prefer the Swift CLI target.

## Architecture

Raven bridges declarative Swift views to the browser DOM through three layers:

```text
SwiftUI Views -> Virtual DOM -> DOM Bridge -> Browser DOM
```

1. Views are declared using SwiftUI APIs.
2. The view tree is converted into virtual nodes.
3. On state changes, a diff computes minimal patches.
4. Patches are applied to real DOM nodes through the rendering bridge.

This keeps updates predictable while minimizing unnecessary DOM churn.

## Requirements

### Development

- Swift 6.2+
- macOS or Linux for package development
- WASM SDK/toolchain for browser targets

### Runtime

- Browser with WebAssembly support (current versions of Chrome, Firefox, Safari, Edge)

### Dependencies

- `JavaScriptKit` (WASM/JS interop)
- `swift-argument-parser` (CLI)

## Project Structure

```text
Raven/
├── Sources/
│   ├── Raven/              # Core framework
│   ├── RavenRuntime/       # Runtime support
│   └── RavenCLI/           # CLI implementation
├── Tests/                  # Test suites
├── Examples/               # Runnable sample apps
├── Documentation/          # Guides and API docs
└── Docs/                   # Deep dives (performance/architecture notes)
```

## Documentation and Examples

- [Getting Started](Documentation/GettingStarted.md)
- [API Overview](Documentation/API-Overview.md)
- [Examples](Examples/)
- [Changelog](CHANGELOG.md)

## Testing

```bash
# all tests
swift test

# focused suites
swift test --filter RavenTests
swift test --filter VirtualDOMTests
swift test --filter IntegrationTests
```

## Performance

Current performance strategy centers on:

- minimal DOM patching through virtual DOM diffing
- update coalescing in render loops
- release-oriented WASM build optimization paths
- bundle size inspection through CLI reporting

A fuller benchmark story is on the roadmap.

## Roadmap

The roadmap is ambitious, with milestones prioritized for practical delivery.

### Now

- tighten SwiftUI API compatibility in high-usage primitives and modifiers
- improve `raven dev` reliability and turnaround time
- continue concurrency hardening and test expansion

### Next

- make `raven create` turnkey without manual uncomment steps
- ship more production-grade example apps
- unify architecture, migration, and deployment documentation

### Later

- deeper SSR + hydration support
- stronger PWA/offline defaults and tooling
- formal benchmark suite and perf-budget guidance

## Contributing

Contributions are welcome.

```bash
swift build
swift test
```

When opening a PR, include:

- clear behavior summary
- tests for new or changed behavior
- documentation updates for public API changes

## License

MIT. See [LICENSE](LICENSE).
