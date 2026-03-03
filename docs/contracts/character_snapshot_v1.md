# Contract: GET /v1/character/snapshot

## Purpose
Stable `v1` wrapper for character snapshots consumed by the app.

## Query Parameters
- `region` (required): `us|eu|kr|tw`
- `realm` (required): realm name or slug
- `name` (required): character name
- `force` (optional): `1` to bypass cache

## Success Response (200)
```json
{
  "version": "v1",
  "source": "cache|blizzard|static|null",
  "generated_at": "2026-03-03T13:00:00.000Z",
  "snapshot": {
    "_source": "cache|blizzard",
    "name": "character",
    "realm": "Realm",
    "region": "EU",
    "level": 80,
    "class": "Paladin",
    "spec": "Retribution",
    "average_item_level": 680,
    "equipped_item_level": 679,
    "equipment": [],
    "stats": {}
  }
}
```

## Error Response
```json
{
  "version": "v1",
  "endpoint": "/v1/character/snapshot",
  "error": "Character not found. Check region, realm and name."
}
```

