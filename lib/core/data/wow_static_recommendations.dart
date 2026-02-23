import 'package:wow_companion/features/builds/domain/entities/spec_recommendation.dart';

/// Base de datos estática de recomendaciones por clase/spec.
///
/// Espejo exacto del documento wow_clases_specs_midnight.md
/// Funciona como fallback offline y como caché instantánea en primer render.
///
/// FUENTE: Icy Veins — Midnight Pre-Patch 12.0.1 — Febrero 2026
/// Cubre TODAS las 40 especializaciones del juego.
///
/// MANTENIMIENTO: actualizar Worker (index.js STATIC_DATA) Y este archivo
/// de forma simultánea al inicio de cada temporada (~2-3 veces/año).
/// Última revisión: Pre-patch Midnight 12.0.1 — Febrero 2026
class WowStaticRecommendations {
  WowStaticRecommendations._();

  static SpecRecommendation? forSpec(String className, String specName) {
    final key = '${className.toLowerCase()}:${specName.toLowerCase()}';
    return _data[key];
  }

  /// Returns all available spec keys (for validation/listing).
  static List<String> get availableKeys => _data.keys.toList();

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS — enchant templates reutilizables
  // ═══════════════════════════════════════════════════════════════════════════

  /// Enchants comunes para DPS/Tank FÍSICO (Strength)
  static Map<String, List<ItemSuggestion>> _strengthEnchants({
    required String ringEnchant1,
    String? ringEnchant2,
    String? ringNote1,
    String? ringNote2,
    String weaponEnchant = 'Authority of Radiant Power',
    String? weaponNote,
    String? offHandEnchant,
    String? offHandNote,
  }) => {
    SlotKeys.back: [
      const ItemSuggestion(name: 'Chant of Burrowing Rapidity', isPrimary: true, note: 'Survivability + movement'),
    ],
    SlotKeys.chest: [
      const ItemSuggestion(name: "Stormrider's Strength", isPrimary: true, note: 'BiS Strength'),
    ],
    SlotKeys.wrist: [
      const ItemSuggestion(name: 'Chant of Armored Speed', isPrimary: true, note: 'BiS physical'),
      const ItemSuggestion(name: 'Chant of Armored Leech', note: 'Sustain alternative'),
    ],
    SlotKeys.legs: [
      const ItemSuggestion(name: 'Stormbound Armor Kit', isPrimary: true, note: 'BiS physical'),
      const ItemSuggestion(name: 'Dual-Layered Armor Kit', note: 'Budget alternative'),
    ],
    SlotKeys.feet: [
      const ItemSuggestion(name: "Scout's March", isPrimary: true, note: 'Movement + stats'),
      const ItemSuggestion(name: "Defender's March", note: 'Tank alternative'),
    ],
    SlotKeys.finger1: [
      ItemSuggestion(name: ringEnchant1, isPrimary: true, note: ringNote1),
      if (ringEnchant2 != null)
        ItemSuggestion(name: ringEnchant2, note: ringNote2),
    ],
    SlotKeys.finger2: [
      ItemSuggestion(name: ringEnchant1, isPrimary: true, note: ringNote1),
      if (ringEnchant2 != null)
        ItemSuggestion(name: ringEnchant2, note: ringNote2),
    ],
    SlotKeys.mainHand: [
      ItemSuggestion(name: weaponEnchant, isPrimary: true, note: weaponNote ?? 'BiS physical'),
    ],
    SlotKeys.offHand: [
      if (offHandEnchant != null)
        ItemSuggestion(name: offHandEnchant, isPrimary: true, note: offHandNote),
    ],
  };

  /// Enchants comunes para DPS/Tank FÍSICO (Agility)
  static Map<String, List<ItemSuggestion>> _agilityEnchants({
    required String ringEnchant1,
    String? ringEnchant2,
    String? ringNote1,
    String? ringNote2,
    String weaponEnchant = 'Authority of Radiant Power',
    String? weaponNote,
  }) => {
    SlotKeys.back: [
      const ItemSuggestion(name: 'Chant of Burrowing Rapidity', isPrimary: true, note: 'Survivability + movement'),
    ],
    SlotKeys.chest: [
      const ItemSuggestion(name: "Stormrider's Agility", isPrimary: true, note: 'BiS Agility'),
    ],
    SlotKeys.wrist: [
      const ItemSuggestion(name: 'Chant of Armored Speed', isPrimary: true, note: 'BiS physical'),
      const ItemSuggestion(name: 'Chant of Armored Leech', note: 'Sustain alternative'),
    ],
    SlotKeys.legs: [
      const ItemSuggestion(name: 'Stormbound Armor Kit', isPrimary: true, note: 'BiS physical'),
      const ItemSuggestion(name: 'Dual-Layered Armor Kit', note: 'Budget alternative'),
    ],
    SlotKeys.feet: [
      const ItemSuggestion(name: "Scout's March", isPrimary: true, note: 'Movement + stats'),
      const ItemSuggestion(name: "Defender's March", note: 'Tank alternative'),
    ],
    SlotKeys.finger1: [
      ItemSuggestion(name: ringEnchant1, isPrimary: true, note: ringNote1),
      if (ringEnchant2 != null)
        ItemSuggestion(name: ringEnchant2, note: ringNote2),
    ],
    SlotKeys.finger2: [
      ItemSuggestion(name: ringEnchant1, isPrimary: true, note: ringNote1),
      if (ringEnchant2 != null)
        ItemSuggestion(name: ringEnchant2, note: ringNote2),
    ],
    SlotKeys.mainHand: [
      ItemSuggestion(name: weaponEnchant, isPrimary: true, note: weaponNote ?? 'BiS physical'),
    ],
    SlotKeys.offHand: const [],
  };

