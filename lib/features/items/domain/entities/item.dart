import 'package:equatable/equatable.dart';

enum TooltipEntityKind {
  item,
  spell;

  String get apiValue => switch (this) {
    TooltipEntityKind.item => 'item',
    TooltipEntityKind.spell => 'spell',
  };

  static TooltipEntityKind fromJsonValue(Object? raw) {
    final normalized = raw?.toString().trim().toLowerCase();
    return switch (normalized) {
      'spell' => TooltipEntityKind.spell,
      _ => TooltipEntityKind.item,
    };
  }
}

class Item extends Equatable {
  final int id;
  final String name;
  final String quality;
  final TooltipEntityKind lookupKind;
  final int? level;
  final int? requiredLevel;
  final String? itemClass;
  final String? itemSubclass;
  final String? inventoryType;
  final String? inventoryName;
  final String? iconUrl;
  final String? localizedName;
  final String? canonicalNameEn;

  const Item({
    required this.id,
    required this.name,
    required this.quality,
    this.lookupKind = TooltipEntityKind.item,
    this.level,
    this.requiredLevel,
    this.itemClass,
    this.itemSubclass,
    this.inventoryType,
    this.inventoryName,
    this.iconUrl,
    this.localizedName,
    this.canonicalNameEn,
  });

  /// Serialización reducida para persistencia en builds (solo campos necesarios).
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'quality': quality,
    'lookupKind': lookupKind.apiValue,
    'level': level,
    'iconUrl': iconUrl,
    'inventoryType': inventoryType,
    'inventoryName': inventoryName,
    'localizedName': localizedName,
    'canonicalNameEn': canonicalNameEn,
  };

  factory Item.fromJson(Map<String, dynamic> json) => Item(
    id: json['id'] as int,
    name: json['name'] as String,
    quality: json['quality'] as String? ?? 'COMMON',
    lookupKind: TooltipEntityKind.fromJsonValue(
      json['lookupKind'] ?? json['lookup_kind'],
    ),
    level: json['level'] as int?,
    iconUrl: json['iconUrl'] as String?,
    inventoryType: json['inventoryType'] as String?,
    inventoryName: json['inventoryName'] as String?,
    localizedName: json['localizedName'] as String?,
    canonicalNameEn: json['canonicalNameEn'] as String?,
  );

  @override
  List<Object?> get props => [
    id,
    name,
    quality,
    lookupKind,
    level,
    inventoryType,
    localizedName,
    canonicalNameEn,
  ];
}
