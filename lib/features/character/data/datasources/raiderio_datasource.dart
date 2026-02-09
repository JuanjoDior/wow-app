import 'package:dio/dio.dart';
import 'package:wow_companion/core/error/exceptions.dart';
import 'package:wow_companion/core/network/api_client.dart';
import 'package:wow_companion/features/character/domain/entities/character.dart';

class RaiderIoDataSource {
  final ApiClient _client;

  static const _baseUrl = 'https://raider.io/api/v1';

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
              'gear,mythic_plus_scores_by_season:current,raid_progression',
        },
      );

      return _mapCharacter(data, region);
    } on DioException catch (e) {
      if (e.response?.statusCode == 400 || e.response?.statusCode == 404) {
        throw const NotFoundException(
          message: 'Character not found. Check region, realm and name.',
        );
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw const NetworkException();
      }
      throw ServerException(
        message: e.message ?? 'Unknown error',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Character _mapCharacter(Map<String, dynamic> data, String region) {
    // Gear / Equipment
    final gear = data['gear'] as Map<String, dynamic>? ?? {};
    final gearItems = gear['items'] as Map<String, dynamic>? ?? {};
    final equipment = _mapEquipment(gearItems);

    // M+ Score
    final seasons =
        data['mythic_plus_scores_by_season'] as List<dynamic>? ?? [];
    double? mPlusScore;
    if (seasons.isNotEmpty) {
      final currentSeason = seasons.first as Map<String, dynamic>;
      final scores = currentSeason['scores'] as Map<String, dynamic>? ?? {};
      mPlusScore = (scores['all'] as num?)?.toDouble();
    }

    // Raid progression — get the latest raid
    final raidProg = data['raid_progression'] as Map<String, dynamic>? ?? {};
    String? raidSummary;
    if (raidProg.isNotEmpty) {
      final latestRaid = raidProg.values.first as Map<String, dynamic>;
      raidSummary = latestRaid['summary'] as String?;
    }

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
      raidProgression: raidSummary,
      avatarUrl: _getFullRenderUrl(data['thumbnail_url'] as String?),
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
      'mainHand': 'MAIN_HAND',
      'offHand': 'OFF_HAND',
      'finger1': 'FINGER_1',
      'finger2': 'FINGER_2',
      'trinket1': 'TRINKET_1',
      'trinket2': 'TRINKET_2',
    };

    final result = <EquippedItem>[];

    for (final entry in slotMapping.entries) {
      final item = items[entry.key] as Map<String, dynamic>?;
      if (item != null) {
        // Build icon URL from icon name
        final iconName = item['icon'] as String?;
        String? iconUrl;
        if (iconName != null && iconName.isNotEmpty) {
          iconUrl =
              'https://wow.zamimg.com/images/wow/icons/large/$iconName.jpg';
        }

        // Extract enchant name
        final enchants = <String>[];
        final enchant = item['enchant'] as int?;
        final enchantName = item['enchant_name'] as String?;
        if (enchantName != null && enchantName.isNotEmpty) {
          enchants.add(enchantName);
        } else if (enchant != null && enchant > 0) {
          enchants.add('Enchanted');
        }

        // Extract gems
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
}
