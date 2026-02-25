import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wow_companion/core/cache/memory_cache.dart';
import 'package:wow_companion/core/error/exceptions.dart';
import 'package:wow_companion/features/character/data/datasources/blizzard_character_datasource.dart';
import 'package:wow_companion/features/character/data/datasources/raiderio_datasource.dart';
import 'package:wow_companion/features/character/data/repositories/character_repository_impl.dart';
import 'package:wow_companion/features/character/domain/entities/character.dart';

class MockBlizzardCharacterDatasource extends Mock
    implements BlizzardCharacterDatasource {}

class MockRaiderIoDataSource extends Mock implements RaiderIoDataSource {}

void main() {
  group('CharacterRepositoryImpl equipment icon merge', () {
    late MockBlizzardCharacterDatasource mockBlizzard;
    late MockRaiderIoDataSource mockRaider;
    late CharacterRepositoryImpl repository;

    setUp(() {
      mockBlizzard = MockBlizzardCharacterDatasource();
      mockRaider = MockRaiderIoDataSource();
      repository = CharacterRepositoryImpl(
        blizzardDataSource: mockBlizzard,
        raiderIoDataSource: mockRaider,
        cache: MemoryCache<Character>(),
      );

      when(
        () => mockRaider.getCurrentLiveRaid(region: any(named: 'region')),
      ).thenAnswer((_) async => null);
    });

    test('keeps Blizzard icon when already present', () async {
      final blizzard = _blizzardData(
        item: const EquippedItem(
          slot: 'HEAD',
          name: 'Blizzard Helm',
          itemLevel: 626,
          quality: 'EPIC',
          itemId: 1001,
          iconUrl: 'https://img.example/blizzard-head.jpg',
        ),
      );
      final raider = _raiderCharacter(
        equipment: const [
          EquippedItem(
            slot: 'HEAD',
            name: 'Raider Helm',
            itemLevel: 626,
            quality: 'EPIC',
            itemId: 1001,
            iconUrl: 'https://img.example/raider-head.jpg',
          ),
        ],
      );

      _stubSources(
        mockBlizzard: mockBlizzard,
        mockRaider: mockRaider,
        blizzard: blizzard,
        raider: raider,
      );
      final result = await repository.getCharacter(
        region: 'eu',
        realm: 'sanguino',
        name: 'apastar',
      );

      result.fold(
        (failure) => fail('Expected success but got failure: $failure'),
        (character) {
          expect(character.equipment, hasLength(1));
          expect(
            character.equipment.first.iconUrl,
            'https://img.example/blizzard-head.jpg',
          );
        },
      );
    });

    test(
      'uses Raider icon when Blizzard icon is null and itemId matches',
      () async {
        final blizzard = _blizzardData(
          item: const EquippedItem(
            slot: 'HEAD',
            name: 'Blizzard Helm',
            itemLevel: 626,
            quality: 'EPIC',
            itemId: 1001,
          ),
        );
        final raider = _raiderCharacter(
          equipment: const [
            EquippedItem(
              slot: 'HEAD',
              name: 'Raider Helm',
              itemLevel: 626,
              quality: 'EPIC',
              itemId: 1001,
              iconUrl: 'https://img.example/raider-head.jpg',
            ),
          ],
        );

        _stubSources(
          mockBlizzard: mockBlizzard,
          mockRaider: mockRaider,
          blizzard: blizzard,
          raider: raider,
        );
        final result = await repository.getCharacter(
          region: 'eu',
          realm: 'sanguino',
          name: 'apastar',
        );

        result.fold(
          (failure) => fail('Expected success but got failure: $failure'),
          (character) {
            expect(character.equipment, hasLength(1));
            expect(
              character.equipment.first.iconUrl,
              'https://img.example/raider-head.jpg',
            );
          },
        );
      },
    );

    test('falls back by slot when no itemId match exists', () async {
      final blizzard = _blizzardData(
        item: const EquippedItem(
          slot: 'HEAD',
          name: 'Blizzard Helm',
          itemLevel: 626,
          quality: 'EPIC',
          itemId: 1001,
        ),
      );
      final raider = _raiderCharacter(
        equipment: const [
          EquippedItem(
            slot: 'HEAD',
            name: 'Raider Helm Different Id',
            itemLevel: 626,
            quality: 'EPIC',
            itemId: 9999,
            iconUrl: 'https://img.example/raider-slot.jpg',
          ),
        ],
      );

      _stubSources(
        mockBlizzard: mockBlizzard,
        mockRaider: mockRaider,
        blizzard: blizzard,
        raider: raider,
      );
      final result = await repository.getCharacter(
        region: 'eu',
        realm: 'sanguino',
        name: 'apastar',
      );

      result.fold(
        (failure) => fail('Expected success but got failure: $failure'),
        (character) {
          expect(character.equipment, hasLength(1));
          expect(
            character.equipment.first.iconUrl,
            'https://img.example/raider-slot.jpg',
          );
        },
      );
    });

    test('keeps null icon when no fallback icon exists', () async {
      final blizzard = _blizzardData(
        item: const EquippedItem(
          slot: 'HEAD',
          name: 'Blizzard Helm',
          itemLevel: 626,
          quality: 'EPIC',
          itemId: 1001,
        ),
      );
      final raider = _raiderCharacter(equipment: const []);

      _stubSources(
        mockBlizzard: mockBlizzard,
        mockRaider: mockRaider,
        blizzard: blizzard,
        raider: raider,
      );
      final result = await repository.getCharacter(
        region: 'eu',
        realm: 'sanguino',
        name: 'apastar',
      );

      result.fold(
        (failure) => fail('Expected success but got failure: $failure'),
        (character) {
          expect(character.equipment, hasLength(1));
          expect(character.equipment.first.iconUrl, isNull);
        },
      );
    });

    test('uses thumbnailUrl when avatarUrl is null', () async {
      final blizzard = _blizzardData(
        item: const EquippedItem(
          slot: 'HEAD',
          name: 'Blizzard Helm',
          itemLevel: 626,
          quality: 'EPIC',
          itemId: 1001,
        ),
        thumbnailUrl: 'https://img.example/blizzard-thumb.jpg',
      );
      final raider = _raiderCharacter(equipment: const []);

      _stubSources(
        mockBlizzard: mockBlizzard,
        mockRaider: mockRaider,
        blizzard: blizzard,
        raider: raider,
      );
      final result = await repository.getCharacter(
        region: 'eu',
        realm: 'sanguino',
        name: 'apastar',
      );

      result.fold(
        (failure) => fail('Expected success but got failure: $failure'),
        (character) {
          expect(character.avatarUrl, isNull);
          expect(
            character.thumbnailUrl,
            'https://img.example/blizzard-thumb.jpg',
          );
          expect(
            character.bestAvatarUrl,
            'https://img.example/blizzard-thumb.jpg',
          );
        },
      );
    });

    test(
      'fills progression defaults when Raider data is unavailable',
      () async {
        final blizzard = _blizzardData(
          item: const EquippedItem(
            slot: 'HEAD',
            name: 'Blizzard Helm',
            itemLevel: 626,
            quality: 'EPIC',
            itemId: 1001,
          ),
        );

        when(
          () => mockBlizzard.getCharacter(
            region: any(named: 'region'),
            realm: any(named: 'realm'),
            name: any(named: 'name'),
          ),
        ).thenAnswer((_) async => blizzard);

        when(
          () => mockRaider.getCharacter(
            region: any(named: 'region'),
            realm: any(named: 'realm'),
            name: any(named: 'name'),
          ),
        ).thenAnswer((_) async => throw const NotFoundException());

        final result = await repository.getCharacter(
          region: 'eu',
          realm: 'sanguino',
          name: 'apastar',
        );

        result.fold(
          (failure) => fail('Expected success but got failure: $failure'),
          (character) {
            expect(character.mythicPlusScore, 0);
            expect(
              character.mythicPlusProfile,
              const MythicPlusProfile(scoreAll: 0),
            );
            expect(character.raidProgression, '0/0');
            expect(character.raidProgressionDetails, isEmpty);
          },
        );
      },
    );

    test(
      'uses current live raid metadata when Raider character has no progression',
      () async {
        final blizzard = _blizzardData(
          item: const EquippedItem(
            slot: 'HEAD',
            name: 'Blizzard Helm',
            itemLevel: 626,
            quality: 'EPIC',
            itemId: 1001,
          ),
        );
        final raider = _raiderCharacter(equipment: const []);

        _stubSources(
          mockBlizzard: mockBlizzard,
          mockRaider: mockRaider,
          blizzard: blizzard,
          raider: raider,
          currentRaid: const CurrentRaidInfo(
            slug: 'liberation-of-undermine',
            name: 'Liberation of Undermine',
            totalBosses: 8,
          ),
        );

        final result = await repository.getCharacter(
          region: 'eu',
          realm: 'sanguino',
          name: 'apastar',
        );

        result.fold(
          (failure) => fail('Expected success but got failure: $failure'),
          (character) {
            expect(character.raidProgression, '0/8');
            expect(character.raidProgressionDetails, hasLength(1));
            expect(
              character.raidProgressionDetails.first.slug,
              'liberation-of-undermine',
            );
            expect(character.raidProgressionDetails.first.totalBosses, 8);
            expect(character.raidProgressionDetails.first.normalKilled, 0);
            expect(character.raidProgressionDetails.first.heroicKilled, 0);
            expect(character.raidProgressionDetails.first.mythicKilled, 0);
          },
        );
      },
    );

    test(
      'keeps only current live raid when Raider returns historical raids',
      () async {
        final blizzard = _blizzardData(
          item: const EquippedItem(
            slot: 'HEAD',
            name: 'Blizzard Helm',
            itemLevel: 626,
            quality: 'EPIC',
            itemId: 1001,
          ),
        );
        final raider = _raiderCharacter(
          equipment: const [],
          raidProgressionDetails: const [
            RaidProgress(
              raidName: 'Nerub-ar Palace',
              slug: 'nerubar-palace',
              summary: '8/8 H',
              totalBosses: 8,
              normalKilled: 8,
              heroicKilled: 8,
              mythicKilled: 0,
            ),
            RaidProgress(
              raidName: 'Liberation of Undermine',
              slug: 'liberation-of-undermine',
              summary: '2/8 N',
              totalBosses: 8,
              normalKilled: 2,
              heroicKilled: 0,
              mythicKilled: 0,
            ),
          ],
        );

        _stubSources(
          mockBlizzard: mockBlizzard,
          mockRaider: mockRaider,
          blizzard: blizzard,
          raider: raider,
          currentRaid: const CurrentRaidInfo(
            slug: 'liberation-of-undermine',
            name: 'Liberation of Undermine',
            totalBosses: 8,
          ),
        );

        final result = await repository.getCharacter(
          region: 'eu',
          realm: 'sanguino',
          name: 'apastar',
        );

        result.fold(
          (failure) => fail('Expected success but got failure: $failure'),
          (character) {
            expect(character.raidProgressionDetails, hasLength(1));
            expect(
              character.raidProgressionDetails.first.slug,
              'liberation-of-undermine',
            );
            expect(character.raidProgressionDetails.first.summary, '2/8 N');
            expect(character.raidProgression, '2/8 N');
          },
        );
      },
    );
  });
}

