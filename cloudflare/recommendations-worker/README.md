# wow-recommendations — Cloudflare Worker v5

Worker orientado a datos objetivos de personaje/build usando Blizzard API.

## Endpoints

| Método | Ruta | Estado | Descripción |
|--------|------|--------|-------------|
| GET | `/health` | activo | Estado del worker + capacidades |
| GET | `/character?region=eu&realm=sanguino&name=apastar` | activo | Snapshot de personaje (legacy) |
| GET | `/v1/character/snapshot?region=eu&realm=sanguino&name=apastar` | activo | Snapshot versionado v1 |
| GET | `/v2/build/verification?region=eu&realm=sanguino&name=apastar` | activo | Verificación objetiva build vs personaje |
| GET | `/v2/catalog/search?q=blasphemite&mode=gem&locale=es_ES` | activo | Búsqueda objetiva de items/enchants/gemas |
| GET | `/v1/build/gap-analysis?region=eu&realm=sanguino&name=apastar` | compat | Alias compatible de V2 |
| GET | `/recommendations` | deprecated | Ya no se sirven recomendaciones estáticas |
| GET | `/specs` | deprecated | Catálogo de recomendaciones retirado |
| POST | `/invalidate` | deprecated | Invalidez de recomendaciones retirada |

## GET /health

```json
{
  "status": "ok",
  "patch": "12.0.1",
  "service_version": "5.1.0",
  "capabilities": {
    "build_verification_v2": true,
    "catalog_search_v2": true
  }
}
```

## GET /v2/catalog/search

Búsqueda de catálogo con datos oficiales Blizzard, fusión dual-locale (`locale` + `en_US`) y ranking determinista por relevancia.

### Query params

| Param | Req | Descripción |
|-------|-----|-------------|
| `q` | ✓ | Texto de búsqueda (mínimo 2 chars) |
| `mode` | - | `item`, `enchant`, `gem`, `consumable` (default `item`) |
| `region` | - | `us`, `eu`, `kr`, `tw` (default `eu`) |
| `locale` | - | locale Blizzard (default por región) |
| `inventory_type` | - | filtro de slot Blizzard (`HEAD`, `CHEST`, etc.) |
| `slot` | - | slot lógico (`mainHand`, `finger1`, etc.) para heurísticas de enchant |
| `limit` | - | límite de resultados (1..60, default 30) |
| `force` | - | `force=1` para saltar caché |

### Success response (resumen)

```json
{
  "version": "v2",
  "endpoint": "/v2/catalog/search",
  "source": { "policy": "official_only" },
  "query": {
    "q": "Culminating Blasphemite",
    "mode": "gem",
    "region": "eu",
    "locale": "es_ES"
  },
  "results": [
    {
      "id": 213743,
      "kind": "item",
      "name_localized": "Blasfemita culminante",
      "name_en_us": "Culminating Blasphemite",
      "display_name": "Blasfemita culminante",
      "quality": "EPIC",
      "item_class": "Gema",
      "inventory_type": "NON_EQUIP",
      "score": 160,
      "source": "blizzard_item"
    }
  ],
  "meta": {
    "results_count": 1,
    "total_candidates": 12
  }
}
```

## GET /v2/build/verification

Compara el estado real del personaje con el target local (`build_slots`) usando IDs primero y nombre como fallback.

### Query params

| Param | Req | Descripción |
|-------|-----|-------------|
| `region` | ✓ | `us`, `eu`, `kr`, `tw` |
| `realm` | ✓ | Reino del personaje |
| `name` | ✓ | Nombre del personaje |
| `build_slots` | - | JSON string con `slot`, `enchantment_id`, `enchantment`, `gem_ids`, `gems` |
| `force` | - | `force=1` para ignorar caché de personaje |

### Success response

```json
{
  "version": "v2",
  "endpoint": "/v2/build/verification",
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
      "expected_id": 2002,
      "current": ["Authority of Radiant Power"],
      "source": "build"
    }
  ]
}
```

## Compatibilidad V1

`/v1/build/gap-analysis` sigue disponible, pero usa el mismo motor objetivo de V2 para evitar datos estáticos/manuales.

## Setup

```bash
npm install -g wrangler
wrangler login
wrangler kv:namespace create "RECS_CACHE"
wrangler secret put BLIZZARD_CLIENT_SECRET
wrangler deploy
```