  /// Enchants comunes para CASTER (Intellect)
  static Map<String, List<ItemSuggestion>> _intellectEnchants({
    required String ringEnchant1,
    String? ringEnchant2,
    String? ringNote1,
    String? ringNote2,
  }) => {
    SlotKeys.back: [
      const ItemSuggestion(name: 'Chant of Burrowing Rapidity', isPrimary: true, note: 'Survivability + movement'),
      const ItemSuggestion(name: 'Chant of Leeching Fangs', note: 'Sustain alternative'),
    ],
    SlotKeys.chest: [
      const ItemSuggestion(name: "Stormrider's Intellect", isPrimary: true, note: 'BiS Intellect'),
    ],
    SlotKeys.wrist: [
      const ItemSuggestion(name: 'Chant of Powerful Rituals', isPrimary: true, note: 'BiS caster'),
      const ItemSuggestion(name: 'Chant of Armored Leech', note: 'Sustain alternative'),
    ],
    SlotKeys.legs: [
      const ItemSuggestion(name: 'Daybreak Spellthread', isPrimary: true, note: 'BiS caster'),
    ],
    SlotKeys.feet: [
      const ItemSuggestion(name: "Scout's March", isPrimary: true, note: 'Movement + stats'),
      const ItemSuggestion(name: "Defender's March", note: 'Defensive alternative'),
    ],
    SlotKeys.finger1: [
      ItemSuggestion(name: ringEnchant1, isPrimary: true, note: ringNote1),
      if (ringEnchant2 != null)
        ItemSuggestion(name: ringEnchant2, note: ringNote2),
    ],
    SlotKeys.finger2: [
      ItemSuggestion(name: ringEnchant1, isPrimary: true, note: ringNote1),
      if (ringEnchant2 != null)
        ItemSuggestion(name: ringEnchant2, note: ringNote2),
    ],
    SlotKeys.mainHand: [
      const ItemSuggestion(name: 'Authority of Fiery Resolve', isPrimary: true, note: 'BiS caster'),
    ],
    SlotKeys.offHand: const [],
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // DATA — 40 especializaciones
  // ═══════════════════════════════════════════════════════════════════════════

  static final Map<String, SpecRecommendation> _data = {
    // ═════════════════════════════════════════════════════════════════════════
    // DEATH KNIGHT
    // ═════════════════════════════════════════════════════════════════════════

    // ── Blood — Tank · Tier A ────────────────────────────────────────────
    // Deathbringer: ilvl > Crit/Vers/Mastery > Haste
    // San'layn: ilvl > Haste > Crit/Vers/Mastery
    'death knight:blood': SpecRecommendation(
      className: 'death knight',
      specName: 'blood',
      patch: '12.0.1',
      source: RecommendationSource.local,
      statPriority: ['Strength', 'Critical Strike', 'Versatility', 'Mastery', 'Haste'],
      enchants: _strengthEnchants(
        ringEnchant1: 'Glimmering Critical Strike',
        ringNote1: 'Deathbringer BiS',
        ringEnchant2: 'Radiant Haste',
        ringNote2: "San'layn alternative",
        weaponEnchant: 'Authority of the Depths',
        weaponNote: 'BiS tank',
      ),
      metaGem: const ItemSuggestion(name: 'Culminating Blasphemite', isPrimary: true, note: 'Damage; o Elusive para movimiento'),
      genericGem: const ItemSuggestion(name: 'Deadly Emerald', isPrimary: true, note: 'Min 1 de cada color para Blasphemite; sim'),
      flask: const ItemSuggestion(name: 'Flask of Alchemical Chaos', isPrimary: true, note: 'O Flask of Tempered Versatility para mitigación'),
      food: const ItemSuggestion(name: 'Feast of the Midnight Masquerade', isPrimary: true, note: 'O Feast of the Divine Day; individual: The Sushi Special, Everything Stew'),
      potion: const ItemSuggestion(name: 'Tempered Potion', isPrimary: true, note: 'Damage; Invigorating Healing Potion para curación'),
      weaponEnhancement: const ItemSuggestion(name: 'Algari Mana Oil', isPrimary: true, note: 'O Ironclaw Whetstone'),
    ),

    // ── Frost — DPS Melee ────────────────────────────────────────────────
    // Crit > Mastery ≈ Haste > Versatility
    // Rider prioriza más Haste; Deathbringer prioriza Crit/Mastery
    'death knight:frost': SpecRecommendation(
      className: 'death knight',
      specName: 'frost',
      patch: '12.0.1',
      source: RecommendationSource.local,
      statPriority: ['Strength', 'Critical Strike', 'Mastery', 'Haste', 'Versatility'],
      enchants: _strengthEnchants(
        ringEnchant1: 'Glimmering Critical Strike',
        ringNote1: 'BiS general',
        ringEnchant2: 'Radiant Haste',
        ringNote2: 'Rider of the Apocalypse alt',
      ),
      metaGem: const ItemSuggestion(name: 'Culminating Blasphemite', isPrimary: true, note: 'Meta BiS'),
      genericGem: const ItemSuggestion(name: 'Deadly Emerald', isPrimary: true, note: 'Sim — Crit o Quick (Haste) según build'),
      flask: const ItemSuggestion(name: 'Flask of Alchemical Chaos', isPrimary: true, note: 'Recommended'),
      food: const ItemSuggestion(name: 'Feast of the Midnight Masquerade', isPrimary: true, note: "Individual: Outsider's Provisions, Beledar's Bounty"),
      potion: const ItemSuggestion(name: 'Tempered Potion', isPrimary: true, note: 'With CDs + Bloodlust'),
      weaponEnhancement: const ItemSuggestion(name: 'Ironclaw Whetstone', isPrimary: true, note: 'Runeforge: Fallen Crusader (2H) / Razorice + FC (DW)'),
    ),

    // ── Unholy — DPS Melee ───────────────────────────────────────────────
    // Mastery > Crit > Haste > Versatility
    'death knight:unholy': SpecRecommendation(
      className: 'death knight',
      specName: 'unholy',
      patch: '12.0.1',
      source: RecommendationSource.local,
      statPriority: ['Strength', 'Mastery', 'Critical Strike', 'Haste', 'Versatility'],
      enchants: _strengthEnchants(
        ringEnchant1: 'Glimmering Mastery',
        ringNote1: 'BiS',
        ringEnchant2: 'Glimmering Critical Strike',
        ringNote2: 'Alternative',
      ),
      metaGem: const ItemSuggestion(name: 'Culminating Blasphemite', isPrimary: true, note: 'Meta BiS'),
      genericGem: const ItemSuggestion(name: 'Masterful Emerald', isPrimary: true, note: 'Sim — Masterful y Deadly'),
      flask: const ItemSuggestion(name: 'Flask of Alchemical Chaos', isPrimary: true, note: 'Recommended'),
      food: const ItemSuggestion(name: 'Feast of the Midnight Masquerade', isPrimary: true, note: "Individual: Outsider's Provisions"),
      potion: const ItemSuggestion(name: 'Tempered Potion', isPrimary: true, note: 'With CDs + Bloodlust'),
      weaponEnhancement: const ItemSuggestion(name: 'Ironclaw Whetstone', isPrimary: true, note: 'Runeforge: Rune of the Fallen Crusader'),
    ),

    // ═════════════════════════════════════════════════════════════════════════
    // DEMON HUNTER
    // ═════════════════════════════════════════════════════════════════════════

    // ── Devourer — DPS Ranged/Híbrido · ¡NUEVA SPEC! ────────────────────
    // Annihilator: Haste > Mastery > Crit > Vers (ST); Mastery > Haste AoE
    // Void-Scarred: Mastery > Haste > Crit > Vers
    'demon hunter:devourer': SpecRecommendation(
      className: 'demon hunter',
      specName: 'devourer',
      patch: '12.0.1',
      source: RecommendationSource.local,
      statPriority: ['Intellect', 'Haste', 'Mastery', 'Critical Strike', 'Versatility'],
      enchants: _intellectEnchants(
        ringEnchant1: 'Radiant Haste',
        ringNote1: 'Annihilator BiS',
        ringEnchant2: 'Glimmering Mastery',
        ringNote2: 'Void-Scarred / AoE alt',
      ),
      metaGem: const ItemSuggestion(name: 'Culminating Blasphemite', isPrimary: true, note: 'Meta BiS'),
      genericGem: const ItemSuggestion(name: 'Quick Ruby', isPrimary: true, note: 'Sim — Quick/Masterful según build'),
      flask: const ItemSuggestion(name: 'Flask of Alchemical Chaos', isPrimary: true, note: 'Recommended'),
      food: const ItemSuggestion(name: 'Feast of the Midnight Masquerade', isPrimary: true, note: "Individual: Outsider's Provisions, Beledar's Bounty"),
      potion: const ItemSuggestion(name: 'Tempered Potion', isPrimary: true, note: 'With CDs'),
      weaponEnhancement: const ItemSuggestion(name: 'Algari Mana Oil', isPrimary: true, note: 'Caster spec — uses INT warglaives'),
    ),

    // ── Havoc — DPS Melee ────────────────────────────────────────────────
    // Crit > Mastery > Haste > Versatility
    'demon hunter:havoc': SpecRecommendation(
      className: 'demon hunter',
      specName: 'havoc',
      patch: '12.0.1',
      source: RecommendationSource.local,
      statPriority: ['Agility', 'Critical Strike', 'Mastery', 'Haste', 'Versatility'],
      enchants: _agilityEnchants(
        ringEnchant1: 'Glimmering Critical Strike',
        ringNote1: 'BiS — Know Your Enemy scaling',
        ringEnchant2: 'Glimmering Mastery',
        ringNote2: 'Mastery amplifica Chaos damage',
      ),
      metaGem: const ItemSuggestion(name: 'Culminating Blasphemite', isPrimary: true, note: 'Meta BiS'),
      genericGem: const ItemSuggestion(name: 'Deadly Emerald', isPrimary: true, note: 'Crit gems; sim resto'),
      flask: const ItemSuggestion(name: 'Flask of Alchemical Chaos', isPrimary: true, note: 'Recommended'),
      food: const ItemSuggestion(name: 'Feast of the Midnight Masquerade', isPrimary: true, note: 'Individual según stat secundaria'),
      potion: const ItemSuggestion(name: 'Tempered Potion', isPrimary: true, note: 'With CDs + Bloodlust'),
      weaponEnhancement: const ItemSuggestion(name: 'Oil of Deep Toxins', isPrimary: true, note: 'O Ironclaw Whetstone'),
    ),

    // ── Vengeance — Tank · Tier A ────────────────────────────────────────
    // Agility > Haste > Versatility/Crit > Mastery
    'demon hunter:vengeance': SpecRecommendation(
      className: 'demon hunter',
      specName: 'vengeance',
      patch: '12.0.1',
      source: RecommendationSource.local,
      statPriority: ['Agility', 'Haste', 'Versatility', 'Critical Strike', 'Mastery'],
      enchants: _agilityEnchants(
        ringEnchant1: 'Radiant Haste',
        ringNote1: 'BiS',
        ringEnchant2: 'Glimmering Critical Strike',
        ringNote2: 'Alternative',
        weaponEnchant: 'Authority of the Depths',
        weaponNote: 'BiS tank',
      ),
      metaGem: const ItemSuggestion(name: 'Elusive Blasphemite', isPrimary: true, note: 'Movement speed BiS; o Culminating para daño'),
      genericGem: const ItemSuggestion(name: 'Deadly Emerald', isPrimary: true, note: 'Mix Quick Ruby/Onyx/Sapphire para activar bonus'),
      flask: const ItemSuggestion(name: 'Flask of Alchemical Chaos', isPrimary: true, note: 'O Flask of Tempered Swiftness'),
      food: const ItemSuggestion(name: "Beledar's Bounty", isPrimary: true, note: "Outsider's Provisions, Jester's Board, The Sushi Special"),
      potion: const ItemSuggestion(name: 'Tempered Potion', isPrimary: true, note: 'Damage; Invigorating Healing Potion para curación'),
      weaponEnhancement: const ItemSuggestion(name: 'Oil of Deep Toxins', isPrimary: true, note: 'O Ironclaw Whetstone / Algari Mana Oil'),
    ),

    // ═════════════════════════════════════════════════════════════════════════
    // DRUID
    // ═════════════════════════════════════════════════════════════════════════

    // ── Balance — DPS Ranged ─────────────────────────────────────────────
    // Haste > Mastery ≈ Crit > Versatility (varía mucho)
    'druid:balance': SpecRecommendation(
      className: 'druid',
      specName: 'balance',
      patch: '12.0.1',
      source: RecommendationSource.local,
      statPriority: ['Intellect', 'Haste', 'Mastery', 'Critical Strike', 'Versatility'],
      enchants: _intellectEnchants(
        ringEnchant1: 'Radiant Haste',
        ringNote1: 'BiS; sim to confirm',
        ringEnchant2: 'Glimmering Critical Strike',
        ringNote2: 'Alternative',
      ),
      metaGem: const ItemSuggestion(name: 'Culminating Blasphemite', isPrimary: true, note: 'Meta BiS'),
      genericGem: const ItemSuggestion(name: 'Quick Ruby', isPrimary: true, note: 'Sim — 1 de cada color + rellenar'),
      flask: const ItemSuggestion(name: 'Flask of Alchemical Chaos', isPrimary: true, note: 'Recommended'),
      food: const ItemSuggestion(name: 'Feast of the Midnight Masquerade', isPrimary: true, note: 'Group feast'),
      potion: const ItemSuggestion(name: 'Tempered Potion', isPrimary: true, note: 'With major CDs'),
      weaponEnhancement: const ItemSuggestion(name: 'Algari Mana Oil', isPrimary: true, note: 'Crit + Haste bonus'),
    ),

    // ── Feral — DPS Melee ────────────────────────────────────────────────
    // Crit ≈ Mastery > Haste > Versatility
    'druid:feral': SpecRecommendation(
      className: 'druid',
      specName: 'feral',
      patch: '12.0.1',
      source: RecommendationSource.local,
      statPriority: ['Agility', 'Critical Strike', 'Mastery', 'Haste', 'Versatility'],
      enchants: _agilityEnchants(
        ringEnchant1: 'Glimmering Critical Strike',
        ringNote1: 'Sim to confirm; Crit/Mastery close',
        ringEnchant2: 'Glimmering Mastery',
        ringNote2: 'Razor Claws amplifica bleeds',
      ),
      metaGem: const ItemSuggestion(name: 'Culminating Blasphemite', isPrimary: true, note: 'Meta BiS'),
      genericGem: const ItemSuggestion(name: 'Deadly Emerald', isPrimary: true, note: 'Sim — Deadly/Masterful según prioridad'),
      flask: const ItemSuggestion(name: 'Flask of Alchemical Chaos', isPrimary: true, note: 'More RNG, net positive'),
      food: const ItemSuggestion(name: 'Feast of the Midnight Masquerade', isPrimary: true, note: 'Group feast (Agility)'),
      potion: const ItemSuggestion(name: 'Tempered Potion', isPrimary: true, note: 'With CDs + Bloodlust'),
      weaponEnhancement: const ItemSuggestion(name: 'Oil of Deep Toxins', isPrimary: true, note: 'O Ironclaw Whetstone'),
    ),

    // ── Guardian — Tank · Tier A ─────────────────────────────────────────
    // Supervivencia: ilvl > Armor/Agi/Vida > Haste > Vers > Mastery > Crit
    // Daño: Haste > Vers ≈ Crit ≈ Mastery
    'druid:guardian': SpecRecommendation(
      className: 'druid',
      specName: 'guardian',
      patch: '12.0.1',
      source: RecommendationSource.local,
      statPriority: ['Agility', 'Haste', 'Versatility', 'Mastery', 'Critical Strike'],
      enchants: _agilityEnchants(
        ringEnchant1: 'Radiant Haste',
        ringNote1: 'BiS survival',
        ringEnchant2: 'Glimmering Critical Strike',
        ringNote2: 'Damage alt',
        weaponEnchant: 'Authority of the Depths',
        weaponNote: 'BiS tank',
      ),
      metaGem: const ItemSuggestion(name: 'Culminating Blasphemite', isPrimary: true, note: 'Meta BiS'),
      genericGem: const ItemSuggestion(name: 'Quick Ruby', isPrimary: true, note: 'Quick Ruby/Onyx/Sapphire, Deadly Emerald; resto Versatile Emerald'),
      flask: const ItemSuggestion(name: 'Flask of Alchemical Chaos', isPrimary: true, note: 'Always keep active'),
      food: const ItemSuggestion(name: 'Feast of the Divine Day', isPrimary: true, note: "O Midnight Masquerade; individual: Stuffed Cave Peppers, Outsider's Provisions"),
      potion: const ItemSuggestion(name: 'Tempered Potion', isPrimary: true, note: 'Damage; Invigorating Healing Potion para curación'),
      weaponEnhancement: const ItemSuggestion(name: 'Ironclaw Whetstone', isPrimary: true, note: 'Physical DPS boost'),
    ),

    // ── Restoration — Healer · Tier S ────────────────────────────────────
    // Raids: Haste = Mastery > Vers > Crit
    // M+: Mastery = Haste > Vers > Crit
    'druid:restoration': SpecRecommendation(
      className: 'druid',
      specName: 'restoration',
      patch: '12.0.1',
      source: RecommendationSource.local,
      statPriority: ['Intellect', 'Haste', 'Mastery', 'Versatility', 'Critical Strike'],
      enchants: _intellectEnchants(
        ringEnchant1: 'Radiant Haste',
        ringNote1: 'Raid BiS',
        ringEnchant2: 'Glimmering Mastery',
        ringNote2: 'M+ alt',
      ),
      metaGem: const ItemSuggestion(name: 'Elusive Blasphemite', isPrimary: true, note: 'Movement speed BiS'),
      genericGem: const ItemSuggestion(name: 'Masterful Emerald', isPrimary: true, note: 'Quick Onyx, Quick Sapphire; resto Masterful Emerald'),
      flask: const ItemSuggestion(name: 'Flask of Tempered Swiftness', isPrimary: true, note: 'O Flask of Tempered Mastery'),
      food: const ItemSuggestion(name: "Beledar's Bounty", isPrimary: true, note: 'Festines cuando disponibles'),
      potion: const ItemSuggestion(name: 'Algari Mana Potion', isPrimary: true, note: 'Maná; Tempered Potion para stats'),
      weaponEnhancement: const ItemSuggestion(name: 'Algari Mana Oil', isPrimary: true, note: 'Crit + Haste'),
    ),

    // ═════════════════════════════════════════════════════════════════════════
    // EVOKER
    // ═════════════════════════════════════════════════════════════════════════

    // ── Augmentation — DPS Support ───────────────────────────────────────
    // Haste > Mastery > Crit > Versatility
    'evoker:augmentation': SpecRecommendation(
      className: 'evoker',
      specName: 'augmentation',
      patch: '12.0.1',
      source: RecommendationSource.local,
      statPriority: ['Intellect', 'Haste', 'Mastery', 'Critical Strike', 'Versatility'],
      enchants: _intellectEnchants(
        ringEnchant1: 'Radiant Haste',
        ringNote1: 'BiS',
        ringEnchant2: 'Glimmering Mastery',
        ringNote2: 'Alternative',
      ),
      metaGem: const ItemSuggestion(name: 'Culminating Blasphemite', isPrimary: true, note: 'Meta BiS'),
      genericGem: const ItemSuggestion(name: 'Quick Ruby', isPrimary: true, note: 'Sim según stat priority'),
      flask: const ItemSuggestion(name: 'Flask of Alchemical Chaos', isPrimary: true, note: 'Recommended'),
      food: const ItemSuggestion(name: 'Feast of the Midnight Masquerade', isPrimary: true, note: 'Group feast'),
      potion: const ItemSuggestion(name: 'Tempered Potion', isPrimary: true, note: 'With major CDs'),
      weaponEnhancement: const ItemSuggestion(name: 'Algari Mana Oil', isPrimary: true, note: 'Crit + Haste'),
    ),

    // ── Devastation — DPS Ranged · Tier S ────────────────────────────────
    // ilvl > Haste > Crit > Mastery > Versatility
    'evoker:devastation': SpecRecommendation(
      className: 'evoker',
      specName: 'devastation',
      patch: '12.0.1',
      source: RecommendationSource.local,
      statPriority: ['Intellect', 'Haste', 'Critical Strike', 'Mastery', 'Versatility'],
      enchants: _intellectEnchants(
        ringEnchant1: 'Radiant Haste',
        ringNote1: 'BiS',
        ringEnchant2: 'Glimmering Critical Strike',
        ringNote2: 'Alternative',
      ),
      metaGem: const ItemSuggestion(name: 'Culminating Blasphemite', isPrimary: true, note: 'Meta BiS'),
      genericGem: const ItemSuggestion(name: 'Quick Ruby', isPrimary: true, note: 'Quick Emerald/Onyx/Sapphire/Ruby (1 cada); resto Quick Ruby'),
      flask: const ItemSuggestion(name: 'Flask of Alchemical Chaos', isPrimary: true, note: 'Recommended'),
      food: const ItemSuggestion(name: "Beledar's Bounty", isPrimary: true, note: "Outsider's Provisions, The Sushi Special"),
      potion: const ItemSuggestion(name: 'Tempered Potion', isPrimary: true, note: 'With major CDs'),
      weaponEnhancement: const ItemSuggestion(name: 'Algari Mana Oil', isPrimary: true, note: 'Crit + Haste'),
    ),

    // ── Preservation — Healer · Tier A ───────────────────────────────────
    // Raids: Mastery > Crit > Haste > Vers
    // M+: Crit > Haste > Vers > Mastery
    'evoker:preservation': SpecRecommendation(
      className: 'evoker',
      specName: 'preservation',
      patch: '12.0.1',
      source: RecommendationSource.local,
      statPriority: ['Intellect', 'Mastery', 'Critical Strike', 'Haste', 'Versatility'],
      enchants: _intellectEnchants(
        ringEnchant1: 'Glimmering Mastery',
        ringNote1: 'Raid BiS',
        ringEnchant2: 'Glimmering Critical Strike',
        ringNote2: 'M+ alt',
      ),
      metaGem: const ItemSuggestion(name: 'Elusive Blasphemite', isPrimary: true, note: 'Movement speed BiS'),
      genericGem: const ItemSuggestion(name: 'Deadly Onyx', isPrimary: true, note: 'Raids: Masterful; M+: Quick/Deadly'),
      flask: const ItemSuggestion(name: 'Flask of Tempered Mastery', isPrimary: true, note: 'Healing BiS; Flask of Tempered Aggression para M+'),
      food: const ItemSuggestion(name: 'Feast of the Midnight Masquerade', isPrimary: true, note: "Mastery: Outsider's Provisions, Beledar's Bounty"),
      potion: const ItemSuggestion(name: 'Slumbering Soul Serum', isPrimary: true, note: 'Maná; Tempered Potion para stats'),
      weaponEnhancement: const ItemSuggestion(name: 'Algari Mana Oil', isPrimary: true, note: 'Crit + Haste'),
    ),

    // ═════════════════════════════════════════════════════════════════════════
    // HUNTER
    // ═════════════════════════════════════════════════════════════════════════

    // ── Beast Mastery — DPS Ranged ───────────────────────────────────────
    // Dark Ranger: Crit ≥ Haste > Vers > Mastery
    // Pack Leader: Crit > Mastery/Haste > Vers
    'hunter:beast mastery': SpecRecommendation(
      className: 'hunter',
      specName: 'beast mastery',
      patch: '12.0.1',
      source: RecommendationSource.local,
      statPriority: ['Agility', 'Critical Strike', 'Haste', 'Versatility', 'Mastery'],
      enchants: _agilityEnchants(
        ringEnchant1: 'Glimmering Critical Strike',
        ringNote1: 'BiS',
        ringEnchant2: 'Radiant Haste',
        ringNote2: 'Dark Ranger alt',
      ),
      metaGem: const ItemSuggestion(name: 'Culminating Blasphemite', isPrimary: true, note: 'Meta BiS'),
      genericGem: const ItemSuggestion(name: 'Deadly Emerald', isPrimary: true, note: 'Sim — generalmente Deadly (Crit)'),
      flask: const ItemSuggestion(name: 'Flask of Alchemical Chaos', isPrimary: true, note: 'Recommended'),
      food: const ItemSuggestion(name: 'Feast of the Midnight Masquerade', isPrimary: true, note: 'Group feast'),
      potion: const ItemSuggestion(name: 'Tempered Potion', isPrimary: true, note: 'With major CDs'),
      weaponEnhancement: const ItemSuggestion(name: 'Algari Mana Oil', isPrimary: true, note: 'Crit + Haste bonus'),
    ),

    // ── Marksmanship — DPS Ranged ────────────────────────────────────────
    // Mastery > Haste ≈ Crit > Versatility
    'hunter:marksmanship': SpecRecommendation(
      className: 'hunter',
      specName: 'marksmanship',
      patch: '12.0.1',
      source: RecommendationSource.local,
      statPriority: ['Agility', 'Mastery', 'Haste', 'Critical Strike', 'Versatility'],
      enchants: _agilityEnchants(
        ringEnchant1: 'Glimmering Mastery',
        ringNote1: 'BiS',
        ringEnchant2: 'Radiant Haste',
        ringNote2: 'Alternative; sim',
      ),
      metaGem: const ItemSuggestion(name: 'Culminating Blasphemite', isPrimary: true, note: 'Meta BiS'),
      genericGem: const ItemSuggestion(name: 'Masterful Emerald', isPrimary: true, note: 'Sim to confirm'),
      flask: const ItemSuggestion(name: 'Flask of Alchemical Chaos', isPrimary: true, note: 'Recommended'),
      food: const ItemSuggestion(name: 'Feast of the Midnight Masquerade', isPrimary: true, note: 'Group feast'),
      potion: const ItemSuggestion(name: 'Tempered Potion', isPrimary: true, note: 'With major CDs'),
      weaponEnhancement: const ItemSuggestion(name: 'Algari Mana Oil', isPrimary: true, note: 'Crit + Haste bonus'),
    ),

    // ── Survival — DPS Melee ─────────────────────────────────────────────
    // Haste > Crit ≈ Versatility > Mastery
    'hunter:survival': SpecRecommendation(
      className: 'hunter',
      specName: 'survival',
      patch: '12.0.1',
      source: RecommendationSource.local,
      statPriority: ['Agility', 'Haste', 'Critical Strike', 'Versatility', 'Mastery'],
      enchants: _agilityEnchants(
        ringEnchant1: 'Radiant Haste',
        ringNote1: 'BiS',
        ringEnchant2: 'Glimmering Critical Strike',
        ringNote2: 'Alternative',
      ),
      metaGem: const ItemSuggestion(name: 'Culminating Blasphemite', isPrimary: true, note: 'Meta BiS'),
      genericGem: const ItemSuggestion(name: 'Quick Ruby', isPrimary: true, note: 'Haste gems generalmente preferidas'),
      flask: const ItemSuggestion(name: 'Flask of Alchemical Chaos', isPrimary: true, note: 'Recommended'),
      food: const ItemSuggestion(name: 'Feast of the Midnight Masquerade', isPrimary: true, note: 'Group feast'),
      potion: const ItemSuggestion(name: 'Tempered Potion', isPrimary: true, note: 'With major CDs'),
      weaponEnhancement: const ItemSuggestion(name: 'Oil of Deep Toxins', isPrimary: true, note: 'O Ironclaw Whetstone'),
    ),

    // ═════════════════════════════════════════════════════════════════════════
    // MAGE
    // ═════════════════════════════════════════════════════════════════════════

    // ── Arcane — DPS Ranged ──────────────────────────────────────────────
    // Haste > Crit ≈ Mastery > Versatility
    'mage:arcane': SpecRecommendation(
      className: 'mage',
      specName: 'arcane',
      patch: '12.0.1',
      source: RecommendationSource.local,
      statPriority: ['Intellect', 'Haste', 'Critical Strike', 'Mastery', 'Versatility'],
      enchants: _intellectEnchants(
        ringEnchant1: 'Radiant Haste',
        ringNote1: 'BiS; varía Spellslinger vs Sunfury',
        ringEnchant2: 'Glimmering Critical Strike',
        ringNote2: 'Alternative',
      ),
      metaGem: const ItemSuggestion(name: 'Culminating Blasphemite', isPrimary: true, note: 'Meta BiS'),
      genericGem: const ItemSuggestion(name: 'Quick Ruby', isPrimary: true, note: 'Sim según build'),
      flask: const ItemSuggestion(name: 'Flask of Alchemical Chaos', isPrimary: true, note: 'Recommended'),
      food: const ItemSuggestion(name: 'Feast of the Midnight Masquerade', isPrimary: true, note: 'Group feast'),
      potion: const ItemSuggestion(name: 'Tempered Potion', isPrimary: true, note: 'With major CDs'),
      weaponEnhancement: const ItemSuggestion(name: 'Algari Mana Oil', isPrimary: true, note: 'Crit + Haste'),
    ),

    // ── Fire — DPS Ranged ────────────────────────────────────────────────
    // Haste > Mastery > Versatility ≈ Crit
    'mage:fire': SpecRecommendation(
      className: 'mage',
      specName: 'fire',
      patch: '12.0.1',
      source: RecommendationSource.local,
      statPriority: ['Intellect', 'Haste', 'Mastery', 'Versatility', 'Critical Strike'],
      enchants: _intellectEnchants(
        ringEnchant1: 'Radiant Haste',
        ringNote1: 'BiS',
        ringEnchant2: 'Glimmering Mastery',
        ringNote2: 'Alternative',
      ),
      metaGem: const ItemSuggestion(name: 'Culminating Blasphemite', isPrimary: true, note: 'Meta BiS'),
      genericGem: const ItemSuggestion(name: 'Quick Ruby', isPrimary: true, note: 'Sim to confirm'),
      flask: const ItemSuggestion(name: 'Flask of Alchemical Chaos', isPrimary: true, note: 'Recommended'),
      food: const ItemSuggestion(name: 'Feast of the Midnight Masquerade', isPrimary: true, note: 'Group feast'),
      potion: const ItemSuggestion(name: 'Tempered Potion', isPrimary: true, note: 'With major CDs'),
      weaponEnhancement: const ItemSuggestion(name: 'Algari Mana Oil', isPrimary: true, note: 'Crit + Haste'),
    ),

    // ── Frost — DPS Ranged · #1 M+ Pre-Patch ────────────────────────────
    // Haste > Crit ≈ Mastery > Versatility
    'mage:frost': SpecRecommendation(
      className: 'mage',
      specName: 'frost',
      patch: '12.0.1',
      source: RecommendationSource.local,
      statPriority: ['Intellect', 'Haste', 'Critical Strike', 'Mastery', 'Versatility'],
      enchants: _intellectEnchants(
        ringEnchant1: 'Radiant Haste',
        ringNote1: 'BiS',
        ringEnchant2: 'Glimmering Critical Strike',
        ringNote2: 'Alternative',
      ),
      metaGem: const ItemSuggestion(name: 'Culminating Blasphemite', isPrimary: true, note: 'Meta BiS'),
      genericGem: const ItemSuggestion(name: 'Quick Ruby', isPrimary: true, note: 'Haste gems generalmente favorecidas'),
      flask: const ItemSuggestion(name: 'Flask of Alchemical Chaos', isPrimary: true, note: 'Recommended'),
      food: const ItemSuggestion(name: 'Feast of the Midnight Masquerade', isPrimary: true, note: 'Group feast'),
      potion: const ItemSuggestion(name: 'Tempered Potion', isPrimary: true, note: 'With major CDs'),
      weaponEnhancement: const ItemSuggestion(name: 'Algari Mana Oil', isPrimary: true, note: 'Crit + Haste'),
    ),

    // ═════════════════════════════════════════════════════════════════════════
    // MONK
    // ═════════════════════════════════════════════════════════════════════════

    // ── Brewmaster — Tank · Tier A ───────────────────────────────────────
    // Defensa: ilvl > Vers = Crit = Mastery > Haste
    // Ofensiva: Crit > Vers > Mastery > Haste
    'monk:brewmaster': SpecRecommendation(
      className: 'monk',
      specName: 'brewmaster',
      patch: '12.0.1',
      source: RecommendationSource.local,
      statPriority: ['Agility', 'Critical Strike', 'Versatility', 'Mastery', 'Haste'],
      enchants: _agilityEnchants(
        ringEnchant1: 'Glimmering Critical Strike',
        ringNote1: 'BiS offensive',
        ringEnchant2: 'Radiant Versatility',
        ringNote2: 'Defensive alt',
        weaponEnchant: 'Authority of the Depths',
        weaponNote: 'BiS tank',
      ),
      metaGem: const ItemSuggestion(name: 'Culminating Blasphemite', isPrimary: true, note: 'Meta BiS; o Elusive Blasphemite'),
      genericGem: const ItemSuggestion(name: 'Deadly Sapphire', isPrimary: true, note: 'Versatile Ruby, Deadly Onyx, Versatile Emerald; sim'),
      flask: const ItemSuggestion(name: 'Flask of Alchemical Chaos', isPrimary: true, note: 'O Tempered Aggression/Versatility'),
      food: const ItemSuggestion(name: 'Feast of the Midnight Masquerade', isPrimary: true, note: "Beledar's Bounty, Outsider's Provisions, Jester's Board"),
      potion: const ItemSuggestion(name: 'Tempered Potion', isPrimary: true, note: 'Damage; Invigorating Healing Potion para curación'),
      weaponEnhancement: const ItemSuggestion(name: 'Ironclaw Whetstone', isPrimary: true, note: 'O Algari Mana Oil'),
    ),

    // ── Mistweaver — Healer · Tier S ─────────────────────────────────────
    // Raids: Haste > Crit > Vers > Mastery
    // M+: Haste > Crit ≥ Vers > Mastery
    'monk:mistweaver': SpecRecommendation(
      className: 'monk',
      specName: 'mistweaver',
      patch: '12.0.1',
      source: RecommendationSource.local,
      statPriority: ['Intellect', 'Haste', 'Critical Strike', 'Versatility', 'Mastery'],
      enchants: _intellectEnchants(
        ringEnchant1: 'Radiant Haste',
        ringNote1: 'BiS',
        ringEnchant2: 'Glimmering Critical Strike',
        ringNote2: 'Alternative',
      ),
      metaGem: const ItemSuggestion(name: 'Elusive Blasphemite', isPrimary: true, note: 'Movement speed BiS'),
      genericGem: const ItemSuggestion(name: 'Deadly Emerald', isPrimary: true, note: 'Quick Ruby/Onyx/Sapphire; resto Deadly Emerald'),
      flask: const ItemSuggestion(name: 'Flask of Tempered Swiftness', isPrimary: true, note: 'BiS para Mistweaver'),
      food: const ItemSuggestion(name: 'Feast of the Midnight Masquerade', isPrimary: true, note: "Outsider's Provisions, Beledar's Bounty, Jester's Board"),
      potion: const ItemSuggestion(name: 'Slumbering Soul Serum', isPrimary: true, note: 'Maná; Tempered Potion / Potion Bomb of Power para daño'),
      weaponEnhancement: const ItemSuggestion(name: 'Algari Mana Oil', isPrimary: true, note: 'Crit + Haste'),
    ),

    // ── Windwalker — DPS Melee ───────────────────────────────────────────
    // Versatility > Crit ≈ Mastery > Haste
    'monk:windwalker': SpecRecommendation(
      className: 'monk',
      specName: 'windwalker',
      patch: '12.0.1',
      source: RecommendationSource.local,
      statPriority: ['Agility', 'Versatility', 'Critical Strike', 'Mastery', 'Haste'],
      enchants: _agilityEnchants(
        ringEnchant1: 'Radiant Versatility',
        ringNote1: 'BiS',
        ringEnchant2: 'Glimmering Critical Strike',
        ringNote2: 'Alternative',
      ),
      metaGem: const ItemSuggestion(name: 'Culminating Blasphemite', isPrimary: true, note: 'Meta BiS'),
      genericGem: const ItemSuggestion(name: 'Versatile Emerald', isPrimary: true, note: 'Sim to confirm'),
      flask: const ItemSuggestion(name: 'Flask of Alchemical Chaos', isPrimary: true, note: 'Recommended'),
      food: const ItemSuggestion(name: 'Feast of the Midnight Masquerade', isPrimary: true, note: 'Group feast'),
      potion: const ItemSuggestion(name: 'Tempered Potion', isPrimary: true, note: 'With CDs + Bloodlust'),
      weaponEnhancement: const ItemSuggestion(name: 'Oil of Deep Toxins', isPrimary: true, note: 'O Ironclaw Whetstone'),
    ),

    // ═════════════════════════════════════════════════════════════════════════
    // PALADIN
    // ═════════════════════════════════════════════════════════════════════════

    // ── Holy — Healer ────────────────────────────────────────────────────
    // Haste > Crit ≈ Mastery > Versatility
    'paladin:holy': SpecRecommendation(
      className: 'paladin',
      specName: 'holy',
      patch: '12.0.1',
      source: RecommendationSource.local,
      statPriority: ['Intellect', 'Haste', 'Critical Strike', 'Mastery', 'Versatility'],
      enchants: _intellectEnchants(
        ringEnchant1: 'Radiant Haste',
        ringNote1: 'BiS',
        ringEnchant2: 'Glimmering Critical Strike',
        ringNote2: 'Alternative',
      ),
      metaGem: const ItemSuggestion(name: 'Elusive Blasphemite', isPrimary: true, note: 'O Insightful Blasphemite para maná'),
      genericGem: const ItemSuggestion(name: 'Quick Ruby', isPrimary: true, note: 'Sim to confirm'),
      flask: const ItemSuggestion(name: 'Flask of Alchemical Chaos', isPrimary: true, note: 'Recommended'),
      food: const ItemSuggestion(name: 'Feast of the Midnight Masquerade', isPrimary: true, note: 'Group feast'),
      potion: const ItemSuggestion(name: 'Algari Mana Potion', isPrimary: true, note: 'Maná; Tempered Potion para daño'),
      weaponEnhancement: const ItemSuggestion(name: 'Algari Mana Oil', isPrimary: true, note: 'Crit + Haste'),
    ),

    // ── Protection — Tank · Tier S ───────────────────────────────────────
    // Templar: Haste > Mastery > Vers/Crit
    // Lightsmith: Haste > Crit > Vers/Mastery
    'paladin:protection': SpecRecommendation(
      className: 'paladin',
      specName: 'protection',
      patch: '12.0.1',
      source: RecommendationSource.local,
      statPriority: ['Strength', 'Haste', 'Mastery', 'Versatility', 'Critical Strike'],
      enchants: _strengthEnchants(
        ringEnchant1: 'Radiant Haste',
        ringNote1: 'BiS (Templar)',
        ringEnchant2: 'Glimmering Critical Strike',
        ringNote2: 'Lightsmith alt',
        weaponEnchant: 'Authority of the Depths',
        weaponNote: 'BiS tank',
      ),
      metaGem: const ItemSuggestion(name: 'Culminating Blasphemite', isPrimary: true, note: 'Meta BiS'),
      genericGem: const ItemSuggestion(name: 'Masterful Emerald', isPrimary: true, note: 'Fill remaining sockets'),
      flask: const ItemSuggestion(name: 'Flask of Alchemical Chaos', isPrimary: true, note: 'Recommended'),
      food: const ItemSuggestion(name: 'Feast of the Midnight Masquerade', isPrimary: true, note: 'O Chippy Tea'),
      potion: const ItemSuggestion(name: 'Tempered Potion', isPrimary: true, note: 'Damage; Invigorating Healing Potion para curación'),
      weaponEnhancement: const ItemSuggestion(name: 'Algari Mana Oil', isPrimary: true, note: 'O Rite of Sanctification para Lightsmith'),
    ),

    // ── Retribution — DPS Melee ──────────────────────────────────────────
    // Haste > Mastery ≈ Versatility > Crit
    'paladin:retribution': SpecRecommendation(
      className: 'paladin',
      specName: 'retribution',
      patch: '12.0.1',
      source: RecommendationSource.local,
      statPriority: ['Strength', 'Haste', 'Mastery', 'Versatility', 'Critical Strike'],
      enchants: _strengthEnchants(
        ringEnchant1: 'Radiant Haste',
        ringNote1: 'BiS',
        ringEnchant2: 'Glimmering Mastery',
        ringNote2: 'Alternative; varía Templar vs Lightsmith',
      ),
      metaGem: const ItemSuggestion(name: 'Culminating Blasphemite', isPrimary: true, note: 'Meta BiS'),
      genericGem: const ItemSuggestion(name: 'Quick Ruby', isPrimary: true, note: 'Sim to confirm'),
      flask: const ItemSuggestion(name: 'Flask of Alchemical Chaos', isPrimary: true, note: 'Recommended'),
      food: const ItemSuggestion(name: 'Feast of the Midnight Masquerade', isPrimary: true, note: 'Group feast'),
      potion: const ItemSuggestion(name: 'Tempered Potion', isPrimary: true, note: 'With major CDs'),
      weaponEnhancement: const ItemSuggestion(name: 'Algari Mana Oil', isPrimary: true, note: 'Crit + Haste'),
    ),

    // ═════════════════════════════════════════════════════════════════════════
    // PRIEST
    // ═════════════════════════════════════════════════════════════════════════

    // ── Discipline — Healer · Tier S ─────────────────────────────────────
    // Haste (hasta 20-25%) > Crit = Mastery > más Haste > Vers
    // Voidweaver: Haste > Mastery > Crit > Vers
    'priest:discipline': SpecRecommendation(
      className: 'priest',
      specName: 'discipline',
      patch: '12.0.1',
      source: RecommendationSource.local,
      statPriority: ['Intellect', 'Haste', 'Critical Strike', 'Mastery', 'Versatility'],
      enchants: _intellectEnchants(
        ringEnchant1: 'Radiant Haste',
        ringNote1: 'Hasta 20-25% de Haste',
        ringEnchant2: 'Glimmering Critical Strike',
        ringNote2: 'Por encima del umbral de Haste',
      ),
      metaGem: const ItemSuggestion(name: 'Elusive Blasphemite', isPrimary: true, note: 'Movement speed BiS'),
      genericGem: const ItemSuggestion(name: 'Quick Sapphire', isPrimary: true, note: '1 de cada color; Haste si < 20-25%; evitar Vers'),
      flask: const ItemSuggestion(name: 'Flask of Tempered Swiftness', isPrimary: true, note: 'O Aggression / Mastery según necesidad'),
      food: const ItemSuggestion(name: 'Hearty Salt Baked Seafood', isPrimary: true, note: 'Festines solo si gratis'),
      potion: const ItemSuggestion(name: 'Slumbering Soul Serum', isPrimary: true, note: 'Maná; Tempered Potion para stats'),
      weaponEnhancement: const ItemSuggestion(name: 'Algari Mana Oil', isPrimary: true, note: 'Crit + Haste'),
    ),

    // ── Holy — Healer · Tier A ───────────────────────────────────────────
    // Raids: Crit > Vers = Mastery > Haste
    // M+: Crit > Vers = Haste > Mastery
    'priest:holy': SpecRecommendation(
      className: 'priest',
      specName: 'holy',
      patch: '12.0.1',
      source: RecommendationSource.local,
      statPriority: ['Intellect', 'Critical Strike', 'Versatility', 'Mastery', 'Haste'],
      enchants: _intellectEnchants(
        ringEnchant1: 'Glimmering Critical Strike',
        ringNote1: 'BiS',
        ringEnchant2: 'Radiant Versatility',
        ringNote2: 'M+ alternative',
      ),
      metaGem: const ItemSuggestion(name: 'Elusive Blasphemite', isPrimary: true, note: 'Movement; Insightful para maná'),
      genericGem: const ItemSuggestion(name: 'Masterful Ruby', isPrimary: true, note: 'Deadly Emerald/Onyx/Sapphire; resto Masterful Ruby'),
      flask: const ItemSuggestion(name: 'Flask of Tempered Aggression', isPrimary: true, note: 'O Flask of Alchemical Chaos'),
      food: const ItemSuggestion(name: 'Hearty Salt Baked Seafood', isPrimary: true, note: "Festines: Divine Day / Midnight Masquerade; Beledar's Bounty"),
      potion: const ItemSuggestion(name: 'Algari Mana Potion', isPrimary: true, note: 'Maná; Tempered Potion para daño'),
      weaponEnhancement: const ItemSuggestion(name: 'Algari Mana Oil', isPrimary: true, note: 'Crit + Haste'),
    ),

    // ── Shadow — DPS Ranged ──────────────────────────────────────────────
    // Haste > Mastery > Crit > Versatility
    'priest:shadow': SpecRecommendation(
      className: 'priest',
      specName: 'shadow',
      patch: '12.0.1',
      source: RecommendationSource.local,
      statPriority: ['Intellect', 'Haste', 'Mastery', 'Critical Strike', 'Versatility'],
      enchants: _intellectEnchants(
        ringEnchant1: 'Radiant Haste',
        ringNote1: 'BiS',
        ringEnchant2: 'Glimmering Mastery',
        ringNote2: 'Alternative',
      ),
      metaGem: const ItemSuggestion(name: 'Culminating Blasphemite', isPrimary: true, note: 'Meta BiS'),
      genericGem: const ItemSuggestion(name: 'Quick Ruby', isPrimary: true, note: 'Sim to confirm'),
      flask: const ItemSuggestion(name: 'Flask of Alchemical Chaos', isPrimary: true, note: 'Recommended'),
      food: const ItemSuggestion(name: 'Feast of the Midnight Masquerade', isPrimary: true, note: 'Group feast'),
      potion: const ItemSuggestion(name: 'Tempered Potion', isPrimary: true, note: 'With major CDs'),
      weaponEnhancement: const ItemSuggestion(name: 'Algari Mana Oil', isPrimary: true, note: 'Crit + Haste'),
    ),

    // ═════════════════════════════════════════════════════════════════════════
    // ROGUE
    // ═════════════════════════════════════════════════════════════════════════

    // ── Assassination — DPS Melee ────────────────────────────────────────
    // Mastery > Haste > Crit > Versatility
    'rogue:assassination': SpecRecommendation(
      className: 'rogue',
      specName: 'assassination',
      patch: '12.0.1',
      source: RecommendationSource.local,
      statPriority: ['Agility', 'Mastery', 'Haste', 'Critical Strike', 'Versatility'],
      enchants: _agilityEnchants(
        ringEnchant1: 'Glimmering Mastery',
        ringNote1: 'BiS — Potent Assassin amplifica envenenamientos',
        ringEnchant2: 'Radiant Haste',
        ringNote2: 'Alternative',
      ),
      metaGem: const ItemSuggestion(name: 'Culminating Blasphemite', isPrimary: true, note: 'Meta BiS'),
      genericGem: const ItemSuggestion(name: 'Masterful Emerald', isPrimary: true, note: 'Sim — Masterful generalmente buenas'),
      flask: const ItemSuggestion(name: 'Flask of Alchemical Chaos', isPrimary: true, note: 'Recommended'),
      food: const ItemSuggestion(name: 'Feast of the Midnight Masquerade', isPrimary: true, note: 'Group feast'),
      potion: const ItemSuggestion(name: 'Tempered Potion', isPrimary: true, note: 'With CDs'),
      weaponEnhancement: const ItemSuggestion(name: 'Oil of Deep Toxins', isPrimary: true, note: 'BiS para Agility melee'),
    ),

    // ── Outlaw — DPS Melee ───────────────────────────────────────────────
    // Haste ≈ Versatility > Crit > Mastery
    'rogue:outlaw': SpecRecommendation(
      className: 'rogue',
      specName: 'outlaw',
      patch: '12.0.1',
      source: RecommendationSource.local,
      statPriority: ['Agility', 'Haste', 'Versatility', 'Critical Strike', 'Mastery'],
      enchants: _agilityEnchants(
        ringEnchant1: 'Radiant Haste',
        ringNote1: 'BiS; Haste ≈ Vers',
        ringEnchant2: 'Radiant Versatility',
        ringNote2: 'Alternative',
      ),
      metaGem: const ItemSuggestion(name: 'Culminating Blasphemite', isPrimary: true, note: 'Meta BiS'),
      genericGem: const ItemSuggestion(name: 'Quick Ruby', isPrimary: true, note: 'Sim to confirm'),
      flask: const ItemSuggestion(name: 'Flask of Alchemical Chaos', isPrimary: true, note: 'Recommended'),
      food: const ItemSuggestion(name: 'Feast of the Midnight Masquerade', isPrimary: true, note: 'Group feast'),
      potion: const ItemSuggestion(name: 'Tempered Potion', isPrimary: true, note: 'With CDs'),
      weaponEnhancement: const ItemSuggestion(name: 'Oil of Deep Toxins', isPrimary: true, note: 'O Ironclaw Whetstone'),
    ),

    // ── Subtlety — DPS Melee ─────────────────────────────────────────────
    // Versatility > Crit ≈ Mastery > Haste
    'rogue:subtlety': SpecRecommendation(
      className: 'rogue',
      specName: 'subtlety',
      patch: '12.0.1',
      source: RecommendationSource.local,
      statPriority: ['Agility', 'Versatility', 'Critical Strike', 'Mastery', 'Haste'],
      enchants: _agilityEnchants(
        ringEnchant1: 'Radiant Versatility',
        ringNote1: 'BiS',
        ringEnchant2: 'Glimmering Critical Strike',
        ringNote2: 'Alternative',
      ),
      metaGem: const ItemSuggestion(name: 'Culminating Blasphemite', isPrimary: true, note: 'Meta BiS'),
      genericGem: const ItemSuggestion(name: 'Versatile Emerald', isPrimary: true, note: 'Sim to confirm'),
      flask: const ItemSuggestion(name: 'Flask of Alchemical Chaos', isPrimary: true, note: 'Recommended'),
      food: const ItemSuggestion(name: 'Feast of the Midnight Masquerade', isPrimary: true, note: 'Group feast'),
      potion: const ItemSuggestion(name: 'Tempered Potion', isPrimary: true, note: 'With CDs'),
      weaponEnhancement: const ItemSuggestion(name: 'Oil of Deep Toxins', isPrimary: true, note: 'BiS para Agility melee'),
    ),

    // ═════════════════════════════════════════════════════════════════════════
    // SHAMAN
    // ═════════════════════════════════════════════════════════════════════════

    // ── Elemental — DPS Ranged ───────────────────────────────────────────
    // Haste > Crit ≈ Versatility > Mastery
    'shaman:elemental': SpecRecommendation(
      className: 'shaman',
      specName: 'elemental',
      patch: '12.0.1',
      source: RecommendationSource.local,
      statPriority: ['Intellect', 'Haste', 'Critical Strike', 'Versatility', 'Mastery'],
      enchants: _intellectEnchants(
        ringEnchant1: 'Radiant Haste',
        ringNote1: 'BiS; varía Stormbringer vs Farseer',
        ringEnchant2: 'Glimmering Critical Strike',
        ringNote2: 'Alternative',
      ),
      metaGem: const ItemSuggestion(name: 'Culminating Blasphemite', isPrimary: true, note: 'Meta BiS'),
      genericGem: const ItemSuggestion(name: 'Quick Ruby', isPrimary: true, note: 'Sim to confirm'),
      flask: const ItemSuggestion(name: 'Flask of Alchemical Chaos', isPrimary: true, note: 'Recommended'),
      food: const ItemSuggestion(name: 'Feast of the Midnight Masquerade', isPrimary: true, note: 'Group feast'),
      potion: const ItemSuggestion(name: 'Tempered Potion', isPrimary: true, note: 'With major CDs'),
      weaponEnhancement: const ItemSuggestion(name: 'Algari Mana Oil', isPrimary: true, note: 'Crit + Haste'),
    ),

    // ── Enhancement — DPS Melee ──────────────────────────────────────────
    // Haste > Mastery > Crit > Versatility
    'shaman:enhancement': SpecRecommendation(
      className: 'shaman',
      specName: 'enhancement',
      patch: '12.0.1',
      source: RecommendationSource.local,
      statPriority: ['Agility', 'Haste', 'Mastery', 'Critical Strike', 'Versatility'],
      enchants: _agilityEnchants(
        ringEnchant1: 'Radiant Haste',
        ringNote1: 'BiS',
        ringEnchant2: 'Glimmering Mastery',
        ringNote2: 'Alternative',
      ),
      metaGem: const ItemSuggestion(name: 'Culminating Blasphemite', isPrimary: true, note: 'Meta BiS'),
      genericGem: const ItemSuggestion(name: 'Quick Ruby', isPrimary: true, note: 'Sim to confirm'),
      flask: const ItemSuggestion(name: 'Flask of Alchemical Chaos', isPrimary: true, note: 'Recommended'),
      food: const ItemSuggestion(name: 'Feast of the Midnight Masquerade', isPrimary: true, note: 'Group feast'),
      potion: const ItemSuggestion(name: 'Tempered Potion', isPrimary: true, note: 'With major CDs'),
      weaponEnhancement: const ItemSuggestion(name: 'Oil of Deep Toxins', isPrimary: true, note: 'O Algari Mana Oil'),
    ),

    // ── Restoration — Healer · Tier A ────────────────────────────────────
    // Stats cercanas; Raids: Crit preferido; M+: Vers preferido
    'shaman:restoration': SpecRecommendation(
      className: 'shaman',
      specName: 'restoration',
      patch: '12.0.1',
      source: RecommendationSource.local,
      statPriority: ['Intellect', 'Critical Strike', 'Versatility', 'Haste', 'Mastery'],
      enchants: _intellectEnchants(
        ringEnchant1: 'Glimmering Critical Strike',
        ringNote1: 'Raid BiS',
        ringEnchant2: 'Radiant Versatility',
        ringNote2: 'M+ alt',
      ),
      metaGem: const ItemSuggestion(name: 'Elusive Blasphemite', isPrimary: true, note: 'Movement speed BiS'),
      genericGem: const ItemSuggestion(name: 'Versatile Ruby', isPrimary: true, note: 'Deadly Onyx/Sapphire/Emerald; resto Versatile Ruby'),
      flask: const ItemSuggestion(name: 'Flask of Tempered Aggression', isPrimary: true, note: 'Raid BiS; Tempered Versatility para M+'),
      food: const ItemSuggestion(name: 'Feast of the Divine Day', isPrimary: true, note: "Stuffed Cave Peppers, Outsider's Provisions, Beledar's Bounty"),
      potion: const ItemSuggestion(name: 'Slumbering Soul Serum', isPrimary: true, note: 'Maná; Tempered Potion para stats'),
      weaponEnhancement: const ItemSuggestion(name: 'Algari Mana Oil', isPrimary: true, note: 'Crit + Haste'),
    ),

    // ═════════════════════════════════════════════════════════════════════════
    // WARLOCK
    // ═════════════════════════════════════════════════════════════════════════

    // ── Affliction — DPS Ranged ──────────────────────────────────────────
    // Haste > Mastery > Crit > Versatility
    // Nota: subió de 0.3% a 4.1% playrate en pre-patch
    'warlock:affliction': SpecRecommendation(
      className: 'warlock',
      specName: 'affliction',
      patch: '12.0.1',
      source: RecommendationSource.local,
      statPriority: ['Intellect', 'Haste', 'Mastery', 'Critical Strike', 'Versatility'],
      enchants: _intellectEnchants(
        ringEnchant1: 'Radiant Haste',
        ringNote1: 'BiS',
        ringEnchant2: 'Glimmering Mastery',
        ringNote2: 'Alternative',
      ),
      metaGem: const ItemSuggestion(name: 'Culminating Blasphemite', isPrimary: true, note: 'Meta BiS'),
      genericGem: const ItemSuggestion(name: 'Quick Ruby', isPrimary: true, note: 'Sim to confirm'),
      flask: const ItemSuggestion(name: 'Flask of Alchemical Chaos', isPrimary: true, note: 'Recommended'),
      food: const ItemSuggestion(name: 'Feast of the Midnight Masquerade', isPrimary: true, note: 'Group feast'),
      potion: const ItemSuggestion(name: 'Tempered Potion', isPrimary: true, note: 'With major CDs'),
      weaponEnhancement: const ItemSuggestion(name: 'Algari Mana Oil', isPrimary: true, note: 'Crit + Haste'),
    ),

    // ── Demonology — DPS Ranged · #1 DPS Beta Midnight ───────────────────
    // Haste > Mastery > Crit > Versatility
    'warlock:demonology': SpecRecommendation(
      className: 'warlock',
      specName: 'demonology',
      patch: '12.0.1',
      source: RecommendationSource.local,
      statPriority: ['Intellect', 'Haste', 'Mastery', 'Critical Strike', 'Versatility'],
      enchants: _intellectEnchants(
        ringEnchant1: 'Radiant Haste',
        ringNote1: 'BiS',
        ringEnchant2: 'Glimmering Mastery',
        ringNote2: 'Alternative',
      ),
      metaGem: const ItemSuggestion(name: 'Culminating Blasphemite', isPrimary: true, note: 'Meta BiS'),
      genericGem: const ItemSuggestion(name: 'Quick Ruby', isPrimary: true, note: 'Sim to confirm'),
      flask: const ItemSuggestion(name: 'Flask of Alchemical Chaos', isPrimary: true, note: 'Recommended'),
      food: const ItemSuggestion(name: 'Feast of the Midnight Masquerade', isPrimary: true, note: 'Group feast'),
      potion: const ItemSuggestion(name: 'Tempered Potion', isPrimary: true, note: 'With major CDs'),
      weaponEnhancement: const ItemSuggestion(name: 'Algari Mana Oil', isPrimary: true, note: 'Crit + Haste'),
    ),

    // ── Destruction — DPS Ranged ─────────────────────────────────────────
    // Haste > Crit > Mastery > Versatility
    'warlock:destruction': SpecRecommendation(
      className: 'warlock',
      specName: 'destruction',
      patch: '12.0.1',
      source: RecommendationSource.local,
      statPriority: ['Intellect', 'Haste', 'Critical Strike', 'Mastery', 'Versatility'],
      enchants: _intellectEnchants(
        ringEnchant1: 'Radiant Haste',
        ringNote1: 'BiS',
        ringEnchant2: 'Glimmering Critical Strike',
        ringNote2: 'Alternative',
      ),
      metaGem: const ItemSuggestion(name: 'Culminating Blasphemite', isPrimary: true, note: 'Meta BiS'),
      genericGem: const ItemSuggestion(name: 'Quick Ruby', isPrimary: true, note: 'Sim to confirm'),
      flask: const ItemSuggestion(name: 'Flask of Alchemical Chaos', isPrimary: true, note: 'Recommended'),
      food: const ItemSuggestion(name: 'Feast of the Midnight Masquerade', isPrimary: true, note: 'Group feast'),
      potion: const ItemSuggestion(name: 'Tempered Potion', isPrimary: true, note: 'With major CDs'),
      weaponEnhancement: const ItemSuggestion(name: 'Algari Mana Oil', isPrimary: true, note: 'Crit + Haste'),
    ),

    // ═════════════════════════════════════════════════════════════════════════
    // WARRIOR
    // ═════════════════════════════════════════════════════════════════════════

    // ── Arms — DPS Melee ─────────────────────────────────────────────────
    // Haste > Crit ≈ Mastery > Versatility
    'warrior:arms': SpecRecommendation(
      className: 'warrior',
      specName: 'arms',
      patch: '12.0.1',
      source: RecommendationSource.local,
      statPriority: ['Strength', 'Haste', 'Critical Strike', 'Mastery', 'Versatility'],
      enchants: _strengthEnchants(
        ringEnchant1: 'Radiant Haste',
        ringNote1: 'BiS',
        ringEnchant2: 'Glimmering Critical Strike',
        ringNote2: 'Alternative; Crit ≈ Mastery',
      ),
      metaGem: const ItemSuggestion(name: 'Culminating Blasphemite', isPrimary: true, note: 'Meta BiS'),
      genericGem: const ItemSuggestion(name: 'Quick Ruby', isPrimary: true, note: 'Sim to confirm'),
      flask: const ItemSuggestion(name: 'Flask of Alchemical Chaos', isPrimary: true, note: 'Recommended'),
      food: const ItemSuggestion(name: 'Feast of the Midnight Masquerade', isPrimary: true, note: 'Group feast'),
      potion: const ItemSuggestion(name: 'Tempered Potion', isPrimary: true, note: 'With major CDs'),
      weaponEnhancement: const ItemSuggestion(name: 'Ironclaw Whetstone', isPrimary: true, note: 'BiS STR melee'),
    ),

    // ── Fury — DPS Melee ─────────────────────────────────────────────────
    // Haste > Mastery > Crit > Versatility
    'warrior:fury': SpecRecommendation(
      className: 'warrior',
      specName: 'fury',
      patch: '12.0.1',
      source: RecommendationSource.local,
      statPriority: ['Strength', 'Haste', 'Mastery', 'Critical Strike', 'Versatility'],
      enchants: _strengthEnchants(
        ringEnchant1: 'Radiant Haste',
        ringNote1: 'BiS',
        ringEnchant2: 'Glimmering Mastery',
        ringNote2: 'Alternative',
        offHandEnchant: 'Authority of Radiant Power',
        offHandNote: 'Dual wield',
      ),
      metaGem: const ItemSuggestion(name: 'Culminating Blasphemite', isPrimary: true, note: 'Meta BiS'),
      genericGem: const ItemSuggestion(name: 'Quick Ruby', isPrimary: true, note: 'Haste gems; sim'),
      flask: const ItemSuggestion(name: 'Flask of Alchemical Chaos', isPrimary: true, note: 'Recommended'),
      food: const ItemSuggestion(name: 'Feast of the Midnight Masquerade', isPrimary: true, note: 'Group feast'),
      potion: const ItemSuggestion(name: 'Tempered Potion', isPrimary: true, note: 'With major CDs'),
      weaponEnhancement: const ItemSuggestion(name: 'Ironclaw Whetstone', isPrimary: true, note: 'BiS STR melee'),
    ),

    // ── Protection — Tank · Tier S ───────────────────────────────────────
    // ilvl > Haste > Crit ≈ Versatility > Mastery
    'warrior:protection': SpecRecommendation(
      className: 'warrior',
      specName: 'protection',
      patch: '12.0.1',
      source: RecommendationSource.local,
      statPriority: ['Strength', 'Haste', 'Critical Strike', 'Versatility', 'Mastery'],
      enchants: _strengthEnchants(
        ringEnchant1: 'Radiant Haste',
        ringNote1: 'BiS',
        ringEnchant2: 'Glimmering Critical Strike',
        ringNote2: 'Alternative',
        weaponEnchant: 'Authority of the Depths',
        weaponNote: 'BiS tank',
        offHandEnchant: 'Authority of the Depths',
        offHandNote: 'Shield',
      ),
      metaGem: const ItemSuggestion(name: 'Culminating Blasphemite', isPrimary: true, note: 'Meta BiS'),
      genericGem: const ItemSuggestion(name: 'Deadly Emerald', isPrimary: true, note: 'Quick Ruby/Onyx/Sapphire (1 cada); resto Deadly Emerald'),
      flask: const ItemSuggestion(name: 'Flask of Alchemical Chaos', isPrimary: true, note: 'Recommended'),
      food: const ItemSuggestion(name: 'Feast of the Divine Day', isPrimary: true, note: "O Midnight Masquerade; Outsider's Provisions, Beledar's Bounty"),
      potion: const ItemSuggestion(name: 'Tempered Potion', isPrimary: true, note: 'Damage; Invigorating Healing Potion para curación'),
      weaponEnhancement: const ItemSuggestion(name: 'Algari Mana Oil', isPrimary: true, note: 'Crit + Haste'),
    ),
  };
}
