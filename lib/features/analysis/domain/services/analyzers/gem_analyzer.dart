import 'package:wow_companion/core/constants/wow_patch_constants.dart';
import 'package:wow_companion/features/analysis/domain/entities/character_insight.dart';
import 'package:wow_companion/features/builds/domain/entities/spec_recommendation.dart';
import 'package:wow_companion/features/character/domain/entities/character.dart';

/// Analyzes the character's gem setup for the Midnight pre-patch:
///   1. Meta gem (Blasphemite family) present?
///   2. 4-color requirement met to activate meta bonus?
///
/// Midnight gem system:
///   Meta gem: Culminating / Elusive / Insightful Blasphemite
///   4-color requirement: Ruby (red) + Emerald (green) + Sapphire (blue)
///     + Onyx (yellow) — one of each anywhere in gear activates the bonus.
///
/// Limitation: Raider.IO returns gem names for *socketed* gems only.
///   We can't detect empty sockets reliably — report 'no data' if gem list empty.
class GemAnalyzer {
  const GemAnalyzer();

  List<CharacterInsight> analyze(
    Character character,
    SpecRecommendation? recommendation,
  ) {
    // Collect all gem names across all equipped items
    final allGems = [
      for (final item in character.equipment) ...item.gems,
    ];

    // No gem data → can't determine state reliably
    if (allGems.isEmpty) {
      return [
        const CharacterInsight(
          category: InsightCategory.gems,
          severity: InsightSeverity.info,
          title: 'Sin datos de gemas disponibles',
          description:
              'No se pudieron detectar los sockets de gemas desde los datos de armadura. '
              'Verifica tus gemas en el juego.',
          simpleExplanation:
              'La app no pudo leer tus datos de gemas. Comprueba en el juego '
              'que tienes la gema meta Blasphemite engarzada en tu Casco, '
              'más una gema de cada color: Rubí, Esmeralda, Zafiro y Ónix.',
          actionItems: [
            'Abre la ficha de tu personaje en el juego',
            'Engarza la gema meta Blasphemite en tu Casco',
            'Añade un Rubí, una Esmeralda, un Zafiro y un Ónix en cualquier slot de tu equipo',
          ],
        ),
      ];
    }

    final insights = <CharacterInsight>[];
    final lower = allGems.map((g) => g.toLowerCase()).toList();

    // 1. Meta gem check (family name from WowPatchContext — update there each expansion)
    final hasMetaGem = lower.any(
      (g) => g.contains(WowPatchContext.metaGemFamily.toLowerCase()),
    );

    if (!hasMetaGem) {
      final recommended =
          recommendation?.metaGem?.name ?? 'Culminating Blasphemite';
      insights.add(CharacterInsight(
        category: InsightCategory.gems,
        severity: InsightSeverity.critical,
        title: 'Gema meta no encontrada',
        description: 'No se detectó ninguna gema meta Blasphemite. Recomendada: $recommended.',
        simpleExplanation:
            'La gema meta ($recommended) proporciona una bonificación enorme a tu stat principal '
            '— es la gema de mayor impacto que puedes añadir. Nada más se le acerca.',
        advancedDetail:
            'Gemas Blasphemite: Culminating (proc STR/AGI/INT), '
            'Elusive (velocidad de movimiento — sanadores/tanques), '
            'Insightful (maná — nicho). '
            'Requiere 1 gema de cada color (Rubí, Esmeralda, Zafiro, Ónix) '
            'en cualquier parte del equipo para activar completamente el bonus.',
        actionItems: [
          'Compra o fabrica $recommended en la Casa de Subastas',
          'Engarza la gema en tu Casco',
          'Añade 1 Rubí, 1 Esmeralda, 1 Zafiro y 1 Ónix en cualquier otro slot',
        ],
      ));
    }

    // 2. 4-color coverage check (colors from WowPatchContext.metaGemColors)
    final hasRed    = lower.any((g) => g.contains(WowPatchContext.metaGemColors[0].toLowerCase())); // Ruby
    final hasGreen  = lower.any((g) => g.contains(WowPatchContext.metaGemColors[1].toLowerCase())); // Emerald
    final hasBlue   = lower.any((g) => g.contains(WowPatchContext.metaGemColors[2].toLowerCase())); // Sapphire
    final hasYellow = lower.any((g) => g.contains(WowPatchContext.metaGemColors[3].toLowerCase())); // Onyx

    final missingColors = <String>[];
    if (!hasRed)    missingColors.add('Rojo (Rubí)');
    if (!hasGreen)  missingColors.add('Verde (Esmeralda)');
    if (!hasBlue)   missingColors.add('Azul (Zafiro)');
    if (!hasYellow) missingColors.add('Amarillo (Ónix)');

    if (missingColors.isNotEmpty) {
      insights.add(CharacterInsight(
        category: InsightCategory.gems,
        severity: InsightSeverity.warning,
        title: 'Bonus de gema meta no activo al 100%',
        description:
            'Faltan colores de gema para el bonus Blasphemite: ${missingColors.join(', ')}.',
        simpleExplanation:
            'La gema meta necesita una gema de cada color para desbloquear su potencia total. '
            'Pueden ser gemas baratas — la stat concreta importa poco, '
            'lo que importa es tener los colores correctos.',
        advancedDetail:
            'Requisito de 4 colores: Rubí (rojo), Esmeralda (verde), '
            'Zafiro (azul), Ónix (amarillo). Una de cada color en cualquier '
            'parte del equipo equipado activa el bonus de meta. '
            'Consejo: usa gemas acordes a tu stat — p.ej., Quick Ónix (Haste), '
            'Deadly Esmeralda (Crit).',
        actionItems: missingColors
            .map((c) => 'Añade una gema ${c.split(' ').first.toLowerCase()} — p.ej., ${_suggestGem(c)}')
            .toList(),
      ));
    }

    // 3. Estado positivo — todo correcto
    if (hasMetaGem && missingColors.isEmpty) {
      insights.add(CharacterInsight(
        category: InsightCategory.gems,
        severity: InsightSeverity.positive,
        title: 'Gemas configuradas correctamente',
        description:
            'Gema meta presente y los 4 colores activos (${allGems.length} gemas en total).',
        simpleExplanation:
            'Tu gema meta Blasphemite está activa y el bonus de 4 colores está desbloqueado. '
            'La optimización de gemas más importante está hecha.',
      ));
    }

    return insights;
  }

  String _suggestGem(String colorLabel) => switch (colorLabel) {
        'Rojo (Rubí)'       => 'Quick Ruby (Haste) o Deadly Ruby (Crit)',
        'Verde (Esmeralda)' => 'Deadly Emerald (Crit) o Masterful Emerald (Mastery)',
        'Azul (Zafiro)'     => 'Quick Sapphire (Haste) o Masterful Sapphire (Mastery)',
        'Amarillo (Ónix)'   => 'Quick Onyx (Haste) o Versatile Onyx (Versatility)',
        _                   => 'gema ${colorLabel.split(' ').first.toLowerCase()}',
      };
}
