import 'package:equatable/equatable.dart';
import 'package:wow_companion/features/items/domain/entities/item.dart';

enum TooltipSectionKind {
  meta,
  stats,
  effects,
  sockets,
  requirements,
  economy,
  source,
  misc,
  context;

  static TooltipSectionKind fromJsonValue(Object? raw) {
    final normalized = raw?.toString().trim().toLowerCase();
    return switch (normalized) {
      'stats' => TooltipSectionKind.stats,
      'effects' => TooltipSectionKind.effects,
      'sockets' => TooltipSectionKind.sockets,
      'requirements' => TooltipSectionKind.requirements,
      'economy' => TooltipSectionKind.economy,
      'source' => TooltipSectionKind.source,
      'misc' => TooltipSectionKind.misc,
      'context' => TooltipSectionKind.context,
      _ => TooltipSectionKind.meta,
    };
  }
}

enum TooltipLineLayout {
  text,
  labelValue,
  currency,
  bullet;

  static TooltipLineLayout fromJsonValue(Object? raw) {
    final normalized = raw?.toString().trim().toLowerCase();
    return switch (normalized) {
      'labelvalue' || 'label_value' => TooltipLineLayout.labelValue,
      'currency' => TooltipLineLayout.currency,
      'bullet' => TooltipLineLayout.bullet,
      _ => TooltipLineLayout.text,
    };
  }
}

enum TooltipLineTone {
  quality,
  gold,
  positive,
  neutral,
  muted,
  flavor,
  warning;

  static TooltipLineTone fromJsonValue(Object? raw) {
    final normalized = raw?.toString().trim().toLowerCase();
    return switch (normalized) {
      'quality' => TooltipLineTone.quality,
      'gold' => TooltipLineTone.gold,
      'positive' => TooltipLineTone.positive,
      'muted' => TooltipLineTone.muted,
      'flavor' => TooltipLineTone.flavor,
      'warning' => TooltipLineTone.warning,
      _ => TooltipLineTone.neutral,
    };
  }
}

class TooltipDetail extends Equatable {
  final TooltipEntityKind entityKind;
  final int id;
  final String name;
  final String? localizedName;
  final String? canonicalNameEn;
  final String? quality;
  final String? iconUrl;
  final TooltipHeader header;
  final List<TooltipSection> sections;
  final TooltipExternalLinks externalLinks;

  const TooltipDetail({
    required this.entityKind,
    required this.id,
    required this.name,
    this.localizedName,
    this.canonicalNameEn,
    this.quality,
    this.iconUrl,
    this.header = const TooltipHeader(),
    this.sections = const [],
    this.externalLinks = const TooltipExternalLinks(),
  });

  factory TooltipDetail.fromJson(Map<String, dynamic> json) {
    final sectionsRaw = json['sections'] as List<dynamic>? ?? const [];
    return TooltipDetail(
      entityKind: TooltipEntityKind.fromJsonValue(
        json['entityKind'] ?? json['entity_kind'],
      ),
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      localizedName:
          json['localizedName'] as String? ?? json['name_localized'] as String?,
      canonicalNameEn:
          json['canonicalNameEn'] as String? ?? json['name_en_us'] as String?,
      quality: json['quality'] as String?,
      iconUrl: json['iconUrl'] as String? ?? json['icon_url'] as String?,
      header: json['header'] is Map<String, dynamic>
          ? TooltipHeader.fromJson(json['header'] as Map<String, dynamic>)
          : const TooltipHeader(),
      sections: sectionsRaw
          .whereType<Map<String, dynamic>>()
          .map(TooltipSection.fromJson)
          .toList(growable: false),
      externalLinks: json['externalLinks'] is Map<String, dynamic>
          ? TooltipExternalLinks.fromJson(
              json['externalLinks'] as Map<String, dynamic>,
            )
          : json['external_links'] is Map<String, dynamic>
          ? TooltipExternalLinks.fromJson(
              json['external_links'] as Map<String, dynamic>,
            )
          : const TooltipExternalLinks(),
    );
  }

