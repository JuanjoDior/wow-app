import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wow_companion/core/cache/memory_cache.dart';
import 'package:wow_companion/core/di/injection.dart';
import 'package:wow_companion/core/l10n/locale_notifier.dart';
import 'package:wow_companion/core/theme/wow_theme.dart';
import 'package:wow_companion/features/character/domain/entities/character.dart';
import 'package:wow_companion/features/items/domain/entities/item.dart';
import 'package:wow_companion/features/items/domain/entities/tooltip_detail.dart';
import 'package:wow_companion/features/items/domain/usecases/get_tooltip_detail.dart';
import 'package:wow_companion/l10n/generated/app_localizations.dart';
import 'package:wow_companion/shared/widgets/wowhead_web_tooltip_anchor.dart';

enum ItemTooltipInteractionMode { detailMode, actionFirstMode }

class ItemTooltipDisplayData {
  final TooltipEntityKind entityKind;
  final int? itemId;
  final String name;
  final String? localizedName;
  final String? canonicalNameEn;
  final String quality;
  final int itemLevel;
  final int? requiredLevel;
  final String? slotLabel;
  final String? itemSubclass;
  final String? iconUrl;
  final TooltipContextAttachment contextAttachment;

  const ItemTooltipDisplayData({
    required this.entityKind,
    required this.itemId,
    required this.name,
    required this.quality,
    required this.itemLevel,
    required this.requiredLevel,
    required this.slotLabel,
    required this.itemSubclass,
    required this.iconUrl,
    required this.contextAttachment,
    this.localizedName,
    this.canonicalNameEn,
  });

  factory ItemTooltipDisplayData.fromSources({
    EquippedItem? equippedItem,
    Item? itemDetail,
    int? fallbackItemId,
    TooltipEntityKind entityKind = TooltipEntityKind.item,
    TooltipContextAttachment? contextAttachment,
  }) {
    final resolvedEntityKind = itemDetail?.lookupKind ?? entityKind;
    final fallbackContext =
        contextAttachment ?? _contextFromEquippedItem(equippedItem);
    final resolvedItemId =
        equippedItem?.itemId ?? itemDetail?.id ?? fallbackItemId;

    return ItemTooltipDisplayData(
      entityKind: resolvedEntityKind,
      itemId: resolvedItemId,
      name: _bestText(
        equippedItem?.name,
        itemDetail?.name,
        fallback: '',
        disallowUnknown: true,
      ),
      localizedName: itemDetail?.localizedName,
      canonicalNameEn: itemDetail?.canonicalNameEn,
      quality: _bestText(
        equippedItem?.quality,
        itemDetail?.quality,
        fallback: 'COMMON',
      ).toUpperCase(),
      itemLevel: _bestInt(
        equippedItem?.itemLevel,
        itemDetail?.level,
        fallback: 0,
        minValue: 1,
      ),
      requiredLevel: itemDetail?.requiredLevel,
      slotLabel: _bestText(
        _slotDisplayName(equippedItem?.slot),
        itemDetail?.inventoryName,
      ),
      itemSubclass: _bestText(itemDetail?.itemSubclass, null),
      iconUrl: _bestText(equippedItem?.iconUrl, itemDetail?.iconUrl),
      contextAttachment: fallbackContext,
    );
  }

  List<String> get enchantments => contextAttachment.appliedEnchantments
      .map((entry) => entry.name)
      .toList(growable: false);

  List<String> get gems => contextAttachment.appliedGems
      .map((entry) => entry.name)
      .toList(growable: false);

  List<int> get bonusIds => contextAttachment.bonusIds;

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

  String? get wowheadUrl {
    if (itemId == null) return null;
    if (entityKind == TooltipEntityKind.spell) {
      return 'https://www.wowhead.com/spell=$itemId';
    }

    final base = 'https://www.wowhead.com/item=$itemId';
    if (bonusIds.isNotEmpty) {
      return '$base&bonus=${bonusIds.join(':')}';
    }
    return base;
  }

