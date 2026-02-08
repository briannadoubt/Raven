# SwiftUI API Gap Phased Delivery Plan

## Process For Every Phase

1. Implement scoped APIs for the phase.
2. Add/adjust usage in `Examples/TodoApp` where practical.
3. Validate locally:
   - `swift build`
   - targeted unit tests
   - example WASM build from `Examples/TodoApp`
   - manual smoke checks via `raven dev`
4. Regenerate API gap artifacts:
   - `Scripts/swiftui_api_gap_report.py --repo-root . --output-dir Reports/swiftui-api-gap`
5. Commit with clear phase-scoped message.
6. Open PR.
7. Watch CI + PR comments.
8. If issues appear, fix and repeat steps 3-7.
9. Merge once green/approved.
10. Move to next phase and repeat.

## Phase 1 (Quick Wins, High Adoption)

- Search UX completion APIs:
  - `searchSuggestions`
  - `searchScopes`
  - `searchFocused`
- Container/layout parity:
  - `contentMargins`
  - `containerBackground`
- Task overload parity:
  - missing `task(...)` overloads from gap report
- Style API runtime follow-through:
  - ensure Phase 1 style surfaces are reflected in behavior and examples

## Phase 2 (Core Capability Unlocks)

- Drag and drop:
  - `draggable`, `onDrag`, `onDrop`, `dropDestination`
- File workflows:
  - `fileImporter`, `fileExporter`, `fileMover`
- Scroll targeting/state:
  - `scrollPosition`, `scrollTargetLayout`, `scrollTargetBehavior`

## Phase 3 (Desktop / Information Dense UX)

- `NavigationSplitView` family
- table ergonomics (`tableStyle`, headers, related API)
- persistence-oriented app settings API (`AppStorage` baseline)

## Phase 4 (Modern Motion and Visual Polish)

- `matchedTransitionSource`
- `symbolEffect`
- dependent transition/presentation follow-ups

## Phase 5 (Accessibility Depth)

- High-frequency accessibility modifiers first
- Advanced focus/rotor/specialized APIs
- Re-run gap analysis and close remaining high-impact a11y gaps
