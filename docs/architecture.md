# Architecture

## In-Repo: iOS App
- UI: SwiftUI
- Persistence: SwiftData
- Pattern: Feature folders + domain services
- Source of truth: local data

### Data Flow
1. User logs session in `NewSession`.
2. Validator enforces required constraints.
3. Session stored in local SwiftData context.
4. Home computes rolling averages and trend points.
5. History lists and details prior sessions.

## External: Go Backend (Later)
- Separate repository.
- Exposes `/v1/auth`, `/v1/sessions`, `/v1/stats/*`.
- Contract mirrored in `docs/contracts/api-v1.md`.

## External: Wails Analytics (Later)
- Separate repository.
- Reads from backend API.
