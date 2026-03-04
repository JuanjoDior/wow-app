import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wow_companion/core/error/exceptions.dart';
import 'package:wow_companion/core/network/api_client.dart';
import 'package:wow_companion/features/builds/data/datasources/build_gap_analysis_datasource.dart';
import 'package:wow_companion/features/builds/domain/entities/build.dart';
import 'package:wow_companion/features/items/domain/entities/item.dart';

class _MockApiClient extends Mock implements ApiClient {}

void main() {
  const v1Endpoint =
      'https://wow-recommendations.wow-comp-app.workers.dev/v1/build/gap-analysis';
  const v2Endpoint =
      'https://wow-recommendations.wow-comp-app.workers.dev/v2/build/verification';
  const healthEndpoint =
      'https://wow-recommendations.wow-comp-app.workers.dev/health';

  late _MockApiClient apiClient;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue(<int>{});
  });

  setUp(() {
    apiClient = _MockApiClient();
  });

  test('serializes build_slots with ids and names on v1 flow', () async {
    final datasource = BuildGapAnalysisDataSource(apiClient, v2Enabled: false);

    when(
      () => apiClient.get(
        any(),
        queryParameters: any(named: 'queryParameters'),
        expectedErrorStatusCodes: any(named: 'expectedErrorStatusCodes'),
      ),
    ).thenAnswer(
      (_) async => <String, dynamic>{
        'summary': {
          'checks_total': 1,
          'checks_completed': 1,
          'completion_pct': 100,
          'missing_enchants': 0,
          'missing_gems': 0,
          'actions_count': 0,
        },
        'actions': const [],
      },
    );

    await datasource.getGapAnalysis(
      region: 'EU',
      realm: 'Sanguino',
      name: 'Apastar',
      className: 'Druid',
      specName: 'Feral',
      buildSlots: [
        BuildSlot(
          slot: WowSlot.mainHand,
          enchantment: const Item(
            id: 1,
            name: 'Authority of Fiery Resolve',
            quality: 'EPIC',
          ),
          gems: const [
            Item(id: 2, name: 'Radiant Mastery', quality: 'UNCOMMON'),
          ],
        ),
      ],
      force: true,
    );

    final captured = verify(
      () => apiClient.get(
        v1Endpoint,
        queryParameters: captureAny(named: 'queryParameters'),
        expectedErrorStatusCodes: captureAny(named: 'expectedErrorStatusCodes'),
      ),
    ).captured;

    final capturedQuery = captured.whereType<Map<String, dynamic>>().single;
    final capturedExpectedStatuses = captured.whereType<Set<int>>().single;
    expect(capturedQuery['region'], 'eu');
    expect(capturedQuery['realm'], 'sanguino');
    expect(capturedQuery['name'], 'apastar');
    expect(capturedQuery['class'], 'druid');
    expect(capturedQuery['spec'], 'feral');
    expect(capturedQuery['force'], '1');
    expect(capturedExpectedStatuses, {400, 404});
    expect(capturedQuery['build_slots'], isA<String>());
    final serializedSlots = capturedQuery['build_slots'] as String;
    expect(serializedSlots, contains('"slot":"mainHand"'));
    expect(serializedSlots, contains('"enchantment_id":1'));
    expect(
      serializedSlots,
      contains('"enchantment":"Authority of Fiery Resolve"'),
    );
    expect(serializedSlots, contains('"gem_ids":[2]'));
    expect(serializedSlots, contains('"gems":["Radiant Mastery"]'));
  });

  test('uses v2 endpoint when enabled and supported by health', () async {
    final datasource = BuildGapAnalysisDataSource(apiClient, v2Enabled: true);

    when(
      () => apiClient.get(
        healthEndpoint,
        queryParameters: any(named: 'queryParameters'),
        expectedErrorStatusCodes: any(named: 'expectedErrorStatusCodes'),
      ),
    ).thenAnswer(
      (_) async => <String, dynamic>{
        'status': 'ok',
        'capabilities': {'build_verification_v2': true},
      },
    );

    when(
      () => apiClient.get(
        v2Endpoint,
        queryParameters: any(named: 'queryParameters'),
        expectedErrorStatusCodes: any(named: 'expectedErrorStatusCodes'),
      ),
    ).thenAnswer(
      (_) async => <String, dynamic>{
        'version': 'v2',
        'endpoint': '/v2/build/verification',
        'facts': {
          'equipped_items_count': 16,
          'enchanted_items_count': 8,
          'sockets_total_count': 7,
          'sockets_filled_count': 6,
          'sockets_empty_count': 1,
        },
        'summary': {
          'analysis_mode': 'objective',
          'target_profile': 'character_only',
          'checks_total': 0,
          'checks_completed': 0,
          'completion_pct': 0,
          'missing_enchants': 0,
          'missing_gems': 0,
          'actions_count': 0,
        },
        'actions': const [],
      },
    );

    final result = await datasource.getGapAnalysis(
      region: 'eu',
      realm: 'sanguino',
      name: 'apastar',
    );

    verify(
      () => apiClient.get(
        healthEndpoint,
        queryParameters: null,
        expectedErrorStatusCodes: const {},
      ),
    ).called(1);
    verify(
      () => apiClient.get(
        v2Endpoint,
        queryParameters: any(named: 'queryParameters'),
        expectedErrorStatusCodes: any(named: 'expectedErrorStatusCodes'),
      ),
    ).called(1);

    expect(result.version, 'v2');
    expect(result.summary.analysisMode, 'objective');
    expect(result.summary.targetProfile, 'character_only');
    expect(result.facts, isNotNull);
    expect(result.facts!.socketsFilledCount, 6);
  });

  test('falls back to v1 when v2 endpoint is unavailable', () async {
    final datasource = BuildGapAnalysisDataSource(apiClient, v2Enabled: true);

    when(
      () => apiClient.get(
        healthEndpoint,
        queryParameters: any(named: 'queryParameters'),
        expectedErrorStatusCodes: any(named: 'expectedErrorStatusCodes'),
      ),
    ).thenAnswer(
      (_) async => <String, dynamic>{
        'status': 'ok',
        'capabilities': {'build_verification_v2': true},
      },
    );

    when(
      () => apiClient.get(
        v2Endpoint,
        queryParameters: any(named: 'queryParameters'),
        expectedErrorStatusCodes: any(named: 'expectedErrorStatusCodes'),
      ),
    ).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: v2Endpoint),
        response: Response(
          requestOptions: RequestOptions(path: v2Endpoint),
          statusCode: 501,
          data: {'error': 'Not implemented'},
        ),
        type: DioExceptionType.badResponse,
      ),
    );

    when(
      () => apiClient.get(
        v1Endpoint,
        queryParameters: any(named: 'queryParameters'),
        expectedErrorStatusCodes: any(named: 'expectedErrorStatusCodes'),
      ),
    ).thenAnswer(
      (_) async => <String, dynamic>{
        'version': 'v1',
        'endpoint': '/v1/build/gap-analysis',
        'summary': {
          'analysis_mode': 'objective',
          'target_profile': 'build_target',
          'checks_total': 1,
          'checks_completed': 0,
          'completion_pct': 0,
          'missing_enchants': 1,
          'missing_gems': 0,
          'actions_count': 1,
        },
        'actions': [
          {
            'priority_score': 95,
            'slot': 'mainHand',
            'type': 'enchant_missing_target',
            'label': 'Apply Authority of Fiery Resolve',
            'recommended': 'Authority of Fiery Resolve',
          },
        ],
      },
    );

    final result = await datasource.getGapAnalysis(
      region: 'eu',
      realm: 'sanguino',
      name: 'apastar',
    );

    verify(
      () => apiClient.get(
        v1Endpoint,
        queryParameters: any(named: 'queryParameters'),
        expectedErrorStatusCodes: any(named: 'expectedErrorStatusCodes'),
      ),
    ).called(1);
    expect(result.version, 'v1');
    expect(result.actions, hasLength(1));
  });

  test('maps 404 to NotFoundException with worker message', () async {
    final datasource = BuildGapAnalysisDataSource(apiClient, v2Enabled: false);

    when(
      () => apiClient.get(
        any(),
        queryParameters: any(named: 'queryParameters'),
        expectedErrorStatusCodes: any(named: 'expectedErrorStatusCodes'),
      ),
    ).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: v1Endpoint),
        response: Response(
          requestOptions: RequestOptions(path: v1Endpoint),
          statusCode: 404,
          data: {'error': 'Character not found. Check region, realm and name.'},
        ),
        type: DioExceptionType.badResponse,
      ),
    );

    expect(
      () => datasource.getGapAnalysis(
        region: 'eu',
        realm: 'sanguino',
        name: 'apastar',
      ),
      throwsA(
        isA<NotFoundException>().having(
          (e) => e.message,
          'message',
          'Character not found. Check region, realm and name.',
        ),
      ),
    );
  });
}
