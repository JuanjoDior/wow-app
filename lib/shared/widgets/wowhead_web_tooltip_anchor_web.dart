// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';

bool isWowheadWebTooltipAvailable() {
  try {
    return js.context.hasProperty(r'$WowheadPower');
  } catch (_) {
    return false;
  }
}

class WowheadWebTooltipAnchorImpl extends StatefulWidget {
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
  State<WowheadWebTooltipAnchorImpl> createState() =>
      _WowheadWebTooltipAnchorImplState();
}

class _WowheadWebTooltipAnchorImplState
    extends State<WowheadWebTooltipAnchorImpl> {
  static int _counter = 0;
  late String _viewType;

  @override
  void initState() {
    super.initState();
    _registerViewFactory();
    _refreshWowheadLinks();
  }

  @override
  void didUpdateWidget(covariant WowheadWebTooltipAnchorImpl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.itemId != widget.itemId ||
        oldWidget.domain != widget.domain) {
      _registerViewFactory();
      _refreshWowheadLinks();
    }
  }

  void _registerViewFactory() {
    _viewType = 'wowhead-tooltip-anchor-${_counter++}';
    final itemId = widget.itemId;
    final domain = widget.domain;

    ui_web.platformViewRegistry.registerViewFactory(_viewType, (_) {
      final anchor = html.AnchorElement()
        ..href = '#'
        ..setAttribute('data-wowhead', 'item=$itemId&domain=$domain')
        ..style.display = 'block'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.opacity = '0'
        ..style.background = 'transparent'
        ..style.textDecoration = 'none';

      anchor.onClick.listen((event) {
        event.preventDefault();
      });

      return anchor;
    });
  }

  void _refreshWowheadLinks() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        if (js.context.hasProperty(r'$WowheadPower')) {
          final power = js.context[r'$WowheadPower'];
          if (power is js.JsObject) {
            power.callMethod('refreshLinks');
          }
        }
      } catch (_) {
        // Fallback silencioso: el trigger abrirá tooltip nativo si no hay script.
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.passthrough,
      children: [
        widget.child,
        Positioned.fill(
          child: HtmlElementView(key: ValueKey(_viewType), viewType: _viewType),
        ),
      ],
    );
  }
}
