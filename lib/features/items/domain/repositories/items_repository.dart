import 'package:dartz/dartz.dart';
import 'package:wow_companion/core/error/failures.dart';
import 'package:wow_companion/features/items/domain/entities/item.dart';
import 'package:wow_companion/features/items/domain/entities/item_search_mode.dart';

abstract class ItemsRepository {
  Future<Either<Failure, List<Item>>> searchItems(
    String name, {
    ItemSearchMode mode = ItemSearchMode.item,
    String? inventoryType,
    String? slot,
    String region = 'eu',
    String locale,
  });
  Future<Either<Failure, Item>> getItemDetail(
    int id, {
    String locale = 'en_GB',
  });
}
