import 'package:dartz/dartz.dart';
import 'package:wow_companion/core/error/failures.dart';
import 'package:wow_companion/features/items/domain/entities/item.dart';

abstract class ItemsRepository {
  Future<Either<Failure, List<Item>>> searchItems(
    String name, {
    String? inventoryType,
    String locale,
  });
}
