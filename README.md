# WoW Companion

Aplicacion companion multiplataforma para World of Warcraft (Flutter) con enfoque en:
- Busqueda de personaje por region/reino/nombre
- Perfil completo (Blizzard + Raider.IO)
- Gestion de builds
- Verificacion objetiva de build (V2)
- Busqueda de items/enchants/gems por catalogo V2
- Favoritos y comparacion de personajes

## Estado actual del proyecto

La base esta limpia y estable en V2 para inteligencia de build y catalogo:
- Eliminado planner semanal
- Eliminada economia/subastas/precios
- Eliminados endpoints V1 retirados del worker de recomendaciones
- Build Intelligence usa verificacion objetiva (`/v2/build/verification`)

## Funcionalidades principales

### Personajes
- Busqueda por region/reino/nombre
- Perfil con equipo, enchants, gemas, iLvl y stats
- Integracion con Raider.IO para M+ y raids
- Vista comparativa entre dos personajes

### Builds
- Creacion/edicion de builds (incluyendo encantamientos y gemas)
- Busqueda especializada por modo (`item`, `enchant`, `gem`, `consumable`)
- Panel **Verificacion de Build** con datos objetivos (sin recomendaciones estaticas)

### Internacionalizacion
- UI completa en Espanol e Ingles
- Glosario WoW controlado (sin traducir terminos canonicos como `iLvl`, `Mythic+`, etc.)

## Arquitectura

- Clean Architecture (data/domain/presentation)
- State management con `flutter_bloc`
- Inyeccion de dependencias con `get_it`
- Cliente HTTP con `dio`

## Endpoints activos del worker de recomendaciones

Base URL:
- `https://wow-recommendations.wow-comp-app.workers.dev`

Endpoints:
- `GET /health`
- `GET /character`
- `GET /v2/character/snapshot`
- `GET /v2/build/verification`
- `GET /v2/catalog/search`

Capacidades esperadas en `/health`:
- `build_intelligence: true`
- `build_verification_v2: true`
- `catalog_search_v2: true`

## Requisitos

- Flutter estable (SDK actual del proyecto)
- Node.js para tests del worker
- Wrangler CLI para despliegue del worker

## Desarrollo local

```bash
flutter pub get
flutter gen-l10n
flutter run -d chrome
```

Para activar catalogo V2 en local:

```bash
flutter run -d chrome --dart-define=CATALOG_SEARCH_V2=true --dart-define=FEATURE_BUILD_INTELLIGENCE=true
```

## Validacion

```bash
flutter analyze
flutter test
node --test cloudflare/recommendations-worker/test/*.mjs
```

## Build web release

```bash
flutter build web --release --base-href "/wow-app/" --dart-define=CATALOG_SEARCH_V2=true --dart-define=FEATURE_BUILD_INTELLIGENCE=true
```

## Despliegue

### GitHub Pages
- El workflow de `.github/workflows/deploy.yml` publica automaticamente al hacer push a `main`.

### Worker Cloudflare

```bash
cd cloudflare/recommendations-worker
npx wrangler deploy
```

## Notas

- Esta rama prioriza estabilidad funcional sobre features experimentales.
- El objetivo de fiabilidad en build verification es: Blizzard oficial + datos locales de la build.
