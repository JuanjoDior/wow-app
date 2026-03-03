# Cache Policy (Worker)

## TTL Matrix
- `recommendations`: env `CACHE_TTL_SECONDS` (default `604800`)
- `character`: env `BLIZZARD_CHAR_CACHE_TTL` (default `300`)
- `characterNoMedia`: fixed `60`
- `oauthToken`: env `BLIZZARD_TOKEN_CACHE_TTL` (default `82800`)
- `realmSlug`: env `BLIZZARD_REALM_CACHE_TTL` (default `2592000`)
- `itemIcon`: env `BLIZZARD_ITEM_ICON_CACHE_TTL` (default `604800`)

## Key Conventions
- `recs:{class}:{spec}:{patch}`
- `char:{region}:{realm}:{name}`
- `btoken:{region}`
- `realm_slug:{region}:{normalizedRealm}`
- `itemicon:{region}:{itemId}`

## Notes
- Character responses with missing media use short TTL (`characterNoMedia`) to recover quickly.
- Endpoints should prefer cache-first and only bypass with explicit `force=1`.

