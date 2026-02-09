import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wow_companion/core/error/failures.dart';
import 'package:wow_companion/features/character/domain/entities/character.dart';
import 'package:wow_companion/features/character/domain/usecases/get_character.dart';
import 'package:wow_companion/features/character/presentation/cubit/character_cubit.dart';

// Creamos mocks de los use cases
class MockGetCharacter extends Mock implements GetCharacter {}

class MockSearchCharacters extends Mock implements SearchCharacters {}

void main() {
  // ============================
  // CharacterCubit tests
  // ============================
  group('CharacterCubit', () {
    late CharacterCubit cubit;
    late MockGetCharacter mockGetCharacter;

    // Datos de prueba
    const tCharacter = Character(
      name: 'Testpala',
      realm: 'Sargeras',
      region: 'EU',
      level: 80,
      race: 'Human',
      characterClass: 'Paladin',
      specialization: 'Retribution',
      equippedItemLevel: 624,
    );

    setUp(() {
      mockGetCharacter = MockGetCharacter();
      cubit = CharacterCubit(mockGetCharacter);
    });

    tearDown(() => cubit.close());

    test('initial state is CharacterInitial', () {
      expect(cubit.state, const CharacterInitial());
    });

    blocTest<CharacterCubit, CharacterState>(
      'emits [Loading, Loaded] when fetch succeeds',
      build: () {
        when(
          () => mockGetCharacter(
            region: any(named: 'region'),
            realm: any(named: 'realm'),
            name: any(named: 'name'),
          ),
        ).thenAnswer((_) async => const Right(tCharacter));
        return cubit;
      },
      act: (c) =>
          c.fetchCharacter(region: 'eu', realm: 'sargeras', name: 'testpala'),
      expect: () => [
        const CharacterLoading(),
        const CharacterLoaded(tCharacter),
      ],
    );

    blocTest<CharacterCubit, CharacterState>(
      'emits [Loading, Error] when fetch fails with NotFound',
      build: () {
        when(
          () => mockGetCharacter(
            region: any(named: 'region'),
            realm: any(named: 'realm'),
            name: any(named: 'name'),
          ),
        ).thenAnswer((_) async => const Left(NotFoundFailure()));
        return cubit;
      },
      act: (c) =>
          c.fetchCharacter(region: 'eu', realm: 'sargeras', name: 'notfound'),
      expect: () => [
        const CharacterLoading(),
        const CharacterError('Resource not found'),
      ],
    );

    blocTest<CharacterCubit, CharacterState>(
      'emits [Loading, Error] when fetch fails with NetworkFailure',
      build: () {
        when(
          () => mockGetCharacter(
            region: any(named: 'region'),
            realm: any(named: 'realm'),
            name: any(named: 'name'),
          ),
        ).thenAnswer((_) async => const Left(NetworkFailure()));
        return cubit;
      },
      act: (c) =>
          c.fetchCharacter(region: 'eu', realm: 'sargeras', name: 'test'),
      expect: () => [
        const CharacterLoading(),
        const CharacterError('No internet connection'),
      ],
    );

    blocTest<CharacterCubit, CharacterState>(
      'reset returns to initial state',
      build: () {
        when(
          () => mockGetCharacter(
            region: any(named: 'region'),
            realm: any(named: 'realm'),
            name: any(named: 'name'),
          ),
        ).thenAnswer((_) async => const Right(tCharacter));
        return cubit;
      },
      act: (c) async {
        await c.fetchCharacter(
          region: 'eu',
          realm: 'sargeras',
          name: 'testpala',
        );
        c.reset();
      },
      expect: () => [
        const CharacterLoading(),
        const CharacterLoaded(tCharacter),
        const CharacterInitial(),
      ],
    );
  });

  // ============================
  // CharacterSearchCubit tests
  // ============================
  group('CharacterSearchCubit', () {
    late CharacterSearchCubit cubit;
    late MockSearchCharacters mockSearch;

    const tResults = [
      Character(
        name: 'Testpala',
        realm: 'Sargeras',
        region: 'EU',
        level: 80,
        race: 'Human',
        characterClass: 'Paladin',
      ),
    ];

    setUp(() {
      mockSearch = MockSearchCharacters();
      cubit = CharacterSearchCubit(mockSearch);
    });

    tearDown(() => cubit.close());

    test('initial state is SearchInitial', () {
      expect(cubit.state, const SearchInitial());
    });

    blocTest<CharacterSearchCubit, CharacterSearchState>(
      'emits [Loading, Loaded] when search succeeds',
      build: () {
        when(
          () => mockSearch(
            query: any(named: 'query'),
            region: any(named: 'region'),
          ),
        ).thenAnswer((_) async => const Right(tResults));
        return cubit;
      },
      act: (c) => c.search(query: 'test'),
      expect: () => [const SearchLoading(), const SearchLoaded(tResults)],
    );

    blocTest<CharacterSearchCubit, CharacterSearchState>(
      'does not search when query is less than 2 characters',
      build: () => cubit,
      act: (c) => c.search(query: 'a'),
      expect: () => [const SearchInitial()],
      verify: (_) {
        verifyNever(
          () => mockSearch(
            query: any(named: 'query'),
            region: any(named: 'region'),
          ),
        );
      },
    );

    blocTest<CharacterSearchCubit, CharacterSearchState>(
      'emits [Loading, Error] when search fails',
      build: () {
        when(
          () => mockSearch(
            query: any(named: 'query'),
            region: any(named: 'region'),
          ),
        ).thenAnswer((_) async => const Left(ServerFailure()));
        return cubit;
      },
      act: (c) => c.search(query: 'test'),
      expect: () => [
        const SearchLoading(),
        const SearchError('Server error occurred'),
      ],
    );

    blocTest<CharacterSearchCubit, CharacterSearchState>(
      'clear returns to initial state',
      build: () => cubit,
      act: (c) => c.clear(),
      expect: () => [const SearchInitial()],
    );
  });
}