  static TooltipContextAttachment _contextFromEquippedItem(
    EquippedItem? equippedItem,
  ) {
    if (equippedItem == null) return const TooltipContextAttachment();

    return TooltipContextAttachment(
      bonusIds: List<int>.from(equippedItem.bonusIds, growable: false),
      appliedEnchantments: [
        for (final enchant in equippedItem.enchantments)
          if (enchant.trim().isNotEmpty) TooltipContextEntry.fromName(enchant),
      ],
      appliedGems: [
        for (final gem in equippedItem.gems)
          if (gem.trim().isNotEmpty) TooltipContextEntry.fromName(gem),
      ],
    );
  }

  static String _bestText(
    String? primary,
    String? secondary, {
    String fallback = '',
    bool disallowUnknown = false,
  }) {
    for (final candidate in [primary, secondary]) {
      final normalized = candidate?.trim();
      if (normalized == null || normalized.isEmpty) continue;
      if (disallowUnknown && normalized.toLowerCase() == 'unknown') continue;
      return normalized;
    }
    return fallback;
  }

  static int _bestInt(
    int? primary,
    int? secondary, {
    required int fallback,
    int? minValue,
  }) {
    for (final candidate in [primary, secondary]) {
      if (candidate == null) continue;
      if (minValue != null && candidate < minValue) continue;
      return candidate;
    }
    return fallback;
  }

  static String? _slotDisplayName(String? slotCode) {
    if (slotCode == null || slotCode.trim().isEmpty) return null;
    return slotCode
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (w) => w.isEmpty
              ? w
              : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}',
        )
        .join(' ');
  }
}

class ItemTooltipOverlayCard extends StatelessWidget {
  final ItemTooltipDisplayData fallbackData;
  final TooltipDetail? detail;
  final bool loading;
  final bool unavailable;

