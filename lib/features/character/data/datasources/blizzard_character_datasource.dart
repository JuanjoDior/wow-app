import 'package:dio/dio.dart';
import 'package:wow_companion/core/error/exceptions.dart';
import 'package:wow_companion/features/character/domain/entities/character.dart';

/// Datasource que obtiene el perfil de un personaje a través del Cloudflare Worker,
/// el cual consulta la Blizzard Battle.net API en nombre de la app.
///
/// Devuelve: nombre, clase, spec, raza, nivel, guild, ilvl, equipo (con enchants y
/// gemas exactos), stats exactas (%, valores), avatar_url y thumbnail_url.
/// NO devuelve M+ score ni raid progression (eso es de Raider.IO).
class BlizzardCharacterDatasource {
  final Dio _dio;

  static const String _workerBaseUrl =
      'https://wow-recommendations.wow-comp-app.workers.dev';
  static const String _characterSnapshotPath = '/v2/character/snapshot';
  static const String _characterLegacyPath = '/character';

  BlizzardCharacterDatasource({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 15),
            ),
          );

  Future<CharacterBlizzardData> getCharacter({
    required String region,
    required String realm,
    required String name,
    String locale = 'en_GB',
    bool force = false,
  }) async {
    final params = <String, String>{
      'region': region.toLowerCase(),
      'realm': realm.toLowerCase(),
      'name': name.toLowerCase(),
      'locale': locale,
      if (force) 'force': '1',
    };

    final payload = await _fetchCharacterPayload(params);
    return CharacterBlizzardData.fromJson(payload);
  }

  Future<Map<String, dynamic>> _fetchCharacterPayload(
    Map<String, String> params,
  ) async {
    try {
      final response = await _dio.get(
        '$_workerBaseUrl$_characterSnapshotPath',
        queryParameters: params,
      );
      return _extractCharacterPayload(response.data);
    } on DioException catch (error) {
      if (_shouldFallbackToLegacy(error)) {
        try {
          final legacyResponse = await _dio.get(
            '$_workerBaseUrl$_characterLegacyPath',
            queryParameters: params,
          );
          return _extractCharacterPayload(legacyResponse.data);
        } on DioException catch (legacyError) {
          _throwMappedException(legacyError);
        }
      }
      _throwMappedException(error);
    }
  }

  Map<String, dynamic> _extractCharacterPayload(dynamic data) {
    if (data is! Map) {
      throw const ServerException(message: 'Unexpected response from Worker');
    }

    final mapData = Map<String, dynamic>.from(data);
    final snapshot = mapData['snapshot'];
    if (snapshot is Map) {
      return Map<String, dynamic>.from(snapshot);
    }
    return mapData;
  }

  bool _shouldFallbackToLegacy(DioException error) {
    final statusCode = error.response?.statusCode;
    if (statusCode != 404 && statusCode != 405 && statusCode != 501) {
      return false;
    }

    final data = error.response?.data;
    if (data is Map) {
      final mapData = Map<String, dynamic>.from(data);
      final endpoint = mapData['endpoint']?.toString();
      final workerError =
          mapData['error']?.toString().toLowerCase().trim() ?? '';

      if (endpoint == _characterSnapshotPath) {
        return false;
      }

      if (workerError.contains('character not found') ||
          workerError.contains('unknown region') ||
          workerError.contains('missing required params')) {
        return false;
      }
    }

    return true;
  }

  Never _throwMappedException(DioException error) {
    final statusCode = error.response?.statusCode;
    final workerErrorMessage = _extractWorkerError(error.response?.data);

    if (statusCode == 400) {
      throw ServerException(
        message: workerErrorMessage ?? 'Invalid character query parameters.',
        statusCode: 400,
      );
    }

    if (statusCode == 404) {
      throw NotFoundException(
        message:
            workerErrorMessage ??
            'Character not found. Check region, realm and name.',
      );
    }

    if (statusCode == 503) {
      throw ServerException(
        message: workerErrorMessage ?? 'Blizzard API not configured on Worker.',
        statusCode: 503,
      );
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      throw const NetworkException(
        message: 'Request timed out. Check your connection.',
      );
    }

    if (error.type == DioExceptionType.connectionError) {
      throw const NetworkException();
    }

    throw ServerException(
      message: workerErrorMessage ?? error.message ?? 'Unknown Worker error',
      statusCode: statusCode,
    );
  }

  String? _extractWorkerError(dynamic data) {
    if (data is! Map) return null;
    final raw = data['error'];
    if (raw is! String) return null;
    final trimmed = raw.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

// ─── Data transfer object ─────────────────────────────────────────────────────
//
// Contiene sólo los datos que provienen de Blizzard.
// El repositorio combina esto con los datos M+ de Raider.IO.

class CharacterBlizzardData {
  final String name;
  final String realm;
  final String region;
  final int level;
  final String race;
  final String characterClass;
  final String? specialization;
  final String? guild;
  final int? achievementPoints;
  final int? averageItemLevel;
  final int? equippedItemLevel;
  final String? avatarUrl;
  final String? thumbnailUrl;
  final List<EquippedItem> equipment;
  final CharacterStats? stats;

  const CharacterBlizzardData({
    required this.name,
    required this.realm,
    required this.region,
    required this.level,
    required this.race,
    required this.characterClass,
    this.specialization,
    this.guild,
    this.achievementPoints,
    this.averageItemLevel,
    this.equippedItemLevel,
    this.avatarUrl,
    this.thumbnailUrl,
    this.equipment = const [],
    this.stats,
  });

  factory CharacterBlizzardData.fromJson(Map<String, dynamic> json) {
    final equipRaw = json['equipment'] as List<dynamic>? ?? [];
    final equipment = equipRaw
        .map((e) => _parseItem(e as Map<String, dynamic>))
        .toList();

    final statsRaw = json['stats'] as Map<String, dynamic>?;
    CharacterStats? stats;
    if (statsRaw != null) {
      stats = CharacterStats(
        health: (statsRaw['health'] as num?)?.toInt(),
        mana: (statsRaw['mana'] as num?)?.toInt(),
        powerType: statsRaw['power_type'] as String?,
        strength: (statsRaw['strength'] as num?)?.toInt(),
        agility: (statsRaw['agility'] as num?)?.toInt(),
        intellect: (statsRaw['intellect'] as num?)?.toInt(),
        stamina: (statsRaw['stamina'] as num?)?.toInt(),
        criticalStrike: (statsRaw['critical_strike'] as num?)?.toDouble(),
        haste: (statsRaw['haste'] as num?)?.toDouble(),
        mastery: (statsRaw['mastery'] as num?)?.toDouble(),
        versatility: (statsRaw['versatility'] as num?)?.toDouble(),
      );
    }

    return CharacterBlizzardData(
      name: json['name'] as String? ?? '',
      realm: json['realm'] as String? ?? '',
      region: (json['region'] as String? ?? '').toUpperCase(),
      level: (json['level'] as num?)?.toInt() ?? 80,
      race: json['race'] as String? ?? 'Unknown',
      characterClass: json['class'] as String? ?? 'Unknown',
      specialization: json['spec'] as String?,
      guild: json['guild'] as String?,
      achievementPoints: (json['achievement_points'] as num?)?.toInt(),
      averageItemLevel: (json['average_item_level'] as num?)?.toInt(),
      equippedItemLevel: (json['equipped_item_level'] as num?)?.toInt(),
      avatarUrl: json['avatar_url'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      equipment: equipment,
      stats: stats,
    );
  }

  static EquippedItem _parseItem(Map<String, dynamic> item) {
    final rawSlot = (item['slot'] as String? ?? 'UNKNOWN').toUpperCase();
    final rawIconUrl = item['icon_url'] ?? item['iconUrl'];
    final iconUrl = rawIconUrl is String && rawIconUrl.trim().isNotEmpty
        ? rawIconUrl
        : null;

    // Enchantments: lista de strings con el nombre del encant exacto (en inglés)
    final enchantments =
        (item['enchantments'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .toList() ??
        [];

    // Gems: lista de strings con el nombre de la gema exacto (en inglés)
    final gems =
        (item['gems'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .toList() ??
        [];

    final bonusIds =
        (item['bonus_ids'] as List<dynamic>?)
            ?.map((e) => (e as num).toInt())
            .toList() ??
        [];
    final enchantmentIds =
        (item['enchantment_ids'] as List<dynamic>?)
            ?.map((e) => (e as num).toInt())
            .toList() ??
        [];
    final gemIds =
        (item['gem_ids'] as List<dynamic>?)
            ?.map((e) => (e as num).toInt())
            .toList() ??
        [];

    return EquippedItem(
      slot: rawSlot,
      name: item['name'] as String? ?? 'Unknown',
      itemLevel: (item['item_level'] as num?)?.toInt() ?? 0,
      quality: (item['quality'] as String? ?? 'EPIC').toUpperCase(),
      itemId: (item['item_id'] as num?)?.toInt(),
      iconUrl: iconUrl,
      enchantments: enchantments,
      enchantmentIds: enchantmentIds,
      gems: gems,
      gemIds: gemIds,
      bonusIds: bonusIds,
    );
  }
}
