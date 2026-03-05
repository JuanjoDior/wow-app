import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wow_companion/features/planner/data/repositories/weekly_planner_local_progress_repository.dart';

void main() {
  late WeeklyPlannerLocalProgressRepository repository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repository = WeeklyPlannerLocalProgressRepository();
  });

  test('guarda y recupera tareas completadas por personaje y semana', () async {
    final plannerKey = repository.buildPlannerKey(
      region: 'eu',
      realm: 'sanguino',
      name: 'apastar',
    );
    const weekKey = '2026-03-02';

    await repository.setCompletedTaskIds(
      plannerKey: plannerKey,
      weekKey: weekKey,
      taskIds: {'mplus_one_run', 'sockets_filled'},
    );

    final result = await repository.getCompletedTaskIds(
      plannerKey: plannerKey,
      weekKey: weekKey,
    );

    expect(result, {'mplus_one_run', 'sockets_filled'});
  });

  test('borra progreso de una semana sin afectar otras', () async {
    final plannerKey = repository.buildPlannerKey(
      region: 'eu',
      realm: 'sanguino',
      name: 'apastar',
    );

    await repository.setCompletedTaskIds(
      plannerKey: plannerKey,
      weekKey: '2026-03-02',
      taskIds: {'mplus_one_run'},
    );
    await repository.setCompletedTaskIds(
      plannerKey: plannerKey,
      weekKey: '2026-03-09',
      taskIds: {'mplus_four_runs'},
    );

    await repository.clearCompletedTaskIds(
      plannerKey: plannerKey,
      weekKey: '2026-03-02',
    );

    final weekA = await repository.getCompletedTaskIds(
      plannerKey: plannerKey,
      weekKey: '2026-03-02',
    );
    final weekB = await repository.getCompletedTaskIds(
      plannerKey: plannerKey,
      weekKey: '2026-03-09',
    );

    expect(weekA, isEmpty);
    expect(weekB, {'mplus_four_runs'});
  });

  test('normaliza week key al lunes en UTC', () {
    final weekKey = repository.buildWeekKey(DateTime.utc(2026, 3, 5, 23, 59));
    expect(weekKey, '2026-03-02');
  });
}