  const ItemTooltipOverlayCard({
    super.key,
    required this.fallbackData,
    this.detail,
    this.loading = false,
    this.unavailable = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = S.of(context)!;
    final localeCode = Localizations.localeOf(context).languageCode;
    final displayName =
        detail?.primaryNameForLanguage(localeCode) ??
        fallbackData.primaryNameForLanguage(localeCode);
    final quality =
        detail?.effectiveQuality.trim().toUpperCase() ??
        fallbackData.quality.trim().toUpperCase();
    final qualityColor = WowTheme.getQualityColor(quality);
    final iconUrl = detail?.iconUrl ?? fallbackData.iconUrl;
    final itemLevel = detail?.header.itemLevel ?? fallbackData.itemLevel;
    final detailSections = _orderedSections(detail?.sections ?? const []);
    final fallbackMetaLines = _fallbackMetaLines(
      t,
      detail?.header,
      detailSections,
    );
    final contextAttachment = fallbackData.contextAttachment;
    final wowheadUrl = detail?.externalLinks.wowhead ?? fallbackData.wowheadUrl;
    final width = math.min(
      360.0,
      math.max(260.0, MediaQuery.sizeOf(context).width - 16),
    );
    final maxHeight = math.min(560.0, MediaQuery.sizeOf(context).height * 0.72);

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: width, maxHeight: maxHeight),
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: const Color(0xFF0A1022),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: qualityColor, width: 1.3),
          boxShadow: [
            BoxShadow(
              color: qualityColor.withValues(alpha: 0.28),
              blurRadius: 16,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TooltipHeaderBlock(
              iconUrl: iconUrl,
              qualityColor: qualityColor,
              title: displayName.isEmpty ? t.unknownItem : displayName,
              itemLevel: itemLevel > 0 ? itemLevel : null,
              quality: quality,
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ..._buildHeaderMetaLines(detail?.header, qualityColor),
                    if (fallbackMetaLines.isNotEmpty) ...[
                      ...fallbackMetaLines,
                      if (detailSections.isNotEmpty ||
                          !contextAttachment.isEmpty ||
                          wowheadUrl != null ||
                          loading ||
                          unavailable)
                        const SizedBox(height: 8),
                    ],
                    for (final section in detailSections)
                      _TooltipSectionBlock(
                        title: _sectionTitle(context, section.kind),
                        lines: section.lines,
                        qualityColor: qualityColor,
                        fallbackSellPriceLabel: t.tooltipSellPrice,
                      ),
                    if (loading && detail == null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2, bottom: 8),
                        child: Text(
                          t.tooltipLoading,
                          style: const TextStyle(
                            color: WowTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    if (unavailable && detail == null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2, bottom: 8),
                        child: Text(
                          t.tooltipUnavailable,
                          style: const TextStyle(
                            color: WowTheme.textSecondary,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    if (!contextAttachment.isEmpty)
                      _TooltipContextBlock(
                        contextAttachment: contextAttachment,
                      ),
                    if (wowheadUrl != null) ...[
                      if (detailSections.isNotEmpty ||
                          fallbackMetaLines.isNotEmpty ||
                          !contextAttachment.isEmpty)
                        const Divider(color: WowTheme.border, height: 18),
                      InkWell(
                        onTap: () => _openWowhead(wowheadUrl),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.open_in_new,
                              size: 14,
                              color: Color(0xFFFF8040),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              t.viewOnWowhead,
                              style: const TextStyle(
                                color: Color(0xFFFF8040),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildHeaderMetaLines(
    TooltipHeader? header,
    Color qualityColor,
  ) {
    if (header == null) return const [];

    final lines = <Widget>[];
    void addText(String? text, {Color? color, FontStyle? fontStyle}) {
      final normalized = text?.trim();
      if (normalized == null || normalized.isEmpty) return;
      if (lines.isNotEmpty) lines.add(const SizedBox(height: 2));
      lines.add(
        Text(
          normalized,
          style: TextStyle(
            color: color ?? WowTheme.textPrimary,
            fontSize: 12,
            fontStyle: fontStyle,
          ),
        ),
      );
    }

    addText(header.bindingText);

    final inventoryRow = _buildMetaPairRow(
      primary: header.inventoryName,
      secondary: header.subclassText,
      color: WowTheme.textPrimary,
    );
    if (inventoryRow != null) {
      lines.add(inventoryRow);
      lines.add(const SizedBox(height: 2));
    }

    final weaponRow = _buildMetaPairRow(
      primary: header.damageText,
      secondary: header.speedText,
      color: WowTheme.textPrimary,
    );
    if (weaponRow != null) {
      lines.add(weaponRow);
      lines.add(const SizedBox(height: 2));
    }

    addText(header.damagePerSecondText);
    if ((header.damageText?.trim().isEmpty ?? true) &&
        (header.speedText?.trim().isEmpty ?? true)) {
      addText(header.weaponText);
    }
    addText(header.armorText);
    addText(header.uniqueText, color: WowTheme.primaryGold);
    addText(header.heroText, color: qualityColor);
    addText(
      header.flavorText,
      color: WowTheme.textSecondary,
      fontStyle: FontStyle.italic,
    );

    if (lines.isNotEmpty) {
      lines.add(const SizedBox(height: 8));
    }
    return lines;
  }

  Widget? _buildMetaPairRow({
    required String? primary,
    required String? secondary,
    required Color color,
  }) {
    final left = primary?.trim();
    final right = secondary?.trim();
    if ((left == null || left.isEmpty) && (right == null || right.isEmpty)) {
      return null;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            left ?? '',
            style: TextStyle(color: color, fontSize: 12, height: 1.2),
          ),
        ),
        if (right != null && right.isNotEmpty) ...[
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              right,
              textAlign: TextAlign.end,
              style: TextStyle(color: color, fontSize: 12, height: 1.2),
            ),
          ),
        ],
      ],
    );
  }

  List<Widget> _fallbackMetaLines(
    S t,
    TooltipHeader? header,
    List<TooltipSection> detailSections,
  ) {
    final lines = <Widget>[];
    final hasRequirementsSection = detailSections.any(
      (section) => section.kind == TooltipSectionKind.requirements,
    );
    final hasHeaderInventory =
        header?.inventoryName?.trim().isNotEmpty ?? false;
    final hasHeaderSubclass = header?.subclassText?.trim().isNotEmpty ?? false;

    if (!hasRequirementsSection && fallbackData.requiredLevel != null) {
      lines.add(
        _TooltipLabelValueRow(
          label: t.tooltipRequiredLevel,
          value: '${fallbackData.requiredLevel}',
          tone: TooltipLineTone.neutral,
          qualityColor: WowTheme.textPrimary,
        ),
      );
    }
    if (!hasHeaderInventory && fallbackData.slotLabel != null) {
      lines.add(
        _TooltipLabelValueRow(
          label: t.slot,
          value: fallbackData.slotLabel!,
          tone: TooltipLineTone.neutral,
          qualityColor: WowTheme.textPrimary,
        ),
      );
    }
    if (!hasHeaderSubclass && fallbackData.itemSubclass != null) {
      lines.add(
        _TooltipLabelValueRow(
          label: t.tooltipType,
          value: fallbackData.itemSubclass!,
          tone: TooltipLineTone.neutral,
          qualityColor: WowTheme.textPrimary,
        ),
      );
    }
    return lines;
  }

  List<TooltipSection> _orderedSections(List<TooltipSection> input) {
    final order = <TooltipSectionKind>[
      TooltipSectionKind.stats,
      TooltipSectionKind.effects,
      TooltipSectionKind.sockets,
      TooltipSectionKind.requirements,
      TooltipSectionKind.economy,
      TooltipSectionKind.source,
      TooltipSectionKind.misc,
      TooltipSectionKind.meta,
      TooltipSectionKind.context,
    ];

    final items = input.where((section) => section.lines.isNotEmpty).toList();
    items.sort((a, b) {
      final leftIndex = order.indexOf(a.kind);
      final rightIndex = order.indexOf(b.kind);
      return leftIndex.compareTo(rightIndex);
    });
    return items;
  }

  String? _sectionTitle(BuildContext context, TooltipSectionKind kind) {
    final t = S.of(context)!;
    return switch (kind) {
      TooltipSectionKind.effects => t.tooltipEffects,
      TooltipSectionKind.sockets => t.tooltipSockets,
      TooltipSectionKind.requirements => t.tooltipRequirements,
      TooltipSectionKind.source => t.tooltipSource,
      _ => null,
    };
  }

  Future<void> _openWowhead(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class ItemTooltipTrigger extends StatefulWidget {
  final Widget child;
  final ItemTooltipInteractionMode mode;
  final VoidCallback? onPrimaryTap;
  final bool enableWebOfficialTooltip;
  final TooltipEntityKind entityKind;
  final EquippedItem? equippedItem;
  final int? itemId;
  final Item? fallbackItem;
  final TooltipContextAttachment contextAttachment;
  final String region;

  ItemTooltipTrigger.forEquippedItem({
    super.key,
    required EquippedItem this.equippedItem,
    required this.child,
    this.mode = ItemTooltipInteractionMode.detailMode,
    this.onPrimaryTap,
    this.enableWebOfficialTooltip = true,
    this.region = 'eu',
  }) : entityKind = TooltipEntityKind.item,
       itemId = equippedItem.itemId,
       fallbackItem = null,
       contextAttachment = TooltipContextAttachment(
         bonusIds: equippedItem.bonusIds,
         appliedEnchantments: [
           for (final enchant in equippedItem.enchantments)
             if (enchant.trim().isNotEmpty)
               TooltipContextEntry.fromName(enchant),
         ],
         appliedGems: [
           for (final gem in equippedItem.gems)
             if (gem.trim().isNotEmpty) TooltipContextEntry.fromName(gem),
         ],
       );

  const ItemTooltipTrigger.forItemId({
    super.key,
    required this.itemId,
    required this.child,
    this.mode = ItemTooltipInteractionMode.detailMode,
    this.onPrimaryTap,
    this.enableWebOfficialTooltip = true,
    this.entityKind = TooltipEntityKind.item,
    this.fallbackItem,
    this.contextAttachment = const TooltipContextAttachment(),
    this.region = 'eu',
  }) : equippedItem = null;

  @override
  State<ItemTooltipTrigger> createState() => _ItemTooltipTriggerState();
}

class _ItemTooltipTriggerState extends State<ItemTooltipTrigger> {
  static final MemoryCache<TooltipDetail> _tooltipCache =
      MemoryCache<TooltipDetail>(ttl: const Duration(minutes: 10));
  static final Map<String, Future<TooltipDetail?>> _inflightRequests = {};
  static const _cacheVersion = 'tooltip-v2';

  final LayerLink _layerLink = LayerLink();

  OverlayEntry? _overlayEntry;
  Timer? _hoverOpenTimer;
  Timer? _hoverCloseTimer;
  TooltipDetail? _cachedTooltipDetail;
  bool _loadingTooltip = false;
  bool _hoveringTarget = false;
  bool _hoveringOverlay = false;
  bool _showBelow = false;
  bool _detailUnavailable = false;

  int? get _effectiveItemId => widget.itemId ?? widget.fallbackItem?.id;

  TooltipEntityKind get _effectiveEntityKind =>
      widget.fallbackItem?.lookupKind ?? widget.entityKind;

  String get _cacheKey {
    final itemId = _effectiveItemId;
    if (itemId == null) return '';
    return [
      _cacheVersion,
      _effectiveEntityKind.apiValue,
      itemId,
      _resolvedBlizzardLocale,
      widget.region.toLowerCase(),
      ...widget.contextAttachment.bonusIds,
    ].join(':');
  }

  String get _resolvedBlizzardLocale {
    if (sl.isRegistered<LocaleNotifier>()) {
      return sl<LocaleNotifier>().blizzardLocale;
    }

    final locale = Localizations.maybeLocaleOf(context);
    return locale?.languageCode.toLowerCase() == 'es' ? 'es_ES' : 'en_GB';
  }

  @override
  void dispose() {
    _hoverOpenTimer?.cancel();
    _hoverCloseTimer?.cancel();
    _removeOverlay();
    super.dispose();
  }

  bool _hasMousePointer(BuildContext context) {
    return RendererBinding.instance.mouseTracker.mouseIsConnected;
  }

  bool _shouldUseOfficialWebTooltip(BuildContext context) {
    return false;
  }

  bool _shouldUseNativeHover(BuildContext context) {
    return false;
  }

  bool _shouldHandleTapForDetails(BuildContext context) {
    if (widget.mode != ItemTooltipInteractionMode.detailMode) return false;
    if (!_hasMousePointer(context)) return true;
    return !_shouldUseOfficialWebTooltip(context);
  }

  String _wowheadDomain(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode.toLowerCase();
    return lang == 'es' ? 'es' : 'www';
  }

  Future<void> _fetchTooltipDetailIfNeeded() async {
    final itemId = _effectiveItemId;
    if (itemId == null || _cachedTooltipDetail != null || _loadingTooltip) {
      return;
    }

    final cacheKey = _cacheKey;
    final cached = _tooltipCache.get(cacheKey);
    if (cached != null) {
      _cachedTooltipDetail = cached;
      _detailUnavailable = false;
      return;
    }

    _loadingTooltip = true;
    _overlayEntry?.markNeedsBuild();

    if (!sl.isRegistered<GetTooltipDetail>()) {
      _loadingTooltip = false;
      _detailUnavailable = true;
      _overlayEntry?.markNeedsBuild();
      return;
    }

    final future = _inflightRequests.putIfAbsent(cacheKey, () async {
      final result = await sl<GetTooltipDetail>()(
        _effectiveEntityKind,
        itemId,
        locale: _resolvedBlizzardLocale,
        region: widget.region,
        bonusIds: widget.contextAttachment.bonusIds,
      );
      return result.fold<TooltipDetail?>((_) => null, (detail) => detail);
    });

    final detail = await future;
    if (identical(_inflightRequests[cacheKey], future)) {
      _inflightRequests.remove(cacheKey);
    }

    _loadingTooltip = false;
    _detailUnavailable = detail == null;
    if (detail != null) {
      _cachedTooltipDetail = detail;
      _tooltipCache.set(cacheKey, detail);
    }
  }

  ItemTooltipDisplayData _buildDisplayData() {
    return ItemTooltipDisplayData.fromSources(
      equippedItem: widget.equippedItem,
      itemDetail: widget.fallbackItem,
      fallbackItemId: _effectiveItemId,
      entityKind: _effectiveEntityKind,
      contextAttachment: widget.contextAttachment,
    );
  }

  Future<void> _toggleNativeTooltip() async {
    if (_overlayEntry != null) {
      _removeOverlay();
      return;
    }
    await _showNativeTooltip();
  }

  Future<void> _showNativeTooltip() async {
    _updateDirection();
    _removeOverlay();

    final overlay = Overlay.of(context);
    _overlayEntry = _buildOverlayEntry();
    overlay.insert(_overlayEntry!);

    await _fetchTooltipDetailIfNeeded();
    if (!mounted || _overlayEntry == null) return;
    _overlayEntry!.markNeedsBuild();
  }

  void _updateDirection() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) {
      _showBelow = false;
      return;
    }

    final top = box.localToGlobal(Offset.zero).dy;
    final screenHeight = MediaQuery.of(context).size.height;
    _showBelow = top < screenHeight * 0.38;
  }

  OverlayEntry _buildOverlayEntry() {
    return OverlayEntry(
      builder: (_) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _removeOverlay,
              behavior: HitTestBehavior.opaque,
            ),
          ),
          CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: _showBelow ? const Offset(0, 8) : const Offset(0, -8),
            targetAnchor: _showBelow
                ? Alignment.bottomCenter
                : Alignment.topCenter,
            followerAnchor: _showBelow
                ? Alignment.topCenter
                : Alignment.bottomCenter,
            child: MouseRegion(
              onEnter: (_) {
                _hoveringOverlay = true;
                _hoverCloseTimer?.cancel();
              },
              onExit: (_) {
                _hoveringOverlay = false;
                _scheduleClose();
              },
              child: Material(
                color: Colors.transparent,
                child: ItemTooltipOverlayCard(
                  fallbackData: _buildDisplayData(),
                  detail: _cachedTooltipDetail,
                  loading: _loadingTooltip,
                  unavailable: _detailUnavailable,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _scheduleClose() {
    _hoverCloseTimer?.cancel();
    _hoverCloseTimer = Timer(const Duration(milliseconds: 120), () {
      if (!_hoveringTarget && !_hoveringOverlay) {
        _removeOverlay();
      }
    });
  }

  void _onTargetEnter(dynamic _) {
    _hoveringTarget = true;
    _hoverCloseTimer?.cancel();

    if (!_shouldUseNativeHover(context)) return;

    _hoverOpenTimer?.cancel();
    _hoverOpenTimer = Timer(const Duration(milliseconds: 160), () {
      if (_hoveringTarget && _overlayEntry == null) {
        _showNativeTooltip();
      }
    });
  }

  void _onTargetExit(dynamic _) {
    _hoveringTarget = false;
    _hoverOpenTimer?.cancel();
    if (_shouldUseNativeHover(context)) {
      _scheduleClose();
    }
  }

  void _onTap() {
    if (widget.mode == ItemTooltipInteractionMode.actionFirstMode) {
      widget.onPrimaryTap?.call();
      return;
    }
    if (_shouldHandleTapForDetails(context)) {
      _toggleNativeTooltip();
    }
  }

  void _onLongPress() {
    if (widget.mode == ItemTooltipInteractionMode.actionFirstMode) {
      _showNativeTooltip();
      return;
    }
    if (!_hasMousePointer(context)) {
      _toggleNativeTooltip();
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: _onTargetEnter,
        onExit: _onTargetExit,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _onTap,
          onLongPress: _onLongPress,
          child: widget.child,
        ),
      ),
    );

    final itemId = _effectiveItemId;
    if (_shouldUseOfficialWebTooltip(context) &&
        itemId != null &&
        _effectiveEntityKind == TooltipEntityKind.item) {
      content = WowheadWebTooltipAnchor(
        key: ValueKey('wh-anchor-$itemId-${_wowheadDomain(context)}'),
        itemId: itemId,
        domain: _wowheadDomain(context),
        child: content,
      );
    }

    return content;
  }
}

void showLegacyItemTooltip(
  BuildContext context,
  EquippedItem item,
  Offset tapPosition,
) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  final data = ItemTooltipDisplayData.fromSources(equippedItem: item);

  entry = OverlayEntry(
    builder: (context) {
      final screenSize = MediaQuery.of(context).size;
      const tooltipWidth = 320.0;
      const tooltipMaxHeight = 420.0;

      double left = tapPosition.dx - tooltipWidth / 2;
      double top = tapPosition.dy + 16;

      if (left < 8) left = 8;
      if (left + tooltipWidth > screenSize.width - 8) {
        left = screenSize.width - tooltipWidth - 8;
      }

      if (top + tooltipMaxHeight > screenSize.height - 8) {
        top = tapPosition.dy - tooltipMaxHeight - 16;
        if (top < 8) top = 8;
      }

      return Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => entry.remove(),
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.black26),
            ),
          ),
          Positioned(
            left: left,
            top: top,
            child: Material(
              color: Colors.transparent,
              child: ItemTooltipOverlayCard(fallbackData: data),
            ),
          ),
        ],
      );
    },
  );

