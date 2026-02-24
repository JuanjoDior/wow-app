import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wow_companion/core/cache/memory_cache.dart';
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
  });
}

void _stubSources({
  required MockBlizzardCharacterDatasource mockBlizzard,
  required MockRaiderIoDataSource mockRaider,
  required CharacterBlizzardData blizzard,
  required Character raider,
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
}

CharacterBlizzardData _blizzardData({required EquippedItem item}) {
  return CharacterBlizzardData(
    name: 'Apastar',
    realm: 'Sanguino',
    region: 'EU',
    level: 80,
    race: 'Human',
    characterClass: 'Paladin',
    equipment: [item],
  );
}

Character _raiderCharacter({required List<EquippedItem> equipment}) {
  return Character(
    name: 'Apastar',
    realm: 'Sanguino',
    region: 'EU',
    level: 80,
    race: 'Human',
    characterClass: 'Paladin',
    equipment: equipment,
    mythicPlusScore: 0,
  );
}
