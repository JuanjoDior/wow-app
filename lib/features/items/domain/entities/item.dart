import 'package:equatable/equatable.dart';

class Item extends Equatable {
  final int id;
  final String name;
  final String quality;
  final int? level;
  final int? requiredLevel;
  final String? itemClass;
  final String? itemSubclass;
  final String? inventoryType;
  final String? inventoryName;
  final String? iconUrl;

  const Item({
    required this.id,
    required this.name,
    required this.quality,
    this.level,
    this.requiredLevel,
    this.itemClass,
    this.itemSubclass,
    this.inventoryType,
    this.inventoryName,
    this.iconUrl,
  });

  @override
  List<Object?> get props => [id, name, quality, level, inventoryType];
}
