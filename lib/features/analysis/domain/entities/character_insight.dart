import 'package:equatable/equatable.dart';

// ─── Enums ────────────────────────────────────────────────────────────────────

enum InsightSeverity {
  /// Leaving significant power on the table. Fix ASAP.
  critical,

  /// Suboptimal but minor. Worth improving.
  warning,

  /// Informational / contextual. No action required.
  info,

  /// Everything looks good in this category.
  positive,
}

enum InsightCategory {
  enchantments,
  gems,
  contentReadiness,
  stats,
  gearProgress,
}

// ─── CharacterInsight ─────────────────────────────────────────────────────────

/// A single actionable analysis finding for a character.
///
/// Works at two detail levels:
/// - [simpleExplanation] — plain language for casual players
/// - [advancedDetail]   — precise technical detail for veterans
///
/// Text is in English. i18n can be layered on top later.
class CharacterInsight extends Equatable {
  final InsightCategory category;
  final InsightSeverity severity;

  /// Short headline — shown in collapsed state.
  final String title;

  /// One-sentence actionable description.
  final String description;

  /// Plain-language version: explains *why* it matters.
  final String simpleExplanation;

  /// Technical detail: mechanics, DR thresholds, specific numbers.
  final String? advancedDetail;

  /// Ordered list of concrete next steps.
  final List<String> actionItems;

  const CharacterInsight({
    required this.category,
    required this.severity,
    required this.title,
    required this.description,
    required this.simpleExplanation,
    this.advancedDetail,
    this.actionItems = const [],
  });

  bool get requiresAction =>
      severity == InsightSeverity.critical ||
      severity == InsightSeverity.warning;

  @override
  List<Object?> get props => [category, severity, title, description];
}