  overlay.insert(entry);
}

class _TooltipHeaderBlock extends StatelessWidget {
  final String? iconUrl;
  final Color qualityColor;
  final String title;
  final int? itemLevel;
  final String quality;

  const _TooltipHeaderBlock({
    required this.iconUrl,
    required this.qualityColor,
    required this.title,
    required this.itemLevel,
    required this.quality,
  });

  @override
  Widget build(BuildContext context) {
    final t = S.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: qualityColor.withValues(alpha: 0.08),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (iconUrl != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                iconUrl!,
                width: 42,
                height: 42,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _fallbackIcon(),
              ),
            ),
            const SizedBox(width: 10),
          ] else
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: _fallbackIcon(),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.isEmpty ? t.unknownItem : title,
                  style: TextStyle(
                    color: qualityColor,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    height: 1.15,
                  ),
                ),
                if (itemLevel != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${t.tooltipItemLevel} $itemLevel',
                    style: const TextStyle(
                      color: WowTheme.primaryGold,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  quality,
                  style: TextStyle(
                    color: qualityColor.withValues(alpha: 0.9),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallbackIcon() => Container(
    width: 42,
    height: 42,
    color: WowTheme.surfaceDark,
    child: const Icon(
      Icons.inventory_2_outlined,
      color: WowTheme.textSecondary,
      size: 24,
    ),
  );
}

class _TooltipSectionBlock extends StatelessWidget {
  final String? title;
  final List<TooltipLine> lines;
  final Color qualityColor;
  final String fallbackSellPriceLabel;

  const _TooltipSectionBlock({
    required this.title,
    required this.lines,
    required this.qualityColor,
    required this.fallbackSellPriceLabel,
  });

  @override
  Widget build(BuildContext context) {
    if (lines.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: const TextStyle(
                color: WowTheme.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
          ],
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: _TooltipLineView(
                line: line,
                qualityColor: qualityColor,
                fallbackSellPriceLabel: fallbackSellPriceLabel,
              ),
            ),
        ],
      ),
    );
  }
}