void _stubSources({
  required MockBlizzardCharacterDatasource mockBlizzard,
  required MockRaiderIoDataSource mockRaider,
  required CharacterBlizzardData blizzard,
  required Character raider,
  CurrentRaidInfo? currentRaid,
}) {
  when(
    () => mockBlizzard.getCharacter(
      region: any(named: 'region'),
      realm: any(named: 'realm'),
      name: any(named: 'name'),
    ),
  ).thenAnswer((_) async => blizzard);

  when(
    () => mockRaider.getCharacter(
      region: any(named: 'region'),
      realm: any(named: 'realm'),
      name: any(named: 'name'),
    ),
  ).thenAnswer((_) async => raider);

  when(
    () => mockRaider.getCurrentLiveRaid(region: any(named: 'region')),
  ).thenAnswer((_) async => currentRaid);
}

CharacterBlizzardData _blizzardData({
  required EquippedItem item,
  String? avatarUrl,
  String? thumbnailUrl,
}) {
  return CharacterBlizzardData(
    name: 'Apastar',
    realm: 'Sanguino',
    region: 'EU',
    level: 80,
    race: 'Human',
    characterClass: 'Paladin',
    avatarUrl: avatarUrl,
    thumbnailUrl: thumbnailUrl,
    equipment: [item],
  );
}

Character _raiderCharacter({
  required List<EquippedItem> equipment,
  String? avatarUrl,
  String? thumbnailUrl,
  List<RaidProgress> raidProgressionDetails = const [],
}) {
  return Character(
    name: 'Apastar',
    realm: 'Sanguino',
    region: 'EU',
    level: 80,
    race: 'Human',
    characterClass: 'Paladin',
    avatarUrl: avatarUrl,
    thumbnailUrl: thumbnailUrl,
    equipment: equipment,
    mythicPlusScore: 0,
    raidProgressionDetails: raidProgressionDetails,
  );
}
