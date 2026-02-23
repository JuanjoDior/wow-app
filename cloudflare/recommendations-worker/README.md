# wow-recommendations — Cloudflare Worker v4

Sirve recomendaciones de enchants, gemas y consumibles por clase/spec.
Prioriza static data embebido (actualizable por parche) y usa KV Storage como caché de respaldo (TTL 7 días).

## Endpoints

| Método | Ruta | Descripción |
|--------|------|-------------|
| GET | `/health` | Estado del Worker |
| GET | `/recommendations?class=druid&spec=feral` | Obtener recomendaciones |
| POST | `/invalidate` | Limpiar caché de una spec |
| GET | `/specs` | Listar specs y estado de caché |

### GET /recommendations

| Param | Req | Descripción |
|-------|-----|-------------|
| `class` | ✓ | Clase en minúsculas (`druid`, `warrior`...) |
| `spec` | ✓ | Spec en minúsculas (`feral`, `arms`...) |
| `patch` | - | Versión (default: `CURRENT_PATCH` en wrangler.toml) |
| `force` | - | `force=1` para ignorar caché y refrescar |

**Response:**
```json
{
  "class_name": "druid",
  "spec_name": "feral",
  "patch": "12.0.1",
  "generated_at": "2026-02-20T10:00:00Z",
  "_source": "static | cache",
  "enchants": { "back": [{"name": "...", "note": "...", "is_primary": true}], ... },
  "gems": { "meta": {"name": "...", "note": "..."}, "generic": {...} },
  "consumables": { "flask": {...}, "food": {...}, "potion": {...}, "weapon": {...} },
  "stat_priority": ["Agility", "Critical Strike", ...]
}
```

### POST /invalidate

Requiere header `X-Invalidate-Secret` si `INVALIDATE_SECRET` está configurado.

```json
{ "class": "druid", "spec": "feral", "patch": "12.0.1" }
```

---

## Setup inicial

```bash
# 1. Instalar Wrangler globalmente
npm install -g wrangler

# 2. Login en tu cuenta Cloudflare
wrangler login

# 3. Crear KV namespace
wrangler kv:namespace create "RECS_CACHE"
# → Copia el id que devuelve y pégalo en wrangler.toml

# 4. Añadir secrets (NUNCA en wrangler.toml) — opcional
wrangler secret put INVALIDATE_SECRET

# 5. Deploy
wrangler deploy
# → Anota la URL: https://wow-recommendations.TU-SUBDOMINIO.workers.dev
```

---

## Conectar la app Flutter

En `lib/features/builds/data/datasources/spec_recommendations_datasource.dart`:

```dart
static const String _baseUrl =
    'https://wow-recommendations.TU-SUBDOMINIO.workers.dev';
```

---

## Flujo de resolución

```
GET /recommendations?class=druid&spec=feral
        │
        ▼
1. ¿Existe en STATIC_DATA?  ──SÍ──▶  Devuelve datos + refresca KV  (_source: static)
        │NO
        ▼
2. ¿Existe en KV cache?     ──SÍ──▶  Devuelve datos               (_source: cache)
        │NO
        ▼
3. 404 — spec no soportada
```

El static data en `src/index.js` es la fuente de verdad. Para añadir o actualizar specs, edita `STATIC_DATA` y haz `wrangler deploy`.

---

## Cuando sale un nuevo parche

1. Actualizar `CURRENT_PATCH` en `wrangler.toml`
2. Editar `STATIC_DATA` en `src/index.js` con los nuevos datos
3. `wrangler deploy`

Para invalidar caché manualmente de una spec:
```bash
curl -X POST https://wow-recommendations.TU-SUBDOMINIO.workers.dev/invalidate \
  -H "Content-Type: application/json" \
  -H "X-Invalidate-Secret: TU_SECRET" \
  -d '{"class": "druid", "spec": "feral"}'
```

Para invalidar TODAS las specs a la vez (útil tras un parche grande):
```bash
for spec in "druid:feral" "druid:balance" "warrior:arms" "warrior:fury" "paladin:retribution" "mage:fire" "hunter:beast mastery"; do
  CLASS="${spec%%:*}"
  SPEC="${spec##*:}"
  curl -X POST https://wow-recommendations.TU-SUBDOMINIO.workers.dev/invalidate \
    -H "Content-Type: application/json" \
    -H "X-Invalidate-Secret: TU_SECRET" \
    -d "{\"class\": \"$CLASS\", \"spec\": \"$SPEC\"}"
  echo "Invalidated $CLASS:$SPEC"
done
```