class _TooltipLineView extends StatelessWidget {
  final TooltipLine line;
  final Color qualityColor;
  final String fallbackSellPriceLabel;

  const _TooltipLineView({
    required this.line,
    required this.qualityColor,
    required this.fallbackSellPriceLabel,
  });

  @override
  Widget build(BuildContext context) {
    final color = _lineColor(line.tone, qualityColor);
    final icon = _lineIcon(line.icon, color);

    return Padding(
      padding: EdgeInsets.only(left: line.indent ? 10 : 0),
      child: switch (line.layout) {
        TooltipLineLayout.labelValue => _TooltipLabelValueRow(
          label: line.label ?? '',
          value: line.text ?? '',
          tone: line.tone,
          qualityColor: qualityColor,
          leadingIcon: icon,
        ),
        TooltipLineLayout.currency => _TooltipCurrencyRow(
          label: line.label ?? fallbackSellPriceLabel,
          currency: line.currency ?? const TooltipCurrency(),
          color: color,
          leadingIcon: icon,
        ),
        TooltipLineLayout.bullet => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            icon ?? Icon(Icons.circle, size: 6, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                line.text ?? '',
                style: TextStyle(color: color, fontSize: 12, height: 1.2),
              ),
            ),
          ],
        ),
        TooltipLineLayout.text => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null) ...[icon, const SizedBox(width: 6)],
            Expanded(
              child: Text(
                line.text ?? '',
                style: TextStyle(color: color, fontSize: 12, height: 1.2),
              ),
            ),
          ],
        ),
      },
    );
  }

  Color _lineColor(TooltipLineTone tone, Color qualityColor) {
    return switch (tone) {
      TooltipLineTone.quality => qualityColor,
      TooltipLineTone.gold => WowTheme.primaryGold,
      TooltipLineTone.positive => const Color(0xFF1EFF00),
      TooltipLineTone.muted => WowTheme.textSecondary,
      TooltipLineTone.flavor => WowTheme.textSecondary,
      TooltipLineTone.warning => WowTheme.accentRed,
      TooltipLineTone.neutral => WowTheme.textPrimary,
    };
  }

  Widget? _lineIcon(String? icon, Color color) {
    return switch (icon?.trim().toLowerCase()) {
      'enchant' => Icon(Icons.auto_fix_high, size: 13, color: color),
      'gem' => Icon(Icons.diamond_outlined, size: 13, color: color),
      'warning' => Icon(Icons.warning_amber_rounded, size: 13, color: color),
      'source' => Icon(Icons.place_outlined, size: 13, color: color),
      'bullet' => Icon(Icons.circle, size: 6, color: color),
      _ => null,
    };
  }
}

