import 'package:wow_companion/core/l10n/wow_translations.dart';
import 'package:wow_companion/features/character/domain/entities/character.dart';

/// Un personaje guardado como favorito
class FavoriteCharacter {
  final String name;
  final String realm;
  final String region;
  final String characterClass;
  final String? specialization;
  final String? race;
  final int? itemLevel;
  final DateTime addedAt;

  FavoriteCharacter({
    required this.name,
    required this.realm,
    required this.region,
    required this.characterClass,
    this.specialization,
    this.race,
    this.itemLevel,
    DateTime? addedAt,
  }) : addedAt = addedAt ?? DateTime.now();

  /// Clave única: región-realm-nombre
  String get key =>
      '${region.toLowerCase()}-${realm.toLowerCase()}-${name.toLowerCase()}';

  /// Crear desde un Character completo
  factory FavoriteCharacter.fromCharacter(Character c) {
    final canonicalClass = WowTranslations.canonicalizeClass(c.characterClass);
    return FavoriteCharacter(
      name: c.name,
      realm: c.realm,
      region: c.region,
      characterClass: canonicalClass,
      specialization: WowTranslations.canonicalizeSpec(
        c.specialization,
        className: canonicalClass,
      ),
      race: WowTranslations.canonicalizeRace(c.race),
      itemLevel: c.equippedItemLevel,
    );
  }

  /// Serialización para guardado local
  Map<String, dynamic> toJson() => {
    'name': name,
    'realm': realm,
    'region': region,
    'characterClass': characterClass,
    'specialization': specialization,
    'race': race,
    'itemLevel': itemLevel,
    'addedAt': addedAt.toIso8601String(),
  };

  factory FavoriteCharacter.fromJson(Map<String, dynamic> json) {
    final rawClass = json['characterClass'] as String;
    final canonicalClass = WowTranslations.canonicalizeClass(rawClass);
    return FavoriteCharacter(
      name: json['name'] as String,
      realm: json['realm'] as String,
      region: json['region'] as String,
      characterClass: canonicalClass,
      specialization: WowTranslations.canonicalizeSpec(
        json['specialization'] as String?,
        className: canonicalClass,
      ),
      race: (json['race'] as String?) == null
          ? null
          : WowTranslations.canonicalizeRace(json['race'] as String),
      itemLevel: json['itemLevel'] as int?,
      addedAt: DateTime.parse(json['addedAt'] as String),
    );
  }
}

/// Contrato del repositorio de favoritos
abstract class FavoritesRepository {
  Future<List<FavoriteCharacter>> getFavorites();
  Future<void> addFavorite(FavoriteCharacter character);
  Future<void> removeFavorite(String key);
  Future<bool> isFavorite(String key);
}
