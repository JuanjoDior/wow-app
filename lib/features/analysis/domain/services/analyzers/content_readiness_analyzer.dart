import 'package:wow_companion/core/constants/wow_patch_constants.dart';
import 'package:wow_companion/features/analysis/domain/entities/character_insight.dart';
import 'package:wow_companion/features/character/domain/entities/character.dart';

/// Analyzes overall content readiness for the current WoW patch context.
///
/// All thresholds, event info and dates are read from [WowPatchContext].
/// To update for a new patch/season, only edit [wow_patch_constants.dart].
///
/// ilvl tiers (Midnight pre-patch, post stat-squish):
///   [WowPatchContext.ilvlFloor]         — Legion Remix transfer base (floor)
///   [WowPatchContext.ilvlMinInstanced]  — Minimum for any instanced content
///   [WowPatchContext.ilvlCatchupStart]  — Catch-up vendor gear (Champion 1/8)
///   [WowPatchContext.ilvlLaunchReady]   — "Ready for launch" floor
///   [WowPatchContext.ilvlCatchupCap]    — Champion track cap
///   [WowPatchContext.ilvlHeroicEquiv]   — S3 Heroic equivalent
///   [WowPatchContext.ilvlMythicEquiv]   — S3 Mythic equivalent
///   [WowPatchContext.ilvlPrePatchMax]   — Pre-patch ceiling
class ContentReadinessAnalyzer {
  const ContentReadinessAnalyzer();

  List<CharacterInsight> analyze(
    Character character, {
    required int missingEnchantCount,
  }) {
    final ilvl = character.equippedItemLevel;
    if (ilvl == null || ilvl == 0) return const [];

    final score = character.mythicPlusProfile?.scoreAll
        ?? character.mythicPlusScore
        ?? 0.0;

    return [_buildInsight(ilvl, missingEnchantCount, score)];
  }

