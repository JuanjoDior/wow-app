import 'package:dartz/dartz.dart';
import 'package:wow_companion/core/cache/memory_cache.dart';
import 'package:wow_companion/core/error/exceptions.dart';
import 'package:wow_companion/core/error/failures.dart';
import 'package:wow_companion/features/character/data/datasources/blizzard_character_datasource.dart';
import 'package:wow_companion/features/character/data/datasources/raiderio_datasource.dart';
import 'package:wow_companion/features/character/domain/entities/character.dart';
import 'package:wow_companion/features/character/domain/repositories/character_repository.dart';

/// Repositorio híbrido:
///
/// - **Blizzard** (vía Worker): perfil, equipo con enchants/gemas exactos, stats.
///   Es la fuente principal para todo lo relacionado con el personaje en sí.
///
/// - **Raider.IO**: score M+, best runs, raid progression.
///   Raider.IO tiene mejores datos de progreso; Blizzard no expone ese score.
///
/// Estrategia:
/// 1. Intentar Blizzard primero (Worker).
/// 2. Lanzar Raider.IO en paralelo para M+ data.
/// 3. Si Blizzard falla → usar Raider.IO como fallback completo (comportamiento anterior).
/// 4. Resultado se cachea en memoria 5 min.
class CharacterRepositoryImpl implements CharacterRepository {
  final BlizzardCharacterDatasource blizzardDataSource;
  final RaiderIoDataSource raiderIoDataSource;
  final MemoryCache<Character> cache;

  CharacterRepositoryImpl({
    required this.blizzardDataSource,
    required this.raiderIoDataSource,
    required this.cache,
  });

  String _cacheKey(String region, String realm, String name) =>
      '${region.toLowerCase()}-${realm.toLowerCase()}-${name.toLowerCase()}';

  @override
  Future<Either<Failure, Character>> getCharacter({
    required String region,
    required String realm,
    required String name,
  }) async {
    // 1. Caché en memoria (5 min TTL gestionado por MemoryCache)
    final key = _cacheKey(region, realm, name);
    final cached = cache.get(key);
    if (cached != null) return Right(cached);

    // 2. Lanzar ambas fuentes en paralelo
    final futures = await Future.wait([
      blizzardDataSource
          .getCharacter(region: region, realm: realm, name: name)
          .then<Object?>((v) => v)
          .catchError((e) => e), // captura excepción como valor
      raiderIoDataSource
          .getCharacter(region: region, realm: realm, name: name)
          .then<Object?>((v) => v)
          .catchError((e) => e),
    ]);

    final blizzardResult = futures[0];
    final raiderResult = futures[1];

    // 3. Evaluar resultados
    final blizzardData = blizzardResult is CharacterBlizzardData
        ? blizzardResult
        : null;
    final raiderCharacter = raiderResult is Character ? raiderResult : null;

    Character? character;

    if (blizzardData != null) {
      final mergedEquipment = _mergeEquipmentIcons(
        blizzardData.equipment,
        raiderCharacter?.equipment ?? const [],
      );

      // ── Blizzard OK: usar como base + fusionar M+ de Raider.IO ──────────
      character = Character(
        name: blizzardData.name,
        realm: blizzardData.realm,
        region: blizzardData.region,
        level: blizzardData.level,
        race: blizzardData.race,
        characterClass: blizzardData.characterClass,
        specialization: blizzardData.specialization,
        guild: blizzardData.guild,
        achievementPoints: blizzardData.achievementPoints,
        averageItemLevel: blizzardData.averageItemLevel,
        equippedItemLevel: blizzardData.equippedItemLevel,
        // Fallback de imagen: Raider.IO tiene render siempre disponible
        avatarUrl: blizzardData.avatarUrl ?? raiderCharacter?.avatarUrl,
        equipment: mergedEquipment,
        stats: blizzardData.stats,
        // M+ data de Raider.IO (si disponible)
        mythicPlusScore: raiderCharacter?.mythicPlusScore,
        mythicPlusProfile: raiderCharacter?.mythicPlusProfile,
        raidProgression: raiderCharacter?.raidProgression,
        raidProgressionDetails: raiderCharacter?.raidProgressionDetails ?? [],
      );
    } else if (raiderCharacter != null) {
      // ── Blizzard falló, Raider.IO OK: fallback completo ─────────────────
      character = raiderCharacter;
    } else {
      // ── Ambas fallaron: devolver el error más informativo ────────────────
      return _handleError(blizzardResult, raiderResult);
    }

    // 4. Guardar en caché y retornar
    cache.set(key, character);
    return Right(character);
  }

  /// Convierte el primer error relevante en un [Failure].
  Either<Failure, Character> _handleError(
    Object? blizzardError,
    Object? raiderError,
  ) {
    // Priorizar el error de Blizzard (es la fuente principal)
    final err = (blizzardError is Exception) ? blizzardError : raiderError;

    if (err is NotFoundException) {
      return Left(NotFoundFailure(message: err.message));
    }
    if (err is RateLimitException) {
      return const Left(RateLimitFailure());
    }
    if (err is NetworkException) {
      return const Left(NetworkFailure());
    }
    if (err is ServerException) {
      return Left(ServerFailure(message: err.message));
    }

    return Left(ServerFailure(message: err?.toString() ?? 'Unknown error'));
  }

  List<EquippedItem> _mergeEquipmentIcons(
    List<EquippedItem> primary,
    List<EquippedItem> fallback,
  ) {
    if (primary.isEmpty || fallback.isEmpty) return primary;

    final fallbackByItemId = <int, EquippedItem>{
      for (final item in fallback)
        if (item.itemId != null && !_isBlank(item.iconUrl)) item.itemId!: item,
    };

    final fallbackBySlot = <String, EquippedItem>{
      for (final item in fallback)
        if (!_isBlank(item.iconUrl)) item.slot: item,
    };

    return primary
        .map((item) {
          if (!_isBlank(item.iconUrl)) return item;

          final byItemId = item.itemId != null
              ? fallbackByItemId[item.itemId!]
              : null;
          final bySlot = fallbackBySlot[item.slot];
          final iconSource = byItemId ?? bySlot;
          if (iconSource == null || _isBlank(iconSource.iconUrl)) return item;

          return EquippedItem(
            slot: item.slot,
            name: item.name,
            itemLevel: item.itemLevel,
            quality: item.quality,
            itemId: item.itemId,
            iconUrl: iconSource.iconUrl,
            enchantments: item.enchantments,
            gems: item.gems,
            bonusIds: item.bonusIds,
          );
        })
        .toList(growable: false);
  }

  bool _isBlank(String? value) => value == null || value.trim().isEmpty;
}
