import 'package:dartz/dartz.dart';
import 'package:wow_companion/core/error/failures.dart';
import 'package:wow_companion/features/items/domain/entities/item.dart';
import 'package:wow_companion/features/items/domain/entities/tooltip_detail.dart';

abstract class TooltipRepository {
  Future<Either<Failure, TooltipDetail>> getTooltipDetail(
    TooltipEntityKind kind,
    int id, {
    required String locale,
    String region = 'eu',
    List<int> bonusIds = const [],
  });
}
