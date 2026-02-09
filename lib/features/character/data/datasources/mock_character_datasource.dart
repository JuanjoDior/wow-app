import 'package:wow_companion/features/character/domain/entities/character.dart';

class MockCharacterDataSource {
  Future<Character> getCharacter({
    required String region,
    required String realm,
    required String name,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));

    if (name.toLowerCase() == 'notfound') {
      throw Exception('Character not found');
    }

    final classData = _classForName(name);

    return Character(
      name: _capitalize(name),
      realm: _capitalize(realm),
      region: region.toUpperCase(),
      level: 80,
      race: classData['race'] as String,
      characterClass: classData['class'] as String,
      specialization: classData['spec'] as String,
      guild: 'Method',
      achievementPoints: 28450,
      averageItemLevel: 626,
      equippedItemLevel: 624,
      equipment: _mockEquipment(),
      stats: const CharacterStats(
        strength: 42850,
        agility: 3200,
        intellect: 3400,
        stamina: 185600,
        criticalStrike: 28.45,
        haste: 18.32,
        mastery: 45.67,
        versatility: 8.12,
      ),
    );
  }

  Future<List<Character>> searchCharacters({
    required String query,
    String region = 'eu',
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (query.isEmpty) return [];

    return [
      Character(
        name: '${_capitalize(query)}pala',
        realm: 'Sargeras',
        region: region.toUpperCase(),
        level: 80,
        race: 'Human',
        characterClass: 'Paladin',
        specialization: 'Holy',
      ),
      Character(
        name: '${_capitalize(query)}lock',
        realm: 'Illidan',
        region: region.toUpperCase(),
        level: 80,
        race: 'Undead',
        characterClass: 'Warlock',
        specialization: 'Affliction',
      ),
      Character(
        name: '${_capitalize(query)}dk',
        realm: 'Ragnaros',
        region: region.toUpperCase(),
        level: 80,
        race: 'Orc',
        characterClass: 'Death Knight',
        specialization: 'Unholy',
      ),
    ];
  }

  List<EquippedItem> _mockEquipment() {
    return const [
      EquippedItem(
        slot: 'HEAD',
        name: 'Heartfire Sentinel\'s Forgehelm',
        itemLevel: 626,
        quality: 'EPIC',
        itemId: 212038,
      ),
      EquippedItem(
        slot: 'NECK',
        name: 'Sureki Zealot\'s Insignia',
        itemLevel: 619,
        quality: 'EPIC',
        itemId: 225577,
      ),
      EquippedItem(
        slot: 'SHOULDER',
        name: 'Heartfire Sentinel\'s Steelwings',
        itemLevel: 626,
        quality: 'EPIC',
        itemId: 212036,
        enchantments: ['Enchant: +Crit'],
      ),
      EquippedItem(
        slot: 'CHEST',
        name: 'Heartfire Sentinel\'s Brigandine',
        itemLevel: 626,
        quality: 'EPIC',
        itemId: 212041,
        enchantments: ['Crystalline Radiance'],
      ),
      EquippedItem(
        slot: 'WAIST',
        name: 'Binding of Searing Tenacity',
        itemLevel: 619,
        quality: 'EPIC',
        itemId: 225583,
      ),
      EquippedItem(
        slot: 'LEGS',
        name: 'Heartfire Sentinel\'s Faulds',
        itemLevel: 626,
        quality: 'EPIC',
        itemId: 212039,
      ),
      EquippedItem(
        slot: 'FEET',
        name: 'Boots of the Undying Pyre',
        itemLevel: 619,
        quality: 'EPIC',
        itemId: 225581,
      ),
      EquippedItem(
        slot: 'WRIST',
        name: 'Wristguards of the Nerubian',
        itemLevel: 619,
        quality: 'EPIC',
        itemId: 225578,
      ),
      EquippedItem(
        slot: 'HANDS',
        name: 'Heartfire Sentinel\'s Gauntlets',
        itemLevel: 626,
        quality: 'EPIC',
        itemId: 212040,
      ),
      EquippedItem(
        slot: 'BACK',
        name: 'Drape of the Cinderbee',
        itemLevel: 619,
        quality: 'EPIC',
        itemId: 225582,
        enchantments: ['Enchant: Avoidance'],
      ),
      EquippedItem(
        slot: 'MAIN_HAND',
        name: 'Void Reaper\'s Warblade',
        itemLevel: 626,
        quality: 'EPIC',
        itemId: 178829,
        enchantments: ['Authority of Radiant Power'],
      ),
      EquippedItem(
        slot: 'FINGER_1',
        name: 'Seal of the Poisoned Pact',
        itemLevel: 619,
        quality: 'EPIC',
        itemId: 225576,
        gems: ['Deadly Onyx'],
      ),
      EquippedItem(
        slot: 'FINGER_2',
        name: 'Ring of Earthen Resolve',
        itemLevel: 626,
        quality: 'EPIC',
        itemId: 225575,
        gems: ['Masterful Ruby'],
      ),
      EquippedItem(
        slot: 'TRINKET_1',
        name: 'Skardyn\'s Grace',
        itemLevel: 619,
        quality: 'EPIC',
        itemId: 133282,
      ),
      EquippedItem(
        slot: 'TRINKET_2',
        name: 'Treacherous Transmitter',
        itemLevel: 626,
        quality: 'EPIC',
        itemId: 221023,
      ),
    ];
  }

  Map<String, String> _classForName(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('dk')) {
      return {'class': 'Death Knight', 'spec': 'Unholy', 'race': 'Orc'};
    }
    if (lower.contains('lock')) {
      return {'class': 'Warlock', 'spec': 'Affliction', 'race': 'Undead'};
    }
    if (lower.contains('mage')) {
      return {'class': 'Mage', 'spec': 'Frost', 'race': 'Human'};
    }
    if (lower.contains('druid')) {
      return {'class': 'Druid', 'spec': 'Balance', 'race': 'Night Elf'};
    }
    return {'class': 'Paladin', 'spec': 'Retribution', 'race': 'Blood Elf'};
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }
}
