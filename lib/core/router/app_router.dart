import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wow_companion/features/character/presentation/pages/character_page.dart';
import 'package:wow_companion/features/compare/presentation/pages/compare_select_page.dart';
import 'package:wow_companion/features/compare/presentation/pages/compare_result_page.dart';
import 'package:wow_companion/features/favorites/presentation/favorites_page.dart';
import 'package:wow_companion/features/items/presentation/items_page.dart';
import 'package:wow_companion/features/search/presentation/home_page.dart';
import 'package:wow_companion/shared/widgets/shell_layout.dart';
import 'package:wow_companion/features/guides/presentation/pages/guides_list_page.dart';
import 'package:wow_companion/features/guides/presentation/pages/guide_detail_page.dart';

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
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/guides',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: GuidesListPage()),
            ),
          ],
        ),
      ],
    ),
    // Character profile — full screen
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
    // Compare — select characters
    GoRoute(
      path: '/compare',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const CompareSelectPage(),
    ),

    GoRoute(
      path: '/guides/:classSlug/:specSlug',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        return GuideDetailPage(
          classSlug: state.pathParameters['classSlug']!,
          specSlug: state.pathParameters['specSlug']!,
        );
      },
    ),
    // Compare — results
    GoRoute(
      path: '/compare/:region1/:realm1/:name1/vs/:region2/:realm2/:name2',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        return CompareResultPage(
          region1: state.pathParameters['region1']!,
          realm1: state.pathParameters['realm1']!,
          name1: state.pathParameters['name1']!,
          region2: state.pathParameters['region2']!,
          realm2: state.pathParameters['realm2']!,
          name2: state.pathParameters['name2']!,
        );
      },
    ),
  ],
);
