import 'package:dartz/dartz.dart';
import 'package:wow_companion/core/error/failures.dart';
import 'package:wow_companion/features/builds/domain/entities/build.dart';
import 'package:wow_companion/features/builds/domain/repositories/spells_repository.dart';

class SearchSpells {
  final SpellsRepository repository;

  SearchSpells(this.repository);

  Future<Either<Failure, List<WowSpell>>> call(
    String name, {
    String locale = 'en_GB',
  }) {
    return repository.searchSpells(name, locale: locale);
  }
}
