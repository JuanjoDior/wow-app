import 'package:equatable/equatable.dart';

/// Sugerencia individual (enchant, gema o consumible).
class ItemSuggestion extends Equatable {
  final String name;
  final String? note;
  final bool isPrimary;

  const ItemSuggestion({
    required this.name,
    this.note,
    this.isPrimary = false,
  });

  @override
  List<Object?> get props => [name, note, isPrimary];
}

/// Recomendaciones completas para una clase/spec de WoW.
class SpecRecommendation extends Equatable {
  final String className;
  final String specName;
  final String patch;

  /// Enchants por nombre de slot. Keys: 'back', 'chest', 'wrist', 'legs',
  /// 'feet', 'finger1', 'finger2', 'mainHand', 'offHand'
  final Map<String, List<ItemSuggestion>> enchants;

  /// Gema meta y gema generica
  final ItemSuggestion? metaGem;
  final ItemSuggestion? genericGem;

  /// Consumibles
  final ItemSuggestion? flask;
  final ItemSuggestion? food;
  final ItemSuggestion? potion;
  final ItemSuggestion? weaponEnhancement;

  /// Stats en orden de prioridad
  final List<String> statPriority;

  /// Fuente de los datos
  final RecommendationSource source;

  const SpecRecommendation({
    required this.className,
    required this.specName,
    required this.patch,
    this.enchants = const <String, List<ItemSuggestion>>{},
    this.metaGem,
    this.genericGem,
    this.flask,
    this.food,
    this.potion,
    this.weaponEnhancement,
    this.statPriority = const <String>[],
    this.source = RecommendationSource.remote,
  });

  /// Enchants del slot o lista vacia.
  List<ItemSuggestion> enchantsForSlot(String slotKey) =>
      enchants[slotKey] ?? const <ItemSuggestion>[];

  /// Primer enchant (BiS) del slot o null.
  ItemSuggestion? primaryEnchantForSlot(String slotKey) {
    final list = enchantsForSlot(slotKey);
    return list.isEmpty ? null : list.first;
  }

  @override
  List<Object?> get props => [className, specName, patch];
}

/// Fuente de los datos de recomendacion.
enum RecommendationSource {
  remote,        // Generado por Claude via Worker
  cache,         // Cacheado en el Worker
  workerStatic,  // Static data en el Worker (sin API key)
  local,         // Static fallback local (sin conexion)
}

/// Keys de slot que usa el Worker y los datos estaticos.
/// Mapea desde WowSlot enum al string del JSON.
class SlotKeys {
  SlotKeys._();

  static const String back = 'back';
  static const String chest = 'chest';
  static const String wrist = 'wrist';
  static const String legs = 'legs';
  static const String feet = 'feet';
  static const String finger1 = 'finger1';
  static const String finger2 = 'finger2';
  static const String mainHand = 'mainHand';
  static const String offHand = 'offHand';

  /// Slots enchantables (mismos que el Worker puede devolver)
  static const Set<String> enchantable = {
    back,
    chest,
    wrist,
    legs,
    feet,
    finger1,
    finger2,
    mainHand,
    offHand,
  };
}
