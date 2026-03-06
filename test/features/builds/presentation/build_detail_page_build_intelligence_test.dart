import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wow_companion/core/di/injection.dart';
import 'package:wow_companion/features/builds/data/datasources/build_gap_analysis_datasource.dart';
import 'package:wow_companion/features/builds/data/datasources/character_media_datasource.dart';
import 'package:wow_companion/features/builds/data/datasources/economy_price_summary_datasource.dart';
import 'package:wow_companion/features/builds/domain/entities/build.dart';
import 'package:wow_companion/features/builds/domain/entities/build_gap_analysis.dart';
import 'package:wow_companion/features/builds/domain/entities/economy_price_summary.dart';
import 'package:wow_companion/features/builds/domain/repositories/builds_repository.dart';
import 'package:wow_companion/features/builds/presentation/cubit/build_detail_cubit.dart';
import 'package:wow_companion/features/builds/presentation/pages/build_detail_page.dart';
import 'package:wow_companion/features/items/domain/entities/item.dart';
import 'package:wow_companion/core/theme/wow_theme.dart';
import 'package:wow_companion/l10n/generated/app_localizations.dart';

class _MockBuildsRepository extends Mock implements BuildsRepository {}

class _MockCharacterMediaDataSource extends Mock
    implements CharacterMediaDataSource {}

class _MockBuildGapAnalysisDataSource extends Mock
    implements BuildGapAnalysisDataSource {}

class _MockEconomyPriceSummaryDataSource extends Mock
    implements EconomyPriceSummaryDataSource {}

