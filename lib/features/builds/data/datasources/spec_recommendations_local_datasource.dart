import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:wow_companion/features/builds/domain/entities/spec_recommendation.dart';

/// Datasource local de recomendaciones por clase/spec desde asset JSON.
///
/// No depende de backend y funciona igual en todas las plataformas.
class SpecRecommendationsLocalDatasource {
  static const String _assetPath =
      'assets/recommendations/spec_recommendations.local.json';

  Map<String, dynamic>? _cachedData;
  String _defaultPatch = '';

  Future<SpecRecommendation?> getRecommendations({
    required String className,
    required String specName,
    String? patch,
  }) async {
    await _ensureLoaded();

    final key = _buildKey(className, specName);
    final raw = _cachedData?[key];
    if (raw is! Map<String, dynamic>) return null;

    return _fromJson(key: key, json: raw, patchOverride: patch);
  }

  Future<void> _ensureLoaded() async {
    if (_cachedData != null) return;

    final raw = await rootBundle.loadString(_assetPath);
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final metadata = decoded['metadata'] as Map<String, dynamic>? ?? const {};
    _defaultPatch = metadata['patch'] as String? ?? '';

    final data = decoded['data'] as Map<String, dynamic>? ?? const {};
    _cachedData = data.map((k, v) {
      if (v is Map<String, dynamic>) {
        return MapEntry(_normalize(k), v);
      }
      if (v is Map) {
        return MapEntry(_normalize(k), Map<String, dynamic>.from(v));
      }
      return const MapEntry('', <String, dynamic>{});
    })..remove('');
  }

  SpecRecommendation _fromJson({
    required String key,
    required Map<String, dynamic> json,
    String? patchOverride,
  }) {
    final parts = key.split(':');
    final classFromKey = parts.isNotEmpty ? parts.first : '';
    final specFromKey = parts.length > 1 ? parts[1] : '';

    final className = _normalize(json['class_name'] as String? ?? classFromKey);
    final specName = _normalize(json['spec_name'] as String? ?? specFromKey);
    final patch = patchOverride ?? json['patch'] as String? ?? _defaultPatch;

    final enchantsRaw = json['enchants'] as Map<String, dynamic>? ?? const {};
    final enchants = enchantsRaw.map((slot, value) {
      final rows = value is List ? value : const <dynamic>[];
      final parsed = rows
          .whereType<Map>()
          .map((e) {
            final map = Map<String, dynamic>.from(e);
            return ItemSuggestion(
              name: map['name'] as String? ?? '',
              note: map['note'] as String?,
              isPrimary: map['is_primary'] as bool? ?? false,
            );
          })
          .where((e) => e.name.trim().isNotEmpty)
          .toList();
      return MapEntry(slot, parsed);
    });

    final gems = json['gems'] as Map<String, dynamic>? ?? const {};
    final consumables =
        json['consumables'] as Map<String, dynamic>? ?? const {};

    final statPriority =
        (json['stat_priority'] as List<dynamic>? ?? const <dynamic>[])
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList();

    return SpecRecommendation(
      className: className,
      specName: specName,
      patch: patch,
      enchants: enchants,
      metaGem: _parseSuggestion(gems['meta']),
      genericGem: _parseSuggestion(gems['generic']),
      flask: _parseSuggestion(consumables['flask']),
      potion: _parseSuggestion(consumables['potion']),
      food: _parseSuggestion(consumables['food']),
      weaponEnhancement: _parseSuggestion(consumables['weapon']),
      statPriority: statPriority,
      source: RecommendationSource.local,
    );
  }

  ItemSuggestion? _parseSuggestion(dynamic raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    final name = (map['name'] as String? ?? '').trim();
    if (name.isEmpty) return null;
    return ItemSuggestion(
      name: name,
      note: (map['note'] as String?)?.trim(),
      isPrimary: map['is_primary'] as bool? ?? true,
    );
  }

  String _buildKey(String className, String specName) =>
      '${_normalize(className)}:${_normalize(specName)}';

  String _normalize(String value) {
    final replacements = <String, String>{
      'á': 'a',
      'é': 'e',
      'í': 'i',
      'ó': 'o',
      'ú': 'u',
      'ü': 'u',
      'ñ': 'n',
    };

    var out = value.trim().toLowerCase();
    replacements.forEach((from, to) => out = out.replaceAll(from, to));
    out = out.replaceAll(RegExp(r'[-_]'), ' ');
    out = out.replaceAll(RegExp(r'\s+'), ' ');
    return out.trim();
  }
}
