import 'package:equatable/equatable.dart';
import 'package:wow_companion/features/items/domain/entities/item.dart';

// ─── BuildContent ─────────────────────────────────────────────────────────────
enum BuildContent { raid, mythicPlus, both }

// ─── WowSpell ─────────────────────────────────────────────────────────────────
/// Habilidad de WoW para la pizarra de rotación.
class WowSpell extends Equatable {
  final int id;
  final String name;
  final String? iconUrl;

  const WowSpell({required this.id, required this.name, this.iconUrl});

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'iconUrl': iconUrl};

  factory WowSpell.fromJson(Map<String, dynamic> json) => WowSpell(
    id: json['id'] as int,
    name: json['name'] as String,
    iconUrl: json['iconUrl'] as String?,
  );

  @override
  List<Object?> get props => [id, name, iconUrl];
}

// ─── BuildConsumables ─────────────────────────────────────────────────────────
/// Flask, poción y comida recomendados para la build.
class BuildConsumables extends Equatable {
  final Item? flask;
  final Item? potion;
  final Item? food;

  const BuildConsumables({this.flask, this.potion, this.food});

  bool get isEmpty => flask == null && potion == null && food == null;

  BuildConsumables copyWith({
    Item? flask,
    Item? potion,
    Item? food,
    bool clearFlask = false,
    bool clearPotion = false,
    bool clearFood = false,
  }) => BuildConsumables(
    flask: clearFlask ? null : (flask ?? this.flask),
    potion: clearPotion ? null : (potion ?? this.potion),
    food: clearFood ? null : (food ?? this.food),
  );

  Map<String, dynamic> toJson() => {
    'flask': flask?.toJson(),
    'potion': potion?.toJson(),
    'food': food?.toJson(),
  };

  factory BuildConsumables.fromJson(Map<String, dynamic> json) =>
      BuildConsumables(
        flask: json['flask'] != null
            ? Item.fromJson(json['flask'] as Map<String, dynamic>)
            : null,
        potion: json['potion'] != null
            ? Item.fromJson(json['potion'] as Map<String, dynamic>)
            : null,
        food: json['food'] != null
            ? Item.fromJson(json['food'] as Map<String, dynamic>)
            : null,
      );

  @override
  List<Object?> get props => [flask, potion, food];
}

// ─── BuildGuide ───────────────────────────────────────────────────────────────
/// Sección de guía: talentos, rotación, consumibles y notas.
class BuildGuide extends Equatable {
  final BuildContent? content;
  final String? heroTalent;
  final List<WowSpell> rotation;
  final BuildConsumables consumables;
  final String? notes;

  const BuildGuide({
    this.content,
    this.heroTalent,
    this.rotation = const [],
    this.consumables = const BuildConsumables(),
    this.notes,
  });

  bool get isEmpty =>
      content == null &&
      (heroTalent == null || heroTalent!.trim().isEmpty) &&
      rotation.isEmpty &&
      consumables.isEmpty &&
      (notes == null || notes!.trim().isEmpty);

  BuildGuide copyWith({
    BuildContent? content,
    String? heroTalent,
    List<WowSpell>? rotation,
    BuildConsumables? consumables,
    String? notes,
    bool clearContent = false,
    bool clearHeroTalent = false,
    bool clearNotes = false,
  }) => BuildGuide(
    content: clearContent ? null : (content ?? this.content),
    heroTalent: clearHeroTalent ? null : (heroTalent ?? this.heroTalent),
    rotation: rotation ?? this.rotation,
    consumables: consumables ?? this.consumables,
    notes: clearNotes ? null : (notes ?? this.notes),
  );

  Map<String, dynamic> toJson() => {
    'content': content?.name,
    'heroTalent': heroTalent,
    'rotation': rotation.map((s) => s.toJson()).toList(),
    'consumables': consumables.toJson(),
    'notes': notes,
  };

  factory BuildGuide.fromJson(Map<String, dynamic> json) => BuildGuide(
    content: json['content'] != null
        ? BuildContent.values.firstWhere(
            (e) => e.name == json['content'],
            orElse: () => BuildContent.both,
          )
        : null,
    heroTalent: json['heroTalent'] as String?,
    rotation: (json['rotation'] as List<dynamic>? ?? [])
        .map((e) => WowSpell.fromJson(e as Map<String, dynamic>))
        .toList(),
    consumables: json['consumables'] != null
        ? BuildConsumables.fromJson(json['consumables'] as Map<String, dynamic>)
        : const BuildConsumables(),
    notes: json['notes'] as String?,
  );

