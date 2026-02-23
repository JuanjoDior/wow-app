import 'package:wow_companion/features/analysis/domain/entities/character_insight.dart';
import 'package:wow_companion/features/builds/domain/entities/spec_recommendation.dart';
import 'package:wow_companion/features/character/domain/entities/character.dart';

// ─── Internal data class ──────────────────────────────────────────────────────

class _SlotResult {
  final String label;
  final String? currentEnchant;   // null = no enchant
  final String? recommendedName;  // null = no spec data for slot

  const _SlotResult({
    required this.label,
    required this.currentEnchant,
    required this.recommendedName,
  });

  bool get hasEnchant => currentEnchant != null;
  bool get isSuboptimal =>
      hasEnchant &&
      recommendedName != null &&
      !_matches(currentEnchant!, recommendedName!);

  static bool _matches(String current, String recommended) {
    final c = current.toLowerCase();
    final r = recommended.toLowerCase();
    if (c.contains(r) || r.contains(c)) return true;
    // Check significant keyword overlap (ignore filler words)
    const ignore = {'of', 'the', 'a', 'an', 'and', 'enchant'};
    final rWords = r.split(' ').where((w) => w.length > 3 && !ignore.contains(w));
    return rWords.any((w) => c.contains(w));
  }
}

// ─── EnchantmentAnalyzer ──────────────────────────────────────────────────────

/// Checks every enchantable slot for:
///   1. Missing enchantment (critical)
///   2. Suboptimal enchantment vs spec BiS (warning)
///   3. All good (positive)
///
/// Slot coverage (Midnight): Back, Chest, Bracers, Legs, Boots,
///   Ring×2, Main Hand, Off Hand (when equipped as weapon).
///
/// Data: [EquippedItem.enchantments] from Raider.IO API.
class EnchantmentAnalyzer {
  const EnchantmentAnalyzer();

  // Raider.IO slot string → SlotKeys string used in SpecRecommendation
  static const _slotMap = {
    'BACK':     ('back',     'Capa'),
    'CHEST':    ('chest',    'Pecho'),
    'WRIST':    ('wrist',    'Muñequeras'),
    'LEGS':     ('legs',     'Piernas'),
    'FEET':     ('feet',     'Botas'),
    'FINGER_1': ('finger1',  'Anillo 1'),
    'FINGER_2': ('finger2',  'Anillo 2'),
    'MAIN_HAND':('mainHand', 'Arma principal'),
    'OFF_HAND': ('offHand',  'Mano secundaria'),
  };

  List<CharacterInsight> analyze(
    Character character,
    SpecRecommendation? recommendation,
  ) {
    final equipped = {for (final i in character.equipment) i.slot: i};
    final results = <_SlotResult>[];

    for (final entry in _slotMap.entries) {
      final raiderSlot = entry.key;
      final slotKey    = entry.value.$1;
      final label      = entry.value.$2;
      final item       = equipped[raiderSlot];

      // Skip unequipped off-hand (many specs are single-wield)
      if (item == null) continue;

      // Get current enchant name (filter Raider.IO generic placeholder)
      final rawEnchant = item.enchantments.isNotEmpty &&
              item.enchantments.first.trim().isNotEmpty &&
              item.enchantments.first.toLowerCase() != 'enchanted'
          ? item.enchantments.first
          : null;

      // Get spec BiS recommendation for this slot
      final recommended = recommendation?.primaryEnchantForSlot(slotKey)?.name;

      results.add(_SlotResult(
        label: label,
        currentEnchant: rawEnchant,
        recommendedName: recommended,
      ));
    }

    if (results.isEmpty) return const [];

    final missing    = results.where((r) => !r.hasEnchant).toList();
    final suboptimal = results.where((r) => r.isSuboptimal).toList();
    final insights   = <CharacterInsight>[];

    if (missing.isNotEmpty) {
      final slots = missing.map((r) => r.label).toList();
      final count = slots.length;
      final specName = recommendation?.specName ??
          character.specialization ??
          'tu spec';

      insights.add(CharacterInsight(
        category: InsightCategory.enchantments,
        severity: InsightSeverity.critical,
        title: '$count encantamiento${count > 1 ? 's' : ''} sin aplicar',
        description: 'Sin encantamiento en: ${slots.join(', ')}.',
        simpleExplanation:
            'Los encantamientos dan bonificaciones de estadísticas permanentes a tu equipo. '
            'Son completamente gratis de aplicar y te hacen notablemente más fuerte. '
            'Los que faltan significan que eres más débil de lo que tu nivel de objeto sugiere.',
        advancedDetail:
            'Cada slot sin encantar es una pérdida plana de rendimiento. '
            'Prioridad: Anillos ≥ Pecho > Capa > Arma > Botas > Piernas > Muñequeras. '
            'Usa encantamientos específicos de $specName para anillos y armas.',
        actionItems: [
          'Visita un proveedor de Encantamiento o la Casa de Subastas',
          ...slots.map((s) => 'Encanta tu $s'),
          'Consulta la sección de Builds para los encantamientos BiS de tu spec',
        ],
      ));
    }

    if (suboptimal.isNotEmpty) {
      final count = suboptimal.length;
      insights.add(CharacterInsight(
        category: InsightCategory.enchantments,
        severity: InsightSeverity.warning,
        title: '$count encantamiento${count > 1 ? 's' : ''} suboptimo${count > 1 ? 's' : ''}',
        description: suboptimal
            .map((r) => '${r.label}: "${r.currentEnchant}" → usa "${r.recommendedName}"')
            .join('; '),
        simpleExplanation:
            'Tienes encantamientos — ¡bien! Pero no son los mejores para tu spec. '
            'Cambiarlos es barato y supone una mejora de rendimiento gratuita.',
        advancedDetail: suboptimal
            .map((r) =>
                '${r.label}: actual "${r.currentEnchant}" vs BiS "${r.recommendedName}"')
            .join(' · '),
        actionItems: suboptimal
            .map((r) => 'Cambia ${r.label}: "${r.currentEnchant}" por "${r.recommendedName}"')
            .toList(),
      ));
    }

    if (missing.isEmpty && suboptimal.isEmpty) {
      insights.add(const CharacterInsight(
        category: InsightCategory.enchantments,
        severity: InsightSeverity.positive,
        title: 'Todos los encantamientos aplicados',
        description: 'Cada slot que puede encantarse tiene un encantamiento.',
        simpleExplanation:
            'Perfecto — todo el equipo encantable está encantado. '
            'No estás perdiendo ningún stat gratuito.',
      ));
    }

    return insights;
  }
}
