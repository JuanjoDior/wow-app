import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:wow_companion/l10n/generated/app_localizations.dart';
import 'package:wow_companion/core/di/injection.dart';
import 'package:wow_companion/core/l10n/locale_notifier.dart';
import 'package:wow_companion/core/theme/wow_theme.dart';

class ShellLayout extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ShellLayout({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final t = S.of(context)!;
    final isWide = MediaQuery.sizeOf(context).width >= 800;

    return Scaffold(
      body: Row(
        children: [
          if (isWide)
            NavigationRail(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: _onTap,
              backgroundColor: WowTheme.surfaceDark,
              indicatorColor: WowTheme.primaryGold.withValues(alpha: 0.2),
              selectedIconTheme: const IconThemeData(
                color: WowTheme.primaryGold,
              ),
              unselectedIconTheme: const IconThemeData(
                color: WowTheme.textSecondary,
              ),
              selectedLabelTextStyle: const TextStyle(
                color: WowTheme.primaryGold,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelTextStyle: const TextStyle(
                color: WowTheme.textSecondary,
              ),
              labelType: NavigationRailLabelType.all,
              leading: const Padding(
                padding: EdgeInsets.all(16),
                child: Text('⚔️', style: TextStyle(fontSize: 28)),
              ),

              trailing: Padding(
                padding: const EdgeInsets.only(top: 32),
                child: IconButton(
                  tooltip: sl<LocaleNotifier>().locale.languageCode == 'es'
                      ? 'English'
                      : 'Español',
                  icon: Text(
                    sl<LocaleNotifier>().locale.languageCode == 'es'
                        ? 'EN'
                        : 'ES',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: WowTheme.primaryGold,
                    ),
                  ),
                  onPressed: () => sl<LocaleNotifier>().toggleLocale(),
                ),
              ),

              destinations: [
                NavigationRailDestination(
                  icon: const Icon(Icons.home_outlined),
                  selectedIcon: const Icon(Icons.home),
                  label: Text(t.home),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.star_outline),
                  selectedIcon: const Icon(Icons.star),
                  label: Text(t.favorites),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.inventory_2_outlined),
                  selectedIcon: const Icon(Icons.inventory_2),
                  label: Text(t.items),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.menu_book_outlined),
                  selectedIcon: const Icon(Icons.menu_book),
                  label: Text(t.guides),
                ),
              ],
            ),
          Expanded(child: navigationShell),
        ],
      ),
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: _onTap,
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.home_outlined),
                  selectedIcon: const Icon(Icons.home),
                  label: t.home,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.star_outline),
                  selectedIcon: const Icon(Icons.star),
                  label: t.favorites,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.inventory_2_outlined),
                  selectedIcon: const Icon(Icons.inventory_2),
                  label: t.items,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.menu_book_outlined),
                  selectedIcon: const Icon(Icons.menu_book),
                  label: t.guides,
                ),
              ],
            ),
    );
  }

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}
