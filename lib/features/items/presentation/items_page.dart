import 'package:flutter/material.dart';
import 'package:wow_companion/core/theme/wow_theme.dart';
import 'package:wow_companion/l10n/generated/app_localizations.dart';

class ItemsPage extends StatelessWidget {
  const ItemsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = S.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(t.items)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: WowTheme.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              t.itemCatalog,
              style: const TextStyle(
                color: WowTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              t.comingSoon,
              style: const TextStyle(color: WowTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
