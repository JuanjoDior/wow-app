import 'package:dartz/dartz.dart';
import 'package:wow_companion/core/error/failures.dart';
import 'package:wow_companion/features/items/domain/entities/item.dart';
import 'package:wow_companion/features/items/domain/entities/tooltip_detail.dart';
import 'package:wow_companion/features/items/domain/repositories/tooltip_repository.dart';

class GetTooltipDetail {
  final TooltipRepository repository;

  GetTooltipDetail(this.repository);

  Future<Either<Failure, TooltipDetail>> call(
    TooltipEntityKind kind,
    int id, {
    required String locale,
    String region = 'eu',
    List<int> bonusIds = const [],
  }) {
    return repository.getTooltipDetail(
      kind,
      id,
      locale: locale,
      region: region,
      bonusIds: bonusIds,
    );
  }
}
