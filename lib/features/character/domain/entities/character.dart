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
  final String? avatarUrl;
  final List<EquippedItem> equipment;
  final CharacterStats? stats;
  final double? mythicPlusScore;
  final String? raidProgression;

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
    this.equipment = const [],
    this.stats,
    this.mythicPlusScore,
    this.raidProgression,
  });

  String get displayName => '$name - $realm ($region)';
  String get realmSlug => realm.toLowerCase().replaceAll(' ', '-');

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

  const EquippedItem({
    required this.slot,
    required this.name,
    required this.itemLevel,
    required this.quality,
    this.itemId,
    this.iconUrl,
    this.enchantments = const [],
    this.gems = const [],
  });

  @override
  List<Object?> get props => [slot, name, itemLevel];
}

class CharacterStats extends Equatable {
  final int? strength;
  final int? agility;
  final int? intellect;
  final int? stamina;
  final double? criticalStrike;
  final double? haste;
  final double? mastery;
  final double? versatility;

  const CharacterStats({
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
