import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wow_companion/core/di/injection.dart';
import 'package:wow_companion/core/l10n/locale_notifier.dart';
import 'package:wow_companion/core/theme/wow_theme.dart';
import 'package:wow_companion/features/builds/data/datasources/build_gap_analysis_datasource.dart';
import 'package:wow_companion/features/builds/data/datasources/character_media_datasource.dart';
import 'package:wow_companion/features/builds/domain/entities/build.dart';
import 'package:wow_companion/features/builds/domain/entities/build_gap_analysis.dart';
import 'package:wow_companion/features/builds/domain/repositories/builds_repository.dart';
import 'package:wow_companion/features/builds/presentation/cubit/build_detail_cubit.dart';
import 'package:wow_companion/features/builds/presentation/pages/build_detail_page.dart';
import 'package:wow_companion/features/character/data/datasources/blizzard_character_datasource.dart';
import 'package:wow_companion/features/character/domain/entities/character.dart';
import 'package:wow_companion/features/items/domain/entities/item.dart';
import 'package:wow_companion/features/items/domain/usecases/get_item_detail.dart';
import 'package:wow_companion/l10n/generated/app_localizations.dart';

class _MockBuildsRepository extends Mock implements BuildsRepository {}

class _MockCharacterMediaDataSource extends Mock
    implements CharacterMediaDataSource {}

class _MockBuildGapAnalysisDataSource extends Mock
    implements BuildGapAnalysisDataSource {}

class _MockBlizzardCharacterDatasource extends Mock
    implements BlizzardCharacterDatasource {}

class _MockGetItemDetail extends Mock implements GetItemDetail {}

class _TestLocaleNotifier extends LocaleNotifier {
  Locale _currentLocale = const Locale('en');

  @override
  Locale get locale => _currentLocale;

  @override
  String get blizzardLocale =>
      _currentLocale.languageCode == 'es' ? 'es_ES' : 'en_GB';

  @override
  Future<void> load() async {}

  @override
  Future<void> setLocale(Locale newLocale) async {
    _currentLocale = newLocale;
    notifyListeners();
  }
}

