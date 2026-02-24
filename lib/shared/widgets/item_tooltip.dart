import 'package:flutter/material.dart';
import 'package:wow_companion/features/character/domain/entities/character.dart';
import 'package:wow_companion/shared/widgets/item_tooltip_trigger.dart';

/// Wrapper legacy: mantiene API previa y delega al renderer nuevo.
class ItemTooltipOverlay extends StatelessWidget {
  final EquippedItem item;

  const ItemTooltipOverlay({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final data = ItemTooltipDisplayData.fromSources(equippedItem: item);
    return ItemTooltipOverlayCard(data: data);
  }
}

/// Wrapper legacy: mantiene firma previa y delega al helper nuevo.
void showItemTooltip(
  BuildContext context,
  EquippedItem item,
  Offset tapPosition,
) {
  showLegacyItemTooltip(context, item, tapPosition);
}
