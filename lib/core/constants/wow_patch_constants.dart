/// Constantes del parche WoW actual. Único punto de edición por parche.
///
/// Al inicio de cada temporada (~2-3 veces/año) solo hay que editar este fichero:
///   1. [current] y [dataLastVerified]
///   2. ilvl thresholds (tras stat squish)
///   3. Evento catch-up (nombre, zona, vendor, moneda, quest, respawn)
///   4. Fechas de temporada / lanzamiento
///   5. Gema meta (normalmente solo cambia cada expansión)
///
/// FUENTE: Icy Veins — Midnight Pre-Patch 12.0.1 — Febrero 2026
class WowPatchContext {
  WowPatchContext._();

  // ── Patch identifier ────────────────────────────────────────────────────────
  static const String current          = '12.0.1';
  static const String dataLastVerified = '2026-02-20';

  // ── ilvl tiers (post stat-squish Midnight) ──────────────────────────────────
  /// Suelo absoluto (transferencia Legion Remix)
  static const int ilvlFloor        = 102;

  /// Mínimo recomendado para cualquier contenido instanciado
  static const int ilvlMinInstanced = 115;

  /// Equipo del vendedor de catch-up (pista Campeón 1/8)
  static const int ilvlCatchupStart = 121;

  /// Base para considerar al personaje "listo para el lanzamiento"
  static const int ilvlLaunchReady  = 131;

  /// Cap de la pista Campeón de Twilight Ascension
  static const int ilvlCatchupCap   = 144;

  /// Equivalente a S3 Heroica
  static const int ilvlHeroicEquiv  = 145;

  /// Equivalente a S3 Mítica
  static const int ilvlMythicEquiv  = 158;

  /// Techo práctico del pre-patch (Myth track S3)
  static const int ilvlPrePatchMax  = 170;

  // ── Evento catch-up ────────────────────────────────────────────────────────
  static const String catchupEventName      = 'Twilight Ascension';
  static const String catchupEventZone      = 'Tierras Altas del Crepúsculo';
  static const String catchupVendorName     = 'Armero Kalinovan';
  static const String catchupVendorWaypoint = '/way #241 49.6 81.2';
  static const int    catchupCurrencyCost   = 40;
  static const String catchupCurrencyName   = "Twilight's Blade Insignia";
  static const String catchupUnlockQuest    = 'The Cult Within';
  static const int    catchupRespawnMinutes = 10;

  // ── Temporada / fechas ─────────────────────────────────────────────────────
  /// Las Míticas+ están congeladas durante el pre-patch
  static const bool   mplusFrozen          = true;
  static const String expansionLaunchDate  = '2 de marzo de 2026';
  static const String season1StartDate     = '24 de marzo de 2026';
  static const String epicEditionEarlyDate = '27 de febrero de 2026';

  // ── Gema meta (familia Blasphemite) ────────────────────────────────────────
  /// Cadena de búsqueda para detectar la gema meta en el equipamiento
  static const String metaGemFamily     = 'Blasphemite';

  /// Meta BiS para DPS y tanques ofensivos (proc stat primaria)
  static const String metaGemBisDamage  = 'Culminating Blasphemite';

  /// Meta BiS para healers y tanques defensivos (velocidad de movimiento)
  static const String metaGemBisMovement = 'Elusive Blasphemite';

  /// Meta nicho para healers con problemas de maná
  static const String metaGemBisMana    = 'Insightful Blasphemite';

  /// Los 4 colores que hay que tener engarzados para activar el bonus de meta.
  /// Orden: Rojo, Verde, Azul, Amarillo.
  static const List<String> metaGemColors = ['Ruby', 'Emerald', 'Sapphire', 'Onyx'];
}