class _TooltipLabelValueRow extends StatelessWidget {
  final String label;
  final String value;
  final TooltipLineTone tone;
  final Color qualityColor;
  final Widget? leadingIcon;

  const _TooltipLabelValueRow({
    required this.label,
    required this.value,
    required this.tone,
    required this.qualityColor,
    this.leadingIcon,
  });

  @override
  Widget build(BuildContext context) {
    final valueColor = switch (tone) {
      TooltipLineTone.quality => qualityColor,
      TooltipLineTone.gold => WowTheme.primaryGold,
      TooltipLineTone.positive => const Color(0xFF1EFF00),
      TooltipLineTone.warning => WowTheme.accentRed,
      TooltipLineTone.muted => WowTheme.textSecondary,
      TooltipLineTone.flavor => WowTheme.textSecondary,
      TooltipLineTone.neutral => WowTheme.textPrimary,
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (leadingIcon != null) ...[leadingIcon!, const SizedBox(width: 6)],
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: WowTheme.textSecondary, fontSize: 12),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(color: valueColor, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

class _TooltipCurrencyRow extends StatelessWidget {
  final String label;
  final TooltipCurrency currency;
  final Color color;
  final Widget? leadingIcon;

  const _TooltipCurrencyRow({
    required this.label,
    required this.currency,
    required this.color,
    this.leadingIcon,
  });

  @override
  Widget build(BuildContext context) {
    final parts = <String>[
      if (currency.gold > 0) '${currency.gold}g',
      if (currency.silver > 0) '${currency.silver}s',
      if (currency.copper > 0) '${currency.copper}c',
    ];
    final value = parts.isEmpty ? '0c' : parts.join(' ');

    return _TooltipLabelValueRow(
      label: label,
      value: value,
      tone: TooltipLineTone.gold,
      qualityColor: color,
      leadingIcon: leadingIcon,
    );
  }
}

class _TooltipContextBlock extends StatelessWidget {
  final TooltipContextAttachment contextAttachment;

  const _TooltipContextBlock({required this.contextAttachment});

  @override
  Widget build(BuildContext context) {
    final t = S.of(context)!;
    final localeCode = Localizations.localeOf(context).languageCode;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (contextAttachment.appliedEnchantments.isNotEmpty) ...[
            Text(
              t.tooltipContextEnchantments,
              style: const TextStyle(
                color: WowTheme.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            for (final enchant in contextAttachment.appliedEnchantments)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.auto_fix_high,
                      size: 14,
                      color: WowTheme.accentBlue,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        enchant.primaryNameForLanguage(localeCode),
                        style: const TextStyle(
                          color: WowTheme.accentBlue,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
          ],
          if (contextAttachment.appliedGems.isNotEmpty) ...[
            if (contextAttachment.appliedEnchantments.isNotEmpty)
              const SizedBox(height: 6),
            Text(
              t.tooltipContextGems,
              style: const TextStyle(
                color: WowTheme.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            for (final gem in contextAttachment.appliedGems)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.diamond_outlined,
                      size: 14,
                      color: WowTheme.primaryGold,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        gem.primaryNameForLanguage(localeCode),
                        style: const TextStyle(
                          color: WowTheme.primaryGold,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
