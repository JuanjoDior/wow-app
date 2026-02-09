import 'package:flutter/material.dart';
import 'package:wow_companion/core/theme/wow_theme.dart';

class ItemsPage extends StatelessWidget {
  const ItemsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Items')),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: WowTheme.textSecondary,
            ),
            SizedBox(height: 16),
            Text(
              'Item Catalog',
              style: TextStyle(
                color: WowTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Coming in Phase 2',
              style: TextStyle(color: WowTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
