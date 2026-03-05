# Contract: GET /v1/planner/weekly

## Status
Implemented in worker (`service_version v5`).

## Query Inputs
- `region` (required)
- `realm` (required)
- `name` (required)
- `force` (optional, `1` to bypass cache)

## Response Shape
```json
{
  "version": "v1",
  "endpoint": "/v1/planner/weekly",
  "generated_at": "2026-03-05T12:00:00Z",
  "source": {
    "character": "blizzard|cache",
    "planner": "blizzard|unavailable",
    "policy": "official_only"
  },
  "context": {
    "region": "eu",
    "realm": "sanguino",
    "name": "apastar"
  },
  "facts": {
    "equipped_items_count": 16,
    "enchanted_items_count": 8,
    "sockets_total_count": 7,
    "sockets_filled_count": 6,
    "sockets_empty_count": 1
  },
  "mythic": {
    "rating": 2850.5,
    "weekly_runs_estimated": 4,
    "weekly_best_level": 12,
    "season_best_level": 15
  },
  "affixes": {
    "current": ["Fortified", "Bursting"],
    "source": "blizzard_profile"
  },
  "summary": {
    "analysis_mode": "objective",
    "checks_total": 5,
    "checks_completed": 3,
    "completion_pct": 60,
    "missing_enchants": 1,
    "missing_gems": 1,
    "weekly_runs_estimated": 4,
    "actions_count": 2
  },
  "checklist": [
    {
      "id": "mplus_one_run",
      "label": "Complete at least 1 Mythic+ run",
      "current": 0,
      "target": 1,
      "remaining": 1,
      "done": false,
      "source": "mythic_profile"
    }
  ],
  "actions": [
    {
      "priority_score": 80,
      "type": "mplus_one_run",
      "label": "Complete at least 1 Mythic+ run (1 remaining)",
      "remaining": 1,
      "source": "mythic_profile"
    }
  ]
}
```

## Notes
- API output remains objective-only (`official_only` policy).
- Weekly checklist manual completion persistence is handled in app local storage (`SharedPreferences`), not in this endpoint.