  CharacterInsight _buildInsight(int ilvl, int missingEnchants, double score) {
    final enchantNote = missingEnchants > 0
        ? ' · $missingEnchants enchantment${missingEnchants > 1 ? 's' : ''} missing'
        : '';
    final scoreNote = score > 0
        ? ' · Score M+ ${score.toStringAsFixed(0)}'
        : '';

    // ── Below minimum ────────────────────────────────────────────────────────
    if (ilvl < WowPatchContext.ilvlMinInstanced) {
      return CharacterInsight(
        category: InsightCategory.contentReadiness,
        severity: InsightSeverity.critical,
        title: 'Equipado por debajo del mínimo',
        description:
            'ilvl $ilvl — Farmea ${WowPatchContext.catchupEventName} para alcanzar '
            'ilvl ${WowPatchContext.ilvlCatchupStart}+.$enchantNote',
        simpleExplanation:
            'Tu equipo está por debajo del nivel recomendado para el contenido de Midnight. '
            'El evento ${WowPatchContext.catchupEventName} en ${WowPatchContext.catchupEventZone} es '
            'la forma más rápida de mejorar: tarda aproximadamente una hora por sesión '
            'y da equipo ilvl ${WowPatchContext.ilvlCatchupStart} gratis sin necesidad de grupo.',
        advancedDetail:
            'Suelo de ilvl en pre-patch: ${WowPatchContext.ilvlFloor} (transferencia Legion Remix). '
            '${WowPatchContext.catchupEventName}: ilvl ${WowPatchContext.ilvlCatchupStart} pista Campeón 1/8, '
            'actualizable hasta ${WowPatchContext.ilvlCatchupCap}. '
            'Coste: ${WowPatchContext.catchupCurrencyCost} ${WowPatchContext.catchupCurrencyName}/slot '
            'del ${WowPatchContext.catchupVendorName} (${WowPatchContext.catchupVendorWaypoint}). '
            'Los jefes raros reaparecen cada ~${WowPatchContext.catchupRespawnMinutes} min. '
            'Las Míticas+ están congeladas — no hay progresión de Temporada 3 disponible.',
        actionItems: [
          'Completa la misión "${WowPatchContext.catchupUnlockQuest}" para desbloquear ${WowPatchContext.catchupEventName}',
          'Farmea los eventos raros cada ~${WowPatchContext.catchupRespawnMinutes} min en ${WowPatchContext.catchupEventZone}',
          'Compra equipo ilvl ${WowPatchContext.ilvlCatchupStart} por ${WowPatchContext.catchupCurrencyCost} Insignias/slot al ${WowPatchContext.catchupVendorName}',
          if (missingEnchants > 0) 'Además: añade encantamientos a tu equipo actual',
        ],
      );
    }

    // ── Catch-up in progress ─────────────────────────────────────────────────
    if (ilvl < WowPatchContext.ilvlLaunchReady) {
      return CharacterInsight(
        category: InsightCategory.contentReadiness,
        severity: InsightSeverity.warning,
        title: 'Catch-up en progreso',
        description:
            'ilvl $ilvl — Buen camino. Sigue farmeando ${WowPatchContext.catchupEventName}.$enchantNote',
        simpleExplanation:
            'Estás en el rango de equipo de ${WowPatchContext.catchupEventName}. ¡Sigue adelante! '
            'Apunta a ilvl ${WowPatchContext.ilvlLaunchReady}+ antes del lanzamiento de Midnight '
            'el ${WowPatchContext.expansionLaunchDate} para empezar con comodidad.',
        advancedDetail:
            '${WowPatchContext.catchupEventName} llega hasta la pista Campeón '
            '(máx. ${WowPatchContext.ilvlCatchupCap}). '
            'Las misiones semanales dan ~80 Insignias totales por reinicio. '
            'Los jefes raros (~${WowPatchContext.catchupRespawnMinutes} min de reaparición) son la fuente más rápida. '
            'Midnight se lanza el ${WowPatchContext.expansionLaunchDate}; '
            'acceso anticipado (Edición Épica) el ${WowPatchContext.epicEditionEarlyDate}.',
        actionItems: [
          'Continúa farmeando raros de ${WowPatchContext.catchupEventName} + misiones semanales',
          'Actualiza el equipo Ascension Arrestor a lo largo de la pista Campeón',
          'Objetivo: ilvl ${WowPatchContext.ilvlLaunchReady}+ antes del lanzamiento el ${WowPatchContext.expansionLaunchDate}',
          if (missingEnchants > 0)
            'Encanta tu equipo ahora — merece la pena aunque sigas actualizándolo',
        ],
      );
    }

    // ── Ready for launch ─────────────────────────────────────────────────────
    if (ilvl < WowPatchContext.ilvlHeroicEquiv) {
      return CharacterInsight(
        category: InsightCategory.contentReadiness,
        severity: InsightSeverity.info,
        title: 'Listo para el lanzamiento de Midnight',
        description:
            'ilvl $ilvl — Base sólida para la expansión Midnight.$enchantNote',
        simpleExplanation:
            'Tienes una buena base de equipo para el lanzamiento de Midnight. '
            'En este punto, encantar y engarzar gemas aporta más valor '
            'que buscar más ilvl durante el pre-patch.',
        advancedDetail:
            'ilvl ${WowPatchContext.ilvlLaunchReady}–${WowPatchContext.ilvlCatchupCap} = pista Campeón de '
            '${WowPatchContext.catchupEventName} / nivel Normal de T3. '
            'Optimizar encantamientos y gemas da más rendimiento marginal '
            'que seguir subiendo ilvl en este rango. Acumula consumibles '
            '(frascos, pociones, runas) para el primer día de Midnight.',
        actionItems: [
          if (missingEnchants > 0)
            'Prioridad: añade $missingEnchants encantamiento${missingEnchants > 1 ? 's' : ''} que faltan',
          'Asegúrate de tener la gema meta ${WowPatchContext.metaGemFamily} y el bonus de 4 colores activo',
          'Acumula frascos, pociones y Crystallized Augment Runes para el lanzamiento',
          'Revisa los encantamientos BiS de tu spec en la sección de Builds',
        ],
      );
    }

    // ── Heroic equivalent ────────────────────────────────────────────────────
    if (ilvl < WowPatchContext.ilvlMythicEquiv) {
      return CharacterInsight(
        category: InsightCategory.contentReadiness,
        severity: InsightSeverity.positive,
        title: 'Bien preparado — nivel Heroica de T3',
        description:
            'ilvl $ilvl — Listo para el contenido inicial de Midnight.$enchantNote$scoreNote',
        simpleExplanation:
            'Preparación excelente — esto equivale al equipo de Heroica de T3. '
            'Estás muy por encima del techo de ${WowPatchContext.catchupEventName} y tendrás '
            'una experiencia de lanzamiento de Midnight muy cómoda.',
        advancedDetail:
            'ilvl ${WowPatchContext.ilvlHeroicEquiv}–${WowPatchContext.ilvlMythicEquiv - 1} = equivalente a Heroica de T3. '
            'Más fuerte que cualquier equipo de catch-up del pre-patch. '
            'En este tier, acumular consumibles y pulir gemas/encantamientos importa más que seguir subiendo ilvl.'
            '${score > 0 ? " Score M+ actual: ${score.toStringAsFixed(0)} (referencia; M+ congelado en pre-patch)." : ""}',
        actionItems: [
          if (missingEnchants > 0)
            'Termina $missingEnchants encantamiento${missingEnchants > 1 ? 's' : ''} pendiente${missingEnchants > 1 ? 's' : ''}',
          'Verifica que la gema meta y el bonus de 4 colores están activos',
          'Acumula consumibles para la semana de lanzamiento de Midnight',
        ],
      );
    }

    // ── Mythic equivalent (ilvl 158+) ────────────────────────────────────────
    return CharacterInsight(
      category: InsightCategory.contentReadiness,
      severity: InsightSeverity.positive,
      title: 'Preparación máxima — nivel Mítica de T3',
      description:
          'ilvl $ilvl — Optimización máxima en el pre-patch.$enchantNote$scoreNote',
      simpleExplanation:
          'Estás en la cima del equipo de pre-patch. El equipo de Mítica de T3 '
          'garantiza la experiencia de día uno más fluida posible en Midnight — '
          'tu equipo te llevará cómodamente por el contenido inicial de la expansión.',
      advancedDetail:
          'ilvl ${WowPatchContext.ilvlMythicEquiv}+ = nivel Mítica de T3 '
          '(techo ~${WowPatchContext.ilvlPrePatchMax}). '
          'En este punto, los consumibles y la composición del grupo importan más '
          'que el ilvl. El ilvl de Midnight Temporada 1 empieza en ~200+ '
          '(entrada recomendada M+2: 230+; techo del Gran Depósito en M+2: 272).'
          '${score > 0 ? " Score M+ pre-patch: ${score.toStringAsFixed(0)}." : ""}',
      actionItems: [
        if (missingEnchants > 0)
          'Completa $missingEnchants encantamiento${missingEnchants > 1 ? 's' : ''} pendiente${missingEnchants > 1 ? 's' : ''}',
        'Verifica la gema meta y el bonus de 4 colores',
        'Acumula consumibles y runas para la semana de lanzamiento',
        'Revisa las pistas de equipo de Midnight Temporada 1 cuando salgan (${WowPatchContext.season1StartDate})',
      ],
    );
  }
}
