# SwiftUI API Gap Automation

This repo includes a deterministic SwiftUI API inventory and Raven parity report generator.

## Script

Path: `Scripts/swiftui_api_gap_report.py`

The script uses Apple SDK metadata from `swift-api-digester` against the `SwiftUI` module, then compares symbol names against Raven public declarations in `Sources/Raven/**/*.swift`.

### Local run

```bash
Scripts/swiftui_api_gap_report.py --repo-root . --output-dir Reports/swiftui-api-gap
```

### Output files

- `Reports/swiftui-api-gap/swiftui_inventory.json`
- `Reports/swiftui-api-gap/raven_inventory.json`
- `Reports/swiftui-api-gap/gap_report.json`
- `Reports/swiftui-api-gap/gap_report.md`

## GitHub Actions Schedule

Workflow: `.github/workflows/swiftui-api-gap-report.yml`

Trigger:

- Every Monday at `09:00 UTC` (`cron: 0 9 * * 1`)
- Manual runs via `workflow_dispatch`

The workflow uploads `Reports/swiftui-api-gap/` as an artifact named `swiftui-api-gap-report`.

## Notes on Determinism

- Results are deterministic for a given Xcode + SDK version + target triple.
- Coverage is currently an owner-qualified name-based parity score.
- Member matching prefers qualified keys such as `Type.func`, `Type.var`, and `Type.init`, with fallback to unqualified names for global/extension scenarios.
- Constructor matching is currently owner-based (`Type.init` exists), not full signature equivalence.
