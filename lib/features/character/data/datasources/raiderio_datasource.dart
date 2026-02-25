import 'package:dio/dio.dart';
import 'package:wow_companion/core/error/exceptions.dart';
import 'package:wow_companion/core/network/api_client.dart';
import 'package:wow_companion/features/character/domain/entities/character.dart';

class CurrentRaidInfo {
  final String slug;
  final String name;
  final int totalBosses;

  const CurrentRaidInfo({
    required this.slug,
    required this.name,
    required this.totalBosses,
  });
}

class _CachedCurrentRaid {
  final CurrentRaidInfo raid;
  final DateTime expiresAt;

  const _CachedCurrentRaid({required this.raid, required this.expiresAt});
}

class RaiderIoDataSource {
  final ApiClient _client;

  static const _baseUrl = 'https://raider.io/api/v1';
  static const _liveRaidCacheTtl = Duration(minutes: 30);
  static const _expansionIds = [11, 10, 9, 8, 7, 6];
  static const _supportedRegions = {'us', 'eu', 'kr', 'tw'};

  final Map<String, _CachedCurrentRaid> _currentRaidCacheByRegion = {};
  final Map<String, CurrentRaidInfo> _lastValidByRegion = {};

  RaiderIoDataSource(this._client);

  Future<Character> getCharacter({
    required String region,
    required String realm,
    required String name,
  }) async {
    try {
      final data = await _client.get(
        '$_baseUrl/characters/profile',
        queryParameters: {
          'region': region.toLowerCase(),
          'realm': realm.toLowerCase(),
          'name': name.toLowerCase(),
          'fields':
              'gear,mythic_plus_scores_by_season:current,mythic_plus_best_runs,raid_progression',
        },
        expectedErrorStatusCodes: const {400, 404},
      );

      return _mapCharacter(data, region);
    } on DioException catch (e) {
      if (e.response?.statusCode == 400 || e.response?.statusCode == 404) {
        throw const NotFoundException(
          message: 'Character not found. Check region, realm and name.',
        );
      }
      if (e.response?.statusCode == 429) {
        throw const RateLimitException();
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw const NetworkException(
          message: 'Request timed out. The server may be slow.',
        );
      }
      if (e.type == DioExceptionType.connectionError) {
        throw const NetworkException();
      }
      throw ServerException(
        message: e.message ?? 'Unknown error',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<CurrentRaidInfo?> getCurrentLiveRaid({required String region}) async {
    final normalizedRegion = _normalizeRegion(region);
    final now = DateTime.now().toUtc();
    final cached = _currentRaidCacheByRegion[normalizedRegion];
    if (cached != null && cached.expiresAt.isAfter(now)) {
      return cached.raid;
    }

    CurrentRaidInfo? resolved;
    for (final expansionId in _expansionIds) {
      try {
        final data = await _client.get(
          '$_baseUrl/raiding/static-data',
          queryParameters: {'expansion_id': expansionId},
        );
        final candidate = _selectCurrentRaidFromStaticData(
          data,
          normalizedRegion,
          now,
        );
        if (candidate != null) {
          resolved = candidate;
          break;
        }
      } on DioException {
        // Ignore this expansion and continue with others.
      } on ServerException {
        // Ignore this expansion and continue with others.
      } on NetworkException {
        // Ignore this expansion and continue with others.
      } on FormatException {
        // Ignore malformed responses for this expansion.
      }
    }

    if (resolved != null) {
      _rememberCurrentRaid(normalizedRegion, resolved, now);
      return resolved;
    }

    final lastValid = _lastValidByRegion[normalizedRegion];
    if (lastValid != null) {
      _rememberCurrentRaid(normalizedRegion, lastValid, now);
      return lastValid;
    }

    return null;
  }

  Character _mapCharacter(Map<String, dynamic> data, String region) {
    // Gear / Equipment
    final gear = data['gear'] as Map<String, dynamic>? ?? {};
    final gearItems = gear['items'] as Map<String, dynamic>? ?? {};
    final equipment = _mapEquipment(gearItems);

    // M+ Score + Profile
    final seasons =
        data['mythic_plus_scores_by_season'] as List<dynamic>? ?? [];
    double? mPlusScore;
    MythicPlusProfile? mPlusProfile;

    if (seasons.isNotEmpty) {
      final currentSeason = seasons.first as Map<String, dynamic>;
      final scores = currentSeason['scores'] as Map<String, dynamic>? ?? {};
      mPlusScore = (scores['all'] as num?)?.toDouble();

      final bestRuns = _mapBestRuns(
        data['mythic_plus_best_runs'] as List<dynamic>? ?? [],
      );

      mPlusProfile = MythicPlusProfile(
        scoreAll: mPlusScore ?? 0,
        scoreDps: (scores['dps'] as num?)?.toDouble() ?? 0,
        scoreHealer: (scores['healer'] as num?)?.toDouble() ?? 0,
        scoreTank: (scores['tank'] as num?)?.toDouble() ?? 0,
        bestRuns: bestRuns,
      );
    }

    // Raid progression — all raids
    final raidProg = data['raid_progression'] as Map<String, dynamic>? ?? {};
    String? raidSummary;
    final raidDetails = <RaidProgress>[];

    for (final entry in raidProg.entries) {
      final raidData = entry.value as Map<String, dynamic>;
      final progress = RaidProgress(
        raidName: _formatRaidName(entry.key),
        slug: entry.key,
        summary: raidData['summary'] as String? ?? '',
        totalBosses: (raidData['total_bosses'] as num?)?.toInt() ?? 0,
        normalKilled: (raidData['normal_bosses_killed'] as num?)?.toInt() ?? 0,
        heroicKilled: (raidData['heroic_bosses_killed'] as num?)?.toInt() ?? 0,
        mythicKilled: (raidData['mythic_bosses_killed'] as num?)?.toInt() ?? 0,
      );
      raidDetails.add(progress);
    }

    // Summary = first raid's summary (current tier)
    if (raidDetails.isNotEmpty) {
      raidSummary = raidDetails.first.summary;
    }

    final rawThumbnailUrl = _normalizeThumbnailUrl(
      data['thumbnail_url'] as String?,
    );

    return Character(
      name: data['name'] as String? ?? '',
      realm: data['realm'] as String? ?? '',
      region: (data['region'] as String? ?? region).toUpperCase(),
      level: 80,
      race: data['race'] as String? ?? 'Unknown',
      characterClass: data['class'] as String? ?? 'Unknown',
      specialization: data['active_spec_name'] as String?,
      guild: data['guild'] != null
          ? (data['guild'] as Map<String, dynamic>)['name'] as String?
          : null,
      achievementPoints: data['achievement_points'] as int?,
      averageItemLevel: (gear['item_level_equipped'] as num?)?.toInt(),
      equippedItemLevel: (gear['item_level_equipped'] as num?)?.toInt(),
      equipment: equipment,
      stats: null,
      mythicPlusScore: mPlusScore,
      mythicPlusProfile: mPlusProfile,
      raidProgression: raidSummary,
      raidProgressionDetails: raidDetails,
      avatarUrl: _getFullRenderUrl(rawThumbnailUrl),
      thumbnailUrl: rawThumbnailUrl,
    );
  }

  String? _getFullRenderUrl(String? thumbnailUrl) {
    if (thumbnailUrl == null || thumbnailUrl.isEmpty) return null;

    if (thumbnailUrl.contains('-avatar.jpg')) {
      return thumbnailUrl.replaceAll('-avatar.jpg', '-main-raw.png');
    }

    if (thumbnailUrl.contains('avatar.jpg')) {
      return thumbnailUrl.replaceAll('avatar.jpg', 'main-raw.png');
    }

    return thumbnailUrl;
  }

  String? _normalizeThumbnailUrl(String? thumbnailUrl) {
    if (thumbnailUrl == null) return null;
    final normalized = thumbnailUrl.trim();
    if (normalized.isEmpty) return null;
    return normalized;
  }

  List<EquippedItem> _mapEquipment(Map<String, dynamic> items) {
    final slotMapping = {
      'head': 'HEAD',
      'neck': 'NECK',
      'shoulder': 'SHOULDER',
      'chest': 'CHEST',
      'waist': 'WAIST',
      'legs': 'LEGS',
      'feet': 'FEET',
      'wrist': 'WRIST',
      'hands': 'HANDS',
      'back': 'BACK',
      'mainhand': 'MAIN_HAND',
      'offhand': 'OFF_HAND',
      'finger1': 'FINGER_1',
      'finger2': 'FINGER_2',
      'trinket1': 'TRINKET_1',
      'trinket2': 'TRINKET_2',
    };

    final result = <EquippedItem>[];

    for (final entry in slotMapping.entries) {
      final item = items[entry.key] as Map<String, dynamic>?;
      if (item != null) {
        final iconName = item['icon'] as String?;
        String? iconUrl;
        if (iconName != null && iconName.isNotEmpty) {
          iconUrl =
              'https://wow.zamimg.com/images/wow/icons/large/$iconName.jpg';
        }

        final enchants = <String>[];
        final enchant = item['enchant'] as int?;
        final enchantName = item['enchant_name'] as String?;
        if (enchantName != null && enchantName.isNotEmpty) {
          enchants.add(enchantName);
        } else if (enchant != null && enchant > 0) {
          enchants.add('Enchanted');
        }

        final gems = <String>[];
        final gemList = item['gems'] as List<dynamic>?;
        if (gemList != null) {
          for (final gem in gemList) {
            if (gem is Map<String, dynamic>) {
              final gemName = gem['name'] as String?;
              if (gemName != null) {
                gems.add(gemName);
              }
            }
          }
        }

        // Extract bonus IDs
        final bonusIds = <int>[];
        final bonusList = item['bonuses'] as List<dynamic>?;
        if (bonusList != null) {
          for (final b in bonusList) {
            if (b is num) bonusIds.add(b.toInt());
          }
        }

        result.add(
          EquippedItem(
            slot: entry.value,
            name: item['name'] as String? ?? 'Unknown',
            itemLevel: (item['item_level'] as num?)?.toInt() ?? 0,
            quality: _mapQuality(
              (item['item_quality'] as num?)?.toString() ?? '',
            ),
            itemId: item['item_id'] as int?,
            iconUrl: iconUrl,
            enchantments: enchants,
            gems: gems,
            bonusIds: bonusIds,
          ),
        );
      }
    }

    return result;
  }

  String _mapQuality(String tier) {
    switch (tier.toLowerCase()) {
      case '5':
      case 'legendary':
        return 'LEGENDARY';
      case '4':
      case 'epic':
        return 'EPIC';
      case '3':
      case 'rare':
        return 'RARE';
      case '2':
      case 'uncommon':
        return 'UNCOMMON';
      default:
        return 'EPIC';
    }
  }

  List<MythicPlusRun> _mapBestRuns(List<dynamic> runs) {
    return runs.map((run) {
      final r = run as Map<String, dynamic>;
      final dungeon = r['dungeon'] as String? ?? 'Unknown';
      final shortName = r['short_name'] as String? ?? dungeon;
      final mythicLevel = (r['mythic_level'] as num?)?.toInt() ?? 0;
      final clearTimeMs = (r['clear_time_ms'] as num?)?.toInt() ?? 0;
      final parTimeMs = (r['par_time_ms'] as num?)?.toInt() ?? 0;
      final numUpgrades = (r['num_keystone_upgrades'] as num?)?.toInt() ?? 0;
      final score = (r['score'] as num?)?.toDouble() ?? 0;
      final url = r['url'] as String?;

      final affixList = r['affixes'] as List<dynamic>? ?? [];
      final affixNames = affixList
          .map((a) => (a as Map<String, dynamic>)['name'] as String? ?? '')
          .where((a) => a.isNotEmpty)
          .join(', ');

      return MythicPlusRun(
        dungeon: dungeon,
        shortName: shortName,
        mythicLevel: mythicLevel,
        completedTime: Duration(milliseconds: clearTimeMs),
        parTime: Duration(milliseconds: parTimeMs),
        numKeystoneUpgrades: numUpgrades,
        score: score,
        affixes: affixNames.isNotEmpty ? affixNames : null,
        url: url,
      );
    }).toList()..sort((a, b) => b.score.compareTo(a.score));
  }

  String _formatRaidName(String slug) {
    const raidNames = {
      'nerubar-palace': "Nerub-ar Palace",
      'blackrock-depths': 'Blackrock Depths',
      'amirdrassil-the-dreams-hope': "Amirdrassil",
      'aberrus-the-shadowed-crucible': 'Aberrus',
      'vault-of-the-incarnates': 'Vault of the Incarnates',
      'liberation-of-undermine': 'Liberation of Undermine',
    };

    return raidNames[slug] ??
        slug
            .split('-')
            .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
            .join(' ');
  }

  void _rememberCurrentRaid(
    String region,
    CurrentRaidInfo raid,
    DateTime nowUtc,
  ) {
    _currentRaidCacheByRegion[region] = _CachedCurrentRaid(
      raid: raid,
      expiresAt: nowUtc.add(_liveRaidCacheTtl),
    );
    _lastValidByRegion[region] = raid;
  }

  CurrentRaidInfo? _selectCurrentRaidFromStaticData(
    Map<String, dynamic> data,
    String region,
    DateTime nowUtc,
  ) {
    final raids = data['raids'] as List<dynamic>? ?? const [];
    if (raids.isEmpty) return null;

    final candidates = <_RaidDateCandidate>[];
    for (final raid in raids) {
      if (raid is! Map<String, dynamic>) continue;
      final slug = (raid['slug'] as String?)?.trim();
      if (slug == null || slug.isEmpty) continue;

      final start = _parseRegionalDate(raid['starts'], region);
      final end = _parseRegionalDate(raid['ends'], region);
      if (start == null) continue;
      if (end != null && !start.isBefore(end)) continue;

      final name = ((raid['name'] as String?)?.trim().isNotEmpty ?? false)
          ? (raid['name'] as String).trim()
          : _formatRaidName(slug);
      final encounters = raid['encounters'] as List<dynamic>? ?? const [];
      final totalBosses = encounters.length;

      candidates.add(
        _RaidDateCandidate(
          info: CurrentRaidInfo(
            slug: slug,
            name: name,
            totalBosses: totalBosses,
          ),
          startsAt: start,
          endsAt: end,
        ),
      );
    }

    if (candidates.isEmpty) return null;

    final active =
        candidates
            .where(
              (c) =>
                  !c.startsAt.isAfter(nowUtc) &&
                  (c.endsAt == null || nowUtc.isBefore(c.endsAt!)),
            )
            .toList()
          ..sort((a, b) => b.startsAt.compareTo(a.startsAt));
    if (active.isNotEmpty) return active.first.info;

    final started =
        candidates.where((c) => !c.startsAt.isAfter(nowUtc)).toList()
          ..sort((a, b) => b.startsAt.compareTo(a.startsAt));
    if (started.isNotEmpty) return started.first.info;

    return null;
  }

  DateTime? _parseRegionalDate(dynamic value, String region) {
    if (value is! Map<String, dynamic>) return null;
    final raw =
        value[region] ??
        value[region.toUpperCase()] ??
        value['us'] ??
        value['US'];
    if (raw is! String || raw.trim().isEmpty) return null;
    try {
      return DateTime.parse(raw).toUtc();
    } on FormatException {
      return null;
    }
  }

  String _normalizeRegion(String region) {
    final normalized = region.trim().toLowerCase();
    if (_supportedRegions.contains(normalized)) return normalized;
    return 'eu';
  }
}

class _RaidDateCandidate {
  final CurrentRaidInfo info;
  final DateTime startsAt;
  final DateTime? endsAt;

  const _RaidDateCandidate({
    required this.info,
    required this.startsAt,
    required this.endsAt,
  });
}
