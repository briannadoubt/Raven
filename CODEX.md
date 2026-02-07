# Raven

Cross compilation for SwiftUI to the DOM

## Critical Development Behavior

- Parallelize independent investigation tasks where practical.
- Avoid concurrent builds/tests that can conflict with each other.
- Do not run detached background jobs with arbitrary sleep-based polling.
- When CI fails, fix the failure and verify with CI logs.
- Keep plans focused on implementation order and bottlenecks, not date timelines.

## Swift

- This project is a Swift Package.
- Prefer Swift Concurrency and Swift 6.2 strict isolation patterns.
- Raven targets Swift WASM runtime behavior.

## Web

- Validate browser behavior with local serving and console checks.
- Treat WASM caching as a common source of stale runtime behavior.

## Skills

- Raven development workflow: `/Users/bri/dev/Raven/.codex/skills/raven-dev/SKILL.md`
- Swift WASM workflow: `/Users/bri/dev/Raven/.codex/skills/swift-wasm/SKILL.md`
