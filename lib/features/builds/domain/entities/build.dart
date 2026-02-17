import 'package:equatable/equatable.dart';
import 'package:wow_companion/features/items/domain/entities/item.dart';

/// Slots estándar de WoW
enum WowSlot {
  head,
  neck,
  shoulder,
  back,
  chest,
  wrist,
  hands,
  waist,
  legs,
  feet,
  finger1,
  finger2,
  trinket1,
  trinket2,
  mainHand,
  offHand;

  String get displayName => switch (this) {
    WowSlot.head => 'Helm',
    WowSlot.neck => 'Neck',
    WowSlot.shoulder => 'Shoulder',
    WowSlot.back => 'Cloak',
    WowSlot.chest => 'Chest',
    WowSlot.wrist => 'Bracers',
    WowSlot.hands => 'Gloves',
    WowSlot.waist => 'Belt',
    WowSlot.legs => 'Legs',
    WowSlot.feet => 'Boots',
    WowSlot.finger1 => 'Ring #1',
    WowSlot.finger2 => 'Ring #2',
    WowSlot.trinket1 => 'Trinket #1',
    WowSlot.trinket2 => 'Trinket #2',
    WowSlot.mainHand => 'Weapon Main-Hand',
    WowSlot.offHand => 'Weapon Off-Hand',
  };

  /// Valor inventoryType que usamos en la API de Blizzard
  String get inventoryType => switch (this) {
    WowSlot.head => 'HEAD',
    WowSlot.neck => 'NECK',
    WowSlot.shoulder => 'SHOULDER',
    WowSlot.back => 'CLOAK',
    WowSlot.chest => 'CHEST',
    WowSlot.wrist => 'WRIST',
    WowSlot.hands => 'HAND',
    WowSlot.waist => 'WAIST',
    WowSlot.legs => 'LEGS',
    WowSlot.feet => 'FEET',
    WowSlot.finger1 => 'FINGER',
    WowSlot.finger2 => 'FINGER',
    WowSlot.trinket1 => 'TRINKET',
    WowSlot.trinket2 => 'TRINKET',
    WowSlot.mainHand => '',
    WowSlot.offHand => '',
  };
}

class BuildSlot extends Equatable {
  final WowSlot slot;
  final Item? item;
  final Item? enchantment;
  final List<Item> gems;
  final bool obtained;
  final bool enchantmentObtained;
  final List<bool> gemsObtained;

  const BuildSlot({
    required this.slot,
    this.item,
    this.enchantment,
    this.gems = const [],
    this.obtained = false,
    this.enchantmentObtained = false,
    this.gemsObtained = const [],
  });

  BuildSlot copyWith({
    Item? item,
    Item? enchantment,
    List<Item>? gems,
    bool? obtained,
    bool? enchantmentObtained,
    List<bool>? gemsObtained,
    bool clearItem = false,
    bool clearEnchantment = false,
  }) {
    return BuildSlot(
      slot: slot,
      item: clearItem ? null : (item ?? this.item),
      enchantment: clearEnchantment ? null : (enchantment ?? this.enchantment),
      gems: gems ?? this.gems,
      obtained: obtained ?? this.obtained,
      enchantmentObtained: clearEnchantment ? false : (enchantmentObtained ?? this.enchantmentObtained),
      gemsObtained: gemsObtained ?? this.gemsObtained,
    );
  }

  Map<String, dynamic> toJson() => {
    'slot': slot.name,
    'item': item != null ? _itemToJson(item!) : null,
    'enchantment': enchantment != null ? _itemToJson(enchantment!) : null,
    'gems': gems.map(_itemToJson).toList(),
    'obtained': obtained,
    'enchantmentObtained': enchantmentObtained,
    'gemsObtained': gemsObtained,
  };

  factory BuildSlot.fromJson(Map<String, dynamic> json) {
    return BuildSlot(
      slot: WowSlot.values.firstWhere((e) => e.name == json['slot']),
      item: json['item'] != null
          ? _itemFromJson(json['item'] as Map<String, dynamic>)
          : null,
      enchantment: json['enchantment'] != null
          ? _itemFromJson(json['enchantment'] as Map<String, dynamic>)
          : null,
      gems: (json['gems'] as List<dynamic>? ?? [])
          .map((e) => _itemFromJson(e as Map<String, dynamic>))
          .toList(),
      obtained: json['obtained'] as bool? ?? false,
      enchantmentObtained: json['enchantmentObtained'] as bool? ?? false,
      gemsObtained: (json['gemsObtained'] as List<dynamic>? ?? [])
          .map((e) => e as bool)
          .toList(),
    );
  }

  @override
  List<Object?> get props => [slot, item, enchantment, gems, obtained, enchantmentObtained, gemsObtained];
}

class Build extends Equatable {
  final String id;
  final String name;

  /// Key del FavoriteCharacter: "eu-sanguino-ganae" o null si es genérica
  final String? characterRefKey;

  /// Nombre para mostrar: "Ganae - Sanguino" o null
  final String? characterRefDisplay;
  final DateTime createdAt;
  final List<BuildSlot> slots;

  const Build({
    required this.id,
    required this.name,
    this.characterRefKey,
    this.characterRefDisplay,
    required this.createdAt,
    required this.slots,
  });

  /// Slots vacíos para una build nueva
  static List<BuildSlot> get emptySlots =>
      WowSlot.values.map((s) => BuildSlot(slot: s)).toList();

  int get totalSlots => slots.length;
  int get obtainedSlots => slots.where((s) => s.obtained).length;
  double get progress => totalSlots == 0 ? 0 : obtainedSlots / totalSlots;

  Build copyWith({
    String? name,
    String? characterRefKey,
    String? characterRefDisplay,
    List<BuildSlot>? slots,
    bool clearCharacterRef = false,
  }) {
    return Build(
      id: id,
      name: name ?? this.name,
      characterRefKey: clearCharacterRef
          ? null
          : (characterRefKey ?? this.characterRefKey),
      characterRefDisplay: clearCharacterRef
          ? null
          : (characterRefDisplay ?? this.characterRefDisplay),
      createdAt: createdAt,
      slots: slots ?? this.slots,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'characterRefKey': characterRefKey,
    'characterRefDisplay': characterRefDisplay,
    'createdAt': createdAt.toIso8601String(),
    'slots': slots.map((s) => s.toJson()).toList(),
  };

  factory Build.fromJson(Map<String, dynamic> json) {
    return Build(
      id: json['id'] as String,
      name: json['name'] as String,
      characterRefKey: json['characterRefKey'] as String?,
      characterRefDisplay: json['characterRefDisplay'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      slots: (json['slots'] as List<dynamic>)
          .map((e) => BuildSlot.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [id, name, characterRefKey, slots];
}

// Helpers de serialización de Item (versión reducida para guardado)
Map<String, dynamic> _itemToJson(Item item) => {
  'id': item.id,
  'name': item.name,
  'quality': item.quality,
  'level': item.level,
  'iconUrl': item.iconUrl,
  'inventoryType': item.inventoryType,
  'inventoryName': item.inventoryName,
};

Item _itemFromJson(Map<String, dynamic> json) => Item(
  id: json['id'] as int,
  name: json['name'] as String,
  quality: json['quality'] as String? ?? 'COMMON',
  level: json['level'] as int?,
  iconUrl: json['iconUrl'] as String?,
  inventoryType: json['inventoryType'] as String?,
  inventoryName: json['inventoryName'] as String?,
);
