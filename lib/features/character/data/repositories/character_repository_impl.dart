import 'package:dartz/dartz.dart';
import 'package:wow_companion/core/error/exceptions.dart';
import 'package:wow_companion/core/error/failures.dart';
import 'package:wow_companion/features/character/data/datasources/raiderio_datasource.dart';
import 'package:wow_companion/features/character/domain/entities/character.dart';
import 'package:wow_companion/features/character/domain/repositories/character_repository.dart';

class CharacterRepositoryImpl implements CharacterRepository {
  final RaiderIoDataSource remoteDataSource;

  CharacterRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, Character>> getCharacter({
    required String region,
    required String realm,
    required String name,
  }) async {
    try {
      final character = await remoteDataSource.getCharacter(
        region: region,
        realm: realm,
        name: name,
      );
      return Right(character);
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(message: e.message));
    } on NetworkException {
      return const Left(NetworkFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Character>>> searchCharacters({
    required String query,
    String region = 'eu',
  }) async {
    // Raider.IO no tiene endpoint de búsqueda,
    // así que por ahora tratamos la query como realm/name directo.
    // En el futuro conectaremos Battle.net search o Raider.IO search.
    return const Right([]);
  }
}
