# Contract: GET /v2/character/snapshot

## Query params

- `region` (required): `us|eu|kr|tw`
- `realm` (required)
- `name` (required)
- `locale` (optional, default `en_US`)
- `force=1` (optional)

## Success response

```json
{
  "version": "v2",
  "source": "cache|blizzard",
  "generated_at": "2026-03-09T12:00:00Z",
  "snapshot": {
    "name": "Apastar",
    "realm": "Sanguino",
    "region": "EU",
    "class": "Druid",
    "spec": "Feral",
    "equipment": []
  }
}
```

## Error response

```json
{
  "version": "v2",
  "endpoint": "/v2/character/snapshot",
  "error": "Character not found. Check region, realm and name."
}
```
