import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wow_companion/core/theme/wow_theme.dart';
import 'package:wow_companion/features/character/domain/entities/character.dart';
import 'package:wow_companion/l10n/generated/app_localizations.dart';

/// A WoW-style item tooltip shown in a popup overlay.
class ItemTooltipOverlay extends StatelessWidget {
  final EquippedItem item;

  const ItemTooltipOverlay({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final qualityColor = WowTheme.getQualityColor(item.quality);
    final t = S.of(context)!;

    return Container(
      width: 280,
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
          // Header: name + ilvl
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: qualityColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(7),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    color: qualityColor,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.displaySlot,
                      style: const TextStyle(
                        color: WowTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      t.itemLevel(item.itemLevel),
                      style: const TextStyle(
                        color: WowTheme.primaryGold,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Body: enchants, gems
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Enchantments
                if (item.enchantments.isNotEmpty) ...[
                  for (final ench in item.enchantments)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.auto_fix_high,
                            size: 14,
                            color: Color(0xFF00FF00),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              ench,
                              style: const TextStyle(
                                color: Color(0xFF00FF00),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],

                // Gems
                if (item.gems.isNotEmpty) ...[
                  if (item.enchantments.isNotEmpty) const SizedBox(height: 4),
                  for (final gem in item.gems)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.diamond_outlined,
                            size: 14,
                            color: Color(0xFF0070DD),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              gem,
                              style: const TextStyle(
                                color: Color(0xFF0070DD),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],

                // Empty state
                if (item.enchantments.isEmpty && item.gems.isEmpty)
                  Text(
                    t.noEnchantmentsOrGems,
                    style: const TextStyle(
                      color: WowTheme.textSecondary,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),

                // Wowhead link
                if (item.wowheadUrl != null) ...[
                  const Divider(color: WowTheme.border, height: 20),
                  InkWell(
                    onTap: () => _openWowhead(item.wowheadUrl!),
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

  Future<void> _openWowhead(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

/// Shows an item tooltip as a popup anchored to the tapped widget.
void showItemTooltip(
  BuildContext context,
  EquippedItem item,
  Offset tapPosition,
) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (context) {
      final screenSize = MediaQuery.of(context).size;
      const tooltipWidth = 280.0;
      const tooltipMaxHeight = 300.0;

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
              child: ItemTooltipOverlay(item: item),
            ),
          ),
        ],
      );
    },
  );

  overlay.insert(entry);
}
