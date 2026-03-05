import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wow_companion/core/error/exceptions.dart';
import 'package:wow_companion/core/network/api_client.dart';
import 'package:wow_companion/features/planner/data/datasources/weekly_planner_datasource.dart';

class _MockApiClient extends Mock implements ApiClient {}

void main() {
  const healthUrl =
      'https://wow-recommendations.wow-comp-app.workers.dev/health';
  const plannerUrl =
      'https://wow-recommendations.wow-comp-app.workers.dev/v1/planner/weekly';

  late _MockApiClient apiClient;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue(<int>{});
  });

  setUp(() {
    apiClient = _MockApiClient();
  });

  test('lanza error cuando feature flag local está desactivado', () async {
    final datasource = WeeklyPlannerDataSource(
      apiClient,
      weeklyPlannerEnabled: false,
    );

    expect(
      () => datasource.getWeeklyPlanner(
        region: 'eu',
        realm: 'sanguino',
        name: 'apastar',
      ),
      throwsA(isA<ServerException>()),
    );

    verifyNever(
      () =>
          apiClient.get(any(), queryParameters: any(named: 'queryParameters')),
    );
  });

  test(
    'usa endpoint v1 cuando capability weekly_planner está activa',
    () async {
      final datasource = WeeklyPlannerDataSource(
        apiClient,
        weeklyPlannerEnabled: true,
      );

      when(
        () => apiClient.get(
          healthUrl,
          queryParameters: any(named: 'queryParameters'),
          expectedErrorStatusCodes: any(named: 'expectedErrorStatusCodes'),
        ),
      ).thenAnswer(
        (_) async => <String, dynamic>{
          'capabilities': {'weekly_planner': true},
        },
      );

      when(
        () => apiClient.get(
          plannerUrl,
          queryParameters: any(named: 'queryParameters'),
          expectedErrorStatusCodes: any(named: 'expectedErrorStatusCodes'),
        ),
      ).thenAnswer(
        (_) async => <String, dynamic>{
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
          'mythic': {'weekly_runs_estimated': 3},
          'summary': {
            'analysis_mode': 'objective',
            'checks_total': 5,
            'checks_completed': 3,
            'completion_pct': 60,
            'missing_enchants': 1,
            'missing_gems': 1,
            'weekly_runs_estimated': 3,
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
            },
          ],
        },
      );

      final planner = await datasource.getWeeklyPlanner(
        region: 'eu',
        realm: 'sanguino',
        name: 'apastar',
      );

      expect(planner.version, 'v1');
      expect(planner.summary.completionPct, 60);
      expect(planner.affixes, contains('Fortified'));
      expect(planner.actions.length, 1);
    },
  );

  test('lanza error cuando capability weekly_planner no está activa', () async {
    final datasource = WeeklyPlannerDataSource(
      apiClient,
      weeklyPlannerEnabled: true,
    );

    when(
      () => apiClient.get(
        healthUrl,
        queryParameters: any(named: 'queryParameters'),
        expectedErrorStatusCodes: any(named: 'expectedErrorStatusCodes'),
      ),
    ).thenAnswer(
      (_) async => <String, dynamic>{
        'capabilities': {'weekly_planner': false},
      },
    );

    expect(
      () => datasource.getWeeklyPlanner(
        region: 'eu',
        realm: 'sanguino',
        name: 'apastar',
      ),
      throwsA(isA<ServerException>()),
    );
  });

  test('mapea 503 del worker a ServerException', () async {
    final datasource = WeeklyPlannerDataSource(
      apiClient,
      weeklyPlannerEnabled: true,
    );

    when(
      () => apiClient.get(
        healthUrl,
        queryParameters: any(named: 'queryParameters'),
        expectedErrorStatusCodes: any(named: 'expectedErrorStatusCodes'),
      ),
    ).thenAnswer(
      (_) async => <String, dynamic>{
        'capabilities': {'weekly_planner': true},
      },
    );

    when(
      () => apiClient.get(
        plannerUrl,
        queryParameters: any(named: 'queryParameters'),
        expectedErrorStatusCodes: any(named: 'expectedErrorStatusCodes'),
      ),
    ).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: plannerUrl),
        response: Response(
          requestOptions: RequestOptions(path: plannerUrl),
          statusCode: 503,
          data: {'error': 'Feature disabled: weekly_planner'},
        ),
        type: DioExceptionType.badResponse,
      ),
    );

    expect(
      () => datasource.getWeeklyPlanner(
        region: 'eu',
        realm: 'sanguino',
        name: 'apastar',
      ),
      throwsA(
        isA<ServerException>().having((e) => e.statusCode, 'statusCode', 503),
      ),
    );
  });
}
