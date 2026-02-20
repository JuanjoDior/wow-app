# wow-recommendations — Cloudflare Worker v2

Genera y cachea recomendaciones de enchants, gemas y consumibles por clase/spec.
Usa Claude API para generar datos frescos y KV Storage para cachear (TTL 7 días).

## Endpoints

| Método | Ruta | Descripción |
|--------|------|-------------|
| GET | `/health` | Estado del Worker |
| GET | `/recommendations?class=druid&spec=feral` | Obtener recomendaciones |
| POST | `/invalidate` | Limpiar cache de una spec |
| GET | `/specs` | Listar specs y estado de cache |

### GET /recommendations

| Param | Req | Descripción |
|-------|-----|-------------|
| `class` | ✓ | Clase en minúsculas (`druid`, `warrior`...) |
| `spec` | ✓ | Spec en minúsculas (`feral`, `arms`...) |
| `patch` | - | Versión (default: `CURRENT_PATCH` en wrangler.toml) |
| `force` | - | `force=1` para ignorar cache y regenerar |

**Response:**
```json
{
  "class_name": "druid",
  "spec_name": "feral",
  "patch": "11.2.7",
  "generated_at": "2026-02-20T10:00:00Z",
  "_source": "cache | generated",
  "enchants": { "back": [{"name": "...", "note": "...", "is_primary": true}], ... },
  "gems": { "meta": {"name": "...", "note": "..."}, "generic": {...} },
  "consumables": { "flask": {...}, "food": {...}, "potion": {...}, "weapon": {...} },
  "stat_priority": ["Agility", "Critical Strike", ...]
}
```

### POST /invalidate

Requiere header `X-Invalidate-Secret` si `INVALIDATE_SECRET` está configurado.

```json
{ "class": "druid", "spec": "feral", "patch": "11.2.7" }
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

# 4. Añadir secrets (NUNCA en wrangler.toml)
wrangler secret put ANTHROPIC_API_KEY
wrangler secret put INVALIDATE_SECRET   # opcional

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

## Cuando sale un nuevo parche

1. Actualizar `CURRENT_PATCH` en `wrangler.toml`
2. `wrangler deploy`
3. El GitHub Action semanal regenerará automáticamente el fallback estático

Para invalidar cache manualmente de una spec:
```bash
curl -X POST https://wow-recommendations.TU-SUBDOMINIO.workers.dev/invalidate \
  -H "Content-Type: application/json" \
  -H "X-Invalidate-Secret: TU_SECRET" \
  -d '{"class": "druid", "spec": "feral"}'
```

Para invalidar TODAS las specs a la vez (útil tras un parche grande):
```bash
# Script para invalidar todas las specs soportadas
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
