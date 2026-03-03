# Roadmap De Ejecucion Tecnica (Marzo 2026)

## 1) Objetivo
Convertir el roadmap funcional en backlog ejecutable para implementar diferenciadores reales:
- Build Intelligence (priorizacion automatica de mejoras).
- Weekly Planner (plan semanal por personaje).
- Economy Assistant (mejoras con coste real).
- Benchmarks competitivos (percentiles y objetivos).

## 2) Fuentes De Datos (confirmadas)
- Blizzard WoW Profile APIs:
  - `/profile/wow/character/{realmSlug}/{characterName}`
  - `/profile/wow/character/{realmSlug}/{characterName}/equipment`
  - `/profile/wow/character/{realmSlug}/{characterName}/character-media`
  - `/profile/wow/character/{realmSlug}/{characterName}/statistics`
  - `/profile/wow/character/{realmSlug}/{characterName}/mythic-keystone-profile`
- Blizzard WoW Game Data APIs:
  - `/data/wow/search/item`, `/data/wow/item/{itemId}`
  - `/data/wow/search/spell`, `/data/wow/spell/{spellId}`
  - `/data/wow/connected-realm/index`, `/data/wow/search/realm`
  - `/data/wow/connected-realm/{connectedRealmId}/auctions`
  - `/data/wow/auctions/commodities`
  - `/data/wow/mythic-keystone/season/{seasonId}`
- Raider.IO API:
  - `/api/v1/characters/profile`
  - `/api/v1/mythic-plus/affixes`
  - `/api/v1/mythic-plus/static-data`
  - `/api/v1/mythic-plus/season-cutoffs`
  - `/api/v1/raiding/static-data`

Notas operativas:
- Blizzard: throttling documentado (36.000 req/h y 100 req/s, 429 en exceso).
- Raider.IO: 200 req/min sin `access_key`, con 429 en exceso.

## 3) Arquitectura Objetivo
- Flutter no consume APIs externas directamente para features nuevas.
- Todo pasa por Workers propios (agregacion, cache y normalizacion).
- Contratos versionados (`/v1/...`) y estables para la app.
- Cache multinivel:
  - App (in-memory): 1-10 min segun dato.
  - Worker KV: 5 min a 24 h segun volatilidad.
  - Revalidacion por `force=1` solo en debug/admin.

## 4) Backlog Priorizado

## Fase 0 - Foundation (Semana 1)
### F0-01 Telemetria y trazabilidad en Workers
- Tareas:
  - Estandarizar log estructurado (`request_id`, `endpoint`, `status`, `latency_ms`, `cache_hit`, `source`).
  - Añadir version del servicio en `/health`.
- Aceptacion:
  - Cada request deja log parseable.
  - `/health` expone `service_version` y estado de dependencias.

### F0-02 Versionado de contratos
- Tareas:
  - Definir rutas `v1` para nuevos agregados:
    - `/v1/character/snapshot`
    - `/v1/build/gap-analysis`
    - `/v1/planner/weekly`
  - Mantener endpoints actuales sin ruptura.
- Aceptacion:
  - Contratos documentados en `docs/contracts/`.
  - Tests de compatibilidad JSON en CI.

### F0-03 Politica de cache centralizada
- Tareas:
  - Tabla TTL por tipo de dato (character, media, affixes, auctions, cutoffs).
  - Helpers compartidos para claves KV.
- Aceptacion:
  - Sin claves duplicadas por formato distinto.
  - Hit ratio medible por endpoint.

### F0-04 Feature flags
- Tareas:
  - Flags para activar progresivamente modulos (`build_intelligence`, `weekly_planner`, `economy_assistant`).
- Aceptacion:
  - Deploy sin riesgo: feature desactivable sin rollback.

### F0-05 Gobernanza i18n (ES/EN + terminos WoW)
- Tareas:
  - Crear glosario de terminos no traducibles (ej. `iLvl`, `Mythic+`, `raid`, `DPS`).
  - Regla de CI para detectar strings hardcodeados.
