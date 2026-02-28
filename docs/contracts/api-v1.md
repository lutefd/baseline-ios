# Baseline API v1 Contract (Backend Repo Target)

## Auth
### POST /v1/auth/login
Request:
```json
{ "email": "string", "password": "string" }
```
Response:
```json
{ "token": "jwt", "expiresAt": "RFC3339" }
```

## Sessions
### GET /v1/sessions
Query:
- `from` (optional RFC3339)
- `to` (optional RFC3339)

Response:
```json
[
  {
    "id": "uuid",
    "userId": "uuid",
    "sessionName": "28 Feb 2026",
    "date": "RFC3339",
    "sessionType": "class|friendly|match",
    "durationMinutes": 60,
    "rushedShots": 12,
    "composure": 6,
    "opponentId": "uuid|null",
    "opponentName": "string|null",
    "matchSetScores": [
      { "setNumber": 1, "playerGames": 6, "opponentGames": 4 }
    ],
    "focusText": "build 3 balls",
    "followedFocus": "yes|partial|no",
    "unforcedErrors": 9,
    "longRallies": 5,
    "directionChanges": 7,
    "notes": "string",
    "createdAt": "RFC3339",
    "updatedAt": "RFC3339"
  }
]
```

### POST /v1/sessions
Headers:
- `Authorization: Bearer <token>`
- `Idempotency-Key: <uuid>`

Request: same schema as session body without server IDs.
Response: created session object.

### PATCH /v1/sessions/:id
Headers:
- `Authorization: Bearer <token>`
- `Idempotency-Key: <uuid>`

Request fields are partial. Conflict strategy in backend repo: last-write-wins by `updatedAt`.

## Opponents
### GET /v1/opponents
Response:
```json
[
  {
    "id": "uuid",
    "name": "string",
    "matchesPlayed": 3,
    "lastPlayedAt": "RFC3339"
  }
]
```

### GET /v1/opponents/:id/history
Response:
```json
{
  "opponent": { "id": "uuid", "name": "string" },
  "sessions": [
    {
      "id": "uuid",
      "sessionName": "28 Feb 2026",
      "date": "RFC3339",
      "sessionType": "friendly|match",
      "matchSetScores": [
        { "setNumber": 1, "playerGames": 6, "opponentGames": 4 }
      ]
    }
  ]
}
```

## Stats
### GET /v1/stats/weekly-summary
Response:
```json
{
  "thisWeek": { "sessions": 2, "avgRushed": 10.5, "avgComposure": 6.5 },
  "previousWeek": { "sessions": 1, "avgRushed": 14, "avgComposure": 5 },
  "delta": { "avgRushed": -3.5, "avgComposure": 1.5 },
  "insight": "Composure improved while rushed shots dropped."
}
```

### GET /v1/stats/trends?rangedays=30
Response:
```json
{
  "rushed": [{ "date": "YYYY-MM-DD", "value": 12 }],
  "composure": [{ "date": "YYYY-MM-DD", "value": 6 }]
}
```
