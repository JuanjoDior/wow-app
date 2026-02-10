import 'package:dartz/dartz.dart';
import 'package:wow_companion/core/cache/memory_cache.dart';
import 'package:wow_companion/core/error/exceptions.dart';
import 'package:wow_companion/core/error/failures.dart';
import 'package:wow_companion/features/character/data/datasources/raiderio_datasource.dart';
import 'package:wow_companion/features/character/domain/entities/character.dart';
import 'package:wow_companion/features/character/domain/repositories/character_repository.dart';

class CharacterRepositoryImpl implements CharacterRepository {
  final RaiderIoDataSource remoteDataSource;
  final MemoryCache<Character> cache;

  CharacterRepositoryImpl({
    required this.remoteDataSource,
    required this.cache,
  });

  /// Build cache key from search params
  String _cacheKey(String region, String realm, String name) =>
      '${region.toLowerCase()}-${realm.toLowerCase()}-${name.toLowerCase()}';

  @override
  Future<Either<Failure, Character>> getCharacter({
    required String region,
    required String realm,
    required String name,
  }) async {
    // 1. Check cache first
    final key = _cacheKey(region, realm, name);
    final cached = cache.get(key);
    if (cached != null) {
      return Right(cached);
    }

    // 2. Fetch from API
    try {
      final character = await remoteDataSource.getCharacter(
        region: region,
        realm: realm,
        name: name,
      );

      // 3. Store in cache
      cache.set(key, character);

      return Right(character);
    } on RateLimitException {
      return const Left(RateLimitFailure());
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
}
