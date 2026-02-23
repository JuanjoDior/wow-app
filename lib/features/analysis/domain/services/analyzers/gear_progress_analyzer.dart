import 'package:wow_companion/features/analysis/domain/entities/character_insight.dart';
import 'package:wow_companion/features/analysis/domain/entities/gear_snapshot.dart';
import 'package:wow_companion/features/character/domain/entities/character.dart';

/// Compara el estado actual del personaje con el snapshot anterior para
/// mostrar la evolución de ilvl y score M+ entre sesiones.
///
/// En la primera consulta (sin snapshot previo) registra el baseline y
/// muestra un mensaje informativo. En consultas posteriores muestra el
/// delta desde la última vez.
///
/// El snapshot se carga/guarda de forma asíncrona en [GearProgressService];
/// este analyzer recibe el snapshot ya resuelto como parámetro para
/// mantener la API de análisis síncrona.
class GearProgressAnalyzer {
  const GearProgressAnalyzer();

  /// Umbral mínimo de cambio en score M+ para considerarlo significativo.
  static const double _scoreThreshold = 5.0;

  List<CharacterInsight> analyze(
    Character character, {
    GearSnapshot? previousSnapshot,
  }) {
    final ilvl = character.equippedItemLevel;
    if (ilvl == null || ilvl == 0) return const [];

    final score = character.mythicPlusProfile?.scoreAll
        ?? character.mythicPlusScore
        ?? 0.0;

    // ── Primera visita: sin snapshot previo ──────────────────────────────────
    if (previousSnapshot == null) {
      return [
        CharacterInsight(
          category: InsightCategory.gearProgress,
          severity: InsightSeverity.info,
          title: 'Progresión: baseline registrado',
          description:
              'ilvl $ilvl · Score ${score.toStringAsFixed(0)} — '
              'vuelve después de tu próxima sesión para ver tu evolución.',
          simpleExplanation:
              'Hemos guardado el estado actual de tu personaje. '
              'La próxima vez que consultes este perfil verás cuánto '
              'ilvl y score M+ has ganado desde hoy.',
          advancedDetail:
              'Snapshot inicial guardado localmente. '
              'ilvl: $ilvl · Score M+: ${score.toStringAsFixed(1)}. '
              'La comparación estará disponible en la siguiente consulta.',
          actionItems: [
            'Vuelve a consultar el personaje tras tu próxima sesión de juego',
          ],
        ),
      ];
    }

    // ── Visitas posteriores: calcular deltas ─────────────────────────────────
    final ilvlDelta  = ilvl - previousSnapshot.ilvl;
    final scoreDelta = score - previousSnapshot.mplusScore;
    final daysSince  = DateTime.now().difference(previousSnapshot.date).inDays;
    final dateLabel  = daysSince == 0
        ? 'hoy'
        : '$daysSince día${daysSince != 1 ? "s" : ""}';

    // Sin cambios apreciables
    if (ilvlDelta == 0 && scoreDelta.abs() < _scoreThreshold) {
      return [
        CharacterInsight(
          category: InsightCategory.gearProgress,
          severity: InsightSeverity.info,
          title: 'Sin cambios desde la última consulta',
          description: 'ilvl $ilvl · Score ${score.toStringAsFixed(0)}',
          simpleExplanation:
              'Tu equipo y puntuación M+ no han cambiado desde $dateLabel.',
          advancedDetail:
              'Última snapshot: ${_formatDate(previousSnapshot.date)} · '
              'ilvl ${previousSnapshot.ilvl} · '
              'Score ${previousSnapshot.mplusScore.toStringAsFixed(1)}.',
          actionItems: const [],
        ),
      ];
    }

    // Con progreso (positivo o negativo)
    final parts = <String>[];
    if (ilvlDelta != 0) {
      parts.add('${ilvlDelta > 0 ? "+" : ""}$ilvlDelta ilvl');
    }
    if (scoreDelta.abs() >= _scoreThreshold) {
      parts.add(
        '${scoreDelta > 0 ? "+" : ""}${scoreDelta.toStringAsFixed(0)} score M+',
      );
    }
    final summary    = parts.join(' · ');
    final isProgress = ilvlDelta >= 0 && scoreDelta >= -_scoreThreshold;

    return [
      CharacterInsight(
        category: InsightCategory.gearProgress,
        severity:
            isProgress ? InsightSeverity.positive : InsightSeverity.info,
        title: isProgress
            ? 'Progreso desde la última consulta'
            : 'Cambios desde la última consulta',
        description: '$summary en $dateLabel.',
        simpleExplanation: isProgress
            ? '¡Has mejorado! $summary desde la última vez que consultaste '
              'este personaje.'
            : 'Tu personaje ha cambiado desde la última consulta: $summary.',
        advancedDetail:
            'Comparación — ilvl: ${previousSnapshot.ilvl} → $ilvl '
            '(${ilvlDelta >= 0 ? "+$ilvlDelta" : "$ilvlDelta"}) · '
            'Score M+: ${previousSnapshot.mplusScore.toStringAsFixed(1)} → '
            '${score.toStringAsFixed(1)} '
            '(${scoreDelta >= 0 ? "+${scoreDelta.toStringAsFixed(1)}" : scoreDelta.toStringAsFixed(1)}). '
            'Período: $dateLabel.',
        actionItems: const [],
      ),
    ];
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.year}';
}
