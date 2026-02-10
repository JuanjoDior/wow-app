import 'package:dartz/dartz.dart';
import 'package:wow_companion/core/error/failures.dart';
import 'package:wow_companion/features/character/domain/entities/character.dart';
import 'package:wow_companion/features/character/domain/repositories/character_repository.dart';

class GetCharacter {
  final CharacterRepository repository;

  GetCharacter(this.repository);

  Future<Either<Failure, Character>> call({
    required String region,
    required String realm,
    required String name,
  }) {
    return repository.getCharacter(region: region, realm: realm, name: name);
  }
}