  String primaryNameForLanguage(String languageCode) {
    final normalized = languageCode.trim().toLowerCase();
    final localized = localizedName?.trim();
    final canonical = canonicalNameEn?.trim();

    if (normalized == 'es') {
      if (localized != null && localized.isNotEmpty) return localized;
      if (canonical != null && canonical.isNotEmpty) return canonical;
      return name;
    }

    if (canonical != null && canonical.isNotEmpty) return canonical;
    if (localized != null && localized.isNotEmpty) return localized;
    return name;
  }

  String get effectiveQuality =>
      (quality?.trim().isNotEmpty ?? false) ? quality!.trim() : 'COMMON';

  @override
  List<Object?> get props => [
    entityKind,
    id,
    name,
    localizedName,
    canonicalNameEn,
    quality,
    iconUrl,
    header,
    sections,
    externalLinks,
  ];
}

class TooltipHeader extends Equatable {
  final int? itemLevel;
  final String? bindingText;
  final String? inventoryName;
  final String? subclassText;
  final String? damageText;
  final String? speedText;
  final String? damagePerSecondText;
  final String? weaponText;
  final String? armorText;
  final String? uniqueText;
  final String? heroText;
  final String? flavorText;

  const TooltipHeader({
    this.itemLevel,
    this.bindingText,
    this.inventoryName,
    this.subclassText,
    this.damageText,
    this.speedText,
    this.damagePerSecondText,
    this.weaponText,
    this.armorText,
    this.uniqueText,
    this.heroText,
    this.flavorText,
  });

  factory TooltipHeader.fromJson(Map<String, dynamic> json) => TooltipHeader(
    itemLevel:
        (json['itemLevel'] as num?)?.toInt() ??
        (json['item_level'] as num?)?.toInt(),
    bindingText:
        json['bindingText'] as String? ?? json['binding_text'] as String?,
    inventoryName:
        json['inventoryName'] as String? ?? json['inventory_name'] as String?,
    subclassText:
        json['subclassText'] as String? ?? json['subclass_text'] as String?,
    damageText: json['damageText'] as String? ?? json['damage_text'] as String?,
    speedText: json['speedText'] as String? ?? json['speed_text'] as String?,
    damagePerSecondText:
        json['damagePerSecondText'] as String? ??
        json['damage_per_second_text'] as String?,
    weaponText: json['weaponText'] as String? ?? json['weapon_text'] as String?,
    armorText: json['armorText'] as String? ?? json['armor_text'] as String?,
    uniqueText: json['uniqueText'] as String? ?? json['unique_text'] as String?,
    heroText: json['heroText'] as String? ?? json['hero_text'] as String?,
    flavorText: json['flavorText'] as String? ?? json['flavor_text'] as String?,
  );

  @override
  List<Object?> get props => [
    itemLevel,
    bindingText,
    inventoryName,
    subclassText,
    damageText,
    speedText,
    damagePerSecondText,
    weaponText,
    armorText,
    uniqueText,
    heroText,
    flavorText,
  ];
}

class TooltipSection extends Equatable {
  final TooltipSectionKind kind;
  final List<TooltipLine> lines;

  const TooltipSection({required this.kind, this.lines = const []});

  factory TooltipSection.fromJson(Map<String, dynamic> json) {
    final linesRaw = json['lines'] as List<dynamic>? ?? const [];
    return TooltipSection(
      kind: TooltipSectionKind.fromJsonValue(json['kind']),
      lines: linesRaw
          .whereType<Map<String, dynamic>>()
          .map(TooltipLine.fromJson)
          .toList(growable: false),
    );
  }

  @override
  List<Object?> get props => [kind, lines];
}

class TooltipLine extends Equatable {
  final TooltipLineLayout layout;
  final String? label;
  final String? text;
  final TooltipLineTone tone;
  final String? icon;
  final bool indent;
  final TooltipCurrency? currency;

  const TooltipLine({
    required this.layout,
    this.label,
    this.text,
    this.tone = TooltipLineTone.neutral,
    this.icon,
    this.indent = false,
    this.currency,
  });

