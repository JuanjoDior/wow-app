# Contract: GET /v1/build/gap-analysis (Compatibility Alias)

## Status
Implemented as compatibility alias over V2 objective engine.

## Query Inputs
- `region` (required)
- `realm` (required)
- `name` (required)
- `build_slots` (optional JSON string)
- `force` (optional, `1` to bypass cache in character lookup)

### `build_slots` payload
```json
[
  {
    "slot": "mainHand",
    "enchantment_id": 2234,
    "enchantment": "Authority of Fiery Resolve",
    "gem_ids": [192982],
    "gems": ["Radiant Mastery"]
  }
]
```

## Success Response (200)
```json
{
  "version": "v1",
  "endpoint": "/v1/build/gap-analysis",
  "generated_at": "2026-03-04T14:00:00.000Z",
  "source": {
    "character": "cache|blizzard",
    "policy": "official_only"
  },
  "facts": {
    "equipped_items_count": 16,
    "enchanted_items_count": 8,
    "sockets_total_count": 7,
    "sockets_filled_count": 6,
    "sockets_empty_count": 1
  },
  "summary": {
    "analysis_mode": "objective",
    "target_profile": "character_only|build_target",
    "checks_total": 2,
    "checks_completed": 1,
    "completion_pct": 50,
    "missing_enchants": 0,
    "missing_gems": 1,
    "mismatched_enchants": 1,
    "mismatched_gems": 0,
    "actions_count": 2
  },
  "actions": [
    {
      "priority_score": 95,
      "slot": "mainHand",
      "type": "enchant_mismatch_target",
      "label": "Replace with Authority of Fiery Resolve",
      "recommended": "Authority of Fiery Resolve",
      "expected": "Authority of Fiery Resolve",
      "expected_id": 2234,
      "current": ["Authority of Radiant Power"],
      "source": "build"
    }
  ]
}
```

## Error Response
```json
{
  "version": "v1",
  "endpoint": "/v1/build/gap-analysis",
  "error": "Missing required params: region, realm, name"
}
```
