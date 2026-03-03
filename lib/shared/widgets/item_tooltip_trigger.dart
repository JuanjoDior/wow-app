import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wow_companion/core/di/injection.dart';
import 'package:wow_companion/core/l10n/locale_notifier.dart';
import 'package:wow_companion/core/theme/wow_theme.dart';
import 'package:wow_companion/features/character/domain/entities/character.dart';
import 'package:wow_companion/features/items/domain/entities/item.dart';
import 'package:wow_companion/features/items/domain/usecases/get_item_detail.dart';
import 'package:wow_companion/l10n/generated/app_localizations.dart';
import 'package:wow_companion/shared/widgets/wowhead_web_tooltip_anchor.dart';

enum ItemTooltipInteractionMode { detailMode, actionFirstMode }

class ItemTooltipDisplayData {
  final int? itemId;
  final String name;
  final String quality;
  final int itemLevel;
  final int? requiredLevel;
  final String? slotLabel;
  final String? itemSubclass;
  final String? iconUrl;
  final List<String> enchantments;
  final List<String> gems;
  final List<int> bonusIds;

  const ItemTooltipDisplayData({
    required this.itemId,
    required this.name,
    required this.quality,
    required this.itemLevel,
    required this.requiredLevel,
    required this.slotLabel,
    required this.itemSubclass,
    required this.iconUrl,
    required this.enchantments,
    required this.gems,
    required this.bonusIds,
  });

  factory ItemTooltipDisplayData.fromSources({
    EquippedItem? equippedItem,
    Item? itemDetail,
    int? fallbackItemId,
  }) {
    final resolvedItemId =
        equippedItem?.itemId ?? itemDetail?.id ?? fallbackItemId;

    final name = _bestText(
      equippedItem?.name,
      itemDetail?.name,
      fallback: '',
      disallowUnknown: true,
    );

    final quality = _bestText(
      equippedItem?.quality,
      itemDetail?.quality,
      fallback: 'COMMON',
    ).toUpperCase();

    final itemLevel = _bestInt(
      equippedItem?.itemLevel,
      itemDetail?.level,
      fallback: 0,
      minValue: 1,
    );

    final slotLabel = _bestText(
      _slotDisplayName(equippedItem?.slot),
      itemDetail?.inventoryName,
    );

    final itemSubclass = _bestText(itemDetail?.itemSubclass, null);

    final iconUrl = _bestText(equippedItem?.iconUrl, itemDetail?.iconUrl);

    final enchantments = (equippedItem?.enchantments ?? const <String>[])
        .where((e) => e.trim().isNotEmpty)
        .toList(growable: false);
    final gems = (equippedItem?.gems ?? const <String>[])
        .where((e) => e.trim().isNotEmpty)
        .toList(growable: false);
    final bonusIds = List<int>.from(
      equippedItem?.bonusIds ?? const <int>[],
      growable: false,
    );

    return ItemTooltipDisplayData(
      itemId: resolvedItemId,
      name: name,
      quality: quality,
      itemLevel: itemLevel,
      requiredLevel: itemDetail?.requiredLevel,
      slotLabel: slotLabel,
      itemSubclass: itemSubclass,
      iconUrl: iconUrl,
      enchantments: enchantments,
      gems: gems,
      bonusIds: bonusIds,
    );
  }

  String? get wowheadUrl {
    if (itemId == null) return null;
    final base = 'https://www.wowhead.com/item=$itemId';
    if (bonusIds.isNotEmpty) {
      return '$base&bonus=${bonusIds.join(':')}';
    }
    return base;
  }

  static String _bestText(
    String? primary,
    String? secondary, {
    String? fallback,
    bool disallowUnknown = false,
  }) {
    final p = primary?.trim();
    final s = secondary?.trim();

    bool isValid(String? text) {
      if (text == null || text.isEmpty) return false;
      if (!disallowUnknown) return true;
      return text.toLowerCase() != 'unknown';
    }

    if (isValid(p)) return p!;
    if (isValid(s)) return s!;
    return fallback ?? '';
  }

