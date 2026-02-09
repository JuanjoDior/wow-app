import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wow_companion/features/character/presentation/pages/character_page.dart';
import 'package:wow_companion/features/favorites/presentation/favorites_page.dart';
import 'package:wow_companion/features/items/presentation/items_page.dart';
import 'package:wow_companion/features/search/presentation/home_page.dart';
import 'package:wow_companion/shared/widgets/shell_layout.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ShellLayout(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: HomePage()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/favorites',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: FavoritesPage()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/items',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: ItemsPage()),
            ),
          ],
        ),
      ],
    ),
    // Perfil de personaje — fuera del shell para pantalla completa
    GoRoute(
      path: '/character/:region/:realm/:name',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        return CharacterPage(
          region: state.pathParameters['region']!,
          realm: state.pathParameters['realm']!,
          name: state.pathParameters['name']!,
        );
      },
    ),
  ],
);