void main() {
  late _MockBuildsRepository buildsRepository;
  late _MockCharacterMediaDataSource mediaDataSource;
  late _MockBuildGapAnalysisDataSource gapDataSource;
  late _MockEconomyPriceSummaryDataSource economyDataSource;
  late bool economyAssistantEnabled;

  setUpAll(() {
    registerFallbackValue(<BuildSlot>[]);
    registerFallbackValue(<int>[]);
  });

  setUp(() async {
    await sl.reset();
    buildsRepository = _MockBuildsRepository();
    mediaDataSource = _MockCharacterMediaDataSource();
    gapDataSource = _MockBuildGapAnalysisDataSource();
    economyDataSource = _MockEconomyPriceSummaryDataSource();
    economyAssistantEnabled = false;

    sl.registerFactory<BuildDetailCubit>(
      () => BuildDetailCubit(
        buildsRepository,
        mediaDataSource,
        gapDataSource,
        economyDataSource,
        economyAssistantEnabled: economyAssistantEnabled,
      ),
    );
  });

  tearDown(() async {
    await sl.reset();
  });

  Future<void> pumpPage(
    WidgetTester tester,
    String buildId, {
    Locale locale = const Locale('en'),
    bool? showEconomyAssistant,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        supportedLocales: S.supportedLocales,
        localizationsDelegates: S.localizationsDelegates,
        theme: WowTheme.darkTheme,
        home: BuildDetailPage(
          buildId: buildId,
          showEconomyAssistant: showEconomyAssistant,
        ),
      ),
    );
  }

  Build buildFixture({
    required String id,
    String? characterRefKey,
    String? characterClass,
    String? characterSpec,
  }) {
    return Build(
      id: id,
      name: 'Test Build',
      characterRefKey: characterRefKey,
      characterRefDisplay: characterRefKey == null
          ? null
          : 'Apastar - Sanguino',
      characterClass: characterClass,
      characterSpec: characterSpec,
      createdAt: DateTime(2026, 3, 4),
      slots: Build.emptySlots,
    );
  }

  testWidgets('shows missing character message when build is generic', (
    tester,
  ) async {
    final build = buildFixture(id: 'b1');
    when(() => buildsRepository.getBuilds()).thenAnswer((_) async => [build]);

    await pumpPage(tester, build.id);
    await tester.pumpAndSettle();

    expect(find.text('Build Verification'), findsOneWidget);
    expect(find.text('Link a character to run analysis.'), findsOneWidget);
  });

  testWidgets(
    'shows summary and top actions when target analysis is available',
    (tester) async {
      final build = buildFixture(
        id: 'b2',
        characterRefKey: 'eu-sanguino-apastar',
        characterClass: 'Druid',
        characterSpec: 'Feral',
      );
      final analysis = BuildGapAnalysis(
        summary: const BuildGapSummary(
          analysisMode: 'objective',
          targetProfile: 'build_target',
          checksTotal: 11,
          checksCompleted: 8,
          completionPct: 73,
          missingEnchants: 2,
          missingGems: 1,
          actionsCount: 3,
        ),
        actions: const [
          BuildGapAction(
            priorityScore: 95,
            slot: 'mainHand',
            type: 'enchant',
            label: 'Apply Authority of Radiant Power',
            recommended: 'Authority of Radiant Power',
            estimatedImpact: 'high',
          ),
        ],
      );

      when(() => buildsRepository.getBuilds()).thenAnswer((_) async => [build]);
      when(
        () => mediaDataSource.getMedia(
          region: any(named: 'region'),
          realm: any(named: 'realm'),
          name: any(named: 'name'),
        ),
      ).thenAnswer((_) async => null);
      when(
        () => gapDataSource.getGapAnalysis(
          region: any(named: 'region'),
          realm: any(named: 'realm'),
          name: any(named: 'name'),
          className: any(named: 'className'),
          specName: any(named: 'specName'),
          buildSlots: any(named: 'buildSlots'),
          force: any(named: 'force'),
        ),
      ).thenAnswer((_) async => analysis);

      await pumpPage(tester, build.id);
      await tester.pumpAndSettle();

      expect(find.text('Build Verification'), findsOneWidget);
      expect(find.text('Top actions'), findsOneWidget);
      expect(find.text('73%'), findsOneWidget);
      expect(
        find.textContaining('Apply Authority of Radiant Power'),
        findsOneWidget,
      );
    },
  );

  testWidgets('muestra coste y ROI cuando la verificación incluye economía', (
    tester,
  ) async {
    final build = buildFixture(
      id: 'b2roi',
      characterRefKey: 'eu-sanguino-apastar',
      characterClass: 'Druid',
      characterSpec: 'Feral',
    );
    final analysis = BuildGapAnalysis(
      summary: const BuildGapSummary(
        analysisMode: 'objective',
        targetProfile: 'build_target',
        checksTotal: 2,
        checksCompleted: 1,
        completionPct: 50,
        missingEnchants: 1,
        missingGems: 0,
        actionsCount: 1,
        pricedActionsCount: 1,
        actionsWithoutPriceCount: 0,
        estimatedTotalCostCopper: 1750000,
      ),
      actions: const [
        BuildGapAction(
          priorityScore: 95,
          slot: 'mainHand',
          type: 'enchant_missing_target',
          label: 'Apply Authority of Fiery Resolve',
          expected: 'Authority of Fiery Resolve',
          expectedId: 2002,
          estimatedCostCopper: 1750000,
          roiScore: 100,
          priceMarket: 'commodities',
        ),
      ],
    );

    when(() => buildsRepository.getBuilds()).thenAnswer((_) async => [build]);
    when(
      () => mediaDataSource.getMedia(
        region: any(named: 'region'),
        realm: any(named: 'realm'),
        name: any(named: 'name'),
      ),
    ).thenAnswer((_) async => null);
    when(
      () => gapDataSource.getGapAnalysis(
        region: any(named: 'region'),
        realm: any(named: 'realm'),
        name: any(named: 'name'),
        className: any(named: 'className'),
        specName: any(named: 'specName'),
        buildSlots: any(named: 'buildSlots'),
        force: any(named: 'force'),
      ),
    ).thenAnswer((_) async => analysis);

    await pumpPage(tester, build.id, locale: const Locale('es'));
    await tester.pumpAndSettle();

    expect(find.text('Coste estimado'), findsOneWidget);
    expect(find.text('175g 0s 0c'), findsWidgets);
    expect(find.textContaining('ROI: 100'), findsOneWidget);
  });

  testWidgets('localiza acciones de verificación en español', (tester) async {
    final build = buildFixture(
      id: 'b2es',
      characterRefKey: 'eu-sanguino-apastar',
      characterClass: 'Druid',
      characterSpec: 'Feral',
    );
    final analysis = BuildGapAnalysis(
      summary: const BuildGapSummary(
        analysisMode: 'objective',
        targetProfile: 'build_target',
        checksTotal: 4,
        checksCompleted: 2,
        completionPct: 50,
        missingEnchants: 1,
        missingGems: 1,
        actionsCount: 2,
      ),
      actions: const [
        BuildGapAction(
          priorityScore: 95,
          slot: 'mainHand',
          type: 'enchant_missing_target',
          label: 'Apply Authority of Radiant Power',
          expected: 'Authority of Radiant Power',
          source: 'build',
        ),
      ],
    );

    when(() => buildsRepository.getBuilds()).thenAnswer((_) async => [build]);
    when(
      () => mediaDataSource.getMedia(
        region: any(named: 'region'),
        realm: any(named: 'realm'),
        name: any(named: 'name'),
      ),
    ).thenAnswer((_) async => null);
    when(
      () => gapDataSource.getGapAnalysis(
        region: any(named: 'region'),
        realm: any(named: 'realm'),
        name: any(named: 'name'),
        className: any(named: 'className'),
        specName: any(named: 'specName'),
        buildSlots: any(named: 'buildSlots'),
        force: any(named: 'force'),
      ),
    ).thenAnswer((_) async => analysis);

    await pumpPage(tester, build.id, locale: const Locale('es'));
    await tester.pumpAndSettle();

    expect(find.text('Verificación de Build'), findsOneWidget);
    expect(
      find.textContaining('Aplica Authority of Radiant Power'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Apply Authority of Radiant Power'),
      findsNothing,
    );
  });

  testWidgets(
    'shows objective facts when character has no local target build',
    (tester) async {
      final build = buildFixture(
        id: 'bFacts',
        characterRefKey: 'eu-sanguino-apastar',
        characterClass: 'Druid',
        characterSpec: 'Feral',
      );
      final analysis = BuildGapAnalysis(
        version: 'v2',
        endpoint: '/v2/build/verification',
        facts: const BuildGapFacts(
          equippedItemsCount: 16,
          enchantedItemsCount: 8,
          socketsTotalCount: 7,
          socketsFilledCount: 6,
          socketsEmptyCount: 1,
        ),
        summary: const BuildGapSummary(
          analysisMode: 'objective',
          targetProfile: 'character_only',
          checksTotal: 0,
          checksCompleted: 0,
          completionPct: 0,
          missingEnchants: 0,
          missingGems: 0,
          actionsCount: 0,
        ),
        actions: const [],
      );

      when(() => buildsRepository.getBuilds()).thenAnswer((_) async => [build]);
      when(
        () => mediaDataSource.getMedia(
          region: any(named: 'region'),
          realm: any(named: 'realm'),
          name: any(named: 'name'),
        ),
      ).thenAnswer((_) async => null);
      when(
        () => gapDataSource.getGapAnalysis(
          region: any(named: 'region'),
          realm: any(named: 'realm'),
          name: any(named: 'name'),
          className: any(named: 'className'),
          specName: any(named: 'specName'),
          buildSlots: any(named: 'buildSlots'),
          force: any(named: 'force'),
        ),
      ).thenAnswer((_) async => analysis);

      await pumpPage(tester, build.id);
      await tester.pumpAndSettle();

      expect(find.text('Build Verification'), findsOneWidget);
      expect(find.text('Verifiable character status'), findsOneWidget);
      expect(find.text('Equipped slots'), findsOneWidget);
      expect(find.text('16'), findsOneWidget);
      expect(find.text('6/7'), findsOneWidget);
      expect(find.text('Top actions'), findsNothing);
    },
  );

  testWidgets('shows loading indicator while gap analysis is in progress', (
    tester,
  ) async {
    final build = buildFixture(
      id: 'b3',
      characterRefKey: 'eu-sanguino-apastar',
      characterClass: 'Druid',
      characterSpec: 'Feral',
    );
    final pending = Completer<BuildGapAnalysis>();

    when(() => buildsRepository.getBuilds()).thenAnswer((_) async => [build]);
    when(
      () => mediaDataSource.getMedia(
        region: any(named: 'region'),
        realm: any(named: 'realm'),
        name: any(named: 'name'),
      ),
    ).thenAnswer((_) async => null);
    when(
      () => gapDataSource.getGapAnalysis(
        region: any(named: 'region'),
        realm: any(named: 'realm'),
        name: any(named: 'name'),
        className: any(named: 'className'),
        specName: any(named: 'specName'),
        buildSlots: any(named: 'buildSlots'),
        force: any(named: 'force'),
      ),
    ).thenAnswer((_) => pending.future);

    await pumpPage(tester, build.id);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Build Verification'), findsOneWidget);

    final intelligenceCard = find
        .ancestor(
          of: find.text('Build Verification'),
          matching: find.byType(Card),
        )
        .first;
    expect(
      find.descendant(
        of: intelligenceCard,
        matching: find.byType(CircularProgressIndicator),
      ),
      findsWidgets,
    );
  });

  testWidgets('muestra panel de economia con precios cuando está activo', (
    tester,
  ) async {
    economyAssistantEnabled = true;
    final build =
        buildFixture(
          id: 'bEco',
          characterRefKey: 'eu-sanguino-apastar',
          characterClass: 'Druid',
          characterSpec: 'Feral',
        ).copyWith(
          slots: [
            BuildSlot(
              slot: WowSlot.mainHand,
              enchantment: const Item(
                id: 5001,
                name: 'Authority of Radiant Power',
                quality: 'EPIC',
              ),
              gems: const [
                Item(
                  id: 213743,
                  name: 'Culminating Blasphemite',
                  quality: 'EPIC',
                ),
              ],
            ),
          ],
          guide: BuildGuide(
            consumables: const BuildConsumables(
              flask: Item(id: 212495, name: 'Flask', quality: 'UNCOMMON'),
            ),
          ),
        );

    when(() => buildsRepository.getBuilds()).thenAnswer((_) async => [build]);
    when(
      () => mediaDataSource.getMedia(
        region: any(named: 'region'),
        realm: any(named: 'realm'),
        name: any(named: 'name'),
      ),
    ).thenAnswer((_) async => null);
    when(
      () => gapDataSource.getGapAnalysis(
        region: any(named: 'region'),
        realm: any(named: 'realm'),
        name: any(named: 'name'),
        className: any(named: 'className'),
        specName: any(named: 'specName'),
        buildSlots: any(named: 'buildSlots'),
        force: any(named: 'force'),
      ),
    ).thenAnswer(
      (_) async => BuildGapAnalysis(
        summary: const BuildGapSummary(
          checksTotal: 0,
          checksCompleted: 0,
          completionPct: 0,
          missingEnchants: 0,
          missingGems: 0,
          actionsCount: 0,
        ),
        actions: const [],
      ),
    );
    when(
      () => economyDataSource.getPriceSummary(
        region: any(named: 'region'),
        itemIds: any(named: 'itemIds'),
        connectedRealmId: any(named: 'connectedRealmId'),
        force: any(named: 'force'),
      ),
    ).thenAnswer(
      (_) async => EconomyPriceSummary(
        summary: const EconomyPriceSummaryStats(
          requestedItems: 3,
          resolvedItems: 2,
          missingItems: 1,
        ),
        source: const EconomyPriceSummarySource(market: 'commodities'),
        results: const [
          EconomyPriceResult(
            itemId: 213743,
            minPrice: 1000000,
            medianPrice: 1300000,
            p95Price: 1600000,
            totalQuantity: 25,
            listingCount: 8,
          ),
          EconomyPriceResult(
            itemId: 5001,
            minPrice: 900000,
            medianPrice: 1100000,
            p95Price: 1400000,
            totalQuantity: 18,
            listingCount: 5,
          ),
        ],
      ),
    );

    await pumpPage(tester, build.id, showEconomyAssistant: true);
    await tester.pumpAndSettle();

    expect(find.text('Economy Assistant'), findsOneWidget);
    expect(find.text('Top market costs'), findsOneWidget);
    expect(find.text('2/3'), findsOneWidget);
    expect(find.textContaining('Culminating Blasphemite'), findsOneWidget);
  });
}