  static int _bestInt(
    int? primary,
    int? secondary, {
    required int fallback,
    int? minValue,
  }) {
    final candidates = [primary, secondary];
    for (final candidate in candidates) {
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
  final ItemTooltipDisplayData data;

  const ItemTooltipOverlayCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final t = S.of(context)!;
    final qualityColor = WowTheme.getQualityColor(data.quality);

    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: qualityColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: qualityColor.withValues(alpha: 0.3),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: qualityColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(7),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (data.iconUrl != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      data.iconUrl!,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const SizedBox(
                        width: 40,
                        height: 40,
                        child: Icon(
                          Icons.shield,
                          color: WowTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.name.isEmpty ? t.unknownItem : data.name,
                        style: TextStyle(
                          color: qualityColor,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (data.itemLevel > 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          t.itemLevel(data.itemLevel),
                          style: const TextStyle(
                            color: WowTheme.primaryGold,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (data.requiredLevel != null)
                  _statRow(t.tooltipRequiredLevel, '${data.requiredLevel}'),
                if (data.slotLabel != null) _statRow(t.slot, data.slotLabel!),
                if (data.itemSubclass != null)
                  _statRow(t.tooltipType, data.itemSubclass!),
                if (data.requiredLevel != null ||
                    data.slotLabel != null ||
                    data.itemSubclass != null)
                  const SizedBox(height: 8),
                if (data.enchantments.isNotEmpty) ...[
                  for (final ench in data.enchantments)
                    _listRow(
                      Icons.auto_fix_high,
                      const Color(0xFF00FF00),
                      ench,
                    ),
                ],
                if (data.gems.isNotEmpty) ...[
                  if (data.enchantments.isNotEmpty) const SizedBox(height: 4),
                  for (final gem in data.gems)
                    _listRow(
                      Icons.diamond_outlined,
                      const Color(0xFF0070DD),
                      gem,
                    ),
                ],
                if (data.enchantments.isEmpty && data.gems.isEmpty)
                  Text(
                    t.noEnchantmentsOrGems,
                    style: const TextStyle(
                      color: WowTheme.textSecondary,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                if (data.wowheadUrl != null) ...[
                  const Divider(color: WowTheme.border, height: 20),
                  InkWell(
                    onTap: () => _openWowhead(data.wowheadUrl!),
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
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: WowTheme.textSecondary, fontSize: 12),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(color: WowTheme.textPrimary, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _listRow(IconData icon, Color color, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
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
  final EquippedItem? equippedItem;
  final int? itemId;

  const ItemTooltipTrigger.forEquippedItem({
    super.key,
    required EquippedItem this.equippedItem,
    required this.child,
    this.mode = ItemTooltipInteractionMode.detailMode,
    this.onPrimaryTap,
    this.enableWebOfficialTooltip = true,
  }) : itemId = null;

  const ItemTooltipTrigger.forItemId({
    super.key,
    required this.itemId,
    required this.child,
    this.mode = ItemTooltipInteractionMode.detailMode,
    this.onPrimaryTap,
    this.enableWebOfficialTooltip = true,
  }) : equippedItem = null;

  @override
  State<ItemTooltipTrigger> createState() => _ItemTooltipTriggerState();
}

class _ItemTooltipTriggerState extends State<ItemTooltipTrigger> {
  final LayerLink _layerLink = LayerLink();

  OverlayEntry? _overlayEntry;
  Timer? _hoverOpenTimer;
  Timer? _hoverCloseTimer;
  Item? _cachedItem;
  bool _loadingItem = false;
  bool _hoveringTarget = false;
  bool _hoveringOverlay = false;
  bool _showBelow = false;

  int? get _effectiveItemId => widget.itemId ?? widget.equippedItem?.itemId;

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
    // Temporalmente desactivado para evitar parpadeos por hover en escritorio/web.
    // El tooltip queda en modo click/long-press.
    return false;
  }

  bool _shouldUseNativeHover(BuildContext context) {
    // Hover desactivado: apertura únicamente por interacción explícita.
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

  Future<void> _fetchItemDetailIfNeeded() async {
    final itemId = _effectiveItemId;
    if (itemId == null || _cachedItem != null || _loadingItem) return;

    _loadingItem = true;
    final result = await sl<GetItemDetail>()(
      itemId,
      locale: sl<LocaleNotifier>().blizzardLocale,
    );
    result.fold((_) {}, (item) {
      _cachedItem = item;
    });
    _loadingItem = false;
  }

  ItemTooltipDisplayData _buildDisplayData() {
    return ItemTooltipDisplayData.fromSources(
      equippedItem: widget.equippedItem,
      itemDetail: _cachedItem,
      fallbackItemId: _effectiveItemId,
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
    await _fetchItemDetailIfNeeded();
    if (!mounted) return;

    _updateDirection();
    _removeOverlay();

    final data = _buildDisplayData();
    final overlay = Overlay.of(context);
    _overlayEntry = _buildOverlayEntry(data);
    overlay.insert(_overlayEntry!);
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

  OverlayEntry _buildOverlayEntry(ItemTooltipDisplayData data) {
    return OverlayEntry(
      builder: (_) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _removeOverlay,
              behavior: HitTestBehavior.opaque,
            ),
          ),
          Positioned(
            width: 300,
            child: CompositedTransformFollower(
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
                  child: ItemTooltipOverlayCard(data: data),
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

    if (_shouldUseOfficialWebTooltip(context)) {
      content = WowheadWebTooltipAnchor(
        key: ValueKey(
          'wh-anchor-${_effectiveItemId!}-${_wowheadDomain(context)}',
        ),
        itemId: _effectiveItemId!,
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
      const tooltipWidth = 300.0;
      const tooltipMaxHeight = 320.0;

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
              child: ItemTooltipOverlayCard(data: data),
            ),
          ),
        ],
      );
    },
  );

  overlay.insert(entry);
}
