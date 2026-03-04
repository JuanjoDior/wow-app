import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wow_companion/core/di/injection.dart';
import 'package:wow_companion/features/builds/data/datasources/build_gap_analysis_datasource.dart';
import 'package:wow_companion/features/builds/data/datasources/character_media_datasource.dart';
import 'package:wow_companion/features/builds/domain/entities/build.dart';
import 'package:wow_companion/features/builds/domain/entities/build_gap_analysis.dart';
import 'package:wow_companion/features/builds/domain/repositories/builds_repository.dart';
import 'package:wow_companion/features/builds/presentation/cubit/build_detail_cubit.dart';
import 'package:wow_companion/features/builds/presentation/pages/build_detail_page.dart';
import 'package:wow_companion/core/theme/wow_theme.dart';
import 'package:wow_companion/l10n/generated/app_localizations.dart';

class _MockBuildsRepository extends Mock implements BuildsRepository {}

class _MockCharacterMediaDataSource extends Mock
    implements CharacterMediaDataSource {}

class _MockBuildGapAnalysisDataSource extends Mock
    implements BuildGapAnalysisDataSource {}

void main() {
  late _MockBuildsRepository buildsRepository;
  late _MockCharacterMediaDataSource mediaDataSource;
  late _MockBuildGapAnalysisDataSource gapDataSource;

  setUpAll(() {
    registerFallbackValue(<BuildSlot>[]);
  });

  setUp(() async {
    await sl.reset();
    buildsRepository = _MockBuildsRepository();
    mediaDataSource = _MockCharacterMediaDataSource();
    gapDataSource = _MockBuildGapAnalysisDataSource();

    sl.registerFactory<BuildDetailCubit>(
      () => BuildDetailCubit(buildsRepository, mediaDataSource, gapDataSource),
    );
  });

  tearDown(() async {
    await sl.reset();
  });

  Future<void> pumpPage(WidgetTester tester, String buildId) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
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
}
