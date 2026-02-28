# Baseline Product Roadmap

## Direction
- Phase 1 (this repo): iOS MVP local-first.
- Phase 2 (external repo): Go API for auth, sync, trends, and weekly summaries.
- Phase 3 (external repo): Wails analytics app consuming backend API.

## MVP Success Criteria
- Session logging in under 60 seconds.
- `rushedShots` and `composure` visible as trends on iOS.
- Offline-first workflow with no login required.

## Scope Now (This Repo)
- iOS SwiftUI app modules, models, validation, local persistence hooks, telemetry counters.
- API contract documentation for future cross-repo integration.

## Deferred (External Repos)
- Backend runtime/deployment.
- Sync transport.
- Desktop analytics runtime and UI.
