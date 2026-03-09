# Contract: GET /v2/build/verification

## Query params

- `region` (required): `us|eu|kr|tw`
- `realm` (required)
- `name` (required)
- `build_slots` (optional): JSON string array with:
  - `slot`
  - `enchantment_id` (optional)
  - `enchantment` (optional)
  - `gem_ids` (optional)
  - `gems` (optional)
- `force=1` (optional)

## Success response

```json
{
  "version": "v2",
  "endpoint": "/v2/build/verification",
  "generated_at": "2026-03-09T12:00:00Z",
  "source": {
    "character": "cache|blizzard",
    "policy": "official_only"
  },
  "context": {
    "region": "eu",
    "realm": "sanguino",
    "name": "apastar",
    "local_build_slots": 3
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
    "checks_total": 5,
    "checks_completed": 3,
    "completion_pct": 60,
    "missing_enchants": 1,
    "missing_gems": 1,
    "mismatched_enchants": 0,
    "mismatched_gems": 0,
    "actions_count": 2
  },
  "actions": [
    {
      "priority_score": 80,
      "slot": "mainHand",
      "type": "enchant_missing_target",
      "label": "Apply Authority of Fiery Resolve",
      "expected": "Authority of Fiery Resolve",
      "current": [],
      "source": "build"
    }
  ]
}
```
