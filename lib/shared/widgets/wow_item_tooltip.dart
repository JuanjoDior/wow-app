import 'package:flutter/widgets.dart';
import 'package:wow_companion/shared/widgets/item_tooltip_trigger.dart';

/// Wrapper legacy para compatibilidad.
class WowItemTooltip extends StatelessWidget {
  final int itemId;
  final Widget child;

  const WowItemTooltip({super.key, required this.itemId, required this.child});

  @override
  Widget build(BuildContext context) {
    return ItemTooltipTrigger.forItemId(
      mode: ItemTooltipInteractionMode.detailMode,
      itemId: itemId,
      child: child,
    );
  }
}