  factory TooltipLine.fromJson(Map<String, dynamic> json) => TooltipLine(
    layout: TooltipLineLayout.fromJsonValue(json['layout']),
    label: json['label'] as String?,
    text: json['text'] as String?,
    tone: TooltipLineTone.fromJsonValue(json['tone']),
    icon: json['icon'] as String?,
    indent: json['indent'] as bool? ?? false,
    currency: json['currency'] is Map<String, dynamic>
        ? TooltipCurrency.fromJson(json['currency'] as Map<String, dynamic>)
        : (json['gold'] != null ||
              json['silver'] != null ||
              json['copper'] != null)
        ? TooltipCurrency.fromJson(json)
        : null,
  );

  @override
  List<Object?> get props => [
    layout,
    label,
    text,
    tone,
    icon,
    indent,
    currency,
  ];
}

class TooltipCurrency extends Equatable {
  final int gold;
  final int silver;
  final int copper;

  const TooltipCurrency({this.gold = 0, this.silver = 0, this.copper = 0});

  factory TooltipCurrency.fromJson(Map<String, dynamic> json) =>
      TooltipCurrency(
        gold: (json['gold'] as num?)?.toInt() ?? 0,
        silver: (json['silver'] as num?)?.toInt() ?? 0,
        copper: (json['copper'] as num?)?.toInt() ?? 0,
      );

  bool get isEmpty => gold == 0 && silver == 0 && copper == 0;

  @override
  List<Object?> get props => [gold, silver, copper];
}

class TooltipExternalLinks extends Equatable {
  final String? wowhead;

  const TooltipExternalLinks({this.wowhead});

  factory TooltipExternalLinks.fromJson(Map<String, dynamic> json) =>
      TooltipExternalLinks(wowhead: json['wowhead'] as String?);

  @override
  List<Object?> get props => [wowhead];
}

class TooltipContextAttachment extends Equatable {
  final List<int> bonusIds;
  final List<TooltipContextEntry> appliedEnchantments;
  final List<TooltipContextEntry> appliedGems;

  const TooltipContextAttachment({
    this.bonusIds = const [],
    this.appliedEnchantments = const [],
    this.appliedGems = const [],
  });

  bool get isEmpty =>
      bonusIds.isEmpty && appliedEnchantments.isEmpty && appliedGems.isEmpty;

  @override
  List<Object?> get props => [bonusIds, appliedEnchantments, appliedGems];
}

class TooltipContextEntry extends Equatable {
  final TooltipEntityKind entityKind;
  final int? id;
  final String name;
  final String? localizedName;
  final String? canonicalNameEn;

  const TooltipContextEntry({
    this.entityKind = TooltipEntityKind.item,
    this.id,
    required this.name,
    this.localizedName,
    this.canonicalNameEn,
  });

  factory TooltipContextEntry.fromItem(Item item) => TooltipContextEntry(
    entityKind: item.lookupKind,
    id: item.id > 0 ? item.id : null,
    name: item.name,
    localizedName: item.localizedName,
    canonicalNameEn: item.canonicalNameEn,
  );

  factory TooltipContextEntry.fromName(
    String name, {
    TooltipEntityKind entityKind = TooltipEntityKind.item,
  }) => TooltipContextEntry(entityKind: entityKind, name: name);

  String primaryNameForLanguage(String languageCode) {
    final normalized = languageCode.trim().toLowerCase();
    final localized = localizedName?.trim();
    final canonical = canonicalNameEn?.trim();

    if (normalized == 'es') {
      if (localized != null && localized.isNotEmpty) return localized;
      if (canonical != null && canonical.isNotEmpty) return canonical;
      return name;
    }

    if (canonical != null && canonical.isNotEmpty) return canonical;
    if (localized != null && localized.isNotEmpty) return localized;
    return name;
  }

  @override
  List<Object?> get props => [
    entityKind,
    id,
    name,
    localizedName,
    canonicalNameEn,
  ];
}
