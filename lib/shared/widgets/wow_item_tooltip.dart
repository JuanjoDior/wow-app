import 'package:flutter/material.dart';
import 'package:wow_companion/core/di/injection.dart';
import 'package:wow_companion/core/theme/wow_theme.dart';
import 'package:wow_companion/features/items/domain/entities/item.dart';
import 'package:wow_companion/features/items/domain/usecases/get_item_detail.dart';
import 'package:wow_companion/l10n/generated/app_localizations.dart';

class WowItemTooltip extends StatefulWidget {
  final int itemId;
  final Widget child;

  const WowItemTooltip({
    super.key,
    required this.itemId,
    required this.child,
  });

  @override
  State<WowItemTooltip> createState() => _WowItemTooltipState();
}

class _WowItemTooltipState extends State<WowItemTooltip> {
  OverlayEntry? _overlayEntry;
  Item? _cachedItem;
  bool _loading = false;
  final _link = LayerLink();

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  Future<void> _fetchItem() async {
    if (_cachedItem != null || _loading) return;
    _loading = true;
    final result = await sl<GetItemDetail>()(widget.itemId);
    result.fold((_) {}, (item) {
      if (mounted) setState(() => _cachedItem = item);
    });
    _loading = false;
  }

  void _showOverlay(BuildContext context) async {
    await _fetchItem();
    if (!mounted || _cachedItem == null) return;

    _removeOverlay();
    _overlayEntry = _buildOverlayEntry(context, _cachedItem!);
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _buildOverlayEntry(BuildContext context, Item item) {
    final t = S.of(context)!;
    return OverlayEntry(
      builder: (_) => Positioned(
        width: 280,
        child: CompositedTransformFollower(
          link: _link,
          showWhenUnlinked: false,
          offset: const Offset(0, -8),
          targetAnchor: Alignment.topCenter,
          followerAnchor: Alignment.bottomCenter,
          child: Material(
            color: Colors.transparent,
            child: _TooltipCard(item: item, t: t),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _link,
      child: MouseRegion(
        onEnter: (_) => _showOverlay(context),
        onExit: (_) => _removeOverlay(),
        child: widget.child,
      ),
    );
  }
}

class _TooltipCard extends StatelessWidget {
  final Item item;
  final S t;
  const _TooltipCard({required this.item, required this.t});

  @override
  Widget build(BuildContext context) {
    final qualityColor = WowTheme.getQualityColor(item.quality);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C2E),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: qualityColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.7),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (item.iconUrl != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(
                    item.iconUrl!,
                    width: 40,
                    height: 40,
                    errorBuilder: (_, __, ___) => const SizedBox(
                      width: 40,
                      height: 40,
                      child: Icon(Icons.shield,
                          color: WowTheme.textSecondary),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  item.name,
                  style: TextStyle(
                    color: qualityColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(color: WowTheme.border, height: 1),
          const SizedBox(height: 8),
          if (item.level != null)
            _statRow(t.tooltipItemLevel, '${item.level}'),
          if (item.requiredLevel != null)
            _statRow(t.tooltipRequiredLevel, '${item.requiredLevel}'),
          if (item.inventoryName != null)
            _statRow(t.slot, item.inventoryName!),
          if (item.itemSubclass != null)
            _statRow(t.tooltipType, item.itemSubclass!),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: WowTheme.textSecondary, fontSize: 12)),
          Text(value,
              style: const TextStyle(
                  color: WowTheme.textPrimary, fontSize: 12)),
        ],
      ),
    );
  }
}
