import 'package:wow_companion/features/character/domain/entities/character.dart';

/// Un personaje guardado como favorito
class FavoriteCharacter {
  final String name;
  final String realm;
  final String region;
  final String characterClass;
  final String? specialization;
  final int? itemLevel;
  final DateTime addedAt;

  FavoriteCharacter({
    required this.name,
    required this.realm,
    required this.region,
    required this.characterClass,
    this.specialization,
    this.itemLevel,
    DateTime? addedAt,
  }) : addedAt = addedAt ?? DateTime.now();

  /// Clave única: región-realm-nombre
  String get key =>
      '${region.toLowerCase()}-${realm.toLowerCase()}-${name.toLowerCase()}';

  /// Crear desde un Character completo
  factory FavoriteCharacter.fromCharacter(Character c) {
    return FavoriteCharacter(
      name: c.name,
      realm: c.realm,
      region: c.region,
      characterClass: c.characterClass,
      specialization: c.specialization,
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
    'itemLevel': itemLevel,
    'addedAt': addedAt.toIso8601String(),
  };

  factory FavoriteCharacter.fromJson(Map<String, dynamic> json) {
    return FavoriteCharacter(
      name: json['name'] as String,
      realm: json['realm'] as String,
      region: json['region'] as String,
      characterClass: json['characterClass'] as String,
      specialization: json['specialization'] as String?,
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