void main() {
  late _MockBuildsRepository buildsRepository;
  late _MockCharacterMediaDataSource mediaDataSource;
  late _MockBuildGapAnalysisDataSource gapDataSource;
  late _MockBlizzardCharacterDatasource blizzardCharacterDatasource;
  late _MockGetItemDetail getItemDetail;
  late _TestLocaleNotifier localeNotifier;

  setUpAll(() {
    registerFallbackValue(<BuildSlot>[]);
    registerFallbackValue(
      Build(
        id: 'fallback',
        name: 'fallback',
        createdAt: DateTime(2026, 1, 1),
        slots: Build.emptySlots,
      ),
    );
  });

  setUp(() async {
    await sl.reset();
    buildsRepository = _MockBuildsRepository();
    mediaDataSource = _MockCharacterMediaDataSource();
    gapDataSource = _MockBuildGapAnalysisDataSource();
    blizzardCharacterDatasource = _MockBlizzardCharacterDatasource();
    getItemDetail = _MockGetItemDetail();
    localeNotifier = _TestLocaleNotifier();

    when(() => getItemDetail(any(), locale: any(named: 'locale'))).thenAnswer((
      invocation,
    ) async {
      final id = invocation.positionalArguments.first as int;
      final locale = invocation.namedArguments[#locale] as String? ?? 'en_GB';
      return Right(
        Item(
          id: id,
          name: locale == 'es_ES' ? 'Objeto $id' : 'Item $id',
          quality: 'COMMON',
          canonicalNameEn: 'Item $id',
          localizedName: locale == 'es_ES' ? 'Objeto $id' : null,
        ),
      );
    });
    when(() => buildsRepository.saveBuild(any())).thenAnswer((_) async {});

    sl.registerFactory<BuildDetailCubit>(
      () => BuildDetailCubit(
        buildsRepository,
        mediaDataSource,
        gapDataSource,
        blizzardCharacterDatasource,
        localeNotifier,
        getItemDetail,
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
  }) async {
    await localeNotifier.setLocale(locale);
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        supportedLocales: S.supportedLocales,
        localizationsDelegates: S.localizationsDelegates,
        theme: WowTheme.darkTheme,
        home: BuildDetailPage(buildId: buildId),
      ),
    );
  }

  Build buildFixture({
    required String id,
    String? characterRefKey,
    String? characterClass,
    String? characterSpec,
    List<BuildSlot>? slots,
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
      slots: slots ?? Build.emptySlots,
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

  testWidgets('keeps paperdoll slot heights stable with mixed content', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final headItem = Item(
      id: 1,
      name: 'Crown of the Endless Hunt',
      quality: 'EPIC',
      level: 639,
    );
    final enchantItem = Item(
      id: 2,
      name: 'Authority of Radiant Power',
      quality: 'EPIC',
    );
    final gemItem = Item(id: 3, name: 'Deadly Emerald', quality: 'RARE');
    final slots = Build.emptySlots
        .map(
          (slot) => slot.slot == WowSlot.head
              ? BuildSlot(
                  slot: WowSlot.head,
                  item: headItem,
                  enchantment: enchantItem,
                  gems: [gemItem, gemItem],
                  gemsObtained: const [true, false],
                )
              : slot,
        )
        .toList(growable: false);
    final analysis = BuildGapAnalysis(
      summary: const BuildGapSummary(
        checksTotal: 0,
        checksCompleted: 0,
        completionPct: 0,
        missingEnchants: 0,
        missingGems: 0,
        actionsCount: 0,
      ),
      actions: const [],
    );
    final build = buildFixture(
      id: 'paperdoll',
      characterRefKey: 'eu-sanguino-apastar',
      characterClass: 'Druid',
      characterSpec: 'Feral',
      slots: slots,
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

    final filledSlot = tester.getSize(
      find.byKey(const Key('paperdoll-slot-head')),
    );
    final emptySlot = tester.getSize(
      find.byKey(const Key('paperdoll-slot-shoulder')),
    );

    expect(filledSlot.height, emptySlot.height);
  });

  testWidgets('keeps the paperdoll grouped on very large screens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1920, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final build = buildFixture(id: 'wide-paperdoll');
    when(() => buildsRepository.getBuilds()).thenAnswer((_) async => [build]);

    await pumpPage(tester, build.id);
    await tester.pumpAndSettle();

    final leftRect = tester.getRect(
      find.byKey(const Key('paperdoll-left-column')),
    );
    final centerRect = tester.getRect(
      find.byKey(const Key('paperdoll-center-frame')),
    );
    final rightRect = tester.getRect(
      find.byKey(const Key('paperdoll-right-column')),
    );

    expect(centerRect.left - leftRect.right, lessThanOrEqualTo(32));
    expect(rightRect.left - centerRect.right, lessThanOrEqualTo(32));
    expect((centerRect.height - leftRect.height).abs(), lessThanOrEqualTo(1));
    expect((rightRect.height - centerRect.height).abs(), lessThanOrEqualTo(1));
  });

  testWidgets('localizes slot item names to the selected app locale', (
    tester,
  ) async {
    final headItem = Item(
      id: 11,
      name: 'Eternal Crown',
      quality: 'EPIC',
      level: 639,
      localizedName: 'Corona eterna',
      canonicalNameEn: 'Eternal Crown',
    );
    final enchantItem = Item(
      id: 12,
      name: 'Radiant Authority',
      quality: 'EPIC',
      localizedName: 'Autoridad radiante',
      canonicalNameEn: 'Radiant Authority',
    );
    final gemItem = Item(
      id: 13,
      name: 'Living Emerald',
      quality: 'RARE',
      localizedName: 'Esmeralda viva',
      canonicalNameEn: 'Living Emerald',
    );
    final slots = Build.emptySlots
        .map(
          (slot) => slot.slot == WowSlot.head
              ? BuildSlot(
                  slot: WowSlot.head,
                  item: headItem,
                  enchantment: enchantItem,
                  gems: [gemItem],
                )
              : slot,
        )
        .toList(growable: false);
    final build = buildFixture(
      id: 'localized-slots',
      characterClass: 'Druid',
      characterSpec: 'Feral',
      slots: slots,
    );

    when(() => buildsRepository.getBuilds()).thenAnswer((_) async => [build]);

    await pumpPage(tester, build.id, locale: const Locale('es'));
    await tester.pumpAndSettle();

    expect(find.text('Corona eterna'), findsOneWidget);
    expect(find.text('Eternal Crown'), findsNothing);

    await tester.tap(find.byKey(const Key('paperdoll-slot-head')));
    await tester.pumpAndSettle();

    expect(find.text('Corona eterna'), findsWidgets);
    expect(find.text('Autoridad radiante'), findsOneWidget);
    expect(find.text('Esmeralda viva'), findsOneWidget);
    expect(find.text('Radiant Authority'), findsNothing);
    expect(find.text('Living Emerald'), findsNothing);
  });

  testWidgets('uses compact slot truncation on narrower desktop widths', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final headItem = Item(
      id: 21,
      name: 'Frozen Instantaneous Blade of the Infernal Tempest',
      quality: 'EPIC',
      level: 108,
      canonicalNameEn: 'Frozen Instantaneous Blade of the Infernal Tempest',
    );
    final enchantItem = Item(
      id: 22,
      name: 'Authority of Radiant Power',
      quality: 'EPIC',
      canonicalNameEn: 'Authority of Radiant Power',
    );
    final gemItem = Item(
      id: 23,
      name: 'Masterful Emerald of the Fevered Dream',
      quality: 'RARE',
      canonicalNameEn: 'Masterful Emerald of the Fevered Dream',
    );
    final slots = Build.emptySlots
        .map(
          (slot) => slot.slot == WowSlot.mainHand
              ? BuildSlot(
                  slot: WowSlot.mainHand,
                  item: headItem,
                  enchantment: enchantItem,
                  gems: [gemItem],
                )
              : slot,
        )
        .toList(growable: false);
    final build = buildFixture(
      id: 'compact-slots',
      characterClass: 'Druid',
      characterSpec: 'Feral',
      slots: slots,
    );

    when(() => buildsRepository.getBuilds()).thenAnswer((_) async => [build]);

    await pumpPage(tester, build.id);
    await tester.pumpAndSettle();

    final itemName = tester.widget<Text>(
      find.byKey(const Key('paperdoll-slot-item-name-mainHand')),
    );

    expect(itemName.maxLines, 1);
    expect(itemName.data, 'Frozen Instantaneous Blade of the Infernal Tempest');
    expect(find.byTooltip('Authority of Radiant Power'), findsOneWidget);
    expect(
      find.byTooltip('Masterful Emerald of the Fevered Dream'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
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

  testWidgets(
    'shows only progress sync action when build has linked character',
    (tester) async {
      final build = buildFixture(
        id: 'syncButton',
        characterRefKey: 'eu-sanguino-apastar',
        characterClass: 'Druid',
        characterSpec: 'Feral',
      );
      final analysis = BuildGapAnalysis(
        summary: const BuildGapSummary(
          analysisMode: 'objective',
          targetProfile: 'build_target',
          checksTotal: 1,
          checksCompleted: 0,
          completionPct: 0,
          missingEnchants: 1,
          missingGems: 0,
          actionsCount: 1,
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

      expect(find.text('Sync progress'), findsOneWidget);
      expect(find.text('Import baseline'), findsNothing);
    },
  );

  testWidgets('runs progress sync and shows success snackbar', (tester) async {
    final build = buildFixture(
      id: 'syncSuccess',
      characterRefKey: 'eu-sanguino-apastar',
      characterClass: 'Druid',
      characterSpec: 'Feral',
    );
    final analysis = BuildGapAnalysis(
      summary: const BuildGapSummary(
        analysisMode: 'objective',
        targetProfile: 'build_target',
        checksTotal: 1,
        checksCompleted: 0,
        completionPct: 0,
        missingEnchants: 1,
        missingGems: 0,
        actionsCount: 1,
      ),
      actions: const [],
    );

    when(() => buildsRepository.getBuilds()).thenAnswer((_) async => [build]);
    when(() => buildsRepository.saveBuild(any())).thenAnswer((_) async {});
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
    when(
      () => blizzardCharacterDatasource.getCharacter(
        region: any(named: 'region'),
        realm: any(named: 'realm'),
        name: any(named: 'name'),
        locale: any(named: 'locale'),
        force: any(named: 'force'),
      ),
    ).thenAnswer(
      (_) async => const CharacterBlizzardData(
        name: 'Apastar',
        realm: 'Sanguino',
        region: 'EU',
        level: 80,
        race: 'Night Elf',
        characterClass: 'Druid',
        equipment: [
          EquippedItem(
            slot: 'HEAD',
            name: 'Headpiece',
            itemLevel: 626,
            quality: 'EPIC',
            enchantments: ['Authority of Radiant Power'],
            enchantmentIds: [2234],
            gems: ['Quick Ruby'],
            gemIds: [192982],
          ),
        ],
      ),
    );

    await pumpPage(tester, build.id);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sync progress'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.textContaining('Progress synced:'), findsOneWidget);
  });

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

    final syncButton = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Sync progress'),
    );
    expect(syncButton.onPressed, isNull);
  });
}
