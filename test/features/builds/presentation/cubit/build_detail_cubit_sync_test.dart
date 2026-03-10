import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wow_companion/core/error/exceptions.dart';
import 'package:wow_companion/core/l10n/locale_notifier.dart';
import 'package:wow_companion/features/builds/data/datasources/build_gap_analysis_datasource.dart';
import 'package:wow_companion/features/builds/data/datasources/character_media_datasource.dart';
import 'package:wow_companion/features/builds/domain/entities/build.dart';
import 'package:wow_companion/features/builds/domain/entities/build_gap_analysis.dart';
import 'package:wow_companion/features/builds/domain/repositories/builds_repository.dart';
import 'package:wow_companion/features/builds/presentation/cubit/build_detail_cubit.dart';
import 'package:wow_companion/features/builds/presentation/cubit/build_detail_state.dart';
import 'package:wow_companion/features/character/data/datasources/blizzard_character_datasource.dart';
import 'package:wow_companion/features/character/domain/entities/character.dart';
import 'package:wow_companion/features/items/domain/entities/item.dart';
import 'package:wow_companion/features/items/domain/usecases/get_item_detail.dart';

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
  late _MockBlizzardCharacterDatasource blizzardDataSource;
  late _MockGetItemDetail getItemDetail;
  late _TestLocaleNotifier localeNotifier;
  late BuildDetailCubit cubit;

  const gapAnalysis = BuildGapAnalysis(
    summary: BuildGapSummary(
      analysisMode: 'objective',
      targetProfile: 'build_target',
      checksTotal: 1,
      checksCompleted: 0,
      completionPct: 0,
      missingEnchants: 1,
      missingGems: 0,
      actionsCount: 1,
    ),
    actions: [],
  );

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

  setUp(() {
    buildsRepository = _MockBuildsRepository();
    mediaDataSource = _MockCharacterMediaDataSource();
    gapDataSource = _MockBuildGapAnalysisDataSource();
    blizzardDataSource = _MockBlizzardCharacterDatasource();
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

    cubit = BuildDetailCubit(
      buildsRepository,
      mediaDataSource,
      gapDataSource,
      blizzardDataSource,
      localeNotifier,
      getItemDetail,
    );

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
    ).thenAnswer((_) async => gapAnalysis);
  });

  tearDown(() async {
    await cubit.close();
  });

  Build linkedBuild({List<BuildSlot>? slots}) {
    return Build(
      id: 'b1',
      name: 'Test Build',
      characterRefKey: 'eu-sanguino-apastar',
      characterRefDisplay: 'Apastar - Sanguino',
      characterClass: 'Druid',
      characterSpec: 'Feral',
      characterAvatarUrl: 'https://cdn.example/avatar.jpg',
      createdAt: DateTime(2026, 3, 9),
      slots: slots ?? Build.emptySlots,
    );
  }

  CharacterBlizzardData snapshot({List<EquippedItem> equipment = const []}) {
    return CharacterBlizzardData(
      name: 'Apastar',
      realm: 'Sanguino',
      region: 'EU',
      level: 80,
      race: 'Night Elf',
      characterClass: 'Druid',
      equipment: equipment,
    );
  }

  test(
    'sincroniza objetos por slot y aplica espejo exacto de obtained',
    () async {
      final headSlot = BuildSlot(
        slot: WowSlot.head,
        item: const Item(id: 1001, name: 'Headpiece', quality: 'EPIC'),
        obtained: false,
        enchantment: const Item(
          id: 2234,
          name: 'Authority of Radiant Power',
          quality: 'COMMON',
        ),
        gems: const [Item(id: 192982, name: 'Quick Ruby', quality: 'COMMON')],
        enchantmentObtained: true,
        gemsObtained: [true],
      );
      final chestSlot = BuildSlot(
        slot: WowSlot.chest,
        item: const Item(id: 2002, name: 'Chestpiece', quality: 'EPIC'),
        obtained: true,
      );

      final build = linkedBuild(
        slots: [
          headSlot,
          chestSlot,
          ...Build.emptySlots.where(
            (slot) => slot.slot != WowSlot.head && slot.slot != WowSlot.chest,
          ),
        ],
      );

      when(() => buildsRepository.getBuilds()).thenAnswer((_) async => [build]);
      when(() => buildsRepository.saveBuild(any())).thenAnswer((_) async {});
      when(
        () => blizzardDataSource.getCharacter(
          region: any(named: 'region'),
          realm: any(named: 'realm'),
          name: any(named: 'name'),
          locale: any(named: 'locale'),
          force: any(named: 'force'),
        ),
      ).thenAnswer(
        (_) async => snapshot(
          equipment: const [
            EquippedItem(
              slot: 'HEAD',
              name: 'Headpiece',
              itemId: 1001,
              itemLevel: 626,
              quality: 'EPIC',
            ),
            EquippedItem(
              slot: 'CHEST',
              name: 'Other Chest',
              itemId: 9999,
              itemLevel: 626,
              quality: 'EPIC',
            ),
          ],
        ),
      );

      await cubit.loadBuild(build.id);
      final result = await cubit.syncCharacterProgress();

      final loaded = cubit.state as BuildDetailLoaded;
      final syncedHead = loaded.build.slots.firstWhere(
        (slot) => slot.slot == WowSlot.head,
      );
      final syncedChest = loaded.build.slots.firstWhere(
        (slot) => slot.slot == WowSlot.chest,
      );

      expect(result.slotsUpdated, 2);
      expect(result.itemsMatched, 1);
      expect(result.itemsTargeted, 2);

      expect(syncedHead.obtained, isTrue);
      expect(syncedChest.obtained, isFalse);

      expect(syncedHead.enchantment?.id, 2234);
      expect(syncedHead.gems.length, 1);
      expect(syncedHead.enchantmentObtained, isTrue);
      expect(syncedHead.gemsObtained, [true]);
    },
  );

  test(
    'usa fallback por nombre cuando no hay ids en item objetivo/equipo',
    () async {
      final ringSlot = BuildSlot(
        slot: WowSlot.finger1,
        item: const Item(
          id: 0,
          name: 'Ashen Band',
          canonicalNameEn: 'Ashen Band',
          quality: 'EPIC',
        ),
        obtained: false,
      );

      final build = linkedBuild(
        slots: [
          ringSlot,
          ...Build.emptySlots.where((slot) => slot.slot != WowSlot.finger1),
        ],
      );

      when(() => buildsRepository.getBuilds()).thenAnswer((_) async => [build]);
      when(() => buildsRepository.saveBuild(any())).thenAnswer((_) async {});
      when(
        () => blizzardDataSource.getCharacter(
          region: any(named: 'region'),
          realm: any(named: 'realm'),
          name: any(named: 'name'),
          locale: any(named: 'locale'),
          force: any(named: 'force'),
        ),
      ).thenAnswer(
        (_) async => snapshot(
          equipment: const [
            EquippedItem(
              slot: 'FINGER_1',
              name: 'Ashen Band',
              itemLevel: 626,
              quality: 'EPIC',
            ),
          ],
        ),
      );

      await cubit.loadBuild(build.id);
      final result = await cubit.syncCharacterProgress();

      final loaded = cubit.state as BuildDetailLoaded;
      final syncedRing = loaded.build.slots.firstWhere(
        (slot) => slot.slot == WowSlot.finger1,
      );

      expect(result.slotsUpdated, 1);
      expect(result.itemsMatched, 1);
      expect(result.itemsTargeted, 1);
      expect(syncedRing.obtained, isTrue);
    },
  );

  test('si slot no tiene item en build, obtained queda false', () async {
    final build = linkedBuild(
      slots: [
        const BuildSlot(slot: WowSlot.head, obtained: true),
        ...Build.emptySlots.where((slot) => slot.slot != WowSlot.head),
      ],
    );

    when(() => buildsRepository.getBuilds()).thenAnswer((_) async => [build]);
    when(() => buildsRepository.saveBuild(any())).thenAnswer((_) async {});
    when(
      () => blizzardDataSource.getCharacter(
        region: any(named: 'region'),
        realm: any(named: 'realm'),
        name: any(named: 'name'),
        locale: any(named: 'locale'),
        force: any(named: 'force'),
      ),
    ).thenAnswer(
      (_) async => snapshot(
        equipment: const [
          EquippedItem(
            slot: 'HEAD',
            name: 'Headpiece',
            itemId: 1001,
            itemLevel: 626,
            quality: 'EPIC',
          ),
        ],
      ),
    );

    await cubit.loadBuild(build.id);
    final result = await cubit.syncCharacterProgress();

    final loaded = cubit.state as BuildDetailLoaded;
    final syncedHead = loaded.build.slots.firstWhere(
      (slot) => slot.slot == WowSlot.head,
    );

    expect(result.slotsUpdated, 1);
    expect(result.itemsMatched, 0);
    expect(result.itemsTargeted, 0);
    expect(syncedHead.obtained, isFalse);
  });

  test('ignora slots no mapeables sin romper el flujo', () async {
    final build = linkedBuild();
    when(() => buildsRepository.getBuilds()).thenAnswer((_) async => [build]);
    when(() => buildsRepository.saveBuild(any())).thenAnswer((_) async {});
    when(
      () => blizzardDataSource.getCharacter(
        region: any(named: 'region'),
        realm: any(named: 'realm'),
        name: any(named: 'name'),
        locale: any(named: 'locale'),
        force: any(named: 'force'),
      ),
    ).thenAnswer(
      (_) async => snapshot(
        equipment: const [
          EquippedItem(
            slot: 'SHIRT',
            name: 'Decorative Shirt',
            itemId: 7777,
            itemLevel: 1,
            quality: 'COMMON',
          ),
        ],
      ),
    );

    await cubit.loadBuild(build.id);
    final result = await cubit.syncCharacterProgress();

    expect(result.slotsUpdated, 0);
    expect(result.itemsMatched, 0);
    expect(result.itemsTargeted, 0);
  });

  test('no guarda cambios si no existe characterRefKey valido', () async {
    final genericBuild = Build(
      id: 'generic',
      name: 'Generic',
      createdAt: DateTime(2026, 3, 9),
      slots: Build.emptySlots,
    );
    when(
      () => buildsRepository.getBuilds(),
    ).thenAnswer((_) async => [genericBuild]);

    await cubit.loadBuild(genericBuild.id);

    expect(
      () => cubit.syncCharacterProgress(),
      throwsA(isA<ServerException>()),
    );
    verifyNever(() => buildsRepository.saveBuild(any()));
  });

  test('si falla datasource no persiste build y reexpone error', () async {
    final build = linkedBuild();
    when(() => buildsRepository.getBuilds()).thenAnswer((_) async => [build]);
    when(
      () => blizzardDataSource.getCharacter(
        region: any(named: 'region'),
        realm: any(named: 'realm'),
        name: any(named: 'name'),
        locale: any(named: 'locale'),
        force: any(named: 'force'),
      ),
    ).thenThrow(const NetworkException());

    await cubit.loadBuild(build.id);

    expect(
      () => cubit.syncCharacterProgress(),
      throwsA(isA<NetworkException>()),
    );
    verifyNever(() => buildsRepository.saveBuild(any()));
  });

  test('rehidrata nombres de objetos cuando cambia el idioma activo', () async {
    final headSlot = BuildSlot(
      slot: WowSlot.head,
      item: const Item(id: 1001, name: 'Radiant Authority', quality: 'EPIC'),
    );
    final build = linkedBuild(
      slots: [
        headSlot,
        ...Build.emptySlots.where((slot) => slot.slot != WowSlot.head),
      ],
    );

    when(() => buildsRepository.getBuilds()).thenAnswer((_) async => [build]);
    when(() => buildsRepository.saveBuild(any())).thenAnswer((_) async {});
    when(() => getItemDetail(1001, locale: 'en_GB')).thenAnswer(
      (_) async => const Right(
        Item(
          id: 1001,
          name: 'Radiant Authority',
          quality: 'EPIC',
          canonicalNameEn: 'Radiant Authority',
        ),
      ),
    );
    when(() => getItemDetail(1001, locale: 'es_ES')).thenAnswer(
      (_) async => const Right(
        Item(
          id: 1001,
          name: 'Autoridad radiante',
          quality: 'EPIC',
          localizedName: 'Autoridad radiante',
          canonicalNameEn: 'Radiant Authority',
        ),
      ),
    );

    await localeNotifier.setLocale(const Locale('en'));
    await cubit.loadBuild(build.id);

    var loaded = cubit.state as BuildDetailLoaded;
    var localizedItem = loaded.build.slots
        .firstWhere((slot) => slot.slot == WowSlot.head)
        .item!;
    expect(localizedItem.name, 'Radiant Authority');
    expect(localizedItem.localizedName, isNull);

    await localeNotifier.setLocale(const Locale('es'));
    await Future<void>.delayed(const Duration(milliseconds: 1));

    loaded = cubit.state as BuildDetailLoaded;
    localizedItem = loaded.build.slots
        .firstWhere((slot) => slot.slot == WowSlot.head)
        .item!;
    expect(localizedItem.canonicalNameEn, 'Radiant Authority');
    expect(localizedItem.localizedName, 'Autoridad radiante');
  });

  test('lanza refresh de gap-analysis con force=true tras sync', () async {
    final build = linkedBuild();
    when(() => buildsRepository.getBuilds()).thenAnswer((_) async => [build]);
    when(() => buildsRepository.saveBuild(any())).thenAnswer((_) async {});
    when(
      () => blizzardDataSource.getCharacter(
        region: any(named: 'region'),
        realm: any(named: 'realm'),
        name: any(named: 'name'),
        locale: any(named: 'locale'),
        force: any(named: 'force'),
      ),
    ).thenAnswer((_) async => snapshot());

    await cubit.loadBuild(build.id);
    await cubit.syncCharacterProgress();

    verify(
      () => gapDataSource.getGapAnalysis(
        region: 'eu',
        realm: 'sanguino',
        name: 'apastar',
        className: 'Druid',
        specName: 'Feral',
        buildSlots: any(named: 'buildSlots'),
        force: true,
      ),
    ).called(1);
  });
}
