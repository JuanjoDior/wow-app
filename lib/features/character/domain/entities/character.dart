import 'package:equatable/equatable.dart';

class Character extends Equatable {
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

  /// URL del render 3D del personaje (main-raw.png — puede ser null si no está disponible).
  final String? avatarUrl;

  /// URL del avatar en miniatura (JPEG pequeño — siempre disponible si hay datos).
  final String? thumbnailUrl;
  final List<EquippedItem> equipment;
  final CharacterStats? stats;
  final double? mythicPlusScore;
  final String? raidProgression;
  final MythicPlusProfile? mythicPlusProfile;
  final List<RaidProgress> raidProgressionDetails;

  const Character({
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
    this.mythicPlusScore,
    this.raidProgression,
    this.mythicPlusProfile,
    this.raidProgressionDetails = const [],
  });

  /// Primera URL de imagen disponible: render 3D si existe, si no la miniatura.
  String? get bestAvatarUrl => avatarUrl ?? thumbnailUrl;

  String get displayName => '$name - $realm ($region)';
  String get realmSlug => realm.toLowerCase().replaceAll(' ', '-');

  Character copyWith({
    String? name,
    String? realm,
    String? region,
    int? level,
    String? race,
    String? characterClass,
    String? specialization,
    String? guild,
    int? achievementPoints,
    int? averageItemLevel,
    int? equippedItemLevel,
    String? avatarUrl,
    String? thumbnailUrl,
    List<EquippedItem>? equipment,
    CharacterStats? stats,
    double? mythicPlusScore,
    String? raidProgression,
    MythicPlusProfile? mythicPlusProfile,
    List<RaidProgress>? raidProgressionDetails,
  }) {
    return Character(
      name: name ?? this.name,
      realm: realm ?? this.realm,
      region: region ?? this.region,
      level: level ?? this.level,
      race: race ?? this.race,
      characterClass: characterClass ?? this.characterClass,
      specialization: specialization ?? this.specialization,
      guild: guild ?? this.guild,
      achievementPoints: achievementPoints ?? this.achievementPoints,
      averageItemLevel: averageItemLevel ?? this.averageItemLevel,
      equippedItemLevel: equippedItemLevel ?? this.equippedItemLevel,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      equipment: equipment ?? this.equipment,
      stats: stats ?? this.stats,
      mythicPlusScore: mythicPlusScore ?? this.mythicPlusScore,
      raidProgression: raidProgression ?? this.raidProgression,
      mythicPlusProfile: mythicPlusProfile ?? this.mythicPlusProfile,
      raidProgressionDetails:
          raidProgressionDetails ?? this.raidProgressionDetails,
    );
  }

  @override
  List<Object?> get props => [name, realm, region];
}

class EquippedItem extends Equatable {
  final String slot;
  final String name;
  final int itemLevel;
  final String quality;
  final int? itemId;
  final String? iconUrl;
  final List<String> enchantments;
  final List<String> gems;
  final List<int> bonusIds;

  const EquippedItem({
    required this.slot,
    required this.name,
    required this.itemLevel,
    required this.quality,
    this.itemId,
    this.iconUrl,
    this.enchantments = const [],
    this.gems = const [],
    this.bonusIds = const [],
  });

  /// Wowhead URL for this item (with bonus IDs for exact version)
  String? get wowheadUrl {
    if (itemId == null) return null;
    final base = 'https://www.wowhead.com/item=$itemId';
    if (bonusIds.isNotEmpty) {
      return '$base&bonus=${bonusIds.join(':')}';
    }
    return base;
  }

  /// Formatted slot name: "MAIN_HAND" → "Main Hand"
  String get displaySlot {
    return slot
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (w) =>
              w.isEmpty ? w : w[0].toUpperCase() + w.substring(1).toLowerCase(),
        )
        .join(' ');
  }

  @override
  List<Object?> get props => [slot, name, itemLevel];
}

class CharacterStats extends Equatable {
  /// Recursos primarios
  final int? health;
  final int? mana;
  final String? powerType; // 'MANA', 'ENERGY', 'RAGE', 'RUNIC_POWER', etc.

  /// Stats base
  final int? strength;
  final int? agility;
  final int? intellect;
  final int? stamina;

  /// Stats secundarias (como porcentaje, e.g. 14.0 = 14%)
  final double? criticalStrike;
  final double? haste;
  final double? mastery;
  final double? versatility;

  const CharacterStats({
    this.health,
    this.mana,
    this.powerType,
    this.strength,
    this.agility,
    this.intellect,
    this.stamina,
    this.criticalStrike,
    this.haste,
    this.mastery,
    this.versatility,
  });

  @override
  List<Object?> get props => [
    health,
    mana,
    powerType,
    strength,
    agility,
    intellect,
    stamina,
    criticalStrike,
    haste,
    mastery,
    versatility,
  ];
}

/// Detailed Mythic+ season profile
class MythicPlusProfile extends Equatable {
  final double scoreAll;
  final double scoreDps;
  final double scoreHealer;
  final double scoreTank;
  final List<MythicPlusRun> bestRuns;

  const MythicPlusProfile({
    required this.scoreAll,
    this.scoreDps = 0,
    this.scoreHealer = 0,
    this.scoreTank = 0,
    this.bestRuns = const [],
  });

  @override
  List<Object?> get props => [scoreAll, bestRuns];
}

/// A single Mythic+ dungeon run
class MythicPlusRun extends Equatable {
  final String dungeon;
  final String shortName;
  final int mythicLevel;
  final Duration completedTime;
  final Duration parTime;
  final int numKeystoneUpgrades; // 0, 1, 2, or 3
  final double score;
  final String? affixes;
  final String? url; // Link to Raider.IO run detail

  const MythicPlusRun({
    required this.dungeon,
    required this.shortName,
    required this.mythicLevel,
    required this.completedTime,
    required this.parTime,
    required this.numKeystoneUpgrades,
    required this.score,
    this.affixes,
    this.url,
  });

  bool get inTime => numKeystoneUpgrades > 0;

  String get formattedTime {
    final minutes = completedTime.inMinutes;
    final seconds = completedTime.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String get upgradeText {
    if (numKeystoneUpgrades <= 0) return 'Depleted';
    return '+$numKeystoneUpgrades';
  }

  @override
  List<Object?> get props => [dungeon, mythicLevel, score];
}

/// Raid progression for a single raid tier
class RaidProgress extends Equatable {
  final String raidName;
  final String slug;
  final String summary;
  final int totalBosses;
  final int normalKilled;
  final int heroicKilled;
  final int mythicKilled;

  const RaidProgress({
    required this.raidName,
    required this.slug,
    required this.summary,
    required this.totalBosses,
    this.normalKilled = 0,
    this.heroicKilled = 0,
    this.mythicKilled = 0,
  });

  /// Highest difficulty with full clear
  String? get highestClear {
    if (mythicKilled >= totalBosses) return 'Mythic';
    if (heroicKilled >= totalBosses) return 'Heroic';
    if (normalKilled >= totalBosses) return 'Normal';
    return null;
  }

  /// Current progress tier (highest difficulty with any kill)
  String get currentTier {
    if (mythicKilled > 0) return 'Mythic';
    if (heroicKilled > 0) return 'Heroic';
    if (normalKilled > 0) return 'Normal';
    return 'N/A';
  }

  /// Pretty name from slug: "nerubar-palace" → "Nerub'ar Palace"
  String get displayName {
    return raidName.isNotEmpty
        ? raidName
        : slug
              .split('-')
              .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
              .join(' ');
  }

  @override
  List<Object?> get props => [slug, summary];
}
