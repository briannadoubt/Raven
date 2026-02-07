# Raven Codex Instructions

Repository-level guidance for Codex agents working on Raven.

## Project Context

- Raven is a Swift Package that cross-compiles SwiftUI-style apps to WebAssembly and the DOM.
- Prefer Swift 6.2 concurrency-safe patterns (`@MainActor`, sendable closures, strict isolation).
- For WASM app work, build from example app directories when possible to avoid unrelated CLI build failures.

## Development Rules

- Prefer fast search/read tools (`rg`) when available; fall back to `grep`/`find`.
- Parallelize independent read-only investigation steps.
- Do not run concurrent builds/tests in parallel.
- Do not use detached/background jobs plus sleep; run blocking commands and observe output.
- When CI is broken, fix root cause and verify with CI logs.

## Build/Test Defaults

- Package checks: `swift build`, `swift test`
- WASM app build (example):
  - `cd Examples/TodoApp`
  - `swift build --swift-sdk swift-6.2.3-RELEASE_wasm`
- Dev serve (example):
  - `python3 serve.py`

## Skills

Use local Codex skills for repeated Raven workflows:

- `raven-dev`: `./.codex/skills/raven-dev/SKILL.md`
- `swift-wasm`: `./.codex/skills/swift-wasm/SKILL.md`

## Notes

- Existing Claude-specific setup remains under `./.claude/` for teams that still use Claude.
- Codex-specific setup lives under `./.codex/`.
