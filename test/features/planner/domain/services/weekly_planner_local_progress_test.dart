import 'package:flutter_test/flutter_test.dart';
import 'package:wow_companion/features/planner/domain/entities/weekly_planner.dart';
import 'package:wow_companion/features/planner/domain/services/weekly_planner_local_progress.dart';

void main() {
  test('aplica completados locales y recalcula resumen/acciones', () {
    final planner = WeeklyPlanner.fromJson({
      'version': 'v1',
      'endpoint': '/v1/planner/weekly',
      'generated_at': '2026-03-05T12:00:00Z',
      'context': {'region': 'eu', 'realm': 'sanguino', 'name': 'apastar'},
      'facts': {
        'equipped_items_count': 16,
        'enchanted_items_count': 8,
        'sockets_total_count': 7,
        'sockets_filled_count': 6,
        'sockets_empty_count': 1,
      },
      'mythic': {'weekly_runs_estimated': 0},
      'summary': {
        'analysis_mode': 'objective',
        'checks_total': 2,
        'checks_completed': 0,
        'completion_pct': 0,
        'missing_enchants': 1,
        'missing_gems': 1,
        'weekly_runs_estimated': 0,
        'actions_count': 2,
      },
      'affixes': {'current': []},
      'checklist': [
        {
          'id': 'mplus_one_run',
          'label': 'Complete at least 1 Mythic+ run',
          'current': 0,
          'target': 1,
          'remaining': 1,
          'done': false,
        },
        {
          'id': 'mplus_four_runs',
          'label': 'Complete 4 Mythic+ runs',
          'current': 0,
          'target': 4,
          'remaining': 4,
          'done': false,
        },
      ],
      'actions': [
        {
          'priority_score': 80,
          'type': 'mplus_one_run',
          'label': 'Complete at least 1 Mythic+ run (1 remaining)',
          'remaining': 1,
          'source': 'planner',
        },
        {
          'priority_score': 70,
          'type': 'mplus_four_runs',
          'label': 'Complete 4 Mythic+ runs (4 remaining)',
          'remaining': 4,
          'source': 'planner',
        },
      ],
    });

    final result = applyWeeklyPlannerLocalProgress(planner, {'mplus_one_run'});

    expect(result.summary.checksCompleted, 1);
    expect(result.summary.completionPct, 50);
    expect(result.summary.actionsCount, 1);
    expect(result.actions.map((e) => e.type), ['mplus_four_runs']);
    expect(
      result.checklist.firstWhere((e) => e.id == 'mplus_one_run').done,
      isTrue,
    );
  });
}
