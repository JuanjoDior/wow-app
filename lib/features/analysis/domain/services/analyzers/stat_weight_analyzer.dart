import 'package:wow_companion/features/analysis/domain/entities/character_insight.dart';
import 'package:wow_companion/features/builds/domain/entities/spec_recommendation.dart';
import 'package:wow_companion/features/character/domain/entities/character.dart';

/// Analiza la distribución de stats secundarias del personaje y la compara
/// con la prioridad recomendada para la spec activa.
///
/// No es un simulador: es una heurística orientativa que detecta desviaciones
/// significativas (≥[_threshold] puntos porcentuales) entre la stat secundaria
/// con mayor valor real y la que la guía marca como prioritaria.
///
/// Ejemplo: si la guía dice Haste > Crit pero el personaje tiene 28% Crit y
/// 18% Haste (diferencia 10 pp), se emite un [InsightSeverity.warning].
class StatWeightAnalyzer {
  const StatWeightAnalyzer();

  /// Diferencia mínima (pp) para emitir una advertencia.
  static const double _threshold = 10.0;

  /// Stats primarios que se ignoran en la comparación de secundarias.
  static const Set<String> _primaryStats = {
    'strength', 'agility', 'intellect', 'stamina',
  };

  /// Mapea nombre de stat (lowercase) al getter correspondiente en [CharacterStats].
  static final Map<String, double? Function(CharacterStats)> _getters = {
    'haste':            (s) => s.haste,
    'critical strike':  (s) => s.criticalStrike,
    'crit':             (s) => s.criticalStrike,
    'mastery':          (s) => s.mastery,
    'versatility':      (s) => s.versatility,
  };

  List<CharacterInsight> analyze(
    Character character,
    SpecRecommendation? recommendation,
  ) {
    final stats = character.stats;
    if (stats == null) return const [];
    if (recommendation == null || recommendation.statPriority.isEmpty) {
      return const [];
    }

    // 1. Extraer stats secundarias en el orden de prioridad de la guía
    final prioritized = recommendation.statPriority
        .map((s) => s.toLowerCase().trim())
        .where((s) => !_primaryStats.contains(s))
        .toList();

    if (prioritized.length < 2) return const [];

    // 2. Leer valores reales (solo los que tienen getter y valor > 0)
    final actual = <String, double>{};
    for (final stat in prioritized) {
      final getter = _getters[stat];
      if (getter == null) continue;
      final val = getter(stats);
      if (val != null && val > 0) actual[stat] = val;
    }

    if (actual.length < 2) return const [];

    // 3. Determinar qué stat secundaria prioritaria y cuál real lideran
    final expectedTop = prioritized.firstWhere(
      actual.containsKey,
      orElse: () => '',
    );
    if (expectedTop.isEmpty) return const [];

    final actualTop = actual.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    final topExpectedValue = actual[expectedTop] ?? 0;
    final topActualValue   = actual[actualTop]   ?? 0;
    final diff = topActualValue - topExpectedValue;

    // 4. Sin desviación significativa → positivo
    if (actualTop == expectedTop || diff < _threshold) {
      return [_buildPositive(expectedTop, actual, recommendation)];
    }

    // 5. Desviación significativa → advertencia
    return [
      _buildWarning(
        expectedTop:    expectedTop,
        actualTop:      actualTop,
        expectedValue:  topExpectedValue,
        actualValue:    topActualValue,
        diff:           diff,
        priority:       prioritized,
        recommendation: recommendation,
      ),
    ];
  }

  // ── Builders ───────────────────────────────────────────────────────────────

  CharacterInsight _buildWarning({
    required String expectedTop,
    required String actualTop,
    required double expectedValue,
    required double actualValue,
    required double diff,
    required List<String> priority,
    required SpecRecommendation recommendation,
  }) {
    final priorityStr = priority.map(_cap).join(' > ');
    final specLabel   =
        '${_cap(recommendation.specName)} ${_cap(recommendation.className)}';

    return CharacterInsight(
      category: InsightCategory.stats,
      severity: InsightSeverity.warning,
      title: 'Stats secundarias fuera de prioridad',
      description:
          '${_cap(actualTop)} (${actualValue.toStringAsFixed(1)}%) '
          'supera a ${_cap(expectedTop)} (${expectedValue.toStringAsFixed(1)}%) '
          'por ${diff.toStringAsFixed(1)} pp.',
      simpleExplanation:
          'Para $specLabel la guía recomienda priorizar ${_cap(expectedTop)} '
          'sobre ${_cap(actualTop)}. Actualmente llevas '
          '${diff.toStringAsFixed(0)} pp más de ${_cap(actualTop)} — '
          'vale la pena ajustarlo al renovar equipo.',
      advancedDetail:
          'Prioridad recomendada: $priorityStr. '
          'Valores actuales — ${_cap(expectedTop)}: ${expectedValue.toStringAsFixed(1)}% · '
          '${_cap(actualTop)}: ${actualValue.toStringAsFixed(1)}%. '
          'Diferencia: +${diff.toStringAsFixed(1)} pp. '
          'Análisis orientativo; simula en Raidbots para confirmar ratios exactos.',
      actionItems: [
        'Prioriza ${_cap(expectedTop)} al elegir entre piezas de equipo equivalentes',
        'Ten en cuenta los ratios de stat al hacer crafteo dirigido',
        'Simula en Raidbots.com con tu personaje actual para confirmar el impacto real',
      ],
    );
  }

  CharacterInsight _buildPositive(
    String topStat,
    Map<String, double> actual,
    SpecRecommendation recommendation,
  ) {
    final valStr = actual.entries
        .map((e) => '${_cap(e.key)}: ${e.value.toStringAsFixed(1)}%')
        .join(' · ');

    return CharacterInsight(
      category: InsightCategory.stats,
      severity: InsightSeverity.positive,
      title: 'Stats secundarias alineadas con la spec',
      description:
          'La distribución de stats coincide con la prioridad de '
          '${_cap(recommendation.specName)} ${_cap(recommendation.className)}.',
      simpleExplanation:
          'Tus stats secundarias están en el orden correcto para tu especialización. '
          '¡Buen trabajo!',
      advancedDetail:
          'Distribución actual: $valStr. '
          'El orden coincide con la prioridad de la guía. '
          'Simula en Raidbots para ajuste fino de ratios.',
      actionItems: const [],
    );
  }

  String _cap(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
