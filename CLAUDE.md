# Raven

Cross compilation for SwiftUI to the DOM

## Critical Development Behavior

- Use as many subagents as you can in order to efficiently use your context window. Have them write code, run commands, all that.
- Whenever you plan a task, make sure that you take parallelizing the work into account and mark the plan as such so that you can easily parallelize the work effectively and identify bottlenecks in the implementation.
- When running subagents, only let one at a time run tests or builds so that these processes don't collide, but feel free to write documentation, identify bugs, analyze potential security risks, or other read-only sessions while building or testing. Just be sure to not let other sub agents corrupt the build or tests.
- Don't fire off a background task and sleep. Use the blocking task to watch it if you need to.
- When CI fails, fix it and use `gh run watch` to watch the logs of the CI to confirm that it was fixed.
- When making plans, don't add timelines with dates.
## Swift

- This project is a Swift Package
- Use Swift Concurrency as much as possible with Swift 6.2 strict isolation
- Raven runs in the Swift WASM runtime

## Web

- (Web technology TBD)
- (Web behaviors TBD)

## Skills

- (Skills TBD)
