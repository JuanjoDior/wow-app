import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wow_companion/core/error/failures.dart';
import 'package:wow_companion/features/character/domain/entities/character.dart';
import 'package:wow_companion/features/character/domain/usecases/get_character.dart';
import 'package:wow_companion/features/character/presentation/cubit/character_cubit.dart';

class MockGetCharacter extends Mock implements GetCharacter {}

void main() {
  group('CharacterCubit', () {
    late CharacterCubit cubit;
    late MockGetCharacter mockGetCharacter;

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
        const CharacterError(
          'Character not found.',
          suggestion: 'Check the region, realm, and character name.',
        ),
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
        const CharacterError(
          'Could not connect to the internet.',
          suggestion: 'Check your connection and try again.',
        ),
      ],
    );

    blocTest<CharacterCubit, CharacterState>(
      'emits [Loading, Error] when fetch fails with RateLimitFailure',
      build: () {
        when(
          () => mockGetCharacter(
            region: any(named: 'region'),
            realm: any(named: 'realm'),
            name: any(named: 'name'),
          ),
        ).thenAnswer((_) async => const Left(RateLimitFailure()));
        return cubit;
      },
      act: (c) =>
          c.fetchCharacter(region: 'eu', realm: 'sargeras', name: 'test'),
      expect: () => [
        const CharacterLoading(),
        const CharacterError(
          'Too many requests.',
          suggestion: 'Wait a moment and try again.',
        ),
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
}
