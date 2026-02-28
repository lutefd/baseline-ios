# Architecture

## In-Repo: iOS App
- UI: SwiftUI
- Persistence: SwiftData
- Pattern: Feature folders + domain services
- Source of truth: local data

### Data Flow
1. User logs session in `NewSession`.
2. Validator enforces required constraints, including optional competitive match result fields.
3. Session stored in local SwiftData context with persisted `sessionName`.
4. If friendly/match result is provided, app resolves/creates an `Opponent` record and stores set/game scores.
5. Home computes rolling averages and trend points.
6. History lists and details prior sessions, including opponent and match score context.

## External: Go Backend (Later)
- Separate repository.
- Exposes `/v1/auth`, `/v1/sessions`, `/v1/stats/*`.
- Exposes `/v1/opponents` and per-opponent history endpoints for player-vs-opponent tracking.
- Contract mirrored in `docs/contracts/api-v1.md`.

## External: Wails Analytics (Later)
- Separate repository.
- Reads from backend API.