  @override
  List<Object?> get props => [
    content,
    heroTalent,
    rotation,
    consumables,
    notes,
  ];
}

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
      enchantmentObtained: clearEnchantment
          ? false
          : (enchantmentObtained ?? this.enchantmentObtained),
      gemsObtained: gemsObtained ?? this.gemsObtained,
    );
  }

  Map<String, dynamic> toJson() => {
    'slot': slot.name,
    'item': item?.toJson(),
    'enchantment': enchantment?.toJson(),
    'gems': gems.map((g) => g.toJson()).toList(),
    'obtained': obtained,
    'enchantmentObtained': enchantmentObtained,
    'gemsObtained': gemsObtained,
  };

  factory BuildSlot.fromJson(Map<String, dynamic> json) {
    return BuildSlot(
      slot: WowSlot.values.firstWhere((e) => e.name == json['slot']),
      item: json['item'] != null
          ? Item.fromJson(json['item'] as Map<String, dynamic>)
          : null,
      enchantment: json['enchantment'] != null
          ? Item.fromJson(json['enchantment'] as Map<String, dynamic>)
          : null,
      gems: (json['gems'] as List<dynamic>? ?? [])
          .map((e) => Item.fromJson(e as Map<String, dynamic>))
          .toList(),
      obtained: json['obtained'] as bool? ?? false,
      enchantmentObtained: json['enchantmentObtained'] as bool? ?? false,
      gemsObtained: (json['gemsObtained'] as List<dynamic>? ?? [])
          .map((e) => e as bool)
          .toList(),
    );
  }

  @override
  List<Object?> get props => [
    slot,
    item,
    enchantment,
    gems,
    obtained,
    enchantmentObtained,
    gemsObtained,
  ];
}

class Build extends Equatable {
  final String id;
  final String name;

  /// Key del FavoriteCharacter: "eu-sanguino-ganae" o null si es genérica
  final String? characterRefKey;

  /// Nombre para mostrar: "Ganae - Sanguino" o null
  final String? characterRefDisplay;
  final String? characterClass;
  final String? characterSpec;
  final String? characterRace;
  final String? characterAvatarUrl;
  final DateTime createdAt;
  final List<BuildSlot> slots;

  /// Guía opcional: talentos, rotación, consumibles y notas
  final BuildGuide guide;

  const Build({
    required this.id,
    required this.name,
    this.characterRefKey,
    this.characterRefDisplay,
    this.characterClass,
    this.characterSpec,
    this.characterRace,
    this.characterAvatarUrl,
    required this.createdAt,
    required this.slots,
    this.guide = const BuildGuide(),
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
    String? characterAvatarUrl,
    List<BuildSlot>? slots,
    BuildGuide? guide,
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
      characterClass: clearCharacterRef ? null : characterClass,
      characterSpec: clearCharacterRef ? null : characterSpec,
      characterRace: clearCharacterRef ? null : characterRace,
      characterAvatarUrl: clearCharacterRef
          ? null
          : (characterAvatarUrl ?? this.characterAvatarUrl),
      createdAt: createdAt,
      slots: slots ?? this.slots,
      guide: guide ?? this.guide,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'characterRefKey': characterRefKey,
    'characterRefDisplay': characterRefDisplay,
    'characterClass': characterClass,
    'characterSpec': characterSpec,
    'characterRace': characterRace,
    'characterAvatarUrl': characterAvatarUrl,
    'createdAt': createdAt.toIso8601String(),
    'slots': slots.map((s) => s.toJson()).toList(),
    'guide': guide.toJson(),
  };

  factory Build.fromJson(Map<String, dynamic> json) {
    return Build(
      id: json['id'] as String,
      name: json['name'] as String,
      characterRefKey: json['characterRefKey'] as String?,
      characterRefDisplay: json['characterRefDisplay'] as String?,
      characterClass: json['characterClass'] as String?,
      characterSpec: json['characterSpec'] as String?,
      characterRace: json['characterRace'] as String?,
      characterAvatarUrl: json['characterAvatarUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      slots: (json['slots'] as List<dynamic>)
          .map((e) => BuildSlot.fromJson(e as Map<String, dynamic>))
          .toList(),
      // Backward compatible: builds antiguas sin 'guide' cargan con guía vacía
      guide: json['guide'] != null
          ? BuildGuide.fromJson(json['guide'] as Map<String, dynamic>)
          : const BuildGuide(),
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    characterRefKey,
    characterRefDisplay,
    characterClass,
    characterSpec,
    characterRace,
    characterAvatarUrl,
    createdAt,
    slots,
    guide,
  ];
}
