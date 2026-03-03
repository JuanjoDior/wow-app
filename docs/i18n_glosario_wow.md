# Glosario i18n WoW (ES/EN)

## Objetivo
Evitar traducciones inconsistentes de terminos de juego que la comunidad usa en su forma canonica en ambos idiomas.

## Reglas
- No traducir terminos canonicos de juego (mantener misma forma en EN y ES).
- Traducir el contexto alrededor del termino cuando aplique.
- Mantener placeholders y claves ARB alineados entre idiomas.

## Terminos bloqueados (canonicos)
- `iLvl`
- `Mythic+`
- `M+`
- `DPS`
- `Builds`
- `Spec`
- `Raid`
- `Raider.IO`
- `World of Warcraft`

## Ejemplos
- Correcto ES: `Mejores runs de Mythic+`
- Incorrecto ES: `Mejores Míticas+`

## Validacion automatica
- Test: `test/core/l10n/arb_glossary_guard_test.dart`
- Ejecutar: `flutter test test/core/l10n/arb_glossary_guard_test.dart`
