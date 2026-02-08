# Raven

<div align="center">

<img width="256" height="256" alt="Raven logo" src="https://github.com/user-attachments/assets/8d0656c7-de7a-4ff8-8953-67affd5427fa" />

**SwiftUI for the web, without switching languages**

Write SwiftUI-style views in Swift, compile to WebAssembly, render in the DOM.

[![Swift](https://img.shields.io/badge/Swift-6.2-orange.svg)](https://swift.org)
[![SPM](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)](Package.swift)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

</div>

## What Raven Is

Raven is my indie attempt to make web UI feel as good in Swift as it does in SwiftUI.

It gives you a SwiftUI-like API, runs in the browser via WebAssembly, and updates the DOM through a virtual DOM renderer. You stay in Swift, keep type safety, and ship real browser apps.

## Project Status

Raven is actively developed and already usable for real apps and experiments.

What is solid today:
- SwiftUI-style view composition (`Text`, `Button`, stacks, lists, forms, nav, modifiers)
- State + data flow (`@State`, `@Binding`, `@StateObject`, `@ObservedObject`, `@Observable`, `@Bindable`)
- Virtual DOM diff + patch rendering pipeline
- Gesture system (tap, drag, long press, magnify, rotate, composition)
- Animation and transitions (`withAnimation`, implicit animation, keyframes, transitions)
- CLI for build/dev/create (`raven build`, `raven dev`, `raven create`)
- Swift 6.2-era concurrency patterns across the codebase

What is still rough in spots:
- CLI scaffolding from `raven create` still expects manual Raven dependency/import uncommenting
- Docs and examples are improving fast, but not every API has polished guide-level coverage yet

## Quick Start

### 1) Clone + build

```bash
git clone https://github.com/briannadoubt/Raven.git
cd Raven
swift build
```

### 2) Run tests

```bash
swift test
```

### 3) Build a real example app (WASM)

```bash
cd Examples/TodoApp
swift build --swift-sdk swift-6.2.3-RELEASE_wasm
```

### 4) Start dev server with hot reload

From the example app directory:

```bash
swift run raven dev
```

By default it serves on `http://localhost:3000`.

## CLI Notes

Raven currently has two CLI paths in this repo:
- Swift CLI target (`swift run raven ...`) from `Sources/RavenCLI`
- Legacy helper script (`./raven`) for older local workflows

If you are actively developing Raven itself, prefer the Swift CLI path.

## Docs + Examples

- [Getting Started](Documentation/GettingStarted.md)
- [API Overview](Documentation/API-Overview.md)
- [Examples](Examples/)
- [Changelog](CHANGELOG.md)

## Roadmap

Big vision, realistic steps.

### Now
- Keep tightening SwiftUI API compatibility where it matters most in day-to-day app work
- Improve dev loop speed and reliability in `raven dev`
- Keep hardening concurrency safety and test coverage

### Next
- Make `raven create` truly turnkey (no manual uncomment setup)
- Ship more production-grade examples (forms, dashboard, offline-first patterns)
- Strengthen docs around architecture, migration, and deployment

### Later
- SSR and hydration maturity
- Deeper PWA/offline tooling
- Performance benchmark suite and publishable perf budget guidance

## Contributing

Contributions are welcome.

```bash
swift build
swift test
```

If you open a PR, please include:
- clear behavior change summary
- tests for new logic
- doc updates if public APIs changed

## License

MIT. See [LICENSE](LICENSE).
