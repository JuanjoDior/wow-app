import 'package:flutter/widgets.dart';

bool isWowheadWebTooltipAvailable() => false;

class WowheadWebTooltipAnchorImpl extends StatelessWidget {
  final Widget child;
  final int itemId;
  final String domain;

  const WowheadWebTooltipAnchorImpl({
    super.key,
    required this.child,
    required this.itemId,
    required this.domain,
  });

  @override
  Widget build(BuildContext context) => child;
}
