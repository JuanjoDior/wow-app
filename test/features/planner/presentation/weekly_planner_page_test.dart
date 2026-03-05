import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wow_companion/core/di/injection.dart';
import 'package:wow_companion/core/error/exceptions.dart';
import 'package:wow_companion/features/planner/data/datasources/weekly_planner_datasource.dart';
import 'package:wow_companion/features/planner/data/repositories/weekly_planner_local_progress_repository.dart';
import 'package:wow_companion/features/planner/domain/entities/weekly_planner.dart';
import 'package:wow_companion/features/planner/presentation/pages/weekly_planner_page.dart';
import 'package:wow_companion/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockWeeklyPlannerDataSource extends Mock
    implements WeeklyPlannerDataSource {}

void main() {
  late _MockWeeklyPlannerDataSource datasource;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await sl.reset();
    datasource = _MockWeeklyPlannerDataSource();
    sl.registerLazySingleton<WeeklyPlannerDataSource>(() => datasource);
    sl.registerLazySingleton<WeeklyPlannerLocalProgressRepository>(
      () => WeeklyPlannerLocalProgressRepository(),
    );
  });

  tearDown(() async {
    await sl.reset();
  });

  Widget appWidget(Widget child) {
    return MaterialApp(
      locale: const Locale('es'),
      supportedLocales: S.supportedLocales,
      localizationsDelegates: S.localizationsDelegates,
      home: child,
    );
  }

  testWidgets('muestra mensaje de feature desactivada', (tester) async {
    when(
      () => datasource.getWeeklyPlanner(
        region: any(named: 'region'),
        realm: any(named: 'realm'),
        name: any(named: 'name'),
        force: any(named: 'force'),
      ),
    ).thenThrow(
      const ServerException(
        message: 'Feature disabled: weekly_planner',
        statusCode: 503,
      ),
    );

    await tester.pumpWidget(
      appWidget(
        const WeeklyPlannerPage(
          region: 'eu',
          realm: 'sanguino',
          name: 'apastar',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Planificador Semanal'), findsOneWidget);
    expect(
      find.text('El Planificador Semanal está desactivado ahora mismo.'),
      findsOneWidget,
    );
  });

  testWidgets('renderiza resumen, afijos y acciones', (tester) async {
    final planner = WeeklyPlanner.fromJson({
      'version': 'v1',
      'endpoint': '/v1/planner/weekly',
      'context': {'region': 'eu', 'realm': 'sanguino', 'name': 'apastar'},
      'facts': {
        'equipped_items_count': 16,
        'enchanted_items_count': 8,
        'sockets_total_count': 7,
        'sockets_filled_count': 6,
        'sockets_empty_count': 1,
      },
      'mythic': {
        'rating': 2850.5,
        'weekly_runs_estimated': 4,
        'weekly_best_level': 12,
        'season_best_level': 15,
      },
      'summary': {
        'analysis_mode': 'objective',
        'checks_total': 5,
        'checks_completed': 3,
        'completion_pct': 60,
        'missing_enchants': 1,
        'missing_gems': 1,
        'weekly_runs_estimated': 4,
        'actions_count': 2,
      },
      'affixes': {
        'current': ['Fortified', 'Bursting'],
      },
      'checklist': [
        {
          'id': 'mplus_one_run',
          'label': 'Complete at least 1 Mythic+ run',
          'current': 0,
          'target': 1,
          'remaining': 1,
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
      ],
    });

    when(
      () => datasource.getWeeklyPlanner(
        region: any(named: 'region'),
        realm: any(named: 'realm'),
        name: any(named: 'name'),
        force: any(named: 'force'),
      ),
    ).thenAnswer((_) async => planner);

    await tester.pumpWidget(
      appWidget(
        const WeeklyPlannerPage(
          region: 'eu',
          realm: 'sanguino',
          name: 'apastar',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Resumen semanal'), findsOneWidget);
    expect(find.text('Afijos'), findsOneWidget);
    expect(find.text('Fortified'), findsOneWidget);
    expect(find.text('Bursting'), findsOneWidget);
    expect(find.text('Lista de tareas'), findsOneWidget);
    expect(find.textContaining('Completa al menos 1 Mythic+'), findsWidgets);
    expect(find.text('Acciones prioritarias'), findsOneWidget);
    expect(find.textContaining('(1 pendientes)'), findsOneWidget);
  });

  testWidgets('permite completar tareas en local y las rehidrata', (
    tester,
  ) async {
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
        'checks_total': 1,
        'checks_completed': 0,
        'completion_pct': 0,
        'missing_enchants': 1,
        'missing_gems': 1,
        'weekly_runs_estimated': 0,
        'actions_count': 1,
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
      ],
      'actions': [
        {
          'priority_score': 80,
          'type': 'mplus_one_run',
          'label': 'Complete at least 1 Mythic+ run (1 remaining)',
          'remaining': 1,
          'source': 'planner',
        },
      ],
    });

    when(
      () => datasource.getWeeklyPlanner(
        region: any(named: 'region'),
        realm: any(named: 'realm'),
        name: any(named: 'name'),
        force: any(named: 'force'),
      ),
    ).thenAnswer((_) async => planner);

    await tester.pumpWidget(
      appWidget(
        const WeeklyPlannerPage(
          region: 'eu',
          realm: 'sanguino',
          name: 'apastar',
        ),
      ),
    );
    await tester.pumpAndSettle();

    final checkboxFinder = find.byKey(
      const ValueKey('planner-check-mplus_one_run'),
    );
    expect(checkboxFinder, findsOneWidget);
    await tester.tap(checkboxFinder);
    await tester.pumpAndSettle();

    expect(find.text('No hay acciones pendientes.'), findsOneWidget);
    expect(find.text('Restablecer progreso local'), findsOneWidget);

    await tester.pumpWidget(
      appWidget(
        const WeeklyPlannerPage(
          region: 'eu',
          realm: 'sanguino',
          name: 'apastar',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No hay acciones pendientes.'), findsOneWidget);
    expect(find.text('Restablecer progreso local'), findsOneWidget);
  });
}