- Aceptacion:
  - Build falla si aparece texto UI no localizado en `lib/` (excepto whitelist).

## Fase 1 - Build Intelligence (Semanas 2-3)
### F1-01 Snapshot de personaje (agregado backend)
- Tareas:
  - Endpoint `/v1/character/snapshot` que combine:
    - Blizzard: profile/equipment/stats/media.
    - Raider.IO: score, best runs, raid progression.
  - Normalizar slots, calidad y metadatos.
- Aceptacion:
  - 1 sola llamada desde app para vista completa.
  - P95 endpoint < 800 ms con cache hit.

### F1-02 Gap Analyzer
- Tareas:
  - Endpoint `/v1/build/gap-analysis`:
    - Compara build objetivo vs equipo actual.
    - Detecta faltantes por slot, enchants y gems.
  - Scoring de prioridad (impacto estimado + facilidad).
- Aceptacion:
  - Respuesta incluye `priority_score` y `next_best_actions`.
  - Sin traducir terminos de juego en payload base.

### F1-03 UI Build Intelligence
- Tareas:
  - Panel en `BuildDetailPage`:
    - Resumen de progreso.
    - Top 3 acciones recomendadas.
    - Filtro Raid/M+.
- Aceptacion:
  - UX usable en movil y desktop.
  - ES/EN consistente (sin traducir terminos bloqueados).

### F1-04 Testing fase 1
- Tareas:
  - Unit tests: scoring y normalizadores.
  - Widget tests: panel de recomendaciones.
  - Contract tests backend: schema estable.
- Aceptacion:
  - Cobertura minima 80% en modulos nuevos.

## Fase 2 - Weekly Planner (Semanas 4-5)
### F2-01 Endpoint planner semanal
- Tareas:
  - `/v1/planner/weekly` con:
    - Afijos actuales.
    - Objetivo de score semanal.
    - Estado de tareas pendientes.
- Aceptacion:
  - Checklist semanal generado por personaje/región.

### F2-02 Vista Planner en app
- Tareas:
  - Pantalla dedicada + tarjeta resumen en Home/Builds.
  - Acciones completables localmente (persistencia).
- Aceptacion:
  - Estado persiste y rehidrata correctamente.

## Fase 3 - Economy Assistant (Semanas 6-8)
### F3-01 Ingesta de subasta optimizada
- Tareas:
  - Worker procesa `auctions` y `commodities` a indices ligeros por `itemId`.
  - Exponer precios resumen (min/mediana/p95).
- Aceptacion:
  - App nunca descarga payload bruto de subasta.

### F3-02 Coste por mejora
- Tareas:
  - Enriquecer Gap Analyzer con `estimated_cost`.
  - Ratio `impacto / coste`.
- Aceptacion:
  - Recomendaciones ordenables por ROI.

## Fase 4 - Benchmarks Competitivos (Semanas 9-10)
### F4-01 Percentiles y objetivos
- Tareas:
  - Consumir cutoffs/score tiers para estimar posicion relativa.
  - Mostrar objetivos concretos para siguiente hito.
- Aceptacion:
  - Usuario ve su percentil y distancia al siguiente bracket.

## 5) Plan De Arranque Inmediato (siguiente iteracion)
1. Implementar F0-01, F0-02 y F0-03 en Workers (base tecnica obligatoria).
2. Publicar primer contrato de `/v1/character/snapshot`.
3. Integrar snapshot en app sin cambiar UI (solo capa de datos).
4. Implementar F1-02 (Gap Analyzer) y exponer en `BuildDetailPage`.

## 6) Definicion De Done (por tarea)
- Codigo + tests + contrato/documentacion actualizados.
- Sin regresiones en ES/EN.
- Sin impacto en rutas actuales.
- Latencia y errores medidos (no solo "funciona en local").

## 7) Riesgos y mitigacion
- 429 por burst:
  - Backoff exponencial + cache + deduplicacion de requests concurrentes.
- Payload de subastas:
  - Preprocesamiento server-side obligatorio.
- Cambios de season/parche:
  - Datos estaticos versionados por parche en Worker.

