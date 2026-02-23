import 'package:wow_companion/core/data/wow_static_recommendations.dart';
import 'package:wow_companion/features/analysis/domain/entities/character_insight.dart';
import 'package:wow_companion/features/analysis/domain/entities/gear_snapshot.dart';
import 'package:wow_companion/features/analysis/domain/services/analyzers/content_readiness_analyzer.dart';
import 'package:wow_companion/features/analysis/domain/services/analyzers/enchantment_analyzer.dart';
import 'package:wow_companion/features/analysis/domain/services/analyzers/gear_progress_analyzer.dart';
import 'package:wow_companion/features/analysis/domain/services/analyzers/gem_analyzer.dart';
import 'package:wow_companion/features/analysis/domain/services/analyzers/stat_weight_analyzer.dart';
import 'package:wow_companion/features/builds/domain/entities/spec_recommendation.dart';
import 'package:wow_companion/features/character/domain/entities/character.dart';

/// Analysis result returned from [CharacterAnalysisService].
class CharacterAnalysisResult {
  final List<CharacterInsight> insights;
  final String? specKey; // e.g. "mage:frost"

  const CharacterAnalysisResult({
    required this.insights,
    this.specKey,
  });

  /// All insights that require immediate action.
  List<CharacterInsight> get criticalInsights => insights
      .where((i) => i.severity == InsightSeverity.critical)
      .toList();

  /// All insights that are warnings (suboptimal but not critical).
  List<CharacterInsight> get warningInsights => insights
      .where((i) => i.severity == InsightSeverity.warning)
      .toList();

  /// Positive findings (everything good in this category).
  List<CharacterInsight> get positiveInsights => insights
      .where((i) => i.severity == InsightSeverity.positive)
      .toList();

  /// Total number of issues found (critical + warning).
  int get issueCount => criticalInsights.length + warningInsights.length;

  bool get hasIssues => issueCount > 0;
}

/// Orchestrates all character analyzers and returns a complete result.
///
/// Pipeline:
///   1. Resolve SpecRecommendation from static data (class + spec lookup)
///   2. EnchantmentAnalyzer  → missing/suboptimal enchants
///   3. GemAnalyzer          → meta gem + 4-color coverage
///   4. ContentReadinessAnalyzer → ilvl tier + readiness summary (+ M+ score)
///   5. StatWeightAnalyzer   → secondary stat distribution vs spec priority
///   6. GearProgressAnalyzer → ilvl/score evolution between sessions
///
/// All analysis runs synchronously and in-process — zero network calls.
/// Latency is O(equipment.length) ≈ <1ms.
/// The optional [previousSnapshot] is loaded asynchronously by the cubit
/// before calling [analyze].
class CharacterAnalysisService {
  const CharacterAnalysisService();

  // Analyzer instances are stateless — safe to share
  static const _enchants  = EnchantmentAnalyzer();
  static const _gems      = GemAnalyzer();
  static const _readiness = ContentReadinessAnalyzer();
  static const _stats     = StatWeightAnalyzer();
  static const _progress  = GearProgressAnalyzer();

  CharacterAnalysisResult analyze(
    Character character, {
    GearSnapshot? previousSnapshot,
  }) {
    // 1. Resolve spec recommendation (null-safe — falls back gracefully)
    final recommendation = _resolveRecommendation(character);
    final specKey = recommendation != null
        ? '${recommendation.className}:${recommendation.specName}'
        : null;

    // 2. Run enchantment analysis first — we need the missing count for readiness
    final enchantInsights = _enchants.analyze(character, recommendation);

    // Count missing enchants for readiness context
    final missingEnchantCount = enchantInsights
        .where((i) =>
            i.category == InsightCategory.enchantments &&
            i.severity == InsightSeverity.critical)
        .fold<int>(0, (sum, i) {
          // Extract count from title: "3 enchantments missing"
          final match = RegExp(r'^(\d+)').firstMatch(i.title);
          return sum + (match != null ? int.tryParse(match.group(1)!) ?? 1 : 1);
        });

    // 3. Gem analysis
    final gemInsights = _gems.analyze(character, recommendation);

    // 4. Content readiness (ilvl + M+ score como contexto)
    final readinessInsights = _readiness.analyze(
      character,
      missingEnchantCount: missingEnchantCount,
    );

    // 5. Stat weight distribution vs spec priority
    final statsInsights = _stats.analyze(character, recommendation);

    // 6. Gear progress (requiere snapshot previo cargado por el cubit)
    final progressInsights = _progress.analyze(
      character,
      previousSnapshot: previousSnapshot,
    );

    // 7. Combine: readiness → enchants → gems → stats → progress
    final all = [
      ...readinessInsights,
      ...enchantInsights,
      ...gemInsights,
      ...statsInsights,
      ...progressInsights,
    ];

    return CharacterAnalysisResult(
      insights: all,
      specKey: specKey,
    );
  }

  SpecRecommendation? _resolveRecommendation(Character character) {
    final className = character.characterClass.toLowerCase();
    final specName  = (character.specialization ?? '').toLowerCase();
    if (className.isEmpty || specName.isEmpty) return null;
    return WowStaticRecommendations.forSpec(className, specName);
  }
}
