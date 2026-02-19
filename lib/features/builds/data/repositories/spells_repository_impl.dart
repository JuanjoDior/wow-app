import 'package:dartz/dartz.dart';
import 'package:wow_companion/core/error/exceptions.dart';
import 'package:wow_companion/core/error/failures.dart';
import 'package:wow_companion/features/builds/data/datasources/spells_datasource.dart';
import 'package:wow_companion/features/builds/domain/entities/build.dart';
import 'package:wow_companion/features/builds/domain/repositories/spells_repository.dart';

class SpellsRepositoryImpl implements SpellsRepository {
  final SpellsDataSource remoteDataSource;

  SpellsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<WowSpell>>> searchSpells(
    String name, {
    String locale = 'en_GB',
  }) async {
    try {
      final spells = await remoteDataSource.searchSpells(
        name,
        locale: locale,
      );
      return Right(spells);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on RateLimitException {
      return const Left(RateLimitFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
