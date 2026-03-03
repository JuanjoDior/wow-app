# Contract: GET /v1/planner/weekly

## Status
Reserved endpoint. Current implementation returns `501 Not Implemented`.

## Current Response
```json
{
  "version": "v1",
  "endpoint": "/v1/planner/weekly",
  "status": "not_implemented",
  "message": "Endpoint reserved for upcoming phase."
}
```

## Planned Query Inputs
- `region` (required)
- `realm` (required)
- `name` (required)

## Planned Output (Phase 2)
- `week` metadata
- `affixes` for current week
- `tasks[]` prioritized checklist
- `progress` summary

