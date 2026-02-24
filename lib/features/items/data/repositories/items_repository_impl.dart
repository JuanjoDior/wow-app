import 'package:dartz/dartz.dart';
import 'package:wow_companion/core/error/exceptions.dart';
import 'package:wow_companion/core/error/failures.dart';
import 'package:wow_companion/features/items/data/datasources/blizzard_items_datasource.dart';
import 'package:wow_companion/features/items/domain/entities/item.dart';
import 'package:wow_companion/features/items/domain/repositories/items_repository.dart';

class ItemsRepositoryImpl implements ItemsRepository {
  final BlizzardItemsDataSource remoteDataSource;

  ItemsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Item>>> searchItems(
    String name, {
    String? inventoryType,
    String locale = 'en_GB',
  }) async {
    try {
      final items = await remoteDataSource.searchItems(
        name,
        inventoryType: inventoryType,
        locale: locale,
      );
      return Right(items);
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

  @override
  Future<Either<Failure, Item>> getItemDetail(
    int id, {
    String locale = 'en_GB',
  }) async {
    try {
      final item = await remoteDataSource.getItemById(id, locale: locale);
      return Right(item);
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
