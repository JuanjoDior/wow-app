import 'package:flutter/widgets.dart';

import 'wowhead_web_tooltip_anchor_stub.dart'
    if (dart.library.html) 'wowhead_web_tooltip_anchor_web.dart'
    as impl;

bool isWowheadWebTooltipAvailable() => impl.isWowheadWebTooltipAvailable();

class WowheadWebTooltipAnchor extends StatelessWidget {
  final Widget child;
  final int itemId;
  final String domain;

  const WowheadWebTooltipAnchor({
    super.key,
    required this.child,
    required this.itemId,
    required this.domain,
  });

  @override
  Widget build(BuildContext context) {
    return impl.WowheadWebTooltipAnchorImpl(
      itemId: itemId,
      domain: domain,
      child: child,
    );
  }
}
