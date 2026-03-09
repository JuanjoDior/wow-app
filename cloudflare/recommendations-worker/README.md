# wow-recommendations — Cloudflare Worker v6

Worker orientado a datos objetivos usando solo APIs oficiales de Blizzard.

## Endpoints activos

| Método | Ruta | Descripción |
|--------|------|-------------|
| GET | `/health` | Estado y capacidades activas |
| GET | `/character?region=eu&realm=sanguino&name=apastar` | Snapshot de personaje (base) |
| GET | `/v2/character/snapshot?region=eu&realm=sanguino&name=apastar` | Snapshot versionado v2 |
| GET | `/v2/build/verification?region=eu&realm=sanguino&name=apastar` | Verificación objetiva build vs personaje |
| GET | `/v2/catalog/search?q=blasphemite&mode=gem&locale=es_ES` | Búsqueda objetiva de items/enchants/gemas |

## Política de datos

- `official_only`: sin catálogos estáticos/manuales para recomendaciones.
- `build verification`: compara personaje real vs `build_slots` local (IDs primero, nombre como fallback).

## GET /health

```json
{
  "status": "ok",
  "patch": "12.0.1",
  "service_version": "6.0.0",
  "capabilities": {
    "build_intelligence": true,
    "build_verification_v2": true,
    "catalog_search_v2": true
  }
}
```

## Setup

```bash
npm install -g wrangler
wrangler login
wrangler kv:namespace create "RECS_CACHE"
wrangler secret put BLIZZARD_CLIENT_SECRET
wrangler deploy
```

## Feature flags (Worker vars)

- `FEATURE_BUILD_INTELLIGENCE` (default `true`)
