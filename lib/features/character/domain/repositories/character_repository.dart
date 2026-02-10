import 'package:dartz/dartz.dart';
import 'package:wow_companion/core/error/failures.dart';
import 'package:wow_companion/features/character/domain/entities/character.dart';

abstract class CharacterRepository {
  /// Fetch full character profile with equipment and stats
  Future<Either<Failure, Character>> getCharacter({
    required String region,
    required String realm,
    required String name,
  });
}
