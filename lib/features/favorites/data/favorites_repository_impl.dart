import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wow_companion/features/favorites/domain/favorites_repository.dart';

class FavoritesRepositoryImpl implements FavoritesRepository {
  static const _storageKey = 'wow_favorites';

  @override
  Future<List<FavoriteCharacter>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_storageKey);
    if (data == null) return [];

    final List<dynamic> list = jsonDecode(data) as List<dynamic>;
    return list
        .map((e) => FavoriteCharacter.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
  }

  @override
  Future<void> addFavorite(FavoriteCharacter character) async {
    final favorites = await getFavorites();
    // No duplicar
    if (favorites.any((f) => f.key == character.key)) return;
    favorites.add(character);
    await _save(favorites);
  }

  @override
  Future<void> removeFavorite(String key) async {
    final favorites = await getFavorites();
    favorites.removeWhere((f) => f.key == key);
    await _save(favorites);
  }

  @override
  Future<bool> isFavorite(String key) async {
    final favorites = await getFavorites();
    return favorites.any((f) => f.key == key);
  }

  Future<void> _save(List<FavoriteCharacter> favorites) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(favorites.map((f) => f.toJson()).toList()),
    );
  }
}
