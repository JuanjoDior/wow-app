import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wow_companion/core/network/api_client.dart';
import 'package:wow_companion/features/items/data/datasources/tooltip_remote_datasource.dart';
import 'package:wow_companion/features/items/domain/entities/item.dart';
import 'package:wow_companion/features/items/domain/entities/tooltip_detail.dart';

class _MockApiClient extends Mock implements ApiClient {}

void main() {
  const endpoint =
      'https://wow-companion-api.wow-comp-app.workers.dev/api/tooltips/spell/3001';

  late _MockApiClient apiClient;
  late TooltipRemoteDataSource datasource;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    apiClient = _MockApiClient();
    datasource = TooltipRemoteDataSource(apiClient);
  });

  test('requests tooltip endpoint with locale region and bonus ids', () async {
    when(
      () => apiClient.get(
        any(),
        queryParameters: any(named: 'queryParameters'),
        expectedErrorStatusCodes: any(named: 'expectedErrorStatusCodes'),
      ),
    ).thenAnswer(
      (_) async => <String, dynamic>{
        'entity_kind': 'spell',
        'id': 3001,
        'name': 'Authority of Fiery Resolve',
        'name_localized': 'Autoridad de resolución ígnea',
        'quality': null,
        'header': {
          'item_level': 0,
          'damage_text': '13 - 24 Damage',
          'speed_text': 'Speed 3.60',
          'damage_per_second_text': '(5.1 damage per second)',
        },
        'sections': [
          {
            'kind': 'effects',
            'lines': [
              {
                'layout': 'text',
                'text': 'Permanently enchants a weapon.',
                'tone': 'positive',
              },
            ],
          },
          {
            'kind': 'economy',
            'lines': [
              {
                'layout': 'currency',
                'label': 'Sell Price',
                'gold': 1,
                'silver': 2,
                'copper': 3,
              },
            ],
          },
        ],
        'external_links': {'wowhead': 'https://www.wowhead.com/spell=3001'},
      },
    );

    final detail = await datasource.getTooltipDetail(
      TooltipEntityKind.spell,
      3001,
      locale: 'es_ES',
      region: 'us',
      bonusIds: const [12, 34],
    );

    final captured =
        verify(
              () => apiClient.get(
                endpoint,
                queryParameters: captureAny(named: 'queryParameters'),
                expectedErrorStatusCodes: any(
                  named: 'expectedErrorStatusCodes',
                ),
              ),
            ).captured.single
            as Map<String, dynamic>;
    expect(captured['locale'], 'es_ES');
    expect(captured['region'], 'us');
    expect(captured['bonus_ids'], '12,34');

    expect(detail.entityKind, TooltipEntityKind.spell);
    expect(detail.localizedName, 'Autoridad de resolución ígnea');
    expect(detail.sections, hasLength(2));
    expect(detail.sections.first.kind, TooltipSectionKind.effects);
    expect(detail.sections.last.lines.first.currency?.gold, 1);
    expect(detail.header.damageText, '13 - 24 Damage');
    expect(detail.header.speedText, 'Speed 3.60');
    expect(detail.header.damagePerSecondText, '(5.1 damage per second)');
    expect(detail.externalLinks.wowhead, 'https://www.wowhead.com/spell=3001');
  });
}
