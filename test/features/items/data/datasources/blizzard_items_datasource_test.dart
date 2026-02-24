import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wow_companion/core/network/api_client.dart';
import 'package:wow_companion/features/items/data/datasources/blizzard_items_datasource.dart';

class _MockApiClient extends Mock implements ApiClient {}

void main() {
  const searchUrl =
      'https://wow-companion-api.wow-comp-app.workers.dev/api/items/search';
  const detailUrl =
      'https://wow-companion-api.wow-comp-app.workers.dev/api/items/12345';

  late _MockApiClient apiClient;
  late BlizzardItemsDataSource datasource;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    apiClient = _MockApiClient();
    datasource = BlizzardItemsDataSource(apiClient);
  });

  test('searchItems sends locale in query params', () async {
    when(
      () =>
          apiClient.get(any(), queryParameters: any(named: 'queryParameters')),
    ).thenAnswer(
      (_) async => <String, dynamic>{
        'results': [
          {'id': 1, 'name': 'Moneda del linaje', 'quality': 'COMMON'},
        ],
      },
    );

    await datasource.searchItems('moneda', locale: 'es_ES');

    final captured =
        verify(
              () => apiClient.get(
                searchUrl,
                queryParameters: captureAny(named: 'queryParameters'),
              ),
            ).captured.single
            as Map<String, dynamic>;
    expect(captured['locale'], 'es_ES');
    expect(captured['name'], 'moneda');
  });

  test('getItemById sends locale in query params', () async {
    when(
      () =>
          apiClient.get(any(), queryParameters: any(named: 'queryParameters')),
    ).thenAnswer(
      (_) async => <String, dynamic>{
        'id': 12345,
        'name': 'Moneda del linaje',
        'quality': 'COMMON',
      },
    );

    await datasource.getItemById(12345, locale: 'es_ES');

    final captured =
        verify(
              () => apiClient.get(
                detailUrl,
                queryParameters: captureAny(named: 'queryParameters'),
              ),
            ).captured.single
            as Map<String, dynamic>;
    expect(captured['locale'], 'es_ES');
  });

  test('getItemById cache is separated by id and locale', () async {
    when(
      () =>
          apiClient.get(any(), queryParameters: any(named: 'queryParameters')),
    ).thenAnswer((invocation) async {
      final query =
          invocation.namedArguments[#queryParameters] as Map<String, dynamic>;
      final locale = query['locale'] as String? ?? 'en_GB';
      return <String, dynamic>{
        'id': 12345,
        'name': locale == 'es_ES' ? 'Moneda del linaje' : 'Lineage Coin',
        'quality': 'COMMON',
      };
    });

    final firstEs = await datasource.getItemById(12345, locale: 'es_ES');
    final firstEn = await datasource.getItemById(12345, locale: 'en_GB');
    final secondEs = await datasource.getItemById(12345, locale: 'es_ES');

    expect(firstEs.name, 'Moneda del linaje');
    expect(firstEn.name, 'Lineage Coin');
    expect(secondEs.name, 'Moneda del linaje');
    verify(
      () => apiClient.get(
        detailUrl,
        queryParameters: any(named: 'queryParameters'),
      ),
    ).called(2);
  });
}
