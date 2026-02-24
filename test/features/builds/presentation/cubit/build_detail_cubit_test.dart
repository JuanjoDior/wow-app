import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wow_companion/features/builds/data/datasources/character_media_datasource.dart';
import 'package:wow_companion/features/builds/domain/entities/build.dart';
import 'package:wow_companion/features/builds/domain/entities/spec_recommendation.dart';
import 'package:wow_companion/features/builds/domain/repositories/builds_repository.dart';
import 'package:wow_companion/features/builds/domain/repositories/spec_recommendations_repository.dart';
import 'package:wow_companion/features/builds/presentation/cubit/build_detail_cubit.dart';
import 'package:wow_companion/features/builds/presentation/cubit/build_detail_state.dart';
import 'package:wow_companion/features/items/domain/entities/item.dart';

class _MockBuildsRepository extends Mock implements BuildsRepository {}

class _MockCharacterMediaDataSource extends Mock
    implements CharacterMediaDataSource {}

class _MockSpecRecommendationsRepository extends Mock
    implements SpecRecommendationsRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      Build(
        id: 'fallback',
        name: 'fallback',
        createdAt: DateTime(2026, 2, 24),
        slots: Build.emptySlots,
      ),
    );
  });

  group('BuildDetailCubit recommendations', () {
    late _MockBuildsRepository buildsRepository;
    late _MockCharacterMediaDataSource mediaDataSource;
    late _MockSpecRecommendationsRepository recsRepository;
    late BuildDetailCubit cubit;

    final baseBuild = Build(
      id: '1',
      name: 'Feral Build',
      characterClass: 'Druid',
      characterSpec: 'Feral',
      createdAt: DateTime(2026, 2, 24),
      slots: Build.emptySlots,
    );

    const recommendation = SpecRecommendation(
      className: 'druid',
      specName: 'feral',
      patch: '11.2 / Pre-Patch Midnight',
      flask: ItemSuggestion(name: 'Flask of Alchemical Chaos'),
      potion: ItemSuggestion(name: 'Tempered Potion'),
      food: ItemSuggestion(name: "Beledar's Bounty"),
    );

    setUp(() {
      buildsRepository = _MockBuildsRepository();
      mediaDataSource = _MockCharacterMediaDataSource();
      recsRepository = _MockSpecRecommendationsRepository();
      cubit = BuildDetailCubit(
        buildsRepository,
        mediaDataSource,
        recsRepository,
      );

      when(
        () => buildsRepository.getBuilds(),
      ).thenAnswer((_) async => [baseBuild]);
      when(() => buildsRepository.saveBuild(any())).thenAnswer((_) async {});
      when(
        () => recsRepository.getRecommendations(
          className: any(named: 'className'),
          specName: any(named: 'specName'),
          patch: any(named: 'patch'),
        ),
      ).thenAnswer((_) async => recommendation);
    });

    tearDown(() => cubit.close());

    test(
      'prefills consumables when recommendation exists and guide is empty',
      () async {
        await cubit.loadBuild('1');
        await Future<void>.delayed(const Duration(milliseconds: 30));

        final state = cubit.state as BuildDetailLoaded;
        expect(state.recommendationLookupDone, true);
        expect(
          state.build.guide.consumables.flask?.name,
          'Flask of Alchemical Chaos',
        );
        expect(state.build.guide.consumables.potion?.name, 'Tempered Potion');
        expect(state.build.guide.consumables.food?.name, "Beledar's Bounty");

        final saved = verify(
          () => buildsRepository.saveBuild(captureAny()),
        ).captured;
        expect(saved, hasLength(1));
        final savedBuild = saved.single as Build;
        expect(
          savedBuild.guide.consumables.flask?.name,
          'Flask of Alchemical Chaos',
        );
      },
    );

    test('does not overwrite existing consumables in guide', () async {
      final withConsumables = baseBuild.copyWith(
        guide: const BuildGuide(
          consumables: BuildConsumables(
            flask: Item(id: 1, name: 'Custom Flask', quality: 'EPIC'),
          ),
        ),
      );
      when(
        () => buildsRepository.getBuilds(),
      ).thenAnswer((_) async => [withConsumables]);

      await cubit.loadBuild('1');
      await Future<void>.delayed(const Duration(milliseconds: 30));

      final state = cubit.state as BuildDetailLoaded;
      expect(state.recommendationLookupDone, true);
      expect(state.build.guide.consumables.flask?.name, 'Custom Flask');
      verifyNever(() => buildsRepository.saveBuild(any()));
    });

    test(
      'marks lookup done and does not prefill when recommendation is null',
      () async {
        when(
          () => recsRepository.getRecommendations(
            className: any(named: 'className'),
            specName: any(named: 'specName'),
            patch: any(named: 'patch'),
          ),
        ).thenAnswer((_) async => null);

        await cubit.loadBuild('1');
        await Future<void>.delayed(const Duration(milliseconds: 30));

        final state = cubit.state as BuildDetailLoaded;
        expect(state.recommendationLookupDone, true);
        expect(state.recommendation, isNull);
        expect(state.build.guide.consumables.isEmpty, true);
        verifyNever(() => buildsRepository.saveBuild(any()));
      },
    );
  });
}
