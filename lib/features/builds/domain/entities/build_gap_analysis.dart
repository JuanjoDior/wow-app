import 'package:equatable/equatable.dart';

class BuildGapFacts extends Equatable {
  final int equippedItemsCount;
  final int enchantedItemsCount;
  final int socketsTotalCount;
  final int socketsFilledCount;
  final int socketsEmptyCount;

  const BuildGapFacts({
    required this.equippedItemsCount,
    required this.enchantedItemsCount,
    required this.socketsTotalCount,
    required this.socketsFilledCount,
    required this.socketsEmptyCount,
  });

  factory BuildGapFacts.fromJson(Map<String, dynamic> json) {
    return BuildGapFacts(
      equippedItemsCount: (json['equipped_items_count'] as num?)?.toInt() ?? 0,
      enchantedItemsCount:
          (json['enchanted_items_count'] as num?)?.toInt() ?? 0,
      socketsTotalCount: (json['sockets_total_count'] as num?)?.toInt() ?? 0,
      socketsFilledCount: (json['sockets_filled_count'] as num?)?.toInt() ?? 0,
      socketsEmptyCount: (json['sockets_empty_count'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [
    equippedItemsCount,
    enchantedItemsCount,
    socketsTotalCount,
    socketsFilledCount,
    socketsEmptyCount,
  ];
}

class BuildGapSummary extends Equatable {
  final String? analysisMode;
  final String? targetProfile;
  final int checksTotal;
  final int checksCompleted;
  final int completionPct;
  final int missingEnchants;
  final int missingGems;
  final int mismatchedEnchants;
  final int mismatchedGems;
  final int actionsCount;

  const BuildGapSummary({
    this.analysisMode,
    this.targetProfile,
    required this.checksTotal,
    required this.checksCompleted,
    required this.completionPct,
    required this.missingEnchants,
    required this.missingGems,
    this.mismatchedEnchants = 0,
    this.mismatchedGems = 0,
    required this.actionsCount,
  });

  factory BuildGapSummary.fromJson(Map<String, dynamic> json) {
    return BuildGapSummary(
      analysisMode: json['analysis_mode'] as String?,
      targetProfile: json['target_profile'] as String?,
      checksTotal: (json['checks_total'] as num?)?.toInt() ?? 0,
      checksCompleted: (json['checks_completed'] as num?)?.toInt() ?? 0,
      completionPct: (json['completion_pct'] as num?)?.toInt() ?? 0,
      missingEnchants: (json['missing_enchants'] as num?)?.toInt() ?? 0,
      missingGems: (json['missing_gems'] as num?)?.toInt() ?? 0,
      mismatchedEnchants: (json['mismatched_enchants'] as num?)?.toInt() ?? 0,
      mismatchedGems: (json['mismatched_gems'] as num?)?.toInt() ?? 0,
      actionsCount: (json['actions_count'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [
    analysisMode,
    targetProfile,
    checksTotal,
    checksCompleted,
    completionPct,
    missingEnchants,
    missingGems,
    mismatchedEnchants,
    mismatchedGems,
    actionsCount,
  ];
}

class BuildGapAction extends Equatable {
  final int priorityScore;
  final String slot;
  final String type;
  final String label;
  final String? recommended;
  final String? expected;
  final int? expectedId;
  final List<String> current;
  final String? estimatedImpact;
  final String? source;

  const BuildGapAction({
    required this.priorityScore,
    required this.slot,
    required this.type,
    required this.label,
    this.recommended,
    this.expected,
    this.expectedId,
    this.current = const [],
    this.estimatedImpact,
    this.source,
  });

  factory BuildGapAction.fromJson(Map<String, dynamic> json) {
    return BuildGapAction(
      priorityScore: (json['priority_score'] as num?)?.toInt() ?? 0,
      slot: json['slot'] as String? ?? '',
      type: json['type'] as String? ?? '',
      label: json['label'] as String? ?? '',
      recommended: json['recommended'] as String?,
      expected: json['expected'] as String?,
      expectedId: (json['expected_id'] as num?)?.toInt(),
      current: (json['current'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      estimatedImpact: json['estimated_impact'] as String?,
      source: json['source'] as String?,
    );
  }

  @override
  List<Object?> get props => [
    priorityScore,
    slot,
    type,
    label,
    recommended,
    expected,
    expectedId,
    current,
    estimatedImpact,
    source,
  ];
}

class BuildGapAnalysis extends Equatable {
  final String? version;
  final String? endpoint;
  final BuildGapFacts? facts;
  final BuildGapSummary summary;
  final List<BuildGapAction> actions;

  const BuildGapAnalysis({
    this.version,
    this.endpoint,
    this.facts,
    required this.summary,
    required this.actions,
  });

  factory BuildGapAnalysis.fromJson(Map<String, dynamic> json) {
    final factsRaw = json['facts'] as Map<String, dynamic>?;
    final summaryRaw = json['summary'] as Map<String, dynamic>? ?? {};
    final actionsRaw = json['actions'] as List<dynamic>? ?? [];
    return BuildGapAnalysis(
      version: json['version'] as String?,
      endpoint: json['endpoint'] as String?,
      facts: factsRaw != null ? BuildGapFacts.fromJson(factsRaw) : null,
      summary: BuildGapSummary.fromJson(summaryRaw),
      actions: actionsRaw
          .whereType<Map<String, dynamic>>()
          .map(BuildGapAction.fromJson)
          .toList(),
    );
  }

  @override
  List<Object?> get props => [version, endpoint, facts, summary, actions];
}
