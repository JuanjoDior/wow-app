import 'package:dartz/dartz.dart';
import 'package:wow_companion/core/error/failures.dart';
import 'package:wow_companion/features/items/domain/entities/item.dart';
import 'package:wow_companion/features/items/domain/entities/item_search_mode.dart';
import 'package:wow_companion/features/items/domain/repositories/items_repository.dart';

class SearchItems {
  final ItemsRepository repository;

  SearchItems(this.repository);

  Future<Either<Failure, List<Item>>> call(
    String name, {
    ItemSearchMode mode = ItemSearchMode.item,
    String? inventoryType,
    String? slot,
    String region = 'eu',
    String locale = 'en_GB',
  }) {
    return repository.searchItems(
      name,
      mode: mode,
      inventoryType: inventoryType,
      slot: slot,
      region: region,
      locale: locale,
    );
  }
}
