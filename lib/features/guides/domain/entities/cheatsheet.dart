import 'package:equatable/equatable.dart';

class Cheatsheet extends Equatable {
  final String classSlug;
  final String specSlug;
  final String className;
  final String specName;
  final String role; // DPS, Healer, Tank
  final List<String> statPriority;
  final List<RotationStep> rotation;
  final List<ConsumableInfo> consumables;
  final List<String> tips;
  final String? lastUpdated;

  const Cheatsheet({
    required this.classSlug,
    required this.specSlug,
    required this.className,
    required this.specName,
    required this.role,
    required this.statPriority,
    required this.rotation,
    required this.consumables,
    this.tips = const [],
    this.lastUpdated,
  });

  String get id => '$classSlug-$specSlug';
  String get displayTitle => '$specName $className';

  factory Cheatsheet.fromJson(Map<String, dynamic> json) {
    return Cheatsheet(
      classSlug: json['class_slug'] as String,
      specSlug: json['spec_slug'] as String,
      className: json['class_name'] as String,
      specName: json['spec_name'] as String,
      role: json['role'] as String,
      statPriority: (json['stat_priority'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      rotation: (json['rotation'] as List<dynamic>)
          .map((e) => RotationStep.fromJson(e as Map<String, dynamic>))
          .toList(),
      consumables: (json['consumables'] as List<dynamic>)
          .map((e) => ConsumableInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      tips:
          (json['tips'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          const [],
      lastUpdated: json['last_updated'] as String?,
    );
  }

  @override
  List<Object?> get props => [classSlug, specSlug];
}

class RotationStep extends Equatable {
  final int priority;
  final String ability;
  final String condition;

  const RotationStep({
    required this.priority,
    required this.ability,
    this.condition = '',
  });

  factory RotationStep.fromJson(Map<String, dynamic> json) {
    return RotationStep(
      priority: json['priority'] as int,
      ability: json['ability'] as String,
      condition: json['condition'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [priority, ability];
}

class ConsumableInfo extends Equatable {
  final String type; // Flask, Food, Potion, Rune, Enchant
  final String name;
  final String? note;

  const ConsumableInfo({required this.type, required this.name, this.note});

  factory ConsumableInfo.fromJson(Map<String, dynamic> json) {
    return ConsumableInfo(
      type: json['type'] as String,
      name: json['name'] as String,
      note: json['note'] as String?,
    );
  }

  @override
  List<Object?> get props => [type, name];
}
