import 'package:wow_companion/features/planner/domain/entities/weekly_planner.dart';

WeeklyPlanner applyWeeklyPlannerLocalProgress(
  WeeklyPlanner planner,
  Set<String> localCompletedTaskIds,
) {
  if (planner.checklist.isEmpty || localCompletedTaskIds.isEmpty) {
    return planner;
  }

  final effectiveChecklist = planner.checklist
      .map((entry) {
        final done = entry.done || localCompletedTaskIds.contains(entry.id);
        if (!done) return entry;
        return WeeklyPlannerChecklistItem(
          id: entry.id,
          label: entry.label,
          current: entry.target,
          target: entry.target,
          remaining: 0,
          done: true,
          source: entry.source,
        );
      })
      .toList(growable: false);

  final completedIds = effectiveChecklist
      .where((entry) => entry.done)
      .map((entry) => entry.id)
      .toSet();

  final checksTotal = effectiveChecklist.length;
  final checksCompleted = completedIds.length;
  final completionPct = checksTotal > 0
      ? ((checksCompleted / checksTotal) * 100).round()
      : 0;
  final actions = planner.actions
      .where((entry) => !completedIds.contains(entry.type))
      .toList(growable: false);

  return WeeklyPlanner(
    version: planner.version,
    endpoint: planner.endpoint,
    generatedAt: planner.generatedAt,
    region: planner.region,
    realm: planner.realm,
    name: planner.name,
    facts: planner.facts,
    mythic: planner.mythic,
    summary: WeeklyPlannerSummary(
      analysisMode: planner.summary.analysisMode,
      checksTotal: checksTotal,
      checksCompleted: checksCompleted,
      completionPct: completionPct,
      missingEnchants: planner.summary.missingEnchants,
      missingGems: planner.summary.missingGems,
      weeklyRunsEstimated: planner.summary.weeklyRunsEstimated,
      actionsCount: actions.length,
    ),
    affixes: planner.affixes,
    checklist: effectiveChecklist,
    actions: actions,
  );
}
