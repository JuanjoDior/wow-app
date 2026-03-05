import 'package:equatable/equatable.dart';

class WeeklyPlannerFacts extends Equatable {
  final int equippedItemsCount;
  final int enchantedItemsCount;
  final int socketsTotalCount;
  final int socketsFilledCount;
  final int socketsEmptyCount;

  const WeeklyPlannerFacts({
    required this.equippedItemsCount,
    required this.enchantedItemsCount,
    required this.socketsTotalCount,
    required this.socketsFilledCount,
    required this.socketsEmptyCount,
  });

  factory WeeklyPlannerFacts.fromJson(Map<String, dynamic> json) {
    return WeeklyPlannerFacts(
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

class WeeklyPlannerMythic extends Equatable {
  final double? rating;
  final int weeklyRunsEstimated;
  final int? weeklyBestLevel;
  final int? seasonBestLevel;

  const WeeklyPlannerMythic({
    this.rating,
    required this.weeklyRunsEstimated,
    this.weeklyBestLevel,
    this.seasonBestLevel,
  });

  factory WeeklyPlannerMythic.fromJson(Map<String, dynamic> json) {
    return WeeklyPlannerMythic(
      rating: (json['rating'] as num?)?.toDouble(),
      weeklyRunsEstimated:
          (json['weekly_runs_estimated'] as num?)?.toInt() ?? 0,
      weeklyBestLevel: (json['weekly_best_level'] as num?)?.toInt(),
      seasonBestLevel: (json['season_best_level'] as num?)?.toInt(),
    );
  }

  @override
  List<Object?> get props => [
    rating,
    weeklyRunsEstimated,
    weeklyBestLevel,
    seasonBestLevel,
  ];
}

class WeeklyPlannerSummary extends Equatable {
  final String? analysisMode;
  final int checksTotal;
  final int checksCompleted;
  final int completionPct;
  final int missingEnchants;
  final int missingGems;
  final int weeklyRunsEstimated;
  final int actionsCount;

  const WeeklyPlannerSummary({
    this.analysisMode,
    required this.checksTotal,
    required this.checksCompleted,
    required this.completionPct,
    required this.missingEnchants,
    required this.missingGems,
    required this.weeklyRunsEstimated,
    required this.actionsCount,
  });

  factory WeeklyPlannerSummary.fromJson(Map<String, dynamic> json) {
    return WeeklyPlannerSummary(
      analysisMode: json['analysis_mode'] as String?,
      checksTotal: (json['checks_total'] as num?)?.toInt() ?? 0,
      checksCompleted: (json['checks_completed'] as num?)?.toInt() ?? 0,
      completionPct: (json['completion_pct'] as num?)?.toInt() ?? 0,
      missingEnchants: (json['missing_enchants'] as num?)?.toInt() ?? 0,
      missingGems: (json['missing_gems'] as num?)?.toInt() ?? 0,
      weeklyRunsEstimated:
          (json['weekly_runs_estimated'] as num?)?.toInt() ?? 0,
      actionsCount: (json['actions_count'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [
    analysisMode,
    checksTotal,
    checksCompleted,
    completionPct,
    missingEnchants,
    missingGems,
    weeklyRunsEstimated,
    actionsCount,
  ];
}

class WeeklyPlannerChecklistItem extends Equatable {
  final String id;
  final String label;
  final int current;
  final int target;
  final int remaining;
  final bool done;
  final String? source;

  const WeeklyPlannerChecklistItem({
    required this.id,
    required this.label,
    required this.current,
    required this.target,
    required this.remaining,
    required this.done,
    this.source,
  });

  factory WeeklyPlannerChecklistItem.fromJson(Map<String, dynamic> json) {
    return WeeklyPlannerChecklistItem(
      id: json['id'] as String? ?? '',
      label: json['label'] as String? ?? '',
      current: (json['current'] as num?)?.toInt() ?? 0,
      target: (json['target'] as num?)?.toInt() ?? 0,
      remaining: (json['remaining'] as num?)?.toInt() ?? 0,
      done: json['done'] == true,
      source: json['source'] as String?,
    );
  }

  @override
  List<Object?> get props => [
    id,
    label,
    current,
    target,
    remaining,
    done,
    source,
  ];
}

class WeeklyPlannerAction extends Equatable {
  final int priorityScore;
  final String type;
  final String label;
  final int remaining;
  final String? source;

  const WeeklyPlannerAction({
    required this.priorityScore,
    required this.type,
    required this.label,
    required this.remaining,
    this.source,
  });

  factory WeeklyPlannerAction.fromJson(Map<String, dynamic> json) {
    return WeeklyPlannerAction(
      priorityScore: (json['priority_score'] as num?)?.toInt() ?? 0,
      type: json['type'] as String? ?? '',
      label: json['label'] as String? ?? '',
      remaining: (json['remaining'] as num?)?.toInt() ?? 0,
      source: json['source'] as String?,
    );
  }

  @override
  List<Object?> get props => [priorityScore, type, label, remaining, source];
}

class WeeklyPlanner extends Equatable {
  final String? version;
  final String? endpoint;
  final String region;
  final String realm;
  final String name;
  final WeeklyPlannerFacts facts;
  final WeeklyPlannerMythic mythic;
  final WeeklyPlannerSummary summary;
  final List<String> affixes;
  final List<WeeklyPlannerChecklistItem> checklist;
  final List<WeeklyPlannerAction> actions;

  const WeeklyPlanner({
    this.version,
    this.endpoint,
    required this.region,
    required this.realm,
    required this.name,
    required this.facts,
    required this.mythic,
    required this.summary,
    this.affixes = const [],
    this.checklist = const [],
    this.actions = const [],
  });

  factory WeeklyPlanner.fromJson(Map<String, dynamic> json) {
    final context = (json['context'] as Map?)?.cast<String, dynamic>() ?? {};
    final factsRaw = (json['facts'] as Map?)?.cast<String, dynamic>() ?? {};
    final mythicRaw = (json['mythic'] as Map?)?.cast<String, dynamic>() ?? {};
    final summaryRaw = (json['summary'] as Map?)?.cast<String, dynamic>() ?? {};
    final affixesRaw = (json['affixes'] as Map?)?.cast<String, dynamic>() ?? {};
    final checklistRaw =
        (json['checklist'] as List?)?.whereType<Map>() ?? const [];
    final actionsRaw = (json['actions'] as List?)?.whereType<Map>() ?? const [];

    return WeeklyPlanner(
      version: json['version'] as String?,
      endpoint: json['endpoint'] as String?,
      region: context['region'] as String? ?? '',
      realm: context['realm'] as String? ?? '',
      name: context['name'] as String? ?? '',
      facts: WeeklyPlannerFacts.fromJson(factsRaw),
      mythic: WeeklyPlannerMythic.fromJson(mythicRaw),
      summary: WeeklyPlannerSummary.fromJson(summaryRaw),
      affixes: (affixesRaw['current'] as List<dynamic>? ?? [])
          .map((value) => value.toString())
          .where((value) => value.trim().isNotEmpty)
          .toList(),
      checklist: checklistRaw
          .map(
            (value) => WeeklyPlannerChecklistItem.fromJson(
              value.cast<String, dynamic>(),
            ),
          )
          .toList(),
      actions: actionsRaw
          .map(
            (value) =>
                WeeklyPlannerAction.fromJson(value.cast<String, dynamic>()),
          )
          .toList(),
    );
  }

  @override
  List<Object?> get props => [
    version,
    endpoint,
    region,
    realm,
    name,
    facts,
    mythic,
    summary,
    affixes,
    checklist,
    actions,
  ];
}
