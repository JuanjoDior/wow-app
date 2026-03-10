import 'package:wow_companion/features/items/domain/entities/item.dart';

class ItemModel extends Item {
  const ItemModel({
    required super.id,
    required super.name,
    required super.quality,
    super.lookupKind,
    super.level,
    super.requiredLevel,
    super.itemClass,
    super.itemSubclass,
    super.inventoryType,
    super.inventoryName,
    super.iconUrl,
    super.localizedName,
    super.canonicalNameEn,
  });

  factory ItemModel.fromJson(Map<String, dynamic> json) {
    return ItemModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? 'Unknown',
      quality: json['quality'] as String? ?? 'COMMON',
      lookupKind: TooltipEntityKind.fromJsonValue(
        json['lookupKind'] ?? json['lookup_kind'] ?? json['kind'],
      ),
      level: json['level'] as int?,
      requiredLevel: json['requiredLevel'] as int?,
      itemClass: json['itemClass'] as String?,
      itemSubclass: json['itemSubclass'] as String?,
      inventoryType: json['inventoryType'] as String?,
      inventoryName: json['inventoryName'] as String?,
      iconUrl: json['iconUrl'] as String?,
      localizedName: json['localizedName'] as String?,
      canonicalNameEn: json['canonicalNameEn'] as String?,
    );
  }
}
