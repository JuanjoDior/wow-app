import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wow_companion/core/error/exceptions.dart';
import 'package:wow_companion/core/network/api_client.dart';
import 'package:wow_companion/features/builds/data/datasources/economy_price_summary_datasource.dart';

class _MockApiClient extends Mock implements ApiClient {}

void main() {
  const healthUrl =
      'https://wow-recommendations.wow-comp-app.workers.dev/health';
  const economyUrl =
      'https://wow-recommendations.wow-comp-app.workers.dev/v1/economy/price-summary';

  late _MockApiClient apiClient;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue(<int>{});
  });

  setUp(() {
    apiClient = _MockApiClient();
  });

  test('lanza error cuando feature flag local está desactivado', () async {
    final datasource = EconomyPriceSummaryDataSource(
      apiClient,
      economyAssistantEnabled: false,
    );

    expect(
      () => datasource.getPriceSummary(region: 'eu', itemIds: const [213743]),
      throwsA(isA<ServerException>()),
    );

    verifyNever(
      () => apiClient.get(
        any(),
        queryParameters: any(named: 'queryParameters'),
        expectedErrorStatusCodes: any(named: 'expectedErrorStatusCodes'),
      ),
    );
  });

  test('usa endpoint v1 cuando capability de economía está activa', () async {
    final datasource = EconomyPriceSummaryDataSource(
      apiClient,
      economyAssistantEnabled: true,
    );

    when(
      () => apiClient.get(
        healthUrl,
        queryParameters: any(named: 'queryParameters'),
        expectedErrorStatusCodes: any(named: 'expectedErrorStatusCodes'),
      ),
    ).thenAnswer(
      (_) async => <String, dynamic>{
        'capabilities': {'economy_price_summary_v1': true},
      },
    );

    when(
      () => apiClient.get(
        economyUrl,
        queryParameters: any(named: 'queryParameters'),
        expectedErrorStatusCodes: any(named: 'expectedErrorStatusCodes'),
      ),
    ).thenAnswer(
      (_) async => <String, dynamic>{
        'version': 'v1',
        'endpoint': '/v1/economy/price-summary',
        'source': {
          'policy': 'official_only',
          'market': 'commodities',
          'data': 'blizzard',
        },
        'summary': {
          'requested_items': 2,
          'resolved_items': 1,
          'missing_items': 1,
        },
        'results': [
          {
            'item_id': 213743,
            'market': 'commodities',
            'currency': 'copper',
            'min_price': 1000000,
            'median_price': 1200000,
            'p95_price': 1400000,
            'total_quantity': 18,
            'listing_count': 6,
          },
        ],
      },
    );

    final summary = await datasource.getPriceSummary(
      region: 'eu',
      realm: 'sanguino',
      itemIds: const [213743, 212495],
      force: true,
    );

    expect(summary.version, 'v1');
    expect(summary.source?.market, 'commodities');
    expect(summary.summary.requestedItems, 2);
    expect(summary.results.length, 1);

    final captured = verify(
      () => apiClient.get(
        economyUrl,
        queryParameters: captureAny(named: 'queryParameters'),
        expectedErrorStatusCodes: captureAny(named: 'expectedErrorStatusCodes'),
      ),
    ).captured;
    final query = captured.whereType<Map<String, dynamic>>().single;
    expect(query['realm'], 'sanguino');
    expect(query['item_ids'], '213743,212495');
    expect(query['force'], '1');
  });

  test('lanza error cuando capability de economía no está activa', () async {
    final datasource = EconomyPriceSummaryDataSource(
      apiClient,
      economyAssistantEnabled: true,
    );

    when(
      () => apiClient.get(
        healthUrl,
        queryParameters: any(named: 'queryParameters'),
        expectedErrorStatusCodes: any(named: 'expectedErrorStatusCodes'),
      ),
    ).thenAnswer(
      (_) async => <String, dynamic>{
        'capabilities': {'economy_price_summary_v1': false},
      },
    );

    expect(
      () => datasource.getPriceSummary(region: 'eu', itemIds: const [213743]),
      throwsA(isA<ServerException>()),
    );
  });

  test('mapea 503 del worker a ServerException', () async {
    final datasource = EconomyPriceSummaryDataSource(
      apiClient,
      economyAssistantEnabled: true,
    );

    when(
      () => apiClient.get(
        healthUrl,
        queryParameters: any(named: 'queryParameters'),
        expectedErrorStatusCodes: any(named: 'expectedErrorStatusCodes'),
      ),
    ).thenAnswer(
      (_) async => <String, dynamic>{
        'capabilities': {'economy_price_summary_v1': true},
      },
    );

    when(
      () => apiClient.get(
        economyUrl,
        queryParameters: any(named: 'queryParameters'),
        expectedErrorStatusCodes: any(named: 'expectedErrorStatusCodes'),
      ),
    ).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: economyUrl),
        response: Response(
          requestOptions: RequestOptions(path: economyUrl),
          statusCode: 503,
          data: {'error': 'Feature disabled: economy_assistant'},
        ),
        type: DioExceptionType.badResponse,
      ),
    );

    expect(
      () => datasource.getPriceSummary(region: 'eu', itemIds: const [213743]),
      throwsA(
        isA<ServerException>().having((e) => e.statusCode, 'statusCode', 503),
      ),
    );
  });
}
