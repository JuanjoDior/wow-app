import 'package:dartz/dartz.dart';
import 'package:wow_companion/core/error/failures.dart';
import 'package:wow_companion/features/builds/domain/entities/build.dart';

abstract class SpellsRepository {
  Future<Either<Failure, List<WowSpell>>> searchSpells(
    String name, {
    String locale,
  });
}
