import 'package:dartz/dartz.dart';
import 'package:wow_companion/core/error/failures.dart';
import 'package:wow_companion/features/items/domain/entities/item.dart';
import 'package:wow_companion/features/items/domain/repositories/items_repository.dart';

class GetItemDetail {
  final ItemsRepository repository;

  GetItemDetail(this.repository);

  Future<Either<Failure, Item>> call(int id, {String locale = 'en_GB'}) {
    return repository.getItemDetail(id, locale: locale);
  }
}
