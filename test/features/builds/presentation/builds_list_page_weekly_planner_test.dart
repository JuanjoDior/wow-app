import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wow_companion/core/di/injection.dart';
import 'package:wow_companion/features/builds/domain/entities/build.dart';
import 'package:wow_companion/features/builds/presentation/cubit/builds_cubit.dart';
import 'package:wow_companion/features/builds/presentation/cubit/builds_state.dart';
import 'package:wow_companion/features/builds/presentation/pages/builds_list_page.dart';
import 'package:wow_companion/features/planner/data/datasources/weekly_planner_datasource.dart';
import 'package:wow_companion/features/planner/domain/entities/weekly_planner.dart';
import 'package:wow_companion/l10n/generated/app_localizations.dart';

class _MockBuildsCubit extends MockCubit<BuildsState> implements BuildsCubit {}

class _MockWeeklyPlannerDataSource extends Mock
    implements WeeklyPlannerDataSource {}

void main() {
  late _MockBuildsCubit cubit;
  late _MockWeeklyPlannerDataSource plannerDataSource;

  setUp(() async {
    await sl.reset();
    cubit = _MockBuildsCubit();
    plannerDataSource = _MockWeeklyPlannerDataSource();

    when(() => cubit.loadBuilds()).thenAnswer((_) async {});

    sl.registerFactory<BuildsCubit>(() => cubit);
    sl.registerLazySingleton<WeeklyPlannerDataSource>(() => plannerDataSource);
  });

  tearDown(() async {
    await sl.reset();
  });

  Widget appWidget() {
    return MaterialApp(
      locale: const Locale('es'),
      supportedLocales: S.supportedLocales,
      localizationsDelegates: S.localizationsDelegates,
      home: const BuildsListPage(showWeeklyPlannerCard: true),
    );
  }

  Build buildFixture({required String id, String? refKey, String? refDisplay}) {
    return Build(
      id: id,
      name: 'Build $id',
      characterRefKey: refKey,
      characterRefDisplay: refDisplay,
      createdAt: DateTime(2026, 3, 5),
      slots: Build.emptySlots,
    );
  }

  WeeklyPlanner plannerFixture() {
    return WeeklyPlanner.fromJson({
      'version': 'v1',
      'endpoint': '/v1/planner/weekly',
      'context': {'region': 'eu', 'realm': 'sanguino', 'name': 'apastar'},
      'facts': {
        'equipped_items_count': 16,
        'enchanted_items_count': 6,
        'sockets_total_count': 4,
        'sockets_filled_count': 3,
        'sockets_empty_count': 1,
      },
      'mythic': {'rating': 2600, 'weekly_runs_estimated': 4},
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
    });
  }

  testWidgets('muestra tarjeta resumen semanal cuando hay build vinculada', (
    tester,
  ) async {
    final builds = [
      buildFixture(
        id: '1',
        refKey: 'eu-sanguino-apastar',
        refDisplay: 'Apastar - Sanguino',
      ),
    ];

    when(() => cubit.state).thenReturn(BuildsLoaded(builds));
    whenListen(
      cubit,
      const Stream<BuildsState>.empty(),
      initialState: BuildsLoaded(builds),
    );

    when(
      () => plannerDataSource.getWeeklyPlanner(
        region: any(named: 'region'),
        realm: any(named: 'realm'),
        name: any(named: 'name'),
        force: any(named: 'force'),
      ),
    ).thenAnswer((_) async => plannerFixture());

    await tester.pumpWidget(appWidget());
    await tester.pumpAndSettle();

    expect(find.text('Resumen semanal'), findsOneWidget);
    expect(find.text('60%'), findsOneWidget);
    expect(find.text('4'), findsWidgets);
    verify(
      () => plannerDataSource.getWeeklyPlanner(
        region: 'eu',
        realm: 'sanguino',
        name: 'apastar',
        force: false,
      ),
    ).called(1);
  });

  testWidgets('no muestra tarjeta semanal si no hay builds vinculadas', (
    tester,
  ) async {
    final builds = [buildFixture(id: '1')];
    when(() => cubit.state).thenReturn(BuildsLoaded(builds));
    whenListen(
      cubit,
      const Stream<BuildsState>.empty(),
      initialState: BuildsLoaded(builds),
    );

    await tester.pumpWidget(appWidget());
    await tester.pumpAndSettle();

    expect(find.text('Build 1'), findsOneWidget);
    expect(find.text('Resumen semanal'), findsNothing);
    verifyNever(
      () => plannerDataSource.getWeeklyPlanner(
        region: any(named: 'region'),
        realm: any(named: 'realm'),
        name: any(named: 'name'),
        force: any(named: 'force'),
      ),
    );
  });
}
