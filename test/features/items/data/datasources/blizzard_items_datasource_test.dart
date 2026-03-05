import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wow_companion/core/network/api_client.dart';
import 'package:wow_companion/features/items/data/datasources/blizzard_items_datasource.dart';
import 'package:wow_companion/features/items/domain/entities/item_search_mode.dart';

class _MockApiClient extends Mock implements ApiClient {}

void main() {
  const searchUrl =
      'https://wow-companion-api.wow-comp-app.workers.dev/api/items/search';
  const detailUrl =
      'https://wow-companion-api.wow-comp-app.workers.dev/api/items/12345';
  const catalogSearchUrl =
      'https://wow-recommendations.wow-comp-app.workers.dev/v2/catalog/search';
  const catalogHealthUrl =
      'https://wow-recommendations.wow-comp-app.workers.dev/health';

  late _MockApiClient apiClient;
  late BlizzardItemsDataSource datasource;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue(<int>{});
  });

  setUp(() {
    apiClient = _MockApiClient();
    datasource = BlizzardItemsDataSource(apiClient, catalogV2Enabled: false);
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

  test('uses catalog V2 when enabled and health capability is true', () async {
    datasource = BlizzardItemsDataSource(apiClient, catalogV2Enabled: true);

    when(
      () => apiClient.get(
        catalogHealthUrl,
        queryParameters: any(named: 'queryParameters'),
        expectedErrorStatusCodes: any(named: 'expectedErrorStatusCodes'),
      ),
    ).thenAnswer(
      (_) async => <String, dynamic>{
        'capabilities': {'catalog_search_v2': true},
      },
    );

    when(
      () => apiClient.get(
        catalogSearchUrl,
        queryParameters: any(named: 'queryParameters'),
        expectedErrorStatusCodes: any(named: 'expectedErrorStatusCodes'),
      ),
    ).thenAnswer(
      (_) async => <String, dynamic>{
        'results': [
          {
            'id': 213743,
            'name_localized': 'Blasfemita culminante',
            'name_en_us': 'Culminating Blasphemite',
            'display_name': 'Blasfemita culminante',
            'quality': 'EPIC',
            'item_class': 'Gem',
            'item_subclass': 'Other',
            'inventory_type': 'NON_EQUIP',
            'inventory_name': 'Non-equippable',
            'icon_url': 'https://cdn/icon.jpg',
          },
        ],
      },
    );

    final items = await datasource.searchItems(
      'blasphemite',
      mode: ItemSearchMode.gem,
      locale: 'es_ES',
      region: 'eu',
      slot: 'finger1',
    );

    expect(items, hasLength(1));
    expect(items.first.name, 'Culminating Blasphemite');
    expect(items.first.localizedName, 'Blasfemita culminante');
    expect(items.first.canonicalNameEn, 'Culminating Blasphemite');

    final capturedQuery =
        verify(
              () => apiClient.get(
                catalogSearchUrl,
                queryParameters: captureAny(named: 'queryParameters'),
                expectedErrorStatusCodes: any(
                  named: 'expectedErrorStatusCodes',
                ),
              ),
            ).captured.single
            as Map<String, dynamic>;
    expect(capturedQuery['mode'], 'gem');
    expect(capturedQuery['slot'], 'finger1');
    expect(capturedQuery['region'], 'eu');
  });

  test('falls back to legacy search when catalog V2 returns 404', () async {
    datasource = BlizzardItemsDataSource(apiClient, catalogV2Enabled: true);

    when(
      () => apiClient.get(
        catalogHealthUrl,
        queryParameters: any(named: 'queryParameters'),
        expectedErrorStatusCodes: any(named: 'expectedErrorStatusCodes'),
      ),
    ).thenAnswer(
      (_) async => <String, dynamic>{
        'capabilities': {'catalog_search_v2': true},
      },
    );

    when(
      () => apiClient.get(
        catalogSearchUrl,
        queryParameters: any(named: 'queryParameters'),
        expectedErrorStatusCodes: any(named: 'expectedErrorStatusCodes'),
      ),
    ).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: catalogSearchUrl),
        response: Response(
          requestOptions: RequestOptions(path: catalogSearchUrl),
          statusCode: 404,
        ),
        type: DioExceptionType.badResponse,
      ),
    );

    when(
      () => apiClient.get(
        searchUrl,
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => <String, dynamic>{
        'results': [
          {'id': 1, 'name': 'Moneda del linaje', 'quality': 'COMMON'},
        ],
      },
    );

    final items = await datasource.searchItems('moneda', locale: 'es_ES');

    expect(items, hasLength(1));
    expect(items.first.name, 'Moneda del linaje');
    verify(
      () => apiClient.get(
        searchUrl,
        queryParameters: any(named: 'queryParameters'),
      ),
    ).called(1);
  });

  test('reranks enchant results in legacy search by exact relevance', () async {
    when(
      () =>
          apiClient.get(any(), queryParameters: any(named: 'queryParameters')),
    ).thenAnswer(
      (_) async => <String, dynamic>{
        'results': [
          {
            'id': 11,
            'name': 'QAEnchant Gloves +26 Attack Power',
            'quality': 'COMMON',
          },
          {
            'id': 12,
            'name': 'Enchant Weapon - Authority of Radiant Power',
            'quality': 'EPIC',
          },
        ],
      },
    );

    final items = await datasource.searchItems(
      'Authority of Radiant Power',
      mode: ItemSearchMode.enchant,
      locale: 'en_US',
    );

    expect(items, hasLength(2));
    expect(items.first.id, 12);
  });

  test('reranks gem over recipe in legacy search', () async {
    when(
      () =>
          apiClient.get(any(), queryParameters: any(named: 'queryParameters')),
    ).thenAnswer(
      (_) async => <String, dynamic>{
        'results': [
          {
            'id': 21,
            'name': 'Design: Culminating Blasphemite',
            'quality': 'COMMON',
            'itemClass': 'Recipe',
            'itemSubclass': 'Jewelcrafting',
            'inventoryType': 'NON_EQUIP',
          },
          {
            'id': 22,
            'name': 'Culminating Blasphemite',
            'quality': 'EPIC',
            'itemClass': 'Gem',
            'itemSubclass': 'Other',
            'inventoryType': 'NON_EQUIP',
          },
        ],
      },
    );

    final items = await datasource.searchItems(
      'Culminating Blasphemite',
      mode: ItemSearchMode.gem,
      locale: 'en_US',
    );

    expect(items, hasLength(2));
    expect(items.first.id, 22);
  });
}
