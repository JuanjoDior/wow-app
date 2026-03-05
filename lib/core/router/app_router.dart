import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wow_companion/features/character/presentation/pages/character_page.dart';
import 'package:wow_companion/features/compare/presentation/pages/compare_select_page.dart';
import 'package:wow_companion/features/compare/presentation/pages/compare_result_page.dart';
import 'package:wow_companion/features/favorites/presentation/favorites_page.dart';
import 'package:wow_companion/features/items/presentation/items_page.dart';
import 'package:wow_companion/features/search/presentation/home_page.dart';
import 'package:wow_companion/shared/widgets/shell_layout.dart';
import 'package:wow_companion/features/builds/presentation/pages/builds_list_page.dart';
import 'package:wow_companion/features/builds/presentation/pages/build_detail_page.dart';
import 'package:wow_companion/features/planner/presentation/pages/weekly_planner_page.dart';

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
              path: '/builds',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: BuildsListPage()),
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
    // Build detail — full screen
    GoRoute(
      path: '/builds/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) =>
          BuildDetailPage(buildId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/planner/:region/:realm/:name',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => WeeklyPlannerPage(
        region: state.pathParameters['region']!,
        realm: state.pathParameters['realm']!,
        name: state.pathParameters['name']!,
      ),
    ),
  ],
);
