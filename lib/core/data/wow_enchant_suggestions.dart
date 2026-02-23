import 'package:wow_companion/features/builds/domain/entities/build.dart';
import 'package:wow_companion/features/builds/domain/entities/spec_recommendation.dart';

/// Sugerencia de encantamiento para un slot concreto.
class EnchantSuggestion {
  final String name;
  final String? note;

  const EnchantSuggestion({required this.name, this.note});
}

/// Convierte WowSlot al string key que usa SpecRecommendation / el Worker.
extension WowSlotKey on WowSlot {
  String get slotKey => switch (this) {
    WowSlot.back     => SlotKeys.back,
    WowSlot.chest    => SlotKeys.chest,
    WowSlot.wrist    => SlotKeys.wrist,
    WowSlot.legs     => SlotKeys.legs,
    WowSlot.feet     => SlotKeys.feet,
    WowSlot.finger1  => SlotKeys.finger1,
    WowSlot.finger2  => SlotKeys.finger2,
    WowSlot.mainHand => SlotKeys.mainHand,
    WowSlot.offHand  => SlotKeys.offHand,
    // Slots sin enchant
    _ => '',
  };

  bool get isEnchantableSlot => slotKey.isNotEmpty;
}

/// Sugerencias genéricas (sin spec) como último fallback.
/// Se usan solo cuando no hay SpecRecommendation disponible.
class WowEnchantSuggestions {
  WowEnchantSuggestions._();

  static const Map<WowSlot, List<EnchantSuggestion>> _data = {
    WowSlot.back: [
      EnchantSuggestion(name: 'Chant of Burrowing Rapidity', note: 'Supervivencia + movilidad'),
      EnchantSuggestion(name: 'Chant of Winged Grace', note: 'Alternativa movilidad'),
    ],
    WowSlot.chest: [
      EnchantSuggestion(name: "Stormrider's Agility", note: 'Agilidad'),
      EnchantSuggestion(name: "Stormrider's Intellect", note: 'Intelecto'),
      EnchantSuggestion(name: "Stormrider's Strength", note: 'Fuerza'),
    ],
    WowSlot.wrist: [
      EnchantSuggestion(name: 'Chant of Armored Speed', note: 'Físicos'),
      EnchantSuggestion(name: 'Chant of Powerful Rituals', note: 'Casters'),
    ],
    WowSlot.legs: [
      EnchantSuggestion(name: 'Stormbound Armor Kit', note: 'Físicos'),
      EnchantSuggestion(name: 'Daybreak Spellthread', note: 'Casters'),
    ],
    WowSlot.feet: [
      EnchantSuggestion(name: "Scout's March", note: 'Movimiento + stats'),
      EnchantSuggestion(name: "Cavalry's March", note: 'Alternativa'),
    ],
    WowSlot.finger1: [
      EnchantSuggestion(name: 'Glimmering Mastery', note: 'Simular para confirmar'),
      EnchantSuggestion(name: 'Radiant Haste'),
      EnchantSuggestion(name: 'Glimmering Critical Strike'),
    ],
    WowSlot.finger2: [
      EnchantSuggestion(name: 'Glimmering Mastery', note: 'Simular para confirmar'),
      EnchantSuggestion(name: 'Radiant Haste'),
      EnchantSuggestion(name: 'Glimmering Critical Strike'),
    ],
    WowSlot.mainHand: [
      EnchantSuggestion(name: 'Authority of Radiant Power', note: 'BiS físicos/Agilidad'),
      EnchantSuggestion(name: 'Authority of Fiery Resolve', note: 'Casters'),
      EnchantSuggestion(name: 'Authority of the Depths', note: 'Tanques'),
    ],
    WowSlot.offHand: [
      EnchantSuggestion(name: 'Authority of Radiant Power', note: 'Si es arma secundaria'),
    ],
  };

  static List<EnchantSuggestion> forSlot(WowSlot slot) => _data[slot] ?? [];
  static EnchantSuggestion? primaryForSlot(WowSlot slot) {
    final list = forSlot(slot);
    return list.isEmpty ? null : list.first;
  }
  static bool isEnchantable(WowSlot slot) => forSlot(slot).isNotEmpty;
}

/// Resuelve sugerencias de enchant para un slot dado una SpecRecommendation opcional.
/// Si hay recomendación de spec → usa esa (Worker/static spec-aware).
/// Si no → usa el fallback genérico de WowEnchantSuggestions.
class EnchantResolver {
  static List<EnchantSuggestion> suggestionsForSlot(
    WowSlot slot, {
    SpecRecommendation? recommendation,
  }) {
    // Spec-aware
    if (recommendation != null) {
      final specItems = recommendation.enchantsForSlot(slot.slotKey);
      if (specItems.isNotEmpty) {
        return specItems
            .map((s) => EnchantSuggestion(name: s.name, note: s.note))
            .toList();
      }
    }
    // Fallback genérico
    return WowEnchantSuggestions.forSlot(slot);
  }

  static EnchantSuggestion? primaryForSlot(
    WowSlot slot, {
    SpecRecommendation? recommendation,
  }) {
    final list = suggestionsForSlot(slot, recommendation: recommendation);
    return list.isEmpty ? null : list.first;
  }

  static bool isEnchantable(
    WowSlot slot, {
    SpecRecommendation? recommendation,
  }) {
    return slot.isEnchantableSlot ||
        suggestionsForSlot(slot, recommendation: recommendation).isNotEmpty;
  }
}
