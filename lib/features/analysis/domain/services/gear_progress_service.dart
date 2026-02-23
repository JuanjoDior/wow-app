import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:wow_companion/features/analysis/domain/entities/gear_snapshot.dart';
import 'package:wow_companion/features/character/domain/entities/character.dart';

/// Persiste y recupera snapshots de progresión del personaje.
///
/// Usa SharedPreferences para almacenamiento local entre sesiones.
/// Los errores son silenciosos — el snapshot es no-crítico.
class GearProgressService {
  static const _prefix = 'gear_snapshot_';

  String _key(Character character) =>
      '$_prefix${character.region}_${character.realmSlug}_${character.name.toLowerCase()}';

  /// Carga el snapshot anterior para [character], o null si no existe.
  Future<GearSnapshot?> loadSnapshot(Character character) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw   = prefs.getString(_key(character));
      if (raw == null) return null;
      return GearSnapshot.fromJson(json.decode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Guarda el estado actual del personaje como nuevo snapshot.
  /// Sobreescribe el snapshot anterior del mismo personaje.
  Future<void> saveSnapshot(Character character) async {
    final ilvl  = character.equippedItemLevel;
    final score = character.mythicPlusProfile?.scoreAll
        ?? character.mythicPlusScore
        ?? 0.0;
    if (ilvl == null || ilvl == 0) return;

    try {
      final prefs    = await SharedPreferences.getInstance();
      final snapshot = GearSnapshot(
        characterKey:
            '${character.region}:${character.realmSlug}:${character.name.toLowerCase()}',
        date:      DateTime.now(),
        ilvl:      ilvl,
        mplusScore: score,
      );
      await prefs.setString(_key(character), json.encode(snapshot.toJson()));
    } catch (_) {
      // Fallo silencioso — no es funcionalidad crítica
    }
  }
}
