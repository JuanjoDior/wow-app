import 'package:dartz/dartz.dart';
import 'package:wow_companion/core/error/exceptions.dart';
import 'package:wow_companion/core/error/failures.dart';
import 'package:wow_companion/features/items/data/datasources/tooltip_remote_datasource.dart';
import 'package:wow_companion/features/items/domain/entities/item.dart';
import 'package:wow_companion/features/items/domain/entities/tooltip_detail.dart';
import 'package:wow_companion/features/items/domain/repositories/tooltip_repository.dart';

class TooltipRepositoryImpl implements TooltipRepository {
  final TooltipRemoteDataSource remoteDataSource;

  TooltipRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, TooltipDetail>> getTooltipDetail(
    TooltipEntityKind kind,
    int id, {
    required String locale,
    String region = 'eu',
    List<int> bonusIds = const [],
  }) async {
    try {
      final detail = await remoteDataSource.getTooltipDetail(
        kind,
        id,
        locale: locale,
        region: region,
        bonusIds: bonusIds,
      );
      return Right(detail);
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
